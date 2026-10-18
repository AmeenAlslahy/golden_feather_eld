import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart' as fp;
import 'package:golden_feather_eld/backend/contracts/rules_screen_backend.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/account/application/models/rules_screen_model.dart';
import 'package:golden_feather_eld/features/account/data/datasources/rules_screen_local_cache.dart';
import 'package:golden_feather_eld/features/account/data/repositories/rules_screen_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockRulesScreenBackend extends Mock implements RulesScreenBackend {}

class MockRulesScreenLocalCache extends Mock implements RulesScreenLocalCache {}

class FakeDriverId extends Fake implements DriverId {}

RulesScreenModel serverModel() => RulesScreenModel(
      ruleSource: 'Federal',
      cycleRule: 'USA 70/8',
      cargoType: 'Property',
      restart: '34 Hour Restart',
      restBreak: '30 Minute Rest Break Required',
      sixteenHourException: false,
      options: const {},
      editableFields: const {},
      readOnlyFields: const {},
      fixedSettings: const {},
      notice: '',
      limits: HosConfiguration.usa70_8(),
    );

void main() {
  late MockRulesScreenBackend backend;
  late MockRulesScreenLocalCache cache;
  late RulesScreenRepository repository;

  setUpAll(() {
    registerFallbackValue(FakeDriverId());
    registerFallbackValue(serverModel());
  });

  setUp(() {
    backend = MockRulesScreenBackend();
    cache = MockRulesScreenLocalCache();
    repository = RulesScreenRepository(backend, cache);
  });

  test('server success is returned and saved to cache', () async {
    final model = serverModel();
    when(() => backend.getRulesScreen(driverId: any(named: 'driverId')))
        .thenAnswer((_) async => fp.Right(model));
    when(() => cache.saveRulesScreen(any())).thenAnswer((_) async {});

    final result = await repository.getRulesScreen();

    expect(result.isRight(), true);
    expect(result.valueOrNull, same(model));
    verify(() => cache.saveRulesScreen(model)).called(1);
    verifyNever(() => cache.loadRulesScreen());
  });

  test('offline failure serves the cached model when available', () async {
    final cached = serverModel();
    when(() => backend.getRulesScreen(driverId: any(named: 'driverId')))
        .thenAnswer((_) async => err(const NetworkError(
              code: 'network.timeout',
              l10nKey: 'errNoInternet',
            )));
    when(() => cache.loadRulesScreen()).thenReturn(cached);

    final result = await repository.getRulesScreen();

    expect(result.isRight(), true);
    expect(result.valueOrNull, same(cached));
  });

  test('offline failure without cache is rethrown to the caller', () async {
    when(() => backend.getRulesScreen(driverId: any(named: 'driverId')))
        .thenAnswer((_) async => err(const NetworkError(
              code: 'network.timeout',
              l10nKey: 'errNoInternet',
            )));
    when(() => cache.loadRulesScreen()).thenReturn(null);

    final result = await repository.getRulesScreen();

    expect(result.isLeft(), true);
    expect(result.valueOrNull, isNull);
  });

  test('network-prefixed failure code is also treated as offline', () async {
    final cached = serverModel();
    when(() => backend.getRulesScreen(driverId: any(named: 'driverId')))
        .thenAnswer((_) async => err(const ServerError(code: 'network.down')));
    when(() => cache.loadRulesScreen()).thenReturn(cached);

    final result = await repository.getRulesScreen();

    expect(result.isRight(), true);
    expect(result.valueOrNull, same(cached));
  });

  test('non-network failure propagates without touching the cache', () async {
    when(() => backend.getRulesScreen(driverId: any(named: 'driverId')))
        .thenAnswer((_) async => err(const ServerError(code: 'HTTP_500')));

    final result = await repository.getRulesScreen();

    expect(result.isLeft(), true);
    verifyNever(() => cache.loadRulesScreen());
    verifyNever(() => cache.saveRulesScreen(any()));
  });
}
