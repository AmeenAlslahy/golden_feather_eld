import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';

class StatusRadioGroup extends StatelessWidget {
  final String groupValue;
  final ValueChanged<String> onChanged;

  const StatusRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    // We use Short Codes as the values (OFF, SB, D, ON, PC, YM).
    final List<Map<String, String>> statuses = [
      {'value': 'OFF', 'label': context.loc.offDuty},
      {'value': 'SB', 'label': context.loc.sleeperBerth},
      {'value': 'D', 'label': context.loc.drivingStatus},
      {'value': 'ON', 'label': context.loc.onDuty},
      {'value': 'PC', 'label': context.loc.personalUse},
      {'value': 'YM', 'label': context.loc.yardMoves},
    ];

    return Column(
      children: statuses.map((status) {
        final isSelected = groupValue == status['value'];
        return Column(
          children: [
            RadioListTile<String>(
              title: Text(
                status['label']!,
                style: context.styles.body.copyWith(
                  fontWeight: isSelected ? AppTypography.semiBold : AppTypography.regular,
                  color: isSelected ? context.styles.gold.color : null,
                ),
              ),
              value: status['value']!,
              // ignore: deprecated_member_use
              groupValue: groupValue,
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) onChanged(value);
              },
              activeColor: AppColors.primaryGold,
              controlAffinity: ListTileControlAffinity.trailing,
              contentPadding: EdgeInsets.zero,
            ),
            Divider(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
              height: 1,
            ),
          ],
        );
      }).toList(),
    );
  }
}
