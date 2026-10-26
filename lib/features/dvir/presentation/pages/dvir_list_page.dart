import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_status_pill.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/eld_retry_view.dart';
import '../../../home/presentation/widgets/eld_drawer.dart';
import '../../domain/defect_enums.dart';
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
      drawer: const EldDrawer(),
      appBar: AppBar(
        title: Text(context.loc.dvirTitle, style: context.styles.appBarTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
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
                MaterialPageRoute(builder: (_) => const DvirFormPage()),
              );
            },
          ),
        ],
      ),
      body: dvirState.isLoading && dvirState.reports.isEmpty
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
                            padding: const EdgeInsets.only(top: AppSpacing.xxl),
                            child: Text(
                              context.loc.dvirListNoRecords,
                              textAlign: TextAlign.center,
                              style: context.styles.sectionTitle,
                            ),
                          ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
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

class _DvirSummaryRow extends ConsumerWidget {
  const _DvirSummaryRow({required this.summary});

  final DvirListSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = context.loc;
    final activeDefects = ref.watch(activeVehicleDefectsProvider).valueOrNull;
    final openCount = activeDefects != null
        ? activeDefects
              .where((d) => d.stage == DefectLifecycleStage.open)
              .length
        : summary.openDefects;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          _cell(context, loc.dvirListTotal, summary.total),
          _cell(context, loc.dvirListOpen, openCount),
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
          Text('$value', style: context.styles.bodyBold),
          const SizedBox(height: AppSpacing.xs),
          Text(
            label,
            textAlign: TextAlign.center,
            style: context.styles.caption,
          ),
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
    // البطاقة القياسية (EldCard) — نفس زاوية/ارتفاع هوية التطبيق، بلا
    // margin افتراضي؛ فراغ القائمة عبر cardGap أسفلها كإعدادات النظام.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      child: EldCard(
        onTap: onOpen,
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
                      ? context.success
                      : context.gold,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.translateInspectionType(report.type.name),
                    // ترويسة قسم بالوزن الموحد (كان bodyBold الأثقل وزنًا).
                    style: context.styles.sectionTitle,
                  ),
                ),
                // حالة التقرير
                AppStatusPill(
                  label: report.isSubmitted
                      ? context.loc.submitted
                      : context.loc.draft,
                  color:
                      (report.isSubmitted
                              ? context.styles.success
                              : context.styles.warning)
                          .color!,
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),
            // معلومات التقرير
            // صف المعلومات القانوني (dense داخل البطاقة) — نفس مكوّن
            // الحساب/القواعد؛ كانت هنا نسخة محلية بمحاذاة قيمة معاكسة.
            EldInfoRow(
              dense: true,
              label: context.loc.dateLabel,
              value: report.date != null
                  ? DateFormat('yyyy-MM-dd').format(report.date!.toLocal())
                  : '—',
            ),
            EldInfoRow(
              dense: true,
              label: context.loc.vehicle,
              value: report.vehicleId,
            ),
            if (report.trailerId != null)
              EldInfoRow(
                dense: true,
                label: context.loc.trailer,
                value: report.trailerId!,
              ),
            EldInfoRow(
              dense: true,
              label: context.loc.odometerReading,
              value: '${report.odometer?.toStringAsFixed(0) ?? "-"} mi',
            ),
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: AppStatusPill(
                  icon: Icons.circle,
                  iconSize: 8,
                  label: report.vehicleOperationalStatus.label(context.loc),
                  color: report.vehicleOperationalStatus.color(context),
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
                        Icon(
                          Icons.warning,
                          color: context.danger,
                          size: AppSpacing.iconSmall,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          '${report.defectsCount} ${context.loc.defectsFound}',
                          style: context.styles.error,
                        ),
                      ],
                    ),
                    if (report.repairStatus != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          Icon(
                            Icons.build,
                            color: context.styles.subtitle.color,
                            size: AppSpacing.iconSmall,
                          ),
                          const SizedBox(width: AppSpacing.sm),
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
                    Icon(
                      Icons.check_circle,
                      color: context.success,
                      size: AppSpacing.iconSmall,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      context.loc.dvirReviewed39613,
                      style: context.styles.success,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
