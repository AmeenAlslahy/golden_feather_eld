import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../../../core/utils/status_color_helper.dart';
import '../../../domain/entities/daily_log.dart';
import 'expanded_content.dart';

/// 'HH:mm' + اختصار منطقة توقيت الحدث (3 أحرف إن توفرت)،
/// دون اعتماد على DateTime.now() ودون رمي استثناء لاسم توقيت فارغ.
String _formatTimeWithZone(DateTime time) {
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  final name = time.timeZoneName.trim();
  if (name.isEmpty) return '$h:$m';
  final short = name.length >= 3 ? name.substring(0, 3) : name;
  return '$h:$m ${short.toUpperCase()}';
}

class LogEventTile extends StatelessWidget {
  final LogEvent event;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  const LogEventTile({
    super.key,
    required this.event,
    required this.onTap,
    this.onEdit,
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
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 32,
                  child: Text(
                    event.status,
                    style: context.styles.bodyBold,
                  ),
                ),

                // Time (من وقت الحدث نفسه، مع اختصار آمن لمنطقة التوقيت)
                Expanded(
                  flex: 2,
                  child: Text(
                    _formatTimeWithZone(event.startTime),
                    style: context.styles.body,
                  ),
                ),

                // Duration
                Expanded(
                  flex: 2,
                  child: Text(
                    event.formattedDuration,
                    style: context.styles.body,
                  ),
                ),

                if (onEdit != null)
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
              duration: const Duration(milliseconds: 300),
            ),
          ],
        ),
      ),
    );
  }
}
