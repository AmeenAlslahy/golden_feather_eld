import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/app.dart';
import 'package:golden_feather_eld/backend/providers/backend_network_providers.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_providers.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/codriver/data/providers/codriver_repository_providers.dart';
import 'package:golden_feather_eld/features/codriver/domain/current_codriver.dart';
import 'package:golden_feather_eld/features/codriver/domain/entities/codriver.dart';
import 'package:golden_feather_eld/features/codriver/domain/repositories/codriver_repository.dart';
import 'package:golden_feather_eld/features/codriver/presentation/providers/codriver_provider.dart';
import 'package:golden_feather_eld/features/hos/data/providers/status_dashboard_repository_providers.dart';
import 'package:golden_feather_eld/features/hos/domain/repositories/status_dashboard_repository.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/hos_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/status_dashboard_providers.dart';

// ─── Fakes ────────────────────────────────────────────────────────────────

User _user(String id, String name) => User(
      id: id,
      fullName: name,
      email: '$id@demo.com',
      username: id,
      role: UserRole.fieldWorker,
      createdAt: DateTime.utc(2026, 1, 1),
    );

class _GatedAuthRepository implements AuthRepository {
  User? current;
  int logoutCalls = 0;
  Completer<void>? logoutGate;
  final completerStarted = Completer<void>();

  @override
  Future<Either<Failure, User>> login({
    required dynamic identifier,
    required dynamic password,
  }) async {
    final id = identifier is String
        ? identifier
        : (identifier as dynamic).value as String;
    current = id == 'driverB@demo.com'
        ? _user('202', 'Driver B')
        : _user('101', 'Driver A');
    return Right(current!);
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    logoutCalls++;
    if (!completerStarted.isCompleted) completerStarted.complete();
    final gate = logoutGate;
    if (gate != null) await gate.future;
    current = null;
    return const Right(unit);
  }

  @override
  Future<Either<Failure, User>> checkAndRestoreSession() async =>
      const Left(ServerFailure(message: 'No session'));

  @override
  Future<Either<Failure, User>> getCurrentSession() async =>
      const Left(ServerFailure(message: 'No session'));
}

const _stubIndicator = HosIndicator(
  label: 'DRIVE',
  value: Duration(hours: 8),
  type: IndicatorType.remaining,
);

StatusDashboard _dashboard() => const StatusDashboard(
      driver:
          DriverRef(id: DriverId(101), name: 'A', displayText: 'A - 101'),
      operationalAlerts: OperationalAlerts(
        toolIcon: false,
        warningTriangleIcon: false,
        connectionStatus: ConnectionStatus.ok,
      ),
      currentDutyStatus: DutyStatusCode.offDuty,
      remainingCircle: RemainingCircle(
        remaining: Duration(hours: 8),
        label: 'DRIVE',
        progress: 0.5,
      ),
      hosIndicators: HosIndicators(
        drive: _stubIndicator,
        shift: _stubIndicator,
        breakTime: _stubIndicator,
        cycle: _stubIndicator,
      ),
      regulatoryConstraints: RegulatoryConstraints(
        ruleSet: CycleRule.usa70_8,
        limits: [],
      ),
    );

class _CountingDashboardRepository implements StatusDashboardRepository {
  int getDashboardCalls = 0;

  @override
  Future<Either<Failure, StatusDashboard>> getDashboard(
      {DriverId? driverId}) async {
    getDashboardCalls++;
    return Right(_dashboard());
  }


  @override
  DateTime? get snapshotAt => null;

  @override
  void cacheDashboard(StatusDashboard dashboard, {required DateTime takenAt}) {}

  @override
  Future<Either<Failure, WeeklyRecap>> getWeeklyRecap(
          {DriverId? driverId}) =>
      throw UnimplementedError();
}

class _GatedCoDriverRepository implements CoDriverRepository {
  int listCalls = 0;
  int currentCalls = 0;
  Completer<void>? listGate;

  @override
  Future<Either<Failure, List<CoDriver>>> getAvailableDrivers() async {
    listCalls++;
    final gate = listGate;
    if (gate != null) await gate.future;
    return const Right([]);
  }

  @override
  Future<Either<Failure, CurrentCoDriverRead>> getCurrentCoDriver() async {
    currentCalls++;
    return const Right(CurrentCoDriverRead());
  }

  @override
  Future<Either<Failure, bool>> switchPrimary({
    required int coDriverId,
    String? reason,
  }) async =>
      const Right(true);
}

/// Real HosNotifier pulls the engine/tracker/Hive chain; the dashboard
/// under test only needs the listen slot to exist.
class _StubHosNotifier extends StateNotifier<HosEngineResult>
    implements HosNotifier {
  _StubHosNotifier()
      : super(HosEngineTimeUnavailable(TrustedTimeState.uninitialized));

  @override
  void refresh() {}

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

ProviderContainer _container(
  _GatedAuthRepository auth,
  _CountingDashboardRepository dashboards,
  _GatedCoDriverRepository codrivers,
) {
  return ProviderContainer(
    overrides: [
      traccarAuthRepositoryProvider.overrideWithValue(auth),
      statusDashboardRepositoryProvider.overrideWithValue(dashboards),
      coDriverRepositoryProvider.overrideWithValue(codrivers),
      hosStatusProvider.overrideWith((ref) => _StubHosNotifier()),
    ],
  );
}

Future<void> _waitFor(bool Function() cond, String what) async {
  final end = DateTime.now().add(const Duration(seconds: 5));
  while (!cond()) {
    if (DateTime.now().isAfter(end)) {
      throw TimeoutException('Timed out waiting for: $what');
    }
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('logout leak regression (device-timeline findings)', () {
    test('R0: invalidation predicate semantics', () {
      const loggedOut = AuthState(status: AuthStatus.unauthenticated);
      final loading = loggedOut.copyWith(
          status: AuthStatus.loading, transitioning: true);
      final freshLogin = AuthState(
          status: AuthStatus.authenticated, user: _user('101', 'A'));

      // No transition, no identity change → no refresh.
      expect(shouldRefreshSessionProviders(loggedOut, loggedOut), isFalse);
      // Transition window → never refresh (the 54.363 leak).
      expect(shouldRefreshSessionProviders(loggedOut, loading), isFalse);
      // Fresh login (null → A, epoch differs) → refresh.
      expect(shouldRefreshSessionProviders(loading, freshLogin), isTrue);
      // Same-driver relogin (null → A again) → refresh (epoch differs).
      expect(shouldRefreshSessionProviders(loggedOut, freshLogin), isTrue);
      // Unrelated emission (same id, same epoch) → no refresh.
      expect(
          shouldRefreshSessionProviders(
              freshLogin, freshLogin.copyWith()),
          isFalse);
    });

    test('R1+R5: no protected reads during the logout window or after',
        () async {
      final auth = _GatedAuthRepository();
      final dashboards = _CountingDashboardRepository();
      final codrivers = _GatedCoDriverRepository();
      final c = _container(auth, dashboards, codrivers);
      addTearDown(c.dispose);

      await c
          .read(authStateProvider.notifier)
          .login(username: 'driverA@demo.com', password: 'x');
      c.read(codriverProvider);
      await c.read(statusDashboardProvider.future);
      final base = dashboards.getDashboardCalls;
      expect(base, 1);

      // Hold the backend DELETE open: logout is now parked mid-transition.
      auth.logoutGate = Completer<void>();
      unawaited(c.read(authStateProvider.notifier).logout());
      await auth.completerStarted.future;
      expect(c.read(authStateProvider).transitioning, isTrue);

      // Timer-equivalent refresh + explicit reloads during the window.
      await c.read(statusDashboardProvider.notifier).refresh();
      await c.read(codriverProvider.notifier).reload();
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(dashboards.getDashboardCalls, base,
          reason: 'R1: zero new protected GETs while transitioning');
      expect(codrivers.listCalls, 1,
          reason: 'R1: reset must not refetch the driver list');

      auth.logoutGate!.complete();
      await _waitFor(
          () => !c.read(authStateProvider).transitioning, 'logout done');

      // Post-logout ticks share the same guard (R5).
      await c.read(statusDashboardProvider.notifier).refresh();
      expect(dashboards.getDashboardCalls, base,
          reason: 'R5: timer-equivalent refresh stays silent offline-auth');
    });

    test('R2: logout parked between co-driver calls cancels the second',
        () async {
      final auth = _GatedAuthRepository();
      final dashboards = _CountingDashboardRepository();
      final codrivers = _GatedCoDriverRepository()
        ..listGate = Completer<void>();
      final c = _container(auth, dashboards, codrivers);
      addTearDown(c.dispose);

      await c
          .read(authStateProvider.notifier)
          .login(username: 'driverA@demo.com', password: 'x');
      // Factory-initial load parks inside getAvailableDrivers.
      c.read(codriverProvider);
      await _waitFor(() => codrivers.listCalls == 1, 'first call started');

      await c.read(authStateProvider.notifier).logout();

      // The 55.313 case: first response lands after the clear.
      codrivers.listGate!.complete();
      await Future<void>.delayed(const Duration(milliseconds: 150));
      expect(codrivers.currentCalls, 0,
          reason: 'R2: second sequential request must never start');
      expect(c.read(codriverProvider).availableDrivers, isEmpty);
    });

    test('R3: stale 401 mid-logout and duplicates clean up once', () async {
      final auth = _GatedAuthRepository();
      final dashboards = _CountingDashboardRepository();
      final codrivers = _GatedCoDriverRepository();
      final c = _container(auth, dashboards, codrivers);
      addTearDown(c.dispose);

      await c
          .read(authStateProvider.notifier)
          .login(username: 'driverA@demo.com', password: 'x');
      final epoch = c.read(authStateProvider).sessionEpoch;

      auth.logoutGate = Completer<void>();
      unawaited(c.read(authStateProvider.notifier).logout());
      await auth.completerStarted.future;

      // Stale 401 (previous generation) during the window: ignored.
      c.read(unauthenticatedEventProvider).add(epoch - 1);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      auth.logoutGate!.complete();
      await _waitFor(
          () => !c.read(authStateProvider).transitioning, 'logout done');
      expect(auth.logoutCalls, 1,
          reason: 'R3: exactly one cleanup despite the stale 401');

      // Duplicate bus events after completion: idempotent no-op.
      c.read(unauthenticatedEventProvider).add(epoch);
      c.read(unauthenticatedEventProvider).add(epoch);
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(auth.logoutCalls, 1,
          reason: 'R3: forceLogout is idempotent once logged out');
    });
  });
}
