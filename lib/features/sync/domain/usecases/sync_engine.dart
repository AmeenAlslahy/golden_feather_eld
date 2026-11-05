import 'dart:async';

import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../entities/dispatch_auth.dart';
import '../entities/pending_event.dart';
import '../entities/quarantine_record.dart';
import '../repositories/offline_queue.dart';

import '../../../../core/time/time_authority.dart';
import '../../../../core/utils/logger.dart';

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

  /// P0 2B-1 — مراقب الجلسة لمراجعة المؤجل (T3): يعيد المؤهل فقط عندما
  /// تعود جلسة مالكه مستقرة. اختياري للتوافق مع الاختبارات القائمة؛
  /// الإنتاج يحقنه دائماً (لا إفراج أعمى بدونه).
  final Future<DispatchAuthContext> Function()? observeAuth;

  /// P0 — إبلاغ طبقة السجلات بأن الطلب خرج نهائياً من الطابور (رفض خادم
  /// أو استنفاد محاولات) كي تُميَّز حالته عن «بانتظار المزامنة».
  /// فشل الإبلاغ لا يغيّر نتيجة المزامنة.
  final Future<void> Function(PendingEvent event)? onDeadLettered;

  bool _isSyncing = false;
  bool _syncAgain = false;
  final Map<String, Completer<Either<Failure, bool>>> _reports = {};
  final List<Completer<void>> _idle = [];

  SyncEngine({
    required OfflineQueue queue,
    required RemoteEventDispatcher dispatcher,
    required TimeAuthority timeAuthority,
    RetryPolicy? retryPolicy,
    this.observeAuth,
    this.onDeadLettered,
  }) : _queue = queue,
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

  /// P0 2B-1 — مراجعة المؤجل المؤهل قبل كل دفعة (T3): يعيد لـ pending
  /// فقط الصفوف المثبتة التي تطابق جلسة مستقرة حاضرة. المحجور-مجهول
  /// لا يُمس أبداً هنا. محدود العدد، وفشله لا يوقف المزامنة.
  /// @returns عدد الأحداث المعادة للتأهيل.
  Future<int> releaseEligible({int limit = 50}) async {
    final observe = observeAuth;
    if (observe == null) return 0;
    late final DispatchAuthContext ctx;
    try {
      ctx = await observe();
    } catch (_) {
      return 0;
    }
    if (ctx.driverId == null || ctx.transitioning) return 0;
    var released = 0;
    try {
      final deferred = await _queue.getDeferred(limit: limit);
      for (final record in deferred) {
        if (record.ownerDriverId == ctx.driverId) {
          await _queue.releaseToPending(record.event.id);
          released++;
          AppLogger.info(
            'SyncEngine: released deferred event ${record.event.id} '
            'to owner ${ctx.driverId}',
          );
        }
      }
    } catch (e) {
      AppLogger.warning('SyncEngine: deferred review failed: $e');
    }
    return released;
  }

  /// تشغيل المزامنة للأحداث المعلقة (تُستدعى يدوياً أو تلقائياً عند عودة الاتصال)
  Future<void> triggerSync() async {
    if (_isSyncing) {
      _syncAgain = true;
      return;
    }
    _isSyncing = true;

    try {
      // P0 2B-1 — أولاً: إعادة تأهيل مؤجل المالك العائد (رخيص ومحلي).
      await releaseEligible();
      while (true) {
        _syncAgain = false;
        var hasMore = true;
        final attemptedThisPass = <String>{};
        while (hasMore) {
          final rawReady = await _queue.getReadyEvents(limit: 10);
          final readyEvents = rawReady
              .where((e) => !attemptedThisPass.contains(e.id))
              .toList();

          if (readyEvents.isEmpty) {
            hasMore = false;
            break;
          }

          for (final event in readyEvents) {
            attemptedThisPass.add(event.id);
            Either<Failure, bool> result;
            try {
              result = await _dispatcher.dispatch(event);
            } catch (e) {
              result = Left(
                ServerFailure(message: 'Failed to dispatch event: $e'),
              );
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

  /// P0 2B-1 — ترجمة حكم الحجر لتخزين ذري. يُستدعى حصراً من _settle.
  StoredEventState _parkStateOf(QuarantinedFailure failure) {
    return StoredEventState.values.firstWhere(
      (s) => s.name == failure.parkState,
      orElse: () => StoredEventState.quarantinedUnknownOwner,
    );
  }

  Future<void> _settle(PendingEvent event, Either<Failure, bool> result) async {
    await result.match(
      (failure) async {
        // 🔴 رفض نهائي من الخادم (409/4xx) — لا إعادة محاولة.
        //
        // `RetryPolicy` تعيد المحاولة إلى ما لا نهاية عمداً (FMCSA: لا
        // تُفقد بيانات HOS)، وهو صحيح لحدث ضائع بسبب الشبكة. لكنه كارثي
        // لحدث مرفوض نهائياً: مثال مُبلَّغ — حفظ نموذج يوم معتمد يُرجع
        // 409 BUSINESS_RULE_VIOLATION، فيُعاد كل ~50 ثانية للأبد بلا
        // أي احتمال للنجاح، مع إغراق السجلات واستنزاف الشبكة.
        //
        // الرفض النهائي وحده ينتقل إلى dead-letter فوراً؛ ما عداه
        // يحتفظ بحماية FMCSA كاملة.
        if (failure is RejectedFailure) {
          await _queue.moveToDeadLetter(event);
          await _notifyDeadLettered(event);
          AppLogger.warning(
            'SyncEngine: event ${event.id} permanently rejected by server '
            '(${failure.code}) — dead-lettered without retry',
          );
          return;
        }
        // P0 2B-1 — حجر الملكية ليس فشل إرسال: نقل ذري لخارج الطابور،
        // بلا retry وبلا تصعيد خطأ. الصف يغيب عن getReadyEvents نهائياً.
        if (failure is QuarantinedFailure) {
          final state = _parkStateOf(failure);
          if (state == StoredEventState.quarantinedUnknownOwner) {
            await _queue.moveToQuarantine(
              event,
              reason: failure.reason,
              ownerDriverId: failure.ownerDriverId,
            );
          } else {
            await _queue.moveToDeferred(
              event,
              state: state,
              reason: failure.reason,
              ownerDriverId: failure.ownerDriverId,
            );
          }
          AppLogger.warning(
            'SyncEngine: parked ${event.id} (${failure.reason})',
          );
          return;
        }
        final nextRetry = _retryPolicy.calculateNextRetry(
          event.retryCount,
          nowUtc: _timeAuthority.nowUtc(),
        );
        if (nextRetry != null) {
          await _queue.updateEvent(
            event.copyWith(
              retryCount: event.retryCount + 1,
              nextRetryAt: nextRetry,
            ),
          );
        } else {
          AppLogger.warning(
            'SyncEngine: Event ${event.id} exhausted retries. Moving to dead-letter.',
          );
          await _queue.moveToDeadLetter(event);
          await _notifyDeadLettered(event);
        }
      },
      (_) async {
        await _queue.removeEvent(event.id);
      },
    );
  }

  Future<void> _notifyDeadLettered(PendingEvent event) async {
    final notify = onDeadLettered;
    if (notify == null) return;
    try {
      await notify(event);
    } catch (e) {
      AppLogger.warning(
        'SyncEngine: dead-letter callback failed for ${event.id}: $e',
      );
    }
  }

  void _completeReport(String id, Either<Failure, bool> result) {
    final report = _reports.remove(id);
    if (report != null && !report.isCompleted) {
      report.complete(result);
    }
  }
}
