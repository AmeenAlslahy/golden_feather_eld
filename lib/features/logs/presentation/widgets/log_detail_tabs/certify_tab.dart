import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/eld_card.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/daily_log.dart';

class CertifyTab extends StatefulWidget {
  final DailyLog selectedLog;

  const CertifyTab({super.key, required this.selectedLog});

  @override
  State<CertifyTab> createState() => _CertifyTabState();
}

class _CertifyTabState extends State<CertifyTab> {
  late SignatureController _signatureController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: Theme.of(context).colorScheme.primary,
      exportBackgroundColor: Theme.of(context).colorScheme.surface,
    );
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          EldCard(
            child: Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.imagePlaceholder),
                border: Border.all(
                  color: AppColors.border,
                  width: 1,
                  style: BorderStyle.solid,
                ),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.loc.drawSignatureHere,
                          textAlign: TextAlign.center,
                          style: AppTextStyles(context).pageTitle.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Signature(
                    controller: _signatureController,
                    height: 200,
                    backgroundColor: AppColors.transparent,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          InkWell(
            onTap: () {
              _signatureController.clear();
            },
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                context.loc.clearSignature,
                style: AppTextStyles(context)
                    .body
                    .copyWith(decoration: TextDecoration.underline),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            context.loc.certifyDeclaration,
            textAlign: TextAlign.center,
            style: AppTextStyles(context).body.copyWith(height: 1.5),
          ),
          const SizedBox(height: AppSpacing.md),
          if (!widget.selectedLog.isFormComplete)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Text(
                context.loc.fillFormFirst,
                textAlign: TextAlign.center,
                style: AppTextStyles(context).errorText,
              ),
            ),
          ListenableBuilder(
            listenable: _signatureController,
            builder: (context, _) {
              final isSigned = _signatureController.isNotEmpty;
              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (isSigned && widget.selectedLog.isFormComplete)
                      ? () {
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.successGreen,
                    disabledBackgroundColor: AppColors.border,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    context.loc.agree,
                    style: AppTextStyles(context)
                        .buttonText
                        .copyWith(color: AppColors.surface),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
