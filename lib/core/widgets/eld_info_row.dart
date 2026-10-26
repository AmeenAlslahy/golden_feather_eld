import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// صف معلومات - عنوان رمادي على اليسار، قيمة على اليمين
class EldInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;

  const EldInfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
    this.onTap,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final fontSize = dense
        ? AppTypography.subtitleSize
        : AppTypography.bodySize;
    final verticalPadding = dense
        ? AppSpacing.rowVerticalCompact
        : AppSpacing.rowVertical;

    return InkWell(
      onTap: onTap,
      splashColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.12),
      highlightColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.06),
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: verticalPadding,
          horizontal: AppSpacing.rowHorizontal,
        ),
        child: Row(
          children: [
            // العنوان الفرعي - رمادي نصف غامق
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
            // المحتوى / القيمة - أساسي عادي
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.start,
                style: context.styles.body.copyWith(
                  fontSize: fontSize,
                  color: valueColor ?? context.textPrimary,
                  fontWeight: AppTypography.regular,
                ),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
