import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';

/// مزود حالة الثيم.
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
    // ترحيل من SharedPreferences القديم.
    final oldPrefs = await SharedPreferences.getInstance();
    if (oldPrefs.containsKey(_oldThemeKey)) {
      final oldIndex = oldPrefs.getInt(_oldThemeKey);
      if (oldIndex != null &&
          oldIndex >= 0 &&
          oldIndex < ThemeMode.values.length) {
        await _storage.setTheme(ThemeMode.values[oldIndex].name);
      }
      await oldPrefs.remove(_oldThemeKey);
    }

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
    // Cycle: system -> light -> dark -> system (for quick toggle)
    if (state == ThemeMode.system) {
      await setThemeMode(ThemeMode.light);
    } else if (state == ThemeMode.light) {
      await setThemeMode(ThemeMode.dark);
    } else {
      await setThemeMode(ThemeMode.system);
    }
  }

  Future<void> setSystemTheme() async => setThemeMode(ThemeMode.system);

  bool get isDarkMode => state == ThemeMode.dark;
  bool get isSystemMode => state == ThemeMode.system;
}
