import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import 'manual_detail_page.dart';
import 'instructions_page.dart';
import 'user_manual_page.dart';

/// شاشة الوثائق والمعلومات
class InfoPacketPage extends ConsumerWidget {
  const InfoPacketPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          loc.infoPacket,
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.surface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const EldDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ========== دليل المستخدم ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.menu_book, color: AppColors.primaryBlue, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.userManual,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc.userManual, // Fallback for secondary text or adjust if there is a specific one
                              style: const TextStyle(fontSize: AppTypography.smallSize, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const UserManualPage(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.darkButton),
                      child: Text(loc.viewUserManual),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ========== تعليمات السجلات الورقية ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.warningYellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.assignment, color: AppColors.warningYellow, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.instructions,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc.instructions,
                              style: const TextStyle(fontSize: AppTypography.smallSize, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const InstructionsPage(),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.darkButton),
                      child: Text(loc.viewInstructions),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // ========== دليل الأعطال ==========
            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.dangerRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.warning_amber, color: AppColors.dangerRed, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.malfunctionManual,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              loc.malfunctionManual,
                              style: const TextStyle(fontSize: AppTypography.smallSize, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ManualDetailPage(
                              title: loc.malfunctionManual,
                              content: _getMalfunctionManualContent(isArabic),
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(backgroundColor: AppColors.darkButton),
                      child: Text(loc.viewMalfunctionManual),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // ========== ملاحظة قانونية ==========
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                loc.legalNotice,
                style: const TextStyle(fontSize: AppTypography.captionSize, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// ========== محتوى دليل الأعطال ==========
List<ManualSection> _getMalfunctionManualContent(bool isArabic) {
  return [
    ManualSection(
      title: isArabic ? 'أنواع الأعطال' : 'Malfunction Types',
      steps: [
        isArabic ? 'فجوة بيانات (Data Gap): انقطاع في تسجيل البيانات لأكثر من 5 دقائق.' : 'Data Gap: Recording interruption for more than 5 minutes.',
        isArabic ? 'عطل تحديد المواقع (Positioning Malfunction): إحداثيات صفرية مع سرعة عالية.' : 'Positioning Malfunction: Zero coordinates at high speed.',
        isArabic ? 'عطل استشعار الحركة (Motion Sensor): تغير مفاجئ في السرعة > 80 كم/س.' : 'Motion Sensor Malfunction: Sudden speed change > 80 km/h.',
        isArabic ? 'عطل مزامنة المحرك (Engine Sync): المحرك يعمل > 60 دقيقة بدون حركة.' : 'Engine Sync Malfunction: Engine running > 60 min without motion.',
        isArabic ? 'قيادة غير محددة (Unidentified Drive): المركبة تتحرك بدون إشعال.' : 'Unidentified Drive: Vehicle moving without ignition.',
      ],
    ),
    ManualSection(
      title: isArabic ? 'خطوات استكشاف الأعطال' : 'Troubleshooting Steps',
      steps: [
        isArabic ? '١. تحقق من توصيل جهاز ELD بمنفذ التشخيص.' : '1. Check ELD device connection to diagnostic port.',
        isArabic ? '٢. أعد تشغيل المركبة وانتظر 30 ثانية.' : '2. Restart the vehicle and wait 30 seconds.',
        isArabic ? '٣. تحقق من تفعيل البلوتوث والـ GPS على هاتفك.' : '3. Check that Bluetooth and GPS are enabled on your phone.',
        isArabic ? '٤. حاول إعادة الاتصال من شاشة الاتصال.' : '4. Try reconnecting from the Connection screen.',
        isArabic ? '٥. إذا استمر العطل، انتقل إلى السجلات الورقية.' : '5. If malfunction persists, switch to paper logs.',
        isArabic ? '٦. اتصل بمدير الأسطول للإبلاغ عن العطل.' : '6. Contact your fleet manager to report the malfunction.',
      ],
    ),
    ManualSection(
      title: isArabic ? 'حدود زمنية مهمة' : 'Important Deadlines',
      steps: [
        isArabic ? 'يجب إصلاح الجهاز خلال 8 أيام من حدوث العطل.' : 'Device must be repaired within 8 days of malfunction.',
        isArabic ? 'لا يمكن القيادة بدون جهاز ELD عامل لأكثر من 8 أيام.' : 'Cannot drive without a working ELD for more than 8 days.',
        isArabic ? 'يجب توثيق جميع الأعطال في السجلات.' : 'All malfunctions must be documented in logs.',
      ],
    ),
  ];
}
