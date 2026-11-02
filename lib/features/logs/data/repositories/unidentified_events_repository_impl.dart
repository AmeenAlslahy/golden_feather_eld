import 'package:fpdart/fpdart.dart';

import '../../../../backend/contracts/contract_enums.dart' as wire;
import '../../../../backend/contracts/unidentified_events_backend.dart';
import '../../../../core/error/app_error.dart';
import '../../../../core/error/failure.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../domain/entities/unidentified_event.dart';
import '../../domain/repositories/unidentified_events_repository.dart';
import '../models/unidentified_event_dto.dart';

/// تنفيذ عقد الأحداث غير المحددة فوق [UnidentifiedEventsBackend].
///
/// تحليل JSON وبناء الكيانات يقع هنا — لا في طبقة العرض.
class UnidentifiedEventsRepositoryImpl implements UnidentifiedEventsRepository {
  final UnidentifiedEventsBackend _backend;

  const UnidentifiedEventsRepositoryImpl(this._backend);

  @override
  Future<Either<Failure, List<UnidentifiedEvent>>> getEvents({
    required UnidentifiedTab tab,
    int page = 0,
    int size = 100,
  }) async {
    final result = await _backend.list(
      tab: _toWire(tab),
      page: page,
      size: size,
    );
    return result.fold(
      (error) => Left(_toFailure(error)),
      (json) => Right(parseUnidentifiedEvents(json)),
    );
  }

  @override
  Future<Either<Failure, UnidentifiedEvent>> getEvent(DutyStatusId id) async {
    final result = await _backend.getById(id: id);
    return result.fold(
      (error) => Left(_toFailure(error)),
      (json) => Right(parseUnidentifiedEvent(json)),
    );
  }

  @override
  Future<Either<Failure, UnidentifiedSummary>> getSummary() async {
    final result = await _backend.summary();
    return result.fold(
      (error) => Left(_toFailure(error)),
      (json) => Right(parseUnidentifiedSummary(json)),
    );
  }

  @override
  Future<Either<Failure, void>> claim({
    required DutyStatusId id,
    required DriverId driverId,
    required String annotation,
  }) async {
    final result = await _backend.claim(
      id: id,
      driverId: driverId,
      annotation: annotation,
    );
    return result.fold(
      (error) => Left(_toFailure(error)),
      (_) => const Right<Failure, void>(null),
    );
  }

  @override
  Future<Either<Failure, void>> reject({
    required DutyStatusId id,
    required DriverId driverId,
    required String rejectionReason,
  }) async {
    final result = await _backend.reject(
      id: id,
      driverId: driverId,
      rejectionReason: rejectionReason,
    );
    return result.fold(
      (error) => Left(_toFailure(error)),
      (_) => const Right<Failure, void>(null),
    );
  }

  wire.UnidentifiedTab _toWire(UnidentifiedTab tab) {
    return switch (tab) {
      UnidentifiedTab.unclaimed => wire.UnidentifiedTab.unclaimed,
      UnidentifiedTab.rejected => wire.UnidentifiedTab.rejected,
    };
  }

  Failure _toFailure(AppError error) {
    final raw = error.context?['message'] ?? error.context?['serverMessage'];
    return ServerFailure(
      message: error.l10nKey,
      statusCode: error is ServerError ? error.statusCode : null,
      serverMessage: raw is String && raw.trim().isNotEmpty ? raw.trim() : null,
    );
  }
}
