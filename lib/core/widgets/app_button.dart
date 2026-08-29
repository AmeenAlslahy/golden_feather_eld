import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
// import '../theme/app_typography.dart';

/// أنواع الأزرار في ELD
enum EldButtonType {
  /// زر اتصال - أخضر (الحل الصحيح)
  connect,
  /// زر متابعة بدون - رمادي غامق (الحل المؤقت)
  continueDisconnected,
  /// زر إرسال - أخضر باهت
  send,
  /// زر موافقة - أخضر
  agree,
  /// زر خطر - أحمر
  danger,
}

/// زر موحد حسب دليل تصميم ELD
class AppButton extends StatelessWidget {
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

  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: AppSpacing.buttonHeight,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: _buttonStyle(theme),
        child: isLoading 
            ? SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: _getForegroundColor(theme), 
                  strokeWidth: 2,
                ),
              ) 
            : _buildChild(),
      ),
    );
  }

  ButtonStyle _buttonStyle(ThemeData theme) {
    // Start with the base button theme
    final baseStyle = theme.elevatedButtonTheme.style ?? ElevatedButton.styleFrom();
    
    return baseStyle.copyWith(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return theme.disabledColor;
        }
        return _getBackgroundColor(theme);
      }),
      foregroundColor: WidgetStatePropertyAll(_getForegroundColor(theme)),
    );
  }

  Color _getBackgroundColor(ThemeData theme) {
    return switch (type) {
      EldButtonType.connect => theme.colorScheme.secondary,
      EldButtonType.agree => theme.colorScheme.secondary,
      EldButtonType.continueDisconnected => const Color(0xFF2C2C2E), // Custom specific color
      EldButtonType.send => const Color(0xFFB5EAD7), // Custom pale green
      EldButtonType.danger => theme.colorScheme.error,
    };
  }

  Color _getForegroundColor(ThemeData theme) {
    return switch (type) {
      EldButtonType.send => theme.colorScheme.onSurface,
      _ => theme.colorScheme.onPrimary,
    };
  }

  Widget _buildChild() {
    if (icon != null) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(label),
          ],
        ),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(label),
    );
  }
}


