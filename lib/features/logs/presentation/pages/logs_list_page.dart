import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../routes.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../domain/entities/daily_log.dart';
import '../providers/logs_provider.dart';

/// شاشة قائمة السجلات
class LogsListPage extends ConsumerWidget {
  const LogsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(logsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const EldDrawer(),
      appBar: AppBar(
        title: Center(
          child: Text(
            context.loc.logsTitle,
            style: context.styles.appBarTitle,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.surface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_copy,
                color: AppColors
                    .surface), // أيقونة القائمة العلوية اليمنى كما في التصميم
            onSelected: (value) {
              if (value == 'suggested') {
                context.push(AppRoutes.suggestedEvents);
              } else if (value == 'unidentified') {
                context.push(AppRoutes.unidentifiedEvents);
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'suggested',
                child: Text(context.loc.suggestedEvents),
              ),
              PopupMenuItem<String>(
                value: 'unidentified',
                child: Text(context.loc.unidentifiedEvents),
              ),
            ],
          ),
        ],
      ),
      body: (logsState.isLoading && logsState.logs.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : (logsState.error != null && logsState.logs.isEmpty)
              ? EldRetryView(
                  message: anyErrorUserMessage(
                    logsState.error!,
                    isArabic: Localizations.localeOf(context).languageCode == 'ar',
                  ),
                  onRetry: () =>
                      ref.read(logsProvider.notifier).loadLogs(refresh: true),
                )
              : logsState.logs.isEmpty
                  ? EldRetryView(
                      message: context.loc.noRecords,
                      onRetry: () =>
                          ref.read(logsProvider.notifier).loadLogs(refresh: true),
                    )
                  : RefreshIndicator(
                      onRefresh: () => ref.read(logsProvider.notifier).loadLogs(refresh: true),
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        itemCount: logsState.logs.length,
                        separatorBuilder: (_, __) =>
                            Divider(color: Theme.of(context).dividerColor, height: 1),
                        itemBuilder: (context, index) {
                          final log = logsState.logs[index];
                          return _LogListItem(
                            log: log,
                            onTap: () {
                              ref.read(logsProvider.notifier).selectLog(log);
                              context.push(
                                  AppRoutes.logDetail.replaceAll(
                                      ':id', log.id.value.toString()));
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

/// عنصر السجل في القائمة
class _LogListItem extends StatelessWidget {
  final DailyLog log;
  final VoidCallback onTap;

  const _LogListItem({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: Colors.black.withValues(alpha: 0.14),
      highlightColor: Colors.black.withValues(alpha: 0.08),
      child: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // السطر الأول: التاريخ + السهم
            Row(
              children: [
                Flexible(
                  child: Text(
                    log.formattedDate,
                    style: context.styles.sectionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (log.today) ...[
                  const SizedBox(width: 8),
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'اليوم'
                        : 'Today',
                    style: context.styles.caption.copyWith(
                      color: AppColors.primaryGold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (log.requiresAction) ...[
                  const SizedBox(width: 8),
                  Text(
                    Localizations.localeOf(context).languageCode == 'ar'
                        ? 'يتطلب إجراء'
                        : 'Action',
                    style: context.styles.caption.copyWith(
                      color: AppColors.dangerRed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                const Spacer(), // يدفع السهم إلى أقصى اليمين
                const Icon(
                  Icons.chevron_right,
                  size: 24,
                ),
              ],
            ),

            const SizedBox(height: 12), // مسافة بين السطر الأول والثاني

            // السطر الثاني: الوقت + الحالات (يلتف على شاشة ضيقة بدل أن يفيض)
            Wrap(
              spacing: 24,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                // 1. عدد الساعات
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: log.totalDrivingHours > 0
                          ? AppColors.successGreen
                          : AppColors.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      log.formattedTotalWorkTime.isNotEmpty
                          ? log.formattedTotalWorkTime
                          : (log.totalDrivingHours < 1
                              ? '< 1m'
                              : '${log.totalDrivingHours.toStringAsFixed(0)}h ${(log.totalDrivingHours % 1 * 60).toStringAsFixed(0)}m'),
                      style: TextStyle(
                        fontSize: AppTypography.subtitleSize,
                        fontWeight: AppTypography.bold,
                        color: log.totalDrivingHours > 0 || log.formattedTotalWorkTime.isNotEmpty
                            ? AppColors.successGreen
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                // 2. حالة النموذج (Form)
                _StatusChip(
                  label: context.loc.formLabel,
                  isComplete: log.isFormComplete,
                ),

                // 3. حالة التوثيق (Certify)
                _StatusChip(
                  label: context.loc.certifyLabel,
                  isComplete: log.isCertified,
                ),

                // لا حاجة لـ Spacer هنا لأن السهم موجود بالفعل في السطر الأول
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// شريحة حالة (Form/Cert)
class _StatusChip extends StatelessWidget {
  final String label;
  final bool isComplete;

  const _StatusChip({required this.label, required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isComplete ? Icons.check_circle : Icons.cancel,
          color: isComplete ? AppColors.successGreen : AppColors.dangerRed,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: AppTypography
                .subtitleSize, // changed from smallSize to match design scale better
            fontWeight: AppTypography.semiBold,
            color: isComplete ? AppColors.successGreen : AppColors.dangerRed,
          ),
        ),
      ],
    );
  }
}
