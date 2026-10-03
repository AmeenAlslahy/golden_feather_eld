// ignore_for_file: unused_field, unused_import

import '../../../../core/error/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
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
  Future<Result<RawJson>> getCompanyFleet({DriverId? driverId}) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.companyVehicles,
      queryParameters:
          driverId != null ? {'driverId': driverId.value} : null,
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        if (data is List) return {'items': data};
        throw const FormatException('vehicle list is not an object');
      },
    );
    return res.mapValue((response) => response.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getMyVehicles({DriverId? driverId}) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.myVehicles,
      queryParameters:
          driverId != null ? {'driverId': driverId.value} : null,
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        if (data is List) return {'items': data};
        return <String, dynamic>{};
      },
    );
    return res.mapValue((response) => response.data ?? <String, dynamic>{});
  }

}
