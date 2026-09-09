import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/time_extensions.dart';
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
                // جدول الأيام السبعة
                ...data.last7Days.map((dayData) => _buildRow(
                      title: dayData.dayName,
                      subtitle: dayData.formattedDate,
                      value:
                          (dayData.hoursWorked * 60).round().toHoursMinutes(),
                    )),

                const Divider(height: 1, color: AppColors.border),
                _buildRow(
                  title: context.loc.total,
                  subtitle: context.loc.last7Days,
                  value: (data.totalLast7Days * 60).round().toHoursMinutes(),
                  isBold: true,
                ),

                const Divider(height: 1, color: AppColors.border),
                _buildRow(
                  title: context.loc.hoursWorkedToday,
                  value: (data.hoursWorkedToday * 60).round().toHoursMinutes(),
                  isBold: true,
                ),

                const Divider(height: 1, color: AppColors.border),
                _buildRow(
                  title: context.loc.hoursAvailableToday,
                  value:
                      (data.hoursAvailableToday * 60).round().toHoursMinutes(),
                  isBold: true,
                ),

                const Divider(height: 1, color: AppColors.border),
                _buildRow(
                  title: context.loc.hoursAvailableTomorrow,
                  value: (data.hoursAvailableTomorrow * 60)
                      .round()
                      .toHoursMinutes(),
                  isBold: true,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('Error loading recap: $err'),
        ),
      ),
    );
  }

  Widget _buildRow({
    required String title,
    String? subtitle,
    required String value,
    bool isBold = false,
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
            child: Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight:
                    isBold ? AppTypography.bold : AppTypography.semiBold,
              ),
            ),
          ),
          if (subtitle != null)
            Expanded(
              flex: 2,
              child: Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 15,
                ),
              ),
            ),
          Expanded(
            flex: 1,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: AppTypography.semiBold,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
