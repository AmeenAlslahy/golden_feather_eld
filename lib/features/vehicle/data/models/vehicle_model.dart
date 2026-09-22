import '../../domain/entities/vehicle.dart';

class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.name,
    required super.year,
    super.type,
    super.vin,
    super.trailerId,
    super.isAssigned,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    return VehicleModel(
      id: json['vehicleId']?.toString() ?? json['uniqueId']?.toString() ?? json['id']?.toString() ?? 'unknown',
      name: json['vehicleName']?.toString() ?? json['name']?.toString() ?? 'Unknown Vehicle',
      year: json['model']?.toString() ?? 'N/A',
      vin: json['vin']?.toString() ?? json['uniqueId']?.toString(), // VIN from ELD or fallback to uniqueId
      type: json['category']?.toString(),
      trailerId: null, // Depending on Traccar implementation
      isAssigned: json['myVehicle'] as bool? ?? true, // Assuming returned means assigned
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'uniqueId': id,
      'name': name,
      'model': year,
      'category': type,
    };
  }

  factory VehicleModel.fromEntity(Vehicle entity) {
    return VehicleModel(
      id: entity.id,
      name: entity.name,
      year: entity.year,
      type: entity.type,
      vin: entity.vin,
      trailerId: entity.trailerId,
      isAssigned: entity.isAssigned,
    );
  }
}
