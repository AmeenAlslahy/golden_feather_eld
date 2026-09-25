import '../../core/result/result.dart';
import '../../domain/duty_status/duty_status_code.dart';
import '../../domain/duty_status/status_dashboard.dart';
import '../../domain/duty_status/weekly_recap.dart';
import '../../domain/shared/value_objects.dart';

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
