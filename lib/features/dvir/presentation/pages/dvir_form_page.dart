import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/dvir_submission.dart';
import '../../domain/entities/dvir_report.dart';


import '../widgets/signature_canvas.dart';

import '../widgets/status_modal.dart';

import '../widgets/defects_modal.dart';

import '../providers/dvir_provider.dart';
import '../../../../core/widgets/app_feedback.dart';

class DvirFormPage extends ConsumerStatefulWidget {
  final DvirReport? existingReport;

  const DvirFormPage({super.key, this.existingReport});

  @override
  ConsumerState<DvirFormPage> createState() => _DvirFormPageState();
}

class _DvirFormPageState extends ConsumerState<DvirFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers for the new flat layout
  late TextEditingController _locationController;
  late TextEditingController _odometerController;
  late TextEditingController _vehicleDefectsController;
  late TextEditingController _trailerDefectsController;
  late TextEditingController _companyController;
  late TextEditingController _remarksController;

  final SignatureController _signatureController = SignatureController(
    penStrokeWidth: 3,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  bool _isSubmitting = false;

  String _selectedStatus = 'Vehicle Condition Satisfactory';
  bool _signed = false;

  /// §396.11 items marked defective (from the live catalog).
  List<DvirDefectSelection> _selectedDefects = const [];

  bool get _hasAnyDefect =>
      _vehicleDefectsController.text.trim().isNotEmpty ||
      _trailerDefectsController.text.trim().isNotEmpty ||
      _selectedDefects.isNotEmpty;

  /// The report shown in read-only mode: the list summary first, then the
  /// full server detail once `loadDvirDetails` returns.
  DvirReport? _report;

  @override
  void initState() {
    super.initState();
    final r = widget.existingReport;
    _report = r;
    _locationController = TextEditingController(text: r?.location ?? '');
    _odometerController = TextEditingController(
      text: r?.odometer?.toString() ?? '',
    );
    _vehicleDefectsController = TextEditingController(
      text: r?.vehicleDefects ?? '',
    );
    _trailerDefectsController = TextEditingController(
      text: r?.trailerDefects ?? '',
    );
    _companyController = TextEditingController(text: r?.companyName ?? '');
    _remarksController = TextEditingController(text: r?.notes ?? '');
    if (r == null) {
      // New report: ask the server which previous DVIR (if any) this vehicle
      // still owes a §396.13 review for.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final vehicleId = ref.read(dashboardDataProvider).vehicleId;
        ref.read(dvirProvider.notifier).loadPreviousDvir(vehicleId);
      });
    }
    if (r != null) {
      _applyReport(r);
      // SRS 7.12: the list row is a summary. Read the full report
      // (`GET /eld/dvir/{id}`) through the existing notifier and refresh the
      // read-only view when it arrives; the summary stays if the read fails.
      final serverId = int.tryParse(r.id);
      if (serverId != null && serverId > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          ref.read(dvirProvider.notifier).loadDvirDetails(r.id);
        });
      }
    }
  }

  /// Fills the read-only view from a report (list summary or full detail).
  void _applyReport(DvirReport r) {
    _report = r;
    _locationController.text = r.location ?? _locationController.text;
    _odometerController.text =
        r.odometer?.toString() ?? _odometerController.text;
    _vehicleDefectsController.text =
        r.vehicleDefects ?? _vehicleDefectsController.text;
    _trailerDefectsController.text =
        r.trailerDefects ?? _trailerDefectsController.text;
    _companyController.text = r.companyName ?? _companyController.text;
    _remarksController.text = r.notes ?? _remarksController.text;
    _selectedStatus = r.condition == VehicleCondition.safe
        ? 'Vehicle Condition Satisfactory'
        : 'Has Defects';
    _signed = r.signature != null;
    if (r.selectedDefects.isNotEmpty || _selectedDefects.isEmpty) {
      _selectedDefects = r.selectedDefects;
    }
  }

  bool get _readOnly => widget.existingReport != null;
  bool get _isAr => Localizations.localeOf(context).languageCode == 'ar';

  String _statusLabel(String wire) {
    final loc = context.loc;
    switch (wire) {
      case 'Vehicle Condition Satisfactory':
        return loc.dvirSatisfactory;
      case 'Has Defects':
        return loc.dvirHasDefects;
      case 'Defects Corrected':
        return loc.dvirDefectsCorrected;
      case 'Defects Need Not Be Corrected':
        return loc.dvirDefectsNotCorrected;
      default:
        return wire;
    }
  }

  Future<void> _openDefectCatalog() async {
    if (_readOnly) return;
    final picked = await showDialog<List<DvirDefectSelection>>(
      context: context,
      builder: (_) =>
          DefectCatalogDialog(initial: _selectedDefects),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _selectedDefects = picked;
      if (picked.isNotEmpty) _selectedStatus = 'Has Defects';
    });
  }

  @override
  void dispose() {
    _locationController.dispose();
    _odometerController.dispose();
    _vehicleDefectsController.dispose();
    _trailerDefectsController.dispose();
    _companyController.dispose();
    _remarksController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _openStatusModal() async {
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => DvirStatusModal(
        hasDefect: _hasAnyDefect,
        selectedStatus: _selectedStatus,
      ),
    );
    if (selected == null || !mounted) return;
    setState(() => _selectedStatus = selected);
    // SRS 7.6: choosing Has Defects with nothing recorded opens the defects list.
    if (selected == 'Has Defects' && !_hasAnyDefect) {
      await _openDefectCatalog();
    }
  }

  String _automaticLocation() {
    final existing = _report?.location;
    final point = ref.read(trackingStateProvider).currentLocation;
    if (point != null) {
      return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    }
    if (existing != null && existing.isNotEmpty) return existing;
    return 'Location unavailable';
  }

  String _companyName() {
    final existing = _report?.companyName;
    if (existing != null && existing.isNotEmpty) return existing;
    return ref.read(accountProvider).accountData?.carrier ??
        'Company unavailable';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final time = ref.read(trustedTimeProvider).currentTime;
    if (time is! TrustedTimeAvailable) {
      AppFeedback.error(
        context,
        context.loc.dvirTimeUnavailable,
      );
      return;
    }

    final dashboard = ref.read(dashboardDataProvider);
    final previousToReview = ref
        .read(dvirProvider)
        .previousToReview(dashboard.vehicleId);

    if (widget.existingReport != null) {
      _snack(
        context.loc.dvirSavedCannotEdit,
      );
      return;
    }

    final signatureData = dvirSignatureData(
      await _signatureController.toPngBytes(),
    );
    if (!mounted) return;
    if (signatureData == null) {
      _snack(context.loc.dvirSignatureRequired);
      return;
    }
    final driverId = ref.read(currentDriverIdProvider);
    if (driverId == null || driverId <= 0) {
      _snack(
        context.loc.dvirDriverSessionMissing,
      );
      return;
    }
    if (dashboard.vehicleId.trim().isEmpty ||
        dashboard.vehicleId == 'No Vehicle') {
      _snack(
        context.loc.dvirVehicleIdMissing,
      );
      return;
    }

    if (previousToReview != null) {
      final latest = previousToReview;
      final previousId = int.tryParse(latest.id);
      if (previousId == null) {
        _snack(
          context.loc.dvirPrevNoServerId,
        );
        return;
      }
      final loc = context.loc;
      final previousDefects = <String>[
        for (final d in latest.selectedDefects)
          d.item.label(loc) +
              ((d.description?.trim().isNotEmpty ?? false)
                  ? ' — ${d.description!.trim()}'
                  : ''),
        if ((latest.vehicleDefects ?? '').trim().isNotEmpty)
          latest.vehicleDefects!.trim(),
        if ((latest.trailerDefects ?? '').trim().isNotEmpty)
          latest.trailerDefects!.trim(),
        if (latest.selectedDefects.isEmpty &&
            (latest.vehicleDefects ?? '').trim().isEmpty &&
            (latest.trailerDefects ?? '').trim().isEmpty &&
            (latest.defectsSummary ?? '').trim().isNotEmpty)
          latest.defectsSummary!.trim(),
      ];
      final reviewed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(context.loc.dvirPreviousInspection),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.loc.dvirReviewBeforeDriving,
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('yyyy-MM-dd HH:mm').format(latest.date.toLocal())} — '
                  '${context.translateVehicleCondition(latest.condition.name)}',
                ),
                const SizedBox(height: 8),
                Text(
                  context.loc.dvirRecordedDefects,
                  style: context.styles.bodyBold,
                ),
                if (previousDefects.isEmpty)
                  Text(context.loc.dvirNone)
                else
                  for (final line in previousDefects) Text('• $line'),
                if ((latest.repairStatus ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    context.loc.dvirRepairStatus +
                        latest.repairStatus!.trim() +
                        ((latest.mechanicName ?? '').trim().isNotEmpty
                            ? ' (${latest.mechanicName!.trim()})'
                            : ''),
                  ),
                  if ((latest.repairNotes ?? '').trim().isNotEmpty)
                    Text(latest.repairNotes!.trim()),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.loc.cancelAction),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.loc.dvirReviewed),
            ),
          ],
        ),
      );
      if (reviewed != true || !mounted) return;
      final reviewError = await ref
          .read(dvirProvider.notifier)
          .reviewDvir(
            dvirId: '$previousId',
            reviewingDriverId: driverId,
            reviewingDriverName: dashboard.driverName,
            signatureData: signatureData,
            driverAgreed: true,
          );
      if (!mounted) return;
      if (reviewError != null) {
        _snack(reviewError);
        return;
      }
    }

    setState(() => _isSubmitting = true);
    final hasDefects = _hasAnyDefect;
    final report = DvirReport(
      id: '',
      type: InspectionType.preTrip,
      date: time.utc,
      driverName: dashboard.driverName,
      vehicleId: dashboard.vehicleId,
      trailerId: dashboard.trailerId,
      odometer: double.tryParse(_odometerController.text),
      items: const [],
      notes: _remarksController.text.isNotEmpty
          ? _remarksController.text
          : null,
      signature: signatureData,
      condition: hasDefects || _selectedStatus == 'Has Defects'
          ? VehicleCondition.needsRepair
          : VehicleCondition.safe,
      isSubmitted: false,
      location: _automaticLocation(),
      companyName: _companyName(),
      vehicleDefects: _vehicleDefectsController.text,
      trailerDefects: _trailerDefectsController.text,
      hasDefects: hasDefects || _selectedStatus == 'Has Defects',
      selectedDefects: _selectedDefects,
    );
    final saved = await ref
        .read(dvirProvider.notifier)
        .createReport(report, driverId: driverId, status: _selectedStatus);
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!saved) {
      _snack(
        ref.read(dvirProvider).error ?? 'The server did not accept the report.',
      );
      return;
    }
    setState(() => _signed = true);
    AppFeedback.success(context, context.loc.reportSavedSuccess);
    Navigator.pop(context);
  }

  /// Every `_snack` call in this page reports a refusal or failure.
  void _snack(String message) => AppFeedback.error(context, message);

  @override
  Widget build(BuildContext context) {
    final existingId = widget.existingReport?.id;
    if (existingId != null) {
      ref.listen<DvirReport?>(dvirProvider.select((s) => s.currentReport), (
        previous,
        next,
      ) {
        if (next == null ||
            next.id != existingId ||
            identical(next, previous)) {
          return;
        }
        setState(() => _applyReport(next));
      });
    }
    final dashboard = ref.watch(dashboardDataProvider);
    final account = ref.watch(accountProvider).accountData;
    final trusted = ref.watch(trustedTimeProvider).currentTime;
    final timeAvailable = trusted is TrustedTimeAvailable;
    // select على النص النهائي فقط: كيان الموقع يحمل timestamp يتغير كل
    // نبضة GPS، لذا مراقبة الكيان نفسه كانت تعيد بناء الصفحة كاملة كل ثانية.
    final automaticLocation =
        ref.watch(
          trackingStateProvider.select((s) {
            final l = s.currentLocation;
            return l == null
                ? null
                : '${l.latitude.toStringAsFixed(5)}, ${l.longitude.toStringAsFixed(5)}';
          }),
        ) ??
        (_report?.location ??
            context.loc.dvirLocationUnavailable);
    final companyName =
        _report?.companyName ??
        account?.carrier ??
        context.loc.dvirCompanyUnavailable;
    final textColor = context.styles.body.color!;
    final borderColor = context.colorScheme.outline;

    final String currentTime = timeAvailable
        ? DateFormat('d MMM yy, hh:mm a').format(trusted.utc.toLocal())
        : context.loc.dvirTimeUnavailableShort;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          context.loc.dvirInsertDvir,
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
        actions: [
          // SRS 7.2: إعادة جلب بيانات الخادم دون فقدان ما أدخله السائق.
          IconButton(
            key: const Key('dvir_form_refresh'),
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(dvirProvider.notifier).refresh(),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (widget.existingReport == null &&
                ref.watch(dvirProvider).previousToReview(dashboard.vehicleId) !=
                    null)
              Container(
                width: double.infinity,
                color: AppColors.warningYellow.withValues(alpha: 0.2),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  context.loc.dvirPreviousReviewNotice,
                ),
              ),
            _buildFieldGroup(
              title: context.loc.dvirTimeET,
              child: Text(
                currentTime,
                style: context.styles.body,
              ),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: context.loc.location,
              child: Text(
                automaticLocation,
                style: context.styles.body,
              ),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: context.loc.dvirOdometerMi,
              child: _buildFlatTextField(
                _odometerController,
                context.loc.dvirOdometerHint,
                textColor,
                keyboardType: TextInputType.number,
              ),
              borderColor: borderColor,
              textColor: textColor,
            ),

            // Reference layout (screenshots 15/19): Vehicle | Defects and
            // Trailers | Defects as two side-by-side underlined cells each.
            _buildTwoColumn(
              left: _buildCell(
                title: context.loc.vehicle,
                child: Text(
                  dashboard.vehicleDisplayName,
                  style: context.styles.body,
                ),
                borderColor: borderColor,
                textColor: textColor,
              ),
              right: _buildCell(
                title: context.loc.defectsTitle,
                child: _buildFlatTextField(
                  _vehicleDefectsController,
                  context.loc.defectsTitle,
                  textColor,
                ),
                borderColor: borderColor,
                textColor: textColor,
              ),
            ),
            _buildTwoColumn(
              left: _buildCell(
                title: context.loc.trailers,
                child: Text(
                  dashboard.trailerId ?? context.loc.trailers,
                  style: dashboard.trailerId == null
                        ? context.styles.subtitle
                        : context.styles.body,
                ),
                borderColor: borderColor,
                textColor: textColor,
              ),
              right: _buildCell(
                title: context.loc.defectsTitle,
                child: _buildFlatTextField(
                  _trailerDefectsController,
                  context.loc.defectsTitle,
                  textColor,
                ),
                borderColor: borderColor,
                textColor: textColor,
              ),
            ),
            // §396.11 catalog picks stay functional; rendered as plain lines
            // under the grid so the reference layout is unchanged.
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCatalogDefects(textColor),
            ),

            _buildFieldGroup(
              title: context.loc.company,
              child: Text(
                companyName,
                style: context.styles.body,
              ),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: context.loc.remarks,
              child: _buildFlatTextField(
                _remarksController,
                context.loc.remarks,
                textColor,
              ),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: context.loc.status,
              child: InkWell(
                onTap: _openStatusModal,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _statusLabel(_selectedStatus),
                        style: context.styles.body,
                      ),
                    ),
                    Icon(Icons.arrow_drop_down, color: textColor),
                  ],
                ),
              ),
              borderColor: borderColor,
              textColor: textColor,
            ),

            // Signature Section
            DvirSignatureCanvas(
              controller: _signatureController,
              borderColor: borderColor,
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 28,
                vertical: AppSpacing.sm,
              ),
              child: AppButton(
                label: _signed
                    ? (_isAr ? 'تم التوقيع' : 'SIGNED')
                    : (_isAr ? 'توقيع' : 'SIGN'),
                type: EldButtonType.agree,
                isLoading: _isSubmitting,
                onPressed: _isSubmitting || !timeAvailable || _signed
                    ? null
                    : _handleSubmit,
              ),
            ),
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldGroup({
    required String title,
    required Widget child,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cellTitle(title),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _cellTitle(String title) {
    return Text(title, style: context.styles.sectionTitle);
  }

  Widget _buildCell({
    required String title,
    required Widget child,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cellTitle(title),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildTwoColumn({required Widget left, required Widget right}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 32),
          Expanded(child: right),
        ],
      ),
    );
  }

  /// §396.11 catalog picks: defect cards plus "+ Add Defects". Free-text fields above stay as they were.
  Widget _buildCatalogDefects(Color textColor) {
    final loc = context.loc;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SRS 7.6: one card per defect (name, note, remove). The wire item
        // (`itemCode/itemName/category/note`) has no photo field, so no
        // photo control is offered.
        if (_selectedDefects.isNotEmpty)
          Column(
            key: const Key('dvir_defect_cards'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final d in _selectedDefects)
                Padding(
                  key: Key('dvir_defect_card_${d.item.code}'),
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        d.item.critical
                            ? Icons.warning_amber_rounded
                            : Icons.build_outlined,
                        size: 16,
                        color: d.item.critical
                            ? AppColors.dangerRed
                            : textColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          (d.description ?? '').trim().isEmpty
                              ? d.item.label(loc)
                              : '${d.item.label(loc)} — ${d.description!.trim()}',
                          style: context.styles.subtitle,
                        ),
                      ),
                      if (!_readOnly)
                        IconButton(
                          tooltip: loc.removeAction,
                          icon: const Icon(Icons.close, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          onPressed: () => setState(
                            () => _selectedDefects = _selectedDefects
                                .where((x) => x != d)
                                .toList(),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        if (!_readOnly)
          TextButton.icon(
            onPressed: _openDefectCatalog,
            icon: const Icon(Icons.add, size: 16),
            label: Text(
              loc.addDefects,
              style: context.styles.body.copyWith(fontSize: 12),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
      ],
    );
  }

  Widget _buildFlatTextField(
    TextEditingController controller,
    String hint,
    Color textColor, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: context.styles.body,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.styles.subtitle,
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }
}


