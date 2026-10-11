import 'package:fpdart/fpdart.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/dispatch_auth.dart';
import '../../domain/entities/event_ownership.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/usecases/sync_engine.dart';
import '../../../../backend/contracts/duty_status_backend.dart';
import '../../../../backend/adapters/eld_engine/models/certify_dto.dart';
import '../../../../backend/contracts/daily_logs_backend.dart';
import '../../../../backend/contracts/dvir_backend.dart';
import '../../../../backend/contracts/inspection_backend.dart';
import '../../../../backend/contracts/contract_enums.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';
import '../../../../domain/duty_status/duty_status_code.dart';

/// يوجه أحداث الطابور إلى endpoints الخادم الصحيحة حسب النوع.
///
/// الأنواع المدعومة:
/// - `duty_status` — POST /eld/duty-status
/// - `daily_log_form` — PUT /eld/daily-logs/{id}/form
/// - `certification` — POST /eld/daily-logs/{id}/certify
/// - `dvir_create` — POST /eld/dvir
/// - `dvir_review` — POST /eld/dvir/{id}/review
/// - `inspection_transfer` — POST /eld/dot-inspection/send-logs or email-logs
class TraccarRemoteEventDispatcher implements RemoteEventDispatcher {
  final DutyStatusBackend _dutyStatusBackend;
  final DailyLogsBackend _dailyLogsBackend;
  final DvirBackend _dvirBackend;
  final AuthLocalDataSource _localDataSource;
  final InspectionBackend? _inspectionBackend;

  /// P0 2B-1 — سياق الجلسة للسياج: driverId الحالي + هل انتقال جارٍ.
  /// تُحقن من طبقة providers (المتصل الوحيد) — الـ dispatcher نفسه بلا Ref.
  /// إلزامية: لا سياج بلا سياق (no fail-open).
  final Future<DispatchAuthContext> Function() observeAuth;

  /// P0 2B-1 — إثبات مالك السجل المخزن (RECOVERABLE عبر كاش Hive).
  /// تُحقن من طبقة providers — الـ dispatcher لا يعرف مصادر السجلات.
  final Future<int?> Function(int logId)? cachedLogOwner;

  TraccarRemoteEventDispatcher(
    this._dutyStatusBackend,
    this._dailyLogsBackend,
    this._dvirBackend,
    this._localDataSource, {
    InspectionBackend? inspectionBackend,
    required this.observeAuth,
    this.cachedLogOwner,
  }) : _inspectionBackend = inspectionBackend;

  Future<int> _driverId() async {
    final session = await _localDataSource.getSession();
    return session == null ? 0 : (int.tryParse(session.user.id) ?? 0);
  }

  /// P0 2B-1 — سياج الإرسال المركزي (نقطة الخنق الوحيدة؛ يمر عبرها
  /// محركا المزامنة معاً). لا HTTP هنا: إما سماح مثبت أو حجر مُعلل
  /// يُحوَّل في المحرك لنقل ذري — لا حذف ولا retry.
  Future<QuarantinedFailure?> _authorize(
    PendingEvent event,
    EventOwnership ownership,
  ) async {
    final ctx = await observeAuth();
    // المصدر الوحيد للهوية الحية هو مراقب الجلسة المحقون؛ قراءة الجلسة
    // المباشرة احتياط دفاعي فقط عند غياب المراقب (لا يحدث إنتاجياً).
    final sessionDriverId = ctx.driverId ?? await _driverId();
    final transitioning = ctx.transitioning;

    if (sessionDriverId <= 0) {
      return QuarantinedFailure(
        reason: 'deferred-unauthenticated',
        ownerDriverId: ownership.driverId,
        parkState: 'deferredUnauthenticated',
      );
    }
    if (transitioning) {
      return QuarantinedFailure(
        reason: 'deferred-transitioning',
        ownerDriverId: ownership.driverId,
        parkState: 'deferredOwnerMismatch',
      );
    }
    if (!ownership.isProven) {
      return QuarantinedFailure(
        reason: 'quarantined-${ownership.evidence.name}',
        ownerDriverId: ownership.driverId,
        parkState: 'quarantinedUnknownOwner',
      );
    }
    if (ownership.driverId != sessionDriverId) {
      return QuarantinedFailure(
        reason: 'deferred-owner-mismatch',
        ownerDriverId: ownership.driverId,
        parkState: 'deferredOwnerMismatch',
      );
    }
    return null;
  }

  /// P0 2B-1 — تعيين مركزي واحد لنتائج الـ backends (يمنع تكرار folds):
  /// رفض وقت-الإرسال (OwnerMismatchError من الـ interceptor) يُحوَّل لحجر
  /// بلا retry؛ أي خطأ آخر يسلك المسار القديم حرفياً (سلوك retry بلا تغيير).
  Either<Failure, bool> _mapResult<T>(
    Either<AppError, T> result,
    int owner,
  ) {
    return result.fold(
      (error) {
        if (error is OwnerMismatchError) {
          AppLogger.warning(
              'Dispatch fenced at HTTP boundary for owner $owner');
          return Left(QuarantinedFailure(
            reason: 'send-time-owner-mismatch',
            ownerDriverId: owner,
            parkState: 'deferredOwnerMismatch',
          ));
        }
        return Left(ServerFailure(message: error.code));
      },
      (_) => const Right(true),
    );
  }

  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    try {
      final resolved = await _resolveOwnership(event);
      final fence = await _authorize(event, resolved);
      if (fence != null) return Left(fence);
      final owner = resolved.driverId!;

      switch (event.type) {
        case 'duty_status':
          return await _dispatchDutyStatus(event, owner);
        case 'daily_log_form':
          return await _dispatchDailyLogForm(event, owner);
        case 'certification':
          return await _dispatchCertification(event, owner);
        case 'dvir_create':
          return await _dispatchDvirCreate(event, owner);
        case 'dvir_review':
          return await _dispatchDvirReview(event, owner);
        case 'inspection_transfer':
          return await _dispatchInspectionTransfer(event, owner);
        default:
          final result = await _dutyStatusBackend.submitLegacyGenericEvent(
            event.payload,
          );
          return await result.fold(
            (error) => Left(ServerFailure(message: error.code)),
            (_) => const Right(true),
          );
      }
    } catch (e) {
      return Left(ServerFailure(message: 'Failed to dispatch event: $e'));
    }
  }

  /// P0 2B-1 — حل الملكية مع دعم lookup غير متزامن للكاش (RECOVERABLE).
  /// المسار السريع أولاً (مباشر/canonical بلا I/O)؛ إن بقي UNKNOWN وكان
  /// النوع يحمل logId، يُستشار الكاش — بلا أي استنتاج من المستخدم الحالي.
  /// فشل الكاش = لا دليل = UNKNOWN (الاتجاه الآمن دائماً).
  Future<EventOwnership> _resolveOwnership(PendingEvent event) async {
    final sync = EventOwnershipResolver.resolve(event);
    if (sync.evidence != OwnerEvidence.unknown) return sync;
    final lookup = cachedLogOwner;
    final logId = _logIdOf(event);
    if (lookup == null || logId == null) return sync;
    try {
      final owner = await lookup(logId);
      if (owner != null && owner > 0) {
        return EventOwnership.recoverable(owner);
      }
    } catch (_) {
      // فشل الكاش = لا دليل — يبقى UNKNOWN (الاتجاه الآمن).
    }
    return EventOwnership.unknown;
  }

  static int? _logIdOf(PendingEvent event) {
    if (event.type != 'daily_log_form' && event.type != 'certification') {
      return null;
    }
    final raw = event.payload['logId'];
    final value =
        raw is int ? raw : int.tryParse('${raw ?? ''}');
    return value != null && value > 0 ? value : null;
  }

  Future<Either<Failure, bool>> _dispatchInspectionTransfer(
    PendingEvent event,
    int owner,
  ) async {
    final backend = _inspectionBackend;
    if (backend == null) return const Right(true);

    // P0 2B-1 — السياج ضمن المالك مسبقاً؛ هنا يُستخدم حصراً (لا fallback
    // لجلسة أخرى). الربط وقت-الإرسال عبر expectedOwnerDriverId أدناه.
    final methodStr = event.payload['method'] as String? ?? 'webService';
    final email = event.payload['email'] as String?;
    final comment = event.payload['comment'] as String? ?? 'Inspection logs';
    final routingCode = event.payload['routingCode'] as String?;

    if (methodStr == 'email' && email != null && email.isNotEmpty) {
      final res = await backend.emailLogs(
        driverId: DriverId(owner),
        recipientEmail: email,
        routingCode: routingCode,
        comment: comment,
        expectedOwnerDriverId: owner,
      );
      return _mapResult(res, owner);
    } else {
      final res = await backend.sendLogs(
        driverId: DriverId(owner),
        transferType: InspectionTransferType.webServices,
        outputFileComment: comment,
        routingCode: routingCode,
        recipientEmail: email,
        expectedOwnerDriverId: owner,
      );
      return _mapResult(res, owner);
    }
  }

  Future<Either<Failure, bool>> _dispatchDutyStatus(
    PendingEvent event,
    int owner,
  ) async {
    final payload = Map<String, dynamic>.from(event.payload);
    payload['driverId'] = owner;

    if (payload['status'] is String) {
      final s = payload['status'] as String;
      payload['status'] = DutyStatusCode.fromAny(s).wire;
    }

    final statusId = payload['statusId'] as int?;
    if (statusId != null && statusId > 0) {
      final result = await _dutyStatusBackend.update(
        statusId: DutyStatusId(statusId),
        update: {
          'status': payload['status'],
          'startTime': payload['startTime'],
          if (payload['locationText'] != null) 'locationText': payload['locationText'],
          if (payload['notes'] != null) 'editReason': payload['notes'],
        },
      );
      return _mapResult(result, owner);
    }

    final result = await _dutyStatusBackend.submitLegacyDutyStatusEvent(
      owner,
      payload,
      expectedOwnerDriverId: owner,
    );
    return _mapResult(result, owner);
  }

  Future<Either<Failure, bool>> _dispatchDailyLogForm(
    PendingEvent event,
    int owner,
  ) async {
    final logId = event.payload['logId'] as int?;
    if (logId == null || logId <= 0) {
      return const Left(ServerFailure(message: 'daily log id is missing'));
    }
    final form = Map<String, dynamic>.from(
      event.payload['form'] as Map<String, dynamic>? ?? {},
    );
    final result = await _dailyLogsBackend.saveForm(
      logId: DailyLogId(logId),
      form: form,
      expectedOwnerDriverId: owner,
    );
    return _mapResult(result, owner);
  }

  Future<Either<Failure, bool>> _dispatchCertification(
    PendingEvent event,
    int owner,
  ) async {
    final logId = event.payload['logId'] as int?;
    if (logId == null || logId <= 0) {
      return const Left(ServerFailure(message: 'daily log id is missing'));
    }
    // P0 2B-1 — هوية التصديق = مالك الحدث المثبت حصراً. انتهى حقن
    // جلسة الإرسال الحالية (كانت ترسل certify-A باسم B).
    final result = await _dailyLogsBackend.certify(
      CertifyRequestDto(
        dailyLogId: logId,
        driverId: owner,
        logDate: event.payload['logDate'] as String? ?? '',
        signatureCertificateId:
            event.payload['signatureCertificateId'] as String? ?? '',
        signatureConfirmation:
            event.payload['signatureConfirmation'] as bool? ?? true,
        certifiedTrue: event.payload['certifiedTrue'] as bool? ?? true,
      ),
      expectedOwnerDriverId: owner,
    );
    return _mapResult(result, owner);
  }

  Future<Either<Failure, bool>> _dispatchDvirCreate(
    PendingEvent event,
    int owner,
  ) async {
    final payload = Map<String, dynamic>.from(event.payload);
    final result =
        await _dvirBackend.create(payload, expectedOwnerDriverId: owner);
    return _mapResult(result, owner);
  }

  Future<Either<Failure, bool>> _dispatchDvirReview(
    PendingEvent event,
    int owner,
  ) async {
    final dvirId = event.payload['dvirId'] as int?;
    if (dvirId == null || dvirId <= 0) {
      return const Left(ServerFailure(message: 'dvir id is missing'));
    }
    final review = Map<String, dynamic>.from(
      event.payload['review'] as Map<String, dynamic>? ?? {},
    );
    final result = await _dvirBackend.review(
      dvirId: DvirId(dvirId),
      review: review,
      expectedOwnerDriverId: owner,
    );
    return _mapResult(result, owner);
  }
}
