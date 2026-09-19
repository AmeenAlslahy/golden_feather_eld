import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_status_dashboard_backend.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
  late MockStatusDashboardBackend backend;

  setUp(() {
    backend = MockStatusDashboardBackend();
  });

  // ==========================================================================
  // getDashboard
  // ==========================================================================

  group('MockStatusDashboardBackend.getDashboard', () {
    test('returns success', () async {
      final result = await backend.getDashboard();
      expect(result.isSuccess, isTrue);
    });

    test('returns a fully-populated dashboard', () async {
      final dashboard = expectSuccess(await backend.getDashboard());

      expect(dashboard.driver.id.value, 101);
      expect(dashboard.driver.name, isNotEmpty);
      expect(dashboard.driver.displayText, isNotEmpty);
      expect(dashboard.operationalAlerts.connectionStatus, ConnectionStatus.ok);
      expect(dashboard.hosIndicators.drive.label, 'DRIVE');
      expect(dashboard.hosIndicators.shift.label, 'SHIFT');
      expect(dashboard.hosIndicators.breakTime.label, 'BREAK');
      expect(dashboard.hosIndicators.cycle.label, 'CYCLE');
      expect(dashboard.regulatoryConstraints.ruleSet, CycleRule.usa70_8);
    });

    test('default duty status is onDutyNotDriving', () async {
      final dashboard = expectSuccess(await backend.getDashboard());
      expect(dashboard.currentDutyStatus, DutyStatusCode.onDutyNotDriving);
    });

    test('accepts optional driverId without error', () async {
      final result = await backend.getDashboard(
        driverId: const DriverId(999),
      );
      expect(result.isSuccess, isTrue);
    });

    test('remainingCircle has positive remaining time', () async {
      final dashboard = expectSuccess(await backend.getDashboard());
      expect(dashboard.remainingCircle.remaining, greaterThan(Duration.zero));
      expect(dashboard.remainingCircle.isExpired, isFalse);
      expect(dashboard.remainingCircle.isCritical, isFalse);
    });

    test('progress is within [0.0, 1.0]', () async {
      final dashboard = expectSuccess(await backend.getDashboard());
      expect(dashboard.remainingCircle.progress, inInclusiveRange(0.0, 1.0));
    });
  });

  // ==========================================================================
  // updateDutyStatus
  // ==========================================================================

  group('MockStatusDashboardBackend.updateDutyStatus', () {
    test('changes current duty status', () async {
      final dashboard = expectSuccess(
        await backend.updateDutyStatus(status: DutyStatusCode.driving),
      );
      expect(dashboard.currentDutyStatus, DutyStatusCode.driving);
    });

    test('subsequent getDashboard reflects new status', () async {
      await backend.updateDutyStatus(status: DutyStatusCode.offDuty);

      final dashboard = expectSuccess(await backend.getDashboard());
      expect(dashboard.currentDutyStatus, DutyStatusCode.offDuty);
    });

    test('works with all DutyStatusCode values', () async {
      for (final status in DutyStatusCode.values) {
        final dashboard = expectSuccess(
          await backend.updateDutyStatus(status: status),
        );
        expect(dashboard.currentDutyStatus, status);
      }
    });

    test('accepts optional notes parameter', () async {
      final result = await backend.updateDutyStatus(
        status: DutyStatusCode.driving,
        notes: 'Trip started',
      );
      expect(result.isSuccess, isTrue);
    });

    test('multiple updates preserve only the latest', () async {
      await backend.updateDutyStatus(status: DutyStatusCode.driving);
      await backend.updateDutyStatus(status: DutyStatusCode.sleeperBerth);
      final dashboard = expectSuccess(
        await backend.updateDutyStatus(status: DutyStatusCode.offDuty),
      );
      expect(dashboard.currentDutyStatus, DutyStatusCode.offDuty);
    });
  });

  // ==========================================================================
  // getWeeklyRecap
  // ==========================================================================

  group('MockStatusDashboardBackend.getWeeklyRecap', () {
    test('returns success', () async {
      final result = await backend.getWeeklyRecap();
      expect(result.isSuccess, isTrue);
    });

    test('returns 7 days', () async {
      final recap = expectSuccess(await backend.getWeeklyRecap());
      expect(recap.days, hasLength(7));
    });

    test('cycleRule is USA 70/8', () async {
      final recap = expectSuccess(await backend.getWeeklyRecap());
      expect(recap.cycleRule, CycleRule.usa70_8);
    });

    test('cycleUsed + cycleRemaining = cycleHours', () async {
      final recap = expectSuccess(await backend.getWeeklyRecap());
      final total = recap.cycleUsed + recap.cycleRemaining;
      expect(
        total.inMinutes,
        equals(CycleRule.usa70_8.cycleHours * 60),
      );
    });

    test('all days have non-empty dayOfWeek', () async {
      final recap = expectSuccess(await backend.getWeeklyRecap());
      for (final day in recap.days) {
        expect(day.dayOfWeek, isNotEmpty);
      }
    });

    test('days are consecutive', () async {
      final recap = expectSuccess(await backend.getWeeklyRecap());
      for (var i = 1; i < recap.days.length; i++) {
        final diff = recap.days[i].date.difference(recap.days[i - 1].date);
        expect(diff.inDays, equals(1));
      }
    });

    test('each day has non-negative durations', () async {
      final recap = expectSuccess(await backend.getWeeklyRecap());
      for (final day in recap.days) {
        expect(day.driving.inMinutes, greaterThanOrEqualTo(0));
        expect(day.onDuty.inMinutes, greaterThanOrEqualTo(0));
        expect(day.totalWork.inMinutes, greaterThanOrEqualTo(0));
      }
    });
  });

  // ==========================================================================
  // State isolation
  // ==========================================================================

  group('MockStatusDashboardBackend — state isolation', () {
    test('two instances have independent state', () async {
      final a = MockStatusDashboardBackend();
      final b = MockStatusDashboardBackend();

      await a.updateDutyStatus(status: DutyStatusCode.driving);

      final dashboardA = expectSuccess(await a.getDashboard());
      final dashboardB = expectSuccess(await b.getDashboard());

      expect(dashboardA.currentDutyStatus, DutyStatusCode.driving);
      expect(dashboardB.currentDutyStatus, DutyStatusCode.onDutyNotDriving);
    });

    test('state persists across calls on same instance', () async {
      await backend.updateDutyStatus(status: DutyStatusCode.personalConveyance);

      expectSuccess(await backend.getDashboard());
      expectSuccess(await backend.getDashboard());
      final dashboard = expectSuccess(await backend.getDashboard());

      expect(dashboard.currentDutyStatus, DutyStatusCode.personalConveyance);
    });
  });
}
