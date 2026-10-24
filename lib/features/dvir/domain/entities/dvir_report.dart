import 'package:equatable/equatable.dart';

import '../dvir_catalog.dart';

/// نوع الفحص
enum InspectionType { preTrip, postTrip }

/// حالة المركبة
enum VehicleCondition { safe, needsRepair, unsafe }

/// حالة DVIR الرسمية كما يعرّفها FMCSA — قيم `wire` هي النصوص التي يرسلها
/// الخادم ويستقبلها؛ لا تُستخدم النصوص كمعرّفات في الكود أبداً، الـ enum
/// فقط (SRS 7.6).
enum DvirConditionStatus {
  satisfactory('Vehicle Condition Satisfactory'),
  hasDefects('Has Defects'),
  defectsCorrected('Defects Corrected'),
  defectsNotCorrected('Defects Need Not Be Corrected'),
  unknown('Unknown');

  const DvirConditionStatus(this.wire);
  final String wire;

  /// حالة غير معروفة → unknown (تحفظ الأمان، لا تتحول بصمت إلى satisfactory).
  static DvirConditionStatus fromWire(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return DvirConditionStatus.unknown;
    for (final status in DvirConditionStatus.values) {
      if (status == DvirConditionStatus.unknown) continue;
      if (status.wire.toLowerCase() == v.toLowerCase()) return status;
    }
    return DvirConditionStatus.unknown;
  }

  /// DVIR-09 / SRS 7.1+7.6: a report with defects cannot stay satisfactory.
  /// Every other status is preserved verbatim; no inference from defect stages
  /// or §396.13 review state happens here.
  DvirConditionStatus resolvedFor({required bool hasDefects}) {
    if (hasDefects && this == DvirConditionStatus.satisfactory) {
      return DvirConditionStatus.hasDefects;
    }
    return this;
  }

  /// SRS 7.6: ما يجوز للسائق اختياره يدوياً في حوار الحالة —
  /// - حالتا الإصلاح يضبطهما الناقل بعد شهادة الإصلاح، ليستا قرار سائق.
  /// - "سليمة" تُمنع عند وجود عيوب مسجلة (وجه آخر من DVIR-09).
  /// - "غير معروف" ليست خياراً معروضاً أصلاً.
  bool driverMaySelect({required bool hasDefects}) {
    return switch (this) {
      DvirConditionStatus.satisfactory => !hasDefects,
      DvirConditionStatus.hasDefects => true,
      _ => false,
    };
  }
}

/// يقرأ نص العداد بنفس تسامح محدد الحقل: إزالة الفواصل، ورفض السالب
/// وغير الرقمي. فارغ أو غير صالح ⇒ `null`.
double? parseDvirOdometer(String? text) {
  final value = text?.trim().replaceAll(',', '') ?? '';
  if (value.isEmpty) return null;
  final parsed = double.tryParse(value);
  if (parsed != null && !parsed.isNaN && !parsed.isNegative) return parsed;
  return null;
}

/// نتيجة فحص عنصر — يُستبدل حقل العيوب في الكيان بـ [DvirDefectSelection]
/// (مواضع §396.11 من كتالوج الخادم)؛ هذه القائمة لم تعد جزءاً من الكيان.
///
/// حالة تشغيل المركبة المشتقة من عيوب التقرير (SRS 7.1).
///
/// تُحسب من العيوب **غير المُعالجة** فقط:
/// - `outOfService`: عيب يستوجب إيقاف الخدمة ولم يُعالج (server flag).
/// - `restricted`: عيوب أخرى غير مُعالجة.
/// - `available`: لا عيوب أو كلها مُعالجة.
/// لا يُدمج هذا الحقل مع حالة العيب في حقل واحد.
enum VehicleOperationalStatus { outOfService, restricted, available }

class DvirTrailer extends Equatable {
  final String trailerNumber;
  final List<String> defects;

  const DvirTrailer({required this.trailerNumber, this.defects = const []});

  @override
  List<Object?> get props => [trailerNumber, defects];
}

class DvirReport extends Equatable {
  final String id;
  final InspectionType type;
  final DateTime? date;
  final String driverName;
  final String vehicleId;

  /// معرف جهاز المركبة الرقمي — شرط الخادم في POST /eld/dvir (لا
  /// اختراع؛ يمر كما قرأته قائمة المركبات).
  final int? deviceId;
  final String? trailerId;
  final double? odometer;
  final String? notes;
  final String? signature;
  final VehicleCondition condition;

  /// الحالة الرسمية كما أعادها الخادم. لا تُشتق من `nextDriverReviewed` أو
  /// مراحل العيوب المحلية؛ `unknown` تعني أن المصدر لم يقدّم حالة صالحة.
  final DvirConditionStatus conditionStatus;
  final bool isSubmitted;

  // Additional fields from API
  final String? location;
  final String? companyName;
  final String? vehicleDefects;
  final String? trailerDefects;
  final bool hasDefects;
  final int defectsCount;
  final String? defectsSummary;
  final bool outOfService;
  final bool certified;
  final String? mechanicName;
  final String? repairStatus;
  final String? repairNotes;
  final String? reviewingDriverName;
  final bool nextDriverReviewed;

  /// §396.11 catalog items marked defective on this report.
  final List<DvirDefectSelection> selectedDefects;

  final List<String> photos;
  final List<DvirTrailer> trailers;

  /// SRS 7.1: حالة تشغيل المركبة المشترقة من عيوب هذا التقرير.
  /// الإيقاف (`outOfService` من الخادم) يرجح على التقييد، والتقييد على التوفر.
  VehicleOperationalStatus get vehicleOperationalStatus {
    if (outOfService) return VehicleOperationalStatus.outOfService;
    if (hasDefects) return VehicleOperationalStatus.restricted;
    return VehicleOperationalStatus.available;
  }

  /// FMCSA requires retaining DVIR records for 3 months from the date of inspection.
  /// يحسب 3 أشهر بدقة مع مراعاة نهايات الأشهر المختلفة.
  DateTime? get retentionUntil {
    final d = date;
    if (d == null) return null;
    var targetYear = d.year;
    var targetMonth = d.month + 3;
    if (targetMonth > 12) {
      targetYear += (targetMonth - 1) ~/ 12;
      targetMonth = (targetMonth - 1) % 12 + 1;
    }
    final daysInTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
    final targetDay = d.day > daysInTargetMonth ? daysInTargetMonth : d.day;
    return DateTime(targetYear, targetMonth, targetDay, d.hour, d.minute);
  }

  /// يبني تقريراً جديداً (غير مُرسل) من قيم النموذج الخام، ويطبّق
  /// ثوابت النطاق مرة واحدة هنا فقط:
  /// - DVIR-09: عيوب مسجلة لا تبقى على حالة "سليمة"
  ///   ([DvirConditionStatus.resolvedFor]).
  /// - الحالة الخشنة: عيوب ⇒ [VehicleCondition.needsRepair].
  /// - التطبيع (trim/فارغ ⇒ null) بنفس القيم التي كان يرسلها النموذج.
  ///
  /// المستدعي يمرر النصوص كما هي؛ كل قرار يعيش هنا أو في دوال النطاق.
  factory DvirReport.draft({
    required InspectionType type,
    required DateTime inspectionTimeUtc,
    required String driverName,
    required String vehicleId,
    required int? deviceId,
    required DvirConditionStatus selectedStatus,
    required bool hasAnyDefect,
    required List<DvirDefectSelection> selectedDefects,
    required String signatureData,
    String? trailerNumber,
    String? odometerText,
    String? notes,
    String? location,
    String? companyName,
    String? vehicleDefects,
    String? trailerDefects,
  }) {
    final status = selectedStatus.resolvedFor(hasDefects: hasAnyDefect);
    final trailer = trailerNumber?.trim();
    final locationTrimmed = location?.trim();
    final companyTrimmed = companyName?.trim();
    return DvirReport(
      id: '',
      type: type,
      date: inspectionTimeUtc,
      driverName: driverName,
      vehicleId: vehicleId,
      deviceId: deviceId,
      trailerId: trailer == null || trailer.isEmpty ? null : trailer,
      odometer: parseDvirOdometer(odometerText),
      notes: notes != null && notes.isNotEmpty ? notes : null,
      signature: signatureData,
      condition: hasAnyDefect
          ? VehicleCondition.needsRepair
          : VehicleCondition.safe,
      conditionStatus: status,
      isSubmitted: false,
      location: locationTrimmed != null && locationTrimmed.isNotEmpty
          ? locationTrimmed
          : null,
      companyName: companyTrimmed != null && companyTrimmed.isNotEmpty
          ? companyTrimmed
          : '',
      vehicleDefects: vehicleDefects,
      trailerDefects: trailerDefects,
      hasDefects: hasAnyDefect,
      selectedDefects: selectedDefects,
    );
  }

  const DvirReport({
    required this.id,
    required this.type,
    this.date,
    required this.driverName,
    required this.vehicleId,
    this.deviceId,
    this.trailerId,
    this.odometer,
    this.notes,
    this.signature,
    this.condition = VehicleCondition.safe,
    this.conditionStatus = DvirConditionStatus.unknown,
    this.isSubmitted = false,
    this.location,
    this.companyName,
    this.vehicleDefects,
    this.trailerDefects,
    this.hasDefects = false,
    this.defectsCount = 0,
    this.defectsSummary,
    this.outOfService = false,
    this.certified = false,
    this.mechanicName,
    this.repairStatus,
    this.repairNotes,
    this.reviewingDriverName,
    this.nextDriverReviewed = false,
    this.selectedDefects = const [],
    this.photos = const [],
    this.trailers = const [],
  });

  DvirReport copyWith({
    String? id,
    InspectionType? type,
    DateTime? date,
    String? driverName,
    String? vehicleId,
    int? deviceId,
    String? trailerId,
    double? odometer,
    String? notes,
    String? signature,
    VehicleCondition? condition,
    DvirConditionStatus? conditionStatus,
    bool? isSubmitted,
    String? location,
    String? companyName,
    String? vehicleDefects,
    String? trailerDefects,
    bool? hasDefects,
    int? defectsCount,
    String? defectsSummary,
    bool? outOfService,
    bool? certified,
    String? mechanicName,
    String? repairStatus,
    String? repairNotes,
    String? reviewingDriverName,
    bool? nextDriverReviewed,
    List<DvirDefectSelection>? selectedDefects,
    bool clearSelectedDefects = false,
    List<String>? photos,
    List<DvirTrailer>? trailers,
  }) {
    return DvirReport(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      driverName: driverName ?? this.driverName,
      vehicleId: vehicleId ?? this.vehicleId,
      deviceId: deviceId ?? this.deviceId,
      trailerId: trailerId ?? this.trailerId,
      odometer: odometer ?? this.odometer,
      notes: notes ?? this.notes,
      signature: signature ?? this.signature,
      condition: condition ?? this.condition,
      conditionStatus: conditionStatus ?? this.conditionStatus,
      isSubmitted: isSubmitted ?? this.isSubmitted,
      location: location ?? this.location,
      companyName: companyName ?? this.companyName,
      vehicleDefects: vehicleDefects ?? this.vehicleDefects,
      trailerDefects: trailerDefects ?? this.trailerDefects,
      hasDefects: hasDefects ?? this.hasDefects,
      defectsCount: defectsCount ?? this.defectsCount,
      defectsSummary: defectsSummary ?? this.defectsSummary,
      outOfService: outOfService ?? this.outOfService,
      certified: certified ?? this.certified,
      mechanicName: mechanicName ?? this.mechanicName,
      repairStatus: repairStatus ?? this.repairStatus,
      repairNotes: repairNotes ?? this.repairNotes,
      reviewingDriverName: reviewingDriverName ?? this.reviewingDriverName,
      nextDriverReviewed: nextDriverReviewed ?? this.nextDriverReviewed,
      selectedDefects: clearSelectedDefects
          ? const []
          : (selectedDefects ?? this.selectedDefects),
      photos: photos ?? this.photos,
      trailers: trailers ?? this.trailers,
    );
  }

  @override
  List<Object?> get props => [
    id,
    type,
    date,
    driverName,
    vehicleId,
    deviceId,
    trailerId,
    odometer,
    notes,
    signature,
    condition,
    conditionStatus,
    isSubmitted,
    location,
    companyName,
    vehicleDefects,
    trailerDefects,
    hasDefects,
    defectsCount,
    defectsSummary,
    outOfService,
    certified,
    mechanicName,
    repairStatus,
    repairNotes,
    reviewingDriverName,
    nextDriverReviewed,
    selectedDefects,
    photos,
    trailers,
  ];
}
