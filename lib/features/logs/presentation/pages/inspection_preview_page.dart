import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../domain/shared/value_objects.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
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
      builder: (_) => InspectionFilterDialog(
        initialShowActiveOnly: _showActiveEventsOnly,
      ),
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

    return screenAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) {
        final selectedLog =
            logsState.selectedLog ?? (logs.isNotEmpty ? logs.first : null);
        // P3: بلا جواب خادم لا تُختلق هوية — القيم الحقيقية من السجل
        // المحلي أو فراغ، ودعوى الامتثال تُترك للنص المحلي المعتمد.
        final fallbackScreen = DotInspectionScreen(
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
        return _buildInspectionView(context, fallbackScreen, logsState, logs, loc);
      },
      data: (screen) =>
          _buildInspectionView(context, screen, logsState, logs, loc),
    );
  }

  Widget _buildInspectionView(
    BuildContext context,
    DotInspectionScreen screen,
    LogsState logsState,
    List<DailyLog> logs,
    AppLocalizations loc,
  ) {
    final selectedLog =
        logsState.selectedLog ?? (logs.isNotEmpty ? logs.first : null);
    final currentDayIndex = selectedLog != null
        ? logs.indexWhere((l) => l.id == selectedLog.id)
        : -1;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.inspectionLogsTitle,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
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
                  // ========== شريط التاريخ ==========
                  EldDatePaginator(
                    dateLabel: selectedLog.formattedDate,
                    canGoOlder: currentDayIndex != -1 &&
                        currentDayIndex < logs.length - 1,
                    canGoNewer: currentDayIndex > 0,
                    onSelectOlder: () =>
                        _goToDay(logs, currentDayIndex + 1),
                    onSelectNewer: () =>
                        _goToDay(logs, currentDayIndex - 1),
                  ),
                  _InspectionSummary(
                    screen: screen,
                    selectedLog: selectedLog,
                  ),
                  const Divider(height: 1),
                  LogGraph(events: selectedLog.events),
                  const Divider(height: 1),
                  EldEventsTable(
                    rows: _buildEventRows(selectedLog.events, context),
                  ),
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
        .where((e) {
          if (!_showActiveEventsOnly) return true;
          return const {'ON', 'D', 'SB', 'OFF'}.contains(e.status);
        })
        .map(
          (e) => EldTableRow(
            time: e.formattedStartTime,
            status: context.translateStatus(e.status),
            location: e.location,
            odom: e.odometer != null ? e.odometer!.toStringAsFixed(0) : '-',
            eng: e.engineHours != null
                ? e.engineHours!.toStringAsFixed(1)
                : '-',
            src: 'Auto',
            statusColor: _getStatusColor(e.status),
          ),
        )
        .toList();
  }

  static Color _getStatusColor(String? status) {
    switch (status) {
      case 'D':
        return AppColors.successGreen;
      case 'ON':
        return AppColors.warningYellow;
      case 'SB':
        return AppColors.infoBlue;
      case 'OFF':
        return AppColors.textSecondary;
      default:
        return AppColors.textPrimary;
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

