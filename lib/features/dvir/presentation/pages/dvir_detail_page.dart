import 'dart:convert';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../domain/defect_enums.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/entities/dvir_report.dart';
import '../extensions/dvir_catalog_extensions.dart';
import '../extensions/dvir_status_extensions.dart';
import '../pages/dvir_form_page.dart';
import '../providers/dvir_provider.dart';

/// SRS 7.12 — شاشة تفاصيل تقرير DVIR (قراءة فقط).
///
/// لا يحق للسائق تعديل تقرير مُعالج بعد حفظه؛ التقرير غير المُرسل
/// (مسودة) يبقى قابلاً للتحرير عبر نموذج الإدراج.
class DvirDetailPage extends ConsumerStatefulWidget {
  const DvirDetailPage({super.key, required this.dvirId});

  final String dvirId;

  @override
  ConsumerState<DvirDetailPage> createState() => _DvirDetailPageState();
}

class _DvirDetailPageState extends ConsumerState<DvirDetailPage> {
  // التحميل صامت في المزود (بلا مؤشر عام)، فتدير الشاشة مؤشرها المحلي —
  // وإلا ومض "لا سجلات" قبل وصول التفاصيل.
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(dvirProvider.notifier).loadDvirDetails(widget.dvirId);
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dvirProvider);
    final report = state.currentReport;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.dvirTitle, style: context.styles.appBarTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : report == null
              ? Center(
                  child: Text(
                    state.error ?? context.loc.dvirListNoRecords,
                    style: context.styles.error,
                    textAlign: TextAlign.center,
                  ),
                )
              : _DetailBody(report: report),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.report});

  final DvirReport report;

  @override
  Widget build(BuildContext context) {
    final loc = context.loc;
    final retention = report.retentionUntil;

    final statusLabel = report.vehicleOperationalStatus.label(loc);
    final statusColor = report.vehicleOperationalStatus.color(context.styles);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _Section(
          title: loc.dvirTitle,
          children: [
            EldInfoRow(label: loc.dvirReportId, value: report.id),
            EldInfoRow(
              label: loc.status,
              value: statusLabel,
              valueColor: statusColor,
            ),
            EldInfoRow(label: loc.driverName, value: report.driverName),
            EldInfoRow(
                label: loc.dvirTimeET,
                value: report.date != null
                    ? DateFormat('d MMM yy, hh:mm a', loc.localeName)
                        .format(report.date!.toLocal())
                    : '—'),
            EldInfoRow(
                label: loc.location,
                value: (report.location ?? '').isEmpty
                    ? loc.dvirLocationUnavailable
                    : report.location!),
            EldInfoRow(
              label: loc.dvirOdometerMi,
              value:
                  '${report.odometer?.toStringAsFixed(0) ?? "-"} mi',
            ),
            EldInfoRow(label: loc.vehicle, value: report.vehicleId),
            if ((report.trailerId ?? '').isNotEmpty)
              EldInfoRow(label: loc.trailer, value: report.trailerId!),
            EldInfoRow(
                label: loc.companyName,
                value: (report.companyName ?? '').isEmpty
                    ? loc.dvirCompanyUnavailable
                    : report.companyName!),
            EldInfoRow(
                label: loc.remarks,
                value: (report.notes ?? '').isEmpty ? '—' : report.notes!),
            EldInfoRow(
              label: loc.dvirRetentionUntil,
              value: retention != null
                  ? '${retention.year}-${retention.month.toString().padLeft(2, '0')}-${retention.day.toString().padLeft(2, '0')}'
                  : '—',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (report.hasDefects) ...[
          _Section(
            title: loc.defectsFound,
            children: [
              for (final defect in report.selectedDefects)
                _DefectCard(defect: defect),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Text(
              loc.dvirSatisfactory,
              textAlign: TextAlign.center,
              style: context.styles.success,
            ),
          ),
        _Section(
          title: loc.dvirSign,
          children: [
            if ((report.signature ?? '').isNotEmpty)
              _SignatureImage(dataUrl: report.signature!)
            else
              Text(loc.dvirSign, style: context.styles.muted),
          ],
        ),
        if (report.nextDriverReviewed) ...[
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: loc.dvirPrevReviewSection,
            children: [
              EldInfoRow(
                  label: loc.reviewedBy,
                  value: report.reviewingDriverName ?? '—'),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (!report.isSubmitted)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: AppDetailEditButton(report: report),
          ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}

/// التقرير غير المُرسل (مسودة) يبقى قابلاً للتحرير من نموذج الإدراج.
class AppDetailEditButton extends StatelessWidget {
  final DvirReport report;

  const AppDetailEditButton({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      icon: const Icon(Icons.edit),
      label: Text(context.loc.edit),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DvirFormPage(existingReport: report),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.largeCard),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.styles.sectionTitle),
          const SizedBox(height: AppSpacing.sm),
          ...children,
        ],
      ),
    );
  }
}

class _SignatureImage extends StatelessWidget {
  final String dataUrl;

  const _SignatureImage({required this.dataUrl});

  @override
  Widget build(BuildContext context) {
    try {
      final base64Part =
          dataUrl.contains(',') ? dataUrl.split(',')[1] : dataUrl;
      final bytes = base64Decode(base64Part);
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.input),
        child: Image.memory(bytes, height: 140, fit: BoxFit.contain),
      );
    } catch (_) {
      return Text(context.loc.dvirImageNotAvailable,
          style: context.styles.muted);
    }
  }
}

/// SRS 7.6 — بطاقة عيب: اسم + Stepper دورة الحياة + تلوين حسب الشدة.
class _DefectCard extends StatelessWidget {
  final DvirDefectSelection defect;

  const _DefectCard({required this.defect});

  Color _severityColor(BuildContext context) {
    final severity = defect.severity;
    if (severity == DefectSeverity.high) return AppColors.dangerText;
    if (severity == DefectSeverity.medium) return AppColors.warningText;
    return context.styles.subtitle.color!;
  }

  @override
  Widget build(BuildContext context) {
    final sevColor = _severityColor(context);
    const stages = DefectLifecycleStage.values;
    final currentIdx = stages.indexOf(defect.stage);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: sevColor, width: 3),
        ),
        borderRadius: BorderRadius.circular(AppRadius.input),
        color: Theme.of(context).colorScheme.surfaceContainerHighest
            .withValues(alpha: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(defect.item.label(context.loc),
                    style: context.styles.body.copyWith(
                      fontWeight: FontWeight.w600,
                    )),
              ),
              if (defect.severity != null)
                Text(defect.severity!.wire,
                    style: context.styles.caption
                        .copyWith(color: sevColor, fontWeight: FontWeight.w700)),
            ],
          ),
          if (defect.description != null && defect.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(defect.description!,
                  style: context.styles.subtitle),
            ),
          const SizedBox(height: AppSpacing.sm),
          // SRS 7.6 Stepper: OPEN → UNDER_REPAIR → REPAIRED → CERTIFIED → CLOSED
          Row(
            children: [
              for (var i = 0; i < stages.length; i++) ...[
                if (i > 0)
                  Expanded(
                    child: Container(
                      height: 2,
                      color: i <= currentIdx
                          ? AppColors.primaryGold
                          : Theme.of(context).dividerColor,
                    ),
                  ),
                Icon(
                  i < currentIdx
                      ? Icons.check_circle
                      : i == currentIdx
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                  size: 14,
                  color: i <= currentIdx
                      ? AppColors.primaryGold
                      : Theme.of(context).dividerColor,
                ),
              ],
            ],
          ),
          const SizedBox(height: 4),
          Text(defect.stage.wire,
              style: context.styles.caption
                  .copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
