import 'package:equatable/equatable.dart';

/// نوع الفحص
enum InspectionType {
  preTrip('قبل الرحلة', 'Pre-Trip'),
  postTrip('بعد الرحلة', 'Post-Trip');

  final String arabicName;
  final String englishName;
  const InspectionType(this.arabicName, this.englishName);
}

/// حالة المركبة
enum VehicleCondition {
  safe('آمنة للقيادة', 'Safe to Drive'),
  needsRepair('تتطلب صيانة', 'Needs Repair'),
  unsafe('غير آمنة', 'Unsafe');

  final String arabicName;
  final String englishName;
  const VehicleCondition(this.arabicName, this.englishName);
}

/// أجزاء المركبة للفحص
enum InspectionItem {
  brakes('المكابح', 'Brakes'),
  tires('الإطارات', 'Tires'),
  lights('الإضاءة', 'Lights'),
  steering('أجهزة التوجيه', 'Steering'),
  trailerCoupling('وصلات المقطورة', 'Trailer Coupling'),
  emergencyEquipment('معدات الطوارئ', 'Emergency Equipment'),
  engine('المحرك', 'Engine'),
  fuelSystem('نظام الوقود', 'Fuel System'),
  exhaustSystem('نظام العادم', 'Exhaust System'),
  suspension('نظام التعليق', 'Suspension'),
  mirrors('المرايا', 'Mirrors'),
  windshield('الزجاج الأمامي', 'Windshield');

  final String arabicName;
  final String englishName;
  const InspectionItem(this.arabicName, this.englishName);
}

/// نتيجة فحص عنصر
class ItemInspectionResult extends Equatable {
  final InspectionItem item;
  final bool isDefective;
  final String? defectDescription;

  const ItemInspectionResult({
    required this.item,
    this.isDefective = false,
    this.defectDescription,
  });

  ItemInspectionResult copyWith({
    bool? isDefective,
    String? defectDescription,
  }) {
    return ItemInspectionResult(
      item: item,
      isDefective: isDefective ?? this.isDefective,
      defectDescription: defectDescription ?? this.defectDescription,
    );
  }

  @override
  List<Object?> get props => [item, isDefective, defectDescription];
}

/// كيان تقرير DVIR
class DvirReport extends Equatable {
  final String id;
  final InspectionType type;
  final DateTime date;
  final String driverName;
  final String vehicleId;
  final String? trailerId;
  final double? odometer;
  final List<ItemInspectionResult> items;
  final List<String>? dtcCodes;
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
  final DateTime? mechanicSignatureDate;
  final String? repairStatus;
  final String? repairNotes;
  final String? reviewingDriverName;
  final bool nextDriverReviewed;

  const DvirReport({
    required this.id,
    required this.type,
    required this.date,
    required this.driverName,
    required this.vehicleId,
    this.trailerId,
    this.odometer,
    required this.items,
    this.dtcCodes,
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
    this.mechanicSignatureDate,
    this.repairStatus,
    this.repairNotes,
    this.reviewingDriverName,
    this.nextDriverReviewed = false,
  });

  DvirReport copyWith({
    String? id,
    InspectionType? type,
    DateTime? date,
    String? driverName,
    String? vehicleId,
    String? trailerId,
    double? odometer,
    List<ItemInspectionResult>? items,
    List<String>? dtcCodes,
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
    DateTime? mechanicSignatureDate,
    String? repairStatus,
    String? repairNotes,
    String? reviewingDriverName,
    bool? nextDriverReviewed,
  }) {
    return DvirReport(
      id: id ?? this.id,
      type: type ?? this.type,
      date: date ?? this.date,
      driverName: driverName ?? this.driverName,
      vehicleId: vehicleId ?? this.vehicleId,
      trailerId: trailerId ?? this.trailerId,
      odometer: odometer ?? this.odometer,
      items: items ?? this.items,
      dtcCodes: dtcCodes ?? this.dtcCodes,
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
      mechanicSignatureDate: mechanicSignatureDate ?? this.mechanicSignatureDate,
      repairStatus: repairStatus ?? this.repairStatus,
      repairNotes: repairNotes ?? this.repairNotes,
      reviewingDriverName: reviewingDriverName ?? this.reviewingDriverName,
      nextDriverReviewed: nextDriverReviewed ?? this.nextDriverReviewed,
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
        items,
        dtcCodes,
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
        mechanicSignatureDate,
        repairStatus,
        repairNotes,
        reviewingDriverName,
        nextDriverReviewed,
      ];
}
