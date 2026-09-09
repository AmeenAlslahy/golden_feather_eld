import 'package:golden_feather_eld/features/hos/domain/engine/hos_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/hos_provider.dart';
import '../widgets/main_circular_timer.dart';
import '../widgets/hos_timer_list.dart';
import '../pages/change_status_page.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/time_extensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../widgets/diagnostics_alert_card.dart';
import '../../../../features/hos/domain/engine/hos_rules_engine.dart';

class HosPage extends ConsumerWidget {
  const HosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosEngineState = ref.watch(hosStatusProvider);

    // Default fallback values if time is untrusted
    DutyStatus currentStatus = DutyStatus.offDuty;
    int remainingMinutes = 0;
    String timeString = '--:--';
    double progress = 0.0;
    HosStatusUpdate? activeUpdate;
    bool isUntrusted = false;

    if (hosEngineState is HosEngineReady) {
      activeUpdate = hosEngineState.update;
      currentStatus = activeUpdate.currentStatus;
      final limits = activeUpdate.limits;

      if (currentStatus == DutyStatus.driving) {
        remainingMinutes = limits.remainingDriveMinutes;
        if (limits.breakRequired && limits.breakRemainingMinutes > 0) {
          remainingMinutes = 0;
        }
      } else {
        remainingMinutes = limits.remainingShiftMinutes;
      }

      timeString = remainingMinutes.toHoursMinutes();
      final maxMinutes =
          (currentStatus == DutyStatus.driving) ? (11 * 60) : (14 * 60);
      progress = remainingMinutes / maxMinutes;
    } else if (hosEngineState is HosEngineTimeUnavailable) {
      isUntrusted = true;
      timeString = 'Error';
    }

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const DiagnosticsAlertCard(),
                  if (isUntrusted)
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.red.shade100,
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red),
                          SizedBox(width: 8),
                          Expanded(
                              child: Text(
                                  'Trusted time is unavailable. HOS calculations suspended.',
                                  style: TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                  Stack(
                    children: [
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Material(
                          color: AppColors.primaryBlue,
                          shape: const CircleBorder(),
                          elevation: 2,
                          child: InkWell(
                            onTap: () {
                              ref
                                  .read(themeModeProvider.notifier)
                                  .toggleTheme();
                            },
                            customBorder: const CircleBorder(),
                            child: const Padding(
                              padding: EdgeInsets.all(12),
                              child: Icon(
                                Icons.brightness_2,
                                color: AppColors.surface,
                                size: 28,
                              ),
                            ),
                          ),
                        ),
                      ),
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32, bottom: 24),
                          child: MainCircularTimer(
                            timeString: timeString,
                            statusText: _getStatusText(currentStatus, context),
                            progress: progress.clamp(0.0, 1.0),
                            onTap: () {
                              _showStatusSelector(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (activeUpdate != null) HosTimerList(status: activeUpdate),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showStatusSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const Padding(
        padding: EdgeInsets.only(top: kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: ChangeStatusPage(),
        ),
      ),
    );
  }

  String _getStatusText(DutyStatus status, BuildContext context) {
    return switch (status) {
      DutyStatus.offDuty => context.loc.offDuty,
      DutyStatus.sleeperBerth => context.loc.sleeperBerth,
      DutyStatus.driving => context.loc.drivingStatus,
      DutyStatus.onDutyNotDriving => context.loc.onDuty,
      DutyStatus.personalUse => context.loc.personalUse,
    };
  }
}
