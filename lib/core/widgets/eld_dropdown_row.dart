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
  final bool dense;

  const EldDropdownRow({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    this.onChanged,
    this.enabled = true,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final safeValue = items.contains(value) ? value : items.first;
    final fontSize = dense
        ? AppTypography.subtitleSize
        : AppTypography.bodySize;
    final verticalPadding = dense
        ? AppSpacing.rowVerticalCompact
        : AppSpacing.rowVertical;

    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: verticalPadding,
        horizontal: AppSpacing.rowHorizontal,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: context.styles.subtitle.copyWith(
                fontSize: fontSize,
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
                isDense: true,
                value: safeValue,
                dropdownColor: Theme.of(context).colorScheme.surface,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  size: AppSpacing.iconMedium,
                  color: enabled ? context.textPrimary : context.textSecondary,
                ),
                onChanged: enabled ? onChanged : null,
                style: context.styles.body.copyWith(
                  fontSize: fontSize,
                  color: enabled ? context.textPrimary : context.textSecondary,
                  fontWeight: AppTypography.regular,
                ),
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
