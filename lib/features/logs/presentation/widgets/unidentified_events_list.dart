import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';
import '../providers/unidentified_events_provider.dart';

/// List of server-provided unidentified driving events.
class UnidentifiedEventsList extends StatelessWidget {
  final List<UnidentifiedEventItem> items;
  final String? error;
  final bool canAct;
  final ValueChanged<int> onClaim;
  final ValueChanged<int> onReject;

  const UnidentifiedEventsList({
    super.key,
    required this.items,
    required this.error,
    required this.canAct,
    required this.onClaim,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            error ?? context.loc.noRecords,
            textAlign: TextAlign.center,
            style: context.styles.subtitle,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final item = items[index];
        return _UnidentifiedEventCard(
          item: item,
          canAct: canAct,
          onClaim: onClaim,
          onReject: onReject,
        );
      },
    );
  }
}

class _UnidentifiedEventCard extends StatelessWidget {
  final UnidentifiedEventItem item;
  final bool canAct;
  final ValueChanged<int> onClaim;
  final ValueChanged<int> onReject;

  const _UnidentifiedEventCard({
    required this.item,
    required this.canAct,
    required this.onClaim,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final timeRange = item.endTime.isEmpty
        ? item.startTime
        : '${item.startTime} – ${item.endTime}';

    return EldCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(item.dutyStatus, style: context.styles.bodyBold),
              ),
              if (item.allocationStatus.isNotEmpty)
                AppStatusPill(
                  label: item.allocationStatus.replaceAll('_', ' '),
                  color: context.gold,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          if (timeRange.isNotEmpty) Text(timeRange, style: context.styles.body),
          if (item.formattedDuration.isNotEmpty)
            Text(item.formattedDuration, style: context.styles.subtitle)
          else if (item.durationMinutes != null)
            Text(
              '${item.durationMinutes} ${context.loc.minute}',
              style: context.styles.subtitle,
            ),
          if (item.startOdometerKm != null || item.endOdometerKm != null)
            Text(
              '${context.loc.odometer}: '
              '${item.startOdometerKm?.toString() ?? '—'} → '
              '${item.endOdometerKm?.toString() ?? '—'} km',
              style: context.styles.subtitle,
            ),
          if (item.totalDistanceKm != null)
            Text(
              '${context.loc.distance}: ${item.totalDistanceKm} km',
              style: context.styles.subtitle,
            ),
          if (item.vehicleName.isNotEmpty)
            Text(item.vehicleName, style: context.styles.bodyBold),
          if (item.uniqueId.isNotEmpty)
            Text(
              '${context.loc.eldIdentifier}: ${item.uniqueId}',
              style: context.styles.subtitle,
            ),
          if (item.location.isNotEmpty)
            Text(
              '${context.loc.location}: ${item.location}',
              style: context.styles.subtitle,
            ),
          if (item.daysPending != null)
            Text(context.loc.pendingDays(item.daysPending!)),
          if (item.overdue)
            Text(
              context.loc.overdue,
              style: context.styles.error.copyWith(fontWeight: FontWeight.bold),
            ),
          if (item.rejectionReason.isNotEmpty)
            Text(item.rejectionReason, style: context.styles.error),
          if (item.createdAt.isNotEmpty)
            Text(
              '${context.loc.createdAt}: ${item.createdAt}',
              style: context.styles.caption,
            ),
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(context.loc.originalRecordPreserved),
          ),
          if (canAct && item.statusId != null)
            Wrap(
              spacing: AppSpacing.sm,
              children: [
                TextButton(
                  onPressed: () => onClaim(item.statusId!),
                  child: Text(context.loc.assume),
                ),
                TextButton(
                  onPressed: () => onReject(item.statusId!),
                  child: Text(context.loc.notMine),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
