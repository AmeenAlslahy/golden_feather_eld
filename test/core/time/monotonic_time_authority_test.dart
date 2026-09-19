import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/time/monotonic_time_authority.dart';
import 'package:golden_feather_eld/core/time/time_authority.dart';

void main() {
  group('MonotonicTimeAuthority', () {
    test('trustLevel is untrusted before initialize', () {
      final authority = MonotonicTimeAuthority();
      expect(authority.trustLevel, TrustLevel.untrusted);
    });

    test('nowUtc returns a UTC DateTime even before initialize', () {
      final authority = MonotonicTimeAuthority();
      final now = authority.nowUtc();
      expect(now.isUtc, isTrue);
    });

    test('trustLevel is localDevice after initialize', () async {
      final authority = MonotonicTimeAuthority();
      await authority.initialize();
      expect(authority.trustLevel, TrustLevel.localDevice);
    });

    test('initialize is idempotent', () async {
      final authority = MonotonicTimeAuthority();
      await authority.initialize();
      final first = authority.nowUtc();
      await authority.initialize();
      final second = authority.nowUtc();
      // Time should advance slightly, not reset.
      expect(second.isBefore(first), isFalse);
    });

    test('nowUtc advances after initialize', () async {
      final authority = MonotonicTimeAuthority();
      await authority.initialize();
      final before = authority.nowUtc();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      final after = authority.nowUtc();
      expect(after.isAfter(before), isTrue);
    });

    test('nowUtc returns isUtc', () async {
      final authority = MonotonicTimeAuthority();
      await authority.initialize();
      expect(authority.nowUtc().isUtc, isTrue);
    });

    test('monotonicElapsed is zero before initialize', () {
      final authority = MonotonicTimeAuthority();
      expect(authority.monotonicElapsed, Duration.zero);
    });

    test('monotonicElapsed advances after initialize', () async {
      final authority = MonotonicTimeAuthority();
      await authority.initialize();
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(authority.monotonicElapsed, greaterThan(Duration.zero));
    });

    test('resync re-anchors to current device time', () async {
      final authority = MonotonicTimeAuthority();
      await authority.initialize();
      final result = await authority.resync();
      expect(result, isTrue);
      expect(authority.trustLevel, TrustLevel.localDevice);
    });
  });
}
