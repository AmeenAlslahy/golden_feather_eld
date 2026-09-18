import '../../core/result/result.dart';
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
  Future<Result<RawJson>> getReadiness({
    String? uniqueId,
    DriverId? driverId,
  });

  /// GET /eld/hardware/status
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  });

  /// POST /eld/hardware/telemetry
  Future<Result<void>> sendTelemetry({
    required DriverId driverId,
    required double speed,
    double? rpm,
    double? odometer,
    double? engineHours,
    bool? engineOn,
  });
}
