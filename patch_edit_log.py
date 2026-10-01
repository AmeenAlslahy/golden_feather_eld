with open('lib/features/logs/presentation/pages/edit_log_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

if 'app_text_field.dart' not in content:
    content = content.replace('import \'../../../../core/widgets/app_button.dart\';', 'import \'../../../../core/widgets/app_button.dart\';\nimport \'../../../../core/widgets/app_text_field.dart\';')

# Change class to ConsumerStatefulWidget
content = content.replace('class EditLogPage extends ConsumerWidget {\n  final dynamic event;\n  final bool isNewEvent;\n\n  const EditLogPage({super.key, required this.event, this.isNewEvent = false});\n\n  void _showTimePicker(BuildContext context, WidgetRef ref) {', 
'''class EditLogPage extends ConsumerStatefulWidget {
  final dynamic event;
  final bool isNewEvent;

  const EditLogPage({super.key, required this.event, this.isNewEvent = false});

  @override
  ConsumerState<EditLogPage> createState() => _EditLogPageState();
}

class _EditLogPageState extends ConsumerState<EditLogPage> {
  final _formKey = GlobalKey<FormState>();

  void _showTimePicker(BuildContext context, WidgetRef ref) {''')

content = content.replace('@override\n  Widget build(BuildContext context, WidgetRef ref) {', '@override\n  Widget build(BuildContext context) {')
content = content.replace('isNewEvent', 'widget.isNewEvent')
content = content.replace('editLogFormProvider(event)', 'editLogFormProvider(widget.event)')
content = content.replace('child: Column(', 'child: Form(\n          key: _formKey,\n          child: Column(')
content = content.replace('const SizedBox(height: AppSpacing.md),\n          ],\n        ),\n      ),', 'const SizedBox(height: AppSpacing.md),\n          ],\n        ),\n        ),\n      ),')

# Update the TextField to AppTextField and add validation
textfield_replacement = '''AppTextField(
                  hint: context.loc.enterReasonRequired,
                  validator: (value) => value == null || value.trim().isEmpty ? context.loc.aReasonForTheChangeIs : null,
                  onChanged: (value) {
                    ref
                        .read(editLogFormProvider(widget.event).notifier)
                        .setReason(value);
                  },
                )'''

# Using regex to replace the TextField since it might span multiple lines
content = re.sub(r'TextField\(\s*decoration: InputDecoration\(\s*hintText: context.loc.enterReasonRequired,.*?\),\s*\)\s*,\s*}\s*,\s*\)', textfield_replacement, content, flags=re.DOTALL)
# Wait, my regex might fail. Let's do exact match replacement instead.
