import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// صف قائمة منسدلة موحد — يطابق أبعاد ومحاذاة [EldInfoRow] تماماً في الهوية البصرية.
class EldDropdownRow extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?>? onChanged;
  final bool enabled;

  const EldDropdownRow({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final safeValue = items.contains(value) ? value : items.first;

    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.rowVertical,
        horizontal: AppSpacing.rowHorizontal,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.styles.body.copyWith(
                color: context.textSecondary,
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: safeValue,
                dropdownColor: Theme.of(context).colorScheme.surface,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: enabled ? context.textPrimary : context.textSecondary,
                ),
                onChanged: enabled ? onChanged : null,
                style: context.styles.body,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(item, overflow: TextOverflow.ellipsis),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
