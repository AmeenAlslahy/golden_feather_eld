import 'package:golden_feather_eld/core/extensions/context_extensions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../providers/logs_provider.dart';
import '../widgets/log_graph.dart';
import '../../domain/entities/audit_entry.dart';

final auditProvider = FutureProvider.family<List<AuditEntry>, DateTime>((ref, date) async {
  return ref.read(logsProvider.notifier).getAuditEntries(date);
});

/// صفحة معاينة التفتيش الكاملة
class InspectionPreviewPage extends ConsumerStatefulWidget {
  const InspectionPreviewPage({super.key});

  @override
  ConsumerState<InspectionPreviewPage> createState() => _InspectionPreviewPageState();
}

class _InspectionPreviewPageState extends ConsumerState<InspectionPreviewPage> {
  int _currentDayIndex = 0;
  bool _isInitialized = false;

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardDataProvider);
    final logsState = ref.watch(logsProvider);
    final logs = logsState.logs;
    final loc = AppLocalizations.of(context)!;

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
        backgroundColor: AppColors.primaryBlue,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          selectedLog?.formattedDate ?? '',
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.tune, color: AppColors.surface),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('خيارات التصفية قيد التطوير')),
              );
            },
          ),
        ],
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
                  // ========== القسم ١: الرسم البياني ==========
                  LogGraph(events: selectedLog.events),
                  const Divider(height: 1),
                  // ========== القسم ٢: جدول الأحداث ==========
                  _EventsTable(events: selectedLog.events),
                  const Divider(height: 1),
                  // ========== القسم ٣: ملخص التفتيش ==========
                  _InspectionSummary(dashboard: dashboard),
                  const Divider(height: 1),
                  // ========== القسم ٤: سجل التدقيق ==========
                  _AuditTrail(selectedLog: selectedLog),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
        ),
        child: BottomNavigationBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          selectedItemColor: Theme.of(context).colorScheme.onSurface,
          unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
          currentIndex: 0,
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(icon: const Icon(Icons.access_time), label: loc.events),
            BottomNavigationBarItem(icon: const Icon(Icons.assignment), label: loc.form),
            BottomNavigationBarItem(icon: const Icon(Icons.check_circle_outline), label: loc.certify),
          ],
          onTap: (_) {},
        ),
      ),
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
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.chevron_left, color: Theme.of(context).colorScheme.onSurface),
            onPressed: hasPrevious ? onPrevious : null,
          ),
          Text(
            selectedLog?.formattedDate ?? '',
            style: TextStyle(
              fontSize: AppTypography.bodySize,
              fontWeight: AppTypography.semiBold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          IconButton(
            icon: Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurface),
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
            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    return Column(
      children: [
        // رأس الجدول
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
    return TextStyle(
      fontSize: AppTypography.smallSize,
      fontWeight: AppTypography.semiBold,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.5))),
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
                color: _getStatusColor(event.status),
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
              event.odometer != null ? '${event.odometer!.toStringAsFixed(0)}' : '-',
              style: _valueStyle(context),
            ),
          ),
          SizedBox(
            width: 55,
            child: Text(
              event.engineHours != null ? '${event.engineHours!.toStringAsFixed(1)}' : '-',
              style: _valueStyle(context),
            ),
          ),
          SizedBox(
            width: 40,
            child: Text(
              'Auto',
              style: _valueStyle(context).copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  TextStyle _valueStyle(BuildContext context) {
    return TextStyle(
      fontSize: AppTypography.smallSize,
      color: Theme.of(context).colorScheme.onSurface,
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'D':
        return AppColors.successGreen;
      case 'ON':
        return AppColors.warningYellow;
      case 'SB':
        return AppColors.primaryBlue;
      case 'OFF':
        return AppColors.textSecondary;
      default:
        return AppColors.textSecondary;
    }
  }
}

// ============================================================
// ملخص التفتيش
// ============================================================
class _InspectionSummary extends StatelessWidget {
  final dynamic dashboard;
  const _InspectionSummary({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // السطر 1: السائق
          _SummaryRow(cells: [
            _SummaryCell(label: loc.driverName, value: dashboard.driverName, flex: 3),
            _SummaryCell(label: loc.driverId, value: dashboard.vehicleId),
            _SummaryCell(label: loc.license, value: dashboard.driverLicense ?? '-'),
            _SummaryCell(label: loc.licenseState, value: 'SA'),
          ]),
          const SizedBox(height: AppSpacing.sm),
          // السطر 2: مساعد
          _SummaryRow(cells: [
            _SummaryCell(label: loc.exemptDriver, value: 'No'),
            _SummaryCell(label: loc.unidentifiedDriving, value: '0'),
            _SummaryCell(label: loc.coDriver, value: dashboard.coDriverName ?? 'None'),
            _SummaryCell(label: loc.coDriverId, value: dashboard.coDriverId ?? '-'),
          ]),
          const SizedBox(height: AppSpacing.sm),
          // السطر 3: التاريخ والتصديق
          _SummaryRow(cells: [
            _SummaryCell(label: loc.logDate, value: DateTime.now().toString().substring(0, 10)),
            _SummaryCell(label: loc.displayDate, value: DateTime.now().toString().substring(0, 10)),
            _SummaryCell(label: loc.displayLocation, value: 'Riyadh, SA'),
            _SummaryCell(label: loc.certified, value: 'Yes'),
          ]),
          const SizedBox(height: AppSpacing.sm),
          // السطر 4: ELD
          _SummaryRow(cells: [
            _SummaryCell(label: loc.eldRegId, value: 'GF-ELD-001'),
            _SummaryCell(label: loc.eldIdentifier, value: 'GF10000001'),
            _SummaryCell(label: loc.provider, value: 'Golden Feather ELD', flex: 2),
          ]),
          const SizedBox(height: AppSpacing.sm),
          // السطر 5: المؤشرات
          _SummaryRow(cells: [
            _SummaryCell(label: loc.periodStart, value: '00:00'),
            _SummaryCell(label: loc.dataDiag, value: '0'),
            _SummaryCell(label: loc.deviceMalf, value: '0'),
          ]),
          const SizedBox(height: AppSpacing.sm),
          // السطر 6: المركبة
          _SummaryRow(cells: [
            _SummaryCell(label: loc.vehicle, value: dashboard.vehicleId),
            _SummaryCell(label: loc.vin, value: '1FUJGLDR5CSBJ0527', flex: 2),
            _SummaryCell(label: loc.odometer, value: '125,000'),
            _SummaryCell(label: loc.distance, value: '450 km'),
            _SummaryCell(label: loc.engineHours, value: '3,500'),
          ]),
          const SizedBox(height: AppSpacing.sm),
          // السطر 7: الناقل
          _SummaryRow(cells: [
            _SummaryCell(label: loc.trailers, value: dashboard.trailerId ?? '-'),
            _SummaryCell(label: loc.shippingDocuments, value: dashboard.shippingDocuments ?? '-'),
            _SummaryCell(label: loc.carrier, value: 'Golden Feather Transport', flex: 2),
            _SummaryCell(label: loc.mainOffice, value: '123 Main St, Riyadh', flex: 2),
            _SummaryCell(label: loc.homeTerminal, value: '456 Terminal Rd, Dammam', flex: 2),
          ]),
        ],
      ),
    );
  }
}

// ============================================================
// صف في الملخص
// ============================================================
class _SummaryRow extends StatelessWidget {
  final List<Widget> cells;
  const _SummaryRow({required this.cells});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: cells,
    );
  }
}

// ============================================================
// خلية في الملخص
// ============================================================
class _SummaryCell extends StatelessWidget {
  final String label;
  final String value;
  final int flex;
  const _SummaryCell({required this.label, required this.value, this.flex = 1});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.xs),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 8,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 9,
                fontWeight: AppTypography.semiBold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// سجل التدقيق
// ============================================================
class _AuditTrail extends ConsumerWidget {
  final dynamic selectedLog;
  const _AuditTrail({required this.selectedLog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (selectedLog == null) return const SizedBox.shrink();

    final auditsAsync = ref.watch(auditProvider(selectedLog.date));

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Audit Trail',
            style: TextStyle(
              fontSize: AppTypography.subtitleSize,
              fontWeight: AppTypography.bold,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          auditsAsync.when(
            data: (audits) {
              if (audits.isEmpty) {
                return Text(context.loc.noManualModifications,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant));
              }
              return Column(
                children: audits.map((audit) => Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Theme.of(context).dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(audit.timestamp.toString().substring(0, 16),
                              style: const TextStyle(fontWeight: AppTypography.semiBold, fontSize: 12)),
                          Text(context.loc.auditStatusChange(audit.oldStatus ?? "New", audit.newStatus),
                              style: const TextStyle(color: AppColors.primaryBlue, fontWeight: AppTypography.bold, fontSize: 12)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(context.loc.auditReason(audit.reason), style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                )).toList(),
              );
            },
            loading: () => const CircularProgressIndicator(),
            error: (_, __) => Text(context.loc.failedToLoadAudits),
          ),
        ],
      ),
    );
  }
}
