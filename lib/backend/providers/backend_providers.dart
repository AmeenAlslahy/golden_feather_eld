/// Riverpod providers for the backend layer.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_environment.dart';
import '../adapters/eld_engine/eld_engine_adapter.dart';
import '../adapters/mock/mock_adapter.dart';
import '../../core/services/local_storage_service.dart';
import '../../core/network/interceptors/time_drift_interceptor.dart';
import '../../core/time/trusted_time_provider.dart';
import '../contracts/account_backend.dart';
import '../contracts/auth_backend.dart';
import '../contracts/compliance_backend.dart';
import '../contracts/config_backend.dart';
import '../contracts/daily_logs_backend.dart';
import '../contracts/driver_rules_backend.dart';
import '../contracts/driver_session_backend.dart';
import '../contracts/duty_status_backend.dart';
import '../contracts/dvir_backend.dart';
import '../contracts/fleet_dashboard_backend.dart';
import '../contracts/hardware_backend.dart';
import '../contracts/health_backend.dart';
import '../contracts/inspection_backend.dart';
import '../contracts/log_transfer_backend.dart';
import '../contracts/reports_backend.dart';
import '../contracts/rules_engine_backend.dart';
import '../contracts/rules_screen_backend.dart';
import '../contracts/stats_backend.dart';
import '../contracts/status_dashboard_backend.dart';
import '../contracts/unidentified_events_backend.dart';
import '../contracts/vehicle_backend.dart';
import '../core/backend_adapter.dart';
import '../core/backend_registry.dart';
import '../http/api_client.dart';
import '../http/api_config.dart';
import 'backend_network_providers.dart';

/// Provides the global [BackendRegistry].
///
/// In Phase 1, it registers [MockAdapter] and [EldEngineAdapter].
final backendRegistryProvider = Provider<BackendRegistry>((ref) {
  final mockAdapter = MockAdapter();
  final realAdapter = EldEngineAdapter.create(
    baseUrl: 'https://snsoft.cloud',
    apiClient: ApiClient(
      config: const ApiConfig(baseUrl: 'https://snsoft.cloud/api'),
    ),
  );

  return BackendRegistry(
    adapters: [mockAdapter, realAdapter],
    activeId: mockAdapter.identity.id, // Default to mock for local dev
  );
});

/// Provides the active [BackendAdapter].
///
/// يستخدم [apiClientProvider] الموحّد الذي يحتوي على AuthInterceptor
/// لضمان إرسال التوكن مع كل الطلبات.
/// يُعاد الرجوع إلى [MockAdapter] فقط عند ضبط البيئة صراحةً على `mock`.
final activeBackendProvider = Provider<BackendAdapter>((ref) {
  final prefs = ref.watch(localStorageProvider);
  
  // الوضع الوهمي (Mock)
  if (prefs.backendType == 'mock' || AppEnvironmentConfig.current == AppEnvironment.mock) {
    return MockAdapter();
  }

  // استخدام apiClientProvider الموحّد (يحتوي على AuthInterceptor + RequestLogger)
  final apiClient = ref.watch(apiClientProvider);

  // حقن متلقف حساب التوقيت (Time Drift)
  apiClient.dio.interceptors.add(
    TimeDriftInterceptor(timeProvider: ref.read(trustedTimeProvider)),
  );

  final baseUrl = prefs.serverUrl.isNotEmpty ? prefs.serverUrl : 'https://snsoft.cloud';

  return EldEngineAdapter.create(
    baseUrl: baseUrl,
    apiClient: apiClient,
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

final complianceBackendProvider = Provider<ComplianceBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.compliance ?? (throw StateError('ComplianceBackend not supported by active adapter'));
});

final configBackendProvider = Provider<ConfigBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.config ?? (throw StateError('ConfigBackend not supported by active adapter'));
});

final dailyLogsBackendProvider = Provider<DailyLogsBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.dailyLogs ?? (throw StateError('DailyLogsBackend not supported by active adapter'));
});

final driverRulesBackendProvider = Provider<DriverRulesBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.driverRules ?? (throw StateError('DriverRulesBackend not supported by active adapter'));
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

final fleetDashboardBackendProvider = Provider<FleetDashboardBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.fleetDashboard ?? (throw StateError('FleetDashboardBackend not supported by active adapter'));
});

final hardwareBackendProvider = Provider<HardwareBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.hardware ?? (throw StateError('HardwareBackend not supported by active adapter'));
});

final healthBackendProvider = Provider<HealthBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.health ?? (throw StateError('HealthBackend not supported by active adapter'));
});

final inspectionBackendProvider = Provider<InspectionBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.inspection ?? (throw StateError('InspectionBackend not supported by active adapter'));
});

final logTransferBackendProvider = Provider<LogTransferBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.logTransfer ?? (throw StateError('LogTransferBackend not supported by active adapter'));
});

final reportsBackendProvider = Provider<ReportsBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.reports ?? (throw StateError('ReportsBackend not supported by active adapter'));
});

final rulesEngineBackendProvider = Provider<RulesEngineBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.rulesEngine ?? (throw StateError('RulesEngineBackend not supported by active adapter'));
});

final rulesScreenBackendProvider = Provider<RulesScreenBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.rulesScreen ?? (throw StateError('RulesScreenBackend not supported by active adapter'));
});

final statsBackendProvider = Provider<StatsBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.stats ?? (throw StateError('StatsBackend not supported by active adapter'));
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
