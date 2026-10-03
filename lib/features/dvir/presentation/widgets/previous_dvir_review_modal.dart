import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
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
      title: Text(loc.dvirPreviousInspection),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.dvirReviewBeforeDriving),
            const SizedBox(height: 8),
            Text('$dateLabel \u2014 $condition'),
            const SizedBox(height: 8),
            Text(
              loc.dvirRecordedDefects,
              style: context.styles.bodyBold,
            ),
            if (previousDefects.isEmpty)
              Text(loc.dvirNone)
            else
              for (final line in previousDefects) Text('\u2022 $line'),
            if ((latest.repairStatus ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                loc.dvirRepairStatus +
                    latest.repairStatus!.trim() +
                    ((latest.mechanicName ?? '').trim().isNotEmpty
                        ? ' (${latest.mechanicName!.trim()})'
                        : ''),
              ),
              if ((latest.repairNotes ?? '').trim().isNotEmpty)
                Text(latest.repairNotes!.trim()),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(loc.cancelAction),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: Text(loc.dvirReviewed),
        ),
      ],
    );
  }
}
