import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:golden_feather_eld/core/theme/app_radius.dart';
import 'package:golden_feather_eld/core/theme/app_spacing.dart';
import '../../domain/entities/dvir_report.dart';

/// §396.13 review dialog: shows the previous inspection summary and asks the
/// incoming driver to confirm they reviewed it before starting the trip.
class PreviousDvirReviewModal extends StatelessWidget {
  final DvirReport latest;

  /// Pre-built human-readable defect lines (localised by the caller).
  final List<String> previousDefects;

  const PreviousDvirReviewModal({
    super.key,
    required this.latest,
    required this.previousDefects,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final dateLabel = latest.date != null
        ? DateFormat('yyyy-MM-dd HH:mm').format(latest.date!.toLocal())
        : '—';
    final condition = context.translateVehicleCondition(latest.condition.name);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      backgroundColor: context.colorScheme.surface,
      title: Row(
        children: [
          Icon(Icons.history_edu_outlined, color: context.gold, size: AppSpacing.iconMedium),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(loc.dvirPreviousInspection, style: context.styles.cardTitle)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.dvirReviewBeforeDriving, style: context.styles.body),
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(AppRadius.input),
                border: Border.all(color: context.colorScheme.outlineVariant.withValues(alpha: 0.5)),
              ),
              child: Text(
                '$dateLabel \u2014 $condition',
                style: context.styles.bodyBold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(loc.dvirRecordedDefects, style: context.styles.sectionTitle),
            const SizedBox(height: AppSpacing.xs),
            if (previousDefects.isEmpty)
              Text(loc.dvirNone, style: context.styles.muted)
            else
              for (final line in previousDefects)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('• ', style: context.styles.error),
                      Expanded(child: Text(line, style: context.styles.body)),
                    ],
                  ),
                ),
            if ((latest.repairStatus ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: context.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: context.warning.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      loc.dvirRepairStatus +
                          latest.repairStatus!.trim() +
                          ((latest.mechanicName ?? '').trim().isNotEmpty
                              ? ' (${latest.mechanicName!.trim()})'
                              : ''),
                      style: context.styles.caption.copyWith(fontWeight: FontWeight.bold),
                    ),
                    if ((latest.repairNotes ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(latest.repairNotes!.trim(), style: context.styles.caption),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            loc.cancelAction,
            style: context.styles.button.copyWith(color: context.colorScheme.onSurfaceVariant),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(
            loc.dvirReviewed,
            style: context.styles.button.copyWith(color: context.gold, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
