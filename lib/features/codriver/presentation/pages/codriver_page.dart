import 'package:flutter/material.dart';
import '../../../../core/design_system.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../domain/entities/codriver.dart';
import '../providers/codriver_provider.dart';
import '../providers/team_status_provider.dart';
import '../../domain/role_switch_guard.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../hos/domain/engine/hos_rules_engine.dart';
import '../../../hos/presentation/providers/hos_engine_provider.dart';
import '../../../hos/presentation/providers/hos_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../hos/presentation/providers/status_dashboard_providers.dart';

class CoDriverPage extends ConsumerStatefulWidget {
  const CoDriverPage({super.key});

  @override
  ConsumerState<CoDriverPage> createState() => _CoDriverPageState();
}

class _CoDriverPageState extends ConsumerState<CoDriverPage> {
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final codriverState = ref.watch(codriverProvider);
    final loc = context.loc;
    final surfaceColor = context.colorScheme.surface;
    final textColor = context.styles.body.color!;

    final selfId = ref.watch(currentDriverIdProvider)?.toString();
    final authUserId = ref.watch(authStateProvider).user?.id;
    final drivers = [
      CoDriver.none,
      ...codriverState.availableDrivers.where(
        (d) => d.id != selfId && (authUserId == null || d.id != authUserId),
      ),
    ];

    final currentSelectedId =
        _selectedId ?? codriverState.selectedCoDriver?.id ?? 'none';

    return Scaffold(
      appBar: GoldenAppBar(
        variant: GoldenAppBarVariant.brand,
        titleText: loc.coDriver,
        leading: Builder(
          builder: (context) => Navigator.of(context).canPop()
              ? IconButton(
                  key: const Key('codriver_back'),
                  icon: Icon(
                    Icons.arrow_back,
                    color: context.onGold,
                    size: AppSpacing.iconSize,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                )
              : IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: context.onGold,
                    size: AppSpacing.iconSize,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
        ),
      ),
      drawer: const EldDrawer(),
      body: codriverState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(codriverProvider.notifier).reload(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Reference layout (screenshot 12): centred heading + hint,
                    // dropdown row, full-width divider, second heading + hint,
                    // SWITCH, full-width divider.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        AppSpacing.lg,
                        AppSpacing.screenPadding,
                        AppSpacing.sectionGap,
                      ),
                      child: Column(
                        children: [
                          Text(
                            loc.coDriverSelectLabel,
                            style: context.styles.sectionTitle,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            loc.coDriverSelectHint,
                            style: context.styles.subtitle,
                          ),
                          const SizedBox(height: AppSpacing.sectionGap),

                          // Selector Row
                          InkWell(
                            onTap: () => _showDriverSelectionDialog(
                              context,
                              drivers,
                              currentSelectedId,
                              textColor,
                              surfaceColor,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: AppSpacing.md,
                              ),
                              decoration: BoxDecoration(
                                // حد سفلي = دور الفاصل الثيمي (كان دور
                                // outline الأبيض في الداكن وحدًا أثقل من
                                // كل فواصل التطبيق في الفاتح).
                                border: Border(
                                  bottom: BorderSide(color: context.divider),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      _driverLabel(
                                        drivers.firstWhere(
                                          (d) => d.id == currentSelectedId,
                                          orElse: () => CoDriver.none,
                                        ),
                                        loc,
                                      ).toUpperCase(),
                                      // عنوان اختيار لا عنوان صفحة —
                                      // وزن الترويسات الموحد (كان 24).
                                      style: context.styles.sectionTitle,
                                    ),
                                  ),
                                  Icon(
                                    Icons.keyboard_arrow_down,
                                    color: textColor,
                                    size: AppSpacing.iconSize,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      child: Column(
                        children: [
                          Text(
                            loc.coDriverSwitchDrivers,
                            style: context.styles.sectionTitle,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Text(
                            loc.coDriverSwitchHint,
                            textAlign: TextAlign.center,
                            style: context.styles.subtitle,
                          ),
                          if (codriverState.error != null) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              anyErrorUserMessage(
                                codriverState.error!,
                                loc: loc,
                              ),
                              textAlign: TextAlign.center,
                              style: context.styles.error,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.sectionGap),
                          if (codriverState.isSwitching)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: Text(loc.coDriverSwitching),
                            ),

                          // Switch Button
                          AppButton(
                            label: loc.coDriverSwitchAction,
                            type: EldButtonType.primary,
                            isLoading: codriverState.isSwitching,
                            onPressed:
                                (codriverState.isSwitching ||
                                    codriverState.selectedCoDriver == null ||
                                    codriverState.selectedCoDriver?.id ==
                                        CoDriver.none.id)
                                ? null
                                : () async {
                                    final hos = ref.read(hosStatusProvider);
                                    final driving = hos is HosEngineReady
                                        ? hos.update.currentStatus ==
                                              DutyStatus.driving
                                        : null;
                                    final refusal = refuseRoleSwitch(
                                      currentDriverId: ref.read(
                                        currentDriverIdProvider,
                                      ),
                                      coDriverId:
                                          codriverState.selectedCoDriver?.id,
                                      speedMps: ref.read(
                                        currentVehicleSpeedProvider,
                                      ),
                                      thresholdKmh: ref
                                          .read(hosConfigurationProvider)
                                          .movingSpeedThresholdKmh,
                                      currentStatusIsDriving: driving,
                                      trackingLive: ref
                                          .read(trackingStateProvider)
                                          .isTracking,
                                    );
                                    if (refusal != null) {
                                      AppFeedback.error(
                                        context,
                                        _refusalText(refusal, loc),
                                      );
                                      return;
                                    }
                                    final confirm = await AppDialog.show(
                                      context,
                                      title: loc.coDriverConfirmSwitchTitle,
                                      contentText:
                                          loc.coDriverConfirmSwitchBody,
                                      type: AppDialogType.confirmation,
                                      primaryLabel: MaterialLocalizations.of(
                                        context,
                                      ).okButtonLabel,
                                      secondaryLabel: MaterialLocalizations.of(
                                        context,
                                      ).cancelButtonLabel,
                                    );

                                    if (confirm == true && mounted) {
                                      final newPrimary = ref
                                          .read(codriverProvider)
                                          .selectedCoDriver
                                          ?.name;
                                      final error = await ref
                                          .read(codriverProvider.notifier)
                                          .switchDrivers();
                                      if (!context.mounted) return;
                                      if (error != null) {
                                        AppFeedback.error(
                                          context,
                                          anyErrorUserMessage(error, loc: loc),
                                        );
                                        return;
                                      }
                                      // SRS 10.4: show the new roles before leaving
                                      // (current → co-driver, co-driver → primary).
                                      await showDialog<void>(
                                        context: context,
                                        builder: (dialogContext) =>
                                            AppDialog.informational(
                                          key: const Key(
                                            'switch_result_dialog',
                                          ),
                                          title:
                                              loc.coDriverRolesSwitchedTitle,
                                          contentWidget: Text(
                                            loc.coDriverRolesSwitchedBody(
                                              newPrimary ??
                                                  loc.coDriverDefaultNewPrimary,
                                            ),
                                            textAlign: TextAlign.center,
                                            style: context.styles.success,
                                          ),
                                          primaryActionLabel:
                                              MaterialLocalizations.of(
                                            dialogContext,
                                          ).okButtonLabel,
                                          onPrimaryAction: () =>
                                              Navigator.pop(dialogContext),
                                        ),
                                      );
                                      if (!context.mounted) return;
                                      ref.invalidate(teamStatusProvider);
                                      ref.invalidate(statusDashboardProvider);
                                      context.go('/home');
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // SRS 10.3: server team state (informational, below the
                    // reference layout so it does not change it).
                    Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenPadding,
                        AppSpacing.md,
                        AppSpacing.screenPadding,
                        AppSpacing.lg,
                      ),
                      child: _LinkedCoDriver(state: codriverState, loc: loc),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _showDriverSelectionDialog(
    BuildContext context,
    List<CoDriver> drivers,
    String currentId,
    Color textColor,
    Color surfaceColor,
  ) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Local state for the dialog radio buttons before pressing OK
        String dialogSelectedId = currentId;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AppDialog(
              title: context.loc.coDriver,
              type: AppDialogType.confirmation,
              contentWidget: SizedBox(
                width: double.maxFinite,
                child: RadioGroup<String>(
                  groupValue: dialogSelectedId,
                  onChanged: (value) {
                    if (value == null) return;
                    setStateDialog(() => dialogSelectedId = value);
                  },
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: drivers.length,
                    itemBuilder: (context, index) {
                      final driver = drivers[index];
                      return RadioListTile<String>(
                        title: Text(
                          _driverLabel(driver, context.loc).toUpperCase(),
                          style: context.styles.subtitle.copyWith(
                            color: dialogSelectedId == driver.id
                                ? context.gold
                                : null,
                          ),
                        ),
                        value: driver.id,
                        activeColor: context.gold,
                      );
                    },
                  ),
                ),
              ),
              secondaryActionLabel: context.loc.cancelAction,
              onSecondaryAction: () => Navigator.of(context).pop(),
              primaryActionLabel: MaterialLocalizations.of(
                context,
              ).okButtonLabel,
              onPrimaryAction: () {
                // الربط (link/add) إجراء إدارة للناقل عبر البوابة —
                // السائق يختار محلياً من سيبدأ معه تبديل الأدوار.
                final selected = drivers.firstWhere(
                  (d) => d.id == dialogSelectedId,
                );
                ref
                    .read(codriverProvider.notifier)
                    .selectCoDriver(selected);
                setState(() {
                  _selectedId = dialogSelectedId;
                });
                Navigator.of(context).pop();
              },
            );
          },
        );
      },
    );
  }
}

String _driverLabel(CoDriver driver, AppLocalizations loc) {
  if (driver.id == CoDriver.none.id) {
    return loc.coDriverNone;
  }
  return driver.name;
}

String _refusalText(RoleSwitchRefusal refusal, AppLocalizations loc) {
  switch (refusal) {
    case RoleSwitchRefusal.sessionMissing:
      return loc.coDriverRefusalSessionMissing;
    case RoleSwitchRefusal.stillDriving:
      return loc.coDriverRefusalStillDriving;
    case RoleSwitchRefusal.motionUnknown:
      return loc.coDriverRefusalMotionUnknown;
    case RoleSwitchRefusal.thresholdMissing:
      return loc.coDriverRefusalThresholdMissing;
    case RoleSwitchRefusal.vehicleMoving:
      return loc.coDriverRefusalVehicleMoving;
    case RoleSwitchRefusal.coDriverMissing:
      return loc.coDriverRefusalCoDriverMissing;
    case RoleSwitchRefusal.sameDriver:
      return loc.coDriverRefusalSameDriver;
  }
}

class _LinkedCoDriver extends StatelessWidget {
  final CoDriverState state;
  final AppLocalizations loc;

  const _LinkedCoDriver({required this.state, required this.loc});

  @override
  Widget build(BuildContext context) {
    final linked = state.currentCoDriver;
    final String value;
    final bool isError;
    if (linked != null && linked.isLinked) {
      value = linked.name ?? linked.coDriverId.toString();
      isError = false;
    } else if (state.currentError != null &&
        state.currentError != 'noInternet') {
      value = anyErrorUserMessage(state.currentError!, loc: loc);
      isError = true;
    } else {
      value = loc.coDriverLinkNone;
      isError = false;
    }
    // SRS 10.3: the team state is read from the server link
    // (`teamDrivingActive`); the app does not infer who is driving.
    final AppStatusBadge? teamBadge = (linked != null && linked.isLinked)
        ? (linked.teamDrivingActive
              ? AppStatusBadge(
                  label: loc.coDriverTeamDrivingActive,
                  type: AppStatusBadgeType.success,
                )
              : AppStatusBadge(
                  label: loc.coDriverTeamDrivingInactive,
                  type: AppStatusBadgeType.warning,
                ))
        : null;
    return Column(
      children: [
        Text(loc.coDriverLinkedTitle, style: context.styles.sectionTitle),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          textAlign: TextAlign.center,
          style: isError ? context.styles.error : context.styles.subtitle,
        ),
        if (teamBadge != null) ...[
          const SizedBox(height: AppSpacing.xs),
          teamBadge,
        ],
        _HosIsolationLine(loc: loc),
      ],
    );
  }
}

/// SRS 5.8 — server statement that both drivers' HOS records are isolated
/// (`GET /eld/daily-logs/{id}/team`). Shown only when today's log exists;
/// the note is the server's own text.
class _HosIsolationLine extends ConsumerWidget {
  const _HosIsolationLine({required this.loc});

  final AppLocalizations loc;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final team = ref.watch(teamStatusProvider);
    return team.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.xs),
        child: Text(
          loc.coDriverHosIsolationReadError,
          textAlign: TextAlign.center,
          style: context.styles.muted,
        ),
      ),
      data: (data) {
        if (data == null || data.hosRecordsIsolated == null) {
          return const SizedBox.shrink();
        }
        final isolated = data.hosRecordsIsolated!;
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Column(
            children: [
              Text(
                isolated ? loc.coDriverHosIsolated : loc.coDriverHosNotIsolated,
                textAlign: TextAlign.center,
                style: isolated ? context.styles.success : context.styles.error,
              ),
              if (data.complianceNote != null)
                Text(
                  data.complianceNote!,
                  textAlign: TextAlign.center,
                  style: context.styles.caption,
                ),
            ],
          ),
        );
      },
    );
  }
}
