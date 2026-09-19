import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import 'raw_json.dart';

abstract interface class VehicleBackend {
  /// GET /eld/company-vehicles
  Future<Result<RawJson>> getCompanyFleet({DriverId? driverId});

  /// GET /eld/company-vehicles/my-vehicles
  Future<Result<RawJson>> getMyVehicles({DriverId? driverId});

  // --- Legacy methods for P5.5 ---
  Future<Result<List<dynamic>>> getLegacyVehicles();
}
