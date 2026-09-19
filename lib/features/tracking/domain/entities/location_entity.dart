import 'package:equatable/equatable.dart';

/// كيان الموقع الجغرافي
class LocationEntity extends Equatable {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? speed;
  final double? bearing;
  final double? accuracy;
  final DateTime timestamp;
  final String? provider;
  final double? odometerMiles;
  final double? engineHours;

  const LocationEntity({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.speed,
    this.bearing,
    this.accuracy,
    required this.timestamp,
    this.provider,
    this.odometerMiles,
    this.engineHours,
  });

  /// موقع افتراضي (للتطوير)
  factory LocationEntity.empty() {
    return LocationEntity(
      latitude: 0.0,
      longitude: 0.0,
      timestamp: DateTime.now(),
    );
  }

  /// نسخ مع تعديل
  LocationEntity copyWith({
    double? latitude,
    double? longitude,
    double? altitude,
    double? speed,
    double? bearing,
    double? accuracy,
    DateTime? timestamp,
    String? provider,
    double? odometerMiles,
    double? engineHours,
  }) {
    return LocationEntity(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      altitude: altitude ?? this.altitude,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      accuracy: accuracy ?? this.accuracy,
      timestamp: timestamp ?? this.timestamp,
      provider: provider ?? this.provider,
      odometerMiles: odometerMiles ?? this.odometerMiles,
      engineHours: engineHours ?? this.engineHours,
    );
  }

  /// نص إحداثيات
  String get coordinates => '$latitude, $longitude';

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        altitude,
        speed,
        bearing,
        accuracy,
        timestamp,
        provider,
        odometerMiles,
        engineHours,
      ];
}

/// كيان إعدادات التتبع
class TrackingConfigEntity extends Equatable {
  final String serverUrl;
  final String deviceId;
  final String accuracy;
  final int distanceMeters;
  final int intervalSeconds;
  final int angleDegrees;
  final int heartbeatSeconds;
  final bool buffer;
  final bool wakeLock;
  final bool stopDetection;
  final bool preferPlatformProviders;

  const TrackingConfigEntity({
    required this.serverUrl,
    required this.deviceId,
    this.accuracy = 'medium',
    this.distanceMeters = 75,
    this.intervalSeconds = 300,
    this.angleDegrees = 0,
    this.heartbeatSeconds = 0,
    this.buffer = true,
    this.wakeLock = false,
    this.stopDetection = true,
    this.preferPlatformProviders = false,
  });

  @override
  List<Object?> get props => [
        serverUrl,
        deviceId,
        accuracy,
        distanceMeters,
        intervalSeconds,
        angleDegrees,
        heartbeatSeconds,
        buffer,
        wakeLock,
        stopDetection,
        preferPlatformProviders,
      ];
}

/// كيان سجل التتبع
class TrackingLogEntity extends Equatable {
  final int time;
  final String message;

  const TrackingLogEntity({
    required this.time,
    required this.message,
  });

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(time);

  @override
  List<Object?> get props => [time, message];
}
