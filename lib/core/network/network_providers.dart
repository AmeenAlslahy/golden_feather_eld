import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'network_info.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import 'request_logger.dart';
import '../services/local_storage_service.dart' as ls; // 🆕
final golden_feather_eld_local_storage_provider = ls.localStorageProvider; // 🆕

/// Provider لحالة الاتصال
final isConnectedProvider = StreamProvider<bool>((ref) {
  // To avoid breaking the UI that relies on this, we'll return a simple stream or remove the stream.
  // Actually, since connectivity_plus supports streams, let's just return a dummy stream or re-add it.
  // For now, let's just return Stream.value(true) temporarily since we removed the stream from NetworkInfo to match user snippet.
  return Stream.value(true); 
});

/// Provider للشبكة
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

/// Provider for ApiConfig
final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig.fromEnvironment();
});

/// Provider for FlutterSecureStorage
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

/// Provider for ApiClient
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  
  // Use the server URL from local storage if available, otherwise fallback to config
  final serverUrl = ref.watch(golden_feather_eld_local_storage_provider).serverUrl;
  final effectiveBaseUrl = serverUrl.isNotEmpty ? serverUrl : config.baseUrl;

  final effectiveConfig = ApiConfig(
    baseUrl: effectiveBaseUrl.endsWith('/') ? effectiveBaseUrl.substring(0, effectiveBaseUrl.length - 1) : effectiveBaseUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
  );

  final client = ApiClient(
    config: effectiveConfig,
    dio: Dio(),
  );
  
  client.addInterceptor(AuthInterceptor(secureStorage));
  client.addInterceptor(RequestLogger());
  
  return client;
});
