import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/mappers/hardware_mapper.dart';
import 'package:golden_feather_eld/core/domain/hardware/telemetry_reading.dart';
import 'package:golden_feather_eld/core/domain/shared/value_objects.dart';

void main() {
  const driverId = DriverId(101);

  group('HardwareMapper.telemetryToJson', () {
    test('includes driverId and speed (converted to MPH)', () {
      const reading = TelemetryReading(
        driverId: driverId,
        speedMps: 10.0,
      );
      final json = HardwareMapper.telemetryToJson(reading);
      expect(json['driverId'], 101);
      // 10 m/s = 22.3694 mph
      expect(json['speed'], closeTo(22.3694, 0.001));
    });

    test('omits nullable fields when null', () {
      const reading = TelemetryReading(
        driverId: driverId,
        speedMps: 5.0,
      );
      final json = HardwareMapper.telemetryToJson(reading);
      expect(json.containsKey('rpm'), isFalse);
      expect(json.containsKey('odometer'), isFalse);
      expect(json.containsKey('engineHours'), isFalse);
      expect(json.containsKey('engineOn'), isFalse);
    });

    test('includes nullable fields when provided', () {
      const reading = TelemetryReading(
        driverId: driverId,
        speedMps: 5.0,
        rpm: 1500,
        odometerMiles: 12450.5,
        engineHours: 1245.3,
        engineOn: true,
      );
      final json = HardwareMapper.telemetryToJson(reading);
      expect(json['rpm'], 1500);
      expect(json['odometer'], 12450.5);
      expect(json['engineHours'], 1245.3);
      expect(json['engineOn'], isTrue);
    });

    test('converts negative speed correctly', () {
      const reading = TelemetryReading(
        driverId: driverId,
        speedMps: -5.0,
      );
      final json = HardwareMapper.telemetryToJson(reading);
      expect(json['speed'], closeTo(-11.1847, 0.001));
    });

    test('zero speed stays zero', () {
      const reading = TelemetryReading(
        driverId: driverId,
        speedMps: 0.0,
      );
      final json = HardwareMapper.telemetryToJson(reading);
      expect(json['speed'], 0.0);
    });
  });
}
