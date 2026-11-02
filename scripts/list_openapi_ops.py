import yaml

with open('openapi.yaml', 'r', encoding='utf-8') as f:
    spec = yaml.safe_load(f)

paths = spec.get('paths', {})

print(f"Total paths in openapi.yaml: {len(paths)}")

for p, methods in sorted(paths.items()):
    for m, details in methods.items():
        summary = details.get('summary', '')
        tags = details.get('tags', [])
        tag_str = tags[0] if tags else 'NO TAG'
        print(f"{m.upper():<6} {p:<50} | {tag_str[:35]}")
