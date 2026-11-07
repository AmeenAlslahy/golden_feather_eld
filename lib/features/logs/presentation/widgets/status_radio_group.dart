import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../domain/entities/event_screen_options.dart';

class StatusRadioGroup extends StatelessWidget {
  final String groupValue;
  final ValueChanged<String> onChanged;
  final List<EventOptionStatus>? allowedStatuses;

  const StatusRadioGroup({
    super.key,
    required this.groupValue,
    required this.onChanged,
    this.allowedStatuses,
  });

  @override
  Widget build(BuildContext context) {
    // We use Short Codes as the values (OFF, SB, D, ON, PC, YM).
    final Map<String, String> statusLabels = {
      'OFF': context.loc.offDuty,
      'SB': context.loc.sleeperBerth,
      'D': context.loc.drivingStatus,
      'ON': context.loc.onDuty,
      'PC': context.loc.personalUse,
      'YM': context.loc.yardMoves,
    };

    final List<Map<String, String>> statuses;
    if (allowedStatuses != null && allowedStatuses!.isNotEmpty) {
      final resolved = <Map<String, String>>[];
      for (final option in allowedStatuses!) {
        final code = option.dutyStatusCode?.shortCode ?? option.code;
        final label = statusLabels[code] ?? code;
        if (!resolved.any((s) => s['value'] == code)) {
          resolved.add({'value': code, 'label': label});
        }
      }
      // إذا كانت الحالة الحالية غير مدرجة، نبقيها لتظهر للمستخدم دون فقد
      if (!resolved.any((s) => s['value'] == groupValue) &&
          statusLabels.containsKey(groupValue)) {
        resolved.add({'value': groupValue, 'label': statusLabels[groupValue]!});
      }
      statuses = resolved;
    } else {
      statuses = [
        {'value': 'OFF', 'label': context.loc.offDuty},
        {'value': 'SB', 'label': context.loc.sleeperBerth},
        {'value': 'D', 'label': context.loc.drivingStatus},
        {'value': 'ON', 'label': context.loc.onDuty},
        {'value': 'PC', 'label': context.loc.personalUse},
        {'value': 'YM', 'label': context.loc.yardMoves},
      ];
    }

    return Column(
      children: statuses.map((status) {
        final isSelected = groupValue == status['value'];
        return Column(
          children: [
            RadioListTile<String>(
              title: Text(
                status['label']!,
                style: context.styles.body.copyWith(
                  fontWeight: isSelected
                      ? AppTypography.semiBold
                      : AppTypography.regular,
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
              activeColor: context.gold,
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
