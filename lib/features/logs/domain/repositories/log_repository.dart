import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/daily_log.dart';
import '../../../../domain/shared/value_objects.dart';
import '../entities/audit_entry.dart';
import '../saved_form_status.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import '../entities/log_readiness.dart';
import '../entities/daily_form_data.dart';
import '../entities/daily_form_update.dart';

abstract class LogRepository {
  Future<Either<Failure, List<DailyLog>>> getDailyLogs({
    required int driverId,
    int limit = 50,
    int offset = 0,
  });

  /// Reads the saved daily log form snapshot from the backend.
  /// Returns null if the form is empty or doesn't exist on the server.
  Future<Either<Failure, DailyFormData?>> getForm(DailyLogId logId);

  /// Saves the daily log form. If offline, the form is queued and will be
  /// dispatched later when connectivity is restored.
  Future<Either<Failure, FormSaveResult>> saveForm({
    required DailyLogId logId,
    required DailyFormUpdate form,
  });

  /// Duty-status events of one daily log.
  ///
  /// Online: the official `GET /eld/daily-logs/{id}/graph-grid` (server is the
  /// source of truth). Offline / on failure: the locally recorded events of
  /// [date] so the driver still sees what was captured on the device.
  Future<Either<Failure, List<LogEvent>>> getEvents(
    DailyLogId logId,
    DateTime date,
  );

  /// Records a new manual duty-status event (`POST /eld/duty-status`).
  /// Falls back to the local store when offline so nothing is lost (SRS 6.8).
  Future<Either<Failure, bool>> addEvent(LogEvent event, {String? reason});

  /// Edits an existing manual event (`PUT /eld/duty-status/{statusId}`,
  /// `editReason` mandatory). Server-rejected edits (automatic driving) are
  /// surfaced as a failure, never silently kept locally.
  /// تعديل حدث: يعيد الحدث **كما أكده الخادم** (DutyEventDto من عقد
  /// PUT /eld/duty-status/{id})، أو null إذا لم يُعِد الخادم جسماً
  /// (أحداث محلية/أوفلاين — حُفظت محلياً).
  Future<Either<Failure, LogEvent?>> updateEvent(
    LogEvent event, {
    required String reason,
  });
  Future<Either<Failure, LogReadiness>> getReadiness(DailyLogId logId);
  Future<Either<Failure, bool>> respondToCarrierEdit({
    required DailyLogId logId,
    required String editId,
    required String action,
    String? driverNotes,
  });
  Future<Either<Failure, bool>> reassignDriving({
    required DailyLogId logId,
    required int statusId,
    required int targetCoDriverId,
    required String annotation,
  });
  Future<Either<Failure, bool>> certifyLog({
    required DailyLogId logId,
    required int driverId,
    required String logDate,
    required String signatureCertificateId,
    required bool signatureConfirmation,
    required bool certifiedTrue,
  });
  Future<Either<Failure, List<DutyPeriod>>> getPeriods(DateTime date);
  Future<Either<Failure, bool>> savePeriod(DutyPeriod period);
  Future<Either<Failure, bool>> logAudit(AuditEntry entry);
  Future<Either<Failure, List<AuditEntry>>> getAuditEntries(DateTime date);

  /// SRS 7.16: أحدث الأحداث للعرض في شاشة سجل التدقيق (قراءة فقط).
  Future<Either<Failure, List<AuditEntry>>> getRecentAuditEntries({
    int limit = 100,
  });
}
