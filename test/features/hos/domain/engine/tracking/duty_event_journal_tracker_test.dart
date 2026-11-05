import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/contracts/status_dashboard_backend.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/tracking/duty_status_tracker.dart';
import 'package:golden_feather_eld/features/hos/domain/repositories/duty_period_store.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/sqlite_duty_event_journal.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/sqlite_offline_queue.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/dispatch_auth.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/duty_event_record.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/domain/repositories/duty_event_journal.dart';
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P1.1 duty event journal', () {
    setUpAll(() {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    });

    late Directory dir;
    late String dbPath;
    late SQLiteOfflineQueue queue;
    late SqliteDutyEventJournal journal;
    final trackers = <DutyStatusTracker>[];

    setUp(() async {
      await SQLiteOfflineQueue.resetForTests();
      dir = await Directory.systemTemp.createTemp('duty_journal');
      dbPath = p.join(dir.path, 'offline_queue.db');
      queue = SQLiteOfflineQueue(dbPathOverride: dbPath);
      journal = SqliteDutyEventJournal(() => queue.database);
    });

    tearDown(() async {
      for (final tracker in trackers) {
        tracker.dispose();
      }
      trackers.clear();
      await SQLiteOfflineQueue.resetForTests();
      try {
        await dir.delete(recursive: true);
      } catch (_) {}
    });

    DutyStatusTracker buildTracker({
      required SQLiteOfflineQueue queue,
      required DutyEventJournal journal,
      required FakeTrustedTimeProvider clock,
      required _TestStorage storage,
      _TestSyncEngine? sync,
    }) {
      final tracker = DutyStatusTracker(
        dutyPeriodStore: _TestDutyPeriodStore(),
        localStorage: storage,
        syncEngine: sync ?? _TestSyncEngine(),
        dashboardBackend: _TestDashboardBackend(),
        timeProvider: clock,
        readDriverId: () => 106,
        journal: journal,
      );
      trackers.add(tracker);
      return tracker;
    }

    test(
      'T1 restart keeps the open driving segment and closes it after replay',
      () async {
        final clock = FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 3, 1, 8),
        );
        final storage = _TestStorage();
        final tracker = buildTracker(
          queue: queue,
          journal: journal,
          clock: clock,
          storage: storage,
        );

        await tracker.hydrateForDriver(106);
        expect(tracker.isHydrated, isTrue);
        expect(tracker.manualTransition('driving'), isNull);
        await tracker.persistenceIdle;

        expect(tracker.currentStatus, 'driving');
        expect(await queue.count, 1);
        final firstRows = await (await queue.database).query(
          SQLiteOfflineQueue.journalTable,
        );
        expect(firstRows, hasLength(1));

        // Restart: close the shared connection and reopen the same file.
        tracker.dispose();
        trackers.remove(tracker);
        await SQLiteOfflineQueue.resetForTests();
        queue = SQLiteOfflineQueue(dbPathOverride: dbPath);
        journal = SqliteDutyEventJournal(() => queue.database);

        clock.advance(const Duration(minutes: 1));
        final restarted = buildTracker(
          queue: queue,
          journal: journal,
          clock: clock,
          storage: _TestStorage(storage.data),
        );
        await restarted.hydrateForDriver(106);

        expect(restarted.isHydrated, isTrue);
        expect(restarted.currentStatus, 'driving');
        expect(restarted.events, hasLength(1));
        expect(
          restarted.periods,
          isEmpty,
          reason: 'the open segment must not be fabricated as a closed period',
        );

        expect(restarted.manualTransition('on_duty'), isNull);
        await restarted.persistenceIdle;

        expect(restarted.periods, hasLength(1));
        final period = restarted.periods.single;
        expect(period.status, 'driving');
        expect(period.startTime, DateTime.utc(2026, 3, 1, 8));
        expect(period.endTime, DateTime.utc(2026, 3, 1, 8, 1));
        expect(await queue.count, 2);
      },
    );

    test('T2 restart while on_duty keeps the open on-duty period', () async {
      await journal.append(
        _record(id: 'off', status: 'off_duty', at: DateTime.utc(2026, 3, 1, 8)),
      );
      await journal.append(
        _record(id: 'on', status: 'on_duty', at: DateTime.utc(2026, 3, 1, 9)),
      );
      final tracker = buildTracker(
        queue: queue,
        journal: journal,
        clock: FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 3, 1, 9, 30),
        ),
        storage: _TestStorage(),
      );

      await tracker.hydrateForDriver(106);

      expect(tracker.isHydrated, isTrue);
      expect(tracker.currentStatus, 'on_duty');
      expect(tracker.events, hasLength(2));
      expect(tracker.events.last.timestamp, DateTime.utc(2026, 3, 1, 9));
      expect(tracker.periods, hasLength(1));
      expect(tracker.periods.single.status, 'off_duty');
      expect(tracker.periods.single.startTime, DateTime.utc(2026, 3, 1, 8));
      expect(tracker.periods.single.endTime, DateTime.utc(2026, 3, 1, 9));
    });

    test(
      'T3 restart while sleeper preserves it and invents no driving',
      () async {
        await journal.append(
          _record(
            id: 'sleeper',
            status: 'sleeper_berth',
            at: DateTime.utc(2026, 3, 1, 8),
          ),
        );
        final tracker = buildTracker(
          queue: queue,
          journal: journal,
          clock: FakeTrustedTimeProvider(
            initialUtcTime: DateTime.utc(2026, 3, 1, 9),
          ),
          storage: _TestStorage(),
        );

        await tracker.hydrateForDriver(106);

        expect(tracker.currentStatus, 'sleeper_berth');
        expect(tracker.events, hasLength(1));
        expect(
          tracker.events.where((e) => e.status == 'driving'),
          isEmpty,
          reason: 'replay must not invent driving from an idle segment',
        );
        expect(tracker.periods, isEmpty);
      },
    );

    test(
      'T3 absent trusted time is journaled but never applied or queued',
      () async {
        final clock = FakeTrustedTimeProvider();
        final storage = _TestStorage();
        final tracker = buildTracker(
          queue: queue,
          journal: journal,
          clock: clock,
          storage: storage,
        );
        await tracker.hydrateForDriver(106);

        final start = DateTime.utc(2026, 3, 1, 8);
        for (var i = 0; i < 3; i++) {
          await tracker.processEldEvent(
            EldEvent(
              fromEcm: true,
              speedMph: 10,
              odometerMiles: 10,
              engineHours: 1,
              timestamp: start.add(Duration(seconds: i * 2)),
            ),
          );
        }

        expect(tracker.currentStatus, 'off_duty');
        expect(tracker.events, isEmpty);
        expect(await queue.count, 0);

        final load = await journal.load(ownerDriverId: 106);
        expect(load.records, hasLength(1));
        final intent = load.records.single;
        expect(intent.syncState, DutyEventSyncState.pendingReview);
        expect(intent.eventTimeUtc, isNull);
        expect(intent.timeConfidence, DutyTimeConfidence.untrusted);

        await SQLiteOfflineQueue.resetForTests();
        queue = SQLiteOfflineQueue(dbPathOverride: dbPath);
        journal = SqliteDutyEventJournal(() => queue.database);
        final restarted = buildTracker(
          queue: queue,
          journal: journal,
          clock: clock,
          storage: _TestStorage(storage.data),
        );
        await restarted.hydrateForDriver(106);
        expect(restarted.currentStatus, 'off_duty');
        expect(
          restarted.events,
          isEmpty,
          reason: 'pendingReview evidence must never become a legal HOS event',
        );
      },
    );

    test('T4 replay is ordered by event time, not insertion order', () async {
      await journal.append(
        _record(
          id: 'later',
          status: 'on_duty',
          at: DateTime.utc(2026, 3, 1, 9),
        ),
      );
      await journal.append(
        _record(
          id: 'earlier',
          status: 'driving',
          at: DateTime.utc(2026, 3, 1, 8),
        ),
      );

      final tracker = buildTracker(
        queue: queue,
        journal: journal,
        clock: FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 3, 1, 10),
        ),
        storage: _TestStorage(),
      );
      await tracker.hydrateForDriver(106);

      expect(tracker.currentStatus, 'on_duty');
      expect(tracker.events.map((e) => e.status), ['driving', 'on_duty']);
      expect(tracker.periods, hasLength(1));
      expect(tracker.periods.single.startTime, DateTime.utc(2026, 3, 1, 8));
      expect(tracker.periods.single.endTime, DateTime.utc(2026, 3, 1, 9));
    });

    test('T12 failed journal+queue transaction rolls both rows back', () async {
      final record = _record(
        id: 'rollback-1',
        status: 'driving',
        at: DateTime.utc(2026, 3, 1, 8),
      );
      final unencodable = PendingEvent(
        id: 'rollback-1',
        type: 'duty_status',
        payload: {'bad': () {}},
        createdAt: DateTime.utc(2026, 3, 1, 8),
      );

      await expectLater(
        journal.append(record, syncEvent: unencodable),
        throwsA(anything),
      );

      final db = await queue.database;
      expect(await db.query(SQLiteOfflineQueue.journalTable), isEmpty);
      expect(await queue.count, 0);
    });

    test(
      'T12b failed append leaves tracker state and stream unchanged',
      () async {
        final tracker = DutyStatusTracker(
          dutyPeriodStore: _TestDutyPeriodStore(),
          localStorage: _TestStorage(),
          syncEngine: _TestSyncEngine(),
          dashboardBackend: _TestDashboardBackend(),
          timeProvider: FakeTrustedTimeProvider(
            initialUtcTime: DateTime.utc(2026, 3, 1, 8),
          ),
          readDriverId: () => 106,
          journal: _ThrowingJournal(),
        );
        trackers.add(tracker);
        await tracker.hydrateForDriver(106);

        final transitions = <DutyTransition>[];
        final sub = tracker.onTransition.listen(transitions.add);
        addTearDown(sub.cancel);

        expect(tracker.manualTransition('driving'), isNull);
        await tracker.persistenceIdle;

        expect(tracker.currentStatus, 'off_duty');
        expect(tracker.events, isEmpty);
        expect(tracker.periods, isEmpty);
        expect(transitions, isEmpty);
      },
    );

    test(
      'T13 duplicate journal rows replay exactly once across restarts',
      () async {
        final driving = _record(
          id: 'same-id',
          status: 'driving',
          at: DateTime.utc(2026, 3, 1, 8),
        );
        await journal.append(driving);
        await journal.append(
          _record(
            id: 'second',
            status: 'on_duty',
            at: DateTime.utc(2026, 3, 1, 9),
          ),
        );
        await journal.append(
          _record(
            id: 'same-id',
            status: 'sleeper_berth',
            at: DateTime.utc(2026, 3, 1, 8),
          ),
        );

        final load = await journal.load(ownerDriverId: 106);
        expect(load.records, hasLength(2));
        expect(
          load.records.first.status,
          'driving',
          reason: 'the first evidence row is immutable',
        );

        final first = buildTracker(
          queue: queue,
          journal: journal,
          clock: FakeTrustedTimeProvider(
            initialUtcTime: DateTime.utc(2026, 3, 1, 10),
          ),
          storage: _TestStorage(),
        );
        await first.hydrateForDriver(106);
        await first.hydrateForDriver(106);

        expect(first.events, hasLength(2));
        expect(first.periods, hasLength(1));
        expect(first.currentStatus, 'on_duty');

        final second = buildTracker(
          queue: queue,
          journal: journal,
          clock: FakeTrustedTimeProvider(
            initialUtcTime: DateTime.utc(2026, 3, 1, 10),
          ),
          storage: _TestStorage(),
        );
        await second.hydrateForDriver(106);
        expect(second.events, hasLength(2));
        expect(second.periods, hasLength(1));
        expect(second.currentStatus, 'on_duty');
      },
    );

    test(
      'T6 hydration gate journals ECM but does not apply until replay',
      () async {
        final journal = _GatedJournal();
        final clock = FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 3, 1, 8),
        );
        final tracker = DutyStatusTracker(
          dutyPeriodStore: _TestDutyPeriodStore(),
          localStorage: _TestStorage(),
          syncEngine: _TestSyncEngine(),
          dashboardBackend: _TestDashboardBackend(),
          timeProvider: clock,
          readDriverId: () => 106,
          journal: journal,
        );
        trackers.add(tracker);

        expect(tracker.isHydrated, isFalse);
        expect(tracker.manualTransition('driving'), DutyStampRefusal.notReady);
        expect(tracker.currentStatus, 'off_duty');

        final start = DateTime.utc(2026, 3, 1, 8);
        for (var i = 0; i < 3; i++) {
          await tracker.processEldEvent(
            EldEvent(
              fromEcm: true,
              speedMph: 10,
              odometerMiles: 10,
              engineHours: 1,
              timestamp: start.add(Duration(seconds: i * 2)),
            ),
          );
        }

        expect(tracker.currentStatus, 'off_duty');
        expect(tracker.events, isEmpty);
        expect(journal.records, hasLength(1));

        journal.gate.complete();
        await tracker.hydrateForDriver(106);

        expect(tracker.isHydrated, isTrue);
        expect(tracker.currentStatus, 'driving');
        expect(tracker.events, hasLength(1));
      },
    );

    test(
      'T6b a row committed during hydration is replayed in legal-time order',
      () async {
        final journal = _LateGatedJournal();
        journal.records.add(
          _record(
            id: 'open-on-duty',
            status: 'on_duty',
            at: DateTime.utc(2026, 3, 1, 9),
          ),
        );
        final tracker = DutyStatusTracker(
          dutyPeriodStore: _TestDutyPeriodStore(),
          localStorage: _TestStorage(),
          syncEngine: _TestSyncEngine(),
          dashboardBackend: _TestDashboardBackend(),
          timeProvider: FakeTrustedTimeProvider(
            initialUtcTime: DateTime.utc(2026, 3, 1, 8),
          ),
          readDriverId: () => 106,
          journal: journal,
        );
        trackers.add(tracker);

        await journal.firstLoadStarted.future;
        expect(tracker.isHydrated, isFalse);
        expect(tracker.manualTransition('driving'), DutyStampRefusal.notReady);

        // ECM evidence committed while the first read is in flight. It must be
        // journaled but not applied, then replayed by legal time (08:00 before
        // the pre-existing 09:00 row), not by arrival order.
        final start = DateTime.utc(2026, 3, 1, 8);
        for (var i = 0; i < 3; i++) {
          await tracker.processEldEvent(
            EldEvent(
              fromEcm: true,
              speedMph: 10,
              odometerMiles: 10,
              engineHours: 1,
              timestamp: start.add(Duration(seconds: i * 2)),
            ),
          );
        }
        expect(journal.records, hasLength(2));
        expect(tracker.events, isEmpty);

        journal.firstLoadGate.complete();
        await tracker.hydrateForDriver(106);

        expect(tracker.isHydrated, isTrue);
        expect(tracker.currentStatus, 'on_duty');
        expect(tracker.events.map((e) => e.status).toList(), [
          'driving',
          'on_duty',
        ]);
        expect(tracker.periods, hasLength(1));
        expect(tracker.periods.single.status, 'driving');
      },
    );

    test('T7 a failed initial read is retryable', () async {
      final journal = _FlakyJournal();
      final tracker = DutyStatusTracker(
        dutyPeriodStore: _TestDutyPeriodStore(),
        localStorage: _TestStorage(),
        syncEngine: _TestSyncEngine(),
        dashboardBackend: _TestDashboardBackend(),
        timeProvider: FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 3, 1, 8),
        ),
        readDriverId: () => 106,
        journal: journal,
      );
      trackers.add(tracker);

      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(tracker.hydrationFailed, isTrue);
      expect(tracker.isHydrated, isFalse);

      await tracker.hydrateForDriver(106);
      expect(tracker.hydrationFailed, isFalse);
      expect(tracker.isHydrated, isTrue);
    });

    test('T8 offline manual change is durable and queued', () async {
      final dashboard = _TestDashboardBackend()
        ..updateResult = const Left(
          NetworkError(code: 'network.offline', l10nKey: 'errNetwork'),
        );
      final tracker = DutyStatusTracker(
        dutyPeriodStore: _TestDutyPeriodStore(),
        localStorage: _TestStorage(),
        syncEngine: _TestSyncEngine(),
        dashboardBackend: dashboard,
        timeProvider: FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 3, 1, 8),
        ),
        readDriverId: () => 106,
        journal: journal,
      );
      trackers.add(tracker);
      await tracker.hydrateForDriver(106);

      final outcome = await tracker.submitManualChange('on_duty');
      await tracker.persistenceIdle;

      expect(outcome.accepted, isTrue);
      expect(tracker.currentStatus, 'on_duty');
      expect(await queue.count, 1);
      final load = await journal.load(ownerDriverId: 106);
      expect(load.records, hasLength(1));
      expect(load.records.single.status, 'on_duty');
      expect(load.records.single.syncState, DutyEventSyncState.queued);
      expect(load.records.single.eventTimeUtc, DateTime.utc(2026, 3, 1, 8));
    });

    test(
      'T14 a corrupt row is retained, flagged, and never presented as HOS',
      () async {
        await journal.append(
          _record(
            id: 'valid',
            status: 'on_duty',
            at: DateTime.utc(2026, 3, 1, 9),
          ),
        );

        final db = await queue.database;
        final received = DateTime.utc(2026, 3, 1, 8).millisecondsSinceEpoch;
        await db.insert(SQLiteOfflineQueue.journalTable, {
          'event_id': 'corrupt-1',
          'owner_driver_id': 106,
          'source': 'manual',
          'status': 'driving',
          'event_time_utc': received,
          'received_at_utc': received,
          'time_source': 'trusted',
          'time_confidence': 'trusted',
          'monotonic_ms': null,
          'payload': 'not-json',
          'sync_state': 'localOnly',
          'server_event_id': null,
          'created_at': received,
        });

        final load = await journal.load(ownerDriverId: 106);
        expect(load.records, hasLength(1));
        expect(load.corruptedRows, 1);
        expect(load.hasCorruption, isTrue);

        final tracker = buildTracker(
          queue: queue,
          journal: journal,
          clock: FakeTrustedTimeProvider(
            initialUtcTime: DateTime.utc(2026, 3, 1, 10),
          ),
          storage: _TestStorage(),
        );
        await tracker.hydrateForDriver(106);

        expect(tracker.journalHasCorruption, isTrue);
        expect(tracker.currentStatus, 'on_duty');
        expect(tracker.events, hasLength(1));
        expect(
          await db.query(SQLiteOfflineQueue.journalTable),
          hasLength(2),
          reason: 'evidence is retained even when it cannot be decoded',
        );
      },
    );
  });
}

DutyEventRecord _record({
  required String id,
  required String status,
  required DateTime at,
}) {
  return DutyEventRecord(
    eventId: id,
    ownerDriverId: 106,
    source: DutyEventSource.manual,
    status: status,
    eventTimeUtc: at,
    receivedAtUtc: at,
    timeSource: DutyTimeSource.trusted,
    timeConfidence: DutyTimeConfidence.trusted,
    monotonicMs: 0,
    payload: {'status': status},
    syncState: DutyEventSyncState.localOnly,
    createdAt: at,
  );
}

class _TestStorage implements LocalStorageService {
  _TestStorage([Map<String, String>? source])
    : data = Map<String, String>.from(source ?? const {});

  Map<String, String> data;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String get currentDutyStatus => data['current_duty_status'] ?? 'off_duty';

  @override
  Future<void> setCurrentDutyStatus(String value) async {
    data['current_duty_status'] = value;
  }

  @override
  String? get selectedVehicleId => data['selected_vehicle_id'];

  @override
  String? get stationarySince => data['stationary_since'];

  @override
  Future<void> setStationarySince(String value) async {
    data['stationary_since'] = value;
  }
}

class _TestDutyPeriodStore implements DutyPeriodStore {
  @override
  Future<List<DutyPeriod>> getPeriods(DateTime date) async => const [];

  @override
  Future<void> savePeriod(DutyPeriod period) async {}
}

class _TestSyncEngine implements SyncEngine {
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> submitEvent(PendingEvent event) async {}

  @override
  Future<Either<Failure, bool>> submitEventAndReport(
    PendingEvent event,
  ) async => const Right(true);

  @override
  Future<void> triggerSync() async {}

  @override
  Future<DispatchAuthContext> Function()? get observeAuth => null;

  @override
  Future<int> releaseEligible({int limit = 50}) async => 0;
}

class _TestDashboardBackend implements StatusDashboardBackend {
  Result<StatusDashboard>? updateResult;

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
    DriverId? driverId,
    VehicleId? vehicleId,
    double? latitude,
    double? longitude,
  }) async {
    final result = updateResult;
    if (result == null) throw UnimplementedError();
    return result;
  }

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async =>
      throw UnimplementedError();

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async =>
      throw UnimplementedError();
}

class _GatedJournal implements DutyEventJournal {
  final List<DutyEventRecord> records = [];
  final Completer<void> gate = Completer<void>();

  @override
  Future<void> append(DutyEventRecord record, {PendingEvent? syncEvent}) async {
    if (!records.any((r) => r.eventId == record.eventId)) {
      records.add(record);
    }
  }

  @override
  Future<DutyEventJournalLoad> load({
    required int ownerDriverId,
    int limit = 1000,
  }) async {
    await gate.future;
    return DutyEventJournalLoad(
      records: records.where((r) => r.ownerDriverId == ownerDriverId).toList(),
      corruptedRows: 0,
    );
  }
}

class _LateGatedJournal implements DutyEventJournal {
  final List<DutyEventRecord> records = [];
  final firstLoadStarted = Completer<void>();
  final firstLoadGate = Completer<void>();
  var _loads = 0;

  @override
  Future<void> append(DutyEventRecord record, {PendingEvent? syncEvent}) async {
    if (!records.any((r) => r.eventId == record.eventId)) {
      records.add(record);
    }
  }

  @override
  Future<DutyEventJournalLoad> load({
    required int ownerDriverId,
    int limit = 1000,
  }) async {
    _loads++;
    // The real journal returns rows ordered by legal time, then sequence.
    // Capture the snapshot before the gate so the first read is stale on
    // purpose while a row is committed in flight.
    final snapshot =
        records.where((r) => r.ownerDriverId == ownerDriverId).toList()
          ..sort((a, b) {
            final left = a.eventTimeUtc;
            final right = b.eventTimeUtc;
            if (left == null && right == null) return 0;
            if (left == null) return 1;
            if (right == null) return -1;
            return left.compareTo(right);
          });
    if (_loads == 1) {
      if (!firstLoadStarted.isCompleted) firstLoadStarted.complete();
      await firstLoadGate.future;
    }
    return DutyEventJournalLoad(records: snapshot, corruptedRows: 0);
  }
}

class _FlakyJournal implements DutyEventJournal {
  var _loads = 0;

  @override
  Future<void> append(
    DutyEventRecord record, {
    PendingEvent? syncEvent,
  }) async {}

  @override
  Future<DutyEventJournalLoad> load({
    required int ownerDriverId,
    int limit = 1000,
  }) async {
    _loads++;
    if (_loads == 1) throw StateError('journal read failed');
    return const DutyEventJournalLoad(records: [], corruptedRows: 0);
  }
}

class _ThrowingJournal implements DutyEventJournal {
  @override
  Future<void> append(DutyEventRecord record, {PendingEvent? syncEvent}) async {
    throw StateError('transaction failed');
  }

  @override
  Future<DutyEventJournalLoad> load({
    required int ownerDriverId,
    int limit = 1000,
  }) async => const DutyEventJournalLoad(records: [], corruptedRows: 0);
}
