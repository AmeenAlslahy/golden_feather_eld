with open('lib/features/settings/presentation/pages/settings_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Add _formKey
content = content.replace('class _SettingsPageState extends ConsumerState<SettingsPage> {', 'class _SettingsPageState extends ConsumerState<SettingsPage> {\n  final _formKey = GlobalKey<FormState>();')

# Update _saveUrl
old_save_url = '''  Future<void> _saveUrl() async {
    final raw = _url.text.trim();
    if (raw.isEmpty) {
      AppFeedback.error(context, context.loc.enterServerUrl);
      return;
    }
    final uri = Uri.tryParse(raw);
    final validHttp =
        uri != null &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    if (!validHttp) {
      AppFeedback.error(context, context.loc.invalidServerUrl);
      return;
    }
    setState(() => _saving = true);'''

new_save_url = '''  Future<void> _saveUrl() async {
    if (!_formKey.currentState!.validate()) return;
    final raw = _url.text.trim();
    setState(() => _saving = true);'''

content = content.replace(old_save_url, new_save_url)

# Update the form part
old_form = '''            EldCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    context.loc.serverUrl,
                    style: context.styles.sectionTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _url,
                    hint: 'https://snsoft.cloud',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppButton(
                    label: context.loc.saveButton,
                    isLoading: _saving,
                    onPressed: _saving ? null : _saveUrl,
                  ),
                ],
              ),
            ),'''

new_form = '''            EldCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      context.loc.serverUrl,
                      style: context.styles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppTextField(
                      controller: _url,
                      hint: 'https://snsoft.cloud',
                      keyboardType: TextInputType.url,
                      validator: (value) {
                        final raw = value?.trim() ?? '';
                        if (raw.isEmpty) return context.loc.enterServerUrl;
                        final uri = Uri.tryParse(raw);
                        final validHttp = uri != null &&
                            uri.hasAuthority &&
                            uri.host.isNotEmpty &&
                            (uri.scheme == 'http' || uri.scheme == 'https');
                        if (!validHttp) return context.loc.invalidServerUrl;
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    AppButton(
                      label: context.loc.saveButton,
                      isLoading: _saving,
                      onPressed: _saving ? null : _saveUrl,
                    ),
                  ],
                ),
              ),
            ),'''

content = content.replace(old_form, new_form)

with open('lib/features/settings/presentation/pages/settings_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
