import 'package:fpdart/fpdart.dart';

import '../../../../core/domain/duty_status/duty_status_code.dart';
import '../../../../core/domain/duty_status/status_dashboard.dart';
import '../../../../core/domain/duty_status/weekly_recap.dart';
import '../../../../core/domain/shared/value_objects.dart';
import '../../../../core/error/failure.dart';

abstract class StatusDashboardRepository {
  /// Fetch the current status dashboard.
  Future<Either<Failure, StatusDashboard>> getDashboard({DriverId? driverId});

  /// Update duty status and get the updated dashboard.
  Future<Either<Failure, StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  });

  /// Fetch the weekly recap data.
  Future<Either<Failure, WeeklyRecap>> getWeeklyRecap({DriverId? driverId});
}
