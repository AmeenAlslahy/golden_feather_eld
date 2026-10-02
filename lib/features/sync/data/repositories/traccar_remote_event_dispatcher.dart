import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../domain/entities/pending_event.dart';
import '../../domain/usecases/sync_engine.dart';
import '../../../../backend/contracts/duty_status_backend.dart';
import '../../../../backend/adapters/eld_engine/models/certify_dto.dart';
import '../../../../backend/contracts/daily_logs_backend.dart';
import '../../../../backend/contracts/dvir_backend.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/data/datasources/auth_local_data_source.dart';

/// يوجه أحداث الطابور إلى endpoints الخادم الصحيحة حسب النوع.
///
/// الأنواع المدعومة:
/// - `duty_status` — POST /eld/duty-status
/// - `daily_log_form` — PUT /eld/daily-logs/{id}/form
/// - `certification` — POST /eld/daily-logs/{id}/certify
/// - `dvir_create` — POST /eld/dvir
/// - `dvir_review` — POST /eld/dvir/{id}/review
class TraccarRemoteEventDispatcher implements RemoteEventDispatcher {
  final DutyStatusBackend _dutyStatusBackend;
  final DailyLogsBackend _dailyLogsBackend;
  final DvirBackend _dvirBackend;
  final AuthLocalDataSource _localDataSource;

  TraccarRemoteEventDispatcher(
    this._dutyStatusBackend,
    this._dailyLogsBackend,
    this._dvirBackend,
    this._localDataSource,
  );

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

  Future<Either<Failure, bool>> _dispatchDutyStatus(PendingEvent event) async {
    final driverId = await _driverId();
    if (driverId <= 0) {
      return const Left(ServerFailure(message: 'Driver session is missing'));
    }
    final payload = Map<String, dynamic>.from(event.payload);
    payload['driverId'] = driverId;

    if (payload['status'] is String) {
      final s = payload['status'] as String;
      switch (s) {
        case 'driving':
          payload['status'] = 'DRIVING';
          break;
        case 'on_duty':
          payload['status'] = 'ON_DUTY';
          break;
        case 'off_duty':
          payload['status'] = 'OFF_DUTY';
          break;
        case 'sleeper':
        case 'sleeper_berth':
          payload['status'] = 'SLEEPER';
          break;
        case 'yard_move':
          payload['status'] = 'YARD_MOVE';
          break;
        case 'personal_use':
        case 'personal_conveyance':
          payload['status'] = 'PERSONAL_CONVEYANCE';
          break;
      }
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
