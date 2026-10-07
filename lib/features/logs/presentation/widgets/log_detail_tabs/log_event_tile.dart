import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_spacing.dart';
import '../../../domain/entities/daily_log.dart';
import '../../../../../core/utils/status_color_helper.dart';
import 'expanded_content.dart';
import '../../../../../../l10n/app_localizations.dart';

import '../../../../../core/time/time_formatter.dart';

/// 'HH:mm' + اختصار منطقة توقيت الحدث (3 أحرف إن توفرت)،
/// دون اعتماد على DateTime.now() ودون رمي استثناء لاسم توقيت فارغ.
String _formatTimeWithZone(DateTime time) {
  return TimeFormatter.formatTimeWithZone(time);
}

class LogEventTile extends StatelessWidget {
  final LogEvent event;
  final VoidCallback onTap;
  final VoidCallback? onEdit;

  /// The day the log belongs to. When the event started on a different
  /// calendar day (e.g. an OFF period that began the evening before) the
  /// start date is shown under the time (SRS 5.2).
  final DateTime? logDate;

  const LogEventTile({
    super.key,
    required this.event,
    required this.onTap,
    this.onEdit,
    this.logDate,
  });

  bool get _startedOnAnotherDay {
    final d = logDate;
    if (d == null) return false;
    final t = event.startTime.toLocal();
    return t.year != d.year || t.month != d.month || t.day != d.day;
  }

  @override
  Widget build(BuildContext context) {
    final color = StatusColorHelper.getStatusColor(event.status);
    final isExpanded = event.isExpanded;

    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Positioned.directional(
                textDirection: Directionality.of(context),
                start: AppSpacing.md,
                top: AppSpacing.md,
                bottom: AppSpacing.sm,
                child: Container(
                  width: 3,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.only(
                  start: AppSpacing.md + 3 + AppSpacing.md, // start margin + width + inner spacing
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Top Row
                    Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: AppSpacing.xs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 36,
                            child: Text(
                              event.status,
                              style: context.styles.sectionTitle.copyWith(fontSize: 15),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Text(
                              _formatTimeWithZone(event.startTime),
                              style: context.styles.body.copyWith(fontSize: 14),
                            ),
                          ),
                          Expanded(
                            child: Row(
                              children: [
                                Text(
                                  event.formattedDuration,
                                  style: context.styles.body.copyWith(fontSize: 14),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                if (_startedOnAnotherDay)
                                  Flexible(
                                    child: Text(
                                        AppLocalizations.of(context)!.startedOnDate('${event.startTime.month}/${event.startTime.day}/${event.startTime.year}'),
                                      style: context.styles.caption,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          if (onEdit != null)
                            IconButton(
                              onPressed: onEdit,
                              icon:  Icon(
                                Icons.edit,
                                size: 22,
                                color: AppColors.textPrimaryFor(Theme.of(context).brightness),
                              ),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                        ],
                      ),
                    ),
                    
                    // Expanded content
                    AnimatedCrossFade(
                      firstChild: const SizedBox(height: AppSpacing.sm),
                      secondChild: Padding(
                        padding: const EdgeInsets.only(
                          left: 36, // Indent to align with Time
                          right: AppSpacing.md,
                          bottom: AppSpacing.md,
                        ),
                        child: ExpandedContent(event: event),
                      ),
                      crossFadeState: isExpanded
                          ? CrossFadeState.showSecond
                          : CrossFadeState.showFirst,
                      duration: const Duration(milliseconds: 300),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Faint Divider
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
          ),
        ],
      ),
    );
  }
}
