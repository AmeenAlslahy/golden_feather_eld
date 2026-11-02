import 'package:flutter/material.dart';

import '../theme/app_density.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/golden_colors.dart';

/// بطاقة موحدة في تطبيق Golden Feather ELD تستمد ألوان الأسطح، الزوايا،
/// الظلال والحدود من طبقة الثيم المركزية مع المحافظة على توافق استخدامات الشاشات.
class EldCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Clip clipBehavior;
  final Color? color;
  final BorderSide? border;
  final AppDensity? density;

  const EldCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.clipBehavior = Clip.none,
    this.color,
    this.border,
    this.density,
  });

  /// مُنشئ سريع للبطاقات المدمجة (Compact Card) ذات الكثافة العالية
  const EldCard.compact({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.clipBehavior = Clip.none,
    this.color,
    this.border,
  }) : density = AppDensity.compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goldenColors =
        theme.extension<GoldenColors>() ??
        (isDark ? GoldenColors.dark : GoldenColors.light);

    final effectiveCardColor = color ??
        theme.cardTheme.color ??
        (isDark ? goldenColors.surfaceElevated : theme.colorScheme.surface);

    final effectiveBorderSide = border ??
        BorderSide(
          color: goldenColors.border,
          width: isDark ? 1.0 : 0.5,
        );

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: effectiveBorderSide,
    );

    final effectivePadding = padding ??
        (density?.cardPadding ?? const EdgeInsets.all(AppSpacing.cardPadding));

    return Card(
      clipBehavior: clipBehavior,
      color: effectiveCardColor,
      elevation: theme.cardTheme.elevation ?? (isDark ? 0.0 : 0.5),
      shadowColor: theme.cardTheme.shadowColor ??
          (isDark
              ? Colors.transparent
              : theme.colorScheme.onSurface.withValues(alpha: 0.05)),
      margin: margin ?? EdgeInsets.zero,
      shape: cardShape,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        splashColor: goldenColors.pressedOverlay,
        highlightColor: goldenColors.hoverOverlay,
        child: Padding(
          padding: effectivePadding,
          child: child,
        ),
      ),
    );
  }
}
