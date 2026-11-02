import yaml
import re

with open('openapi.yaml', 'r', encoding='utf-8') as f:
    spec = yaml.safe_load(f)
openapi_paths = spec.get('paths', {})

with open('lib/backend/http/eld_endpoints.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Parse constants
const_pat = re.compile(r'static const String (\w+)\s*=\s*([^;]+);')
# Parse methods
method_pat = re.compile(r'static String (\w+)\(([^)]*)\)\s*=>\s*([^;]+);', re.MULTILINE | re.DOTALL)

items = []
for m in const_pat.finditer(content):
    name = m.group(1)
    if name == '_eld': continue
    val = m.group(2).strip()
    items.append(('const', name, None, val, m.start()))

for m in method_pat.finditer(content):
    name = m.group(1)
    params = m.group(2).strip()
    val = m.group(3).strip()
    items.append(('method', name, params, val, m.start()))

items.sort(key=lambda x: x[4])

def resolve_val(raw_val):
    val = raw_val.replace("$_eld", "/eld").replace("$inspections", "/eld/inspections")
    val = re.sub(r'\s+', ' ', val).strip("'\"")
    # Resolve aliases
    if val == 'authSession': return '/session'
    if val == 'statusDashboard': return '/eld/hos/dashboard'
    if val == 'recordDutyStatusEvent': return '/eld/hos'
    if val == 'legacyGraphGridTimeline': return '/eld/duty-status/graph-grid'
    if 'eldSession(' in val: return '/eld/sessions/$driverId'
    if 'legacyEditDutyStatus(' in val: return '/eld/duty-status/$statusId'
    if 'legacyEditDutyStatusForm(' in val: return '/eld/duty-status/$statusId/edit-form'
    return val

def norm_param(val):
    return re.sub(r'\$[a-zA-Z0-9_]+', '{param}', val)

def norm_openapi(p):
    return re.sub(r'\{[^}]+\}', '{param}', p)

norm_spec = {norm_openapi(p): p for p in openapi_paths}

results = []

for kind, name, params, raw_val, _ in items:
    route = resolve_val(raw_val)
    norm = norm_param(route)
    
    # Check Traccar
    if not route.startswith('/eld'):
        results.append({
            'name': name,
            'type': kind,
            'params': params,
            'route': route,
            'category': 'Traccar Core',
            'spec_match': 'N/A (Traccar standard)',
            'status': 'OK (Standard Traccar GPS/Session endpoint)',
            'issue': None
        })
        continue

    # Check match with OpenAPI
    if route in openapi_paths:
        methods = list(openapi_paths[route].keys())
        results.append({
            'name': name,
            'type': kind,
            'params': params,
            'route': route,
            'category': 'ELD Exact Match',
            'spec_match': f"{route} ({methods})",
            'status': 'MATCH',
            'issue': None
        })
    elif norm in norm_spec:
        matched_spec = norm_spec[norm]
        methods = list(openapi_paths[matched_spec].keys())
        results.append({
            'name': name,
            'type': kind,
            'params': params,
            'route': route,
            'category': 'ELD Param Match',
            'spec_match': f"{matched_spec} ({methods})",
            'status': 'MATCH',
            'issue': None
        })
    else:
        # Investigate mismatch
        issue = "Path not found in openapi.yaml"
        category = "MISMATCH / EXTENSION"
        suggested = None
        
        # Check known discrepancies
        if 'unidentified' in route:
            suggested = route.replace('/eld/unidentified', '/eld/unidentified-events')
            issue = f"OpenAPI uses '/eld/unidentified-events'. Should be: {suggested}"
        elif 'vehicles' in route and 'company-vehicles' not in route:
            suggested = route.replace('/eld/vehicles', '/eld/company-vehicles')
            issue = f"OpenAPI uses '/eld/company-vehicles'. Should be: {suggested}"
        elif '/eld/inspections' in route:
            suggested = route.replace('/eld/inspections', '/eld/dot-inspection')
            issue = f"OpenAPI uses '/eld/dot-inspection'. Should be: {suggested}"
        elif route == '/eld/transfer/email-logs':
            suggested = '/eld/dot-inspection/email-logs'
            issue = f"OpenAPI uses '/eld/dot-inspection/email-logs'"
        elif '/eld/hos' in route:
            if route == '/eld/hos/dashboard': suggested = '/eld/status'
            elif route == '/eld/hos/recap': suggested = '/eld/status/recap'
            elif route == '/eld/hos/status': suggested = '/eld/status/duty-status'
            elif route == '/eld/hos': suggested = '/eld/duty-status'
            issue = f"Spec uses '{suggested}'. '/eld/hos' is from non-standard/unimplemented HOS draft."
        elif route == '/eld/driver-rules':
            suggested = '/eld/rules-screen'
            issue = f"OpenAPI uses '/eld/rules-screen'"
        elif route == '/eld/sessions/connect':
            suggested = '/eld/hardware/connect'
            issue = f"OpenAPI uses '/eld/hardware/connect?uniqueId=...'"
        elif route == '/eld/sessions/disconnect':
            suggested = '/eld/hardware/connect?disconnected=true'
            issue = f"No disconnect route in OpenAPI. Disconnect is done via hardware connect query param"
        elif 'dvir/previous' in route:
            suggested = '/eld/dvir/pre-trip/{uniqueId} or /eld/dvir/{id}/review'
            issue = f"Spec uses '/eld/dvir/pre-trip/{{uniqueId}}' for previous and '/eld/dvir/{{id}}/review' for review."
        elif 'dvir/sync' in route:
            issue = "Offline sync endpoint not in OpenAPI (custom client-side/unimplemented)"
        elif 'dvir/defects' in route:
            issue = "DVIR defect details/vehicle defects endpoints not in OpenAPI"
        elif 'daily-logs' in route and ('/options' in route or '/events' in route or '/summary' in route):
            issue = f"Drafted in daily-log spec proposal, but NOT deployed in OpenAPI or live server (server has /graph-grid)"

        results.append({
            'name': name,
            'type': kind,
            'params': params,
            'route': route,
            'category': category,
            'spec_match': suggested or 'NONE',
            'status': 'MISMATCH',
            'issue': issue
        })

print(f"Total analyzed: {len(results)}")
matches = [r for r in results if r['status'] == 'MATCH']
mismatches = [r for r in results if r['status'] == 'MISMATCH']
traccar = [r for r in results if r['status'].startswith('OK')]

print(f"Matches with OpenAPI: {len(matches)}")
print(f"Traccar Core: {len(traccar)}")
print(f"Mismatches / Not in OpenAPI: {len(mismatches)}")
print("\n" + "="*80)
print("MISMATCH DETAILS:")
print("="*80)
for m in mismatches:
    print(f"[-] {m['name']} ({m['route']})")
    print(f"    Issue: {m['issue']}")
    print(f"    Expected: {m['spec_match']}\n")
