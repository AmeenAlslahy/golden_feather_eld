import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../../../core/widgets/app_feedback.dart';
import '../../../../../core/widgets/app_signature_canvas.dart';
import '../../../domain/entities/daily_log.dart';
import '../../../domain/entities/log_readiness.dart';
import '../../pages/edit_log_page.dart';
import '../../providers/certify_log_provider.dart';
import '../../providers/log_draft_signature_provider.dart';
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
  bool _signatureControllerInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_signatureControllerInitialized) return;
    final initialDraft = ref.read(
      logDraftSignatureProvider(widget.selectedLog.id),
    );
    // نسخة قابلة للتعديل: SignatureController يضيف النقاط إلى نفس القائمة
    // التي نسلّمها، وقائمة المسودة `List.unmodifiable` → كانت تكسر الرسم.
    _signatureController = SignatureController(
      points: initialDraft.isNotEmpty ? List<Point>.of(initialDraft) : null,
      penStrokeWidth: 3,
      penColor: context.textPrimary,
      exportBackgroundColor: Theme.of(context).colorScheme.surface,
    );
    _signatureController.addListener(_onSignatureChanged);
    _signatureControllerInitialized = true;
  }

  void _onSignatureChanged() {
    if (!mounted) return;
    ref
        .read(logDraftSignatureProvider(widget.selectedLog.id).notifier)
        .updateDraft(_signatureController.points);
  }

  @override
  void didUpdateWidget(covariant CertifyTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedLog.id != widget.selectedLog.id) {
      final newDraft = ref.read(
        logDraftSignatureProvider(widget.selectedLog.id),
      );
      _signatureController.value = List<Point>.of(newDraft);
    }
  }

  @override
  void dispose() {
    if (_signatureControllerInitialized) {
      _signatureController.removeListener(_onSignatureChanged);
      _signatureController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<List<Point>>(logDraftSignatureProvider(widget.selectedLog.id), (
      previous,
      current,
    ) {
      if (_signatureController.isEmpty && current.isNotEmpty) {
        _signatureController.value = List<Point>.of(current);
      }
    });

    ref.listen<CertifyLogState>(certifyLogProvider(widget.selectedLog.id), (
      previous,
      current,
    ) {
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

    final notifier = ref.read(
      certifyLogProvider(widget.selectedLog.id).notifier,
    );
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
            Icon(
              Icons.error_outline,
              size: AppSpacing.iconHero,
              color: context.colors.error,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.error!,
              textAlign: TextAlign.center,
              style: context.styles.error,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.loc.retryButton,
              onPressed: notifier.checkReadiness,
            ),
          ],
        ),
      );
    }

    final readinessData =
        state.readinessData ??
        LogReadiness(
          dailyLogId: widget.selectedLog.id.value,
          driverId: 0,
          driverName: widget.selectedLog.driverName ?? '',
          logDate: widget.selectedLog.date.toIso8601String().split('T').first,
          readinessStatus: widget.selectedLog.isFormComplete
              ? 'READY'
              : 'NOT_READY',
          missingRequirements: widget.selectedLog.isFormComplete
              ? const []
              : [context.loc.fillFormFirst],
          legalStatement: context.loc.certifyLegalStatement,
          availableActions: const ['CERTIFY'],
        );

    final isReady =
        state.isReady ||
        (state.readinessData == null && widget.selectedLog.isFormComplete);

    if (!isReady) {
      return _buildNotReadyView(
        context,
        notifier,
        readinessData,
        state.isLoading,
      );
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
            size: AppSpacing.iconFeature,
            color: context.warning,
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
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: Row(
                children: [
                  Icon(
                    Icons.circle,
                    size: AppSpacing.iconDot,
                    color: context.colors.error,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(req, style: context.styles.body)),
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
                  builder: (_) =>
                      const EditLogPage(event: null, isNewEvent: true),
                ),
              );
              if (saved == true && mounted) {
                await notifier.checkReadiness();
              }
            },
            icon: const Icon(Icons.add, size: AppSpacing.iconMedium),
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
            // "غير جاهز" يمسح التوقيع المرسوم فقط (كسلوك زر المسح في
            // اللوحة) — لا يبدّل التبويب ولا يغادر الصفحة.
            onPressed: () => _signatureController.clear(),
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
              // البيان القانوني بنسخته المعرّبة المحلية دائماً — الخادم
              // يرسل نصاً إنجليزياً ثابتاً فكان يظهر بالإنجليزية دوماً.
              context.loc.certifyLegalStatement,
              textAlign: TextAlign.center,
              style: context.styles.body.copyWith(
                height: 1.5,
                fontWeight: AppTypography.medium,
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
              // نفس السلوك: مسح التوقيع فقط، بلا تنقل.
              onPressed: () => _signatureController.clear(),
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
