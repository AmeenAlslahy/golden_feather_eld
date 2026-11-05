import '../../core/result/result.dart';
import '../../domain/hardware/diagnostic_alert.dart';
import '../../domain/hardware/telemetry_reading.dart';
import '../../domain/shared/value_objects.dart';
import 'raw_json.dart';

abstract interface class HardwareBackend {
  /// GET /eld/hardware/alerts
  Future<Result<RawJson>> getAlerts({DriverId? driverId});

  /// POST /eld/hardware/manual-mode
  Future<Result<RawJson>> setManualMode({
    required bool enable,
    required String reason,
    DriverId? driverId,
  });

  /// GET /eld/hardware/readiness
  Future<Result<RawJson>> getReadiness({String? uniqueId, DriverId? driverId});

  /// POST /eld/sessions/connect
  ///
  /// لا توجد Query Parameters؛ كل الحقول تُرسل في جسم الطلب:
  /// `driverId`, `coDriverId`, `deviceId`, `manualMode`, `manualModeEnabled`.
  Future<Result<RawJson>> connectSession({
    String? uniqueId,
    bool disconnected = false,
    DriverId? driverId,
    DriverId? coDriverId,
  });

  /// POST /eld/sessions/disconnect
  Future<Result<RawJson>> disconnectSession();

  /// GET /eld/hardware/status
  Future<Result<RawJson>> getStatus({String? uniqueId, DriverId? driverId});

  /// POST /eld/hardware/telemetry
  Future<Result<RawJson>> sendTelemetry(TelemetryReading reading);

  /// Decision 2 (P1): Report hardware diagnostic alert (e.g. BLE reconnect alert).
  /// Falls back to offline queue on network failures.
  Future<AlertResponse> reportAlert(DiagnosticAlertRequest request);
}
