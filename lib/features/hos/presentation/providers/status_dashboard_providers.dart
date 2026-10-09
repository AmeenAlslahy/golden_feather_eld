import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../domain/duty_status/status_dashboard.dart';
import '../../data/providers/status_dashboard_repository_providers.dart';
import '../../domain/engine/hos_rules_engine.dart';
import '../../domain/usecases/get_status_dashboard_use_case.dart';
import 'hos_provider.dart';
import '../../../../core/events/app_events.dart';

// --- Clean Architecture Providers ---

final getStatusDashboardUseCaseProvider = Provider<GetStatusDashboardUseCase>((ref) {
  return GetStatusDashboardUseCase(ref.watch(statusDashboardRepositoryProvider));
});
// Use cases mapped to providers

// --- State Providers ---

/// Manages the status dashboard state.
///
/// **Lifecycle:**
/// - Loads initial dashboard on first watch.
/// - Rebuilds when [getStatusDashboardUseCaseProvider] changes.
/// - Mutations via [changeStatus] update state in place.
/// - Performs a quiet periodic refresh every minute to keep HOS indicators updated.
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

    // تحديث دوري هادئ كل دقيقة لتحديث المؤشرات والعدادات
    final timer = Timer.periodic(const Duration(minutes: 1), (_) {
      refresh(showLoading: false);
    });
    ref.onDispose(timer.cancel);

    final useCase = ref.watch(getStatusDashboardUseCaseProvider);
    final result = await useCase.execute();
    return result.fold(
      (failure) => throw failure,
      (dashboard) => dashboard,
    );
  }

  // Method removed. Duty status changes must route through DutyStatusTracker 
  // to ensure offline sync queueing, correct HOS engine transitions, and 
  // single source of truth for backend syncing.

  /// Manually reloads the dashboard.
  Future<void> refresh({bool showLoading = true}) async {
    if (showLoading && !state.hasValue) {
      state = const AsyncValue<StatusDashboard>.loading();
    }

    final useCase = ref.read(getStatusDashboardUseCaseProvider);
    final result = await useCase.execute();
    result.fold(
      (failure) {
        if (!state.hasValue) {
          state = AsyncValue.error(failure, StackTrace.current);
        }
      },
      (dashboard) {
        state = AsyncValue.data(dashboard);
      },
    );
  }

  /// Clears any error state and reloads.
  Future<void> clearErrorAndReload() => refresh();
}
