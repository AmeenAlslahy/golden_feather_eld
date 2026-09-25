import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:signature/signature.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/dvir_submission.dart';
import '../../domain/entities/dvir_report.dart';
import '../providers/dvir_provider.dart';

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

  @override
  void initState() {
    super.initState();
    final r = widget.existingReport;
    _locationController = TextEditingController(text: r?.location ?? '');
    _odometerController =
        TextEditingController(text: r?.odometer?.toString() ?? '');
    _vehicleDefectsController =
        TextEditingController(text: r?.vehicleDefects ?? '');
    _trailerDefectsController =
        TextEditingController(text: r?.trailerDefects ?? '');
    _companyController = TextEditingController(text: r?.companyName ?? '');
    _remarksController = TextEditingController(text: r?.notes ?? '');
    if (r != null) {
      _selectedStatus = r.condition == VehicleCondition.safe
          ? 'Vehicle Condition Satisfactory'
          : 'Has Defects';
      _signed = r.signature != null;
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
    final existing = widget.existingReport?.location;
    final point = ref.read(trackingStateProvider).currentLocation;
    if (point != null) {
      return '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
    }
    if (existing != null && existing.isNotEmpty) return existing;
    return 'Location unavailable';
  }

  String _companyName() {
    final existing = widget.existingReport?.companyName;
    if (existing != null && existing.isNotEmpty) return existing;
    return ref.read(accountProvider).accountData?.carrier ??
        'Company unavailable';
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    final time = ref.read(trustedTimeProvider).currentTime;
    if (time is! TrustedTimeAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inspection time is unavailable. Connect and try again.'),
        ),
      );
      return;
    }

    final dashboard = ref.read(dashboardDataProvider);
    final previous = ref
        .read(dvirProvider)
        .reports
        .where((report) => report.vehicleId == dashboard.vehicleId)
        .toList();

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

    if (previous.isNotEmpty && previous.first.nextDriverReviewed != true) {
      final latest = previous.first;
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

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final dashboard = ref.watch(dashboardDataProvider);
    final account = ref.watch(accountProvider).accountData;
    final location = ref.watch(trackingStateProvider).currentLocation;
    final trusted = ref.watch(trustedTimeProvider).currentTime;
    final timeAvailable = trusted is TrustedTimeAvailable;
    final automaticLocation = location == null
        ? (widget.existingReport?.location ?? 'Location unavailable')
        : '${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
    final companyName = widget.existingReport?.companyName ??
        account?.carrier ??
        'Company unavailable';
    final brightness = Theme.of(context).brightness;
    final surfaceColor = AppColors.surfaceFor(brightness);
    final textColor = AppColors.textPrimaryFor(brightness);
    final borderColor = AppColors.borderFor(brightness);

    final String currentTime = timeAvailable
        ? DateFormat('d MMM yy, hh:mm a').format(trusted.utc.toLocal())
        : 'Time unavailable';

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.surface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Insert DVIR',
          style: context.styles.appBarTitle,
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            if (ref.watch(dvirProvider).reports.any((report) =>
                report.vehicleId == dashboard.vehicleId &&
                report.id != widget.existingReport?.id))
              Container(
                width: double.infinity,
                color: AppColors.warningYellow.withValues(alpha: 0.2),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: const Text(
                  'Previous DVIR Review — §396.13. Opening the report is not a review.',
                ),
              ),
            _buildFieldGroup(
              title: 'Time',
              child: Text(currentTime,
                  style: TextStyle(color: textColor, fontSize: 14)),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: 'Location',
              child: Text(automaticLocation,
                  style: TextStyle(color: textColor, fontSize: 14)),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: 'Odometer (mi)',
              child: _buildFlatTextField(
                  _odometerController, 'Odometer', textColor,
                  keyboardType: TextInputType.number),
              borderColor: borderColor,
              textColor: textColor,
            ),

            // Grid for Vehicle and Trailers
            Container(
              decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: borderColor))),
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md, vertical: AppSpacing.sm),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.loc.vehicle,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(height: 4),
                        Text(dashboard.vehicleDisplayName,
                            style: TextStyle(color: textColor, fontSize: 14)),
                        const SizedBox(height: AppSpacing.md),
                        Text(context.loc.trailers,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        const SizedBox(height: 4),
                        Text(dashboard.trailerId ?? context.loc.trailers,
                            style: TextStyle(
                                color: AppColors.textSecondaryFor(
                                    brightness),
                                fontSize: 14)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.loc.defectsTitle,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        _buildFlatTextField(_vehicleDefectsController,
                            context.loc.defectsTitle, textColor),
                        const SizedBox(height: AppSpacing.sm),
                        Text(context.loc.defectsTitle,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: textColor)),
                        _buildFlatTextField(_trailerDefectsController,
                            context.loc.defectsTitle, textColor),
                        const SizedBox(height: AppSpacing.sm),
                        _buildCatalogDefects(textColor),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            _buildFieldGroup(
              title: 'Company',
              child: Text(companyName,
                  style: TextStyle(color: textColor, fontSize: 14)),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: 'Remarks',
              child:
                  _buildFlatTextField(_remarksController, 'Remarks', textColor),
              borderColor: borderColor,
              textColor: textColor,
            ),
            _buildFieldGroup(
              title: 'Status',
              child: InkWell(
                onTap: _openStatusModal,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(_statusLabel(_selectedStatus),
                          style: TextStyle(color: textColor, fontSize: 14)),
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
                            'Image not available.',
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
                    child: const Text(
                      'Clear signature',
                      style: TextStyle(
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
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              child: AppButton(
                label: _signed ? 'SIGNED' : 'SIGN',
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
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          child,
        ],
      ),
    );
  }

  /// §396.11 catalog picks: chips plus "+ Add Defects". Free-text fields above stay as they were.
  Widget _buildCatalogDefects(Color textColor) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedDefects.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: [
              for (final d in _selectedDefects)
                Chip(
                  label: Text(d.item.label(isArabic),
                      style: const TextStyle(fontSize: 11)),
                  avatar: d.item.critical
                      ? const Icon(Icons.warning_amber_rounded,
                          size: 14, color: AppColors.dangerRed)
                      : null,
                  onDeleted: _readOnly
                      ? null
                      : () => setState(() => _selectedDefects =
                          _selectedDefects.where((x) => x != d).toList()),
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
      style: TextStyle(color: textColor, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
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
