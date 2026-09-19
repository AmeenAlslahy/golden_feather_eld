import 'dart:convert';
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
import '../../../../../backend/providers/backend_providers.dart';
import '../../../../../domain/shared/value_objects.dart';
import '../../../../../domain/signature/signature.dart';
import 'package:intl/intl.dart';

class CertifyTab extends ConsumerStatefulWidget {
  final DailyLog selectedLog;

  const CertifyTab({super.key, required this.selectedLog});

  @override
  ConsumerState<CertifyTab> createState() => _CertifyTabState();
}

class _CertifyTabState extends ConsumerState<CertifyTab> {
  late SignatureController _signatureController;
  bool _saving = false;

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

    // 1. Driver ID from auth.
    final driverId = ref.read(authStateProvider).user?.id;
    if (driverId == null || driverId.isEmpty) {
      _showError('Session missing. Please log in again.');
      return;
    }

    // 2. Log ID — must be numeric (legacy ids are 'log_0' → refuse).
    final logIdInt = int.tryParse(widget.selectedLog.id);
    if (logIdInt == null) {
      _showError('Cannot certify: this log is not yet synced.');
      return;
    }

    setState(() => _saving = true);

    try {
      final backend = ref.read(activeBackendProvider);
      final signatureBackend = backend.signature;
      if (signatureBackend == null) {
        _showError('Signature service unavailable.');
        return;
      }

      // 3. Save signature.
      final result = await signatureBackend.save(
        driverId: DriverId(int.parse(driverId)),
        logDate: _formatDate(widget.selectedLog.date),
        signatureDataBase64: base64Encode(signatureBytes),
        type: SignatureType.driverCertification,
      );

      result.fold(
        (error) => _showError('Failed: ${error.l10nKey}'),
        (certificate) {
          // 4. TODO(Phase4): call dailyLogsBackend.certify(...).
          _showSuccess('Signed. Certificate: ${certificate.signatureId}');
          Navigator.of(context).pop();
        },
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          EldCard(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.imagePlaceholder),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.loc.drawSignatureHere,
                          textAlign: TextAlign.center,
                          style: AppTextStyles(context).pageTitle.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
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
            onTap: () {
              _signatureController.clear();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                context.loc.clearSignature,
                style: AppTextStyles(context)
                    .body
                    .copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.loc.certifyDeclaration,
            textAlign: TextAlign.center,
            style: AppTextStyles(context).body.copyWith(height: 1.5),
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
                  onPressed: (_saving || !isSigned || !widget.selectedLog.isFormComplete)
                      ? null
                      : _onAgree,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    elevation: 0,
                  ),
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          context.loc.agree,
                          style: AppTextStyles(context)
                              .buttonText
                              .copyWith(color: AppColors.surface),
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
