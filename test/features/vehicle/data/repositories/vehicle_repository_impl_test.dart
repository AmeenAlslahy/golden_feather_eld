import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/vehicle_backend.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/features/vehicle/data/repositories/vehicle_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockVehicleBackend extends Mock implements VehicleBackend {}
class MockLocalStorageService extends Mock implements LocalStorageService {}
class MockNetworkInfo extends Mock implements NetworkInfo {}

void main() {
  late MockVehicleBackend mockBackend;
  late MockLocalStorageService mockStorage;
  late MockNetworkInfo mockNetworkInfo;
  late VehicleRepositoryImpl repository;

  setUp(() {
    mockBackend = MockVehicleBackend();
    mockStorage = MockLocalStorageService();
    mockNetworkInfo = MockNetworkInfo();
    repository = VehicleRepositoryImpl(
      vehicleBackend: mockBackend,
      localDataSource: mockStorage,
      networkInfo: mockNetworkInfo,
    );

    when(() => mockNetworkInfo.isConnected).thenReturn(true);
  });

  group('VehicleRepositoryImpl Tests', () {
    test('successfully parses list of vehicles from getMyVehicles', () async {
      when(() => mockBackend.getMyVehicles(driverId: any(named: 'driverId')))
          .thenAnswer((_) async => ok({
                'data': [
                  {
                    'vehicleId': 'VIN-101',
                    'vehicleName': 'Truck 101',
                    'vin': 'VIN-101',
                    'model': 'Cascadia',
                    'myVehicle': true,
                    'inUseByOtherDriver': false,
                  },
                  {
                    'vehicleId': 'VIN-102',
                    'vehicleName': 'Truck 102',
                    'vin': 'VIN-102',
                    'model': 'LT',
                    'myVehicle': false,
                    'inUseByOtherDriver': false,
                  }
                ]
              }));

      final result = await repository.getVehicles();

      expect(result.isRight(), isTrue);
      result.fold(
        (failure) => fail('Should not fail: $failure'),
        (vehicles) {
          expect(vehicles.length, equals(2));
          expect(vehicles[0].id, equals('VIN-101'));
          expect(vehicles[0].name, equals('Truck 101'));
          expect(vehicles[0].isAssigned, isTrue);
          expect(vehicles[1].id, equals('VIN-102'));
          expect(vehicles[1].isAssigned, isFalse);
        },
      );
    });
  });
}
