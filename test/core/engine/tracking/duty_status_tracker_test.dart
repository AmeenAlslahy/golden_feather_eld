import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/tracking/duty_status_tracker.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/audit_entry.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/log_readiness.dart';
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
}

class MockDashboardBackend implements StatusDashboardBackend {
  Either<AppError, StatusDashboard> updateResult = Right(_sampleDashboard());
  DutyStatusCode? lastStatus;
  String? lastNotes;

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  }) async {
    lastStatus = status;
    lastNotes = notes;
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

class MockLogRepository implements LogRepository {
  List<DutyPeriod> savedPeriods = [];

  @override
  Future<Either<Failure, bool>> savePeriod(DutyPeriod period) async {
    savedPeriods.add(period);
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> addEvent(LogEvent event, {String? reason}) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<AuditEntry>>> getAuditEntries(
          DateTime date) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<LogEvent>>> getEvents(
          DailyLogId logId, DateTime date) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<DutyPeriod>>> getPeriods(DateTime date) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, bool>> logAudit(AuditEntry entry) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, LogEvent?>> updateEvent(LogEvent event,
          {required String reason}) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, List<DailyLog>>> getDailyLogs({
    required int driverId,
    int limit = 50,
    int offset = 0,
  }) async => throw UnimplementedError();

  @override
  Future<Either<Failure, LogReadiness>> getReadiness(DailyLogId logId) async {
    return Right(LogReadiness(
      dailyLogId: logId.value,
      driverId: 12345,
      driverName: 'Mock Driver',
      logDate: '2023-01-01',
      readinessStatus: 'READY',
      missingRequirements: const [],
      availableActions: const [],
      legalStatement: 'Mock Legal Statement',
      carrierProposedEditsPending: false,
      pendingCarrierEdits: const [],
    ));
  }

  @override
  Future<Either<Failure, bool>> certifyLog({
    required DailyLogId logId,
    required int driverId,
    required String logDate,
    required String signatureCertificateId,
    required bool signatureConfirmation,
    required bool certifiedTrue,
  }) async {
    return const Right(true);
  }

  @override
  Future<Either<Failure, bool>> respondToCarrierEdit({
    required DailyLogId logId,
    required String editId,
    required String action,
    String? driverNotes,
  }) async =>
      throw UnimplementedError();

  @override
  Future<Either<Failure, bool>> reassignDriving({
    required DailyLogId logId,
    required int statusId,
    required int targetCoDriverId,
    required String annotation,
  }) async =>
      throw UnimplementedError();


  @override
  Future<Either<Failure, List<AuditEntry>>> getRecentAuditEntries({int limit = 100}) async => const Right([]);
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
  String? get stationarySince => data['stationary_since'];

  @override
  Future<void> setStationarySince(String value) async {
    data['stationary_since'] = value;
  }
}

void main() {
  group('DutyStatusTracker FakeClock Tests', () {
    late DutyStatusTracker tracker;
    late MockLogRepository mockRepo;
    late FakeTrustedTimeProvider clock;
    late FakeLocalStorage db;

    setUp(() {
      mockRepo = MockLogRepository();
      clock = FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2023, 1, 1, 12, 0, 0));
      db = FakeLocalStorage();
      tracker = DutyStatusTracker(
        logRepository: mockRepo,
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

      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));

      // Should remain driving
      expect(tracker.currentStatus, 'driving');
      expect(db.data['stationary_since'], isNotNull);
      expect(db.data['stationary_since'], isNotEmpty);
    });

    test('2. stationary < 5 min - remains driving', () {
      tracker.manualTransition('driving');
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));

      clock.advance(const Duration(minutes: 4));
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));

      expect(tracker.currentStatus, 'driving');
    });

    test('3. stationary >= 5 min - transitions to on_duty', () {
      tracker.manualTransition('driving');
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));

      clock.advance(const Duration(minutes: 5));
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));

      expect(tracker.currentStatus, 'on_duty');
      expect(db.data['stationary_since'], isEmpty); // should clear
    });

    test('4. movement interrupts stationary period (needs 3s sustained)', () {
      tracker.manualTransition('driving');
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));
      expect(db.data['stationary_since'], isNotNull);

      clock.advance(const Duration(minutes: 3));
      // Moving again - spike (1 event, 0s elapsed)
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 6.0,
          odometerMiles: 10.5,
          engineHours: 1.1,
          timestamp: getClockTime()));
      // Still driving (since it was driving before), but stationary_since should NOT be cleared yet (wait, yes it is cleared on the FIRST event in my logic or 3rd event? Wait... my logic says "if (consecutive >= 3 && elapsed >= 3) { clear stationary timer }". So stationary_since is NOT cleared on the first spike!)
      // Wait, let's verify my logic: I put clearing stationary_since INSIDE the `if (_consecutiveMovingEvents >= 3)` block. So stationary_since is NOT cleared on a spike!

      // Send 3 events spanning 3 seconds
      clock.advance(const Duration(seconds: 1));
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 6.0,
          odometerMiles: 10.5,
          engineHours: 1.1,
          timestamp: getClockTime()));
      clock.advance(const Duration(seconds: 2));
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 6.0,
          odometerMiles: 10.5,
          engineHours: 1.1,
          timestamp: getClockTime()));

      expect(tracker.currentStatus, 'driving');
      expect(db.data['stationary_since'],
          isEmpty); // Timer cancelled after 3 seconds
    });

    test('5. restart during stationary hydration', () {
      tracker.manualTransition('driving');
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));

      // Simulate app kill and advance clock by 6 minutes
      final savedData = db.data;
      clock.advance(const Duration(minutes: 6));

      // New app session
      final newDb = FakeLocalStorage()..data = savedData;
      final newTracker = DutyStatusTracker(
        logRepository: mockRepo,
        localStorage: newDb,
        syncEngine: MockSyncEngine(),
        dashboardBackend: MockDashboardBackend(),
        timeProvider: clock,
      );
      // The status should hydrate to driving, and stationarySince should be intact.
      // Now, an event arrives (which triggers _evaluateStationaryState if speed is 0)
      newTracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));

      expect(newTracker.currentStatus, 'on_duty');
      expect(newDb.data['stationary_since'], isEmpty);
      newTracker.dispose();
    });
  });

  group('Fake Location Streamer Tests', () {
    late DutyStatusTracker tracker;
    late MockLogRepository mockRepo;
    late FakeTrustedTimeProvider clock;
    late FakeLocalStorage db;

    setUp(() {
      mockRepo = MockLogRepository();
      clock = FakeTrustedTimeProvider(initialUtcTime: DateTime.now().toUtc());
      db = FakeLocalStorage();
      tracker = DutyStatusTracker(
        logRepository: mockRepo,
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
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 4.9,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));
      expect(tracker.currentStatus, 'off_duty');
    });

    test('at threshold (= 5.0) remains current status', () {
      expect(tracker.currentStatus, 'off_duty');
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 5.0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));
      expect(tracker.currentStatus, 'off_duty');
    });

    test('above threshold (> 5.0) but only 1 event (spike) does not transition',
        () {
      expect(tracker.currentStatus, 'off_duty');
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 5.1,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));
      expect(tracker.currentStatus, 'off_duty');
    });

    test(
        'above threshold (> 5.0) for 3 consecutive events across 3 seconds transitions to driving',
        () {
      expect(tracker.currentStatus, 'off_duty');

      // Event 1 (0s)
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 5.1,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));
      expect(tracker.currentStatus, 'off_duty');

      // Event 2 (1s)
      clock.advance(const Duration(seconds: 1));
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 5.1,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));
      expect(tracker.currentStatus, 'off_duty');

      // Event 3 (3s)
      clock.advance(const Duration(seconds: 2));
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 5.1,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));
      expect(tracker.currentStatus, 'driving');
    });

    test('interrupted spike resets consecutive counter', () {
      expect(tracker.currentStatus, 'off_duty');

      // Event 1 (> 5)
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 5.1,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));

      // Event 2 (<= 5) - interrupts the streak
      clock.advance(const Duration(seconds: 1));
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 4.0,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));

      // Event 3 (> 5)
      clock.advance(const Duration(seconds: 1));
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 5.1,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));

      // Event 4 (> 5)
      clock.advance(const Duration(seconds: 2));
      tracker.processEldEvent(EldEvent(fromEcm: true, 
          speedMph: 5.1,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));

      // Still off_duty because the streak was broken and the new streak is only 2 events
      expect(tracker.currentStatus, 'off_duty');
    });

    test('phone or simulated speed does not create a driving record', () {
      expect(tracker.currentStatus, 'off_duty');
      tracker.processEldEvent(EldEvent(
          fromEcm: false,
          speedMph: 40,
          odometerMiles: 10,
          engineHours: 1,
          timestamp: getClockTime()));
      clock.advance(const Duration(seconds: 4));
      tracker.processEldEvent(EldEvent(
          fromEcm: false,
          speedMph: 40,
          odometerMiles: 12,
          engineHours: 1,
          timestamp: getClockTime()));
      expect(tracker.currentStatus, 'off_duty');
    });
  });

  group('legal duty stamp', () {
    late MockLogRepository mockRepo;
    late FakeLocalStorage db;
    late MockSyncEngine sync;
    late MockDashboardBackend dashboard;

    DutyStatusTracker build({
      TrustedTimeProvider? time,
      int? Function()? readDriverId,
    }) {
      return DutyStatusTracker(
        logRepository: mockRepo,
        localStorage: db,
        syncEngine: sync,
        dashboardBackend: dashboard,
        timeProvider: time ?? FakeTrustedTimeProvider(),
        readDriverId: readDriverId,
      );
    }

    setUp(() {
      mockRepo = MockLogRepository();
      db = FakeLocalStorage();
      sync = MockSyncEngine();
      dashboard = MockDashboardBackend();
    });

    test('missing trusted time rejects the duty event and does not stamp it', () {
      final tracker = build();
      final refusal = tracker.manualTransition('on_duty');

      expect(refusal, DutyStampRefusal.timeUnavailable);
      expect(tracker.currentStatus, 'off_duty');
      expect(sync.submitted, isEmpty);
      expect(sync.reported, isEmpty);
      tracker.dispose();
    });

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

    test('accepted manual change hits the dashboard endpoint, not the queue',
        () async {
      final trusted = DateTime.utc(2026, 9, 23, 8, 15);
      final clock = FakeTrustedTimeProvider(initialUtcTime: trusted);
      final tracker = build(time: clock, readDriverId: () => 106);

      final refusal = await tracker.submitManualChange('on_duty',
          annotation: 'Available');

      expect(refusal, isNull);
      expect(tracker.currentStatus, 'on_duty');
      expect(dashboard.lastStatus, DutyStatusCode.onDutyNotDriving);
      expect(dashboard.lastNotes, 'Available');
      // المسار اليدوي لم يعد يمر بطابور الأحداث (دلالة 02.3 لا 05.2)
      expect(sync.submitted, isEmpty);
      expect(sync.reported, isEmpty);
      tracker.dispose();
    });

    test('server rejection does not change local duty status', () async {
      final clock = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 9, 23, 8),
      );
      dashboard.updateResult = const Left(ServerError(code: 'server.rejected'));
      final tracker = build(time: clock, readDriverId: () => 106);

      final refusal = await tracker.submitManualChange('sleeper');

      expect(refusal, DutyStampRefusal.serverRejected);
      expect(tracker.currentStatus, 'off_duty');
      expect(dashboard.lastStatus, DutyStatusCode.sleeperBerth);
      expect(sync.reported, isEmpty);
      tracker.dispose();
    });
  });
}
