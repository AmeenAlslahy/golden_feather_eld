import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class HosTimerList extends StatelessWidget {
  final HosStatusUpdate status;

  const HosTimerList({
    super.key,
    required this.status,
  });

  String _formatMinutes(int totalMinutes) {
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final limits = status.limits;
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
                title: 'DRIVE',
                subtitle: '11-Hour Driving Limit',
                time: _formatMinutes(limits.remainingDriveMinutes),
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildRow(
                title: 'SHIFT',
                subtitle: '14-Hour On Duty Limit',
                time: _formatMinutes(limits.remainingShiftMinutes),
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildRow(
                title: 'BREAK',
                subtitle: '30 Minute Rest Break',
                time: _formatMinutes(limits.breakRemainingMinutes > 0
                    ? limits.breakRemainingMinutes
                    : 8 * 60), // مؤقت لعرض وقت الاستراحة
              ),
              const Divider(height: 1, color: AppColors.border),
              _buildRow(
                title: 'CYCLE',
                subtitle: 'USA 70/8',
                time: _formatMinutes(cycleMinutes),
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
