import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/log_readiness.dart';
import '../../providers/certify_log_provider.dart';
import 'carrier_edit_card.dart';

class PendingCarrierEditsSection extends StatelessWidget {
  final List<CarrierProposedEditEntity> edits;
  final bool isBusy;
  final void Function(String editId, CarrierEditResponse response) onRespond;
  final bool showWarningHeader;

  const PendingCarrierEditsSection({
    super.key,
    required this.edits,
    required this.isBusy,
    required this.onRespond,
    required this.showWarningHeader,
  });

  @override
  Widget build(BuildContext context) {
    if (edits.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showWarningHeader) ...[
          Text(
            context.loc.carrierEditsMustBeAcceptedOr,
            textAlign: TextAlign.center,
            style: context.styles.error,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        for (final edit in edits)
          CarrierEditCard(
            edit: edit,
            busy: isBusy,
            onRespond: (action) => onRespond(edit.id, action),
          ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}
