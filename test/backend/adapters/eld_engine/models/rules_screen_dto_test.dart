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
  });

  group('RulesScreenUpdateRequest', () {
    test('toJson generates correct map', () {
      const req = RulesScreenUpdateRequest(
        cycleRule: 'Rule A',
        cargoType: 'Type B',
        restart: 'Restart C',
        restBreak: 'Break D',
        sixteenHourException: true,
      );

      final json = req.toJson();
      expect(json, {
        'cycleRule': 'Rule A',
        'cargoType': 'Type B',
        'restart': 'Restart C',
        'restBreak': 'Break D',
        'sixteenHourException': true,
      });
    });
  });
}
