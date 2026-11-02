import yaml
import re
import os

with open('openapi.yaml', 'r', encoding='utf-8') as f:
    spec = yaml.safe_load(f)
openapi_paths = spec.get('paths', {})

with open('lib/backend/http/eld_endpoints.dart', 'r', encoding='utf-8') as f:
    lines = f.readlines()

# Collect definitions with their line numbers and doc comments
definitions = []
current_docs = []

for idx, line in enumerate(lines, 1):
    stripped = line.strip()
    if stripped.startswith('///'):
        current_docs.append(stripped)
    elif stripped.startswith('static const String ') or stripped.startswith('static String '):
        is_deprecated = False
        if idx >= 2 and '@Deprecated' in lines[idx-2]:
            is_deprecated = True
        definitions.append({
            'line': idx,
            'code': stripped,
            'docs': "\n".join(current_docs),
            'deprecated': is_deprecated
        })
        current_docs = []
    elif not stripped:
        pass
    else:
        current_docs = []

print(f"Total endpoints defined: {len(definitions)}")

# Search lib for usages
usages = {}
for root, dirs, files in os.walk('lib'):
    for file in files:
        if file.endswith('.dart'):
            filepath = os.path.join(root, file).replace('\\', '/')
            if 'eld_endpoints.dart' in filepath:
                continue
            with open(filepath, 'r', encoding='utf-8', errors='ignore') as f:
                content = f.read()
            for d in definitions:
                # get identifier
                m = re.search(r'static (?:const String|String) (\w+)', d['code'])
                if m:
                    ident = m.group(1)
                    if f'EldEndpoints.{ident}' in content:
                        usages.setdefault(ident, []).append(filepath)

# Now report details
print(f"{'Line':<5} | {'Identifier':<25} | {'Value / Pattern':<45} | {'Usages':<6} | {'OpenAPI status'}")
print("-" * 120)

for d in definitions:
    m = re.search(r'static (?:const String|String) (\w+)(?:\(([^)]*)\))?\s*(?:=\s*([^;]+)|=>\s*([^;]+));', d['code'])
    if not m:
        continue
    ident = m.group(1)
    params = m.group(2)
    val = m.group(3) or m.group(4)
    val = val.strip().replace("$_eld", "/eld").replace("$inspections", "/eld/inspections").strip("'\"")
    
    use_count = len(usages.get(ident, []))
    
    # Check openapi match
    norm_val = re.sub(r'\$[a-zA-Z0-9_]+', '{param}', val)
    
    match_status = "UNKNOWN"
    if not val.startswith('/eld'):
        match_status = "TRACCAR CORE"
    elif val in openapi_paths:
        match_status = f"MATCH EXACT ({','.join(openapi_paths[val].keys())})"
    else:
        # check parameterized
        found = False
        for op in openapi_paths:
            norm_op = re.sub(r'\{[^}]+\}', '{param}', op)
            if norm_op == norm_val:
                match_status = f"MATCH PARAM -> {op} ({','.join(openapi_paths[op].keys())})"
                found = True
                break
        if not found:
            match_status = "NOT IN OPENAPI"
            
    dep_str = "[DEP] " if d['deprecated'] else ""
    print(f"{d['line']:<5} | {dep_str + ident:<25} | {val:<45} | {use_count:<6} | {match_status}")
