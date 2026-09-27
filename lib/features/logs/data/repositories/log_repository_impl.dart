import 'dart:async';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/network/core_providers.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../../backend/contracts/daily_logs_backend.dart';
import '../../../../backend/contracts/duty_status_backend.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../domain/repositories/log_repository.dart';
import '../datasources/log_local_data_source.dart';
import '../models/log_model.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/audit_entry.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_log_dto.dart';
import '../../../../backend/adapters/eld_engine/models/certify_dto.dart';
import '../../../../backend/adapters/eld_engine/models/readiness_dto.dart';
import '../../../../core/utils/repository_helper.dart';

class LogRepositoryImpl implements LogRepository {
  final LogLocalDataSource _localDataSource;
  final DailyLogsBackend _dailyLogsBackend;
  final DutyStatusBackend _dutyStatusBackend;
  final NetworkInfo _networkInfo;

  LogRepositoryImpl({
    required LogLocalDataSource localDataSource,
    required DailyLogsBackend dailyLogsBackend,
    required DutyStatusBackend dutyStatusBackend,
    required NetworkInfo networkInfo,
  })  : _localDataSource = localDataSource,
        _dailyLogsBackend = dailyLogsBackend,
        _dutyStatusBackend = dutyStatusBackend,
        _networkInfo = networkInfo;

  @override
  Future<Either<Failure, List<DailyLog>>> getDailyLogs({
    required int driverId,
    int limit = 50,
    int offset = 0,
  }) async {
    if (!_networkInfo.isConnected) {
      // SRS 6.8 — offline: serve the last server snapshot read-only
      // (first page only; nothing is invented and nothing is re-owned).
      if (offset == 0) {
        final cached = await _localDataSource.getCachedDailyLogs(driverId);
        if (cached != null) {
          return Right(_toDailyLogs(cached));
        }
      }
      return const Left(NetworkFailure());
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
            final logsJson = (data['data'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .toList();
            if (offset == 0) {
              // Fire-and-forget; a cache failure must not fail the read.
              _cacheQuietly(_localDataSource.cacheDailyLogs(driverId, logsJson));
            }
            return _toDailyLogs(logsJson);
          },
        );
      },
      tag: 'LogRepositoryImpl.getDailyLogs',
    );
  }

  /// Snapshot writes are best-effort: they never delay or fail a read.
  void _cacheQuietly(Future<void> write) =>
      unawaited(write.catchError((Object _) {}));

  List<DailyLog> _toDailyLogs(List<Map<String, dynamic>> logsJson) => logsJson
      .map((json) => DailyLogDto.fromJson(json).toEntity())
      .toList();

  @override
  Future<Either<Failure, List<LogEvent>>> getEvents(
      DailyLogId logId, DateTime date) async {
    if (_networkInfo.isConnected) {
      final result = await _dailyLogsBackend.getGraphGrid(logId);
      final remoteJson = result.fold(
        (_) => null,
        (data) => (data['events'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(),
      );
      // الخادم هو مصدر الحقيقة؛ المحلي احتياطي عند غياب الرد فقط.
      if (remoteJson != null) {
        _cacheQuietly(_localDataSource.cacheLogEvents(logId, remoteJson));
        return Right(remoteJson.map(LogEventModel.fromJson).toList());
      }
    }

    // SRS 6.8 — offline / no answer: last server snapshot for this day,
    // then any events recorded locally while disconnected.
    return executeWithHandling(
      () async {
        final cached = await _localDataSource.getCachedLogEvents(logId);
        final local = await _localDataSource.getEvents(date);
        if (cached == null) return local;
        final cachedIds = cached.map((e) => '${e['id']}').toSet();
        return [
          ...cached.map(LogEventModel.fromJson),
          ...local.where((e) => !cachedIds.contains(e.id)),
        ];
      },
      tag: 'LogRepositoryImpl.getEvents',
    );
  }

  @override
  Future<Either<Failure, bool>> addEvent(LogEvent event,
      {String? reason}) async {
    if (!_networkInfo.isConnected) {
      // SRS 6.8 — offline: keep it on the device, never lose it.
      return executeWithHandling(
        () => _localDataSource.addEvent(event),
        tag: 'LogRepositoryImpl.addEvent(offline)',
      );
    }
    final wire = DutyStatusCode.fromShortCode(event.status)?.wire ??
        DutyStatusCode.offDuty.wire;
    final result = await _dutyStatusBackend.record({
      'status': wire,
      'startTime': event.startTime.toUtc().toIso8601String(),
      if (event.location.isNotEmpty) 'locationText': event.location,
      if (reason != null && reason.trim().isNotEmpty) 'notes': reason.trim(),
      'origin': 'DRIVER',
    });
    return result.fold(
      (error) => Left(ServerFailure(message: error.l10nKey)),
      (_) => const Right(true),
    );
  }

  @override
  Future<Either<Failure, bool>> updateEvent(LogEvent event,
      {required String reason}) async {
    final statusId = int.tryParse(event.id);
    if (!_networkInfo.isConnected || statusId == null) {
      // Local-only event (never reached the server) or offline: local store.
      return executeWithHandling(
        () => _localDataSource.updateEvent(event),
        tag: 'LogRepositoryImpl.updateEvent(local)',
      );
    }
    final wire = DutyStatusCode.fromShortCode(event.status)?.wire ??
        DutyStatusCode.offDuty.wire;
    final result = await _dutyStatusBackend.update(
      statusId: DutyStatusId(statusId),
      update: {
        'status': wire,
        'startTime': event.startTime.toUtc().toIso8601String(),
        if (event.location.isNotEmpty) 'locationText': event.location,
        'editReason': reason.trim(),
      },
    );
    return result.fold(
      (error) => Left(ServerFailure(message: error.l10nKey)),
      (_) => const Right(true),
    );
  }

  @override
  Future<Either<Failure, ReadinessDto>> getReadiness(DailyLogId logId) async {
    if (!_networkInfo.isConnected) {
      return const Left(NetworkFailure());
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
      return const Left(NetworkFailure());
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
    dutyStatusBackend: ref.watch(dutyStatusBackendProvider),
    networkInfo: ref.watch(networkInfoProvider),
  );
});
