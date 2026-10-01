filepath = 'lib/features/dvir/presentation/widgets/defects_modal.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('_DefectCatalogDialogState', 'DefectCatalogDialogState')

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
