import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/daily_log.dart';
import '../entities/audit_entry.dart';
import '../../../../core/engine/hos_models.dart';

abstract class LogRepository {
  Future<Either<Failure, List<LogEvent>>> getEvents(DateTime date);
  Future<Either<Failure, bool>> addEvent(LogEvent event);
  Future<Either<Failure, bool>> updateEvent(LogEvent event);
  Future<Either<Failure, List<DutyPeriod>>> getPeriods(DateTime date);
  Future<Either<Failure, bool>> savePeriod(DutyPeriod period);
  Future<Either<Failure, bool>> logAudit(AuditEntry entry);
  Future<Either<Failure, List<AuditEntry>>> getAuditEntries(DateTime date);
}
