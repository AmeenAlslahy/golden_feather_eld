import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart';
import 'package:golden_feather_eld/core/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/core/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/core/domain/shared/value_objects.dart';

void main() {
  group('StatusDashboardMapper.fromDashboardJson', () {
    test('parses full valid JSON into StatusDashboard', () {
      final json = {
        'driver': {'id': 123, 'name': 'John Doe', 'displayText': 'J. Doe'},
        'operationalAlerts': {
          'toolIcon': true,
          'warningTriangleIcon': false,
          'connectionStatus': 'OK',
        },
        'currentDutyStatus': 'ON_DUTY',
        'remainingCircle': {
          'time': '08:37',
          'label': 'Remaining',
          'progress': 0.5,
        },
        'hosIndicators': {
          'drive': {'label': 'DRIVE', 'value': '11:00', 'type': 'REMAINING'},
          'shift': {'label': 'SHIFT', 'value': '14:00', 'type': 'REMAINING'},
          'breakTime': {'label': 'BREAK', 'value': '08:00', 'type': 'USED'},
          'cycle': {'label': 'CYCLE', 'value': '70:00', 'type': 'REMAINING'},
        },
        'regulatoryConstraints': {
          'ruleSet': 'USA 70/8',
          'limits': ['60_7', '70_8'],
        },
      };

      final dashboard = StatusDashboardMapper.fromDashboardJson(json);

      expect(dashboard.driver.id, equals(const DriverId(123)));
      expect(dashboard.driver.name, 'John Doe');
      expect(dashboard.driver.displayText, 'J. Doe');

      expect(dashboard.operationalAlerts.toolIcon, isTrue);
      expect(dashboard.operationalAlerts.warningTriangleIcon, isFalse);
      expect(dashboard.operationalAlerts.connectionStatus,
          equals(ConnectionStatus.ok));

      expect(dashboard.currentDutyStatus, equals(DutyStatusCode.onDutyNotDriving));

      expect(
          dashboard.remainingCircle.remaining,
          equals(const Duration(hours: 8, minutes: 37)));
      expect(dashboard.remainingCircle.progress, equals(0.5));
      expect(dashboard.remainingCircle.label, 'Remaining');

      expect(
          dashboard.hosIndicators.drive.value, equals(const Duration(hours: 11)));
      expect(dashboard.hosIndicators.drive.type, equals(IndicatorType.remaining));

      expect(dashboard.regulatoryConstraints.ruleSet, equals(CycleRule.usa70_8));
      expect(dashboard.regulatoryConstraints.limits, equals(['60_7', '70_8']));
    });

    test('handles missing driver with fallback', () {
      final json = <String, dynamic>{};
      final dashboard = StatusDashboardMapper.fromDashboardJson(json);

      expect(dashboard.driver.id, equals(const DriverId(0)));
      expect(dashboard.driver.name, '');
      expect(dashboard.driver.displayText, '');
    });

    test('parses currentDutyStatus = "DRIVING" -> DutyStatusCode.driving', () {
      final json = {'currentDutyStatus': 'DRIVING'};
      final dashboard = StatusDashboardMapper.fromDashboardJson(json);
      expect(dashboard.currentDutyStatus, equals(DutyStatusCode.driving));
    });

    test('parses currentDutyStatus = "BOGUS" -> DutyStatusCode.offDuty', () {
      final json = {'currentDutyStatus': 'BOGUS'};
      final dashboard = StatusDashboardMapper.fromDashboardJson(json);
      expect(dashboard.currentDutyStatus, equals(DutyStatusCode.offDuty));
    });

    test('parses remainingCircle.time formats correctly', () {
      final json = {
        'remainingCircle': {'time': '08:37'}
      };
      final dashboard = StatusDashboardMapper.fromDashboardJson(json);
      expect(
          dashboard.remainingCircle.remaining,
          equals(const Duration(hours: 8, minutes: 37)));

      final jsonNeg = {
        'remainingCircle': {'time': '-02:30'}
      };
      final dashboardNeg = StatusDashboardMapper.fromDashboardJson(jsonNeg);
      expect(
          dashboardNeg.remainingCircle.remaining,
          equals(const Duration(hours: -2, minutes: -30)));

      final jsonInvalid = {
        'remainingCircle': {'time': 'invalid'}
      };
      final dashboardInvalid =
          StatusDashboardMapper.fromDashboardJson(jsonInvalid);
      expect(
          dashboardInvalid.remainingCircle.remaining, equals(Duration.zero));
    });

    test('clamps progress to [0.0, 1.0]', () {
      final json1 = {
        'remainingCircle': {'progress': 1.5}
      };
      final dashboard1 = StatusDashboardMapper.fromDashboardJson(json1);
      expect(dashboard1.remainingCircle.progress, equals(1.0));

      final json2 = {
        'remainingCircle': {'progress': -0.5}
      };
      final dashboard2 = StatusDashboardMapper.fromDashboardJson(json2);
      expect(dashboard2.remainingCircle.progress, equals(0.0));
    });

    test('handles missing hosIndicators with default indicators', () {
      final json = <String, dynamic>{};
      final dashboard = StatusDashboardMapper.fromDashboardJson(json);

      expect(dashboard.hosIndicators.drive.label, 'DRIVE');
      expect(dashboard.hosIndicators.shift.label, 'SHIFT');
      expect(dashboard.hosIndicators.breakTime.label, 'BREAK');
      expect(dashboard.hosIndicators.cycle.label, 'CYCLE');
    });

    test('handles hosIndicators.drive.label = "" -> fallback "DRIVE"', () {
      final json = {
        'hosIndicators': {
          'drive': {'label': ''}
        }
      };
      final dashboard = StatusDashboardMapper.fromDashboardJson(json);
      expect(dashboard.hosIndicators.drive.label, 'DRIVE');
    });

    test('regulatoryConstraints handles invalid limits by stringifying', () {
      final json = {
        'regulatoryConstraints': {
          'limits': [1, 2, 'a']
        }
      };
      final dashboard = StatusDashboardMapper.fromDashboardJson(json);
      expect(dashboard.regulatoryConstraints.limits, equals(['1', '2', 'a']));
    });
  });

  group('StatusDashboardMapper.fromRecapJson', () {
    test('parses full valid JSON into WeeklyRecap', () {
      final json = {
        'cycleRule': 'USA 70/8',
        'cycleUsed': '61:23',
        'cycleRemaining': '08:37',
        'availableTomorrow': '10:00',
        'days': [
          {
            'date': '2026-09-18T10:00:00Z',
            'dayOfWeek': 'Friday',
            'driving': '08:00',
            'onDuty': '02:00',
            'totalWork': '10:00',
          }
        ]
      };

      final recap = StatusDashboardMapper.fromRecapJson(json);

      expect(recap.cycleRule, equals(CycleRule.usa70_8));
      expect(
          recap.cycleUsed, equals(const Duration(hours: 61, minutes: 23)));
      expect(
          recap.cycleRemaining, equals(const Duration(hours: 8, minutes: 37)));
      expect(recap.availableTomorrow, equals(const Duration(hours: 10)));
      expect(recap.days.length, 1);
      expect(recap.days.first.dayOfWeek, 'Friday');
      expect(recap.days.first.driving, equals(const Duration(hours: 8)));
    });

    test('handles empty days list', () {
      final json = {'days': <dynamic>[]};
      final recap = StatusDashboardMapper.fromRecapJson(json);
      expect(recap.days, isEmpty);
    });

    test('filters out invalid entries in days', () {
      final json = {
        'days': [
          'invalid',
          123,
          {
            'dayOfWeek': 'Monday',
            'driving': '08:00',
            'onDuty': '02:00',
            'totalWork': '10:00',
          }
        ]
      };
      final recap = StatusDashboardMapper.fromRecapJson(json);
      expect(recap.days.length, 1);
      expect(recap.days.first.dayOfWeek, 'Monday');
    });

    test('primitive parsers handle custom duration formats', () {
      final json = {
        'cycleUsed': '23:59:59', // HH:MM:SS
        'cycleRemaining': 90, // numeric minutes
        'availableTomorrow': null,
      };

      final recap = StatusDashboardMapper.fromRecapJson(json);
      expect(
          recap.cycleUsed,
          equals(const Duration(hours: 23, minutes: 59, seconds: 59)));
      expect(recap.cycleRemaining, equals(const Duration(minutes: 90)));
      expect(recap.availableTomorrow, equals(Duration.zero));
    });
  });
}
