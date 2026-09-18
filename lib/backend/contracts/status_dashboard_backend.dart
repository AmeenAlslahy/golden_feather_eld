import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import 'raw_json.dart';

abstract interface class StatusDashboardBackend {
  /// GET /eld/status
  // TODO(P2): replace with StatusDashboard
  Future<Result<RawJson>> getDashboard({DriverId? driverId});

  /// POST /eld/status/duty-status
  // TODO(P2): replace with StatusDashboard
  Future<Result<RawJson>> updateDutyStatus({
    required String dutyStatus,
    String? notes,
  });

  /// GET /eld/status/recap
  // TODO(P2): replace with WeeklyRecap
  Future<Result<RawJson>> getWeeklyRecap({DriverId? driverId});
}
