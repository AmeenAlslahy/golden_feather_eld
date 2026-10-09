// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/hardware/telemetry_reading.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/hardware_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../../core/network/api_client.dart';
import '../../../http/eld_endpoints.dart';
import '../mappers/hardware_mapper.dart';

/// ELD Engine implementation of [HardwareBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldHardwareBackend implements HardwareBackend {
  final ApiClient _apiClient;

  const EldHardwareBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getAlerts({DriverId? driverId}) async {
    final res = await _apiClient.get<RawJson>(
      EldEndpoints.hardwareAlerts,
      queryParameters: driverId != null ? {'driverId': driverId.value} : null,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> setManualMode({
    required bool enable,
    required String reason,
    DriverId? driverId,
  }) async {
    final Map<String, dynamic> query = {};
    if (driverId != null) query['driverId'] = driverId.value;

    final res = await _apiClient.post<RawJson>(
      EldEndpoints.hardwareManualMode,
      queryParameters: query.isNotEmpty ? query : null,
      data: {
        'enable': enable,
        'reason': reason,
      },
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getReadiness({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    final Map<String, dynamic> query = {};
    if (uniqueId != null) query['uniqueId'] = uniqueId;
    if (driverId != null) query['driverId'] = driverId.value;

    final res = await _apiClient.get<RawJson>(
      EldEndpoints.hardwareReadiness,
      queryParameters: query.isNotEmpty ? query : null,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> connectSession({
    String? uniqueId,
    bool disconnected = false,
  }) async {
    final Map<String, dynamic> query = {};
    if (uniqueId != null) query['uniqueId'] = uniqueId;
    if (disconnected) query['disconnected'] = true;

    final res = await _apiClient.post<RawJson>(
      EldEndpoints.connectSession,
      queryParameters: query.isNotEmpty ? query : null,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    final Map<String, dynamic> query = {};
    if (uniqueId != null) query['uniqueId'] = uniqueId;
    if (driverId != null) query['driverId'] = driverId.value;

    final res = await _apiClient.get<RawJson>(
      EldEndpoints.hardwareStatus,
      queryParameters: query.isNotEmpty ? query : null,
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        throw const FormatException('connectivity body is not an object');
      },
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  @override
  Future<Result<RawJson>> sendTelemetry(TelemetryReading reading) async {
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.hardwareTelemetry,
      data: HardwareMapper.telemetryToJson(reading),
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }
}
