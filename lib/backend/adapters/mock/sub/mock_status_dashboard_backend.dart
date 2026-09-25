import '../../../../core/result/result.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../contracts/status_dashboard_backend.dart';

/// In-memory mock for [StatusDashboardBackend].
///
/// **Rules:**
/// - No network, no delays, no platform channels.
/// - Deterministic output.
/// - Mutable state per instance (duty status change persists).
///
/// **State:**
/// - `_currentStatus` — starts at `onDutyNotDriving`.
///   Changes via [updateDutyStatus] and persists for the lifetime
///   of this instance.
class MockStatusDashboardBackend implements StatusDashboardBackend {
  MockStatusDashboardBackend();

  DutyStatusCode _currentStatus = DutyStatusCode.onDutyNotDriving;

  // ==========================================================================
  // Contract implementation
  // ==========================================================================

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async {
    return ok(_buildDashboard());
  }

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  }) async {
    _currentStatus = status;
    return ok(_buildDashboard());
  }

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async {
    return ok(_buildWeeklyRecap());
  }

  // ==========================================================================
  // Builders
  // ==========================================================================

  StatusDashboard _buildDashboard() {
    return StatusDashboard(
      driver: const DriverRef(
        id: DriverId(101),
        name: 'سعد بن محمد العتيبي',
        displayText: 'سعد بن محمد العتيبي - 101',
      ),
      operationalAlerts: const OperationalAlerts(
        toolIcon: false,
        warningTriangleIcon: false,
        connectionStatus: ConnectionStatus.ok,
      ),
      currentDutyStatus: _currentStatus,
      // الحلقة الدائرية تتبع الحالة النشطة — القيمة الثابتة (8:37) كانت
      // تعرض نفس الرقم أثناء القيادة وخارجها.
      remainingCircle: _remainingCircle(),
      hosIndicators: const HosIndicators(
        drive: HosIndicator(
          label: 'DRIVE',
          value: Duration(hours: 2, minutes: 23),
          type: IndicatorType.used,
        ),
        shift: HosIndicator(
          label: 'SHIFT',
          value: Duration(hours: 5, minutes: 23),
          type: IndicatorType.used,
        ),
        breakTime: HosIndicator(
          label: 'BREAK',
          value: Duration(minutes: 30),
          type: IndicatorType.remaining,
        ),
        cycle: HosIndicator(
          label: 'CYCLE',
          value: Duration(hours: 61, minutes: 23),
          type: IndicatorType.used,
        ),
      ),
      regulatoryConstraints: const RegulatoryConstraints(
        ruleSet: CycleRule.usa70_8,
        limits: [
          'maxDrivingHours: 11',
          'maxShiftHours: 14',
          'mandatoryRestHours: 10',
          'cycleHours: 70',
        ],
      ),
    );
  }

  RemainingCircle _remainingCircle() {
    const remaining = Duration(hours: 8, minutes: 37);
    if (_currentStatus == DutyStatusCode.driving) {
      const total = Duration(hours: 11);
      return RemainingCircle(
        remaining: remaining,
        label: 'Drive remaining',
        progress: remaining.inMinutes / total.inMinutes,
      );
    }
    const total = Duration(hours: 14);
    return RemainingCircle(
      remaining: remaining,
      label: 'Shift remaining',
      progress: remaining.inMinutes / total.inMinutes,
    );
  }

  WeeklyRecap _buildWeeklyRecap() {
    // Fixed reference date for deterministic output.
    final startDate = DateTime(2026, 1, 9);

    return WeeklyRecap(
      cycleRule: CycleRule.usa70_8,
      cycleUsed: const Duration(hours: 61, minutes: 23),
      cycleRemaining: const Duration(hours: 8, minutes: 37),
      availableTomorrow: const Duration(hours: 8, minutes: 45),
      days: List.generate(7, (i) {
        final date = startDate.add(Duration(days: i));
        // Deterministic pattern per day index.
        final driving = Duration(
          hours: 6 + (i % 3),
          minutes: (i * 15) % 60,
        );
        final onDuty = Duration(
          hours: 7 + (i % 2),
          minutes: (i * 10) % 60,
        );
        return RecapDay(
          date: date,
          dayOfWeek: _dayOfWeek(date),
          driving: driving,
          onDuty: onDuty,
          totalWork: onDuty,
        );
      }),
    );
  }

  static String _dayOfWeek(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[date.weekday - 1];
  }
}
