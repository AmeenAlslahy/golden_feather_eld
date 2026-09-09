import '../../domain/entities/location_entity.dart';

/// نموذج الموقع
class LocationModel extends LocationEntity {
  const LocationModel({
    required super.latitude,
    required super.longitude,
    super.altitude,
    super.speed,
    super.bearing,
    super.accuracy,
    required super.timestamp,
    super.provider,
  });

  /// إنشاء من JSON
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      altitude: json['altitude']?.toDouble(),
      speed: json['speed']?.toDouble(),
      bearing: json['bearing']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      provider: json['provider'],
    );
  }

  /// التحويل إلى JSON
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'speed': speed,
      'bearing': bearing,
      'accuracy': accuracy,
      'timestamp': timestamp.toIso8601String(),
      'provider': provider,
    };
  }

  /// إنشاء من كيان
  factory LocationModel.fromEntity(LocationEntity entity) {
    return LocationModel(
      latitude: entity.latitude,
      longitude: entity.longitude,
      altitude: entity.altitude,
      speed: entity.speed,
      bearing: entity.bearing,
      accuracy: entity.accuracy,
      timestamp: entity.timestamp,
      provider: entity.provider,
    );
  }
}
