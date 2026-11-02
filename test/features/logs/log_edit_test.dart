import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/log_edit.dart';

void main() {
  group('parseEditFormTime', () {
    final day = DateTime(2026, 9, 23);

    test('parses 24h HH:mm on the log day', () {
      expect(parseEditFormTime('08:15', day), DateTime(2026, 9, 23, 8, 15));
    });

    test('parses 12h with seconds and AM/PM', () {
      expect(
        parseEditFormTime('08:15:04 PM', day),
        DateTime(2026, 9, 23, 20, 15, 4),
      );
      expect(parseEditFormTime('12:00 AM', day), DateTime(2026, 9, 23, 0, 0));
      expect(parseEditFormTime('12:00 PM', day), DateTime(2026, 9, 23, 12, 0));
    });

    test('returns null for unparseable input', () {
      expect(parseEditFormTime('', day), isNull);
      expect(parseEditFormTime('25:00', day), isNull);
      expect(parseEditFormTime('9:99', day), isNull);
    });
  });

  group('parseEditFormDuration', () {
    test('parses the editor clock and the display format', () {
      expect(
        parseEditFormDuration('02:30'),
        const Duration(hours: 2, minutes: 30),
      );
      expect(
        parseEditFormDuration('2h 30m'),
        const Duration(hours: 2, minutes: 30),
      );
      expect(parseEditFormDuration('8h'), const Duration(hours: 8));
      expect(parseEditFormDuration('00:00'), Duration.zero);
    });

    test('rejects malformed or out-of-range minutes', () {
      expect(parseEditFormDuration(''), isNull);
      expect(parseEditFormDuration('2:75'), isNull);
      expect(parseEditFormDuration('abc'), isNull);
      expect(parseEditFormDuration('2h 75m'), isNull);
    });
  });

  test('placeholder locations are not real locations', () {
    expect(isPlaceholderLocation('Unknown Location'), isTrue);
    expect(isPlaceholderLocation('unknown'), isTrue);
    expect(isPlaceholderLocation('  '), isTrue);
    expect(isPlaceholderLocation('Dock 4'), isFalse);
    expect(isPlaceholderLocation('Reno, NV'), isFalse);
  });

  test('automatic driving cannot change status or start time', () {
    final event = LogEvent(
      id: '1',
      status: 'D',
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
