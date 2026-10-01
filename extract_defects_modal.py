import os
import re

source_file = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
dest_file = 'lib/features/dvir/presentation/widgets/defects_modal.dart'

with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()

match = re.search(r'/// Checkbox list of the live.*?class _DefectCatalogDialog extends ConsumerStatefulWidget \{.*?\n\}\n', content, re.DOTALL)

if match:
    dialog_code = match.group(0)
    dialog_code = dialog_code.replace('_DefectCatalogDialog', 'DefectCatalogDialog')
    
    imports = '''import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/entities/dvir_report.dart';

'''
    
    with open(dest_file, 'w', encoding='utf-8') as f:
        f.write(imports + dialog_code)
    
    print('Created defects_modal.dart successfully')
    
    new_content = content.replace(match.group(0), '')
    new_content = new_content.replace('_DefectCatalogDialog(', 'DefectCatalogDialog(')
    
    import_statement = "import '../widgets/defects_modal.dart';\n"
    if import_statement not in new_content:
        new_content = new_content.replace("import '../../domain/entities/dvir_report.dart';", "import '../../domain/entities/dvir_report.dart';\n" + import_statement)
        
    with open(source_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
        
    print('Updated dvir_form_page.dart successfully')
else:
    print('Could not find _DefectCatalogDialog')
