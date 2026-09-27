import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/app/orchestrators/tracking_orchestrator.dart';
import 'package:golden_feather_eld/core/config/app_environment.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/services/tracking_config_storage_service.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/hos_provider.dart';
import 'package:golden_feather_eld/features/tracking/domain/entities/location_entity.dart';
import 'package:golden_feather_eld/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth() : super(const AuthState());
  void set(AuthStatus status) => state = AuthState(status: status);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHos extends StateNotifier<HosEngineResult> implements HosNotifier {
  _FakeHos() : super(HosEngineTimeUnavailable(TrustedTimeState.unavailable));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTrackingRepository implements TrackingRepository {
  final _locations = StreamController<LocationEntity>.broadcast();
  bool serviceStarted = false;
  int stopCalls = 0;

  @override
  Stream<LocationEntity> get locationStream => _locations.stream;

  @override
  Future<Either<Failure, bool>> startTracking() async {
    serviceStarted = true;
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> stopTracking() async {
    stopCalls++;
    serviceStarted = false;
    return const Right(true);
  }

  @override
  Future<bool> isTracking() async => serviceStarted;

  @override
  Future<Either<Failure, bool>> clearLogs() async => const Right(true);

  @override
  Future<Either<Failure, LocationEntity>> requestPosition({String? alarm}) async =>
      throw UnimplementedError();

  @override
  Future<TrackingConfigEntity> getCurrentConfig() async =>
      const TrackingConfigEntity(serverUrl: 'http://mock.test', deviceId: '1');

  @override
  Future<Either<Failure, LocationEntity>> getCurrentLocation() async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<TrackingLogEntity>>> getLogs() async =>
      const Right([]);

  @override
  Future<Either<Failure, bool>> updateConfig(TrackingConfigEntity config) async =>
      const Right(true);

  void dispose() => _locations.close();
}

class _MockLocalStorage extends Mock implements LocalStorageService {}

class _MockConfigStorage extends Mock implements TrackingConfigStorageService {}

class _MockVehicleRepository extends Mock implements VehicleRepository {}

/// Owner decision 2026-09-25 + SRS §1 / 49 CFR §395.32: signing out must
/// NOT stop vehicle tracking — movement after logout is recorded as
/// Unidentified Driver time instead of being lost.
void main() {
  late _FakeTrackingRepository repo;
  late _FakeAuth auth;
  late ProviderContainer container;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppEnvironmentConfig.init(testEnv: {'API_BASE_URL': 'http://mock.test'});
    SharedPreferences.setMockInitialValues({});

    repo = _FakeTrackingRepository();
    auth = _FakeAuth();

    final localStorage = _MockLocalStorage();
    when(() => localStorage.currentDutyStatus).thenReturn('off_duty');
    when(() => localStorage.serverUrl).thenReturn('http://mock.test');
    when(() => localStorage.backendType).thenReturn('traccar');
    final configStorage = _MockConfigStorage();
    when(() => configStorage.deviceId).thenReturn('12345');
    final vehicles = _MockVehicleRepository();
    when(() => vehicles.getSelectedVehicle())
        .thenAnswer((_) async => const Right(null));
    when(() => vehicles.getVehicles()).thenAnswer((_) async => const Right([]));

    container = ProviderContainer(overrides: [
      localStorageProvider.overrideWithValue(localStorage),
      trackingRepositoryProvider.overrideWithValue(repo),
      trackingConfigStorageProvider.overrideWithValue(configStorage),
      vehicleRepositoryProvider.overrideWithValue(vehicles),
      authStateProvider.overrideWith((ref) => auth),
      hosStatusProvider.overrideWith((ref) => _FakeHos()),
    ]);
    addTearDown(() {
      container.dispose();
      repo.dispose();
    });
  });

  test('logout keeps the tracking service running (unidentified driver mode)',
      () async {
    container.read(trackingOrchestratorProvider);
    auth.set(AuthStatus.authenticated);
    await container.read(trackingStateProvider.notifier).startTracking();
    await Future<void>.delayed(Duration.zero);
    expect(repo.serviceStarted, isTrue);

    auth.set(AuthStatus.unauthenticated);
    await Future<void>.delayed(Duration.zero);

    expect(repo.stopCalls, 0);
    expect(repo.serviceStarted, isTrue);
    expect(container.read(trackingStateProvider).status,
        isNot(TrackingStatus.stopped));
  });

  test('a vehicle selection auto-starts tracking', () async {
    container.read(trackingOrchestratorProvider);
    expect(repo.serviceStarted, isFalse);

    container.read(vehicleProvider.notifier).state =
        container.read(vehicleProvider).copyWith(
              selectedVehicle: const Vehicle(
                id: 'TRK-7',
                uniqueId: 'imei-7',
                name: 'T-7',
                year: '2022',
                isAssigned: true,
                activeForCurrentDriver: true,
              ),
            );
    await Future<void>.delayed(Duration.zero);

    expect(repo.serviceStarted, isTrue);
  });
}
