import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/time/time_authority.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../core/time/time_formatter.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/log_edit.dart';

class EditLogFormState {
  final String selectedStatus;
  final String startTime;
  final String duration;
  final String location;
  final String reason;

  EditLogFormState({
    required this.selectedStatus,
    required this.startTime,
    required this.duration,
    required this.location,
    this.reason = '',
  });

  EditLogFormState copyWith({
    String? selectedStatus,
    String? startTime,
    String? duration,
    String? location,
    String? reason,
  }) {
    return EditLogFormState(
      selectedStatus: selectedStatus ?? this.selectedStatus,
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      location: location ?? this.location,
      reason: reason ?? this.reason,
    );
  }
}

class EditLogFormNotifier extends StateNotifier<EditLogFormState> {
  final TimeAuthority? _timeAuthority;
  final LogEvent? _editingEvent;
  DailyLog? _selectedLog;

  EditLogFormNotifier(
    super.state, {
    TimeAuthority? timeAuthority,
    LogEvent? editingEvent,
    DailyLog? selectedLog,
  })  : _timeAuthority = timeAuthority,
        _editingEvent = editingEvent,
        _selectedLog = selectedLog;

  void setStatus(String status) =>
      state = state.copyWith(selectedStatus: status);

  void updateSelectedLog(DailyLog? log) {
    _selectedLog = log;
  }

  void setStartTime(String time, [DailyLog? selectedLog]) {
    final log = selectedLog ?? _selectedLog;
    final computedDuration = _computeDuration(time, log);
    state = state.copyWith(
      startTime: time,
      duration: computedDuration ?? state.duration,
    );
  }

  void setLocation(String location) =>
      state = state.copyWith(location: location);

  void setReason(String reason) => state = state.copyWith(reason: reason);

  /// حساب الوقت الابتدائي لاختيار الوقت استناداً إلى وقت السجل أو الوقت الحالي الموثوق
  DateTime getInitialTime(DateTime? logDate, TimeAuthority timeAuthority) {
    return parseEditFormTime(state.startTime, logDate) ??
        timeAuthority.nowUtc().toLocal();
  }

  String? _computeDuration(String timeStr, DailyLog? log) {
    final now = _timeAuthority?.nowUtc().toLocal() ?? DateTime.now();
    final baseDate = log?.date;
    final parsedTime = parseEditFormTime(timeStr, baseDate, now);
    if (parsedTime == null) return null;

    final events = log?.events ?? [];
    final otherEvents = _editingEvent == null
        ? events
        : events.where((e) => e.id != _editingEvent.id).toList();

    // ابحث عن الحدث التالي زمنياً بعد وقت البدء
    LogEvent? nextEvent;
    for (final e in otherEvents) {
      if (e.startTime.isAfter(parsedTime)) {
        if (nextEvent == null || e.startTime.isBefore(nextEvent.startTime)) {
          nextEvent = e;
        }
      }
    }

    Duration duration;
    if (nextEvent != null) {
      duration = nextEvent.startTime.difference(parsedTime);
    } else {
      final isToday = log?.today ??
          (baseDate != null &&
              baseDate.year == now.year &&
              baseDate.month == now.month &&
              baseDate.day == now.day);

      if (isToday) {
        if (now.isAfter(parsedTime)) {
          duration = now.difference(parsedTime);
        } else {
          duration = Duration.zero;
        }
      } else {
        // ليوم سابق ليس بعده أحداث، تمتد الحالة حتى نهاية اليوم
        final day = baseDate ?? parsedTime;
        final endOfDay = DateTime(day.year, day.month, day.day, 24, 0, 0);
        if (endOfDay.isAfter(parsedTime)) {
          duration = endOfDay.difference(parsedTime);
        } else {
          duration = Duration.zero;
        }
      }
    }

    if (duration.isNegative) {
      duration = Duration.zero;
    }

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }
}

// دالة مساعدة لتنسيق الوقت الحالي
String _formatCurrentTime(TimeAuthority timeAuthority) {
  final now = timeAuthority.nowUtc().toLocal();
  return TimeFormatter.formatCurrentTime12Hour(now);
}

final editLogFormProvider = StateNotifierProvider.autoDispose
    .family<EditLogFormNotifier, EditLogFormState, LogEvent?>((ref, event) {
  final timeAuthority = ref.watch(timeAuthorityProvider);
  return EditLogFormNotifier(
    EditLogFormState(
      selectedStatus: event?.status ?? 'OFF',
      startTime:
          event?.formattedStartTime ?? _formatCurrentTime(timeAuthority),
      duration: event?.formattedDuration ?? '00:00',
      location: event?.location ?? '',
    ),
    timeAuthority: timeAuthority,
    editingEvent: event,
  );
});
