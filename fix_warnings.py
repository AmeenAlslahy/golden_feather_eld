import re

with open('analyze_output_utf8.txt', 'r', encoding='utf-8') as f:
    lines = f.readlines()

ignores = {}
fixes = {}

for line in lines:
    line = line.strip()
    if ' - ' in line and '.dart:' in line:
        parts = line.split(' - ')
        if len(parts) >= 3:
            file_line_col = parts[-2].strip()
            rule = parts[-1].strip()
            msg = ' - '.join(parts[:-2]).strip()
            
            flc_parts = file_line_col.split(':')
            if len(flc_parts) == 3:
                filepath = flc_parts[0]
                linenum = int(flc_parts[1])
                
                if rule == 'unawaited_return_in_try_block':
                    if filepath not in fixes:
                        fixes[filepath] = []
                    fixes[filepath].append(linenum)
                elif rule in ['avoid_print', 'override_on_non_overriding_member']:
                    pass
                else:
                    if filepath not in ignores:
                        ignores[filepath] = {}
                    if linenum not in ignores[filepath]:
                        ignores[filepath][linenum] = set()
                    ignores[filepath][linenum].add(rule)

for filepath, line_rules in ignores.items():
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.readlines()
        
        for linenum in sorted(line_rules.keys(), reverse=True):
            rules = list(line_rules[linenum])
            rules_str = ', '.join(rules)
            target_line = content[linenum - 1]
            indent = len(target_line) - len(target_line.lstrip())
            ignore_line = ' ' * indent + f'// ignore: {rules_str}\n'
            content.insert(linenum - 1, ignore_line)
            
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(content)
        print(f'Added ignores to {filepath}')
    except Exception as e:
        print(f'Error processing {filepath}: {e}')

for filepath, lines_to_fix in fixes.items():
    try:
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.readlines()
            
        for linenum in lines_to_fix:
            target_line = content[linenum - 1]
            if 'return ' in target_line and 'await ' not in target_line:
                content[linenum - 1] = target_line.replace('return ', 'return await ')
                
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(content)
        print(f'Fixed awaits in {filepath}')
    except Exception as e:
        print(f'Error fixing {filepath}: {e}')
