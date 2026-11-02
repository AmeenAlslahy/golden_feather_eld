import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:signature/signature.dart';
import 'package:intl/intl.dart';

import '../../../../core/error/user_facing_message.dart';
import '../../../../core/extensions/context_extensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/dvir_previous_review.dart';
import '../extensions/dvir_catalog_extensions.dart';
import '../../domain/dvir_signature.dart';
import '../../domain/entities/dvir_report.dart';

import '../widgets/dvir_form_sections.dart';

import '../widgets/status_modal.dart';

import '../widgets/defects_modal.dart';

import '../providers/dvir_form_provider.dart';
import '../providers/dvir_provider.dart';
import '../extensions/dvir_status_extensions.dart';
import '../widgets/previous_dvir_review_modal.dart';
import '../../../../core/widgets/app_feedback.dart';
import '../../../../core/widgets/golden_app_bar.dart';

import '../../../logs/presentation/widgets/vehicle_picker_dialog.dart';
import '../../../vehicle/domain/entities/vehicle.dart';

/// شاشة إدراج DVIR — عرضٌ غبيّ فوق [DvirFormNotifier]: كل قرار (المركبة،
/// العيوب، الحالة، بوابة §396.13، بناء المسودة) في الحالة/النطاق،
/// والصفحة تجمع النصوص وتدير الحوارات والتغذية الراجعة فقط.
class DvirFormPage extends ConsumerStatefulWidget {
  final DvirReport? existingReport;

  const DvirFormPage({super.key, this.existingReport});

  @override
  ConsumerState<DvirFormPage> createState() => _DvirFormPageState();
}

class _DvirFormPageState extends ConsumerState<DvirFormPage> {
  final _formKey = GlobalKey<FormState>();

  // متحكمات حقول النص التي يكتب فيها السائق فعلاً — ملك العرض.
  // حقولا العيوب ليسا هنا: نصّهما مشتق من الاختيارات (انظر _defectsText).
  late TextEditingController _locationController;
  late TextEditingController _odometerController;
  late TextEditingController _trailerController;
  late TextEditingController _companyController;
  late TextEditingController _remarksController;

  // Initialised in didChangeDependencies so pen/background colours
  // match the active theme (light / dark) from the very first frame.
  late SignatureController _signatureController;
  bool _signatureReady = false;

  // isSubmitting is read directly from dvirProvider.isSubmitting — no local
  // duplicate to avoid divergence between widget state and provider state.
  bool _signed = false;

  DvirFormNotifier get _form =>
      ref.read(dvirFormProvider(widget.existingReport).notifier);

  DvirFormState get _formState =>
      ref.read(dvirFormProvider(widget.existingReport));

  /// مصدر وحيد للحقيقة: حالة النموذج تقرر وضع القراءة فقط.
  bool get _readOnly => _formState.readOnly;

  @override
  void initState() {
    super.initState();
    final r = widget.existingReport;
    // إنشاء الحالة يقرأ المزوّدات مرة واحدة ويجمع القيم الابتدائية.
    final initial = _formState;
    _locationController = TextEditingController(text: r?.location ?? '');
    _odometerController = TextEditingController(
      text: r?.odometer?.toString() ?? '',
    );
    _trailerController = TextEditingController(
      text: r?.trailerId ?? initial.initialTrailerNumber,
    );
    _companyController = TextEditingController(
      text: r?.companyName ?? initial.initialCompany,
    );
    _remarksController = TextEditingController(text: r?.notes ?? '');
    _signed = r?.signature != null;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Build the controller once using the active theme colours.
    // Re-building it on every dependency change would silently drop any
    // signature the driver has already started drawing.
    if (_signatureReady) return;
    _signatureReady = true;
    final colorScheme = Theme.of(context).colorScheme;
    _signatureController = SignatureController(
      penStrokeWidth: 3,
      penColor: colorScheme.onSurface,
      exportBackgroundColor: colorScheme.surface,
    );
    // زر الإرسال يعكس حالة التوقيع لحظياً — كان يبقى "SIGN" للأبد في
    // التقارير الجديدة لأن لا أحد يحدّث _signed.
    _signatureController.addListener(() {
      if (!mounted || _readOnly) return;
      final has = _signatureController.isNotEmpty;
      if (has != _signed) setState(() => _signed = has);
    });
  }

  /// يملأ حقول القراءة فقط من تقرير وصل/تحدّث — قيمة الخادم غير الفارغة
  /// فقط تستبدل ما في الحقل.
  void _fillReadOnlyFields(DvirReport r) {
    _locationController.text = r.location ?? _locationController.text;
    _odometerController.text =
        r.odometer?.toString() ?? _odometerController.text;
    _trailerController.text = r.trailerId ?? _trailerController.text;
    _companyController.text = r.companyName ?? _companyController.text;
    _remarksController.text = r.notes ?? _remarksController.text;
    _signed = r.signature != null;
  }

  // ---- الحوارات: تفتح، ثم تسلّم القرار للحالة ----

  Future<void> _openVehicleDefectCatalog() async {
    if (_readOnly) return;
    final picked = await showDialog<List<DvirDefectSelection>>(
      context: context,
      builder: (_) => DefectCatalogDialog(
        title: '${context.loc.vehicle} - ${context.loc.defectsTitle}',
        initial: _formState.selectedDefects
            .where((d) => !d.item.isTrailer)
            .toList(),
      ),
    );
    if (picked == null || !mounted) return;
    _form.applyPickedDefects(picked, trailerScope: false);
  }

  Future<void> _openTrailerDefectCatalog() async {
    if (_readOnly) return;
    final picked = await showDialog<List<DvirDefectSelection>>(
      context: context,
      builder: (_) => DefectCatalogDialog(
        title: '${context.loc.trailer} - ${context.loc.defectsTitle}',
        customItems: kStandardTrailerDefectItems,
        initial: _formState.selectedDefects
            .where((d) => d.item.isTrailer)
            .toList(),
      ),
    );
    if (picked == null || !mounted) return;
    _form.applyPickedDefects(picked, trailerScope: true);
  }

  /// كتالوج كامل (SRS 7.6): يُفتح عند اختيار "بها عيوب" بلا عيوب مسجلة.
  Future<void> _openFullDefectCatalog() async {
    if (_readOnly) return;
    final picked = await showDialog<List<DvirDefectSelection>>(
      context: context,
      builder: (_) => DefectCatalogDialog(initial: _formState.selectedDefects),
    );
    if (picked == null || !mounted) return;
    _form.applyUnscopedPickedDefects(picked);
  }

  Future<void> _openTimePicker() async {
    if (_readOnly) return;
    final trusted = ref.read(trustedTimeProvider).currentTime;
    final initialDate =
        _formState.customTime ??
        (trusted is TrustedTimeAvailable
            ? trusted.utc.toLocal()
            : DateTime.now());
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialDate),
    );
    if (pickedTime == null || !mounted) return;
    _form.setCustomTime(
      DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      ),
    );
  }

  Future<void> _openVehiclePicker() async {
    if (_readOnly) return;
    final vehicle = await showDialog<Vehicle>(
      context: context,
      builder: (_) => const VehiclePickerDialog(
        // 🔴 مركبات السائق فقط — والسماح برسم تقرير فحص لمركبة لا يقودها
        // السائق مخالفة امتثال مباشرة (نفس قاعدة النموذج اليومي:
        // `form_tab.dart: allowCompanyFleet: false`).
        allowCompanyFleet: false,
      ),
    );
    if (vehicle != null && mounted) {
      // مركبة الفحص محلية لهذا التقرير — الحالة تقرر، ولا شيء يُكتب في
      // لوحة القيادة/النموذج اليومي.
      _form.setInspectionVehicle(vehicle);
    }
  }

  @override
  void dispose() {
    _locationController.dispose();
    _odometerController.dispose();
    _trailerController.dispose();
    _companyController.dispose();
    _remarksController.dispose();
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _openStatusModal() async {
    final selected = await showDialog<DvirConditionStatus>(
      context: context,
      builder: (context) => DvirStatusModal(
        hasDefect: _formState.hasAnyDefect,
        selectedStatus: _formState.selectedStatus,
      ),
    );
    if (selected == null || !mounted) return;
    _form.selectStatus(selected);
    // SRS 7.6: choosing Has Defects with nothing recorded opens the defects list.
    if (_formState.shouldPromptDefectsAfterStatus(selected)) {
      await _openFullDefectCatalog();
      // Mounted check after the second awaited dialog.
      if (!mounted) return;
    }
  }

  // ---- نصوص العيوب المشتقة: تنسيق عرض فقط، القرار في الحالة ----

  String _defectsText(DvirFormState state, {required bool trailer}) {
    if (state.readOnly) {
      final report = state.existing!;
      final server = trailer ? report.trailerDefects : report.vehicleDefects;
      if (server != null && server.isNotEmpty) return server;
      return report.selectedDefects
          .where((d) => d.item.isTrailer == trailer)
          .map((d) => d.item.name)
          .join(', ');
    }
    final loc = context.loc;
    return state.selectedDefects
        .where((d) => d.item.isTrailer == trailer)
        .map((d) => d.item.label(loc))
        .join(', ');
  }

  /// Every `_snack` call in this page reports a refusal or failure.
  void _snack(String message) => AppFeedback.error(context, message);

  /// يرسم كل نوع فشل مُطبَّع رسالته — المترجم يجبر معالجة الحالات كلها.
  String _failureMessage(DvirSubmissionFailure failure) => switch (failure) {
    DvirVehicleMissingFailure() => context.loc.dvirVehicleIdMissing,
    DvirPreviousUnavailableFailure() => context.loc.dvirPrevUnavailable,
    DvirPreviousNoServerIdFailure() => context.loc.dvirPrevNoServerId,
    DvirTimeUnavailableFailure() => context.loc.dvirTimeUnavailable,
    DvirReportReadOnlyFailure() => context.loc.dvirSavedCannotEdit,
    DvirServerRejectedFailure(:final message) =>
      message == null
          ? context.loc.errServerRejected
          : anyErrorUserMessage(message, loc: context.loc),
    // إلغاء العملية (تخلّص/تغيّر مركبة) لا رسالة له — الحالة انتهت.
    DvirFlowCancelledFailure() => '',
  };

  Future<void> _handleSubmit() async {
    if (ref.read(dvirProvider).isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;
    // فتح عملية الإرسال الكاملة — false يعني عملية جارية أصلاً (حتى
    // مرحلة حوار المراجعة مشمولة، لا isSubmitting وحده). المرجع يُلتقط
    // قبل أول await حتى يبقى finally صالحاً بعد تخلّص الواجهة.
    final form = _form;
    if (!form.beginSubmission()) return;
    try {
      // بوابة §396.13 (المركبة/الجهاز/المراجعة السابقة) — قرار الحالة.
      final gate = await form.prepareReviewGate();
      if (!mounted) return;
      final gateFailure = gate.failure;
      if (gateFailure is DvirFlowCancelledFailure) return;
      if (gateFailure != null) {
        _snack(_failureMessage(gateFailure));
        return;
      }

      final signatureData = dvirSignatureData(
        await _signatureController.toPngBytes(),
      );
      if (!mounted) return;
      if (signatureData == null) {
        // توقيع فارغ يُرفض بصوت مسموع — كان ينهي الطلب بصمت.
        _snack(context.loc.dvirSignatureRequired);
        return;
      }
      final driverId = ref.read(currentDriverIdProvider);
      if (driverId == null || driverId <= 0) {
        _snack(context.loc.dvirDriverSessionMissing);
        return;
      }

      final previous = gate.previous;
      if (previous != null) {
        final reviewed = await showDialog<bool>(
          context: context,
          builder: (context) => PreviousDvirReviewModal(
            latest: previous,
            previousDefects: previousDvirDefectLines(
              previous,
              label: (d) => d.item.label(context.loc),
            ),
          ),
        );
        if (!mounted || reviewed != true) return;

        final reviewError = await form.confirmPreviousReview(
          previous: previous,
          driverId: driverId,
          signatureData: signatureData,
        );
        if (!mounted) return;
        if (reviewError != null) {
          _snack(anyErrorUserMessage(reviewError, loc: context.loc));
          return;
        }
      }

      final state = _formState;
      final failure = await form.submitDraft(
        text: DvirFormTextValue(
          location: _locationController.text,
          odometer: _odometerController.text,
          trailerNumber: _trailerController.text,
          company: _companyController.text,
          remarks: _remarksController.text,
          vehicleDefects: _defectsText(state, trailer: false),
          trailerDefects: _defectsText(state, trailer: true),
        ),
        signatureData: signatureData,
        driverId: driverId,
        gatedVehicleId: gate.vehicleId,
      );
      if (!mounted) return;
      if (failure is DvirFlowCancelledFailure) return;
      if (failure != null) {
        _snack(_failureMessage(failure));
        return;
      }
      AppFeedback.success(context, context.loc.reportSavedSuccess);
      Navigator.pop(context);
    } catch (error, stackTrace) {
      // بيانات السائق لا تُسجَّل (لا توقيع ولا هويات) — الاستثناء وحده.
      AppLogger.error(
        'DVIR submission flow failed unexpectedly',
        error,
        stackTrace,
      );
      if (!mounted) return;
      _snack(context.loc.errRequestFailed);
    } finally {
      form.endSubmission();
    }
  }

  @override
  Widget build(BuildContext context) {
    final formKey = widget.existingReport;
    final formState = ref.watch(dvirFormProvider(formKey));
    final dvirState = ref.watch(dvirProvider);
    // تفاصيل الخادم وصلت للتقرير المفتوح للقراءة فقط ⇒ حدّث الحقول.
    ref.listen<DvirFormState>(dvirFormProvider(formKey), (previous, next) {
      if (!identical(previous?.existing, next.existing) &&
          next.existing != null) {
        _fillReadOnlyFields(next.existing!);
      }
    });
    final trusted = ref.watch(trustedTimeProvider).currentTime;
    final timeAvailable = trusted is TrustedTimeAvailable;
    final String currentTime = timeAvailable
        ? DateFormat('d MMM yy, hh:mm a').format(trusted.utc.toLocal())
        : context.loc.dvirTimeUnavailableShort;
    final readOnly = formState.readOnly;

    return Scaffold(
      appBar: GoldenAppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        titleText: context.loc.dvirInsertDvir,
        variant: GoldenAppBarVariant.brand,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          children: [
            DvirInspectionTypeSection(
              selectedType: formState.inspectionType,
              readOnly: readOnly,
              onTypeChanged: _form.setInspectionType,
            ),
            DvirNoticeSection(
              hasExistingReport: readOnly,
              hasPreviousToReview: formState.hasPreviousToReview,
            ),
            DvirTimeSection(
              currentTime: currentTime,
              onTap: _openTimePicker,
              readOnly: readOnly,
            ),
            DvirLocationSection(
              controller: _locationController,
              readOnly: readOnly,
            ),
            DvirOdometerSection(
              controller: _odometerController,
              readOnly: readOnly,
            ),
            DvirVehicleSection(
              vehicleId: formState.displayVehicleId,
              vehicleDisplayName: formState.displayVehicleName,
              defectsText: _defectsText(formState, trailer: false),
              readOnly: readOnly,
              onSelectDefects: _openVehicleDefectCatalog,
              onSelectVehicle: _openVehiclePicker,
            ),
            DvirTrailerSection(
              controller: _trailerController,
              defectsText: _defectsText(formState, trailer: true),
              readOnly: readOnly,
              onSelectDefects: _openTrailerDefectCatalog,
            ),
            DvirCompanySection(
              controller: _companyController,
              readOnly: readOnly,
            ),
            DvirRemarksSection(
              controller: _remarksController,
              readOnly: readOnly,
            ),
            DvirStatusSection(
              selectedStatusLabel: formState.selectedStatus.label(context.loc),
              onOpenStatusModal: _openStatusModal,
              readOnly: readOnly,
            ),
            DvirSignatureSection(
              controller: _signatureController,
              readOnly: readOnly,
              signatureData: formState.existing?.signature,
            ),
            if (!readOnly)
              DvirSubmitButtonSection(
                isSigned: _signed,
                isSubmitting: dvirState.isSubmitting,
                timeAvailable: timeAvailable,
                onSubmit: _handleSubmit,
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}
