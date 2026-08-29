# FLOWCHART EVIDENCE MATRIX

| Flow ID | Node / Decision | Evidence File | Class | Method / Symbol | Confidence | Status |
|---|---|---|---|---|---|---|
| FLOW-BOOT-001 | بدء التطبيق / Application Start | `lib/main.dart` | N/A | `main()` | High | VERIFIED |
| FLOW-BOOT-002 | تهيئة البيئة / Environment Initialization | `lib/core/services/app_initializer.dart` | `AppInitializer` | `AppEnvironmentConfig.init()` | High | VERIFIED |
| FLOW-BOOT-003 | تهيئة Firebase / Firebase Initialization | `lib/core/services/app_initializer.dart` | `AppInitializer` | `Firebase.initializeApp()` | High | CONDITIONAL |
| FLOW-BOOT-004 | تهيئة الخدمات الأساسية / Core Services Init | `lib/core/services/app_initializer.dart` | `AppInitializer` | `_initCoreServices()` | High | VERIFIED |
| FLOW-BOOT-005 | خدمات المزامنة / Sync Services Init | `lib/core/services/app_initializer.dart` | `AppInitializer` | `_initSyncServices()` | High | VERIFIED |
| FLOW-BOOT-006 | تهيئة التوجيه / Router Init | `lib/app.dart` | `GoldenFeatherApp` | `routerProvider` | High | VERIFIED |
| FLOW-BOOT-007 | الشاشة الافتتاحية / Splash Screen | `lib/routes/auth_routes.dart` | `AuthRoutes` | `AppRoutes.splash` | High | VERIFIED |
| FLOW-BOOT-008 | التحقق من الإطلاق الأول والصلاحيات / First Launch Check | `lib/features/auth/presentation/pages/splash_page.dart` | `_SplashPageState` | `_checkFirstLaunch()` | High | VERIFIED |
| FLOW-PERM-001 | هل تم منح الصلاحيات؟ / Permissions Granted? | `lib/features/auth/presentation/pages/splash_page.dart` | `_SplashPageState` | `Permission.location.isGranted` | High | VERIFIED |
| FLOW-PERM-002 | صفحة الصلاحيات / Permissions Page | `lib/features/auth/presentation/pages/splash_page.dart` | `_SplashPageState` | `context.goNamed('permissions')` | High | VERIFIED |
| FLOW-AUTH-001 | التحقق من حالة المصادقة / Check Auth Status | `lib/features/auth/presentation/providers/auth_state_provider.dart` | `AuthNotifier` | `checkAuthStatus()` | High | VERIFIED |
| FLOW-AUTH-002 | هل المستخدم مسجل الدخول؟ / Is User Authenticated? | `lib/features/auth/presentation/pages/splash_page.dart` | `_SplashPageState` | `authStateProvider.isAuthenticated` | High | VERIFIED |
| FLOW-AUTH-003 | توجيه للاتصال أو الرئيسية / Route to Connection | `lib/features/auth/presentation/pages/splash_page.dart` | `_SplashPageState` | `context.goNamed('connection')` | High | VERIFIED |
| FLOW-AUTH-004 | صفحة تسجيل الدخول / Login Page | `lib/features/auth/presentation/pages/splash_page.dart` | `_SplashPageState` | `context.goNamed('login')` | High | VERIFIED |
| FLOW-AUTH-005 | إرسال بيانات الدخول / Submit Login | `lib/features/auth/presentation/widgets/login_form.dart` | `_LoginFormState` | `_handleLogin()` | High | VERIFIED |
| FLOW-AUTH-006 | تنفيذ الدخول / Execute Login | `lib/features/auth/presentation/providers/auth_state_provider.dart` | `AuthNotifier` | `login()` | High | VERIFIED |
| FLOW-AUTH-007 | استخدام تسجيل الدخول / Login UseCase | `lib/features/auth/domain/usercases/login.dart` | `Login` | `call()` | High | VERIFIED |
| FLOW-AUTH-008 | الاتصال بالـ API / API Call | `lib/features/auth/data/repositories/auth_repository_impl.dart` | `AuthRepositoryImpl` | `_remoteDataSource.login()` | High | BACKEND_DEPENDENCY |
| FLOW-AUTH-009 | حفظ التوكن / Save Token | `lib/features/auth/data/datasources/auth_local_data_source.dart` | `AuthLocalDataSourceImpl` | `saveToken()` | High | VERIFIED |
| FLOW-AUTH-010 | توجيه للرئيسية / Navigate to Home | `lib/features/auth/presentation/widgets/login_form.dart` | `_LoginFormState` | `context.goNamed('home')` | High | VERIFIED |
| FLOW-CONN-001 | الاتصال بالمركبة / Connect to Vehicle | `lib/features/connection/presentation/pages/eld_connection_page.dart` | `_EldConnectionPageState` | `_attemptConnection()` | High | MOCK |
| FLOW-TRK-001 | بدء التتبع (Flutter) / Start Tracking (Flutter) | `lib/features/tracking/data/services/tracking_service.dart` | `TrackingService` | `start()` | High | VERIFIED |
| FLOW-TRK-002 | تفعيل SDK التتبع / Invoke Traccar SDK | `lib/core/network/traccar_client_sdk.dart` | `TraccarRealClient` | `start()` | High | VERIFIED |
| FLOW-TRK-003 | بدء المتتبع الأصلي / Start Native Tracker | `android/app/.../plugins/TraccarPlugin.kt` | `TraccarPlugin` | `startTracking()` | High | VERIFIED |
| FLOW-BG-001 | بدء الخدمة الأمامية / Start Foreground Service | `android/app/.../services/TrackingForegroundService.kt` | `TrackingForegroundService` | `startForeground()` | High | VERIFIED |
| FLOW-BG-002 | طلب تحديثات الموقع / Request Location Updates | `android/app/.../services/TrackingForegroundService.kt` | `TrackingForegroundService` | `startLocationTracking()` | High | VERIFIED |
| FLOW-BG-003 | استلام تحديث الموقع / Receive Location Update | `android/app/.../services/TrackingForegroundService.kt` | `TrackingForegroundService` | `onLocationChanged()` | High | VERIFIED |
| FLOW-DB-001 | تخزين الموقع محلياً / Insert Location Local DB | `android/app/.../database/LocationDatabaseHelper.kt` | `LocationDatabaseHelper` | `insertLocation()` | High | VERIFIED |
| FLOW-SYNC-001 | تشغيل رفع البيانات / Trigger Upload | `android/app/.../database/NetworkUploader.kt` | `NetworkUploader` | `triggerUpload()` | High | VERIFIED |
| FLOW-SYNC-002 | رفع الموقع للـ API / Upload Single Location | `android/app/.../database/NetworkUploader.kt` | `NetworkUploader` | `uploadSingleLocation()` | High | VERIFIED (OsmAnd Protocol) |
| FLOW-HOS-001 | تغيير الحالة يدوياً / Manual Status Change | `lib/features/hos/presentation/providers/hos_provider.dart` | `HosNotifier` | `changeStatus()` | High | VERIFIED |
| FLOW-HOS-002 | التحقق من السرعة / Check Current Speed | `lib/features/hos/presentation/providers/hos_provider.dart` | `HosNotifier` | `changeStatus()` | High | VERIFIED |
| FLOW-HOS-003 | الانتقال لمحرك HOS / Engine Transition | `lib/core/engine/hos_rules_engine.dart` | `HosRulesEngine` | `manualTransition()` | High | VERIFIED |
| FLOW-HOS-004 | آلة الحالات / State Machine | `lib/core/engine/hos_state_machine.dart` | `HosStateMachine` | `transitionTo()` | High | VERIFIED |
| FLOW-HOS-005 | حساب الحدود والتنبيهات / Calculate Limits & Alerts | `lib/core/engine/hos_rules_engine.dart` | `HosRulesEngine` | `currentStatus (getter)` | High | VERIFIED |
| FLOW-HOS-006 | استلام حدث ELD معزول / Orphaned ELD Event | `lib/core/engine/hos_rules_engine.dart` | `HosRulesEngine` | `processEvent()` | High | ORPHAN |
| FLOW-AUTO-001 | استلام بيانات التتبع الحية / Live Tracking Event | `lib/core/engine/tracking/duty_status_tracker.dart` | `DutyStatusTracker` | `_processEldEvent()` | High | VERIFIED |
| FLOW-AUTO-002 | الانتقال الآلي / Auto Transition | `lib/core/engine/tracking/duty_status_tracker.dart` | `DutyStatusTracker` | `_transitionTo()` | High | VERIFIED |
| FLOW-AUTO-003 | حفظ الفترة المنتهية / Save Completed Period | `lib/features/logs/data/repositories/log_repository_impl.dart` | `LogRepositoryImpl` | `savePeriod()` | High | BACKEND_DEPENDENCY |
| FLOW-TRK-004 | إرسال الحدث لـ Flutter / Broadcast Event to Flutter | `android/app/.../plugins/TraccarPlugin.kt` | `TraccarPlugin` | `sendEventToFlutter()` | High | VERIFIED |
| FLOW-SYNC-003 | إرسال لـ SyncEngine / Submit Event | `lib/features/sync/domain/usecases/sync_engine.dart` | `SyncEngine` | `submitEvent()` | High | VERIFIED |
| FLOW-SYNC-004 | إضافة لطابور الأوفلاين / Enqueue Offline | `lib/features/sync/data/repositories/offline_queue_impl.dart` | `OfflineQueueImpl` | `enqueue()` | High | BACKEND_DEPENDENCY |
| FLOW-SYNC-005 | المزامنة المتكررة / Trigger Sync Loop | `lib/features/sync/domain/usecases/sync_engine.dart` | `SyncEngine` | `triggerSync()` | High | VERIFIED |
