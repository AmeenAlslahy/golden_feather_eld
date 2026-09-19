import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import 'raw_json.dart';

abstract interface class DutyStatusBackend {
  /// POST /eld/duty-status
  // TODO(P2): replace with DutyStatus
  Future<Result<RawJson>> record(RawJson event);

  /// PUT /eld/duty-status/{statusId}
  // TODO(P2): replace with DutyStatus
  Future<Result<RawJson>> update({
    required DutyStatusId statusId,
    required RawJson update,
  });

  /// GET /eld/duty-status/{statusId}/edit-form
  // TODO(P2): replace with DutyStatusEditForm
  Future<Result<RawJson>> getEditForm(DutyStatusId statusId);

  /// GET /eld/duty-status/graph-grid
  // TODO(P2): replace with GraphGrid
  Future<Result<RawJson>> getGraphGrid({
    DriverId? driverId,
    required DateTime logDate,
  });

  // --- Legacy methods for P5.5 ---
  Future<Result<void>> submitLegacyDutyStatusEvent(
      int driverId, RawJson payload);
  Future<Result<void>> submitLegacyGenericEvent(RawJson payload);
}
