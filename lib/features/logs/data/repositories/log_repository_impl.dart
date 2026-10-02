import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../../../features/sync/domain/entities/pending_event.dart';
import '../../../../features/sync/domain/repositories/offline_queue.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/exception.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/network/network_info.dart';
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
import '../models/daily_log_dto.dart';
import '../../../../backend/adapters/eld_engine/models/certify_dto.dart';
import '../../domain/entities/log_readiness.dart';
import '../../domain/saved_form_status.dart';
import '../../domain/entities/daily_form_data.dart';
import '../../domain/entities/daily_form_update.dart';

// جسر توافق (المرحلة 3b): تعريف logRepositoryProvider انتقل إلى
// data/providers/log_repository_providers.dart — التصدير هنا يبقي
// الاختبارات القائمة التي تستورد هذا الملف تعمل.
export '../providers/log_repository_providers.dart';
import '../../../../core/utils/repository_helper.dart';

class LogRepositoryImpl implements LogRepository {
  final LogLocalDataSource _localDataSource;
  final DailyLogsBackend _dailyLogsBackend;
  final DutyStatusBackend _dutyStatusBackend;
  final NetworkInfo _networkInfo;
  final OfflineQueue _offlineQueue;
  final Uuid _uuid;

  LogRepositoryImpl({
    required LogLocalDataSource localDataSource,
    required DailyLogsBackend dailyLogsBackend,
    required DutyStatusBackend dutyStatusBackend,
    required NetworkInfo networkInfo,
    required OfflineQueue offlineQueue,
  }) : _localDataSource = localDataSource,
       _dailyLogsBackend = dailyLogsBackend,
       _dutyStatusBackend = dutyStatusBackend,
       _networkInfo = networkInfo,
       _offlineQueue = offlineQueue,
       _uuid = const Uuid();

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

    return executeWithHandling(() async {
      final result = await _dailyLogsBackend.list(
        driverId: DriverId(driverId),
        limit: limit,
        offset: offset,
      );

      return result.match((failure) => throw Exception(failure.l10nKey), (
        data,
      ) {
        final logsJson = (data['data'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList();
        if (offset == 0) {
          // Fire-and-forget; a cache failure must not fail the read.
          _cacheQuietly(_localDataSource.cacheDailyLogs(driverId, logsJson));
        }
        return _toDailyLogs(logsJson);
      });
    }, tag: 'LogRepositoryImpl.getDailyLogs');
  }

  /// Snapshot writes are best-effort: they never delay or fail a read.
  void _cacheQuietly(Future<void> write) =>
      unawaited(write.catchError((Object _) {}));

  List<DailyLog> _toDailyLogs(List<Map<String, dynamic>> logsJson) =>
      logsJson.map((json) => DailyLogDto.fromJson(json).toEntity()).toList();

  @override
  Future<Either<Failure, List<LogEvent>>> getEvents(
    DailyLogId logId,
    DateTime date,
  ) async {
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
    return executeWithHandling(() async {
      final cached = await _localDataSource.getCachedLogEvents(logId);
      final local = await _localDataSource.getEvents(date);
      if (cached == null) return local;
      final cachedIds = cached.map((e) => '${e['id']}').toSet();
      return [
        ...cached.map(LogEventModel.fromJson),
        ...local.where((e) => !cachedIds.contains(e.id)),
      ];
    }, tag: 'LogRepositoryImpl.getEvents');
  }

  @override
  Future<Either<Failure, bool>> addEvent(
    LogEvent event, {
    String? reason,
  }) async {
    if (!_networkInfo.isConnected) {
      // SRS 6.8 — offline: keep it on the device, never lose it.
      return executeWithHandling(
        () => _localDataSource.addEvent(event),
        tag: 'LogRepositoryImpl.addEvent(offline)',
      );
    }
    final wire =
        DutyStatusCode.fromShortCode(event.status)?.wire ??
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
  Future<Either<Failure, LogEvent?>> updateEvent(
    LogEvent event, {
    required String reason,
  }) async {
    final statusId = int.tryParse(event.id);
    if (!_networkInfo.isConnected || statusId == null) {
      // Local-only event (never reached the server) or offline: local store.
      final localResult = await executeWithHandling(
        () => _localDataSource.updateEvent(event),
        tag: 'LogRepositoryImpl.updateEvent(local)',
      );
      return localResult.fold((failure) => Left(failure), (_) => Right(event));
    }
    final wire =
        DutyStatusCode.fromShortCode(event.status)?.wire ??
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
    return result.fold((error) => Left(ServerFailure(message: error.l10nKey)), (
      raw,
    ) {
      // العقد: 200 يعيد DutyEventDto المعدّل — نعتمده مرجعاً للواجهة
      // بدل إعادة الجلب عبر graph-grid (كان يرمي الاستجابة فيرتد
      // التعديل عند أي تأخير/فشل في الجلب التالي).
      try {
        final confirmed = LogEventModel.fromJson(raw);
        return Right(confirmed);
      } catch (_) {
        return const Right(null);
      }
    });
  }

  Map<String, dynamic> _mapFormUpdateToJson(DailyFormUpdate form) {
    return {
      'uniqueId': form.vehicleUniqueId,
      'coDriverId': form.coDriverId,
      'trailers': form.trailers.map((t) => {'trailerNumber': t}).toList(),
      'shippingDocuments': form.shippingDocuments
          .map((d) => {'documentNumber': d})
          .toList(),
    };
  }

  @override
  Future<Either<Failure, DailyFormData?>> getForm(DailyLogId logId) async {
    if (!_networkInfo.isConnected) {
      // Phase 1: offline fetch not implemented yet
      return const Left(NetworkFailure());
    }

    return executeWithHandling(() async {
      final response = await _dailyLogsBackend.getForm(logId);
      return response.fold((error) => throw ServerException(message: error.code), (json) {
        final data = json['data'] is Map
            ? Map<String, dynamic>.from(json['data'] as Map)
            : json;
        if (data.isEmpty) return null;

        final trailersList = (data['trailers'] as List<dynamic>? ?? [])
            .map((e) => e is Map ? e['trailerNumber']?.toString() ?? '' : '')
            .where((e) => e.isNotEmpty)
            .toList();

        final docsList = (data['shippingDocuments'] as List<dynamic>? ?? [])
            .map((e) => e is Map ? e['documentNumber']?.toString() ?? '' : '')
            .where((e) => e.isNotEmpty)
            .toList();

        return DailyFormData(
          vehicleUniqueId: data['uniqueId']?.toString(),
          coDriverId: data['coDriverId'] as int?,
          trailers: trailersList,
          shippingDocuments: docsList,
        );
      });
    }, tag: 'LogRepositoryImpl.getForm');
  }

  @override
  Future<Either<Failure, FormSaveResult>> saveForm({
    required DailyLogId logId,
    required DailyFormUpdate form,
  }) async {
    final payload = _mapFormUpdateToJson(form);

    if (!_networkInfo.isConnected) {
      await _offlineQueue.enqueue(
        PendingEvent(
          id: _uuid.v4(),
          type: 'daily_log_form',
          payload: {'logId': logId.value, 'form': payload},
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return const Right(FormSaveResult.offline());
    }

    return executeWithHandling(() async {
      final response = await _dailyLogsBackend.saveForm(
        logId: logId,
        form: payload,
      );

      return response.fold((error) => throw Exception(error.code), (json) {
        final read = readSavedForm(json);
        return FormSaveResult.online(read);
      });
    }, tag: 'LogRepositoryImpl.saveForm');
  }

  @override
  Future<Either<Failure, LogReadiness>> getReadiness(DailyLogId logId) async {
    if (!_networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    return executeWithHandling(() async {
      final result = await _dailyLogsBackend.getReadiness(logId);
      return result.match((failure) => throw Exception(failure.l10nKey), (
        data,
      ) {
        return LogReadiness(
          dailyLogId: data.dailyLogId,
          driverId: data.driverId,
          driverName: data.driverName,
          logDate: data.logDate,
          readinessStatus: data.readinessStatus,
          missingRequirements: data.missingRequirements,
          legalStatement: data.legalStatement,
          availableActions: data.availableActions,
          carrierProposedEditsPending: data.carrierProposedEditsPending,
          pendingCarrierEdits: data.pendingCarrierEdits
              .map(
                (e) => CarrierProposedEditEntity(
                  id: e.id,
                  carrierName: e.carrierName,
                  carrierReason: e.carrierReason,
                  proposedStatus: e.proposedStatus,
                  previousValuesSummary: e.previousValuesSummary,
                  newValuesSummary: e.newValuesSummary,
                ),
              )
              .toList(),
        );
      });
    }, tag: 'LogRepositoryImpl.getReadiness');
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
      // SRS 6.8 — offline: enqueue for sync, never lose the driver's certification.
      await _offlineQueue.enqueue(
        PendingEvent(
          id: _uuid.v4(),
          type: 'certification',
          payload: {
            'logId': logId.value,
            'logDate': logDate,
            'signatureCertificateId': signatureCertificateId,
            'signatureConfirmation': signatureConfirmation,
            'certifiedTrue': certifiedTrue,
          },
          createdAt: DateTime.now().toUtc(),
        ),
      );
      return const Right(true);
    }
    return executeWithHandling(() async {
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
    }, tag: 'LogRepositoryImpl.certifyLog');
  }

  @override
  Future<Either<Failure, bool>> respondToCarrierEdit({
    required DailyLogId logId,
    required String editId,
    required String action,
    String? driverNotes,
  }) {
    return executeWithHandling(() async {
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
    }, tag: 'LogRepositoryImpl.respondToCarrierEdit');
  }

  @override
  Future<Either<Failure, bool>> reassignDriving({
    required DailyLogId logId,
    required int statusId,
    required int targetCoDriverId,
    required String annotation,
  }) {
    return executeWithHandling(() async {
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
    }, tag: 'LogRepositoryImpl.reassignDriving');
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

  @override
  Future<Either<Failure, List<AuditEntry>>> getRecentAuditEntries({
    int limit = 100,
  }) {
    return executeWithHandling(
      () => _localDataSource.getRecentAuditEntries(limit: limit),
      tag: 'LogRepositoryImpl.getRecentAuditEntries',
    );
  }
}
