import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

import '../../../../backend/adapters/eld_engine/models/readiness_dto.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/error/failure.dart';
import '../entities/audit_entry.dart';
import '../entities/daily_log.dart';

abstract class LogRepository {
  // ==========================================================================
  // Daily Logs (Driver-facing)
  // ==========================================================================
  
  /// GET /eld/daily-logs — List daily logs
  Future<Either<Failure, List<DailyLog>>> getDailyLogs({
    required int driverId,
    int limit = 50,
    int offset = 0,
  });

  /// GET /eld/daily-logs/{id} — Get daily log details
  Future<Either<Failure, DailyLog>> getDailyLogById(DailyLogId logId);

  /// GET /eld/daily-logs/{id}/form — Get complete daily form
  Future<Either<Failure, Map<String, dynamic>>> getForm(DailyLogId logId);

  /// PUT /eld/daily-logs/{id}/form — Save unified daily form (Atomic)
  Future<Either<Failure, Map<String, dynamic>>> saveForm({
    required DailyLogId logId,
    required Map<String, dynamic> formData,
  });

  /// GET /eld/daily-logs/{id}/graph-grid — Get 24-hour graph grid
  Future<Either<Failure, Map<String, dynamic>>> getGraphGrid(DailyLogId logId);

  /// POST /eld/daily-logs/{id}/lock — Lock certified daily log
  Future<Either<Failure, bool>> lockLog(DailyLogId logId);

  // ==========================================================================
  // Certification (Driver-facing)
  // ==========================================================================

  /// GET /eld/daily-logs/{id}/readiness — Check certification readiness
  Future<Either<Failure, ReadinessDto>> getReadiness(DailyLogId logId);

  /// POST /eld/daily-logs/{id}/certify — Certify and sign daily log
  Future<Either<Failure, bool>> certifyLog({
    required DailyLogId logId,
    required String signatureCertificateId,
    required bool signatureConfirmation,
    required bool certifiedTrue,
  });

  // ==========================================================================
  // Duty Status Events (Driver-facing)
  // ==========================================================================

  Future<Either<Failure, List<LogEvent>>> getEvents(DateTime date);
  Future<Either<Failure, bool>> addEvent(LogEvent event);

  /// PUT /eld/duty-status/{statusId} — Edit manual duty status event
  Future<Either<Failure, bool>> updateEvent(LogEvent event);

  /// POST /eld/daily-logs/{id}/events/{statusId}/reassign-driving — Reassign driving time
  Future<Either<Failure, bool>> reassignDriving({
    required DailyLogId logId,
    required int statusId,
    required int targetCoDriverId,
    required String annotation,
  });

  // ==========================================================================
  // Carrier Edits (Driver response — driver-facing)
  // ==========================================================================

  /// POST /eld/daily-logs/{id}/carrier-edits/{editId}/respond — Accept/Reject carrier edit
  Future<Either<Failure, bool>> respondToCarrierEdit({
    required DailyLogId logId,
    required String editId,
    required String action, // 'accept' or 'reject'
    String? driverNotes,
  });

  // ==========================================================================
  // Legacy / Local (to be migrated)
  // ==========================================================================

  Future<Either<Failure, List<DutyPeriod>>> getPeriods(DateTime date);
  Future<Either<Failure, bool>> savePeriod(DutyPeriod period);
  Future<Either<Failure, bool>> logAudit(AuditEntry entry);
  Future<Either<Failure, List<AuditEntry>>> getAuditEntries(DateTime date);
}
