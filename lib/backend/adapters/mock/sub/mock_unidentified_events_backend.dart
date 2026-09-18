import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/unidentified_events_backend.dart';

/// In-memory mock for [UnidentifiedEventsBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class MockUnidentifiedEventsBackend implements UnidentifiedEventsBackend {
  const MockUnidentifiedEventsBackend();

  @override
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    String? uniqueId,
    DriverId? driverId,
  }) =>
      throw UnimplementedError(
        'MockUnidentifiedEventsBackend.list — Phase 2',
      );

  @override
  Future<Result<void>> claim({
    required DutyStatusId id,
    required DriverId driverId,
    required String annotation,
  }) =>
      throw UnimplementedError('MockUnidentifiedEventsBackend.claim — Phase 2');

  @override
  Future<Result<void>> reject({
    required DutyStatusId id,
    required DriverId driverId,
    required String rejectionReason,
  }) =>
      throw UnimplementedError(
        'MockUnidentifiedEventsBackend.reject — Phase 2',
      );
}
