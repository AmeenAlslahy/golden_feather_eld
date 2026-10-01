import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/dvir_catalog.dart';
import '../extensions/dvir_catalog_extensions.dart';
import '../../domain/dvir_submission.dart';
import '../../domain/entities/dvir_report.dart';


import '../widgets/dvir_form_sections.dart';
import '../widgets/defect_card.dart';


import '../widgets/status_modal.dart';

import '../widgets/defects_modal.dart';

import '../providers/dvir_provider.dart';
import '../widgets/previous_dvir_review_modal.dart';
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

  // Initialised in didChangeDependencies so pen/background colours
  // match the active theme (light / dark) from the very first frame.
  late SignatureController _signatureController;
  bool _signatureReady = false;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the controller once using the active theme colours.
    // Re-building it on every dependency change would silently drop any
    // signature the driver has already started drawing.
    if (_signatureReady) return;
    _signatureReady = true;
    final cs = Theme.of(context).colorScheme;
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: cs.onSurface,
      exportBackgroundColor: cs.surface,
    );
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
    // FIX: only overwrite local selection if the server report has defects.
    if (r.selectedDefects.isNotEmpty) {
      _selectedDefects = r.selectedDefects;
    }
  }

  bool get _readOnly => widget.existingReport != null;

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
      // FIX: mounted check after the second awaited dialog.
      if (!mounted) return;
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

  Future<bool> _reviewPreviousDvirIfNeeded({
    required DvirReport latest,
    required int driverId,
    required DashboardData dashboard,
    required String signatureData,
  }) async {
    final previousId = int.tryParse(latest.id);
    if (previousId == null) {
      _snack(context.loc.dvirPrevNoServerId);
      return false;
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
      builder: (context) => PreviousDvirReviewModal(
        latest: latest,
        previousDefects: previousDefects,
      ),
    );
    
    if (reviewed != true || !mounted) return false;
    
    final reviewError = await ref.read(dvirProvider.notifier).reviewDvir(
          dvirId: '$previousId',
          reviewingDriverId: driverId,
          reviewingDriverName: dashboard.driverName,
          signatureData: signatureData,
          driverAgreed: true,
        );
        
    if (!mounted) return false;
    
    if (reviewError != null) {
      _snack(reviewError);
      return false;
    }
    
    return true;
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
    if (signatureData == null) return;
    final driverId = ref.read(currentDriverIdProvider);
    if (driverId == null || driverId <= 0) {
      _snack(
        context.loc.dvirDriverSessionMissing,
      );
      return;
    }

    if (previousToReview != null) {
      final success = await _reviewPreviousDvirIfNeeded(
        latest: previousToReview,
        driverId: driverId,
        dashboard: dashboard,
        signatureData: signatureData,
      );
      if (!success) return; // Review was aborted or failed
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
            DvirNoticeSection(
              dashboard: dashboard,
              hasExistingReport: widget.existingReport != null,
              hasPreviousToReview: ref.watch(dvirProvider).previousToReview(dashboard.vehicleId) != null,
            ),
            DvirTimeLocationSection(
              currentTime: currentTime,
              automaticLocation: automaticLocation,
              borderColor: borderColor,
              textColor: textColor,
            ),
            DvirOdometerSection(
              controller: _odometerController,
              readOnly: _readOnly,
              borderColor: borderColor,
              textColor: textColor,
            ),
            DvirVehicleSection(
              dashboard: dashboard,
              defectsController: _vehicleDefectsController,
              readOnly: _readOnly,
              borderColor: borderColor,
              textColor: textColor,
            ),
            DvirTrailerSection(
              dashboard: dashboard,
              defectsController: _trailerDefectsController,
              readOnly: _readOnly,
              borderColor: borderColor,
              textColor: textColor,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCatalogDefects(textColor),
            ),
            DvirCompanySection(
              companyName: companyName,
              borderColor: borderColor,
              textColor: textColor,
            ),
            DvirRemarksSection(
              controller: _remarksController,
              readOnly: _readOnly,
              borderColor: borderColor,
              textColor: textColor,
            ),
            DvirStatusSection(
              selectedStatusLabel: _statusLabel(_selectedStatus),
              onOpenStatusModal: _openStatusModal,
              borderColor: borderColor,
              textColor: textColor,
            ),
            DvirSignatureSection(
              controller: _signatureController,
            ),
            DvirSubmitButtonSection(
              isSigned: _signed,
              isSubmitting: _isSubmitting,
              timeAvailable: timeAvailable,
              onSubmit: _handleSubmit,
            ),
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }


  

  Widget _buildCatalogDefects(Color textColor) {
    final loc = context.loc;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_selectedDefects.isNotEmpty)
          Column(
            key: const Key('dvir_defect_cards'),
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final d in _selectedDefects)
                DefectCard(
                  key: const Key('dvir_defect_card_'),
                  defect: d,
                  textColor: textColor,
                  readOnly: _readOnly,
                  onRemove: () {
                    setState(() {
                      _selectedDefects = _selectedDefects.where((x) => x != d).toList();
                      if (_selectedDefects.isEmpty) {
                        _selectedStatus = 'Vehicle Condition Satisfactory';
                      }
                    });
                  },
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
}


