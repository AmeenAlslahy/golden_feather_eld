import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_status_badge.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../providers/reports_provider.dart';
import '../../../../core/engine/diagnostics/diagnostics_engine.dart';
import '../../data/services/pdf_export_service.dart';
import '../../../../core/engine/tracking/duty_status_tracker.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../core/utils/logger.dart';

/// شاشة التقارير
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(reportsProvider);
    final diagnostics = reportsState.diagnostics;
    final dashboard = ref.watch(dashboardDataProvider);
    final dutyTracker = ref.watch(dutyStatusTrackerProvider);
    final todayStats = dutyTracker.getTodayStats();
    final weekStats = dutyTracker.getWeekStats();
    final loc = context.loc;
    
    if (reportsState.eldReportJson == null && !reportsState.isLoading) {
      Future.microtask(() {
        if (context.mounted) {
          ref.read(reportsProvider.notifier).generateReports(loc);
        }
      });
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          loc.reports,
          style: AppTextStyles(context).pageTitle.copyWith(color: AppColors.surface),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.surface),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: const EldDrawer(),
      body: reportsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ========== تنبيهات الأعطال ==========
                  if (diagnostics.hasActiveMalfunctions) ...[
                    _buildDiagnosticsCard(context, diagnostics, ref),
                    const SizedBox(height: AppSpacing.md),
                  ],

                  // ========== تقرير ELD ==========
                  _buildReportCard(
                    context,
                    title: loc.eldReport,
                    icon: Icons.description,
                    color: AppColors.primaryBlue,
                    summary: _buildEldSummary(context, dashboard, todayStats),
                    reports: reportsState,
                    isEld: true,
                    dashboard: dashboard,
                    todayStats: todayStats,
                    weekStats: weekStats,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // ========== تقرير HOS ==========
                  _buildReportCard(
                    context,
                    title: loc.hosReport,
                    icon: Icons.analytics,
                    color: AppColors.successGreen,
                    summary: _buildHosSummary(context, todayStats, weekStats),
                    reports: reportsState,
                    isEld: false,
                    dashboard: dashboard,
                    todayStats: todayStats,
                    weekStats: weekStats,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
    );
  }

  /// بطاقة الأعطال
  Widget _buildDiagnosticsCard(BuildContext context, DiagnosticsState diagnostics, WidgetRef ref) {
    final loc = context.loc;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).errorLightBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.dangerRed.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber, color: AppColors.dangerRed, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(
                loc.malfunctionAlerts,
                style: AppTextStyles(context).bodyBold.copyWith(color: AppColors.dangerRed),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => ref.read(reportsProvider.notifier).clearDiagnostics(),
                child: Text(
                  loc.clearAll,
                  style: AppTextStyles(context).caption.copyWith(color: AppColors.dangerRed),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ...diagnostics.activeMalfunctions.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: [
                const Icon(Icons.error, size: 14, color: AppColors.dangerRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    Localizations.localeOf(context).languageCode == 'ar' ? m.arabicMessage : m.message,
                    style: AppTextStyles(context).caption.copyWith(color: AppColors.dangerRed),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  /// بطاقة تقرير
  Widget _buildReportCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color color,
    required Widget summary,
    required ReportsState reports,
    required bool isEld,
    required dynamic dashboard,
    required Map<String, dynamic> todayStats,
    required Map<String, dynamic> weekStats,
  }) {
    return EldCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTextStyles(context).bodyBold.copyWith(color: color)),
              const Spacer(),
              _buildStatusBadge(context),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          summary,
          const Divider(color: AppColors.border),
          const SizedBox(height: AppSpacing.sm),
          // أزرار التصدير
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildExportButton(context, 'JSON', () => _shareReport(context, isEld ? reports.eldReportJson : reports.hosReportJson, 'json')),
                const SizedBox(width: AppSpacing.sm),
                _buildExportButton(context, 'CSV', () => _shareReport(context, isEld ? reports.eldReportCsv : reports.hosReportCsv, 'csv')),
                const SizedBox(width: AppSpacing.sm),
                _buildExportButton(context, 'HTML', () => _shareReport(context, isEld ? reports.eldReportHtml : reports.hosReportHtml, 'html')),
                const SizedBox(width: AppSpacing.sm),
                _buildExportButton(context, 'PDF', () => _exportPdf(context, isEld, dashboard, todayStats, weekStats), isIcon: false, color: AppColors.dangerRed),
                const SizedBox(width: AppSpacing.sm),
                _buildExportButton(context, '📤', () => _shareReport(context, isEld ? reports.eldReportJson : reports.hosReportJson, 'txt'), isIcon: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// ملخص ELD
  Widget _buildEldSummary(BuildContext context, dynamic dashboard, Map<String, dynamic> todayStats) {
    final loc = context.loc;
    return Column(
      children: [
        _summaryRow(context, loc.driver, dashboard.driverName),
        _summaryRow(context, loc.vehicle, dashboard.vehicleId),
        _summaryRow(context, loc.drivingStatus, '${(todayStats['driving'] ?? 0).toStringAsFixed(2)}h'),
        _summaryRow(context, loc.onDuty, '${(todayStats['on_duty'] ?? 0).toStringAsFixed(2)}h'),
        _summaryRow(context, loc.offDuty, '${(todayStats['off_duty'] ?? 0).toStringAsFixed(2)}h'),
        _summaryRow(context, loc.sleeperBerth, '${(todayStats['sleeper'] ?? 0).toStringAsFixed(2)}h'),
        _summaryRow(context, loc.certified, loc.yes),
      ],
    );
  }

  /// ملخص HOS
  Widget _buildHosSummary(BuildContext context, Map<String, dynamic> todayStats, Map<String, dynamic> weekStats) {
    final loc = context.loc;
    return Column(
      children: [
        _summaryRow(context, loc.drivingStatus, '${(todayStats['driving'] ?? 0).toStringAsFixed(2)}h'),
        _summaryRow(context, loc.work, '${((todayStats['driving'] ?? 0) + (todayStats['on_duty'] ?? 0)).toStringAsFixed(2)}h'),
        _summaryRow(context, loc.rest, '${((todayStats['off_duty'] ?? 0) + (todayStats['sleeper'] ?? 0)).toStringAsFixed(2)}h'),
        _summaryRow(context, loc.break_, '0.00h'),
        _summaryRow(context, loc.distance, '${weekStats['distance'] ?? 0} km'),
        _summaryRow(context, loc.status, '✅ ${loc.compliant}'),
      ],
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppTextStyles(context).caption.copyWith(color: AppColors.textSecondary)),
          Text(value, style: AppTextStyles(context).caption.copyWith(fontWeight: AppTypography.semiBold)),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    return AppStatusBadge(
      label: context.loc.compliant,
      type: AppStatusBadgeType.success,
    );
  }

  Widget _buildExportButton(BuildContext context, String label, VoidCallback onTap, {bool isIcon = false, Color? color}) {
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          side: BorderSide(color: (color ?? (isIcon ? AppColors.successGreen : AppColors.primaryBlue)).withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(label, style: AppTextStyles(context).caption.copyWith(color: color ?? (isIcon ? AppColors.successGreen : AppColors.primaryBlue), fontWeight: AppTypography.semiBold)),
      ),
    );
  }

  Future<void> _exportPdf(BuildContext context, bool isEld, dynamic dashboard, Map<String, dynamic> todayStats, Map<String, dynamic> weekStats) async {
    final loc = context.loc;
    File? file;
    final date = DateTime.now().toString().substring(0, 10);
    
    if (isEld) {
      file = await PdfExportService.exportEldReport(
        driverName: dashboard.driverName,
        vehicleId: dashboard.vehicleId,
        date: date,
        stats: todayStats.map((key, value) => MapEntry(key, (value as num).toDouble())),
        isCertified: true,
        loc: loc,
      );
    } else {
      file = await PdfExportService.exportHosReport(
        driverName: dashboard.driverName,
        date: date,
        dailyStats: {
          'driving': (todayStats['driving'] as num?)?.toDouble() ?? 0.0,
          'work': ((todayStats['driving'] as num? ?? 0) + (todayStats['on_duty'] as num? ?? 0)).toDouble(),
          'rest': ((todayStats['off_duty'] as num? ?? 0) + (todayStats['sleeper'] as num? ?? 0)).toDouble(),
          'break': 0.0,
          'distance': (todayStats['distance'] as num?)?.toDouble() ?? 0.0,
        },
        weeklyStats: {
          'total_driving': (weekStats['driving'] as num?)?.toDouble() ?? 0.0,
          'total_work': (weekStats['work'] as num?)?.toDouble() ?? 0.0,
          'total_rest': (weekStats['rest'] as num?)?.toDouble() ?? 0.0,
          'total_break': 0.0,
          'total_distance': (weekStats['distance'] as num?)?.toDouble() ?? 0.0,
          'available_today': 11.0 - ((todayStats['driving'] as num?)?.toDouble() ?? 0.0),
          'available_tomorrow': 11.0,
        },
        isCompliant: true,
        loc: loc,
      );
    }

    if (file != null && context.mounted) {
      final success = await PdfExportService.sharePdf(file);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${loc.pdfExportedSuccess}'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    }
  }

  Future<void> _shareReport(BuildContext context, String? content, String extension) async {
    if (content == null) return;
    try {
      final directory = await getApplicationDocumentsDirectory();
      final file = File('${directory.path}/ELD_Report.$extension');
      await file.writeAsString(content);
      
      final result = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'ELD/HOS Report',
      );
      
      if (result.status == ShareResultStatus.success && context.mounted) {
        final isArabic = Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isArabic ? '✅ تم التصدير بنجاح' : '✅ Exported successfully'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      AppLogger.error('Failed to share report', e);
    }
  }
}
