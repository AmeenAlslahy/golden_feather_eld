

import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../l10n/app_localizations.dart';
import '../../../domain/entities/hardware_alert.dart';

class EventCard extends StatelessWidget {
  final HardwareAlert alert;
  final bool malfunction;

  const EventCard({
    super.key,
    required this.alert,
    required this.malfunction,
  });

  @override
  Widget build(BuildContext context) {
    final kind =
        malfunction ? 'MALFUNCTION' : 'DATA_DIAGNOSTIC';
    final detectedAt = alert.timestamp;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: malfunction
            ? AppColors.dangerBg.withValues(alpha: 0.35)
            : AppColors.warningBg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(
          color: malfunction ? AppColors.dangerRed : AppColors.warningYellow,
          width: malfunction ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // تمييز بصري صريح: MALFUNCTION ≠ DATA_DIAGNOSTIC
              Text(kind,
                  style: context.styles.caption.copyWith(
                    fontWeight: FontWeight.w700,
                    color: malfunction
                        ? AppColors.dangerText
                        : AppColors.warningText,
                  )),
              const Spacer(),
              Text('DETECTED',
                  style: context.styles.caption
                      .copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 4),
          Text(alert.message, style: context.styles.body),
          if (detectedAt != null)
            Text(
              AppLocalizations.of(context)!.startedOnDate(
                  '${detectedAt.month}/${detectedAt.day}/${detectedAt.year}'),
              style: context.styles.caption,
            ),
        ],
      ),
    );
  }
}