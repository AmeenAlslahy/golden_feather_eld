import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/data/models/log_model.dart';

/// SRS 5.2 — the Events tab and the 24-hour Graph-Grid are fed by
/// `GET /eld/daily-logs/{id}/graph-grid`. Its `GraphGridEvent` wire shape
/// (status enum names, `durationMinutes`, `odometerKm`, `origin`) must map to
/// the short codes / Duration / miles the UI and the painter expect.
/// Before this fix `DRIVING` fell back to OFF and durations were 0, which is
/// why the graph rendered as a flat line.
void main() {
  group('LogEventModel.fromJson — GraphGridEvent wire format', () {
    test('maps DRIVING + durationMinutes + odometerKm + origin', () {
      final e = LogEventModel.fromJson(const {
        'id': 9105,
        'status': 'DRIVING',
        'startTime': '2026-09-24T08:15:00Z',
        'durationMinutes': 95,
        'location': 'I-80, Reno NV',
        'odometerKm': 100.0,
        'engineHours': 12.5,
        'origin': 'AUTOMATIC',
        'editable': false,
      });

      expect(e.id, '9105');
      expect(e.status, 'D');
      expect(e.duration, const Duration(minutes: 95));
      expect(e.startTime.toUtc(), DateTime.utc(2026, 9, 24, 8, 15));
      expect(e.location, 'I-80, Reno NV');
      expect(e.odometer, closeTo(62.137, 0.01)); // km → miles
      expect(e.engineHours, 12.5);
      expect(e.automatedDriving, isTrue);
      expect(e.editable, isFalse);
    });

    test('maps every wire status to its short code', () {
      String code(String wire) =>
          LogEventModel.fromJson(<String, dynamic>{'status': wire, 'durationMinutes': 1}).status;
      expect(code('OFF_DUTY'), 'OFF');
      expect(code('SLEEPER'), 'SB');
      expect(code('DRIVING'), 'D');
      expect(code('ON_DUTY'), 'ON');
      expect(code('YARD_MOVE'), 'YM');
      expect(code('PERSONAL_CONVEYANCE'), 'PC');
    });

    test('DRIVER origin is not automated driving; locationText accepted', () {
      final e = LogEventModel.fromJson(const {
        'id': 1,
        'status': 'ON_DUTY',
        'startTime': '2026-09-24T06:00:00Z',
        'durationMinutes': 30,
        'locationText': 'Yard 3',
        'origin': 'DRIVER',
      });
      expect(e.automatedDriving, isFalse);
      expect(e.location, 'Yard 3');
    });
  });

  group('LogEventModel.fromJson — local (toJson) shape still round-trips', () {
    test('short code + duration seconds + odometer miles', () {
      final original = LogEventModel(
        id: 'local-1',
        status: 'SB',
        statusArabic: 'النوم',
        startTime: DateTime(2026, 9, 24, 22, 0),
        duration: const Duration(hours: 8),
        location: 'Truck stop',
        odometer: 123.4,
      );
      final parsed = LogEventModel.fromJson(original.toJson());
      expect(parsed.status, 'SB');
      expect(parsed.duration, const Duration(hours: 8));
      expect(parsed.odometer, 123.4);
      expect(parsed.location, 'Truck stop');
    });
  });
}
