import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/utils/logger.dart';
import '../../../account/presentation/providers/account_provider.dart';
import '../../../home/presentation/providers/dashboard_provider.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../domain/dvir_catalog.dart';
import '../../domain/dvir_vehicle.dart';
import '../../domain/entities/dvir_report.dart';
import 'dvir_provider.dart';

/// فشل عملية الإرسال/البوابة — نوع مغلق بدل نصوص مفاتيح: كل حالة ترسم
/// رسالتها في العرض، والمترجم يكشف أي حالة غير معالجة.
sealed class DvirSubmissionFailure {
  const DvirSubmissionFailure();
}

/// هوية/جهاز المركبة غير قابلين للحل — لا تقرير بلا مركبة موثوقة.
class DvirVehicleMissingFailure extends DvirSubmissionFailure {
  const DvirVehicleMissingFailure();
}

/// التزام §396.13 غير معروف (دون اتصال بلا إجابة موثوقة) — لا توقيع
/// بصمت على سؤال امتثال مجهول.
class DvirPreviousUnavailableFailure extends DvirSubmissionFailure {
  const DvirPreviousUnavailableFailure();
}

/// التقرير السابق بلا معرف خادم — لا يمكن تسجيل المراجعة عليه.
class DvirPreviousNoServerIdFailure extends DvirSubmissionFailure {
  const DvirPreviousNoServerIdFailure();
}

/// الوقت الموثوق غير متاح لحظة الحفظ — سجل قانوني لا يُوقّت بغيره.
class DvirTimeUnavailableFailure extends DvirSubmissionFailure {
  const DvirTimeUnavailableFailure();
}

/// التقرير محفوظ/معالَج — لا تعديل بعد الحفظ (SRS 7.12).
class DvirReportReadOnlyFailure extends DvirSubmissionFailure {
  const DvirReportReadOnlyFailure();
}

/// الخادم رفض الحفظ؛ [message] رسالة الخادم الأصلية (تُترجم في العرض
/// عبر anyErrorUserMessage) وقد تكون null فتُعرض الرسالة العامة.
class DvirServerRejectedFailure extends DvirSubmissionFailure {
  const DvirServerRejectedFailure(this.message);
  final String? message;
}

/// العملية أُلغيت: تخلّص الحالة أثناء التنفيذ، أو تغيّرت مركبة الفحص
/// بين البوابة والحفظ — لا يُرسل تقرير بسياق مراجعة قديم.
class DvirFlowCancelledFailure extends DvirSubmissionFailure {
  const DvirFlowCancelledFailure();
}

/// نتيجة بوابة §396.13: فشلٌ مُطبَّع، أو تقرير سابق يتطلب حوار مراجعة
/// (الحوار مسؤولية العرض)، و[vehicleId] المركبة التي اجتازت البوابة —
/// الحفظ اللاحق يجب أن يتحقق أنها لم تتغير.
class DvirReviewGate {
  final DvirSubmissionFailure? failure;
  final DvirReport? previous;
  final String vehicleId;

  const DvirReviewGate._(this.failure, this.previous, this.vehicleId);

  const DvirReviewGate.failed(DvirSubmissionFailure failure)
    : this._(failure, null, '');

  const DvirReviewGate.open({required this.previous, required this.vehicleId})
    : failure = null;
}

/// قيم حقول النص الخام كما جمعتها الواجهة من متحكماتها — كل قرار عنها
/// يعيش في النطاق أو في هذه الحالة، لا في الواجهة.
class DvirFormTextValue {
  final String location;
  final String odometer;
  final String trailerNumber;
  final String company;
  final String remarks;

  /// نصا العيوب (ضمّ تسميات الاختيارات) — توطينها قرار عرض، وقيمتها
  /// هنا بيانات تُرسل كما هي.
  final String vehicleDefects;
  final String trailerDefects;

  const DvirFormTextValue({
    required this.location,
    required this.odometer,
    required this.trailerNumber,
    required this.company,
    required this.remarks,
    required this.vehicleDefects,
    required this.trailerDefects,
  });
}

/// حالة نموذج إدراج DVIR — تملك كل قرار؛ الصفحة عرضٌ غبيّ فوقها.
class DvirFormState {
  /// التقرير المعروض للقراءة فقط (ملخص القائمة أو تفاصيل الخادم).
  /// غير null ⇒ الوضع قراءة فقط — **المصدر الوحيد** لهذا القرار.
  final DvirReport? existing;

  final InspectionType inspectionType;
  final DvirConditionStatus selectedStatus;
  final List<DvirDefectSelection> selectedDefects;

  /// مركبة الفحص المحلية — اختيار خاص بهذا التقرير لا يُعيد كتابة
  /// مركبة لوحة القيادة/نموذج اليوم. [hasExplicitVehicleSelection]
  /// يميّز اختيار السائق صراحةً عن القيمة الموروثة تلقائياً: الموروثة
  /// يمكن أن تتبدل مع تحديد التطبيق، والمختارة لا تُمس.
  final Vehicle? inspectionVehicle;
  final bool hasExplicitVehicleSelection;
  final DateTime? customTime;

  /// هوية مركبة الفحص المحلولة (اختيار محلي ← تحديد التطبيق ← لوحة
  /// القيادة) — القاعدة في `domain/dvir_vehicle.dart`. '' = غير متاحة.
  ///
  /// الثابت المرافق: `resolveDvirDeviceId` يحل الجهاز **لهذه الهوية
  /// نفسها** (مطابقة عبر قائمة المركبات) فلا يُرسل تقرير بمعرف مركبة
  /// وجهازٍ لمركبة أخرى.
  final String resolvedVehicleId;
  final String? vehicleDisplayName;

  /// هل توجد مراجعة §396.13 مستحقة لمركبة الفحص الحالية؟ (شريط التنبيه)
  final bool hasPreviousToReview;

  /// عملية الإرسال الكاملة (بوابة ← مراجعة ← حفظ) جارية — تمنع بدء
  /// عملية ثانية قبل انتهاء الأولى، بما يشمل مرحلة حوار المراجعة التي
  /// لا يغطيها isSubmitting في مزوّد القائمة.
  final bool submissionInProgress;

  /// القيم الابتدائية لحقول نص يملكها العرض (متحكماته) — تُحسب مرة
  /// عند الإنشاء حتى تبقى الواجهة بلا قراءات مزوّدات.
  final String initialTrailerNumber;
  final String initialCompany;

  const DvirFormState({
    this.existing,
    this.inspectionType = InspectionType.preTrip,
    this.selectedStatus = DvirConditionStatus.satisfactory,
    this.selectedDefects = const [],
    this.inspectionVehicle,
    this.hasExplicitVehicleSelection = false,
    this.customTime,
    this.resolvedVehicleId = '',
    this.vehicleDisplayName,
    this.hasPreviousToReview = false,
    this.submissionInProgress = false,
    this.initialTrailerNumber = '',
    this.initialCompany = '',
  });

  bool get readOnly => existing != null;
  bool get hasAnyDefect => selectedDefects.isNotEmpty;

  /// SRS 7.6: اختيار "بها عيوب" بلا عيوب مسجلة يستوجب فتح قائمة العيوب
  /// فوراً — قاعدة امتثال، فتسكن الحالة لا الواجهة.
  bool shouldPromptDefectsAfterStatus(DvirConditionStatus picked) =>
      picked == DvirConditionStatus.hasDefects && !hasAnyDefect;

  /// هوية المركبة كما تُعرض/تُتحقق في النموذج: التقرير أولاً في وضع
  /// القراءة، ثم الهوية المحلولة.
  String get displayVehicleId {
    final report = existing;
    if (report != null && report.vehicleId.trim().isNotEmpty) {
      return report.vehicleId.trim();
    }
    return resolvedVehicleId;
  }

  String get displayVehicleName {
    final report = existing;
    if (report != null && report.vehicleId.trim().isNotEmpty) {
      return report.vehicleId.trim();
    }
    return vehicleDisplayName ?? '';
  }

  DvirFormState copyWith({
    DvirReport? existing,
    InspectionType? inspectionType,
    DvirConditionStatus? selectedStatus,
    List<DvirDefectSelection>? selectedDefects,
    Vehicle? inspectionVehicle,
    bool clearInspectionVehicle = false,
    bool? hasExplicitVehicleSelection,
    DateTime? customTime,
    bool clearCustomTime = false,
    String? resolvedVehicleId,
    String? vehicleDisplayName,
    bool? hasPreviousToReview,
    bool? submissionInProgress,
  }) {
    return DvirFormState(
      existing: existing ?? this.existing,
      inspectionType: inspectionType ?? this.inspectionType,
      selectedStatus: selectedStatus ?? this.selectedStatus,
      selectedDefects: selectedDefects ?? this.selectedDefects,
      inspectionVehicle: clearInspectionVehicle
          ? null
          : (inspectionVehicle ?? this.inspectionVehicle),
      hasExplicitVehicleSelection:
          hasExplicitVehicleSelection ?? this.hasExplicitVehicleSelection,
      customTime: clearCustomTime ? null : (customTime ?? this.customTime),
      resolvedVehicleId: resolvedVehicleId ?? this.resolvedVehicleId,
      vehicleDisplayName: vehicleDisplayName ?? this.vehicleDisplayName,
      hasPreviousToReview: hasPreviousToReview ?? this.hasPreviousToReview,
      submissionInProgress: submissionInProgress ?? this.submissionInProgress,
      initialTrailerNumber: initialTrailerNumber,
      initialCompany: initialCompany,
    );
  }
}

/// حالة نموذج DVIR — نسخة لكل شاشة مفتوحة (`null` = تقرير جديد).
///
/// مفتاح الـ family هو `DvirReport?` بمساواة قيمية كاملة (Equatable):
/// نفس التقرير ⇒ نفس الحالة؛ ولا يُفتح نموذجان في آنٍ واحد أصلاً.
final dvirFormProvider = StateNotifierProvider.autoDispose
    .family<DvirFormNotifier, DvirFormState, DvirReport?>((ref, existing) {
      return DvirFormNotifier(ref: ref, existing: existing);
    });

class DvirFormNotifier extends StateNotifier<DvirFormState> {
  final Ref _ref;
  String? _requestedPreviousVehicleId;

  DvirFormNotifier({required Ref ref, DvirReport? existing})
    : _ref = ref,
      super(_initialState(ref, existing)) {
    _installListeners();
    _refreshVehicleDisplay();
    // الآثار الجانبية على مزوّدات أخرى تُؤجَّل حتى تكتمل تهيئة هذا
    // المزوّد (بدء أي شيء داخل سلسلة التهيئة يعدّل مزوّدًا قيد البناء —
    // كانت الصفحة القديمة تؤجلها بـ postFrameCallback للسبب نفسه).
    scheduleMicrotask(() {
      if (!mounted) return;
      if (existing != null) {
        // SRS 7.12: صف القائمة ملخص؛ التفاصيل الكاملة تُجلب وتُطبَّق عند
        // وصولها. فشل الجلب يُبقي الملخص.
        final serverId = int.tryParse(existing.id);
        if (serverId != null && serverId > 0) {
          _ref.read(dvirProvider.notifier).loadDvirDetails(existing.id);
        }
      } else {
        _loadPreviousDvirForCurrentVehicle();
      }
    });
  }

  static DvirFormState _initialState(Ref ref, DvirReport? existing) {
    if (existing != null) {
      // الحالة الرسمية كما وصلت — لا اشتقاق من مراجعة أو مراحل عيوب.
      return DvirFormState(
        existing: existing,
        inspectionType: existing.type,
        selectedStatus: existing.conditionStatus,
        selectedDefects: existing.selectedDefects,
      );
    }
    final dashboard = ref.read(dashboardDataProvider);
    return DvirFormState(
      inspectionVehicle: ref.read(vehicleProvider).selectedVehicle,
      initialTrailerNumber: initialDvirTrailerNumber(dashboard.trailerId),
      // اسم الناقل من الحساب — قيمة ابتدائية للعرض، لا قرار.
      initialCompany: ref.read(accountProvider).accountData?.carrier ?? '',
    );
  }

  void _installListeners() {
    // الاختيار العام قد يصل بعد فتح النموذج (بداية باردة) — تبنّاه مركبةَ
    // فحص **فقط ما لم يختر السائق مركبة صراحةً داخل هذا التقرير**.
    _ref.listen<VehicleState>(vehicleProvider, (previous, next) {
      final selected = next.selectedVehicle;
      if (!state.hasExplicitVehicleSelection &&
          state.inspectionVehicle == null &&
          selected != null) {
        state = state.copyWith(inspectionVehicle: selected);
        _refreshVehicleDisplay();
        _loadPreviousDvirForCurrentVehicle();
      }
    });
    // مركبة لوحة القيادة قد تُحلّ بعد فتح النموذج — بدون هذا لن يُفحص
    // التزام §396.13 لتلك المركبة أبداً. الاختيار الصريح يظل أعلى منها.
    _ref.listen<DashboardData>(dashboardDataProvider, (previous, next) {
      if (state.readOnly ||
          state.hasExplicitVehicleSelection ||
          previous?.vehicleId == next.vehicleId) {
        return;
      }
      _refreshVehicleDisplay();
      _loadPreviousDvirForCurrentVehicle();
    });
    // تفاصيل الخادم للتقرير المفتوح للقراءة فقط.
    final existingId = state.existing?.id;
    if (existingId != null) {
      _ref.listen<DvirReport?>(dvirProvider.select((s) => s.currentReport), (
        previous,
        next,
      ) {
        if (next == null ||
            next.id != existingId ||
            identical(next, previous)) {
          return;
        }
        applyServerDetail(next);
      });
    }
    _ref.listen<DvirState>(dvirProvider, (previous, next) {
      _syncPreviousNotice();
    }, fireImmediately: true);
  }

  /// يعيد حساب هوية/اسم مركبة الفحص من حالة المزوّدات الحالية.
  void _refreshVehicleDisplay() {
    final vehicleState = _ref.read(vehicleProvider);
    final dashboard = _ref.read(dashboardDataProvider);
    final inspection = state.inspectionVehicle ?? vehicleState.selectedVehicle;
    final resolved = resolveDvirVehicleUniqueId(
      vehicles: vehicleRefsForDvir(vehicleState.vehicles),
      selectedUniqueId: inspection?.uniqueId,
      dashboardVehicleId: dashboard.vehicleId,
    );
    state = state.copyWith(
      resolvedVehicleId: resolved ?? '',
      vehicleDisplayName:
          inspection?.displayName ?? dashboard.vehicleDisplayName,
    );
    _syncPreviousNotice();
  }

  void _syncPreviousNotice() {
    final has =
        !state.readOnly &&
        _ref.read(dvirProvider).previousToReview(state.resolvedVehicleId) !=
            null;
    if (state.hasPreviousToReview != has) {
      state = state.copyWith(hasPreviousToReview: has);
    }
  }

  void _loadPreviousDvirForCurrentVehicle() {
    if (state.readOnly) return;
    final vehicleId = state.resolvedVehicleId;
    if (isUnassignedVehicleId(vehicleId) ||
        vehicleId == _requestedPreviousVehicleId) {
      return;
    }
    _requestedPreviousVehicleId = vehicleId;
    _ref.read(dvirProvider.notifier).loadPreviousDvir(vehicleId);
  }

  // ---- قرارات النموذج (كانت حقول State في الصفحة) ----

  void setInspectionType(InspectionType type) =>
      state = state.copyWith(inspectionType: type);

  void selectStatus(DvirConditionStatus status) =>
      state = state.copyWith(selectedStatus: status);

  void setCustomTime(DateTime time) => state = state.copyWith(customTime: time);

  /// مركبة الفحص المحلية: تحديث النموذج + تحويل مصدر قائمة التقارير،
  /// دون المساس بمركبة لوحة القيادة (Bug #3/عزل النموذج اليومي).
  /// اختيار صريح — لن تتبدل بعد الآن مع تحديد التطبيق/لوحة القيادة.
  void setInspectionVehicle(Vehicle vehicle) {
    state = state.copyWith(
      inspectionVehicle: vehicle,
      hasExplicitVehicleSelection: true,
    );
    _ref.read(dvirProvider.notifier).setVehicle(vehicle.uniqueId);
    _refreshVehicleDisplay();
    _loadPreviousDvirForCurrentVehicle();
  }

  /// يطبّق اختيارات الكتالوج لنطاق واحد (مركبة/مقطورة) — كان ثلاثة
  /// معالجات منسوخة؛ القاعدة الآن واحدة: أي عيب ⇒ "بها عيوب"، لا شيء
  /// ⇒ "سليمة".
  void applyPickedDefects(
    List<DvirDefectSelection> picked, {
    required bool trailerScope,
  }) {
    final otherScope = state.selectedDefects
        .where((d) => d.item.isTrailer != trailerScope)
        .toList();
    final merged = trailerScope
        ? [...otherScope, ...picked]
        : [...picked, ...otherScope];
    state = state.copyWith(
      selectedDefects: merged,
      selectedStatus: merged.isNotEmpty
          ? DvirConditionStatus.hasDefects
          : DvirConditionStatus.satisfactory,
    );
  }

  /// يطبّق اختيارات كتالوج كامل (بلا نطاق مركبة/مقطورة) — مسار SRS 7.6
  /// عند اختيار "بها عيوب" بلا عيوب مسجلة.
  void applyUnscopedPickedDefects(List<DvirDefectSelection> picked) {
    state = state.copyWith(
      selectedDefects: picked,
      selectedStatus: picked.isNotEmpty
          ? DvirConditionStatus.hasDefects
          : DvirConditionStatus.satisfactory,
    );
  }

  /// تفاصيل الخادم وصلت للتقرير المفتوح للقراءة فقط. التفصيل هو **حقيقة
  /// الخادم الكاملة** (SRS 7.12): حالته ونوعه وعيوبه تحلّ محل الملخص
  /// كما وصلت — قائمة فارغة جوابٌ ("لا عيوب مسجلة") لا "أبقِ القديم".
  void applyServerDetail(DvirReport report) {
    state = state.copyWith(
      existing: report,
      inspectionType: report.type,
      selectedStatus: report.conditionStatus,
      selectedDefects: report.selectedDefects,
    );
  }

  // ---- عملية الإرسال: بروتوكول واحد لا يتداخل ----

  /// يفتح عملية الإرسال الكاملة (بوابة ← مراجعة ← حفظ). false = عملية
  /// أخرى جارية — الوسيط الوحيد المسموح له بعدها هو التخلّص.
  bool beginSubmission() {
    if (state.submissionInProgress) return false;
    state = state.copyWith(submissionInProgress: true);
    return true;
  }

  /// يغلق عملية الإرسال أيّاً كانت نتيجتها (نجاح/رفض/إلغاء) — تستدعيه
  /// الواجهة في finally.
  void endSubmission() {
    if (!mounted) return;
    if (state.submissionInProgress) {
      state = state.copyWith(submissionInProgress: false);
    }
  }

  /// بوابة ما قبل التوقيع — **كل شروط بدء عملية التوقيع هنا لا في
  /// الواجهة** (SRS 7.9/7.12): لا تعديل لتقرير محفوظ، لا بدء بلا وقت
  /// موثوق (وإلا خاض السائق حوار المراجعة ثم رُفض)، ثم حل الهوية
  /// والجهاز، ثم سؤال §396.13 «هل توجد مراجعة سابقة مستحقة؟» بسلطة
  /// (إجابة الخادم أو قائمة المركبة كاحتياط موثق؛ لا تخمين). بعد كل
  /// انتظار يُعاد التحقق أن مركبة الفحص لم تتغير — تغيّرها يلغي العملية.
  Future<DvirReviewGate> prepareReviewGate() async {
    if (!state.submissionInProgress) {
      return const DvirReviewGate.failed(DvirFlowCancelledFailure());
    }
    if (state.readOnly) {
      return const DvirReviewGate.failed(DvirReportReadOnlyFailure());
    }
    final trusted = _ref.read(trustedTimeProvider).currentTime;
    if (trusted is! TrustedTimeAvailable) {
      return const DvirReviewGate.failed(DvirTimeUnavailableFailure());
    }
    final vehicleId = state.resolvedVehicleId;
    if (isUnassignedVehicleId(vehicleId) || _resolveDeviceId() == null) {
      return const DvirReviewGate.failed(DvirVehicleMissingFailure());
    }
    final notifier = _ref.read(dvirProvider.notifier);
    final ready = await notifier.ensurePreviousDvir(vehicleId);
    if (!mounted || state.resolvedVehicleId != vehicleId) {
      return const DvirReviewGate.failed(DvirFlowCancelledFailure());
    }
    if (!ready) {
      return const DvirReviewGate.failed(DvirPreviousUnavailableFailure());
    }
    final previous = _ref.read(dvirProvider).previousToReview(vehicleId);
    if (previous != null && int.tryParse(previous.id) == null) {
      return const DvirReviewGate.failed(DvirPreviousNoServerIdFailure());
    }
    return DvirReviewGate.open(previous: previous, vehicleId: vehicleId);
  }

  int? _resolveDeviceId() {
    final vehicleState = _ref.read(vehicleProvider);
    final dashboard = _ref.read(dashboardDataProvider);
    final inspection = state.inspectionVehicle ?? vehicleState.selectedVehicle;
    return resolveDvirDeviceId(
      reportVehicleId: state.resolvedVehicleId,
      selectedVehicle: inspection == null
          ? null
          : DvirVehicleRef(
              id: inspection.id,
              uniqueId: inspection.uniqueId,
              deviceId: inspection.deviceId,
            ),
      dashboardDeviceId: dashboard.deviceId,
      vehicles: vehicleRefsForDvir(vehicleState.vehicles),
    );
  }

  /// يؤكد مراجعة السائق التالي للتقرير السابق. يعيد رسالة خطأ الخادم
  /// أو null للنجاح — الترجمة مسؤولية العرض.
  Future<String?> confirmPreviousReview({
    required DvirReport previous,
    required int driverId,
    required String signatureData,
  }) {
    return _ref
        .read(dvirProvider.notifier)
        .reviewDvir(
          dvirId: previous.id,
          reviewingDriverId: driverId,
          reviewingDriverName: _ref.read(dashboardDataProvider).driverName,
          signatureData: signatureData,
          driverAgreed: true,
        );
  }

  /// يبني المسودة عبر مصنع النطاق (الثوابت تُطبَّق مرة واحدة هناك)
  /// ويرسلها. لا يقبل إلا المركبة التي اجتازت البوابة
  /// ([gatedVehicleId]) — تغيّرها يُلغي العملية. وقت التفتيش يُقرأ
  /// **لحظة الحفظ** من المصدر الموثوق (لا وقت بداية الجلسة)، والوقت
  /// المختار صراحةً من السائق يظل مقدَّماً عليه.
  Future<DvirSubmissionFailure?> submitDraft({
    required DvirFormTextValue text,
    required String signatureData,
    required int driverId,
    required String gatedVehicleId,
  }) async {
    if (!state.submissionInProgress || state.readOnly) {
      return state.readOnly
          ? const DvirReportReadOnlyFailure()
          : const DvirFlowCancelledFailure();
    }
    final reportVehicleId = state.resolvedVehicleId;
    if (reportVehicleId != gatedVehicleId) {
      return const DvirFlowCancelledFailure();
    }
    final deviceId = _resolveDeviceId();
    if (deviceId == null ||
        deviceId <= 0 ||
        isUnassignedVehicleId(reportVehicleId)) {
      return const DvirVehicleMissingFailure();
    }
    final trusted = _ref.read(trustedTimeProvider).currentTime;
    if (trusted is! TrustedTimeAvailable) {
      return const DvirTimeUnavailableFailure();
    }
    final dashboard = _ref.read(dashboardDataProvider);
    final report = DvirReport.draft(
      type: state.inspectionType,
      inspectionTimeUtc: state.customTime?.toUtc() ?? trusted.utc,
      driverName: dashboard.driverName,
      vehicleId: reportVehicleId,
      deviceId: deviceId,
      selectedStatus: state.selectedStatus,
      hasAnyDefect: state.hasAnyDefect,
      selectedDefects: state.selectedDefects,
      signatureData: signatureData,
      trailerNumber: text.trailerNumber,
      odometerText: text.odometer,
      notes: text.remarks,
      location: text.location,
      companyName: text.company,
      vehicleDefects: text.vehicleDefects,
      trailerDefects: text.trailerDefects,
    );
    final saved = await _ref
        .read(dvirProvider.notifier)
        .createReport(report, driverId: driverId);
    if (!mounted) return const DvirFlowCancelledFailure();
    if (saved) return null;
    final error = _ref.read(dvirProvider).error;
    AppLogger.debug('DVIR draft submission rejected: ${error ?? 'unknown'}');
    return DvirServerRejectedFailure(error);
  }
}
