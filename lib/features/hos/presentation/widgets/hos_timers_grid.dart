import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/engine/hos_calculator.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/countdown_wheel.dart';
import '../providers/hos_provider.dart';

class HosTimersGrid extends ConsumerWidget {
  const HosTimersGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(hosStatusProvider);
    final limits = status.limits;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 600 ? 4 : 2;
        final wheelSize = (constraints.maxWidth / crossAxisCount) - AppSpacing.lg;

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.8,
          children: [
            _buildWheel(
              label: 'القيادة (Drive)',
              minutes: limits.remainingDriveMinutes,
              maxMinutes: HosCalculator.maxDriveMinutes,
              color: AppColors.success,
              size: wheelSize,
            ),
            _buildWheel(
              label: 'الوردية (Shift)',
              minutes: limits.remainingShiftMinutes,
              maxMinutes: HosCalculator.maxShiftMinutes,
              color: AppColors.primary,
              size: wheelSize,
            ),
            _buildWheel(
              label: 'الدورة (Cycle)',
              minutes: (limits.remainingCycleHours * 60).toInt(),
              maxMinutes: HosCalculator.maxCycleHours * 60,
              color: AppColors.secondary,
              size: wheelSize,
            ),
            _buildWheel(
              label: 'الاستراحة (Break)',
              minutes: limits.breakRemainingMinutes,
              maxMinutes: HosCalculator.requiredBreakMinutes,
              color: limits.breakRequired ? AppColors.warning : AppColors.textSecondaryLight,
              size: wheelSize,
            ),
          ],
        );
      },
    );
  }

  Widget _buildWheel({
    required String label,
    required int minutes,
    required int maxMinutes,
    required Color color,
    required double size,
  }) {
    final progress = (minutes / maxMinutes).clamp(0.0, 1.0);
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    final timeString = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';

    return CountdownWheel(
      label: label,
      remainingTime: timeString,
      progress: progress,
      color: progress < 0.1 ? AppColors.error : color,
      size: size,
    );
  }
}



