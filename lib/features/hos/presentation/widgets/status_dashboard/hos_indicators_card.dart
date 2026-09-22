import 'package:flutter/material.dart';

import '../../../../../core/domain/duty_status/status_dashboard.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/widgets/app_gap.dart';
import '../../../../../core/widgets/eld_card.dart';

/// Card with the four HOS indicators (drive, shift, break, cycle).
class HosIndicatorsCard extends StatelessWidget {
  final HosIndicators indicators;

  const HosIndicatorsCard({
    super.key,
    required this.indicators,
  });

  @override
  Widget build(BuildContext context) {
    return EldCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          _IndicatorRow(indicator: indicators.drive),
          const Divider(height: 1, color: AppColors.border),
          _IndicatorRow(indicator: indicators.shift),
          const Divider(height: 1, color: AppColors.border),
          _IndicatorRow(indicator: indicators.breakTime),
          const Divider(height: 1, color: AppColors.border),
          _IndicatorRow(indicator: indicators.cycle),
        ],
      ),
    );
  }
}

class _IndicatorRow extends StatelessWidget {
  final HosIndicator indicator;

  const _IndicatorRow({required this.indicator});

  @override
  Widget build(BuildContext context) {
    final isCritical = indicator.type == IndicatorType.remaining &&
        indicator.value <= const Duration(hours: 1);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicator.label,
                  style: const TextStyle(
                    fontSize: AppTypography.bodySize,
                    fontWeight: AppTypography.bold,
                  ),
                ),
                const AppGap.custom(2),
                Text(
                  indicator.type == IndicatorType.used
                      ? 'Used'
                      : 'Remaining',
                  style: const TextStyle(
                    fontSize: AppTypography.smallSize,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDuration(indicator.value),
            style: TextStyle(
              fontSize: 24,
              fontWeight: AppTypography.bold,
              color: isCritical ? AppColors.dangerRed : AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  static String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }
}
