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
    // تحليل آمن للـ bool بدون cast مباشر يسبب TypeError
    bool safeBool(dynamic value, {bool fallback = false}) {
      if (value is bool) return value;
      if (value is int) return value != 0;
      if (value is String) return value.toLowerCase() == 'true';
      return fallback;
    }

    // isAssigned = السائق الحالي هو من أُسندت له هذه المركبة
    // وليست تحت استخدام سائق آخر حالياً
    final myVehicle = safeBool(json['myVehicle'], fallback: false);
    final inUseByOther = safeBool(json['inUseByOtherDriver'], fallback: false);
    final isAssigned = myVehicle && !inUseByOther;

    return VehicleModel(
      // vehicleId هو المفتاح الأساسي في ELD API
      id: json['vehicleId']?.toString() ??
          json['id']?.toString() ??
          'unknown',
      // vehicleName هو اسم المركبة في ELD API
      name: json['vehicleName']?.toString() ??
          json['name']?.toString() ??
          'Unknown Vehicle',
      // model في ELD API = طراز المركبة (Freightliner Cascadia, إلخ)
      year: json['model']?.toString() ?? '',
      vin: json['vin']?.toString(),
      // ELD API لا يعيد category؛ type يبقى null
      type: null,
      trailerId: null,
      isAssigned: isAssigned,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehicleId': id,
      'vehicleName': name,
      'model': year,
      'vin': vin,
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
