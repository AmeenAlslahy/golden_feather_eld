import '../../../../core/error/app_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/daily_logs_backend.dart';
import '../../../contracts/raw_json.dart';
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
    int? deviceId,
    String? status,
    String? formStatus,
    String? certificationStatus,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? logDate,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogs,
      queryParameters: {
        'page': page,
        'size': size,
        if (driverId != null) 'driverId': driverId.value,
        if (deviceId != null) 'deviceId': deviceId,
        if (status != null) 'status': status,
        if (formStatus != null) 'formStatus': formStatus,
        if (certificationStatus != null)
          'certificationStatus': certificationStatus,
        if (startDate != null) 'startDate': _dateOnly(startDate),
        if (endDate != null) 'endDate': _dateOnly(endDate),
        if (logDate != null) 'logDate': _dateOnly(logDate),
      },
      parser: (data) => data is List
          ? <String, dynamic>{'data': data}
          : (data is Map<String, dynamic> ? data : <String, dynamic>{}),
    );
    // يحمل المغلف `pagination` فوق `data`؛ نمررها للمستودع كما هي.
    return res.mapValue((r) {
      final data = r.data ?? <String, dynamic>{};
      final pagination = r.pagination;
      if (pagination == null) return data;
      return <String, dynamic>{
        ...data,
        'pagination': {
          'page': pagination.page,
          'size': pagination.size,
          'totalElements': pagination.totalElements,
          'totalPages': pagination.totalPages,
          'hasNext': pagination.hasNext,
          'hasPrevious': pagination.hasPrevious,
        },
      };
    });
  }

  @override
  Future<Result<RawJson>> getSummary({
    DriverId? driverId,
    int? deviceId,
    String? status,
    String? formStatus,
    String? certificationStatus,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? logDate,
    int page = 0,
    int size = 20,
  }) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogSummary,
      queryParameters: {
        'page': page,
        'size': size,
        if (driverId != null) 'driverId': driverId.value,
        if (deviceId != null) 'deviceId': deviceId,
        if (status != null) 'status': status,
        if (formStatus != null) 'formStatus': formStatus,
        if (certificationStatus != null)
          'certificationStatus': certificationStatus,
        if (startDate != null) 'startDate': _dateOnly(startDate),
        if (endDate != null) 'endDate': _dateOnly(endDate),
        if (logDate != null) 'logDate': _dateOnly(logDate),
      },
      parser: (data) => data is List
          ? <String, dynamic>{'data': data}
          : (data is Map<String, dynamic> ? data : <String, dynamic>{}),
    );
    // الوثيقة (قاعدة 2): الترقيم قائم في القوائم — نمرر `pagination` كما هي.
    return res.mapValue((r) {
      final data = r.data ?? <String, dynamic>{};
      final pagination = r.pagination;
      if (pagination == null) return data;
      return <String, dynamic>{
        ...data,
        'pagination': {
          'page': pagination.page,
          'size': pagination.size,
          'totalElements': pagination.totalElements,
          'totalPages': pagination.totalPages,
          'hasNext': pagination.hasNext,
          'hasPrevious': pagination.hasPrevious,
        },
      };
    });
  }

  static String _dateOnly(DateTime date) =>
      date.toIso8601String().split('T').first;

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
  Future<Result<CertifyResponseDto>> certify(
    CertifyRequestDto request, {
    int? expectedOwnerDriverId,
  }) async {
    final res = await _apiClient.post<CertifyResponseDto>(
      EldEndpoints.certifyLog(request.dailyLogId),
      data: request.toJson(),
      parser: (data) => CertifyResponseDto.fromJson(data as Map<String, dynamic>),
      expectedOwnerDriverId: expectedOwnerDriverId,
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
    int? expectedOwnerDriverId,
  }) async {
    final res = await _apiClient.put<RawJson>(
      EldEndpoints.dailyLogForm(logId.value),
      data: form,
      parser: (data) => data is Map<String, dynamic> ? data : {},
      expectedOwnerDriverId: expectedOwnerDriverId,
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getEvents(DailyLogId logId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogEvents(logId.value),
      parser: (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
    // خادم لم يُحدَّث بعد إلى العقد الجديد → fallback للمسار القديم
    // `graph-grid` (نفس شكل الحمولة: data.events).
    if (res.isLeft() && res.errorOrNull is NotFoundError) {
      final legacy = await _apiClient.get<RawJson>(
        EldEndpoints.dailyLogGraphGrid(logId.value),
        parser: (data) =>
            data is Map<String, dynamic> ? data : <String, dynamic>{},
      );
      return legacy.mapValue((r) => r.data ?? <String, dynamic>{});
    }
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getEventDetails(
    DailyLogId logId,
    DutyStatusId eventId,
  ) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogEvent(logId.value, eventId.value),
      parser: (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> updateEvent({
    required DailyLogId logId,
    required DutyStatusId eventId,
    required RawJson event,
    int? expectedOwnerDriverId,
  }) async {
    final res = await _apiClient.put<RawJson>(
      EldEndpoints.dailyLogEvent(logId.value, eventId.value),
      data: event,
      parser: (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
      expectedOwnerDriverId: expectedOwnerDriverId,
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getEventsOptions(DailyLogId logId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogEventsOptions(logId.value),
      parser: (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getFormOptions(DailyLogId logId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogFormOptions(logId.value),
      parser: (data) => data is Map<String, dynamic> ? data : <String, dynamic>{},
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

  @override
  Future<Result<CertifyStateDto>> getCertifyState(DailyLogId logId) async {
    final res = await _apiClient.get<CertifyStateDto>(
      EldEndpoints.certifyLog(logId.value),
      parser: (data) => CertifyStateDto.fromJson(data as Map<String, dynamic>),
    );
    return res.mapValue((r) => r.data!);
  }
}
