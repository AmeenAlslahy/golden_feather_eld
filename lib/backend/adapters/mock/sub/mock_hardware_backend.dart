import '../../../../core/result/result.dart';
import '../../../../domain/hardware/telemetry_reading.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/hardware_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [HardwareBackend].
///
/// **State:**
/// - Records every [sendTelemetry] call in memory.
/// - Exposes [sentTelemetry] for test assertions.
class MockHardwareBackend implements HardwareBackend {
  MockHardwareBackend();

  final List<TelemetryReading> _sentTelemetry = [];

  /// All telemetry readings sent through this mock.
  List<TelemetryReading> get sentTelemetry =>
      List.unmodifiable(_sentTelemetry);

  /// Clears the recorded telemetry (for test isolation).
  void clearTelemetry() => _sentTelemetry.clear();

  @override
  Future<Result<RawJson>> getAlerts({DriverId? driverId}) async {
    throw UnimplementedError('MockHardwareBackend.getAlerts — not implemented');
  }

  @override
  Future<Result<RawJson>> setManualMode({
    required bool enable,
    required String reason,
    DriverId? driverId,
  }) async {
    return ok(<String, dynamic>{
      'connectionStatus': enable ? 'MALFUNCTION' : 'CONNECTED',
      'manualModeActive': enable,
      'reason': reason,
    });
  }

  @override
  Future<Result<RawJson>> getReadiness({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    throw UnimplementedError('MockHardwareBackend.getReadiness — not implemented');
  }

  @override
  Future<Result<RawJson>> connectSession({
    String? uniqueId,
    bool disconnected = false,
  }) async {
    throw UnimplementedError('MockHardwareBackend.connectSession — not implemented');
  }

  @override
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    throw UnimplementedError('MockHardwareBackend.getStatus — not implemented');
  }

  @override
  Future<Result<void>> sendTelemetry(TelemetryReading reading) async {
    _sentTelemetry.add(reading);
    return ok(null);
  }
}
