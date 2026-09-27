import 'package:flutter/material.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_typography.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/entities/daily_log.dart';

class ExpandedContent extends StatelessWidget {
  final LogEvent event;

  const ExpandedContent({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _expandedRow(context, context.loc.startTime, event.formattedStartTime),
        _expandedRow(context, context.loc.duration, event.formattedDuration),
        _expandedRow(context, context.loc.location, event.location),
        if (event.odometer != null)
          _expandedRow(
            context,
            context.loc.odometer,
            '${event.odometer!.toStringAsFixed(1)} ${context.loc.miles}',
          ),
        if (event.engineHours != null)
          _expandedRow(
            context,
            context.loc.engineHours,
            '${event.engineHours!.toStringAsFixed(1)} ${context.loc.hour}',
          ),
      ],
    );
  }

  Widget _expandedRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: context.styles.caption,
          ),
          Expanded(
            child: Text(
              value,
              style: context.styles.caption.copyWith(
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
