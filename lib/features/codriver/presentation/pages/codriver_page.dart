import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../../hos/domain/engine/hos_rules_engine.dart';
import '../../../hos/presentation/providers/hos_engine_provider.dart';
import '../../../hos/presentation/providers/hos_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../domain/entities/codriver.dart';
import '../../domain/role_switch_guard.dart';
import '../providers/codriver_provider.dart';

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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final brightness = Theme.of(context).brightness;
    final bgColor = AppColors.backgroundFor(brightness);
    final surfaceColor = AppColors.surfaceFor(brightness);
    final textColor = AppColors.textPrimaryFor(brightness);
    final textSecondaryColor = AppColors.textSecondaryFor(brightness);

    final selfId = ref.watch(currentDriverIdProvider)?.toString();
    final drivers = [
      CoDriver.none,
      ...codriverState.availableDrivers.where((d) => d.id != selfId),
    ];

    final currentSelectedId =
        _selectedId ?? codriverState.selectedCoDriver?.id ?? 'none';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          loc.coDriver,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.surface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            tooltip: isArabic ? 'تحديث' : 'Refresh',
            icon: const Icon(Icons.refresh, color: AppColors.surface),
            onPressed: codriverState.isLoading
                ? null
                : () => ref.read(codriverProvider.notifier).reload(),
          ),
        ],
      ),
      drawer: const EldDrawer(),
      body: codriverState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => ref.read(codriverProvider.notifier).reload(),
              child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: 48.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    isArabic ? 'اختر مساعد السائق' : 'Select Co-driver',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    isArabic
                        ? 'الرجاء اختيار مساعد السائق الخاص بك'
                        : 'Select your co-driver',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: 32.0),

                  // Selector Row
                  InkWell(
                    onTap: () => _showDriverSelectionDialog(context, drivers,
                        currentSelectedId, isArabic, textColor, surfaceColor),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                      decoration: BoxDecoration(
                        border: Border(
                            bottom: BorderSide(
                                color:
                                    AppColors.borderFor(brightness))),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              _driverLabel(
                                drivers.firstWhere(
                                  (d) => d.id == currentSelectedId,
                                  orElse: () => CoDriver.none,
                                ),
                                isArabic,
                              ).toUpperCase(),
                              style: TextStyle(
                                fontSize: 16,
                                color: textColor,
                              ),
                            ),
                          ),
                          Icon(Icons.keyboard_arrow_down, color: textColor),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 60),

                  Text(
                    isArabic ? 'تبديل الأدوار' : 'Switch Drivers',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    isArabic
                        ? 'ستصبح السائق المساعد. سيصبح مساعدك السائق.'
                        : 'You will become the co-driver. Your co-driver will become the driver.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _LinkedCoDriver(state: codriverState, isArabic: isArabic),
                  if (codriverState.error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      codriverState.error!,
                      textAlign: TextAlign.center,
                      style: context.styles.error,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.xl),
                  if (codriverState.isSwitching)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: Text(
                        isArabic ? 'جاري التبديل...' : 'Switching...',
                      ),
                    ),

                  // Switch Button
                  AppButton(
                    label: isArabic ? 'تبديل' : 'SWITCH',
                    type: EldButtonType.agree,
                    isLoading: codriverState.isSwitching,
                    onPressed: (codriverState.isSwitching ||
                            codriverState.selectedCoDriver == null)
                        ? null
                        : () async {
                            final hos = ref.read(hosStatusProvider);
                            final driving = hos is HosEngineReady
                                ? hos.update.currentStatus == DutyStatus.driving
                                : null;
                            final refusal = refuseRoleSwitch(
                              currentDriverId: ref.read(currentDriverIdProvider),
                              coDriverId: codriverState.selectedCoDriver?.id,
                              speedMps: ref.read(currentVehicleSpeedProvider),
                              thresholdKmh: ref
                                  .read(hosConfigurationProvider)
                                  .movingSpeedThresholdKmh,
                              currentStatusIsDriving: driving,
                            );
                            if (refusal != null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_refusalText(refusal, isArabic)),
                                ),
                              );
                              return;
                            }
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text(isArabic
                                    ? 'تأكيد التبديل'
                                    : 'Confirm Switch'),
                                content: Text(
                                  isArabic
                                      ? 'يطلب التبديل من الخادم فقط. لن تُنقل ساعات الخدمة ولن تتغير حالة الواجب.'
                                      : 'This asks the server to switch roles. Hours are not copied and duty status is not changed.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () =>
                                        Navigator.pop(context, false),
                                    child: Text(
                                        MaterialLocalizations.of(context)
                                            .cancelButtonLabel),
                                  ),
                                  FilledButton(
                                    onPressed: () =>
                                        Navigator.pop(context, true),
                                    child: Text(
                                        MaterialLocalizations.of(context)
                                            .okButtonLabel),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true && mounted) {
                              final error = await ref
                                  .read(codriverProvider.notifier)
                                  .switchDrivers();
                              if (!context.mounted) return;
                              if (error != null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(error)),
                                );
                                return;
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isArabic
                                        ? 'قبل الخادم التبديل. لم تُنقل الساعات ولم تتغير حالة الواجب. يضبط السائق الجديد حالته قبل الحركة.'
                                        : 'The server accepted the switch. Hours were not copied and duty status was not changed. The new driver sets duty before moving.',
                                  ),
                                  backgroundColor: AppColors.successGreen,
                                ),
                              );
                              context.go('/home');
                            }
                          },
                  ),
                ],
              ),
            ),
            ),
    );
  }

  void _showDriverSelectionDialog(BuildContext context, List<CoDriver> drivers,
      String currentId, bool isArabic, Color textColor, Color surfaceColor) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // Local state for the dialog radio buttons before pressing OK
        String dialogSelectedId = currentId;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: surfaceColor,
              title: Text(
                isArabic ? 'مساعد السائق' : 'Co-driver',
                style:
                    TextStyle(color: textColor, fontWeight: FontWeight.normal),
              ),
              contentPadding: const EdgeInsets.only(top: 16),
              content: SizedBox(
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
                          _driverLabel(driver, isArabic).toUpperCase(),
                          style: TextStyle(
                            color: dialogSelectedId == driver.id
                                ? AppColors.primaryGold
                                : textColor,
                            fontSize: 14,
                          ),
                        ),
                        value: driver.id,
                        activeColor: AppColors.primaryGold,
                      );
                    },
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    isArabic ? 'إلغاء' : 'CANCEL',
                    style: const TextStyle(color: AppColors.primaryGold),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final selected =
                        drivers.firstWhere((d) => d.id == dialogSelectedId);
                    final uniqueId =
                        ref.read(vehicleProvider).selectedVehicle?.uniqueId;
                    final error = await ref
                        .read(codriverProvider.notifier)
                        .applySessionCoDriver(
                          driver: selected,
                          uniqueId: uniqueId,
                        );
                    if (!context.mounted) return;
                    if (error != null) {
                      final text = error == 'vehicle_identifier_missing'
                          ? (isArabic
                              ? 'اختر مركبة قبل ربط السائق المساعد.'
                              : 'Select a vehicle before linking a co-driver.')
                          : error;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(text)),
                      );
                      return;
                    }
                    setState(() {
                      _selectedId = dialogSelectedId;
                    });
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    isArabic ? 'موافق' : 'OK',
                    style: const TextStyle(color: AppColors.primaryGold),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

String _driverLabel(CoDriver driver, bool isArabic) {
  if (driver.id == CoDriver.none.id) {
    return isArabic ? 'لا سائق مساعد' : 'No co-driver';
  }
  return driver.name;
}

String _refusalText(RoleSwitchRefusal refusal, bool isArabic) {
  switch (refusal) {
    case RoleSwitchRefusal.sessionMissing:
      return isArabic
          ? 'جلسة السائق غير موجودة. سجّل الدخول قبل التبديل.'
          : 'Driver session is missing. Sign in before switching.';
    case RoleSwitchRefusal.stillDriving:
      return isArabic
          ? 'غيّر حالة الواجب قبل التسليم. التبديل لا يغيّر الحالة.'
          : 'Change duty status before handover. The switch does not change it.';
    case RoleSwitchRefusal.motionUnknown:
      return isArabic
          ? 'حركة المركبة غير معروفة. لا يُعدّ ذلك توقفاً.'
          : 'Vehicle motion is unknown. That is not treated as stopped.';
    case RoleSwitchRefusal.thresholdMissing:
      return isArabic
          ? 'عتبة الحركة غير متوفرة من الإعداد.'
          : 'The motion threshold is not available.';
    case RoleSwitchRefusal.vehicleMoving:
      return isArabic
          ? 'لا يمكن تبديل الأدوار والمركبة تتحرك.'
          : 'Roles can be switched only when the vehicle is stopped.';
    case RoleSwitchRefusal.coDriverMissing:
      return isArabic
          ? 'اختر سائقاً مساعداً قبل التبديل.'
          : 'Select a co-driver before switching.';
    case RoleSwitchRefusal.sameDriver:
      return isArabic
          ? 'لا يمكن اختيار الحساب الحالي سائقاً مساعداً.'
          : 'The current account cannot be selected as the co-driver.';
  }
}

class _LinkedCoDriver extends StatelessWidget {
  final CoDriverState state;
  final bool isArabic;

  const _LinkedCoDriver({required this.state, required this.isArabic});

  @override
  Widget build(BuildContext context) {
    final linked = state.currentCoDriver;
    final String value;
    if (state.currentError != null) {
      value = state.currentError!;
    } else if (linked == null) {
      value = isArabic ? 'لم يُقرأ الارتباط بعد.' : 'The link has not been read.';
    } else if (!linked.isLinked) {
      value = isArabic ? 'لا سائق مساعد مرتبط.' : 'No linked co-driver.';
    } else {
      value = linked.name ?? linked.coDriverId.toString();
    }
    // SRS 10.3: the team state is read from the server link
    // (`teamDrivingActive`); the app does not infer who is driving.
    final AppStatusBadge? teamBadge = (linked != null && linked.isLinked)
        ? (linked.teamDrivingActive
            ? AppStatusBadge(
                label: isArabic ? 'قيادة جماعية نشطة' : 'Team driving active',
                type: AppStatusBadgeType.success,
              )
            : AppStatusBadge(
                label: isArabic ? 'قيادة جماعية غير نشطة' : 'Team driving inactive',
                type: AppStatusBadgeType.warning,
              ))
        : null;
    return Column(
      children: [
        Text(
          isArabic ? 'المساعد المرتبط' : 'Linked co-driver',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: state.currentError == null
                ? AppColors.textSecondary
                : AppColors.dangerRed,
          ),
        ),
        if (teamBadge != null) ...[
          const SizedBox(height: AppSpacing.xs),
          teamBadge,
        ],
      ],
    );
  }
}
