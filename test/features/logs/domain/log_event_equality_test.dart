import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';

void main() {
  LogEvent baseEvent() => LogEvent(
        id: 'ev-1',
        status: 'D',
        startTime: DateTime(2026, 1, 5, 8, 30),
        duration: const Duration(hours: 2),
        location: 'Riyadh, SA',
      );

  group('LogEvent equality', () {
    test('identical values are equal', () {
      expect(baseEvent(), baseEvent());
    });

    test('odometer and engineHours participate in equality', () {
      final withOdometer = baseEvent().copyWith(odometer: 1234.5);
      final withEngineHours = baseEvent().copyWith(engineHours: 99.25);

      expect(withOdometer, isNot(baseEvent()));
      expect(withEngineHours, isNot(baseEvent()));
      expect(withOdometer, isNot(withEngineHours));
    });

    test('automatedDriving and editable participate in equality', () {
      expect(baseEvent().copyWith(automatedDriving: true), isNot(baseEvent()));
      expect(baseEvent().copyWith(editable: false), isNot(baseEvent()));
    });

    test('startedOnPreviousDay participates in equality', () {
      expect(
        baseEvent().copyWith(startedOnPreviousDay: true),
        isNot(baseEvent()),
      );
    });

    test('copyWith keeps untouched nullable fields', () {
      final event = baseEvent().copyWith(
        odometer: 10,
        engineHours: 5,
        automatedDriving: false,
        editable: true,
        startedOnPreviousDay: true,
      );

      final expanded = event.copyWith(isExpanded: true);

      expect(expanded.odometer, 10);
      expect(expanded.engineHours, 5);
      expect(expanded.automatedDriving, false);
      expect(expanded.editable, true);
      expect(expanded.startedOnPreviousDay, true);
    });
  });
}
