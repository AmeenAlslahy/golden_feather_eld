import '../../../../core/result/result.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/inspection_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
import '../mappers/dot_inspection_mapper.dart';

class EldInspectionBackend implements InspectionBackend {
  final ApiClient _apiClient;

  const EldInspectionBackend(this._apiClient);

  @override
  Future<Result<DotInspectionScreen>> getScreen({DriverId? driverId}) {
    return _apiClient
        .get<Map<String, dynamic>>(
          '/eld/dot-inspection',
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
          '/eld/dot-inspection/cycle',
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
          '/eld/dot-inspection/logs',
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
  }) =>
      throw UnimplementedError('EldInspectionBackend.emailLogs — Phase 2');

  @override
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId}) =>
      throw UnimplementedError('EldInspectionBackend.getInformationPacket — Phase 2');

  @override
  Future<Result<RawJson>> sendLogs({
    required DriverId driverId,
    required InspectionTransferType transferType,
    required String outputFileComment,
    String? routingCode,
    String? recipientEmail,
    int? daysCount,
    DateTime? endDate,
  }) =>
      throw UnimplementedError('EldInspectionBackend.sendLogs — Phase 2');

  @override
  Future<Result<RawJson>> startInspection({
    required DriverId driverId,
    String? inspectorName,
    String? inspectorBadge,
    String? inspectorAgency,
    String? location,
    String? notes,
  }) =>
      throw UnimplementedError('EldInspectionBackend.startInspection — Phase 2');

  @override
  Future<Result<RawJson>> getTransfers({DriverId? driverId}) =>
      throw UnimplementedError('EldInspectionBackend.getTransfers — Phase 2');
}
