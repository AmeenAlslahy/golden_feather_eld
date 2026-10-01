with open('lib/features/account/presentation/pages/rules_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re
content = re.sub(r'  bool get _isFormValid \{.*?\}\n', '', content, flags=re.DOTALL)

with open('lib/features/account/presentation/pages/rules_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
