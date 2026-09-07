import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart';
import '../../features/tracking/data/services/tracking_service.dart';
import 'local_database_service.dart';
import 'local_storage_service.dart';
import 'push_notification_service.dart';
import 'remote_config_service.dart';
import 'utc_sync_service.dart';
import '../config/app_environment.dart';
import '../utils/logger.dart';
import '../../features/sync/presentation/providers/sync_provider.dart';
import '../../features/sync/presentation/providers/sync_engine_provider.dart';
import '../time/trusted_time_provider.dart';

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

    localDatabaseService = LocalDatabaseService();
    await localDatabaseService.init();
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
    // إرساء التوقيت الموثوق باستخدام خدمة المزامنة
    final utcSyncService = container.read(utcSyncServiceProvider);
    container.read(trustedTimeProvider).anchor(utcSyncService.utcNow);

    try {
      await RemoteConfigService.fetchOnStartup(container);
    } catch (e) {
      AppLogger.error('Failed to fetch remote config on startup', e);
    }

    Future.microtask(() {
      container.read(syncStateProvider.notifier);
      container.read(syncEngineProvider);
    });
  }
}
