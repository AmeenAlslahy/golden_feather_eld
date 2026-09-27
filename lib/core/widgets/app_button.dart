import 'package:flutter/material.dart';
import '../theme/app_spacing.dart';
import '../theme/app_styles.dart';

enum EldButtonType {
  connect,
  continueDisconnected,
  send,
  agree,
  danger,
  dark,
  muted,
}

/// زر ملعب. حالة الضغط تغميق فوري (وليس Ripple فقط) حتى يظهر النقر.
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
    this.type = EldButtonType.agree,
    this.isFullWidth = true,
    this.icon,
    this.isLoading = false,
  });

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton> {
  bool _pressed = false;

  bool get _onDark =>
      widget.type == EldButtonType.continueDisconnected ||
      widget.type == EldButtonType.dark ||
      widget.type == EldButtonType.danger;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  Color _base(ThemeData theme) {
    return switch (widget.type) {
      EldButtonType.connect => const Color(0xFF4CAF50),
      EldButtonType.agree => const Color(0xFF4CAF50),
      EldButtonType.continueDisconnected => const Color(0xFF2C2C2E),
      EldButtonType.dark => const Color(0xFF3A3A3C),
      EldButtonType.send => const Color(0xFFB5EAD7),
      EldButtonType.danger => theme.colorScheme.error,
      EldButtonType.muted => const Color(0xFFC8C8C8),
    };
  }

  Color _foreground(ThemeData theme) {
    return switch (widget.type) {
      EldButtonType.send => Colors.white,
      EldButtonType.muted => Colors.white,
      _ => Colors.white,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = !_enabled &&
            widget.type != EldButtonType.send &&
            widget.type != EldButtonType.muted
        ? theme.disabledColor
        : _base(theme);
    final overlay = _onDark
        ? Colors.white.withValues(alpha: 0.28)
        : Colors.black.withValues(alpha: 0.28);
    final color = _pressed && _enabled ? Color.alphaBlend(overlay, base) : base;

    return SizedBox(
      width: widget.isFullWidth ? double.infinity : null,
      height: AppSpacing.buttonHeight,
      child: Material(
        color: color,
        elevation: 0,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: Listener(
          onPointerDown: _enabled
              ? (_) {
                  if (!_pressed) setState(() => _pressed = true);
                }
              : null,
          onPointerUp: (_) {
            if (_pressed) setState(() => _pressed = false);
          },
          onPointerCancel: (_) {
            if (_pressed) setState(() => _pressed = false);
          },
          child: InkWell(
          onTap: _enabled ? widget.onPressed : null,
          onHighlightChanged: (value) {
            if (_pressed == value) return;
            setState(() => _pressed = value);
          },
          customBorder: const StadiumBorder(),
          splashColor: overlay,
          highlightColor: overlay,
          splashFactory: InkRipple.splashFactory,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 80),
            color: Colors.transparent,
            alignment: Alignment.center,
            child: widget.isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: _foreground(theme),
                    ),
                  )
                : _child(theme),
          ),
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
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 20, color: _foreground(theme)),
            const SizedBox(width: AppSpacing.sm),
            Text(widget.label, style: style),
          ],
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(widget.label, style: style),
    );
  }
}
