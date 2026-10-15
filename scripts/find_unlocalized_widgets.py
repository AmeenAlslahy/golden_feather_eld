import os
import re

# Match Text('...') or Text("...")
# Match const Text('...')
# Ignore Text('${...}') or Text(variable)
text_regex = re.compile(r'''\bText\(\s*['"]([^'"]+)['"]''')

# Ignore strings that are numbers, symbols, spaces, date formats, or short acronyms
ignore_set = {
    '—', '-', '+', ':', '/', '%', '•', '\u2022', '00:00', 'HH:mm', 'AM', 'PM',
    'ELD', 'VIN', 'DOT', 'FMCSA', 'HOS', 'GPS', 'ECM', 'UTC', 'PT30', 'OBD',
    'USA 70/8', 'CAN 70/8', 'XML', 'CSV', 'PDF', 'V', 'T', 'D', 'N', 'M',
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '0',
    'Unknown', 'Location',
}

unlocalized = []

for root, _, files in os.walk('lib'):
    # Focus on presentation layer: pages, widgets
    if 'presentation' not in root and 'core/widgets' not in root:
        continue
    for file in files:
        if not file.endswith('.dart'):
            continue
        filepath = os.path.join(root, file).replace('\\', '/')
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        for idx, line in enumerate(lines, 1):
            s = line.strip()
            if s.startswith('//') or s.startswith('*'):
                continue
            for m in text_regex.finditer(line):
                txt = m.group(1).strip()
                if not txt:
                    continue
                if txt in ignore_set:
                    continue
                # If it is only digits or punctuation
                if re.match(r'^[0-9\s\.\:\,\-\_\/\%\#\$\@\*\+\=\(\)\\\u2022]+$', txt):
                    continue
                unlocalized.append((filepath, idx, txt, s))

print(f'Total unlocalized Text widgets found: {len(unlocalized)}')
with open('scripts/unlocalized_text_report.txt', 'w', encoding='utf-8') as out:
    for item in unlocalized:
        out.write(f'{item[0]}:{item[1]} -> "{item[2]}" | Line: {item[3]}\n')

for item in unlocalized[:30]:
    print(f'{item[0]}:{item[1]} -> "{item[2]}"')
