import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_identity.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/hos_engine_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/status_dashboard_providers.dart';
import 'package:golden_feather_eld/backend/contracts/status_dashboard_backend.dart';

class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
    : super(
        AuthState(
          status: AuthStatus.authenticated,
          user: User(
            id: '646',
            username: 'naseem646',
            email: 'naseem@test.com',
            fullName: 'Naseem Hassan Ali Adam',
            role: UserRole.fieldWorker,
            createdAt: DateTime(2026),
          ),
        ),
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        activeBackendProvider.overrideWithValue(MockAdapter()),
        authStateProvider.overrideWith((ref) => _FakeAuthNotifier()),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // ==========================================================================
  // Initial load
  // ==========================================================================

  group('statusDashboardProvider — initial load', () {
    test('is loading initially', () {
      final container = createContainer();

      final initial = container.read(statusDashboardProvider);
      expect(initial, isA<AsyncLoading<StatusDashboard>>());
    });

    test('loads dashboard from mock backend', () async {
      final container = createContainer();
      final dashboard = await container.read(statusDashboardProvider.future);

      expect(dashboard.currentDutyStatus, DutyStatusCode.onDutyNotDriving);
      expect(dashboard.driver.id.value, 646);
      expect(dashboard.hosIndicators.drive.label, 'DRIVE');
    });

    test('state becomes AsyncData after load', () async {
      final container = createContainer();
      await container.read(statusDashboardProvider.future);

      final current = container.read(statusDashboardProvider);
      expect(current, isA<AsyncData<StatusDashboard>>());
      expect(current.hasValue, isTrue);
      expect(current.hasError, isFalse);
    });
  });

  // changeStatus tests removed because StatusDashboardNotifier no longer has changeStatus method

  // ==========================================================================
  // refresh
  // ==========================================================================

  group('statusDashboardProvider — refresh', () {
    // Test removed because it relies on changeStatus, which was removed.

    test('state is AsyncData after refresh', () async {
      final container = createContainer();
      await container.read(statusDashboardProvider.future);

      await container.read(statusDashboardProvider.notifier).refresh();

      expect(
        container.read(statusDashboardProvider),
        isA<AsyncData<StatusDashboard>>(),
      );
    });
  });

  // ==========================================================================
  // server authority (owner decision): every poll REPLACES local values
  // ==========================================================================

  group('statusDashboardProvider — الخادم يستبدل المحلي كل نبضة', () {
    test(
      'refresh replaces values verbatim even when the server is more generous',
      () async {
        final fakeTime = FakeTrustedTimeProvider(
          initialUtcTime: DateTime.utc(2026, 10, 14, 2),
        );
        final backend = _ScriptedStatusDashboard(
          _dashboard(
            circle: const Duration(hours: 8),
            shiftUsed: const Duration(hours: 6, minutes: 30),
          ),
        );
        final container = ProviderContainer(
          overrides: [
            activeBackendProvider.overrideWithValue(_ScriptedAdapter(backend)),
            authStateProvider.overrideWith((ref) => _FakeAuthNotifier()),
            trustedTimeProvider.overrideWithValue(fakeTime),
          ],
        );
        addTearDown(container.dispose);

        final first = await container.read(statusDashboardProvider.future);
        expect(first.remainingCircle.remaining, const Duration(hours: 8));

        // النبضة التالية: الخادم "متأخر" (يعرض أكثر). تحت الحارس الأحادي
        // القديم كان يُقصّ إلى الاشتقاق المحلي (≈7:30)؛ الآن يُعرض كما ورد.
        backend.dashboard = _dashboard(
          circle: const Duration(hours: 9),
          shiftUsed: const Duration(hours: 5),
        );
        fakeTime.advance(const Duration(seconds: 30));

        await container
            .read(statusDashboardProvider.notifier)
            .reconcileWithServer();

        final state = container.read(statusDashboardProvider).value!;
        expect(
          state.remainingCircle.remaining,
          const Duration(hours: 9),
          reason: 'الاستبدال لا التقليص — الخادم هو المرجع',
        );
        expect(
          state.hosIndicators.shift.value,
          const Duration(hours: 5),
          reason: 'مؤشرات الخادم تُعرض حرفياً بلا دمج محلي',
        );
      },
    );
  });

  // ==========================================================================
  // clearErrorAndReload
  // ==========================================================================

  group('statusDashboardProvider — clearErrorAndReload', () {
    test('reloads after error-free state', () async {
      final container = createContainer();
      await container.read(statusDashboardProvider.future);

      await container
          .read(statusDashboardProvider.notifier)
          .clearErrorAndReload();

      final dashboard = container.read(statusDashboardProvider).value!;
      expect(dashboard.currentDutyStatus, DutyStatusCode.onDutyNotDriving);
    });
  });

  // ==========================================================================
  // Error handling (using a failing override)
  // ==========================================================================

  group('statusDashboardProvider — error handling', () {
    test('surfaces Failure when backend fails', () async {
      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(_FailingAdapter()),
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier()),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(statusDashboardProvider.future),
        throwsA(isA<Failure>()),
      );

      final state = container.read(statusDashboardProvider);
      expect(state, isA<AsyncError<StatusDashboard>>());
    });

    test('clearErrorAndReload retries a failed hydration', () async {
      var hydrationAttempts = 0;
      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(_FailingAdapter()),
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier()),
          networkInfoProvider.overrideWithValue(_OfflineNetwork()),
          hosEngineProvider.overrideWith(
            (ref) => throw StateError('engine unavailable in this test'),
          ),
          hosHydrationReadyProvider.overrideWith((ref) async {
            hydrationAttempts++;
            if (hydrationAttempts == 1) {
              throw StateError('journal hydration failed');
            }
          }),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(statusDashboardProvider.future),
        throwsA(isA<Failure>()),
      );
      expect(hydrationAttempts, 1);

      await container
          .read(statusDashboardProvider.notifier)
          .clearErrorAndReload();

      expect(
        hydrationAttempts,
        2,
        reason: 'P1.3: a cached hydration failure must be retryable',
      );
    });
  });
}

class _OfflineNetwork implements NetworkInfo {
  @override
  bool get isConnected => false;

  @override
  Stream<bool> get onConnectionChange => const Stream<bool>.empty();
}

// =============================================================================
// Test doubles
// =============================================================================

/// Adapter that always fails on statusDashboard operations.
class _FailingAdapter implements BackendAdapter {
  @override
  BackendIdentity get identity => BackendIdentity.mock();

  @override
  bool get isMock => true;

  @override
  StatusDashboardBackend get statusDashboard => _FailingStatusDashboard();

  // All other contracts throw if accessed.
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Not used in this test');

  @override
  Future<void> dispose() async {}
}

class _FailingStatusDashboard implements StatusDashboardBackend {
  @override
  String? get lastServerMessage => null;

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async {
    return err(
      const NetworkError(code: 'test.failure', l10nKey: 'testFailure'),
    );
  }

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
    DriverId? driverId,
    VehicleId? vehicleId,
    double? latitude,
    double? longitude,
  }) async {
    return err(
      const NetworkError(code: 'test.failure', l10nKey: 'testFailure'),
    );
  }

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async {
    return err(
      const NetworkError(code: 'test.failure', l10nKey: 'testFailure'),
    );
  }
}

/// Adapter whose status dashboard can be swapped between polls.
class _ScriptedAdapter implements BackendAdapter {
  _ScriptedAdapter(this._backend);

  final StatusDashboardBackend _backend;

  @override
  BackendIdentity get identity => BackendIdentity.mock();

  @override
  bool get isMock => true;

  @override
  StatusDashboardBackend get statusDashboard => _backend;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('Not used in this test');

  @override
  Future<void> dispose() async {}
}

class _ScriptedStatusDashboard implements StatusDashboardBackend {
  _ScriptedStatusDashboard(this.dashboard);

  @override
  String? get lastServerMessage => null;

  StatusDashboard dashboard;

  @override
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async =>
      ok(dashboard);

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
    DriverId? driverId,
    VehicleId? vehicleId,
    double? latitude,
    double? longitude,
  }) async => ok(dashboard);

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async => err(
    const NetworkError(
      code: 'test.unimplemented',
      l10nKey: 'testUnimplemented',
    ),
  );
}

StatusDashboard _dashboard({
  required Duration circle,
  required Duration shiftUsed,
}) {
  return StatusDashboard(
    driver: const DriverRef(
      id: DriverId(646),
      name: 'Naseem Hassan Ali Adam',
      displayText: 'Naseem - 646',
    ),
    operationalAlerts: const OperationalAlerts(
      toolIcon: false,
      warningTriangleIcon: false,
      connectionStatus: ConnectionStatus.ok,
    ),
    currentDutyStatus: DutyStatusCode.onDutyNotDriving,
    remainingCircle: RemainingCircle(
      remaining: circle,
      label: 'Remaining',
      progress: 0.5,
    ),
    hosIndicators: HosIndicators(
      drive: const HosIndicator(
        label: 'DRIVE',
        value: Duration.zero,
        type: IndicatorType.used,
      ),
      shift: HosIndicator(
        label: 'SHIFT',
        value: shiftUsed,
        type: IndicatorType.used,
      ),
      breakTime: const HosIndicator(
        label: 'BREAK',
        value: Duration(hours: 8),
        type: IndicatorType.remaining,
      ),
      cycle: const HosIndicator(
        label: 'CYCLE',
        value: Duration(hours: 69),
        type: IndicatorType.used,
      ),
    ),
    regulatoryConstraints: const RegulatoryConstraints(
      ruleSet: CycleRule.usa70_8,
      limits: ['70-Hour / 8-Day Cycle Limit'],
    ),
  );
}
