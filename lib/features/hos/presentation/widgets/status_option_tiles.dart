import 'package:flutter/material.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';

class StatusOptionTile extends StatelessWidget {
  final DutyStatus status;
  final String label;
  final bool isSelected;
  final bool isLast;
  final VoidCallback? onTap;

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
    final enabled = onTap != null;

    return Column(
      children: [
        InkWell(
          onTap: onTap,
          splashColor: Colors.black.withValues(alpha: 0.14),
          highlightColor: Colors.black.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                      color: !enabled || (isDriving && !isSelected)
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.38)
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isSelected
                      ? context.styles.gold.color
                      : theme.dividerColor,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(
              height: 1,
              indent: AppSpacing.lg,
              endIndent: AppSpacing.lg,
              color: theme.dividerColor.withValues(alpha: 0.5)),
      ],
    );
  }
}

class YardMovesOptionTile extends StatelessWidget {
  final bool isYardMoves;
  final VoidCallback? onTap;

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
            indent: AppSpacing.lg,
            endIndent: AppSpacing.lg,
            color: theme.dividerColor.withValues(alpha: 0.5)),
        InkWell(
          onTap: onTap,
          splashColor: Colors.black.withValues(alpha: 0.14),
          highlightColor: Colors.black.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    loc.yardMoves,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight:
                          isYardMoves ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
                Icon(
                  isYardMoves
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: isYardMoves
                      ? context.styles.gold.color
                      : theme.dividerColor,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
