import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/localization/locale_provider.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
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

  group('UX-002: Locale Initialization and Flash Elimination', () {
    test('Saved English preference initializes synchronously with LTR Locale(en)',
        () async {
      final storage = LocalStorageService();
      await storage.init();
      await storage.setLanguage('en');

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      // Must be synchronously 'en' on the very first read
      final initialLocale = container.read(localeProvider);
      expect(initialLocale, equals(const Locale('en')));
      expect(initialLocale.languageCode, equals('en'));
    });

    test('Saved Arabic preference initializes synchronously with RTL Locale(ar)',
        () async {
      final storage = LocalStorageService();
      await storage.init();
      await storage.setLanguage('ar');

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final initialLocale = container.read(localeProvider);
      expect(initialLocale, equals(const Locale('ar')));
      expect(initialLocale.languageCode, equals('ar'));
    });

    test('First installation defaults cleanly to Locale(en)', () async {
      final storage = LocalStorageService();
      await storage.init();
      await storage.prefs.clear();

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      final initialLocale = container.read(localeProvider);
      expect(initialLocale, equals(const Locale('en')));
    });

    test('Missing preference or uninitialized storage safely defaults to Locale(en)',
        () {
      final uninitializedStorage = LocalStorageService();
      // Not calling .init()

      final notifier = LocaleNotifier(uninitializedStorage);
      expect(notifier.state, equals(const Locale('en')));
    });

    test('Language switching updates state and persists to storage', () async {
      final storage = LocalStorageService();
      await storage.init();
      await storage.setLanguage('ar');

      final container = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storage),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(localeProvider), equals(const Locale('ar')));

      // Switch to English
      await container.read(localeProvider.notifier).setLocale('en');

      expect(container.read(localeProvider), equals(const Locale('en')));
      expect(storage.language, equals('en'));

      // Switch to Spanish
      await container.read(localeProvider.notifier).setLocale('es');

      expect(container.read(localeProvider), equals(const Locale('es')));
      expect(storage.language, equals('es'));
    });

    test('Application restart simulation retains saved preference on frame 0',
        () async {
      final storageSession1 = LocalStorageService();
      await storageSession1.init();
      await storageSession1.setLanguage('en');

      // Simulate app restart with a fresh container & storage instance reading the same persistent store
      final storageSession2 = LocalStorageService();
      await storageSession2.init();

      final containerSession2 = ProviderContainer(
        overrides: [
          localStorageProvider.overrideWithValue(storageSession2),
        ],
      );
      addTearDown(containerSession2.dispose);

      final restartLocale = containerSession2.read(localeProvider);
      expect(restartLocale, equals(const Locale('en')));
    });
  });
}
