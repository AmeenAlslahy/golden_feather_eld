import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_signature_canvas.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/daily_log.dart';
import '../../../domain/entities/log_readiness.dart';
import '../../providers/certify_log_provider.dart';
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

  CertifyLogNotifier get _notifier =>
      ref.read(certifyLogProvider(widget.selectedLog.id).notifier);

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

  /// Renders an outcome decided by the notifier. Returns true on success.
  bool _show(CertifyOutcome? outcome) {
    if (outcome == null || !mounted) return false;
    switch (outcome) {
      case CertifySucceeded(:final message):
        AppFeedback.success(context, message);
        return true;
      case CertifyFailed(:final message):
        AppFeedback.error(context, message);
        return false;
    }
  }

  Future<void> _respondToEdit(String editId, CarrierEditResponse response) async {
    _show(await _notifier.respondToCarrierEdit(editId: editId, response: response));
  }

  Future<void> _onAgree() async {
    if (!_formKey.currentState!.validate()) return;
    final signatureBytes = await _signatureController.toPngBytes();
    if (!mounted) return;
    final outcome = await _notifier.certify(
      log: widget.selectedLog,
      signatureBytes: signatureBytes,
    );
    if (_show(outcome) && mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(certifyLogProvider(widget.selectedLog.id));

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
              onPressed: _notifier.checkReadiness,
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
              type: EldButtonType.secondary,
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
            type: EldButtonType.secondary,
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: context.loc.agree.toUpperCase(),
            type: EldButtonType.agree,
            isLoading: state.isLoading,
            onPressed: _onAgree,
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
  final void Function(CarrierEditResponse response) onRespond;

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
                  onPressed: busy ? null : () => onRespond(CarrierEditResponse.reject),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: context.loc.accept,
                  type: EldButtonType.agree,
                  onPressed: busy ? null : () => onRespond(CarrierEditResponse.accept),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

