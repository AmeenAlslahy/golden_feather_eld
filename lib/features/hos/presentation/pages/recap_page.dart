import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/duration_format.dart';
import '../../../../domain/duty_status/weekly_recap.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
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
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(recapProvider);
              await ref.read(recapProvider.future);
            },
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                // 7 Days Table
                ...data.days.map(
                  (dayData) => _buildRow(
                    context,
                    title: dayData.dayOfWeek,
                    subtitle: DateFormat('MMM d').format(dayData.date),
                    value: DurationFormat.decimalHours(dayData.totalWork),
                  ),
                ),
                _buildRow(
                  context,
                  title: context.loc.total,
                  subtitle: context.loc.last7Days,
                  value: DurationFormat.decimalHours(data.cycleUsed),
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
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(title, style: context.styles.sectionTitle),
          ),
          if (subtitle != null)
            Expanded(
              flex: 2,
              child: Text(subtitle, style: context.styles.muted),
            )
          else
            const Spacer(flex: 2),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: context.styles.number,
            ),
          ),
        ],
      ),
    );
  }
}
