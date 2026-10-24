import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import '../adapters/eld_engine/models/certify_dto.dart';
import '../adapters/eld_engine/models/readiness_dto.dart';
import 'raw_json.dart';

abstract interface class DailyLogsBackend {
  /// GET /eld/daily-logs — unified spec: `page`/`size` + filters.
  /// Response envelope: `{ data: [...], pagination: {...} }`.
  // TODO(P2): replace with List<DailyLog>
  Future<Result<RawJson>> list({
    DriverId? driverId,
    int? deviceId,
    String? status,
    String? formStatus,
    String? certificationStatus,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? logDate,
    int page = 0,
    int size = 20,
  });

  /// GET /eld/daily-logs/summary — same filters as [list] + `page`/`size`;
  /// the unified envelope carries `pagination` (spec rule #2).
  // TODO(P2): replace with typed summary
  Future<Result<RawJson>> getSummary({
    DriverId? driverId,
    int? deviceId,
    String? status,
    String? formStatus,
    String? certificationStatus,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? logDate,
    int page = 0,
    int size = 20,
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
  Future<Result<CertifyResponseDto>> certify(
    CertifyRequestDto request, {
    int? expectedOwnerDriverId,
  });

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
    int? expectedOwnerDriverId,
  });

  /// GET /eld/daily-logs/{id}/events — `graphGrid` totals/segments +
  /// `events[]` (nested `timeRange`) + `applicableExceptions`.
  // TODO(P2): replace with typed graph grid
  Future<Result<RawJson>> getEvents(DailyLogId logId);

  /// GET /eld/daily-logs/{id}/events/{eventId} — one event with details.
  // TODO(P2): replace with DutyEventDto
  Future<Result<RawJson>> getEventDetails(
    DailyLogId logId,
    DutyStatusId eventId,
  );

  /// PUT /eld/daily-logs/{id}/events/{eventId} — edit one event
  /// (body: `status`, `startTime`, `notes`, `location{description}`).
  Future<Result<RawJson>> updateEvent({
    required DailyLogId logId,
    required DutyStatusId eventId,
    required RawJson event,
    int? expectedOwnerDriverId,
  });

  /// GET /eld/daily-logs/{id}/events/options — allowed statuses,
  /// special categories and edit window for that log.
  Future<Result<RawJson>> getEventsOptions(DailyLogId logId);

  /// GET /eld/daily-logs/{id}/form/options — selectable vehicles/co-drivers.
  Future<Result<RawJson>> getFormOptions(DailyLogId logId);

  /// POST /eld/daily-logs/{id}/lock
  Future<Result<void>> lock(DailyLogId logId);

  /// GET /eld/daily-logs/{id}/readiness
  Future<Result<ReadinessDto>> getReadiness(DailyLogId logId);

  /// GET /eld/daily-logs/{id}/certify — certification screen state:
  /// statement, signature presence, `canCertify`, `validationCodes`.
  Future<Result<CertifyStateDto>> getCertifyState(DailyLogId logId);
}
