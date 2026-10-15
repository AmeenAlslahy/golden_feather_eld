import os
import re

patterns = [
    ('AppButton_label', re.compile(r'''\bAppButton\s*\([^)]*label\s*:\s*['"]([^'"]+)['"]''', re.DOTALL)),
    ('Text_widget', re.compile(r'''\bText\s*\(\s*['"]([^'"]+)['"]''')),
    ('InfoRow_label', re.compile(r'''\bEldInfoRow\s*\([^)]*label\s*:\s*['"]([^'"]+)['"]''', re.DOTALL)),
    ('Input_label', re.compile(r'''\b(?:labelText|hintText|helperText|title|subtitle)\s*:\s*['"]([^'"]+)['"]''')),
]

ignore_set = {
    '—', '-', '+', ':', '/', '%', '•', '\u2022', '00:00', 'HH:mm', 'AM', 'PM',
    'ELD', 'VIN', 'DOT', 'FMCSA', 'HOS', 'GPS', 'ECM', 'UTC', 'PT30', 'OBD',
    'USA 70/8', 'CAN 70/8', 'XML', 'CSV', 'PDF', 'V', 'T', 'D', 'N', 'M',
    'Unknown', 'Location', 'Traccar',
}

results = []

for root, _, files in os.walk('lib'):
    if 'presentation' not in root and 'core/widgets' not in root:
        continue
    for file in files:
        if not file.endswith('.dart'):
            continue
        filepath = os.path.join(root, file).replace('\\', '/')
        with open(filepath, 'r', encoding='utf-8') as f:
            content = f.read()
            lines = content.split('\n')
        
        for idx, line in enumerate(lines, 1):
            s = line.strip()
            if s.startswith('//') or s.startswith('*'):
                continue
            
            # Simple line-by-line checks
            for p_name, p_reg in [
                ('Text', re.compile(r'''\bText\s*\(\s*['"]([^'"]+)['"]''')),
                ('Attribute', re.compile(r'''\b(?:labelText|hintText|helperText|title|subtitle|label)\s*:\s*['"]([^'"]+)['"]''')),
            ]:
                for m in p_reg.finditer(line):
                    val = m.group(1).strip()
                    if val in ignore_set or re.match(r'^[0-9\s\.\:\,\-\_\/\%\#\$\@\*\+\=\(\)\\\u2022]+$', val):
                        continue
                    if val.startswith('http') or val.startswith('package:') or val.startswith('assets/'):
                        continue
                    results.append((filepath, idx, p_name, val, s))

print(f'Total findings: {len(results)}')
with open('scripts/all_unlocalized_attributes.txt', 'w', encoding='utf-8') as out:
    for item in results:
        out.write(f'{item[0]}:{item[1]} [{item[2]}] -> "{item[3]}" | Line: {item[4]}\n')

for item in results:
    print(f'{item[0]}:{item[1]} [{item[2]}] -> "{item[3]}"')
