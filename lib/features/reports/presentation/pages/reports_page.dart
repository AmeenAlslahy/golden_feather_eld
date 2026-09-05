import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../../../../features/hos/domain/engine/diagnostics/diagnostics_engine.dart';
import '../../../../features/hos/domain/engine/tracking/duty_status_tracker.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../../core/network/network_providers.dart';

/// شاشة التقارير
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsState = ref.watch(reportsProvider);
    final backendType = ref.watch(backendTypeProvider);
    final diagnostics = reportsState.diagnostics;
    final dashboard = ref.watch(dashboardDataProvider);
    final dutyTracker = ref.watch(dutyStatusTrackerProvider);
    final todayStats = dutyTracker.getTodayStats();
    final weekStats = dutyTracker.getWeekStats();
    final loc = context.loc;
    
    final hasData = backendType == 'traccar' 
        ? reportsState.standardSummary != null 
        : reportsState.eldReport != null;
        
    if (!hasData && !reportsState.isLoading) {
      Future.microtask(() {
        if (context.mounted) {
          ref.read(reportsProvider.notifier).generateReports();
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

                  if (backendType == 'traccar') ...[
                    // ========== تقرير الملخص ==========
                    _buildReportCard(
                      context,
                      title: loc.reports, // summary report
                      icon: Icons.summarize,
                      color: AppColors.primaryBlue,
                      summary: _buildStandardSummary(context, reportsState.standardSummary),
                      isEld: false,
                      ref: ref,
                      exportFormat: 'summary',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    // ========== تقرير الرحلات ==========
                    _buildReportCard(
                      context,
                      title: 'Trips',
                      icon: Icons.directions_car,
                      color: AppColors.successGreen,
                      summary: _buildStandardSummary(context, reportsState.standardRoute), // using route or trips
                      isEld: false,
                      ref: ref,
                      exportFormat: 'trips',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ] else ...[
                    // ========== تقرير ELD ==========
                    _buildReportCard(
                      context,
                      title: loc.eldReport,
                      icon: Icons.description,
                      color: AppColors.primaryBlue,
                      summary: _buildEldSummary(context, dashboard, todayStats),
                      isEld: true,
                      ref: ref,
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // ========== تقرير HOS ==========
                    _buildReportCard(
                      context,
                      title: loc.hosReport,
                      icon: Icons.analytics,
                      color: AppColors.successGreen,
                      summary: _buildHosSummary(context, todayStats, weekStats),
                      isEld: false,
                      ref: ref,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
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
                    m.message,
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
    required bool isEld,
    required WidgetRef ref,
    String? exportFormat,
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
                if (exportFormat != null)
                  _buildExportButton(context, 'Excel', () => _exportReport(context, ref, isEld, 'excel', standardType: exportFormat))
                else ...[
                  _buildExportButton(context, 'CSV', () => _exportReport(context, ref, isEld, 'csv')),
                  const SizedBox(width: AppSpacing.sm),
                  _buildExportButton(context, 'PDF', () => _exportReport(context, ref, isEld, 'pdf'), isIcon: false, color: AppColors.dangerRed),
                ],
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

  /// ملخص التقارير القياسية
  Widget _buildStandardSummary(BuildContext context, List<dynamic>? reportData) {
    return Column(
      children: [
        _summaryRow(context, 'Records', reportData != null ? reportData.length.toString() : '0'),
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

  Future<void> _exportReport(BuildContext context, WidgetRef ref, bool isEld, String format, {String? standardType}) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Requesting export...'), duration: Duration(seconds: 1)),
    );

    final downloadUrl = await ref.read(reportsProvider.notifier).exportReport(isEld, format, standardReportType: standardType);
    
    if (downloadUrl != null && context.mounted) {
      if (downloadUrl.startsWith('http://') || downloadUrl.startsWith('https://')) {
        final uri = Uri.parse(downloadUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error launching report URL.'), backgroundColor: AppColors.dangerRed),
            );
          }
        }
      } else {
        // It is a local file path downloaded by the repository
        try {
          await Share.shareXFiles([XFile(downloadUrl)], text: 'Exported Report');
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Error sharing local report file.'), backgroundColor: AppColors.dangerRed),
            );
          }
        }
      }
    } else {
      if (context.mounted) {
        if (standardType != null) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to download standard report.'), backgroundColor: AppColors.dangerRed),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error exporting report.'), backgroundColor: AppColors.dangerRed),
          );
        }
      }
    }
  }
}
