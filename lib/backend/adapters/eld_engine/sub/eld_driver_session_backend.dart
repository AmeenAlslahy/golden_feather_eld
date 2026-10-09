import '../../../../core/error/app_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/driver_session_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/eld_endpoints.dart';

/// ELD Engine implementation of [DriverSessionBackend].
class EldDriverSessionBackend implements DriverSessionBackend {
  final ApiClient _apiClient;

  const EldDriverSessionBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getActiveSession(DriverId driverId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.getSession(driverId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getCurrentCoDriver() async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.manageCoDriver,
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        throw const FormatException('co-driver body is not an object');
      },
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<List<dynamic>>> getAvailableDrivers() async {
    final response = await _apiClient.get<List<dynamic>>(EldEndpoints.drivers);
    return response.map((res) {
      if (res.isSuccess && res.data != null) {
        return res.data!;
      }
      throw Exception(res.message ?? 'Failed to fetch drivers');
    });
  }

  @override
  Future<Result<RawJson>> connect({
    String? uniqueId,
    bool disconnected = false,
  }) async {
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.connectSession,
      queryParameters: {
        if (uniqueId != null) 'uniqueId': uniqueId,
        if (disconnected) 'disconnected': disconnected,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<void>> switchPrimaryDriver({
    required DutyStatusAction action,
    required DriverId coDriverId,
    String? reason,
  }) async {
    final payload = <String, dynamic>{
      'action': action.wire,
      'coDriverId': coDriverId.value,
      if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
    };
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.switchPrimaryDriver,
      queryParameters: payload,
      data: payload,
      parser: (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
    return res.fold(
      err,
      (response) => response.isSuccess
          ? ok(null)
          : err(ServerError(
              code: 'eld.request_failed',
              context: {'message': response.message},
            )),
    );
  }
}
