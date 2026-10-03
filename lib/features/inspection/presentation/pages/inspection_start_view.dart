import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../routes.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/extensions/context_extensions.dart';
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

/// عرض البداية: الإرشاد + الصلاحيات الأربع من الخادم (fail-closed).
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
        enabled: screen?.canStartInspection ?? false,
        disabledMessage: loc.serverDoesNotAllow,
        onPressed: onStartInspection,
      ),
      InspectionSectionData(
        title: loc.sendLogsFor24,
        description: loc.sendLogsToOfficer,
        buttonLabel: loc.sendLogsUpper,
        enabled: screen?.canSendLogs ?? false,
        disabledMessage: loc.notAllowedByServer,
        onPressed: () => _push(context, const SendLogsPage()),
      ),
      InspectionSectionData(
        title: loc.emailLogs24Pdf,
        description: loc.emailLogsPdf,
        buttonLabel: loc.emailLogsUpper,
        enabled: screen?.canEmailLogs ?? false,
        disabledMessage: loc.notAllowedByServer,
        onPressed: () => _push(context, const SendLogsPage(isEmailMode: true)),
      ),
      InspectionSectionData(
        title: text(screen?.carrierComplianceStatement, loc.eldCertifies),
        buttonLabel: loc.infoPacketUpper,
        enabled: screen?.canViewInformationPacket ?? false,
        disabledMessage: loc.notAllowedByServer,
        onPressed: () => context.push(AppRoutes.infoPacket),
      ),
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        if (error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: context.styles.error,
            ),
          ),
        if (screenAsync.hasError)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
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
        const SizedBox(height: 32),
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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      child: Column(
        children: [
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: context.styles.body,
          ),
          if (data.description != null) ...[
            const SizedBox(height: 8),
            Text(
              data.description!,
              textAlign: TextAlign.center,
              style: context.styles.muted,
            ),
          ],
          const SizedBox(height: 16),
          AppButton(
            label: data.buttonLabel,
            type: EldButtonType.dark,
            onPressed: data.enabled ? data.onPressed : null,
          ),
          if (!data.enabled && data.disabledMessage != null) ...[
            const SizedBox(height: 8),
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
