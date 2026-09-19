import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import 'package:golden_feather_eld/core/extensions/time_extensions.dart';
import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/hos/domain/engine/hos_state_machine.dart';

class HosTimerList extends ConsumerWidget {
  final HosStatusUpdate status;

  const HosTimerList({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limits = status.limits;
    final config = ref.watch(hosConfigurationProvider);
    final cycleMinutes = (limits.remainingCycleHours * 60).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // شريط العنوان
        Container(
          color: Theme.of(context).colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 16),
          alignment: Alignment.center,
          child: const Text(
            'HOURS OF SERVICE',
            style: TextStyle(
              fontSize: 13,
              fontWeight: AppTypography.regular,
              letterSpacing: 0.5,
            ),
          ),
        ),

        // القائمة
        Container(
          color: AppColors.surface,
          child: Column(
            children: [
              _buildRow(
                title: context.loc.driveLimitTitle,
                subtitle: context.loc.driveLimitDesc,
                time: limits.remainingDriveMinutes.toHoursMinutes(),
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildRow(
                title: context.loc.shiftLimitTitle,
                subtitle: context.loc.shiftLimitDesc,
                time: limits.remainingShiftMinutes.toHoursMinutes(),
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildRow(
                title: context.loc.breakLimitTitle,
                subtitle: context.loc.breakLimitDesc,
                time: (limits.breakRemainingMinutes > 0
                        ? limits.breakRemainingMinutes
                        : config.driveBeforeBreakMinutes)
                    .toHoursMinutes(), // مؤقت لعرض وقت الاستراحة
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildRow(
                title: context.loc.cycleLimitTitle,
                subtitle: context.loc.cycleLimitDesc,
                time: cycleMinutes.toHoursMinutes(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow({
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: AppTypography.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: AppTypography.regular,
                ),
              ),
            ],
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: AppTypography.regular,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
