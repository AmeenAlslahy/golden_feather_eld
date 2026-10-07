import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/utils/id_generator.dart';

class MockIdGenerator implements IdGenerator {
  @override
  String v4() => 'test-id-1';
}

void main() {
  group('IdGenerator', () {
    test('Mock returns test-id-1', () {
      final generator = MockIdGenerator();
      expect(generator.v4(), 'test-id-1');
    });

    test('UuidIdGenerator returns valid UUID', () {
      const generator = UuidIdGenerator();
      final id = generator.v4();
      expect(id.isNotEmpty, true);
      // Basic UUID length check (36 chars with hyphens)
      expect(id.length, 36);
    });
  });
}
