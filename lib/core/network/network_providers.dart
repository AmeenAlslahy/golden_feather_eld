import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'api_client.dart';
import 'api_config.dart';
import 'auth_interceptor.dart';
import '../../features/auth/presentation/providers/auth_providers.dart';
import 'request_logger.dart';
import '../../features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart';
import '../../features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart';
import '../../features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart';
import '../config/app_environment.dart';
import 'core_providers.dart';

final unauthenticatedEventProvider = Provider<StreamController<void>>((ref) {
  final controller = StreamController<void>.broadcast();
  ref.onDispose(() => controller.close());
  return controller;
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
  
  final unauthController = ref.watch(unauthenticatedEventProvider);
  
  client.addInterceptor(AuthInterceptor(
    sessionStore: sessionStore,
    endpoints: endpoints,
    backendType: backendType,
    onUnauthenticated: () {
      // Trigger event instead of directly depending on AuthStateProvider
      unauthController.add(null);
    },
  ));
  
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
