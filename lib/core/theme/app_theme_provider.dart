import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';

/// مزود حالة الثيم
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(localStorageProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final LocalStorageService _storage;

  ThemeModeNotifier(this._storage) : super(ThemeMode.system) {
    _loadThemeMode();
  }

  static const String _oldThemeKey = 'theme_mode';

  Future<void> _loadThemeMode() async {
    // Migration check from old SharedPreferences
    final oldPrefs = await SharedPreferences.getInstance();
    if (oldPrefs.containsKey(_oldThemeKey)) {
      final oldIndex = oldPrefs.getInt(_oldThemeKey);
      if (oldIndex != null &&
          oldIndex >= 0 &&
          oldIndex < ThemeMode.values.length) {
        final migratedMode = ThemeMode.values[oldIndex];
        await _storage.setTheme(migratedMode.name);
      }
      await oldPrefs.remove(_oldThemeKey);
    }

    // Read from unified storage
    final themeStr = _storage.theme;
    state = ThemeMode.values.firstWhere(
      (e) => e.name == themeStr,
      orElse: () => ThemeMode.system,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.setTheme(mode.name);
  }

  Future<void> toggleTheme() async {
    if (state == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.light);
    }
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
