import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../providers/recap_provider.dart';

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
                ...data.days.map((dayData) => _buildRow(
                      context,
                      title: dayData.dayOfWeek,
                      subtitle: DateFormat('MMM d').format(dayData.date),
                      value: _decimalHours(dayData.totalWork),
                    )),
                _buildRow(
                  context,
                  title: context.loc.total,
                  subtitle: context.loc.last7Days,
                  value: _decimalHours(data.cycleUsed),
                ),
                _buildRow(
                  context,
                  title: context.loc.hoursWorkedToday,
                  value: () {
                    final now = DateTime.now();
                    for (final day in data.days) {
                      if (day.date.year == now.year &&
                          day.date.month == now.month &&
                          day.date.day == now.day) {
                        return _decimalHours(day.totalWork);
                      }
                    }
                    return '00.00';
                  }(),
                ),
                _buildRow(
                  context,
                  title: context.loc.hoursAvailableToday,
                  value: _decimalHours(data.cycleRemaining),
                ),
                _buildRow(
                  context,
                  title: context.loc.hoursAvailableTomorrow,
                  value: _decimalHours(data.availableTomorrow),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          final isArabic = Localizations.localeOf(context).languageCode == 'ar';
          return EldRetryView(
            message: anyErrorUserMessage(err, isArabic: isArabic),
            onRetry: () => ref.invalidate(recapProvider),
          );
        },
      ),
    );
  }

  String _decimalHours(Duration d) {
    final hours = d.inMinutes / 60.0;
    return hours.abs().toStringAsFixed(2).padLeft(5, '0');
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
