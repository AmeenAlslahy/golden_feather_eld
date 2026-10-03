import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/vehicle/domain/vehicle_selection.dart';

void main() {
  test('operable uniqueId is not invented from a numeric list id', () {
    expect(readOperableUniqueId(null), isNull);
    expect(readOperableUniqueId('No Vehicle'), isNull);
    expect(readOperableUniqueId('1001'), '1001');
  });

  test('unknown speed is not treated as stopped', () {
    expect(
      refuseVehicleOperate(speedMps: null, thresholdKmh: 8, uniqueId: '1001'),
      VehicleOperateRefusal.motionUnknown,
    );
  });

  test('a missing uniqueId is not invented from the numeric id', () {
    expect(
      refuseVehicleOperate(speedMps: 0, thresholdKmh: 8, uniqueId: null),
      VehicleOperateRefusal.identifierMissing,
    );
  });

  test('a stopped vehicle with an identifier can be offered to the server', () {
    expect(
      refuseVehicleOperate(speedMps: 0, thresholdKmh: 8, uniqueId: '1001'),
      isNull,
    );
  });

  test('an empty list is empty, and a body without a list is unreadable', () {
    expect(parseVehicleList([]), isEmpty);
    expect(parseVehicleList({'companyName': 'Carrier'}), isNull);
  });

  test(
    'a classification row does not become assigned or selected by default',
    () {
      final vehicles = parseVehicleList([
        {'vehicleId': 7, 'vehicleName': 'Truck', 'inUseByOtherDriver': true},
      ]);

      expect(vehicles, isNotNull);
      expect(vehicles!.single.uniqueId, isNull);
      expect(vehicles.single.isAssigned, isFalse);
      expect(vehicles.single.selectedByServer, isNull);
      expect(vehicles.single.inUseByOther, isTrue);
    },
  );

  test('company fleet browse does not operate an unassigned vehicle', () {
    final vehicles = parseVehicleList([
      {
        'vehicleId': 7,
        'vehicleName': 'Truck',
        'assignedToCurrentDriver': false,
      },
      {
        'uniqueId': '1001',
        'vehicleName': 'Mine',
        'assignedToCurrentDriver': true,
      },
    ]);
    expect(vehicles, isNotNull);
    expect(
      listedVehicleIsOperable(
        browsingCompanyFleet: true,
        vehicle: vehicles!.first,
      ),
      isFalse,
    );
    expect(
      listedVehicleIsOperable(
        browsingCompanyFleet: true,
        vehicle: vehicles.last,
      ),
      isTrue,
    );
    expect(
      listedVehicleIsOperable(
        browsingCompanyFleet: false,
        vehicle: vehicles.first,
      ),
      isTrue,
    );
  });

  test(
    'HTTP rejection names come from the status when the body has no sentence',
    () {
      expect(
        vehicleOperateFailure(code: 'permission.denied', statusCode: 403),
        'unauthorized',
      );
      expect(
        vehicleOperateFailure(code: 'conflict', statusCode: 409),
        'in_use',
      );
      expect(
        vehicleOperateFailure(
          code: 'x',
          statusCode: 403,
          serverMessage: 'Already in use',
        ),
        'Already in use',
      );
    },
  );
}
