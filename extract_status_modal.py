import os
import re

source_file = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
dest_file = 'lib/features/dvir/presentation/widgets/status_modal.dart'

with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()

status_modal_code = '''import 'package:flutter/material.dart';
import '../../../../l10n/app_localizations.dart';

class DvirStatusModal extends StatelessWidget {
  final bool hasDefect;
  final String? selectedStatus;

  const DvirStatusModal({
    super.key,
    required this.hasDefect,
    this.selectedStatus,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return AlertDialog(
      title: Text(loc.status),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(loc.dvirSatisfactory),
            enabled: !hasDefect,
            subtitle: hasDefect ? Text(loc.dvirDefectRecorded) : null,
            onTap: hasDefect
                ? null
                : () => Navigator.pop(
                      context,
                      'Vehicle Condition Satisfactory',
                    ),
          ),
          ListTile(
            title: Text(loc.dvirHasDefects),
            onTap: () => Navigator.pop(context, 'Has Defects'),
          ),
          ListTile(
            enabled: false,
            title: Text(loc.dvirDefectsCorrected),
            subtitle: Text(loc.dvirNoRepairCert),
          ),
          ListTile(
            enabled: false,
            title: Text(loc.dvirDefectsNotCorrected),
            subtitle: Text(loc.dvirSetByCarrier),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.cancelAction),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, selectedStatus),
          child: Text(loc.okButton),
        ),
      ],
    );
  }
}
'''

with open(dest_file, 'w', encoding='utf-8') as f:
    f.write(status_modal_code)

print('Created status_modal.dart successfully')

# Now update dvir_form_page.dart
old_status_method_regex = r'  Future<void> _openStatusModal\(\) async \{.*?\s+final selected = await showDialog<String>\(\s+context: context,\s+builder: \(context\) => AlertDialog\(.*?\),\s+\);\s+if \(selected == null \|\| !mounted\) return;\s+setState\(\(\) => _selectedStatus = selected\);\s+// SRS 7\.6: choosing Has Defects with nothing recorded opens the defects list\.\s+if \(selected == \'Has Defects\' && !_hasAnyDefect\) \{\s+await _openDefectCatalog\(\);\s+\}\s+\}'

def replacer(match):
    return '''  Future<void> _openStatusModal() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => DvirStatusModal(
        hasDefect: _hasAnyDefect,
        selectedStatus: _selectedStatus,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedStatus = selected);
    // SRS 7.6: choosing Has Defects with nothing recorded opens the defects list.
    if (selected == 'Has Defects' && !_hasAnyDefect) {
      await _openDefectCatalog();
    }
  }'''

new_content = re.sub(old_status_method_regex, replacer, content, flags=re.DOTALL)

import_statement = "import '../widgets/status_modal.dart';\n"
if import_statement not in new_content:
    new_content = new_content.replace("import '../../domain/entities/dvir_report.dart';", "import '../../domain/entities/dvir_report.dart';\n" + import_statement)

with open(source_file, 'w', encoding='utf-8') as f:
    f.write(new_content)

print('Updated dvir_form_page.dart with DvirStatusModal')
