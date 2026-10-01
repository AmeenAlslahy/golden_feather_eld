import re

source_file = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace _buildFieldGroup( -> DvirFieldGroup(
content = content.replace('_buildFieldGroup(', 'DvirFieldGroup(')
# Replace _buildCell( -> DvirCell(
content = content.replace('_buildCell(', 'DvirCell(')
# Replace _buildTwoColumn( -> DvirTwoColumn(
content = content.replace('_buildTwoColumn(', 'DvirTwoColumn(')

# Replace _buildFlatTextField(_xxxController, hint, textColor) -> DvirFlatTextField(controller: _xxxController, hint: hint, readOnly: _readOnly)
def flat_textfield_replacer(match):
    controller = match.group(1)
    hint = match.group(2)
    # Check if keyboardType is passed
    keyboardType = match.group(3)
    
    if keyboardType:
        return f"DvirFlatTextField(controller: {controller}, hint: {hint}, readOnly: _readOnly, {keyboardType})"
    else:
        return f"DvirFlatTextField(controller: {controller}, hint: {hint}, readOnly: _readOnly)"

content = re.sub(r'_buildFlatTextField\(\s*([^,]+),\s*([^,]+),\s*textColor(?:,\s*(keyboardType:\s*[^)]+))?\s*\)', flat_textfield_replacer, content)

# Remove the actual definitions at the bottom
content = re.sub(r'  Widget _buildFieldGroup\(.*?\}\n  \}\n', '}\n', content, flags=re.DOTALL)

# Also fix _buildCatalogDefects usage of DefectCard. Wait, _buildCatalogDefects wasn't matched above because it's above _buildFieldGroup.
# Let's fix the DefectCard row inside _buildCatalogDefects
old_defect_row = r'                Padding\(\s*key: Key\(\'dvir_defect_card_\$\{d\.item\.code\}\'\),\s*padding: const EdgeInsets\.only\(top: 8\),\s*child: Row\(\s*children: \[\s*Icon\(.*?setState\(\s*\(\) => _selectedDefects = _selectedDefects.*?toList\(\),\s*\),\s*\),\s*\](?:,\s*)?\s*\),\s*\),'

def replacer_row(match):
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
                ),'''

content = re.sub(old_defect_row, replacer_row, content, flags=re.DOTALL)

# Add imports
import_statement = "import '../widgets/dvir_form_components.dart';\nimport '../widgets/defect_card.dart';\n"
if "dvir_form_components.dart" not in content:
    content = content.replace("import '../widgets/signature_canvas.dart';", "import '../widgets/signature_canvas.dart';\n" + import_statement)

with open(source_file, 'w', encoding='utf-8') as f:
    f.write(content)

print('Updated dvir_form_page.dart successfully')
