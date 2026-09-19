import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/services/event_log_service.dart';
import 'package:golden_feather_eld/core/time/fake_time_authority.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // Reset SharedPreferences before each test.
    SharedPreferences.setMockInitialValues({});
  });

  group('EventLogService.logEvent', () {
    test('uses TimeAuthority for timestamp', () async {
      final clock = FakeTimeAuthority(
        initialTime: DateTime.utc(2026, 1, 15, 10),
      );
      final service = EventLogService(timeAuthority: clock);
      await service.init();

      await service.logEvent('test', {'key': 'value'});

      final events = service.allEvents;
      expect(events, hasLength(1));
      expect(events.first.timestamp, DateTime.utc(2026, 1, 15, 10));
    });

    test('uses TimeAuthority for id', () async {
      final clock = FakeTimeAuthority(
        initialTime: DateTime.utc(2026, 1, 15, 10),
      );
      final service = EventLogService(timeAuthority: clock);
      await service.init();

      await service.logEvent('test', {});

      final event = service.allEvents.first;
      expect(event.id, DateTime.utc(2026, 1, 15, 10).millisecondsSinceEpoch.toString());
    });

    test('respects clock advance between events', () async {
      final clock = FakeTimeAuthority(
        initialTime: DateTime.utc(2026, 1, 15, 10),
      );
      final service = EventLogService(timeAuthority: clock);
      await service.init();

      await service.logEvent('first', {});
      clock.advance(const Duration(hours: 1));
      await service.logEvent('second', {});

      final events = service.allEvents;
      expect(events, hasLength(2));
      expect(
        events[1].timestamp.difference(events[0].timestamp),
        const Duration(hours: 1),
      );
    });
  });

  group('EventLogService.getTodayEvents', () {
    test('returns events from current UTC day', () async {
      final clock = FakeTimeAuthority(
        initialTime: DateTime.utc(2026, 1, 15, 10),
      );
      final service = EventLogService(timeAuthority: clock);
      await service.init();

      await service.logEvent('today', {});

      final today = service.getTodayEvents();
      expect(today, hasLength(1));
    });

    test('excludes events from previous day', () async {
      final clock = FakeTimeAuthority(
        initialTime: DateTime.utc(2026, 1, 15, 10),
      );
      final service = EventLogService(timeAuthority: clock);
      await service.init();

      // Log an event, then advance to next day.
      await service.logEvent('yesterday', {});

      clock.setTime(DateTime.utc(2026, 1, 16, 10));

      final today = service.getTodayEvents();
      expect(today, isEmpty);
    });

    test('uses UTC midnight as day boundary', () async {
      final clock = FakeTimeAuthority(
        initialTime: DateTime.utc(2026, 1, 15, 23, 59),
      );
      final service = EventLogService(timeAuthority: clock);
      await service.init();

      await service.logEvent('late', {});

      clock.setTime(DateTime.utc(2026, 1, 16, 0, 1));

      final today = service.getTodayEvents();
      expect(today, isEmpty, reason: 'Event was on previous UTC day');
    });

    test('includes event right at UTC midnight', () async {
      final clock = FakeTimeAuthority(
        initialTime: DateTime.utc(2026, 1, 15, 0, 0),
      );
      final service = EventLogService(timeAuthority: clock);
      await service.init();

      await service.logEvent('midnight', {});

      final today = service.getTodayEvents();
      expect(today, hasLength(1));
    });
  });

  group('EventLogService — persistence', () {
    test('persists events to storage', () async {
      final clock = FakeTimeAuthority(
        initialTime: DateTime.utc(2026, 1, 15, 10),
      );
      final service = EventLogService(timeAuthority: clock);
      await service.init();

      await service.logEvent('persisted', {'k': 'v'});

      // New service, same storage.
      final service2 = EventLogService(timeAuthority: clock);
      await service2.init();

      expect(service2.allEvents, hasLength(1));
      expect(service2.allEvents.first.type, 'persisted');
    });
  });
}
