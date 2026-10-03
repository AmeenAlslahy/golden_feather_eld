/// Riverpod providers for the backend layer.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';
import '../../core/config/runtime_selection.dart';
import '../adapters/eld_engine/eld_engine_adapter.dart';
import '../adapters/mock/mock_adapter.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/network/core_providers.dart';
import '../contracts/account_backend.dart';
import '../contracts/auth_backend.dart';
import '../contracts/daily_logs_backend.dart';
import '../contracts/driver_session_backend.dart';
import '../contracts/duty_status_backend.dart';
import '../contracts/dvir_backend.dart';
import '../contracts/hardware_backend.dart';
import '../contracts/inspection_backend.dart';
import '../contracts/rules_screen_backend.dart';
import '../contracts/status_dashboard_backend.dart';
import '../contracts/unidentified_events_backend.dart';
import '../contracts/vehicle_backend.dart';
import '../core/backend_adapter.dart';
import '../core/backend_registry.dart';
/// View of [activeBackendProvider]. Not a second selector and not a second client.
final backendRegistryProvider = Provider<BackendRegistry>((ref) {
  return BackendRegistry.single(ref.watch(activeBackendProvider));
});

/// Provides the active [BackendAdapter].
///
/// Mock only when the environment is mock, or development saved an explicit
/// mock override. Production and staging ignore a saved mock flag.
/// The host comes from [serverUrlProvider], the same value the HTTP client uses.
final activeBackendProvider = Provider<BackendAdapter>((ref) {
  final prefs = ref.watch(localStorageProvider);
  final choice = resolveRuntimeBackend(
    environment: AppEnvironmentConfig.current,
    buildBaseUrl: AppEnvironmentConfig.apiBaseUrl,
    savedServerUrl: ref.watch(serverUrlProvider),
    savedBackendType: prefs.backendType,
  );

  if (choice.useMock) {
    return MockAdapter();
  }

  return EldEngineAdapter.create(
    baseUrl: choice.serverUrl,
    apiClient: ref.watch(apiClientProvider),
  );
});

// ==========================================================================
// Contract Providers
// ==========================================================================

final authBackendProvider = Provider<AuthBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.auth ?? (throw StateError('AuthBackend not supported by active adapter'));
});

final accountBackendProvider = Provider<AccountBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.account ?? (throw StateError('AccountBackend not supported by active adapter'));
});

final dailyLogsBackendProvider = Provider<DailyLogsBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.dailyLogs ?? (throw StateError('DailyLogsBackend not supported by active adapter'));
});

final driverSessionBackendProvider = Provider<DriverSessionBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.driverSession ?? (throw StateError('DriverSessionBackend not supported by active adapter'));
});

final dutyStatusBackendProvider = Provider<DutyStatusBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.dutyStatus ?? (throw StateError('DutyStatusBackend not supported by active adapter'));
});

final dvirBackendProvider = Provider<DvirBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.dvir ?? (throw StateError('DvirBackend not supported by active adapter'));
});

final hardwareBackendProvider = Provider<HardwareBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.hardware ?? (throw StateError('HardwareBackend not supported by active adapter'));
});

final inspectionBackendProvider = Provider<InspectionBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.inspection ?? (throw StateError('InspectionBackend not supported by active adapter'));
});

final rulesScreenBackendProvider = Provider<RulesScreenBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.rulesScreen ?? (throw StateError('RulesScreenBackend not supported by active adapter'));
});

final statusDashboardBackendProvider = Provider<StatusDashboardBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.statusDashboard ?? (throw StateError('StatusDashboardBackend not supported by active adapter'));
});

final unidentifiedEventsBackendProvider = Provider<UnidentifiedEventsBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.unidentifiedEvents ?? (throw StateError('UnidentifiedEventsBackend not supported by active adapter'));
});

final vehicleBackendProvider = Provider<VehicleBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.vehicle ?? (throw StateError('VehicleBackend not supported by active adapter'));
});
