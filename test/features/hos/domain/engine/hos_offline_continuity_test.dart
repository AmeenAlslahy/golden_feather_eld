import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_offline_dashboard.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_state_machine.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/circular_timer_logic.dart';

void main() {
  group('HOS Offline Continuity & Timer Preservation', () {
    test('HosOfflineDashboardBuilder provides positive break time and governing limit', () {
      const limits = HosLimits(
        remainingDriveMinutes: 600, // 10h
        remainingShiftMinutes: 720, // 12h
        remainingCycleHours: 65.0,
        breakRequired: false,
        breakRemainingMinutes: 0,
        timeUntilBreakMinutes: 420, // 7h until 30-min break
      );
      const update = HosStatusUpdate(
        currentStatus: DutyStatus.driving,
        limits: limits,
        alerts: [],
        violations: [],
        remainingDriveMinutes: 600,
        remainingShiftMinutes: 720,
        remainingCycleHours: 65.0,
        breakRequired: false,
        breakRemainingMinutes: 0,
      );
      final ready = HosEngineReady(update);

      const builder = HosOfflineDashboardBuilder();
      final dashboard = builder.build(
        engineResult: ready,
        driverId: const DriverId(1),
        driverName: 'Driver 1',
      );

      // Break indicator must show 420 minutes (7 hours), NOT 0
      expect(dashboard.hosIndicators.breakTime.value.inMinutes, 420);
      expect(dashboard.hosIndicators.breakTime.type, IndicatorType.remaining);

      // Governing remaining for driving is min(600, 720, 420) = 420
      expect(dashboard.remainingCircle.remaining.inMinutes, 420);
    });

    test('HosStateMachine tracks active driving and onDuty sessions', () {
      final fakeTime = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 10, 14, 10, 0),
      );
      final sm = HosStateMachine(fakeTime);

      // Manually transition to driving using effectiveNow
      sm.transitionTo(DutyStatus.driving);
      expect(sm.currentStatus, DutyStatus.driving);

      // Total driving hours should not throw and should remain valid
      expect(sm.totalDrivingHours, greaterThanOrEqualTo(0.0));

      // Transition to onDuty
      sm.transitionTo(DutyStatus.onDutyNotDriving);
      expect(sm.currentStatus, DutyStatus.onDutyNotDriving);
      expect(sm.cycleHours, greaterThanOrEqualTo(0.0));
    });

    test('CircularTimerLogic.liveIndicators preserves elapsed countdown during offline period', () {
      const initialIndicators = HosIndicators(
        drive: HosIndicator(label: 'DRIVE', value: Duration(hours: 10), type: IndicatorType.remaining),
        shift: HosIndicator(label: 'SHIFT', value: Duration(hours: 12), type: IndicatorType.remaining),
        breakTime: HosIndicator(label: 'BREAK', value: Duration(hours: 7), type: IndicatorType.remaining),
        cycle: HosIndicator(label: 'CYCLE', value: Duration(hours: 60), type: IndicatorType.remaining),
      );

      const elapsed = Duration(minutes: 45);

      final live = CircularTimerLogic.liveIndicators(
        indicators: initialIndicators,
        dutyStatus: DutyStatusCode.driving,
        statusLabel: 'Driving',
        elapsedSinceSnapshot: elapsed,
      );

      // Remaining indicators must decrease by exactly 45 minutes
      expect(live.drive.value, const Duration(hours: 9, minutes: 15));
      expect(live.shift.value, const Duration(hours: 11, minutes: 15));
      expect(live.breakTime.value, const Duration(hours: 6, minutes: 15));
      expect(live.cycle.value, const Duration(hours: 59, minutes: 15));
    });

    test('server circle value is authoritative — no one-directional clamp', () {
      const serverCircle = RemainingCircle(
        remaining: Duration(hours: 8),
        label: 'Remaining',
        progress: 0.0,
      );
      // مؤشرات تشير محلياً إلى أضيق (وردية 6:30 مستهلكة ⇒ 7:30 متبقية).
      const indicators = HosIndicators(
        drive: HosIndicator(
            label: 'DRIVE', value: Duration.zero, type: IndicatorType.used),
        shift: HosIndicator(
            label: 'SHIFT',
            value: Duration(hours: 6, minutes: 30),
            type: IndicatorType.used),
        breakTime: HosIndicator(
            label: 'BREAK',
            value: Duration(hours: 8),
            type: IndicatorType.remaining),
        cycle: HosIndicator(
            label: 'CYCLE', value: Duration.zero, type: IndicatorType.used),
      );

      final ui = CircularTimerLogic.calculateUiState(
        circle: serverCircle,
        dutyStatus: DutyStatusCode.onDutyNotDriving,
        hosIndicators: indicators,
        statusLabel: 'ON_DUTY',
        elapsedSinceSnapshot: Duration.zero,
      );

      // Must display the server value verbatim — not the local derivation
      expect(ui.liveRemaining, const Duration(hours: 8));
    });
  });
}
