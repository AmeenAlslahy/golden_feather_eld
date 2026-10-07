
import 'package:flutter/material.dart';

import '../../../../../core/design_system.dart';
import '../../../../../core/widgets/app_feedback.dart';

/// إجراءات العطل النشط وفق SRS 3.7: تدوين العطل وإخطار الناقل خلال 24 ساعة،
/// إعادة بناء السجل (24 ساعة + 7 أيام نماذج ورقية)، والاستمرار اليدوي حتى
/// إصلاح ELD.
class ActiveMalfunctionActions extends StatelessWidget {
  const ActiveMalfunctionActions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          icon: const Icon(Icons.notifications_active, size: 18),
          label: Text(context.loc.notifyCarrier),
          onPressed: () => AppFeedback.info(
              context, context.loc.eldMalfunctionStep1),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          icon: const Icon(Icons.edit_note, size: 18),
          label: Text(context.loc.eldMalfunctionManualActive),
          onPressed: () => AppFeedback.info(
              context, context.loc.eldMalfunctionStep2),
        ),
        const SizedBox(height: AppSpacing.sm),
        OutlinedButton.icon(
          icon: const Icon(Icons.schedule, size: 18),
          label: Text(context.loc.requestExtension),
          onPressed: () => AppFeedback.info(
              context, context.loc.eldMalfunctionStep3),
        ),
      ],
    );
  }
}
