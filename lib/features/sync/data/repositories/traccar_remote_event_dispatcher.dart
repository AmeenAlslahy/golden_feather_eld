import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
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

  TraccarRemoteEventDispatcher(
    this._dutyStatusBackend,
    this._dailyLogsBackend,
    this._dvirBackend,
    this._localDataSource, [
    this._inspectionBackend,
  ]);

  Future<int> _driverId() async {
    final session = await _localDataSource.getSession();
    return session == null ? 0 : (int.tryParse(session.user.id) ?? 0);
  }

  @override
  Future<Either<Failure, bool>> dispatch(PendingEvent event) async {
    try {
      switch (event.type) {
        case 'duty_status':
          return await _dispatchDutyStatus(event);
        case 'daily_log_form':
          return await _dispatchDailyLogForm(event);
        case 'certification':
          return await _dispatchCertification(event);
        case 'dvir_create':
          return await _dispatchDvirCreate(event);
        case 'dvir_review':
          return await _dispatchDvirReview(event);
        case 'inspection_transfer':
          return await _dispatchInspectionTransfer(event);
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

  Future<Either<Failure, bool>> _dispatchInspectionTransfer(
    PendingEvent event,
  ) async {
    final backend = _inspectionBackend;
    if (backend == null) return const Right(true);

    final driverId = event.payload['driverId'] as int? ?? await _driverId();
    if (driverId <= 0) {
      return const Left(ServerFailure(message: 'Driver session is missing'));
    }

    final methodStr = event.payload['method'] as String? ?? 'webService';
    final email = event.payload['email'] as String?;
    final comment = event.payload['comment'] as String? ?? 'Inspection logs';
    final routingCode = event.payload['routingCode'] as String?;

    if (methodStr == 'email' && email != null && email.isNotEmpty) {
      final res = await backend.emailLogs(
        driverId: DriverId(driverId),
        recipientEmail: email,
        routingCode: routingCode,
        comment: comment,
      );
      return res.fold(
        (err) => Left(ServerFailure(message: err.code)),
        (_) => const Right(true),
      );
    } else {
      final res = await backend.sendLogs(
        driverId: DriverId(driverId),
        transferType: InspectionTransferType.webServices,
        outputFileComment: comment,
        routingCode: routingCode,
        recipientEmail: email,
      );
      return res.fold(
        (err) => Left(ServerFailure(message: err.code)),
        (_) => const Right(true),
      );
    }
  }

  Future<Either<Failure, bool>> _dispatchDutyStatus(PendingEvent event) async {
    final payload = Map<String, dynamic>.from(event.payload);
    final eventDriverId = payload['driverId'] as int?;
    
    final driverId = eventDriverId != null && eventDriverId > 0 
        ? eventDriverId 
        : await _driverId();

    if (driverId <= 0) {
      return const Left(ServerFailure(message: 'Driver session is missing'));
    }
    payload['driverId'] = driverId;

    if (payload['status'] is String) {
      final s = payload['status'] as String;
      payload['status'] = DutyStatusCode.fromAny(s).wire;
    }

    final result = await _dutyStatusBackend.submitLegacyDutyStatusEvent(
      driverId,
      payload,
    );
    return await result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (_) => const Right(true),
    );
  }

  Future<Either<Failure, bool>> _dispatchDailyLogForm(
    PendingEvent event,
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
    );
    return await result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (_) => const Right(true),
    );
  }

  Future<Either<Failure, bool>> _dispatchCertification(
    PendingEvent event,
  ) async {
    final logId = event.payload['logId'] as int?;
    if (logId == null || logId <= 0) {
      return const Left(ServerFailure(message: 'daily log id is missing'));
    }
    final driverId = await _driverId();
    if (driverId <= 0) {
      return const Left(ServerFailure(message: 'Driver session is missing'));
    }
    final result = await _dailyLogsBackend.certify(
      CertifyRequestDto(
        dailyLogId: logId,
        driverId: driverId,
        logDate: event.payload['logDate'] as String? ?? '',
        signatureCertificateId:
            event.payload['signatureCertificateId'] as String? ?? '',
        signatureConfirmation:
            event.payload['signatureConfirmation'] as bool? ?? true,
        certifiedTrue: event.payload['certifiedTrue'] as bool? ?? true,
      ),
    );
    return await result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (_) => const Right(true),
    );
  }

  Future<Either<Failure, bool>> _dispatchDvirCreate(PendingEvent event) async {
    final payload = Map<String, dynamic>.from(event.payload);
    final result = await _dvirBackend.create(payload);
    return await result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (_) => const Right(true),
    );
  }

  Future<Either<Failure, bool>> _dispatchDvirReview(PendingEvent event) async {
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
    );
    return await result.fold(
      (error) => Left(ServerFailure(message: error.code)),
      (_) => const Right(true),
    );
  }
}
