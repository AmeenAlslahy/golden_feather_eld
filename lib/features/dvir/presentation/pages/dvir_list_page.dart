import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_status_pill.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../domain/dvir_list_summary.dart';
import '../../domain/entities/dvir_report.dart';
import '../providers/dvir_provider.dart';
import '../widgets/active_defects_section.dart';
import '../extensions/dvir_status_extensions.dart';
import 'dvir_detail_page.dart';
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
            icon: const Icon(Icons.refresh),
            color: AppColors.surface,
            onPressed: () {
              ref.invalidate(dvirCatalogProvider);
              ref.read(dvirProvider.notifier).refresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
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
              onRefresh: () async {
                ref.invalidate(dvirCatalogProvider);
                await ref.read(dvirProvider.notifier).refresh();
              },
                  child: dvirState.reports.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          children: [
                            const ActiveDefectsSection(),
                            if (dvirState.error != null)
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: EldRetryView(
                              message: anyErrorUserMessage(
                                dvirState.error!,
                                loc: AppLocalizations.of(context)!,
                              ),
                              onRetry: () {
                                ref.invalidate(dvirCatalogProvider);
                                ref.read(dvirProvider.notifier).refresh();
                              },
                            ),
                          )
                        else
                          // Reference layout (screenshot 21): plain grey
                          // "No Records" near the top of an empty list.
                          Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text(
                              context.loc.dvirListNoRecords,
                              textAlign: TextAlign.center,
                              style: context.styles.subtitle.copyWith(fontSize: 18),
                            ),
                          ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.md),
                      itemCount: dvirState.reports.length + 2,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _DvirSummaryRow(
                            summary: summarizeDvirReports(dvirState.reports),
                          );
                        }
                        if (index == 1) {
                          // العيوب النشطة لمركبة السائق — قسم قراءة فقط.
                          return const ActiveDefectsSection();
                        }
                        final report = dvirState.reports[index - 2];
                        return _DvirCard(
                          report: report,
                          // SRS 7.12: النقر على أي تقرير في القائمة يفتح
                          // شاشة التفاصيل (قراءة فقط)؛ التحرير من داخلها
                          // للتقرير غير المُرسل.
                          onOpen: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    DvirDetailPage(dvirId: report.id),
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
    final loc = context.loc;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          _cell(context, loc.dvirListTotal, summary.total),
          _cell(context, loc.dvirListOpen, summary.openDefects),
          _cell(context, loc.dvirListSigned, summary.signed),
          _cell(context, loc.dvirListOos, summary.outOfService),
        ],
      ),
    );
  }

  Widget _cell(BuildContext context, String label, int value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: context.styles.bodyBold,
          ),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, style: context.styles.caption.copyWith(fontSize: 11)),
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
                    context.translateInspectionType(report.type.name),
                    style: context.styles.bodyBold,
                  ),
                ),
                // حالة التقرير
                AppStatusPill(
                  label: report.isSubmitted
                      ? context.loc.submitted
                      : context.loc.draft,
                  color: (report.isSubmitted
                          ? context.styles.success
                          : context.styles.warning)
                      .color!,
                ),
              ],
            ),
            const Divider(height: 24),
            // معلومات التقرير
            _infoRow(
                context,
                context.loc.dateLabel,
                report.date != null
                    ? DateFormat('yyyy-MM-dd').format(report.date!.toLocal())
                    : '—'),
            _infoRow(context, context.loc.vehicle, report.vehicleId),
            if (report.trailerId != null)
              _infoRow(context, context.loc.trailer, report.trailerId!),
            _infoRow(context, context.loc.odometerReading,
                '${report.odometer?.toStringAsFixed(0) ?? "-"} mi'),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppStatusPill(
                  icon: Icons.circle,
                  iconSize: 8,
                  label: report.vehicleOperationalStatus.label(context.loc),
                  color: report.vehicleOperationalStatus.color(context.styles),
                ),
              ),
            ),
            // عدد الأعطال وحالة الإصلاح
            if (report.hasDefects)
              Container(
                margin: const EdgeInsets.only(top: AppSpacing.sm),
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: AppDecorations.tinted(
                  context.styles.error.color!,
                  alpha: 0.1,
                  radius: AppRadius.input,
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
                           Icon(Icons.build, color: context.styles.subtitle.color, size: 14),
                          const SizedBox(width: 8),
                          Text(
                            '${context.loc.dvirRepairCert} · ${report.repairStatus}',
                            style: context.styles.caption,
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
                decoration: AppDecorations.tinted(
                  context.styles.success.color!,
                  alpha: 0.1,
                  radius: AppRadius.input,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        color: AppColors.successGreen, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      context.loc.dvirReviewed39613,
                      style: context.styles.success.copyWith(fontSize: 13),
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
