import os
import re

text_widget_pattern = re.compile(r'Text\(\s*[\'"]([^\'"]{2,})[\'"]')
title_pattern = re.compile(r'(?:title|labelText|hintText|tooltip|helperText)\s*:\s*[\'"]([^\'"]{2,})[\'"]')
arabic_pattern = re.compile(r'[\u0600-\u06FF]')

found = []

for root, _, files in os.walk('lib'):
    for file in files:
        if not file.endswith('.dart'):
            continue
        if 'l10n' in root:
            continue
        filepath = os.path.join(root, file).replace('\\', '/')
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        for idx, line in enumerate(lines, 1):
            stripped = line.strip()
            if stripped.startswith('//') or stripped.startswith('*') or 'AppLogger' in line:
                continue
            
            # Check Text('...')
            for m in text_widget_pattern.finditer(line):
                txt = m.group(1)
                if re.match(r'^[0-9\s\.\:\,\-\_\/\%\#\$\@\*\+\=\(\)]+$', txt):
                    continue
                found.append((filepath, idx, 'Text', txt, line.strip()))

            # Check title/labelText/hintText
            for m in title_pattern.finditer(line):
                txt = m.group(1)
                if re.match(r'^[0-9\s\.\:\,\-\_\/\%\#\$\@\*\+\=\(\)]+$', txt):
                    continue
                found.append((filepath, idx, 'Attribute', txt, line.strip()))
                
            # Check for any raw Arabic string outside l10n
            if arabic_pattern.search(line) and 'AppLogger' not in line and not stripped.startswith('//'):
                if 'context.loc' not in line and 'AppLocalizations' not in line:
                    found.append((filepath, idx, 'RawArabic', line.strip(), line.strip()))

# Deduplicate
unique_found = []
seen = set()
for item in found:
    key = (item[0], item[1], item[2])
    if key not in seen:
        seen.add(key)
        unique_found.append(item)

print(f'Total occurrences found: {len(unique_found)}')
with open('scripts/audit_strings_report.txt', 'w', encoding='utf-8') as out:
    for item in unique_found:
        out.write(f'{item[0]}:{item[1]} [{item[2]}] -> {item[3]}\n')
print('Written to scripts/audit_strings_report.txt')
