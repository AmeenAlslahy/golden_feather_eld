import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements VehicleRepository {}

class _MockStorage extends Mock implements LocalStorageService {}

void main() {
  late _MockRepo repo;
  late _MockStorage storage;

  const vehicleA = Vehicle(
    id: 'TRK-101',
    uniqueId: 'IMEI-101',
    name: 'Freightliner 101',
    year: '2023',
    activeDriverId: 101,
  );

  const vehicleB = Vehicle(
    id: 'TRK-102',
    uniqueId: 'IMEI-102',
    name: 'Volvo 102',
    year: '2022',
  );

  const vehicleC = Vehicle(
    id: 'TRK-103',
    uniqueId: 'IMEI-103',
    name: 'Kenworth 103',
    year: '2021',
  );

  setUp(() {
    repo = _MockRepo();
    storage = _MockStorage();
    when(() => storage.saveSelectedVehicleId(any())).thenAnswer((_) async {});
  });

  test('loadVehicles: selects vehicle matching activeDriverId from server', () async {
    when(() => storage.selectedVehicleId).thenReturn(null);
    when(() => repo.getVehicles()).thenAnswer(
      (_) async => const Right([vehicleA, vehicleB]),
    );

    final notifier = VehicleNotifier(repo, storage);
    notifier.bindOwner('101', 1);

    await notifier.loadVehicles();

    expect(notifier.selectedVehicle, equals(vehicleA));
    verify(() => storage.saveSelectedVehicleId('101|TRK-101')).called(1);
  });

  test('loadVehicles: restores previously saved vehicle from storage when server is unselected', () async {
    when(() => storage.selectedVehicleId).thenReturn('TRK-102');
    when(() => repo.getVehicles()).thenAnswer(
      (_) async => const Right([vehicleB, vehicleC]),
    );

    final notifier = VehicleNotifier(repo, storage);
    notifier.bindOwner('999', 1);

    await notifier.loadVehicles();

    expect(notifier.selectedVehicle, equals(vehicleB));
  });

  test('loadVehicles: restores a vehicle saved for the same driver', () async {
    when(() => storage.selectedVehicleId).thenReturn('999|TRK-102');
    when(() => repo.getVehicles()).thenAnswer(
      (_) async => const Right([vehicleB, vehicleC]),
    );

    final notifier = VehicleNotifier(repo, storage);
    notifier.bindOwner('999', 1);

    await notifier.loadVehicles();

    expect(notifier.selectedVehicle, equals(vehicleB));
  });

  test('loadVehicles: ignores a selection saved by another driver', () async {
    when(() => storage.selectedVehicleId).thenReturn('111|TRK-102');
    when(() => repo.getVehicles()).thenAnswer(
      (_) async => const Right([vehicleB, vehicleC]),
    );

    final notifier = VehicleNotifier(repo, storage);
    notifier.bindOwner('999', 1);

    await notifier.loadVehicles();

    expect(notifier.selectedVehicle, isNull);
  });

  test('loadVehicles: auto-selects single vehicle when driver has only one vehicle assigned', () async {
    when(() => storage.selectedVehicleId).thenReturn(null);
    when(() => repo.getVehicles()).thenAnswer(
      (_) async => const Right([vehicleB]),
    );

    final notifier = VehicleNotifier(repo, storage);
    notifier.bindOwner('999', 1);

    await notifier.loadVehicles();

    expect(notifier.selectedVehicle, equals(vehicleB));
    verify(() => storage.saveSelectedVehicleId('999|TRK-102')).called(1);
  });

  test('selectVehicle: saves selected vehicle id to storage', () {
    final notifier = VehicleNotifier(repo, storage);
    notifier.bindOwner('999', 1);

    notifier.selectVehicle(
      vehicleB,
      speedMps: 0.0,
      thresholdKmh: 8.0,
      trackingLive: false,
    );

    expect(notifier.selectedVehicle, equals(vehicleB));
    verify(() => storage.saveSelectedVehicleId('999|TRK-102')).called(1);
  });
}

