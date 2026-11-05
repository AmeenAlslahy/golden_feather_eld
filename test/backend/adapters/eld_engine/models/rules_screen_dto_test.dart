import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/models/rules_screen_dto.dart';

void main() {
  group('RulesScreenDto', () {
    test('fromJson parses correctly with all fields', () {
      final json = {
        'driver': '100',
        'ruleSource': 'SnSoft - ELD',
        'cycleRule': 'USA 70 hour / 8 day',
        'cargoType': 'Property',
        'restart': '34 Hour Restart',
        'restBreak': '30 Minute Rest Break Required',
        'sixteenHourException': true,
        'options': {
          'cycleRule': ['USA 70 hour / 8 day', 'USA 60 hour / 7 day'],
          'cargoType': ['Property', 'Passenger'],
        },
        'limits': {
          'cycleHours': 70,
          'cycleDays': 8,
          'maxShiftHours': 14,
          'maxDrivingHours': 11,
          'mandatoryRestHours': 10
        },
        'editableFields': ['cycleRule', 'cargoType'],
        'readOnlyFields': ['restart'],
        'fixedSettings': {'someSetting': 'value'},
        'notice': 'Test notice'
      };

      final dto = RulesScreenDto.fromJson(json);

      expect(dto.driverId, '100');
      expect(dto.ruleSource, 'SnSoft - ELD');
      expect(dto.cycleRule, 'USA 70 hour / 8 day');
      expect(dto.cargoType, 'Property');
      expect(dto.restart, '34 Hour Restart');
      expect(dto.restBreak, '30 Minute Rest Break Required');
      expect(dto.sixteenHourException, true);
      expect(dto.options['cycleRule'], ['USA 70 hour / 8 day', 'USA 60 hour / 7 day']);
      expect(dto.limits.cycleHours, 70);
      expect(dto.limits.cycleDays, 8);
      expect(dto.editableFields, ['cycleRule', 'cargoType']);
      expect(dto.readOnlyFields, ['restart']);
      expect(dto.notice, 'Test notice');
    });

    test('fromJson handles missing or null fields gracefully', () {
      final json = <String, dynamic>{};
      final dto = RulesScreenDto.fromJson(json);

      expect(dto.driverId, '');
      expect(dto.ruleSource, '');
      expect(dto.limits.cycleHours, 0);
      expect(dto.editableFields, []);
      expect(dto.options, {});
      expect(dto.sixteenHourException, false);
    });

    test('fromJson populates editableFields from editPermissions when present', () {
      final json = {
        'driverId': 1,
        'editable': true,
        'rules': {
          'cycleRule': 'USA_70HR_8DAY',
          'shortHaul16HourException': true,
        },
        'editPermissions': {
          'canEditCycleRule': true,
          'canEditShortHaul16HourException': true,
          'canEditCargoType': false,
        },
      };

      final dto = RulesScreenDto.fromJson(json);

      expect(dto.driverId, '1');
      expect(dto.sixteenHourException, isTrue);
      expect(dto.editableFields, contains('cycleRule'));
      expect(dto.editableFields, contains('sixteenHourException'));
      expect(dto.editableFields, contains('shortHaul16HourException'));
      expect(dto.editableFields.contains('cargoType'), isFalse);
    });

    test('fromJson parses OAS 3.0 Swagger limits format correctly', () {
      final json = {
        'driverId': 101,
        'limits': {
          'drivingLimitHours': 11,
          'dutyLimitHours': 14,
          'restBreakMinutes': 30,
          'restBreakTriggerHours': 8,
          'cycleDutyHours': 70,
          'cycleDays': 8,
          'restartHours': 34
        }
      };

      final dto = RulesScreenDto.fromJson(json);

      expect(dto.driverId, '101');
      expect(dto.limits.cycleHours, 70);
      expect(dto.limits.cycleDays, 8);
      expect(dto.limits.maxDrivingHours, 11);
      expect(dto.limits.maxShiftHours, 14);
      expect(dto.limits.mandatoryRestHours, 34);
      expect(dto.limits.restBreakMinutes, 30);
      expect(dto.limits.restBreakTriggerHours, 8);
    });
  });
}
