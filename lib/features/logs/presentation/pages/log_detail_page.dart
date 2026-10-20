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
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../core/error/user_facing_message.dart';

/// شاشة تفاصيل اليوم (Shell)
class LogDetailPage extends ConsumerStatefulWidget {
  const LogDetailPage({super.key, this.logId});

  /// معرّف اليوم من المسار (`/logs/:id`). عند غيابه (استدعاء قديم) يبقى
  /// الاعتماد على السجل المحدد.
  final String? logId;

  @override
  ConsumerState<LogDetailPage> createState() => _LogDetailPageState();
}

class _LogDetailPageState extends ConsumerState<LogDetailPage> {
  String? _activeLogId;
  bool _ensureScheduled = false;

  /// آخر صفحة طُلبت للعثور على سجل المسار. يميّز نجاح الترقيم (يتقدم
  /// `page` بعد كل استجابة ناجحة) من فشل صامت (شبكة بلا خطأ صريح) حتى لا
  /// ندور في حلقة تحميل لا نهائية.
  int? _requestedPage;

  @override
  void initState() {
    super.initState();
    _activeLogId = widget.logId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureSelection());
  }

  @override
  void didUpdateWidget(covariant LogDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.logId != widget.logId) {
      _activeLogId = widget.logId;
      _requestedPage = null;
      _scheduleEnsureSelection();
    }
  }

  DailyLog? _findLog(LogsState state, String id) {
    for (final log in state.logs) {
      if (log.id.value.toString() == id) return log;
    }
    final selected = state.selectedLog;
    if (selected != null && selected.id.value.toString() == id) {
      return selected;
    }
    return null;
  }

  /// يضمن أن السجل المحدد هو سجل المسار: من القائمة إن وُجد، وإلا يتابع
  /// الترقيم صفحةً صفحة حتى يجد السجل أو تنفد الصفحات (الوصل العميق قد
  /// يشير إلى يوم أقدم من الصفحة الأولى). لا يبقي الصفحة رهينة اختيار قديم.
  void _ensureSelection([LogsState? snapshot]) {
    if (!mounted) return;
    final desiredId = _activeLogId;
    if (desiredId == null || desiredId.isEmpty) return;

    final LogsState state = snapshot ?? ref.read(logsProvider);
    final target = _findLog(state, desiredId);
    if (target != null) {
      _requestedPage = null;
      if (state.selectedLog?.id != target.id) {
        ref.read(logsProvider.notifier).selectLog(target);
      }
      return;
    }

    if (state.isLoading || state.error != null || state.hasReachedMax) return;

    // نتوقف إذا لم يتقدم `page` بعد الطلب السابق (فشل صامت) — زر إعادة
    // المحاولة في الواجهة يكسر الجمود دون حلقة تلقائية.
    final pageBefore = state.page;
    if (_requestedPage != null && pageBefore == _requestedPage) return;
    _requestedPage = pageBefore;
    ref.read(logsProvider.notifier).loadLogs();
  }

  void _scheduleEnsureSelection() {
    if (_ensureScheduled) return;
    _ensureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureScheduled = false;
      _ensureSelection();
    });
  }

  void _selectDay(DailyLog log) {
    _activeLogId = log.id.value.toString();
    ref.read(logsProvider.notifier).selectLog(log);
  }

  @override
  Widget build(BuildContext context) {
    final logsState = ref.watch(logsProvider);
    ref.listen<LogsState>(logsProvider, (_, next) => _ensureSelection(next));
    final currentIndex = ref.watch(logDetailTabProvider);

    DailyLog? selectedLog;
    if (_activeLogId != null && _activeLogId!.isNotEmpty) {
      selectedLog = _findLog(logsState, _activeLogId!);
      if (selectedLog != null &&
          logsState.selectedLog?.id != selectedLog.id) {
        // السجل من القائمة ولم يُحدَّد بعد — لا نعرض بيانات يوم آخر.
        _scheduleEnsureSelection();
        selectedLog = null;
      }
    } else {
      selectedLog = logsState.selectedLog;
    }

    if (selectedLog == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: logsState.isLoading
              ? const CircularProgressIndicator()
              : EldRetryView(
                  message: logsState.error != null
                      ? anyErrorUserMessage(logsState.error!, loc: context.loc)
                      : context.loc.noData,
                  isError: logsState.error != null,
                  onRetry: () {
                    _requestedPage = null;
                    ref
                        .read(logsProvider.notifier)
                        .loadLogs(refresh: true);
                  },
                ),
        ),
      );
    }

    final allLogs = logsState.logs;
    final selectedId = selectedLog.id;
    final logIndex = allLogs.indexWhere((l) => l.id == selectedId);
    final hasNextDay = logIndex > 0;
    final hasPrevDay = logIndex >= 0 && logIndex < allLogs.length - 1;

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          ref.read(logDetailTabProvider.notifier).state = 0;
        }
      },
      child: Scaffold(
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
                if (hasPrevDay)
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      size: 26,
                      color: context.styles.appBarTitle.color,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _selectDay(allLogs[logIndex + 1]),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    selectedLog.formattedDate,
                    style: context.styles.appBarTitle,
                  ),
                ),
                if (hasNextDay)
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      size: 26,
                      color: context.styles.appBarTitle.color,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => _selectDay(allLogs[logIndex - 1]),
                  ),
              ],
            ),
          ),
        ),
        centerTitle: true,
        // أيقونتا المعاينة والإضافة خاصتان بتبويب الأحداث فقط —
        // تُخفيان في النموذج والتوثيق.
        actions: [
          if (currentIndex == 0)
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
          if (currentIndex == 0)
            IconButton(
              icon: const Icon(Icons.add, size: 28),
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
              color: AppColors.warningBg,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: AppColors.warningText),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.loc.reCertificationRequiredMsg,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.warningText,
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
      ), // ← إغلاق PopScope
    );
  }

  Widget _buildBodyContent(int currentIndex, DailyLog selectedLog) {
    return IndexedStack(
      index: currentIndex.clamp(0, 2),
      children: [
        EventsTab(
          key: ValueKey('events_${selectedLog.id.value}'),
          selectedLog: selectedLog,
        ),
        FormTab(
          key: ValueKey('form_${selectedLog.id.value}'),
        ),
        CertifyTab(
          key: ValueKey('certify_${selectedLog.id.value}'),
          selectedLog: selectedLog,
        ),
      ],
    );
  }
}
