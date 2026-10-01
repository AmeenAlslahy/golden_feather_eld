import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../providers/logs_provider.dart';
import '../widgets/log_graph.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../inspection/domain/transfer_audit.dart';
import '../../../inspection/presentation/providers/dot_inspection_providers.dart';
import '../../../inspection/presentation/widgets/inspection_log_header_table.dart';

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
            icon: const Icon(Icons.arrow_back, color: AppColors.surface),
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
              icon: const Icon(Icons.arrow_back, color: AppColors.surface),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text('Inspection Logs', style: context.styles.appBarTitle),
            centerTitle: true,
          ),
          body: selectedLog == null
              ? Center(child: Text(loc.noData))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      // ========== شريط التاريخ ==========
                      _DateHeader(
                        selectedLog: selectedLog,
                        hasPrevious: _currentDayIndex < logs.length - 1,
                        hasNext: _currentDayIndex > 0,
                        onPrevious: () {
                          if (_currentDayIndex < logs.length - 1) {
                            setState(() => _currentDayIndex++);
                          }
                        },
                        onNext: () {
                          if (_currentDayIndex > 0) {
                            setState(() => _currentDayIndex--);
                          }
                        },
                      ),
                      _InspectionSummary(screen: screen, selectedLog: selectedLog),
                      const Divider(height: 1),
                      LogGraph(events: selectedLog.events),
                      const Divider(height: 1),
                      _EventsTable(events: selectedLog.events),
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
}

// ============================================================
// شريط التاريخ
// ============================================================
class _DateHeader extends StatelessWidget {
  final dynamic selectedLog;
  final bool hasPrevious;
  final bool hasNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _DateHeader({
    required this.selectedLog,
    required this.hasPrevious,
    required this.hasNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: context.isDark ? const Color(0xFF3A3A3C) : AppColors.surfaceDark,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: hasPrevious ? onPrevious : null,
          ),
          Text(
            selectedLog?.formattedDate ?? '',
            style: context.styles.appBarTitle,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: hasNext ? onNext : null,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// جدول الأحداث
// ============================================================
class _EventsTable extends StatelessWidget {
  final List<dynamic> events;
  const _EventsTable({required this.events});

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Text(
            AppLocalizations.of(context)!.noData,
            style: context.styles.subtitle,
          ),
        ),
      );
    }

    return Column(
      children: [
        // رأس الجدول
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Row(
            children: [
              SizedBox(
                width: 60,
                child: Text(context.loc.time, style: _headerStyle(context)),
              ),
              Expanded(
                flex: 2,
                child: Text(context.loc.status, style: _headerStyle(context)),
              ),
              Expanded(
                flex: 3,
                child: Text(context.loc.location, style: _headerStyle(context)),
              ),
              SizedBox(
                width: 60,
                child: Text(context.loc.odom, style: _headerStyle(context)),
              ),
              SizedBox(
                width: 55,
                child: Text(context.loc.eng, style: _headerStyle(context)),
              ),
              SizedBox(
                width: 40,
                child: Text(context.loc.src, style: _headerStyle(context)),
              ),
            ],
          ),
        ),
        // صفوف البيانات
        ...events.map((event) => _EventRow(event: event)),
      ],
    );
  }

  TextStyle _headerStyle(BuildContext context) {
    return context.styles.caption.copyWith(
      fontWeight: FontWeight.w600,
    );
  }
}

// ============================================================
// صف حدث
// ============================================================
class _EventRow extends StatelessWidget {
  final dynamic event;
  const _EventRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: Theme.of(context).dividerColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              event.formattedStartTime ?? '',
              style: _valueStyle(context),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              event.statusArabic ?? event.status ?? '',
              style: _valueStyle(context).copyWith(
                color: _getStatusColor(context, event.status),
                fontWeight: AppTypography.semiBold,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              event.location ?? '',
              style: _valueStyle(context),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 60,
            child: Text(
              event.odometer != null
                  ? '${event.odometer!.toStringAsFixed(0)}'
                  : '-',
              style: _valueStyle(context),
            ),
          ),
          SizedBox(
            width: 55,
            child: Text(
              event.engineHours != null
                  ? '${event.engineHours!.toStringAsFixed(1)}'
                  : '-',
              style: _valueStyle(context),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              'Auto',
              style: _valueStyle(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _valueStyle(BuildContext context) {
    return context.styles.caption.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  Color _getStatusColor(BuildContext context, String? status) {
    switch (status) {
      case 'D':
        return AppColors.successGreen;
      case 'ON':
        return AppColors.warningYellow;
      case 'SB':
        return AppColors.primaryGold;
      case 'OFF':
        return context.styles.subtitle.color!;
      default:
        return context.styles.subtitle.color!;
    }
  }
}

// ============================================================
// ملخص التفتيش
// ============================================================
class _InspectionSummary extends ConsumerWidget {
  final DotInspectionScreen screen;
  final dynamic selectedLog;
  const _InspectionSummary({required this.screen, required this.selectedLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cycleAsync = ref.watch(dotInspectionCycleProvider);
    DotInspectionCycleDay? currentDay;
    cycleAsync.whenData((cycle) {
      try {
        currentDay = cycle.firstWhere(
          (d) =>
              d.logDate.year == selectedLog.date.year &&
              d.logDate.month == selectedLog.date.month &&
              d.logDate.day == selectedLog.date.day,
          orElse: () => cycle.first,
        );
      } catch (_) {
        if (cycle.isNotEmpty) currentDay = cycle.first;
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
