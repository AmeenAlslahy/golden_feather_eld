// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/vehicle_backend.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [VehicleBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldVehicleBackend implements VehicleBackend {
  final ApiClient _apiClient;

  const EldVehicleBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getCompanyFleet({DriverId? driverId}) =>
      throw UnimplementedError('EldVehicleBackend.getCompanyFleet — Phase 2');

  @override
  Future<Result<RawJson>> getMyVehicles({DriverId? driverId}) =>
      throw UnimplementedError('EldVehicleBackend.getMyVehicles — Phase 2');
}
