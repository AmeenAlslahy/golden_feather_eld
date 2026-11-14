import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/local_storage_service.dart';

/// مزود حالة الثيم.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((
  ref,
) {
  final storage = ref.watch(localStorageProvider);
  return ThemeModeNotifier(storage);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final LocalStorageService _storage;

  ThemeModeNotifier(this._storage) : super(_resolveInitialThemeMode(_storage)) {
    _loadThemeMode();
  }

  static ThemeMode _resolveInitialThemeMode(LocalStorageService storage) {
    try {
      final themeStr = storage.theme;
      return ThemeMode.values.firstWhere(
        (e) => e.name == themeStr,
        orElse: () => ThemeMode.dark,
      );
    } catch (_) {}
    return ThemeMode.dark;
  }

  static const String _oldThemeKey = 'theme_mode';

  Future<void> _loadThemeMode() async {
    try {
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
      if (mounted) {
        state = ThemeMode.values.firstWhere(
          (e) => e.name == themeStr,
          orElse: () => ThemeMode.dark,
        );
      }
    } catch (_) {
      // Ignore migration lookup errors in test/uninitialized environments
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _storage.setTheme(mode.name);
  }

  bool get isDarkMode => state == ThemeMode.dark;
}
