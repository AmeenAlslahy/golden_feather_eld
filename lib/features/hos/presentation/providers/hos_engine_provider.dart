import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/hos_configuration.dart';
import '../../../../core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/features/tracking/data/datasources/live_tracking_data_source.dart'; // ignore_architecture
import '../../../../core/services/local_storage_service.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../logs/data/providers/log_repository_providers.dart';
import '../../../sync/data/providers/sync_providers.dart';
import '../../../../backend/providers/backend_providers.dart';
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

  final tracking = ref.watch(liveTrackingDataSourceProvider);
  final sub = tracking.events.listen((event) {
    tracker.processEldEvent(event);
  });

  ref.onDispose(() {
    sub.cancel();
    tracker.dispose();
  });

  return tracker;
});
