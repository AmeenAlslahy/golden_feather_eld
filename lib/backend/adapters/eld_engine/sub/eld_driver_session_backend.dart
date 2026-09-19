import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/driver_session_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
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
  Future<Result<List<dynamic>>> getAvailableDrivers() async {
    final response = await _apiClient.get<List<dynamic>>('/drivers');
    return response.map((res) {
      if (res.isSuccess && res.data != null) {
        return res.data!;
      }
      throw Exception(res.message ?? 'Failed to fetch drivers');
    });
  }

  @override
  Future<Result<RawJson>> getMembers(int sessionId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.sessionMembers(sessionId),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
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
  Future<Result<RawJson>> manageCoDriver({
    required CoDriverAction action,
    DriverId? coDriverId,
    DriverId? newCoDriverId,
    String? uniqueId,
    String? reason,
  }) async {
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.manageCoDriver,
      queryParameters: {
        'action': action.name,
        if (coDriverId != null) 'coDriverId': coDriverId.value,
        if (newCoDriverId != null) 'newCoDriverId': newCoDriverId.value,
        if (uniqueId != null) 'uniqueId': uniqueId,
        if (reason != null) 'reason': reason,
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
    final res = await _apiClient.post<dynamic>(
      EldEndpoints.switchPrimaryDriver,
      queryParameters: {
        'action': action.name,
        'coDriverId': coDriverId.value,
        if (reason != null) 'reason': reason,
      },
    );
    return res.map((r) => r.isSuccess ? null : throw Exception(r.message));
  }
}
