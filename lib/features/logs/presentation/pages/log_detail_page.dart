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
    final selectedLog = ref.watch(logsProvider).selectedLog;
    final currentIndex = ref.watch(logDetailTabProvider);

    if (selectedLog == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Center(child: Text(context.loc.noData)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () {
            ref.read(logDetailTabProvider.notifier).state = 0; // Reset state
            Navigator.pop(context);
          },
        ),
        title: Text(
          selectedLog.formattedDate,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility, color: AppColors.surface),
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
            icon: const Icon(Icons.add, color: AppColors.surface, size: 28),
            onPressed: () async {
              final successMsg = context.loc.eventAddedSuccess;
              final newEvent = LogEvent(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                status: 'OFF',
                statusArabic: 'خارج الخدمة',
                startTime: DateTime.now(),
                duration: Duration.zero,
                location: '',
              );

              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditLogPage(
                    event: newEvent,
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
                      Localizations.localeOf(context).languageCode == 'ar'
                          ? 'يلزم إعادة الاعتماد: حدثت تعديلات بعد آخر توقيع.'
                          : 'Re-certification Required: Edits were made after your last signature.',
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
