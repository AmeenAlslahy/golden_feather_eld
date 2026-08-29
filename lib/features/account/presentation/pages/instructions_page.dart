import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class InstructionsPage extends StatelessWidget {
  const InstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final brightness = Theme.of(context).brightness;
    final bgColor = AppColors.backgroundForBrightness(brightness);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surfaceLight),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isArabic ? 'التعليمات' : 'Instructions',
          style: const TextStyle(
            fontSize: AppTypography.headerSize,
            fontWeight: AppTypography.bold,
            color: AppColors.surfaceLight,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Section 1: Inspection Mode
          _buildInspectionModeSection(isArabic, brightness),
          
          // Section 2: Send Logs
          _buildSendLogsSection(isArabic, brightness),
          
          // Section 3: Malfunction Manual
          _buildMalfunctionManualSection(isArabic, brightness),
        ],
      ),
    );
  }

  Widget _buildInspectionModeSection(bool isArabic, Brightness brightness) {
    // Dark background for this section as per design
    final sectionColor = brightness == Brightness.light ? const Color(0xFF333A45) : const Color(0xFF1E242C);
    final textColor = Colors.white;

    return Container(
      color: sectionColor,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder for the Phone Image
          Expanded(
            flex: 4,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.smartphone, size: 64, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Text Content
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'وضع التفتيش لـ TOP COMPLIANCE ELD' : 'TOP COMPLIANCE ELD Inspection Mode',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _buildChecklistItem(
                  text: isArabic
                      ? 'اضغط "وضع التفتيش" في القائمة واضغط "بدء التفتيش". دع الضابط يعرض السجلات من جهازك. اعرض بطاقة التعليمات هذه إذا طلب.'
                      : 'Tap "DOT Inspection" in the menu & press "Start Inspection". Let an officer to view your logs directly from your mobile device. Show this instruction card if requested.',
                  textColor: textColor,
                  iconColor: Colors.white,
                ),
                _buildChecklistItem(
                  text: isArabic
                      ? 'يمكن للمفتش الضغط على الأسهم لعرض السجلات السابقة أو التالية.'
                      : 'An inspector may press arrows to view previous or next day\'s logs.',
                  textColor: textColor,
                  iconColor: Colors.white,
                ),
                _buildChecklistItem(
                  text: isArabic
                      ? 'يمكن للمفتش عرض نموذج السجل، المخطط الشبكي، والأحداث مع الملاحظات.'
                      : 'An inspector may view the log form, the log graph and the log events with notes.',
                  textColor: textColor,
                  iconColor: Colors.white,
                ),
                _buildChecklistItem(
                  text: isArabic
                      ? 'اخرج من وضع التفتيش بالضغط على سهم العودة في الزاوية العلوية.'
                      : 'Exit the inspection mode by pressing back arrow in the left top corner of the app.',
                  textColor: textColor,
                  iconColor: Colors.white,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSendLogsSection(bool isArabic, Brightness brightness) {
    final sectionColor = AppColors.surfaceForBrightness(brightness);
    final textColor = AppColors.textPrimaryForBrightness(brightness);
    final textSecondaryColor = AppColors.textSecondaryForBrightness(brightness);

    return Container(
      color: sectionColor,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.xl),
      child: Row(
        children: [
          // Empty space to align with the text above
          Expanded(flex: 4, child: const SizedBox()),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'إرسال السجلات' : 'Send Logs',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  isArabic
                      ? 'جهاز TOP COMPLIANCE ELD قادر على إنتاج ونقل سجلات ELD عبر طرق النقل التليماتية: الويب اللاسلكي والبريد الإلكتروني. لإرسال السجلات عبر الويب، اضغط زر "DOT Inspection" ثم "Send Logs". لإرسالها عبر البريد، اختر "Email Logs" وأدخل البريد.'
                      : 'TOP COMPLIANCE ELD is capable of producing and transferring the ELD records via telematics transfer methods: Wireless Web services and Email. In order to send the ELD records via Web services a driver must press "DOT Inspection" menu item and then press "Send Logs" button. In order to send the ELD records via Email a driver must press "DOT Inspection" menu item, press "Email Logs", enter an email provided by an authorized safety official and press "Send" button.',
                  style: TextStyle(fontSize: 10, color: textSecondaryColor, height: 1.5),
                ),
                const SizedBox(height: AppSpacing.xl),
                _buildContactInfo(isArabic, textSecondaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMalfunctionManualSection(bool isArabic, Brightness brightness) {
    // Light gray background
    final sectionColor = brightness == Brightness.light ? const Color(0xFFF7F7F7) : const Color(0xFF1C1C1E);
    final textColor = AppColors.textPrimaryForBrightness(brightness);
    final textSecondaryColor = AppColors.textSecondaryForBrightness(brightness);

    return Container(
      color: sectionColor,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Placeholder for Hardware Image
          Expanded(
            flex: 4,
            child: Column(
              children: [
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Center(child: Icon(Icons.router, color: Colors.white, size: 48)),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildSmallHardwarePlaceholder(),
                    _buildSmallHardwarePlaceholder(),
                    _buildSmallHardwarePlaceholder(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          // Text Content
          Expanded(
            flex: 6,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic ? 'دليل الأعطال لـ TOP COMPLIANCE ELD' : 'TOP COMPLIANCE ELD Malfunction Manual',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor, height: 1.2),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isArabic ? 'وفقاً للإرشادات المحددة في 395.34' : 'In accordance with the guidelines set forth in 395.34',
                  style: TextStyle(fontSize: 11, color: textSecondaryColor),
                ),
                const SizedBox(height: AppSpacing.md),
                
                _buildSquareChecklistItem(
                  title: isArabic ? 'مؤشر العطل' : 'Malfunction indication',
                  desc: isArabic
                      ? 'اتصل بالدعم فوراً إذا انطفأ ضوء LED عند التوصيل بالمركبة أو إذا أبلغ التطبيق عن عطل.'
                      : 'Immediately contact the support if LED light on the device is off when the device is plugged into the diagnostic port or if the malfunction reported by the app.',
                  textColor: textColor,
                  secondaryColor: textSecondaryColor,
                ),
                _buildSquareChecklistItem(
                  title: isArabic ? 'تسجيل العطل' : 'Note the malfunction',
                  desc: isArabic
                      ? 'سجل العطل وقدم إشعاراً خطياً لشركتك خلال 24 ساعة.'
                      : 'Note the malfunction and provide a written notice to your fleet within 24 hours.',
                  textColor: textColor,
                  secondaryColor: textSecondaryColor,
                ),
                _buildSquareChecklistItem(
                  title: isArabic ? 'التبديل للسجلات الورقية' : 'Switch to paper logs',
                  desc: isArabic
                      ? 'احتفظ بسجل ورقي لذلك اليوم وحتى يتم إصلاح الجهاز. في حال التفتيش، اعرض الأيام السبعة السابقة من التطبيق.'
                      : 'Keep a paper log for that day and until the device is repaired or replaced. In the event of an inspection, display the previous 7 days from the app.',
                  textColor: textColor,
                  secondaryColor: textSecondaryColor,
                ),
                _buildSquareChecklistItem(
                  title: isArabic ? 'قاعدة 8 أيام' : '8 days rule',
                  desc: isArabic
                      ? 'في حال عطل ELD، يجب على الشركة اتخاذ إجراءات لإصلاح العطل خلال 8 أيام من اكتشافه.'
                      : 'In the event of an ELD malfunction, the motor carrier must take actions to correct the malfunction within 8 days of discovery.',
                  textColor: textColor,
                  secondaryColor: textSecondaryColor,
                ),
                
                const SizedBox(height: AppSpacing.xl),
                _buildContactInfo(isArabic, textSecondaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({required String text, required Color textColor, required Color iconColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, size: 14, color: iconColor),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 10, color: textColor, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareChecklistItem({required String title, required String desc, required Color textColor, required Color secondaryColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 14,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.black54, // Matches the dark grey square checkmark in design
              borderRadius: BorderRadius.circular(2),
            ),
            child: const Icon(Icons.check, size: 12, color: Colors.white),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
                Text(desc, style: TextStyle(fontSize: 10, color: secondaryColor, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfo(bool isArabic, Color secondaryColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'www.topceld.com',
          style: TextStyle(fontSize: 10, color: secondaryColor, fontWeight: FontWeight.bold),
        ),
        Text(
          isArabic ? 'تواصل مع الدعم عبر topceld@gmail.com' : 'Contact the support team at topceld@gmail.com',
          style: TextStyle(fontSize: 9, color: secondaryColor),
        ),
      ],
    );
  }

  Widget _buildSmallHardwarePlaceholder() {
    return Container(
      width: 24,
      height: 24,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.cable, size: 14, color: Colors.white),
    );
  }
}
