import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/hardware_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [HardwareBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockHardwareBackend implements HardwareBackend {
  const MockHardwareBackend();

  @override
  Future<Result<RawJson>> getAlerts({DriverId? driverId}) =>
      throw UnimplementedError('MockHardwareBackend.getAlerts — Phase 2');

  @override
  Future<Result<RawJson>> setManualMode({
    required bool enable,
    required String reason,
    DriverId? driverId,
  }) =>
      throw UnimplementedError('MockHardwareBackend.setManualMode — Phase 2');

  @override
  Future<Result<RawJson>> getReadiness({
    String? uniqueId,
    DriverId? driverId,
  }) =>
      throw UnimplementedError('MockHardwareBackend.getReadiness — Phase 2');

  @override
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  }) =>
      throw UnimplementedError('MockHardwareBackend.getStatus — Phase 2');

  @override
  Future<Result<void>> sendTelemetry({
    required DriverId driverId,
    required double speed,
    double? rpm,
    double? odometer,
    double? engineHours,
    bool? engineOn,
  }) =>
      throw UnimplementedError('MockHardwareBackend.sendTelemetry — Phase 2');
}
