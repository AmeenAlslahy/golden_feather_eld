import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../backend/providers/backend_providers.dart';
import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';

/// Manages the status dashboard state.
///
/// **Lifecycle:**
/// - Loads initial dashboard on first watch.
/// - Rebuilds when [statusDashboardBackendProvider] changes
///   (e.g., swapping Mock ↔ Real adapter).
/// - Mutations via [changeStatus] update state in place.
///
/// **Error handling:**
/// - Errors are surfaced as [AsyncError] with the underlying [AppError].
/// - UI resolves `error.l10nKey` for display.
final statusDashboardProvider =
    AsyncNotifierProvider<StatusDashboardNotifier, StatusDashboard>(
  StatusDashboardNotifier.new,
);

class StatusDashboardNotifier extends AsyncNotifier<StatusDashboard> {
  @override
  Future<StatusDashboard> build() async {
    final backend = ref.watch(statusDashboardBackendProvider);
    final result = await backend.getDashboard();
    return result.fold(
      (error) => throw error,
      (dashboard) => dashboard,
    );
  }

  /// Changes duty status via the backend.
  ///
  /// **Optimization:** Skips the network call if the requested
  /// status equals the current one.
  ///
  /// **Error handling:** Failures move state to [AsyncError]; the
  /// previous value is lost (intentional — UI shows retry).
  Future<void> changeStatus(DutyStatusCode status, {String? notes}) async {
    final current = state.valueOrNull;
    if (current != null && current.currentDutyStatus == status) {
      return;
    }

    state = const AsyncValue<StatusDashboard>.loading();

    final backend = ref.read(statusDashboardBackendProvider);
    final result = await backend.updateDutyStatus(
      status: status,
      notes: notes,
    );

    state = result.fold(
      (error) => AsyncValue.error(error, StackTrace.current),
      (dashboard) => AsyncValue.data(dashboard),
    );
  }

  /// Manually reloads the dashboard from the backend.
  ///
  /// Useful when the user pulls-to-refresh, or after a session
  /// restoration.
  Future<void> refresh() async {
    state = const AsyncValue<StatusDashboard>.loading();

    state = await AsyncValue.guard(() async {
      final backend = ref.read(statusDashboardBackendProvider);
      final result = await backend.getDashboard();
      return result.fold(
        (error) => throw error,
        (dashboard) => dashboard,
      );
    });
  }

  /// Clears any error state and reloads.
  ///
  /// Useful when the UI wants to dismiss an error banner and retry.
  Future<void> clearErrorAndReload() => refresh();
}
