import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_gap.dart';

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
          context.loc.eldUserManual,
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
          _buildHeader(context, isArabic, surfaceColor, textColor, textSecondaryColor),
          AppGap.lg,
          _buildSectionTitle(
              context.loc.features, textColor, context),
          _buildFeaturesSection(context, isArabic, surfaceColor, textColor, textSecondaryColor),
          AppGap.lg,
          _buildSectionTitle(
              context.loc.installationAndSetup,
              textColor,
              context),
          _buildInstallationSection(context, isArabic, surfaceColor, textColor, textSecondaryColor),
          AppGap.lg,
          _buildSectionTitle(context.loc.logManagement,
              textColor, context),
          _buildLogManagementSection(context, isArabic, surfaceColor, textColor, textSecondaryColor),
          AppGap.lg,
          _buildSectionTitle(context.loc.roadsideInspections,
              textColor, context),
          _buildRoadsideSection(context, isArabic, surfaceColor, textColor, textSecondaryColor),
          AppGap.lg,
          _buildSectionTitle(
              context.loc.electronicDriverVehicleInspectionReports,
              textColor,
              context),
          _buildDvirSection(context, isArabic, surfaceColor, textColor, textSecondaryColor),
          AppGap.lg,
          _buildSectionTitle(
              context.loc.fleetManagerPortal,
              textColor,
              context),
          _buildFleetManagerSection(context, isArabic, surfaceColor, textColor, textSecondaryColor),
          AppGap.xl,
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
            style: context.textTheme.bodyLarge?.copyWith(color: textColor),
          ),
          AppGap.xs,
          Divider(color: AppColors.surface.withValues(alpha: 0.2), thickness: 1),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isArabic, Color surfaceColor, Color textColor,
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
                borderRadius: BorderRadius.circular(AppRadius.dialog),
              ),
              child: const Center(
                child: Icon(Icons.local_shipping, size: 64, color: AppColors.border),
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
                    context.loc.userManual,
                    style: context.textTheme.labelSmall?.copyWith(color: secondaryColor),
                  ),
                  const Divider(),
                  AppGap.md,
                  Text(
                    'TOP COMPLIANCE ELD',
                    style: context.textTheme.bodyMedium?.copyWith(color: textColor),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xl),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text(
                      context.loc.electronicLoggingDeviceEld,
                      style: context.textTheme.labelSmall?.copyWith(color: AppColors.textPrimary),
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

  Widget _buildFeaturesSection(BuildContext context, bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor) {
    final features = [
      {
        'title': context.loc.recordsOfNdutyStatus,
        'desc': context.loc.easilyManageYourDutyStatus
      },
      {
        'title': context.loc.availableHoursAndNrequiredBreaks,
        'desc': context.loc.stayInformedAboutYourAvailable
      },
      {
        'title': context.loc.roadsideInspectionNfunction,
        'desc': context.loc.duringRoadsideInspectionsUseThe
      },
      {
        'title':
            context.loc.vehicleInspectionNreports,
        'desc': context.loc.generatePreOrPostTrip
      },
    ];

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: features
            .map((f) => _buildListRow(context, f['title']!, f['desc']!, textColor, secondaryColor))
            .toList(),
      ),
    );
  }

  Widget _buildFleetManagerSection(BuildContext context, bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor) {
    final features = [
      {
        'title': context.loc.setUpFleetNmanagerPortal,
        'desc': context.loc.useYourCredentialsToSign
      },
      {
        'title':
            context.loc.monitorHosAndNfmcsaCompliance,
        'desc': context.loc.stayOnTopOfDrivers
      },
    ];

    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: features
            .map((f) => _buildListRow(context, f['title']!, f['desc']!, textColor, secondaryColor))
            .toList(),
      ),
    );
  }

  Widget _buildListRow(BuildContext context,
      String title, String description, Color textColor, Color secondaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.input),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              flex: 3,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: context.textTheme.labelSmall?.copyWith(color: textColor),
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
                style: context.textTheme.labelSmall?.copyWith(color: secondaryColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstallationSection(BuildContext context, bool isArabic, Color surfaceColor,
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
                borderRadius: BorderRadius.circular(AppRadius.input),
              ),
              child: const Center(
                  child: Icon(Icons.router, color: AppColors.surface, size: 48)),
            ),
          ),
          AppGap.hMd,
          // Instructions
          Expanded(
            flex: 7,
            child: _buildInfoCard(context, title: context.loc.installEldHardware,
              textColor: textColor,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.loc.beginByLocatingTheEcm,
                    style: context.textTheme.labelSmall?.copyWith(color: secondaryColor),
                  ),
                  AppGap.sm,
                  Text(
                      '• 6-pin Connector\n• 9-pin Connector\n• OBDII Connector',
                      style: context.textTheme.labelSmall?.copyWith(color: secondaryColor)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogManagementSection(BuildContext context, bool isArabic, Color surfaceColor,
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
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(color: Colors.grey.shade400, width: 2),
              ),
              child: const Center(
                  child: Icon(Icons.smartphone, color: AppColors.border, size: 48)),
            ),
          ),
          AppGap.hMd,
          Expanded(
            flex: 7,
            child: Column(
              children: [
                _buildInfoCard(context, title: context.loc.accessingLogs,
                  textColor: textColor,
                  content: Text(
                      context.loc.logInAndNavigateTo,
                      style: context.textTheme.labelSmall?.copyWith(color: secondaryColor)),
                ),
                AppGap.sm,
                _buildInfoCard(context, title: context.loc.viewingLogs1,
                  textColor: textColor,
                  content: Text(
                      context.loc.viewDetailedRodsForDifferent,
                      style: context.textTheme.labelSmall?.copyWith(color: secondaryColor)),
                ),
                AppGap.sm,
                _buildInfoCard(context, title: context.loc.editingLogs,
                  textColor: textColor,
                  content: Text(
                      context.loc.editDutyStatusEntriesExcept,
                      style: context.textTheme.labelSmall?.copyWith(color: secondaryColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadsideSection(BuildContext context, bool isArabic, Color surfaceColor,
      Color textColor, Color secondaryColor) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildInfoCard(context, title: context.loc.dotInspection,
              textColor: textColor,
              content: Text(
                isArabic
                    ? '• اختر وضع التفتيش من القائمة.\n• اضغط "بدء التفتيش" لعرض السجلات.\n• استخدم الأسهم للتنقل.\n• شارك البيانات عند الطلب.'
                    : '• Access "DOT Inspection" mode.\n• Tap "Start Inspection".\n• Use arrows to review logs.\n• Send RODS via web/email.',
                style:
                    context.textTheme.labelSmall?.copyWith(color: secondaryColor, height: 1.5),
              ),
            ),
          ),
          AppGap.hSm,
          Expanded(
            child: _buildInfoCard(context, title: context.loc.hosComplianceAlerts,
              textColor: textColor,
              content: Text(
                context.loc.watchForTheRedExclamation,
                style:
                    context.textTheme.labelSmall?.copyWith(color: secondaryColor, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDvirSection(BuildContext context, bool isArabic, Color surfaceColor, Color textColor,
      Color secondaryColor) {
    return Container(
      color: surfaceColor,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildInfoCard(context, title: context.loc.createDvir,
              textColor: textColor,
              content: Text(
                  context.loc.startNewInspectionMarkDefects,
                  style: context.textTheme.labelSmall?.copyWith(color: secondaryColor)),
            ),
          ),
          AppGap.hSm,
          Expanded(
            child: Column(
              children: [
                _buildInfoCard(context, title: context.loc.editDvir,
                  textColor: textColor,
                  content: Text(
                      context.loc.selectAnExistingReportTo,
                      style: context.textTheme.labelSmall?.copyWith(color: secondaryColor)),
                ),
                AppGap.sm,
                _buildInfoCard(context, title: context.loc.deleteDvir,
                  textColor: textColor,
                  content: Text(
                      context.loc.removeTheReportFromHistory,
                      style: context.textTheme.labelSmall?.copyWith(color: secondaryColor)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context,
      {required String title,
      required Widget content,
      required Color textColor}) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: context.textTheme.labelSmall?.copyWith(color: textColor)),
          const Divider(),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsetsDirectional.only(top: 4, end: 6, start: 2),
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