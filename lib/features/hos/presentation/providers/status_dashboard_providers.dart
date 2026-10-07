import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/duty_status/duty_status_code.dart';
import '../../../../domain/duty_status/status_dashboard.dart';
import '../../data/providers/status_dashboard_repository_providers.dart';
import '../../domain/engine/hos_rules_engine.dart';
import '../../domain/usecases/get_status_dashboard_use_case.dart';
import '../../domain/usecases/update_duty_status_use_case.dart';
import 'hos_provider.dart';
import '../../../../core/events/app_events.dart';

// --- Clean Architecture Providers ---

final getStatusDashboardUseCaseProvider = Provider<GetStatusDashboardUseCase>((ref) {
  return GetStatusDashboardUseCase(ref.watch(statusDashboardRepositoryProvider));
});

final updateDutyStatusUseCaseProvider = Provider<UpdateDutyStatusUseCase>((ref) {
  return UpdateDutyStatusUseCase(ref.watch(statusDashboardRepositoryProvider));
});

// --- State Providers ---

/// Manages the status dashboard state.
///
/// **Lifecycle:**
/// - Loads initial dashboard on first watch.
/// - Rebuilds when [getStatusDashboardUseCaseProvider] changes.
/// - Mutations via [changeStatus] update state in place.
///
/// **Error handling:**
/// - Errors are surfaced as [AsyncError] with the underlying [Failure].
final statusDashboardProvider =
    AsyncNotifierProvider<StatusDashboardNotifier, StatusDashboard>(
  StatusDashboardNotifier.new,
);

class StatusDashboardNotifier extends AsyncNotifier<StatusDashboard> {
  @override
  Future<StatusDashboard> build() async {
    // تحديث تفاعلي تلقائي للوحة عند تغير حالة السائق في محرك HOS
    ref.listen<HosEngineResult>(hosStatusProvider, (prev, next) {
      if (prev is HosEngineReady && next is HosEngineReady) {
        if (prev.update.currentStatus != next.update.currentStatus) {
          refresh();
        }
      }
    });
    
    final bus = ref.watch(appEventBusProvider);
    final sub = bus.stream.listen((event) {
      if (event == AppEvent.logDataChanged) refresh();
    });
    ref.onDispose(sub.cancel);

    final useCase = ref.watch(getStatusDashboardUseCaseProvider);
    final result = await useCase.execute();
    return result.fold(
      (failure) => throw failure,
      (dashboard) => dashboard,
    );
  }

  /// Changes duty status via the use case.
  ///
  /// **Optimization:** Skips the network call if the requested
  /// status equals the current one.
  Future<void> changeStatus(DutyStatusCode status, {String? notes}) async {
    final current = state.valueOrNull;
    if (current != null && current.currentDutyStatus == status) {
      return;
    }

    state = const AsyncValue<StatusDashboard>.loading();

    final useCase = ref.read(updateDutyStatusUseCaseProvider);
    final result = await useCase.execute(
      status: status,
      notes: notes,
    );

    state = result.fold(
      (failure) => AsyncValue.error(failure, StackTrace.current),
      (dashboard) => AsyncValue.data(dashboard),
    );
  }

  /// Manually reloads the dashboard.
  Future<void> refresh() async {
    state = const AsyncValue<StatusDashboard>.loading();

    state = await AsyncValue.guard(() async {
      final useCase = ref.read(getStatusDashboardUseCaseProvider);
      final result = await useCase.execute();
      return result.fold(
        (failure) => throw failure,
        (dashboard) => dashboard,
      );
    });
  }

  /// Clears any error state and reloads.
  Future<void> clearErrorAndReload() => refresh();
}
