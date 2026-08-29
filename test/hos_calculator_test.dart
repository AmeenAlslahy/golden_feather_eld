import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/engine/hos_calculator.dart';

void main() {
  group('HOS Calculator Tests', () {
    test('calculateDriveLimit should return remaining minutes', () {
      final calculator = HosCalculator();
      final remaining = calculator.calculateDriveLimit(10.0); // 10 hours driven
      
      // 11 hours max - 10 hours = 1 hour = 60 minutes
      expect(remaining, 60);
    });

    test('calculateShiftLimit should return remaining minutes', () {
      final calculator = HosCalculator();
      final now = DateTime.now();
      final shiftStart = now.subtract(const Duration(hours: 10)); // 10 hours elapsed
      
      final remaining = calculator.calculateShiftLimit(shiftStart);
      
      // 14 hours max - 10 hours = 4 hours = 240 minutes
      expect(remaining, 240);
    });

    test('calculateAllLimits should return correct HosLimits', () {
      final calculator = HosCalculator();
      final now = DateTime.now();
      final shiftStart = now.subtract(const Duration(hours: 10));
      
      final limits = calculator.calculateAllLimits(
        drivingHours: 9.0, // 9 hours driven
        shiftStartTime: shiftStart,
        cycleHours: 50.0,
      );

      expect(limits.remainingDriveMinutes, 120); // 11 - 9 = 2h
      expect(limits.remainingShiftMinutes, 240); // 14 - 10 = 4h
      expect(limits.remainingCycleHours, 20.0);  // 70 - 50 = 20h
      expect(limits.breakRequired, true);        // >= 8 hours
    });

    test('setCycleRule should change max cycle hours', () {
      HosCalculator.setCycleRule('USA 60/7');
      expect(HosCalculator.activeMaxCycleHours, 60);

      HosCalculator.setCycleRule('Canada 70/7');
      expect(HosCalculator.activeMaxCycleHours, 70);
    });
  });
}
