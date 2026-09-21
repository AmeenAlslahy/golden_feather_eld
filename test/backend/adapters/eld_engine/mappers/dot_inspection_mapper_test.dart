import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/mappers/dot_inspection_mapper.dart';

void main() {
  group('DotInspectionMapper', () {
    test('fromScreenJson parses full JSON', () {
      final json = {
        'screenTitle': 'Title',
        'driver': {'id': 101, 'name': 'Ahmed'},
        'inspectionDate': '2026-01-15',
        'cycleDaysCovered': 8,
        'canStartInspection': true,
      };
      final screen = DotInspectionMapper.fromScreenJson(json);
      expect(screen.screenTitle, 'Title');
      expect(screen.driverId.value, 101);
      expect(screen.driverName, 'Ahmed');
      expect(screen.cycleDaysCovered, 8);
      expect(screen.canStartInspection, true);
    });

    test('fromScreenJson parses with missing fields', () {
      final json = <String, dynamic>{};
      final screen = DotInspectionMapper.fromScreenJson(json);
      expect(screen.screenTitle, '');
      expect(screen.driverId.value, 0);
      expect(screen.driverName, '');
      expect(screen.cycleDaysCovered, 0);
      expect(screen.canStartInspection, false);
    });

    test('fromCycleJson parses list', () {
      final raw = [
        {
          'driver': {'id': 101, 'name': 'Ahmed'},
          'logDate': '2026-01-15',
          'certified': true,
        },
        {
          'driver': {'id': 101, 'name': 'Ahmed'},
          'logDate': '2026-01-16',
          'certified': false,
        }
      ];
      final days = DotInspectionMapper.fromCycleJson(raw);
      expect(days.length, 2);
      expect(days.first.certified, true);
      expect(days.last.certified, false);
    });

    test('fromLogJson parses json', () {
      final json = {
        'driver': {'id': 101, 'name': 'Ahmed'},
        'logDate': '2026-01-15',
        'events': [
          {
            'sequenceNumber': 1,
            'timeEt': '06:00',
          }
        ]
      };
      final log = DotInspectionMapper.fromLogJson(json);
      expect(log.driverId.value, 101);
      expect(log.events.length, 1);
      expect(log.events.first.sequenceNumber, 1);
    });
  });
}
