import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
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
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.surface,
                ),
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
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(logsState.error!, style: const TextStyle(color: AppColors.dangerRed)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.read(logsProvider.notifier).loadLogs(refresh: true),
                        child: const Text('Retry'), // Or context.loc.retry if available
                      ),
                    ],
                  ),
                )
              : logsState.logs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt,
                              size: 64,
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            context.loc.noData,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
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
                Text(
                  log.formattedDate,
                  style: const TextStyle(
                    fontSize: AppTypography.bodySize,
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
                const Spacer(), // يدفع السهم إلى أقصى اليمين
                const Icon(
                  Icons.chevron_right,
                  size: 24,
                ),
              ],
            ),

            const SizedBox(height: 12), // مسافة بين السطر الأول والثاني

            // السطر الثاني: الوقت + الحالات
            Row(
              children: [
                // 1. عدد الساعات
                Row(
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

                const SizedBox(
                    width: 32), // مسافة ثابتة تفصل بين الوقت والحالة الأولى

                // 2. حالة النموذج (Form)
                _StatusChip(
                  label: context.loc.formLabel,
                  isComplete: log.isFormComplete,
                ),

                const SizedBox(width: 24), // مسافة ثابتة تفصل بين الحالتين

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
