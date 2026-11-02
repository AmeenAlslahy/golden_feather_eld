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
      // An absent capability flag must not lock the driver out of the screen.
      expect(screen.canStartInspection, true);
      expect(screen.canSendLogs, true);
    });

    test('fromScreenJson honours an explicit false capability', () {
      final screen = DotInspectionMapper.fromScreenJson({
        'canStartInspection': false,
        'canSendLogs': 'false',
      });
      expect(screen.canStartInspection, false);
      expect(screen.canSendLogs, false);
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
      expect(log.period24HourStartTime, isNull);
    });

    test('fromLogJson maps period24HourStartTime (LocalTime object or string)',
        () {
      final asObject = DotInspectionMapper.fromLogJson({
        'driver': {'id': 101},
        'logDate': '2026-01-15',
        'period24HourStartTime': {'hour': 0, 'minute': 0, 'second': 0, 'nano': 0},
      });
      expect(asObject.period24HourStartTime, '00:00');

      final asString = DotInspectionMapper.fromLogJson({
        'driver': {'id': 101},
        'logDate': '2026-01-15',
        'period24HourStartTime': '04:30:00',
      });
      expect(asString.period24HourStartTime, '04:30');
    });

    test('fromLogJson takes license and co-driver from the record itself', () {
      final log = DotInspectionMapper.fromLogJson({
        'driver': {
          'id': 101,
          'name': 'Ahmed',
          'licenseNumber': 'D1234567',
          'licenseState': 'NV',
        },
        'coDriver': {'id': 202, 'name': 'Sami'},
        'logDate': '2026-01-15',
      });
      expect(log.driverLicenseNumber, 'D1234567');
      expect(log.driverLicenseState, 'NV');
      expect(log.coDriverName, 'Sami');
      expect(log.coDriverId, 202);

      final none = DotInspectionMapper.fromLogJson({
        'driver': {'id': 101, 'licenseNumber': ''},
        'logDate': '2026-01-15',
      });
      expect(none.driverLicenseNumber, isNull);
      expect(none.coDriverName, isNull);
    });

    test('fromScreenJson parses new Swagger response correctly', () {
      final json = {
        'inspectionId': 239,
        'status': 'ACTIVE',
        'startedAt': '2026-10-23T23:12:40.303413Z',
        'driver': {
          'id': 2,
          'name': 'إبراهيم الشامي',
          'licenseNumber': 'A350622298913',
          'licenseState': 'TX',
        },
        'vehicle': {
          'id': 485,
          'name': 'Truck 485',
          'vin': '3AKJHHDR1JSJT1066',
        },
        'eld': {
          'registrationId': 'CX7H',
          'identifier': 'TCE516',
          'provider': 'TOP COMPLIANCE ELD',
        },
        'carrier': {
          'name': 'eld transport',
          'dotNumber': '3892014',
          'mainOffice': '100 Fleet Boulevard',
          'homeTerminal': 'Dallas Terminal A',
        },
        'inspectionLogs': [
          {'logDate': '2026-10-30'},
          {'logDate': '2026-10-29'},
        ],
      };

      final screen = DotInspectionMapper.fromScreenJson(json);
      expect(screen.activeInspectionId, 239);
      expect(screen.inspectionActive, true);
      expect(screen.carrierName, 'eld transport');
      expect(screen.usdotNumber, '3892014');
      expect(screen.eldIdentifier, 'TCE516');
      expect(screen.eldRegistrationId, 'CX7H');
      expect(screen.driverId.value, 2);
      expect(screen.driverName, 'إبراهيم الشامي');
      expect(screen.cycleDaysCovered, 2);
      expect(screen.canStartInspection, true);
    });

    test('cycleFromSessionJson and logFromSessionJson extract logs properly', () {
      final session = {
        'inspectionId': 239,
        'status': 'ACTIVE',
        'driver': {
          'id': 2,
          'name': 'Driver Name',
          'certified': true,
        },
        'vehicle': {
          'id': 485,
          'name': 'Truck 485',
          'vin': '3AKJHHDR1JSJT1066',
        },
        'carrier': {
          'name': 'Carrier Name',
          'dotNumber': '3892014',
        },
        'eld': {
          'identifier': 'TCE516',
          'registrationId': 'CX7H',
          'provider': 'TOP COMPLIANCE ELD',
        },
        'inspectionLogs': [
          {
            'logDate': '2026-10-30',
            'periodStartingTime': '00:00:00',
            'displayLocation': 'Dearborn, MI',
            'dataDiagnosticIndicator': true,
            'deviceMalfunctionIndicator': false,
            'odometer': {'start': 100, 'end': 200, 'total': 100},
            'engineHours': {'start': 50, 'end': 60, 'total': 10},
            'shipment': {
              'trailers': [{'trailerNumber': 'TR-101'}],
              'shippingDocuments': [{'documentNumber': 'DOC-202'}],
            },
            'graphGrid': {
              'events': [
                {
                  'time': '2026-10-30T00:00Z',
                  'code': 'OFF',
                  'location': 'Home Terminal',
                  'odometer': 100,
                  'engineHours': 50,
                  'origin': 'AUTO',
                  'notes': 'Off duty',
                }
              ]
            }
          }
        ]
      };

      final cycle = DotInspectionMapper.cycleFromSessionJson(session);
      expect(cycle.length, 1);
      final day = cycle.first;
      expect(day.driverId.value, 2);
      expect(day.carrierName, 'Carrier Name');
      expect(day.usdotNumber, '3892014');
      expect(day.trailers, 'TR-101');
      expect(day.shippingDocuments, 'DOC-202');
      expect(day.totalDistanceKm, 100.0);
      expect(day.engineHours, 10.0);
      expect(day.activeDataDiagnostics, contains('DATA_DIAGNOSTIC'));
      expect(day.activeDeviceMalfunctions, isEmpty);

      final log = DotInspectionMapper.logFromSessionJson(session, targetDate: DateTime.utc(2026, 10, 30));
      expect(log.driverId.value, 2);
      expect(log.events.length, 1);
      expect(log.events.first.eventCode, 'OFF');
      expect(log.events.first.timeEt, '2026-10-30T00:00Z');
      expect(log.events.first.location, 'Home Terminal');
    });
  });
}
