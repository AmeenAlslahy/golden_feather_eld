// App-level repository providers — Composition Root
// This file re-exports Data providers so Presentation does not import Data directly
// Clean Architecture: Presentation -> App (Composition Root) -> Data -> Domain

export '../../backend/providers/backend_network_providers.dart' show traccarNativeClientProvider;
export '../../core/network/core_providers.dart' show backendTypeProvider, apiClientProvider, apiConfigProvider;
export '../../core/services/tracking_config_storage_service.dart' show trackingConfigStorageProvider;
export '../../features/codriver/data/providers/repository_providers.dart' show coDriverRepositoryProvider;
// DVIR & Inspection
export '../../features/dvir/data/providers/repository_providers.dart' show dvirRepositoryProvider;
// HOS
export '../../features/hos/data/providers/datasource_providers.dart' show hosLocalDataSourceProvider;
export '../../features/hos/data/providers/repository_providers.dart' show statusDashboardRepositoryProvider;
export '../../features/inspection/data/providers/repository_providers.dart' show inspectionRepositoryProvider;
// Logs
export '../../features/logs/data/repositories/log_repository_impl.dart' show logRepositoryProvider;
// Others
export '../../features/reports/data/providers/repository_providers.dart' show reportsRepositoryProvider;
export '../../features/sync/data/providers/repository_providers.dart' show offlineQueueProvider, syncDispatcherProvider;
export '../../features/sync/data/providers/repository_providers.dart' show syncRepositoryProvider;
// Tracking
export '../../features/tracking/data/providers/repository_providers.dart' show trackingRepositoryProvider;
export '../../features/tracking/data/providers/repository_providers.dart' show nativeEventChannelClientProvider;
export '../../features/tracking/data/services/tracking_service.dart' show trackingServiceProvider;
// Vehicle
export '../../features/vehicle/data/providers/repository_providers.dart' show vehicleRepositoryProvider;
