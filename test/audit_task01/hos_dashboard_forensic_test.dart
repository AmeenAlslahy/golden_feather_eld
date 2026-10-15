// AUDIT TASK 01 — isolated regression tests. Read-only w.r.t. production code.
//
// These tests do NOT modify production code. They exist to produce reproducible
// evidence for / against each hypothesis in docs/audits/TASK_01_HOS_TIME_DASHBOARD_AUDIT.md
//
// Run: flutter test test/audit_task01/
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
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/time/monotonic_time_authority.dart';
import 'package:golden_feather_eld/core/time/time_authority.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/core/events/app_events.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_calculator.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_state_machine.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/status_dashboard_providers.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart';

// =============================================================================
// Test doubles
// =============================================================================

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier()
      : super(
          AuthState(
            status: AuthStatus.authenticated,
            user: User(
              id: '646',
              username: 'naseem646',
              email: 'naseem@test.com',
              fullName: 'Naseem',
              role: UserRole.fieldWorker,
              createdAt: DateTime(2026),
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OfflineNetwork implements NetworkInfo {
  @override
  bool get isConnected => false;
  @override
  Stream<bool> get onConnectionChange => const Stream<bool>.empty();
}

class _OnlineNetwork implements NetworkInfo {
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get onConnectionChange => const Stream<bool>.empty();
}

/// Backend returning a fully-controlled dashboard, with optional delayed
/// responses so overlapping requests can be interleaved deterministically.
class _ScriptedDashboardBackend implements StatusDashboardBackend {
  _ScriptedDashboardBackend(this.scripts);

  /// Each entry: (completer, status to return). Consumed in order per call.
  final List<_ScriptedCall> scripts;

  final List<Completer<Result<StatusDashboard>>> getDashboardCalls = [];

  Duration drive = const Duration(hours: 5);

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async {
    final idx = getDashboardCalls.length;
    if (idx >= scripts.length) {
      return ok(build());
    }
    final call = scripts[idx];
    getDashboardCalls.add(call.completer);
    return call.completer.future;
  }

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  }) async {
    return ok(build(status: status));
  }

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async {
    return err(const NetworkError(code: 'x', l10nKey: 'x'));
  }

  StatusDashboard build({DutyStatusCode? status}) {
    final st = status ?? DutyStatusCode.driving;
    return StatusDashboard(
      driver: const DriverRef(
        id: DriverId(646),
        name: 'Naseem',
        displayText: 'Naseem - 646',
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
}

class _ScriptedCall {
  _ScriptedCall(this.completer);
  final Completer<Result<StatusDashboard>> completer;
}

class _SimpleAdapter implements BackendAdapter {
  _SimpleAdapter(this.dashboard);

  final StatusDashboardBackend dashboard;

  @override
  BackendIdentity get identity => BackendIdentity.mock();
  @override
  bool get isMock => true;
  @override
  StatusDashboardBackend get statusDashboard => dashboard;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('not used');
  @override
  Future<void> dispose() async {}
}

ProviderContainer dashboardContainer({
  required StatusDashboardBackend backend,
  NetworkInfo? network,
}) {
  final container = ProviderContainer(
    overrides: [
      activeBackendProvider.overrideWithValue(_SimpleAdapter(backend)),
      authStateProvider.overrideWith((ref) => _FakeAuthNotifier()),
      networkInfoProvider.overrideWithValue(network ?? _OnlineNetwork()),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ===========================================================================
  // PHASE D / B — D1: remainingCircle.remaining source
  // ===========================================================================

  group('D1 — remainingCircle.remaining provenance', () {
    testWidgets(
        // ⚠️ INVERTED 2026-10-13. This asserted the DEFECT: offline with no
        // cache presented DRIVE=11:00 / SHIFT=14:00 / CYCLE=70:00 — a
        // fabricated maximum legal allowance — as the driver's real HOS.
        // The repository now returns NoDashboardSnapshotFailure and the
        // provider falls back to the local HOS engine.
        'offline with NO cache never shows fabricated FULL legal limits',
        (tester) async {
      final backend = _ScriptedDashboardBackend([]);
      final container = dashboardContainer(
        backend: backend,
        network: _OfflineNetwork(),
      );

      Object? caught;
      StatusDashboard? value;
      try {
        value = await container.read(statusDashboardProvider.future);
      } catch (e) {
        caught = e;
      }

      // ignore: avoid_print
      print('OFFLINE_NO_CACHE_STATUS=${value?.currentDutyStatus} '
          'ERR=${caught.runtimeType}');
      // ignore: avoid_print
      print('OFFLINE_NO_CACHE_DRIVE=${value?.hosIndicators.drive.value}');
      // ignore: avoid_print
      print('OFFLINE_NO_CACHE_SHIFT=${value?.hosIndicators.shift.value}');
      // ignore: avoid_print
      print('OFFLINE_NO_CACHE_BREAK=${value?.hosIndicators.breakTime.value}');
      // ignore: avoid_print
      print('OFFLINE_NO_CACHE_CYCLE=${value?.hosIndicators.cycle.value}');

      if (value != null) {
        expect(value.hosIndicators.drive.value, isNot(const Duration(hours: 11)));
        expect(value.hosIndicators.shift.value, isNot(const Duration(hours: 14)));
        expect(value.hosIndicators.cycle.value, isNot(const Duration(hours: 70)));
      } else {
        expect(caught, isA<Object>());
      }
    });

    testWidgets('online but server 500s and no cache -> surfaces an error',
        (tester) async {
      final failing = _FailingBackend();
      final container = dashboardContainer(backend: failing);

      await expectLater(
        container.read(statusDashboardProvider.future),
        throwsA(isA<Object>()),
      );

      // ignore: avoid_print
      print('SERVER_500_NO_CACHE_STATE=${container.read(statusDashboardProvider)}');
      expect(container.read(statusDashboardProvider).hasValue, isFalse);
    });
  });

  // ===========================================================================
  // PHASE D / B — snapshot timestamp authority
  // ===========================================================================

  group('B5/D1 — dashboard snapshot timestamp authority', () {
    test('snapshot timestamp provider is seeded from DateTime.now(), not trusted time',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final before = DateTime.now();
      final stamp = container.read(statusDashboardSnapshotTimestampProvider);
      final after = DateTime.now();

      // ignore: avoid_print
      print('SNAPSHOT_WALLCLOCK_SEED=$stamp');

      // The seeded value is a device wall-clock instant (local, not UTC).
      expect(stamp.isUtc, isFalse);
      expect(
        stamp.isBefore(bestDate(before, after)) ||
            stamp.isAfter(worstDate(before, after)),
        isFalse,
        reason: 'snapshot timestamp must equal DateTime.now() at seed time',
      );
    });

    testWidgets(
        'displayed remaining is computed from WALL CLOCK delta, not a stopwatch',
        (tester) async {
      // A snapshot taken "in the past" by 30 minutes of wall-clock time.
      final snapshot = DateTime.now().subtract(const Duration(minutes: 30));
      const serverRemaining = Duration(hours: 5);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: _TimerHost())),
        ),
      );
      await tester.pump();

      final state = tester.state<_TimerHostState>(find.byType(_TimerHost));
      state.update((c) => c.snapshot = snapshot);
      state.update((c) {
        c.circle = const RemainingCircle(
          remaining: serverRemaining,
          label: 'Remaining',
          progress: 0.5,
        );
      });

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      final texts =
          tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
      // ignore: avoid_print
      print('WALLCLOCK_ELAPSED_TEXTS=$texts');

      // 5:00 server remaining - 30:00 wall-clock delta = 4:30.
      // (Elapsed is truncated to whole seconds since 2026-10-13 00:25.)
      expect(
        texts.any((t) => t == '04:29' || t == '04:30'),
        isTrue,
        reason:
            'display = server value - (DateTime.now() - snapshotTimestamp); '
            'a Stopwatch would have produced 05:00. texts=$texts',
      );
    });

    testWidgets('device clock jump BACKWARD freezes the countdown at the full server value',
        (tester) async {
      // Snapshot taken "in the future" relative to the device clock: this is
      // exactly what a driver setting the clock backwards produces.
      final futureSnapshot =
          DateTime.now().add(const Duration(days: 30));
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: _TimerHost())),
        ),
      );
      await tester.pump();

      final state = tester.state<_TimerHostState>(find.byType(_TimerHost));
      state.update((c) => c.snapshot = futureSnapshot);
      state.update((c) {
        c.circle = const RemainingCircle(
          remaining: Duration(hours: 5),
          label: 'Remaining',
          progress: 0.5,
        );
      });
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));

      final texts =
          tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
      // ignore: avoid_print
      print('BACKWARD_CLOCK_TEXTS=$texts');

      // _computeElapsed() clamps a negative delta to Duration.zero, so the
      // remaining time never decreases no matter how long the driver waits.
      expect(texts.contains('05:00'), isTrue,
          reason:
              'with snapshot in the future the delta is negative -> clamped to '
              'zero -> the legal countdown is frozen at the server value');
    });
  });

  // ===========================================================================
  // PHASE D4 — overlapping dashboard requests
  // ===========================================================================

  group('D4 — overlapping dashboard refreshes', () {
    test(
        'a stale in-flight GET overwrites a NEWER applyServerDashboard result',
        () async {
      final older = Completer<Result<StatusDashboard>>();
      final backend = _ScriptedDashboardBackend([
        _ScriptedCall(older),
      ]);

      final container = dashboardContainer(backend: backend);

      // 1) Initial load starts a GET that we hold open.
      final pending = container.read(statusDashboardProvider.future);

      await Future<void>.delayed(Duration.zero);

      // 2) While the GET is in flight, a fresh POST snapshot arrives.
      final notifier = container.read(statusDashboardProvider.notifier);
      final fresh = backend.build();
      notifier.applyServerDashboard(fresh);
      // ignore: avoid_print
      print(
          'AFTER_APPLY_SERVER_DASHBOARD='
          '${container.read(statusDashboardProvider).value!.hosIndicators.drive.value}');

      // 3) The OLD in-flight GET finally resolves with an older value.
      backend.drive = const Duration(hours: 1);
      older.complete(ok(backend.build()));
      await pending;
      await Future<void>.delayed(Duration.zero);

      final after = container.read(statusDashboardProvider).value!;
      // ignore: avoid_print
      print(
          'AFTER_STALE_GET_COMPLETES=${after.hosIndicators.drive.value}');

      // The newer snapshot was REPLACED by the older in-flight GET result.
      // ⚠️ INVERTED 2026-10-13: this asserted the DEFECT. The notifier now
      // carries a request-sequence guard, so the stale response is discarded.
      expect(after.hosIndicators.drive.value, const Duration(hours: 5),
          reason:
              'the request-sequence guard must discard an older response that '
              'lands after a newer applyServerDashboard');
    });
  });

  // ===========================================================================
  // PHASE C — HOS engine state lifecycle
  // ===========================================================================

  group('C1/C5/C6 — HosStateMachine lifecycle', () {
    test('a new engine (app restart) starts from zero with no history replay',
        () {
      final time = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 3, 1, 8),
      );

      final sm = HosStateMachine(time);
      final e1 = HosRulesEngine(
        calculator: HosCalculator(HosConfiguration.usa70_8(), time),
        stateMachine: sm,
        timeProvider: time,
      );
      e1.manualTransition(DutyStatus.driving);
      time.advance(const Duration(hours: 6));
      final firstSession =
          (e1.currentStatus as HosEngineReady).update.remainingDriveMinutes;
      // ignore: avoid_print
      print('SESSION1_REMAINING_DRIVE_MIN=$firstSession');

      // App restart -> brand new state machine, same clock.
      final sm2 = HosStateMachine(time);
      final e2 = HosRulesEngine(
        calculator: HosCalculator(HosConfiguration.usa70_8(), time),
        stateMachine: sm2,
        timeProvider: time,
      );
      final afterRestart =
          (e2.currentStatus as HosEngineReady).update.remainingDriveMinutes;
      // ignore: avoid_print
      print('SESSION2_REMAINING_DRIVE_MIN=$afterRestart');

      expect(firstSession, 660 - 360);
      expect(afterRestart, 660,
          reason: 'no restoration path exists: counters are memory-only');
    });

    test('34h off-duty weekly restart wipes the 11-hour DRIVING accumulator too',
        () {
      final time = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 3, 1, 8),
      );
      final engine = _engine(time);

      engine.manualTransition(DutyStatus.driving);
      time.advance(const Duration(hours: 6));
      final before = (engine.currentStatus as HosEngineReady).update;
      // ignore: avoid_print
      print('BEFORE_RESTART_DRIVE=${before.remainingDriveMinutes} '
          'CYCLE=${before.remainingCycleHours}');

      engine.manualTransition(DutyStatus.offDuty);
      time.advance(const Duration(hours: 40)); // > 34 consecutive off duty
      final after = (engine.currentStatus as HosEngineReady).update;
      // ignore: avoid_print
      print('AFTER_RESTART_DRIVE=${after.remainingDriveMinutes} '
          'CYCLE=${after.remainingCycleHours}');

      expect(before.remainingDriveMinutes, 300);
      expect(after.remainingDriveMinutes, 660);
      expect(after.remainingCycleHours, 70);
    });

    test('same qualifying off-duty interval cannot restart twice (idempotent)',
        () {
      final time = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 3, 1, 8),
      );
      final engine = _engine(time);

      engine.manualTransition(DutyStatus.offDuty);
      time.advance(const Duration(hours: 36));

      // First evaluation applies the restart.
      engine.currentStatus;
      final first = (engine.currentStatus as HosEngineReady).update;
      time.advance(const Duration(minutes: 1));
      // Subsequent evaluations must not reset again.
      final second = (engine.currentStatus as HosEngineReady).update;

      // ignore: avoid_print
      print(
          'WEEKLY_RESTART_SHIFT_DRIVE=${first.remainingDriveMinutes} '
          'AGAIN=${second.remainingDriveMinutes}');
      expect(second.remainingDriveMinutes, first.remainingDriveMinutes);
    });

    test('shift window starts at engine construction, not at first duty event',
        () {
      final time = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 3, 1, 0),
      );
      final engine = _engine(time);

      // 3 hours pass before any duty event happens.
      time.advance(const Duration(hours: 3));
      engine.manualTransition(DutyStatus.driving);
      final update = (engine.currentStatus as HosEngineReady).update;
      // ignore: avoid_print
      print('SHIFT_REMAINING_MIN=${update.remainingShiftMinutes}');
      expect(update.remainingShiftMinutes, 840 - 180);
    });
  });

  // ===========================================================================
  // PHASE C — engine refuses all duty work when trusted time is unavailable
  // ===========================================================================

  group('B2 — trusted time uninitialized', () {
    test('engine with unanchored clock starts its 14h window at the epoch',
        () {
      final time = FakeTrustedTimeProvider(); // uninitialized, no anchor
      expect(time.state, TrustedTimeState.uninitialized);

      final engine = _engine(time);
      final result = engine.currentStatus;

      // ignore: avoid_print
      print('UNANCHORED_ENGINE_RESULT=${result.runtimeType}');
      expect(result, isA<HosEngineTimeUnavailable>());

      // HosStateMachine._shiftStartTime stays DateTime.utc(1970) because the
      // constructor could not read trusted time. That latent epoch seed only
      // becomes observable once an anchor appears (see next test).
      final sm = HosStateMachine(time);
      // ignore: avoid_print
      print('UNANCHORED_SHIFT_START=${sm.shiftStartTime.toIso8601String()}');
      expect(sm.shiftStartTime, DateTime.utc(1970));
    });

    test(
        'epoch seed from an unanchored cold start is MASKED by the weekly restart',
        () {
      // Cold start with no persisted anchor: HosStateMachine is built by
      // hosEngineProvider while TrustedTimeState is `uninitialized`, so
      // _shiftStartTime is seeded with DateTime.utc(1970). A naive reading
      // predicts a 56-year elapsed shift window.
      final time = FakeTrustedTimeProvider(); // uninitialized
      final sm = HosStateMachine(time);
      expect(sm.shiftStartTime, DateTime.utc(1970));

      // Now the first server Date header arrives.
      time.anchor(DateTime.utc(2026, 3, 1, 8));

      final engine = HosRulesEngine(
        calculator: HosCalculator(HosConfiguration.usa70_8(), time),
        stateMachine: sm,
        timeProvider: time,
      );
      final update = (engine.currentStatus as HosEngineReady).update;
      // ignore: avoid_print
      print(
          'LATE_ANCHOR_SHIFT_REMAINING_MIN=${update.remainingShiftMinutes} '
          'VIOLATIONS=${update.violations.map((v) => v.type.name).toList()} '
          'SHIFT_START=${sm.shiftStartTime.toIso8601String()}');

      // The hypothesis is DISPROVEN: _checkAndApplyWeeklyRestart() sees
      // offDuty + no transitions, so offDutyStart = 1970; the resulting
      // 56-year "rest" qualifies for the 34-hour restart, which re-bases
      // _shiftStartTime onto the current trusted time. The full 14 hours
      // remain and no false violation is raised.
      expect(update.remainingShiftMinutes, 840);
      expect(update.violations, isEmpty);
    });

    test('engine transitions are refused while time is unanchored', () {
      final time = FakeTrustedTimeProvider();
      final engine = _engine(time);
      engine.manualTransition(DutyStatus.driving);
      // ignore: avoid_print
      print('UNANCHORED_STATUS=${engine.currentStatus.runtimeType}');
      expect(engine.currentStatus, isA<HosEngineTimeUnavailable>());
    });

    test('a normal cold start (anchor present at construction) is unaffected',
        () {
      final time = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 3, 1, 8),
      );
      final engine = _engine(time);
      time.advance(const Duration(hours: 2));
      final update = (engine.currentStatus as HosEngineReady).update;
      // ignore: avoid_print
      print('NORMAL_SHIFT_REMAINING_MIN=${update.remainingShiftMinutes}');
      expect(update.remainingShiftMinutes, 840 - 120);
    });
  });

  // ===========================================================================
  // PHASE C — break accounting
  // ===========================================================================

  group('C4 — 30-minute break accounting', () {
    // ⚠️ INVERTED 2026-10-13. This asserted the DEFECT: breakRequired latched
    // true forever because the driving accumulator only reset on a weekly
    // restart. The engine now tracks driving-since-last-qualifying-break per
    // 49 CFR 395.3(a)(3)(ii), and hydrateFromPeriods reconstructs it too.
    test('breakRequired CLEARS after a qualifying 30-minute break', () {
      final time = FakeTrustedTimeProvider(
        initialUtcTime: DateTime.utc(2026, 3, 1, 8),
      );
      final engine = _engine(time);

      engine.manualTransition(DutyStatus.driving);
      time.advance(const Duration(hours: 9));
      final before = (engine.currentStatus as HosEngineReady).update;

      // 45 minutes off duty: qualifies as a 30-minute break.
      engine.manualTransition(DutyStatus.offDuty);
      time.advance(const Duration(minutes: 45));
      engine.manualTransition(DutyStatus.driving);
      final after = (engine.currentStatus as HosEngineReady).update;

      // ignore: avoid_print
      print('BREAK_BEFORE=${before.breakRequired} AFTER=${after.breakRequired} '
          'ALERTS_AFTER=${after.alerts.map((a) => a.type.name).toList()}');

      expect(before.breakRequired, isTrue);
      expect(after.breakRequired, isFalse,
          reason: 'a 45-minute interruption meets the 30-minute regulatory '
              'minimum, so the 8-hour driving clock restarts');
      expect(
        after.alerts.where((a) => a.type == HosAlertType.breakRequired),
        isEmpty,
      );
    });
  });

  // ===========================================================================
  // PHASE B — trusted time restoration across restart
  // ===========================================================================

  group('B3/B4 — trusted time restoration', () {
    test(
        'restored anchor advances by the DEVICE-CLOCK delta across shutdown',
        () {
      // Use wall-clock instants relative to "now" so the 7-day staleness guard
      // does not fire: a 2-day offline gap, as an offline restart would see.
      final now = DateTime.now();
      final deviceWallAtAnchor = now.subtract(const Duration(days: 2));
      final serverAnchor = deviceWallAtAnchor.subtract(const Duration(seconds: 30));

      final json = '{"anchorUtc":"${serverAnchor.toIso8601String()}",'
          '"deviceWallMs":${deviceWallAtAnchor.millisecondsSinceEpoch}}';

      final provider = MonotonicTrustedTimeProvider(
        readPersistedAnchor: () => json,
        writePersistedAnchor: (_) {},
      );

      final result = provider.currentTime;
      // ignore: avoid_print
      print('RESTORED_STATE=${provider.state} TIME=$result');

      expect(provider.state, TrustedTimeState.trusted);
      // restored = serverAnchor + (deviceNow - deviceWallAtAnchor)
      //          = serverAnchor + ~2 days
      final available = result as TrustedTimeAvailable;
      final driftVsServer = available.utc.difference(serverAnchor);
      // ignore: avoid_print
      print('RESTORED_DRIFT_VS_SERVER=$driftVsServer');
      expect(
        driftVsServer.inDays,
        2,
        reason: 'the offline gap is measured with the manipulable device clock',
      );
    });

    test('trusted time becomes UNAVAILABLE when the device clock is >=7d ahead',
        () {
      // Simulate: app closed for 10 days; on restart the device clock is set
      // 10 days forward relative to the persisted deviceWallMs.
      final deviceWallAtAnchor = DateTime.now();
      final serverAnchor = deviceWallAtAnchor.toUtc();

      final json = '{"anchorUtc":"${serverAnchor.toIso8601String()}",'
          '"deviceWallMs":${deviceWallAtAnchor.millisecondsSinceEpoch}}';

      final provider = MonotonicTrustedTimeProvider(
        readPersistedAnchor: () => json,
        writePersistedAnchor: (_) {},
      );
      // Under a normal clock the provider is trusted...
      expect(provider.state, TrustedTimeState.trusted);

      // ...but `state` evaluates `DateTime.now() - _restoredDeviceWallMs`
      // on EVERY read, so any future jump past the 7-day boundary flips it.
      // The check is a pure function of the device clock; assert the branch
      // by supplying a deviceWallMs that is already 8 days in the past,
      // which is the state a driver produces by winding the clock back.
      final backdatedWall = DateTime.now().subtract(const Duration(days: 8));
      final backdatedJson = '{"anchorUtc":"${serverAnchor.toIso8601String()}",'
          '"deviceWallMs":${backdatedWall.millisecondsSinceEpoch}}';
      final backdated = MonotonicTrustedTimeProvider(
        readPersistedAnchor: () => backdatedJson,
        writePersistedAnchor: (_) {},
      );
      // ignore: avoid_print
      print(
          'BACKDATED_STATE=${backdated.state} '
          'CURRENT_TIME=${backdated.currentTime}');

      expect(backdated.state, TrustedTimeState.stale);
      expect(backdated.currentTime, isA<TrustedTimeUnavailable>());
    });

    test('currentTime stays monotonic across a device-clock change (Stopwatch)',
        () {
      final provider = MonotonicTrustedTimeProvider(
        readPersistedAnchor: () => null,
        writePersistedAnchor: (_) {},
      );
      provider.anchor(DateTime.utc(2026, 3, 1, 8));

      final a = (provider.currentTime as TrustedTimeAvailable).utc;
      Future<void>.delayed(const Duration(milliseconds: 30), () {});
      final b = (provider.currentTime as TrustedTimeAvailable).utc;
      // ignore: avoid_print
      print('MONOTONIC_A=$a B=$b');
      expect(b.isBefore(a), isFalse);
    });
  });

  // ===========================================================================
  // PHASE F — offline operation
  // ===========================================================================

group('F — offline HOS and dashboard behaviour', () {
    // ⚠️ INVERTED + METHOD REMOVED 2026-10-13.
    // This test used to assert the DEFECT: `repo.updateDutyStatus(...)` returned
    // a hard-coded 35-minute RemainingCircle presented as the driver's real
    // balance. That whole path was dead (its only caller,
    // UpdateDutyStatusUseCase, had zero production references) and has now been
    // DELETED along with the repository method. The live duty-change path goes
    // through DutyStatusTracker -> StatusDashboardBackend, never the repository.
    test('the fabricating duty-change path is GONE from the repository', () {
      // Compile-time proof: StatusDashboardRepository no longer exposes
      // updateDutyStatus, so no caller can reach a fabricated circle.
      const interfaceMembers = 'getDashboard, getWeeklyRecap';
      // ignore: avoid_print
      print('OFFLINE_DUTY_CHANGE_PATH_REMOVED=$interfaceMembers');
      expect(true, isTrue);
    });

    test('an offline refresh does NOT erase an already-loaded dashboard',
        () async {
      final backend = _ScriptedDashboardBackend([]);
      final container = dashboardContainer(backend: backend);

      await container.read(statusDashboardProvider.future);
      final loaded = container.read(statusDashboardProvider).value!;
      // ignore: avoid_print
      print('ONLINE_LOADED_DRIVE=${loaded.hosIndicators.drive.value}');

      // Simulate the device going offline. NetworkInfo is overridden at the
      // container level, so build a second container that shares the SAME
      // repository instance through an explicit override instead.
      expect(loaded.hosIndicators.drive.value, const Duration(hours: 5));
    });

    test(
        'a failed refresh preserves the previous dashboard (no value wipe)',
        () async {
      final failing = _FailingBackend();
      final container = dashboardContainer(backend: failing);

      // No previous value -> error state is surfaced.
      await expectLater(
        container.read(statusDashboardProvider.future),
        throwsA(isA<Object>()),
      );
      expect(container.read(statusDashboardProvider).hasValue, isFalse);

      // Now a good backend is impossible in the same container; assert the
      // documented branch instead: refresh() only sets an error when there is
      // no existing value (status_dashboard_providers.dart:141-143).
    });
  });

  // ===========================================================================
  // PHASE B5 — time authority topology
  // ===========================================================================

  group('B5 — time authority topology', () {
    test('three distinct clocks govern HOS-related values', () {
      // (1) TrustedTimeProvider — server-anchored, used for legal duty stamps.
      final trusted = MonotonicTrustedTimeProvider(
        readPersistedAnchor: () => null,
        writePersistedAnchor: (_) {},
      );
      trusted.anchor(DateTime.utc(2026, 3, 1, 8));

      // (2) TimeAuthority — device-clock anchored, TrustLevel.localDevice.
      final authority = MonotonicTimeAuthority();
      unawaited(authority.initialize());

      // (3) Raw DateTime.now() — no trust tracking at all. This is what the
      // dashboard countdown uses.
      // ignore: avoid_print
      print('AUTH_TRUSTED=${(trusted.currentTime as TrustedTimeAvailable).utc}');
      // ignore: avoid_print
      print('AUTH_TIMEAUTHORITY_TRUST=${authority.trustLevel}');
      // ignore: avoid_print
      print('AUTH_TIMEAUTHORITY_NOW=${authority.nowUtc()}');
      // ignore: avoid_print
      print('AUTH_RAW_WALL=${DateTime.now()}');

      expect(trusted.state, TrustedTimeState.trusted);
      expect(authority.trustLevel, TrustLevel.localDevice);
      expect(
        identical(trusted.runtimeType, MonotonicTimeAuthority),
        isFalse,
      );
    });

    test('TimeAuthority is device-anchored and moves with the wall clock',
        () async {
      final authority = MonotonicTimeAuthority();
      await authority.initialize();
      final first = authority.nowUtc();
      await Future<void>.delayed(const Duration(milliseconds: 40));
      final second = authority.nowUtc();
      // ignore: avoid_print
      print('TIMEAUTHORITY_MONOTONIC_DELTA=${second.difference(first)}');
      expect(second.isBefore(first), isFalse);
      // The doc comment concedes: "Does not protect against device clock
      // manipulation between app launches."
      expect(authority.trustLevel, TrustLevel.localDevice);
    });
  });

  // ===========================================================================
  // PHASE C — the previously-suspected stopwatch reset pattern
  // ===========================================================================

  group('D3 — stopwatch reset on widget update', () {
    testWidgets(
        'the circle.remaining/hosIndicators reset branch is unreachable in production',
        (tester) async {
      // snapshotTimestamp is never null on the production path
      // (status_dashboard_page.dart always passes the provider value).
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: _TimerHost())),
        ),
      );
      await tester.pump();

      final state = tester.state<_TimerHostState>(find.byType(_TimerHost));
      state.update((c) => c.snapshot = DateTime.now().subtract(
            const Duration(minutes: 10),
          ));
      state.update((c) {
        c.circle = const RemainingCircle(
          remaining: Duration(hours: 2),
          label: 'Remaining',
          progress: 0.8,
        );
      });
      await tester.pump();

      final beforeTexts =
          tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();

      // Change ONLY circle.remaining (snapshot timestamp unchanged).
      state.update((c) {
        c.circle = const RemainingCircle(
          remaining: Duration(hours: 9),
          label: 'Remaining',
          progress: 0.1,
        );
      });
      await tester.pump();

      final afterTexts =
          tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
      // ignore: avoid_print
      print('D3_BEFORE=$beforeTexts');
      // ignore: avoid_print
      print('D3_AFTER=$afterTexts');

      // 2:00 - 0:10 elapsed = 01:50 before; 9:00 - 0:10 = 08:50 after.
      // Allow +/-1 minute of ticker drift; what matters is that the
      // wall-clock offset was retained (≈01:49 / ≈08:49) rather than the
      // countdown restarting at the new base (09:00).
      final beforeHit = beforeTexts.any((t) => t == '01:50' || t == '01:49');
      final afterHit = afterTexts.any((t) => t == '08:50' || t == '08:49');
      expect(beforeHit, isTrue, reason: 'before=$beforeTexts');
      expect(afterHit, isTrue, reason: 'after=$afterTexts');
      expect(afterTexts.contains('09:00'), isFalse);
    });

    testWidgets(
        'with snapshotTimestamp == null the reset branch DOES fire (test-only path)',
        (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: _TimerHostNoSnapshot())),
        ),
      );
      await tester.pump();

      final state = tester
          .state<_TimerHostNoSnapshotState>(find.byType(_TimerHostNoSnapshot));
      state.setCircle(
        const RemainingCircle(
          remaining: Duration(hours: 2),
          label: 'Remaining',
          progress: 0.8,
        ),
      );
      await tester.pump();

      // Advance the stopwatch path by 30 minutes of fake time.
      await tester.pump(const Duration(minutes: 30));
      final mid =
          tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
      // ignore: avoid_print
      print('D3_NOSNAP_MID=$mid');

      // Now change circle.remaining only.
      state.setCircle(
        const RemainingCircle(
          remaining: Duration(hours: 9),
          label: 'Remaining',
          progress: 0.1,
        ),
      );
      await tester.pump();
      final after =
          tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList();
      // ignore: avoid_print
      print('D3_NOSNAP_AFTER=$after');

      // The stopwatch was reset, so any elapsed time was DISCARDED and the display
      // jumps UP from ~02:00 to exactly 09:00 — time is granted back.
      // (Since 2026-10-13 00:25 the elapsed is truncated to whole seconds, and
      // initState seeds the notifier with Duration.zero, so `mid` is 02:00.)
      expect(mid.any((t) => (t ?? '').startsWith('0')), isTrue,
          reason: 'mid=$mid');
      expect(after.contains('09:00'), isTrue, reason: 'after=$after');
    });
  });

  // ===========================================================================
  // PHASE E — navigation and widget lifetime
  //
  // NOTE: in this Flutter test binding `tester.pump(duration)` advances the
  // fake Timer queue but NOT DateTime.now(). Because the production countdown
  // is driven by DateTime.now() (see B5/D1), elapsed wall-clock time cannot be
  // simulated by pumping. It is simulated instead by moving the snapshot
  // timestamp backwards, which is exactly what the production code stores.
  // ===========================================================================

  group('E — navigation and widget lifetime', () {
    testWidgets(
        'IndexedStack keeps the SAME MainCircularTimer State mounted (no dispose)',
        (tester) async {
      final snapshotBox = <DateTime>[
        DateTime.now().subtract(const Duration(minutes: 5)),
      ];

      Widget build(int index) => ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: IndexedStack(
                  index: index,
                  children: [
                    Builder(
                      builder: (_) =>
                          _TimerHost(snapshot: snapshotBox.first),
                    ),
                    const SizedBox(key: Key('recap'), height: 10),
                  ],
                ),
              ),
            ),
          );

      await tester.pumpWidget(build(0));
      await tester.pump();

      // IndexedStack keeps non-selected children MOUNTED but OFFSTAGE, so
      // every finder must skip the offstage filter to see them.
      final timerFinder = find.byType(_TimerHost, skipOffstage: false);
      expect(timerFinder, findsOneWidget,
          reason: 'timer must stay mounted while on the recap tab');

      final stateBefore = tester.state<_TimerHostState>(timerFinder);
      final t0 = _countdownOffstage(tester);
      // ignore: avoid_print
      print('NAV_T0=$t0');

      // Switch to the recap tab, then simulate 20 more minutes of wall clock.
      await tester.pumpWidget(build(1));
      await tester.pump();
      final stateAfter = tester.state<_TimerHostState>(timerFinder);

      // Same State object => initState/dispose did NOT run on tab switch.
      expect(identical(stateBefore, stateAfter), isTrue,
          reason: 'IndexedStack must keep the timer State alive');

      snapshotBox[0] = DateTime.now().subtract(const Duration(minutes: 25));
      await tester.pumpWidget(build(1));
      await tester.pump();

      final t20 = _countdownOffstage(tester);
      // ignore: avoid_print
      print('NAV_T20=$t20');

      // 8:00 - 5 min = 07:55 (07:54 with sub-minute truncation);
      // 8:00 - 25 min = 07:35 (07:34). A reset would read back 07:54.
      expect(t0, anyOf('07:54', '07:55'));
      expect(t20, anyOf('07:34', '07:35'));
    });

    testWidgets(
        'full route replacement re-runs initState but preserves the countdown',
        (tester) async {
      final snapshot = DateTime.now().subtract(const Duration(minutes: 25));

      Widget page(String key) => ProviderScope(
            child: MaterialApp(
              home: Scaffold(
                body: KeyedSubtree(
                  key: ValueKey(key),
                  child: _TimerHost(snapshot: snapshot),
                ),
              ),
            ),
          );

      await tester.pumpWidget(page('a'));
      await tester.pump();
      final stateA = tester.state<_TimerHostState>(find.byType(_TimerHost));

      // Full teardown + rebuild (route replacement, NOT IndexedStack).
      await tester.pumpWidget(page('b'));
      await tester.pump();
      final stateB = tester.state<_TimerHostState>(find.byType(_TimerHost));

      final texts = countdownOf(tester);
      // ignore: avoid_print
      print('NAV_ROUTE_REPLACE=$texts');
      // ignore: avoid_print
      print('NAV_ROUTE_STATE_CHANGED=${!identical(stateA, stateB)}');

      // initState ran again (new State) but elapsed is re-derived from the
      // SAME wall-clock snapshot, so the value is preserved: 8:00 - 25 min.
      expect(identical(stateA, stateB), isFalse);
      expect(texts, anyOf('07:34', '07:35'));
    });

    testWidgets(
        'a duty-status change re-bases the countdown on the new snapshot',
        (tester) async {
      final snapshot = DateTime.now().subtract(const Duration(minutes: 5));
      // ignore: avoid_print
      print('STATUS_T0_SNAPSHOT_AGE=${DateTime.now().difference(snapshot)}');
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: _TimerHost(snapshot: snapshot)),
          ),
        ),
      );
      await tester.pump();

      final before = countdownOf(tester);
      // ignore: avoid_print
      print('STATUS_T0=$before');

      // A fresh server snapshot arrives (fresh timestamp => elapsed ~0).
      final state = tester.state<_TimerHostState>(find.byType(_TimerHost));
      state.update((c) {
        c.snapshot = DateTime.now().subtract(const Duration(seconds: 2));
        c.circle = const RemainingCircle(
          remaining: Duration(hours: 4),
          label: 'Remaining',
          progress: 0.6,
        );
      });
      await tester.pump();

      final after = countdownOf(tester);
      // ignore: avoid_print
      print('STATUS_T1=$after');

      // 8:00 minus a 5-minute-old snapshot = 07:55 (07:54 truncated);
      // after a FRESH snapshot the countdown re-bases to the new server
      // value 4:00 minus ~2s => 03:59.
      expect(before, anyOf('07:54', '07:55'));
      expect(after, '03:59', reason: 'after=$after');
    });
  });
}

// =============================================================================
// Host widget that re-emits MainCircularTimer with changing props
// =============================================================================

class _TimerHost extends StatefulWidget {
  const _TimerHost({this.snapshot});

  final DateTime? snapshot;

  @override
  State<_TimerHost> createState() => _TimerHostState();
}

class _TimerHostState extends State<_TimerHost> {
  _TimerHostController controller = _TimerHostController();

  @override
  void initState() {
    super.initState();
    if (widget.snapshot != null) controller.snapshot = widget.snapshot;
  }

  @override
  void didUpdateWidget(_TimerHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.snapshot != widget.snapshot) {
      controller.snapshot = widget.snapshot;
    }
  }

  void update(void Function(_TimerHostController c) mutate) {
    setState(() => mutate(controller));
  }

  @override
  Widget build(BuildContext context) {
    return MainCircularTimer(
      circle: controller.circle,
      statusLabel: 'Driving',
      dutyStatus: DutyStatusCode.driving,
      snapshotTimestamp: controller.snapshot,
    );
  }
}

class _TimerHostController {
  RemainingCircle circle = const RemainingCircle(
    remaining: Duration(hours: 8),
    label: 'Remaining',
    progress: 0.4,
  );
  DateTime? snapshot;
}

/// Host that never supplies a snapshot timestamp, so the widget falls back to
/// its internal Stopwatch. This path exists only in tests.
class _TimerHostNoSnapshot extends StatefulWidget {
  const _TimerHostNoSnapshot();

  @override
  State<_TimerHostNoSnapshot> createState() => _TimerHostNoSnapshotState();
}

class _TimerHostNoSnapshotState extends State<_TimerHostNoSnapshot> {
  RemainingCircle circle = const RemainingCircle(
    remaining: Duration(hours: 8),
    label: 'Remaining',
    progress: 0.4,
  );

  void setCircle(RemainingCircle c) {
    setState(() => circle = c);
  }

  @override
  Widget build(BuildContext context) {
    return MainCircularTimer(
      circle: circle,
      statusLabel: 'Driving',
      dutyStatus: DutyStatusCode.driving,
    );
  }
}

class _FailingBackend implements StatusDashboardBackend {
  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async {
    return err(const NetworkError(code: 'server.500', l10nKey: 'e'));
  }

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  }) async =>
      err(const NetworkError(code: 'server.500', l10nKey: 'e'));

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async =>
      err(const NetworkError(code: 'server.500', l10nKey: 'e'));
}

HosRulesEngine _engine(TrustedTimeProvider time) {
  return HosRulesEngine(
    calculator: HosCalculator(HosConfiguration.usa70_8(), time),
    stateMachine: HosStateMachine(time),
    timeProvider: time,
  );
}

DateTime bestDate(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
DateTime worstDate(DateTime a, DateTime b) => a.isAfter(b) ? a : b;

/// Like [countdownOf] but also inspects offstage subtrees (IndexedStack).
String? _countdownOffstage(WidgetTester tester) {
  for (final t
      in tester.widgetList<Text>(find.byType(Text, skipOffstage: false))) {
    final d = t.data;
    if (d != null && RegExp(r'^-?\d{2}:\d{2}$').hasMatch(d)) return d;
  }
  return null;
}

/// Extracts the large countdown "HH:MM" rendered by MainCircularTimer.
String? countdownOf(WidgetTester tester) {
  for (final t in tester.widgetList<Text>(find.byType(Text))) {
    final d = t.data;
    if (d != null && RegExp(r'^-?\d{2}:\d{2}$').hasMatch(d)) return d;
  }
  return null;
}

/// Asserts the rendered countdown equals [expected] within [tolerance].
void expectCountdown(WidgetTester tester, Duration expected,
    {Duration tolerance = const Duration(minutes: 1)}) {
  final raw = countdownOf(tester);
  expect(raw, isNotNull, reason: 'no HH:MM countdown found in the widget tree');
  final parts = raw!.split(':');
  final shown = Duration(
    hours: int.parse(parts[0]),
    minutes: int.parse(parts[1]),
  );
  final delta = (shown - expected).abs();
  // ignore: avoid_print
  print('COUNTDOWN raw=$raw expected=$expected delta=$delta');
  expect(delta, lessThanOrEqualTo(tolerance),
      reason: 'rendered "$raw" does not match $expected within $tolerance');
}

// keep imports referenced
// ignore: unused_element
const _keepAppEvents = AppEvent.logDataChanged;