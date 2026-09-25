import '../../domain/entities/vehicle.dart';
import '../../domain/vehicle_selection.dart';

class VehicleModel extends Vehicle {
  const VehicleModel({
    required super.id,
    super.uniqueId,
    required super.name,
    required super.year,
    super.type,
    super.vin,
    super.trailerId,
    super.isAssigned,
    super.operationalStatus,
    super.statusReason,
    super.inUseByOther,
    super.selectedByServer,
    super.activeForCurrentDriver,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) {
    final vehicle = readVehicle(json);
    if (vehicle == null) {
      throw const FormatException('vehicle row has no identifier');
    }
    return VehicleModel.fromEntity(vehicle);
  }

  Map<String, dynamic> toJson() {
    return {
      if (uniqueId != null) 'uniqueId': uniqueId,
      'name': name,
      'model': year,
      'category': type,
    };
  }

  factory VehicleModel.fromEntity(Vehicle entity) {
    return VehicleModel(
      id: entity.id,
      uniqueId: entity.uniqueId,
      name: entity.name,
      year: entity.year,
      type: entity.type,
      vin: entity.vin,
      trailerId: entity.trailerId,
      isAssigned: entity.isAssigned,
      operationalStatus: entity.operationalStatus,
      statusReason: entity.statusReason,
      inUseByOther: entity.inUseByOther,
      selectedByServer: entity.selectedByServer,
      activeForCurrentDriver: entity.activeForCurrentDriver,
    );
  }
}
