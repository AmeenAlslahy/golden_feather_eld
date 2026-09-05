import 'package:flutter/widgets.dart';
import '../../l10n/app_localizations.dart';

extension LocalizationHelper on BuildContext {
  /// Translate a string key to its localized value, or return the key if not found.
  String translateErrorKey(String? key) {
    if (key == null || key.isEmpty) return '';
    final loc = AppLocalizations.of(this)!;
    
    switch (key) {
      case 'emailRequired':
        return loc.emailRequired;
      case 'invalidEmailFormat':
        return loc.invalidEmailFormat;
      case 'passwordRequired':
        return loc.passwordRequired;
      case 'invalidValue':
        return loc.invalidValue;
      case 'noInternet':
        return loc.noInternet;
      case 'sessionExpired':
        return loc.sessionExpired;
      case 'serverNotConfigured':
        return loc.serverNotConfigured;
      case 'invalidConfiguration':
        return loc.invalidConfiguration;
      case 'invalidCredentials':
        return loc.invalidCredentials;
      case 'sessionMissing':
        return loc.sessionMissing;
      case 'permissionDenied':
        return loc.permissionDenied;
      default:
        // Return the key itself as a fallback
        return key;
    }
  }
}
