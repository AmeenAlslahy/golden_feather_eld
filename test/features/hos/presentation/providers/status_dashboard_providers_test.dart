import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_adapter.dart';
import 'package:golden_feather_eld/backend/core/backend_identity.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/status_dashboard_providers.dart';
import 'package:golden_feather_eld/backend/contracts/status_dashboard_backend.dart';

import '../../../../helpers/test_helpers.dart';

void main() {
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

  // ==========================================================================
  // changeStatus
  // ==========================================================================

  group('statusDashboardProvider — changeStatus', () {
    test('changes status to driving', () async {
      final container = createContainer();
      await container.read(statusDashboardProvider.future);

      await container
          .read(statusDashboardProvider.notifier)
          .changeStatus(DutyStatusCode.driving);

      final dashboard = container.read(statusDashboardProvider).value!;
      expect(dashboard.currentDutyStatus, DutyStatusCode.driving);
    });

    test('same status is a no-op (no state change)', () async {
      final container = createContainer();
      final original = await container.read(statusDashboardProvider.future);

      await container
          .read(statusDashboardProvider.notifier)
          .changeStatus(original.currentDutyStatus);

      final dashboard = container.read(statusDashboardProvider).value!;
      expect(dashboard.currentDutyStatus, original.currentDutyStatus);
    });

    test('accepts optional notes', () async {
      final container = createContainer();
      await container.read(statusDashboardProvider.future);

      await container
          .read(statusDashboardProvider.notifier)
          .changeStatus(DutyStatusCode.driving, notes: 'Trip started');

      final dashboard = container.read(statusDashboardProvider).value!;
      expect(dashboard.currentDutyStatus, DutyStatusCode.driving);
    });

    test('iterates through all statuses', () async {
      final container = createContainer();
      await container.read(statusDashboardProvider.future);

      final notifier = container.read(statusDashboardProvider.notifier);

      for (final status in [
        DutyStatusCode.driving,
        DutyStatusCode.offDuty,
        DutyStatusCode.sleeperBerth,
        DutyStatusCode.onDutyNotDriving,
        DutyStatusCode.yardMove,
        DutyStatusCode.personalConveyance,
      ]) {
        await notifier.changeStatus(status);
        expect(
          container.read(statusDashboardProvider).value!.currentDutyStatus,
          status,
        );
      }
    });

    test('state stays AsyncData during and after mutation', () async {
      final container = createContainer();
      await container.read(statusDashboardProvider.future);

      await container
          .read(statusDashboardProvider.notifier)
          .changeStatus(DutyStatusCode.driving);

      final current = container.read(statusDashboardProvider);
      expect(current, isA<AsyncData<StatusDashboard>>());
      expect(current.hasError, isFalse);
    });
  });

  // ==========================================================================
  // refresh
  // ==========================================================================

  group('statusDashboardProvider — refresh', () {
    test('reloads dashboard from backend', () async {
      final container = createContainer();
      await container.read(statusDashboardProvider.future);

      await container
          .read(statusDashboardProvider.notifier)
          .changeStatus(DutyStatusCode.driving);

      await container.read(statusDashboardProvider.notifier).refresh();

      final dashboard = container.read(statusDashboardProvider).value!;
      expect(dashboard.currentDutyStatus, DutyStatusCode.driving);
    });

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
    test('surfaces AppError when backend fails', () async {
      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(_FailingAdapter()),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(statusDashboardProvider.future),
        throwsA(isA<AppError>()),
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
