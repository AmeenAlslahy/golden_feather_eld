import 'package:flutter/material.dart';

import '../../../../../core/theme/app_durations.dart';
import '../../../../../core/theme/app_radius.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/utils/status_color_helper.dart';
import '../../../../../core/widgets/app_gap.dart';
import '../../../domain/entities/daily_log.dart';
import 'expanded_content.dart';

class LogEventTile extends StatelessWidget {
  final LogEvent event;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const LogEventTile({
    super.key,
    required this.event,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = event.isExpanded;
    final color = StatusColorHelper.getStatusColor(event.status);

    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
              bottom:
                  BorderSide(color: Theme.of(context).dividerColor, width: 1)),
        ),
        padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm, horizontal: AppSpacing.md),
        child: Column(
          children: [
            // Main row
            Row(
              children: [
                // Color bar
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                AppGap.hMd,
                SizedBox(
                  width: 32,
                  child: Text(
                    event.status,
                    style: AppTextStyles(context).bodyBold,
                  ),
                ),

                // Time
                Expanded(
                  flex: 2,
                  child: Text(
                    '${event.formattedStartTime} ${DateTime.now().timeZoneName.substring(0, 3).toUpperCase()}',
                    style: AppTextStyles(context).body,
                  ),
                ),

                // Duration
                Expanded(
                  flex: 2,
                  child: Text(
                    event.formattedDuration,
                    style: AppTextStyles(context).body,
                  ),
                ),

                // Edit Icon
                IconButton(
                  onPressed: onEdit,
                  icon: const Icon(
                    Icons.edit,
                    size: 22,
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            // Expanded content
            AnimatedCrossFade(
              firstChild: const SizedBox.shrink(),
              secondChild: ExpandedContent(event: event),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: AppDurations.normal,
            ),
          ],
        ),
      ),
    );
  }
}