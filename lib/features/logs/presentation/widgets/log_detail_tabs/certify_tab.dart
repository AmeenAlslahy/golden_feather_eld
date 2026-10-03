import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_signature_canvas.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/daily_log.dart';
import '../../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../../../domain/shared/value_objects.dart';
import 'package:intl/intl.dart';
import '../../../domain/entities/log_readiness.dart';
import '../../providers/certify_log_provider.dart';
import '../../providers/logs_provider.dart';
import '../../../../../core/widgets/app_feedback.dart';

class CertifyTab extends ConsumerStatefulWidget {
  final DailyLog selectedLog;

  const CertifyTab({super.key, required this.selectedLog});

  @override
  ConsumerState<CertifyTab> createState() => _CertifyTabState();
}

class _CertifyTabState extends ConsumerState<CertifyTab> {
  final _formKey = GlobalKey<FormState>();
  late SignatureController _signatureController;
  bool _signatureReady = false;

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
    // Theme is needed for the pen colour, so the controller is built here —
    // but only once: rebuilding it on every dependency change (locale/theme)
    // would silently drop a signature in progress.
    if (_signatureReady) return;
    _signatureReady = true;
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
      // SRS 7.11 — the placeholder must disappear as soon as the driver
      // draws (and come back after Clear).
      onDrawStart: () => setState(() {}),
    );
    _signatureController.addListener(_onSignatureChanged);
  }

  void _onSignatureChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _signatureController.removeListener(_onSignatureChanged);
    _signatureController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    AppFeedback.error(context, message);
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    AppFeedback.success(context, message);
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Accept / reject one carrier-proposed edit through the existing respond API.
  Future<void> _respondToEdit(String editId, String action) async {
final error = await ref.read(certifyLogProvider.notifier).respondToCarrierEdit(
          logId: widget.selectedLog.id,
          editId: editId,
          action: action,
        );
    if (!mounted) return;
    if (error != null) {
      _showError(error);
      return;
    }
    _showSuccess(
      action.toUpperCase() == 'ACCEPT'
          ? (context.loc.carrierEditAcceptedReCertifyThe)
          : (context.loc.carrierEditRejected),
    );
  }

  Future<void> _onAgree() async {
final signatureBytes = await _signatureController.toPngBytes();
    if (!mounted) return;
    if (signatureBytes == null || signatureBytes.isEmpty) {
      _showError(
        context.loc.pleaseDrawASignatureFirst,
      );
      return;
    }

    final driverId = ref.read(authStateProvider).user?.id;
    if (driverId == null || driverId.isEmpty) {
      _showError(context.loc.sessionMissingPleaseLogInAgain);
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
      _showSuccess(
        context.loc.logSuccessfullyCertified,
      );
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
            Text(state.error!, textAlign: TextAlign.center, style: context.styles.error),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.loc.retryButton,
              onPressed: () => ref.read(certifyLogProvider.notifier).checkReadiness(widget.selectedLog.id),
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
              context.loc.notReadyForCertification,
              textAlign: TextAlign.center,
              style: context.styles.pageTitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              context.loc.pleaseResolveTheFollowingIssuesBefore,
              style: context.styles.body,
            ),
            const SizedBox(height: AppSpacing.md),
            ...readinessData.missingRequirements.map((req) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  const Icon(Icons.circle, size: 8, color: AppColors.dangerRed),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(req, style: context.styles.body)),
                ],
              ),
            )),
            const SizedBox(height: AppSpacing.xl),
            if (readinessData.pendingCarrierEdits.isNotEmpty) ...[
              for (final edit in readinessData.pendingCarrierEdits)
                _CarrierEditCard(
                  edit: edit,
                  busy: state.isLoading,
                  onRespond: (action) => _respondToEdit(edit.id, action),
                ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppButton(
              label: context.loc.notReady,
              type: EldButtonType.send,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      );
    }

    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            AppSignatureFormField(
              controller: _signatureController,
              padding: EdgeInsets.zero,
              validator: (hasSignature) {
                if (hasSignature != true) {
                  return context.loc.pleaseDrawASignatureFirst;
                }
                return null;
              },
            ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            readinessData.legalStatement.trim().isEmpty
                ? context.loc.certifyLegalStatement
                : readinessData.legalStatement,
            textAlign: TextAlign.center,
            style: context.styles.body.copyWith(height: 1.5, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: AppSpacing.md),
          if (readinessData.pendingCarrierEdits.isNotEmpty) ...[
            Text(
              context.loc.carrierEditsMustBeAcceptedOr,
              textAlign: TextAlign.center,
              style: context.styles.error,
            ),
            const SizedBox(height: AppSpacing.md),
            for (final edit in readinessData.pendingCarrierEdits)
              _CarrierEditCard(
                edit: edit,
                busy: state.isLoading,
                onRespond: (action) => _respondToEdit(edit.id, action),
              ),
            const SizedBox(height: AppSpacing.md),
          ],
          if (!widget.selectedLog.isFormComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                context.loc.fillFormFirst,
                textAlign: TextAlign.center,
                style: context.styles.error,
              ),
            ),
          AppButton(
            label: context.loc.notReady,
            type: EldButtonType.muted,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: AppSpacing.md),
          ListenableBuilder(
            listenable: _signatureController,
            builder: (context, _) {
              return AppButton(
                label: context.loc.agree.toUpperCase(),
                type: EldButtonType.agree,
                isLoading: state.isLoading,
                onPressed: () {
                  if (state.isLoading) return;
                  if (!_formKey.currentState!.validate()) return;
                  if (!widget.selectedLog.isFormComplete) {
                    _showError(context.loc.fillFormFirst);
                    return;
                  }
                  _onAgree();
                },
              );
            },
          ),
        ],
      ),
      ),
    );
  }
}

class _CarrierEditCard extends StatelessWidget {
  const _CarrierEditCard({
    required this.edit,
    required this.busy,
    required this.onRespond,
  });

  final CarrierProposedEditEntity edit;
  final bool busy;
  final void Function(String action) onRespond;

  @override
  Widget build(BuildContext context) {
final summary = [
      if (edit.carrierName != null && edit.carrierName!.trim().isNotEmpty)
        edit.carrierName!.trim(),
      if (edit.proposedStatus != null && edit.proposedStatus!.trim().isNotEmpty)
        edit.proposedStatus!.trim(),
      if (edit.newValuesSummary != null &&
          edit.newValuesSummary!.trim().isNotEmpty)
        edit.newValuesSummary!.trim(),
      if (edit.carrierReason != null && edit.carrierReason!.trim().isNotEmpty)
        edit.carrierReason!.trim(),
    ].join(' · ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            summary.isEmpty
                ? (context.loc.carrierProposedEdit)
                : summary,
            textAlign: TextAlign.center,
            style: context.styles.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.loc.reject,
                  type: EldButtonType.danger,
                  onPressed: busy ? null : () => onRespond('REJECT'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: context.loc.accept,
                  type: EldButtonType.agree,
                  onPressed: busy ? null : () => onRespond('ACCEPT'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

