import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/hos_configuration.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/events/eld_events_provider.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../logs/data/providers/log_repository_providers.dart';
import '../../../sync/data/providers/sync_providers.dart';
import '../../../../backend/providers/backend_providers.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';
import '../../domain/engine/hos_state_machine.dart';
import '../../domain/engine/hos_rules_engine.dart';
import '../../domain/engine/hos_calculator.dart';
import '../../domain/engine/tracking/duty_status_tracker.dart';

/// Configuration Provider
final hosConfigurationProvider = Provider<HosConfiguration>((ref) {
  final storage = ref.watch(localStorageProvider);
  return storage.hosConfiguration;
});

/// State Machine & Engine Provider
final hosEngineProvider = Provider<HosRulesEngine>((ref) {
  final config = ref.watch(hosConfigurationProvider);
  final timeProvider = ref.watch(trustedTimeProvider);
  final calculator = HosCalculator(config, timeProvider);
  final stateMachine = HosStateMachine(timeProvider);

  ref.onDispose(() {
    stateMachine.dispose();
  });

  return HosRulesEngine(
    calculator: calculator,
    stateMachine: stateMachine,
    timeProvider: timeProvider,
  );
});

/// Duty Status Tracker Provider
final dutyStatusTrackerProvider = Provider<DutyStatusTracker>((ref) {
  final repo = ref.watch(logRepositoryProvider);
  final localStorage = ref.watch(localStorageProvider);
  final syncEngine = ref.watch(syncEngineProvider);
  final dashboardBackend = ref.watch(statusDashboardBackendProvider);
  final timeProvider = ref.watch(trustedTimeProvider);

  final tracker = DutyStatusTracker(
    logRepository: repo,
    localStorage: localStorage,
    syncEngine: syncEngine,
    dashboardBackend: dashboardBackend,
    timeProvider: timeProvider,
    readDriverId: () => ref.read(currentDriverIdProvider),
  );

  ref.listen<AsyncValue>(eldEventsStreamProvider, (_, next) {
    if (next.hasValue && next.value != null) {
      tracker.processEldEvent(next.value!);
    }
  });

  ref.onDispose(() {
    tracker.dispose();
  });

  return tracker;
});

/// سرعة المركبة الحالية كم/س — 0 عند غياب القياس.
final currentSpeedKmhProvider = Provider<double>((ref) {
  final speedMs = ref.watch(currentVehicleSpeedProvider);
  return (speedMs ?? 0) * 3.6;
});

/// هل المركبة متحركة الآن (السرعة ≥ عتبة الحركة من الإعداد)؟
/// كان المنطق مكرراً في change_status_page وHosNotifier.changeStatus —
/// هذا هو المصدر الوحيد للقرار.
final isVehicleMovingProvider = Provider<bool>((ref) {
  return ref.watch(currentSpeedKmhProvider) >=
      ref.watch(hosConfigurationProvider).movingSpeedThresholdKmh;
});
