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

  LocaleNotifier(this._storage) : super(const Locale('ar')) {
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

    // Read from unified storage
    final langCode = _storage.language;
    state = Locale(langCode);
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    await _storage.setLanguage(languageCode);
  }
}
