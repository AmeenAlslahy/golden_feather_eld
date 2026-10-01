import re

source_file = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the leftover methods from line 629 to the end, but keep _buildCatalogDefects?
# Wait, if I remove _buildCatalogDefects, I have to extract it, but _buildCatalogDefects is 50 lines.
# Instead of complicated regex, let's just truncate the file from '  Widget DvirFieldGroup({' downwards and just write the end of the class.

lines = content.split('\n')
end_index = -1
for i, line in enumerate(lines):
    if '  Widget DvirFieldGroup({' in line:
        end_index = i
        break

if end_index != -1:
    lines = lines[:end_index]
    lines.append('}')
    content = '\n'.join(lines)
    
    with open(source_file, 'w', encoding='utf-8') as f:
        f.write(content)
    print('Truncated leftover methods.')
else:
    print('Could not find DvirFieldGroup.')
