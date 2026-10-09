import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/entities/daily_log.dart';
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

    final referenceDate = (logDate ?? (sortedEvents.isNotEmpty ? sortedEvents.first.startTime : DateTime.now())).toLocal();
    final midnight = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

    final points = <EldGraphPoint>[];
    final stats = <String, double>{
      'OFF': 0.0,
      'SB': 0.0,
      'D': 0.0,
      'ON': 0.0,
    };

    for (final event in sortedEvents) {
      final startTime = event.startTime.toLocal();
      final duration = event.duration;
      final status = event.status;

      double startHour = startTime.difference(midnight).inMinutes / 60.0;
      double endHour = startHour + (duration.inMinutes / 60.0);

      if (endHour <= 0.0) continue;
      if (startHour >= 24.0) continue;

      startHour = startHour.clamp(0.0, 24.0);
      endHour = endHour.clamp(0.0, 24.0);

      String normalized;
      if (status == 'PC') {
        normalized = 'OFF';
      } else if (status == 'YM' || status == 'OTH' || !stats.containsKey(status)) {
        normalized = 'ON';
      } else {
        normalized = status;
      }

      stats[normalized] = stats[normalized]! + (endHour - startHour);

      final isPcOrYm = (status == 'PC' || status == 'YM');
      points.add(
        EldGraphPoint(
          startHour: startHour,
          endHour: endHour,
          status: normalized,
          tag: isPcOrYm ? status : null,
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
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
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
