import 'package:flutter/material.dart';

import '../theme/app_radius.dart';
import '../theme/app_sizing.dart';
import '../theme/app_spacing.dart';
import '../theme/app_styles.dart';
import '../theme/golden_colors.dart';

/// الأدوار الدلالية لنظام الأزرار في Design System 2.0
enum AppButtonRole {
  /// الزر الأساسي بلون الهوية الذهبي
  primary,

  /// الزر الثانوي المؤطر (Outlined)
  secondary,

  /// الزر الثالثي أو الشفاف للإجراءات الخفيفة
  tertiary,

  /// زر الإجراءات الحرجة أو الحذف أو الرفض
  destructive,

  /// زر الإجراءات الإيجابية والاعتماد والاتصال
  success,
}

/// تعداد أنواع الأزرار المتوافق مع الاستخدامات السابقة والحالية
enum EldButtonType {
  /// الزر الأساسي بلون الهوية الذهبي (Golden Feather Primary Gold)
  primary,

  /// الزر الثانوي المؤطر (Outlined) بإطار ولون ذهبي أنيق وخلفية شفافة
  secondary,

  /// الزر الثالثي للإجراءات الخفيفة
  tertiary,

  /// الزر التحذيري أو الحذف أو الإلغاء الحرج (Danger Red)
  destructive,

  /// زر الإجراءات الإيجابية والاعتماد (Success Green)
  success,

  // أنواع التوافق الخلفي:
  connect,
  agree,
  danger,
  continueDisconnected,
  send,
  dark,
  muted;

  /// تعيين النوع إلى الدور الدلالي المقابل
  AppButtonRole get role => switch (this) {
    EldButtonType.primary || EldButtonType.send => AppButtonRole.primary,
    EldButtonType.secondary ||
    EldButtonType.continueDisconnected => AppButtonRole.secondary,
    EldButtonType.tertiary ||
    EldButtonType.dark ||
    EldButtonType.muted => AppButtonRole.tertiary,
    EldButtonType.destructive ||
    EldButtonType.danger => AppButtonRole.destructive,
    EldButtonType.success ||
    EldButtonType.connect ||
    EldButtonType.agree => AppButtonRole.success,
  };
}

/// اسم بديل متوافق لـ [EldButtonType]
typedef AppButtonType = EldButtonType;

/// زر موحد في التطبيق يستمد جميع خصائصه البصرية من الثيم المركزي،
/// مع دعم كامل لحالات Normal وPressed وDisabled وLoading في وضعي Light وDark.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final EldButtonType type;
  final bool isFullWidth;
  final bool isCompact;
  final IconData? icon;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = EldButtonType.primary,
    this.isFullWidth = true,
    this.isCompact = false,
    this.icon,
    this.isLoading = false,
  });

  /// مُنشئ سريع للزر الأساسي
  const AppButton.primary({
    super.key,
    required this.label,
    this.onPressed,
    this.isFullWidth = true,
    this.isCompact = false,
    this.icon,
    this.isLoading = false,
  }) : type = EldButtonType.primary;

  /// مُنشئ سريع للزر الثانوي
  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.isFullWidth = true,
    this.isCompact = false,
    this.icon,
    this.isLoading = false,
  }) : type = EldButtonType.secondary;

  /// مُنشئ سريع للزر الثالثي
  const AppButton.tertiary({
    super.key,
    required this.label,
    this.onPressed,
    this.isFullWidth = true,
    this.isCompact = false,
    this.icon,
    this.isLoading = false,
  }) : type = EldButtonType.tertiary;

  /// مُنشئ سريع لزر الحذف أو الخطر
  const AppButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.isFullWidth = true,
    this.isCompact = false,
    this.icon,
    this.isLoading = false,
  }) : type = EldButtonType.destructive;

  /// مُنشئ سريع للزر الإيجابي / النجاح
  const AppButton.success({
    super.key,
    required this.label,
    this.onPressed,
    this.isFullWidth = true,
    this.isCompact = false,
    this.icon,
    this.isLoading = false,
  }) : type = EldButtonType.success;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  AppButtonRole get _role => widget.type.role;

  bool get _isOutlined => _role == AppButtonRole.secondary;

  bool get _isTertiary => _role == AppButtonRole.tertiary;

  Color _baseColor(ThemeData theme, GoldenColors goldenColors) {
    if (_isOutlined) return Colors.transparent;
    if (_isTertiary) {
      return goldenColors.surfaceSecondary.withValues(alpha: 0.5);
    }
    return switch (_role) {
      AppButtonRole.primary => theme.colorScheme.primary,
      AppButtonRole.success => goldenColors.successText,
      AppButtonRole.destructive => theme.colorScheme.error,
      _ => theme.colorScheme.primary,
    };
  }

  Color _foregroundColor(ThemeData theme, GoldenColors goldenColors) {
    if (!_enabled) {
      return goldenColors.disabledForeground;
    }
    if (_isOutlined) {
      return goldenColors.primaryText;
    }
    if (_isTertiary) {
      return goldenColors.textMuted;
    }
    return switch (_role) {
      AppButtonRole.primary => theme.colorScheme.onPrimary,
      AppButtonRole.success => Colors.white,
      AppButtonRole.destructive => theme.colorScheme.onError,
      _ => theme.colorScheme.onPrimary,
    };
  }

  OutlinedBorder _shape(ThemeData theme, GoldenColors goldenColors) {
    final hasFocusRing = _focused && _enabled;
    if (_isOutlined) {
      final borderColor = !_enabled
          ? goldenColors.border.withValues(alpha: 0.5)
          : (hasFocusRing
              ? goldenColors.focusRing
              : goldenColors.primaryText);
      final borderWidth = hasFocusRing ? 2.5 : 1.5;
      return RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        side: BorderSide(color: borderColor, width: borderWidth),
      );
    }
    if (_isTertiary) {
      final borderColor = !_enabled
          ? goldenColors.border.withValues(alpha: 0.3)
          : (hasFocusRing ? goldenColors.focusRing : goldenColors.border);
      final borderWidth = hasFocusRing ? 2.0 : 1.0;
      return RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        side: BorderSide(color: borderColor, width: borderWidth),
      );
    }
    if (hasFocusRing) {
      return RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        side: BorderSide(
          color: goldenColors.focusRing,
          width: 2.0,
        ),
      );
    }
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goldenColors =
        theme.extension<GoldenColors>() ??
        (theme.brightness == Brightness.dark
            ? GoldenColors.dark
            : GoldenColors.light);

    final base = !_enabled
        ? (_isOutlined || _isTertiary
              ? Colors.transparent
              : goldenColors.disabledSurface)
        : _baseColor(theme, goldenColors);

    final overlay = _isOutlined || _isTertiary
        ? goldenColors.primaryText.withValues(alpha: 0.12)
        : (_role == AppButtonRole.destructive
              ? theme.colorScheme.onError.withValues(alpha: 0.2)
              : (_role == AppButtonRole.success
                    ? Colors.white.withValues(alpha: 0.2)
                    : theme.colorScheme.onPrimary.withValues(alpha: 0.2)));

    Color color;
    if (!_enabled) {
      color = base;
    } else if (_pressed) {
      color = _isOutlined || _isTertiary
          ? overlay
          : Color.alphaBlend(goldenColors.pressedOverlay, base);
    } else if (_hovered) {
      final hoverBlend = goldenColors.hoverOverlay;
      color = _isOutlined || _isTertiary
          ? hoverBlend
          : Color.alphaBlend(hoverBlend, base);
    } else {
      color = base;
    }

    final targetHeight = widget.isCompact || _isOutlined || _isTertiary
        ? AppSizing.buttonCompactHeight
        : AppSizing.buttonHeight;

    final foreground = _foregroundColor(theme, goldenColors);
    final shape = _shape(theme, goldenColors);

    final textScaler =
        MediaQuery.maybeTextScalerOf(context) ?? TextScaler.noScaling;
    final isScaled = textScaler.scale(1.0) > 1.15;

    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      height: isScaled ? null : targetHeight,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: targetHeight),
        child: Material(
          color: color,
          elevation: 0,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: _enabled ? widget.onPressed : null,
            onHighlightChanged: (value) {
              if (_pressed == value) return;
              setState(() => _pressed = value);
            },
            onHover: (value) {
              if (_hovered == value) return;
              setState(() => _hovered = value);
            },
            onFocusChange: (value) {
              if (_focused == value) return;
              setState(() => _focused = value);
            },
            customBorder: shape,
            splashColor: overlay,
            highlightColor: overlay,
            splashFactory: InkRipple.splashFactory,
            child: Center(
              heightFactor: isScaled ? 1.0 : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: AppSpacing.xs,
                  horizontal: AppSpacing.sm,
                ),
                child: widget.isLoading
                    ? Semantics(
                        liveRegion: true,
                        label: 'Loading',
                        child: SizedBox(
                          width: AppSizing.iconMedium,
                          height: AppSizing.iconMedium,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: foreground,
                          ),
                        ),
                      )
                    : _child(theme, foreground),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _child(ThemeData theme, Color foreground) {
    final style = (theme.extension<AppStyles>()?.button ??
            theme.textTheme.labelLarge ??
            const TextStyle())
        .copyWith(color: foreground);

    Widget content;
    if (widget.icon != null) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              widget.icon,
              size: AppSizing.iconMedium,
              color: foreground,
            ),
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Text(
                widget.label,
                style: style,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    } else {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Text(
          widget.label,
          style: style,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
      );
    }

    return Tooltip(
      message: widget.label,
      child: Semantics(
        button: true,
        enabled: _enabled,
        label: widget.label,
        child: content,
      ),
    );
  }
}
