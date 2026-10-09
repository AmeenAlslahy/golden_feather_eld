import 'dart:async';

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import 'package:golden_feather_eld/core/utils/logger.dart';
import '../entities/pending_event.dart';
import '../repositories/offline_queue.dart';

import '../../../../core/time/time_authority.dart';

/// واجهة الإرسال الفعلي للبيانات لضمان عزل الـ Sync عن Traccar
abstract class RemoteEventDispatcher {
  /// إرسال الحدث إلى الخادم (بدون المعرفة بتفاصيل الاتصال)
  Future<Either<Failure, bool>> dispatch(PendingEvent event);
}

class SyncEngine {
  final OfflineQueue _queue;
  final RemoteEventDispatcher _dispatcher;
  final RetryPolicy _retryPolicy;
  final TimeAuthority _timeAuthority;

  bool _isSyncing = false;
  bool _syncAgain = false;
  final Map<String, Completer<Either<Failure, bool>>> _reports = {};
  final List<Completer<void>> _idle = [];

  SyncEngine({
    required OfflineQueue queue,
    required RemoteEventDispatcher dispatcher,
    required TimeAuthority timeAuthority,
    RetryPolicy? retryPolicy,
  })  : _queue = queue,
        _dispatcher = dispatcher,
        _timeAuthority = timeAuthority,
        _retryPolicy = retryPolicy ?? const RetryPolicy();

  /// إرسال حدث جديد
  Future<void> submitEvent(PendingEvent event) async {
    await _queue.enqueue(event);
    await triggerSync();
  }

  /// Enqueue a stamped event and return this attempt's accept or reject.
  ///
  /// The caller must already have a trusted stamp. A rejection is removed
  /// from the queue so it cannot succeed later without the driver seeing it.
  Future<Either<Failure, bool>> submitEventAndReport(PendingEvent event) async {
    final report = Completer<Either<Failure, bool>>();
    _reports[event.id] = report;
    await _queue.enqueue(event);
    if (_isSyncing) {
      _syncAgain = true;
      final idle = Completer<void>();
      _idle.add(idle);
      if (!_isSyncing && !idle.isCompleted) {
        idle.complete();
      }
      await idle.future;
    }
    if (!report.isCompleted) {
      await triggerSync();
    }
    if (!report.isCompleted) {
      _completeReport(
        event.id,
        const Left(ServerFailure(message: 'Duty event was not sent')),
      );
    }
    final result = await report.future;
    // A shown rejection must not later succeed in the background.
    if (result.isLeft()) {
      await _queue.removeEvent(event.id);
    }
    return result;
  }

  /// تشغيل المزامنة للأحداث المعلقة (تُستدعى يدوياً أو تلقائياً عند عودة الاتصال)
  Future<void> triggerSync() async {
    if (_isSyncing) {
      _syncAgain = true;
      return;
    }
    _isSyncing = true;

    try {
      while (true) {
        _syncAgain = false;
        var hasMore = true;
        while (hasMore) {
          final readyEvents = await _queue.getReadyEvents(limit: 10);

          if (readyEvents.isEmpty) {
            hasMore = false;
            break;
          }

          for (final event in readyEvents) {
            Either<Failure, bool> result;
            try {
              result = await _dispatcher.dispatch(event);
            } catch (e) {
              result = Left(ServerFailure(message: 'Failed to dispatch event: $e'));
            }
            await _settle(event, result);
            _completeReport(event.id, result);
          }
        }
        if (!_syncAgain) break;
      }
    } finally {
      _isSyncing = false;
      final idle = List<Completer<void>>.of(_idle);
      _idle.clear();
      for (final waiter in idle) {
        if (!waiter.isCompleted) waiter.complete();
      }
    }
  }

  Future<void> _settle(
    PendingEvent event,
    Either<Failure, bool> result,
  ) async {
    await result.match(
      (failure) async {
        // أخطاء 4xx من الخادم (مثل duplicate key أو bad request) دائمة ولن تُحَل
        // بإعادة المحاولة — احذف الحدث فوراً حتى لا يتكرر الإرسال إلى الأبد.
        final statusCode = failure.statusCode;
        final isPermanentClientError =
            statusCode != null && statusCode >= 400 && statusCode < 500;
        if (isPermanentClientError) {
          AppLogger.warning(
            'SyncEngine: dropping event ${event.id} (type=${event.type}) '
            'after permanent server rejection HTTP $statusCode.',
          );
          await _queue.removeEvent(event.id);
          return;
        }

        final nextRetry = _retryPolicy.calculateNextRetry(
          event.retryCount,
          nowUtc: _timeAuthority.nowUtc(),
        );
        if (nextRetry != null) {
          await _queue.updateEvent(event.copyWith(
            retryCount: event.retryCount + 1,
            nextRetryAt: nextRetry,
          ));
        }
      },
      (_) async {
        await _queue.removeEvent(event.id);
      },
    );
  }

  void _completeReport(String id, Either<Failure, bool> result) {
    final report = _reports.remove(id);
    if (report != null && !report.isCompleted) {
      report.complete(result);
    }
  }
}
