// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/hardware/telemetry_reading.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/hardware_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';
import '../mappers/hardware_mapper.dart';

/// ELD Engine implementation of [HardwareBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldHardwareBackend implements HardwareBackend {
  final ApiClient _apiClient;

  const EldHardwareBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getAlerts({DriverId? driverId}) =>
      throw UnimplementedError('EldHardwareBackend.getAlerts — Phase 2');

  @override
  Future<Result<RawJson>> setManualMode({
    required bool enable,
    required String reason,
    DriverId? driverId,
  }) =>
      throw UnimplementedError('EldHardwareBackend.setManualMode — Phase 2');

  @override
  Future<Result<RawJson>> getReadiness({
    String? uniqueId,
    DriverId? driverId,
  }) =>
      throw UnimplementedError('EldHardwareBackend.getReadiness — Phase 2');

  @override
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  }) =>
      throw UnimplementedError('EldHardwareBackend.getStatus — Phase 2');

  @override
  Future<Result<void>> sendTelemetry(TelemetryReading reading) {
    return _apiClient
        .post<dynamic>(
          '/eld/hardware/telemetry',
          data: HardwareMapper.telemetryToJson(reading),
        )
        .then(
          (result) => result.mapValue((_) {}),
        );
  }
}
