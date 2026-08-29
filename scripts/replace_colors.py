import os
import re

directories_to_scan = [
    'd:/Flutter projects/golden_feather_eld/lib/features',
    'd:/Flutter projects/golden_feather_eld/lib/core/engine',
    'd:/Flutter projects/golden_feather_eld/lib/core/services'
]

replacements = [
    (r'Colors\.white(?!\w)', r'Theme.of(context).colorScheme.surface'),
    (r'Colors\.black(?!\w)', r'Theme.of(context).colorScheme.onSurface'),
    (r'Colors\.red(?!\w)', r'AppColors.dangerRed'),
    (r'Colors\.green(?!\w)', r'AppColors.successGreen'),
    (r'Colors\.blue(?!\w)', r'AppColors.primaryBlue'),
    (r'Colors\.grey(?!\w)', r'Theme.of(context).colorScheme.outline'),
    (r'Colors\.transparent(?!\w)', r'AppColors.transparent'),
    (r'Color\(0xFF005A9C\)', r'AppColors.primaryBlue'),
    (r'Color\(0xFFF9F9F9\)', r'Theme.of(context).colorScheme.surface'),
    (r'Color\(0xFFA5D6A7\)', r'AppColors.successGreen')
]

for directory in directories_to_scan:
    for root, _, files in os.walk(directory):
        for file in files:
            if file.endswith('.dart'):
                file_path = os.path.join(root, file)
                with open(file_path, 'r', encoding='utf-8') as f:
                    content = f.read()
                
                original_content = content
                for pattern, replacement in replacements:
                    content = re.sub(pattern, replacement, content)
                
                if content != original_content:
                    # check if Theme.of(context) is used but material is not imported? 
                    # material is usually imported. 
                    # check if AppColors is used but not imported
                    if 'AppColors' in content and 'app_colors.dart' not in content:
                        # find the relative path or just use absolute package import
                        content = "import 'package:golden_feather_eld/core/theme/app_colors.dart';\n" + content
                        
                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f'Updated {file_path}')
