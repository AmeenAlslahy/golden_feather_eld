import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../domain/entities/event_screen_options.dart';
import '../../data/providers/log_repository_providers.dart';

/// موفر خيارات ومراجع شاشة تعديل الأحداث لكل سجل يومي استناداً إلى
/// `GET /eld/daily-logs/{id}/events/options`.
final eventScreenOptionsProvider =
    FutureProvider.autoDispose.family<EventScreenOptions, DailyLogId>((
  ref,
  logId,
) async {
  final EventScreenOptions options;
  try {
    final repo = ref.watch(logRepositoryProvider);
    final result = await repo.getEventScreenOptions(logId);
    options = result.fold(
      (failure) => EventScreenOptions.standardFallback,
      (data) => data,
    );
  } catch (_) {
    return EventScreenOptions.standardFallback;
  }
  return options;
});
