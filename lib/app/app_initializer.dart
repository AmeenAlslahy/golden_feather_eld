import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart';
import '../features/tracking/data/services/tracking_service.dart';
import '../core/services/local_database_service.dart';
import '../core/services/local_storage_service.dart';
import 'services/push_notification_service.dart';
import '../core/services/utc_sync_service.dart';
import '../core/config/app_environment.dart';
import '../core/utils/logger.dart';
import '../core/utils/startup_profiler.dart';
import '../core/events/eld_events_provider.dart';
import '../core/session/auth_session_provider.dart';
import '../features/tracking/data/datasources/live_tracking_data_source.dart';
import 'di/auth_local_data_source_provider.dart';
import '../features/sync/presentation/providers/sync_provider.dart';
import '../features/sync/data/providers/sync_providers.dart';
import 'orchestrators/tracking_orchestrator.dart';

class AppInitializer {
  late final LocalStorageService localStorageService;
  late final LocalDatabaseService localDatabaseService;
  Future<void>? _dbInitFuture;
  late final TrackingService trackingService;
  late final UtcSyncService utcSync;

  Future<void> initialize() async {
    // 1. تهيئة البيئة
    await StartupProfiler.phase('init:env', () => AppEnvironmentConfig.init());

    // 2. تهيئة Firebase بشكل آمن (استيعاب الفشل للبيئات التي لا تملك Configuration)
    await StartupProfiler.phase('init:firebase', () async {
      try {
        await Firebase.initializeApp();
        AppLogger.info('Firebase initialized successfully');
      } catch (e) {
        AppLogger.warning(
          'Firebase initialization failed (App will continue without Firebase services): $e',
        );
      }
    });

    // 3. تهيئة الخدمات الأساسية (Hive يهيّئ نفسه فقط؛ الصناديق lazy)
    await StartupProfiler.phase(
      'init:local-storage',
      () => _initCoreServices(),
    );

    // 4. تهيئة الخدمات المعتمدة
    await StartupProfiler.phase(
      'init:tracking+push',
      () => _initDependentServices(),
    );

    // 5. انتظار تهيئة Hive فقط (Hive.initFlutter). لا صندوق يُفتح هنا:
    //    كل صندوق يُفتح عند أول استخدام فعلي عبر ensureHiveBox.
    if (_dbInitFuture != null) {
      await StartupProfiler.phase('init:await-hive', () => _dbInitFuture!);
    }

    // 6. تهيئة خدمات المزامنة
    await StartupProfiler.phase('init:utc-sync', () => _initSyncServices());
  }

  Future<void> _initCoreServices() async {
    localStorageService = LocalStorageService();
    await localStorageService.init();

    // Hive: تهيئة المسار فقط (سريعة) — لا فتح صناديق.
    // الصناديق تُفتح عند أول قراءة/كتابة عبر `ensureHiveBox`، فلا يحجب
    // الإقلاع فتحُ خمسة صناديق وترحيلها (كان ~13 ثانية على جهاز الاختبار).
    // تنبيه: يُستدعى من initialize() مرة واحدة فقط — إسناد late final
    // مزدوج يرمي LateInitializationError (حدث فعلياً في 2026-09-30).
    localDatabaseService = LocalDatabaseService();
    StartupProfiler.mark('init:hive:init-start');
    _dbInitFuture = localDatabaseService.init();
    // قياس فقط — مستمع منفصل لا يغيّر المستقبل الأصلي ولا ترتيبه.
    unawaited(
      _dbInitFuture!.whenComplete(
        () => StartupProfiler.mark('init:hive:init-done'),
      ),
    );
  }

  Future<void> _initDependentServices() async {
    trackingService = TrackingService(
      storage: localStorageService,
      tracker: TraccarNativeClientImpl(),
    );
    await StartupProfiler.phase('init:tracking', () => trackingService.init());

    await StartupProfiler.phase('init:push', () async {
      try {
        await PushNotificationService.init(
          trackingService: trackingService,
          storage: localStorageService,
        );
      } catch (e) {
        AppLogger.error('PushNotificationService initialization failed', e);
      }
    });
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
        liveEldEventSourceProvider.overrideWith(
          (ref) => ref.watch(liveTrackingDataSourceProvider),
        ),
        authSessionReaderProvider.overrideWith(
          (ref) => ref.watch(authLocalDataSourceProvider),
        ),
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
    // /eld/config/settings (وسم 19) خارج نطاق تطبيق السائق —
    // الخادم يرد 500 NPE دائماً. الاستدعاء أُزيل وفق قرار المالك.

    // تمت إزالة الاستدعاء المتوازي لـ getSession() لأنه كان يسبب Deadlock
    // مع شاشة الإقلاع (SplashPage) في مكتبة flutter_secure_storage على أندرويد
    // عند استدعائه مرتين في نفس الوقت.

    // تأجيل مبدئي لتخفيف الضغط على الخيط الرئيسي (Main Thread) عند الإقلاع
    Future.delayed(const Duration(milliseconds: 500), () {
      container.read(syncStateProvider.notifier);
      container.read(syncEngineProvider);
      container.read(trackingOrchestratorProvider);

      // 🔄 مزامنة عند الفتح: المتطلب "إن توفّر النت يعمل أونلاين، وإلا
      // أوفلاين".
      //
      // لماذا الاستدعاء الصريح: مشغّلNetworkInfo يستمع *لانتقالات* الشبكة.
      // عند فتح التطبيق والخ��د متصل أصلاً لا تقع انتقال�� (true) ← لا تُشغَّل
      // المزامنة إطلاقاً، فتبقى الأحداث المؤجلة حتى أول انقطاع/عودة.
      // هنا نطلب صراحةً مرة واحدة عند الإقلاع؛ `SyncEngine.triggerSync`
      // محمي بـ _isSyncing فالنكرار آمن.
      //
      // بلا اتصال: triggerSync يجرّب الإرسال، تفشل المحاولات، وتُعاد
      // جدولتها بـ backoff — بلا فقدان بيانات (لا dead-letter أبداً).
      container.read(syncEngineProvider).triggerSync();
    });

    StartupProfiler.mark('post-container: providers wired');
  }
}
