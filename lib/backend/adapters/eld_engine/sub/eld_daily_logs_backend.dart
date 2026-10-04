import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/daily_logs_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';
import '../models/certify_dto.dart';
import '../models/readiness_dto.dart';

/// ELD Engine implementation of [DailyLogsBackend].
class EldDailyLogsBackend implements DailyLogsBackend {
  final ApiClient _apiClient;

  const EldDailyLogsBackend(this._apiClient);

  @override
  Future<Result<RawJson>> list({
    DriverId? driverId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? certificationStatus,
    int? ruleId,
    bool? requiresAction,
    int limit = 50,
    int offset = 0,
  }) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogs,
      queryParameters: {
        if (driverId != null) 'driverId': driverId.value,
        if (startDate != null) 'startDate': startDate.toIso8601String().split('T').first,
        if (endDate != null) 'endDate': endDate.toIso8601String().split('T').first,
        if (status != null) 'status': status,
        if (certificationStatus != null) 'certificationStatus': certificationStatus,
        if (ruleId != null) 'ruleId': ruleId,
        if (requiresAction != null) 'requiresAction': requiresAction,
        'limit': limit,
        'offset': offset,
      },
      parser: (data) => data is List ? {'data': data} : (data is Map<String, dynamic> ? data : {}),
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getById(DailyLogId logId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogDetails(logId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getTeamStatus(DailyLogId logId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.teamStatus(logId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<void>> respondToCarrierEdit({
    required DailyLogId logId,
    required EditId editId,
    required String action,
    String? driverNotes,
  }) async {
    final res = await _apiClient.post<dynamic>(
      EldEndpoints.respondCarrierEdit(logId.value, editId.value),
      data: {
        'editId': editId.value,
        'action': action,
        if (driverNotes != null) 'driverNotes': driverNotes,
      },
    );
    return res.map((r) => r.isSuccess ? null : throw Exception(r.message));
  }

  @override
  Future<Result<CertifyResponseDto>> certify(CertifyRequestDto request) async {
    final res = await _apiClient.post<CertifyResponseDto>(
      EldEndpoints.certifyLog(request.dailyLogId),
      data: request.toJson(),
      parser: (data) => CertifyResponseDto.fromJson(data as Map<String, dynamic>),
    );
    return res.mapValue((r) => r.data!);
  }

  @override
  Future<Result<void>> reassignDriving({
    required DailyLogId logId,
    required DutyStatusId statusId,
    required DriverId targetCoDriverId,
    required String annotation,
  }) async {
    final res = await _apiClient.post<dynamic>(
      EldEndpoints.reassignDriving(logId.value, statusId.value),
      data: {
        'targetCoDriverId': targetCoDriverId.value,
        'annotation': annotation,
      },
    );
    return res.map((r) => r.isSuccess ? null : throw Exception(r.message));
  }

  @override
  Future<Result<RawJson>> getForm(DailyLogId logId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogForm(logId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> saveForm({
    required DailyLogId logId,
    required RawJson form,
  }) async {
    final res = await _apiClient.put<RawJson>(
      EldEndpoints.dailyLogForm(logId.value),
      data: form,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getGraphGrid(DailyLogId logId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogGraphGrid(logId.value),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<void>> lock(DailyLogId logId) async {
    final res = await _apiClient.post<dynamic>(
      EldEndpoints.lockLog(logId.value),
    );
    return res.map((r) => r.isSuccess ? null : throw Exception(r.message));
  }

  @override
  Future<Result<ReadinessDto>> getReadiness(DailyLogId logId) async {
    final res = await _apiClient.get<ReadinessDto>(
      EldEndpoints.checkReadiness(logId.value),
      parser: (data) => ReadinessDto.fromJson(data as Map<String, dynamic>),
    );
    return res.mapValue((r) => r.data!);
  }
}
