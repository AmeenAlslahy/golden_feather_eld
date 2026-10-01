import re

source_file = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
dest_file = 'lib/features/dvir/presentation/widgets/previous_dvir_review_modal.dart'

with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()

modal_code = '''import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/theme_extension.dart';
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
              '\',
            ),
            const SizedBox(height: 8),
            Text(
              loc.dvirRecordedDefects,
              style: context.styles.bodyBold,
            ),
            if (previousDefects.isEmpty)
              Text(loc.dvirNone)
            else
              for (final line in previousDefects) Text('• \'),
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
'''

with open(dest_file, 'w', encoding='utf-8') as f:
    f.write(modal_code)

old_dialog = r'            final reviewed = await showDialog<bool>\(\s*context: context,\s*builder: \(context\) => AlertDialog\(.*?actions: \[\s*TextButton\(.*?\),\s*FilledButton\(.*?\),\s*\],\s*\),\s*\);'

def replacer(match):
    return '''            final reviewed = await showDialog<bool>(
              context: context,
              builder: (context) => PreviousDvirReviewModal(
                latest: latest,
                previousDefects: previousDefects,
              ),
            );'''

new_content = re.sub(old_dialog, replacer, content, flags=re.DOTALL)

import_statement = "import '../widgets/previous_dvir_review_modal.dart';\n"
if import_statement not in new_content:
    new_content = new_content.replace("import '../widgets/status_modal.dart';", "import '../widgets/status_modal.dart';\n" + import_statement)

with open(source_file, 'w', encoding='utf-8') as f:
    f.write(new_content)

print('Updated dvir_form_page.dart successfully')
