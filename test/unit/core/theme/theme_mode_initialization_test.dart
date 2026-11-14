import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    SharedPreferences.setMockInitialValues({});
  });

  group('ThemeMode Initialization and Defaults', () {
    test('First installation defaults cleanly to ThemeMode.dark', () async {
      final storage = LocalStorageService();
      await storage.init();
      await storage.prefs.clear();

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final initialTheme = container.read(themeModeProvider);
      expect(initialTheme, equals(ThemeMode.dark));
    });

    test('Missing preference or uninitialized storage safely defaults to ThemeMode.dark',
        () {
      final uninitializedStorage = LocalStorageService();
      final notifier = ThemeModeNotifier(uninitializedStorage);
      expect(notifier.state, equals(ThemeMode.dark));
      expect(notifier.isDarkMode, isTrue);
    });

    test('Saved light preference initializes and loads as ThemeMode.light',
        () async {
      final storage = LocalStorageService();
      await storage.init();
      await storage.setTheme('light');

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(themeModeProvider.notifier);
      // Wait for async load to finish
      await Future<void>.delayed(Duration.zero);

      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(notifier.isDarkMode, isFalse);
    });

    test('Theme switching updates state and persists to storage', () async {
      final storage = LocalStorageService();
      await storage.init();
      await storage.prefs.clear();

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(themeModeProvider), equals(ThemeMode.dark));

      // Switch to light
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.light);

      expect(container.read(themeModeProvider), equals(ThemeMode.light));
      expect(storage.theme, equals('light'));

      // Switch to system
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.system);

      expect(container.read(themeModeProvider), equals(ThemeMode.system));
      expect(storage.theme, equals('system'));

      // Switch back to dark
      await container
          .read(themeModeProvider.notifier)
          .setThemeMode(ThemeMode.dark);

      expect(container.read(themeModeProvider), equals(ThemeMode.dark));
      expect(storage.theme, equals('dark'));
    });
  });
}
