import 'package:flutter/material.dart';

import '../../../../core/design_system.dart';
import '../../domain/entities/daily_log.dart';
import 'status_chip.dart';

/// عنصر السجل في القائمة
class LogListItem extends StatelessWidget {
  final DailyLog log;
  final VoidCallback onTap;

  const LogListItem({super.key, required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.14),
      highlightColor: Theme.of(
        context,
      ).colorScheme.primary.withValues(alpha: 0.08),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.rowHorizontal,
          vertical: AppSpacing.rowVertical,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // السطر الأول: التاريخ + وسم اليوم (SRS 5.1) + السهم
            Row(
              children: [
                Expanded(
                  child: Text(
                    log.today
                        ? context.loc.todayLogDate(log.formattedDate)
                        : log.formattedDate,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.styles.body,
                  ),
                ),
                const DirectionalChevron(),
              ],
            ),

            const SizedBox(height: AppSpacing.compact),
            // السطر الثاني: الوقت + الحالات
            Row(
              children: [
                // 1. عدد الساعات
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: context.success,
                        size: AppSpacing.iconSmall,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          log.formattedTotalWorkTime.isNotEmpty
                              ? log.formattedTotalWorkTime
                              : (log.totalDrivingHours < 1
                                    ? '< 1m'
                                    : '${log.totalDrivingHours.toStringAsFixed(0)}h ${(log.totalDrivingHours % 1 * 60).toStringAsFixed(0)}m'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.styles.success.copyWith(
                            fontWeight: AppTypography.medium,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // مسافة تفصل بين الوقت والحالة الأولى (تنكمش عند الضيق)
                const Flexible(child: SizedBox(width: AppSpacing.xl)),

                // 2. حالة النموذج (Form)
                StatusChip(
                  label: context.loc.formLabel,
                  isComplete: log.isFormComplete,
                ),

                // مسافة تفصل بين الحالتين (تنكمش عند الضيق)
                const Flexible(child: SizedBox(width: AppSpacing.lg)),

                // 3. حالة التوثيق (Certify)
                StatusChip(
                  label: context.loc.certifyLabel,
                  isComplete: log.isCertified,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
