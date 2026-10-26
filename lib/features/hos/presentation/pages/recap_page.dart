import 'package:flutter/material.dart';
import '../../../../../core/theme/app_typography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/error/failure.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../providers/recap_provider.dart';
import '../../../../l10n/app_localizations.dart';

class RecapPage extends ConsumerWidget {
  const RecapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recapAsync = ref.watch(recapProvider);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: recapAsync.when(
        data: (data) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // 7 Days Table
                if (data.days.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: Center(
                      child: Text(
                        context.loc.noData,
                        style: context.styles.muted,
                      ),
                    ),
                  )
                else
                  ...data.days.map(
                    (dayData) => _buildRow(
                      context,
                      title: dayData.dayOfWeek,
                      subtitle: DateFormat.MMMd(
                        Localizations.localeOf(context).languageCode,
                      ).format(dayData.date),
                      value: DurationFormat.decimalHours(dayData.totalWork),
                    ),
                  ),
                _buildRow(
                  context,
                  title: context.loc.total,
                  subtitle: context.loc.last7Days,
                  value: DurationFormat.decimalHours(data.cycleUsed),
                  isTotal: true,
                ),
                _buildRow(
                  context,
                  title: context.loc.hoursWorkedToday,
                  value: DurationFormat.decimalHours(data.todayWork),
                ),
                _buildRow(
                  context,
                  title: context.loc.hoursAvailableToday,
                  value: DurationFormat.decimalHours(data.cycleRemaining),
                ),
                _buildRow(
                  context,
                  title: context.loc.hoursAvailableTomorrow,
                  value: DurationFormat.decimalHours(data.availableTomorrow),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          // لا كاش ولا خادم ⇒ لا نعرض أرقاماً. نقول "لا توجد بيانات"
          // بدل إيهام السائق برصيد أسبوعي فارغ.
          if (err is NoRecapSnapshotFailure) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(context.loc.noData, style: context.styles.muted),
                  TextButton.icon(
                    onPressed: () => ref.invalidate(recapProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(context.loc.retryButton),
                  ),
                ],
              ),
            );
          }
          return EldRetryView(
            message: anyErrorUserMessage(
              err,
              loc: AppLocalizations.of(context)!,
            ),
            onRetry: () => ref.invalidate(recapProvider),
          );
        },
      ),
    );
  }

  Widget _buildRow(
    BuildContext context, {
    required String title,
    String? subtitle,
    required String value,
    bool isTotal = false,
  }) {
    final titleColor = isTotal
        ? context.styles.body.color
        : context.styles.subtitle.color;
    final titleWeight = isTotal ? AppTypography.semiBold : AppTypography.medium;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.5),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: subtitle != null ? 3 : 5,
            child: Text(
              title,
              style: context.styles.body.copyWith(
                color: titleColor,
                fontWeight: titleWeight,
              ),
            ),
          ),
          if (subtitle != null)
            Expanded(
              flex: 3,
              child: Text(
                subtitle,
                style: context.styles.body.copyWith(
                  color: titleColor,
                  fontWeight: titleWeight,
                ),
              ),
            ),
          Expanded(
            flex: 2,
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: context.styles.body.copyWith(
                color: context.styles.body.color,
                fontWeight: isTotal
                    ? AppTypography.semiBold
                    : AppTypography.regular,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
