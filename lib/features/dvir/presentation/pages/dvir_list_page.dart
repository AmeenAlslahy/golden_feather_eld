import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_status_pill.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/golden_app_bar.dart';
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
      appBar: GoldenAppBar(
        titleText: context.loc.dvirTitle,
        variant: GoldenAppBarVariant.brand,
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
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      children: [
                        _buildCreateButton(context),
                        const ActiveDefectsSection(),
                        if (dvirState.error != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            child: EldCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.cloud_off_rounded,
                                    color: context.colorScheme.error,
                                    size: 40,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Text(
                                    context.loc.dvirTitle,
                                    style: context.styles.bodyBold,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    anyErrorUserMessage(
                                      dvirState.error!,
                                      loc: AppLocalizations.of(context)!,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: context.styles.caption.copyWith(
                                      color:
                                          context.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  AppButton(
                                    label: context.loc.retryAction,
                                    type: EldButtonType.secondary,
                                    isCompact: true,
                                    isFullWidth: false,
                                    icon: Icons.refresh,
                                    onPressed: () {
                                      ref.invalidate(dvirCatalogProvider);
                                      ref.read(dvirProvider.notifier).refresh();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.xl),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.assignment_turned_in_outlined,
                                  size: 48,
                                  color: context.colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.4),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  context.loc.dvirListNoRecords,
                                  textAlign: TextAlign.center,
                                  style: context.styles.sectionTitle.copyWith(
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSpacing.screenPadding),
                      itemCount: dvirState.reports.length + 3,
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return _DvirSummaryRow(
                            summary: summarizeDvirReports(dvirState.reports),
                          );
                        }
                        if (index == 1) {
                          return _buildCreateButton(context);
                        }
                        if (index == 2) {
                          return const ActiveDefectsSection();
                        }
                        final report = dvirState.reports[index - 3];
                        return _DvirCard(
                          report: report,
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

  Widget _buildCreateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppButton(
        label: context.loc.createNewReport,
        icon: Icons.post_add,
        type: EldButtonType.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DvirFormPage()),
          );
        },
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
      child: EldCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: _cell(
                    context,
                    label: loc.dvirListTotal,
                    value: summary.total,
                    color: context.gold,
                    icon: Icons.assignment_outlined,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _cell(
                    context,
                    label: loc.dvirListSigned,
                    value: summary.signed,
                    color: context.success,
                    icon: Icons.check_circle_outline,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _cell(
                    context,
                    label: loc.dvirListOpen,
                    value: openCount,
                    color: context.warning,
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _cell(
                    context,
                    label: loc.dvirListOos,
                    value: summary.outOfService,
                    color: context.danger,
                    icon: Icons.do_not_disturb_on_outlined,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _cell(
    BuildContext context, {
    required String label,
    required int value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '$value',
                  style: context.styles.cardTitle.copyWith(
                    fontWeight: FontWeight.bold,
                    color: value > 0 ? color : context.colorScheme.onSurface,
                  ),
                ),
                Text(
                  label,
                  style: context.styles.caption.copyWith(
                    color: context.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
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
                  size: AppSpacing.iconMedium,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    context.translateInspectionType(report.type.name),
                    style: context.styles.sectionTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Divider(
                height: 1,
                thickness: 1,
                color: context.colorScheme.outlineVariant.withValues(alpha: 0.3),
              ),
            ),
            // معلومات التقرير
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
            if (report.trailerId != null && report.trailerId!.isNotEmpty)
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
              padding: const EdgeInsets.only(top: AppSpacing.xs),
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
                decoration: BoxDecoration(
                  color: context.danger.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: context.danger.withValues(alpha: 0.3)),
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
                        Expanded(
                          child: Text(
                            '${report.defectsCount} ${context.loc.defectsFound}',
                            style: context.styles.error.copyWith(fontWeight: FontWeight.w600),
                          ),
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
                          Expanded(
                            child: Text(
                              '${context.loc.dvirRepairCert} · ${report.repairStatus}',
                              style: context.styles.caption,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                  color: context.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(AppRadius.input),
                  border: Border.all(color: context.success.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: context.success,
                      size: AppSpacing.iconSmall,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        context.loc.dvirReviewed39613,
                        style: context.styles.success.copyWith(fontWeight: FontWeight.w600),
                      ),
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
