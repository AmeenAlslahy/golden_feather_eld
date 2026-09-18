// ignore_for_file: unused_field, unused_import

import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/duty_status_backend.dart';
import '../../../contracts/raw_json.dart';
import '../../../http/api_client.dart';

/// ELD Engine implementation of [DutyStatusBackend].
/// **Status:** Skeleton — implemented in Phase 2.
class EldDutyStatusBackend implements DutyStatusBackend {
  final ApiClient _apiClient;

  const EldDutyStatusBackend(this._apiClient);

  @override
  Future<Result<RawJson>> record(RawJson event) =>
      throw UnimplementedError('EldDutyStatusBackend.record — Phase 2');

  @override
  Future<Result<RawJson>> update({
    required DutyStatusId statusId,
    required RawJson update,
  }) =>
      throw UnimplementedError('EldDutyStatusBackend.update — Phase 2');

  @override
  Future<Result<RawJson>> getEditForm(DutyStatusId statusId) =>
      throw UnimplementedError('EldDutyStatusBackend.getEditForm — Phase 2');

  @override
  Future<Result<RawJson>> getGraphGrid({
    DriverId? driverId,
    required DateTime logDate,
  }) =>
      throw UnimplementedError('EldDutyStatusBackend.getGraphGrid — Phase 2');
}
