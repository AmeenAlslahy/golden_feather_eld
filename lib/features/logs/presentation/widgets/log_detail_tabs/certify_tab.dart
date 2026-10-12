import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/app_signature_canvas.dart';
import '../../../domain/entities/daily_log.dart';
import '../../../domain/entities/log_readiness.dart';
import '../../pages/edit_log_page.dart';
import '../../providers/certify_log_provider.dart';
import '../../providers/log_detail_tab_provider.dart';
import 'pending_carrier_edits_section.dart';

class CertifyTab extends ConsumerStatefulWidget {
  final DailyLog selectedLog;

  const CertifyTab({super.key, required this.selectedLog});

  @override
  ConsumerState<CertifyTab> createState() => _CertifyTabState();
}

class _CertifyTabState extends ConsumerState<CertifyTab> {
  final _formKey = GlobalKey<FormState>();
  late final SignatureController _signatureController;

  @override
  void initState() {
    super.initState();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Colors.black,
      exportBackgroundColor: Colors.white,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<CertifyLogState>(certifyLogProvider(widget.selectedLog.id), (previous, current) {
      final outcome = current.outcome;
      if (outcome != null && outcome != previous?.outcome) {
        switch (outcome) {
          case CertifySucceeded(:final message, :final isLogCertified):
            AppFeedback.success(context, message);
            if (isLogCertified) {
              Navigator.of(context).maybePop();
            }
          case CertifyFailed(:final message):
            AppFeedback.error(context, message);
        }
      }
    });

    final notifier = ref.read(certifyLogProvider(widget.selectedLog.id).notifier);
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
            Icon(Icons.error_outline, size: 48, color: context.colors.error),
            const SizedBox(height: AppSpacing.md),
            Text(state.error!, textAlign: TextAlign.center, style: context.styles.error),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.loc.retryButton,
              onPressed: notifier.checkReadiness,
            )
          ],
        ),
      );
    }

    final readinessData = state.readinessData ??
        LogReadiness(
          dailyLogId: widget.selectedLog.id.value,
          driverId: 0,
          driverName: widget.selectedLog.driverName ?? '',
          logDate: widget.selectedLog.date.toIso8601String().split('T').first,
          readinessStatus:
              widget.selectedLog.isFormComplete ? 'READY' : 'NOT_READY',
          missingRequirements: widget.selectedLog.isFormComplete
              ? const []
              : [context.loc.fillFormFirst],
          legalStatement: context.loc.certifyLegalStatement,
          availableActions: const ['CERTIFY'],
        );

    if (!state.isReady && state.readinessData != null) {
      return _buildNotReadyView(context, notifier, readinessData, state.isLoading);
    }

    return _buildReadyView(context, notifier, readinessData, state.isLoading);
  }

  Widget _buildNotReadyView(
    BuildContext context,
    CertifyLogNotifier notifier,
    LogReadiness readinessData,
    bool isLoading,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 64,
            color: context.styles.warning.color ?? AppColors.warningYellow,
          ),
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
          ...readinessData.formattedMissingRequirements.map(
            (req) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 8, color: context.colors.error),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      req,
                      style: context.styles.body,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          // معالجة الفجوات: إضافة الحدث الناقص يدوياً ثم إعادة الفحص.
          OutlinedButton.icon(
            onPressed: () async {
              final saved = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EditLogPage(
                    event: null,
                    isNewEvent: true,
                  ),
                ),
              );
              if (saved == true && mounted) {
                await notifier.checkReadiness();
              }
            },
            icon: const Icon(Icons.add, size: 20),
            label: Text(context.loc.addButton),
          ),
          const SizedBox(height: AppSpacing.xl),
          PendingCarrierEditsSection(
            edits: readinessData.pendingCarrierEdits,
            isBusy: isLoading,
            onRespond: (editId, response) => notifier.respondToCarrierEdit(
              editId: editId,
              response: response,
            ),
            showWarningHeader: false,
          ),
          AppButton(
            label: context.loc.notReady,
            type: EldButtonType.secondary,
            onPressed: () {
              ref.read(logDetailTabProvider.notifier).state = 0;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReadyView(
    BuildContext context,
    CertifyLogNotifier notifier,
    LogReadiness readinessData,
    bool isLoading,
  ) {
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
              style: context.styles.body.copyWith(
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            PendingCarrierEditsSection(
              edits: readinessData.pendingCarrierEdits,
              isBusy: isLoading,
              onRespond: (editId, response) => notifier.respondToCarrierEdit(
                editId: editId,
                response: response,
              ),
              showWarningHeader: true,
            ),
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
              onPressed: () {
                _signatureController.clear();
              },
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: context.loc.agree.toUpperCase(),
              type: EldButtonType.agree,
              isLoading: isLoading,
              onPressed: () async {
                if (!_formKey.currentState!.validate()) return;
                final bytes = await _signatureController.toPngBytes();
                notifier.certify(
                  log: widget.selectedLog,
                  signatureBytes: bytes,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

