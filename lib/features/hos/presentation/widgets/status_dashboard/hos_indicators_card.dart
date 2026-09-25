import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';

import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/eld_card.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';

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
                  style: context.styles.bodyBold,
                ),
                const SizedBox(height: 2),
                Text(
                  indicator.type == IndicatorType.used
                      ? 'Used'
                      : 'Remaining',
                  style: context.styles.caption,
                ),
              ],
            ),
          ),
          Text(
            _formatDuration(indicator.value),
            style: context.styles.number.copyWith(
              fontSize: 24,
              color: isCritical
                  ? context.styles.error.color
                  : context.styles.number.color,
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
