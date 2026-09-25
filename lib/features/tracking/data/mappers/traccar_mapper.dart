import '../../domain/entities/tracking_event.dart';

/// محول (Mapper) يقوم بتحويل استجابات Traccar (JSON Maps)
/// إلى كيانات Domain (TrackingEvent) لضمان عدم تسرب نماذج Traccar
/// إلى طبقة الـ Domain أو الـ Business Logic.
class TraccarMapper {
  /// تحويل Traccar Position Map إلى TrackingEvent
  static TrackingEvent fromTraccarPosition(
    Map<String, dynamic> position, {
    String? vehicleId,
    String? driverId,
  }) {
    final attributes = position['attributes'] as Map<String, dynamic>? ?? {};

    return TrackingEvent(
      id: position['id']?.toString() ?? '',
      deviceId: position['deviceId']?.toString() ?? '',
      vehicleId: vehicleId,
      driverId: driverId,
      latitude: (position['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (position['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (position['speed'] as num?)?.toDouble() ?? 0.0,
      bearing: (position['course'] as num?)?.toDouble() ?? 0.0,
      altitude: (position['altitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (position['accuracy'] as num?)?.toDouble() ?? 0.0,
      odometer: (attributes['odometer'] as num?)?.toDouble(),
      engineHours: (attributes['hours'] as num?)?.toDouble(),
      timestampUtc: _parseUtcDate(position['fixTime']?.toString()),
      source: TrackingEventSource.traccar,
      metadata: attributes,
    );
  }

  /// تحويل Traccar Event Map إلى TrackingEvent
  /// (إذا كان الحدث يحتوي على إحداثيات أو معلومات ذات صلة)
  static TrackingEvent fromTraccarEvent(
    Map<String, dynamic> event,
    Map<String, dynamic> lastKnownPosition, {
    String? vehicleId,
    String? driverId,
  }) {
    // Traccar Events لا تحتوي دائماً على الإحداثيات مباشرة، لذا ندمجها مع آخر موقع معروف.
    final attributes = event['attributes'] as Map<String, dynamic>? ?? {};

    return TrackingEvent(
      id: event['id']?.toString() ?? '',
      deviceId: event['deviceId']?.toString() ?? '',
      vehicleId: vehicleId,
      driverId: driverId,
      latitude: (lastKnownPosition['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (lastKnownPosition['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (lastKnownPosition['speed'] as num?)?.toDouble() ?? 0.0,
      bearing: (lastKnownPosition['course'] as num?)?.toDouble() ?? 0.0,
      altitude: (lastKnownPosition['altitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (lastKnownPosition['accuracy'] as num?)?.toDouble() ?? 0.0,
      odometer: (attributes['odometer'] as num?)?.toDouble(),
      engineHours: (attributes['hours'] as num?)?.toDouble(),
      timestampUtc: _parseUtcDate(event['serverTime']?.toString()),
      source: TrackingEventSource.traccar,
      metadata: {
        'eventType': event['type'],
        ...attributes,
      },
    );
  }

  /// التأكد من أن الوقت المأخوذ هو UTC
  static DateTime _parseUtcDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) {
      return DateTime.now().toUtc();
    }
    try {
      final parsed = DateTime.parse(dateStr);
      // إذا كان النص لا يحتوي على حرف Z أو توقيت، فقد يتم تفسيره محلياً.
      // للتأكيد، نجبره على التحول إلى UTC.
      return parsed.toUtc();
    } catch (_) {
      return DateTime.now().toUtc();
    }
  }
}
