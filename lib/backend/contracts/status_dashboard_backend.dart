import '../../core/domain/duty_status/duty_status_code.dart';
import '../../core/domain/duty_status/status_dashboard.dart';
import '../../core/domain/duty_status/weekly_recap.dart';
import '../../core/domain/shared/value_objects.dart';
import '../../core/result/result.dart';

/// Contract for the status dashboard (main driver screen).
abstract interface class StatusDashboardBackend {
  /// GET /eld/status
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId});

  /// POST /eld/status/duty-status
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  });

  /// GET /eld/status/recap
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId});
}
