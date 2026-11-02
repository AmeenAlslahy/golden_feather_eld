import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';
import '../../domain/entities/daily_log.dart';
import '../formatters/log_date_formatter.dart';

/// Presentation card displaying a pending suggested log or re-certification item.
class SuggestedLogCard extends StatelessWidget {
  final DailyLog log;
  final VoidCallback onTap;

  const SuggestedLogCard({
    super.key,
    required this.log,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRecertification =
        log.certificationStatus == CertificationStatus.reCertificationRequired;

    // Status label for pill
    final String statusLabel;
    final Color statusColor;
    if (isRecertification) {
      statusLabel = context.loc.reCertificationRequiredMsg.contains(':')
          ? context.loc.reCertificationRequiredMsg.split(':').first.trim()
          : context.loc.reCertificationRequiredMsg;
      statusColor = context.warning;
    } else {
      statusLabel = context.loc.carrierProposedEdit;
      statusColor = context.gold;
    }

    // Explanation / reason text
    final String? description = isRecertification &&
            context.loc.reCertificationRequiredMsg.contains(':')
        ? context.loc.reCertificationRequiredMsg.split(':').last.trim()
        : null;

    return EldCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.compact,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Semantic Icon Container
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (isRecertification ? context.warning : context.gold)
                  .withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isRecertification
                  ? Icons.warning_amber_rounded
                  : Icons.edit_note_rounded,
              size: 18,
              color: isRecertification ? context.warning : context.gold,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Date, Status & Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  log.localizedDate(context),
                  style: context.styles.bodyBold.copyWith(
                    fontSize: 15,
                    fontWeight: AppTypography.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.space4),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.space2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    AppStatusPill(
                      label: statusLabel,
                      color: statusColor,
                    ),
                    if (description != null && description.isNotEmpty)
                      Text(
                        description,
                        style: context.styles.caption.copyWith(
                          color: context.textSecondary,
                          fontSize: 11,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Directional Chevron Affordance (adapts to RTL/LTR)
          const DirectionalChevron(),
        ],
      ),
    );
  }
}

