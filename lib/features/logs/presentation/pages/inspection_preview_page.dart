import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/eld_date_paginator.dart';
import '../../../../core/widgets/eld_events_table.dart';
import '../../../../core/widgets/golden_app_bar.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../inspection/presentation/providers/dot_inspection_providers.dart';
import '../../../codriver/presentation/providers/codriver_provider.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../inspection/presentation/widgets/inspection_log_header_table.dart';
import '../../domain/entities/daily_log.dart';
import '../formatters/log_date_formatter.dart';
import '../mappers/inspection_preview_event_mapper.dart';
import '../providers/log_detail_tab_provider.dart';
import '../providers/logs_provider.dart';
import '../widgets/inspection_audit_trail_section.dart';
import '../widgets/inspection_filter_dialog.dart';
import '../widgets/log_graph.dart';

/// صفحة معاينة التفتيش الكاملة (Roadside DOT Inspection Preview).
///
/// تعرض كافة بيانات التفتيش المطلوبة نظاماً في مكان واحد:
/// 1. شريط التنقل بين الأيام (EldDatePaginator).
/// 2. جدول بيانات الهيدر والناقل والمركبة (InspectionLogHeaderTable).
/// 3. الرسم البياني للحالات اليومية (LogGraph).
/// 4. جدول أحداث اليوم الرسمي (EldEventsTable).
/// 5. سجل التدقيق الميداني (InspectionAuditTrailSection).
class InspectionPreviewPage extends ConsumerStatefulWidget {
  const InspectionPreviewPage({super.key});

  @override
  ConsumerState<InspectionPreviewPage> createState() =>
      _InspectionPreviewPageState();
}

class _InspectionPreviewPageState extends ConsumerState<InspectionPreviewPage> {
  bool _showActiveEventsOnly = true;

  Future<void> _showFilterDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) =>
          InspectionFilterDialog(initialShowActiveOnly: _showActiveEventsOnly),
    );

    if (result != null && result != _showActiveEventsOnly) {
      setState(() {
        _showActiveEventsOnly = result;
      });
    }
  }

  void _goToDay(List<DailyLog> logs, int index) {
    if (index < 0 || index >= logs.length) return;
    ref.read(logsProvider.notifier).selectLog(logs[index]);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(logsProvider.notifier).loadSelectedLogEvents();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenAsync = ref.watch(dotInspectionScreenProvider);
    final logsState = ref.watch(logsProvider);
    final logs = logsState.logs;
    final loc = AppLocalizations.of(context)!;

    final screen = screenAsync.valueOrNull;
    final view = _buildInspectionView(
      context,
      screen ?? _fallbackScreen(logsState, loc),
      logsState,
      logs,
      loc,
      metadataUnavailable: screenAsync.hasError,
    );
    if (screen != null) return view;

    // Daily logs remain usable while inspection metadata is loading/failing.
    return Stack(
      children: [
        view,
        if (screenAsync.isLoading)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(),
          ),
      ],
    );
  }

  DotInspectionScreen _fallbackScreen(
    LogsState logsState,
    AppLocalizations loc,
  ) {
    final selectedLog =
        logsState.selectedLog ??
        (logsState.logs.isNotEmpty ? logsState.logs.first : null);
    return DotInspectionScreen(
      screenTitle: loc.inspectionMode,
      guidanceText: loc.inspectionFallbackGuidance,
      handOverDeviceNotice: loc.inspectionHandOverNotice,
      carrierComplianceStatement: loc.eldCertifies,
      carrierName: selectedLog?.carrierName ?? '',
      usdotNumber: selectedLog?.usdotNumber ?? '',
      eldIdentifier: '',
      eldRegistrationId: '',
      driverId: DriverId(ref.read(currentDriverIdProvider) ?? 0),
      driverName: selectedLog?.driverName ?? '',
      inspectionDate: selectedLog?.date ?? DateTime.now(),
      cycleDaysCovered: 8,
      canStartInspection: true,
      canSendLogs: false,
      canEmailLogs: false,
      canViewInformationPacket: true,
      inspectionActive: false,
      readOnlyMode: true,
    );
  }

  Widget _buildInspectionView(
    BuildContext context,
    DotInspectionScreen screen,
    LogsState logsState,
    List<DailyLog> logs,
    AppLocalizations loc, {
    bool metadataUnavailable = false,
  }) {
    final selectedLog =
        logsState.selectedLog ?? (logs.isNotEmpty ? logs.first : null);
    final currentDayIndex = selectedLog != null
        ? logs.indexWhere((l) => l.id == selectedLog.id)
        : -1;
    final visibleEvents = InspectionPreviewEventMapper.filterEvents(
      selectedLog?.events ?? const [],
      showActiveOnly: _showActiveEventsOnly,
    );
    final tableRows = visibleEvents
        .map((e) => InspectionPreviewEventMapper.toTableRow(e, context))
        .toList();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: GoldenAppBar(
        leading: const BackButton(),
        title: Text(loc.inspectionPreview, style: context.styles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _showFilterDialog,
          ),
        ],
      ),
      body: selectedLog == null
          ? Center(child: Text(loc.noData))
          : SingleChildScrollView(
              child: Column(
                children: [
                  if (metadataUnavailable)
                    MaterialBanner(
                      content: Text(loc.errRequestFailed),
                      actions: [
                        TextButton(
                          onPressed: () => ref
                              .read(dotInspectionScreenProvider.notifier)
                              .reload(),
                          child: Text(loc.retryButton),
                        ),
                      ],
                    ),
                  // ========== شريط التاريخ ==========
                  EldDatePaginator(
                    dateLabel: selectedLog.formattedDate,
                    canGoOlder:
                        currentDayIndex != -1 &&
                        currentDayIndex < logs.length - 1,
                    canGoNewer: currentDayIndex > 0,
                    onSelectOlder: () => _goToDay(logs, currentDayIndex + 1),
                    onSelectNewer: () => _goToDay(logs, currentDayIndex - 1),
                  ),
                  _InspectionSummary(screen: screen, selectedLog: selectedLog),
                  const Divider(height: 1),
                  if (logsState.eventsError != null)
                    MaterialBanner(
                      content: Text(
                        anyErrorUserMessage(logsState.eventsError!, loc: loc),
                      ),
                      actions: [
                        TextButton(
                          onPressed: logsState.isLoadingEvents
                              ? null
                              : () => ref
                                    .read(logsProvider.notifier)
                                    .loadSelectedLogEvents(),
                          child: Text(loc.retryButton),
                        ),
                      ],
                    ),
                  if (logsState.isLoadingEvents && selectedLog.events.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  if (logsState.isLoadingEvents &&
                      selectedLog.events.isNotEmpty)
                    const LinearProgressIndicator(),
                  LogGraph(events: visibleEvents, logDate: selectedLog.date),
                  const Divider(height: 1),
                  EldEventsTable(rows: tableRows),
                  const Divider(height: 1),
                  const InspectionAuditTrailSection(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
      bottomNavigationBar: selectedLog == null
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                    width: 1,
                  ),
                ),
              ),
              child: SafeArea(
                child: SizedBox(
                  height: 56,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(logDetailTabProvider.notifier).state =
                                LogDetailTab.events.index;
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(
                                AppRadius.small,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.access_time, size: 20),
                                const SizedBox(width: AppSpacing.xs),
                                Text(
                                  context.loc.events,
                                  style: context.styles.bodyBold,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(logDetailTabProvider.notifier).state =
                                LogDetailTab.form.index;
                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Badge(
                                isLabelVisible: !selectedLog.isFormComplete,
                                backgroundColor: context.colors.error,
                                child: const Icon(Icons.assignment, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                context.loc.form,
                                style: context.styles.subtitle,
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () {
                            ref.read(logDetailTabProvider.notifier).state =
                                LogDetailTab.certify.index;
                            Navigator.pop(context);
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 20),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                context.loc.certify,
                                style: context.styles.subtitle,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

// ============================================================
// ملخص التفتيش
// ============================================================
class _InspectionSummary extends ConsumerWidget {
  final DotInspectionScreen screen;
  final DailyLog? selectedLog;
  const _InspectionSummary({required this.screen, required this.selectedLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentDay = ref.watch(
      matchingInspectionCycleDayProvider(selectedLog?.date),
    );
    // المصدر الأغنى أولاً (log) + الرخصة والسائق المساعد — نفس مصادر
    // شاشة التفتيش النشطة؛ كانت المعاينة تحرم الجدول منها فيفرغ أكثر
    // حقول RODS (سبب اختفاء الترويسة).
    final dayLog = ref
        .watch(inspectionDayLogProvider(selectedLog?.date))
        .valueOrNull;
    final license = ref.watch(
      accountProvider.select((s) => s.accountData?.license),
    );
    final co = ref.watch(codriverProvider.select((s) => s.currentCoDriver));
    return InspectionLogHeaderTable(
      screen: screen,
      day: currentDay,
      log: dayLog,
      driverLicense: license?.number ?? '-',
      driverLicenseState: license?.state ?? '-',
      coDriver: co?.name ?? '',
      coDriverId: co?.isLinked == true ? '${co?.coDriverId}' : '',
    );
  }
}
