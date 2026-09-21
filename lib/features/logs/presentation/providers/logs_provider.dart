import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/log_repository.dart';
import '../../data/repositories/log_repository_impl.dart';
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

  const LogsState({
    this.logs = const [],
    this.selectedLog,
    this.isLoading = false,
    this.error,
    this.offset = 0,
    this.hasReachedMax = false,
  });

  LogsState copyWith({
    List<DailyLog>? logs,
    DailyLog? selectedLog,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? offset,
    bool? hasReachedMax,
  }) {
    return LogsState(
      logs: logs ?? this.logs,
      selectedLog: selectedLog ?? this.selectedLog,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      offset: offset ?? this.offset,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
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

  /// تحديد سجل محدد للتفاصيل
  void selectLog(DailyLog log) {
    state = state.copyWith(selectedLog: log);
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

  /// إضافة حدث جديد للسجل المحدد
  void addEvent(LogEvent event) {
    if (state.selectedLog == null) return;

    final updatedEvents = <LogEvent>[...state.selectedLog!.events, event];

    final updatedLog = state.selectedLog!.copyWith(
      events: updatedEvents,
    );

    // Update the selected log
    state = state.copyWith(selectedLog: updatedLog);

    // Update the log in the main logs list
    final updatedLogs = state.logs.map((log) {
      if (log.id == updatedLog.id) return updatedLog;
      return log;
    }).toList();

    state = state.copyWith(logs: updatedLogs);
  }

  /// تحديث سجل بالكامل (مثل إكمال النموذج)
  void updateLog(DailyLog updatedLog) {
    // Update the selected log if it matches
    if (state.selectedLog?.id == updatedLog.id) {
      state = state.copyWith(selectedLog: updatedLog);
    }

    // Update the log in the main logs list
    final updatedLogs = state.logs.map((log) {
      if (log.id == updatedLog.id) return updatedLog;
      return log;
    }).toList();

    state = state.copyWith(logs: updatedLogs);
  }

  /// جلب سجل التدقيق ليوم محدد
  Future<List<AuditEntry>> getAuditEntries(DateTime date) async {
    final result = await _repository.getAuditEntries(date);
    return result.match((l) => [], (r) => r);
  }

  /// حفظ سجل تدقيق جديد
  Future<Either<Failure, void>> saveAuditEntry(AuditEntry entry) async {
    return await _repository.logAudit(entry);
  }
}
