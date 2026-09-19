import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../backend/contracts/daily_logs_backend.dart';
import '../../../../core/services/tracking_config_storage_service.dart';
import '../../domain/repositories/log_repository.dart';
import '../datasources/log_local_data_source.dart';
import '../models/log_model.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/audit_entry.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/repository_helper.dart';

class LogRepositoryImpl implements LogRepository {
  final LogLocalDataSource _localDataSource;
  final DailyLogsBackend _dailyLogsBackend;
  final NetworkInfo _networkInfo;
  final TrackingConfigStorageService _storageService;

  LogRepositoryImpl({
    required LogLocalDataSource localDataSource,
    required DailyLogsBackend dailyLogsBackend,
    required NetworkInfo networkInfo,
    required TrackingConfigStorageService storageService,
  })  : _localDataSource = localDataSource,
        _dailyLogsBackend = dailyLogsBackend,
        _networkInfo = networkInfo,
        _storageService = storageService;

  @override
  Future<Either<Failure, List<LogEvent>>> getEvents(DateTime date) async {
    if (_networkInfo.isConnected) {
      try {
        final driverId = int.tryParse(_storageService.deviceId) ?? 100;
        final result = await _dailyLogsBackend.getLegacyDutyStatusLogs(driverId, date);
        
        final remoteLogs = result.fold(
          (error) => <LogEvent>[],
          (data) => data.map((json) => LogEventModel.fromJson(json as Map<String, dynamic>)).toList()
        );

        if (remoteLogs.isNotEmpty) {
          // In a real scenario, we would merge these or update the local DB
          // For now, we prefer remote if available and not empty
          return Right(remoteLogs.cast<LogEvent>().toList());
        }
      } catch (_) {
        // Fallback to local on any error
      }
    }

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
  return LogRepositoryImpl(
    localDataSource: ref.watch(logLocalDataSourceProvider),
    dailyLogsBackend: ref.watch(dailyLogsBackendProvider),
    networkInfo: ref.watch(networkInfoProvider),
    storageService: ref.watch(trackingConfigStorageProvider),
  );
});
