import yaml
import re

with open('openapi.yaml', 'r', encoding='utf-8') as f:
    spec = yaml.safe_load(f)
openapi_paths = spec.get('paths', {})

with open('lib/backend/http/eld_endpoints.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern for constants
# static const String authSession = '/session';
const_pat = re.compile(r'static const String (\w+)\s*=\s*([^;]+);')

# Pattern for methods:
# static String dailyLogDetails(int logId) => '$_eld/daily-logs/$logId';
# or multi-line
method_pat = re.compile(r'static String (\w+)\(([^)]*)\)\s*=>\s*([^;]+);', re.MULTILINE | re.DOTALL)

items = []

for m in const_pat.finditer(content):
    name = m.group(1)
    val = m.group(2).strip()
    items.append(('const', name, None, val, m.start()))

for m in method_pat.finditer(content):
    name = m.group(1)
    params = m.group(2).strip()
    val = m.group(3).strip()
    items.append(('method', name, params, val, m.start()))

items.sort(key=lambda x: x[4])

def resolve_val(val):
    val = val.replace("$_eld", "/eld").replace("$inspections", "/eld/inspections")
    val = re.sub(r'\s+', ' ', val)
    val = val.strip("'\"")
    return val

def norm_param(val):
    return re.sub(r'\$[a-zA-Z0-9_]+', '{param}', val)

def norm_openapi(p):
    return re.sub(r'\{[^}]+\}', '{param}', p)

norm_spec = {norm_openapi(p): p for p in openapi_paths}

print(f"{'Type':<7} | {'Name':<28} | {'Resolved Route':<55} | {'OpenAPI Route / Status'}")
print("-" * 130)

for kind, name, params, raw_val, _ in items:
    resolved = resolve_val(raw_val)
    norm = norm_param(resolved)
    
    status = ""
    if not resolved.startswith('/eld'):
        if name in ['session', 'status', 'recordDutyStatus', 'graphGridTimeline']:
            status = f"ALIAS -> {resolved}"
        elif kind == 'method' and ('eldSession' in resolved or 'legacyEdit' in resolved):
            status = f"ALIAS METHOD -> {resolved}"
        else:
            status = "TRACCAR / INTERNAL CORE"
    elif resolved in openapi_paths:
        status = f"EXACT: {resolved} [{','.join(openapi_paths[resolved].keys())}]"
    elif norm in norm_spec:
        matched = norm_spec[norm]
        status = f"PARAM: {matched} [{','.join(openapi_paths[matched].keys())}]"
    else:
        status = "NOT FOUND IN OPENAPI.YAML"
        
    print(f"{kind:<7} | {name:<28} | {resolved:<55} | {status}")
