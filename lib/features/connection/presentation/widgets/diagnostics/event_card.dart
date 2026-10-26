import 'package:flutter/material.dart';
import '../../../../../../core/theme/app_typography.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/hardware_alert.dart';

class EventCard extends StatelessWidget {
  final HardwareAlert alert;
  final bool malfunction;

  const EventCard({super.key, required this.alert, required this.malfunction});

  @override
  Widget build(BuildContext context) {
    final kind = malfunction ? 'MALFUNCTION' : 'DATA_DIAGNOSTIC';
    final detectedAt = alert.timestamp;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: (malfunction ? context.danger : context.warning).withValues(
          alpha: 0.08,
        ),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: malfunction ? context.danger : context.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // تمييز بصري صريح: MALFUNCTION ≠ DATA_DIAGNOSTIC
              Text(
                kind,
                style: context.styles.caption.copyWith(
                  fontWeight: AppTypography.bold,
                  color: malfunction ? context.danger : context.warning,
                ),
              ),
              const Spacer(),
              Text(
                'DETECTED',
                style: context.styles.caption.copyWith(
                  fontWeight: AppTypography.semiBold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(alert.message, style: context.styles.body),
          if (detectedAt != null)
            Text(
              AppLocalizations.of(context)!.startedOnDate(
                '${detectedAt.month}/${detectedAt.day}/${detectedAt.year}',
              ),
              style: context.styles.caption,
            ),
        ],
      ),
    );
  }
}
