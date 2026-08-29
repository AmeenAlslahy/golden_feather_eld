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
  List<Object?> get props => [id, type, createdAt, priority, retryCount, nextRetryAt];
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

  DateTime? calculateNextRetry(int currentRetries) {
    if (currentRetries >= maxRetries) {
      // بدلاً من إيقاف الإعادة وحذف الحدث، نثبت التأخير عند الحد الأقصى للمحاولات
      final maxDelaySeconds = baseDelay.inSeconds * (backoffFactor * maxRetries);
      return DateTime.now().add(Duration(seconds: maxDelaySeconds.toInt()));
    }
    
    // Exponential backoff
    final delaySeconds = baseDelay.inSeconds * (backoffFactor * (currentRetries + 1));
    return DateTime.now().add(Duration(seconds: delaySeconds.toInt()));
  }
}
