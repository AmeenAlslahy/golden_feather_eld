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
  void initState() {
    super.initState();
    _requestInitialData();
  }

  /// الجلب الأولي قرار الشاشة لا أثر جانبي في مُنشئ الـ notifier.
  void _requestInitialData() {
    ref
        .read(logDraftSignatureProvider(widget.selectedLog.id).notifier)
        .ensureLoaded();
    if (widget.selectedLog.isCertified) return;
    final logId = widget.selectedLog.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(certifyLogProvider(logId).notifier).checkReadiness();
    });
  }

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
      _requestInitialData();
    } else if (oldWidget.selectedLog.isCertified &&
        !widget.selectedLog.isCertified) {
      // أُعيد فتح السجل بعد تعديل يستوجب إعادة الاعتماد.
      _requestInitialData();
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
          case CertifyPending(:final message):
            // محفوظ للمزامنة فقط — ليس اعتمادًا مؤكدًا، ولا نغلق الشاشة.
            AppFeedback.warning(context, message);
          case CertifyFailed(:final message):
            AppFeedback.error(context, message);
        }
      }
    });

    final notifier = ref.read(
      certifyLogProvider(widget.selectedLog.id).notifier,
    );
    final state = ref.watch(certifyLogProvider(widget.selectedLog.id));

    if (widget.selectedLog.isCertified) {
      return _buildCertifiedView(context);
    }

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

    // لا نختلق LogReadiness محلياً: غيابها يعني أن الخادم لم يؤكد الجاهزية.
    final readinessData = state.readinessData;
    if (readinessData == null) {
      return _buildUnavailableView(context, notifier);
    }

    if (!state.isReady) {
      return _buildNotReadyView(
        context,
        notifier,
        readinessData,
        state.isLoading,
      );
    }

    return _buildReadyView(context, notifier, readinessData, state.isLoading);
  }

  Widget _buildCertifiedView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: AppSpacing.iconHero,
              color: context.success,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              context.loc.certified,
              textAlign: TextAlign.center,
              style: context.styles.pageTitle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnavailableView(
    BuildContext context,
    CertifyLogNotifier notifier,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
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
              context.loc.notReadyForCertification,
              textAlign: TextAlign.center,
              style: context.styles.pageTitle,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: context.loc.retryButton,
              onPressed: notifier.checkReadiness,
            ),
          ],
        ),
      ),
    );
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
          AppButton(
            label: context.loc.clearSignature,
            type: EldButtonType.secondary,
            // زر مسح التوقيع — لا يغيّر الجاهزية ولا يبدّل التبويب.
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
              label: context.loc.clearSignature,
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
