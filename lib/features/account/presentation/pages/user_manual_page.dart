import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class UserManualPage extends StatelessWidget {
  const UserManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final brightness = Theme.of(context).brightness;
    final bgColor = AppColors.backgroundFor(brightness);
    final surfaceColor = AppColors.surfaceFor(brightness);
    final textColor = AppColors.textPrimaryFor(brightness);
    final textSecondaryColor = AppColors.textSecondaryFor(brightness);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isArabic ? 'دليل المستخدم' : 'ELD User Manual',
          style: const TextStyle(
            fontSize: AppTypography.headerSize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(isArabic, surfaceColor, textColor, textSecondaryColor),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle(
              isArabic ? 'الميزات' : 'Features', textColor, context),
          _buildFeaturesSection(
              isArabic, surfaceColor, textColor, textSecondaryColor),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle(
              isArabic ? 'التثبيت والإعداد' : 'Installation and Setup',
              textColor,
              context),
          _buildInstallationSection(
              isArabic, surfaceColor, textColor, textSecondaryColor),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle(isArabic ? 'إدارة السجلات' : 'Log Management',
              textColor, context),
          _buildLogManagementSection(
              isArabic, surfaceColor, textColor, textSecondaryColor),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle(isArabic ? 'تفتيش الطريق' : 'Roadside Inspections',
              textColor, context),
          _buildRoadsideSection(
              isArabic, surfaceColor, textColor, textSecondaryColor),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle(
              isArabic
                  ? 'تقارير فحص المركبة (DVIR)'
                  : 'Electronic Driver Vehicle Inspection Reports (DVIR)',
              textColor,
              context),
          _buildDvirSection(
              isArabic, surfaceColor, textColor, textSecondaryColor),
          const SizedBox(height: AppSpacing.lg),
          _buildSectionTitle(
              isArabic ? 'بوابة مدير الأسطول' : 'Fleet Manager Portal',
              textColor,
              context),
          _buildFleetManagerSection(
              isArabic, surfaceColor, textColor, textSecondaryColor),
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
      String title, Color textColor, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Divider(color: Colors.white.withValues(alpha: 0.2), thickness: 1),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isArabic, Color surfaceColor, Color textColor,
      Color secondaryColor) {
    return Container(
      color: surfaceColor,
      height: 250,
      child: Row(
        children: [
          // Placeholder for the Truck Image
          Expanded(
            flex: 4,
            child: Container(
              margin: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.local_shipping, size: 64, color: Colors.grey),
              ),
            ),
          ),
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.only(
                  right: AppSpacing.md,
                  top: AppSpacing.xl,
                  bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isArabic ? 'دليل المستخدم' : 'User Manual',
                    style: TextStyle(
                        fontSize: 12,
                        color: secondaryColor,
                        fontWeight: FontWeight.bold),
                  ),
                  const Divider(),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'TOP COMPLIANCE ELD',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: textColor),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      isArabic
                          ? 'جهاز التسجيل الإلكتروني (ELD)'
                          : 'Electronic Logging Device (ELD)',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection(bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor) {
    final features = [
      {
        'title': isArabic ? 'سجلات حالة الخدمة' : 'Records of\nDuty Status',
        'desc': isArabic
            ? 'إدارة الحالات بسهولة مع إمكانية عرض، وتعديل، وتوقيع السجلات بدقة.'
            : 'Easily manage your duty status changes with our user-friendly ELD app. View, edit, and certify your logs.'
      },
      {
        'title': isArabic
            ? 'الساعات المتاحة\nوالفترات المطلوبة'
            : 'Available Hours and\nRequired Breaks',
        'desc': isArabic
            ? 'ابقَ على اطلاع بساعات القيادة المتاحة وفترات الراحة الإلزامية لضمان الامتثال.'
            : 'Stay informed about your available driving hours and mandatory rest breaks to ensure compliance.'
      },
      {
        'title': isArabic ? 'تفتيش الطريق' : 'Roadside Inspection\nFunction',
        'desc': isArabic
            ? 'أثناء التفتيش الأمني، استخدم وضع التفتيش (DOT) في التطبيق لمشاركة السجلات بسهولة.'
            : 'During roadside inspections, use the DOT Inspection mode in the app to share your logs with ease.'
      },
      {
        'title':
            isArabic ? 'تقارير فحص المركبة' : 'Vehicle Inspection\nReports',
        'desc': isArabic
            ? 'أنشئ تقارير DVIR قبل أو بعد الرحلة لإشعار الميكانيكيين بأي أعطال فوراً.'
            : 'Generate pre- or post-trip DVIRs within the app, notifying mechanics of any vehicle defects.'
      },
    ];

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: features
            .map((f) => _buildListRow(
                f['title']!, f['desc']!, textColor, secondaryColor))
            .toList(),
      ),
    );
  }

  Widget _buildFleetManagerSection(bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor) {
    final features = [
      {
        'title': isArabic ? 'إعداد البوابة' : 'Set Up Fleet\nManager Portal',
        'desc': isArabic
            ? 'استخدم بيانات الدخول للوصول إلى البوابة وتوفير معلومات شركتك والسائقين.'
            : 'Use your credentials to sign into the online portal, providing essential information about your company.'
      },
      {
        'title':
            isArabic ? 'مراقبة الامتثال' : 'Monitor HOS and\nFMCSA-Compliance',
        'desc': isArabic
            ? 'تتبع حالة السائقين وساعاتهم المتبقية في الوقت الفعلي واستقبل التنبيهات.'
            : 'Stay on top of drivers\' duty status and remaining hours in real-time. Receive notifications.'
      },
    ];

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: features
            .map((f) => _buildListRow(
                f['title']!, f['desc']!, textColor, secondaryColor))
            .toList(),
      ),
    );
  }

  Widget _buildListRow(
      String title, String description, Color textColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: textColor),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              width: 6,
              height: 20,
              color: AppColors.primaryBlue,
            ),
            Expanded(
              flex: 6,
              child: Text(
                description,
                style: TextStyle(fontSize: 12, color: secondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallationSection(bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hardware Image Placeholder
          Expanded(
            flex: 3,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                  child: Icon(Icons.router, color: Colors.white, size: 48)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Instructions
          Expanded(
            flex: 7,
            child: _buildInfoCard(
              title: isArabic ? 'تثبيت الجهاز' : 'Install ELD Hardware',
              textColor: textColor,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic
                        ? 'ابدأ بتحديد موقع منفذ (ECM) في مركبتك. يتواجد عادة بالقرب من عجلة القيادة. بناءً على مركبتك استخدم الاتصال المناسب:'
                        : 'Begin by locating the ECM (diagnostic) port in your vehicle. Depending on your vehicle type, use the appropriate connection:',
                    style: TextStyle(fontSize: 12, color: secondaryColor),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                      '• 6-pin Connector\n• 9-pin Connector\n• OBDII Connector',
                      style: TextStyle(
                          fontSize: 12,
                          color: secondaryColor,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogManagementSection(bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Phone UI Placeholder
          Expanded(
            flex: 3,
            child: Container(
              height: 250,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: const Center(
                  child: Icon(Icons.smartphone, color: Colors.grey, size: 48)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 7,
            child: Column(
              children: [
                _buildInfoCard(
                  title: isArabic ? 'الوصول للسجلات' : 'Accessing Logs',
                  textColor: textColor,
                  content: Text(
                      isArabic
                          ? 'سجل الدخول وانتقل لقسم السجلات.'
                          : 'Log in and navigate to the "Logs" section.',
                      style: TextStyle(fontSize: 11, color: secondaryColor)),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoCard(
                  title: isArabic ? 'عرض السجلات' : 'Viewing Logs',
                  textColor: textColor,
                  content: Text(
                      isArabic
                          ? 'شاهد التفاصيل اليومية لكل تغيير حالة.'
                          : 'View detailed RODS for different dates.',
                      style: TextStyle(fontSize: 11, color: secondaryColor)),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoCard(
                  title: isArabic ? 'تعديل السجلات' : 'Editing Logs',
                  textColor: textColor,
                  content: Text(
                      isArabic
                          ? 'عدّل الإدخالات (باستثناء وقت القيادة الآلي).'
                          : 'Edit duty status entries (except auto driving).',
                      style: TextStyle(fontSize: 11, color: secondaryColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadsideSection(bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildInfoCard(
              title: isArabic ? 'تفتيش DOT' : 'DOT Inspection',
              textColor: textColor,
              content: Text(
                isArabic
                    ? '• اختر وضع التفتيش من القائمة.\n• اضغط "بدء التفتيش" لعرض السجلات.\n• استخدم الأسهم للتنقل.\n• شارك البيانات عند الطلب.'
                    : '• Access "DOT Inspection" mode.\n• Tap "Start Inspection".\n• Use arrows to review logs.\n• Send RODS via web/email.',
                style:
                    TextStyle(fontSize: 11, color: secondaryColor, height: 1.5),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildInfoCard(
              title: isArabic ? 'تنبيهات الامتثال' : 'HOS Compliance Alerts',
              textColor: textColor,
              content: Text(
                isArabic
                    ? '• راقب العلامة الحمراء التحذيرية.\n• راجع قائمة الانتهاكات أسفل المخطط لمعرفة التفاصيل.'
                    : '• Watch for the red exclamation icon.\n• Review a list of HOS violations below the log graph.',
                style:
                    TextStyle(fontSize: 11, color: secondaryColor, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDvirSection(bool isArabic, Color surfaceColor, Color textColor,
      Color secondaryColor) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildInfoCard(
              title: isArabic ? 'إنشاء فحص' : 'Create DVIR',
              textColor: textColor,
              content: Text(
                  isArabic
                      ? 'ابدأ فحصاً جديداً، حدد الأعطال إن وجدت، وضع الملاحظات ثم وقّع.'
                      : 'Start new inspection, mark defects, add notes, and sign.',
                  style: TextStyle(fontSize: 11, color: secondaryColor)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              children: [
                _buildInfoCard(
                  title: isArabic ? 'تعديل الفحص' : 'Edit DVIR',
                  textColor: textColor,
                  content: Text(
                      isArabic
                          ? 'اختر فحصاً سابقاً للتعديل.'
                          : 'Select an existing report to edit.',
                      style: TextStyle(fontSize: 11, color: secondaryColor)),
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildInfoCard(
                  title: isArabic ? 'حذف الفحص' : 'Delete DVIR',
                  textColor: textColor,
                  content: Text(
                      isArabic
                          ? 'احذف التقرير من قائمة السجل.'
                          : 'Remove the report from history.',
                      style: TextStyle(fontSize: 11, color: secondaryColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(
      {required String title,
      required Widget content,
      required Color textColor}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.bold, color: textColor)),
          const Divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 4, right: 6, left: 2),
                width: 4,
                height: 12,
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
              ),
              Expanded(child: content),
            ],
          ),
        ],
      ),
    );
  }
}
