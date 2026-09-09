import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/pending_event.dart';
import '../repositories/offline_queue.dart';

/// واجهة الإرسال الفعلي للبيانات لضمان عزل الـ Sync عن Traccar
abstract class RemoteEventDispatcher {
  /// إرسال الحدث إلى الخادم (بدون المعرفة بتفاصيل الاتصال)
  Future<Either<Failure, bool>> dispatch(PendingEvent event);
}

class SyncEngine {
  final OfflineQueue _queue;
  final RemoteEventDispatcher _dispatcher;
  final RetryPolicy _retryPolicy;

  bool _isSyncing = false;

  SyncEngine({
    required OfflineQueue queue,
    required RemoteEventDispatcher dispatcher,
    RetryPolicy? retryPolicy,
  })  : _queue = queue,
        _dispatcher = dispatcher,
        _retryPolicy = retryPolicy ?? const RetryPolicy();

  /// إرسال حدث جديد
  Future<void> submitEvent(PendingEvent event) async {
    await _queue.enqueue(event);
    await triggerSync();
  }

  /// تشغيل المزامنة للأحداث المعلقة (تُستدعى يدوياً أو تلقائياً عند عودة الاتصال)
  Future<void> triggerSync() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      bool hasMore = true;
      while (hasMore) {
        final readyEvents = await _queue.getReadyEvents(limit: 10);

        if (readyEvents.isEmpty) {
          hasMore = false;
          break;
        }

        for (final event in readyEvents) {
          final result = await _dispatcher.dispatch(event);

          await result.match(
            (failure) async {
              // Failure State: فشل الإرسال
              final nextRetry =
                  _retryPolicy.calculateNextRetry(event.retryCount);
              if (nextRetry != null) {
                // جدولة المحاولة القادمة (Exponential Backoff)
                final updatedEvent = event.copyWith(
                  retryCount: event.retryCount + 1,
                  nextRetryAt: nextRetry,
                );
                await _queue.updateEvent(updatedEvent);
              } else {
                // إذا كنا هنا فهذا يعني وجود عطل خطير في سياسة الإعادة
                // لا نحذف الحدث منعاً لفقدان البيانات
              }
            },
            (_) async {
              // Success (Acknowledgement): نجاح الإرسال، نزيل الحدث من الطابور
              await _queue.removeEvent(event.id);
            },
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
  }
}
