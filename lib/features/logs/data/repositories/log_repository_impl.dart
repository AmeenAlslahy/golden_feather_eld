import 'dart:async';
import 'package:intl/intl.dart';
import '../../../../core/utils/id_generator.dart';
import '../../../../features/sync/domain/entities/pending_event.dart';
import '../../../../features/sync/domain/repositories/offline_queue.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/exception.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/time/time_authority.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/network/network_info.dart';

import '../../../../backend/contracts/daily_logs_backend.dart';
import '../../../../backend/contracts/duty_status_backend.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../domain/repositories/log_repository.dart';
import '../datasources/log_local_data_source.dart';
import '../models/log_model.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/entities/daily_log_page.dart';
import '../../domain/entities/audit_entry.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import '../models/daily_log_dto.dart';
import '../models/saved_form_dto.dart';
import '../../../../backend/adapters/eld_engine/models/certify_dto.dart';
import '../../domain/entities/log_readiness.dart';
import '../../domain/entities/log_certify_state.dart';
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
  final TimeAuthority _timeAuthority;
  final IdGenerator _idGenerator;

  LogRepositoryImpl({
    required LogLocalDataSource localDataSource,
    required DailyLogsBackend dailyLogsBackend,
    required DutyStatusBackend dutyStatusBackend,
    required NetworkInfo networkInfo,
    required OfflineQueue offlineQueue,
    required TimeAuthority timeAuthority,
    required IdGenerator idGenerator,
  }) : _localDataSource = localDataSource,
       _dailyLogsBackend = dailyLogsBackend,
       _dutyStatusBackend = dutyStatusBackend,
       _networkInfo = networkInfo,
       _offlineQueue = offlineQueue,
       _timeAuthority = timeAuthority,
       _idGenerator = idGenerator;

  @override
  Future<Either<Failure, DailyLogPage>> getDailyLogs({
    required int driverId,
    int page = 0,
    int size = 20,
  }) async {
    if (!_networkInfo.isConnected) {
      // SRS 6.8 — offline: serve the last server snapshot read-only
      // (first page only; nothing is invented and nothing is re-owned).
      if (page == 0) {
        final cached = await _localDataSource.getCachedDailyLogs(driverId);
        if (cached != null) {
          return Right(DailyLogPage(logs: _toDailyLogs(cached)));
        }
      }
      return const Left(NetworkFailure());
    }

    return executeWithHandling(() async {
      final result = await _dailyLogsBackend.list(
        driverId: DriverId(driverId),
        page: page,
        size: size,
      );

      return result.match(
        (failure) => throw ServerException(message: failure.l10nKey),
        (data) {
          final logsJson = (data['data'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .toList();
          if (page == 0) {
            // Fire-and-forget; a cache failure must not fail the read.
            _cacheQuietly(_localDataSource.cacheDailyLogs(driverId, logsJson));
          }
          final pagination = data['pagination'] is Map
              ? Map<String, dynamic>.from(data['pagination'] as Map)
              : const <String, dynamic>{};
          return DailyLogPage(
            logs: _toDailyLogs(logsJson),
            page: page,
            // خادم بلا `pagination` (عقد أقدم): اكتمال الصفحة = لا مزيد.
            hasNext: pagination.isEmpty
                ? logsJson.length >= size
                : pagination['hasNext'] == true,
            totalElements: pagination['totalElements'] is int
                ? pagination['totalElements'] as int
                : null,
            totalPages: pagination['totalPages'] is int
                ? pagination['totalPages'] as int
                : null,
          );
        },
      );
    }, tag: 'LogRepositoryImpl.getDailyLogs');
  }

  /// Snapshot writes are best-effort: they never delay or fail a read.
  void _cacheQuietly(Future<void> write) =>
      unawaited(write.catchError((Object _) {}));

  List<DailyLog> _toDailyLogs(List<Map<String, dynamic>> logsJson) =>
      logsJson.map((json) => DailyLogDto.fromJson(json).toEntity()).toList();

  @override
  Future<Either<Failure, DailyLog>> getLogById(DailyLogId logId) async {
    if (!_networkInfo.isConnected) {
      final owner = await _localDataSource.ownerOfCachedLog(logId.value);
      if (owner != null) {
        final cached = await _localDataSource.getCachedDailyLogs(owner);
        if (cached != null) {
          final found = cached
              .where(
                (m) =>
                    m['id'] == logId.value ||
                    m['id']?.toString() == logId.value.toString(),
              )
              .toList();
          if (found.isNotEmpty) {
            return Right(DailyLogDto.fromJson(found.first).toEntity());
          }
        }
      }
      return const Left(NetworkFailure());
    }
    return executeWithHandling(() async {
      final result = await _dailyLogsBackend.getById(logId);
      return result.match(
        (failure) => throw ServerException(message: failure.l10nKey),
        (data) => DailyLogDto.fromJson(data).toEntity(),
      );
    }, tag: 'LogRepositoryImpl.getLogById');
  }

  @override
  Future<Either<Failure, List<LogEvent>>> getEvents(
    DailyLogId logId,
    DateTime date,
  ) async {
    if (_networkInfo.isConnected) {
      // العقد الموحّد: GET /eld/daily-logs/{id}/events (events[] + graphGrid).
      final result = await _dailyLogsBackend.getEvents(logId);
      final remoteJson = result.fold(
        (_) => null,
        (data) => (data['events'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .toList(),
      );
      // الخادم هو مصدر الحقيقة؛ المحلي احتياطي عند غياب الرد فقط.
      if (remoteJson != null) {
        _cacheQuietly(_localDataSource.cacheLogEvents(logId, remoteJson));
        return Right(LogEventModel.parseList(remoteJson, source: 'events'));
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
        ...LogEventModel.parseList(cached, source: 'events cache'),
        ...local.where((e) => !cachedIds.contains(e.id)),
      ];
    }, tag: 'LogRepositoryImpl.getEvents');
  }

  @override
  Future<Either<Failure, bool>> addEvent(
    LogEvent event, {
    String? reason,
    int? ownerDriverId,
  }) async {
    final wire =
        DutyStatusCode.fromShortCode(event.status)?.wire ??
        DutyStatusCode.offDuty.wire;

    if (!_networkInfo.isConnected) {
      // SRS 6.8 — offline: keep it on the device, never lose it.
      final localResult = await executeWithHandling(
        () => _localDataSource.addEvent(event),
        tag: 'LogRepositoryImpl.addEvent(offline)',
      );
      if (localResult.isLeft()) return localResult;

      await _offlineQueue.enqueue(
        PendingEvent(
          id: _idGenerator.v4(),
          type: 'duty_status',
          payload: {
            'status': wire,
            'startTime': event.startTime.toUtc().toIso8601String(),
            if (event.location.isNotEmpty) 'locationText': event.location,
            if (reason != null && reason.trim().isNotEmpty)
              'notes': reason.trim(),
            'origin': 'MANUAL',
            'clientId': event.id,
            if (ownerDriverId != null) 'driverId': ownerDriverId,
            if (ownerDriverId != null) 'ownerDriverId': ownerDriverId,
          },
          createdAt: _timeAuthority.nowUtc(),
        ),
      );
      return const Right(true);
    }
    final result = await _dutyStatusBackend.record({
      'status': wire,
      'startTime': event.startTime.toUtc().toIso8601String(),
      if (event.location.isNotEmpty) 'locationText': event.location,
      if (reason != null && reason.trim().isNotEmpty) 'notes': reason.trim(),
      'origin': 'MANUAL',
      'clientId': event.id,
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
    DailyLogId? logId,
    int? ownerDriverId,
  }) async {
    final statusId = int.tryParse(event.id);

    final wire =
        DutyStatusCode.fromShortCode(event.status)?.wire ??
        DutyStatusCode.offDuty.wire;

    final base = {
      'status': wire,
      'startTime': event.startTime.toUtc().toIso8601String(),
      if (event.location.isNotEmpty) 'locationText': event.location,
    };

    // If offline, always go local and enqueue for background sync.
    if (!_networkInfo.isConnected) {
      final localResult = await executeWithHandling(
        () => _localDataSource.updateEvent(event),
        tag: 'LogRepositoryImpl.updateEvent(local)',
      );
      if (localResult.isLeft()) {
        return localResult.fold(
          (failure) => Left(failure),
          (_) => Right(event),
        );
      }

      await _offlineQueue.enqueue(
        PendingEvent(
          id: _idGenerator.v4(),
          type: 'duty_status',
          payload: {
            ...base,
            if (statusId != null) 'statusId': statusId,
            if (logId != null) 'logId': logId.value,
            'notes': reason.trim(),
            'origin': 'MANUAL',
            'clientId': event.id,
            if (ownerDriverId != null) 'driverId': ownerDriverId,
            if (ownerDriverId != null) 'ownerDriverId': ownerDriverId,
          },
          createdAt: _timeAuthority.nowUtc(),
        ),
      );
      return Right(event);
    }

    // Local UUIDs are created through POST /eld/duty-status.
    // Persisted events use PUT /eld/duty-status/{id}; the unified
    // PUT /eld/daily-logs/{logId}/events/{eventId} returned 404 on the live API.
    // Keep the failing call commented until that route is available:
    // final unifiedResult = await _dailyLogsBackend.updateEvent(...);
    // Correct path: this endpoint requires `editReason` and accepts
    // `locationText` (already included in `base`).
    final result = statusId == null
        ? await _dutyStatusBackend.record({
            ...base,
            'notes': reason.trim(),
            'origin': 'MANUAL',
            'clientId': event.id,
          })
        : await _dutyStatusBackend.update(
            statusId: DutyStatusId(statusId),
            update: {...base, 'editReason': reason.trim()},
          );

    return result.fold((error) => Left(ServerFailure(message: error.l10nKey)), (
      raw,
    ) {
      // العقد: 200 يعيد الحدث المعدّل — نعتمده مرجعاً للواجهة
      // بدل إعادة الجلب عبر /events (كان يرمي الاستجابة فيرتد
      // التعديل عند أي تأخير/فشل في الجلب التالي).
      try {
        final payload = raw['event'] is Map
            ? Map<String, dynamic>.from(raw['event'] as Map)
            : raw;
        final confirmed = LogEventModel.fromJson(payload);
        return Right(confirmed);
      } catch (e, st) {
        // الخادم طبّق التعديل فعلاً (200) — لا نحوّلها لفشل كاذب، لكن انحراف
        // العقد (echo غير قابل للتحليل) يجب أن يبقى مرئياً في السجلات.
        AppLogger.error(
          'LogRepositoryImpl.updateEvent: 200 body was not a parseable '
          'event DTO — UI keeps optimistic state without confirmation',
          e,
          st,
        );
        return const Right(null);
      }
    });
  }

  /// جسم تعديل الحدث وفق الوثيقة: `status` + `specialCategory` + `notes`
  /// (السبب الإلزامي) + `location`. نضيف `startTime` لأن التطبيق يتيح
  /// تعديل وقت البدء (`editRestrictions` في الوثيقة تحدّد نافذته)،
  /// و`location.description` هو الشكل المتاح محلياً (المحرر لا يجمع
  /// إحداثيات). `vehicleId` غير متاح في مسار التعديل الحالي.
  /// جسم PUT /eld/daily-logs/{id}/form وفق مواصفة الخادم الحالية:
  /// `uniqueId` (نصي) + `coDriverId` + `trailers` + `shippingDocuments`
  /// + `notes`. لا يُشتق معرّف رقمي من نص `uniqueId` (كان يُنتج معرّفاً
  /// غير موجود)، و`vehicleId` الرقمي مرفوض دائماً من الخادم فلا يُرسل
  /// إطلاقاً — [saveForm] يمنع أي حفظ بلا `uniqueId` قبل الوصول إلى هنا.
  Map<String, dynamic> _mapFormUpdateToJson(DailyFormUpdate form) {
    return {
      'uniqueId': form.vehicleUniqueId.trim(),
      'coDriverId': form.coDriverId,
      'trailers': form.trailers.map((t) => {'trailerNumber': t}).toList(),
      'shippingDocuments': form.shippingDocuments
          .map((d) => {'documentNumber': d})
          .toList(),
      if (form.notes != null && form.notes!.trim().isNotEmpty)
        'notes': form.notes!.trim(),
    };
  }

  @override
  Future<Either<Failure, DailyFormData?>> getForm(DailyLogId logId) async {
    if (!_networkInfo.isConnected) {
      final cached = await _localDataSource.getCachedDailyForm(logId);
      if (cached != null) {
        return Right(_parseDailyFormData(cached));
      }
      return const Right(null);
    }

    return executeWithHandling(() async {
      final response = await _dailyLogsBackend.getForm(logId);
      return response.fold(
        (error) => throw ServerException(
          message: error.code,
          // 🔴 لا تُرمى رسالة الخادم: هي تفسير دقيق مكتوب للقارئ.
          serverMessage: error.context?['serverMessage']?.toString(),
        ),
        (json) {
          final data = json['data'] is Map
              ? Map<String, dynamic>.from(json['data'] as Map)
              : json;
          if (data.isEmpty) return null;

          _localDataSource.cacheDailyForm(logId, data);
          return _parseDailyFormData(data);
        },
      );
    }, tag: 'LogRepositoryImpl.getForm');
  }

  DailyFormData _parseDailyFormData(Map<String, dynamic> data) {
    List<dynamic> extractList(dynamic val) {
      if (val is List) return val;
      if (val is String && val.trim().isNotEmpty) return val.split(',');
      return [];
    }

    final trailersList = extractList(data['trailers'])
        .map((e) {
          if (e is Map) return e['trailerNumber']?.toString() ?? '';
          if (e is String) return e.trim();
          return e?.toString() ?? '';
        })
        .where((e) => e.isNotEmpty)
        .toList();

    final docsList = extractList(data['shippingDocuments'])
        .map((e) {
          if (e is Map) return e['documentNumber']?.toString() ?? '';
          if (e is String) return e.trim();
          return e?.toString() ?? '';
        })
        .where((e) => e.isNotEmpty)
        .toList();

    int? coDriverId = data['coDriverId'] as int?;
    String? coDriverName;
    if (data['coDriver'] is Map) {
      final coDriverMap = data['coDriver'] as Map<dynamic, dynamic>;
      coDriverId ??= coDriverMap['id'] is int
          ? coDriverMap['id'] as int
          : int.tryParse(coDriverMap['id']?.toString() ?? '');
      coDriverName = coDriverMap['name']?.toString();
    }

    final vehicle = data['vehicle'] is Map
        ? Map<String, dynamic>.from(data['vehicle'] as Map)
        : null;
    // الوثيقة: `vehicle.identifier`/`vehicle.id`؛ نقرأ أيضاً الأشكال
    // المسطّحة القديمة (uniqueId/vehicleName) كي لا ينكسر سجل من عقد أقدم.
    final vehicleId = (vehicle?['id'] as num?)?.toInt();
    final vehicleUniqueId =
        vehicle?['identifier']?.toString() ??
        vehicle?['uniqueId']?.toString() ??
        data['uniqueId']?.toString();
    final vehicleName =
        vehicle?['name']?.toString() ??
        vehicle?['displayName']?.toString() ??
        data['vehicleName']?.toString();

    return DailyFormData(
      vehicleId: vehicleId,
      vehicleUniqueId: vehicleUniqueId,
      vehicleName: vehicleName,
      coDriverId: coDriverId,
      coDriverName: coDriverName,
      trailers: trailersList,
      shippingDocuments: docsList,
    );
  }

  @override
  Future<Either<Failure, FormSaveResult>> saveForm({
    required DailyLogId logId,
    required DailyFormUpdate form,
    int? ownerDriverId,
  }) async {
    // بوابة سبق الحفظ: بلا `uniqueId` العقد يرفض الطلب (400)، فلا نلوّث
    // الكاش ولا طابور الأوفلاين بجسم غير قابل للحفظ أصلاً.
    if (form.vehicleUniqueId.trim().isEmpty) {
      return const Left(
        ValidationFailure(message: 'validation.vehicleRequired'),
      );
    }

    final payload = _mapFormUpdateToJson(form);
    await _localDataSource.cacheDailyForm(logId, payload);
    final hasVehicle = form.vehicleUniqueId.trim().isNotEmpty;
    final hasDocs = form.shippingDocuments.isNotEmpty;
    if (ownerDriverId != null) {
      await _localDataSource.markCachedDailyLogFormComplete(
        driverId: ownerDriverId,
        logId: logId,
        isComplete: hasVehicle && hasDocs,
      );
    }

    if (!_networkInfo.isConnected) {
      await _offlineQueue.enqueue(
        PendingEvent(
          id: _idGenerator.v4(),
          type: 'daily_log_form',
          // P0 2B-1 — canonical owner slot read by EventOwnershipResolver.
          // Legal form semantics unchanged; identity only. Null when the
          // caller could not prove an owner (→ UNKNOWN, never inferred).
          payload: {
            'logId': logId.value,
            'form': payload,
            'ownerDriverId': ownerDriverId,
          },
          createdAt: _timeAuthority.nowUtc(),
        ),
      );
      return const Right(FormSaveResult.offline());
    }

    return executeWithHandling(() async {
      final response = await _dailyLogsBackend.saveForm(
        logId: logId,
        form: payload,
      );

      return response.fold(
        (error) => throw ServerException(
          message: error.code,
          // 🔴 لا تُرمى رسالة الخادم: هي تفسير دقيق مكتوب للقارئ.
          serverMessage: error.context?['serverMessage']?.toString(),
        ),
        (json) {
          final read = SavedFormDto.fromJson(json);
          if (ownerDriverId != null && read.complete != null) {
            _localDataSource.markCachedDailyLogFormComplete(
              driverId: ownerDriverId,
              logId: logId,
              isComplete: read.complete!,
            );
          }
          return FormSaveResult.online(read);
        },
      );
    }, tag: 'LogRepositoryImpl.saveForm');
  }

  @override
  Future<Either<Failure, LogReadiness>> getReadiness(DailyLogId logId) async {
    if (!_networkInfo.isConnected) {
      // P3 — جاهزية أوفلاين صادقة: تُشتق من السجل المخزّن نفسه (المالك
      // والاكتمال الفعليان). لا ادعاء «READY» بلا بيانات، وغياب سجل
      // مخزّن يعني فشلاً صريحاً تتكفل الواجهة بعرضه (ببيانات محلية حقيقية).
      final owner = await _localDataSource.ownerOfCachedLog(logId.value);
      if (owner == null) return const Left(NetworkFailure());
      final cached = await _localDataSource.getCachedDailyLogs(owner);
      if (cached == null) return const Left(NetworkFailure());
      final found = cached
          .where(
            (m) =>
                m['id'] == logId.value ||
                m['id']?.toString() == logId.value.toString(),
          )
          .toList();
      if (found.isEmpty) return const Left(NetworkFailure());
      final log = DailyLogDto.fromJson(found.first).toEntity();
      final isComplete = log.isFormComplete;
      return Right(
        LogReadiness(
          dailyLogId: logId.value,
          driverId: owner,
          driverName: log.driverName ?? '',
          logDate: DateFormat('yyyy-MM-dd').format(log.date),
          readinessStatus: isComplete ? 'READY' : 'NOT_READY',
          missingRequirements: isComplete
              ? const []
              : const ['The daily form is not complete for this day.'],
          // الفراغ يجعل الواجهة تستخدم النص القانوني المترجم المعتمد.
          legalStatement: '',
          availableActions: const ['CERTIFY'],
        ),
      );
    }
    return executeWithHandling(() async {
      final result = await _dailyLogsBackend.getReadiness(logId);
      return result.match(
        (failure) => throw ServerException(message: failure.l10nKey),
        (data) {
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
        },
      );
    }, tag: 'LogRepositoryImpl.getReadiness');
  }

  @override
  Future<Either<Failure, LogCertifyState>> getCertifyState(
    DailyLogId logId,
  ) async {
    if (!_networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    final result = await _dailyLogsBackend.getCertifyState(logId);
    // خادم قديم بلا `GET /certify` (404 أو 405) حالة متوقعة وليست خطأً:
    // لا نسجّل ضجيجاً — شاشة الاعتماد تعود لبيانات الجاهزية وحدها.
    final backendError = result.fold((e) => e, (_) => null);
    if (backendError != null && _isEndpointUnsupported(backendError)) {
      return const Left(
        ServerFailure(message: 'certify_state_unavailable', statusCode: 404),
      );
    }
    return executeWithHandling(() async {
      return result.match(
        (failure) => throw ServerException(message: failure.l10nKey),
        (data) => LogCertifyState(
          dailyLogId: data.dailyLogId,
          logDate: data.logDate,
          statementText: data.statementText,
          ruleReference: data.ruleReference,
          hasSignature: data.hasSignature,
          signatureImageData: data.signatureImageData,
          certificationStatus: data.certificationStatus,
          certified: data.certified,
          canCertify: data.canCertify,
          validationCodes: data.validationCodes,
        ),
      );
    }, tag: 'LogRepositoryImpl.getCertifyState');
  }

  /// `GET /certify` غير منشور على الخادم (404)، أو موجود بفعل آخر (405).
  static bool _isEndpointUnsupported(AppError error) =>
      error is NotFoundError ||
      (error is UnknownError && error.code == 'network.http.405');

  @override
  Future<Either<Failure, bool>> certifyLog({
    required DailyLogId logId,
    required int driverId,
    bool certified = true,
    String? signatureImageBase64,
  }) async {
    if (driverId <= 0) {
      return const Left(ServerFailure(message: 'Driver session is missing'));
    }
    if (!_networkInfo.isConnected) {
      // SRS 6.8 — offline: enqueue for sync, never lose the driver's certification.
      await _offlineQueue.enqueue(
        PendingEvent(
          id: _idGenerator.v4(),
          type: 'certification',
          // P0 2B-1 — canonical owner slot (driverId param already
          // validated >0 above). Legal certify semantics unchanged.
          payload: {
            'logId': logId.value,
            'certified': certified,
            if (signatureImageBase64 != null && signatureImageBase64.isNotEmpty)
              'signatureImage': signatureImageBase64,
            'ownerDriverId': driverId,
          },
          createdAt: _timeAuthority.nowUtc(),
        ),
      );
      return const Right(true);
    }
    return executeWithHandling(() async {
      final result = await _dailyLogsBackend.certify(
        CertifyRequestDto(
          dailyLogId: logId.value,
          certified: certified,
          signatureImage: signatureImageBase64,
        ),
      );
      return result.match(
        (failure) => throw ServerException(message: failure.l10nKey),
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
        (failure) => throw ServerException(message: failure.l10nKey),
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
        (failure) => throw ServerException(message: failure.l10nKey),
        (_) => true,
      );
    }, tag: 'LogRepositoryImpl.reassignDriving');
  }

  @override
  Future<Either<Failure, List<DutyPeriod>>> getPeriods(DateTime date) {
    return executeWithHandling(
      () =>
          _localDataSource.getPeriods(date, _timeAuthority.nowUtc().toLocal()),
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

  @override
  Future<void> saveDraftSignature(DailyLogId logId, String pointsJson) {
    return _localDataSource.saveDraftSignature(logId, pointsJson);
  }

  @override
  Future<String?> getDraftSignature(DailyLogId logId) {
    return _localDataSource.getDraftSignature(logId);
  }

  @override
  Future<void> deleteDraftSignature(DailyLogId logId) {
    return _localDataSource.deleteDraftSignature(logId);
  }
}
