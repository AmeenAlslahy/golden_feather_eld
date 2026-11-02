import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failure.dart';
import '../../../../domain/shared/value_objects.dart';
import '../entities/unidentified_event.dart';

/// عقد قراءة/الاعتراض على أحداث القيادة غير المحددة (SRS 11).
abstract class UnidentifiedEventsRepository {
  Future<Either<Failure, List<UnidentifiedEvent>>> getEvents({
    required UnidentifiedTab tab,
    int page = 0,
    int size = 100,
  });

  Future<Either<Failure, UnidentifiedEvent>> getEvent(DutyStatusId id);

  Future<Either<Failure, UnidentifiedSummary>> getSummary();

  Future<Either<Failure, void>> claim({
    required DutyStatusId id,
    required DriverId driverId,
    required String annotation,
  });

  Future<Either<Failure, void>> reject({
    required DutyStatusId id,
    required DriverId driverId,
    required String rejectionReason,
  });
}
