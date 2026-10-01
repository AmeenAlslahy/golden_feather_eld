with open('lib/features/settings/presentation/pages/settings_page.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import re

# Need to close the Form widget correctly
# The Form widget was inserted but the closing was missed.
content = content.replace('                    },\n                  ),\n                ],\n              ),\n            ),', '                    },\n                  ),\n                ],\n              ),\n              ),\n            ),')

with open('lib/features/settings/presentation/pages/settings_page.dart', 'w', encoding='utf-8') as f:
    f.write(content)
