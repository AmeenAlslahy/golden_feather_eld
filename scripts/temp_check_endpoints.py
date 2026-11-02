import yaml
import re
import os

with open('openapi.yaml', 'r', encoding='utf-8') as f:
    spec = yaml.safe_load(f)
openapi_paths = spec.get('paths', {})

with open('lib/backend/http/eld_endpoints.dart', 'r', encoding='utf-8') as f:
    eld_content = f.read()

# Extract constants
const_pattern = re.compile(r'static const String (\w+)\s*=\s*([^;]+);')
constants = {}
for name, val in const_pattern.findall(eld_content):
    val = val.strip().strip("'\"")
    # Resolve simple variable substitutions
    if name == 'session':
        val = '/session'
    elif name == 'status':
        val = '/eld/hos/dashboard'
    elif name == 'recordDutyStatus':
        val = '/eld/hos'
    elif name == 'graphGridTimeline':
        val = '/eld/duty-status/graph-grid'
    else:
        val = val.replace("$_eld", "/eld").replace("$inspections", "/eld/inspections")
        val = val.replace("'", "").replace('"', '').strip()
    constants[name] = val

# Extract methods
method_pattern = re.compile(r'static String (\w+)\(([^)]*)\)\s*=>\s*([^;]+);')
methods = {}
for name, params, expr in method_pattern.findall(eld_content):
    expr = expr.strip().strip("'\"")
    expr = expr.replace("$_eld", "/eld").replace("'", "").replace('"', '').strip()
    methods[name] = (params.strip(), expr)

print("Total constants:", len(constants))
print("Total methods:", len(methods))

print("\n--- MATCHING WITH OPENAPI.YAML ---")
# Build a normalized map of openapi routes
# e.g., /eld/daily-logs/{id} -> /eld/daily-logs/{param}
def normalize_openapi(p):
    return re.sub(r'\{[^}]+\}', '{param}', p)

def normalize_method_expr(expr):
    # e.g. /eld/daily-logs/$logId/carrier-edits/$editId/respond -> /eld/daily-logs/{param}/carrier-edits/{param}/respond
    res = re.sub(r'\$[a-zA-Z0-9_]+', '{param}', expr)
    return res

norm_openapi = {normalize_openapi(p): p for p in openapi_paths}

print("\n[1] CONSTANTS vs OPENAPI:")
for name, path in sorted(constants.items()):
    # Ignore Traccar core routes
    if not path.startswith('/eld'):
        print(f"  [TRACCAR CORE] {name}: {path}")
        continue
    if path in openapi_paths:
        methods_allowed = list(openapi_paths[path].keys())
        print(f"  [EXACT MATCH] {name}: {path} (Methods in spec: {methods_allowed})")
    else:
        print(f"  [NOT IN OPENAPI] {name}: {path}")

print("\n[2] METHODS vs OPENAPI:")
for name, (params, expr) in sorted(methods.items()):
    norm = normalize_method_expr(expr)
    if norm in norm_openapi:
        matched_spec = norm_openapi[norm]
        methods_allowed = list(openapi_paths[matched_spec].keys())
        print(f"  [MATCH] {name}({params}) -> {expr} === matches {matched_spec} (Spec: {methods_allowed})")
    else:
        print(f"  [NO MATCH IN OPENAPI] {name}({params}) -> {expr} (norm: {norm})")

print("\n[3] OPENAPI PATHS NOT IN ELD_ENDPOINTS:")
all_app_routes = set(constants.values()) | {normalize_method_expr(expr) for _, expr in methods.values()}
norm_app_routes = {normalize_openapi(r): r for r in all_app_routes}

missing_from_eld = []
for p in sorted(openapi_paths.keys()):
    norm_p = normalize_openapi(p)
    if norm_p not in norm_app_routes and p not in all_app_routes:
        missing_from_eld.append((p, list(openapi_paths[p].keys())))

for p, m in missing_from_eld:
    print(f"  [SPEC NOT IN DART] {p} ({m})")
