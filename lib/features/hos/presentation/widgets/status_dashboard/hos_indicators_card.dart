import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';
import '../../../../../core/utils/duration_format.dart';

/// "HOURS OF SERVICE" table with the four HOS indicators
/// (drive, shift, break, cycle) — reference layout (screenshot 1):
/// grey header row, then label / limit description on the left and the
/// large HH:MM value on the right.
class HosIndicatorsCard extends StatelessWidget {
  final HosIndicators indicators;

  /// Rule set and legal limits applied by the server (SRS 4.x); they feed
  /// the description line under each label ("11-Hour Driving Limit").
  final RegulatoryConstraints? constraints;

  const HosIndicatorsCard({
    super.key,
    required this.indicators,
    this.constraints,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final descriptions = _descriptions(context);
    return Column(
      children: [
        Container(
          width: double.infinity,
          // الشريط تحت دائرة الوقت: كان يستخدم رمز الخلفية الفاتحة فيظهر
          // أبيض في الوضع الداكن (بلاغ المالك).
          color: context.colorScheme.surface,
          padding: const EdgeInsets.symmetric(vertical: 18),
          child: Text(
            loc.hoursOfService,
            textAlign: TextAlign.center,
            style: context.styles.body,
          ),
        ),
        const Divider(height: 1, color: AppColors.border),
        _IndicatorRow(
          indicator: indicators.drive,
          description: descriptions[0],
        ),
        const Divider(height: 1, color: AppColors.border),
        _IndicatorRow(
          indicator: indicators.shift,
          description: descriptions[1],
        ),
        const Divider(height: 1, color: AppColors.border),
        _IndicatorRow(
          indicator: indicators.breakTime,
          description: descriptions[2],
        ),
        const Divider(height: 1, color: AppColors.border),
        _IndicatorRow(
          indicator: indicators.cycle,
          description: descriptions[3],
        ),
        const Divider(height: 1, color: AppColors.border),
      ],
    );
  }

  /// Drive / shift / break / cycle descriptions. Server limits win when they
  /// carry a number (e.g. `maxDrivingHours: 11`, `Hour Driving Limit-11`);
  /// otherwise the localized reference wording is used.
  List<String> _descriptions(BuildContext context) {
    final loc = context.loc;
    final drive = constraints?.limitHoursFor(['driving', 'drive']);
    final shift = constraints?.limitHoursFor(['shift', 'onduty', 'on duty', 'on_duty']);
    final rest = constraints?.limitHoursFor(['break']);
    final ruleSet = constraints?.ruleSet ?? CycleRule.unknown;

    return [
      drive == null
          ? loc.driveLimitDesc
          : loc.driveLimitFormat(drive),
      shift == null
          ? loc.shiftLimitDesc
          : loc.shiftLimitFormat(shift),
      rest == null
          ? loc.breakLimitDesc
          : loc.breakLimitFormat(rest),
      ruleSet == CycleRule.unknown ? loc.cycleLimitDesc : ruleSet.wire,
    ];
  }
}

class _IndicatorRow extends StatelessWidget {
  final HosIndicator indicator;
  final String description;

  const _IndicatorRow({required this.indicator, required this.description});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final isCritical = indicator.type == IndicatorType.remaining &&
        indicator.value <= const Duration(hours: 1);
    // The reference shows remaining time; a "used" value is marked so the
    // driver never reads a consumed figure as time left.
    final detail = indicator.type == IndicatorType.used
        ? loc.usedFormat(description)
        : description;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  indicator.label,
                  style: context.styles.sectionTitle.copyWith(
                      fontSize: 18,
                      color: context.styles.subtitle.color,
                    ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: context.styles.subtitle.copyWith(fontSize: 15),
                ),
              ],
            ),
          ),
          Expanded(
            child: Text(
              DurationFormat.hhMm(indicator.value),
              textAlign: TextAlign.end,
              style: context.styles.body.copyWith(
                fontSize: 34,
                color: isCritical
                    ? context.styles.error.color
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

}
