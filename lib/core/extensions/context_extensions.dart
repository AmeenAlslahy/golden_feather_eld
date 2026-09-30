import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_styles.dart';

/// امتدادات BuildContext
extension ContextExtensions on BuildContext {
  // ========== السمات والترجمة ==========
  AppLocalizations get loc => AppLocalizations.of(this)!;
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  ColorScheme get colors => theme.colorScheme;
  AppStyles get styles => theme.extension<AppStyles>()!;
  MediaQueryData get mediaQuery => MediaQuery.of(this);
  Size get screenSize => mediaQuery.size;
  double get screenWidth => screenSize.width;
  double get screenHeight => screenSize.height;
}


/// لغة الواجهة الحالية — بدل تكرار Localizations.localeOf في كل widget.
extension LocaleContextX on BuildContext {
  bool get isArabic => Localizations.localeOf(this).languageCode == 'ar';
}
