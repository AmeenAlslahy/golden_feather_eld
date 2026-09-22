// ignore_for_file: unused_field, unused_import

import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../../core/utils/logger.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/vehicle_backend.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';

/// ELD Engine implementation of [VehicleBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldVehicleBackend implements VehicleBackend {
  final ApiClient _apiClient;

  const EldVehicleBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getCompanyFleet({DriverId? driverId}) =>
      throw UnimplementedError('EldVehicleBackend.getCompanyFleet — Phase 2');

  @override
  Future<Result<RawJson>> getMyVehicles({DriverId? driverId}) async {
    final response = await _apiClient.get<List<dynamic>>(
      EldEndpoints.devices,
      parser: (data) => data is List ? data : [],
    );

    return response.mapValue((res) {
      final list = res.data ?? <dynamic>[];
      AppLogger.info('🚗 [EldVehicleBackend] Fetched ${list.length} vehicles from server: $list');
      return {'data': list};
    });
  }

  @override
  Future<Result<List<dynamic>>> getLegacyVehicles() async {
    final response = await _apiClient.get<List<dynamic>>(
      EldEndpoints.devices,
      parser: (data) => data is List ? data : [],
    );
    return response.mapValue((res) => res.data ?? []);
  }
}
