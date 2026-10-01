with open('lib/features/logs/presentation/pages/edit_log_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('editLogFormProvider(event)', 'editLogFormProvider(widget.event)')

if 'app_text_field.dart' not in content:
    content = content.replace('import \'../../../../core/widgets/app_button.dart\';', 'import \'../../../../core/widgets/app_button.dart\';\nimport \'../../../../core/widgets/app_text_field.dart\';')

with open('lib/features/logs/presentation/pages/edit_log_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
