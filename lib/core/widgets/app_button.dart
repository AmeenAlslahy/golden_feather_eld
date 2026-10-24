import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_styles.dart';

enum EldButtonType {
  /// الزر الأساسي بلون الهوية الذهبي (Golden Feather Primary Gold)
  primary,

  /// الزر الثانوي المؤطر (Outlined) بإطار ولون ذهبي أنيق وخلفية شفافة
  secondary,

  /// زر الاتصال والإجراءات الإيجابية والاعتماد (Success Green)
  connect,
  agree,

  /// الزر التحذيري أو الحذف أو الإلغاء الحرج (Danger Red)
  danger,

  /// للمطابقة مع الاستخدامات السابقة وتوجيهها للمظهر المناسب:
  continueDisconnected,
  send,
  dark,
  muted,
}

/// زر موحد في التطبيق مع رد فعل بصري فوري ودعم كامل للأشكال الدلالية.
class AppButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final EldButtonType type;
  final bool isFullWidth;
  final IconData? icon;
  final bool isLoading;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = EldButtonType.primary,
    this.isFullWidth = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  bool get _isOutlined =>
      widget.type == EldButtonType.secondary ||
      widget.type == EldButtonType.continueDisconnected ||
      widget.type == EldButtonType.dark ||
      widget.type == EldButtonType.muted;

  Color _base(ThemeData theme) {
    if (_isOutlined) return Colors.transparent;
    return switch (widget.type) {
      EldButtonType.primary || EldButtonType.send => theme.colorScheme.primary,
      EldButtonType.connect || EldButtonType.agree => AppColors.successText,
      EldButtonType.danger => AppColors.dangerText,
      _ => theme.colorScheme.primary,
    };
  }

  Color _foreground(ThemeData theme) {
    if (!_enabled) {
      return theme.colorScheme.onSurface.withValues(alpha: 0.38);
    }
    if (_isOutlined) {
      return theme.brightness == Brightness.dark
          ? AppColors.primaryGold
          : AppColors.goldDeep;
    }
    return switch (widget.type) {
      EldButtonType.primary ||
      EldButtonType.send => theme.colorScheme.onPrimary,
      EldButtonType.connect || EldButtonType.agree => AppColors.white,
      EldButtonType.danger => AppColors.white,
      _ => theme.colorScheme.onPrimary,
    };
  }

  OutlinedBorder _shape(ThemeData theme) {
    if (_isOutlined) {
      final borderColor = _enabled
          ? (theme.brightness == Brightness.dark
                ? AppColors.primaryGold
                : AppColors.goldDeep)
          : theme.disabledColor.withValues(alpha: 0.35);
      return RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.button),
        side: BorderSide(color: borderColor, width: 1.5),
      );
    }
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.button),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = !_enabled
        ? (_isOutlined
              ? Colors.transparent
              : (widget.type == EldButtonType.primary
                    ? theme.colorScheme.primary.withValues(alpha: 0.4)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.12)))
        : _base(theme);

    final overlay = _isOutlined
        ? AppColors.primaryGold.withValues(alpha: 0.12)
        : (widget.type == EldButtonType.danger
              ? AppColors.white.withValues(alpha: 0.28)
              : AppColors.black.withValues(alpha: 0.24));

    final color = _pressed && _enabled
        ? (_isOutlined ? overlay : Color.alphaBlend(overlay, base))
        : base;

    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      height: _isOutlined
          ? AppSpacing.secondaryButtonHeight
          : AppSpacing.buttonHeight,
      child: Material(
        color: color,
        elevation: 0,
        shape: _shape(theme),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: _enabled ? widget.onPressed : null,
          onHighlightChanged: (value) {
            if (_pressed == value) return;
            setState(() => _pressed = value);
          },
          customBorder: _shape(theme),
          splashColor: overlay,
          highlightColor: overlay,
          splashFactory: InkRipple.splashFactory,
          child: Container(
            alignment: Alignment.center,
            child: widget.isLoading
                ? SizedBox(
                    width: AppSpacing.iconMedium,
                    height: AppSpacing.iconMedium,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _foreground(theme),
                    ),
                  )
                : _child(theme),
          ),
        ),
      ),
    );
  }

  Widget _child(ThemeData theme) {
    final style = theme.extension<AppStyles>()!.button.copyWith(
      color: _foreground(theme),
    );
    if (widget.icon != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 20, color: _foreground(theme)),
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
    }
    return Padding(
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
}
