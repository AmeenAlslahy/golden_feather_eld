import 'dart:convert';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/eld_info_row.dart';
import '../../../../core/widgets/eld_card.dart';
import '../../../../core/widgets/golden_app_bar.dart';
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
      appBar: GoldenAppBar(
        titleText: context.loc.dvirTitle,
        variant: GoldenAppBarVariant.standard,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : report == null
          ? Center(
              child: Text(
                state.error == null
                    ? context.loc.dvirListNoRecords
                    : anyErrorUserMessage(state.error!, loc: context.loc),
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
    final statusColor = report.vehicleOperationalStatus.color(context);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        _Section(
          title: loc.dvirTitle,
          icon: Icons.description_outlined,
          children: [
            EldInfoRow(label: loc.dvirReportId, value: report.id),
            EldInfoRow(
              label: loc.inspectionType,
              value: context.translateInspectionType(report.type.name),
            ),
            EldInfoRow(
              label: loc.status,
              value: statusLabel,
              valueColor: statusColor,
            ),
            EldInfoRow(
              label: loc.vehicleCondition,
              value: report.conditionStatus.label(loc),
              valueColor: report.conditionStatus.color(context),
            ),
            EldInfoRow(label: loc.driverName, value: report.driverName),
            EldInfoRow(
              label: loc.dvirTimeET,
              value: report.date != null
                  ? DateFormat(
                      'd MMM yy, hh:mm a',
                      loc.localeName,
                    ).format(report.date!.toLocal())
                  : '—',
            ),
            EldInfoRow(
              label: loc.location,
              value: (report.location ?? '').isEmpty
                  ? loc.dvirLocationUnavailable
                  : report.location!,
            ),
            EldInfoRow(
              label: loc.dvirOdometerMi,
              value: '${report.odometer?.toStringAsFixed(0) ?? "-"} mi',
            ),
            EldInfoRow(label: loc.vehicle, value: report.vehicleId),
            if ((report.trailerId ?? '').isNotEmpty)
              EldInfoRow(label: loc.trailer, value: report.trailerId!),
            EldInfoRow(
              label: loc.companyName,
              value: (report.companyName ?? '').isEmpty
                  ? loc.dvirCompanyUnavailable
                  : report.companyName!,
            ),
            EldInfoRow(
              label: loc.remarks,
              value: (report.notes ?? '').isEmpty ? '—' : report.notes!,
            ),
            EldInfoRow(
              label: loc.dvirRetentionUntil,
              value: retention != null
                  ? '${retention.year}-${retention.month.toString().padLeft(2, '0')}-${retention.day.toString().padLeft(2, '0')}'
                  : '—',
            ),
          ],
        ),

        // --- Trailers Section ---
        if (report.trailers.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: loc.trailers,
            icon: Icons.rv_hookup_outlined,
            children: report.trailers
                .map((t) => _TrailerCard(trailer: t))
                .toList(),
          ),
        ],

        // --- Photos Section ---
        if (report.photos.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: loc.dvirPhotosAttached,
            icon: Icons.photo_camera_back_outlined,
            children: [
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: report.photos
                    .where((p) => p.isNotEmpty)
                    .map((p) => _PhotoThumbnail(dataUrl: p))
                    .toList(),
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        if (report.hasDefects) ...[
          _Section(
            title: loc.defectsFound,
            icon: Icons.warning_amber_rounded,
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
          icon: Icons.draw_outlined,
          children: [
            if ((report.signature ?? '').isNotEmpty)
              _SignatureImage(dataUrl: report.signature!)
            else
              Text(loc.dvirSign, style: context.styles.muted),
          ],
        ),

        // --- Mechanic Certification Section ---
        if (report.certified ||
            (report.mechanicName != null &&
                report.mechanicName!.isNotEmpty)) ...[
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: loc.mechanicCertification,
            icon: Icons.verified_outlined,
            children: [
              EldInfoRow(
                label: loc.mechanicLabel,
                value: report.mechanicName ?? '—',
              ),
              EldInfoRow(
                label: loc.statusTitle,
                value: report.repairStatus ?? '—',
                valueColor: report.repairStatus == 'REPAIRED'
                    ? context.success
                    : context.warning,
              ),
              if (report.repairNotes != null && report.repairNotes!.isNotEmpty)
                EldInfoRow(
                  label: loc.repairNotesLabel,
                  value: report.repairNotes!,
                ),
            ],
          ),
        ],

        if (report.nextDriverReviewed) ...[
          const SizedBox(height: AppSpacing.md),
          _Section(
            title: loc.dvirPrevReviewSection,
            icon: Icons.verified_user_outlined,
            children: [
              EldInfoRow(
                label: loc.reviewedBy,
                value: report.reviewingDriverName ?? '—',
              ),
            ],
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        if (!report.isSubmitted) AppDetailEditButton(report: report),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: AppButton(
        label: context.loc.edit,
        type: EldButtonType.primary,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DvirFormPage(existingReport: report),
            ),
          );
        },
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final IconData? icon;
  final List<Widget> children;

  const _Section({
    required this.title,
    this.icon,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.cardGap),
      child: EldCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: AppSpacing.iconMedium, color: context.gold),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Expanded(
                  child: Text(title, style: context.styles.sectionTitle),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _SignatureImage extends StatefulWidget {
  final String dataUrl;

  const _SignatureImage({required this.dataUrl});

  @override
  State<_SignatureImage> createState() => _SignatureImageState();
}

class _SignatureImageState extends State<_SignatureImage> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _decode(widget.dataUrl);
  }

  @override
  void didUpdateWidget(covariant _SignatureImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataUrl != widget.dataUrl) {
      _bytes = _decode(widget.dataUrl);
    }
  }

  static Uint8List? _decode(String dataUrl) {
    try {
      final base64Part = dataUrl.contains(',')
          ? dataUrl.split(',')[1]
          : dataUrl;
      return base64Decode(base64Part);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) {
      return Text(
        context.loc.dvirImageNotAvailable,
        style: context.styles.muted,
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: context.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: Image.memory(bytes, height: 140, fit: BoxFit.contain),
        ),
      ),
    );
  }
}

/// SRS 7.6 — بطاقة عيب: اسم + Stepper دورة الحياة + تلوين حسب الشدة.
class _DefectCard extends StatelessWidget {
  final DvirDefectSelection defect;

  const _DefectCard({required this.defect});

  Color _severityColor(BuildContext context) {
    final severity = defect.severity;
    if (severity == DefectSeverity.high) return context.danger;
    if (severity == DefectSeverity.medium) return context.warning;
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
        border: BorderDirectional(start: BorderSide(color: sevColor, width: 3.5)),
        borderRadius: BorderRadius.circular(AppRadius.input),
        color: context.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  defect.item.label(context.loc),
                  style: context.styles.body.copyWith(
                    fontWeight: AppTypography.semiBold,
                  ),
                ),
              ),
              if (defect.severity != null)
                Text(
                  defect.severity!.wire,
                  style: context.styles.caption.copyWith(
                    color: sevColor,
                    fontWeight: AppTypography.bold,
                  ),
                ),
            ],
          ),
          if (defect.description != null && defect.description!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(defect.description!, style: context.styles.subtitle),
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
                      color: i <= currentIdx ? context.gold : context.divider,
                    ),
                  ),
                Icon(
                  i < currentIdx
                      ? Icons.check_circle
                      : i == currentIdx
                          ? Icons.radio_button_checked
                          : Icons.radio_button_off,
                  size: AppSpacing.iconSmall,
                  color: i <= currentIdx ? context.gold : context.divider,
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            defect.stage.wire,
            style: context.styles.caption.copyWith(
              fontWeight: AppTypography.semiBold,
            ),
          ),
        ],
      ),
    );
  }
}

class _TrailerCard extends StatelessWidget {
  final DvirTrailer trailer;

  const _TrailerCard({required this.trailer});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadius.input),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.directions_car_filled_outlined,
                size: AppSpacing.iconMedium,
                color: context.gold,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                trailer.trailerNumber,
                style: context.styles.body.copyWith(
                  fontWeight: AppTypography.bold,
                ),
              ),
            ],
          ),
          if (trailer.defects.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            for (final defect in trailer.defects)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• ', style: context.styles.error),
                    Expanded(
                      child: Text(defect, style: context.styles.subtitle),
                    ),
                  ],
                ),
              ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Text(context.loc.noDefectsReported, style: context.styles.subtitle),
          ],
        ],
      ),
    );
  }
}

class _PhotoThumbnail extends StatefulWidget {
  final String dataUrl;

  const _PhotoThumbnail({required this.dataUrl});

  @override
  State<_PhotoThumbnail> createState() => _PhotoThumbnailState();
}

class _PhotoThumbnailState extends State<_PhotoThumbnail> {
  /// P2 — فكّ مرة واحدة عند التغيير فقط (كما في `_SignatureImage`).
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _bytes = _decode(widget.dataUrl);
  }

  @override
  void didUpdateWidget(covariant _PhotoThumbnail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dataUrl != widget.dataUrl) {
      _bytes = _decode(widget.dataUrl);
    }
  }

  static Uint8List? _decode(String dataUrl) {
    try {
      final base64Part = dataUrl.contains(',')
          ? dataUrl.split(',')[1]
          : dataUrl;
      return base64Decode(base64Part);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return _errorPlaceholder(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.input),
      child: Image.memory(
        bytes,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _errorPlaceholder(context),
      ),
    );
  }

  Widget _errorPlaceholder(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: context.colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadius.input),
      ),
      child: Icon(Icons.broken_image, color: context.styles.subtitle.color),
    );
  }
}
