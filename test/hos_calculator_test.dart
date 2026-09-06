import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_calculator.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';

void main() {
  group('HOS Calculator Tests', () {
    test('calculateDriveLimit should return remaining minutes', () {
      final config = HosConfiguration.usa70_8();
      final now = DateTime.now();
      final calculator = HosCalculator(config, FakeTrustedTimeProvider(initialUtcTime: now.toUtc()));
      final result = calculator.calculateAllLimits(
        drivingHours: 10.0,
        shiftStartTime: now,
        cycleHours: 0.0,
      );
      
      expect(result, isA<CalculationSuccess>());
      final remaining = (result as CalculationSuccess).limits.remainingDriveMinutes;
      
      // 11 hours max - 10 hours = 1 hour = 60 minutes
      expect(remaining, 60);
    });

    test('calculateShiftLimit should return remaining minutes', () {
      final config = HosConfiguration.usa70_8();
      final now = DateTime.now();
      final calculator = HosCalculator(config, FakeTrustedTimeProvider(initialUtcTime: now.toUtc()));
      final shiftStart = now.subtract(const Duration(hours: 10)); // 10 hours elapsed
      
      final result = calculator.calculateAllLimits(
        drivingHours: 0.0,
        shiftStartTime: shiftStart,
        cycleHours: 0.0,
      );
      
      expect(result, isA<CalculationSuccess>());
      final remaining = (result as CalculationSuccess).limits.remainingShiftMinutes;
      
      // 14 hours max - 10 hours = 4 hours = 240 minutes
      expect(remaining, 240);
    });

    test('calculateAllLimits should return correct HosLimits', () {
      final config = HosConfiguration.usa70_8();
      final now = DateTime.now();
      final calculator = HosCalculator(config, FakeTrustedTimeProvider(initialUtcTime: now.toUtc()));
      final shiftStart = now.subtract(const Duration(hours: 10));
      
      final result = calculator.calculateAllLimits(
        drivingHours: 9.0, // 9 hours driven
        shiftStartTime: shiftStart,
        cycleHours: 50.0,
      );
      
      expect(result, isA<CalculationSuccess>());
      final limits = (result as CalculationSuccess).limits;

      expect(limits.remainingDriveMinutes, 120); // 11 - 9 = 2h
      expect(limits.remainingShiftMinutes, 240); // 14 - 10 = 4h
      expect(limits.remainingCycleHours, 20.0);  // 70 - 50 = 20h
      expect(limits.breakRequired, true);        // >= 8 hours
    });

    test('different config should change cycle limits', () {
      final config60 = HosConfiguration.usa60_7();
      final now = DateTime.now();
      final calculator = HosCalculator(config60, FakeTrustedTimeProvider(initialUtcTime: now.toUtc()));
      
      final result = calculator.calculateAllLimits(
        drivingHours: 0.0,
        shiftStartTime: now,
        cycleHours: 50.0,
      );
      
      expect(result, isA<CalculationSuccess>());
      final limits = (result as CalculationSuccess).limits;
      
      // 60 - 50 = 10h remaining
      expect(limits.remainingCycleHours, 10.0);
    });
  });
}
