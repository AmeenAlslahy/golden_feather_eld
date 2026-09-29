import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/log_repository.dart';
import '../../data/providers/log_repository_providers.dart';
import '../../domain/entities/audit_entry.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';

/// حالة شاشة السجلات
class LogsState {
  final List<DailyLog> logs;
  final DailyLog? selectedLog;
  final bool isLoading;
  final String? error;
  final int offset;
  final bool hasReachedMax;

  /// True while the events of [selectedLog] are being fetched.
  final bool isLoadingEvents;

  /// Set when fetching the events of [selectedLog] failed (raw failure
  /// message; sanitize before display).
  final String? eventsError;

  const LogsState({
    this.logs = const [],
    this.selectedLog,
    this.isLoading = false,
    this.error,
    this.offset = 0,
    this.hasReachedMax = false,
    this.isLoadingEvents = false,
    this.eventsError,
  });

  LogsState copyWith({
    List<DailyLog>? logs,
    DailyLog? selectedLog,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? offset,
    bool? hasReachedMax,
    bool? isLoadingEvents,
    String? eventsError,
    bool clearEventsError = false,
  }) {
    return LogsState(
      logs: logs ?? this.logs,
      selectedLog: selectedLog ?? this.selectedLog,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      offset: offset ?? this.offset,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoadingEvents: isLoadingEvents ?? this.isLoadingEvents,
      eventsError:
          clearEventsError ? null : (eventsError ?? this.eventsError),
    );
  }
}

/// مزود السجلات
final logsProvider = StateNotifierProvider<LogsNotifier, LogsState>((ref) {
  final repository = ref.watch(logRepositoryProvider);
  final driverId = ref.watch(currentDriverIdProvider);
  return LogsNotifier(repository, driverId);
});

class LogsNotifier extends StateNotifier<LogsState> {
  final LogRepository _repository;
  final int? _driverId;

  LogsNotifier(this._repository, this._driverId) : super(const LogsState()) {
    if (_driverId != null) {
      loadLogs();
    }
  }

  Future<void> loadLogs({bool refresh = false}) async {
    if (_driverId == null) return;
    if (state.isLoading) return;
    if (!refresh && state.hasReachedMax) return;

    final isFirstLoad = state.logs.isEmpty || refresh;
    if (isFirstLoad) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      state = state.copyWith(isLoading: true);
    }

    final currentOffset = refresh ? 0 : state.offset;
    const limit = 20;

    final result = await _repository.getDailyLogs(
      driverId: _driverId,
      limit: limit,
      offset: currentOffset,
    );

    if (!mounted) return;

    result.match(
      (failure) {
        state = state.copyWith(
          isLoading: false,
          error: failure.message,
        );
      },
      (newLogs) {
        final mergedLogs = refresh ? newLogs : [...state.logs, ...newLogs];
        // Deduplicate by ID just in case
        final uniqueLogs = <DailyLogId, DailyLog>{};
        for (final log in mergedLogs) {
          uniqueLogs[log.id] = log;
        }

        state = state.copyWith(
          isLoading: false,
          logs: uniqueLogs.values.toList(),
          offset: currentOffset + newLogs.length,
          hasReachedMax: newLogs.length < limit,
          clearError: true,
        );
      },
    );
  }

  /// تحديد سجل محدد للتفاصيل ثم جلب أحداثه.
  ///
  /// قائمة `GET /eld/daily-logs` لا تتضمن الأحداث؛ لذلك تُجلب عند فتح اليوم
  /// من `GET /eld/daily-logs/{id}/graph-grid` (SRS 5.2).
  void selectLog(DailyLog log) {
    state = state.copyWith(selectedLog: log, clearEventsError: true);
    loadSelectedLogEvents();
  }

  /// (إعادة) جلب أحداث السجل المحدد. آمنة للاستدعاء من زر «إعادة المحاولة».
  Future<void> loadSelectedLogEvents() async {
    final log = state.selectedLog;
    if (log == null) return;

    state = state.copyWith(isLoadingEvents: true, clearEventsError: true);
    final result = await _repository.getEvents(log.id, log.date);
    if (!mounted) return;
    // المستخدم قد يكون فتح يوماً آخر أثناء الانتظار.
    if (state.selectedLog?.id != log.id) return;

    result.match(
      (failure) {
        state = state.copyWith(
          isLoadingEvents: false,
          eventsError: failure.message,
        );
      },
      (events) {
        // نحافظ على حالة التوسيع الحالية للأحداث ذات المعرّف نفسه.
        final expanded = {
          for (final e in state.selectedLog!.events)
            if (e.isExpanded) e.id,
        };
        final merged = events
            .map((e) =>
                expanded.contains(e.id) ? e.copyWith(isExpanded: true) : e)
            .toList();
        _replaceSelected(state.selectedLog!.copyWith(events: merged));
        state = state.copyWith(isLoadingEvents: false, clearEventsError: true);
      },
    );
  }

  /// يحدّث السجل المحدد ونسخته داخل القائمة معاً (مصدر حقيقة واحد).
  void _replaceSelected(DailyLog updatedLog) {
    state = state.copyWith(
      selectedLog: updatedLog,
      logs: state.logs
          .map((l) => l.id == updatedLog.id ? updatedLog : l)
          .toList(),
    );
  }

  /// تبديل توسيع حدث
  void toggleEventExpansion(String eventId) {
    if (state.selectedLog == null) return;

    final updatedEvents = state.selectedLog!.events.map((e) {
      if (e.id == eventId) {
        return e.copyWith(isExpanded: !e.isExpanded);
      }
      return e;
    }).toList();

    final updatedLog = state.selectedLog!.copyWith(
      events: updatedEvents,
    );

    state = state.copyWith(selectedLog: updatedLog);
  }

  /// تصديق السجل
  void certifyLog(DailyLogId logId) {
    final updatedLogs = state.logs.map((log) {
      if (log.id == logId) {
        return log.copyWith(isCertified: true);
      }
      return log;
    }).toList();

    state = state.copyWith(logs: updatedLogs);
  }

  /// إضافة حدث جديد للسجل المحدد (POST /eld/duty-status، أو محلياً دون اتصال).
  Future<bool> addEvent(LogEvent event, {String? reason}) async {
    if (state.selectedLog == null) return false;

    // الحفظ في المستودع أولاً؛ لا تحديث للواجهة عند فشل الحفظ.
    final persisted = (await _repository.addEvent(event, reason: reason))
        .fold((_) => false, (ok) => ok);
    if (!persisted || !mounted) return persisted;

    _replaceSelected(state.selectedLog!.copyWith(
      events: <LogEvent>[...state.selectedLog!.events, event],
    ));
    // الخادم يعيد حساب المدد والمعرّفات — أعد الجلب لتطابق الشبكة الرسمية.
    unawaited(loadSelectedLogEvents());
    return true;
  }

  /// تعديل حدث (PUT /eld/duty-status/{id} مع سبب إلزامي).
  ///
  /// الخادم يعيد DutyEventDto المعدّل — يُعتمد مرجعاً للواجهة بدل
  /// التخمين المحلي، ثم إعادة جلب للتأكيد (الخادم يعيد حساب المدد).
  Future<bool> updateEvent(LogEvent event, {required String reason}) async {
    if (state.selectedLog == null) return false;

    final confirmed = await _repository.updateEvent(event, reason: reason);
    if (!mounted) return false;
    final persistedEvent = confirmed.fold((_) => null, (e) => e);
    if (persistedEvent == null) {
      // حدث محلي/أوفلاين أو استجابة بلا جسم: السلوك الاحتياطي السابق.
      _replaceSelected(state.selectedLog!.copyWith(
        events: state.selectedLog!.events
            .map((e) => e.id == event.id ? event : e)
            .toList(),
      ));
      unawaited(loadSelectedLogEvents());
      return true;
    }

    _replaceSelected(state.selectedLog!.copyWith(
      events: state.selectedLog!.events
          .map((e) => e.id == persistedEvent.id ? persistedEvent : e)
          .toList(),
    ));
    unawaited(loadSelectedLogEvents());
    return true;
  }

  /// تحديث سجل بالكامل (مثل إكمال النموذج)
  void updateLog(DailyLog updatedLog) {
    if (state.selectedLog?.id == updatedLog.id) {
      _replaceSelected(updatedLog);
      return;
    }
    state = state.copyWith(
      logs: state.logs
          .map((log) => log.id == updatedLog.id ? updatedLog : log)
          .toList(),
    );
  }

  /// جلب سجل التدقيق ليوم محدد
  Future<List<AuditEntry>> getAuditEntries(DateTime date) async {
    final result = await _repository.getAuditEntries(date);
    return result.match((l) => [], (r) => r);
  }

  /// حفظ سجل تدقيق جديد
  Future<Either<Failure, bool>> saveAuditEntry(AuditEntry entry) async {
    return await _repository.logAudit(entry);
  }
}
