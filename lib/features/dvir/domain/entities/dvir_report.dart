import 'package:equatable/equatable.dart';

import '../dvir_catalog.dart';

/// نوع الفحص
enum InspectionType {
  preTrip,
  postTrip;
}

/// حالة المركبة
enum VehicleCondition {
  safe,
  needsRepair,
  unsafe;
}

/// حالة DVIR الرسمية كما يعرّفها FMCSA — قيم `wire` هي النصوص التي يرسلها
/// الخادم ويستقبلها؛ لا تُستخدم النصوص كمعرّفات في الكود أبداً، الـ enum
/// فقط (SRS 7.6).
enum DvirConditionStatus {
  satisfactory('Vehicle Condition Satisfactory'),
  hasDefects('Has Defects'),
  defectsCorrected('Defects Corrected'),
  defectsNotCorrected('Defects Need Not Be Corrected');

  const DvirConditionStatus(this.wire);
  final String wire;

  /// حالة غير معروفة → satisfactory (الافتراضي عند الإنشاء).
  static DvirConditionStatus fromWire(String? value) {
    final v = value?.trim() ?? '';
    for (final status in DvirConditionStatus.values) {
      if (status.wire == v) return status;
    }
    return DvirConditionStatus.satisfactory;
  }
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
enum VehicleOperationalStatus {
  outOfService,
  restricted,
  available,
}

class DvirReport extends Equatable {
  final String id;
  final InspectionType type;
  final DateTime date;
  final String driverName;
  final String vehicleId;
  final String? trailerId;
  final double? odometer;
  final String? notes;
  final String? signature;
  final VehicleCondition condition;
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

  /// SRS 7.1: حالة تشغيل المركبة المشترقة من عيوب هذا التقرير.
  /// الإيقاف (`outOfService` من الخادم) يرجح على التقييد، والتقييد على التوفر.
  VehicleOperationalStatus get vehicleOperationalStatus {
    if (outOfService) return VehicleOperationalStatus.outOfService;
    if (hasDefects) return VehicleOperationalStatus.restricted;
    return VehicleOperationalStatus.available;
  }

  const DvirReport({
    required this.id,
    required this.type,
    required this.date,
    required this.driverName,
    required this.vehicleId,
    this.trailerId,
    this.odometer,
    this.notes,
    this.signature,
    this.condition = VehicleCondition.safe,
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
  });

  DvirReport copyWith({
    String? id,
    InspectionType? type,
    DateTime? date,
    String? driverName,
    String? vehicleId,
    String? trailerId,
    double? odometer,
    String? notes,
    String? signature,
    VehicleCondition? condition,
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
  }) {
    return DvirReport(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      driverName: driverName ?? this.driverName,
      vehicleId: vehicleId ?? this.vehicleId,
      trailerId: trailerId ?? this.trailerId,
      odometer: odometer ?? this.odometer,
      notes: notes ?? this.notes,
      signature: signature ?? this.signature,
      condition: condition ?? this.condition,
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
      selectedDefects: selectedDefects ?? this.selectedDefects,
    );
  }

  @override
  List<Object?> get props => [
        id,
        type,
        date,
        driverName,
        vehicleId,
        trailerId,
        odometer,
        notes,
        signature,
        condition,
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
      ];
}
