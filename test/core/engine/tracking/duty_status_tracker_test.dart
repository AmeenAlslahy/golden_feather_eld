import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/tracking/duty_status_tracker.dart';
import 'package:golden_feather_eld/features/hos/domain/repositories/duty_period_store.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/dispatch_auth.dart';
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/backend/contracts/status_dashboard_backend.dart';

class MockSyncEngine implements SyncEngine {
  final List<PendingEvent> submitted = [];
  final List<PendingEvent> reported = [];
  Either<Failure, bool> reportResult = const Right(true);

  @override
  Future<void> submitEvent(PendingEvent event) async {
    submitted.add(event);
  }

  @override
  Future<Either<Failure, bool>> submitEventAndReport(PendingEvent event) async {
    reported.add(event);
    return reportResult;
  }

  @override
  Future<void> triggerSync() async {}

  // P0 2B-1 members — unused by these tracker tests (fence inactive here).
  @override
  Future<DispatchAuthContext> Function()? get observeAuth => null;

  @override
  Future<int> releaseEligible({int limit = 50}) async => 0;

  @override
  Future<void> Function(PendingEvent event)? get onDeadLettered => null;
}

class MockDashboardBackend implements StatusDashboardBackend {
  Either<AppError, StatusDashboard> updateResult = Right(_sampleDashboard());
  DutyStatusCode? lastStatus;
  String? lastNotes;
  DriverId? lastDriverId;
  VehicleId? lastVehicleId;
  double? lastLatitude;
  double? lastLongitude;

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
    DriverId? driverId,
    VehicleId? vehicleId,
    double? latitude,
    double? longitude,
  }) async {
    lastStatus = status;
    lastNotes = notes;
    lastDriverId = driverId;
    lastVehicleId = vehicleId;
    lastLatitude = latitude;
    lastLongitude = longitude;
    return updateResult;
  }

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async =>
      Right(_sampleDashboard());

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async =>
      throw UnimplementedError();
}

StatusDashboard _sampleDashboard() {
  return const StatusDashboard(
    driver: DriverRef(
      id: DriverId(101),
      name: 'Ahmed',
      displayText: 'Ahmed - 101',
    ),
    operationalAlerts: OperationalAlerts(
      toolIcon: false,
      warningTriangleIcon: false,
      connectionStatus: ConnectionStatus.ok,
    ),
    currentDutyStatus: DutyStatusCode.onDutyNotDriving,
    remainingCircle: RemainingCircle(
      remaining: Duration(hours: 8, minutes: 37),
      label: 'Remaining',
      progress: 0.62,
    ),
    hosIndicators: HosIndicators(
      drive: HosIndicator(
        label: 'DRIVE',
        value: Duration(hours: 2, minutes: 23),
        type: IndicatorType.used,
      ),
      shift: HosIndicator(
        label: 'SHIFT',
        value: Duration(hours: 5, minutes: 23),
        type: IndicatorType.used,
      ),
      breakTime: HosIndicator(
        label: 'BREAK',
        value: Duration(minutes: 30),
        type: IndicatorType.remaining,
      ),
      cycle: HosIndicator(
        label: 'CYCLE',
        value: Duration(hours: 61, minutes: 23),
        type: IndicatorType.used,
      ),
    ),
    regulatoryConstraints: RegulatoryConstraints(
      ruleSet: CycleRule.usa70_8,
      limits: [],
    ),
  );
}

class MockDutyPeriodStore implements DutyPeriodStore {
  List<DutyPeriod> savedPeriods = [];

  @override
  Future<List<DutyPeriod>> getPeriods(DateTime date) async => const [];

  @override
  Future<void> savePeriod(DutyPeriod period) async {
    savedPeriods.add(period);
  }
}

// Replaced FakeClock with FakeTrustedTimeProvider inline in setUp

class FakeLocalStorage implements LocalStorageService {
  @override
  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  Map<String, String> data = {};

  @override
  String get deviceId => data['device_id'] ?? '12345';

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

void main() {
  group('DutyStatusTracker FakeClock Tests', () {
    late DutyStatusTracker tracker;
    late MockDutyPeriodStore mockRepo;
    late FakeTrustedTimeProvider clock;
    late FakeLocalStorage db;

    setUp(() {
      mockRepo = MockDutyPeriodStore();
      clock = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2023, 1, 1, 12, 0, 0),
      );
      db = FakeLocalStorage();
      tracker = DutyStatusTracker(
        dutyPeriodStore: mockRepo,
        localStorage: db,
        syncEngine: MockSyncEngine(),
        dashboardBackend: MockDashboardBackend(),
        timeProvider: clock,
      );
    });

    tearDown(() {
      tracker.dispose();
    });

    DateTime getClockTime() => (clock.currentTime as TrustedTimeAvailable).utc;

    test('1. stationary start - does not transition immediately', () {
      tracker.manualTransition('driving');
      expect(tracker.currentStatus, 'driving');

      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );

      // Should remain driving
      expect(tracker.currentStatus, 'driving');
      expect(db.data['stationary_since'], isNotNull);
      expect(db.data['stationary_since'], isNotEmpty);
    });

    test('2. stationary < 5 min - remains driving', () {
      tracker.manualTransition('driving');
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );

      clock.advance(const Duration(minutes: 4));
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );

      expect(tracker.currentStatus, 'driving');
    });

    test('3. stationary >= 5 min - transitions to on_duty', () {
      tracker.manualTransition('driving');
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );

      clock.advance(const Duration(minutes: 5));
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );

      expect(tracker.currentStatus, 'on_duty');
      expect(db.data['stationary_since'], isEmpty); // should clear
    });

    test('4. movement interrupts stationary period (needs 3s sustained)', () {
      tracker.manualTransition('driving');
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );
      expect(db.data['stationary_since'], isNotNull);

      clock.advance(const Duration(minutes: 3));
      // Moving again - spike (1 event, 0s elapsed)
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 6.0,
          odometerMiles: 10.5,
          engineHours: 1.1,
          timestamp: getClockTime(),
        ),
      );
      // Still driving (since it was driving before), but stationary_since should NOT be cleared yet (wait, yes it is cleared on the FIRST event in my logic or 3rd event? Wait... my logic says "if (consecutive >= 3 && elapsed >= 3) { clear stationary timer }". So stationary_since is NOT cleared on the first spike!)
      // Wait, let's verify my logic: I put clearing stationary_since INSIDE the `if (_consecutiveMovingEvents >= 3)` block. So stationary_since is NOT cleared on a spike!

      // Send 3 events spanning 3 seconds
      clock.advance(const Duration(seconds: 1));
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 6.0,
          odometerMiles: 10.5,
          engineHours: 1.1,
          timestamp: getClockTime(),
        ),
      );
      clock.advance(const Duration(seconds: 2));
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 6.0,
          odometerMiles: 10.5,
          engineHours: 1.1,
          timestamp: getClockTime(),
        ),
      );

      expect(tracker.currentStatus, 'driving');
      expect(
        db.data['stationary_since'],
        isEmpty,
      ); // Timer cancelled after 3 seconds
    });

    test('5. restart during stationary hydration', () {
      tracker.manualTransition('driving');
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );

      // Simulate app kill and advance clock by 6 minutes
      final savedData = db.data;
      clock.advance(const Duration(minutes: 6));

      // New app session
      final newDb = FakeLocalStorage()..data = savedData;
      final newTracker = DutyStatusTracker(
        dutyPeriodStore: mockRepo,
        localStorage: newDb,
        syncEngine: MockSyncEngine(),
        dashboardBackend: MockDashboardBackend(),
        timeProvider: clock,
      );
      // The status should hydrate to driving, and stationarySince should be intact.
      // Now, an event arrives (which triggers _evaluateStationaryState if speed is 0)
      newTracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );

      expect(newTracker.currentStatus, 'on_duty');
      expect(newDb.data['stationary_since'], isEmpty);
      newTracker.dispose();
    });
  });

  group('Fake Location Streamer Tests', () {
    late DutyStatusTracker tracker;
    late MockDutyPeriodStore mockRepo;
    late FakeTrustedTimeProvider clock;
    late FakeLocalStorage db;

    setUp(() {
      mockRepo = MockDutyPeriodStore();
      clock = FakeTrustedTimeProvider(initialUtcTime: DateTime.now().toUtc());
      db = FakeLocalStorage();
      tracker = DutyStatusTracker(
        dutyPeriodStore: mockRepo,
        localStorage: db,
        syncEngine: MockSyncEngine(),
        dashboardBackend: MockDashboardBackend(),
        timeProvider: clock,
      );
    });

    tearDown(() {
      tracker.dispose();
    });

    DateTime getClockTime() => (clock.currentTime as TrustedTimeAvailable).utc;

    test('below threshold (<= 5) remains current status if not driving', () {
      expect(tracker.currentStatus, 'off_duty');
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 4.9,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );
      expect(tracker.currentStatus, 'off_duty');
    });

    test('at threshold (= 5.0) remains current status', () {
      expect(tracker.currentStatus, 'off_duty');
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 5.0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );
      expect(tracker.currentStatus, 'off_duty');
    });

    test(
      'above threshold (> 5.0) transitions immediately to driving without debounce (Decision 3 P0)',
      () {
        expect(tracker.currentStatus, 'off_duty');
        tracker.processEldEvent(
          EldEvent(
            fromEcm: true,
            speedMph: 5.1,
            odometerMiles: 10,
            engineHours: 1,
            timestamp: getClockTime(),
          ),
        );
        expect(tracker.currentStatus, 'driving');
      },
    );

    test(
      'above threshold (> 5.0) transitions immediately and remains driving across subsequent events',
      () {
        expect(tracker.currentStatus, 'off_duty');

        // Event 1 (0s) - Immediate transition
        tracker.processEldEvent(
          EldEvent(
            fromEcm: true,
            speedMph: 5.1,
            odometerMiles: 10,
            engineHours: 1,
            timestamp: getClockTime(),
          ),
        );
        expect(tracker.currentStatus, 'driving');

        // Event 2 (1s)
        clock.advance(const Duration(seconds: 1));
        tracker.processEldEvent(
          EldEvent(
            fromEcm: true,
            speedMph: 5.1,
            odometerMiles: 10,
            engineHours: 1,
            timestamp: getClockTime(),
          ),
        );
        expect(tracker.currentStatus, 'driving');

        // Event 3 (3s)
        clock.advance(const Duration(seconds: 2));
        tracker.processEldEvent(
          EldEvent(
            fromEcm: true,
            speedMph: 5.1,
            odometerMiles: 10,
            engineHours: 1,
            timestamp: getClockTime(),
          ),
        );
        expect(tracker.currentStatus, 'driving');
      },
    );

    test('movement transitions to driving immediately upon exceeding 5 mph', () {
      expect(tracker.currentStatus, 'off_duty');

      // Event 1 (> 5) - Immediate transition to driving (Decision 3 P0)
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 5.1,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );
      expect(tracker.currentStatus, 'driving');

      // Event 2 (<= 5) - Initiates stationary evaluation
      clock.advance(const Duration(seconds: 1));
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 4.0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );
      expect(tracker.currentStatus, 'driving');

      // Event 3 (> 5) - Clears stationary marker, stays driving
      clock.advance(const Duration(seconds: 1));
      tracker.processEldEvent(
        EldEvent(
          fromEcm: true,
          speedMph: 5.1,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );
      expect(tracker.currentStatus, 'driving');
    });

    test('phone or simulated speed does not create a driving record', () {
      expect(tracker.currentStatus, 'off_duty');
      tracker.processEldEvent(
        EldEvent(
          fromEcm: false,
          speedMph: 40,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );
      clock.advance(const Duration(seconds: 4));
      tracker.processEldEvent(
        EldEvent(
          fromEcm: false,
          speedMph: 40,
          odometerMiles: 12,
          engineHours: 1,
          timestamp: getClockTime(),
        ),
      );
      expect(tracker.currentStatus, 'off_duty');
    });
  });

  group('legal duty stamp', () {
    late MockDutyPeriodStore mockRepo;
    late FakeLocalStorage db;
    late MockSyncEngine sync;
    late MockDashboardBackend dashboard;

    DutyStatusTracker build({
      TrustedTimeProvider? time,
      int? Function()? readDriverId,
    }) {
      return DutyStatusTracker(
        dutyPeriodStore: mockRepo,
        localStorage: db,
        syncEngine: sync,
        dashboardBackend: dashboard,
        timeProvider: time ?? FakeTrustedTimeProvider(),
        readDriverId: readDriverId,
      );
    }

    setUp(() {
      mockRepo = MockDutyPeriodStore();
      db = FakeLocalStorage();
      sync = MockSyncEngine();
      dashboard = MockDashboardBackend();
    });

    test(
      'missing trusted time rejects the duty event and does not stamp it',
      () {
        final tracker = build();
        final refusal = tracker.manualTransition('on_duty');

        expect(refusal, DutyStampRefusal.timeUnavailable);
        expect(tracker.currentStatus, 'off_duty');
        expect(sync.submitted, isEmpty);
        expect(sync.reported, isEmpty);
        tracker.dispose();
      },
    );

    test('missing driver session rejects before a stamp is queued', () {
      final clock = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 9, 23, 8),
      );
      final tracker = build(time: clock, readDriverId: () => null);
      final refusal = tracker.manualTransition('on_duty');

      expect(refusal, DutyStampRefusal.sessionMissing);
      expect(tracker.currentStatus, 'off_duty');
      expect(sync.submitted, isEmpty);
      tracker.dispose();
    });

    test(
      'accepted manual change hits the dashboard endpoint, not the queue',
      () async {
        final trusted = DateTime.utc(2026, 9, 23, 8, 15);
        final clock = FakeTrustedTimeProvider(initialUtcTime: trusted);
        final tracker = build(time: clock, readDriverId: () => 106);

        final outcome = await tracker.submitManualChange(
          'on_duty',
          annotation: 'Available',
        );

        expect(outcome.refusal, isNull);
        // لقطة الخادم تُمرر للواجهة لتغذية اللوحة دون GET ثانٍ.
        expect(outcome.dashboard, isNotNull);
        expect(tracker.currentStatus, 'on_duty');
        expect(dashboard.lastStatus, DutyStatusCode.onDutyNotDriving);
        expect(dashboard.lastNotes, 'Available');
        // المسار اليدوي لم يعد يمر بطابور الأحداث (دلالة 02.3 لا 05.2)
        expect(sync.submitted, isEmpty);
        expect(sync.reported, isEmpty);
        tracker.dispose();
      },
    );

    test(
      'manual change forwards captured GPS coordinates to the direct request',
      () async {
        final trusted = DateTime.utc(2026, 9, 23, 8, 15);
        final clock = FakeTrustedTimeProvider(initialUtcTime: trusted);
        final tracker = build(time: clock, readDriverId: () => 106);

        final outcome = await tracker.submitManualChange(
          'on_duty',
          annotation: 'Available',
          lat: 35.4714,
          lon: -93.4668,
        );

        expect(outcome.refusal, isNull);
        // الإحداثيات تصل لواجهة الباك-إند (تُرسل داخل location متداخل).
        expect(dashboard.lastLatitude, 35.4714);
        expect(dashboard.lastLongitude, -93.4668);
        // لا تغيير في سلوك الأوفلاين/الطابور للمسار المباشر.
        expect(sync.submitted, isEmpty);
        tracker.dispose();
      },
    );

    test(
      'manual change forwards selectedVehicleId to the direct request',
      () async {
        final trusted = DateTime.utc(2026, 9, 23, 8, 15);
        final clock = FakeTrustedTimeProvider(initialUtcTime: trusted);
        db.data['selected_vehicle_id'] = '42';
        final tracker = build(
          time: clock,
          readDriverId: () => 106,
        );

        final outcome = await tracker.submitManualChange(
          'on_duty',
          annotation: 'Available',
        );

        expect(outcome.refusal, isNull);
        expect(dashboard.lastVehicleId, equals(const VehicleId(42)));
        tracker.dispose();
      },
    );

    test('server rejection does not change local duty status', () async {
      final clock = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 9, 23, 8),
      );
      dashboard.updateResult = const Left(ServerError(code: 'server.rejected'));
      final tracker = build(time: clock, readDriverId: () => 106);

      final outcome = await tracker.submitManualChange('sleeper');

      expect(outcome.refusal, DutyStampRefusal.serverRejected);
      expect(outcome.dashboard, isNull);
      expect(tracker.currentStatus, 'off_duty');
      expect(dashboard.lastStatus, DutyStatusCode.sleeperBerth);
      expect(sync.reported, isEmpty);
      tracker.dispose();
    });
  });

  group('P0 — transition durability & idempotency key', () {
    late MockDutyPeriodStore mockRepo;
    late FakeLocalStorage db;
    late FakeTrustedTimeProvider clock;

    setUp(() {
      mockRepo = MockDutyPeriodStore();
      db = FakeLocalStorage();
      clock = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 3, 1, 8),
      );
    });

    DutyStatusTracker build({
      required MockSyncEngine sync,
      LocalStorageService? storage,
      DutyPeriodStore? store,
    }) => DutyStatusTracker(
      dutyPeriodStore: store ?? mockRepo,
      localStorage: storage ?? db,
      syncEngine: sync,
      dashboardBackend: MockDashboardBackend(),
      timeProvider: clock,
    );

    test('clientId is stamped and equals the queued event id', () async {
      final sync = MockSyncEngine();
      final tracker = build(sync: sync);

      tracker.manualTransition('on_duty');
      await pumpEventQueue();

      expect(sync.submitted, hasLength(1));
      final event = sync.submitted.single;
      expect(
        event.payload['clientId'],
        event.id,
        reason: 'مفتاح idempotency لغلق ازدواج السجل عند فقد ردّ الخادم',
      );
      expect(event.id, isNotEmpty);
      tracker.dispose();
    });

    test('declared status is persisted before the event is enqueued', () async {
      final order = <String>[];
      final tracker = build(
        sync: _OrderedSyncEngine(order),
        storage: _OrderedStorage(order),
      );

      tracker.manualTransition('on_duty');
      await pumpEventQueue();

      expect(order, [
        'status:on_duty',
        'enqueue',
      ], reason: 'قبل الإصلاح كان الطابور يُطلق دون انتظار كتابة الحالة');
      tracker.dispose();
    });

    test(
      'throwing submitEvent is contained and status stays persisted',
      () async {
        final tracker = build(sync: _ThrowingSyncEngine());

        tracker.manualTransition('on_duty');
        await pumpEventQueue();

        expect(
          db.data['current_duty_status'],
          'on_duty',
          reason: 'الفشل يُحتوى ولا يُسقط الكتابة المحلية',
        );
        tracker.dispose();
      },
    );

    test('throwing savePeriod does not drop the queued event', () async {
      final sync = MockSyncEngine();
      final tracker = build(sync: sync, store: _ThrowingPeriodRepo());

      tracker.manualTransition('on_duty');
      await pumpEventQueue();
      expect(sync.submitted, hasLength(1));

      tracker.manualTransition('off_duty'); // يغلق فترة ⇒ savePeriod يرمي
      await pumpEventQueue();

      expect(
        sync.submitted,
        hasLength(2),
        reason: 'فشل حفظ الفترة يجب ألا يُسقط حدث المزامنة',
      );
      tracker.dispose();
    });
  });
}

class _OrderedStorage extends FakeLocalStorage {
  _OrderedStorage(this.order);

  final List<String> order;

  @override
  Future<void> setCurrentDutyStatus(String value) async {
    order.add('status:$value');
    await super.setCurrentDutyStatus(value);
  }
}

class _OrderedSyncEngine extends MockSyncEngine {
  _OrderedSyncEngine(this.order);

  final List<String> order;

  @override
  Future<void> submitEvent(PendingEvent event) async {
    order.add('enqueue');
    await super.submitEvent(event);
  }
}

class _ThrowingSyncEngine extends MockSyncEngine {
  @override
  Future<void> submitEvent(PendingEvent event) async {
    throw StateError('queue unavailable');
  }
}

class _ThrowingPeriodRepo extends MockDutyPeriodStore {
  @override
  Future<void> savePeriod(DutyPeriod period) async {
    throw StateError('disk full');
  }
}
