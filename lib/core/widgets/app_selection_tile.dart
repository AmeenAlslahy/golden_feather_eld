import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../theme/app_density.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import '../theme/golden_colors.dart';

/// بطاقة اختيار تفاعلية موحدة (Design System 2.0).
///
/// توحد إدارة حالات التحديد (Selected)، التعطيل (Disabled)، والضغط
/// مع الاعتماد المباشر على [GoldenColors.selectedContainer] و [GoldenColors.focusRing]،
/// وتضمن مساحة لمس أدنى 48.0 بكسل وتوافق كامل مع إمكانية الوصول.
class AppSelectionTile extends StatelessWidget {
  /// العنوان الرئيسي للخيار
  final String title;

  /// الوصف الفرعي تحت العنوان (اختياري)
  final String? subtitle;

  /// هل العنصر محدد حالياً؟
  final bool selected;

  /// هل العنصر متاح للاختيار والتفاعل؟
  final bool enabled;

  /// إجراء النقر عند تفعيل العنصر
  final VoidCallback? onTap;

  /// عنصر بادئ في أول السطر كأيقونة أو زر راديو مخصص (اختياري)
  final Widget? leading;

  /// عنصر تابع في نهاية السطر كأيقونة التحقق أو شارة (اختياري)
  final Widget? trailing;

  /// كثافة المحتوى (الافتراضي [AppDensity.comfortable])
  final AppDensity density;

  /// حشوة مخصصة إن وجدت
  final EdgeInsetsGeometry? padding;

  const AppSelectionTile({
    super.key,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.enabled = true,
    this.onTap,
    this.leading,
    this.trailing,
    this.density = AppDensity.comfortable,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goldenColors = context.goldenColors;

    // ─── حل الألوان حسب الحالة الدلالية ───
    final Color backgroundColor;
    final BorderSide borderSide;
    final Color titleColor;
    final Color subtitleColor;

    if (!enabled) {
      backgroundColor = goldenColors.disabledSurface;
      borderSide = BorderSide(
        color: goldenColors.inputBorder.withValues(alpha: 0.4),
        width: 1.0,
      );
      titleColor = goldenColors.disabledForeground;
      subtitleColor = goldenColors.disabledForeground;
    } else if (selected) {
      backgroundColor = goldenColors.selectedContainer;
      borderSide = BorderSide(
        color: goldenColors.focusRing,
        width: 1.5,
      );
      titleColor = isDark ? goldenColors.textPrimary : goldenColors.primaryText;
      subtitleColor = goldenColors.textSecondary;
    } else {
      backgroundColor = isDark
          ? goldenColors.surfaceElevated
          : theme.colorScheme.surface;
      borderSide = BorderSide(
        color: goldenColors.inputBorder,
        width: isDark ? 1.0 : 0.5,
      );
      titleColor = context.textPrimary;
      subtitleColor = goldenColors.textMuted;
    }

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
      side: borderSide,
    );

    final effectivePadding = padding ??
        EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: density.isCompact ? AppSpacing.sm : AppSpacing.md,
        );

    return Semantics(
      selected: selected,
      enabled: enabled,
      button: true,
      label: title,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: density.minTouchTarget,
        ),
        child: Material(
          color: backgroundColor,
          elevation: 0,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            splashColor: goldenColors.pressedOverlay,
            highlightColor: goldenColors.hoverOverlay,
            child: Padding(
              padding: effectivePadding,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: context.styles.body.copyWith(
                            color: titleColor,
                            fontWeight: selected
                                ? AppTypography.semiBold
                                : AppTypography.regular,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.space1),
                          Text(
                            subtitle!,
                            style: context.styles.caption.copyWith(
                              color: subtitleColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
