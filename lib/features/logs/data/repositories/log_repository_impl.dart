import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

import '../../../../backend/adapters/eld_engine/models/certify_dto.dart';
import '../../../../backend/adapters/eld_engine/models/readiness_dto.dart';
import '../../../../backend/contracts/daily_logs_backend.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/services/tracking_config_storage_service.dart';
import '../../../../core/utils/repository_helper.dart';
import '../../domain/entities/audit_entry.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/log_repository.dart';
import '../datasources/log_local_data_source.dart';
import '../models/daily_log_dto.dart';
import '../models/log_model.dart';

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
  Future<Either<Failure, List<DailyLog>>> getDailyLogs({
    required int driverId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!_networkInfo.isConnected) {
      return const Left(ServerFailure(message: 'No internet connection'));
    }

    return executeWithHandling(
      () async {
        final result = await _dailyLogsBackend.list(
          driverId: DriverId(driverId),
          limit: limit,
          offset: offset,
        );

        return result.match(
          (failure) => throw Exception(failure.l10nKey),
          (data) {
            final logsJson = data['data'] as List<dynamic>? ?? [];
            return logsJson
                .map((json) =>
                    DailyLogDto.fromJson(json as Map<String, dynamic>).toEntity())
                .toList();
          },
        );
      },
      tag: 'LogRepositoryImpl.getDailyLogs',
    );
  }

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
          // الخادم هو مصدر الحقيقة؛ المحلي احتياطي عند غياب الرد.
          return Right(remoteLogs.toList());
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
  Future<Either<Failure, ReadinessDto>> getReadiness(DailyLogId logId) async {
    if (!_networkInfo.isConnected) {
      return const Left(ServerFailure(message: 'No internet connection'));
    }
    return executeWithHandling(
      () async {
        final result = await _dailyLogsBackend.getReadiness(logId);
        return result.match(
          (failure) => throw Exception(failure.l10nKey),
          (data) => data,
        );
      },
      tag: 'LogRepositoryImpl.getReadiness',
    );
  }

  @override
  Future<Either<Failure, bool>> certifyLog({
    required DailyLogId logId,
    required int driverId,
    required String logDate,
    required String signatureCertificateId,
    required bool signatureConfirmation,
    required bool certifiedTrue,
  }) async {
    if (driverId <= 0) {
      return const Left(ServerFailure(message: 'Driver session is missing'));
    }
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(logDate)) {
      return const Left(ServerFailure(message: 'Log date must be YYYY-MM-DD'));
    }
    if (!_networkInfo.isConnected) {
      return const Left(ServerFailure(message: 'No internet connection'));
    }
    return executeWithHandling(
      () async {
        final result = await _dailyLogsBackend.certify(
          CertifyRequestDto(
            dailyLogId: logId.value,
            driverId: driverId,
            logDate: logDate,
            signatureCertificateId: signatureCertificateId,
            signatureConfirmation: signatureConfirmation,
            certifiedTrue: certifiedTrue,
          ),
        );
        return result.match(
          (failure) => throw Exception(failure.l10nKey),
          (data) => data.isCertified,
        );
      },
      tag: 'LogRepositoryImpl.certifyLog',
    );
  }

  @override
  Future<Either<Failure, bool>> respondToCarrierEdit({
    required DailyLogId logId,
    required String editId,
    required String action,
    String? driverNotes,
  }) {
    return executeWithHandling(
      () async {
        final result = await _dailyLogsBackend.respondToCarrierEdit(
          logId: logId,
          editId: EditId(editId),
          action: action,
          driverNotes: driverNotes,
        );
        return result.match(
          (failure) => throw Exception(failure.l10nKey),
          (_) => true,
        );
      },
      tag: 'LogRepositoryImpl.respondToCarrierEdit',
    );
  }

  @override
  Future<Either<Failure, bool>> reassignDriving({
    required DailyLogId logId,
    required int statusId,
    required int targetCoDriverId,
    required String annotation,
  }) {
    return executeWithHandling(
      () async {
        final result = await _dailyLogsBackend.reassignDriving(
          logId: logId,
          statusId: DutyStatusId(statusId),
          targetCoDriverId: DriverId(targetCoDriverId),
          annotation: annotation,
        );
        return result.match(
          (failure) => throw Exception(failure.l10nKey),
          (_) => true,
        );
      },
      tag: 'LogRepositoryImpl.reassignDriving',
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
