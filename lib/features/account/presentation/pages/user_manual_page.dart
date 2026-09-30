import '../../../../core/extensions/context_extensions.dart';
import '../../../../l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class UserManualPage extends StatelessWidget {
  const UserManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
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
          loc.eldUserManual,
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
          _buildHeader(loc, surfaceColor, textColor, textSecondaryColor, brightness),
          const SizedBox(height: AppSpacing.sm),
          _buildSectionTitle(
              loc.features, textColor),
          _buildFeaturesSection(
              loc, surfaceColor, textColor, textSecondaryColor, brightness),
          
          _buildSectionTitle(
              loc.installationAndSetup,
              textColor),
          _buildInstallationSection(
              loc, surfaceColor, textColor, textSecondaryColor, brightness),
          
          _buildSectionTitle(loc.logManagement,
              textColor),
          _buildLogManagementSection(
              loc, surfaceColor, textColor, textSecondaryColor, brightness),
          
          _buildSectionTitle(loc.roadsideInspections,
              textColor),
          _buildRoadsideSection(
              loc, surfaceColor, textColor, textSecondaryColor, brightness),
          
          _buildSectionTitle(
              loc.electronicDriverVehicleInspect,
              textColor),
          _buildDvirSection(
              loc, surfaceColor, textColor, textSecondaryColor, brightness),
          
          _buildSectionTitle(
              loc.fleetManagerPortal,
              textColor),
          _buildFleetManagerSection(
              loc, surfaceColor, textColor, textSecondaryColor, brightness),
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
          Divider(color: textColor.withValues(alpha: 0.3), thickness: 1, height: 1),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc, Color surfaceColor, Color textColor,
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
                  color: textColor.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(Icons.local_shipping, size: 64, color: secondaryColor),
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
                          loc.userManual,
                          style: TextStyle(
                              fontSize: 11,
                              color: textColor,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Divider(color: textColor.withValues(alpha: 0.3))),
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
                        color: brightness == Brightness.light ? AppColors.white : AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          if (brightness == Brightness.light)
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                        ],
                      ),
                      child: Text(
                        loc.electronicLoggingDeviceEld,
                        textAlign: TextAlign.center,
                        style:  TextStyle(
                            fontSize: 11, color: AppColors.textPrimaryFor(brightness)),
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

  Widget _buildFeaturesSection(AppLocalizations loc, Color surfaceColor,
      Color textColor, Color secondaryColor, Brightness brightness) {
    final features = [
      {
        'title': loc.recordsOfDutyStatus,
        'desc': loc.easilyManageYourDutyStatusChan
      },
      {
        'title': loc.availableHoursAndRequiredBreaks,
        'desc': loc.stayInformedAboutYourAvailable
      },
      {
        'title': loc.interAndIntrastateHosRules,
        'desc': loc.ourAppSupportsBothInterAndIntr
      },
      {
        'title': loc.roadsideInspectionFunction,
        'desc': loc.duringRoadsideInspectionsUseTh
      },
      {
        'title':
            loc.vehicleInspectionReports,
        'desc': loc.generatePreOrPostTripDvirsWith
      },
      {
        'title':
            loc.onlineFleetManagerPortal,
        'desc': loc.accessTheFleetManagerPortalToM
      },
      {
        'title': loc.gpsTracking,
        'desc': loc.trackYourVehicleSLocationIn
      },
      {
        'title': loc.iftaCalculations,
        'desc': loc.automaticallyCalculateIftaData
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

  Widget _buildFleetManagerSection(AppLocalizations loc, Color surfaceColor,
      Color textColor, Color secondaryColor, Brightness brightness) {
    final features = [
      {
        'title': loc.setUpFleetManagerPortal,
        'desc': loc.useYourCredentialsToSignIntoTh
      },
      {
        'title':
            loc.monitorHosAndFmcsaCompliance,
        'desc': loc.stayOnTopOfDriversDuty
      },
      {
        'title': loc.preconfiguredStatuses,
        'desc': loc.customizeDutyStatusesAccessByS
      },
      {
        'title': loc.driverAndVehicleInformation,
        'desc': loc.trackYourDriversCurrentOrLast
      },
      {
        'title': loc.downloadAndTransferLogs,
        'desc': loc.downloadAnyDriversLogsInPdf
      },
      {
        'title': loc.filterLogs,
        'desc': loc.saveTimeByQuicklyFindingLogsBy
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
              color: Colors.black.withValues(alpha: 0.04),
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

  Widget _buildInstallationSection(AppLocalizations loc, Color surfaceColor,
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
                color: textColor,
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
                  title: loc.installEldHardware,
                  textColor: textColor,
                  brightness: brightness,
                  content: Text(
                    loc.beginByLocatingTheEcmDiagnostic,
                    style: TextStyle(
                        fontSize: 9, color: secondaryColor, height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTabbedCard(
                  title: loc.installEldSoftware,
                  textColor: textColor,
                  brightness: brightness,
                  content: Text(
                    loc.beforeYouStartUsingTheEld,
                    style: TextStyle(
                        fontSize: 9, color: secondaryColor, height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTabbedCard(
                  title: loc.hoursOfService1,
                  textColor: textColor,
                  brightness: brightness,
                  content: Text(
                    loc.onceTheEldIsSetUp,
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

  Widget _buildLogManagementSection(AppLocalizations loc, Color surfaceColor,
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
                    color: textColor.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: textColor.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Center(
                      child: Icon(Icons.smartphone, color: secondaryColor, size: 48)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    _buildTabbedCard(
                      title: loc.accessingLogs,
                      textColor: textColor,
                      brightness: brightness,
                      content: Text(
                          loc.logInToTheEldAppWithYourUnique,
                          style: TextStyle(fontSize: 9, color: secondaryColor)),
                    ),
                    const SizedBox(height: 12),
                    _buildTabbedCard(
                      title: loc.viewingLogs1,
                      textColor: textColor,
                      brightness: brightness,
                      content: Text(
                          loc.viewDetailedRodsForDifferentDa,
                          style: TextStyle(fontSize: 9, color: secondaryColor)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTabbedCard(
            title: loc.editingLogs,
            textColor: textColor,
            brightness: brightness,
            content: Text(
                loc.editDutyStatusEntriesExceptFor,
                style: TextStyle(fontSize: 9, color: secondaryColor)),
          ),
          const SizedBox(height: 12),
          _buildTabbedCard(
            title: loc.certifyingLogs,
            textColor: textColor,
            brightness: brightness,
            content: Text(
                loc.certifyingLogsEndYourShiftByDi,
                style: TextStyle(fontSize: 9, color: secondaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadsideSection(AppLocalizations loc, Color surfaceColor,
      Color textColor, Color secondaryColor, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildTabbedCard(
              title: loc.dotInspection,
              textColor: textColor,
              brightness: brightness,
              content: Text(
                loc.duringARoadsideInspectionFollowThese,
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
                title: loc.hosComplianceAlerts,
                textColor: textColor,
                brightness: brightness,
                content: Text(
                  loc.stayCompliantWithHosRegulationsBy,
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

  Widget _buildDvirSection(AppLocalizations loc, Color surfaceColor, Color textColor,
      Color secondaryColor, Brightness brightness) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          _buildTabbedCard(
            title: loc.createDvir,
            textColor: textColor,
            brightness: brightness,
            content: Text(
                loc.createANewInspectionReportAccess,
                style: TextStyle(fontSize: 9, color: secondaryColor, height: 1.5)),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTabbedCard(
                  title: loc.editDvir,
                  textColor: textColor,
                  brightness: brightness,
                  content: Text(
                      loc.editAnExistingReportGoTo,
                      style: TextStyle(fontSize: 9, color: secondaryColor, height: 1.5)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTabbedCard(
                  title: loc.deleteDvir,
                  textColor: textColor,
                  brightness: brightness,
                  content: Text(
                      loc.deleteAnExistingReportInDvir,
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
                color: textColor.withValues(alpha: 0.06),
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
                  color: Colors.black.withValues(alpha: 0.04),
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
