import '../../../../core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_spacing.dart';



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
