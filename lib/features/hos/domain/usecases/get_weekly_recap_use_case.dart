import 'package:fpdart/fpdart.dart';

import '../../../../core/domain/duty_status/weekly_recap.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/error/failure.dart';
import '../repositories/status_dashboard_repository.dart';

class GetWeeklyRecapUseCase {
  final StatusDashboardRepository _repository;

  GetWeeklyRecapUseCase(this._repository);

  Future<Either<Failure, WeeklyRecap>> execute({DriverId? driverId}) {
    return _repository.getWeeklyRecap(driverId: driverId);
  }
}
