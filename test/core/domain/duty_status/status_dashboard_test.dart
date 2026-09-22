import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/core/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/core/domain/shared/value_objects.dart';

void main() {
  // ==========================================================================
  // DutyStatusCode
  // ==========================================================================

  group('DutyStatusCode', () {
    test('fromWire parses known values', () {
      expect(DutyStatusCode.fromWire('DRIVING'), DutyStatusCode.driving);
      expect(DutyStatusCode.fromWire('OFF_DUTY'), DutyStatusCode.offDuty);
      expect(DutyStatusCode.fromWire('SLEEPER'), DutyStatusCode.sleeperBerth);
      expect(DutyStatusCode.fromWire('ON_DUTY'), DutyStatusCode.onDutyNotDriving);
      expect(DutyStatusCode.fromWire('YARD_MOVE'), DutyStatusCode.yardMove);
      expect(DutyStatusCode.fromWire('PERSONAL_CONVEYANCE'), DutyStatusCode.personalConveyance);
    });

    test('fromWire is case-insensitive', () {
      expect(DutyStatusCode.fromWire('driving'), DutyStatusCode.driving);
      expect(DutyStatusCode.fromWire('Driving'), DutyStatusCode.driving);
    });

    test('fromWire falls back to offDuty on unknown', () {
      expect(DutyStatusCode.fromWire('BOGUS'), DutyStatusCode.offDuty);
      expect(DutyStatusCode.fromWire(null), DutyStatusCode.offDuty);
      expect(DutyStatusCode.fromWire(''), DutyStatusCode.offDuty);
    });

    test('fromShortCode parses known codes', () {
      expect(DutyStatusCode.fromShortCode('D'), DutyStatusCode.driving);
      expect(DutyStatusCode.fromShortCode('OFF'), DutyStatusCode.offDuty);
      expect(DutyStatusCode.fromShortCode('SB'), DutyStatusCode.sleeperBerth);
    });

    test('fromShortCode returns null on unknown', () {
      expect(DutyStatusCode.fromShortCode('XYZ'), isNull);
      expect(DutyStatusCode.fromShortCode(null), isNull);
    });

    test('countsAsOnDuty is correct per FMCSA', () {
      expect(DutyStatusCode.offDuty.countsAsOnDuty, isFalse);
      expect(DutyStatusCode.sleeperBerth.countsAsOnDuty, isFalse);
      expect(DutyStatusCode.driving.countsAsOnDuty, isTrue);
      expect(DutyStatusCode.onDutyNotDriving.countsAsOnDuty, isTrue);
      expect(DutyStatusCode.yardMove.countsAsOnDuty, isTrue);
      expect(DutyStatusCode.personalConveyance.countsAsOnDuty, isTrue);
    });
  });

  // ==========================================================================
  // ConnectionStatus
  // ==========================================================================

  group('ConnectionStatus', () {
    test('fromWire parses known values', () {
      expect(ConnectionStatus.fromWire('OK'), ConnectionStatus.ok);
      expect(ConnectionStatus.fromWire('WARNING'), ConnectionStatus.warning);
      expect(ConnectionStatus.fromWire('DISCONNECTED'), ConnectionStatus.disconnected);
    });

    test('falls back to unknown', () {
      expect(ConnectionStatus.fromWire('BOGUS'), ConnectionStatus.unknown);
      expect(ConnectionStatus.fromWire(null), ConnectionStatus.unknown);
    });
  });

  // ==========================================================================
  // IndicatorType
  // ==========================================================================

  group('IndicatorType', () {
    test('fromWire parses known values', () {
      expect(IndicatorType.fromWire('USED'), IndicatorType.used);
      expect(IndicatorType.fromWire('REMAINING'), IndicatorType.remaining);
    });

    test('falls back to used', () {
      expect(IndicatorType.fromWire('BOGUS'), IndicatorType.used);
      expect(IndicatorType.fromWire(null), IndicatorType.used);
    });
  });

  // ==========================================================================
  // CycleRule
  // ==========================================================================

  group('CycleRule', () {
    test('fromWire parses known values', () {
      expect(CycleRule.fromWire('USA 70/8'), CycleRule.usa70_8);
      expect(CycleRule.fromWire('USA 60/7'), CycleRule.usa60_7);
    });

    test('falls back to unknown', () {
      expect(CycleRule.fromWire('BOGUS'), CycleRule.unknown);
      expect(CycleRule.fromWire(null), CycleRule.unknown);
    });

    test('cycleHours and cycleDays correct', () {
      expect(CycleRule.usa70_8.cycleHours, 70);
      expect(CycleRule.usa70_8.cycleDays, 8);
      expect(CycleRule.usa60_7.cycleHours, 60);
      expect(CycleRule.usa60_7.cycleDays, 7);
    });
  });

  // ==========================================================================
  // RemainingCircle
  // ==========================================================================

  group('RemainingCircle', () {
    test('isExpired when remaining is zero', () {
      const circle = RemainingCircle(
        remaining: Duration.zero,
        label: 'Remaining',
        progress: 0.0,
      );
      expect(circle.isExpired, isTrue);
    });

    test('isExpired when remaining is negative', () {
      const circle = RemainingCircle(
        remaining: Duration(minutes: -30),
        label: 'Remaining',
        progress: 0.0,
      );
      expect(circle.isExpired, isTrue);
    });

    test('isCritical when remaining ≤ 1h', () {
      const circle = RemainingCircle(
        remaining: Duration(minutes: 45),
        label: 'Remaining',
        progress: 0.5,
      );
      expect(circle.isCritical, isTrue);
      expect(circle.isExpired, isFalse);
    });

    test('not critical when remaining > 1h', () {
      const circle = RemainingCircle(
        remaining: Duration(hours: 3),
        label: 'Remaining',
        progress: 0.6,
      );
      expect(circle.isCritical, isFalse);
      expect(circle.isExpired, isFalse);
    });
  });

  // ==========================================================================
  // Equality
  // ==========================================================================

  group('Value equality', () {
    test('StatusDashboard equality', () {
      final a = _sampleDashboard();
      final b = _sampleDashboard();
      expect(a, equals(b));
    });

    test('StatusDashboard inequality', () {
      final a = _sampleDashboard();
      final b = _sampleDashboard().copyWith(
        currentDutyStatus: DutyStatusCode.driving,
      );
      expect(a, isNot(equals(b)));
    });

    test('HosIndicator equality', () {
      const a = HosIndicator(
        label: 'DRIVE',
        value: Duration(hours: 2),
        type: IndicatorType.used,
      );
      const b = HosIndicator(
        label: 'DRIVE',
        value: Duration(hours: 2),
        type: IndicatorType.used,
      );
      expect(a, equals(b));
    });

    test('copyWith preserves other fields', () {
      final original = _sampleDashboard();
      final modified = original.copyWith(
        currentDutyStatus: DutyStatusCode.offDuty,
      );
      expect(modified.driver, equals(original.driver));
      expect(modified.hosIndicators, equals(original.hosIndicators));
      expect(modified.currentDutyStatus, DutyStatusCode.offDuty);
    });
  });
}

// =============================================================================
// Test fixtures
// =============================================================================

StatusDashboard _sampleDashboard() {
  return const StatusDashboard(
    driver: DriverRef(
      id: DriverId(101),
      name: 'Ahmed',
      displayText: 'Ahmed - 101',
    ),
    operationalAlerts: OperationalAlerts(
      toolIcon: false,
      warningTriangleIcon: false,
      connectionStatus: ConnectionStatus.ok,
    ),
    currentDutyStatus: DutyStatusCode.onDutyNotDriving,
    remainingCircle: RemainingCircle(
      remaining: Duration(hours: 8, minutes: 37),
      label: 'Remaining',
      progress: 0.62,
    ),
    hosIndicators: HosIndicators(
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
    regulatoryConstraints: RegulatoryConstraints(
      ruleSet: CycleRule.usa70_8,
      limits: ['maxDrivingHours: 11'],
    ),
  );
}
