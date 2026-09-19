import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../domain/shared/value_objects.dart';
import '../repositories/status_dashboard_repository.dart';

class GetWeeklyRecapUseCase {
  final StatusDashboardRepository _repository;

  GetWeeklyRecapUseCase(this._repository);

  Future<Either<Failure, WeeklyRecap>> execute({DriverId? driverId}) {
    return _repository.getWeeklyRecap(driverId: driverId);
  }
}
