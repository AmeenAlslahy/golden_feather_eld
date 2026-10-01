import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';

/// دليل المستخدم — صفحة مرجعية كثيفة النصوص (9-11px مقصودة)،
/// لكن الألوان والأوزان كلها من `context.styles` عبر copyWith.
class UserManualPage extends StatelessWidget {
  const UserManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.eldUserManual,
          style: context.styles.appBarTitle,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildHeader(loc, context),
          const SizedBox(height: AppSpacing.sm),
          _buildSectionTitle(loc.features, context),
          _buildFeaturesSection(loc, context),

          _buildSectionTitle(loc.installationAndSetup, context),
          _buildInstallationSection(loc, context),

          _buildSectionTitle(loc.logManagement, context),
          _buildLogManagementSection(loc, context),

          _buildSectionTitle(loc.roadsideInspections, context),
          _buildRoadsideSection(loc, context),

          _buildSectionTitle(loc.electronicDriverVehicleInspect, context),
          _buildDvirSection(loc, context),

          _buildSectionTitle(loc.fleetManagerPortal, context),
          _buildFleetManagerSection(loc, context),
          const SizedBox(height: 32.0),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final lineColor = context.styles.body.color!.withValues(alpha: 0.3);
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: context.styles.bodyBold.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          Divider(color: lineColor, thickness: 1, height: 1),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc, BuildContext context) {
    final iconColor = context.styles.subtitle.color!;
    return Container(
      color: Theme.of(context).colorScheme.surface,
      constraints: const BoxConstraints(minHeight: 250),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 4,
              child: Container(
                margin: const EdgeInsets.all(AppSpacing.md),
                decoration: AppDecorations.tinted(
                  context.styles.body.color!,
                  alpha: 0.06,
                  radius: AppRadius.largeCard,
                ),
                child: Center(
                  child: Icon(Icons.local_shipping, size: 64, color: iconColor),
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
                          style: context.styles.bodyBold.copyWith(fontSize: 11),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Divider(
                            color: context.styles.body.color!
                                .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Golden Feather ELD',
                      style: context.styles.body
                          .copyWith(fontSize: 24, fontWeight: FontWeight.w400),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md, vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          if (!context.isDark)
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
                        style: context.styles.body.copyWith(fontSize: 11),
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

  Widget _buildFeaturesSection(AppLocalizations loc, BuildContext context) {
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
            .map((f) => _buildFeatureCard(f['title']!, f['desc']!, context))
            .toList(),
      ),
    );
  }

  Widget _buildFleetManagerSection(AppLocalizations loc, BuildContext context) {
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
            .map((f) => _buildFeatureCard(f['title']!, f['desc']!, context))
            .toList(),
      ),
    );
  }

  Widget _buildFeatureCard(
      String title, String description, BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: AppDecorations.card(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.styles.bodyBold.copyWith(fontSize: 10),
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            width: 4,
            height: 24,
            color: AppColors.primaryGold.withValues(alpha: 0.8),
          ),
          Expanded(
            flex: 7,
            child: Text(
              description,
              style: context.styles.subtitle.copyWith(fontSize: 9, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationSection(
      AppLocalizations loc, BuildContext context) {
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
                color: context.styles.body.color!,
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
                  context: context,
                  title: loc.installEldHardware,
                  content: Text(
                    loc.beginByLocatingTheEcmDiagnostic,
                    style: context.styles.subtitle
                        .copyWith(fontSize: 9, height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTabbedCard(
                  context: context,
                  title: loc.installEldSoftware,
                  content: Text(
                    loc.beforeYouStartUsingTheEld,
                    style: context.styles.subtitle
                        .copyWith(fontSize: 9, height: 1.5),
                  ),
                ),
                const SizedBox(height: 12),
                _buildTabbedCard(
                  context: context,
                  title: loc.hoursOfService1,
                  content: Text(
                    loc.onceTheEldIsSetUp,
                    style: context.styles.subtitle
                        .copyWith(fontSize: 9, height: 1.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogManagementSection(
      AppLocalizations loc, BuildContext context) {
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
                    color: context.styles.body.color!.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.largeCard),
                    border: Border.all(
                        color:
                            context.styles.body.color!.withValues(alpha: 0.3),
                        width: 2),
                  ),
                  child: Center(
                      child: Icon(Icons.smartphone,
                          color: context.styles.subtitle.color!, size: 48)),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                flex: 7,
                child: Column(
                  children: [
                    _buildTabbedCard(
                      context: context,
                      title: loc.accessingLogs,
                      content: Text(
                          loc.logInToTheEldAppWithYourUnique,
                          style:
                              context.styles.subtitle.copyWith(fontSize: 9)),
                    ),
                    const SizedBox(height: 12),
                    _buildTabbedCard(
                      context: context,
                      title: loc.viewingLogs1,
                      content: Text(
                          loc.viewDetailedRodsForDifferentDa,
                          style:
                              context.styles.subtitle.copyWith(fontSize: 9)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTabbedCard(
            context: context,
            title: loc.editingLogs,
            content: Text(
                loc.editDutyStatusEntriesExceptFor,
                style: context.styles.subtitle.copyWith(fontSize: 9)),
          ),
          const SizedBox(height: 12),
          _buildTabbedCard(
            context: context,
            title: loc.certifyingLogs,
            content: Text(
                loc.certifyingLogsEndYourShiftByDi,
                style: context.styles.subtitle.copyWith(fontSize: 9)),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadsideSection(
      AppLocalizations loc, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildTabbedCard(
              context: context,
              title: loc.dotInspection,
              content: Text(
                loc.duringARoadsideInspectionFollowThese,
                style:
                    context.styles.subtitle.copyWith(fontSize: 9, height: 1.5),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 40),
              child: _buildTabbedCard(
                context: context,
                title: loc.hosComplianceAlerts,
                content: Text(
                  loc.stayCompliantWithHosRegulationsBy,
                  style:
                      context.styles.subtitle.copyWith(fontSize: 9, height: 1.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDvirSection(AppLocalizations loc, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          _buildTabbedCard(
            context: context,
            title: loc.createDvir,
            content: Text(
                loc.createANewInspectionReportAccess,
                style:
                    context.styles.subtitle.copyWith(fontSize: 9, height: 1.5)),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTabbedCard(
                  context: context,
                  title: loc.editDvir,
                  content: Text(
                      loc.editAnExistingReportGoTo,
                      style: context.styles.subtitle
                          .copyWith(fontSize: 9, height: 1.5)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTabbedCard(
                  context: context,
                  title: loc.deleteDvir,
                  content: Text(
                      loc.deleteAnExistingReportInDvir,
                      style: context.styles.subtitle
                          .copyWith(fontSize: 9, height: 1.5)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabbedCard({
    required BuildContext context,
    required String title,
    required Widget content,
    bool fullWidth = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: Text(
                title,
                style: context.styles.muted.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                color: context.styles.body.color!.withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: fullWidth ? double.infinity : null,
          decoration: AppDecorations.card(context, radius: AppRadius.input),
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 2, right: 8, left: 4),
                width: 4,
                height: 14,
                color: AppColors.primaryGold.withValues(alpha: 0.8),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      ],
    );
  }
}
