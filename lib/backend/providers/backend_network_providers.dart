import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../http/api_client.dart';
import '../http/api_config.dart';
import '../http/interceptors/auth_interceptor.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import '../http/interceptors/request_logger.dart';
import '../../features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart';
import '../../features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart';
import '../../features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart';
import '../../core/config/app_environment.dart';
import '../../core/network/core_providers.dart';

final unauthenticatedEventProvider = Provider<StreamController<void>>((ref) {
  final controller = StreamController<void>.broadcast();
  ref.onDispose(() => controller.close());
  return controller;
});

// Provider لـ ApiClient (يعيد الإنشاء عند تغير السيرفر)
final apiClientProvider = Provider<ApiClient>((ref) {
  final coreConfig = ref.watch(apiConfigProvider);
  final serverUrl = ref.watch(serverUrlProvider);

  var effectiveUrl = serverUrl.isNotEmpty ? serverUrl : coreConfig.baseUrl;

  // ضمان أن الرابط يحتوي على /api
  if (effectiveUrl.isNotEmpty && !effectiveUrl.endsWith('/api')) {
    // إزالة أي / زائدة من النهاية
    while (effectiveUrl.endsWith('/')) {
      effectiveUrl = effectiveUrl.substring(0, effectiveUrl.length - 1);
    }
    effectiveUrl = '$effectiveUrl/api';
  }

  final effectiveConfig = ApiConfig(
    baseUrl: effectiveUrl,
    connectTimeout: coreConfig.connectTimeout,
    receiveTimeout: coreConfig.receiveTimeout,
  );

  final client = ApiClient(config: effectiveConfig);
  final dio = client.dio;

  final localDataSource = ref.watch(authLocalDataSourceProvider);
  final backendType = ref.watch(backendTypeProvider);
  
  final unauthController = ref.watch(unauthenticatedEventProvider);
  
  dio.interceptors.add(AuthInterceptor(
    localDataSource: localDataSource,
    backendType: backendType,
    onUnauthenticated: () {
      // Trigger event instead of directly depending on AuthStateProvider
      unauthController.add(null);
    },
  ));
  
  dio.interceptors.add(RequestLogger());

  return client;
});

// Provider لعميل التتبع الخلفي (بديلاً عن trackingClientProvider)
final traccarNativeClientProvider = Provider<TraccarNativeClient>((ref) {
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    return MockTraccarNativeClient();
  }
  return TraccarNativeClientImpl();
});
