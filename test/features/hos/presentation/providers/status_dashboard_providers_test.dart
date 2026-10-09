import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_identity.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/status_dashboard_providers.dart';
import 'package:golden_feather_eld/backend/contracts/status_dashboard_backend.dart';


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        activeBackendProvider.overrideWithValue(MockAdapter()),
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
      expect(dashboard.driver.id.value, 101);
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

      expect(container.read(statusDashboardProvider), isA<AsyncData<StatusDashboard>>());
    });
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
  });
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
  Future<Result<StatusDashboard>> getDashboard({DriverId? driverId}) async {
    return err(const NetworkError(
      code: 'test.failure',
      l10nKey: 'testFailure',
    ));
  }

  @override
  Future<Result<StatusDashboard>> updateDutyStatus({
    required DutyStatusCode status,
    String? notes,
  }) async {
    return err(const NetworkError(
      code: 'test.failure',
      l10nKey: 'testFailure',
    ));
  }

  @override
  Future<Result<WeeklyRecap>> getWeeklyRecap({DriverId? driverId}) async {
    return err(const NetworkError(
      code: 'test.failure',
      l10nKey: 'testFailure',
    ));
  }
}
