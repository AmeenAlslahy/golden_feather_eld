import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/data/models/log_model.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/edit_log_form_provider.dart';

void main() {
  group('LogEvent Coordinates Tests', () {
    test(
      'fromJson with location map extracts originalLatitude and originalLongitude',
      () {
        final json = {
          'id': 'ev-1',
          'status': 'ON',
          'startTime': '2026-03-01T08:00:00Z',
          'durationSeconds': 3600,
          'location': {
            'description': 'Dallas',
            'latitude': 32.77,
            'longitude': -96.79,
          },
        };

        final model = LogEventModel.fromJson(json);

        expect(model.location, 'Dallas');
        expect(model.originalLatitude, 32.77);
        expect(model.originalLongitude, -96.79);
      },
    );

    test('fromJson with flat string location leaves coordinates as null', () {
      final json = {
        'id': 'ev-2',
        'status': 'OFF',
        'startTime': '2026-03-01T08:00:00Z',
        'durationSeconds': 1800,
        'location': 'Dallas',
      };

      final model = LogEventModel.fromJson(json);

      expect(model.location, 'Dallas');
      expect(model.originalLatitude, isNull);
      expect(model.originalLongitude, isNull);
    });

    test(
      'fromJson with top-level latitude and longitude (no location object) extracts coordinates',
      () {
        final json = {
          'id': 'ev-3',
          'status': 'D',
          'startTime': '2026-03-01T08:00:00Z',
          'durationSeconds': 7200,
          'latitude': 32.77,
          'longitude': -96.79,
        };

        final model = LogEventModel.fromJson(json);

        expect(model.originalLatitude, 32.77);
        expect(model.originalLongitude, -96.79);
      },
    );

    test('copyWith changing status does NOT change originalLatitude', () {
      final event = LogEvent(
        id: 'ev-4',
        status: 'ON',
        startTime: DateTime.utc(2026, 3, 1, 8, 0),
        duration: const Duration(hours: 1),
        location: 'Dallas',
        originalLatitude: 32.77,
        originalLongitude: -96.79,
      );

      final updated = event.copyWith(status: 'OFF');

      expect(updated.status, 'OFF');
      expect(updated.originalLatitude, 32.77);
      expect(updated.originalLongitude, -96.79);
    });

    test(
      'EditLogFormState with originalLatitude: 32.77 — copyWith(selectedStatus: "OFF") preserves coordinates',
      () {
        final form = EditLogFormState(
          selectedStatus: 'ON',
          startTime: '08:00',
          duration: '01:00',
          originalLocation: 'Dallas',
          originalLatitude: 32.77,
          originalLongitude: -96.79,
        );

        final updated = form.copyWith(selectedStatus: 'OFF');

        expect(updated.selectedStatus, 'OFF');
        expect(updated.originalLatitude, 32.77);
        expect(updated.originalLongitude, -96.79);
      },
    );

    test(
      'toJson roundtrip: fromJson(model.toJson()) preserves originalLatitude when non-null',
      () {
        final model = LogEventModel(
          id: 'ev-5',
          status: 'ON',
          startTime: DateTime.utc(2026, 3, 1, 8, 0),
          duration: const Duration(hours: 1),
          location: 'Dallas',
          originalLatitude: 32.77,
          originalLongitude: -96.79,
        );

        final json = model.toJson();
        expect(json['originalLatitude'], 32.77);
        expect(json['originalLongitude'], -96.79);

        final roundtrip = LogEventModel.fromJson(json);
        expect(roundtrip.originalLatitude, 32.77);
        expect(roundtrip.originalLongitude, -96.79);
      },
    );

    test('fromEntity preserves originalLatitude and originalLongitude', () {
      final entity = LogEvent(
        id: 'ev-6',
        status: 'SB',
        startTime: DateTime.utc(2026, 3, 1, 8, 0),
        duration: const Duration(hours: 2),
        location: 'Fort Worth',
        originalLatitude: 32.75,
        originalLongitude: -97.33,
      );

      final model = LogEventModel.fromEntity(entity);

      expect(model.originalLatitude, 32.75);
      expect(model.originalLongitude, -97.33);
    });
  });
}
