import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';

void main() {
  group('Sync Data Loss Prevention', () {
    test(
        'RetryPolicy calculateNextRetry should cap at max delay, not return null, to prevent deletion',
        () {
      const policy = RetryPolicy(
          maxRetries: 5, baseDelay: Duration(seconds: 5), backoffFactor: 2.0);

      // Act
      final nextRetry = policy.calculateNextRetry(5, nowUtc: DateTime.utc(2026, 1, 15, 10));

      // Assert
      expect(nextRetry, isNotNull);
      // 5 * (2.0 * 5) = 50 seconds delay
      final difference = nextRetry!.difference(DateTime.utc(2026, 1, 15, 10)).inSeconds;
      expect(difference, closeTo(50, 1));
    });
  });
}
