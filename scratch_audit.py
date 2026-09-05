import json
import os

with open('audit_evidence.json', 'r', encoding='utf-8') as f:
    evidence = json.load(f)

areas = {
    'auth': ['auth', 'login', 'register', 'session'],
    'connection': ['hardware', 'bluetooth', 'connection', 'traccar', 'device', 'native'],
    'account': ['account', 'profile', 'carrier', 'company', 'preference'],
    'navigation': ['route', 'nav', 'menu', 'drawer', 'home'],
    'dashboard': ['dashboard', 'status', 'grid', 'chart', 'time'],
    'hos': ['hos', 'rules', 'fmcsa', 'violation', 'calculator', 'cycle', 'restart'],
    'logs': ['log', 'daily', 'record'],
    'duty': ['duty', 'event', 'status'],
    'form': ['form', 'trip', 'codriver', 'trailer', 'shipping'],
    'cert': ['certify', 'signature', 'sign'],
    'dvir': ['dvir', 'inspection', 'defect', 'pti'],
    'dot': ['dot', 'inspection', 'unidentified'],
    'packet': ['packet', 'info', 'manual', 'instruction'],
    'transfer': ['transfer', 'export', 'email', 'webservice'],
    'vehicle': ['vehicle', 'truck'],
    'about': ['about', 'diagnostic', 'version']
}

summary = {}
for area, keywords in areas.items():
    summary[area] = {'files': set(), 'classes': set(), 'apis': set(), 'mocks': set(), 'todos': set()}
    
for f in evidence.get('files', []):
    for area, kws in areas.items():
        if any(kw in f.lower() for kw in kws):
            summary[area]['files'].add(f)

classes_data = evidence.get('classes', {})
if isinstance(classes_data, dict):
    for cls, data in classes_data.items():
        for area, kws in areas.items():
            if isinstance(data, dict):
                if any(kw in cls.lower() for kw in kws) or any(kw in data.get('file', '').lower() for kw in kws):
                    summary[area]['classes'].add(f"{cls} ({data.get('file', '')})")
elif isinstance(classes_data, list):
    for item in classes_data:
        # if item is a dict with 'name'
        if isinstance(item, dict):
            cls_name = item.get('name', '')
            for area, kws in areas.items():
                if any(kw in cls_name.lower() for kw in kws) or any(kw in item.get('file', '').lower() for kw in kws):
                    summary[area]['classes'].add(f"{cls_name} ({item.get('file', '')})")
        elif isinstance(item, str):
            for area, kws in areas.items():
                if any(kw in item.lower() for kw in kws):
                    summary[area]['classes'].add(item)

for api in evidence.get('apis', []):
    for area, kws in areas.items():
        if any(kw in api.lower() for kw in kws):
            summary[area]['apis'].add(api)

for mock in evidence.get('mocks', []):
    for area, kws in areas.items():
        if any(kw in str(mock).lower() for kw in kws):
            summary[area]['mocks'].add(str(mock))
            
for todo in evidence.get('todos', []):
    for area, kws in areas.items():
        if any(kw in str(todo).lower() for kw in kws):
            summary[area]['todos'].add(str(todo))

with open('audit_summary_output.txt', 'w', encoding='utf-8') as out:
    for area, data in summary.items():
        out.write(f"=== {area.upper()} ===\n")
        out.write(f"Files ({len(data['files'])}):\n")
        for x in sorted(list(data['files'])): out.write(f"  {x}\n")
        out.write(f"Classes ({len(data['classes'])}):\n")
        for x in sorted(list(data['classes'])): out.write(f"  {x}\n")
        out.write(f"APIs ({len(data['apis'])}):\n")
        for x in sorted(list(data['apis'])): out.write(f"  {x}\n")
        out.write(f"Mocks ({len(data['mocks'])}):\n")
        for x in sorted(list(data['mocks'])): out.write(f"  {x}\n")
        out.write(f"TODOs ({len(data['todos'])}):\n")
        for x in sorted(list(data['todos'])): out.write(f"  {x}\n")
        out.write("\n")

print("Generated audit_summary_output.txt")
