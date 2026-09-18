import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/driver_session_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [DriverSessionBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockDriverSessionBackend implements DriverSessionBackend {
  const MockDriverSessionBackend();

  @override
  Future<Result<RawJson>> getActiveSession(DriverId driverId) =>
      throw UnimplementedError(
        'MockDriverSessionBackend.getActiveSession — Phase 2',
      );

  @override
  Future<Result<RawJson>> getMembers(int sessionId) =>
      throw UnimplementedError('MockDriverSessionBackend.getMembers — Phase 2');

  @override
  Future<Result<RawJson>> connect({
    String? uniqueId,
    bool disconnected = false,
  }) =>
      throw UnimplementedError('MockDriverSessionBackend.connect — Phase 2');

  @override
  Future<Result<RawJson>> manageCoDriver({
    required CoDriverAction action,
    DriverId? coDriverId,
    DriverId? newCoDriverId,
    String? uniqueId,
    String? reason,
  }) =>
      throw UnimplementedError(
        'MockDriverSessionBackend.manageCoDriver — Phase 2',
      );

  @override
  Future<Result<void>> switchPrimaryDriver({
    required DutyStatusAction action,
    required DriverId coDriverId,
    String? reason,
  }) =>
      throw UnimplementedError(
        'MockDriverSessionBackend.switchPrimaryDriver — Phase 2',
      );
}
