import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';

class RulesNoticeBanner extends StatelessWidget {
  final String notice;

  const RulesNoticeBanner({super.key, required this.notice});

  @override
  Widget build(BuildContext context) {
    if (notice.trim().isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: context.warningContainer,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: context.warning.withValues(alpha: 0.6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: context.textPrimary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(notice, style: context.styles.body)),
        ],
      ),
    );
  }
}
