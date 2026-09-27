import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';

void main() {
  const defaultPolicy = RetryPolicy(
    maxRetries: 5,
    baseDelay: Duration(seconds: 5),
    backoffFactor: 2.0,
  );

  final fixedNow = DateTime.utc(2026, 1, 15, 10);

  group('RetryPolicy.calculateNextRetry', () {
    test('returns non-null DateTime based on nowUtc', () {
      final result = defaultPolicy.calculateNextRetry(
        0,
        nowUtc: fixedNow,
      );
      expect(result, isNotNull);
      expect(result!.isUtc, isTrue);
    });

    test('advances by baseDelay * backoffFactor * (retries+1)', () {
      // retries = 0 -> 5 * 2 * 1 = 10s
      final result = defaultPolicy.calculateNextRetry(
        0,
        nowUtc: fixedNow,
      );
      expect(
        result,
        fixedNow.add(const Duration(seconds: 10)),
      );
    });

    test('grows linearly with retries', () {
      // retries = 1 -> 5 * 2 * 2 = 20s
      final result = defaultPolicy.calculateNextRetry(
        1,
        nowUtc: fixedNow,
      );
      expect(
        result,
        fixedNow.add(const Duration(seconds: 20)),
      );
    });

    test('retries = 4 -> 5 * 2 * 5 = 50s', () {
      final result = defaultPolicy.calculateNextRetry(
        4,
        nowUtc: fixedNow,
      );
      expect(
        result,
        fixedNow.add(const Duration(seconds: 50)),
      );
    });

    test('beyond maxRetries -> maxDelaySeconds', () {
      // maxDelaySeconds = 5 * 2 * 5 = 50s
      final result = defaultPolicy.calculateNextRetry(
        5,
        nowUtc: fixedNow,
      );
      expect(
        result,
        fixedNow.add(const Duration(seconds: 50)),
      );
    });

    test('result depends only on nowUtc, not system clock', () {
      // Same nowUtc -> same result regardless of when called.
      final first = defaultPolicy.calculateNextRetry(2, nowUtc: fixedNow);
      final second = defaultPolicy.calculateNextRetry(2, nowUtc: fixedNow);
      expect(first, equals(second));
    });

    test('different nowUtc yields different result', () {
      final laterNow = fixedNow.add(const Duration(hours: 1));
      final first = defaultPolicy.calculateNextRetry(2, nowUtc: fixedNow);
      final second = defaultPolicy.calculateNextRetry(2, nowUtc: laterNow);
      expect(first, isNot(equals(second)));
    });
  });
}
