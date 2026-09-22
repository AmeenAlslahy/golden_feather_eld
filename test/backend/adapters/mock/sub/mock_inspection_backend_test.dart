import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/sub/mock_inspection_backend.dart';
import 'package:golden_feather_eld/core/domain/shared/value_objects.dart';

void main() {
  group('MockInspectionBackend', () {
    late MockInspectionBackend backend;

    setUp(() {
      backend = MockInspectionBackend();
    });

    test('getScreen returns valid data', () async {
      final result = await backend.getScreen(driverId: const DriverId(101));
      result.fold(
        (l) => fail('Expected right'),
        (r) {
          expect(r.driverId.value, 101);
          expect(r.carrierName, 'Golden Feather Transport');
        },
      );
    });

    test('getCycle returns correct number of days', () async {
      final result = await backend.getCycle(driverId: const DriverId(101), days: 8);
      result.fold(
        (l) => fail('Expected right'),
        (r) {
          expect(r.length, 8);
          expect(r.first.displayLocation, 'Riyadh');
        },
      );
    });

    test('getLogs returns single log with events', () async {
      final result = await backend.getLogs(driverId: const DriverId(101));
      result.fold(
        (l) => fail('Expected right'),
        (r) {
          expect(r.displayLocation, 'Riyadh');
          expect(r.events.isNotEmpty, isTrue);
        },
      );
    });
  });
}
