import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_config.dart';
import '../http/interceptors/auth_interceptor.dart';
import '../../core/session/auth_session_provider.dart';
import '../http/interceptors/request_logger.dart';
import '../http/interceptors/time_drift_interceptor.dart';
import '../../core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart'; // ignore_architecture
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart'; // ignore_architecture
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart'; // ignore_architecture
import '../../core/config/app_environment.dart';
import '../../core/network/core_providers.dart';

/// P0 Stage 1: يحمل epoch الطلب المرفوض بـ 401 حتى يتجاهل المستمع
/// الأحداث الأقدم من الجيل الحالي (late 401 من جلسة سابقة).
final unauthenticatedEventProvider = Provider<StreamController<int>>((ref) {
  final controller = StreamController<int>.broadcast();
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
    sendTimeout: coreConfig.sendTimeout,
  );

  final client = ApiClient(config: effectiveConfig);
  final dio = client.dio;

  final localDataSource = ref.watch(authSessionReaderProvider);
  final backendType = ref.watch(backendTypeProvider);

  final unauthController = ref.watch(unauthenticatedEventProvider);

  dio.interceptors.add(
    AuthInterceptor(
      localDataSource: localDataSource,
      backendType: backendType,
      onUnauthenticated: (requestEpoch) {
        // Trigger event instead of directly depending on AuthStateProvider
        unauthController.add(requestEpoch);
      },
    ),
  );

  if (kDebugMode) dio.interceptors.add(RequestLogger());
  // Added once per client. Do not add it again when the backend provider rebuilds.
  dio.interceptors.add(
    TimeDriftInterceptor(timeProvider: ref.read(trustedTimeProvider)),
  );

  return client;
});

// Provider لعميل التتبع الخلفي (بديلاً عن trackingClientProvider)
final traccarNativeClientProvider = Provider<TraccarNativeClient>((ref) {
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    return MockTraccarNativeClient();
  }
  return TraccarNativeClientImpl();
});
