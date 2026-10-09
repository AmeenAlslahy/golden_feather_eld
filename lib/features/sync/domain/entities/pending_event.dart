import 'package:equatable/equatable.dart';

enum SyncPriority { high, normal, low }

class PendingEvent extends Equatable {
  final String id;
  final String type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final SyncPriority priority;
  final int retryCount;
  final DateTime? nextRetryAt;

  const PendingEvent({
    required this.id,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.priority = SyncPriority.normal,
    this.retryCount = 0,
    this.nextRetryAt,
  });

  PendingEvent copyWith({
    int? retryCount,
    DateTime? nextRetryAt,
  }) {
    return PendingEvent(
      id: id,
      type: type,
      payload: payload,
      createdAt: createdAt,
      priority: priority,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
    );
  }

  @override
  List<Object?> get props =>
      [id, type, createdAt, priority, retryCount, nextRetryAt];
}

class RetryPolicy {
  final int maxRetries;
  final Duration baseDelay;
  final double backoffFactor;

  const RetryPolicy({
    this.maxRetries = 5,
    this.baseDelay = const Duration(seconds: 5),
    this.backoffFactor = 2.0,
  });

  /// Calculates the next retry timestamp.
  ///
  /// **Requires** an explicit `nowUtc` — no implicit `DateTime.now()`.
  /// The caller (SyncEngine) provides this from `TimeAuthority` to
  /// ensure retries are not affected by device clock changes.
  DateTime? calculateNextRetry(
    int currentRetries, {
    required DateTime nowUtc,
  }) {
    // FMCSA: Never drop HOS data, cap at max retries delay and keep retrying.
    final effectiveRetries = currentRetries >= maxRetries ? maxRetries : (currentRetries + 1);
    
    // Linear backoff: base × factor × (effectiveRetries) — locked by pending_event_test.
    final delaySeconds =
        baseDelay.inSeconds * (backoffFactor * effectiveRetries);
    return nowUtc.add(Duration(seconds: delaySeconds.toInt()));
  }
}
