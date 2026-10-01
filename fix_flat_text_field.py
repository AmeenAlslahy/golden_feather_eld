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

# Replace _buildFlatTextField(controller, hint, textColor, keyboardType: keyboardType) -> DvirFlatTextField(controller: controller, hint: hint, keyboardType: keyboardType)
# This one requires regex since it's passing positional args to named args now, wait no, I made DvirFlatTextField have equired this.controller, required this.hint. So positional args in the widget? No, I defined equired this.controller so they are named arguments!
# But wait, _buildFlatTextField(controller, hint, textColor) had positional args!
# I need to change them to named arguments.
