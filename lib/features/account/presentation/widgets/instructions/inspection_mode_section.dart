import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_decorations.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'instructions_shared.dart';

/// المقطع الأول: الدخول في وضع التفتيش — شريط داكن دائم في الوضعين.
class InspectionModeSection extends StatelessWidget {
  const InspectionModeSection({super.key});

  static const double _phoneImageHeight = 220;
  static const double _phoneIconSize = 64;

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Container(
      decoration: AppDecorations.band(context.inspectionBand),
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: InstructionsSplitRow(
        visual: Container(
          height: _phoneImageHeight,
          decoration: AppDecorations.solid(
            context.onBand,
            radius: AppRadius.sheet,
          ),
          child: Center(
            child: Icon(
              Icons.smartphone,
              size: _phoneIconSize,
              color: context.textSecondary,
            ),
          ),
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.goldenFeatherEldInspectionMode,
              style: context.styles.onBandTitle,
            ),
            const SizedBox(height: AppSpacing.md),
            InstructionsChecklistItem(text: loc.tapDotInspectionInTheMenuPress),
            InstructionsChecklistItem(text: loc.anInspectorMayPressArrowsToVie),
            InstructionsChecklistItem(text: loc.anInspectorMayViewTheLogFormTh),
            InstructionsChecklistItem(text: loc.theOfficerCannotLeaveInspectio),
          ],
        ),
      ),
    );
  }
}
