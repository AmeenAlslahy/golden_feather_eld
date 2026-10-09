import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/native_location_event.dart';

class NativeLocationQualityValidator {
  /// [nowUtc] defaults to the device clock; production wires the trusted
  /// `TimeAuthority.nowUtc` so freshness checks survive a skewed device clock.
  NativeLocationQualityValidator({DateTime Function()? nowUtc})
      : _nowUtc = nowUtc ?? (() => DateTime.now().toUtc());

  final DateTime Function() _nowUtc;

  NativeLocationEvent validate(
      NativeLocationEvent event, DateTime? lastRecordedAt) {
    // Basic coordinate bounds
    if (event.latitude < -90 ||
        event.latitude > 90 ||
        event.longitude < -180 ||
        event.longitude > 180) {
      return event.copyWith(qualityStatus: LocationQualityStatus.invalid);
    }

    if (event.latitude.isNaN ||
        event.longitude.isNaN ||
        event.latitude.isInfinite ||
        event.longitude.isInfinite) {
      return event.copyWith(qualityStatus: LocationQualityStatus.invalid);
    }

    if (event.accuracyMeters < 0 || event.speedMetersPerSecond < 0) {
      return event.copyWith(qualityStatus: LocationQualityStatus.invalid);
    }

    // Time validation
    final now = _nowUtc();
    final timeDiff = event.recordedAt.difference(now).inMinutes;
    if (timeDiff > 5) {
      // Future timestamp (suspicious)
      return event.copyWith(qualityStatus: LocationQualityStatus.suspicious);
    }

    if (now.difference(event.recordedAt).inMinutes > 60) {
      // Very old (stale)
      return event.copyWith(qualityStatus: LocationQualityStatus.stale);
    }

    // Ordering validation
    if (lastRecordedAt != null && event.recordedAt.isBefore(lastRecordedAt)) {
      return event.copyWith(qualityStatus: LocationQualityStatus.outOfOrder);
    }

    return event.copyWith(qualityStatus: LocationQualityStatus.valid);
  }
}

class NativeEventChannelClient {
  static const EventChannel _eventChannel =
      EventChannel('com.goldenfeather.eld/traccar/events');

  StreamSubscription? _subscription;
  final StreamController<NativeLocationEvent> _locationController =
      StreamController<NativeLocationEvent>.broadcast();
  final NativeLocationQualityValidator _validator;
  DateTime? _lastRecordedAt;

  NativeEventChannelClient({NativeLocationQualityValidator? validator})
      : _validator = validator ?? NativeLocationQualityValidator();

  Stream<NativeLocationEvent> get locationStream => _locationController.stream;

  void startListening() {
    if (_subscription != null) return; // Prevent multiple subscriptions

    AppLogger.info('NativeEventChannelClient: startListening called');

    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (dynamic event) {
        AppLogger.info('📡 EventChannel received: $event');
        AppLogger.info('NativeEventChannelClient: Event received from native');
        if (event is Map) {
          try {
            final parsedEvent = _parseEvent(Map<String, dynamic>.from(event));
            if (parsedEvent != null) {
              AppLogger.info(
                  'NativeEventChannelClient: Event parsed successfully');
              final validatedEvent =
                  _validator.validate(parsedEvent, _lastRecordedAt);
              if (validatedEvent.qualityStatus == LocationQualityStatus.valid ||
                  validatedEvent.qualityStatus ==
                      LocationQualityStatus.suspicious ||
                  validatedEvent.qualityStatus == LocationQualityStatus.stale) {
                _lastRecordedAt = validatedEvent.recordedAt;
              }
              _locationController.add(validatedEvent);
            } else {
              AppLogger.info(
                  'NativeEventChannelClient: Event parsing failed (returned null)');
            }
          } catch (e) {
            AppLogger.error(
                'NativeEventChannelClient: Malformed event caught in try-catch',
                e);
          }
        } else {
          AppLogger.info('NativeEventChannelClient: Event is not a Map');
        }
      },
      onError: (dynamic error) {
        AppLogger.error(
            'NativeEventChannelClient: Stream error from native', error);
      },
      cancelOnError:
          false, // Ensure stream survives malformed events or temporary errors
    );
  }

  NativeLocationEvent? _parseEvent(Map<String, dynamic> data) {
    try {
      final lat = (data['latitude'] as num?)?.toDouble();
      final lon = (data['longitude'] as num?)?.toDouble();
      final speed = (data['speed'] as num?)?.toDouble() ?? 0.0;
      final bearing = (data['bearing'] as num?)?.toDouble() ?? 0.0;
      final altitude = (data['altitude'] as num?)?.toDouble() ?? 0.0;
      final accuracy = (data['accuracy'] as num?)?.toDouble() ?? 0.0;
      final timestampMs = (data['timestamp'] as num?)?.toInt();

      if (lat == null || lon == null || timestampMs == null) return null;

      final recordedAt =
          DateTime.fromMillisecondsSinceEpoch(timestampMs, isUtc: true);
      final receivedAt = DateTime.now().toUtc(); // Time of receipt in Flutter

      return NativeLocationEvent(
        latitude: lat,
        longitude: lon,
        recordedAt: recordedAt,
        receivedAt: receivedAt,
        speedMetersPerSecond: speed,
        bearingDegrees: bearing,
        altitudeMeters: altitude,
        accuracyMeters: accuracy,
        source: LocationSource.localNative,
        platform: Platform.isIOS ? 'iOS' : 'Android',
        isMock: data['isMock'] == true, // Default to false unless provided by native
        qualityStatus: LocationQualityStatus.valid, // Will be validated later
        metadata: data, // تمرير كامل الـ Map لاستخراج fromEcm وغيرها لاحقاً
      );
    } catch (_) {
      return null;
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stopListening();
    _locationController.close();
  }
}
