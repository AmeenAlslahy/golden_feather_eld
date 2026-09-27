import 'package:flutter_test/flutter_test.dart';
import '../../helpers/fake_time_authority.dart';
import 'package:golden_feather_eld/core/time/time_authority.dart';

void main() {
  group('FakeTimeAuthority — defaults', () {
    test('default trust is serverSynced', () {
      expect(FakeTimeAuthority().trustLevel, TrustLevel.serverSynced);
    });

    test('default time is 2026-01-15 10:00 UTC', () {
      final authority = FakeTimeAuthority();
      expect(authority.nowUtc(), DateTime.utc(2026, 1, 15, 10));
    });

    test('default monotonicElapsed is zero', () {
      expect(FakeTimeAuthority().monotonicElapsed, Duration.zero);
    });

    test('accepts custom initialTime', () {
      final authority = FakeTimeAuthority(
        initialTime: DateTime.utc(2025, 6, 1),
      );
      expect(authority.nowUtc(), DateTime.utc(2025, 6, 1));
    });

    test('accepts custom initialTrust', () {
      final authority = FakeTimeAuthority(
        initialTrust: TrustLevel.localDevice,
      );
      expect(authority.trustLevel, TrustLevel.localDevice);
    });
  });

  group('FakeTimeAuthority — advance', () {
    test('advances time and monotonic clock', () {
      final authority = FakeTimeAuthority();
      authority.advance(const Duration(hours: 1));
      expect(
        authority.nowUtc(),
        DateTime.utc(2026, 1, 15, 11),
      );
      expect(authority.monotonicElapsed, const Duration(hours: 1));
    });

    test('multiple advances accumulate', () {
      final authority = FakeTimeAuthority();
      authority.advance(const Duration(minutes: 30));
      authority.advance(const Duration(minutes: 45));
      expect(
        authority.nowUtc(),
        DateTime.utc(2026, 1, 15, 11, 15),
      );
      expect(authority.monotonicElapsed, const Duration(minutes: 75));
    });
  });

  group('FakeTimeAuthority — setTime', () {
    test('changes wall clock without affecting monotonic', () {
      final authority = FakeTimeAuthority();
      authority.advance(const Duration(hours: 1));
      authority.setTime(DateTime.utc(2024, 1, 1));
      expect(authority.nowUtc(), DateTime.utc(2024, 1, 1));
      expect(authority.monotonicElapsed, const Duration(hours: 1));
    });
  });

  group('FakeTimeAuthority — setTrustLevel', () {
    test('changes trust level', () {
      final authority = FakeTimeAuthority();
      authority.setTrustLevel(TrustLevel.untrusted);
      expect(authority.trustLevel, TrustLevel.untrusted);
    });
  });

  group('FakeTimeAuthority — initialize', () {
    test('initialize is idempotent', () async {
      final authority = FakeTimeAuthority();
      await authority.initialize();
      await authority.initialize();
      expect(authority.isInitialized, isTrue);
    });

    test('resync returns true', () async {
      final authority = FakeTimeAuthority();
      expect(await authority.resync(), isTrue);
    });
  });
}
