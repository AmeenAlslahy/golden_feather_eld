import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/daily_log.dart';
import '../../../../domain/shared/value_objects.dart';
import '../entities/audit_entry.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import '../../../../backend/adapters/eld_engine/models/readiness_dto.dart';

abstract class LogRepository {
  Future<Either<Failure, List<DailyLog>>> getDailyLogs({
    required int driverId,
    int limit = 50,
    int offset = 0,
  });
  Future<Either<Failure, List<LogEvent>>> getEvents(DateTime date);
  Future<Either<Failure, bool>> addEvent(LogEvent event);
  Future<Either<Failure, bool>> updateEvent(LogEvent event);
  Future<Either<Failure, ReadinessDto>> getReadiness(DailyLogId logId);
  Future<Either<Failure, bool>> certifyLog({
    required DailyLogId logId,
    required String signatureCertificateId,
    required bool signatureConfirmation,
    required bool certifiedTrue,
  });
  Future<Either<Failure, List<DutyPeriod>>> getPeriods(DateTime date);
  Future<Either<Failure, bool>> savePeriod(DutyPeriod period);
  Future<Either<Failure, bool>> logAudit(AuditEntry entry);
  Future<Either<Failure, List<AuditEntry>>> getAuditEntries(DateTime date);
}
