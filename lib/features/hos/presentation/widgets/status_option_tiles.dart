import 'package:flutter/material.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class StatusOptionTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final bool isLast;
  final bool enabled;
  final VoidCallback? onTap;

  const StatusOptionTile({
    super.key,
    required this.label,
    required this.isSelected,
    required this.isLast,
    this.enabled = true,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isClickable = enabled && onTap != null;

    final radioColor = isSelected
        ? context.gold
        : (!enabled
            ? context.textSecondary.withValues(alpha: 0.25)
            : context.textSecondary.withValues(alpha: 0.5));

    final textColor = !enabled
        ? context.textSecondary.withValues(alpha: 0.38)
        : (isSelected ? context.goldenColors.primaryText : null);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: isSelected
              ? context.gold.withValues(alpha: 0.08)
              : Colors.transparent,
          child: InkWell(
            onTap: isClickable ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.compact + 2,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: context.styles.body.copyWith(
                        fontWeight: isSelected
                            ? AppTypography.bold
                            : AppTypography.medium,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(
                    isSelected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: radioColor,
                    size: AppSpacing.iconMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (!isLast)
          Divider(
            height: 1,
            thickness: 1,
            color: context.border.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}

