import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/hos_provider.dart';
import '../widgets/main_circular_timer.dart';
import '../widgets/hos_timer_list.dart';
import '../pages/change_status_page.dart';
// import '../../../../core/engine/hos_state_machine.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_theme_provider.dart';
import '../widgets/diagnostics_alert_card.dart';

class HosPage extends ConsumerWidget {
  const HosPage({super.key});

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hosState = ref.watch(hosStatusProvider);
    final limits = hosState.limits;

    // حساب الوقت المتبقي ليعرض في الدائرة
    // بالعادة يعرض أقل وقت متبقي يوقف السائق
    int remainingMinutes;
    if (hosState.currentStatus == DutyStatus.driving) {
      remainingMinutes = limits.remainingDriveMinutes;
      // التأكد من استراحة الـ 8 ساعات
      if (limits.breakRequired && limits.breakRemainingMinutes > 0) {
        // إذا كان يحتاج استراحة الآن
        remainingMinutes = 0;
      }
    } else {
      remainingMinutes = limits.remainingShiftMinutes;
    }

    final timeString = _formatMinutes(remainingMinutes);
    final progress =
        remainingMinutes / (11 * 60); // نسبة التقدم بناء على 11 ساعة (أو 14)

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // بطاقة التنبيهات والأعطال
                  const DiagnosticsAlertCard(),

                  // القسم العلوي
                  Stack(
                    children: [
                      // زر حالة النوم (اللون الأزرق في الصورة)
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

                      // الدائرة المركزية
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

                  // قائمة الساعات
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
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const ChangeStatusPage(),
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
