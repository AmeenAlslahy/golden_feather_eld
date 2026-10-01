import re

source_file = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Truncate the file by removing from _buildFieldGroup down to the end of the class
methods_regex = r'  Widget _buildFieldGroup.*\}\n\}\n'
content = re.sub(methods_regex, '}\n', content, flags=re.DOTALL)

# 2. Add the _buildCatalogDefects back to the class (since it needs state to update the _selectedDefects list)
# Wait, it's easier to just do string replacements on usages instead of deleting methods and rewriting them from scratch. Let's undo.
