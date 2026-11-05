import '../../../../core/result/result.dart';
import '../../../../domain/hardware/diagnostic_alert.dart';
import '../../../../domain/hardware/telemetry_reading.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/hardware_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [HardwareBackend].
class MockHardwareBackend implements HardwareBackend {
  const MockHardwareBackend();

  @override
  Future<Result<RawJson>> getAlerts({DriverId? driverId}) async {
    return ok(<String, dynamic>{
      'malfunctions': <String>[],
      'diagnostics': <String>[],
      'unidentifiedDriving': false,
    });
  }

  @override
  Future<Result<RawJson>> setManualMode({
    required bool enable,
    required String reason,
    DriverId? driverId,
  }) async {
    return ok(<String, dynamic>{
      'manual_mode': enable,
      'reason': reason,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  @override
  Future<Result<RawJson>> getReadiness({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    return ok(<String, dynamic>{
      'ready': true,
      'checklist': <String, bool>{
        'engine_connected': false,
        'connection_active': false,
        'motion_data': false,
        'location_data': false,
        'engine_telemetry': false,
      },
      'rejectionReasons': <String>['No ELD data received yet.'],
      'recommendedAction':
          'Start the engine and wait for the device to report.',
    });
  }

  @override
  Future<Result<RawJson>> connectSession({
    String? uniqueId,
    bool disconnected = false,
    DriverId? driverId,
    DriverId? coDriverId,
  }) async {
    return ok(<String, dynamic>{
      'status': 'success',
      'message': 'connected',
      'uniqueId': uniqueId,
      'disconnected': disconnected,
      if (driverId != null) 'driverId': driverId.value,
      if (coDriverId != null) 'coDriverId': coDriverId.value,
    });
  }

  @override
  Future<Result<RawJson>> disconnectSession() async {
    return ok(<String, dynamic>{
      'status': 'success',
      'message': 'disconnected',
    });
  }

  @override
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    throw UnimplementedError('MockHardwareBackend.getStatus — not implemented');
  }

  @override
  Future<Result<RawJson>> sendTelemetry(TelemetryReading reading) async {
    return ok(<String, dynamic>{'success': true});
  }

  // Decision 2 (P1): Reconnect Loop
  @override
  Future<AlertResponse> reportAlert(DiagnosticAlertRequest request) async {
    return AlertResponse(
      success: true,
      alertId: 'mock-alert-${request.attemptNumber}',
      message: 'Alert reported successfully',
    );
  }
}
