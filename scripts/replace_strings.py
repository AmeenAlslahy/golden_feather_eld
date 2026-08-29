import os
import re

directories_to_scan = [
    'd:/Flutter projects/golden_feather_eld/lib/features'
]

replacements = [
    (r"const Text\('متابعة بدون'\)", r"Text(context.loc.continueWithout)"),
    (r"const Text\('منح'\)", r"Text(context.loc.grant)"),
    (r"const Text\('Select Co-Driver'\)", r"Text(context.loc.coDriver)"),
    (r"const Text\('Cancel'\)", r"Text(context.loc.cancelButton)"),
    (r"const Text\('OK'\)", r"Text(context.loc.okButton)"),
    (r"const Text\('Select Vehicle'\)", r"Text(context.loc.selectVehicle)"),
    (r"Text\('VIN: \$\{vehicle\.vin!\.substring\(vehicle\.vin!\.length - 8\)\}'", r"Text('${context.loc.vin}: ${vehicle.vin!.substring(vehicle.vin!.length - 8)}'"),
    (r"Text\('ADD', style: TextStyle\(color: AppColors\.surface\)\)", r"Text(context.loc.addButton, style: const TextStyle(color: AppColors.surface))"),
    (r"Text\('Time', style: _headerStyle\(context\)\)", r"Text(context.loc.time, style: _headerStyle(context))"),
    (r"Text\('Status', style: _headerStyle\(context\)\)", r"Text(context.loc.status, style: _headerStyle(context))"),
    (r"Text\('Location', style: _headerStyle\(context\)\)", r"Text(context.loc.location, style: _headerStyle(context))"),
    (r"Text\('Odom\.', style: _headerStyle\(context\)\)", r"Text(context.loc.odom, style: _headerStyle(context))"),
    (r"Text\('Eng\.', style: _headerStyle\(context\)\)", r"Text(context.loc.eng, style: _headerStyle(context))"),
    (r"Text\('Src', style: _headerStyle\(context\)\)", r"Text(context.loc.src, style: _headerStyle(context))"),
    (r"Text\('No manual modifications found for this date\.'", r"Text(context.loc.noManualModifications"),
    (r"const Text\('Failed to load audits'\)", r"Text(context.loc.failedToLoadAudits)"),
    (r"const Text\('Export as eRODS \(XML/CSV\)'\)", r"Text(context.loc.exportErods)"),
    (r"const Text\('Required for FMCSA inspection'\)", r"Text(context.loc.requiredForFmcsa)"),
    (r"Text\('تغيير الحالة إلى \$\{widget\.newStatus\.arabicName\}'\)", r"Text(context.loc.changeStatusTo(widget.newStatus.arabicName))"),
    (r"const Text\('إلغاء'\)", r"Text(context.loc.cancelButton)"),
    (r"const Text\('تأكيد'\)", r"Text(context.loc.okButton)")
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
                    if 'context_extensions.dart' not in content and 'context.loc' in content:
                        # find relative path or use absolute
                        content = "import 'package:golden_feather_eld/core/extensions/context_extensions.dart';\n" + content

                    with open(file_path, 'w', encoding='utf-8') as f:
                        f.write(content)
                    print(f'Updated {file_path}')
