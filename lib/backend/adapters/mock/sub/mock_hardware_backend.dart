import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/hardware_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [HardwareBackend].
class MockHardwareBackend implements HardwareBackend {
  MockHardwareBackend();

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
    // Mirrors PreOperationReadinessResponse for the offline demo backend.
    return ok(<String, dynamic>{
      'uniqueId': uniqueId,
      'ready': false,
      'checklist': <String, bool>{
        'device_paired': true,
        'connection_active': false,
        'motion_data': false,
        'location_data': false,
        'engine_telemetry': false,
      },
      'rejectionReasons': <String>['No ELD data received yet.'],
      'recommendedAction': 'Start the engine and wait for the device to report.',
    });
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

}
