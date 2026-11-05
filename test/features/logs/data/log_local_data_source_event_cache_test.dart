import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:golden_feather_eld/core/constants/storage_constants.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/data/datasources/log_local_data_source.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const logId = DailyLogId(42);
  final oldDay = DateTime(2026, 9, 23);
  final newDay = DateTime(2026, 9, 24);

  late Directory dir;
  late LogLocalDataSourceImpl local;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('event_cache_');
    Hive.init(dir.path);
    await Hive.openBox<String>(StorageConstants.dailyLogsCacheBox);
    await Hive.openBox<String>(StorageConstants.eventsBox);
    local = LogLocalDataSourceImpl();
  });

  tearDown(() async {
    await Hive.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test(
    'upsert updates the log snapshot and moves the local day entry',
    () async {
      await local.cacheLogEvents(logId, [
        {
          'id': 7,
          'status': 'ON_DUTY',
          'timeRange': {
            'startTime': '2026-09-23T22:00:00Z',
            'durationSeconds': 3600,
          },
          'location': {'description': 'Dock 4'},
        },
      ]);
      await local.addEvent(
        LogEvent(
          id: '7',
          status: 'ON',
          startTime: oldDay.add(const Duration(hours: 22)),
          duration: const Duration(hours: 1),
          location: 'Dock 4',
        ),
      );

      await local.upsertCachedLogEvent(logId, {
        'id': 7,
        'status': 'ON',
        'startTime': newDay
            .add(const Duration(hours: 22, minutes: 30))
            .toIso8601String(),
        'duration': 9000,
        'location': 'Dock 4',
      });

      final cached = (await local.getCachedLogEvents(logId))!.single;
      expect(cached['startTime'], contains('2026-09-24T22:30'));
      expect(cached['duration'], 9000);
      expect(cached['location'], 'Dock 4');

      expect(
        await local.getEvents(oldDay),
        isEmpty,
        reason: 'the old day must not keep a duplicate of the moved event',
      );
      final moved = (await local.getEvents(newDay)).single;
      expect(moved.id, '7');
      expect(
        moved.startTime,
        newDay.add(const Duration(hours: 22, minutes: 30)),
      );
      expect(moved.duration, const Duration(hours: 2, minutes: 30));
    },
  );

  test(
    'sync status round-trips through the snapshot and the day box',
    () async {
      await local.cacheLogEvents(logId, [
        {
          'id': 7,
          'status': 'ON',
          'startTime': '2026-09-24T09:00:00.000',
          'duration': 1800,
          'location': 'Dock 4',
          'syncStatus': 'PENDING_SYNC',
        },
      ]);

      final pending = (await local.getCachedLogEvents(logId))!.single;
      expect(pending['syncStatus'], 'PENDING_SYNC');

      // التعديل الأوفلاين يكتب أيضاً في صندوق الأحداث المحلي.
      await local.upsertCachedLogEvent(logId, pending);
      final localEvent = (await local.getEvents(newDay)).single;
      expect(localEvent.id, '7');
      expect(localEvent.syncStatus, EventSyncStatus.pendingSync);

      await local.setCachedEventSyncStatus(
        logId: logId,
        eventId: '7',
        status: EventSyncStatus.none,
      );

      final cleared = (await local.getCachedLogEvents(logId))!.single;
      expect(cleared.containsKey('syncStatus'), isFalse);
      expect(
        (await local.getEvents(newDay)).single.syncStatus,
        EventSyncStatus.none,
        reason: 'the badge must not survive the server confirmation',
      );
    },
  );

  test(
    'sync failure is distinct from pending and keeps the user edit',
    () async {
      await local.cacheLogEvents(logId, [
        {
          'id': 7,
          'status': 'ON',
          'startTime': '2026-09-24T09:00:00.000',
          'duration': 1800,
          'location': 'Dock 4',
          'syncStatus': 'PENDING_SYNC',
        },
      ]);

      await local.setCachedEventSyncStatus(
        logId: logId,
        eventId: '7',
        status: EventSyncStatus.syncFailed,
      );

      final row = (await local.getCachedLogEvents(logId))!.single;
      expect(row['syncStatus'], 'SYNC_FAILED');
      expect(row['location'], 'Dock 4');
      expect(row['duration'], 1800);
    },
  );

  test('upsert replaces only the edited event in the log snapshot', () async {
    await local.cacheLogEvents(logId, [
      {'id': 1, 'status': 'OFF_DUTY', 'startTime': '2026-09-24T00:00:00Z'},
      {'id': 2, 'status': 'DRIVING', 'startTime': '2026-09-24T08:00:00Z'},
    ]);

    await local.upsertCachedLogEvent(logId, {
      'id': 2,
      'status': 'ON',
      'startTime': '2026-09-24T09:00:00Z',
      'duration': 1800,
      'location': 'Yard',
    });

    final cached = (await local.getCachedLogEvents(logId))!;
    expect(cached, hasLength(2));
    expect(cached.first['id'].toString(), '1');
    expect(cached.last['id'], '2');
    expect(cached.last['status'], 'ON');
    expect(cached.last['location'], 'Yard');
  });
}
