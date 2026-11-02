import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';
import '../../../../core/time/time_formatter.dart';
import '../providers/unidentified_events_provider.dart';

/// List of server-provided unidentified driving events under Design System 2.0.
class UnidentifiedEventsList extends StatelessWidget {
  final List<UnidentifiedEvent> items;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: context.gold.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  error != null
                      ? Icons.cloud_off_rounded
                      : Icons.verified_outlined,
                  size: 40,
                  color: error != null ? context.danger : context.gold,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                error ?? context.loc.noRecords,
                textAlign: TextAlign.center,
                style: context.styles.cardTitle.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.sm,
      ),
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
  final UnidentifiedEvent item;
  final bool canAct;
  final ValueChanged<int> onClaim;
  final ValueChanged<int> onReject;

  const _UnidentifiedEventCard({
    required this.item,
    required this.canAct,
    required this.onClaim,
    required this.onReject,
  });

  String _resolveStatusLabel(BuildContext context, String allocationType) {
    final upper = allocationType.trim().toUpperCase();
    if (upper == 'UNASSIGNED') {
      return context.loc.unassigned.toUpperCase();
    } else if (upper == 'UNCLAIMED') {
      return context.loc.unclaimed.toUpperCase();
    } else if (upper == 'REJECTED') {
      return context.loc.rejected.toUpperCase();
    }
    return allocationType.replaceAll('_', ' ').toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = _resolveStatusLabel(context, item.allocationType);

    final startDt = DateTime.tryParse(item.startTime);
    final endDt =
        item.endTime.isNotEmpty ? DateTime.tryParse(item.endTime) : null;
    final localStart = startDt?.toLocal();
    final localEnd = endDt?.toLocal();

    final matLoc = MaterialLocalizations.of(context);

    // Format Date: Single date or date crossing (start -> end)
    String dateStr = '';
    if (localStart != null) {
      final startDateFmt = matLoc.formatMediumDate(localStart);
      if (localEnd != null &&
          (localStart.year != localEnd.year ||
              localStart.month != localEnd.month ||
              localStart.day != localEnd.day)) {
        final endDateFmt = matLoc.formatMediumDate(localEnd);
        dateStr = '$startDateFmt → $endDateFmt';
      } else {
        dateStr = startDateFmt;
      }
    } else if (item.startTime.isNotEmpty) {
      dateStr = item.startTime;
    }

    // Format Time Range (Chronological, strictly LTR)
    String timeRangeStr = '';
    if (localStart != null) {
      final startT = TimeFormatter.formatTime12Hour(localStart);
      if (localEnd != null) {
        final endT = TimeFormatter.formatTime12Hour(localEnd);
        timeRangeStr = '$startT – $endT';
      } else {
        timeRangeStr = startT;
      }
    } else if (item.startTime.isNotEmpty) {
      timeRangeStr = item.endTime.isNotEmpty
          ? '${item.startTime} – ${item.endTime}'
          : item.startTime;
    }

    // Timezone name/offset (isolated in distinct LTR chip)
    String tzStr = '';
    if (localEnd != null || localStart != null) {
      final refDt = localEnd ?? localStart!;
      final tz = refDt.timeZoneName.trim();
      tzStr = tz.isNotEmpty
          ? (tz.length > 4 ? tz.substring(0, 4).toUpperCase() : tz.toUpperCase())
          : 'UTC';
    }

    // Duration chip
    Widget? durationChip;
    final durationText = item.durationFormatted.isNotEmpty
        ? item.durationFormatted
        : (item.durationMinutes != null
            ? '${item.durationMinutes} ${context.loc.minute}'
            : null);

    if (durationText != null && durationText.isNotEmpty) {
      durationChip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: context.gold.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppRadius.small),
          border: Border.all(
            color: context.gold.withValues(alpha: 0.25),
            width: 0.5,
          ),
        ),
        child: Text(
          durationText,
          style: context.styles.caption.copyWith(
            color: context.isDark ? context.gold : const Color(0xFF7A5C00),
            fontWeight: AppTypography.bold,
            fontSize: 11,
          ),
        ),
      );
    }

    return EldCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.compact,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Header: Vehicle Name (wraps up to 2 lines) & Status Badges ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: context.gold.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: context.gold,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.vehicleName.isEmpty
                                ? context.loc.vehicle
                                : item.vehicleName,
                            style: context.styles.bodyBold.copyWith(
                              fontSize: 15,
                              fontWeight: AppTypography.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (statusLabel.isNotEmpty) ...[
                          const SizedBox(width: AppSpacing.xs),
                          AppStatusPill(
                            label: statusLabel,
                            color:
                                item.allocationType.toUpperCase() == 'REJECTED'
                                    ? context.textSecondary
                                    : context.gold,
                          ),
                        ],
                      ],
                    ),
                    if (item.pendingOver8Days) ...[
                      const SizedBox(height: AppSpacing.space4),
                      AppStatusBadge(
                        label: context.loc.overdue,
                        type: AppStatusBadgeType.error,
                        icon: Icons.warning_amber_rounded,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.xs),

          // ─── Date Row (Calendar + Date + Duration Chip) ───
          if (dateStr.isNotEmpty)
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: context.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    dateStr,
                    style: context.styles.body.copyWith(
                      fontSize: 13,
                      fontWeight: AppTypography.medium,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (durationChip != null) durationChip,
              ],
            ),

          // ─── Time Range Row (Clock + LTR Chronological Time + Timezone Chip) ───
          if (timeRangeStr.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Row(
              children: [
                Icon(
                  Icons.access_time_rounded,
                  size: 14,
                  color: context.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Text(
                      timeRangeStr,
                      style: context.styles.body.copyWith(
                        fontSize: 13,
                        fontWeight: AppTypography.bold,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                if (tzStr.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1.5,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(AppRadius.small),
                    ),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Text(
                        tzStr,
                        style: context.styles.caption.copyWith(
                          fontSize: 10,
                          fontWeight: AppTypography.bold,
                          color: context.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],

          // ─── Location Description ───
          if (item.locationDescription.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Row(
              children: [
                Icon(
                  Icons.place_outlined,
                  size: 14,
                  color: context.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${context.loc.location}: ${item.locationDescription}',
                    style: context.styles.caption.copyWith(
                      color: context.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: AppSpacing.xs),
          Divider(
            height: 1,
            thickness: 0.5,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: AppSpacing.xs),

          // ─── Dedicated Full-Width VIN Row (Preserves character order, strictly LTR, monospace) ───
          if (item.vehicleVin.isNotEmpty)
            Directionality(
              textDirection: TextDirection.ltr,
              child: Text(
                '${context.loc.vin}: ${item.vehicleVin}',
                style: context.styles.caption.copyWith(
                  fontFamily: 'monospace',
                  letterSpacing: 0.5,
                  fontWeight: AppTypography.medium,
                  color: context.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // ─── Telemetry Row: Odometer & Engine Hours ───
          if (item.odometerMiles != null || item.engineHours != null) ...[
            if (item.vehicleVin.isNotEmpty)
              const SizedBox(height: AppSpacing.space2),
            Row(
              children: [
                if (item.odometerMiles != null)
                  Expanded(
                    child: Text(
                      '${context.loc.odometer}: ${item.odometerMiles} ${context.loc.miles}',
                      style: context.styles.caption.copyWith(
                        color: context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (item.engineHours != null)
                  Expanded(
                    child: Text(
                      '${context.loc.engineHours}: ${item.engineHours}',
                      style: context.styles.caption.copyWith(
                        color: context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],

          // ─── ELD Device Identifier ───
          if (item.deviceId != null) ...[
            const SizedBox(height: AppSpacing.space2),
            Text(
              '${context.loc.eldIdentifier}: ${item.deviceId}',
              style: context.styles.caption.copyWith(
                color: context.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          // ─── Annotation / Driver Notes ───
          if (item.annotation.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 14,
                  color: context.textSecondary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    '${context.loc.notes}: ${item.annotation}',
                    style: context.styles.caption,
                  ),
                ),
              ],
            ),
          ],

          // ─── Rejection Reason ───
          if (item.rejectionReason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.space4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.report_problem_outlined,
                  size: 14,
                  color: context.danger,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    item.rejectionReason,
                    style: context.styles.error,
                  ),
                ),
              ],
            ),
          ],

          // ─── Original Record Preserved Compliance Notice ───
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.space4,
              bottom: AppSpacing.space2,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.lock_clock_outlined,
                  size: 12,
                  color: context.textSecondary,
                ),
                const SizedBox(width: AppSpacing.space4),
                Expanded(
                  child: Text(
                    context.loc.originalRecordPreserved,
                    style: context.styles.caption.copyWith(
                      fontSize: 10.5,
                      color: context.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── Action Buttons (Assume & Not Mine) ───
          if (canAct && item.id != null) ...[
            const SizedBox(height: AppSpacing.xs),
            LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 280) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppButton(
                        label: context.loc.assume,
                        type: EldButtonType.primary,
                        isCompact: true,
                        icon: Icons.check_circle_outline,
                        onPressed: () => onClaim(item.id!),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      AppButton(
                        label: context.loc.notMine,
                        type: EldButtonType.secondary,
                        isCompact: true,
                        icon: Icons.close,
                        onPressed: () => onReject(item.id!),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: context.loc.notMine,
                        type: EldButtonType.secondary,
                        isCompact: true,
                        icon: Icons.close,
                        onPressed: () => onReject(item.id!),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AppButton(
                        label: context.loc.assume,
                        type: EldButtonType.primary,
                        isCompact: true,
                        icon: Icons.check_circle_outline,
                        onPressed: () => onClaim(item.id!),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

