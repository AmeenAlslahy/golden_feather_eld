import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/sqlite_offline_queue.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/event_ownership.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/quarantine_record.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────

PendingEvent _event(
  String id,
  String type,
  Map<String, dynamic> payload,
) =>
    PendingEvent(
      id: id,
      type: type,
      payload: payload,
      createdAt: DateTime.utc(2026, 3, 1, 8),
    );

Future<Directory> _tempDir() =>
    Directory.systemTemp.createTemp('queue_ownership_test_');

Future<SQLiteOfflineQueue> _queue(String dir,
    [String name = 'q.db']) async {
  await SQLiteOfflineQueue.resetForTests();
  return SQLiteOfflineQueue(dbPathOverride: p.join(dir, name));
}

Future<int> _pendingCount(SQLiteOfflineQueue q) => q.count;

Future<int> _parkedCount(SQLiteOfflineQueue q) async {
  final d = await q.getDeferred(limit: 1000);
  final quarantined = await q.getQuarantined(limit: 1000);
  return d.length + quarantined.length;
}

void main() {
  group('EventOwnershipResolver (pure, no current user)', () {
    test('PROVEN for documented direct slots', () {
      expect(
        EventOwnershipResolver.resolve(
            _event('1', 'duty_status', {'driverId': 101})).evidence,
        OwnerEvidence.proven,
      );
      expect(
        EventOwnershipResolver.resolve(
            _event('2', 'dvir_create', {'driverId': '202'})).driverId,
        202,
      );
      expect(
        EventOwnershipResolver.resolve(_event('3', 'dvir_review', {
          'dvirId': 7,
          'review': {'reviewingDriverId': 303},
        })).evidence,
        OwnerEvidence.proven,
      );
      expect(
        EventOwnershipResolver.resolve(
            _event('4', 'inspection_transfer', {'driverId': 404})).driverId,
        404,
      );
    });

    test('UNKNOWN for missing/zero/negative/garbage ids', () {
      for (final payload in [
        <String, dynamic>{},
        {'driverId': 0},
        {'driverId': -5},
        {'driverId': 'abc'},
        {'driverId': null},
      ]) {
        expect(
          EventOwnershipResolver.resolve(
                  _event('x', 'duty_status', payload))
              .evidence,
          OwnerEvidence.unknown,
          reason: 'payload $payload',
        );
      }
      // Review id alone is not ownership.
      expect(
        EventOwnershipResolver.resolve(
                _event('x', 'dvir_review', {'dvirId': 7}))
            .evidence,
        OwnerEvidence.unknown,
      );
    });

    test('RECOVERABLE via cache lookup, never auto-PROVEN', () {
      int? lookup(int logId) => logId == 55 ? 101 : null;
      final hit = EventOwnershipResolver.resolve(
        _event('c', 'certification', {'logId': 55}),
        cachedLogOwner: lookup,
      );
      expect(hit.evidence, OwnerEvidence.recoverable);
      expect(hit.driverId, 101);
      expect(hit.isProven, isFalse,
          reason: 'attestation/cache alone must never self-upgrade');

      final miss = EventOwnershipResolver.resolve(
        _event('c', 'certification', {'logId': 56}),
        cachedLogOwner: lookup,
      );
      expect(miss.evidence, OwnerEvidence.unknown);

      final noLookup = EventOwnershipResolver.resolve(
        _event('f', 'daily_log_form', {'logId': 55, 'form': {}}),
      );
      expect(noLookup.evidence, OwnerEvidence.unknown);
    });

    test('unknown types and unidentified design', () {
      expect(
        EventOwnershipResolver.resolve(
                _event('u', 'mystery_type', {'driverId': 101}))
            .evidence,
        OwnerEvidence.unknown,
        reason: 'slots apply per documented type only',
      );
      expect(
        EventOwnershipResolver.resolve(
                _event('u', 'unidentified_driving', {}))
            .evidence,
        OwnerEvidence.unidentifiedByDesign,
      );
    });
  });

  group('SQLiteOfflineQueue ownership storage (real file DB)', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    late Directory dir;
    setUp(() async {
      dir = await _tempDir();
    });
    tearDown(() async {
      await SQLiteOfflineQueue.resetForTests();
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('migration v2→v3 preserves rows and adds quarantine', () async {
      final path = p.join(dir.path, 'legacy.db');
      final v2 = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: (db, version) async {
            await db.execute('''
              CREATE TABLE pending_events (
                id TEXT PRIMARY KEY, type TEXT NOT NULL,
                payload TEXT NOT NULL, createdAt INTEGER NOT NULL,
                priority INTEGER NOT NULL, retryCount INTEGER NOT NULL,
                nextRetryAt INTEGER
              )''');
            await db.execute('''
              CREATE TABLE dead_letters (
                id TEXT PRIMARY KEY, type TEXT NOT NULL,
                payload TEXT NOT NULL, createdAt INTEGER NOT NULL,
                failedAt INTEGER NOT NULL
              )''');
          },
        ),
      );
      await v2.insert('pending_events', {
        'id': 'legacy-1',
        'type': 'certification',
        'payload': '{"logId": 9}',
        'createdAt': 1000,
        'priority': 1,
        'retryCount': 2,
        'nextRetryAt': null,
      });
      await v2.insert('pending_events', {
        'id': 'legacy-2',
        'type': 'duty_status',
        'payload': '{"driverId": 101}',
        'createdAt': 2000,
        'priority': 0,
        'retryCount': 0,
        'nextRetryAt': null,
      });
      await v2.close();

      final q = SQLiteOfflineQueue(dbPathOverride: path);
      expect(await q.count, 2, reason: 'legacy rows survive upgrade');
      final ready = await q.getReadyEvents(limit: 10);
      expect(ready.map((e) => e.id), containsAll(['legacy-1', 'legacy-2']));
      // Quarantine table usable immediately after upgrade.
      await q.moveToQuarantine(
        _event('legacy-1', 'certification', {'logId': 9}),
        reason: 'unknown-owner',
      );
      expect(await q.count, 1);
      final parked = await q.getQuarantined();
      expect(parked, hasLength(1));
      expect(parked.single.event.id, 'legacy-1');
    });

    test('atomic move preserves payload, reason, state, owner', () async {
      final q = await _queue(dir.path);
      final event = _event('e1', 'certification', {'logId': 55});
      await q.enqueue(event);

      await q.moveToQuarantine(event,
          reason: 'unknown-owner', ownerDriverId: null);

      expect(await _pendingCount(q), 0);
      final parked = await q.getQuarantined();
      expect(parked, hasLength(1));
      final record = parked.single;
      expect(record.event.payload, {'logId': 55});
      expect(record.event.id, 'e1');
      expect(record.state, StoredEventState.quarantinedUnknownOwner);
      expect(record.reason, 'unknown-owner');
      expect(record.ownerDriverId, isNull);
      expect(record.proof, OwnershipProof.none);
      // Parked rows are invisible to the dispatch surface (no retry storm).
      expect(await q.getReadyEvents(limit: 10), isEmpty);
    });

    test('restart persistence: new instance on same file recovers rows',
        () async {
      final path = p.join(dir.path, 'restart.db');
      var q = SQLiteOfflineQueue(dbPathOverride: path);
      await q.enqueue(_event('r1', 'duty_status', {'driverId': 101}));
      await q.moveToDeferred(
        _event('r1', 'duty_status', {'driverId': 101}),
        state: StoredEventState.deferredOwnerMismatch,
        reason: 'owner-mismatch',
        ownerDriverId: 101,
      );
      await SQLiteOfflineQueue.resetForTests();

      q = SQLiteOfflineQueue(dbPathOverride: path);
      final deferred = await q.getDeferred();
      expect(deferred, hasLength(1));
      expect(deferred.single.ownerDriverId, 101);
      expect(deferred.single.state,
          StoredEventState.deferredOwnerMismatch);
      expect(await q.count, 0);
    });

    test('repeated moves are idempotent, counts invariant', () async {
      final q = await _queue(dir.path);
      final event = _event('dup', 'duty_status', {'driverId': 7});
      await q.enqueue(event);

      await q.moveToQuarantine(event, reason: 'a');
      await q.moveToQuarantine(event, reason: 'b');
      expect(await q.getQuarantined(), hasLength(1));
      expect(await _pendingCount(q), 0);

      await q.moveToDeferred(
        event,
        state: StoredEventState.deferredUnauthenticated,
        reason: 'c',
      );
      expect(await q.getQuarantined(), isEmpty);
      expect(await q.getDeferred(), hasLength(1));
      expect(await _parkedCount(q), 1,
          reason: 'exactly one parked row across repeated moves');

      await q.releaseToPending('dup');
      expect(await _pendingCount(q), 1);
      expect(await _parkedCount(q), 0);
      final back = await q.getReadyEvents(limit: 10);
      expect(back.single.payload, {'driverId': 7});
    });

    test('move of unknown id is a safe no-op for pending', () async {
      final q = await _queue(dir.path);
      await q.enqueue(_event('kept', 'duty_status', {'driverId': 1}));
      await q.releaseToPending('no-such-id');
      expect(await _pendingCount(q), 1);
      expect(await _parkedCount(q), 0);
    });

    test('UNKNOWN_OWNER remains preserved with original data', () async {
      final q = await _queue(dir.path);
      final payload = {
        'logId': 999,
        'logDate': '2026-03-01',
        'signatureCertificateId': 'sig',
        'signatureConfirmation': true,
        'certifiedTrue': true,
      };
      await q.enqueue(_event('old-cert', 'certification', payload));
      await q.moveToQuarantine(
        _event('old-cert', 'certification', payload),
        reason: 'unknown-owner',
      );

      final parked = await q.getQuarantined();
      expect(parked, hasLength(1));
      expect(parked.single.event.payload, payload);
      expect(parked.single.ownerDriverId, isNull);
      // Still there after reopen — never silently dropped.
      await SQLiteOfflineQueue.resetForTests();
      final q2 = SQLiteOfflineQueue(
          dbPathOverride: p.join(dir.path, 'q.db'));
      expect((await q2.getQuarantined()).single.event.id, 'old-cert');
    });
  });
}
