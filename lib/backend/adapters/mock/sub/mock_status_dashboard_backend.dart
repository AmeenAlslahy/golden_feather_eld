import '../../../../core/result/result.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/status_dashboard_backend.dart';

/// In-memory mock for [StatusDashboardBackend].
/// **Status:** Skeleton — typed implementation in T2.3.
class MockStatusDashboardBackend implements StatusDashboardBackend {
  const MockStatusDashboardBackend();

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) =>
      throw UnimplementedError(
        'MockStatusDashboardBackend.getDashboard — T2.3',
      );

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  }) =>
      throw UnimplementedError(
        'MockStatusDashboardBackend.updateDutyStatus — T2.3',
      );

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) =>
      throw UnimplementedError(
        'MockStatusDashboardBackend.getWeeklyRecap — T2.3',
      );
}
