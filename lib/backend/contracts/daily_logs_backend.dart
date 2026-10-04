import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import '../adapters/eld_engine/models/certify_dto.dart';
import '../adapters/eld_engine/models/readiness_dto.dart';
import 'raw_json.dart';

abstract interface class DailyLogsBackend {
  /// GET /eld/daily-logs
  // TODO(P2): replace with List<DailyLog>
  Future<Result<RawJson>> list({
    DriverId? driverId,
    DateTime? startDate,
    DateTime? endDate,
    String? status,
    String? certificationStatus,
    int? ruleId,
    bool? requiresAction,
    int limit = 50,
    int offset = 0,
  });

  /// GET /eld/daily-logs/{id}
  // TODO(P2): replace with DailyLog
  Future<Result<RawJson>> getById(DailyLogId logId);

  /// GET /eld/daily-logs/{id}/team — team status + HOS isolation (§5.8).
  Future<Result<RawJson>> getTeamStatus(DailyLogId logId);

  /// POST /eld/daily-logs/{id}/carrier-edits/{editId}/respond
  Future<Result<void>> respondToCarrierEdit({
    required DailyLogId logId,
    required EditId editId,
    required String action,
    String? driverNotes,
  });

  /// POST /eld/daily-logs/{id}/certify
  Future<Result<CertifyResponseDto>> certify(CertifyRequestDto request);

  /// POST /eld/daily-logs/{id}/events/{statusId}/reassign-driving
  Future<Result<void>> reassignDriving({
    required DailyLogId logId,
    required DutyStatusId statusId,
    required DriverId targetCoDriverId,
    required String annotation,
  });

  /// GET /eld/daily-logs/{id}/form
  // TODO(P2): replace with DailyForm
  Future<Result<RawJson>> getForm(DailyLogId logId);

  /// PUT /eld/daily-logs/{id}/form
  // TODO(P2): replace with DailyForm
  Future<Result<RawJson>> saveForm({
    required DailyLogId logId,
    required RawJson form,
  });

  /// GET /eld/daily-logs/{id}/graph-grid
  // TODO(P2): replace with GraphGrid
  Future<Result<RawJson>> getGraphGrid(DailyLogId logId);

  /// POST /eld/daily-logs/{id}/lock
  Future<Result<void>> lock(DailyLogId logId);

  /// GET /eld/daily-logs/{id}/readiness
  Future<Result<ReadinessDto>> getReadiness(DailyLogId logId);
}
