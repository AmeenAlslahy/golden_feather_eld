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

/// زر التطبيق الأساسي المعتمد على ثيم Flutter (Material 3).
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final EldButtonType type;
  final bool isFullWidth;
  final IconData? icon;
  final bool isLoading;
  final TextStyle? textStyle;
  final double? height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.type = EldButtonType.agree,
    this.isFullWidth = true,
    this.icon,
    this.isLoading = false,
    this.textStyle,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final enabled = onPressed != null && !isLoading;

    Color? backgroundColor;
    Color? foregroundColor;

    switch (type) {
      case EldButtonType.connect:
      case EldButtonType.agree:
        backgroundColor = theme.colorScheme.secondary; // Green
        foregroundColor = theme.colorScheme.onSecondary;
        break;
      case EldButtonType.danger:
        backgroundColor = theme.colorScheme.error;
        foregroundColor = theme.colorScheme.onError;
        break;
      case EldButtonType.send:
        backgroundColor = theme.colorScheme.secondaryContainer;
        foregroundColor = theme.colorScheme.onSecondaryContainer;
        break;
      case EldButtonType.continueDisconnected:
      case EldButtonType.dark:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        foregroundColor = theme.colorScheme.onSurfaceVariant;
        break;
      case EldButtonType.muted:
        backgroundColor = theme.disabledColor;
        foregroundColor = theme.colorScheme.onSurface;
        break;
    }

    final style = FilledButton.styleFrom(
      backgroundColor: backgroundColor,
      foregroundColor: foregroundColor,
      minimumSize: Size(
        isFullWidth ? double.infinity : 64,
        height ?? AppSpacing.buttonHeight,
      ),
      textStyle: textStyle,
    );

    final child = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: foregroundColor ?? theme.colorScheme.onPrimary,
            ),
          )
        : (icon != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 20),
                  const SizedBox(width: AppSpacing.sm),
                  Text(label),
                ],
              )
            : Text(label));

    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: style,
      child: child,
    );
  }
}
