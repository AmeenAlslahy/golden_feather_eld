import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// استيراد network_info هنا لتجنب cyclic dependency
import '../../l10n/app_localizations.dart';
import '../network/core_providers.dart';

import '../theme/app_styles.dart';
import '../theme/eld_colors.dart';

import '../../l10n/app_localizations_en.dart';

/// امتدادات BuildContext
extension ContextExtensions on BuildContext {
  // ========== السمات والترجمة ==========
  AppLocalizations get loc => AppLocalizations.of(this) ?? AppLocalizationsEn();
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  ColorScheme get colors => theme.colorScheme;
  EldColors get eld => theme.extension<EldColors>() ?? EldColors.light();
  AppStyles get styles => theme.extension<AppStyles>() ?? AppStyles.light();
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;

  // ========== الرسائل ==========
  void showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? colorScheme.error : null, // Use theme error color instead of Colors.red
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void hideSnackBar() {
    ScaffoldMessenger.of(this).hideCurrentSnackBar();
  }

  // ========== الحوارات ==========
  Future<bool?> showConfirmDialog({
    required String title,
    required String message,
    String? confirmText,
    String? cancelText,
    bool isDismissible = true,
  }) async {
    return showDialog<bool>(
      context: this,
      barrierDismissible: isDismissible,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText ?? loc.cancelButton), // Use localization
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(confirmText ?? loc.confirmTitle), // Use localization
          ),
        ],
      ),
    );
  }

  void showLoadingDialog({String? message}) {
    final loadingMsg = message ?? 'Loading...'; // Fallback message, although usually loc is available
    showDialog(
      context: this,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(loadingMsg),
            ],
          ),
        ),
      ),
    );
  }
}

/// امتدادات WidgetRef للوصول السهل
extension RefExtensions on WidgetRef {
  bool get isConnected => watch(isConnectedProvider).value ?? false;
}
