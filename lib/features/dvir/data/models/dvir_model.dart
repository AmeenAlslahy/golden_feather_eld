import '../../domain/entities/dvir_report.dart';

/// نموذج DVIR للتحويل من/إلى JSON
class DvirModel extends DvirReport {
  const DvirModel({
    required super.id,
    required super.type,
    required super.date,
    required super.driverName,
    required super.vehicleId,
    super.trailerId,
    super.odometer,
    required super.items,
    super.dtcCodes,
    super.notes,
    super.signature,
    super.condition = VehicleCondition.safe,
    super.isSubmitted = false,
  });

  factory DvirModel.fromJson(Map<String, dynamic> json) {
    return DvirModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] == 'post_trip'
          ? InspectionType.postTrip
          : InspectionType.preTrip,
      date: DateTime.tryParse(json['date'] ?? '') ?? DateTime.now(),
      driverName: json['driver_name'] ?? '',
      vehicleId: json['vehicle_id'] ?? '',
      trailerId: json['trailer_id'],
      odometer: json['odometer']?.toDouble(),
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => ItemInspectionResult(
                    item: InspectionItem.values.firstWhere(
                      (e) => e.name == item['item'],
                      orElse: () => InspectionItem.brakes,
                    ),
                    isDefective: item['is_defective'] ?? false,
                    defectDescription: item['defect_description'],
                  ))
              .toList() ??
          InspectionItem.values
              .map((item) => ItemInspectionResult(item: item))
              .toList(),
      dtcCodes: (json['dtc_codes'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      notes: json['notes'],
      signature: json['signature'],
      condition: VehicleCondition.values.firstWhere(
        (e) => e.name == json['condition'],
        orElse: () => VehicleCondition.safe,
      ),
      isSubmitted: json['is_submitted'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == InspectionType.postTrip ? 'post_trip' : 'pre_trip',
      'date': date.toIso8601String(),
      'driver_name': driverName,
      'vehicle_id': vehicleId,
      'trailer_id': trailerId,
      'odometer': odometer,
      'items': items
          .map((item) => {
                'item': item.item.name,
                'is_defective': item.isDefective,
                'defect_description': item.defectDescription,
              })
          .toList(),
      'dtc_codes': dtcCodes,
      'notes': notes,
      'signature': signature,
      'condition': condition.name,
      'is_submitted': isSubmitted,
    };
  }

  factory DvirModel.fromEntity(DvirReport report) {
    return DvirModel(
      id: report.id,
      type: report.type,
      date: report.date,
      driverName: report.driverName,
      vehicleId: report.vehicleId,
      trailerId: report.trailerId,
      odometer: report.odometer,
      items: report.items,
      dtcCodes: report.dtcCodes,
      notes: report.notes,
      signature: report.signature,
      condition: report.condition,
      isSubmitted: report.isSubmitted,
    );
  }
}
