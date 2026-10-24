import 'package:flutter/material.dart';

import '../../../../../core/config/hos_configuration.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/eld_info_row.dart';
import '../../utils/account_display.dart';

class DailyLimitsSection extends StatelessWidget {
  final HosConfiguration limits;

  const DailyLimitsSection({super.key, required this.limits});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.rowHorizontal,
            vertical: AppSpacing.compact,
          ),
          child: Text(loc.dailyLimits, style: context.styles.sectionTitle),
        ),
        EldInfoRow(
          label: loc.drivingLimit,
          value: formatHoursMinutes(loc, limits.drivingLimitMinutes),
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(
          label: loc.shiftWindowLimit,
          value: formatHoursMinutes(loc, limits.shiftLimitMinutes),
        ),
        Divider(color: context.border, height: AppSpacing.dividerHeight),
        EldInfoRow(
          label: loc.cycleLimit,
          value: '${limits.cycleLimitHours} / ${limits.maxConsecutiveDays}',
        ),
      ],
    );
  }
}
