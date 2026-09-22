/// Events Tab — Displays 24-hour graph grid and duty status events.
///
/// **API Integration:** Fetches official graph-grid data from
/// `GET /eld/daily-logs/{id}/graph-grid` via [graphGridProvider].
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_gap.dart';
import '../../../../../routes.dart';
import '../../../domain/entities/daily_log.dart';
import '../../providers/graph_grid_provider.dart';
import '../../providers/logs_provider.dart';
import '../../widgets/log_graph.dart';
import 'log_event_tile.dart';

class EventsTab extends ConsumerStatefulWidget {
  final DailyLog selectedLog;

  const EventsTab({super.key, required this.selectedLog});

  @override
  ConsumerState<EventsTab> createState() => _EventsTabState();
}

class _EventsTabState extends ConsumerState<EventsTab> {
  @override
  void initState() {
    super.initState();
    // Load official graph-grid from API
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(graphGridProvider.notifier)
          .loadGraphGrid(widget.selectedLog.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final graphState = ref.watch(graphGridProvider);

    // Use API events if available, fallback to local events
    final events = graphState.events.isNotEmpty
        ? graphState.events
        : widget.selectedLog.events;

    if (events.isEmpty && !graphState.isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_busy,
              size: 64,
              color: Theme.of(context)
                  .colorScheme
                  .onSurfaceVariant
                  .withValues(alpha: 0.5),
            ),
            AppGap.md,
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
        // ========== Graph Grid ==========
        // Use API graph-grid events (authoritative), fall back to local events
        LogGraph(events: graphState.events.isNotEmpty
            ? graphState.events
            : widget.selectedLog.events),

        // ========== Totals from API ==========
        if (graphState.data != null) _buildTotalsBar(context, graphState),

        // ========== API Error indicator ==========
        if (graphState.error != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.xs),
            color: AppColors.warningYellow.withValues(alpha: 0.1),
            child: Row(
              children: [
                const Icon(Icons.cloud_off,
                    size: 14, color: AppColors.warningYellow),
                AppGap.hSm,
                Expanded(
                  child: Text(
                    'Using local data: ${graphState.error}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.warningYellow,
                        ),
                  ),
                ),
                GestureDetector(
                  onTap: () => ref
                      .read(graphGridProvider.notifier)
                      .loadGraphGrid(widget.selectedLog.id),
                  child: const Icon(Icons.refresh,
                      size: 14, color: AppColors.warningYellow),
                ),
              ],
            ),
          ),

        // ========== Loading indicator ==========
        if (graphState.isLoading)
          const Padding(
            padding: EdgeInsets.all(AppSpacing.xs),
            child: LinearProgressIndicator(minHeight: 2),
          ),

        // ========== Events List ==========
        Expanded(
          child: Container(
            color: Theme.of(context).colorScheme.surface,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: widget.selectedLog.events.length,
              itemBuilder: (context, index) {
                final event = widget.selectedLog.events[index];
                return LogEventTile(
                  event: event,
                  onTap: () {
                    ref
                        .read(logsProvider.notifier)
                        .toggleEventExpansion(event.id);
                  },
                  onEdit: () {
                    context.push(
                        AppRoutes.editLog.replaceAll(':id', event.id),
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

  /// Compact totals bar showing API-calculated hours.
  Widget _buildTotalsBar(BuildContext context, GraphGridState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor,
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _totalChip(context, 'OFF', state.formattedOffDuty),
          _totalChip(context, 'SB', state.formattedSleeper),
          _totalChip(context, 'D', state.formattedDriving),
          _totalChip(context, 'ON', state.formattedOnDuty),
        ],
      ),
    );
  }

  Widget _totalChip(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const AppGap.custom(2),
        Text(
          value,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }
}
