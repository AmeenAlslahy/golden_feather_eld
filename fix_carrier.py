import re

filepath = r'lib\features\logs\presentation\pages\carrier_edits_page.dart'
try:
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.readlines()
    
    # insert ignore on lines 181, 204, 224, 256
    lines_to_ignore = sorted([181, 204, 224, 256], reverse=True)
    for linenum in lines_to_ignore:
        target_line = content[linenum - 1]
        indent = len(target_line) - len(target_line.lstrip())
        ignore_line = ' ' * indent + f'// ignore: dead_null_aware_expression\n'
        content.insert(linenum - 1, ignore_line)
        
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(content)
    print(f'Added ignores to {filepath}')
except Exception as e:
    print(f'Error processing {filepath}: {e}')
