import '../../../../core/domain/inspection/dot_inspection.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/inspection_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
import '../../../http/eld_endpoints.dart';
import '../mappers/dot_inspection_mapper.dart';

class EldInspectionBackend implements InspectionBackend {
  final ApiClient _apiClient;

  const EldInspectionBackend(this._apiClient);

  @override
  Future<Result<DotInspectionScreen>> getScreen({DriverId? driverId}) {
    return _apiClient
        .get<Map<String, dynamic>>(
          EldEndpoints.dotInspection,
          queryParameters:
              driverId != null ? {'driverId': driverId.value} : null,
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
  }) {
    return _apiClient
        .get<List<dynamic>>(
          EldEndpoints.dotInspectionCycle,
          queryParameters: {
            if (driverId != null) 'driverId': driverId.value,
            'days': days,
            if (endDate != null)
              'endDate': endDate.toIso8601String().split('T').first,
          },
          parser: (data) => data is List ? data : <dynamic>[],
        )
        .then(
          (r) => r.mapValue(
            (response) =>
                DotInspectionMapper.fromCycleJson(response.data ?? const []),
          ),
        );
  }

  @override
  Future<Result<DotInspectionLog>> getLogs({
    DriverId? driverId,
    DateTime? date,
  }) {
    return _apiClient
        .get<Map<String, dynamic>>(
          EldEndpoints.dotInspectionLogs,
          queryParameters: {
            if (driverId != null) 'driverId': driverId.value,
            if (date != null)
              'date': date.toIso8601String().split('T').first,
          },
          parser: (data) => data is Map<String, dynamic> ? data : {},
        )
        .then(
          (r) => r.mapValue(
            (response) =>
                DotInspectionMapper.fromLogJson(response.data ?? const {}),
          ),
        );
  }

  @override
  Future<Result<RawJson>> emailLogs({
    required DriverId driverId,
    required String recipientEmail,
    String? routingCode,
    String? comment,
    int? daysCount,
    DateTime? endDate,
  }) async {
    final response = await _apiClient.post<RawJson>(
      EldEndpoints.dotInspectionEmailLogs,
      data: {
        'driverId': driverId.value,
        'recipientEmail': recipientEmail,
        if (routingCode != null) 'routingCode': routingCode,
        if (comment != null) 'comment': comment,
        if (daysCount != null) 'daysCount': daysCount,
        if (endDate != null) 'endDate': endDate.toIso8601String().split('T').first,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return response.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId}) async {
    final response = await _apiClient.get<RawJson>(
      EldEndpoints.dotInspectionInfoPacket,
      queryParameters: driverId != null ? {'driverId': driverId.value} : null,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return response.mapValue((r) => r.data ?? <String, dynamic>{});
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
  }) async {
    final response = await _apiClient.post<RawJson>(
      EldEndpoints.dotInspectionSendLogs,
      data: {
        'driverId': driverId.value,
        'transferType': transferType.name.toUpperCase(),
        'outputFileComment': outputFileComment,
        if (routingCode != null) 'routingCode': routingCode,
        if (recipientEmail != null) 'recipientEmail': recipientEmail,
        if (daysCount != null) 'daysCount': daysCount,
        if (endDate != null) 'endDate': endDate.toIso8601String().split('T').first,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return response.mapValue((r) => r.data ?? <String, dynamic>{});
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
    final response = await _apiClient.post<RawJson>(
      EldEndpoints.dotInspectionStart,
      data: {
        'driverId': driverId.value,
        if (inspectorName != null) 'inspectorName': inspectorName,
        if (inspectorBadge != null) 'inspectorBadge': inspectorBadge,
        if (inspectorAgency != null) 'inspectorAgency': inspectorAgency,
        if (location != null) 'location': location,
        if (notes != null) 'notes': notes,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return response.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getTransfers({DriverId? driverId}) async {
    final response = await _apiClient.get<RawJson>(
      EldEndpoints.dotInspectionTransfers,
      queryParameters: driverId != null ? {'driverId': driverId.value} : null,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return response.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<List<dynamic>>> getLegacyInspectionReport(int driverId) async {
    final response = await _apiClient.get<dynamic>('/eld/report/inspection/$driverId');
    return response.map((res) {
      if (res.isSuccess && res.data != null) {
        final data = res.data;
        if (data is List) return data;
        if (data is Map && data.containsKey('days')) return data['days'] as List<dynamic>;
        return [];
      }
      throw Exception(res.message ?? 'Failed to fetch inspection report');
    });
  }

  @override
  Future<Result<void>> exportLegacyInspectionData(
      int driverId, String method, String? email, bool isErods) async {
    final response = await _apiClient.post<dynamic>(
      '/eld/report/inspection/$driverId/export',
      data: {
        'method': method,
        'email': email,
        'isErods': isErods,
      },
    );
    return response.map((res) {
      if (!res.isSuccess) {
        throw Exception(res.message ?? 'Failed to export inspection data');
      }
      return;
    });
  }
}
