import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'network_info.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'request_logger.dart';
import '../services/local_storage_service.dart' as ls;
import '../../features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart';
import '../../features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart';
import 'api_endpoints.dart';
import 'endpoints/traccar_endpoints.dart';
import 'endpoints/eld_server_endpoints.dart';
import '../../features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart';
import '../config/app_environment.dart';

final goldenFeatherEldLocalStorageProvider = ls.localStorageProvider;

// Provider for API Endpoints (Abstract Factory)
final endpointsProvider = Provider<ApiEndpoints>((ref) {
  final backendType = ref.watch(backendTypeProvider);
  
  if (backendType == 'eld') {
    return EldServerEndpoints();
  }
  return TraccarEndpoints();
});

// Provider لحالة الاتصال (قابل للمتابعة)
final isConnectedProvider = StreamProvider<bool>((ref) {
  final networkInfo = ref.watch(networkInfoProvider);
  return networkInfo.onConnectionChange;
});

// Provider للشبكة
final networkInfoProvider = Provider<NetworkInfo>((ref) {
  return NetworkInfoImpl();
});

// Provider للإعدادات
final apiConfigProvider = Provider<ApiConfig>((ref) {
  return ApiConfig.fromEnvironment();
});

// Provider للتخزين الآمن
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

// Providers للحالة المتفاعلة
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

// Provider لـ ApiClient (يعيد الإنشاء عند تغير السيرفر)
final apiClientProvider = Provider<ApiClient>((ref) {
  final config = ref.watch(apiConfigProvider);
  final serverUrl = ref.watch(serverUrlProvider);
  
  final effectiveUrl = serverUrl.isNotEmpty ? serverUrl : config.baseUrl;
  final effectiveConfig = ApiConfig(
    baseUrl: effectiveUrl.endsWith('/') 
        ? effectiveUrl.substring(0, effectiveUrl.length - 1) 
        : effectiveUrl,
    connectTimeout: config.connectTimeout,
    receiveTimeout: config.receiveTimeout,
  );

  final dio = Dio();
  final client = ApiClient(config: effectiveConfig, dio: dio);
  
  final sessionStore = ref.watch(authSessionStoreProvider);
  final endpoints = ref.watch(endpointsProvider);
  final backendType = ref.watch(backendTypeProvider);
  client.addInterceptor(AuthInterceptor(sessionStore, endpoints, backendType));
  client.addInterceptor(RequestLogger());
  
  return client;
});

// Provider لعميل التتبع الخلفي (بديلاً عن trackingClientProvider)
final traccarNativeClientProvider = Provider<TraccarNativeClient>((ref) {
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    return MockTraccarNativeClient();
  }
  return TraccarNativeClientImpl();
});