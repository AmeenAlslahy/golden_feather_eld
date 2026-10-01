def add_import(filepath, imp):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    if imp not in content:
        content = imp + content
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)

add_import('lib/features/dvir/presentation/widgets/defect_card.dart', "import '../../domain/dvir_catalog.dart';\n")
add_import('lib/features/dvir/presentation/widgets/defects_modal.dart', "import '../providers/dvir_provider.dart';\n")

print('Imports fixed.')
