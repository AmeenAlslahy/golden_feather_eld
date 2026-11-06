import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_feather_eld/routes/app_routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/network/core_providers.dart';
import '../providers/dot_inspection_providers.dart';
import '../providers/inspection_provider.dart';
import 'send_logs_page.dart';

/// سياسة عرض نصوص التوجيه (SRS 8.1): نصوص الخادم إنجليزية فقط — في
/// العربية تُعرض الترجمة المحلية، وفي الإنجليزية نص الخادم إن وُجد
/// وإلا الترجمة المحلية. دالة صرفة قابلة للاختبار بلا widget.
String inspectionDisplayText({
  required bool isArabic,
  required String? serverText,
  required String localFallback,
}) {
  final value = serverText?.trim() ?? '';
  return (isArabic || value.isEmpty) ? localFallback : value;
}

/// هل تفتح البوابة، وبأي شرط؟
///
/// قُصِدت لتكون **نقية وقابلة للاختبار بلا widget** — لأن كل قرار تمكين
/// في شاشة الأمان يُستحق أن يكون قابلاً للتدقيق بسطر واحد.
///
/// | الخادم | الشبكة | القرار |
/// |---|---|---|
/// | أجاب | — | **fail-closed**: تُطاع إlagsه حرفياً |
/// | لم يجب بعد | متصل | **fail-closed**: لسنا نسأل بعد، لا نخمّن |
/// | لم يجب | **غير متصل** | **fail-open**: لا انتظار لِما لا يأتي |
///
/// ❌ الحالة الثالثة كانت تُجمّد الأزرار الأربعة على **إقلاع بارد بلا
/// إنترنت**: `getScreen` قراءة شبكة، و`_screenFallback` يُرجع `Left` لأن
/// كاشه في الذاكرة فقط فيُفقد عند إعادة التشغيل. فلمبتش المفتّش يدرك أن
/// جهازه معطّل، مع أن كل ما خلف البوابة يعمل بلا شبكة — بدء التفتيش
/// محلي والتسجيل `unawaited`، وإرسال السجلات يولّد ملف 395 محلياً
/// ويصفّه في الطابور.
///
/// الأمان لم يُضعَف: الخادم يبقى المرجع النهائي عند المزامنة، ورفضه
/// أصبح `RejectedFailure` نهائياً (dead-letter) لا إعادة محاولة لا نهائية.
class InspectionCapabilityGate {
  const InspectionCapabilityGate({
    required this.serverAnswered,
    required this.isOnline,
  });

  /// هل ردّ الخادم ببياناتScreen فعلاً (وليس خطأ ولا null)؟
  final bool serverAnswered;

  final bool isOnline;

  /// بلا خادم وبلا شبكة ⇒ لا فائدة من الانتظار.
  bool get offlineWithoutServerAnswer => !serverAnswered && !isOnline;

  /// تُفتح البوابة إما بجواب الخادم أو لغيابه.Network مع انقطاع.
  bool get isOpen => serverAnswered || offlineWithoutServerAnswer;

  bool isEnabled({required bool serverFlag}) =>
      isOpen && (offlineWithoutServerAnswer || serverFlag);

  /// رسالة الرفض تُعرض فقط حين **رفض الخادم فعلاً** — لا حين تعذّر
  /// الوصول إليه، حتى لا نُتهم الخادم برفض لم يُصدر.
  String? denial({required bool serverFlag, required String message}) {
    if (offlineWithoutServerAnswer) return null;
    if (!serverAnswered) return null;
    return serverFlag ? null : message;
  }
}

/// عرض البداية: الإرشاد + الصلاحيات الأربع من الخادم.
///
/// كل القرارات (الصلاحيات، سياسة النصوص، الإيقاف) محسوبة مرة واحدة هنا؛
/// الأقسام نفسها بيانات تُرسم بـ [InspectionActionSection] الأعمى.
class InspectionStartView extends ConsumerWidget {
  const InspectionStartView({super.key, required this.onStartInspection});

  /// بوابة الدخول: حوار PIN ثم startInspection — يملكها الصفحة الأم.
  final VoidCallback onStartInspection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenAsync = ref.watch(dotInspectionScreenProvider);
    final screen = screenAsync.asData?.value;
    final isOnline = ref.watch(
      networkInfoProvider.select((n) => n.isConnected),
    );

    final gate = InspectionCapabilityGate(
      serverAnswered: screen != null,
      isOnline: isOnline,
    );

    bool enabled(bool serverFlag) => gate.isEnabled(serverFlag: serverFlag);
    String? denial(bool serverFlag, String message) =>
        gate.denial(serverFlag: serverFlag, message: message);
    final error = ref.watch(inspectionProvider.select((s) => s.error));
    final loc = context.loc;
    final isArabic = context.isArabic;

    String text(String? serverText, String localFallback) =>
        inspectionDisplayText(
          isArabic: isArabic,
          serverText: serverText,
          localFallback: localFallback,
        );

    final sections = [
      InspectionSectionData(
        title: text(screen?.guidanceText, loc.inspectLogs24),
        description: text(screen?.handOverDeviceNotice, loc.setPinGuidance),
        buttonLabel: loc.startInspectionUpper,
        enabled: enabled(screen?.canStartInspection ?? false),
        disabledMessage: denial(
          screen?.canStartInspection ?? false,
          loc.serverDoesNotAllow,
        ),
        onPressed: onStartInspection,
      ),
      InspectionSectionData(
        title: loc.sendLogsFor24,
        description: loc.sendLogsToOfficer,
        buttonLabel: loc.sendLogsUpper,
        enabled: enabled(screen?.canSendLogs ?? false),
        disabledMessage: denial(
          screen?.canSendLogs ?? false,
          loc.notAllowedByServer,
        ),
        onPressed: () => _push(context, const SendLogsPage()),
      ),
      InspectionSectionData(
        title: loc.emailLogs24Pdf,
        description: loc.emailLogsPdf,
        buttonLabel: loc.emailLogsUpper,
        enabled: enabled(screen?.canEmailLogs ?? false),
        disabledMessage: denial(
          screen?.canEmailLogs ?? false,
          loc.notAllowedByServer,
        ),
        onPressed: () => _push(context, const SendLogsPage(isEmailMode: true)),
      ),
      InspectionSectionData(
        title: text(screen?.carrierComplianceStatement, loc.eldCertifies),
        buttonLabel: loc.infoPacketUpper,
        enabled: enabled(screen?.canViewInformationPacket ?? false),
        disabledMessage: denial(
          screen?.canViewInformationPacket ?? false,
          loc.notAllowedByServer,
        ),
        onPressed: () => context.push(AppRoutes.infoPacket),
      ),
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (screenAsync.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
            child: LinearProgressIndicator(minHeight: 2),
          ),
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.md,
            ),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: context.styles.error,
            ),
          ),
        // ⚠️ بلا خادم وبلا شبكة: نُعلم السائق بأن الصلاحيات لم تُتحقّق منها،
        // بدل إظهار «فشل الطلب» + إعادة محاولة لن تنجح.
        //
        // ❌ «فشل الطلب» كانت تُعرض أيضاً عند انقطاع الشبكة، فيُفهم أن
        // الخادم معطّل — بينما هو سليم والإقرار هو ما تعذّر.
        if (gate.offlineWithoutServerAnswer)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                Text(
                  loc.offlineMode,
                  textAlign: TextAlign.center,
                  style: context.styles.subtitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  loc.weakConnectionDelayedData,
                  textAlign: TextAlign.center,
                  style: context.styles.subtitle,
                ),
              ],
            ),
          )
        // الخادم متصل ولم يجب بعد ⇒ جلبٌ جارٍ، لا خطأ.
        else if (screenAsync.hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.md,
              AppSpacing.screenPadding,
              AppSpacing.sm,
            ),
            child: Column(
              children: [
                Text(
                  context.loc.errRequestFailed,
                  textAlign: TextAlign.center,
                  style: context.styles.error,
                ),
                TextButton(
                  onPressed: () => ref.invalidate(dotInspectionScreenProvider),
                  child: Text(context.loc.retryAction),
                ),
              ],
            ),
          ),
        for (final (i, section) in sections.indexed) ...[
          if (i > 0) const Divider(height: 1, thickness: 1),
          InspectionActionSection(data: section),
        ],
        const SizedBox(height: AppSpacing.sectionGap),
      ],
    );
  }
}

void _push(BuildContext context, Widget page) {
  Navigator.push(context, MaterialPageRoute(builder: (_) => page));
}

/// قسم إجراء واحد: عنوان + وصف اختياري + زر + رسالة رفض عند التعطيل.
class InspectionActionSection extends StatelessWidget {
  const InspectionActionSection({super.key, required this.data});

  final InspectionSectionData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sectionGap,
      ),
      child: Column(
        children: [
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: context.styles.body,
          ),
          if (data.description != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              data.description!,
              textAlign: TextAlign.center,
              style: context.styles.muted,
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: data.buttonLabel,
            type: EldButtonType.primary,
            onPressed: data.enabled ? data.onPressed : null,
          ),
          if (!data.enabled && data.disabledMessage != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              data.disabledMessage!,
              textAlign: TextAlign.center,
              style: context.styles.muted,
            ),
          ],
        ],
      ),
    );
  }
}

/// بيانات قسم الإجراء — مجرد قيم، بلا أي منطق.
class InspectionSectionData {
  const InspectionSectionData({
    required this.title,
    required this.buttonLabel,
    required this.enabled,
    required this.onPressed,
    this.description,
    this.disabledMessage,
  });

  final String title;
  final String? description;
  final String buttonLabel;
  final bool enabled;
  final VoidCallback onPressed;
  final String? disabledMessage;
}
