import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/codriver/domain/current_codriver.dart';
import 'package:golden_feather_eld/features/codriver/domain/role_switch_guard.dart';

void main() {
  test('unknown speed is not treated as stopped', () {
    expect(
      refuseRoleSwitch(
        currentDriverId: 101,
        coDriverId: '102',
        speedMps: null,
        thresholdKmh: 8,
        currentStatusIsDriving: false,
        trackingLive: true,
      ),
      RoleSwitchRefusal.motionUnknown,
    );
  });

  test('moving at or above the threshold is refused', () {
    expect(
      refuseRoleSwitch(
        currentDriverId: 101,
        coDriverId: '102',
        speedMps: 8 / 3.6,
        thresholdKmh: 8,
        currentStatusIsDriving: false,
        trackingLive: true,
      ),
      RoleSwitchRefusal.vehicleMoving,
    );
  });

  test('a stopped different driver can be offered to the server', () {
    expect(
      refuseRoleSwitch(
        currentDriverId: 101,
        coDriverId: '102',
        speedMps: 0,
        thresholdKmh: 8,
        currentStatusIsDriving: false,
        trackingLive: true,
      ),
      isNull,
    );
  });

  test('the current driver cannot switch to the same account', () {
    expect(
      refuseRoleSwitch(
        currentDriverId: 101,
        coDriverId: '101',
        speedMps: 0,
        thresholdKmh: 8,
        currentStatusIsDriving: false,
        trackingLive: true,
      ),
      RoleSwitchRefusal.sameDriver,
    );
  });

  test('driving status is refused without changing it', () {
    expect(
      refuseRoleSwitch(
        currentDriverId: 101,
        coDriverId: '102',
        speedMps: 0,
        thresholdKmh: 8,
        currentStatusIsDriving: true,
        trackingLive: true,
      ),
      RoleSwitchRefusal.stillDriving,
    );
  });

  test('tracking off: unknown speed does not refuse — no driving evidence', () {
    expect(
      refuseRoleSwitch(
        currentDriverId: 101,
        coDriverId: '102',
        speedMps: null,
        thresholdKmh: 8,
        currentStatusIsDriving: false,
        trackingLive: false,
      ),
      isNull,
    );
  });

  test('tracking off: stale high speed does not refuse either', () {
    expect(
      refuseRoleSwitch(
        currentDriverId: 101,
        coDriverId: '102',
        speedMps: 30,
        thresholdKmh: 8,
        currentStatusIsDriving: false,
        trackingLive: false,
      ),
      isNull,
    );
  });

  test(
    'coDriverId 0 is an empty link, and a session id is not a co-driver',
    () {
      expect(
        parseCurrentCoDriver({
          'id': 9,
          'coDriverId': 0,
          'teamDrivingActive': false,
        })?.isLinked,
        isFalse,
      );
      expect(parseCurrentCoDriver(['102']), isNull);
      expect(
        parseCurrentCoDriver({
          'coDriver': {'id': 102, 'name': 'Sam'},
        })?.coDriverId,
        102,
      );
    },
  );
}
