import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/features/account/application/models/rules_screen_model.dart';
import 'package:golden_feather_eld/features/account/data/datasources/rules_screen_local_cache.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late PrefsRulesScreenLocalCache cache;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    storage = LocalStorageService();
    await storage.init();
    cache = PrefsRulesScreenLocalCache(storage);
  });

  test('saves and loads RulesScreenModel correctly from cache', () async {
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
      editableFields: const {'cycleRule', 'cargoType'},
      readOnlyFields: const {'ruleSource'},
      fixedSettings: const {'personalConveyance': false},
      notice: 'Federal Rules apply',
      limits: HosConfiguration.usa70_8(),
    );

    await cache.saveRulesScreen(model);

    final loaded = cache.loadRulesScreen();
    expect(loaded, isNotNull);
    expect(loaded!.ruleSource, equals('USA 70hr/8day'));
    expect(loaded.cycleRule, equals('70 hours / 8 days'));
    expect(loaded.cargoType, equals('Property'));
    expect(loaded.options['cycleRule'], contains('70 hours / 8 days'));
    expect(loaded.editableFields, contains('cycleRule'));
    expect(loaded.notice, equals('Federal Rules apply'));

    await cache.clear();
    expect(cache.loadRulesScreen(), isNull);
  });

  test('returns null when cache is empty or corrupted', () async {
    expect(cache.loadRulesScreen(), isNull);

    await storage.prefs.setString('rules_screen_cache', 'not-valid-json');
    expect(cache.loadRulesScreen(), isNull);
  });
}
