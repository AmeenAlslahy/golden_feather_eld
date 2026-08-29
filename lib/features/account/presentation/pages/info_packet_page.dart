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

// ========== محتوى دليل المستخدم ==========
List<ManualSection> _getUserManualContent(BuildContext context) {
  final loc = context.loc;
  final isArabic = Localizations.localeOf(context).languageCode == 'ar';
  return [
    ManualSection(
      title: '١. ${loc.gettingStarted}',
      steps: [
        isArabic
            ? 'افتح تطبيق Golden Feather ELD على هاتفك.'
            : 'Open the Golden Feather ELD app on your phone.',
        isArabic
            ? 'امنح الصلاحيات المطلوبة: الموقع، البلوتوث، والإشعارات.'
            : 'Grant required permissions: Location, Bluetooth, and Notifications.',
        isArabic
            ? 'سجل الدخول باستخدام اسم المستخدم وكلمة المرور الخاصة بك.'
            : 'Log in using your username and password.',
        isArabic
            ? 'إذا لم يكن لديك حساب، اضغط على "إنشاء حساب" وأنشئ حساباً جديداً.'
            : 'If you don\'t have an account, tap "Create Account" and register.',
      ],
    ),
    ManualSection(
      title: '٢. ${loc.connectingToVehicle}',
      steps: [
        isArabic
            ? 'تأكد من تشغيل المركبة وتركيب جهاز ELD في منفذ التشخيص.'
            : 'Ensure the vehicle is running and the ELD device is plugged into the diagnostic port.',
        isArabic
            ? 'أدخل عنوان MAC الخاص بجهاز ELD (موجود على ملصق الجهاز).'
            : 'Enter the MAC address of your ELD device (found on the device label).',
        isArabic
            ? 'اضغط على "اتصال" وانتظر حتى يظهر الاتصال ناجحاً.'
            : 'Tap "Connect" and wait for the connection to be established.',
        isArabic
            ? 'اختر مركبتك من القائمة. إذا لم تظهر، اتصل بمدير الأسطول.'
            : 'Select your vehicle from the list. If not listed, contact your fleet manager.',
      ],
    ),
    ManualSection(
      title: '٣. ${loc.changingDutyStatus}',
      steps: [
        isArabic
            ? 'من الشاشة الرئيسية، اضغط على العداد الدائري.'
            : 'From the main dashboard, tap the circular timer.',
        isArabic
            ? 'اختر الحالة المناسبة: قيادة، في الخدمة، خارج الخدمة، أو نوم.'
            : 'Select the appropriate status: Driving, On Duty, Off Duty, or Sleeper Berth.',
        isArabic
            ? 'سيتم تغيير الحالة تلقائياً إلى "قيادة" عندما تتحرك المركبة بسرعة > 8 كم/س.'
            : 'Status will automatically change to "Driving" when the vehicle moves > 5 mph.',
      ],
    ),
    ManualSection(
      title: '٤. ${loc.viewingLogs}',
      steps: [
        isArabic
            ? 'من القائمة الجانبية، اختر "السجلات".'
            : 'From the side menu, select "Logs".',
        isArabic
            ? 'اختر اليوم المطلوب لعرض التفاصيل.'
            : 'Select the desired day to view details.',
        isArabic
            ? 'في نهاية اليوم، اذهب إلى تبويب "Certify" ووقع على السجل.'
            : 'At the end of the day, go to the "Certify" tab and sign the log.',
        isArabic
            ? 'اضغط على "AGREE" للتصديق على صحة البيانات.'
            : 'Tap "AGREE" to certify the accuracy of the data.',
      ],
    ),
    ManualSection(
      title: '٥. ${loc.vehicleInspection}',
      steps: [
        isArabic
            ? 'من القائمة الجانبية، اختر "DVIR".'
            : 'From the side menu, select "DVIR".',
        isArabic
            ? 'اضغط على "+" لإنشاء تقرير فحص جديد.'
            : 'Tap "+" to create a new inspection report.',
        isArabic
            ? 'افحص جميع الأجزاء المطلوبة وسجل أي أعطال.'
            : 'Inspect all required parts and record any defects.',
        isArabic
            ? 'وقع على التقرير واضغط "حفظ".'
            : 'Sign the report and tap "Save".',
      ],
    ),
    ManualSection(
      title: '٦. ${loc.roadsideInspection}',
      steps: [
        isArabic
            ? 'من القائمة الجانبية، اختر "التفتيش".'
            : 'From the side menu, select "Inspection".',
        isArabic
            ? 'اضغط "START INSPECTION" وأدخل رمز PIN.'
            : 'Tap "START INSPECTION" and enter a PIN code.',
        isArabic
            ? 'سلم الهاتف للمفتش لمراجعة السجلات.'
            : 'Hand the phone to the officer to review the logs.',
        isArabic
            ? 'بعد الانتهاء، أدخل PIN واضغط "END INSPECTION".'
            : 'When finished, enter the PIN and tap "END INSPECTION".',
      ],
    ),
  ];
}

// ========== محتوى التعليمات ==========
List<ManualSection> _getInstructionsContent(bool isArabic) {
  return [
    ManualSection(
      title: isArabic ? 'تعليمات السجلات الورقية الاحتياطية' : 'Paper Log Backup Instructions',
      steps: [
        isArabic
            ? 'في حالة تعطل جهاز ELD، يجب عليك التبديل إلى السجلات الورقية فوراً.'
            : 'In case of ELD malfunction, you must switch to paper logs immediately.',
        isArabic
            ? 'يجب أن تحتفظ بنماذج سجلات ورقية فارغة (RODS) في المركبة لمدة 8 أيام على الأقل.'
            : 'You must keep blank paper log forms (RODS) in the vehicle for at least 8 days.',
        isArabic
            ? 'قم بتسجيل جميع تغييرات الحالة يدوياً: الوقت، الحالة، والموقع.'
            : 'Record all status changes manually: time, status, and location.',
        isArabic
            ? 'يجب إصلاح جهاز ELD خلال 8 أيام من حدوث العطل.'
            : 'The ELD device must be repaired within 8 days of the malfunction.',
        isArabic
            ? 'بعد إصلاح الجهاز، قم بنقل جميع بيانات السجلات الورقية إلى نظام ELD.'
            : 'After repairing the device, transfer all paper log data to the ELD system.',
        isArabic
            ? 'احتفظ بالسجلات الورقية لمدة 6 أشهر على الأقل.'
            : 'Keep paper logs for at least 6 months.',
      ],
    ),
    ManualSection(
      title: isArabic ? 'كيفية تعبئة السجل الورقي' : 'How to Fill Paper Logs',
      steps: [
        isArabic ? 'اكتب التاريخ واسم السائق ورقم المركبة في أعلى النموذج.' : 'Write the date, driver name, and vehicle number at the top of the form.',
        isArabic ? 'ارسم خطاً أفقياً لكل حالة: قيادة (أعلى)، خدمة (ثاني)، نوم (ثالث)، خارج الخدمة (أسفل).' : 'Draw a horizontal line for each status: Driving (top), On Duty (second), Sleeper (third), Off Duty (bottom).',
        isArabic ? 'سجل الوقت والموقع عند كل تغيير حالة.' : 'Record the time and location at each status change.',
        isArabic ? 'وقع على السجل في نهاية اليوم.' : 'Sign the log at the end of the day.',
      ],
    ),
  ];
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
