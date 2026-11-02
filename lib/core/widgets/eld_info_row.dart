import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';
import '../theme/app_density.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// صف معلومات يعرض عنصراً دلالياً (مفتاح / قيمة) وفق Design System 2.0.
///
/// يدعم:
/// - الوضع المضغوط عبر [dense] أو [density].
/// - أيقونة أو عنصر بادئ [leading].
/// - قيمة مخصصة [customValue] أو نصية [value].
/// - خط فاصل سفلي اختياري [showDivider].
/// - دعم إمكانية الوصول والتفاعل عبر [onTap].
class EldInfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final AppDensity? density;
  final Widget? leading;
  final Widget? customValue;
  final bool showDivider;

  const EldInfoRow({
    super.key,
    required this.label,
    this.value = '',
    this.valueColor,
    this.trailing,
    this.onTap,
    this.dense = false,
    this.density,
    this.leading,
    this.customValue,
    this.showDivider = false,
  });

  /// مُنشئ سريع للوضع المضغوط
  const EldInfoRow.compact({
    super.key,
    required this.label,
    this.value = '',
    this.valueColor,
    this.trailing,
    this.onTap,
    this.leading,
    this.customValue,
    this.showDivider = false,
  })  : dense = true,
        density = AppDensity.compact;

  @override
  Widget build(BuildContext context) {
    final isCompact = dense || (density?.isCompact ?? false);
    final fontSize = isCompact
        ? AppTypography.subtitleSize
        : AppTypography.bodySize;
    final verticalPadding = isCompact
        ? AppSpacing.rowVerticalCompact
        : AppSpacing.rowVertical;

    Widget content = InkWell(
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
            if (leading != null) ...[
              leading!,
              const SizedBox(width: AppSpacing.sm),
            ],
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
            // المحتوى / القيمة
            Expanded(
              flex: 3,
              child: customValue ??
                  Text(
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

    if (showDivider) {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          content,
          Divider(
            height: 1,
            thickness: 1,
            color: context.goldenColors.border,
          ),
        ],
      );
    }

    return Semantics(
      label: value.isNotEmpty ? '$label: $value' : label,
      button: onTap != null,
      enabled: onTap != null,
      child: content,
    );
  }
}

