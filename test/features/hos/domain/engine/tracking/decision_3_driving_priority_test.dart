import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/contracts/status_dashboard_backend.dart';
import 'package:golden_feather_eld/core/constants/app_constants.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
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
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Decision 3 (P0): Driving Priority & Conflict Resolution Tests', () {
    late Directory tempDir;
    late String dbPath;
    late SQLiteOfflineQueue queue;
    late SqliteDutyEventJournal journal;
    late FakeTrustedTimeProvider clock;
    late _TestStorage storage;
    late DateTime baseTime;
    final trackers = <DutyStatusTracker>[];

    setUp(() async {
      await SQLiteOfflineQueue.resetForTests();
      tempDir = await Directory.systemTemp.createTemp('decision_3_test_');
      dbPath = p.join(tempDir.path, 'offline_queue.db');
      queue = SQLiteOfflineQueue(dbPathOverride: dbPath);
      journal = SqliteDutyEventJournal(() => queue.database);
      baseTime = DateTime.utc(2026, 11, 5, 4, 0, 0);
      clock = FakeTrustedTimeProvider(initialUtcTime: baseTime);
      storage = _TestStorage();
    });

    tearDown(() async {
      for (final tracker in trackers) {
        tracker.dispose();
      }
      trackers.clear();
      await SQLiteOfflineQueue.resetForTests();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    DutyStatusTracker createTracker() {
      final tracker = DutyStatusTracker(
        dutyPeriodStore: _TestDutyPeriodStore(),
        localStorage: storage,
        syncEngine: _TestSyncEngine(),
        dashboardBackend: _TestDashboardBackend(),
        timeProvider: clock,
        readDriverId: () => 101,
        journal: journal,
      );
      trackers.add(tracker);
      return tracker;
    }

    // -------------------------------------------------------------------------
    // Test 1: ECM 5.01 mph -> Immediate Driving (source='ecm'), NO debounce.
    // -------------------------------------------------------------------------
    test('1. ECM 5.01 mph triggers immediate transition to Driving without debounce', () async {
      final tracker = createTracker();
      await tracker.hydrateForDriver(101);

      expect(tracker.currentStatus, equals('off_duty'));

      final ecmEvent = EldEvent(
        timestamp: baseTime,
        speedMph: 5.01,
        fromEcm: true,
      );

      final stopwatch = Stopwatch()..start();
      await tracker.processEldEvent(ecmEvent);
      await tracker.persistenceIdle;
      stopwatch.stop();

      // Zero debounce: single packet instantly transitions to driving
      expect(tracker.currentStatus, equals('driving'));
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));

      final load = await journal.load(ownerDriverId: 101);
      expect(load.records.isNotEmpty, isTrue);

      final drivingRecord = load.records.last;
      expect(drivingRecord.status, equals('driving'));
      expect(drivingRecord.source, equals(DutyEventSource.ecm));
      expect(drivingRecord.payload['source'], equals('ecm'));
    });

    // -------------------------------------------------------------------------
    // Gap 1: Speed boundary tests at 5.00 mph and 4.99 mph
    // FMCSA defines driving at > 5.0 mph. Exactly 5.00 mph must NOT transition.
    // -------------------------------------------------------------------------
    test('2a. ECM 5.00 mph exactly does NOT trigger transition to driving (FMCSA > 5.0 rule)', () async {
      final tracker = createTracker();
      await tracker.hydrateForDriver(101);

      expect(tracker.currentStatus, equals('off_duty'));

      final ecmEvent = EldEvent(
        timestamp: baseTime,
        speedMph: 5.00,
        fromEcm: true,
      );

      await tracker.processEldEvent(ecmEvent);
      await tracker.persistenceIdle;

      // Status remains off_duty because 5.00 is not strictly > 5.0
      expect(tracker.currentStatus, equals('off_duty'));
      expect(tracker.lastEcmSpeedMph, equals(5.00));
    });

    test('2b. ECM 4.99 mph does NOT trigger transition to driving', () async {
      final tracker = createTracker();
      await tracker.hydrateForDriver(101);

      expect(tracker.currentStatus, equals('off_duty'));

      final ecmEvent = EldEvent(
        timestamp: baseTime,
        speedMph: 4.99,
        fromEcm: true,
      );

      await tracker.processEldEvent(ecmEvent);
      await tracker.persistenceIdle;

      expect(tracker.currentStatus, equals('off_duty'));
      expect(tracker.lastEcmSpeedMph, equals(4.99));
    });

    // -------------------------------------------------------------------------
    // Test 3: Server transitionedToDriving=true, no ECM -> Driving (source='server')
    // -------------------------------------------------------------------------
    test('3. Server telemetry transitionedToDriving=true with no ECM transitions to Driving (source=server)', () async {
      final tracker = createTracker();
      await tracker.hydrateForDriver(101);

      expect(tracker.currentStatus, equals('off_duty'));
      expect(tracker.isEcmStationaryActive, isFalse);

      final success = await tracker.transitionToDriving(source: DutyEventSource.server);
      await tracker.persistenceIdle;

      expect(success, isTrue);
      expect(tracker.currentStatus, equals('driving'));

      final load = await journal.load(ownerDriverId: 101);
      final serverRecord = load.records.last;
      expect(serverRecord.status, equals('driving'));
      expect(serverRecord.source, equals(DutyEventSource.server));
      expect(serverRecord.payload['source'], equals('server'));
    });

    // -------------------------------------------------------------------------
    // Test 4: Server transitionedToDriving=true, active ECM stationary -> ECM wins, conflict logged
    // -------------------------------------------------------------------------
    test('4. Active ECM stationary overrides Server transitionedToDriving and logs conflict (Case A)', () async {
      final tracker = createTracker();
      await tracker.hydrateForDriver(101);

      // Feed active ECM stationary packet (0.0 mph)
      await tracker.processEldEvent(
        EldEvent(
          timestamp: baseTime,
          speedMph: 0.0,
          fromEcm: true,
        ),
      );
      await tracker.persistenceIdle;

      expect(tracker.isEcmStationaryActive, isTrue);
      expect(tracker.currentStatus, equals('off_duty'));

      // Server tries to command driving
      final success = await tracker.transitionToDriving(source: DutyEventSource.server);
      await tracker.persistenceIdle;

      // Server request rejected; driver remains off_duty
      expect(success, isFalse);
      expect(tracker.currentStatus, equals('off_duty'));

      // Verify conflict logged in journal
      final load = await journal.load(ownerDriverId: 101);
      final conflictRecord = load.records.firstWhere(
        (r) => r.payload['conflict_resolution'] == 'ecm_override_server',
      );

      expect(conflictRecord.source, equals(DutyEventSource.ecm));
      expect(conflictRecord.payload['server_event'], equals('transitionedToDriving'));
      expect(conflictRecord.payload['ecm_speed_mph'], equals(0.0));
    });

    // -------------------------------------------------------------------------
    // Test 5: Phone GPS only (fromEcm=false) -> Line 325 blocked, No Driving
    // -------------------------------------------------------------------------
    test('5. Phone GPS only (fromEcm=false) is strictly rejected at line 325 with no driving transition', () async {
      final tracker = createTracker();
      await tracker.hydrateForDriver(101);

      expect(tracker.currentStatus, equals('off_duty'));

      // 60 mph simulated speed from Phone GPS (NOT from ECM)
      final phoneGpsEvent = EldEvent(
        timestamp: baseTime,
        speedMph: 60.0,
        fromEcm: false,
      );

      await tracker.processEldEvent(phoneGpsEvent);
      await tracker.persistenceIdle;

      // Status remains completely unchanged
      expect(tracker.currentStatus, equals('off_duty'));
      expect(tracker.lastEcmSpeedMph, isNull);

      final load = await journal.load(ownerDriverId: 101);
      expect(load.records.isEmpty, isTrue);
    });

    // -------------------------------------------------------------------------
    // Critical 2: Real disk-based Migration v6 -> v7 (no nested transaction)
    // -------------------------------------------------------------------------
    test('6. Database migration v6 to v7 on real disk file succeeds without nested transaction errors', () async {
      final dbFile = p.join(tempDir.path, 'migration_real_disk_test.db');

      // 1. Create a version 6 schema on real disk file with legacy data
      final legacyDb = await openDatabase(
        dbFile,
        version: 6,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE duty_event_journal (
              seq INTEGER PRIMARY KEY AUTOINCREMENT,
              event_id TEXT NOT NULL UNIQUE,
              owner_driver_id INTEGER,
              status TEXT NOT NULL,
              event_time_utc INTEGER,
              received_at_utc INTEGER NOT NULL,
              time_source TEXT NOT NULL,
              time_confidence TEXT NOT NULL,
              monotonic_ms INTEGER,
              payload TEXT NOT NULL,
              sync_state TEXT NOT NULL,
              server_event_id TEXT,
              created_at INTEGER NOT NULL
            )
          ''');
          await db.execute('''
            CREATE TABLE pending_events (
              id TEXT PRIMARY KEY,
              type TEXT NOT NULL,
              payload TEXT NOT NULL,
              createdAt INTEGER NOT NULL,
              priority INTEGER NOT NULL,
              retryCount INTEGER NOT NULL,
              nextRetryAt INTEGER,
              dedupeKey TEXT
            )
          ''');
        },
      );

      // Insert legacy rows into v6 table without 'source' column
      await legacyDb.insert('duty_event_journal', {
        'event_id': 'legacy_evt_1',
        'owner_driver_id': 101,
        'status': 'off_duty',
        'event_time_utc': baseTime.millisecondsSinceEpoch,
        'received_at_utc': baseTime.millisecondsSinceEpoch,
        'time_source': 'trusted',
        'time_confidence': 'trusted',
        'monotonic_ms': 100,
        'payload': '{"status":"off_duty"}',
        'sync_state': 'localOnly',
        'created_at': baseTime.millisecondsSinceEpoch,
      });

      await legacyDb.close();

      // 2. Open via SQLiteOfflineQueue (version: 7) which invokes _migrateToV7 on the real disk file
      final v7Queue = SQLiteOfflineQueue(dbPathOverride: dbFile);
      final upgradedDb = await v7Queue.database;

      final versionResult = await upgradedDb.rawQuery('PRAGMA user_version');
      expect(versionResult.first.values.first, equals(7));

      // 3. Verify 'source' column exists and legacy row was backfilled to 'manual'
      final tableInfo = await upgradedDb.rawQuery('PRAGMA table_info(duty_event_journal)');
      final hasSource = tableInfo.any((col) => col['name'] == 'source');
      expect(hasSource, isTrue);

      final rows = await upgradedDb.query('duty_event_journal', where: 'event_id = ?', whereArgs: ['legacy_evt_1']);
      expect(rows.length, equals(1));
      expect(rows.first['source'], equals('manual'));
      expect(rows.first['status'], equals('off_duty'));
      expect(rows.first['owner_driver_id'], equals(101));

      await upgradedDb.close();
    });

    // -------------------------------------------------------------------------
    // Test 7: ECM driving + Server tries OnDuty -> ECM wins, conflict logged (Case B)
    // -------------------------------------------------------------------------
    test('7. ECM driving actively moving overrides Server attempt to set OnDuty and logs conflict (Case B)', () async {
      final tracker = createTracker();
      await tracker.hydrateForDriver(101);

      // ECM speed 15.0 mph -> driver transitions to driving
      await tracker.processEldEvent(
        EldEvent(
          timestamp: baseTime,
          speedMph: 15.0,
          fromEcm: true,
        ),
      );
      await tracker.persistenceIdle;

      expect(tracker.currentStatus, equals('driving'));
      expect(tracker.isEcmDrivingActive, isTrue);

      // Server attempts to set OnDuty
      final success = await tracker.transitionToStatus('on_duty', source: DutyEventSource.server);
      await tracker.persistenceIdle;

      // Server attempt rejected; driver remains in driving
      expect(success, isFalse);
      expect(tracker.currentStatus, equals('driving'));

      // Verify conflict logged in journal: ecm_override_server_driving
      final load = await journal.load(ownerDriverId: 101);
      final conflictRecord = load.records.firstWhere(
        (r) => r.payload['conflict_resolution'] == 'ecm_override_server_driving',
      );

      expect(conflictRecord.source, equals(DutyEventSource.ecm));
      expect(conflictRecord.payload['server_event'], equals('server_transition_on_duty'));
      expect(conflictRecord.payload['ecm_speed_mph'], equals(15.0));
    });

    // -------------------------------------------------------------------------
    // Boundary Tests: ecmActiveWindowSeconds (59.9s vs 60.1s)
    // -------------------------------------------------------------------------
    test('8. ECM active window boundaries: 59.9s is ACTIVE, 60.1s is INACTIVE (60s window)', () async {
      final tracker = createTracker();
      await tracker.hydrateForDriver(101);

      // Receive ECM packet at baseTime
      await tracker.processEldEvent(
        EldEvent(
          timestamp: baseTime,
          speedMph: 0.0,
          fromEcm: true,
        ),
      );
      await tracker.persistenceIdle;

      expect(AppConstants.ecmActiveWindowSeconds, equals(60));

      // At 59.9 seconds later: Still active!
      clock.anchor(baseTime.add(const Duration(milliseconds: 59900)));
      expect(tracker.isEcmStationaryActive, isTrue);

      // At 60.1 seconds later: Inactive (lapsed beyond 60s threshold)
      clock.anchor(baseTime.add(const Duration(milliseconds: 60100)));
      expect(tracker.isEcmStationaryActive, isFalse);
    });

    // -------------------------------------------------------------------------
    // Critical 1: No false conflict during regular streaming (5 packets @ 30s)
    // -------------------------------------------------------------------------
    test('9. No false conflict during regular streaming: streams 5 packets at 30s intervals with zero false conflicts', () async {
      final tracker = createTracker();
      await tracker.hydrateForDriver(101);

      // Start streaming packets every 30 seconds (standard telemetry interval)
      for (int i = 0; i < 5; i++) {
        final packetTime = baseTime.add(Duration(seconds: i * 30));
        clock.anchor(packetTime);

        await tracker.processEldEvent(
          EldEvent(
            timestamp: packetTime,
            speedMph: 15.0,
            fromEcm: true,
          ),
        );
        await tracker.persistenceIdle;

        // Immediately after packet
        expect(tracker.isEcmDrivingActive, isTrue, reason: 'Packet $i must be active');
        expect(tracker.currentStatus, equals('driving'));

        // Check just before the next packet arrives (29.99 seconds later)
        // With 60s window, the state MUST NOT flicker to inactive!
        final justBeforeNext = packetTime.add(const Duration(milliseconds: 29990));
        clock.anchor(justBeforeNext);
        expect(tracker.isEcmDrivingActive, isTrue,
            reason: 'State must not flicker to inactive at +29.99s for packet $i');
      }

      // Verify journal has only the single driving transition and NO conflict records
      final load = await journal.load(ownerDriverId: 101);
      final conflictRecords = load.records.where(
        (r) => r.payload['conflict_resolution'] != null,
      );
      expect(conflictRecords.isEmpty, isTrue, reason: 'Zero false conflicts during regular 30s streaming');
      expect(tracker.currentStatus, equals('driving'));
    });
  });
}
