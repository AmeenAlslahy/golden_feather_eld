import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';

void main() {
  group('TrustedTimeProvider', () {
    test('MonotonicTrustedTimeProvider calculates elapsed time independently of system clock', () async {
      final provider = MonotonicTrustedTimeProvider();
      
      final serverTime = DateTime.utc(2026, 1, 1, 10, 0, 0);
      provider.anchor(serverTime);
      
      expect(provider.state == TrustedTimeState.trusted, isTrue);
      
      // Wait for a short duration
      await Future.delayed(const Duration(milliseconds: 50));
      
      final timeResult = provider.currentTime;
      expect(timeResult, isA<TrustedTimeAvailable>());
      if (timeResult is TrustedTimeAvailable) {
        final currentUtc = timeResult.utc;
        expect(currentUtc.isAfter(serverTime), isTrue);
      }
    });

    test('FakeTrustedTimeProvider allows manual manipulation', () {
      final initialTime = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final fakeProvider = FakeTrustedTimeProvider(initialUtcTime: initialTime);
      
      final result1 = fakeProvider.currentTime;
      expect(result1, isA<TrustedTimeAvailable>());
      if (result1 is TrustedTimeAvailable) {
        expect(result1.utc, equals(initialTime));
      }
      
      fakeProvider.advance(const Duration(hours: 2));
      
      final result2 = fakeProvider.currentTime;
      expect(result2, isA<TrustedTimeAvailable>());
      if (result2 is TrustedTimeAvailable) {
        expect(result2.utc, equals(initialTime.add(const Duration(hours: 2))));
      }
    });
  });
}
