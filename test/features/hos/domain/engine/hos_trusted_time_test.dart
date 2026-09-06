import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_calculator.dart';

void main() {
  group('HosCalculator with TrustedTimeProvider', () {
    test('calculateShiftLimit relies on TrustedTimeProvider, not DateTime.now', () {
      // 1. Setup fake provider
      final initialTime = DateTime.utc(2026, 1, 1, 8, 0); // 8:00 AM UTC
      final fakeProvider = FakeTrustedTimeProvider(
        initialUtcTime: initialTime,
      );
      
      final config = HosConfiguration.usa70_8();
      final calculator = HosCalculator(config, fakeProvider);
      
      // 2. Start shift at 8:00 AM
      final shiftStartTime = (fakeProvider.currentTime as TrustedTimeAvailable).utc;
      
      // 3. Advance fake provider by 2 hours
      fakeProvider.advance(const Duration(hours: 2));
      
      // 4. Calculate shift limit
      final shiftLimitResult = calculator.calculateShiftLimit(shiftStartTime);
      
      expect(shiftLimitResult, isA<ShiftLimitSuccess>());
      final shiftLimit = (shiftLimitResult as ShiftLimitSuccess).remainingMinutes;
      
      // Shift limit is 14 hours (840 minutes)
      // Elapsed is 2 hours (120 minutes)
      // Remaining should be 720 minutes
      expect(shiftLimit, equals(720));
      
      // 5. Advance by another 12 hours (Total 14 hours elapsed)
      fakeProvider.advance(const Duration(hours: 12));
      
      final finalShiftLimitResult = calculator.calculateShiftLimit(shiftStartTime);
      
      expect(finalShiftLimitResult, isA<ShiftLimitSuccess>());
      final finalShiftLimit = (finalShiftLimitResult as ShiftLimitSuccess).remainingMinutes;
      
      // Remaining should be 0
      expect(finalShiftLimit, equals(0));
    });
  });
}
