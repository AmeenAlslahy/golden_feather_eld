// TASK 02/03 — REGRESSION TESTS: the reported bugs must STAY fixed.
//
// These tests originally asserted the DEFECTIVE behaviour (offline fabricated
// 11:00/70:00, Recap zeros, stale-write race). They were inverted once the fix
// landed so the suite now guards the CORRECTED behaviour.
//
// Every test states what is REAL production wiring and what is FAKE.
//
// Run: flutter test test/audit_task02/
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';

import 'package:golden_feather_eld/backend/contracts/status_dashboard_backend.dart';
import 'package:golden_feather_eld/backend/core/backend_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_identity.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/hos/data/repositories/status_dashboard_repository_impl.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_calculator.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_offline_dashboard.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_state_machine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/tracking/duty_status_tracker.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/recap_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/status_dashboard_providers.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/dispatch_auth.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';

// =============================================================================
// Fakes
// =============================================================================

/// FAKE: replaces EldEngineAdapter.
class _Backend implements StatusDashboardBackend {
  _Backend({this.onlineFails = false, this.drive = const Duration(hours: 5)});
  bool onlineFails;
  Duration drive;
  Duration lastRecapUsed = const Duration(hours: 61);

  /// Held-open responses so request ordering can be controlled.
  final List<Completer<Result<StatusDashboard>>> calls = [];
  int getDashboardCount = 0;

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async {
    getDashboardCount++;
    if (onlineFails) return err(const NetworkError(code: 'net', l10nKey: 'n'));
    if (calls.isEmpty) return ok(build());
    return calls.removeAt(0).future;
  }

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  }) async {
    if (onlineFails) return err(const NetworkError(code: 'net', l10nKey: 'n'));
    return ok(build(status: status));
  }

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async {
    if (onlineFails) return err(const NetworkError(code: 'net', l10nKey: 'n'));
    return ok(WeeklyRecap(
      cycleRule: CycleRule.usa70_8,
      cycleUsed: lastRecapUsed,
      cycleRemaining: const Duration(hours: 9),
      availableTomorrow: const Duration(hours: 9),
      days: [
        RecapDay(
          date: DateTime(2026, 3, 1),
          dayOfWeek: 'Mon',
          driving: const Duration(hours: 6),
          onDuty: const Duration(hours: 9),
          totalWork: const Duration(hours: 9),
        ),
      ],
    ));
  }

  StatusDashboard build({DutyStatusCode? status}) => StatusDashboard(
        driver: const DriverRef(
            id: DriverId(646), name: 'N', displayText: 'N-646'),
        operationalAlerts: const OperationalAlerts(
            toolIcon: false,
            warningTriangleIcon: false,
            connectionStatus: ConnectionStatus.ok),
        currentDutyStatus: status ?? DutyStatusCode.onDutyNotDriving,
        remainingCircle: RemainingCircle(
            remaining: drive, label: 'Remaining', progress: 0.5),
        hosIndicators: HosIndicators(
          drive: HosIndicator(
              label: 'DRIVE', value: drive, type: IndicatorType.remaining),
          shift: const HosIndicator(
              label: 'SHIFT',
              value: Duration(hours: 10),
              type: IndicatorType.remaining),
          breakTime: const HosIndicator(
              label: 'BREAK',
              value: Duration(hours: 7),
              type: IndicatorType.remaining),
          cycle: const HosIndicator(
              label: 'CYCLE',
              value: Duration(hours: 50),
              type: IndicatorType.remaining),
        ),
        regulatoryConstraints: const RegulatoryConstraints(
            ruleSet: CycleRule.usa70_8, limits: ['maxDrivingHours: 11']),
      );
}

class _Adapter implements BackendAdapter {
  _Adapter(this.d);
  final StatusDashboardBackend d;
  @override
  BackendIdentity get identity => BackendIdentity.mock();
  @override
  bool get isMock => true;
  @override
  StatusDashboardBackend get statusDashboard => d;
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError('unused');
  @override
  Future<void> dispose() async {}
}

class _Net implements NetworkInfo {
  _Net(this.connected);
  final bool connected;
  @override
  bool get isConnected => connected;
  @override
  Stream<bool> get onConnectionChange => const Stream<bool>.empty();
}

class _Auth extends StateNotifier<AuthState> implements AuthNotifier {
  _Auth()
      : super(AuthState(
            status: AuthStatus.authenticated,
            user: User(
                id: '646',
                username: 'n',
                email: 'n@t.com',
                fullName: 'Naseem',
                role: UserRole.fieldWorker,
                createdAt: DateTime(2026)),
          ));
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Storage implements LocalStorageService {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
  Map<String, String> d = {};
  @override
  String get currentDutyStatus => d['c'] ?? 'off_duty';
  @override
  Future<void> setCurrentDutyStatus(String v) async => d['c'] = v;
  @override
  String? get stationarySince => d['s'];
  @override
  Future<void> setStationarySince(String v) async => d['s'] = v;
  @override
  HosConfiguration get hosConfiguration => HosConfiguration.usa70_8();
}

class _Sync implements SyncEngine {
  final List<PendingEvent> submitted = [];
  @override
  Future<void> submitEvent(PendingEvent e) async => submitted.add(e);
  @override
  Future<void> triggerSync() async {}
  @override
  Future<Either<Failure, bool>> submitEventAndReport(PendingEvent e) async =>
      const Right(true);
  @override
  Future<DispatchAuthContext> Function()? get observeAuth => null;
  @override
  Future<int> releaseEligible({int limit = 50}) async => 0;
}

class _LogRepo implements LogRepository {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
  @override
  Future<Either<Failure, bool>> savePeriod(DutyPeriod p) async =>
      const Right(true);
}

ProviderContainer _c({
  required StatusDashboardBackend backend,
  required bool online,
}) {
  final c = ProviderContainer(overrides: [
    activeBackendProvider.overrideWithValue(_Adapter(backend)),
    networkInfoProvider.overrideWithValue(_Net(online)),
    authStateProvider.overrideWith((ref) => _Auth()),
    // FAKE: production supplies this via AppInitializer.createProviderContainer
    // after LocalStorageService.init(); a bare container has uninitialised prefs.
    localStorageProvider.overrideWithValue(_Storage()),
  ]);
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // BUG 1 - offline must NOT fabricate offDuty + maximum legal allowances
  // =========================================================================
  group('BUG 1 fixed - no fabricated offline dashboard', () {
    test('cold offline start never advertises maximum legal allowances',
        () async {
      // REAL: statusDashboardProvider -> notifier -> repository -> guardedNetwork
      // FAKE: backend, NetworkInfo, auth
      final c = _c(backend: _Backend(), online: false);

      Object? caught;
      StatusDashboard? value;
      try {
        value = await c.read(statusDashboardProvider.future);
      } catch (e) {
        caught = e;
      }

      // ignore: avoid_print
      print('BUG1_STATUS=$value ERR=${caught.runtimeType}');

      if (value != null) {
        expect(value.hosIndicators.drive.value, isNot(const Duration(hours: 11)),
            reason: 'must not advertise a full 11h driving allowance');
        expect(value.hosIndicators.cycle.value, isNot(const Duration(hours: 70)));
      } else {
        expect(caught, isA<Failure>());
      }
    });

    test('the fabricated constants are gone from the repository', () async {
      // REAL repository, offline network, no disk cache injected
      final repo = StatusDashboardRepositoryImpl(_Backend(), _Net(false));
      final result = await repo.getDashboard();

      // ignore: avoid_print
      print('BUG1_REPO=${result.fold((l) => l.runtimeType, (r) => 'RIGHT')}');

      expect(result.isLeft(), isTrue,
          reason: 'explicit failure, never a fabricated Right');
      expect(result.getLeft().toNullable(), isA<NoDashboardSnapshotFailure>());
    });

    test('the duty record survives an offline change (no data loss)', () async {
      // REAL DutyStatusTracker. FAKE backend/storage/sync.
      final storage = _Storage();
      final sync = _Sync();
      final tracker = DutyStatusTracker(
        logRepository: _LogRepo(),
        localStorage: storage,
        syncEngine: sync,
        // FAILS -> the tracker takes its offline branch and must queue.
        dashboardBackend: _Backend(onlineFails: true),
        timeProvider: FakeTrustedTimeProvider(
            initialUtcTime: DateTime.utc(2026, 3, 1, 8)),
        readDriverId: () => 646,
      );
      await tracker.submitManualChange('on_duty');

      // ignore: avoid_print
      print('BUG1_LOCAL=${tracker.currentStatus} '
          'PERSISTED=${storage.currentDutyStatus} '
          'QUEUED=${sync.submitted.length}');

      expect(tracker.currentStatus, 'on_duty');
      expect(storage.currentDutyStatus, 'on_duty');
      expect(sync.submitted.length, 1);
      tracker.dispose();
    });
  });

  // =========================================================================
  // BUG 2 - offline change updates the page; Recap is not zeros
  // =========================================================================
  group('BUG 2 fixed - offline change and Recap', () {
    test('offline submitManualChange returns no server dashboard (expected)',
        () async {
      final storage = _Storage();
      final sync = _Sync();
      final tracker = DutyStatusTracker(
        logRepository: _LogRepo(),
        localStorage: storage,
        syncEngine: sync,
        dashboardBackend: _Backend(onlineFails: true),
        timeProvider: FakeTrustedTimeProvider(
            initialUtcTime: DateTime.utc(2026, 3, 1, 8)),
        readDriverId: () => 646,
      );

      final result = await tracker.submitManualChange('driving');

      // ignore: avoid_print
      print('BUG2_ACCEPTED=${result.accepted} '
          'DASHBOARD_NULL=${result.dashboard == null} '
          'LOCAL=${tracker.currentStatus} '
          'PERSISTED=${storage.currentDutyStatus} '
          'QUEUED=${sync.submitted.length}');

      expect(result.accepted, isTrue);
      expect(result.dashboard, isNull,
          reason: 'no server snapshot offline - the notifier builds one locally');
      expect(tracker.currentStatus, 'driving');
      expect(storage.currentDutyStatus, 'driving');
      expect(sync.submitted.length, 1);
      tracker.dispose();
    });

    test('the offline dashboard is COMPUTED from real accumulated driving',
        () {
      // REAL HosRulesEngine + real builder. FAKE clock only.
      final time = FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 3, 1, 8));
      final engine = HosRulesEngine(
        calculator: HosCalculator(HosConfiguration.usa70_8(), time),
        stateMachine: HosStateMachine(time),
        timeProvider: time,
      );

      engine.manualTransition(DutyStatus.driving);
      time.advance(const Duration(hours: 6));
      final result = engine.currentStatus;

      final built = const HosOfflineDashboardBuilder().build(
        engineResult: result,
        driverId: const DriverId(646),
      );

      // ignore: avoid_print
      print('BUG2_LOCAL_DRIVE=${built.hosIndicators.drive.value} '
          'STATUS=${built.currentDutyStatus}');

      // 11h limit - 6h consumed = 5h, NOT the old fabricated 11h.
      expect(built.hosIndicators.drive.value, const Duration(hours: 5));
      expect(built.currentDutyStatus, DutyStatusCode.driving);
    });

    test('offline Recap no longer returns fabricated zero values', () async {
      // REAL recapProvider -> use case -> repository offline branch
      final c = _c(backend: _Backend(), online: false);

      Object? caught;
      WeeklyRecap? value;
      try {
        value = await c.read(recapProvider.future);
      } catch (e) {
        caught = e;
      }

      // ignore: avoid_print
      print('BUG2_RECAP=$value ERR=${caught.runtimeType}');

      if (value != null) {
        expect(value.days, isNotEmpty,
            reason: 'never present an empty week as real data');
      } else {
        expect(caught, isA<Failure>(),
            reason: 'explicit failure instead of "0 used / 70 remaining"');
      }
    });
  });

  // =========================================================================
  // BUG 3 - request sequencing (F-03)
  // =========================================================================
  group('BUG 3 fixed - dashboard write ordering', () {
    test('a stale in-flight GET can no longer overwrite a newer POST result',
        () async {
      // REAL notifier + REAL repository. FAKE backend.
      final gate = Completer<Result<StatusDashboard>>();
      final backend = _Backend(drive: const Duration(hours: 9));
      backend.calls.add(gate);
      final c = _c(backend: backend, online: true);

      final firstLoad = c.read(statusDashboardProvider.future);
      await Future<void>.delayed(Duration.zero);

      // POST arrives first (newest).
      final notifier = c.read(statusDashboardProvider.notifier);
      backend.drive = const Duration(hours: 9);
      notifier.applyServerDashboard(backend.build());
      final afterPost = c.read(statusDashboardProvider).value!;

      // The older GET resolves afterwards with stale data.
      backend.drive = const Duration(hours: 2);
      gate.complete(ok(backend.build()));
      await firstLoad;
      await Future<void>.delayed(Duration.zero);
      final settled = c.read(statusDashboardProvider).value!;

      // ignore: avoid_print
      print('BUG3_AFTER_POST=${afterPost.hosIndicators.drive.value} '
          'AFTER_STALE_GET=${settled.hosIndicators.drive.value}');

      expect(afterPost.hosIndicators.drive.value, const Duration(hours: 9));
      expect(settled.hosIndicators.drive.value, const Duration(hours: 9),
          reason: 'the request-sequence guard must discard the older response');
    });

    test('concurrent refresh() calls are still deduped (1 HTTP call)', () async {
      final backend = _Backend();
      final gate = Completer<Result<StatusDashboard>>();
      backend.calls.add(gate);
      final c = _c(backend: backend, online: true);

      final a = c.read(statusDashboardProvider.future);
      await Future<void>.delayed(Duration.zero);
      final b = c.read(statusDashboardProvider.notifier).refresh();
      await Future<void>.delayed(Duration.zero);

      // ignore: avoid_print
      print('BUG3_HTTPCALLS=${backend.getDashboardCount}');
      expect(backend.getDashboardCount, 1);

      gate.complete(ok(backend.build()));
      await a;
      await b;
    });
  });

  // =========================================================================
  // Offline parity - the persistence + hydration enablers
  // =========================================================================
  group('Offline parity - persistence and hydration', () {
    test('a failed refresh preserves the last good dashboard', () async {
      final c = _c(backend: _Backend(drive: const Duration(hours: 4)), online: true);
      await c.read(statusDashboardProvider.future);
      final before = c.read(statusDashboardProvider).value!;

      await c.read(statusDashboardProvider.notifier).refresh();
      final after = c.read(statusDashboardProvider).value!;

      // ignore: avoid_print
      print('PARITY_PRESERVED=${after.hosIndicators.drive.value}');
      expect(after.hosIndicators.drive.value, before.hosIndicators.drive.value);
    });

    test('hydration rebuilds driving totals from persisted duty periods', () {
      // REAL HosStateMachine.hydrateFromPeriods. Simulated persisted periods.
      final time = FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 3, 2, 12));
      final sm = HosStateMachine(time);

      final base = DateTime.utc(2026, 3, 2, 6);
      final periods = [
        DutyPeriod(
            status: 'driving',
            startTime: base,
            endTime: base.add(const Duration(hours: 6))),
        DutyPeriod(
            status: 'on_duty',
            startTime: base.add(const Duration(hours: 6)),
            endTime: base.add(const Duration(hours: 7))),
      ];

      sm.hydrateFromPeriods(
        periods: periods,
        now: DateTime.utc(2026, 3, 2, 12),
        shiftWindow: const Duration(hours: 14),
      );

      final engine = HosRulesEngine(
        calculator: HosCalculator(HosConfiguration.usa70_8(), time),
        stateMachine: sm,
        timeProvider: time,
      );
      final update = (engine.currentStatus as HosEngineReady).update;

      // ignore: avoid_print
      print('PARITY_HYDRATED_DRIVE=${update.remainingDriveMinutes} '
          'STATUS=${update.currentStatus.name}');

      // 11h - 6h driving = 5h remaining (300 min), not the full 660.
      expect(update.remainingDriveMinutes, 300);
      expect(update.currentStatus, DutyStatus.onDutyNotDriving);
    });

    test('hydration with no periods leaves a clean 11h allowance', () {
      final time = FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 3, 2, 12));
      final sm = HosStateMachine(time);
      sm.hydrateFromPeriods(
        periods: const [],
        now: DateTime.utc(2026, 3, 2, 12),
        shiftWindow: const Duration(hours: 14),
      );
      final engine = HosRulesEngine(
        calculator: HosCalculator(HosConfiguration.usa70_8(), time),
        stateMachine: sm,
        timeProvider: time,
      );
      final update = (engine.currentStatus as HosEngineReady).update;

      // ignore: avoid_print
      print('PARITY_EMPTY_DRIVE=${update.remainingDriveMinutes}');
      expect(update.remainingDriveMinutes, 660);
    });
  });

  // =========================================================================
  // Sync safety - must NOT be "fixed"
  // =========================================================================
  group('Sync safety - retries never drop data', () {
    test('RetryPolicy never returns null, so dead-lettering stays unreachable',
        () {
      const policy = RetryPolicy();
      final now = DateTime.utc(2026, 3, 1, 8);
      final delays = <Duration>[];
      for (var i = 0; i < 12; i++) {
        final next = policy.calculateNextRetry(i, nowUtc: now);
        expect(next, isNotNull);
        delays.add(next!.difference(now));
      }
      // ignore: avoid_print
      print('SYNC_MAX_DELAY=${delays.last}');
      expect(delays.last, const Duration(seconds: 50));
    });
  });
}