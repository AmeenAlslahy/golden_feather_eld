import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';
import '../../domain/entities/daily_log.dart';

/// Presentation card displaying a pending suggested log or re-certification item.
class SuggestedLogCard extends StatelessWidget {
  final DailyLog log;
  final VoidCallback onTap;

  const SuggestedLogCard({super.key, required this.log, required this.onTap});

  String _resolveSubtitle(BuildContext context) {
    if (log.certificationStatus ==
        CertificationStatus.reCertificationRequired) {
      return context.loc.reCertificationRequiredMsg;
    }
    return context.loc.carrierProposedEdit;
  }

  @override
  Widget build(BuildContext context) {
    return EldCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: context.warning),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(log.formattedDate, style: context.styles.bodyBold),
                const SizedBox(height: AppSpacing.compact),
                Text(_resolveSubtitle(context), style: context.styles.subtitle),
              ],
            ),
          ),
          const DirectionalChevron(),
        ],
      ),
    );
  }
}
