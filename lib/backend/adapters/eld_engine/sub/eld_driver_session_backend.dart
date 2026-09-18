// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/driver_session_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [DriverSessionBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldDriverSessionBackend implements DriverSessionBackend {
  final ApiClient _apiClient;

  const EldDriverSessionBackend(this._apiClient);

  @override
  Future<Result<RawJson>> getActiveSession(DriverId driverId) =>
      throw UnimplementedError('EldDriverSessionBackend.getActiveSession — Phase 2');

  @override
  Future<Result<RawJson>> getMembers(int sessionId) =>
      throw UnimplementedError('EldDriverSessionBackend.getMembers — Phase 2');

  @override
  Future<Result<RawJson>> connect({
    String? uniqueId,
    bool disconnected = false,
  }) =>
      throw UnimplementedError('EldDriverSessionBackend.connect — Phase 2');

  @override
  Future<Result<RawJson>> manageCoDriver({
    required CoDriverAction action,
    DriverId? coDriverId,
    DriverId? newCoDriverId,
    String? uniqueId,
    String? reason,
  }) =>
      throw UnimplementedError('EldDriverSessionBackend.manageCoDriver — Phase 2');

  @override
  Future<Result<void>> switchPrimaryDriver({
    required DutyStatusAction action,
    required DriverId coDriverId,
    String? reason,
  }) =>
      throw UnimplementedError('EldDriverSessionBackend.switchPrimaryDriver — Phase 2');
}
