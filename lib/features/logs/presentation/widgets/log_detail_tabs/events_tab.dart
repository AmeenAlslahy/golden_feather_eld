import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../domain/entities/daily_log.dart';
import '../../providers/logs_provider.dart';
import '../../widgets/log_graph.dart';
import 'log_event_tile.dart';
import '../../../../../../routes.dart';

import '../../../../../../core/extensions/context_extensions.dart';

class EventsTab extends ConsumerWidget {
  final DailyLog selectedLog;

  const EventsTab({super.key, required this.selectedLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedLog.events.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy, 
              size: 64, 
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              context.loc.noRecordsToday,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        LogGraph(events: selectedLog.events),
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: selectedLog.events.length,
              itemBuilder: (context, index) {
                final event = selectedLog.events[index];
                return LogEventTile(
                  event: event,
                  onTap: () {
                    ref
                        .read(logsProvider.notifier)
                        .toggleEventExpansion(event.id);
                  },
                  onEdit: () {
                    context.push(AppRoutes.editLog.replaceAll(':id', event.id),
                        extra: event);
                  },
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
