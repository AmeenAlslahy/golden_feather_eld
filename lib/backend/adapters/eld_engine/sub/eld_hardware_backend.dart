// ignore_for_file: unused_field, unused_import

import '../../../../core/error/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/hardware/telemetry_reading.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/hardware_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_response.dart';
import '../../../http/eld_endpoints.dart';
import '../mappers/hardware_mapper.dart';

/// ELD Engine implementation of [HardwareBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldHardwareBackend implements HardwareBackend {
  final ApiClient _apiClient;
  final Map<String, Future<Result<RawJson>>> _inFlightStatus = {};

  EldHardwareBackend(this._apiClient);

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
      data: {'enable': enable, 'reason': reason},
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
    if (res.isSuccess && res.valueOrNull?.data != null) {
      return res.mapValue((r) => r.data ?? <String, dynamic>{});
    }
    final isNotFound = res.isFailure && res.errorOrNull is NotFoundError;
    if (isNotFound) {
      return ok(<String, dynamic>{
        'ready': true,
        'checklist': <String, bool>{},
        'rejectionReasons': <String>[],
      });
    }
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  static const String _connectRejectedCode = 'eld.session.connectRejected';
  static const String _connectUnconfirmedCode =
      'eld.session.connectUnconfirmed';

  /// Confirmed success requires **all** of the following:
  ///
  /// 1. Transport success (`Right`) and an HTTP 2xx response.
  /// 2. No explicit top-level failure marker (`success: false` or
  ///    `status: false`, including the bare `{"success": false}` body).
  /// 3. A non-empty JSON object payload — either the envelope's `data` or a
  ///    direct response body.
  ///
  /// No individual `DriverSessionModel` field is required: the OpenAPI schema
  /// marks none of them as required. Missing, empty, or non-object `data`
  /// therefore yields an explicit "unconfirmed" error instead of
  /// `{}` being reported as success.
  @override
  Future<Result<RawJson>> connectSession({
    String? uniqueId,
    bool disconnected = false,
  }) async {
    final Map<String, dynamic> query = {};
    if (uniqueId != null) query['uniqueId'] = uniqueId;
    if (disconnected) query['disconnected'] = true;

    final payload = <String, dynamic>{
      if (uniqueId != null) 'deviceId': uniqueId,
      'manualMode': disconnected,
      'manualModeEnabled': disconnected,
    };

    final res = await _apiClient.post<RawJson>(
      EldEndpoints.connectSession,
      queryParameters: query.isNotEmpty ? query : null,
      data: payload,
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        return <String, dynamic>{};
      },
    );

    return res.flatMap((response) {
      final requestId = _requestIdOf(response.rawBody) ?? response.requestId;
      final statusCode = response.statusCode;
      final failureMarker = _explicitFailureMarker(response.rawBody);

      if (!response.isSuccess || failureMarker != null) {
        return err<RawJson>(
          ServerError(
            code: _connectRejectedCode,
            l10nKey: 'sessionConnectRejected',
            statusCode: statusCode,
            context: {
              'statusCode': statusCode,
              'reason': failureMarker ?? 'http_or_envelope_failure',
              if (requestId != null) 'requestId': requestId,
            },
          ),
        );
      }

      final data = _confirmedPayload(response);
      if (data == null) {
        return err<RawJson>(
          ServerError(
            code: _connectUnconfirmedCode,
            l10nKey: 'sessionStatusUnconfirmed',
            statusCode: statusCode,
            context: {
              'statusCode': statusCode,
              'reason': 'missing_or_malformed_data',
              if (requestId != null) 'requestId': requestId,
            },
          ),
        );
      }

      return ok<RawJson>(data);
    });
  }

  /// `success`/`status` false at the top level is an explicit server refusal,
  /// even when the response is a bare `{"success": false}` body that
  /// [ApiResponse] cannot recognise as an envelope.
  String? _explicitFailureMarker(Object? rawBody) {
    if (rawBody is! Map) return null;
    if (_isFalse(rawBody['success'])) return 'success_false';
    if (_isFalse(rawBody['status'])) return 'status_false';
    return null;
  }

  bool _isFalse(Object? value) {
    if (value == false) return true;
    return value is String && value.trim().toLowerCase() == 'false';
  }

  /// Returns only the payload that is strong enough to call the session
  /// confirmed. Envelope-shaped bodies must carry a non-empty object `data`;
  /// direct bodies must themselves be a non-empty object.
  Map<String, dynamic>? _confirmedPayload(ApiResponse<RawJson> response) {
    final body = _asStringMap(response.rawBody);
    if (body != null) {
      final isEnvelope =
          body.containsKey('success') ||
          body.containsKey('data') ||
          (body.containsKey('code') && body.containsKey('status'));
      if (isEnvelope) {
        final data = _asStringMap(body['data']);
        if (data == null || data.isEmpty) return null;
        return data;
      }
    }

    final data = response.data;
    if (data == null || data.isEmpty) return null;
    return data;
  }

  Map<String, dynamic>? _asStringMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String? _requestIdOf(Object? rawBody) {
    if (rawBody is! Map) return null;
    final value = rawBody['requestId'];
    if (value is! String) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    final key = '${uniqueId ?? ''}:${driverId?.value ?? ''}';
    if (_inFlightStatus.containsKey(key)) {
      return _inFlightStatus[key]!;
    }
    final future = _fetchStatus(uniqueId: uniqueId, driverId: driverId);
    _inFlightStatus[key] = future;
    try {
      return await future;
    } finally {
      _inFlightStatus.remove(key);
    }
  }

  Future<Result<RawJson>> _fetchStatus({
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
    if (res.isSuccess && res.valueOrNull?.data != null) {
      return res.mapValue((r) => r.data ?? <String, dynamic>{});
    }
    final isNotFound = res.isFailure && res.errorOrNull is NotFoundError;
    if (isNotFound) {
      return ok(<String, dynamic>{
        'connectionStatus': 'DISCONNECTED',
        'deviceStatus': 'DISCONNECTED',
        'normalOperationAllowed': true,
        'isReliable': false,
        'activeDiagnostics': <String>[],
        'activeMalfunctions': <String>[],
        'alerts': <String>[],
      });
    }
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
