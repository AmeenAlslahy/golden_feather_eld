import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/logs_provider.dart';
import '../providers/log_detail_tab_provider.dart';
import '../../domain/entities/daily_log.dart';
import 'edit_log_page.dart';
import 'inspection_preview_page.dart';
import '../widgets/log_detail_tabs/events_tab.dart';
import '../widgets/log_detail_tabs/form_tab.dart';
import '../widgets/log_detail_tabs/certify_tab.dart';
import '../../../../core/widgets/app_feedback.dart';

/// شاشة تفاصيل اليوم (Shell)
class LogDetailPage extends ConsumerWidget {
  const LogDetailPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logsState = ref.watch(logsProvider);
    final selectedLog = logsState.selectedLog;
    final currentIndex = ref.watch(logDetailTabProvider);

    if (selectedLog == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text(context.loc.noData)),
      );
    }

    final allLogs = logsState.logs;
    final logIndex = allLogs.indexWhere((l) => l.id == selectedLog.id);
    final hasNextDay = logIndex > 0;
    final hasPrevDay = logIndex >= 0 && logIndex < allLogs.length - 1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(logDetailTabProvider.notifier).state = 0; // Reset state
            Navigator.pop(context);
          },
        ),
        title: Directionality(
          textDirection: TextDirection.ltr,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Icon(
                    Icons.chevron_left,
                    size: 26,
                    color: hasPrevDay
                        ? context.styles.appBarTitle.color
                        : context.styles.appBarTitle.color?.withValues(alpha: 0.2),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: hasPrevDay
                      ? () {
                          ref
                              .read(logsProvider.notifier)
                              .selectLog(allLogs[logIndex + 1]);
                        }
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    selectedLog.formattedDate,
                    style: context.styles.appBarTitle,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    size: 26,
                    color: hasNextDay
                        ? context.styles.appBarTitle.color
                        : context.styles.appBarTitle.color?.withValues(alpha: 0.2),
                  ),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: hasNextDay
                      ? () {
                          ref
                              .read(logsProvider.notifier)
                              .selectLog(allLogs[logIndex - 1]);
                        }
                      : null,
                ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const InspectionPreviewPage(),
                ),
              );
            },
          ),
          IconButton(
            icon:  const Icon(Icons.add, size: 28),
            onPressed: () async {
              final successMsg = context.loc.eventAddedSuccess;

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const EditLogPage(
                    event: null,
                    isNewEvent: true,
                  ),
                ),
              );

              if (result == true && context.mounted) {
                // الحفظ يتم من داخل EditLogPage (حدث المستخدم المعدّل وليس الافتراضي)
                if (context.mounted) {
                  AppFeedback.success(context, successMsg);
                }
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (selectedLog.certificationStatus == CertificationStatus.reCertificationRequired)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              color: AppColors.warningYellow.withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warningYellow),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.loc.reCertificationRequiredMsg,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.warningYellow,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(child: _buildBodyContent(currentIndex, selectedLog)),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
              top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          currentIndex: currentIndex,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.access_time),
              label: context.loc.events,
            ),
            BottomNavigationBarItem(
              icon: Badge(
                isLabelVisible: !selectedLog.isFormComplete,
                backgroundColor: AppColors.dangerRed,
                child: const Icon(Icons.assignment),
              ),
              label: context.loc.form,
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.check_circle_outline),
              label: context.loc.certify,
            ),
          ],
          onTap: (index) {
            ref.read(logDetailTabProvider.notifier).state = index;
          },
        ),
      ),
    );
  }

  Widget _buildBodyContent(int currentIndex, DailyLog selectedLog) {
    switch (currentIndex) {
      case 0:
        return EventsTab(selectedLog: selectedLog);
      case 1:
        return const FormTab();
      case 2:
        return CertifyTab(selectedLog: selectedLog);
      default:
        return const SizedBox.shrink();
    }
  }
}
