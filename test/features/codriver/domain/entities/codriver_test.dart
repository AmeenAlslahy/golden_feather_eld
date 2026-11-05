import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/codriver/domain/entities/codriver.dart';

void main() {
  group('CoDriver entity and JSON deserialization', () {
    test('parses standard OpenAPI AvailableCoDriverResponse structure', () {
      final json = {
        'driver': {
          'id': 102,
          'name': 'أحمد خالد',
          'licenseNumber': 'DL-CA-449102',
        },
        'carrier': {
          'id': 1,
          'name': 'eld',
          'legalName': 'eld',
          'usdotNumber': '3892014',
        },
        'eligible': true,
      };

      final coDriver = CoDriver.fromJson(json);

      expect(coDriver.id, '102');
      expect(coDriver.name, 'أحمد خالد');
      expect(coDriver.licenseNumber, 'DL-CA-449102');
    });

    test('parses flat json structure with id and name', () {
      final json = {
        'id': '103',
        'name': 'عمر الخطيب',
        'licenseNumber': 'DL-FL-771920',
      };

      final coDriver = CoDriver.fromJson(json);

      expect(coDriver.id, '103');
      expect(coDriver.name, 'عمر الخطيب');
      expect(coDriver.licenseNumber, 'DL-FL-771920');
    });

    test('parses alternative fields (driverId, fullName, attributes.licenseNumber)', () {
      final json = {
        'driverId': 104,
        'fullName': 'سعيد علي',
        'attributes': {
          'licenseNumber': 'LIC-9999',
        },
      };

      final coDriver = CoDriver.fromJson(json);

      expect(coDriver.id, '104');
      expect(coDriver.name, 'سعيد علي');
      expect(coDriver.licenseNumber, 'LIC-9999');
    });

    test('falls back to Unknown for empty or null name', () {
      final json = {'id': 105};

      final coDriver = CoDriver.fromJson(json);

      expect(coDriver.id, '105');
      expect(coDriver.name, 'Unknown');
      expect(coDriver.licenseNumber, isNull);
    });

    test('toJson serializes correctly', () {
      const coDriver = CoDriver(
        id: '102',
        name: 'أحمد خالد',
        licenseNumber: 'DL-CA-449102',
      );

      final map = coDriver.toJson();

      expect(map['id'], '102');
      expect(map['name'], 'أحمد خالد');
      expect(map['licenseNumber'], 'DL-CA-449102');
    });

    test('equality and hashCode work as expected', () {
      const d1 = CoDriver(id: '102', name: 'أحمد', licenseNumber: 'L1');
      const d2 = CoDriver(id: '102', name: 'أحمد', licenseNumber: 'L1');
      const d3 = CoDriver(id: '103', name: 'أحمد', licenseNumber: 'L1');

      expect(d1, equals(d2));
      expect(d1.hashCode, equals(d2.hashCode));
      expect(d1, isNot(equals(d3)));
    });
  });
}
