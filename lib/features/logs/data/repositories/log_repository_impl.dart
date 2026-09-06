import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/services/tracking_config_storage_service.dart';
import '../../domain/repositories/log_repository.dart';
import '../datasources/log_local_data_source.dart';
import '../datasources/log_remote_data_source.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/audit_entry.dart';
import '../../../../features/hos/domain/engine/hos_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/repository_helper.dart';

final logRemoteDataSourceProvider = Provider<LogRemoteDataSource>((ref) {
  return LogRemoteDataSourceImpl(
    ref.watch(apiClientProvider),
    ref.watch(endpointsProvider),
  );
});

class LogRepositoryImpl implements LogRepository {
  final LogLocalDataSource _localDataSource;
  final LogRemoteDataSource _remoteDataSource;
  final NetworkInfo _networkInfo;
  final TrackingConfigStorageService _storageService;

  LogRepositoryImpl({
    required LogLocalDataSource localDataSource,
    required LogRemoteDataSource remoteDataSource,
    required NetworkInfo networkInfo,
    required TrackingConfigStorageService storageService,
  })  : _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _networkInfo = networkInfo,
        _storageService = storageService;

  @override
  Future<Either<Failure, List<LogEvent>>> getEvents(DateTime date) async {
    if (_networkInfo.isConnected) {
      try {
        final driverId = int.tryParse(_storageService.deviceId) ?? 100;
        final remoteLogs = await _remoteDataSource.getDutyStatusLogs(driverId, date);
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
    remoteDataSource: ref.watch(logRemoteDataSourceProvider),
    networkInfo: ref.watch(networkInfoProvider),
    storageService: ref.watch(trackingConfigStorageProvider),
  );
});
