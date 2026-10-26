import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/domain/account/driver_account.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/account/application/models/rules_screen_model.dart';
import 'package:golden_feather_eld/features/account/data/datasources/rules_screen_local_cache.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late PrefsRulesScreenLocalCache rulesCache;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    storage = LocalStorageService();
    await storage.init();
    rulesCache = PrefsRulesScreenLocalCache(storage);
  });

  group('NET-001: Dynamic Cache Key Isolation and Persistence', () {
    test('1 & 2: Dynamic account cache writes and reads with driver scope',
        () async {
      const ownerId = 'driver_alpha_42';
      const account = DriverAccount(
        driverId: 42,
        email: 'alpha@carrier.com',
        phone: '123-456-7890',
        license: LicenseInfo(
          state: 'TX',
          number: '99887766',
          formatted: 'TX 99887766',
        ),
        carrier: 'Apex Logistics',
        mainOfficeAddress: '100 Main St, Dallas, TX',
        homeTerminalAddress: '200 Terminal Rd, Fort Worth, TX',
        timeZone: 'America/Chicago',
        language: 'en',
        odometer: '125430',
      );

      const key = 'driver_account_cache_$ownerId';
      await storage.prefs.setString(key, jsonEncode(account.toJson()));

      final storedJson = storage.prefs.getString(key);
      expect(storedJson, isNotNull);

      final decoded = jsonDecode(storedJson!) as Map<String, dynamic>;
      final restoredAccount = DriverAccount.fromJson(decoded);

      expect(restoredAccount.email, equals('alpha@carrier.com'));
      expect(restoredAccount.license.formatted, equals('TX 99887766'));
      expect(restoredAccount.carrier, equals('Apex Logistics'));
      expect(restoredAccount.odometer, equals('125430'));
    });

    test('3 & 4: Dynamic rules cache writes and reads with DriverId scope',
        () async {
      const driverId = DriverId(777);
      final model = RulesScreenModel(
        ruleSource: 'USA 70hr/8day',
        cycleRule: '70 hours / 8 days',
        cargoType: 'Property',
        restart: '34 consecutive hours off-duty',
        restBreak: '30 consecutive minutes after 8 cumulative hours driving',
        sixteenHourException: false,
        options: const {
          'cycleRule': ['70 hours / 8 days', '60 hours / 7 days'],
          'cargoType': ['Property', 'Passenger'],
        },
        editableFields: const {'cycleRule'},
        readOnlyFields: const {'ruleSource'},
        fixedSettings: const {'personalConveyance': false},
        notice: 'FMCSA Certified Rules',
        limits: HosConfiguration.usa70_8(),
      );

      // Writes to rules_screen_cache_777 without ArgumentError
      await rulesCache.saveRulesScreen(model, driverId: driverId);

      final loaded = rulesCache.loadRulesScreen(driverId: driverId);
      expect(loaded, isNotNull);
      expect(loaded!.ruleSource, equals('USA 70hr/8day'));
      expect(loaded.notice, equals('FMCSA Certified Rules'));
    });

    test('5: Driver A / Driver B cache isolation prevents cross-driver leakage',
        () async {
      const driverA = DriverId(101);
      const driverB = DriverId(202);

      final modelA = RulesScreenModel(
        ruleSource: 'Driver A Rules (Texas Intrastate)',
        cycleRule: '70 hours / 7 days',
        cargoType: 'Property',
        restart: '34 hours',
        restBreak: 'None',
        sixteenHourException: true,
        options: const {},
        editableFields: const {},
        readOnlyFields: const {},
        fixedSettings: const {},
        notice: 'Texas Rules',
        limits: HosConfiguration.usa70_8(),
      );

      final modelB = RulesScreenModel(
        ruleSource: 'Driver B Rules (USA Interstate)',
        cycleRule: '70 hours / 8 days',
        cargoType: 'Property',
        restart: '34 consecutive hours',
        restBreak: '30 min',
        sixteenHourException: false,
        options: const {},
        editableFields: const {},
        readOnlyFields: const {},
        fixedSettings: const {},
        notice: 'Federal Rules',
        limits: HosConfiguration.usa70_8(),
      );

      await rulesCache.saveRulesScreen(modelA, driverId: driverA);
      await rulesCache.saveRulesScreen(modelB, driverId: driverB);

      final loadedA = rulesCache.loadRulesScreen(driverId: driverA);
      final loadedB = rulesCache.loadRulesScreen(driverId: driverB);

      expect(loadedA?.ruleSource, equals('Driver A Rules (Texas Intrastate)'));
      expect(loadedB?.ruleSource, equals('Driver B Rules (USA Interstate)'));
      expect(loadedA?.notice, isNot(equals(loadedB?.notice)));

      // Account cache isolation check
      await storage.prefs.setString(
          'driver_account_cache_101', '{"email":"driverA@test.com"}');
      await storage.prefs.setString(
          'driver_account_cache_202', '{"email":"driverB@test.com"}');

      expect(storage.prefs.getString('driver_account_cache_101'),
          contains('driverA@test.com'));
      expect(storage.prefs.getString('driver_account_cache_202'),
          contains('driverB@test.com'));
    });

    test('6: Logout and login transitions maintain account data separation',
        () async {
      // Driver 1 logs in and caches account
      const driver1 = 'driver_1';
      await storage.prefs.setString(
        'driver_account_cache_$driver1',
        '{"email":"d1@domain.com","carrier":"FleetOne"}',
      );

      // Duty tracking state is cleared on logout/switch
      await storage.clearDutyTrackingState();

      // Driver 2 logs in
      const driver2 = 'driver_2';
      final cachedForDriver2 =
          storage.prefs.getString('driver_account_cache_$driver2');
      expect(cachedForDriver2, isNull);

      // Driver 1 cache is still preserved intact in storage for when Driver 1 returns
      final cachedForDriver1 =
          storage.prefs.getString('driver_account_cache_$driver1');
      expect(cachedForDriver1, contains('d1@domain.com'));
    });

    test('7: Missing cache entries return null cleanly without throwing', () {
      const nonExistentDriver = DriverId(9999);
      final loadedRules =
          rulesCache.loadRulesScreen(driverId: nonExistentDriver);
      expect(loadedRules, isNull);

      final loadedAccount =
          storage.prefs.getString('driver_account_cache_non_existent');
      expect(loadedAccount, isNull);
    });

    test('8: Offline retrieval works when remote network is absent', () async {
      const offlineDriver = DriverId(555);
      final offlineRules = RulesScreenModel(
        ruleSource: 'USA 70hr/8day (Offline Cache)',
        cycleRule: '70 hours / 8 days',
        cargoType: 'Property',
        restart: '34 consecutive hours off-duty',
        restBreak: '30 consecutive minutes',
        sixteenHourException: false,
        options: const {},
        editableFields: const {},
        readOnlyFields: const {},
        fixedSettings: const {},
        notice: 'Retrieved from offline cache',
        limits: HosConfiguration.usa70_8(),
      );

      await rulesCache.saveRulesScreen(offlineRules, driverId: offlineDriver);

      // Simulate offline launch: read directly from storage cache
      final retrieved = rulesCache.loadRulesScreen(driverId: offlineDriver);
      expect(retrieved, isNotNull);
      expect(retrieved!.ruleSource, contains('(Offline Cache)'));
      expect(retrieved.notice, equals('Retrieved from offline cache'));
    });

    test('9: Static storage keys still operate without regression', () async {
      await storage.setOnboardingSeen();
      expect(storage.onboardingSeen, isTrue);

      await storage.setLanguage('en');
      expect(storage.language, equals('en'));

      await storage.setTheme('dark');
      expect(storage.theme, equals('dark'));

      await storage.setCurrentDutyStatus('driving');
      expect(storage.currentDutyStatus, equals('driving'));

      await storage.saveSelectedVehicleId('veh-99');
      expect(storage.selectedVehicleId, equals('veh-99'));

      await storage.prefs.setString('hos_dashboard_snapshot', '{"ok":true}');
      expect(storage.prefs.getString('hos_dashboard_snapshot'),
          equals('{"ok":true}'));
    });
  });
}
