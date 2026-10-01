import os
import re

source_file = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
dest_file = 'lib/features/dvir/presentation/widgets/defect_card.dart'

with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()

defect_card_code = '''import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/theme_extension.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/dvir_report.dart';

class DefectCard extends StatelessWidget {
  final DvirDefectSelection defect;
  final Color textColor;
  final bool readOnly;
  final VoidCallback onRemove;

  const DefectCard({
    super.key,
    required this.defect,
    required this.textColor,
    required this.readOnly,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Icon(
            defect.item.critical
                ? Icons.warning_amber_rounded
                : Icons.build_outlined,
            size: 16,
            color: defect.item.critical
                ? AppColors.dangerRed
                : textColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              (defect.description ?? '').trim().isEmpty
                  ? defect.item.label(loc)
                  : ' — ',
              style: context.styles.subtitle,
            ),
          ),
          if (!readOnly)
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: AppColors.dangerRed),
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
'''

with open(dest_file, 'w', encoding='utf-8') as f:
    f.write(defect_card_code)

print('Created defect_card.dart successfully')

old_defect_card_regex = r'                Padding\(\s+key: Key\(\'dvir_defect_card_\$\{d\.item\.code\}\'\),\s+padding: const EdgeInsets\.only\(top: 8\),\s+child: Row\(\s+children: \[\s+Icon\(\s+d\.item\.critical\s+\?\s+Icons\.warning_amber_rounded\s+:\s+Icons\.build_outlined,\s+size: 16,\s+color: d\.item\.critical\s+\?\s+AppColors\.dangerRed\s+:\s+textColor,\s+\),\s+const SizedBox\(width: 8\),\s+Expanded\(\s+child: Text\(\s+\(d\.description \?\? \'\'\)\.trim\(\)\.isEmpty\s+\?\s+d\.item\.label\(loc\)\s+:\s+\'\$\{d\.item\.label\(loc\)\}  \$\{d\.description!\.trim\(\)\}\',\s+style: context\.styles\.subtitle,\s+\),\s+\),\s+if \(!_readOnly\)\s+IconButton\(\s+icon: const Icon\(\s+Icons\.remove_circle_outline,\s+color: AppColors\.dangerRed,\s+\),\s+onPressed: \(\) \{\s+setState\(\(\) \{\s+_selectedDefects\.remove\(d\);\s+if \(_selectedDefects\.isEmpty\) \{\s+_selectedStatus = \'Vehicle Condition Satisfactory\';\s+\}\s+\}\);\s+\},\s+\),\s+\],\s+\),\s+\),'

def replacer(match):
    return '''                DefectCard(
                  key: Key('dvir_defect_card_'),
                  defect: d,
                  textColor: textColor,
                  readOnly: _readOnly,
                  onRemove: () {
                    setState(() {
                      _selectedDefects.remove(d);
                      if (_selectedDefects.isEmpty) {
                        _selectedStatus = 'Vehicle Condition Satisfactory';
                      }
                    });
                  },
                ),'''

new_content = re.sub(old_defect_card_regex, replacer, content, flags=re.DOTALL)

import_statement = "import '../widgets/defect_card.dart';\n"
if import_statement not in new_content:
    new_content = new_content.replace("import '../../domain/entities/dvir_report.dart';", "import '../../domain/entities/dvir_report.dart';\n" + import_statement)

with open(source_file, 'w', encoding='utf-8') as f:
    f.write(new_content)

print('Updated dvir_form_page.dart with DefectCard')
