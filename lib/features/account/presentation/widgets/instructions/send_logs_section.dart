import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_decorations.dart';
import '../../../../../core/theme/app_spacing.dart';
import 'instructions_shared.dart';

/// المقطع الثاني: ورقة تعليمات نقل البيانات — يظهر بعد بند التفتيش
/// بنفس تخطيط الأعمدة (العمود المرئي فارغ عمداً).
class SendLogsSection extends StatelessWidget {
  const SendLogsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;

    return Container(
      decoration: AppDecorations.band(context.colorScheme.surface),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl,
      ),
      child: Column(
        children: [
          InstructionsSplitRow(
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(loc.sendLogs, style: context.styles.sheetTitle),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  loc.goldenFeatherEldIsCapableOfPro,
                  style: context.styles.sheetItem,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const InstructionsContactInfo(),
        ],
      ),
    );
  }
}
