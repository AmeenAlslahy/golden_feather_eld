import re

source_file = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
dest_file = 'lib/features/dvir/presentation/widgets/defects_modal.dart'

with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()

# Capture _DefectCatalogDialogState until the end of the file or next class
match = re.search(r'class _DefectCatalogDialogState extends ConsumerState<_DefectCatalogDialog> \{.*?\}\n\}\n', content, re.DOTALL)

if match:
    state_code = match.group(0)
    
    # Remove it from source
    content = content.replace(state_code, '')
    with open(source_file, 'w', encoding='utf-8') as f:
        f.write(content)
        
    # Fix the state code class names
    state_code = state_code.replace('_DefectCatalogDialogState', 'DefectCatalogDialogState')
    state_code = state_code.replace('_DefectCatalogDialog', 'DefectCatalogDialog')
    
    # Append to dest
    with open(dest_file, 'a', encoding='utf-8') as f:
        f.write('\n' + state_code)
        
    print('Successfully moved DefectCatalogDialogState.')
else:
    print('Could not find _DefectCatalogDialogState in source.')
