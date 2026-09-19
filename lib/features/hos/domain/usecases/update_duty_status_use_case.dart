import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../repositories/status_dashboard_repository.dart';

class UpdateDutyStatusUseCase {
  final StatusDashboardRepository _repository;

  UpdateDutyStatusUseCase(this._repository);

  Future<Either<Failure, StatusDashboard>> execute({
    required DutyStatusCode status,
    String? notes,
  }) {
    return _repository.updateDutyStatus(status: status, notes: notes);
  }
}
