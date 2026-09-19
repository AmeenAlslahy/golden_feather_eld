import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/domain/hardware/telemetry_reading.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

void main() {
  group('TelemetryReading', () {
    test('constructs with required fields only', () {
      const reading = TelemetryReading(
        driverId: DriverId(101),
        speedMps: 20.0,
      );
      expect(reading.driverId.value, 101);
      expect(reading.speedMps, 20.0);
      expect(reading.rpm, isNull);
      expect(reading.odometerMiles, isNull);
      expect(reading.engineHours, isNull);
      expect(reading.engineOn, isNull);
    });

    test('constructs with all fields', () {
      const reading = TelemetryReading(
        driverId: DriverId(101),
        speedMps: 20.0,
        rpm: 1500,
        odometerMiles: 12450.5,
        engineHours: 1245.3,
        engineOn: true,
      );
      expect(reading.rpm, 1500);
      expect(reading.odometerMiles, 12450.5);
      expect(reading.engineHours, 1245.3);
      expect(reading.engineOn, isTrue);
    });

    test('equality', () {
      const a = TelemetryReading(driverId: DriverId(101), speedMps: 20.0);
      const b = TelemetryReading(driverId: DriverId(101), speedMps: 20.0);
      expect(a, equals(b));
    });

    test('copyWith preserves fields', () {
      const a = TelemetryReading(
        driverId: DriverId(101),
        speedMps: 20.0,
        rpm: 1500,
      );
      final b = a.copyWith(speedMps: 30.0);
      expect(b.speedMps, 30.0);
      expect(b.rpm, 1500);
      expect(b.driverId, a.driverId);
    });
  });
}
