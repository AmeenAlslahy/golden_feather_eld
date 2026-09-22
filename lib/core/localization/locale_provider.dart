import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';

/// مزود حالة اللغة
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final storage = ref.watch(localStorageProvider);
  return LocaleNotifier(storage);
});

class LocaleNotifier extends StateNotifier<Locale> {
  final LocalStorageService _storage;

  // UX-HIGH-01 fix: Default locale is English per product requirement.
  LocaleNotifier(this._storage) : super(const Locale('en')) {
    _loadLocale();
  }

  static const String _oldLanguageKey = 'language_code';

  Future<void> _loadLocale() async {
    // Migration check from old SharedPreferences
    final oldPrefs = await SharedPreferences.getInstance();
    if (oldPrefs.containsKey(_oldLanguageKey)) {
      final oldLangCode = oldPrefs.getString(_oldLanguageKey);
      if (oldLangCode != null) {
        await _storage.setLanguage(oldLangCode);
      }
      await oldPrefs.remove(_oldLanguageKey);
    }

    // If user never chose language, follow device locale
    if (!_storage.hasLanguage) {
      // Follow system locale
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final supportedCode = ['ar', 'en'].contains(deviceLocale.languageCode)
          ? deviceLocale.languageCode
          : 'en';
      state = Locale(supportedCode);
      return;
    }

    // Read from unified storage
    final langCode = _storage.language;
    state = Locale(langCode);
  }

  Future<void> setLocale(String languageCode) async {
    if (languageCode == 'system') {
      // Follow device locale and clear stored preference
      await _storage.clearLanguage();
      final deviceLocale = WidgetsBinding.instance.platformDispatcher.locale;
      final supportedCode = ['ar', 'en'].contains(deviceLocale.languageCode)
          ? deviceLocale.languageCode
          : 'en';
      state = Locale(supportedCode);
      return;
    }
    state = Locale(languageCode);
    await _storage.setLanguage(languageCode);
  }

  Future<void> setSystemLocale() async => setLocale('system');
}
