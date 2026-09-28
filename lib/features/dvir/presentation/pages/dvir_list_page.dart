import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
// import '../../../../l10n/app_localizations.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../domain/dvir_list_summary.dart';
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
        title: Text(
          context.loc.dvirTitle,
          style: context.styles.appBarTitle,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.surface),
            onPressed: () => ref.read(dvirProvider.notifier).refresh(),
          ),
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
          : RefreshIndicator(
              onRefresh: () => ref.read(dvirProvider.notifier).refresh(),
              child: dvirState.reports.isEmpty
                  ? ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [
                        if (dvirState.error != null)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: EldRetryView(
                              message: anyErrorUserMessage(
                                dvirState.error!,
                                isArabic:
                                    Localizations.localeOf(context).languageCode ==
                                        'ar',
                              ),
                              onRetry: () =>
                                  ref.read(dvirProvider.notifier).refresh(),
                            ),
                          )
                        else
                          // Reference layout (screenshot 21): plain grey
                          // "No Records" near the top of an empty list.
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(
                              Localizations.localeOf(context).languageCode ==
                                      'ar'
                                  ? 'لا توجد سجلات'
                                  : 'No Records',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: dvirState.reports.length + 1,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _DvirSummaryRow(
                            summary: summarizeDvirReports(dvirState.reports),
                          );
                        }
                        final report = dvirState.reports[index - 1];
                        return _DvirCard(
                          report: report,
                          onOpen: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DvirFormPage(existingReport: report),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}

class _DvirSummaryRow extends StatelessWidget {
  const _DvirSummaryRow({required this.summary});

  final DvirListSummary summary;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          _cell(isArabic ? 'إجمالي' : 'Total', summary.total),
          _cell(isArabic ? 'عيوب مفتوحة' : 'Open', summary.openDefects),
          _cell(isArabic ? 'موقّعة' : 'Signed', summary.signed),
          _cell(isArabic ? 'خارج الخدمة' : 'OOS', summary.outOfService),
        ],
      ),
    );
  }

  Widget _cell(String label, int value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}

/// بطاقة تقرير DVIR
class _DvirCard extends StatelessWidget {
  final DvirReport report;
  final VoidCallback onOpen;

  const _DvirCard({required this.report, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        onTap: onOpen,
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
                      : AppColors.primaryGold,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    isArabic ? report.type.arabicName : report.type.englishName,
                    style: context.styles.bodyBold,
                  ),
                ),
                // حالة التقرير
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: report.isSubmitted
                        ? AppColors.successGreen.withValues(alpha: 0.1)
                        : AppColors.warningYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
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
            // SRS 7.1: حالة تشغيل المركبة المحسوبة من العيوب غير المُعالجة.
            Builder(
              builder: (context) {
                final status = report.vehicleOperationalStatus;
                final (label, color) = switch (status) {
                  VehicleOperationalStatus.outOfService => (
                      context.loc.vehicleStatusOutOfService,
                      AppColors.dangerRed,
                    ),
                  VehicleOperationalStatus.restricted => (
                      context.loc.vehicleStatusRestricted,
                      AppColors.warningYellow,
                    ),
                  VehicleOperationalStatus.available => (
                      context.loc.vehicleStatusAvailable,
                      AppColors.successGreen,
                    ),
                };
                return Container(
                  margin: const EdgeInsets.only(top: AppSpacing.sm),
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 8, color: color),
                      const SizedBox(width: 6),
                      Text(
                        label,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            // عدد الأعطال وحالة الإصلاح
            if (report.hasDefects)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: AppColors.dangerRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning,
                            color: AppColors.dangerRed, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          '${report.defectsCount} ${context.loc.defectsFound}',
                          style: context.styles.error,
                        ),
                      ],
                    ),
                    if (report.repairStatus != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.build, color: AppColors.textSecondary, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            'Repair Cert · ${report.repairStatus}',
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
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle,
                        color: AppColors.successGreen, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Reviewed §396.13',
                      style: TextStyle(
                          color: AppColors.successGreen, fontSize: 13),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: context.styles.muted),
          const SizedBox(width: 8),
          // Long values (defect summaries, locations) wrap instead of overflowing.
          Expanded(
            child: Text(
              value,
              style: context.styles.body,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}
