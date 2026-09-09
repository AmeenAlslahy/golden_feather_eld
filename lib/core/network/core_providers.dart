import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'network_info.dart';
import 'api_config.dart';
import 'api_endpoints.dart';
import 'endpoints/traccar_endpoints.dart';
import 'endpoints/eld_server_endpoints.dart';
import '../services/local_storage_service.dart' as ls;

// Re-export apiClientProvider so files only need to import core_providers.dart
export 'network_providers.dart'
    show apiClientProvider, traccarNativeClientProvider;

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
  final storage = ref.watch(goldenFeatherEldLocalStorageProvider);
  return storage.serverUrl;
});

final backendTypeProvider = Provider<String>((ref) {
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

final endpointsProvider = Provider<ApiEndpoints>((ref) {
  final backendType = ref.watch(backendTypeProvider);

  if (backendType == 'eld') {
    return EldServerEndpoints();
  }
  return TraccarEndpoints();
});

final rawDioProvider = Provider<Dio>((ref) {
  final config = ref.watch(apiConfigProvider);
  final serverUrl = ref.watch(serverUrlProvider);

  final effectiveUrl = serverUrl.isNotEmpty ? serverUrl : config.baseUrl;
  final baseUrl = effectiveUrl.endsWith('/')
      ? effectiveUrl.substring(0, effectiveUrl.length - 1)
      : effectiveUrl;

  return Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
  ));
});
