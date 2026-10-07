import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/time/time_authority.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../core/time/time_formatter.dart';
import '../../domain/entities/daily_log.dart';

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
  EditLogFormNotifier(super.state);

  void setStatus(String status) =>
      state = state.copyWith(selectedStatus: status);
  void setStartTime(String time) => state = state.copyWith(startTime: time);
  void setLocation(String location) => state = state.copyWith(location: location);
  void setReason(String reason) => state = state.copyWith(reason: reason);
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
      startTime: event?.formattedStartTime ?? _formatCurrentTime(timeAuthority),
      duration: event?.formattedDuration ?? '00:00',
      location: event?.location ?? '',
    ),
  );
});
