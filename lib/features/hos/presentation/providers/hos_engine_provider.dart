import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/hos_configuration.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/services/live_tracking_data_source.dart';
import '../../../../core/services/local_storage_service.dart';
import '../../../logs/data/repositories/log_repository_impl.dart';
import '../../../sync/presentation/providers/sync_engine_provider.dart';
import '../../data/datasources/hos_local_data_source.dart';
import '../../domain/engine/hos_state_machine.dart';
import '../../domain/engine/hos_rules_engine.dart';
import '../../domain/engine/hos_calculator.dart';
import '../../domain/engine/hos_violations_engine.dart';
import '../../domain/engine/tracking/duty_status_tracker.dart';
import '../../domain/engine/tracking/distance_tracker.dart';
import '../../domain/engine/diagnostics/diagnostics_engine.dart';

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
  final timeProvider = ref.watch(trustedTimeProvider);

  final tracker = DutyStatusTracker(
    logRepository: repo,
    localStorage: localStorage,
    syncEngine: syncEngine,
    timeProvider: timeProvider,
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

/// Distance Tracker Provider
final distanceTrackerProvider = Provider<DistanceTracker>((ref) {
  final timeProvider = ref.watch(trustedTimeProvider);
  final tracker = DistanceTracker(timeProvider);
  final dataSource = ref.watch(liveTrackingDataSourceProvider);

  final subscription = dataSource.locations.listen((point) {
    tracker.addPoint(point);
  });

  ref.onDispose(() {
    subscription.cancel();
    tracker.clear();
  });

  return tracker;
});

/// Violations Engine Provider
final hosViolationsEngineProvider = Provider<HosViolationsEngine>((ref) {
  final tracker = ref.watch(dutyStatusTrackerProvider);
  final db = ref.watch(hosLocalDataSourceProvider);
  final config = ref.watch(hosConfigurationProvider);
  final timeProvider = ref.watch(trustedTimeProvider);
  final engine = HosViolationsEngine(tracker, db, config, timeProvider);
  
  ref.onDispose(() {
    engine.dispose();
  });
  
  return engine;
});

/// Diagnostics Engine Provider
final diagnosticsEngineProvider = Provider<DiagnosticsEngine>((ref) {
  final tracking = ref.watch(liveTrackingDataSourceProvider);
  final db = ref.watch(hosLocalDataSourceProvider);
  final timeProvider = ref.watch(trustedTimeProvider);
  final engine = DiagnosticsEngine(tracking, db, timeProvider);
  ref.onDispose(() {
    engine.dispose();
  });
  return engine;
});
