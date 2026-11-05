import '../../../../core/error/app_error.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
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
    String? sortBy = 'id',
    String? sortDirection = 'ASC',
  }) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogs,
      queryParameters: {
        'page': page,
        'size': size,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortDirection != null) 'sortDirection': sortDirection,
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
    String? sortBy = 'id',
    String? sortDirection = 'ASC',
  }) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogSummary,
      queryParameters: {
        'page': page,
        'size': size,
        if (sortBy != null) 'sortBy': sortBy,
        if (sortDirection != null) 'sortDirection': sortDirection,
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
  Future<Result<CertifyResponseDto>> certify(
    CertifyRequestDto request, {
    int? expectedOwnerDriverId,
  }) async {
    final res = await _apiClient.post<CertifyResponseDto>(
      EldEndpoints.certifyLog(request.dailyLogId),
      data: request.toJson(),
      parser: (data) =>
          CertifyResponseDto.fromJson(data as Map<String, dynamic>),
      expectedOwnerDriverId: expectedOwnerDriverId,
    );
    return res.mapValue((r) => r.data!);
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
      parser: (data) =>
          data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getEventDetails(
    DailyLogId logId,
    DutyStatusId eventId,
  ) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogEvent(logId.value, eventId.value),
      parser: (data) =>
          data is Map<String, dynamic> ? data : <String, dynamic>{},
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
      parser: (data) =>
          data is Map<String, dynamic> ? data : <String, dynamic>{},
      expectedOwnerDriverId: expectedOwnerDriverId,
    );
    return res.fold((error) => err(error), (response) {
      // HTTP 200 وحده ليس نجاحاً: المغلف الموحّد قد يحمل
      // `success:false` مع `errors[]`. بدون هذا الفحص كان المستودع
      // يستقبل `{}` ويعرض التعديل كأنه محفوظ.
      if (!response.isSuccess) return err(_envelopeFailure(response));
      return ok(response.data ?? <String, dynamic>{});
    });
  }

  /// يحوّل مغلفاً فاشلاً (HTTP 2xx مع `success:false`) إلى [AppError]
  /// قابلاً للتصنيف في طبقة المزامنة. الأخطاء الحقلية رفض نهائي، لذا
  /// تُصنّف [ValidationError] حتى لا يعاد إرسالها إلى ما لا نهاية.
  AppError _envelopeFailure(ApiResponse<RawJson> response) {
    final fieldErrors = <String, String>{
      for (final error in response.errors) error.field: error.message,
    };
    final message = fieldErrors.isNotEmpty
        ? fieldErrors.entries
              .map((entry) => '${entry.key}: ${entry.value}')
              .join('; ')
        : response.message ?? response.errorCode ?? 'serverRejectedRequest';
    final context = <String, dynamic>{
      'statusCode': response.statusCode,
      'serverMessage': message,
      if (response.errorCode != null) 'errorCode': response.errorCode,
      if (response.requestId != null) 'requestId': response.requestId,
      if (fieldErrors.isNotEmpty) 'fieldErrors': fieldErrors,
    };
    final code = response.errorCode ?? 'server.rejectedRequest';

    if (fieldErrors.isNotEmpty) {
      return ValidationError(
        code: code,
        l10nKey: 'validationError',
        fieldErrors: fieldErrors,
        context: context,
      );
    }
    if (code.toLowerCase().contains('conflict') ||
        code.toLowerCase().contains('already')) {
      return ConflictError(
        code: code,
        l10nKey: 'conflictError',
        context: context,
      );
    }
    return ValidationError(
      code: code,
      l10nKey: 'validationError',
      context: context,
    );
  }

  @override
  Future<Result<RawJson>> getEventsOptions(DailyLogId logId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogEventsOptions(logId.value),
      parser: (data) =>
          data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getFormOptions(DailyLogId logId) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dailyLogFormOptions(logId.value),
      parser: (data) =>
          data is Map<String, dynamic> ? data : <String, dynamic>{},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<ReadinessDto>> getReadiness(DailyLogId logId) async {
    // الجاهزية مشتقة من `GET /eld/daily-logs/{id}/certify` — لا نقطة
    // readiness مستقلة في واجهة الـ12 مساراً المعتمدة.
    return (await getCertifyState(logId)).mapValue(
      (c) => ReadinessDto(
        dailyLogId: c.dailyLogId != 0 ? c.dailyLogId : logId.value,
        driverId: 0,
        driverName: '',
        logDate: c.logDate,
        readinessStatus: c.canCertify
            ? 'READY'
            : (c.certified ? 'CERTIFIED' : 'NOT_READY'),
        missingRequirements: c.validationCodes,
        legalStatement: c.statementText,
        availableActions: c.canCertify ? const ['CERTIFY'] : const [],
        carrierProposedEditsPending: c.validationCodes.contains(
          'UNCERTIFIED_EDITS_PENDING',
        ),
        pendingCarrierEdits: const [],
      ),
    );
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
