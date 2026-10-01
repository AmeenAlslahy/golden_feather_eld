def fix_imports(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Remove bad imports
    content = content.replace("import '../../../../l10n/app_localizations.dart';", "")
    content = content.replace("import '../../../../core/utils/theme_extension.dart';", "")
    
    # Add good import
    good_import = "import '../../../../core/extensions/context_extensions.dart';\n"
    if good_import not in content:
        content = good_import + content

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(content)

fix_imports('lib/features/dvir/presentation/widgets/defect_card.dart')
fix_imports('lib/features/dvir/presentation/widgets/defects_modal.dart')
fix_imports('lib/features/dvir/presentation/widgets/signature_canvas.dart')
fix_imports('lib/features/dvir/presentation/widgets/status_modal.dart')

print('Imports fixed in all 4 widgets.')
