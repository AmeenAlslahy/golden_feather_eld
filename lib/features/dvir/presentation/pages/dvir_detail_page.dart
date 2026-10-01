import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../extensions/dvir_catalog_extensions.dart';
import '../../domain/entities/dvir_report.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dvirProvider.notifier).loadDvirDetails(widget.dvirId);
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
      body: state.isLoading && report == null
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
    final retention = _retentionUntil(report.date);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _Section(
          title: loc.dvirTitle,
          children: [
            EldInfoRow(label: 'Report ID', value: report.id),
            EldInfoRow(
              label: loc.status,
              value: _statusWire(report),
              valueColor: _statusColor(context, report),
            ),
            EldInfoRow(label: loc.driverName, value: report.driverName),
            EldInfoRow(
                label: loc.dvirTimeUnavailableShort.isEmpty
                    ? 'Time (ET)'
                    : loc.dvirTimeUnavailableShort,
                value: _formatTime(report.date)),
            EldInfoRow(
                label: loc.location, value: report.location ?? loc.dvirLocationUnavailable),
            EldInfoRow(
              label: loc.dvirOdometerMi,
              value:
                  '${report.odometer?.toStringAsFixed(0) ?? "-"} mi',
            ),
            EldInfoRow(label: loc.vehicle, value: report.vehicleId),
            if ((report.trailerId ?? '').isNotEmpty)
              EldInfoRow(label: loc.trailer, value: report.trailerId!),
            EldInfoRow(
                label: loc.dvirCompanyUnavailable.isEmpty ? 'Company' : loc.companyName,
                value: report.companyName ?? loc.dvirCompanyUnavailable),
            EldInfoRow(
                label: loc.remarks,
                value: (report.notes ?? '').isEmpty ? '—' : report.notes!),
            EldInfoRow(
              label: 'Retention Until (§396.11)',
              value:
                  '${retention.year}-${retention.month.toString().padLeft(2, '0')}-${retention.day.toString().padLeft(2, '0')}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (report.hasDefects) ...[
          _Section(
            title: loc.defectsFound,
            children: [
              for (final defect in report.selectedDefects)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber,
                          size: 16,
                          color: report.outOfService
                              ? AppColors.dangerText
                              : AppColors.warningText),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          defect.item.label(loc),
                          style: context.styles.body,
                        ),
                      ),
                    ],
                  ),
                ),
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
            title: 'Previous DVIR Review (§396.13)',
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

  String _statusWire(DvirReport report) {
    switch (report.vehicleOperationalStatus) {
      case VehicleOperationalStatus.outOfService:
        return 'OUT_OF_SERVICE';
      case VehicleOperationalStatus.restricted:
        return 'RESTRICTED';
      case VehicleOperationalStatus.available:
        return 'AVAILABLE';
    }
  }

  Color? _statusColor(BuildContext context, DvirReport report) {
    switch (report.vehicleOperationalStatus) {
      case VehicleOperationalStatus.outOfService:
        return AppColors.dangerText;
      case VehicleOperationalStatus.restricted:
        return AppColors.warningText;
      case VehicleOperationalStatus.available:
        return AppColors.successText;
    }
  }

  String _formatTime(DateTime dt) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }
}

DateTime _retentionUntil(DateTime inspectedAt) {
  final y = inspectedAt.year;
  final m = inspectedAt.month;
  return DateTime(y, m + 3, inspectedAt.day, inspectedAt.hour,
      inspectedAt.minute);
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
      return Text('Image not available', style: context.styles.muted);
    }
  }
}
