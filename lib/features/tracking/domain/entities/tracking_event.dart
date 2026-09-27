import 'package:equatable/equatable.dart';

/// يحدد مصدر إحداثيات التتبع
enum TrackingEventSource { gps, network, mock, obd, traccar, unknown }

/// الكيان الأساسي (Domain Entity) لبيانات التتبع.
/// مستقل تماماً عن Traccar أو أي نظام خارجي.
class TrackingEvent extends Equatable {
  final String id;
  final String deviceId;
  final String? vehicleId;
  final String? driverId;
  final double latitude;
  final double longitude;
  /// Metres per second (OS / OsmAnd raw). Convert at the consumer (×2.23694 mph, ×3.6 km/h).
  final double speed;
  final double bearing;
  final double altitude;
  final double accuracy;
  final double? odometer;
  final double? engineHours;
  final DateTime timestampUtc;
  final TrackingEventSource source;
  final Map<String, dynamic> metadata;

  const TrackingEvent({
    required this.id,
    required this.deviceId,
    this.vehicleId,
    this.driverId,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.bearing,
    required this.altitude,
    required this.accuracy,
    this.odometer,
    this.engineHours,
    required this.timestampUtc,
    required this.source,
    this.metadata = const {},
  });

  TrackingEvent copyWith({
    String? id,
    String? deviceId,
    String? vehicleId,
    String? driverId,
    double? latitude,
    double? longitude,
    double? speed,
    double? bearing,
    double? altitude,
    double? accuracy,
    double? odometer,
    double? engineHours,
    DateTime? timestampUtc,
    TrackingEventSource? source,
    Map<String, dynamic>? metadata,
  }) {
    return TrackingEvent(
      id: id ?? this.id,
      deviceId: deviceId ?? this.deviceId,
      vehicleId: vehicleId ?? this.vehicleId,
      driverId: driverId ?? this.driverId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      speed: speed ?? this.speed,
      bearing: bearing ?? this.bearing,
      altitude: altitude ?? this.altitude,
      accuracy: accuracy ?? this.accuracy,
      odometer: odometer ?? this.odometer,
      engineHours: engineHours ?? this.engineHours,
      timestampUtc: timestampUtc ?? this.timestampUtc,
      source: source ?? this.source,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        id,
        deviceId,
        vehicleId,
        driverId,
        latitude,
        longitude,
        speed,
        bearing,
        altitude,
        accuracy,
        odometer,
        engineHours,
        timestampUtc,
        source,
        metadata,
      ];
}
