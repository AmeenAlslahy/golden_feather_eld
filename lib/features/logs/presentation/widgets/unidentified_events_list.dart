import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/unidentified_events_provider.dart';

/// قائمة عرض بطاقات الأحداث غير المحددة
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    item.dutyStatus,
                    style: context.styles.bodyBold,
                  ),
                ),
                // SRS 11.2 — allocation state chip from the server.
                if (item.allocationStatus.isNotEmpty)
                  Chip(
                    label: Text(item.allocationStatus.replaceAll('_', ' ')),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
              ],
            ),
            const SizedBox(height: 4),
            if (timeRange.isNotEmpty) Text(timeRange),
            if (item.formattedDuration.isNotEmpty) Text(item.formattedDuration),
            if (item.vehicleName.isNotEmpty) Text(item.vehicleName),
            // SRS 11.2 — ELD / vehicle identifier of the record.
            if (item.uniqueId.isNotEmpty) Text('ELD: ${item.uniqueId}'),
            if (item.location.isNotEmpty) Text(item.location),
            if (item.daysPending != null)
              Text(context.loc.pendingDays(item.daysPending!)),
            if (item.overdue)
              Text(
                context.loc.overdue,
                style: context.styles.error.copyWith(fontWeight: FontWeight.bold),
              ),
            if (item.rejectionReason.isNotEmpty) Text(item.rejectionReason),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(context.loc.originalRecordPreserved),
            ),
            if (canAct && item.statusId != null)
              Row(
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
      ),
    );
  }
}
