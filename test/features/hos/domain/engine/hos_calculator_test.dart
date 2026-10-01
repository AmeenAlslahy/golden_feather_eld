import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_calculator.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';

void main() {
  late HosCalculator calculator;

  setUp(() {
    calculator = HosCalculator(HosConfiguration.usa70_8(), FakeTrustedTimeProvider());
  });

  test('34:00 exactly (true)', () {
    final start = DateTime.utc(2023, 1, 1, 0, 0);
    final end = start.add(const Duration(hours: 34));
    expect(calculator.hasWeeklyRestart([(start: start, end: end)]), isTrue);
  });

  test('33:59 (false)', () {
    final start = DateTime.utc(2023, 1, 1, 0, 0);
    final end = start.add(const Duration(hours: 33, minutes: 59));
    expect(calculator.hasWeeklyRestart([(start: start, end: end)]), isFalse);
  });

  test('Two periods split by driving (false)', () {
    final start1 = DateTime.utc(2023, 1, 1, 0, 0);
    final end1 = start1.add(const Duration(hours: 20));
    final start2 = end1.add(const Duration(hours: 2)); // 2 hours driving
    final end2 = start2.add(const Duration(hours: 15));
    expect(calculator.hasWeeklyRestart([(start: start1, end: end1), (start: start2, end: end2)]), isFalse);
  });

  test('Longer period (true)', () {
    final start = DateTime.utc(2023, 1, 1, 0, 0);
    final end = start.add(const Duration(hours: 48));
    expect(calculator.hasWeeklyRestart([(start: start, end: end)]), isTrue);
  });
}
