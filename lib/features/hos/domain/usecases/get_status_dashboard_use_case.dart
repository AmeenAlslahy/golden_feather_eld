import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/shared/value_objects.dart';
import '../repositories/status_dashboard_repository.dart';

class GetStatusDashboardUseCase {
  final StatusDashboardRepository _repository;

  GetStatusDashboardUseCase(this._repository);

  Future<Either<Failure, StatusDashboard>> execute({DriverId? driverId}) {
    return _repository.getDashboard(driverId: driverId);
  }
}
