import glob
import re

files = glob.glob(r"d:\Flutter projects\golden_feather_eld\docs\as_built_flowcharts\*.mmd")

for f in files:
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
        
    # 1. Quote ([ ... ])
    content = re.sub(r'\(\[(.*?)\]\)', lambda m: f'([{m.group(1)}])' if m.group(1).startswith('"') else f'(["{m.group(1)}"])', content)
    # 2. Quote [( ... )]
    content = re.sub(r'\[\((.*?)\)\]', lambda m: f'[({m.group(1)})]' if m.group(1).startswith('"') else f'[("{m.group(1)}")]', content)
    # 3. Quote { ... }
    content = re.sub(r'\{(.*?)\}', lambda m: f'{{{m.group(1)}}}' if m.group(1).startswith('"') else f'{{"{m.group(1)}"}}', content)
    
    # 4. Quote [ ... ]
    def fix_brackets(m):
        val = m.group(1)
        if val.startswith('"') and val.endswith('"'): return f'[{val}]'
        if val.startswith('("') and val.endswith('")'): return f'[{val}]'
        val = val.replace('"', "'")
        return f'["{val}"]'
        
    content = re.sub(r'\[([^\[\]]+)\]', fix_brackets, content)

    # Write back
    with open(f, 'w', encoding='utf-8') as file:
        file.write(content)
print("MMD files fixed")
