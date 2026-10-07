import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/daily_log.dart';
import '../providers/logs_provider.dart';
import '../widgets/log_graph.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../inspection/domain/transfer_audit.dart';
import '../../../inspection/presentation/providers/dot_inspection_providers.dart';
import '../../../inspection/presentation/widgets/inspection_log_header_table.dart';
import '../../../../core/widgets/eld_date_paginator.dart';
import '../../../../core/widgets/eld_events_table.dart';

/// صفحة معاينة التفتيش الكاملة
class InspectionPreviewPage extends ConsumerStatefulWidget {
  const InspectionPreviewPage({super.key});

  @override
  ConsumerState<InspectionPreviewPage> createState() =>
      _InspectionPreviewPageState();
}

class _InspectionPreviewPageState extends ConsumerState<InspectionPreviewPage> {
  int _currentDayIndex = 0;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final screenAsync = ref.watch(dotInspectionScreenProvider);
    final logsState = ref.watch(logsProvider);
    final logs = logsState.logs;
    final loc = AppLocalizations.of(context)!;

    return screenAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: EldRetryView(
          message: anyErrorUserMessage(
            e,
            loc: AppLocalizations.of(context)!,
          ),
          onRetry: () => ref.invalidate(dotInspectionScreenProvider),
        ),
      ),
      data: (screen) {
        // تهيئة المؤشر لليوم المحدد حالياً عند فتح الشاشة
        if (!_isInitialized && logsState.selectedLog != null && logs.isNotEmpty) {
          final index = logs.indexWhere((l) => l.id == logsState.selectedLog!.id);
          if (index != -1) {
            _currentDayIndex = index;
          }
          _isInitialized = true;
        }

        final selectedLog = logs.isNotEmpty ? logs[_currentDayIndex] : null;

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(loc.inspectionLogsTitle,
                style: context.styles.appBarTitle),
            centerTitle: true,
          ),
          body: selectedLog == null
              ? Center(child: Text(loc.noData))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // ========== شريط التاريخ ==========
                      EldDatePaginator(
                        dateLabel: selectedLog.formattedDate,
                        canGoOlder: _currentDayIndex < logs.length - 1,
                        canGoNewer: _currentDayIndex > 0,
                        onSelectOlder: () {
                          if (_currentDayIndex < logs.length - 1) {
                            setState(() => _currentDayIndex++);
                          }
                        },
                        onSelectNewer: () {
                          if (_currentDayIndex > 0) {
                            setState(() => _currentDayIndex--);
                          }
                        },
                      ),
                      _InspectionSummary(screen: screen, selectedLog: selectedLog),
                      const Divider(height: 1),
                      LogGraph(events: selectedLog.events),
                      const Divider(height: 1),
                      EldEventsTable(
                        rows: selectedLog.events.map((e) => EldTableRow(
                          time: e.formattedStartTime,
                          status: context.translateStatus(e.status),
                          location: e.location,
                          odom: e.odometer != null ? e.odometer!.toStringAsFixed(0) : '-',
                          eng: e.engineHours != null ? e.engineHours!.toStringAsFixed(1) : '-',
                          src: 'Auto',
                          statusColor: _getStatusColor(context, e.status),
                        )).toList(),
                      ),
                      const Divider(height: 1),
                      const _AuditTrail(),
                      const SizedBox(height: AppSpacing.lg),
                    ],
                  ),
                ),
          bottomNavigationBar: null,
        );
      },
    );
  }

  Color _getStatusColor(BuildContext context, String? status) {
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
    final cycleAsync = ref.watch(dotInspectionCycleProvider);
    DotInspectionCycleDay? currentDay;
    cycleAsync.whenData((cycle) {
      if (selectedLog != null) {
        try {
          currentDay = cycle.firstWhere(
            (d) =>
                d.logDate.year == selectedLog!.date.year &&
                d.logDate.month == selectedLog!.date.month &&
                d.logDate.day == selectedLog!.date.day,
            orElse: () => cycle.first,
          );
        } catch (_) {
          if (cycle.isNotEmpty) currentDay = cycle.first;
        }
      }
    });

    return InspectionLogHeaderTable(screen: screen, day: currentDay);
  }
}

// ============================================================
// سجل التدقيق
// ============================================================
class _AuditTrail extends ConsumerWidget {
  const _AuditTrail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auditsAsync = ref.watch(transferAuditProvider);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.loc.transferAuditTitle,
            style: context.styles.bodyBold
                .copyWith(fontSize: AppTypography.subtitleSize),
          ),
          const SizedBox(height: AppSpacing.md),
          auditsAsync.when(
            data: (audits) {
              if (audits.isEmpty) {
                return Text(
                  context.loc.noTransfersFromServer,
                  style: context.styles.subtitle,
                );
              }
              return Column(
                children: [
                  for (final audit in audits) _TransferAuditTile(audit: audit),
                ],
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text(
              context.loc.transferAuditNotLoaded(error.toString()),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransferAuditTile extends StatelessWidget {
  final TransferAuditRow audit;
  const _TransferAuditTile({required this.audit});

  @override
  Widget build(BuildContext context) {
    final lines = [
      if (audit.status.isNotEmpty) audit.status,
      if (audit.channel.isNotEmpty) audit.channel,
      if (audit.recipient.isNotEmpty) audit.recipient,
      if (audit.transferredAt.isNotEmpty) audit.transferredAt,
      if (audit.period.isNotEmpty) audit.period,
      if (audit.recordCount.isNotEmpty) audit.recordCount,
      if (audit.message.isNotEmpty) audit.message,
    ];
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Text(lines.join(' · '), style: context.styles.caption),
    );
  }
}
