import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/daily_log.dart';
import '../../providers/logs_provider.dart';
import '../../widgets/log_graph.dart';
import 'log_event_tile.dart';
import '../../../../../../routes.dart';
import '../../../../../../core/error/user_facing_message.dart';
import '../../../../../../core/extensions/context_extensions.dart';
import '../../../../../../core/widgets/eld_retry_view.dart';

/// SRS 5.2 — Graph-Grid + the day's duty-status events.
///
/// Events are fetched when the log is opened (`selectLog`); this tab renders
/// loading / failure / empty / data from [LogsState].
class EventsTab extends ConsumerWidget {
  final DailyLog selectedLog;

  const EventsTab({super.key, required this.selectedLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(logsProvider);
    final events = selectedLog.events;

    if (events.isEmpty) {
      if (logsState.isLoadingEvents) {
        return const Center(child: CircularProgressIndicator());
      }
      if (logsState.eventsError != null) {
        return EldRetryView(
          message: anyErrorUserMessage(
            logsState.eventsError!,
            isArabic: Localizations.localeOf(context).languageCode == 'ar',
          ),
          onRetry: () =>
              ref.read(logsProvider.notifier).loadSelectedLogEvents(),
        );
      }
      return EldRetryView(
        message: context.loc.noRecordsToday,
        isError: false,
        onRetry: () => ref.read(logsProvider.notifier).loadSelectedLogEvents(),
      );
    }

    return Column(
      children: [
        Directionality(
          textDirection: TextDirection.ltr,
          child: LogGraph(events: events, logDate: selectedLog.date),
        ),
        _StatusTotalsRow(events: events),
        Expanded(
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: RefreshIndicator(
                onRefresh: () =>
                    ref.read(logsProvider.notifier).loadSelectedLogEvents(),
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: events.length,
                  itemBuilder: (context, index) {
                    final event = events[index];
                    return LogEventTile(
                      event: event,
                      logDate: selectedLog.date,
                      onTap: () {
                        ref
                            .read(logsProvider.notifier)
                            .toggleEventExpansion(event.id);
                      },
                      // SRS 5.2 / §395.30(b): automatically recorded driving
                      // and server-locked events have no pencil at all.
                      onEdit: (event.automatedDriving == true ||
                              event.editable == false)
                          ? null
                          : () {
                              context.push(
                                  AppRoutes.editLog.replaceAll(':id', event.id),
                                  extra: event);
                            },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      );
  }
}

/// SRS 5.2 — hour totals per duty status under the Graph-Grid
/// (the "Total" column of the paper grid).
class _StatusTotalsRow extends StatelessWidget {
  const _StatusTotalsRow({required this.events});

  final List<LogEvent> events;

  static const _order = ['OFF', 'SB', 'D', 'ON'];

  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }

  @override
  Widget build(BuildContext context) {
    final totals = <String, Duration>{for (final s in _order) s: Duration.zero};
    for (final e in events) {
      // PC counts as OFF and YM as ON for the daily totals (§395.28).
      final key = switch (e.status) {
        'PC' => 'OFF',
        'YM' => 'ON',
        _ => e.status,
      };
      if (totals.containsKey(key)) totals[key] = totals[key]! + e.duration;
    }
    return Container(
      key: const Key('events_status_totals'),
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          for (final s in _order)
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(s, style: context.styles.caption),
                  Text(_fmt(totals[s]!), style: context.styles.bodyBold),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
