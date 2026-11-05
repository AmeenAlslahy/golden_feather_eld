import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/widgets/golden_app_bar.dart';

/// دليل المستخدم — صفحة مرجعية كثيفة النصوص (9-11px مقصودة)،
/// لكن الألوان والأوزان كلها من `context.styles` عبر copyWith.
class UserManualPage extends StatelessWidget {
  const UserManualPage({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Scaffold(
      appBar: GoldenAppBar(
        leading: const BackButton(),
        titleText: loc.eldUserManual,
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
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, BuildContext context) {
    final lineColor = (context.styles.body.color ?? context.textPrimary)
        .withValues(alpha: 0.3);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.styles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          Divider(
            color: lineColor,
            thickness: AppSpacing.dividerHeight,
            height: AppSpacing.dividerHeight,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppLocalizations loc, BuildContext context) {
    final iconColor = context.styles.subtitle.color ?? context.textSecondary;
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
                  context.styles.body.color ?? context.textPrimary,
                  alpha: 0.06,
                  radius: AppRadius.largeCard,
                ),
                child: Center(
                  child: Icon(
                    Icons.local_shipping,
                    size: AppSpacing.iconFeature,
                    color: iconColor,
                  ),
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
                  bottom: AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            loc.userManual,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.styles.bodyBold,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Divider(
                            color:
                                (context.styles.body.color ??
                                        context.textPrimary)
                                    .withValues(alpha: 0.3),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Golden Feather ELD',
                      style: context.styles.sectionTitle,
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.md,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppRadius.round),
                        boxShadow: [
                          if (!context.isDark)
                            BoxShadow(
                              color: context.colors.shadow.withValues(
                                alpha: 0.05,
                              ),
                              blurRadius: AppSpacing.sm,
                              offset: const Offset(0, AppSpacing.xs),
                            ),
                        ],
                      ),
                      child: Text(
                        loc.electronicLoggingDeviceEld,
                        textAlign: TextAlign.center,
                        style: context.styles.body,
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
      (
        title: loc.recordsOfDutyStatus,
        desc: loc.easilyManageYourDutyStatusChan,
      ),
      (
        title: loc.availableHoursAndRequiredBreaks,
        desc: loc.stayInformedAboutYourAvailable,
      ),
      (
        title: loc.interAndIntrastateHosRules,
        desc: loc.ourAppSupportsBothInterAndIntr,
      ),
      (
        title: loc.roadsideInspectionFunction,
        desc: loc.duringRoadsideInspectionsUseTh,
      ),
      (
        title: loc.vehicleInspectionReports,
        desc: loc.generatePreOrPostTripDvirsWith,
      ),
      (
        title: loc.onlineFleetManagerPortal,
        desc: loc.accessTheFleetManagerPortalToM,
      ),
      (title: loc.gpsTracking, desc: loc.trackYourVehicleSLocationIn),
      (title: loc.iftaCalculations, desc: loc.automaticallyCalculateIftaData),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: features
            .map((f) => _buildFeatureCard(f.title, f.desc, context))
            .toList(),
      ),
    );
  }

  Widget _buildFleetManagerSection(AppLocalizations loc, BuildContext context) {
    final features = [
      {
        'title': loc.setUpFleetManagerPortal,
        'desc': loc.useYourCredentialsToSignIntoTh,
      },
      {
        'title': loc.monitorHosAndFmcsaCompliance,
        'desc': loc.stayOnTopOfDriversDuty,
      },
      {
        'title': loc.preconfiguredStatuses,
        'desc': loc.customizeDutyStatusesAccessByS,
      },
      {
        'title': loc.driverAndVehicleInformation,
        'desc': loc.trackYourDriversCurrentOrLast,
      },
      {
        'title': loc.downloadAndTransferLogs,
        'desc': loc.downloadAnyDriversLogsInPdf,
      },
      {'title': loc.filterLogs, 'desc': loc.saveTimeByQuicklyFindingLogsBy},
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
    String title,
    String description,
    BuildContext context,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.compact),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.compact,
      ),
      decoration: AppDecorations.card(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: context.styles.sectionTitle,
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            width: 4,
            height: 24,
            color: context.gold.withValues(alpha: 0.8),
          ),
          Expanded(
            flex: 7,
            child: Text(
              description,
              style: context.styles.subtitle.copyWith(height: 1.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstallationSection(AppLocalizations loc, BuildContext context) {
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
                color: context.placeholderSurface,
                borderRadius: BorderRadius.circular(AppRadius.imagePlaceholder),
                border: Border.all(color: context.placeholderBorder),
              ),
              child: Center(
                child: Icon(
                  Icons.router,
                  color: context.styles.subtitle.color,
                  size: AppSpacing.iconXLarge,
                ),
              ),
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
                    style: context.styles.subtitle.copyWith(height: 1.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.compact),
                _buildTabbedCard(
                  context: context,
                  title: loc.installEldSoftware,
                  content: Text(
                    loc.beforeYouStartUsingTheEld,
                    style: context.styles.subtitle.copyWith(height: 1.6),
                  ),
                ),
                const SizedBox(height: AppSpacing.compact),
                _buildTabbedCard(
                  context: context,
                  title: loc.hoursOfService1,
                  content: Text(
                    loc.onceTheEldIsSetUp,
                    style: context.styles.subtitle.copyWith(height: 1.6),
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
    AppLocalizations loc,
    BuildContext context,
  ) {
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
                    color: context.placeholderSurface,
                    borderRadius: BorderRadius.circular(AppRadius.largeCard),
                    border: Border.all(
                      color: context.placeholderBorder,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.smartphone,
                      color: context.styles.subtitle.color!,
                      size: AppSpacing.iconHero,
                    ),
                  ),
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
                        style: context.styles.subtitle,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.compact),
                    _buildTabbedCard(
                      context: context,
                      title: loc.viewingLogs1,
                      content: Text(
                        loc.viewDetailedRodsForDifferentDa,
                        style: context.styles.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.compact),
          _buildTabbedCard(
            context: context,
            title: loc.editingLogs,
            content: Text(
              loc.editDutyStatusEntriesExceptFor,
              style: context.styles.subtitle,
            ),
          ),
          const SizedBox(height: AppSpacing.compact),
          _buildTabbedCard(
            context: context,
            title: loc.certifyingLogs,
            content: Text(
              loc.certifyingLogsEndYourShiftByDi,
              style: context.styles.subtitle,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoadsideSection(AppLocalizations loc, BuildContext context) {
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
                style: context.styles.subtitle.copyWith(height: 1.6),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xxl),
              child: _buildTabbedCard(
                context: context,
                title: loc.hosComplianceAlerts,
                content: Text(
                  loc.stayCompliantWithHosRegulationsBy,
                  style: context.styles.subtitle.copyWith(height: 1.6),
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
              style: context.styles.subtitle.copyWith(height: 1.6),
            ),
          ),
          const SizedBox(height: AppSpacing.compact),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTabbedCard(
                  context: context,
                  title: loc.editDvir,
                  content: Text(
                    loc.editAnExistingReportGoTo,
                    style: context.styles.subtitle.copyWith(height: 1.6),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildTabbedCard(
                  context: context,
                  title: loc.deleteDvir,
                  content: Text(
                    loc.deleteAnExistingReportInDvir,
                    style: context.styles.subtitle.copyWith(height: 1.6),
                  ),
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
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Text(
                title,
                style: context.styles.subtitle.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ),
            Expanded(
              child: Container(
                height: AppSpacing.dividerHeight,
                color: (context.styles.body.color ?? context.textPrimary)
                    .withValues(alpha: 0.06),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          width: double.infinity,
          decoration: AppDecorations.card(context, radius: AppRadius.input),
          padding: const EdgeInsets.all(AppSpacing.compact),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsetsDirectional.only(
                  start: AppSpacing.xs,
                  end: AppSpacing.sm,
                  top: AppSpacing.xs,
                ),
                width: AppSpacing.xs,
                height: AppSpacing.iconSmall,
                color: context.gold.withValues(alpha: 0.8),
              ),
              Expanded(child: content),
            ],
          ),
        ),
      ],
    );
  }
}
