import 'package:flutter/widgets.dart';
import '../error/user_facing_message.dart';
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
        // Not an l10n key: a backend error code such as
        // `network.connectionFailed`, `server.unavailable`, `server_error`.
        // The driver never sees the code itself.
        final loc = AppLocalizations.of(this)!;
        final lower = key.toLowerCase();
        if (lower.startsWith('network.') || lower.contains('connection')) {
          return anyErrorUserMessage('noInternet', loc: loc);
        }
        if (lower.startsWith('server') ||
            lower.endsWith('_error') ||
            lower.contains('.') ||
            lower.contains('_')) {
          return anyErrorUserMessage(Object(), loc: loc);
        }
        return anyErrorUserMessage(key, loc: loc);
    }
  }
}
