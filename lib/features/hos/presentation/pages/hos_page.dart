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

class HosPage extends ConsumerWidget {
  const HosPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosState = ref.watch(hosStatusProvider);
    final limits = hosState.limits;

    // ط­ط³ط§ط¨ ط§ظ„ظˆظ‚طھ ط§ظ„ظ…طھط¨ظ‚ظٹ ظ„ظٹط¹ط±ط¶ ظپظٹ ط§ظ„ط¯ط§ط¦ط±ط©
    // ط¨ط§ظ„ط¹ط§ط¯ط© ظٹط¹ط±ط¶ ط£ظ‚ظ„ ظˆظ‚طھ ظ…طھط¨ظ‚ظٹ ظٹظˆظ‚ظپ ط§ظ„ط³ط§ط¦ظ‚
    int remainingMinutes;
    if (hosState.currentStatus == DutyStatus.driving) {
      remainingMinutes = limits.remainingDriveMinutes;
      // ط§ظ„طھط£ظƒط¯ ظ…ظ† ط§ط³طھط±ط§ط­ط© ط§ظ„ظ€ 8 ط³ط§ط¹ط§طھ
      if (limits.breakRequired && limits.breakRemainingMinutes > 0) {
        // ط¥ط°ط§ ظƒط§ظ† ظٹط­طھط§ط¬ ط§ط³طھط±ط§ط­ط© ط§ظ„ط¢ظ†
        remainingMinutes = 0;
      }
    } else {
      remainingMinutes = limits.remainingShiftMinutes;
    }

    final timeString = remainingMinutes.toHoursMinutes();
    final maxMinutes = (hosState.currentStatus == DutyStatus.driving) ? (11 * 60) : (14 * 60);
    final progress = remainingMinutes / maxMinutes;

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // ط¨ط·ط§ظ‚ط© ط§ظ„طھظ†ط¨ظٹظ‡ط§طھ ظˆط§ظ„ط£ط¹ط·ط§ظ„
                  const DiagnosticsAlertCard(),

                  // ط§ظ„ظ‚ط³ظ… ط§ظ„ط¹ظ„ظˆظٹ
                  Stack(
                    children: [
                      // ط²ط± ط­ط§ظ„ط© ط§ظ„ظ†ظˆظ… (ط§ظ„ظ„ظˆظ† ط§ظ„ط£ط²ط±ظ‚ ظپظٹ ط§ظ„طµظˆط±ط©)
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

                      // ط§ظ„ط¯ط§ط¦ط±ط© ط§ظ„ظ…ط±ظƒط²ظٹط©
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 32, bottom: 24),
                          child: MainCircularTimer(
                            timeString: timeString,
                            statusText:
                                _getStatusText(hosState.currentStatus, context),
                            progress: progress.clamp(0.0, 1.0),
                            onTap: () {
                              _showStatusSelector(context);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ظ‚ط§ط¦ظ…ط© ط§ظ„ط³ط§ط¹ط§طھ
                  HosTimerList(status: hosState),
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
