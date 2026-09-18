import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';

void main() {
  group('Value objects — equality', () {
    test('same value → equal', () {
      expect(const UserId(1), equals(const UserId(1)));
    });

    test('different values → not equal', () {
      expect(const UserId(1), isNot(equals(const UserId(2))));
    });

    test('different types with same value → not equal', () {
      // This is the key benefit: type safety at compile time.
      expect(const UserId(1), isNot(equals(const DriverId(1))));
    });
  });

  group('Value objects — all types constructible', () {
    test('every ID type works', () {
      expect(const UserId(1).value, 1);
      expect(const DriverId(2).value, 2);
      expect(const DeviceId(3).value, 3);
      expect(const VehicleId(4).value, 4);
      expect(const DailyLogId(5).value, 5);
      expect(const DutyStatusId(6).value, 6);
      expect(const DvirId(7).value, 7);
      expect(const InspectionId(8).value, 8);
      expect(const DocumentId(9).value, 9);
      expect(const TransferId(10).value, 10);
      expect(const RuleId(11).value, 11);
      expect(const EditId('abc').value, 'abc');
    });
  });

  group('Value objects — hashCode', () {
    test('same value → same hashCode', () {
      expect(
        const UserId(1).hashCode,
        equals(const UserId(1).hashCode),
      );
    });
  });
}
