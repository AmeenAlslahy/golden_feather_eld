import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/duty_status_backend.dart';
import '../../../contracts/raw_json.dart';

/// In-memory mock for [DutyStatusBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockDutyStatusBackend implements DutyStatusBackend {
  const MockDutyStatusBackend();

  @override
  Future<Result<RawJson>> record(RawJson event) async =>
      ok(<String, dynamic>{'id': DateTime.now().millisecondsSinceEpoch, ...event});

  @override
  Future<Result<RawJson>> update({
    required DutyStatusId statusId,
    required RawJson update,
  }) async =>
      ok(<String, dynamic>{'id': statusId.value, ...update});

  @override
  Future<Result<RawJson>> getGraphGrid({
    DriverId? driverId,
    required DateTime logDate,
  }) =>
      throw UnimplementedError('MockDutyStatusBackend.getGraphGrid — Phase 2');

  @override
  Future<Result<void>> submitLegacyDutyStatusEvent(
      int driverId, RawJson payload) async {
    return ok(null);
  }

  @override
  Future<Result<void>> submitLegacyGenericEvent(RawJson payload) async {
    return ok(null);
  }
}
