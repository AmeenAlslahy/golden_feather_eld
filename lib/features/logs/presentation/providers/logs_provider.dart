import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/repositories/log_repository.dart';
import '../../data/repositories/log_repository_impl.dart';
import '../../domain/entities/audit_entry.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failure.dart';

/// حالة شاشة السجلات
class LogsState {
  final List<DailyLog> logs;
  final DailyLog? selectedLog;
  final bool isLoading;

  const LogsState({
    this.logs = const [],
    this.selectedLog,
    this.isLoading = false,
  });

  LogsState copyWith({
    List<DailyLog>? logs,
    DailyLog? selectedLog,
    bool? isLoading,
  }) {
    return LogsState(
      logs: logs ?? this.logs,
      selectedLog: selectedLog ?? this.selectedLog,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// مزود السجلات
final logsProvider = StateNotifierProvider<LogsNotifier, LogsState>((ref) {
  final repository = ref.watch(logRepositoryProvider);
  return LogsNotifier(repository);
});

class LogsNotifier extends StateNotifier<LogsState> {
  final LogRepository _repository;

  LogsNotifier(this._repository) : super(const LogsState()) {
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    state = state.copyWith(isLoading: true);
    try {
      final futures = List.generate(8, (i) async {
        final date = DateTime.now().subtract(Duration(days: i));

        final result = await _repository.getEvents(date);
        final events = result.match((l) => <LogEvent>[], (r) => r);

        double totalDrivingHours = 0;
        for (final event in events) {
          if (event.status == 'D') {
            totalDrivingHours += event.duration.inMinutes / 60.0;
          }
        }

        return DailyLog(
          id: 'log_$i',
          date: date,
          totalDrivingHours: totalDrivingHours,
          isFormComplete: i > 1,
          isCertified: i > 2,
          events: events,
        );
      });

      final dbLogs = await Future.wait(futures);

      if (mounted) {
        state = state.copyWith(isLoading: false, logs: dbLogs);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false);
      }
    }
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

    final updatedLog = DailyLog(
      id: state.selectedLog!.id,
      date: state.selectedLog!.date,
      totalDrivingHours: state.selectedLog!.totalDrivingHours,
      isFormComplete: state.selectedLog!.isFormComplete,
      isCertified: state.selectedLog!.isCertified,
      events: updatedEvents,
    );

    state = state.copyWith(selectedLog: updatedLog);
  }

  /// تصديق السجل
  void certifyLog(String logId) {
    final updatedLogs = state.logs.map((log) {
      if (log.id == logId) {
        return DailyLog(
          id: log.id,
          date: log.date,
          totalDrivingHours: log.totalDrivingHours,
          isFormComplete: log.isFormComplete,
          isCertified: true,
          events: log.events,
        );
      }
      return log;
    }).toList();

    state = state.copyWith(logs: updatedLogs);
  }

  /// إضافة حدث جديد للسجل المحدد
  void addEvent(LogEvent event) {
    if (state.selectedLog == null) return;

    final updatedEvents = <LogEvent>[...state.selectedLog!.events, event];

    final updatedLog = DailyLog(
      id: state.selectedLog!.id,
      date: state.selectedLog!.date,
      totalDrivingHours: state.selectedLog!.totalDrivingHours,
      isFormComplete: state.selectedLog!.isFormComplete,
      isCertified: state.selectedLog!.isCertified,
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
