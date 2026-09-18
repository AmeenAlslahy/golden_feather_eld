import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/vehicle_backend.dart';

/// In-memory mock for [VehicleBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockVehicleBackend implements VehicleBackend {
  const MockVehicleBackend();

  @override
  Future<Result<RawJson>> getCompanyFleet({DriverId? driverId}) =>
      throw UnimplementedError('MockVehicleBackend.getCompanyFleet — Phase 2');

  @override
  Future<Result<RawJson>> getMyVehicles({DriverId? driverId}) =>
      throw UnimplementedError('MockVehicleBackend.getMyVehicles — Phase 2');
}
