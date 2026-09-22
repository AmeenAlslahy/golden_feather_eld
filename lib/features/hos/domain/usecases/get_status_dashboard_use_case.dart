import 'package:fpdart/fpdart.dart';

import '../../../../core/domain/duty_status/status_dashboard.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/error/failure.dart';
import '../repositories/status_dashboard_repository.dart';

class GetStatusDashboardUseCase {
  final StatusDashboardRepository _repository;

  GetStatusDashboardUseCase(this._repository);

  Future<Either<Failure, StatusDashboard>> execute({DriverId? driverId}) {
    return _repository.getDashboard(driverId: driverId);
  }
}
