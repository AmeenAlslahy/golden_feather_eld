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

  LocaleNotifier(this._storage) : super(_resolveInitialLocale(_storage)) {
    _checkOldMigration();
  }

  static Locale _resolveInitialLocale(LocalStorageService storage) {
    try {
      final lang = storage.language;
      if (lang.isNotEmpty) {
        return Locale(lang);
      }
    } catch (_) {}
    return const Locale('en');
  }

  static const String _oldLanguageKey = 'language_code';

  Future<void> _checkOldMigration() async {
    try {
      final oldPrefs = await SharedPreferences.getInstance();
      if (oldPrefs.containsKey(_oldLanguageKey)) {
        final oldLangCode = oldPrefs.getString(_oldLanguageKey);
        if (oldLangCode != null && oldLangCode.isNotEmpty) {
          await _storage.setLanguage(oldLangCode);
          if (mounted && state.languageCode != oldLangCode) {
            state = Locale(oldLangCode);
          }
        }
        await oldPrefs.remove(_oldLanguageKey);
      }
    } catch (_) {
      // Ignore migration lookup errors in environments without platform plugins
    }
  }

  Future<void> setLocale(String languageCode) async {
    state = Locale(languageCode);
    await _storage.setLanguage(languageCode);
  }
}
