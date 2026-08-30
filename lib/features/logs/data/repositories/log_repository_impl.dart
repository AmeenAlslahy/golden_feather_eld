import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/repositories/log_repository.dart';
import '../datasources/log_local_data_source.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/audit_entry.dart';
import '../../../../core/engine/hos_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/repository_helper.dart';

class LogRepositoryImpl implements LogRepository {
  final LogLocalDataSource _localDataSource;

  LogRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, List<LogEvent>>> getEvents(DateTime date) {
    return executeWithHandling(
      () => _localDataSource.getEvents(date),
      tag: 'LogRepositoryImpl.getEvents',
    );
  }

  @override
  Future<Either<Failure, bool>> addEvent(LogEvent event) {
    return executeWithHandling(
      () => _localDataSource.addEvent(event),
      tag: 'LogRepositoryImpl.addEvent',
    );
  }

  @override
  Future<Either<Failure, bool>> updateEvent(LogEvent event) {
    return executeWithHandling(
      () => _localDataSource.updateEvent(event),
      tag: 'LogRepositoryImpl.updateEvent',
    );
  }

  @override
  Future<Either<Failure, List<DutyPeriod>>> getPeriods(DateTime date) {
    return executeWithHandling(
      () => _localDataSource.getPeriods(date),
      tag: 'LogRepositoryImpl.getPeriods',
    );
  }

  @override
  Future<Either<Failure, bool>> savePeriod(DutyPeriod period) {
    return executeWithHandling(
      () => _localDataSource.savePeriod(period),
      tag: 'LogRepositoryImpl.savePeriod',
    );
  }

  @override
  Future<Either<Failure, bool>> logAudit(AuditEntry entry) {
    return executeWithHandling(
      () => _localDataSource.logAudit(entry),
      tag: 'LogRepositoryImpl.logAudit',
    );
  }

  @override
  Future<Either<Failure, List<AuditEntry>>> getAuditEntries(DateTime date) {
    return executeWithHandling(
      () => _localDataSource.getAuditEntries(date),
      tag: 'LogRepositoryImpl.getAuditEntries',
    );
  }
}

final logRepositoryProvider = Provider<LogRepository>((ref) {
  final localDataSource = ref.watch(logLocalDataSourceProvider);
  return LogRepositoryImpl(localDataSource);
});
