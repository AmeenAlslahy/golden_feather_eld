import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/widgets/app_button.dart';
import '../../../domain/entities/log_readiness.dart';
import '../../providers/certify_log_provider.dart';

class CarrierEditCard extends StatelessWidget {
  const CarrierEditCard({
    super.key,
    required this.edit,
    required this.busy,
    required this.onRespond,
  });

  final CarrierProposedEditEntity edit;
  final bool busy;
  final void Function(CarrierEditResponse response) onRespond;

  @override
  Widget build(BuildContext context) {
    final summary = edit.displaySummary;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            summary.isEmpty ? context.loc.carrierProposedEdit : summary,
            textAlign: TextAlign.center,
            style: context.styles.body,
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: context.loc.reject,
                  type: EldButtonType.danger,
                  onPressed: busy ? null : () => onRespond(CarrierEditResponse.reject),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: AppButton(
                  label: context.loc.accept,
                  type: EldButtonType.agree,
                  onPressed: busy ? null : () => onRespond(CarrierEditResponse.accept),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
