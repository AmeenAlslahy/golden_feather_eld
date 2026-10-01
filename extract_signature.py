import os
import re

source_file = 'lib/features/dvir/presentation/pages/dvir_form_page.dart'
dest_file = 'lib/features/dvir/presentation/widgets/signature_canvas.dart'

with open(source_file, 'r', encoding='utf-8') as f:
    content = f.read()

signature_code = '''import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/theme_extension.dart';
import '../../../../l10n/app_localizations.dart';

class DvirSignatureCanvas extends StatelessWidget {
  final SignatureController controller;
  final Color borderColor;

  const DvirSignatureCanvas({
    super.key,
    required this.controller,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        children: [
          Container(
            height: 200,
            width: double.infinity,
            decoration: AppDecorations.outlined(
              borderColor: borderColor,
              alpha: 0.5,
              color: Colors.white,
            ),
            child: Stack(
              children: [
                Center(
                  child: Text(
                    context.loc.dvirImageNotAvailable,
                    textAlign: TextAlign.center,
                    style: context.styles.muted.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
                Signature(
                  controller: controller,
                  backgroundColor: Colors.transparent,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () => controller.clear(),
            child: Text(
              context.loc.dvirClearSignature,
              style: context.styles.subtitle.copyWith(
                decoration: TextDecoration.underline,
                decorationStyle: TextDecorationStyle.dotted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
'''

with open(dest_file, 'w', encoding='utf-8') as f:
    f.write(signature_code)

print('Created signature_canvas.dart successfully')

old_signature_regex = r'            // Signature Section\s+Padding\(\s+padding: const EdgeInsets\.all\(AppSpacing\.xl\),\s+child: Column\(\s+children: \[\s+Container\(\s+height: 200,\s+width: double\.infinity,\s+decoration: AppDecorations\.outlined\(\s+borderColor: borderColor,\s+alpha: 0\.5,\s+color: Colors\.white,\s+\),\s+child: Stack\(\s+children: \[\s+Center\(\s+child: Text\(\s+context\.loc\.dvirImageNotAvailable,\s+textAlign: TextAlign\.center,\s+style: context\.styles\.muted\.copyWith\(\s+fontSize: 32,\s+fontWeight: FontWeight\.bold,\s+color: Theme\.of\(context\)\.colorScheme\.outline,\s+\),\s+\),\s+\),\s+Signature\(\s+controller: _signatureController,\s+backgroundColor: Colors\.transparent,\s+\),\s+\],\s+\),\s+\),\s+const SizedBox\(height: AppSpacing\.sm\),\s+InkWell\(\s+onTap: \(\) => _signatureController\.clear\(\),\s+child: Text\(\s+context\.loc\.dvirClearSignature,\s+style: context\.styles\.subtitle\.copyWith\(\s+decoration: TextDecoration\.underline,\s+decorationStyle: TextDecorationStyle\.dotted,\s+\),\s+\),\s+\),\s+\],\s+\),\s+\),'

def replacer(match):
    return '''            // Signature Section
            DvirSignatureCanvas(
              controller: _signatureController,
              borderColor: borderColor,
            ),'''

new_content = re.sub(old_signature_regex, replacer, content, flags=re.DOTALL)

import_statement = "import '../widgets/signature_canvas.dart';\n"
if import_statement not in new_content:
    new_content = new_content.replace("import '../../domain/entities/dvir_report.dart';", "import '../../domain/entities/dvir_report.dart';\n" + import_statement)

with open(source_file, 'w', encoding='utf-8') as f:
    f.write(new_content)

print('Updated dvir_form_page.dart with DvirSignatureCanvas')
