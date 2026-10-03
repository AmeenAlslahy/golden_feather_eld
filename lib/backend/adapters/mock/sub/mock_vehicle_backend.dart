import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/vehicle_backend.dart';

/// In-memory mock for [VehicleBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockVehicleBackend implements VehicleBackend {
  const MockVehicleBackend();

  // Honest empty envelopes: a synchronous throw here crashed every page that
  // lists vehicles under the mock backend before the repository's try/catch.
  @override
  Future<Result<RawJson>> getCompanyFleet({DriverId? driverId}) async =>
      ok(<String, dynamic>{'data': <dynamic>[]});

  @override
  Future<Result<RawJson>> getMyVehicles({DriverId? driverId}) async =>
      ok(<String, dynamic>{'data': <dynamic>[]});

}
