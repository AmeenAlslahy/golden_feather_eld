filepath = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import '../../../../core/theme/app_decorations.dart';", "")
content = content.replace("import '../widgets/defect_card.dart';", "")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
