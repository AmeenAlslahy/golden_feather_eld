import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_hardware_backend.dart';
import 'package:golden_feather_eld/domain/hardware/telemetry_reading.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

void main() {
  late MockHardwareBackend backend;

  setUp(() => backend = MockHardwareBackend());

  group('MockHardwareBackend.sendTelemetry', () {
    test('returns success', () async {
      const reading = TelemetryReading(
        driverId: DriverId(101),
        speedMps: 10.0,
      );
      final result = await backend.sendTelemetry(reading);
      expect(result.isRight(), isTrue);
    });

    test('records reading in sentTelemetry', () async {
      const reading = TelemetryReading(
        driverId: DriverId(101),
        speedMps: 10.0,
      );
      await backend.sendTelemetry(reading);
      expect(backend.sentTelemetry, hasLength(1));
      expect(backend.sentTelemetry.first, reading);
    });

    test('accumulates multiple readings', () async {
      await backend.sendTelemetry(
        const TelemetryReading(driverId: DriverId(101), speedMps: 5.0),
      );
      await backend.sendTelemetry(
        const TelemetryReading(driverId: DriverId(101), speedMps: 10.0),
      );
      expect(backend.sentTelemetry, hasLength(2));
    });

    test('clearTelemetry removes all', () async {
      await backend.sendTelemetry(
        const TelemetryReading(driverId: DriverId(101), speedMps: 5.0),
      );
      backend.clearTelemetry();
      expect(backend.sentTelemetry, isEmpty);
    });

    test('sentTelemetry returns unmodifiable list', () async {
      await backend.sendTelemetry(
        const TelemetryReading(driverId: DriverId(101), speedMps: 5.0),
      );
      expect(
        () => backend.sentTelemetry.add(
          const TelemetryReading(driverId: DriverId(1), speedMps: 0),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
