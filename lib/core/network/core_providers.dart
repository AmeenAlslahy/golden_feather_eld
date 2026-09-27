import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'network_info.dart';
import 'api_config.dart';
import '../services/local_storage_service.dart' as ls;
import '../config/server_config_store.dart';
import '../services/bluetooth_service.dart';
import '../config/app_environment.dart';
import '../config/runtime_selection.dart';

// Re-export apiClientProvider so files only need to import core_providers.dart
export '../../backend/providers/backend_network_providers.dart'
    show apiClientProvider, traccarNativeClientProvider;

final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  final service = BluetoothService();
  ref.onDispose(() => service.dispose());
  return service;
});

final goldenFeatherEldLocalStorageProvider = ls.localStorageProvider;

final isConnectedProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.onConnectionChange;
});

final networkInfoProvider = Provider<NetworkInfo>((ref) {
  final networkInfo = NetworkInfoImpl();
  // النسخة السابقة لم تستدعِ dispose أبداً — اشتراك Connectivity بقي للأبد.
  ref.onDispose(networkInfo.dispose);
  return networkInfo;
});

final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig.fromEnvironment();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final serverUrlProvider = Provider<String>((ref) {
  final config = ref.watch(serverConfigProvider);
  final storage = ref.watch(goldenFeatherEldLocalStorageProvider);
  final saved = config != null && config.baseUrl.isNotEmpty
      ? config.baseUrl
      : storage.serverUrl;
  return resolveRuntimeBackend(
    environment: AppEnvironmentConfig.current,
    buildBaseUrl: AppEnvironmentConfig.apiBaseUrl,
    savedServerUrl: saved,
    savedBackendType: storage.backendType,
  ).serverUrl;
});

final backendTypeProvider = Provider<String>((ref) {
  final config = ref.watch(serverConfigProvider);
  final storage = ref.watch(goldenFeatherEldLocalStorageProvider);
  return resolveBackendType(
    configuredType: AppEnvironmentConfig.configuredBackendType,
    savedConfigType: config?.backendType.wire,
    storedType: storage.backendType,
  );
});
