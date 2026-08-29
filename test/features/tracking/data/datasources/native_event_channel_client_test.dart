import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/tracking/domain/entities/native_location_event.dart';
import 'package:golden_feather_eld/features/tracking/data/datasources/native_event_channel_client.dart';

void main() {
  group('NativeLocationQualityValidator', () {
    late NativeLocationQualityValidator validator;

    setUp(() {
      validator = NativeLocationQualityValidator();
    });

    test('valid location is marked valid', () {
      final now = DateTime.now().toUtc();
      final event = NativeLocationEvent(
        latitude: 24.0,
        longitude: 46.0,
        recordedAt: now,
        receivedAt: now,
        speedMetersPerSecond: 15.0,
        bearingDegrees: 90.0,
        altitudeMeters: 100.0,
        accuracyMeters: 5.0,
        source: LocationSource.localNative,
        platform: 'Android',
        isMock: false,
        qualityStatus: LocationQualityStatus.valid,
      );

      final validated = validator.validate(event, null);
      expect(validated.qualityStatus, LocationQualityStatus.valid);
    });

    test('invalid latitude is marked invalid', () {
      final now = DateTime.now().toUtc();
      final event = NativeLocationEvent(
        latitude: 100.0, // Invalid
        longitude: 46.0,
        recordedAt: now,
        receivedAt: now,
        speedMetersPerSecond: 15.0,
        bearingDegrees: 90.0,
        altitudeMeters: 100.0,
        accuracyMeters: 5.0,
        source: LocationSource.localNative,
        platform: 'Android',
        isMock: false,
        qualityStatus: LocationQualityStatus.valid,
      );

      final validated = validator.validate(event, null);
      expect(validated.qualityStatus, LocationQualityStatus.invalid);
    });

    test('stale location is marked stale', () {
      final now = DateTime.now().toUtc();
      final event = NativeLocationEvent(
        latitude: 24.0,
        longitude: 46.0,
        recordedAt: now.subtract(const Duration(hours: 2)), // 2 hours old
        receivedAt: now,
        speedMetersPerSecond: 15.0,
        bearingDegrees: 90.0,
        altitudeMeters: 100.0,
        accuracyMeters: 5.0,
        source: LocationSource.localNative,
        platform: 'Android',
        isMock: false,
        qualityStatus: LocationQualityStatus.valid,
      );

      final validated = validator.validate(event, null);
      expect(validated.qualityStatus, LocationQualityStatus.stale);
    });

    test('out of order location is marked outOfOrder', () {
      final now = DateTime.now().toUtc();
      final event = NativeLocationEvent(
        latitude: 24.0,
        longitude: 46.0,
        recordedAt: now.subtract(const Duration(seconds: 10)),
        receivedAt: now,
        speedMetersPerSecond: 15.0,
        bearingDegrees: 90.0,
        altitudeMeters: 100.0,
        accuracyMeters: 5.0,
        source: LocationSource.localNative,
        platform: 'Android',
        isMock: false,
        qualityStatus: LocationQualityStatus.valid,
      );

      final lastRecordedAt = now.subtract(const Duration(seconds: 5)); // Newer than event

      final validated = validator.validate(event, lastRecordedAt);
      expect(validated.qualityStatus, LocationQualityStatus.outOfOrder);
    });
  });
}
