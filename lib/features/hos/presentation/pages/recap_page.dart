import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/extensions/time_extensions.dart';
import '../../../../core/error/failure.dart' as f;
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
                      title: dayData.dayOfWeek,
                      subtitle: DateFormat('MMM d').format(dayData.date),
                      value: dayData.totalWork.inMinutes.toHoursMinutes(),
                    )),

                const Divider(height: 1, color: AppColors.border),
                _buildRow(
                  title: 'Cycle Rule',
                  value: data.cycleRule.wire,
                  isBold: true,
                ),

                const Divider(height: 1, color: AppColors.border),
                _buildRow(
                  title: 'Cycle Used', // You can use context.loc.total if suitable
                  value: data.cycleUsed.inMinutes.toHoursMinutes(),
                  isBold: true,
                ),

                const Divider(height: 1, color: AppColors.border),
                _buildRow(
                  title: 'Cycle Remaining',
                  value: data.cycleRemaining.inMinutes.toHoursMinutes(),
                  isBold: true,
                ),

                const Divider(height: 1, color: AppColors.border),
                _buildRow(
                  title: context.loc.hoursAvailableTomorrow,
                  value: data.availableTomorrow.inMinutes.toHoursMinutes(),
                  isBold: true,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) {
          String msg = 'حدث خطأ غير متوقع';
          if (err is f.Failure) {
            if (err is f.NetworkFailure) {
              msg = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.';
            } else if (err is f.ServerFailure) {
              msg = 'حدثت مشكلة في الاتصال بالخادم. يرجى المحاولة لاحقاً.';
            } else {
              msg = 'فشل في العملية. الرجاء المحاولة مرة أخرى.';
            }
          }
          return Center(
            child: Text(msg),
          );
        },
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
