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
    _odometerController =
        TextEditingController(text: r?.odometer?.toString() ?? '');
    _vehicleDefectsController =
        TextEditingController(text: r?.vehicleDefects ?? '');
    _trailerDefectsController =
        TextEditingController(text: r?.trailerDefects ?? '');
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
    if (!_isAr) return wire;
    switch (wire) {
      case 'Vehicle Condition Satisfactory':
        return 'حالة المركبة مرضية';
      case 'Has Defects':
        return 'توجد عيوب';
      case 'Defects Corrected':
        return 'تم إصلاح العيوب';
      case 'Defects Need Not Be Corrected':
        return 'العيوب لا تستوجب الإصلاح';
      default:
        return wire;
    }
  }

  Future<void> _openDefectCatalog() async {
    if (_readOnly) return;
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final picked = await showDialog<List<DvirDefectSelection>>(
      context: context,
      builder: (_) => _DefectCatalogDialog(
        initial: _selectedDefects,
        isArabic: isArabic,
      ),
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
    final hasDefect = _hasAnyDefect;
    final ar = _isAr;
    // Wire values stay English (server contract); only the labels follow the locale.
    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(ar ? 'الحالة' : 'Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              title: Text(ar ? 'حالة المركبة مرضية' : 'Vehicle Condition Satisfactory'),
              enabled: !hasDefect,
              subtitle: hasDefect
                  ? Text(ar ? '— يوجد عيب مسجّل' : '— a defect is recorded')
                  : null,
              onTap: hasDefect
                  ? null
                  : () => Navigator.pop(
                      context, 'Vehicle Condition Satisfactory'),
            ),
            ListTile(
              title: Text(ar ? 'توجد عيوب' : 'Has Defects'),
              onTap: () => Navigator.pop(context, 'Has Defects'),
            ),
            ListTile(
              enabled: false,
              title: Text(ar ? 'تم إصلاح العيوب' : 'Defects Corrected'),
              subtitle: Text(ar ? 'لا يوجد تصديق إصلاح بعد' : 'No repair certification yet'),
            ),
            ListTile(
              enabled: false,
              title: Text(ar ? 'العيوب لا تستوجب الإصلاح' : 'Defects Need Not Be Corrected'),
              subtitle: Text(ar ? 'يحدّدها الناقل لا السائق' : 'Set by the carrier, not the driver'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(ar ? 'إلغاء' : 'CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, _selectedStatus),
            child: Text(ar ? 'موافق' : 'OK'),
          ),
        ],
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
        _isAr
            ? 'وقت الفحص غير متاح. اتصل ثم أعد المحاولة.'
            : 'Inspection time is unavailable. Connect and try again.',
      );
      return;
    }

    final dashboard = ref.read(dashboardDataProvider);
    final previousToReview =
        ref.read(dvirProvider).previousToReview(dashboard.vehicleId);

    if (widget.existingReport != null) {
      _snack(_isAr ? 'لا يمكن تعديل تقرير محفوظ من هذا الجهاز.' : 'A saved report cannot be edited on this device.');
      return;
    }

    final signatureData = dvirSignatureData(await _signatureController.toPngBytes());
    if (!mounted) return;
    if (signatureData == null) {
      _snack(_isAr ? 'التوقيع مطلوب.' : 'A signature is required.');
      return;
    }
    final driverId = ref.read(currentDriverIdProvider);
    if (driverId == null || driverId <= 0) {
      _snack(_isAr ? 'جلسة السائق مفقودة. سجّل الدخول مجدداً قبل التوقيع.' : 'Driver session is missing. Sign in again before signing the report.');
      return;
    }
    if (dashboard.vehicleId.trim().isEmpty || dashboard.vehicleId == 'No Vehicle') {
      _snack(_isAr ? 'معرّف المركبة مفقود. اختر مركبة قبل التوقيع.' : 'Vehicle id is missing. Select a vehicle before signing.');
      return;
    }

    if (previousToReview != null) {
      final latest = previousToReview;
      final previousId = int.tryParse(latest.id);
      if (previousId == null) {
        _snack(_isAr ? 'التقرير السابق بلا معرّف خادم ولا يمكن مراجعته.' : 'The previous report has no server id and cannot be reviewed.');
        return;
      }
      final isArabic = Localizations.localeOf(context).languageCode == 'ar';
      final previousDefects = <String>[
        for (final d in latest.selectedDefects)
          d.item.label(isArabic) +
              ((d.description?.trim().isNotEmpty ?? false) ? ' — ${d.description!.trim()}' : ''),
        if ((latest.vehicleDefects ?? '').trim().isNotEmpty) latest.vehicleDefects!.trim(),
        if ((latest.trailerDefects ?? '').trim().isNotEmpty) latest.trailerDefects!.trim(),
        if (latest.selectedDefects.isEmpty &&
            (latest.vehicleDefects ?? '').trim().isEmpty &&
            (latest.trailerDefects ?? '').trim().isEmpty &&
            (latest.defectsSummary ?? '').trim().isNotEmpty)
          latest.defectsSummary!.trim(),
      ];
      final reviewed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(isArabic ? 'الفحص السابق' : 'Previous inspection'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isArabic
                      ? 'راجع التقرير السابق ووقّع عليه قبل القيادة.'
                      : 'Review and sign the previous report before driving.',
                ),
                const SizedBox(height: 8),
                Text(
                  '${DateFormat('yyyy-MM-dd HH:mm').format(latest.date.toLocal())} — '
                  '${isArabic ? latest.condition.arabicName : latest.condition.englishName}',
                ),
                const SizedBox(height: 8),
                Text(
                  isArabic ? 'العيوب المسجّلة:' : 'Recorded defects:',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (previousDefects.isEmpty)
                  Text(isArabic ? 'لا توجد عيوب.' : 'None.')
                else
                  for (final line in previousDefects) Text('• $line'),
                if ((latest.repairStatus ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    (isArabic ? 'حالة الإصلاح: ' : 'Repair status: ') +
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
              child: Text(isArabic ? 'إلغاء' : 'CANCEL'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(isArabic ? 'تمت المراجعة' : 'Reviewed'),
            ),
          ],
        ),
      );
      if (reviewed != true || !mounted) return;
      final reviewError = await ref.read(dvirProvider.notifier).reviewDvir(
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
      notes: _remarksController.text.isNotEmpty ? _remarksController.text : null,
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
    final saved = await ref.read(dvirProvider.notifier).createReport(
          report,
          driverId: driverId,
          status: _selectedStatus,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    if (!saved) {
      _snack(ref.read(dvirProvider).error ?? 'The server did not accept the report.');
      return;
    }
    setState(() => _signed = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.loc.reportSavedSuccess),
        backgroundColor: AppColors.successGreen,
      ),
    );
    Navigator.pop(context);
  }

  /// Every `_snack` call in this page reports a refusal or failure.
  void _snack(String message) => AppFeedback.error(context, message);

  @override
  Widget build(BuildContext context) {
    final existingId = widget.existingReport?.id;
    if (existingId != null) {
      ref.listen<DvirReport?>(
        dvirProvider.select((s) => s.currentReport),
        (previous, next) {
          if (next == null || next.id != existingId || identical(next, previous)) {
            return;
          }
          setState(() => _applyReport(next));
        },
      );
    }
    final dashboard = ref.watch(dashboardDataProvider);
    final account = ref.watch(accountProvider).accountData;
    final location = ref.watch(trackingStateProvider).currentLocation;
    final trusted = ref.watch(trustedTimeProvider).currentTime;
    final timeAvailable = trusted is TrustedTimeAvailable;
    final automaticLocation = location == null
        ? (_report?.location ?? (_isAr ? 'الموقع غير متاح' : 'Location unavailable'))
        : '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
    final companyName = _report?.companyName ??
        account?.carrier ??
        (_isAr ? 'الشركة غير متاحة' : 'Company unavailable');
    final brightness = Theme.of(context).brightness;
    final textColor = AppColors.textPrimaryFor(brightness);
    final borderColor = AppColors.borderFor(brightness);

    final String currentTime = timeAvailable
        ? DateFormat('d MMM yy, hh:mm a').format(trusted.utc.toLocal())
        : (_isAr ? 'الوقت غير متاح' : 'Time unavailable');

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          _isAr ? 'إدراج تقرير فحص (DVIR)' : 'Insert DVIR',
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (widget.existingReport == null &&
                ref.watch(dvirProvider).previousToReview(dashboard.vehicleId) != null)
              Container(
                width: double.infinity,
                color: AppColors.warningYellow.withValues(alpha: 0.2),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(
                  _isAr
                      ? 'مراجعة التقرير السابق — فتح التقرير لا يعد مراجعة له.'
                      : 'Previous DVIR Review — §396.13. Opening the report is not a review.',
                ),
              ),
            _buildFieldGroup(
              title: _isAr ? 'الوقت' : 'Time (ET)',
              child: Text(currentTime,
                  style: TextStyle(color: textColor, fontSize: 16)),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: _isAr ? 'الموقع' : 'Location',
              child: Text(automaticLocation,
                  style: TextStyle(color: textColor, fontSize: 16)),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: _isAr ? 'المسافة' : 'Odometer (mi)',
              child: _buildFlatTextField(
                  _odometerController, _isAr ? 'المسافة' : 'Odometer', textColor,
                  keyboardType: TextInputType.number),
              borderColor: borderColor,
              textColor: textColor,
            ),

            // Reference layout (screenshots 15/19): Vehicle | Defects and
            // Trailers | Defects as two side-by-side underlined cells each.
            _buildTwoColumn(
              left: _buildCell(
                title: context.loc.vehicle,
                child: Text(dashboard.vehicleDisplayName,
                    style: TextStyle(color: textColor, fontSize: 16)),
                borderColor: borderColor,
                textColor: textColor,
              ),
              right: _buildCell(
                title: context.loc.defectsTitle,
                child: _buildFlatTextField(_vehicleDefectsController,
                    context.loc.defectsTitle, textColor),
                borderColor: borderColor,
                textColor: textColor,
              ),
            ),
            _buildTwoColumn(
              left: _buildCell(
                title: context.loc.trailers,
                child: Text(dashboard.trailerId ?? context.loc.trailers,
                    style: TextStyle(
                        color: dashboard.trailerId == null
                            ? AppColors.textSecondaryFor(brightness)
                            : textColor,
                        fontSize: 16)),
                borderColor: borderColor,
                textColor: textColor,
              ),
              right: _buildCell(
                title: context.loc.defectsTitle,
                child: _buildFlatTextField(_trailerDefectsController,
                    context.loc.defectsTitle, textColor),
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
              title: _isAr ? 'الشركة' : 'Company',
              child: Text(companyName,
                  style: TextStyle(color: textColor, fontSize: 16)),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: _isAr ? 'ملاحظات' : 'Remarks',
              child:
                  _buildFlatTextField(_remarksController, _isAr ? 'ملاحظات' : 'Remarks', textColor),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: _isAr ? 'الحالة' : 'Status',
              child: InkWell(
                onTap: _openStatusModal,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_statusLabel(_selectedStatus),
                          style: TextStyle(color: textColor, fontSize: 16)),
                    ),
                    Icon(Icons.arrow_drop_down, color: textColor),
                  ],
                ),
              ),
              borderColor: borderColor,
              textColor: textColor,
            ),

            // Signature Section
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                children: [
                  Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border:
                          Border.all(color: borderColor.withValues(alpha: 0.5)),
                      color: Colors
                          .white, // Ensure signature pad is visible against white
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Text(
                            _isAr ? 'الصورة غير متاحة.' : 'Image not available.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade300,
                            ),
                          ),
                        ),
                        Signature(
                          controller: _signatureController,
                          backgroundColor: Colors.transparent,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  InkWell(
                    onTap: () => _signatureController.clear(),
                    child: Text(
                      _isAr ? 'مسح التوقيع' : 'Clear signature',
                      style: const TextStyle(
                        fontSize: 14,
                        decoration: TextDecoration.underline,
                        decorationStyle: TextDecorationStyle.dotted,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 28, vertical: AppSpacing.sm),
              child: AppButton(
                label: _signed ? (_isAr ? 'تم التوقيع' : 'SIGNED') : (_isAr ? 'توقيع' : 'SIGN'),
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
          _cellTitle(title, textColor),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _cellTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
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
          _cellTitle(title, textColor),
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
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
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
                              ? d.item.label(isArabic)
                              : '${d.item.label(isArabic)} — ${d.description!.trim()}',
                          style: TextStyle(fontSize: 14, color: textColor),
                        ),
                      ),
                      if (!_readOnly)
                        IconButton(
                          tooltip: isArabic ? 'إزالة' : 'Remove',
                          icon: const Icon(Icons.close, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                              minWidth: 32, minHeight: 32),
                          onPressed: () => setState(() =>
                              _selectedDefects = _selectedDefects
                                  .where((x) => x != d)
                                  .toList()),
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
            label: Text(isArabic ? 'إضافة عيوب' : 'Add Defects',
                style: TextStyle(fontSize: 12, color: textColor)),
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
      TextEditingController controller, String hint, Color textColor,
      {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: textColor, fontSize: 16),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 16),
        border: InputBorder.none,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
    );
  }

}


/// Checkbox list of the live §396.11 catalog with an optional note per item.
class _DefectCatalogDialog extends ConsumerStatefulWidget {
  const _DefectCatalogDialog({required this.initial, required this.isArabic});

  final List<DvirDefectSelection> initial;
  final bool isArabic;

  @override
  ConsumerState<_DefectCatalogDialog> createState() => _DefectCatalogDialogState();
}

class _DefectCatalogDialogState extends ConsumerState<_DefectCatalogDialog> {
  late final Map<String, DvirDefectSelection> _picked = {
    for (final d in widget.initial) d.item.code: d,
  };
  final Map<String, TextEditingController> _notes = {};

  @override
  void dispose() {
    for (final c in _notes.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _noteFor(DvirCatalogItem item) =>
      _notes.putIfAbsent(item.code,
          () => TextEditingController(text: _picked[item.code]?.description ?? ''));

  @override
  Widget build(BuildContext context) {
    final isArabic = widget.isArabic;
    final catalog = ref.watch(dvirCatalogProvider);
    return AlertDialog(
      title: Text(isArabic ? 'العيوب (§396.11)' : 'Defects (§396.11)'),
      content: SizedBox(
        width: double.maxFinite,
        child: catalog.when(
          loading: () => const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic
                    ? 'تعذر تحميل قائمة العيوب من الخادم.'
                    : 'Could not load the defects list from the server.',
              ),
              TextButton(
                onPressed: () => ref.invalidate(dvirCatalogProvider),
                child: Text(isArabic ? 'إعادة المحاولة' : 'RETRY'),
              ),
            ],
          ),
          data: (items) => items.isEmpty
              ? Text(isArabic ? 'القائمة فارغة.' : 'The catalog is empty.')
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final checked = _picked.containsKey(item.code);
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                          value: checked,
                          title: Text(item.label(isArabic)),
                          subtitle: item.critical
                              ? Text(
                                  isArabic ? 'يؤثر على السلامة' : 'Safety affecting',
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.dangerRed),
                                )
                              : null,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              _picked[item.code] = DvirDefectSelection(
                                item: item,
                                description: _noteFor(item).text,
                              );
                            } else {
                              _picked.remove(item.code);
                            }
                          }),
                        ),
                        if (checked)
                          Padding(
                            padding: const EdgeInsets.only(left: 40, bottom: 8),
                            child: TextField(
                              controller: _noteFor(item),
                              style: const TextStyle(fontSize: 12),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: isArabic ? 'وصف (اختياري)' : 'Description (optional)',
                              ),
                              onChanged: (text) => _picked[item.code] =
                                  DvirDefectSelection(item: item, description: text),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isArabic ? 'إلغاء' : 'CANCEL'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _picked.values.toList()),
          child: Text(isArabic ? 'موافق' : 'OK'),
        ),
      ],
    );
  }
}
