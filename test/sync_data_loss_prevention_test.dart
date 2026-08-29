import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/presentation/providers/sync_engine_provider.dart';

void main() {
  group('Sync Data Loss Prevention', () {
    test('FailClosedRemoteEventDispatcher should return ServerFailure in production', () async {
      // Arrange
      final dispatcher = FailClosedRemoteEventDispatcher();
      final event = PendingEvent(
        id: '123',
        type: 'test_event',
        payload: const {'data': 'test'},
        createdAt: DateTime.now(),
      );

      // Act
      final result = await dispatcher.dispatch(event);

      // Assert
      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<ServerFailure>());
          expect((failure as ServerFailure).message, contains('Production dispatcher not implemented yet'));
        },
        (_) => fail('Should not return success in production'),
      );
    });

    test('RetryPolicy calculateNextRetry should cap at max delay, not return null, to prevent deletion', () {
      final policy = const RetryPolicy(maxRetries: 5, baseDelay: Duration(seconds: 5), backoffFactor: 2.0);
      
      // Act
      final nextRetry = policy.calculateNextRetry(5);
      
      // Assert
      expect(nextRetry, isNotNull);
      // 5 * (2.0 * 5) = 50 seconds delay
      final difference = nextRetry!.difference(DateTime.now()).inSeconds;
      expect(difference, closeTo(50, 1));
    });
  });
}
