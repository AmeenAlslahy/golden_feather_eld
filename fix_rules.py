import re

with open('lib/features/account/presentation/pages/rules_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add FormKey
if '_formKey' not in content:
    content = content.replace('class _RulesPageState extends ConsumerState<RulesPage> {', 'class _RulesPageState extends ConsumerState<RulesPage> {\n  final _formKey = GlobalKey<FormState>();')

# In _saveRules, replace !_isFormValid with Form validation
old_save_rules = '''  Future<void> _saveRules(RulesScreenModel model) async {
    if (!_isFormValid) {
      AppFeedback.error(context, context.loc.formIncomplete);
      return;
    }
    setState(() => _isSaving = true);'''

new_save_rules = '''  Future<void> _saveRules(RulesScreenModel model) async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() => _isSaving = true);'''

content = content.replace(old_save_rules, new_save_rules)

# Add Form around Column in build
content = content.replace('      body: RefreshIndicator(\n        onRefresh:', '      body: Form(\n        key: _formKey,\n        child: RefreshIndicator(\n          onRefresh:')
content = content.replace('          },\n        ),\n      ),\n    );\n  }\n\n  Widget _buildField', '          },\n        ),\n        ),\n      ),\n    );\n  }\n\n  Widget _buildField')

# Replace DropdownButtonHideUnderline -> DropdownButtonFormField
dropdown_find = '''            Expanded(
              flex: 3,
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  isExpanded: true,
                  value: currentValue,
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    color: context.textPrimary,
                  ),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        switch (fieldName) {
                          case 'cycleRule':
                            _cycleRule = newValue;
                            break;
                          case 'cargoType':
                            _cargoType = newValue;
                            break;
                          case 'restart':
                            _restart = newValue;
                            break;
                          case 'restBreak':
                            _restBreak = newValue;
                            break;
                        }
                      });
                    }
                  },
                  style: context.styles.body.copyWith(
                    fontSize: AppTypography.bodySize,
                  ),
                  items: options.map<DropdownMenuItem<String>>((String val) {
                    return DropdownMenuItem<String>(
                      value: val,
                      child: Text(
                        val,
                        style: context.styles.body.copyWith(
                          fontSize: AppTypography.bodySize,
                          color: context.textPrimary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),'''

dropdown_replace = '''            Expanded(
              flex: 3,
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: currentValue.isEmpty ? null : currentValue,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: context.textPrimary,
                ),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                  border: UnderlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? context.loc.formIncomplete : null,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      switch (fieldName) {
                        case 'cycleRule':
                          _cycleRule = newValue;
                          break;
                        case 'cargoType':
                          _cargoType = newValue;
                          break;
                        case 'restart':
                          _restart = newValue;
                          break;
                        case 'restBreak':
                          _restBreak = newValue;
                          break;
                      }
                    });
                  }
                },
                style: context.styles.body.copyWith(
                  fontSize: AppTypography.bodySize,
                ),
                items: options.map<DropdownMenuItem<String>>((String val) {
                  return DropdownMenuItem<String>(
                    value: val,
                    child: Text(
                      val,
                      style: context.styles.body.copyWith(
                        fontSize: AppTypography.bodySize,
                        color: context.textPrimary,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),'''

content = content.replace(dropdown_find, dropdown_replace)

with open('lib/features/account/presentation/pages/rules_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)

