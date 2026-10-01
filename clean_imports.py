def remove_import(filepath, imp):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    content = content.replace(imp, "")
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

remove_import('lib/features/dvir/presentation/widgets/defect_card.dart', "import '../../domain/entities/dvir_report.dart';\n")
remove_import('lib/features/dvir/presentation/widgets/defects_modal.dart', "import '../../domain/entities/dvir_report.dart';\n")
