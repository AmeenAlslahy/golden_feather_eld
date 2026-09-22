import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// import '../../../../l10n/app_localizations.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_gap.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../domain/entities/dvir_report.dart';
import '../providers/dvir_provider.dart';
import 'dvir_form_page.dart';

/// شاشة قائمة تقارير DVIR
class DvirListPage extends ConsumerWidget {
  const DvirListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dvirState = ref.watch(dvirProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      drawer: const EldDrawer(),
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        title: Text(
          context.loc.dvirTitle,
          style: const TextStyle(
            fontSize: AppTypography.bodySize,
            fontWeight: AppTypography.bold,
            color: AppColors.surface,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.surface),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DvirFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      body: dvirState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : dvirState.reports.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment,
                          size: 64,
                          color: Theme.of(context).colorScheme.outline),
                      AppGap.md,
                      Text(context.loc.noDvirReports),
                      AppGap.lg,
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DvirFormPage(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.add),
                        label: Text(context.loc.createNewReport),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: dvirState.reports.length,
                  itemBuilder: (context, index) {
                    final report = dvirState.reports[index];
                    return _DvirCard(report: report);
                  },
                ),
    );
  }
}

/// بطاقة تقرير DVIR
class _DvirCard extends StatelessWidget {
  final DvirReport report;

  const _DvirCard({required this.report});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // العنوان والنوع
            Row(
              children: [
                Icon(
                  report.type == InspectionType.preTrip
                      ? Icons.play_circle
                      : Icons.stop_circle,
                  color: report.type == InspectionType.preTrip
                      ? AppColors.successGreen
                      : AppColors.primaryBlue,
                ),
                AppGap.hSm,
                Expanded(
                  child: Text(
                    isArabic ? report.type.arabicName : report.type.englishName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: AppTypography.bodySize,
                    ),
                  ),
                ),
                // حالة التقرير
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: report.isSubmitted
                        ? AppColors.successGreen.withValues(alpha: 0.1)
                        : AppColors.warningYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(AppRadius.dialog),
                  ),
                  child: Text(
                    report.isSubmitted
                        ? context.loc.submitted
                        : context.loc.draft,
                    style: TextStyle(
                      fontSize: 12,
                      color: report.isSubmitted
                          ? AppColors.successGreen
                          : AppColors.warningYellow,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            // معلومات التقرير
            _infoRow(context, context.loc.dateLabel,
                report.date.toString().substring(0, 10)),
            _infoRow(context, context.loc.vehicle, report.vehicleId),
            if (report.trailerId != null)
              _infoRow(context, context.loc.trailer, report.trailerId!),
            _infoRow(context, context.loc.odometerReading,
                '${report.odometer?.toStringAsFixed(0) ?? "-"} mi'),
            // عدد الأعطال وحالة الإصلاح
            if (report.hasDefects)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning,
                            color: AppColors.dangerRed, size: 16),
                        AppGap.hSm,
                        Text(
                          '${report.defectsCount} ${context.loc.defectsFound}',
                          style: const TextStyle(
                              color: AppColors.dangerRed, fontSize: 13),
                        ),
                      ],
                    ),
                    if (report.repairStatus != null) ...[
                      AppGap.xs,
                      Row(
                        children: [
                          const Icon(Icons.build, color: AppColors.textSecondary, size: 14),
                          AppGap.hSm,
                          Text(
                            'Repair: ${report.repairStatus}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            // مراجعة السائق التالي
            if (report.nextDriverReviewed)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.successGreen, size: 16),
                    AppGap.hSm,
                    Text(
                      'Reviewed by next driver',
                      style: TextStyle(
                          color: AppColors.successGreen, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}