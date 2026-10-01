import re

source_file = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
dest_file = 'lib/features/dvir/presentation/widgets/dvir_form_components.dart'

with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()

components_code = '''import 'package:flutter/material.dart';
import '../../../../core/utils/theme_extension.dart';

class DvirFieldGroup extends StatelessWidget {
  final String title;
  final Widget child;
  final Color borderColor;

  const DvirFieldGroup({
    super.key,
    required this.title,
    required this.child,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.styles.sectionTitle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class DvirCell extends StatelessWidget {
  final String title;
  final Widget child;
  final Color borderColor;

  const DvirCell({
    super.key,
    required this.title,
    required this.child,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.styles.sectionTitle),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class DvirTwoColumn extends StatelessWidget {
  final Widget left;
  final Widget right;

  const DvirTwoColumn({
    super.key,
    required this.left,
    required this.right,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 32),
          Expanded(child: right),
        ],
      ),
    );
  }
}

class DvirFlatTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;
  final bool readOnly;

  const DvirFlatTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: context.styles.body,
      readOnly: readOnly,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.styles.subtitle,
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }
}
'''

with open(dest_file, 'w', encoding='utf-8') as f:
    f.write(components_code)

print('Created dvir_form_components.dart successfully')

# Update dvir_form_page.dart
content = re.sub(r'  Widget _buildFieldGroup.*?_buildFlatTextField.*?\}\n  \}\n', '', content, flags=re.DOTALL)

# Replace usage
content = content.replace('_buildFieldGroup(', 'DvirFieldGroup(')
content = content.replace('_buildCell(', 'DvirCell(')
content = content.replace('_buildTwoColumn(', 'DvirTwoColumn(')
content = content.replace('_buildFlatTextField(', 'DvirFlatTextField(')

# The signature of DvirFieldGroup doesn't have textColor param.
# Let's clean that up with regex
content = re.sub(r'textColor: textColor,\s*', '', content)
content = re.sub(r'textColor: textColor\s*', '', content)

import_statement = "import '../widgets/dvir_form_components.dart';\n"
if import_statement not in content:
    content = content.replace("import '../widgets/status_modal.dart';", "import '../widgets/status_modal.dart';\n" + import_statement)
    
# Fix DefectCard inside _buildCatalogDefects
old_defect_row = r'                Padding\(\s*key: Key\(\'dvir_defect_card_\$\{d\.item\.code\}\'\),\s*padding: const EdgeInsets\.only\(top: 8\),\s*child: Row\(.*?\),\s*\),\s*\]'

def replacer(match):
    return '''                DefectCard(
                  key: Key('dvir_defect_card_'),
                  defect: d,
                  textColor: textColor,
                  readOnly: _readOnly,
                  onRemove: () {
                    setState(() {
                      _selectedDefects = _selectedDefects.where((x) => x != d).toList();
                      if (_selectedDefects.isEmpty) {
                        _selectedStatus = 'Vehicle Condition Satisfactory';
                      }
                    });
                  },
                ),
            ]'''

content = re.sub(old_defect_row, replacer, content, flags=re.DOTALL)

import_defect_card = "import '../widgets/defect_card.dart';\n"
if import_defect_card not in content:
    content = content.replace("import '../widgets/status_modal.dart';", "import '../widgets/status_modal.dart';\n" + import_defect_card)

with open(source_file, 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated dvir_form_page.dart successfully')
