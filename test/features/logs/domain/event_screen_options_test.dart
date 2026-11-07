import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/event_screen_options.dart';

void main() {
  group('EventScreenOptions', () {
    test('parses accurately from canonical Swagger response', () {
      final json = <String, dynamic>{
        'statuses': [
          {'code': 'OFF_DUTY', 'baseStatus': null},
          {'code': 'SLEEPER', 'baseStatus': null},
          {'code': 'DRIVING', 'baseStatus': null},
          {'code': 'ON_DUTY', 'baseStatus': null},
          {'code': 'PERSONAL_CONVEYANCE', 'baseStatus': 'DRIVING'},
          {'code': 'YARD_MOVE', 'baseStatus': 'ON_DUTY'},
        ],
        'vehicles': [
          {'id': 485, 'identifier': '485'},
          {'id': 502, 'identifier': 'Volvo VNL 860 #102'},
        ],
        'locationSources': [
          {'code': 'ELD_AUTO'},
          {'code': 'MANUAL'},
        ],
      };

      final options = EventScreenOptions.fromJson(json);

      expect(options.statuses.length, 6);
      expect(options.statuses[0].code, 'OFF_DUTY');
      expect(options.statuses[0].dutyStatusCode, DutyStatusCode.offDuty);
      expect(options.statuses[1].code, 'SLEEPER');
      expect(options.statuses[1].dutyStatusCode, DutyStatusCode.sleeperBerth);
      expect(options.statuses[4].code, 'PERSONAL_CONVEYANCE');
      expect(options.statuses[4].baseStatus, 'DRIVING');
      expect(
        options.statuses[4].dutyStatusCode,
        DutyStatusCode.personalConveyance,
      );
      expect(options.statuses[5].code, 'YARD_MOVE');
      expect(options.statuses[5].baseStatus, 'ON_DUTY');
      expect(options.statuses[5].dutyStatusCode, DutyStatusCode.yardMove);

      expect(options.vehicles.length, 2);
      expect(options.vehicles[0].id, 485);
      expect(options.vehicles[0].identifier, '485');
      expect(options.vehicles[1].id, 502);
      expect(options.vehicles[1].identifier, 'Volvo VNL 860 #102');

      expect(options.locationSources, ['ELD_AUTO', 'MANUAL']);
    });

    test('handles fallback when fields are null or empty gracefully', () {
      final options = EventScreenOptions.fromJson(const {});
      expect(options.statuses, isEmpty);
      expect(options.vehicles, isEmpty);
      expect(options.locationSources, isEmpty);
      expect(options.isStatusAllowed(DutyStatusCode.offDuty), isTrue);
    });

    test('standardFallback contains full 6 legal statuses', () {
      const fallback = EventScreenOptions.standardFallback;
      expect(fallback.statuses.length, 6);
      expect(fallback.isStatusAllowed(DutyStatusCode.offDuty), isTrue);
      expect(fallback.isStatusAllowed(DutyStatusCode.sleeperBerth), isTrue);
      expect(fallback.isStatusAllowed(DutyStatusCode.driving), isTrue);
      expect(fallback.isStatusAllowed(DutyStatusCode.onDutyNotDriving), isTrue);
      expect(fallback.isStatusAllowed(DutyStatusCode.personalConveyance), isTrue);
      expect(fallback.isStatusAllowed(DutyStatusCode.yardMove), isTrue);
      expect(fallback.locationSources, ['ELD_AUTO', 'MANUAL']);
    });

    test('EventOptionStatus and EventOptionVehicle serialization roundtrip', () {
      const status = EventOptionStatus(
        code: 'PERSONAL_CONVEYANCE',
        baseStatus: 'DRIVING',
      );
      expect(status.toJson(), {
        'code': 'PERSONAL_CONVEYANCE',
        'baseStatus': 'DRIVING',
      });
      expect(EventOptionStatus.fromJson(status.toJson()), status);

      const vehicle = EventOptionVehicle(id: 502, identifier: 'Volvo 860');
      expect(vehicle.toJson(), {'id': 502, 'identifier': 'Volvo 860'});
      expect(EventOptionVehicle.fromJson(vehicle.toJson()), vehicle);
    });
  });
}
