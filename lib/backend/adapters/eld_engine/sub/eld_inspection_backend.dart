import '../../../../core/error/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/inspection_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../../core/network/api_client.dart';
import '../../../http/eld_endpoints.dart';
import '../mappers/dot_inspection_mapper.dart';

class EldInspectionBackend implements InspectionBackend {
  final ApiClient _apiClient;

  const EldInspectionBackend(this._apiClient);

  @override
  Future<Result<DotInspectionScreen>> getScreen({DriverId? driverId}) {
    return _apiClient
        .get<Map<String, dynamic>>(
          EldEndpoints.inspections,
          queryParameters: driverId != null
              ? {'driverId': driverId.value}
              : null,
          parser: (data) => data is Map<String, dynamic> ? data : {},
        )
        .then(
          (r) => r.mapValue(
            (response) =>
                DotInspectionMapper.fromScreenJson(response.data ?? const {}),
          ),
        );
  }

  @override
  Future<Result<List<DotInspectionCycleDay>>> getCycle({
    DriverId? driverId,
    int days = 8,
    DateTime? endDate,
  }) async {
    final result = await _apiClient.get<List<dynamic>>(
      EldEndpoints.dotInspectionCycle,
      queryParameters: {
        if (driverId != null) 'driverId': driverId.value,
        'days': days,
        if (endDate != null)
          'endDate': endDate.toIso8601String().split('T').first,
      },
      parser: (data) => data is List ? data : <dynamic>[],
    );
    if (result.isSuccess) {
      return result.mapValue(
        (response) =>
            DotInspectionMapper.fromCycleJson(response.data ?? const []),
      );
    }
    // Fallback: If separate /cycle endpoint is absent (404), fetch root inspection session
    final sessionRes = await _apiClient.get<Map<String, dynamic>>(
      EldEndpoints.inspections,
      queryParameters: {
        'page': 0,
        'size': days,
        'sortBy': 'id',
        'sortDirection': 'ASC',
        if (driverId != null) 'driverId': driverId.value,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return sessionRes.mapValue(
      (response) =>
          DotInspectionMapper.cycleFromSessionJson(response.data ?? const {}),
    );
  }

  @override
  Future<Result<DotInspectionLog>> getLogs({
    DriverId? driverId,
    DateTime? date,
  }) async {
    // 1. Primary: The canonical OAS 3.0 / snsoft route is GET /eld/inspections,
    // which returns the complete 8-day inspection bundle (inspectionLogs[], driver, vehicle, eld, carrier).
    final sessionRes = await _apiClient.get<Map<String, dynamic>>(
      EldEndpoints.inspections,
      queryParameters: {
        'page': 0,
        'size': 20,
        'sortBy': 'id',
        'sortDirection': 'ASC',
        if (driverId != null) 'driverId': driverId.value,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    if (sessionRes.isSuccess && sessionRes.valueOrNull?.data != null) {
      final data = sessionRes.valueOrNull!.data!;
      if (data.containsKey('inspectionLogs')) {
        return ok(
          DotInspectionMapper.logFromSessionJson(data, targetDate: date),
        );
      }
      // If the root inspection endpoint returned only screen metadata without
      // the inspectionLogs array, fall through to query the dedicated log endpoint.
    }

    // 2. Fallback: Legacy /logs endpoint only if the root endpoint is absent or fails
    final result = await _apiClient.get<Map<String, dynamic>>(
      EldEndpoints.dotInspectionLogs,
      queryParameters: {
        if (driverId != null) 'driverId': driverId.value,
        if (date != null) 'date': date.toIso8601String().split('T').first,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    if (result.isSuccess) {
      final data = result.valueOrNull?.data ?? const <String, dynamic>{};
      if (data.containsKey('inspectionLogs')) {
        return ok(DotInspectionMapper.logFromSessionJson(data, targetDate: date));
      }
      return ok(DotInspectionMapper.fromLogJson(data));
    }

    return sessionRes.mapValue(
      (response) => DotInspectionMapper.logFromSessionJson(
        response.data ?? const {},
        targetDate: date,
      ),
    );
  }

  RawJson _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }

  Future<Result<RawJson>> _postJson(
    String path,
    Map<String, dynamic> data, {
    int? expectedOwnerDriverId,
  }) async {
    final res = await _apiClient.post<RawJson>(
      path,
      data: data,
      parser: _asMap,
      expectedOwnerDriverId: expectedOwnerDriverId,
    );
    return res.mapValue((response) => response.data ?? <String, dynamic>{});
  }

  /// Posts to a Swagger-documented transfer endpoint and rejects a failed
  /// unified envelope **before** its body can be mistaken for an accepted
  /// transfer. A missing `data` is not proof of success.
  Future<Result<RawJson>> _postTransferJson(
    String path,
    Map<String, dynamic> data, {
    int? expectedOwnerDriverId,
  }) async {
    final res = await _apiClient.post<RawJson>(
      path,
      data: data,
      parser: _asMap,
      expectedOwnerDriverId: expectedOwnerDriverId,
    );
    return res.flatMap((response) {
      if (response.isSuccess) {
        final payload =
            Map<String, dynamic>.from(response.data ?? <String, dynamic>{});
        if (response.message != null && response.message!.trim().isNotEmpty) {
          payload['serverMessage'] = response.message!.trim();
          payload.putIfAbsent('message', () => response.message!.trim());
        }
        return ok(payload);
      }

      final message = response.message?.trim();
      final context = <String, dynamic>{
        'endpoint': path,
        if (message != null && message.isNotEmpty) 'message': message,
        if (response.errors.isNotEmpty)
          'errors': response.errors.map((error) => error.toString()).toList(),
        if (response.requestId != null) 'requestId': response.requestId,
      };

      // Field errors are a permanent rejection; an envelope failure without
      // field errors is treated as a retryable server-side failure.
      return err(
        response.errors.isNotEmpty
            ? ValidationError(
                code: 'inspection.transfer.rejected',
                l10nKey: 'validation.badRequest',
                context: context,
              )
            : ServerError(
                code: 'inspection.transfer.rejected',
                statusCode: response.statusCode,
                context: context,
              ),
      );
    });
  }

  @override
  Future<Result<RawJson>> emailLogs({
    required DriverId driverId,
    required String recipientEmail,
    String? routingCode,
    String? comment,
    int? daysCount,
    DateTime? endDate,
    int? expectedOwnerDriverId,
  }) {
    // Swagger's EmailLogsRequest documents only driverId, recipientEmail and
    // comment. routingCode/daysCount/endDate stay in the contract for callers
    // but are not sent until the backend confirms them.
    final normalizedComment = comment?.trim();
    return _postTransferJson(EldEndpoints.dotInspectionEmailLogs, {
      'driverId': driverId.value,
      'recipientEmail': recipientEmail.trim(),
      if (normalizedComment != null && normalizedComment.isNotEmpty)
        'comment': normalizedComment,
    }, expectedOwnerDriverId: expectedOwnerDriverId);
  }

  @override
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId}) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dotInspectionPacket,
      queryParameters: driverId != null ? {'driverId': driverId.value} : null,
      parser: _asMap,
    );
    return res.mapValue((response) => response.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> sendLogs({
    required DriverId driverId,
    required InspectionTransferType transferType,
    required String outputFileComment,
    String? routingCode,
    String? recipientEmail,
    int? daysCount,
    DateTime? endDate,
    int? expectedOwnerDriverId,
  }) {
    return _postJson(EldEndpoints.dotInspectionSendLogs, {
      'driverId': driverId.value,
      'transferType': transferType.wire,
      'outputFileComment': outputFileComment,
      if (routingCode != null) 'routingCode': routingCode,
      if (recipientEmail != null) 'recipientEmail': recipientEmail,
      if (daysCount != null) 'daysCount': daysCount,
      if (endDate != null)
        'endDate': endDate.toIso8601String().split('T').first,
    }, expectedOwnerDriverId: expectedOwnerDriverId);
  }

  @override
  Future<Result<RawJson>> startInspection({
    required DriverId driverId,
    String? inspectorName,
    String? inspectorBadge,
    String? inspectorAgency,
    String? location,
    String? notes,
  }) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dotInspectionStart,
      queryParameters: {
        'page': 0,
        'size': 20,
        'sortBy': 'id',
        'sortDirection': 'ASC',
        if (driverId.value > 0) 'driverId': driverId.value,
        if (inspectorName != null) 'inspectorName': inspectorName,
        if (inspectorBadge != null) 'inspectorBadge': inspectorBadge,
        if (inspectorAgency != null) 'inspectorAgency': inspectorAgency,
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
      },
      parser: _asMap,
    );
    return res.mapValue((response) => response.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getTransfers({DriverId? driverId}) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.dotInspectionTransfers,
      queryParameters: driverId != null ? {'driverId': driverId.value} : null,
      parser: _asMap,
    );
    return res.mapValue((response) => response.data ?? <String, dynamic>{});
  }
}
