import '../../../../core/result/result.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/raw_json.dart';
import '../../../contracts/status_dashboard_backend.dart';
import '../fixtures/status_dashboard_fixtures.dart';

/// In-memory mock for [StatusDashboardBackend].
///
/// **Rule:** Deterministic. Duty status changes persist in-memory.
class MockStatusDashboardBackend implements StatusDashboardBackend {
  MockStatusDashboardBackend();

  String _currentDutyStatus = 'ON_DUTY';

  @override
  Future<Result<RawJson>> getDashboard({DriverId? driverId}) async {
    return ok({
      ...statusDashboardFixture,
      'currentDutyStatus': _currentDutyStatus,
    });
  }

  @override
  Future<Result<RawJson>> updateDutyStatus({
    required String dutyStatus,
    String? notes,
  }) async {
    _currentDutyStatus = dutyStatus;
    return ok({
      ...statusDashboardFixture,
      'currentDutyStatus': _currentDutyStatus,
    });
  }

  @override
  Future<Result<RawJson>> getWeeklyRecap({DriverId? driverId}) async {
    return ok(Map<String, dynamic>.from(weeklyRecapFixture));
  }
}
