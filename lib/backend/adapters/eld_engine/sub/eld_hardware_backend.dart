// ignore_for_file: unused_field, unused_import

import '../../../../core/error/app_error.dart';
import '../../../../core/result/result.dart';
import '../../../../domain/hardware/telemetry_reading.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/hardware_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/utils/logger.dart';
import '../../../../domain/hardware/diagnostic_alert.dart';
import '../../../../core/network/api_response.dart';
import '../../../http/eld_endpoints.dart';
import '../mappers/hardware_mapper.dart';
import '../session_connect.dart';

/// ELD Engine implementation of [HardwareBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldHardwareBackend implements HardwareBackend {
  final ApiClient _apiClient;
  final Map<String, Future<Result<RawJson>>> _inFlightStatus = {};

  // Decision 2 (P1): Reconnect Loop. Callback for offline queue fallback without upward feature imports.
  final Future<void> Function(DiagnosticAlertRequest request)? onOfflineEnqueue;

  EldHardwareBackend(this._apiClient, {this.onOfflineEnqueue});

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
    DriverId? driverId,
    DriverId? coDriverId,
  }) async {
    final payload = EldSessionConnect.payload(
      uniqueId: uniqueId,
      disconnected: disconnected,
      driverId: driverId,
      coDriverId: coDriverId,
    );

    final res = await EldSessionConnect.post(
      apiClient: _apiClient,
      payload: payload,
      parser: EldSessionConnect.parsePermissiveBody,
    );

    return res.flatMap((response) {
      final requestId = EldSessionConnect.requestIdOf(response);
      final statusCode = response.statusCode;
      final failureMarker = EldSessionConnect.failureMarkerOf(response.rawBody);

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

      final data = EldSessionConnect.confirmedPayload(response);
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

  @override
  Future<Result<RawJson>> disconnectSession() async {
    final res = await _apiClient.post<RawJson>(
      EldEndpoints.disconnectSession,
      parser: (data) => data is Map<String, dynamic> ? data : {},
    );
    return res.mapValue((r) => r.data ?? <String, dynamic>{});
  }

  /// `success`/`status` false at the top level is an explicit server refusal,
  /// even when the response is a bare `{"success": false}` body that
  /// [ApiResponse] cannot recognise as an envelope.
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

  // Decision 2 (P1): Reconnect Loop. Report alert with offline queue fallback.
  @override
  Future<AlertResponse> reportAlert(DiagnosticAlertRequest request) async {
    try {
      final res = await _apiClient.post<RawJson>(
        EldEndpoints.hardwareAlerts,
        data: request.toJson(),
        parser: (data) => data is Map<String, dynamic> ? data : {},
      );
      if (res.isFailure) {
        AppLogger.warning(
          'Decision 2 (P1): reportAlert network failure (${res.errorOrNull}), fallback to offline queue',
        );
        if (onOfflineEnqueue != null) {
          await onOfflineEnqueue!(request);
        }
        return const AlertResponse(
          success: false,
          message: 'Enqueued offline due to network failure',
        );
      }
      return AlertResponse.fromJson(res.valueOrNull?.data ?? {});
    } catch (e, st) {
      AppLogger.warning(
        'Decision 2 (P1): reportAlert exception ($e), fallback to offline queue',
        e,
        st,
      );
      if (onOfflineEnqueue != null) {
        await onOfflineEnqueue!(request);
      }
      return const AlertResponse(
        success: false,
        message: 'Enqueued offline due to exception',
      );
    }
  }
}

