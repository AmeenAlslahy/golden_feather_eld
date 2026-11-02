import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

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
      expect(
        dashboard.operationalAlerts.connectionStatus,
        equals(ConnectionStatus.ok),
      );

      expect(
        dashboard.currentDutyStatus,
        equals(DutyStatusCode.onDutyNotDriving),
      );

      expect(
        dashboard.remainingCircle.remaining,
        equals(const Duration(hours: 8, minutes: 37)),
      );
      expect(dashboard.remainingCircle.progress, equals(0.5));
      expect(dashboard.remainingCircle.label, 'Remaining');

      expect(
        dashboard.hosIndicators.drive.value,
        equals(const Duration(hours: 11)),
      );
      expect(
        dashboard.hosIndicators.drive.type,
        equals(IndicatorType.remaining),
      );

      expect(
        dashboard.regulatoryConstraints.ruleSet,
        equals(CycleRule.usa70_8),
      );
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
        'remainingCircle': {'time': '08:37'},
      };
      final dashboard = StatusDashboardMapper.fromDashboardJson(json);
      expect(
        dashboard.remainingCircle.remaining,
        equals(const Duration(hours: 8, minutes: 37)),
      );

      final jsonNeg = {
        'remainingCircle': {'time': '-02:30'},
      };
      final dashboardNeg = StatusDashboardMapper.fromDashboardJson(jsonNeg);
      expect(
        dashboardNeg.remainingCircle.remaining,
        equals(const Duration(hours: -2, minutes: -30)),
      );

      final jsonInvalid = {
        'remainingCircle': {'time': 'invalid'},
      };
      final dashboardInvalid = StatusDashboardMapper.fromDashboardJson(
        jsonInvalid,
      );
      expect(dashboardInvalid.remainingCircle.remaining, equals(Duration.zero));
    });

    test('clamps progress to [0.0, 1.0]', () {
      final json1 = {
        'remainingCircle': {'progress': 1.5},
      };
      final dashboard1 = StatusDashboardMapper.fromDashboardJson(json1);
      expect(dashboard1.remainingCircle.progress, equals(1.0));

      final json2 = {
        'remainingCircle': {'progress': -0.5},
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
          'drive': {'label': ''},
        },
      };
      final dashboard = StatusDashboardMapper.fromDashboardJson(json);
      expect(dashboard.hosIndicators.drive.label, 'DRIVE');
    });

    test('regulatoryConstraints handles invalid limits by stringifying', () {
      final json = {
        'regulatoryConstraints': {
          'limits': [1, 2, 'a'],
        },
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
          },
        ],
      };

      final recap = StatusDashboardMapper.fromRecapJson(json);

      expect(recap.cycleRule, equals(CycleRule.usa70_8));
      expect(recap.cycleUsed, equals(const Duration(hours: 61, minutes: 23)));
      expect(
        recap.cycleRemaining,
        equals(const Duration(hours: 8, minutes: 37)),
      );
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
          },
        ],
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
        equals(const Duration(hours: 23, minutes: 59, seconds: 59)),
      );
      expect(recap.cycleRemaining, equals(const Duration(minutes: 90)));
      expect(recap.availableTomorrow, equals(Duration.zero));
    });

    test(
      'parses new GET /eld/hos/recap JSON with dailyRecap & cycleSummary',
      () {
        final json = {
          'cycleSummary': {
            'rule': 'USA 70/8',
            'used': {'seconds': 149400, 'formatted': '41h 30m'},
            'remaining': {'seconds': 102600, 'formatted': '28h 30m'},
            'availableTomorrow': {'seconds': 36000, 'formatted': '10h 00m'},
          },
          'dailyRecap': [
            {
              'date': '2026-03-30T00:00:00Z',
              'driving': {'seconds': 18000, 'formatted': '05:00'},
              'onDuty': {'seconds': 7200, 'formatted': '02:00'},
              'totalWork': {'seconds': 25200, 'formatted': '07:00'},
            },
          ],
        };

        final recap = StatusDashboardMapper.fromRecapJson(json);

        expect(recap.cycleRule, equals(CycleRule.usa70_8));
        expect(recap.cycleUsed, equals(const Duration(hours: 41, minutes: 30)));
        expect(recap.effectiveCycleUsed.formatted, equals('41h 30m'));
        expect(
          recap.cycleRemaining,
          equals(const Duration(hours: 28, minutes: 30)),
        );
        expect(recap.availableTomorrow, equals(const Duration(hours: 10)));

        expect(recap.days.length, 1);
        final day = recap.days.first;
        expect(day.date, equals(DateTime.parse('2026-03-30T00:00:00Z')));
        expect(day.dayOfWeek, equals('Mon')); // Derived from date!
        expect(day.driving, equals(const Duration(hours: 5)));
        expect(day.effectiveDriving.formatted, equals('05:00'));
        expect(day.effectiveDriving.isPresent, isTrue);
        expect(day.onDuty, equals(const Duration(hours: 2)));
        expect(day.totalWork, equals(const Duration(hours: 7)));
        expect(day.isDrivingMissing, isFalse);
      },
    );

    test('handles missing driving without fabricating zero duration', () {
      final json = {
        'dailyRecap': [
          {
            'date': '2026-03-31T00:00:00Z',
            // No driving field!
            'onDuty': {'seconds': 7200, 'formatted': '02:00'},
          },
        ],
      };

      final recap = StatusDashboardMapper.fromRecapJson(json);
      expect(recap.days.length, 1);
      final day = recap.days.first;
      expect(day.isDrivingMissing, isTrue);
      expect(day.drivingTime?.isMissing, isTrue);
      expect(day.drivingTime?.duration, isNull);
    });

    test(
      'handles missing totalWork without copying onDuty or summing driving+onDuty',
      () {
        final json = {
          'dailyRecap': [
            {
              'date': '2026-03-31T00:00:00Z',
              'driving': {'seconds': 18000, 'formatted': '05:00'},
              'onDuty': {'seconds': 7200, 'formatted': '02:00'},
              // No totalWork field!
            },
          ],
        };

        final recap = StatusDashboardMapper.fromRecapJson(json);
        expect(recap.days.length, 1);
        final day = recap.days.first;
        expect(day.isTotalWorkMissing, isTrue);
        expect(day.totalWorkTime?.isMissing, isTrue);
        expect(day.totalWorkTime?.duration, isNull);
      },
    );

    test('handles missing onDuty without fabricating zero duration', () {
      final json = {
        'dailyRecap': [
          {
            'date': '2026-03-31T00:00:00Z',
            'driving': {'seconds': 18000, 'formatted': '05:00'},
          },
        ],
      };

      final recap = StatusDashboardMapper.fromRecapJson(json);
      expect(recap.days.length, 1);
      final day = recap.days.first;
      expect(day.isOnDutyMissing, isTrue);
      expect(day.onDutyTime?.isMissing, isTrue);
      expect(day.onDutyTime?.duration, isNull);
    });

    test('distinguishes real zero seconds from missing/invalid', () {
      final json = {
        'dailyRecap': [
          {
            'date': '2026-03-31T00:00:00Z',
            'driving': {'seconds': 0, 'formatted': '00:00'},
            'onDuty': {'seconds': 'bad-string'},
          },
        ],
      };

      final recap = StatusDashboardMapper.fromRecapJson(json);
      final day = recap.days.first;

      // Real zero:
      expect(day.effectiveDriving.isZero, isTrue);
      expect(day.effectiveDriving.isPresent, isTrue);
      expect(day.effectiveDriving.isMissing, isFalse);
      expect(day.effectiveDriving.duration, equals(Duration.zero));

      // Invalid:
      expect(day.effectiveOnDuty.isInvalid, isTrue);
      expect(day.effectiveOnDuty.isPresent, isFalse);
      expect(day.effectiveOnDuty.duration, isNull);

      // Missing:
      expect(day.effectiveTotalWork.isMissing, isTrue);
      expect(day.effectiveTotalWork.isPresent, isFalse);
    });

    test('handles empty dailyRecap gracefully', () {
      final json = {
        'cycleSummary': {'rule': 'USA 70/8'},
        'dailyRecap': <dynamic>[],
      };
      final recap = StatusDashboardMapper.fromRecapJson(json);
      expect(recap.days, isEmpty);
      expect(recap.cycleRule, equals(CycleRule.usa70_8));
    });
  });

  group('New GET /eld/hos/dashboard features', () {
    test('parses title, subtitle, seconds, and CONNECTED status', () {
      final json = {
        'operationalAlerts': {
          'toolIcon': false,
          'warningTriangleIcon': false,
          'connectionStatus': 'CONNECTED',
        },
        'currentDutyStatus': 'DRIVING',
        'remainingCircle': {
          'seconds': 28800,
          'title': 'Drive Time Remaining',
          'progress': 0.75,
        },
        'hosIndicators': {
          'drive': {
            'title': 'DRIVE',
            'subtitle': 'until rest break',
            'seconds': 28800,
            // no type sent!
          },
          'shift': {
            'title': 'SHIFT',
            'subtitle': 'until end of shift',
            'seconds': 43200,
          },
          'breakTime': {'title': 'BREAK', 'seconds': 1800},
          'cycle': {'title': 'CYCLE', 'seconds': 216000},
        },
      };

      final dashboard = StatusDashboardMapper.fromDashboardJson(json);

      expect(
        dashboard.operationalAlerts.connectionStatus,
        equals(ConnectionStatus.ok),
      );
      expect(dashboard.currentDutyStatus, equals(DutyStatusCode.driving));
      expect(dashboard.remainingCircle.label, equals('Drive Time Remaining'));
      expect(
        dashboard.remainingCircle.remaining,
        equals(const Duration(hours: 8)),
      );

      expect(dashboard.hosIndicators.drive.label, equals('DRIVE'));
      expect(
        dashboard.hosIndicators.drive.subtitle,
        equals('until rest break'),
      );
      expect(
        dashboard.hosIndicators.drive.value,
        equals(const Duration(hours: 8)),
      );
      // Indicator type defaulted to fallback without crashing or fabricating:
      expect(dashboard.hosIndicators.drive.type, equals(IndicatorType.remaining));
      expect(
        dashboard.hosIndicators.breakTime.type,
        equals(IndicatorType.remaining),
      );
    });

    test('handles partial dashboard responses without crashing', () {
      final json = <String, dynamic>{'currentDutyStatus': 'OFF_DUTY'};
      final dashboard = StatusDashboardMapper.fromDashboardJson(json);
      expect(dashboard.currentDutyStatus, equals(DutyStatusCode.offDuty));
      expect(dashboard.hosIndicators.drive.label, equals('DRIVE'));
      expect(dashboard.remainingCircle.label, equals('Remaining'));
    });
  });
}
