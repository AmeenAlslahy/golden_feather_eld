import 'package:flutter/material.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_gap.dart';

class StatusOptionTile extends StatelessWidget {
  final DutyStatus status;
  final String label;
  final bool isSelected;
  final bool isLast;
  final VoidCallback onTap;

  const StatusOptionTile({
    super.key,
    required this.status,
    required this.label,
    required this.isSelected,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDriving = status == DutyStatus.driving;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                  size: 24,
                ),
                AppGap.hMd,
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isDriving && !isSelected
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.5)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              indent: AppSpacing.xxxl,
              endIndent: AppSpacing.lg,
              color: theme.dividerColor.withValues(alpha: 0.3)),
      ],
    );
  }
}

class YardMovesOptionTile extends StatelessWidget {
  final bool isYardMoves;
  final VoidCallback onTap;

  const YardMovesOptionTile({
    super.key,
    required this.isYardMoves,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = context.loc;

    return Column(
      children: [
        Divider(
            height: 1,
            indent: AppSpacing.xxxl,
            endIndent: AppSpacing.lg,
            color: theme.dividerColor.withValues(alpha: 0.3)),
        InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                AppGap.hXxl, // Indent to show it's a sub-option (36 = xxl)
                Icon(
                  isYardMoves ? Icons.check_box : Icons.check_box_outline_blank,
                  color: isYardMoves
                      ? theme.colorScheme.primary
                      : theme.dividerColor,
                  size: 24,
                ),
                AppGap.hMd,
                Expanded(
                  child: Text(
                    loc.yardMoves,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight:
                          isYardMoves ? FontWeight.bold : FontWeight.normal,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
