import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/duty_status_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';

/// ELD Engine implementation of [DutyStatusBackend].
class EldDutyStatusBackend implements DutyStatusBackend {
  final ApiClient _apiClient;

  const EldDutyStatusBackend(this._apiClient);

  @override
  Future<Result<RawJson>> record(RawJson event) async {
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.dutyStatus,
      data: event,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> update({
    required DutyStatusId statusId,
    required RawJson update,
  }) async {
    final res = await _apiClient.put<RawJson>(
      EldEndpoints.updateDutyStatus(statusId.value),
      data: update,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getEditForm(DutyStatusId statusId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.editDutyStatusForm(statusId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getGraphGrid({
    DriverId? driverId,
    required DateTime logDate,
  }) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.graphGridTimeline,
      queryParameters: {
        if (driverId != null) 'driverId': driverId.value,
        'logDate': logDate.toIso8601String().split('T').first,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<void>> submitLegacyDutyStatusEvent(
      int driverId, RawJson payload) async {
    final response = await _apiClient.post<dynamic>(
      '/eld/duty-status',
      data: payload,
    );
    return response.map((res) {
      if (!res.isSuccess) {
        throw Exception(res.message ?? 'Failed to submit duty status');
      }
      return null;
    });
  }

  @override
  Future<Result<void>> submitLegacyGenericEvent(RawJson payload) async {
    final response = await _apiClient.post<dynamic>(
      '/events',
      data: payload,
    );
    return response.map((res) {
      if (!res.isSuccess) {
        throw Exception(res.message ?? 'Failed to submit event');
      }
      return null;
    });
  }
}
