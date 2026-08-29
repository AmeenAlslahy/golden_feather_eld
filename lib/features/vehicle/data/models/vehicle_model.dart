import '../../domain/entities/vehicle.dart';

/// نموذج المركبة للتحويل من/إلى JSON
class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    required super.name,
    required super.year,
    super.type,
    super.vin,
    super.trailerId,
    super.isAssigned = true,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final name = json['name'];
    final year = json['year'];

    if (id == null || name == null || year == null) {
      throw FormatException('Missing required fields: id=$id, name=$name, year=$year');
    }

    return VehicleModel(
      id: id.toString(),
      name: name.toString(),
      year: year.toString(),
      type: json['type'],
      vin: json['vin'],
      trailerId: json['trailer_id'],
      isAssigned: json['is_assigned'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'year': year,
      'type': type,
      'vin': vin,
      'trailer_id': trailerId,
      'is_assigned': isAssigned,
    };
  }

  factory VehicleModel.fromEntity(Vehicle vehicle) {
    return VehicleModel(
      id: vehicle.id,
      name: vehicle.name,
      year: vehicle.year,
      type: vehicle.type,
      vin: vehicle.vin,
      trailerId: vehicle.trailerId,
      isAssigned: vehicle.isAssigned,
    );
  }
}
