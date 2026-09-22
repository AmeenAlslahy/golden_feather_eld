// ignore_for_file: unused_field, unused_import

import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/result/result.dart';
import '../../../contracts/contract_enums.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/unidentified_events_backend.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [UnidentifiedEventsBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldUnidentifiedEventsBackend implements UnidentifiedEventsBackend {
  final ApiClient _apiClient;

  const EldUnidentifiedEventsBackend(this._apiClient);

  @override
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    String? uniqueId,
    DriverId? driverId,
  }) =>
      throw UnimplementedError('EldUnidentifiedEventsBackend.list — Phase 2');

  @override
  Future<Result<void>> claim({
    required DutyStatusId id,
    required DriverId driverId,
    required String annotation,
  }) =>
      throw UnimplementedError('EldUnidentifiedEventsBackend.claim — Phase 2');

  @override
  Future<Result<void>> reject({
    required DutyStatusId id,
    required DriverId driverId,
    required String rejectionReason,
  }) =>
      throw UnimplementedError('EldUnidentifiedEventsBackend.reject — Phase 2');
}
