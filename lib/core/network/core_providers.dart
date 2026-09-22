import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../features/settings/presentation/providers/server_config_providers.dart';
import '../services/bluetooth_service.dart';
import '../services/local_storage_service.dart' as ls;
import 'api_config.dart';
import 'network_info.dart';

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
  return NetworkInfoImpl();
});

final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig.fromEnvironment();
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final serverUrlProvider = StateProvider<String>((ref) {
  final config = ref.watch(serverConfigProvider);
  if (config != null && config.baseUrl.isNotEmpty) {
    return config.baseUrl;
  }

  final storage = ref.watch(goldenFeatherEldLocalStorageProvider);
  return storage.serverUrl;
});

final backendTypeProvider = Provider<String>((ref) {
  final config = ref.watch(serverConfigProvider);
  if (config != null) {
    return config.backendType.wire;
  }

  final storage = ref.watch(goldenFeatherEldLocalStorageProvider);
  final serverUrl = ref.watch(serverUrlProvider);

  if (serverUrl.contains('/api/v1/tracker/traccar') ||
      serverUrl.contains('api.goldenfeather.com')) {
    return 'eld';
  } else if (serverUrl.contains('traccar.org') || serverUrl.contains('demo')) {
    return 'traccar';
  }

  return storage.backendType.isNotEmpty ? storage.backendType : 'traccar';
});
