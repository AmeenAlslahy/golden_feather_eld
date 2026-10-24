import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/daily_log.dart';
import '../providers/logs_provider.dart';
import '../widgets/log_graph.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../inspection/presentation/providers/dot_inspection_providers.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../inspection/presentation/widgets/inspection_log_header_table.dart';
import '../../../../core/widgets/eld_date_paginator.dart';
import '../../../../core/widgets/eld_events_table.dart';
import '../providers/log_detail_tab_provider.dart';
import '../widgets/inspection_audit_trail_section.dart';
import '../widgets/inspection_filter_dialog.dart';

/// صفحة معاينة التفتيش الكاملة
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
      screenTitle: 'DOT Inspection Mode',
      guidanceText: 'Present this screen to the safety official upon request.',
      handOverDeviceNotice: 'Hand over device to safety official',
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
    final visibleEvents = _visibleEvents(selectedLog?.events ?? const []);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const BackButton(),
        title: Text(loc.inspectionLogsTitle, style: context.styles.appBarTitle),
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
                  EldEventsTable(rows: _buildEventRows(visibleEvents, context)),
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
              child: BottomNavigationBar(
                backgroundColor: Theme.of(context).colorScheme.surface,
                selectedItemColor: Theme.of(context).colorScheme.primary,
                unselectedItemColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                currentIndex: 0,
                type: BottomNavigationBarType.fixed,
                items: [
                  BottomNavigationBarItem(
                    icon: const Icon(Icons.access_time),
                    label: context.loc.events,
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: !selectedLog.isFormComplete,
                      backgroundColor: context.colors.error,
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
                  Navigator.pop(context);
                },
              ),
            ),
    );
  }

  List<EldTableRow> _buildEventRows(
    List<LogEvent> events,
    BuildContext context,
  ) {
    return events
        .map(
          (e) => EldTableRow(
            time: e.formattedStartTime,
            status: context.translateStatus(e.status),
            location: e.location,
            odom: e.odometer != null ? e.odometer!.toStringAsFixed(0) : '-',
            eng: e.engineHours != null
                ? e.engineHours!.toStringAsFixed(1)
                : '-',
            src: e.automatedDriving == null
                ? '—'
                : e.automatedDriving!
                ? 'Auto'
                : 'Driver',
            statusColor: _getStatusColor(context, e.status),
          ),
        )
        .toList();
  }

  List<LogEvent> _visibleEvents(List<LogEvent> events) {
    if (!_showActiveEventsOnly) return events;
    return events
        .where(
          (event) =>
              const {'ON', 'D', 'SB', 'OFF', 'PC', 'YM'}.contains(event.status),
        )
        .toList();
  }

  static Color _getStatusColor(BuildContext context, String? status) {
    switch (status) {
      case 'D':
        return context.success;
      case 'ON':
        return context.warning;
      case 'SB':
        return context.info;
      case 'OFF':
        return context.textSecondary;
      default:
        return context.textPrimary;
    }
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
    return InspectionLogHeaderTable(screen: screen, day: currentDay);
  }
}
