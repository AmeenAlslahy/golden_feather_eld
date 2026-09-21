import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/eld_card.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/daily_log.dart';
import '../../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../../domain/shared/value_objects.dart';
import 'package:intl/intl.dart';
import '../../providers/certify_log_provider.dart';
import '../../providers/logs_provider.dart';

class CertifyTab extends ConsumerStatefulWidget {
  final DailyLog selectedLog;

  const CertifyTab({super.key, required this.selectedLog});

  @override
  ConsumerState<CertifyTab> createState() => _CertifyTabState();
}

class _CertifyTabState extends ConsumerState<CertifyTab> {
  late SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(certifyLogProvider.notifier).checkReadiness(widget.selectedLog.id);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Theme.of(context).colorScheme.primary,
      exportBackgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.dangerRed),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.successGreen),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  Future<void> _onAgree() async {
    final signatureBytes = await _signatureController.toPngBytes();
    if (signatureBytes == null || signatureBytes.isEmpty) {
      _showError('Please draw a signature first.');
      return;
    }

    final driverId = ref.read(authStateProvider).user?.id;
    if (driverId == null || driverId.isEmpty) {
      _showError('Session missing. Please log in again.');
      return;
    }

    final logId = widget.selectedLog.id;
    
    await ref.read(certifyLogProvider.notifier).saveAndCertify(
      logId: logId,
      driverId: DriverId(int.parse(driverId)),
      logDate: _formatDate(widget.selectedLog.date),
      signatureBytes: signatureBytes,
    );
    
    if (!mounted) return;
    
    final certifyState = ref.read(certifyLogProvider);
    if (certifyState.isSuccess) {
      _showSuccess('Log successfully certified.');
      ref.read(logsProvider.notifier).loadLogs(refresh: true);
      if (mounted) Navigator.of(context).pop();
    } else if (certifyState.error != null) {
      _showError(certifyState.error!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(certifyLogProvider);

    if (state.isLoading && state.readinessData == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (state.error != null && state.readinessData == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: AppColors.dangerRed),
            const SizedBox(height: AppSpacing.md),
            Text(state.error!, textAlign: TextAlign.center, style: AppTextStyles(context).errorText),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton(
              onPressed: () => ref.read(certifyLogProvider.notifier).checkReadiness(widget.selectedLog.id),
              child: const Text('Retry'),
            )
          ],
        ),
      );
    }

    final readinessData = state.readinessData;
    if (readinessData == null) {
      return const SizedBox.shrink();
    }

    if (!state.isReady) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.warningYellow),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Not Ready for Certification',
              textAlign: TextAlign.center,
              style: AppTextStyles(context).pageTitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Please resolve the following issues before certifying your log:',
              style: AppTextStyles(context).body,
            ),
            const SizedBox(height: AppSpacing.md),
            ...readinessData.missingRequirements.map((req) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.dangerRed),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(req, style: AppTextStyles(context).body)),
                ],
              ),
            )),
            const SizedBox(height: AppSpacing.xl),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surface,
                foregroundColor: AppColors.primaryBlue,
                side: const BorderSide(color: AppColors.primaryBlue),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
              child: Text('NOT READY (Close)', style: AppTextStyles(context).buttonText.copyWith(color: AppColors.primaryBlue)),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          EldCard(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.imagePlaceholder),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(
                      context.loc.drawSignatureHere,
                      textAlign: TextAlign.center,
                      style: AppTextStyles(context).pageTitle.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Signature(
                    controller: _signatureController,
                    height: 200,
                    backgroundColor: AppColors.transparent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => _signatureController.clear(),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                context.loc.clearSignature,
                style: AppTextStyles(context).body.copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            readinessData.legalStatement,
            textAlign: TextAlign.center,
            style: AppTextStyles(context).body.copyWith(height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!widget.selectedLog.isFormComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                context.loc.fillFormFirst,
                textAlign: TextAlign.center,
                style: AppTextStyles(context).errorText,
              ),
            ),
          ListenableBuilder(
            listenable: _signatureController,
            builder: (context, _) {
              final isSigned = _signatureController.isNotEmpty;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (state.isLoading || !isSigned || !widget.selectedLog.isFormComplete)
                      ? null
                      : _onAgree,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.button)),
                    elevation: 0,
                  ),
                  child: state.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          context.loc.agree,
                          style: AppTextStyles(context).buttonText.copyWith(color: AppColors.surface),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
