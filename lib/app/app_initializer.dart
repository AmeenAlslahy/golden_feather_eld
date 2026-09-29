import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart';
import '../features/tracking/data/services/tracking_service.dart';
import '../core/di/auth_local_data_source_provider.dart';
import '../core/services/local_database_service.dart';
import '../core/services/local_storage_service.dart';
import 'services/push_notification_service.dart';
import 'services/remote_config_service.dart';
import '../core/services/utc_sync_service.dart';
import '../core/config/app_environment.dart';
import '../core/utils/logger.dart';
import '../features/sync/presentation/providers/sync_provider.dart';
import '../features/sync/data/providers/sync_providers.dart';
import 'orchestrators/tracking_orchestrator.dart';

class AppInitializer {
  late final LocalStorageService localStorageService;
  late final LocalDatabaseService localDatabaseService;
  late final TrackingService trackingService;
  late final UtcSyncService utcSync;

  Future<void> initialize() async {
    // 1. تهيئة البيئة
    await AppEnvironmentConfig.init();

    // 2. تهيئة Firebase بشكل آمن (استيعاب الفشل للبيئات التي لا تملك Configuration)
    try {
      await Firebase.initializeApp();
      AppLogger.info('Firebase initialized successfully');
    } catch (e) {
      AppLogger.warning(
          'Firebase initialization failed (App will continue without Firebase services): $e');
    }

    // 3. تهيئة الخدمات الأساسية
    await _initCoreServices();

    // 4. تهيئة الخدمات المعتمدة
    await _initDependentServices();

    // 5. تهيئة خدمات المزامنة
    await _initSyncServices();
  }

  Future<void> _initCoreServices() async {
    localStorageService = LocalStorageService();
    await localStorageService.init();

    // Hive (1 ثانية على الأجهزة المتوسطة) لا يحجب الإقلاع: يُفتح بالتوازي
    // مع بقية التهيئة — المستودعات لا تقرأه إلا بعد اكتمال runApp.
    localDatabaseService = LocalDatabaseService();
    final dbFuture = localDatabaseService.init();

    await _initDependentServices();
    await dbFuture;
  }

  Future<void> _initDependentServices() async {
    trackingService = TrackingService(
      storage: localStorageService,
      tracker: TraccarNativeClientImpl(),
    );
    await trackingService.init();

    try {
      await PushNotificationService.init(
        trackingService: trackingService,
        storage: localStorageService,
      );
    } catch (e) {
      AppLogger.error('PushNotificationService initialization failed', e);
    }
  }

  Future<void> _initSyncServices() async {
    utcSync = UtcSyncService();
    await utcSync.syncWithUtc();
  }

  ProviderContainer createProviderContainer() {
    return ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(localStorageService),
        localDatabaseServiceProvider.overrideWithValue(localDatabaseService),
        trackingServiceProvider.overrideWithValue(trackingService),
        utcSyncServiceProvider.overrideWithValue(utcSync),
      ],
    );
  }

  Future<void> initializePostContainer(ProviderContainer container) async {
    // UtcSyncService.utcNow is DateTime.now(). Anchoring TrustedTimeProvider
    // from it would let a device clock become a legal duty stamp. Only a
    // server Date header, through TimeDriftInterceptor, may anchor the clock.

    // جلب إعدادات الخادم لم يعد يحجب الإقلاع: كان أول إطار ينتظر دورة
    // شبكة كاملة (حتى 30 ثانية على شبكة ضعيفة). يعمل الآن بالخلفية،
    // والواجهة تُفتح فوراً على القيم المخزنة محلياً.
    unawaited(() async {
      try {
        await RemoteConfigService.fetchOnStartup(container);
      } catch (e) {
        AppLogger.error('Background remote-config fetch failed', e);
      }
    }());

    // تدفئة كاش الجلسة: أول قراءة من Android Keystore مكلفة (ثوانٍ على
    // بعض الأجهزة) — تُدفأ هنا بالتوازي بدل أن تحجب أول طلب HTTP.
    unawaited(container.read(authLocalDataSourceProvider).getSession());

    Future.microtask(() {
      container.read(syncStateProvider.notifier);
      container.read(syncEngineProvider);
      container.read(trackingOrchestratorProvider);
    });
  }
}
