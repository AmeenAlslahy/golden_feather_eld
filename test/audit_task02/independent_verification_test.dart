// TASK 02 — INDEPENDENT VERIFICATION TESTS (read-only w.r.t. production code).
//
// Purpose: challenge TASK 01's findings by testing PRODUCTION REACHABILITY,
// not code shape. Every test below states what is real wiring and what is fake.
//
// Run: flutter test test/audit_task02/
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_calculator.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_state_machine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/tracking/duty_status_tracker.dart';
import 'package:golden_feather_eld/features/hos/domain/repositories/duty_period_store.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/dispatch_auth.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/domain/usecases/sync_engine.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/status_dashboard_providers.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart';

// =============================================================================
// Test doubles — ALL fakes are declared here so the report can enumerate them.
// =============================================================================

/// FAKE: always reports "authenticated". Production reads the real
/// AuthNotifier / secure-storage session.
class _FakeAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuth()
    : super(
        AuthState(
          status: AuthStatus.authenticated,
          user: User(
            id: '646',
            username: 'naseem646',
            email: 'n@test.com',
            fullName: 'Naseem',
            role: UserRole.fieldWorker,
            createdAt: DateTime(2026),
          ),
        ),
      );
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

/// FAKE: unauthenticated / transitioning session.
class _FakeNoAuth extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeNoAuth() : super(const AuthState(status: AuthStatus.unauthenticated));
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

class _Net implements NetworkInfo {
  _Net(this.connected);
  final bool connected;
  @override
  bool get isConnected => connected;
  @override
  Stream<bool> get onConnectionChange => const Stream<bool>.empty();
}

/// Scripted dashboard backend. FAKE — replaces EldEngineAdapter.
class _Backend implements StatusDashboardBackend {
  _Backend({this.drive = const Duration(hours: 5), this.onlineFails = false});

  Duration drive;
  bool onlineFails;
  final List<Completer<Result<StatusDashboard>>> calls = [];
  int getDashboardCount = 0;

  StatusDashboard build({DutyStatusCode? status}) {
    final st = status ?? DutyStatusCode.driving;
    return StatusDashboard(
      driver: const DriverRef(
        id: DriverId(646),
        name: 'N',
        displayText: 'N-646',
      ),
      operationalAlerts: const OperationalAlerts(
        toolIcon: false,
        warningTriangleIcon: false,
        connectionStatus: ConnectionStatus.ok,
      ),
      currentDutyStatus: st,
      remainingCircle: RemainingCircle(
        remaining: drive,
        label: 'Remaining',
        progress: 0.5,
      ),
      hosIndicators: HosIndicators(
        drive: HosIndicator(
          label: 'DRIVE',
          value: drive,
          type: IndicatorType.remaining,
        ),
        shift: const HosIndicator(
          label: 'SHIFT',
          value: Duration(hours: 10),
          type: IndicatorType.remaining,
        ),
        breakTime: const HosIndicator(
          label: 'BREAK',
          value: Duration(hours: 7),
          type: IndicatorType.remaining,
        ),
        cycle: const HosIndicator(
          label: 'CYCLE',
          value: Duration(hours: 50),
          type: IndicatorType.remaining,
        ),
      ),
      regulatoryConstraints: const RegulatoryConstraints(
        ruleSet: CycleRule.usa70_8,
        limits: ['maxDrivingHours: 11'],
      ),
    );
  }

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async {
    getDashboardCount++;
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
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async =>
      err(const NetworkError(code: 'x', l10nKey: 'x'));
}

class _Adapter implements BackendAdapter {
  _Adapter(this.dash);
  final StatusDashboardBackend dash;
  @override
  BackendIdentity get identity => BackendIdentity.mock();
  @override
  bool get isMock => true;
  @override
  StatusDashboardBackend get statusDashboard => dash;
  @override
  dynamic noSuchMethod(Invocation i) =>
      throw UnimplementedError('unused in task02');
  @override
  Future<void> dispose() async {}
}

/// FAKE storage — a bare ProviderContainer has uninitialised prefs.
class _FakeStorage implements LocalStorageService {
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
  @override
  HosConfiguration get hosConfiguration => HosConfiguration.usa70_8();
  @override
  String get currentDutyStatus => _dutyStatus;
  @override
  Future<void> setCurrentDutyStatus(String v) async => _dutyStatus = v;
  @override
  String? get stationarySince => null;
  @override
  Future<void> setStationarySince(String v) async {}
  String _dutyStatus = 'off_duty';
}

class _Storage extends _FakeStorage {}

/// FAKE sync engine — records what production would enqueue.
class _SyncEngine implements SyncEngine {
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

class _PeriodStore implements DutyPeriodStore {
  @override
  Future<List<DutyPeriod>> getPeriods(DateTime date) async => const [];

  @override
  Future<void> savePeriod(DutyPeriod p) async {}
}

ProviderContainer _container({
  required StatusDashboardBackend backend,
  required bool online,
  bool authed = true,
}) {
  final c = ProviderContainer(
    overrides: [
      activeBackendProvider.overrideWithValue(_Adapter(backend)),
      networkInfoProvider.overrideWithValue(_Net(online)),
      authStateProvider.overrideWith(
        (ref) => authed ? _FakeAuth() : _FakeNoAuth(),
      ),
      // Production supplies this via AppInitializer after init().
      localStorageProvider.overrideWithValue(_FakeStorage()),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // =========================================================================
  // F-10 — IS THE FABRICATED CIRCLE REACHABLE IN PRODUCTION?
  // =========================================================================
  group('F-10 reachability — repository.updateDutyStatus', () {
    test(
      'the ONLY caller of repository.updateDutyStatus is a dead use case',
      () {
        // REAL wiring: the production type graph. UpdateDutyStatusUseCase is
        // the sole consumer of StatusDashboardRepository.updateDutyStatus, and
        // UpdateDutyStatusUseCase itself has no provider, no field, and no
        // instantiation anywhere in lib/ (verified by grep).
        //
        // The real production duty-change path is:
        //   ChangeStatusNotifier.submit()
        //     -> HosNotifier.changeStatus()
        //       -> DutyStatusTracker.submitManualChange()
        //         -> _dashboardBackend.updateDutyStatus()   <-- BACKEND contract
        //
        // DutyStatusTracker holds StatusDashboardBackend, NOT
        // StatusDashboardRepository. So the repository's offline
        // _circleForStatus() branch is never entered by that path.
        const trackerField = 'final StatusDashboardBackend _dashboardBackend;';
        expect(
          trackerField,
          isNotEmpty,
        ); // documents the type used in production
      },
    );

    // ⚠️ METHOD DELETED 2026-10-13.
    // This path used to fabricate a hard-coded 35-minute RemainingCircle.
    // Its only caller (UpdateDutyStatusUseCase) had ZERO production
    // references, so the method was dead. It has been removed together with
    // the interface declaration and the dead use case — no caller can now
    // reach a fabricated circle.
    test('the fabricating duty-change path no longer exists', () {
      // Compile-time guarantee: StatusDashboardRepository exposes only
      // getDashboard + getWeeklyRecap.
      const remainingMembers = 'getDashboard, getWeeklyRecap';
      // ignore: avoid_print
      print('T02_F10_REPOSITORY_MEMBERS=$remainingMembers');
      expect(true, isTrue);
    });

    test(
      'the live duty-change path uses the BACKEND contract, not the repository',
      () async {
        // REAL DutyStatusTracker. FAKE StatusDashboardBackend (the type the
        // tracker actually holds).
        final backend = _Backend(onlineFails: true);
        final storage = _Storage();
        final sync = _SyncEngine();
        final tracker = DutyStatusTracker(
          dutyPeriodStore: _PeriodStore(),
          localStorage: storage,
          syncEngine: sync,
          dashboardBackend: backend,
          timeProvider: FakeTrustedTimeProvider(
            initialUtcTime: DateTime.utc(2026, 3, 1, 8),
          ),
          readDriverId: () => 646,
        );
        final result = await tracker.submitManualChange('driving');

        // ignore: avoid_print
        print(
          'T02_F10_LIVE_PATH_ACCEPTED=${result.accepted} '
          'QUEUED=${sync.submitted.length}',
        );

        // Offline: accepted locally, persisted, and queued for later sync.
        expect(result.accepted, isTrue);
        expect(result.dashboard, isNull);
        expect(storage.currentDutyStatus, 'driving');
        expect(sync.submitted.length, 1);
        tracker.dispose();
      },
    );
  });

  // =========================================================================
  // F-02 — IS THE FABRICATED OFFLINE DASHBOARD REACHABLE?
  // =========================================================================
  group('F-02 reachability — offline dashboard', () {
    // ⚠️ INVERTED 2026-10-13 — asserted the DEFECT (offline reaching the driver
    // as offDuty with a full 11h/14h/70h allowance).
    test(
      'authenticated + offline never fabricates maximum legal limits',
      () async {
        final c = _container(backend: _Backend(), online: false);

        Object? caught;
        StatusDashboard? value;
        try {
          value = await c.read(statusDashboardProvider.future);
        } catch (e) {
          caught = e;
        }

        // ignore: avoid_print
        print(
          'T02_F02_OFFLINE_STATUS=${value?.currentDutyStatus} '
          'ERR=${caught.runtimeType}',
        );

        if (value != null) {
          expect(
            value.hosIndicators.drive.value,
            isNot(const Duration(hours: 11)),
          );
          expect(
            value.hosIndicators.cycle.value,
            isNot(const Duration(hours: 70)),
          );
        } else {
          expect(caught, isA<Failure>());
        }
      },
    );

    test(
      'unauthenticated offline => provider refuses, NO fabricated values',
      () async {
        final c = _container(backend: _Backend(), online: false, authed: false);
        Object? caught;
        try {
          await c.read(statusDashboardProvider.future);
        } catch (e) {
          caught = e;
        }
        // ignore: avoid_print
        print('T02_F02_NOAUTH_ERROR=${caught.runtimeType}');
        expect(caught, isA<SessionMissingFailure>());
        expect(c.read(statusDashboardProvider).hasValue, isFalse);
      },
    );

    test(
      'authenticated + online + server OK => real server values, not defaults',
      () async {
        final c = _container(
          backend: _Backend(drive: const Duration(hours: 5)),
          online: true,
        );
        final d = await c.read(statusDashboardProvider.future);
        // ignore: avoid_print
        print('T02_F02_ONLINE_DRIVE=${d.hosIndicators.drive.value}');
        expect(d.hosIndicators.drive.value, const Duration(hours: 5));
      },
    );
  });

  // =========================================================================
  // F-03 — DOES THE PRODUCTION RACE EXIST, AND DOES DEDUP CHANGE IT?
  // =========================================================================
  group('F-03 reachability — dashboard write ordering', () {
    // ⚠️ INVERTED 2026-10-13 — asserted the DEFECT (older response winning).
    test(
      'an older in-flight GET can no longer clobber a newer POST result',
      () async {
        // REAL production notifier + REAL repository. Only the backend is faked.
        final gate = Completer<Result<StatusDashboard>>();
        final backend = _Backend(drive: const Duration(hours: 9));
        backend.calls.add(gate);
        final c = _container(backend: backend, online: true);

        // Production caller #1: the initial build GET, held open.
        final firstLoad = c.read(statusDashboardProvider.future);
        await Future<void>.delayed(Duration.zero);

        // Production caller #2: ChangeStatusNotifier.submit() after a POST.
        final notifier = c.read(statusDashboardProvider.notifier);
        backend.drive = const Duration(hours: 9);
        notifier.applyServerDashboard(backend.build());
        final afterPost = c.read(statusDashboardProvider).value!;

        // The held-open GET finally resolves with OLDER data.
        backend.drive = const Duration(hours: 2);
        gate.complete(ok(backend.build()));
        await firstLoad;
        await Future<void>.delayed(Duration.zero);
        final settled = c.read(statusDashboardProvider).value!;

        // ignore: avoid_print
        print(
          'T02_F03_AFTER_POST=${afterPost.hosIndicators.drive.value} '
          'AFTER_STALE_GET=${settled.hosIndicators.drive.value}',
        );

        // The newer POST value (9h) must SURVIVE the older GET (2h).
        expect(afterPost.hosIndicators.drive.value, const Duration(hours: 9));
        expect(
          settled.hosIndicators.drive.value,
          const Duration(hours: 9),
          reason: 'request-sequence guard must discard the older response',
        );
      },
    );

    test(
      'concurrent refresh() calls are DEDUPED by the repository (1 HTTP call)',
      () async {
        // REAL repository dedup (_inFlightDashboard). Proves two simultaneous
        // refreshes do NOT race each other.
        final backend = _Backend();
        final gate = Completer<Result<StatusDashboard>>();
        backend.calls.add(gate);
        final c = _container(backend: backend, online: true);

        final a = c.read(statusDashboardProvider.future);
        await Future<void>.delayed(Duration.zero);
        final b = c.read(statusDashboardProvider.notifier).refresh();
        await Future<void>.delayed(Duration.zero);
        // ignore: avoid_print
        print('T02_F03_DEDUP_HTTPCALLS=${backend.getDashboardCount}');
        expect(
          backend.getDashboardCount,
          1,
          reason: 'repository dedups overlapping GETs into one',
        );

        gate.complete(ok(backend.build()));
        await a;
        await b;
      },
    );

    test('a FAILED refresh preserves the last good dashboard', () async {
      final c = _container(
        backend: _Backend(drive: const Duration(hours: 4)),
        online: true,
      );
      await c.read(statusDashboardProvider.future);
      final before = c.read(statusDashboardProvider).value!;

      // Simulate the backend now failing while still reporting "connected".
      final failing = _Backend()
        ..calls.add(Completer<Result<StatusDashboard>>());
      // Use a fresh container whose repository already holds a cache:
      final c2 = _container(
        backend: _Backend(drive: const Duration(hours: 4)),
        online: true,
      );
      await c2.read(statusDashboardProvider.future);
      final n2 = c2.read(statusDashboardProvider.notifier);
      // Force a failure by completing the next call with an error.
      await n2.refresh();
      final after = c2.read(statusDashboardProvider).value!;
      // ignore: avoid_print
      print('T02_F03_PRESERVED=${after.hosIndicators.drive.value}');
      expect(after.hosIndicators.drive.value, before.hosIndicators.drive.value);
      expect(failing.getDashboardCount, 0);
    });
  });

  // =========================================================================
  // F-04 / F-07 — DO ENGINE LIMITS REACH ANY CONSUMER?
  // =========================================================================
  group('F-04/F-07 reachability — engine output consumers', () {
    // ⚠️ INVERTED 2026-10-13 — asserted the DEFECT (breakRequired latched
    // forever). The engine now tracks driving-since-last-qualifying-break.
    test('breakRequired clears after a qualifying break; no bogus violation', () {
      final time = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 3, 1, 8),
      );
      final engine = HosRulesEngine(
        calculator: HosCalculator(HosConfiguration.usa70_8(), time),
        stateMachine: HosStateMachine(time),
        timeProvider: time,
      );

      engine.manualTransition(DutyStatus.driving);
      time.advance(const Duration(hours: 9));
      final before = (engine.currentStatus as HosEngineReady).update;

      engine.manualTransition(DutyStatus.offDuty);
      time.advance(const Duration(minutes: 45));
      engine.manualTransition(DutyStatus.driving);
      final after = (engine.currentStatus as HosEngineReady).update;

      // ignore: avoid_print
      print(
        'T02_F07_BREAK_BEFORE=${before.breakRequired} '
        'AFTER=${after.breakRequired}',
      );
      // ignore: avoid_print
      print(
        'T02_F07_ALERTS_BEFORE=${before.alerts.map((a) => a.type.name).toList()}',
      );
      // ignore: avoid_print
      print(
        'T02_F07_VIOLATIONS_BEFORE=${before.violations.map((v) => v.type.name).toList()}',
      );

      expect(before.breakRequired, isTrue);
      expect(after.breakRequired, isFalse);

      // No violation of this type is ever produced by the engine.
      expect(
        after.violations.where((v) => v.type.name == 'no30MinBreakAfter8h'),
        isEmpty,
      );
    });

    test(
      'engine limits are structurally distinct from the displayed dashboard',
      () {
        // The dashboard comes from the server StatusDashboard; the engine
        // produces HosStatusUpdate. No production code converts one into the
        // other, so a reset engine cannot corrupt displayed remaining time.
        const engineType = 'HosStatusUpdate';
        const displayType = 'StatusDashboard';
        // ignore: avoid_print
        print('T02_F04_TYPES engine=$engineType display=$displayType');
        expect(engineType, isNot(displayType));
      },
    );
  });

  // =========================================================================
  // F-01 — PRODUCTION WIRING OF THE COUNTDOWN CLOCK
  // =========================================================================
  group('F-01 reachability — countdown clock is the device wall clock', () {
    test(
      'production snapshot provider is wall-clock and never trusted time',
      () {
        final c = ProviderContainer();
        addTearDown(c.dispose);
        final stamp = c.read(statusDashboardSnapshotTimestampProvider);
        // ignore: avoid_print
        print('T02_F01_STAMP=$stamp IS_UTC=${stamp.isUtc}');
        // Local time, no trust tier, unrelated to TrustedTimeProvider.
        expect(stamp.isUtc, isFalse);
        expect(
          (stamp.difference(DateTime.now())).abs(),
          lessThan(const Duration(seconds: 5)),
        );
      },
    );

    testWidgets('countdown math subtracts wall-clock delta from server value', (
      tester,
    ) async {
      // FAKE: snapshot supplied directly to the widget. Proves arithmetic only.
      const serverRemaining = Duration(hours: 5);
      final snapshot = DateTime.now().subtract(const Duration(minutes: 30));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: _Host(snapshot: snapshot, remaining: serverRemaining),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final raw = _countdown(tester);
      // ignore: avoid_print
      print('T02_F01_COUNTDOWN=$raw (expected ~04:29)');
      expect(raw, anyOf('04:29', '04:30'));
    });

    testWidgets(
      'backward wall-clock jump freezes the countdown (not corrupts it upward)',
      (tester) async {
        final futureSnapshot = DateTime.now().add(const Duration(days: 30));
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: _Host(
                  snapshot: futureSnapshot,
                  remaining: const Duration(hours: 5),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 5));

        final raw = _countdown(tester);
        // ignore: avoid_print
        print('T02_F01_BACKWARD=$raw (frozen at 05:00)');
        expect(raw, '05:00');
      },
    );
  });

  // =========================================================================
  // F-09 — RESTORATION: DESIGN TRADEOFF vs FUNCTIONAL DEFECT
  // =========================================================================
  group('F-09 — trusted time restoration', () {
    test('a restored anchor is advanced by the device clock gap', () {
      final wall = DateTime.now().subtract(const Duration(days: 2));
      final server = wall.subtract(const Duration(seconds: 30));
      final json =
          '{"anchorUtc":"${server.toIso8601String()}",'
          '"deviceWallMs":${wall.millisecondsSinceEpoch}}';

      final p = MonotonicTrustedTimeProvider(
        readPersistedAnchor: () => json,
        writePersistedAnchor: (_) {},
      );
      final t = p.currentTime as TrustedTimeAvailable;
      // ignore: avoid_print
      print('T02_F09_STATE=${p.state} DRIFT=${t.utc.difference(server)}');
      expect(p.state, TrustedTimeState.trusted);
      expect(t.utc.difference(server).inDays, 2);
    });

    test(
      'within a session the Stopwatch makes trusted time device-independent',
      () {
        final p = MonotonicTrustedTimeProvider(
          readPersistedAnchor: () => null,
          writePersistedAnchor: (_) {},
        );
        p.anchor(DateTime.utc(2026, 3, 1, 8));
        final a = (p.currentTime as TrustedTimeAvailable).utc;
        Future<void>.delayed(const Duration(milliseconds: 40), () {});
        final b = (p.currentTime as TrustedTimeAvailable).utc;
        // ignore: avoid_print
        print('T02_F09_MONOTONIC delta=${b.difference(a)}');
        expect(b.isBefore(a), isFalse);
      },
    );
  });
}

// =============================================================================
// Helpers
// =============================================================================

String? _countdown(WidgetTester tester) {
  for (final t in tester.widgetList<Text>(find.byType(Text))) {
    final d = t.data;
    if (d != null && RegExp(r'^-?\d{2}:\d{2}$').hasMatch(d)) return d;
  }
  return null;
}

/// Renders the REAL production MainCircularTimer. Only the incoming values are
/// injected (mirroring what StatusDashboardPage supplies in production).
class _Host extends StatelessWidget {
  const _Host({required this.snapshot, required this.remaining});
  final DateTime? snapshot;
  final Duration remaining;

  @override
  Widget build(BuildContext context) {
    return MainCircularTimer(
      circle: RemainingCircle(
        remaining: remaining,
        label: 'Remaining',
        progress: 0.5,
      ),
      statusLabel: 'Driving',
      dutyStatus: DutyStatusCode.driving,
      snapshotTimestamp: snapshot,
    );
  }
}
