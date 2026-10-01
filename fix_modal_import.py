filepath = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

import_statement = "import '../widgets/previous_dvir_review_modal.dart';\n"
if import_statement not in content:
    content = content.replace("import '../widgets/signature_canvas.dart';", "import '../widgets/signature_canvas.dart';\n" + import_statement)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
