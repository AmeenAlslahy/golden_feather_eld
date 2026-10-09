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
    final isRest = _currentStatus == DutyStatusCode.offDuty ||
        _currentStatus == DutyStatusCode.sleeperBerth ||
        _currentStatus == DutyStatusCode.personalConveyance;

    return StatusDashboard(
      driver: const DriverRef(
        id: DriverId(646),
        name: 'Naseem Hassan Ali Adam',
        displayText: 'Naseem Hassan Ali Adam - 646',
      ),
      operationalAlerts: const OperationalAlerts(
        toolIcon: false,
        warningTriangleIcon: false,
        connectionStatus: ConnectionStatus.ok,
      ),
      currentDutyStatus: _currentStatus,
      remainingCircle: _remainingCircle(),
      hosIndicators: isRest
          ? const HosIndicators(
              drive: HosIndicator(
                label: 'DRIVE',
                value: Duration(hours: 11),
                type: IndicatorType.remaining,
              ),
              shift: HosIndicator(
                label: 'SHIFT',
                value: Duration(hours: 14),
                type: IndicatorType.remaining,
              ),
              breakTime: HosIndicator(
                label: 'BREAK',
                value: Duration(hours: 8),
                type: IndicatorType.remaining,
              ),
              cycle: HosIndicator(
                label: 'CYCLE',
                value: Duration(hours: 70),
                type: IndicatorType.remaining,
              ),
            )
          : const HosIndicators(
              drive: HosIndicator(
                label: 'DRIVE',
                value: Duration(minutes: 35),
                type: IndicatorType.remaining,
              ),
              shift: HosIndicator(
                label: 'SHIFT',
                value: Duration(hours: 2, minutes: 8),
                type: IndicatorType.remaining,
              ),
              breakTime: HosIndicator(
                label: 'BREAK',
                value: Duration(hours: 6, minutes: 15),
                type: IndicatorType.remaining,
              ),
              cycle: HosIndicator(
                label: 'CYCLE',
                value: Duration(hours: 52, minutes: 48),
                type: IndicatorType.remaining,
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
    if (_currentStatus == DutyStatusCode.offDuty ||
        _currentStatus == DutyStatusCode.sleeperBerth ||
        _currentStatus == DutyStatusCode.personalConveyance) {
      return const RemainingCircle(
        remaining: Duration.zero,
        label: 'Remaining',
        progress: 0.0,
      );
    }
    if (_currentStatus == DutyStatusCode.driving) {
      // 00:35 remaining of 11:00 -> 10:25 elapsed (94.7% progress clockwise)
      const remaining = Duration(minutes: 35);
      const total = Duration(hours: 11);
      return RemainingCircle(
        remaining: remaining,
        label: 'Remaining',
        progress: (total.inMinutes - remaining.inMinutes) / total.inMinutes,
      );
    }
    // On Duty / Yard Move: 02:08 remaining of 14:00
    const remaining = Duration(hours: 2, minutes: 8);
    const total = Duration(hours: 14);
    return RemainingCircle(
      remaining: remaining,
      label: 'Remaining',
      progress: (total.inMinutes - remaining.inMinutes) / total.inMinutes,
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
