import 'dart:async';
import 'package:golden_feather_eld/core/config/app_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fpdart/fpdart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/features/tracking/domain/entities/location_entity.dart';
import 'package:golden_feather_eld/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:golden_feather_eld/core/services/battery_optimization_service.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';

// Fake Repository
class FakeTrackingRepository implements TrackingRepository {
  final StreamController<LocationEntity> _locationStreamController =
      StreamController<LocationEntity>.broadcast();
  bool isServiceStarted = false;

  @override
  Stream<LocationEntity> get locationStream => _locationStreamController.stream;

  void emitLocation(LocationEntity location) {
    _locationStreamController.add(location);
  }

  void emitError(Exception error) {
    _locationStreamController.addError(error);
  }

  @override
  Future<Either<Failure, bool>> startTracking() async {
    isServiceStarted = true;
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> stopTracking() async {
    isServiceStarted = false;
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> clearLogs() async => const Right(true);

  @override
  Future<TrackingConfigEntity> getCurrentConfig() async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LocationEntity>> getCurrentLocation() async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<TrackingLogEntity>>> getLogs() async =>
      const Right([]);

  @override
  Future<bool> isTracking() async => isServiceStarted;

  @override
  Future<Either<Failure, LocationEntity>> requestPosition(
          {String? alarm}) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, bool>> updateConfig(
          TrackingConfigEntity config) async =>
      const Right(true);

  void dispose() {
    _locationStreamController.close();
  }
}

// Fake Battery Service
class FakeBatteryOptimizationService implements BatteryOptimizationService {
  @override
  Future<bool> isBatteryOptimizationEnabled() async => false;

  Future<void> openBatteryOptimizationSettings() async {}

  Future<bool> requestIgnoreBatteryOptimizations() async => true;

  @override
  Future<void> requestDisableBatteryOptimization() async {}
}

class MockLocalStorageService extends Mock implements LocalStorageService {}

class MockVehicleRepository extends Mock implements VehicleRepository {}

void main() {
  late FakeTrackingRepository fakeRepository;
  late ProviderContainer container;
  late TrackingNotifier notifier;

  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppEnvironmentConfig.init(testEnv: {'API_BASE_URL': 'http://mock.test'});
    SharedPreferences.setMockInitialValues({});
    fakeRepository = FakeTrackingRepository();
    final mockLocalStorage = MockLocalStorageService();
    when(() => mockLocalStorage.currentDutyStatus).thenReturn('off_duty');
    when(() => mockLocalStorage.serverUrl).thenReturn('http://mock.test');
    when(() => mockLocalStorage.backendType).thenReturn('traccar');

    final mockVehicleRepo = MockVehicleRepository();
    when(() => mockVehicleRepo.getSelectedVehicle()).thenAnswer((_) async => const Right(null));
    when(() => mockVehicleRepo.getVehicles()).thenAnswer((_) async => const Right([]));

    container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(mockLocalStorage),
        batteryOptimizationServiceProvider
            .overrideWithValue(FakeBatteryOptimizationService()),
        trackingRepositoryProvider.overrideWithValue(fakeRepository),
        vehicleRepositoryProvider.overrideWithValue(mockVehicleRepo),
      ],
    );
    notifier = container.read(trackingStateProvider.notifier);
  });

  tearDown(() {
    fakeRepository.dispose();
    container.dispose();
  });

  test(
      'startTracking sets status to loading initially and waits for first location to become active',
      () async {
    expect(notifier.state.status, TrackingStatus.initial);

    // Call startTracking
    await notifier.startTracking(skipBatteryCheck: true);

    // After startTracking completes, the service is started but UI shouldn't be active yet.
    // It should be loading or waiting. Wait, my code sets it to active ON first location.
    // So immediately after start, status is loading!
    expect(
        container.read(trackingStateProvider).status, TrackingStatus.loading);
    expect(container.read(trackingStateProvider).isTracking, false);
    expect(fakeRepository.isServiceStarted, true);

    // Now emit the first location
    final testLocation = LocationEntity(
      latitude: 24.0,
      longitude: 46.0,
      timestamp: DateTime.now(),
    );
    fakeRepository.emitLocation(testLocation);

    // Allow event loop to process stream
    await Future.delayed(Duration.zero);

    // Now state should be active
    expect(container.read(trackingStateProvider).status, TrackingStatus.active);
    expect(container.read(trackingStateProvider).isTracking, true);
    expect(container.read(trackingStateProvider).currentLocation, testLocation);
  });

  test('location stream error sets state to error and stops tracking status',
      () async {
    await notifier.startTracking(skipBatteryCheck: true);

    fakeRepository.emitError(Exception('Stream error'));

    await Future.delayed(Duration.zero);

    expect(container.read(trackingStateProvider).status, TrackingStatus.error);
    expect(container.read(trackingStateProvider).isTracking, false);
    expect(container.read(trackingStateProvider).errorType,
        TrackingErrorType.technical);
  });

  test('stopTracking cancels subscription and sets state to stopped', () async {
    await notifier.startTracking(skipBatteryCheck: true);

    fakeRepository.emitLocation(LocationEntity.empty());
    await Future.delayed(Duration.zero);
    expect(container.read(trackingStateProvider).isTracking, true);

    await notifier.stopTracking();

    expect(
        container.read(trackingStateProvider).status, TrackingStatus.stopped);
    expect(container.read(trackingStateProvider).isTracking, false);
    expect(fakeRepository.isServiceStarted, false);

    // Emitting location after stop should not change state
    fakeRepository.emitLocation(LocationEntity(
      latitude: 10.0,
      longitude: 10.0,
      timestamp: DateTime.now(),
    ));
    await Future.delayed(Duration.zero);

    expect(
        container.read(trackingStateProvider).status, TrackingStatus.stopped);
    expect(container.read(trackingStateProvider).isTracking, false);
  });
}
