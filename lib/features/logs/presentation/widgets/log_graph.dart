import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/time_authority_provider.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../domain/entities/daily_log.dart';
import '../../domain/log_day_slice.dart';
import '../../../../core/events/eld_events_provider.dart';
import '../../../../core/widgets/eld_graph_grid.dart';

class LogGraph extends ConsumerWidget {
  final List<LogEvent> events;
  final DateTime? logDate;

  const LogGraph({super.key, required this.events, this.logDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestEldEvent = ref.watch(eldEventsStreamProvider).valueOrNull;

    final sortedEvents = List<LogEvent>.from(events)
      ..sort((a, b) => a.startTime.compareTo(b.startTime));

    final fallbackNow = ref.watch(timeAuthorityProvider).nowUtc().toLocal();
    final referenceDate =
        (logDate ??
                (sortedEvents.isNotEmpty
                    ? sortedEvents.first.startTime
                    : fallbackNow))
            .toLocal();
    final midnight = DateTime(
      referenceDate.year,
      referenceDate.month,
      referenceDate.day,
    );

    final points = <EldGraphPoint>[];
    final stats = <String, double>{'OFF': 0.0, 'SB': 0.0, 'D': 0.0, 'ON': 0.0};

    for (final event in sortedEvents) {
      // نفس القصّ المستخدم في صف الإجماليات: حدث بدأ أمس يُرسم ويُجمع
      // بالجزء الواقع داخل يوم السجل فقط.
      final slice = sliceLogEventToDay(event, referenceDate);
      if (slice == null) continue;

      final startHour = slice.startHour;
      final endHour = slice.endHour;
      final status = event.status;

      final parsedCode = DutyStatusCode.fromAny(status);
      final normalized = parsedCode.canonicalGridShortCode;

      stats[normalized] = (stats[normalized] ?? 0.0) + (endHour - startHour);

      final isPcOrYm = parsedCode.isSpecialDrivingCategory;
      points.add(
        EldGraphPoint(
          startHour: startHour,
          endHour: endHour,
          status: normalized,
          tag: isPcOrYm ? parsedCode.shortCode : null,
          isDashed: isPcOrYm,
        ),
      );
    }

    double? liveHour;
    if (latestEldEvent != null) {
      final liveTime = latestEldEvent.timestamp.toLocal();
      if (liveTime.year == referenceDate.year &&
          liveTime.month == referenceDate.month &&
          liveTime.day == referenceDate.day) {
        liveHour = liveTime.difference(midnight).inMinutes / 60.0;
      }
    }

    return Container(
      height: 190,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.md),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: EldGraphGrid(
              points: points,
              rightSideStats: stats,
              liveMarkerHour: liveHour,
            ),
          );
        },
      ),
    );
  }
}
