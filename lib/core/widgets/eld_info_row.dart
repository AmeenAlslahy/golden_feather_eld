import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_spacing.dart';

/// صف معلومات - عنوان رمادي على اليسار، قيمة سوداء على اليمين
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
    final rowStyle = dense ? context.styles.subtitle : context.styles.body;

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
          vertical: dense ? AppSpacing.sm : AppSpacing.rowVertical,
          horizontal: AppSpacing.rowHorizontal,
        ),
        child: Row(
          children: [
            // العنوان - رمادي
            Expanded(
              flex: 2,
              child: Text(
                label,
                style: rowStyle.copyWith(
                  color: context.styles.subtitle.color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // القيمة - أسود
            Expanded(
              flex: 3,
              child: Text(
                value,
                textAlign: TextAlign.start,
                style: valueColor == null
                    ? rowStyle
                    : rowStyle.copyWith(color: valueColor),
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
