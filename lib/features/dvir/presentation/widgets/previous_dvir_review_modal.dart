import 'package:flutter/material.dart';
import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:intl/intl.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dvir_report.dart';

class PreviousDvirReviewModal extends StatelessWidget {
  final DvirReport latest;
  final List<String> previousDefects;

  const PreviousDvirReviewModal({
    super.key,
    required this.latest,
    required this.previousDefects,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return AlertDialog(
      title: Text(loc.dvirPreviousInspection),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(loc.dvirReviewBeforeDriving),
            const SizedBox(height: 8),
            Text(
              '\ — '
              '',
            ),
            const SizedBox(height: 8),
            Text(
              loc.dvirRecordedDefects,
              style: context.styles.bodyBold,
            ),
            if (previousDefects.isEmpty)
              Text(loc.dvirNone)
            else
              for (final line in previousDefects) Text('• '),
            if ((latest.repairStatus ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                loc.dvirRepairStatus +
                    latest.repairStatus!.trim() +
                    ((latest.mechanicName ?? '').trim().isNotEmpty
                        ? ' (\)'
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
