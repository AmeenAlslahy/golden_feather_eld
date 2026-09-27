import os

code = """import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class UserManualPage extends StatelessWidget {
  const UserManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final brightness = Theme.of(context).brightness;
    final surfaceColor = AppColors.surfaceFor(brightness);
    final textColor = AppColors.textPrimaryFor(brightness);
    final textSecondaryColor = AppColors.textSecondaryFor(brightness);

    return Scaffold(
      backgroundColor: brightness == Brightness.light ? const Color(0xFFF3F4F6) : AppColors.background,
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
        centerTitle: true,
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(isArabic, surfaceColor, textColor, textSecondaryColor, brightness),
          const SizedBox(height: AppSpacing.sm),
          _buildSectionTitle(
              isArabic ? 'الميزات' : 'Features', textColor),
          _buildFeaturesSection(
              isArabic, surfaceColor, textColor, textSecondaryColor, brightness),
          
          _buildSectionTitle(
              isArabic ? 'التثبيت والإعداد' : 'Installation and Setup',
              textColor),
          _buildInstallationSection(
              isArabic, surfaceColor, textColor, textSecondaryColor, brightness),
          
          _buildSectionTitle(isArabic ? 'إدارة السجلات' : 'Log Management',
              textColor),
          _buildLogManagementSection(
              isArabic, surfaceColor, textColor, textSecondaryColor, brightness),
          
          _buildSectionTitle(isArabic ? 'تفتيش الطريق' : 'Roadside Inspections',
              textColor),
          _buildRoadsideSection(
              isArabic, surfaceColor, textColor, textSecondaryColor, brightness),
          
          _buildSectionTitle(
              isArabic
                  ? 'تقارير فحص المركبة (DVIR)'
                  : 'Electronic Driver Vehicle Inspection Reports (DVIR)',
              textColor),
          _buildDvirSection(
              isArabic, surfaceColor, textColor, textSecondaryColor, brightness),
          
          _buildSectionTitle(
              isArabic ? 'بوابة مدير الأسطول' : 'Fleet Manager Portal',
              textColor),
          _buildFleetManagerSection(
              isArabic, surfaceColor, textColor, textSecondaryColor, brightness),
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: Colors.grey.shade400, thickness: 1, height: 1),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isArabic, Color surfaceColor, Color textColor,
      Color secondaryColor, Brightness brightness) {
    return Container(
      color: surfaceColor,
      constraints: const BoxConstraints(minHeight: 250),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    left: AppSpacing.md,
                    top: AppSpacing.xl,
                    bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Text(
                          isArabic ? 'دليل المستخدم' : 'User Manual',
                          style: TextStyle(
                              fontSize: 11,
                              color: textColor,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Divider(color: Colors.grey.shade400)),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Golden Feather ELD',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w400,
                          color: textColor),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: brightness == Brightness.light ? Colors.white : AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          if (brightness == Brightness.light)
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Text(
                        isArabic
                            ? 'جهاز التسجيل الإلكتروني (ELD)'
                            : 'Electronic Logging Device (ELD)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor, Brightness brightness) {
    final features = [
      {
        'title': isArabic ? 'سجلات حالة الخدمة' : 'Records of\\nDuty Status',
        'desc': isArabic
            ? 'إدارة الحالات بسهولة مع إمكانية عرض، وتعديل، وتوقيع السجلات بدقة.'
            : 'Easily manage your duty status changes with our user-friendly ELD app. View, edit, and certify your logs for accurate and compliant records.'
      },
      {
        'title': isArabic
            ? 'الساعات المتاحة\\nوالفترات المطلوبة'
            : 'Available Hours and\\nRequired Breaks',
        'desc': isArabic
            ? 'ابقَ على اطلاع بساعات القيادة المتاحة وفترات الراحة الإلزامية لضمان الامتثال.'
            : 'Stay informed about your available driving hours and mandatory rest breaks to ensure compliance with HOS regulations.'
      },
      {
        'title': isArabic ? 'قواعد HOS' : 'Inter- and Intrastate\\nHOS Rules',
        'desc': isArabic
            ? 'يدعم تطبيقنا قواعد القيادة بين الولايات وداخلها.'
            : 'Our app supports both inter- and intrastate HOS rules, providing you with the flexibility to comply with specific regulations.'
      },
      {
        'title': isArabic ? 'تفتيش الطريق' : 'Roadside Inspection\\nFunction',
        'desc': isArabic
            ? 'أثناء التفتيش الأمني، استخدم وضع التفتيش في التطبيق لمشاركة السجلات.'
            : 'During roadside inspections, use the DOT Inspection mode in the app to share your logs with ease.'
      },
      {
        'title':
            isArabic ? 'تقارير فحص المركبة' : 'Vehicle Inspection\\nReports',
        'desc': isArabic
            ? 'أنشئ تقارير DVIR قبل أو بعد الرحلة لإشعار الميكانيكيين بأي أعطال فوراً.'
            : 'Generate pre- or post-trip DVIRs within the app, notifying mechanics of any vehicle defects promptly.'
      },
      {
        'title':
            isArabic ? 'بوابة مدير الأسطول' : 'Online Fleet\\nManager Portal',
        'desc': isArabic
            ? 'الوصول لبوابة المدير لمراقبة الامتثال وعرض البيانات في الوقت الفعلي.'
            : 'Access the Fleet Manager Portal to monitor HOS compliance, view real-time data on driver duty status, and receive notifications on HOS violations.'
      },
      {
        'title': isArabic ? 'تتبع GPS' : 'GPS Tracking',
        'desc': isArabic
            ? 'تتبع موقع مركبتك في الوقت الفعلي لتحسين الإدارة والأمان.'
            : 'Track your vehicle\'s location in real-time for improved fleet management and security.'
      },
      {
        'title': isArabic ? 'حسابات IFTA' : 'IFTA Calculations',
        'desc': isArabic
            ? 'حساب بيانات IFTA آلياً لتبسيط تقارير ضرائب الوقود.'
            : 'Automatically calculate IFTA data to simplify fuel tax reporting for interstate carriers.'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: features
            .map((f) => _buildFeatureCard(
                f['title']!, f['desc']!, textColor, secondaryColor, brightness))
            .toList(),
      ),
    );
  }

  Widget _buildFleetManagerSection(bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor, Brightness brightness) {
    final features = [
      {
        'title': isArabic ? 'إعداد البوابة' : 'Set Up Fleet\\nManager Portal',
        'desc': isArabic
            ? 'استخدم بيانات الدخول للوصول إلى البوابة وتوفير معلومات شركتك والسائقين.'
            : 'Use your credentials to sign into the online portal, providing essential information about your company, portal users, drivers, and vehicles.'
      },
      {
        'title':
            isArabic ? 'مراقبة الامتثال' : 'Monitor HOS and\\nFMCSA-Compliance',
        'desc': isArabic
            ? 'تتبع حالة السائقين وساعاتهم المتبقية في الوقت الفعلي واستقبل التنبيهات.'
            : 'Stay on top of drivers\' duty status and remaining hours in real-time. Receive notifications about HOS violations and access archived violation records.'
      },
      {
        'title': isArabic ? 'حالات مسبقة الإعداد' : 'Preconfigured Statuses',
        'desc': isArabic
            ? 'تخصيص الوصول للحالات عبر تفعيل تحرك الساحة والاستخدام الشخصي كخيارات متاحة.'
            : 'Customize duty statuses access by setting Yard Move and Personal Use as valid options.'
      },
      {
        'title': isArabic ? 'معلومات السائق والمركبة' : 'Driver and Vehicle Information',
        'desc': isArabic
            ? 'تتبع موقع السائقين الحالي أو الأخير، المركبة، ومعلومات الاتصال بسهولة.'
            : 'Track your drivers\' current or last location, the vehicle driven, and their contact information effortlessly.'
      },
      {
        'title': isArabic ? 'تحميل ونقل السجلات' : 'Download and Transfer Logs',
        'desc': isArabic
            ? 'حمل أي سجل للسائقين بصيغة PDF بنقرات قليلة. في حال التفتيش يمكن إرسالها بسهولة للضابط.'
            : 'Download any drivers\' logs in PDF format with a few clicks. In case of a roadside inspection, easily send logs to an FMCSA officer from the online portal.'
      },
      {
        'title': isArabic ? 'تصفية السجلات' : 'Filter Logs',
        'desc': isArabic
            ? 'وفر الوقت بإيجاد السجلات بسرعة حسب التاريخ، السائق، أو المركبة باستخدام خيار التصفية.'
            : 'Save time by quickly finding logs by date, driver, or vehicle using the filter option.'
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: features
            .map((f) => _buildFeatureCard(
                f['title']!, f['desc']!, textColor, secondaryColor, brightness))
            .toList(),
      ),
    );
  }

  Widget _buildFeatureCard(String title, String description, Color textColor,
      Color secondaryColor, Brightness brightness) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: brightness == Brightness.light ? Colors.white : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (brightness == Brightness.light)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
        ],
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
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: textColor),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            width: 4,
            height: 24,
            color: AppColors.primaryBlue.withValues(alpha: 0.8),
          ),
          Expanded(
            flex: 7,
            child: Text(
              description,
              style: TextStyle(
                  fontSize: 9, color: secondaryColor, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationSection(bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hardware Image Placeholder
          Expanded(
            flex: 2,
            child: Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.grey.shade800,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Center(
                  child: Icon(Icons.router, color: Colors.white, size: 32)),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          // Instructions
          Expanded(
            flex: 8,
            child: Column(
              children: [
                _buildTabbedCard(
                  title: isArabic ? 'تثبيت الجهاز' : 'Install ELD Hardware',
                  textColor: textColor,
                  brightness: brightness,
                  content: Text(
                    isArabic
                        ? 'ابدأ بتحديد موقع منفذ (ECM) في مركبتك. يتواجد عادة بالقرب من عجلة القيادة. بناءً على مركبتك استخدم الاتصال المناسب:\n\n• وصلة 6-pin\n• وصلة 9-pin\n• وصلة OBDII\n\nبمجرد تحديد الوصلة، ركب الجهاز وثبته بإحكام.'
                        : 'Begin by locating the ECM (diagnostic) port in your vehicle. This port is typically found on or near the dashboard, under the steering column, or close to the driver\'s seat. Depending on your vehicle type, use the appropriate connection:\n\n• 6-pin Connector: Common in older commercial vehicles.\n• 9-pin Connector: Standard in most modern commercial trucks.\n• OBDII Connector: Typically found in light commercial vehicles and passenger cars.\n\nOnce you\'ve identified the correct connector, securely attach the ELD hardware to the port using the appropriate cable provided. Ensure the ELD device is firmly mounted on your dashboard where it remains visible and accessible for operation. This placement is crucial for ease of use during your driving and inspection processes.',
                    style: TextStyle(
                        fontSize: 9, color: secondaryColor, height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTabbedCard(
                  title: isArabic ? 'تثبيت البرنامج' : 'Install ELD Software',
                  textColor: textColor,
                  brightness: brightness,
                  content: Text(
                    isArabic
                        ? 'تأكد من أن جهازك متصل بالإنترنت والبلوتوث مفعل.\n\n• قم بتثبيت التطبيق.\n• سجل الدخول ببياناتك.\n• زامن الجهاز من خلال اختيار مركبتك من القائمة.'
                        : 'Before you start using the ELD, ensure that your mobile device is connected to the internet and Bluetooth is enabled:\n\n• Installing the ELD Software: Download the ELD app from your device\'s app store and follow the on-screen instructions to complete the installation.\n• Logging In: Use your provided credentials to access the app. If you encounter login issues, verify your credentials with your fleet manager or contact customer support.\n• Syncing Your Device with ELD Hardware: After logging in, select your vehicle from the list to sync your mobile device with the ELD hardware.',
                    style: TextStyle(
                        fontSize: 9, color: secondaryColor, height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTabbedCard(
                  title: isArabic ? 'ساعات الخدمة' : 'Hours of Service',
                  textColor: textColor,
                  brightness: brightness,
                  content: Text(
                    isArabic
                        ? 'بمجرد الإعداد، يسجل الجهاز وقت القيادة آلياً، ويحسب الساعات المتاحة وفترات الراحة.'
                        : 'Once the ELD is set up, it automatically records driving time. Any movement at 5 mph or faster is logged as driving. When stationary, the driver can select a different duty status. The system calculates and displays:\n\n• On-Duty Limits\n• Available Driving Time\n• Required Breaks and Off-Duty Periods\n\nThis information is shown in the app\'s Status section for drivers and in the online portal for fleet managers, ensuring compliance with HOS regulations.',
                    style: TextStyle(
                        fontSize: 9, color: secondaryColor, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogManagementSection(bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Phone UI Placeholder
              Expanded(
                flex: 3,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
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
                    _buildTabbedCard(
                      title: isArabic ? 'الوصول للسجلات' : 'Accessing Logs',
                      textColor: textColor,
                      brightness: brightness,
                      content: Text(
                          isArabic
                              ? 'سجل الدخول وانتقل لقسم "السجلات" للوصول للبيانات.'
                              : 'Log in to the ELD app with your unique credentials and navigate to the "Logs" section to access your electronic HOS records.',
                          style: TextStyle(fontSize: 9, color: secondaryColor)),
                    ),
                    const SizedBox(height: 12),
                    _buildTabbedCard(
                      title: isArabic ? 'عرض السجلات' : 'Viewing Logs',
                      textColor: textColor,
                      brightness: brightness,
                      content: Text(
                          isArabic
                              ? 'شاهد التفاصيل اليومية لكل تغيير حالة يتضمن الوقت والمدة والمكان.'
                              : 'View detailed RODS for different dates, including time, duration, and location of each duty status change.',
                          style: TextStyle(fontSize: 9, color: secondaryColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTabbedCard(
            title: isArabic ? 'تعديل السجلات' : 'Editing Logs',
            textColor: textColor,
            brightness: brightness,
            content: Text(
                isArabic
                    ? 'عدّل الإدخالات (باستثناء وقت القيادة الآلي). اضغط على التاريخ وعدل واحفظ.'
                    : 'Edit duty status entries (except for the automatically recorded driving logs) to ensure accuracy. Simply tap on a date, use the pencil icon to make changes, and save your edits.',
                style: TextStyle(fontSize: 9, color: secondaryColor)),
          ),
          const SizedBox(height: 12),
          _buildTabbedCard(
            title: isArabic ? 'توقيع السجلات' : 'Certifying Logs',
            textColor: textColor,
            brightness: brightness,
            content: Text(
                isArabic
                    ? 'أنهِ ورديتك بتوقيع سجلاتك رقمياً للتأكيد على دقتها والامتثال بضغطة زر.'
                    : 'Certifying Logs: End your shift by digitally certifying your logs for accuracy and compliance with the tap of a button.',
                style: TextStyle(fontSize: 9, color: secondaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadsideSection(bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildTabbedCard(
              title: isArabic ? 'تفتيش DOT' : 'DOT Inspection',
              textColor: textColor,
              brightness: brightness,
              content: Text(
                isArabic
                    ? 'أثناء التفتيش الأمني، اتبع الخطوات:\n\n• ادخل لوضع تفتيش DOT من القائمة الرئيسية.\n• اضغط "بدء التفتيش" لعرض سجلات (RODS) للضابط.\n• استخدم أسهم التنقل لمراجعة السجلات حسب التاريخ.\n• إذا طلب منك، أرسل السجلات عبر الويب أو البريد.\n• بعد الانتهاء، اضغط "رجوع" للعودة.'
                    : 'During a roadside inspection, follow these steps:\n\n• Access "DOT Inspection" mode from the Main Menu.\n• Tap "Start Inspection" to display your Records of Duty Status (RODS) to the officer.\n• Use the navigation arrows to review logs by date.\n• If requested, send your RODS via web services or email by selecting the "Send" button.\n• Once the inspection is complete, tap "Back" to return to your regular logs.',
                style:
                    TextStyle(fontSize: 9, color: secondaryColor, height: 1.5),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: _buildTabbedCard(
                title: isArabic ? 'تنبيهات الامتثال' : 'HOS Compliance Alerts',
                textColor: textColor,
                brightness: brightness,
                content: Text(
                  isArabic
                      ? 'ابقَ ممتثلاً لمراقبة التنبيهات:\n\n• على شاشة السجلات الرئيسية، راقب الأيقونة الحمراء التي تشير لمخالفة HOS أو تحذير النموذج.\n• راجع قائمة الانتهاكات أسفل المخطط لمعرفة التفاصيل عبر الضغط عليها.'
                      : 'Stay compliant with HOS regulations by monitoring alerts:\n\n• On the main logs screen, watch for the red exclamation icon, which signals an HOS violation or Form/Certification warning.\n• Review a list of HOS violations by scrolling below the log graph. Tapping on a violation provides more details.',
                  style:
                      TextStyle(fontSize: 9, color: secondaryColor, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDvirSection(bool isArabic, Color surfaceColor, Color textColor,
      Color secondaryColor, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          _buildTabbedCard(
            title: isArabic ? 'إنشاء فحص' : 'Create DVIR',
            textColor: textColor,
            brightness: brightness,
            content: Text(
                isArabic
                    ? 'إنشاء تقرير فحص جديد:\n\n• افتح القائمة واختر DVIR.\n• اضغط على علامة الزائد لبدء فحص جديد.\n• راجع المكونات وحدد أي أعطال.\n• أضف ملاحظات إذا لزم الأمر.\n• اضغط توقيع للحفظ في السجل.'
                    : 'Create a New Inspection Report:\n\n• Access the Menu and select DVIR.\n• Tap the plus sign to start a new inspection.\n• Review the list of vehicle components and mark any with detected defects.\n• Add notes in the Remarks section if needed.\n• Tap Sign to finalize and save the report in the DVIR history.',
                style: TextStyle(fontSize: 9, color: secondaryColor, height: 1.5)),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTabbedCard(
                  title: isArabic ? 'تعديل الفحص' : 'Edit DVIR',
                  textColor: textColor,
                  brightness: brightness,
                  content: Text(
                      isArabic
                          ? 'تعديل تقرير سابق:\n\n• اذهب للسجل واختر التقرير.\n• اضغط زر التعديل لإجراء التغييرات.'
                          : 'Edit an existing Report:\n\n• Go to DVIR History and select the report you wish to edit.\n• Click the "..." button.\n• Choose Edit to make changes.',
                      style: TextStyle(fontSize: 9, color: secondaryColor, height: 1.5)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTabbedCard(
                  title: isArabic ? 'حذف الفحص' : 'Delete DVIR',
                  textColor: textColor,
                  brightness: brightness,
                  content: Text(
                      isArabic
                          ? 'حذف تقرير سابق:\n\n• اذهب للسجل واختر التقرير.\n• اضغط زر الحذف وتأكد.'
                          : 'Delete an existing Report:\n\n• In DVIR History, select the report to delete.\n• Click the "..." button.\n• Choose Remove and confirm the deletion.',
                      style: TextStyle(fontSize: 9, color: secondaryColor, height: 1.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabbedCard(
      {required String title,
      required Widget content,
      required Color textColor,
      required Brightness brightness,
      bool fullWidth = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textColor.withValues(alpha: 0.6),
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: Colors.grey.shade300,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: brightness == Brightness.light ? Colors.white : AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              if (brightness == Brightness.light)
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 8, left: 4),
                width: 4,
                height: 14,
                color: AppColors.primaryBlue.withValues(alpha: 0.8),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      ],
    );
  }
}
"""

with open(r"d:\Flutter projects\golden_feather_eld\lib\features\account\presentation\pages\user_manual_page.dart", "w", encoding="utf-8") as f:
    f.write(code)
