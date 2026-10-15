import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/features/codriver/data/datasources/codriver_local_cache.dart';
import 'package:golden_feather_eld/features/codriver/domain/current_codriver.dart';
import 'package:golden_feather_eld/features/codriver/domain/entities/codriver.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late PrefsCoDriverLocalCache cache;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    storage = LocalStorageService();
    await storage.init();
    cache = PrefsCoDriverLocalCache(storage);
  });

  test('saves and loads available drivers from cache', () async {
    final drivers = [
      const CoDriver(id: '101', name: 'John Doe', licenseNumber: 'DL12345'),
      const CoDriver(id: '102', name: 'Jane Smith', licenseNumber: 'DL67890'),
    ];

    await cache.saveAvailableDrivers(drivers);

    final loaded = cache.loadAvailableDrivers();
    expect(loaded, isNotNull);
    expect(loaded!.length, equals(2));
    expect(loaded[0].id, equals('101'));
    expect(loaded[0].name, equals('John Doe'));
    expect(loaded[0].licenseNumber, equals('DL12345'));
    expect(loaded[1].id, equals('102'));
  });

  test('saves and loads current co-driver link from cache', () async {
    const current = CurrentCoDriverRead(
      coDriverId: 102,
      name: 'Jane Smith',
      teamDrivingActive: true,
    );

    await cache.saveCurrentCoDriver(current);

    final loaded = cache.loadCurrentCoDriver();
    expect(loaded, isNotNull);
    expect(loaded!.coDriverId, equals(102));
    expect(loaded.name, equals('Jane Smith'));
    expect(loaded.teamDrivingActive, isTrue);
  });

  test('clears all co-driver caches on clear()', () async {
    await cache.saveAvailableDrivers([
      const CoDriver(id: '101', name: 'John'),
    ]);
    await cache.saveCurrentCoDriver(const CurrentCoDriverRead(
      coDriverId: 101,
      teamDrivingActive: true,
    ));

    await cache.clear();

    expect(cache.loadAvailableDrivers(), isNull);
    expect(cache.loadCurrentCoDriver(), isNull);
  });
}
