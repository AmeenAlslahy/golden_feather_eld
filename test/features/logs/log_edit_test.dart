import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/log_edit.dart';

void main() {
  group('statusFromEditValue', () {
    test('maps the five known statuses to app codes', () {
      expect(statusFromEditValue('Off Duty').code, 'OFF');
      expect(statusFromEditValue('Sleeper').code, 'SB');
      expect(statusFromEditValue('Driving').code, 'D');
      expect(statusFromEditValue('On Duty').code, 'ON');
      expect(statusFromEditValue('Personal Use').code, 'PC');
    });

    test('does not invent a code for an unmapped status', () {
      final v = statusFromEditValue('Yard Moves');
      expect(v.code, 'Yard Moves');
      expect(v.arabic, 'Yard Moves');
    });
  });

  group('editValueForStatus', () {
    test('maps stored codes back to form values', () {
      expect(editValueForStatus('OFF'), 'Off Duty');
      expect(editValueForStatus('SB'), 'Sleeper');
      expect(editValueForStatus('D'), 'Driving');
      expect(editValueForStatus('ON'), 'On Duty');
      expect(editValueForStatus('PC'), 'Personal Use');
    });

    test('round trips with statusFromEditValue', () {
      for (final form in [
        'Off Duty',
        'Sleeper',
        'Driving',
        'On Duty',
        'Personal Use'
      ]) {
        expect(editValueForStatus(statusFromEditValue(form).code), form);
      }
    });

    test('passes unknown codes through unchanged', () {
      expect(editValueForStatus('Yard Moves'), 'Yard Moves');
      expect(editValueForStatus(null), 'Sleeper');
    });
  });

  group('parseEditFormTime', () {
    final day = DateTime(2026, 9, 23);

    test('parses 24h HH:mm on the log day', () {
      expect(parseEditFormTime('08:15', day), DateTime(2026, 9, 23, 8, 15));
    });

    test('parses 12h with seconds and AM/PM', () {
      expect(parseEditFormTime('08:15:04 PM', day),
          DateTime(2026, 9, 23, 20, 15, 4));
      expect(parseEditFormTime('12:00 AM', day), DateTime(2026, 9, 23, 0, 0));
      expect(parseEditFormTime('12:00 PM', day), DateTime(2026, 9, 23, 12, 0));
    });

    test('returns null for unparseable input', () {
      expect(parseEditFormTime('', day), isNull);
      expect(parseEditFormTime('25:00', day), isNull);
      expect(parseEditFormTime('9:99', day), isNull);
    });
  });

  test('automatic driving cannot change status or start time', () {
    final event = LogEvent(
      id: '1',
      status: 'D',
      statusArabic: 'قيادة',
      startTime: DateTime(2026, 9, 24, 8),
      duration: const Duration(hours: 1),
      location: '',
      automatedDriving: true,
    );
    expect(
      refuseAutomaticDrivingEdit(
        original: event,
        newStatusCode: 'ON',
        newStart: event.startTime,
      ),
      'automatic_driving',
    );
    expect(
      refuseAutomaticDrivingEdit(
        original: event,
        newStatusCode: 'D',
        newStart: event.startTime,
      ),
      isNull,
    );
  });
}
