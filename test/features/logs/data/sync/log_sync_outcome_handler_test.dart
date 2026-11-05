import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:golden_feather_eld/core/constants/storage_constants.dart';
import 'package:golden_feather_eld/core/events/app_events.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/data/datasources/log_local_data_source.dart';
import 'package:golden_feather_eld/features/logs/data/sync/log_sync_outcome_handler.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/memory_offline_queue.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/sync_verification.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late Box<String> box;
  late LogLocalDataSourceImpl local;
  late AppEventBus bus;
  late List<AppEvent> visibleEvents;
  late StreamSubscription<AppEvent> subscription;
  late LogSyncOutcomeHandler handler;

  const driverId = 101;
  const logId = DailyLogId(42);

  PendingEvent certificationEvent() => PendingEvent(
    id: 'cert-1',
    type: 'certification',
    payload: {'logId': logId.value, 'ownerDriverId': driverId},
    createdAt: DateTime.utc(2026, 10, 1, 8),
  );

  PendingEvent formEvent() => PendingEvent(
    id: 'form-1',
    type: 'daily_log_form',
    payload: {
      'logId': logId.value,
      'ownerDriverId': driverId,
      'form': const {
        'uniqueId': 'veh-1',
        'trailers': ['T1'],
      },
    },
    createdAt: DateTime.utc(2026, 10, 1, 8),
  );

  PendingEvent dutyEdit({String id = 'edit-1'}) => PendingEvent(
    id: id,
    type: 'duty_status',
    payload: {
      'logId': logId.value,
      'statusId': 7,
      'clientId': '7',
      'ownerDriverId': driverId,
    },
    createdAt: DateTime.utc(2026, 10, 1, 8),
  );

  Future<void> seedEvent({String sync = 'PENDING_SYNC'}) async {
    final row = <String, dynamic>{
      'id': 7,
      'status': 'ON',
      'startTime': '2026-10-01T09:00:00.000',
      'duration': 1800,
      'location': 'Dock 4',
      'syncStatus': sync,
    };
    await local.cacheLogEvents(logId, [row]);
    await local.upsertCachedLogEvent(logId, row);
  }

  Future<Map<String, dynamic>> cachedEvent() async =>
      (await local.getCachedLogEvents(logId))!.single;

  Future<void> seed({
    String form = 'INCOMPLETE',
    String cert = 'UNCERTIFIED',
  }) => local.cacheDailyLogs(driverId, [
    {
      'id': logId.value,
      'uniqueId': 'T-1',
      'logDate': '2026-10-01T00:00:00Z',
      'formStatus': form,
      'certificationStatus': cert,
      'isFormComplete': form == 'COMPLETED',
      'isCertified': cert == 'CERTIFIED',
    },
  ]);

  Future<Map<String, dynamic>> cachedRow() async =>
      (await local.getCachedDailyLogs(driverId))!.single;

  Future<void> flushEvents() => Future<void>.delayed(Duration.zero);

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('log_sync_outcome_');
    Hive.init(dir.path);
    box = await Hive.openBox<String>(StorageConstants.dailyLogsCacheBox);
    await Hive.openBox<String>(StorageConstants.eventsBox);
    local = LogLocalDataSourceImpl();
    bus = AppEventBus();
    visibleEvents = [];
    subscription = bus.stream.listen(visibleEvents.add);
    handler = LogSyncOutcomeHandler(local: local, events: bus);
  });

  tearDown(() async {
    await subscription.cancel();
    await Hive.close();
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  group('certification outcome', () {
    test(
      'confirmed only after server isCertified=true → CERTIFIED + UI',
      () async {
        await seed(cert: 'PENDING_SYNC');

        await handler.onVerified(
          VerifiedSyncResult(
            event: certificationEvent(),
            ownerDriverId: driverId,
            verification: SyncVerification.confirmed,
          ),
        );
        await flushEvents();

        final row = await cachedRow();
        expect(row['certificationStatus'], 'CERTIFIED');
        expect(row['isCertified'], isTrue);
        expect(visibleEvents, [AppEvent.logDataChanged]);
      },
    );

    test('retryable keeps PENDING_SYNC and does not rebuild the UI', () async {
      await seed(cert: 'PENDING_SYNC');

      await handler.onVerified(
        VerifiedSyncResult(
          event: certificationEvent(),
          ownerDriverId: driverId,
          verification: SyncVerification.retryable,
        ),
      );
      await flushEvents();

      final row = await cachedRow();
      expect(row['certificationStatus'], 'PENDING_SYNC');
      expect(row['isCertified'], isFalse);
      expect(visibleEvents, isEmpty);
    });

    test('rejected becomes SYNC_FAILED, distinct from PENDING_SYNC', () async {
      await seed(cert: 'PENDING_SYNC');

      await handler.onVerified(
        VerifiedSyncResult(
          event: certificationEvent(),
          ownerDriverId: driverId,
          verification: SyncVerification.rejected,
        ),
      );
      await flushEvents();

      final row = await cachedRow();
      expect(row['certificationStatus'], 'SYNC_FAILED');
      expect(row['isCertified'], isFalse);
      expect(visibleEvents, [AppEvent.logDataChanged]);
    });

    test('dead-lettering also becomes SYNC_FAILED', () async {
      await seed(cert: 'PENDING_SYNC');

      await handler.onDeadLettered(certificationEvent());
      await flushEvents();

      final row = await cachedRow();
      expect(row['certificationStatus'], 'SYNC_FAILED');
      expect(visibleEvents, [AppEvent.logDataChanged]);
    });
  });

  group('daily form outcome', () {
    test('server COMPLETED → COMPLETED + UI', () async {
      await seed(form: 'PENDING_SYNC');

      await handler.onVerified(
        VerifiedSyncResult(
          event: formEvent(),
          ownerDriverId: driverId,
          verification: SyncVerification.confirmed,
          serverData: {
            'data': {'formStatus': 'COMPLETED', 'message': 'Saved'},
          },
        ),
      );
      await flushEvents();

      final row = await cachedRow();
      expect(row['formStatus'], 'COMPLETED');
      expect(row['isFormComplete'], isTrue);
      expect(visibleEvents, [AppEvent.logDataChanged]);
    });

    test('server INCOMPLETE is never promoted to COMPLETED', () async {
      await seed(form: 'PENDING_SYNC');

      await handler.onVerified(
        VerifiedSyncResult(
          event: formEvent(),
          ownerDriverId: driverId,
          verification: SyncVerification.confirmed,
          serverData: {
            'data': {'formStatus': 'INCOMPLETE'},
          },
        ),
      );
      await flushEvents();

      final row = await cachedRow();
      expect(row['formStatus'], 'INCOMPLETE');
      expect(row['isFormComplete'], isFalse);
    });

    test('saved without a completion signal → SAVED_UNCONFIRMED', () async {
      await seed(form: 'PENDING_SYNC');

      await handler.onVerified(
        VerifiedSyncResult(
          event: formEvent(),
          ownerDriverId: driverId,
          verification: SyncVerification.confirmed,
          serverData: {
            'data': {'message': 'Saved'},
          },
        ),
      );
      await flushEvents();

      final row = await cachedRow();
      expect(row['formStatus'], 'SAVED_UNCONFIRMED');
      expect(row['isFormComplete'], isFalse);
      expect(visibleEvents, [AppEvent.logDataChanged]);
    });

    test('rejected keeps the user form data and marks SYNC_FAILED', () async {
      await seed(form: 'PENDING_SYNC');

      await handler.onVerified(
        VerifiedSyncResult(
          event: formEvent(),
          ownerDriverId: driverId,
          verification: SyncVerification.rejected,
          serverData: null,
        ),
      );
      await flushEvents();

      final row = await cachedRow();
      expect(row['formStatus'], 'SYNC_FAILED');
      expect(row['isFormComplete'], isFalse);
      final form = await local.getCachedDailyForm(logId);
      expect(form, isNotNull);
      expect(form!['uniqueId'], 'veh-1');
      expect(form['trailers'], ['T1']);
      expect(visibleEvents, [AppEvent.logDataChanged]);
    });

    test('dead-lettering keeps data and marks SYNC_FAILED', () async {
      await seed(form: 'PENDING_SYNC');

      await handler.onDeadLettered(formEvent());
      await flushEvents();

      final row = await cachedRow();
      expect(row['formStatus'], 'SYNC_FAILED');
      expect(await local.getCachedDailyForm(logId), isNotNull);
      expect(visibleEvents, [AppEvent.logDataChanged]);
    });
  });

  group('duty-status edit outcome', () {
    test('confirmed clears PENDING_SYNC and merges the server echo', () async {
      await seedEvent();

      await handler.onVerified(
        VerifiedSyncResult(
          event: dutyEdit(),
          ownerDriverId: driverId,
          verification: SyncVerification.confirmed,
          serverData: {
            'event': {
              'id': 7,
              'status': 'DRIVING',
              'timeRange': {
                'startTime': '2026-10-01T09:00:00Z',
                'durationSeconds': 1800,
              },
            },
          },
        ),
      );
      await flushEvents();

      final row = await cachedEvent();
      expect(row.containsKey('syncStatus'), isFalse);
      expect(row['status'], 'DRIVING');
      expect(
        row['location'],
        'Dock 4',
        reason: 'the echo omitted location; the user edit must survive',
      );
      expect(visibleEvents, [AppEvent.logDataChanged]);
    });

    test('retryable keeps PENDING_SYNC and does not rebuild the UI', () async {
      await seedEvent();

      await handler.onVerified(
        VerifiedSyncResult(
          event: dutyEdit(),
          ownerDriverId: driverId,
          verification: SyncVerification.retryable,
        ),
      );
      await flushEvents();

      final row = await cachedEvent();
      expect(row['syncStatus'], 'PENDING_SYNC');
      expect(visibleEvents, isEmpty);
    });

    test('rejected becomes SYNC_FAILED and keeps local data', () async {
      await seedEvent();

      await handler.onVerified(
        VerifiedSyncResult(
          event: dutyEdit(),
          ownerDriverId: driverId,
          verification: SyncVerification.rejected,
        ),
      );
      await flushEvents();

      final row = await cachedEvent();
      expect(row['syncStatus'], 'SYNC_FAILED');
      expect(row['location'], 'Dock 4');
      expect(row['duration'], 1800);
      expect(visibleEvents, [AppEvent.logDataChanged]);
    });

    test('dead-lettering becomes SYNC_FAILED', () async {
      await seedEvent();

      await handler.onDeadLettered(dutyEdit());
      await flushEvents();

      final row = await cachedEvent();
      expect(row['syncStatus'], 'SYNC_FAILED');
      expect(visibleEvents, [AppEvent.logDataChanged]);
    });

    test('an older confirmation waits for a newer queued edit', () async {
      final queue = MemoryOfflineQueue(
        now: () => DateTime.utc(2026, 10, 1, 12),
      );
      final first = dutyEdit(id: 'edit-1');
      final second = dutyEdit(id: 'edit-2');
      await queue.enqueue(first);
      await queue.enqueue(second);
      final withQueue = LogSyncOutcomeHandler(
        local: local,
        events: bus,
        queue: queue,
      );
      await seedEvent();

      await withQueue.onVerified(
        VerifiedSyncResult(
          event: first,
          ownerDriverId: driverId,
          verification: SyncVerification.confirmed,
        ),
      );
      await flushEvents();

      expect(
        (await cachedEvent())['syncStatus'],
        'PENDING_SYNC',
        reason: 'the newer edit is still in the queue',
      );
      expect(visibleEvents, isEmpty);

      await queue.removeEvent(first.id);
      await withQueue.onVerified(
        VerifiedSyncResult(
          event: second,
          ownerDriverId: driverId,
          verification: SyncVerification.confirmed,
        ),
      );
      await flushEvents();

      expect((await cachedEvent()).containsKey('syncStatus'), isFalse);
      expect(visibleEvents, [AppEvent.logDataChanged]);
    });
  });

  group('cache survives refresh and restart', () {
    test('a server list refresh cannot erase local PENDING_SYNC', () async {
      await seed(form: 'PENDING_SYNC', cert: 'PENDING_SYNC');

      // الخادم لا يعرف حالة الطابور المحلي؛ صف القائمة يعود قديماً.
      await local.cacheDailyLogs(driverId, [
        {
          'id': logId.value,
          'uniqueId': 'T-1',
          'logDate': '2026-10-01T00:00:00Z',
          'formStatus': 'INCOMPLETE',
          'certificationStatus': 'UNCERTIFIED',
          'isFormComplete': false,
          'isCertified': false,
        },
      ]);

      final row = await cachedRow();
      expect(row['formStatus'], 'PENDING_SYNC');
      expect(row['certificationStatus'], 'PENDING_SYNC');
    });

    test('a server confirmation still wins over the local state', () async {
      await seed(form: 'PENDING_SYNC', cert: 'PENDING_SYNC');

      await local.cacheDailyLogs(driverId, [
        {
          'id': logId.value,
          'uniqueId': 'T-1',
          'logDate': '2026-10-01T00:00:00Z',
          'formStatus': 'COMPLETED',
          'certificationStatus': 'CERTIFIED',
          'isFormComplete': true,
          'isCertified': true,
        },
      ]);

      final row = await cachedRow();
      expect(row['formStatus'], 'COMPLETED');
      expect(row['certificationStatus'], 'CERTIFIED');
    });

    test('SYNC_FAILED is preserved after reopening the cache box', () async {
      await seed(form: 'SYNC_FAILED', cert: 'SYNC_FAILED');
      await box.close();
      box = await Hive.openBox<String>(StorageConstants.dailyLogsCacheBox);

      final row = await cachedRow();
      expect(row['formStatus'], 'SYNC_FAILED');
      expect(row['certificationStatus'], 'SYNC_FAILED');
    });
  });
}
