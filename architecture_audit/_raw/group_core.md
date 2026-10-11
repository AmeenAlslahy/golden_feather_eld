# Group: core+app+routes — Layer/Responsibility Audit

**نطاق التدقيق:** 70 ملفاً في `lib/core/**` (مستثنى `theme/` و`widgets/`)، `lib/app/**`، `lib/routes/**`، و`lib/main.dart`، `lib/app.dart`, `lib/routes.dart`.
**الأساس:** قراءة كاملة لكل ملف (4,812 سطراً غير فارغ). لم يُعدَّل أي ملف.

---

## A. Per-file findings

### `lib/main.dart` (64 lines, non-empty 54)
- Actual responsibilities: تهيئة `WidgetsBinding`، قفل الاتجاه، تلوين شريط الحالة، تركيب `FlutterError.onError`، تشغيل `AppInitializer`، بناء `ProviderContainer`، `runApp`، وشاشة خطأ حرج عند الفشل.
- Declared layer / actual layer: Entry point → Entry point. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/app.dart` (114 lines, non-empty 103)
- Actual responsibilities: جذر `MaterialApp.router`، الاستماع لـ`authStateProvider` لإبطال مزودات HOS، الاستماع لـ`hosStatusProvider` لإظهار `AppFeedback` بنص عربي ثابت، تهيئة `ScreenUtilInit` والثيم واللغة والتوجيه.
- Declared layer / actual layer: App root → App root +Presentation side-effects +Business messaging.
- Architectural status: MODERATE
- Issue IDs: CORE-026, CORE-001 (transitively)

### `lib/routes.dart` (100 lines, non-empty 86)
- Actual responsibilities: ثوابت المسارات، مجموعة `publicRoutes`، `RouterNotifier` (جسر Riverpod→GoRouter)، ومزوّد `routerProvider` مع منطق `redirect` للمصادقة.
- Declared layer / actual layer: Routing/Presentation → Routing/Presentation. مطابق.
- Architectural status: MINOR
- Issue IDs: CORE-028

### `lib/app/app_initializer.dart` (119 lines, non-empty 101)
- Actual responsibilities: تهيئة البيئة، Firebase، Hive، بناء `TrackingService` يدوياً، `PushNotificationService`، `UtcSyncService`، إنشاء `ProviderContainer` بـ4 `overrides`، ومهام ما بعد الإقلاع.
- Declared layer / actual layer: Composition root → Composition root + Ad-hoc object construction من داخل features.
- Architectural status: MODERATE
- Issue IDs: CORE-005, CORE-023, CORE-024, CORE-033

### `lib/app/orchestrators/tracking_orchestrator.dart` (110 lines, non-empty 96)
- Actual responsibilities: 4 `ref.listen` على `trackingStateProvider`/`authStateProvider`/`vehicleProvider`/`hosStatusProvider`، حسابات عتبة الإرسال (throttling) للـtelemetry، بناء `TelemetryReading`، استدعاء `hardwareBackendProvider.sendTelemetry`، وربط `isDrivingChecker`.
- Declared layer / actual layer: Orchestration → Orchestration + HTTP-trigger policy + business rules.
- Architectural status: MODERATE
- Issue IDs: CORE-025

### `lib/app/services/push_notification_service.dart` (156 lines, non-empty 137)
- Actual responsibilities: استقبال FCM، معالجة الأوامر (تتبع/إيقاف/position)، التنقل عبر `rootNavigatorKey`، إظهار إشعار داخلي، ورفع توكن الإشعار للخادم.
- Declared layer / actual layer: App services → App services + **Direct `HttpClient` bypass for the network layer** + Presentation navigation.
- Architectural status: MAJOR
- Issue IDs: CORE-016, CORE-024

### `lib/app/services/quick_actions_initializer.dart` (77 lines, non-empty 68)
- Actual responsibilities: تسجيل `ShortcutItem` للنظام، ومعالجة `start/stop/sos` عبر `trackingServiceProvider`، ثم `SystemNavigator.pop()`.
- Declared layer / actual layer: Widget initializer → Widget + Direct service invocation (بدون طبقة use-case).
- Architectural status: MINOR
- Issue IDs: CORE-024

### `lib/routes/account_routes.dart` (46 lines, non-empty 44)
- Actual responsibilities: ربط 6 مسارات (`account`, `rules`, `info-packet`, `userManual`, `about`, `settings`) بصفحات `features/**`.
- Declared layer / actual layer: Routing → Routing. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/routes/auth_routes.dart` (39 lines, non-empty 37)
- Actual responsibilities: ربط 5 مسارات (`splash`, `onboarding`, `permissions`, `login`, `connection`).
- Declared layer / actual layer: Routing → Routing. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/routes/dvir_routes.dart` (33 lines, non-empty 31)
- Actual responsibilities: ربط 4 مسارات DVIR/Inspection بصفحات `features/**`.
- Declared layer / actual layer: Routing → Routing. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/routes/home_routes.dart` (38 lines, non-empty 36)
- Actual responsibilities: ربط 5 مسارات؛ `/status` و`/hos` يبنيان **نفس** `StatusDashboardPage`.
- Declared layer / actual layer: Routing → Routing مع ازدواج مسار.
- Architectural status: MINOR
- Issue IDs: CORE-030

### `lib/routes/logs_routes.dart` (43 lines, non-empty 41)
- Actual responsibilities: ربط 5 مسارات سجلات؛ `editLog` يمرر كياناً عبر `state.extra` مع cast غير محمي.
- Declared layer / actual layer: Routing → Routing + unsafe cast.
- Architectural status: MINOR
- Issue IDs: CORE-027

### `lib/core/network/api_client.dart` (345 lines, non-empty 318)
- Actual responsibilities: غلاف رقيق حول Dio: `get/post/put/delete/uploadFile/download`، تطبيع الاستجابة، `mapDioException`، إعادة محاولة GET العابر فقط مع exponential backoff، ومعالجة `OwnerMismatchSignal`.
- Declared layer / actual layer: Network → Network. تصميم نظيف ومعلَن بوضوح.
- Architectural status: MINOR
- Issue IDs: CORE-032

### `lib/core/network/api_config.dart` (109 lines, non-empty 93)
- Actual responsibilities: كائن قيمة خالص للـ base URL والمهلات والترويسات، مع `normalized()` و`fromEnvironment()`.
- Declared layer / actual layer: Network config → Network config. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/network/api_response.dart` (157 lines, non-empty 138)
- Actual responsibilities: تطبيع ثلاثة صيغ استجابة (مغلف قديم/جديد/مباشر) إلى تمثيل واحد، مع كشف `status`/`success` داخل `data`.
- Declared layer / actual layer: Network → Network. مطابق.
- Architectural status: MINOR
- Issue IDs: CORE-029

### `lib/core/network/error_mapper.dart` (228 lines, non-empty 204)
- Actual responsibilities: نقطة الترجمة الوحيدة `DioException → AppError`، مع كاشف «تراكمات الخادم» في `_extractServerMessage`.
- Declared layer / actual layer: Network → Network. مطابق.
- Architectural status: MINOR
- Issue IDs: CORE-012

### `lib/core/network/lenient_json_transformer.dart` (34 lines, non-empty 30)
- Actual responsibilities: تحويل استجابات JSON متساهلة (جسم فارغ → `{}`، نص غير JSON → نص).
- Declared layer / actual layer: Network → Network. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/network/network_guard.dart` (29 lines, non-empty 27)
- Actual responsibilities: توحيد حارس الاتصال (`guardedNetwork`) مع مسار offline اختياري؛ يوحّد نمطاً كان مكرراً في ستة مستودعات.
- Declared layer / actual layer: Network → Network. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/network/network_info.dart` (57 lines, non-empty 49)
- Actual responsibilities: `NetworkInfo` port + تنفيذ عبر `connectivity_plus` مع قيمة متفائلة أولية و`dispose` صحيح.
- Declared layer / actual layer: Network → Network. مطابق، والتعليق يوثّق قراراً تصميمياً.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/network/core_providers.dart` (66 lines, non-empty 56)
- Actual responsibilities: مزوّدات `BluetoothService`، `NetworkInfo`، `ApiConfig`، `serverUrlProvider`، `backendTypeProvider`؛ **وإعادة تصدير** `apiClientProvider` من `backend/`؛ و**تعريف ثانٍ** لـ`secureStorageProvider` من نوع `FlutterSecureStorage` ميت.
- Declared layer / actual layer: Network DI → Network DI + **Barrel file يعبر حدود الطبقات**.
- Architectural status: MODERATE
- Issue IDs: CORE-019, CORE-004, CORE-014

### `lib/core/error/app_error.dart` (565 lines, non-empty 504)
- Actual responsibilities: تعداد `ErrorSeverity`، صنف مغلق `AppError` بـ7 حقول، و**14 فئة فرعية**: `NetworkError`, `AuthError`, `SessionExpiredError`, `ValidationError`, `PermissionError`, `NotFoundError`, `ConflictError`, `UnsupportedCapabilityError`, `ServerError`, `TimeUnavailableError`, `StorageError`, `SyncError`, `OwnerMismatchError`, `UnknownError`. كل subclass يكرّر نفس هيكل `_copyWith`.
- Declared layer / actual layer: Error → Error. **ليس dumping ground** — كل فئةiko متجانسة ومقصودة؛ التكرار آلي (`_copyWith`) ويمثّل 60% من حجم الملف.
- Architectural status: MINOR
- Issue IDs: CORE-009, CORE-010

### `lib/core/error/exception.dart` (77 lines, non-empty 57)
- Actual responsibilities: 7 استثناءات (`ServerException`, `OfflineException`, `UnauthorizedException`, `CacheException`, `SyncException`, `TrackingException`, `PermissionException`)، كلها `message` + `toString()`.
- Declared layer / actual layer: Error → Error. **شبه ميت**: موقع `throw` واحد فقط في كامل `lib/`.
- Architectural status: MODERATE
- Issue IDs: CORE-011

### `lib/core/error/failure.dart` (136 lines, non-empty 113)
- Actual responsibilities: 14 `Failure` مبنية على Equatable تُستخدم مع `Either<Failure, T>`، بالإضافة إلى `QuarantinedFailure` و`OwnerMismatchSignal`.
- Declared layer / actual layer: Error → Error. **نظام خطأ موازٍ** لـ`AppError`.
- Architectural status: MODERATE
- Issue IDs: CORE-010, CORE-011

### `lib/core/error/user_facing_message.dart` (99 lines, non-empty 92)
- Actual responsibilities: بوابة رسائل آمنة للسائق: كشف PII، URLs، تراكمات الخادم، حد 140 حرفاً؛ ثم `switch` على `AppError` لاختيار نص.
- Declared layer / actual layer: Error/Presentation → Error/Presentation. تصميم جيد أمنياً.
- Architectural status: MINOR
- Issue IDs: CORE-012, CORE-013

### `lib/core/result/result.dart` (104 lines, non-empty 86)
- Actual responsibilities: `typedef Result<T> = fp.Either<AppError, T>` مع `ok/err` وامتداد `ResultX`.
- Declared layer / actual layer: Result → Result. **مستخدم فعلياً** لكن مع تسرّب إلى نظام `Failure` الموازي.
- Architectural status: MINOR
- Issue IDs: CORE-010

### `lib/core/config/app_environment.dart` (106 lines, non-empty 90)
- Actual responsibilities: تهيئة `.env`/`dart-define`، اختيار `AppEnvironment`، وإتاحة `API_BASE_URL`, `TRACCAR_USERNAME`, `TRACCAR_PASSWORD`, `TRACCAR_DEVICE_ID`, `TRACCAR_DEVICE_UNIQUE_ID`، ونوع الـ backend.
- Declared layer / actual layer: Config → Config + **قراءة أسرار من ملف متتبَّع بـgit**.
- Architectural status: MODERATE
- Issue IDs: CORE-015

### `lib/core/config/hos_configuration.dart` (99 lines, non-empty 93)
- Actual responsibilities: كائن قيمة لحدود HOS مع مصانع `usa70_8()`/`usa60_7()`، `copyWith`, `toJson`, `fromJson`.
- Declared layer / actual layer: Config/domain → Config. **يكرّر أرقام 49 CFR الموجودة في `fmcsa_constants.dart`**.
- Architectural status: MINOR
- Issue IDs: CORE-022

### `lib/core/config/runtime_selection.dart` (61 lines, non-empty 53)
- Actual responsibilities: دوال نقية `resolveRuntimeBackend` و`resolveBackendType` (mock-vs-live، وترتيب أولوية المضيف).
- Declared layer / actual layer: Config → Config. مطابق ووظيفاً نقي.
- Architectural status: MINOR
- Issue IDs: CORE-014

### `lib/core/config/server_config_provider.dart` (8 lines, non-empty 7)
- Actual responsibilities: واجهة `ServerConfigProvider` بمُ.Getter لـ`serverUrl` و`backendType`.
- Declared layer / actual layer: Config → Config. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/config/server_config_store.dart` (79 lines, non-empty 67)
- Actual responsibilities: `StateNotifier` يقرأ/يكتب `ServerConfig` في `SecureStoragePort` تحت المفتاح `server_config_v1`.
- Declared layer / actual layer: Config/persistence → Config/persistence. **يستورد `domain/config/server_config.dart` مع علامة `ignore_architecture`**.
- Architectural status: MODERATE
- Issue IDs: CORE-004

### `lib/core/di/app_providers.dart` (33 lines, non-empty 25)
- Actual responsibilities: «Composition Root» — يركّب مستودع واحد فقط (`traccarAuthRepositoryProvider`) ويستورد `auth_repository_impl.dart` و`backend/providers/backend_providers.dart`.
- Declared layer / actual layer: DI → DI + **استيراد مباشر من `features/**/data`** (وادي `core`).
- Architectural status: MAJOR
- Issue IDs: CORE-003, CORE-031, CORE-004

### `lib/core/di/auth_local_data_source_provider.dart` (11 lines, non-empty 9)
- Actual responsibilities: مزوّد واحد يعيد `AuthLocalDataSourceImpl()` مباشرة بلا `ignore_architecture` على الاستدعاء نفسه.
- Declared layer / actual layer: DI → DI + **اعتماد على `features/auth/data`**.
- Architectural status: MAJOR
- Issue IDs: CORE-003, CORE-004

### `lib/core/di/id_generator_provider.dart` (6 lines, non-empty 5)
- Actual responsibilities: مزوّد `IdGenerator` يفوّض إلى `UuidIdGenerator`.
- Declared layer / actual layer: DI → DI. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/providers/driver_rules_provider.dart` (24 lines, non-empty 21)
- Actual responsibilities: تعريف كيان نطاقي `DriverRules` ومزوّد يحوّل `rulesScreenProvider` (presentation في features) إلى `DriverRules`.
- Declared layer / actual layer: **Core** → **Core depends on features/presentation**.
- Architectural status: MAJOR
- Issue IDs: CORE-001

### `lib/core/session/session_epoch.dart` (31 lines, non-empty 28)
- Actual responsibilities: عدّاد جيل أحادي ثابت `SessionEpoch.current/bump/resetForTests` لفصل الجلسات بين الحسابات.
- Declared layer / actual layer: Session → Session. **حالة عامة ثابتة** (global mutable) لكنها مقصودة وموثّقة ومقصودة للاعتراض غير المتزامن.
- Architectural status: MINOR
- Issue IDs: CORE-006 (مرتبط)

### `lib/core/storage/storage_providers.dart` (12 lines, non-empty 10)
- Actual responsibilities: providing `SecureStoragePort` عبر `FlutterSecureStorageAdapter`.
- Declared layer / actual layer: Storage DI → Storage DI. مطابق.
- Architectural status: MINOR
- Issue IDs: CORE-019

### `lib/core/storage/adapters/flutter_secure_storage_adapter.dart` (29 lines, non-empty 21)
- Actual responsibilities: تفويض 5 عمليات إلى `flutter_secure_storage`.
- Declared layer / actual layer: Storage adapter → Storage adapter. مطابق (Hexagonal).
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/storage/ports/secure_storage_port.dart` (17 lines, non-empty 13)
- Actual responsibilities: منفذ `SecureStoragePort` بـ5 عمليات، مع قاعدة صريحة: لا أسرار في preferences العادية.
- Declared layer / actual layer: Storage port → Storage port. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/services/bluetooth_service.dart` (97 lines, non-empty 83)
- Actual responsibilities: `MethodChannel` + `EventChannel` لجهاز ELD: `startScan`, `stopScan`, `connect`, `disconnect`, `isConnected`, بث الأحداث، `dispose`.
- Declared layer / actual layer: Platform service → Platform service. مطابق.
- Architectural status: MINOR
- Issue IDs: CORE-041

### `lib/core/services/local_database_service.dart` (31 lines, non-empty 26)
- Actual responsibilities: فتح 4 صناديق Hive فقط؛ ومزوّد يرمي `UnimplementedError` كـguard.
- Declared layer / actual layer: Persistence bootstrap → Persistence bootstrap. **صنف شبه فارغ + provider يرمي عمداً**.
- Architectural status: MINOR
- Issue IDs: CORE-033

### `lib/core/services/local_storage_service.dart` (225 lines, non-empty 190)
- Actual responsibilities: واجهة (Facade) لـ`SharedPreferencesWithCache`: إنشاء المثيل، القيم الافتراضية، 20+ getter وsetter مُفوَّضة، تخزين `HosConfiguration` بـJSON، تهيئة معرّف جهاز عشوائي، و`clearAll`.
- Declared layer / actual layer: Core services → Core services + **state ثابت (`static _initFuture`/`_prefs`)** + **استيراد دائري**.
- Architectural status: MODERATE
- Issue IDs: CORE-018, CORE-014, CORE-033, CORE-020

### `lib/core/services/tracking_config_storage_service.dart` (107 lines, non-empty 98)
- Actual responsibilities: 12 مفتاح تهيئة تتبع + getter/setter + `applyFromUri`؛ ومزوّد يعتمد على `localStorageProvider` للوصول إلى `prefs`.
- Declared layer / actual layer: Core services → Core services + **استيراد دائري مع facade + تكرار مزوّد**.
- Architectural status: MODERATE
- Issue IDs: CORE-018, CORE-020, CORE-033

### `lib/core/services/user_preferences_storage_service.dart` (40 lines, non-empty 32)
- Actual responsibilities: 6 مفاتيح تفضيلات (لغة، ثيم، مركبة، حالة، توقّف، seen).
- Declared layer / actual layer: Core services → Core services. مطابق.
- Architectural status: MINOR
- Issue IDs: CORE-020

### `lib/core/services/utc_sync_service.dart` (50 lines, non-empty 44)
- Actual responsibilities: حساب انحراف زمني من `serverTime`، والتعرض لـ`syncedTime`/`utcNow`.
- Declared layer / actual layer: Core services → Core services. **بنية ميتة**: `syncWithUtc()` يُستدعى دائماً بلا `serverTime` ⇒ `_drift` يبقى `null` أب��اً، ولا يوجد أي مستهلك لـ`utcNow` في `lib/` خارج الملف نفسه.
- Architectural status: MODERATE
- Issue IDs: CORE-023

### `lib/core/time/monotonic_time_authority.dart` (56 lines, non-empty 50)
- Actual responsibilities: تنفيذ `TimeAuthority` مثبّت على ساعة الجهاز عند أول استخدام + `Stopwatch` للأ.monotonic elapsed.
- Declared layer / actual layer: Time → Time. **مصرَّح بأنه للتطوير فقط**.
- Architectural status: MODERATE
- Issue IDs: CORE-006, CORE-008

### `lib/core/time/time_authority.dart` (70 lines, non-empty 61)
- Actual responsibilities: `TrustLevel` (4 مستويات) وواجهة `TimeAuthority` بـ4 أعضاء.
- Declared layer / actual layer: Time abstraction → Time abstraction. **`trustLevel` لا يقرأه أي مستهلك خارج ملف التعريف**.
- Architectural status: MODERATE
- Issue IDs: CORE-006, CORE-008

### `lib/core/time/time_authority_provider.dart` (31 lines, non-empty 29)
- Actual responsibilities: المزوّد الافتراضي `timeAuthorityProvider` = `MonotonicTimeAuthority` + `initialize()` غير متزامن بلا انتظار.
- Declared layer / actual layer: Time DI → Time DI. **هذا هو المزوّد الذي تستخدمه features/logs وfeatures/sync لوسم أحداث الطابور القانوني**.
- Architectural status: MAJOR
- Issue IDs: CORE-006, CORE-008

### `lib/core/time/time_formatter.dart` (45 lines, non-empty 41)
- Actual responsibilities: 4 دوال تنسيق وقت ثابت (12h، مع منطقة، مع ثوانٍ، `TimeOfDay`).
- Declared layer / actual layer: Core utils → Core utils. `formatTime12Hour` و`formatTimeOfDay12Hour` متطابقتان منطقياً.
- Architectural status: MINOR
- Issue IDs: CORE-042

### `lib/core/time/trusted_time_provider.dart` (230 lines, non-empty 197)
- Actual responsibilities: عائلة ثانية بالكامل للزمن الموثوق: `TrustedTimeState`, `TrustedTimeResult` (مغلق), `TrustedTimeProvider`, تنفيذ `MonotonicTrustedTimeProvider` مع استعادة من القرص، و`FakeTrustedTimeProvider` للاختبار، ومزوّد يربط التخزين.
- Declared layer / actual layer: Time → Time. **نظام موازٍ لـ`TimeAuthority`**، ويحفظ المرساة في `SharedPreferences` عادي.
- Architectural status: MAJOR
- Issue IDs: CORE-008, CORE-007, CORE-035

### `lib/core/utils/app_date_utils.dart` (16 lines, non-empty 15)
- Actual responsibilities: تنسيق `YYYY-MM-DD` واستخراج التاريخ من ISO مع fallback إلى `DateTime.now()`.
- Declared layer / actual layer: Core utils → Core utils. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/utils/duration_format.dart` (21 lines, non-empty 20)
- Actual responsibilities: `hhMm` و`decimalHours` — توحيد منسق مكرر سابقاً.
- Declared layer / actual layer: Core utils → Core utils. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/utils/id_generator.dart` (12 lines, non-empty 9)
- Actual responsibilities: منفذ `IdGenerator` + تنفيذ UUID v4.
- Declared layer / actual layer: Core utils → Core utils. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/utils/localization_helper.dart` (52 lines, non-empty 50)
- Actual responsibilities: `switch` من 12 حالة على `BuildContext` يترجم مفاتيح `l10n`، مع fallback يمرّر النص إلى `anyErrorUserMessage`.
- Declared layer / actual layer: Core utils → Core utils + **آلية توصيل رسائل موازية لـ`user_facing_message.dart`**.
- Architectural status: MODERATE
- Issue IDs: CORE-013

### `lib/core/utils/logger.dart` (37 lines, non-empty 31)
- Actual responsibilities: غلاف `AppLogger` بـ5 مستويات فوق `package:logger`، مع `methodCount: 0` لأداء الجهاز.
- Declared layer / actual layer: Cross-cutting → Cross-cutting. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/utils/provider_cache.dart` (18 lines, non-empty 16)
- Actual responsibilities: `cacheFor(ref, duration)` لإبقاء آخر قيمة لـ`autoDispose` حية مؤقتاً مع إدارة `Timer`.
- Declared layer / actual layer: Riverpod util → Riverpod util. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/utils/repository_helper.dart` (61 lines, non-empty 58)
- Actual responsibilities: `executeWithHandling<T>` يلتقط 7 استثناءات ويعيدها `Failure`؛ **و`_defaultNetworkInfo` نسخة عامة على مستوى الوحدة**.
- Declared layer / actual layer: Core utils → Core utils + **تسريب مورد على مستوى الوحدة + نظام خطأ موازٍ**.
- Architectural status: MAJOR
- Issue IDs: CORE-017, CORE-011

### `lib/core/utils/status_color_helper.dart` (8 lines, non-empty 7)
- Actual responsibilities: جسر واحد من رمز الحالة إلى اللون عبر `DutyStatusCode.fromAny(...).displayColor`.
- Declared layer / actual layer: Core utils → Core utils. مطابق (ألواحو، لا تفرّع وضع).
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/events/app_events.dart` (18 lines, non-empty 15)
- Actual responsibilities: تعداد `AppEvent` (قيمة واحدة: `logDataChanged`)، ناقل أحداث `StreamController.broadcast`، ومزوّد مع `onDispose`.
- Declared layer / actual layer: Core events → Core events. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/events/eld_events_provider.dart` (18 lines, non-empty 15)
- Actual responsibilities: كشف `liveTrackingDataSourceProvider.events` و`.connectionStatus` كمزوّدَي `StreamProvider` «على مستوى النطاق».
- Declared layer / actual layer: **Core** → **Core depends on `features/tracking/data` و`features/tracking/domain`**.
- Architectural status: MAJOR
- Issue IDs: CORE-002

### `lib/core/extensions/context_extensions.dart` (112 lines, non-empty 94)
- Actual responsibilities: امتداد `BuildContext` (ثيم، نصوص، ترجمة حالات السائق وDVIR، الوضع، اللغة) + امتداد `AppSemanticColors` لـ7 ألوان دلالية.
- Declared layer / actual layer: Presentation extension داخل core → Presentation. **يستورد `core/theme/`** (خارج نطاق القراءة لكن مثبت بالاستيراد).
- Architectural status: MINOR
- Issue IDs: CORE-026

### `lib/core/localization/locale_provider.dart` (41 lines, non-empty 34)
- Actual responsibilities: `LocaleNotifier` يقرأ/يكتب اللغة، مع ترحيل لمفتاح قديم `language_code` من `SharedPreferences.getInstance()` القديم.
- Declared layer / actual layer: Localization → Localization. مطابق، لكن الوصول المباشر لـ`SharedPreferences.getInstance()` يتجاوز `LocalStorageService`.
- Architectural status: MINOR
- Issue IDs: CORE-020

### `lib/core/design_system.dart` (19 lines, non-empty 17)
- Actual responsibilities: ملف barrel بحت يعيد تصدير 11 ملفاً من `core/theme/` + امتداد + widget.
- Declared layer / actual layer: Barrel → Barrel. مطابق بطبيعته.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/constants/app_constants.dart` (53 lines, non-empty 45)
- Actual responsibilities: ثوابت تسمية وإعدادات افتراضية ومفاتيح تخزين (`tokenKey`, `refreshTokenKey`, ...) + تعدادا `SyncStatus` و`InspectionStatus`.
- Declared layer / actual layer: Constants → Constants. **7 مفاتيح تخزين ميتة**، منها مفاتيح توكن توحي بتخزين غير آمن.
- Architectural status: MINOR
- Issue IDs: CORE-021, CORE-020

### `lib/core/constants/channel_constants.dart` (5 lines, non-empty 5)
- Actual responsibilities: ثلاثة أسماء منصات (bluetooth/traccar/tracking).
- Declared layer / actual layer: Constants → Constants. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

### `lib/core/constants/fmcsa_constants.dart` (41 lines, non-empty 30)
- Actual responsibilities: 14 ثابتاً تنظيمياً من 49 CFR Part 395 (عتبة 5mph، نافذة 11/14، دورة 60/70، بريد FMCSA…).
- Declared layer / actual layer: Constants → Constants. **مصدر الحقيقة التنظيمي**، لكن `HosConfiguration` تعيد تعريف أرقامه.
- Architectural status: MINOR
- Issue IDs: CORE-022

### `lib/core/constants/storage_constants.dart` (15 lines, non-empty 13)
- Actual responsibilities: 3 مفاتيح preferences + 4 أسماء صناديق Hive.
- Declared layer / actual layer: Constants → Constants. **3 مفاتيح preferences مكررة/ميتة**.
- Architectural status: MINOR
- Issue IDs: CORE-020

### `lib/core/data/models/user_model.dart` (99 lines, non-empty 91)
- Actual responsibilities: وراثة `User` مع `fromEntity`, `fromJson`, `fromMetadata`, `toJson`. **`fromJson` يعرف صيغة TraccarWire** (`administrator`, `disabled`, `name`).
- Declared layer / actual layer: **Core data model** → **Feature (Traccar) knowledge inside core**.
- Architectural status: MODERATE
- Issue IDs: CORE-033

### `lib/core/domain/entities/hos_models.dart` (316 lines, non-empty 278)
- Actual responsibilities: 9 أنواع/فئات: `DutyStatus` (+`toShortCode`/`fromShortCode`), `EldEvent`, `DutyStatusEvent`, `DutyPeriod`, `DutyTransition`, `HosAlertType`, `AlertSeverity`, `HosAlert`, `HosStatusUpdate`, `HosViolationType`, `ViolationLevel`, `HosViolation`, `HosLimits`.
- Declared layer / actual layer: Domain entities → Domain entities (مع `fromMap` = معرفة storage داخل كيان). **`DutyPeriod.distanceKm` يُعيد `null` دائماً.**
- Architectural status: MINOR
- Issue IDs: CORE-034, CORE-010

### `lib/core/domain/entities/location_point.dart` (12 lines, non-empty 11)
- Actual responsibilities: كيان إحداثيات ثلاثي الحقول بلا `Equatable` ولا `toJson`.
- Declared layer / actual layer: Domain entity → Domain entity. **بلا Serena، ومنافس لـ`location_point` الخاص بـfeatures** (تحقّق).
- Architectural status: MINOR
- Issue IDs: CORE-033

### `lib/core/domain/entities/user.dart` (77 lines, non-empty 64)
- Actual responsibilities: كيان `User` بـ10 حقول + 3 getters أدوار + تعداد `UserRole` مع `fromCode`.
- Declared layer / actual layer: Domain entity → Domain entity. مطابق.
- Architectural status: COMPLIANT
- Issue IDs: none

---

## B. Detailed issues

--------------------------------------------------
### ISSUE CORE-001: `core` يستورد من `features/**/presentation`
- Severity: HIGH
- Category: Coupling
- Location: `lib/core/providers/driver_rules_provider.dart:2` (والمزوّد في السطر 17-18)
- Evidence:
```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/account/presentation/providers/rules_screen_provider.dart';
```
```dart
final driverRulesProvider = Provider.autoDispose<AsyncValue<DriverRules>>((ref) {
  return ref.watch(rulesScreenProvider).whenData((model) {
```
- Current behavior: مزوّد في قلب `core/` يشاهد مزوّداً من طبقة **presentation** داخل `features/account`، ثم يترجم نموذج الشاشة (`model`) إلى كيان نطاقي `DriverRules`.
- Why problematic: `(1)` اتجاه الاعتماد معكوس: صنف داخل `core` لا يمكن اختباره أو إعادة استخدامه دونFeatures كاملة. `(2) `core` يُقصد أن يكون innermost — استيراده من `presentation` يجعل دورة الاعتماد مغلقة (features → core → features). `(3) لا توجد أي علامة `ignore_architecture` على هذا السطر، ما يعني أن الانتهاك غير مُعلَن حتى.
- Violated principle: Dependency Rule (Clean Architecture) — العينات الداخلية (Innermost) لا تعرف الأنماط الخارجية؛ قاعدة «الاعتماد يشير إلى الداخل».
- Current owner: `lib/core/providers/driver_rules_provider.dart`
- Correct owner: الواجهة/المستودع داخل `features/account/domain` (أو عقد داخل `core/domain`) — على أن يكون `features/account` هو المستهلك الوحيد لـ`DriverRules`، ويُعاد استخدامه من هناك.
- Consequences: أي استخراج لـ`features/account` من التطبيق يسقط `core/providers/` كاملاً. كما أن `autoDispose` هنا مربوط بعمر صفحة `RulesPage`، فدورة حياة `driverRulesProvider` داخل `core` تصبح مشروطة بعمر واجهة مستخدمية.
- Recommended correction: (أ) انقل `DriverRules` + `driverRulesProvider` إلى `features/account/domain/` واعتمد على مستودع قواعد؛ (ب) إن أصرّ بقاؤه في `core` فليكن يقرأ من `core/network/api_client` أو من contract في `backend/contracts/rules_screen_backend.dart` لا من presentation.
- Related files: `lib/features/account/presentation/providers/rules_screen_provider.dart`, `lib/backend/contracts/rules_screen_backend.dart`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-002: `core/events` يستورد مصدر بيانات تنقّل من `features/tracking`
- Severity: HIGH
- Category: Coupling
- Location: `lib/core/events/eld_events_provider.dart:3,5,12,17`
- Evidence:
```dart
import '../../features/tracking/data/datasources/live_tracking_data_source.dart';
import '../domain/entities/hos_models.dart';
import '../../features/tracking/domain/entities/connection_status.dart';
```
```dart
final eldEventsStreamProvider = StreamProvider<EldEvent>((ref) {
  return ref.watch(liveTrackingDataSourceProvider).events;
});
```
- Current behavior: `core` يعرّف «واجهة نطاقية»ama على مستوى النطاق하지만 ينفّذها بجلب `data source` تنفيذي من داخل `features/tracking`.
- Why problematic: ادعاء التوثيق نفسه مخالف للواقع:
```dart
/// This decouples the HOS/Sync/Logs domains from directly importing
/// the tracking data source.
```
  الملف يدّعي أنه يفصل الميزات، بينما هو نفسه استيراد تنفيذي. النتيجة انتقال التبعية: `features/hos` → `core/events` → `features/tracking/data`. عند استبدال مصدر التتبع أو fake-test يُكتب، لا يوجد مسار حقن — الاختبار يجب أن يحقن `liveTrackingDataSourceProvider`Concrete كامل.
- Violated principle: Dependency Inversion + Ports & Adapters.
- Current owner: `lib/core/events/eld_events_provider.dart`
- Correct owner: منفذ `EldEventStream` port داخل `core/domain` أو `domain/shared`، مع التنفيذ في `features/tracking/data` أو `backend/adapters`.
- Consequences: لا يمكن اختبار HOS/Sync دون features tracking كاملة؛ واستبدال Traccar بواجهة ELD أخرى يمسّ `core`.
- Recommended correction: عرّف `abstract interface class LiveEldEventSource { Stream<EldEvent> get events; }` في `core/domain`، واجعل `liveTrackingDataSourceProvider` (أو محوّلاً) ينفّذها، ثم اجعل `eldEventsStreamProvider` يعتمد على `Provider<LiveEldEventSource>`.
- Related files: `lib/features/tracking/data/datasources/live_tracking_data_source.dart`, `lib/core/domain/entities/hos_models.dart`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-003: جذر تركيب داخل `core/di` يستورد تنفيذ `features` مباشرة
- Severity: HIGH
- Category: Architecture
- Location: `lib/core/di/app_providers.dart:3,7,10,26-33`; `lib/core/di/auth_local_data_source_provider.dart:3,9-11`
- Evidence:
```dart
import 'package:golden_feather_eld/backend/providers/backend_providers.dart'; // ignore_architecture
import '../../core/network/core_providers.dart';
import '../../core/services/local_storage_service.dart';

import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart'; // ignore_architecture

// Import data implementations (ONLY ALLOWED IN THIS FILE)
import 'package:golden_feather_eld/features/auth/data/repositories/auth_repository_impl.dart'; // ignore_architecture
```
```dart
final traccarAuthRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(
```
- Current behavior: `core/di/app_providers.dart` يعلن نفسه «Composition Root» ويسمح باستيراد تنفيذات `data`، ويصل إلى `backend/` وإلى `features/auth/data`.
- Why problematic: `(1)` جذر التركيب موقعه الصحيح هو أعلى الشجرة أو نطاق مستقل (`lib/di/`)، لا داخل innermost. `(2)` الملف يحمل تعليمة ذاتية «ONLY ALLOWED IN THIS FILE» بلا أي آلية تفرضها. `(3)` `auth_local_data_source_provider.dart` ينشئ `AuthLocalDataSourceImpl()` مباشرة — تجاوز حتى نمط `ref.watch`.
- Violated principle: Composition Root placement؛ قاعدة «التنفيذيات في الأطراف فقط».
- Current owner: `lib/core/di/app_providers.dart` + `lib/core/di/auth_local_data_source_provider.dart`
- Correct owner: `lib/di/composition_root.dart` (خارج `core`)، مع إبقاء `core` خالياً من أي `features/**/data`.
- Consequences: استخراج مكتبة reusable من `core` مستحيل؛ كل feature جديدة تحتاج تعديل `core`؛ و`core/di` لا يمكن اختباره دون features.
- Recommended correction: انقل الجذر إلى `lib/di/`. داخل `core/di` اترك فقط abstractions (protocols) — لا implementations.
- Related files: `lib/backend/providers/backend_providers.dart`, `lib/features/auth/data/repositories/auth_repository_impl.dart`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-004: قواعد الطبقات غير مفروضة؛ علامات `// ignore_architecture` زخرفية
- Severity: HIGH
- Category: Architecture
- Location: `analysis_options.yaml` (مق entirety) + 19 استيراد موسوم عبر 13 ملفاً
- Evidence (من `analysis_options.yaml`):
```yaml
analyzer:
  exclude:
    - scratch/**
    - build/**
    - android/**
    - ios/**
    - web/**
    - windows/**
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    # avoid_print: false  # Uncomment to disable the `avoid_print` rule
    # prefer_single_quotes: true  # Uncomment to enable the `prefer_single_quotes` rule
```
- Current behavior: المشروع يحمل 19 تعليق `// ignore_architecture` موزّعة على 13 ملفاً، منها `lib/core/di/app_providers.dart` (3)، `lib/backend/providers/backend_network_providers.dart` (3)، `lib/core/network/api_client.dart`، `lib/core/network/error_mapper.dart`، `lib/core/network/lenient_json_transformer.dart`، `lib/core/config/server_config_store.dart`. **ولا يوجد أي lint باسم `architecture` ولا `avoid_print` في التهيئة.**
- Why problematic: التعليقات لا تفعل شيئاً (لا lint مطابق)، والتقييم يوهم القارئ بأن الانتهاكات «معالَجة». النتيجة: `core → features` في 5 مواضع، و`avoid_print` معطّل تماماً، ولا يوجد أي فحص آلي يمنع تكرار الكود.
- Violated principle: Enforced architecture boundary — القواعد غير المفروضة ليست قواعد.
- Current owner: `analysis_options.yaml` + مؤلفو الملفات الموسومة
- Correct owner: إعداد analyzer مع `custom_lint` (مثلاً `very_good_analysis` أو `arch_lint`) + `import_lint` granularity على `core/`.
- Consequences: كل إضافة جديدة reintroduce الانolkاء بلا مراجعة؛ الـ audit اليدوي هو خط الدفاع الوحيد.
- Recommended correction: فعّل `avoid_print`، وأضف lint لتقييد الاستيراد في `core/**` (يمنع `features/`، `backend/`، `app/`)، واحذف أووحّد كل `ignore_architecture` على Strikes التي مخالفة فعلية.
- Related files: كل الملفات الحاملة للعلامة (انظر CORE-001..CORE-003)
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-005: كائنان حيّان من `TrackingService` — وتجاوز لـ`traccarNativeClientProvider` الواعي بالـmock
- Severity: HIGH
- Category: Riverpod
- Location: `lib/app/app_initializer.dart:65-68,89-91`
- Evidence:
```dart
trackingService = TrackingService(
  storage: localStorageService,
  tracker: TraccarNativeClientImpl(),
);
```
```dart
      overrides: [
        localStorageProvider.overrideWithValue(localStorageService),
        localDatabaseServiceProvider.overrideWithValue(localDatabaseService),
        trackingServiceProvider.overrideWithValue(trackingService),
        utcSyncServiceProvider.overrideWithValue(utcSync),
      ],
```
- Current behavior: `AppInitializer` يبني `TrackingService` يدوياً بحقن `TraccarNativeClientImpl()` مباشرة، ثم يفرضه عبر `overrideWithValue` على `trackingServiceProvider`. بينما `traccarNativeClientProvider` (المُعاد تصديره عبر `core/network/core_providers.dart:13-14`) يطبّق اختيار mock:
```dart
final traccarNativeClientProvider = Provider<TraccarNativeClient>((ref) {
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    return MockTraccarNativeClient();
  }
  return TraccarNativeClientImpl();
});
```
 بينما `trackingServiceFullProvider` في `features/tracking/data/providers/tracking_providers.dart:22-26` يبني **نفس** `TrackingService` بنفس التركيبة، وغير مُoverride.
- Why problematic: (1) في بيئة `mock`، الكائن المُستخدَم من `quick_actions_initializer.dart:29` (وهو `trackingServiceProvider` المُoverride) يذهب إلى Traccar حقيقي بينما بقية النظام يذهب إلى mock — سلوكان مختلفان في نفس الجلسة. (2) وجود نسختين حيّتين من `TrackingService` يعني أن حالة التتبع (config, subscriptions, init flag) منقسمة على كائنين لا يتبادلان الحالة.
- Violated principle: Single Source of Truth / Dependency Injection via composition root؛ also Principle of least surprise في بيئة mock.
- Current owner: `lib/app/app_initializer.dart` (بناء يدوي) + `features/tracking/data/services/tracking_service.dart:200-204` (المزوّد) + `features/tracking/data/providers/tracking_providers.dart:22-26` (المزوّد الثاني)
- Correct owner: `lib/backend/providers/backend_network_providers.dart:26` (`apiClientProvider`) ومزوّد واحد فقط لـ`TrackingService` يعتمد على `traccarNativeClientProvider`.
- Consequences: في وضع mock، الاختبار يذهب للإنترنت؛ وفي الإنتاج، `quick_actions` و`tracking_repository` يبدآن دورة تتبّع منفصلة (_isInitialized منفردة لكل نسخة).
- Recommended correction: احذف البناء اليدوي من `AppInitializer`؛ اجعل `trackingServiceProvider` يعتمد على `traccarNativeClientProvider` واحذف `trackingServiceFullProvider` (أو اجعل أحدهما `alias` للآخر). للاحتفاظ الاعتماد على تهيئة ما قبل الحاوية، استخدم `ProviderContainer(overrides: ...)` على `traccarNativeClientProvider` بدلاً من الخدمة كاملة.
- Related files: `lib/features/tracking/data/services/tracking_service.dart:200-204`, `lib/features/tracking/data/providers/tracking_providers.dart:22-26`, `lib/backend/providers/backend_network_providers.dart:77-82`, `lib/app/services/quick_actions_initializer.dart:29`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-006: ساعة الجهاز تُستخدم ل��سم الأحداث القانونية في الطابور، و`trustLevel` لا يُقرأ أبداً
- Severity: HIGH
- Category: Architecture
- Location: `lib/core/time/time_authority_provider.dart:24-30`; `lib/core/time/time_authority.dart:16-35,62-63`; `lib/core/time/monotonic_time_authority.dart:42-44`
- Evidence:
```dart
final timeAuthorityProvider = Provider<TimeAuthority>((ref) {
  final authority = MonotonicTimeAuthority();
  // Fire-and-forget: initialize in the background.
  // Safe because `nowUtc()` falls back to `DateTime.now()` until
  // initialized.
  authority.initialize();
  return authority;
});
```
```dart
  /// The current level of trust for [nowUtc].
  TrustLevel get trustLevel;
```
```dart
  @override
  TrustLevel get trustLevel =>
      _anchorUtc == null ? TrustLevel.untrusted : TrustLevel.localDevice;
```
- Current behavior: المزوّد الافتراضي هو `MonotonicTimeAuthority` — مرساة على `DateTime.now()` + `Stopwatch`. هذا المزوّد هو ما تستهلكه `features/sync/domain/usecases/sync_engine.dart:201` (`nowUtc: _timeAuthority.nowUtc()`) و`features/logs/data/repositories/log_repository_impl.dart:346,433` (`createdAt: _timeAuthority.nowUtc()`) و`features/tracking/data/providers/tracking_providers.dart:31-33`. **`TrustLevel` و`trustLevel` لا يقرأهما أي ملف خارج `time_authority.dart` و`monotonic_time_authority.dart`.**
- Why problematic: الواجهة تعلن قاعدة صريحة:
```dart
/// Level of trust for the current time source.
///
/// Callers may refuse to compute time-sensitive results when trust is
/// below a threshold.
```
  ثم لا يوجد «caller» واحد يفعل ذلك. النتيجة: `SyncEngine` يضع `nowUtc` على أحداث قانونية مُدرجة في الطابور باستخدام ساعة جهاز قابلة للتلاعب، و`TrustLevel` remains ornamental. هذا يناقض صراحةً ما كتبه الفريق نفسه في `lib/app/app_initializer.dart:98-100`:
```dart
    // UtcSyncService.utcNow is DateTime.now(). Anchoring TrustedTimeProvider
    // from it would let a device clock become a legal duty stamp. Only a
    // server Date header, through TimeDriftInterceptor, may anchor the clock.
```
  الحظر كُتب لـ`UtcSyncService` وطبّق، لكنه لم يُطبَّق على `timeAuthorityProvider` الذي يملك الاستهلاك الفعلي.
- Violated principle: 49 CFR §395.8 / ELD time-authority requirement؛ وقاعدة «الطبقات تعكس النية الموثّقة».
- Current owner: `lib/core/time/time_authority_provider.dart`
- Correct owner: مزوّد يُعيد `MonotonicTrustedTimeProvider` (الموثوق خادمياً) أو `ServerAnchoredTimeAuthority` تنفّذه `TimeAuthority`، مع تحويل `features/sync` لاستخدام `TrustedTimeProvider`(sealed) لا `TimeAuthority`.
- Consequences: يمكن للسائق تعديل ساعة الجهاز/manipulate ليُزيح توقيت سجل قانوني قبل المزامنة؛ ولا يوجد في الكود أي مؤشر يجعل الفشل مرئياً.
- Recommended correction: (أ) اجعل `timeAuthorityProvider` افتراضياً مرساة خادمية (تُغذّى من `TimeDriftInterceptor`)، أو (ب) ألغِ عائلة `TimeAuthority` بالكامل واجعل الاستهلاك يمر بـ`TrustedTimeProvider`/`TrustedTimeResult` بالفعل المستخدَم في `trusted_time_provider.dart:127-136`. (ج) أضف حارساً: في `SyncEngine`، ارفض الطابع عند `state != TrustedTimeState.trusted` (وأنشئ `TimeUnavailableError` المعرّف أصلاً والمُهمَل — انظر CORE-009).
- Related files: `lib/core/time/trusted_time_provider.dart`, `lib/features/sync/domain/usecases/sync_engine.dart:201`, `lib/features/logs/data/repositories/log_repository_impl.dart:346,433`, `lib/core/error/app_error.dart:414`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-007: استعادة المرساة تعتمد على ساعة الجهاز كمرجع offline حتى 7 أيام وتُبلَّغ `trusted`
- Severity: HIGH
- Category: Architecture
- Location: `lib/core/time/trusted_time_provider.dart:76-84,91-98`
- Evidence:
```dart
      _trustedServerUtcAtSync = anchorUtc.add(
        DateTime.now().difference(restoredDeviceWall),
      );
```
```dart
    if (_restoredFromDisk && _restoredDeviceWallMs != null) {
      // حد الثبات للنسخة المستعادة يُقاس عبر فترة الإغلاق بساعة الجهاز.
      if (DateTime.now().difference(_restoredDeviceWallMs!) >=
          const Duration(days: 7)) {
        return TrustedTimeState.stale;
      }
      return TrustedTimeState.trusted;
    }
```
- Current behavior: بعد إعادة تشغيل التطبيق، يُعاد بناء الزمن من مرساة خادمية محفوظة + فرق ساعة الجهاز عبر فترة الإغلاق، ثم يُعاد `TrustedTimeState.trusted`. التعليق يقرّ بذلك صراحةً:
```dart
/// **الاستمرارية عبر الإقلاع (قرار المالك 2026-10-03):** ... مرساة خادمية
/// تُخزَّن محلياً مع ساعة الجهاز لحظتها ... ملاحظة أمنية معلنة: هذا يجعل
/// ساعة الجهاز مرجعَ الفترة offline فقط
```
- Why problematic: `(1)` معيار «الثقة» يُشتق من ساعة الجهاز نفسها التي يفترض المنعِد أنها غير موثوقة — دcircري منطقي. `(2)` التلاعب بساعة الجهاز (إرجاعها 7 أيام، أو تقديمها) يُزيح كل طابع زمني محسوب داخل نافذة السبع أيام بينما الحالة تبقى `trusted`، فلا يُمنع أي حساب. `(3)` العتبة `days >= 7` تقاس بساعة الجهاز (`DateTime.now().difference(_restoredDeviceWallMs)`)، أي أن التلاعب نفسه يملي حدوده.
- Violated principle: Trust cannot be self-certified by the untrusted source؛ مبدأ «عدم الثقة المُعلنة».
- Current owner: `lib/core/time/trusted_time_provider.dart`
- Correct owner: طبقة `TrustedTimeProvider` نفسها، عبر: (أ) تخزين عدّاد رتيب غير قابل للتلاعب، أو (ب) تخفيض الحالة إلى `untrusted` حتى تصل مرساة خادمية جديدة، مع السماح بالعرض فقط لا بالحساب القانوني.
- Consequences: انحراف يبلغ حتى ±7 أيام في الطوابع القانونية دون أي مؤشر في الكود. الخطر مُعلن في التعليق لكنه غير مفروض بالسلوك.
- Recommended correction: عند الاستعادة، اضبط الحالة على `untrusted` (أو `stale`) ما لم تكن هناك مرساة خادمية **من هذه الجلسة**؛ واسمح بالعرض فقط. وثّق الحالة في سجل تشخيصي مرتبط بكل طابع (`TrustedTimeState` + معرّف الإقلاع) ليصل الخادم عند المزامنة.
- Related files: `lib/core/time/time_authority.dart:20-35`, `lib/backend/http/interceptors/time_drift_interceptor.dart:62`, `lib/core/error/app_error.dart:414`
- Confidence: POTENTIAL (القرار موثّق كقرار مالك — الخطر معماري حتى لو كان مقصوداً)
--------------------------------------------------

### ISSUE CORE-008: نظامان موازيان بالكامل للزمن الموثوق داخل `core/time`
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/time/time_authority.dart` + `time_authority_provider.dart` + `monotonic_time_authority.dart` مقابل `lib/core/time/trusted_time_provider.dart`
- Evidence:
```dart
abstract interface class TimeAuthority {
  Future<void> initialize();
  DateTime nowUtc();
  Duration get monotonicElapsed;
  TrustLevel get trustLevel;
  Future<bool> resync();
}
```
```dart
abstract interface class TrustedTimeProvider {
  TrustedTimeState get state;
  TrustedTimeResult get currentTime;
  Duration get monotonicElapsed;
  void anchor(DateTime serverUtc);
}
```
- Current behavior: واجهتان بمجموعة أعضاء متقاربة في نفس المجلد، لهما تنفيذان (`MonotonicTimeAuthority` و`MonotonicTrustedTimeProvider`)، ولهما مزوّدان (`timeAuthorityProvider` و`trustedTimeProvider`)، ونموذجا ثقة (`TrustLevel` enum مقابل `TrustedTimeState` enum + `TrustedTimeResult` sealed). الأولى مستهلكة من `features/logs` و`features/sync` و`features/tracking`؛ والثانية مستهلكة من `backend/http/interceptors/time_drift_interceptor.dart:70` فقط.
- Why problematic: مجموعتان من البنى بنفس الاسم-ish (`monotonicElapsed` في둘) بنفس الدلالة ولكن بعقود مختلفة (`resync()` مقابل `anchor()`). من ينظر للمجلد لا يستطيع أيهما «سلاح الزمن الموثوق». كما أن أحدهما يحمل الفجوة الأمنية (CORE-006) والآخر يحمل الاستعادة (CORE-007)، فلا يوجد مسار واحد يمكن تشديده.
- Violated principle: DRY على مستوى التجريد؛ وتقدّم الكائنات (Low coupling / High cohesion على مستوى النموذج).
- Current owner: `lib/core/time/` (كلاهما)
- Correct owner: abstractions واحدة — `core/time/trusted_time.dart` (Contract + sealed result + state)، مع `FakeTrustedTimeProvider` كبديل اختبار موحّد.
- Consequences: صيانة مكرّرة، احتمال اختلاف سلوك بين مستهلكَين للزمن، وصعوبة certifying واحدة للإتقان القانوني.
- Recommended correction: احذف عائلة `TimeAuthority` (أو اجعلها `typedef`/adapter رقيق فوق `TrustedTimeProvider`)، وحمّل الاستهلاك على `trustedTimeProvider` + `TrustedTimeResult`.
- Related files: `lib/core/time/time_authority_provider.dart`, `lib/core/time/monotonic_time_authority.dart`, `lib/backend/http/interceptors/time_drift_interceptor.dart`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-009: ثلاث فئات خطأ مُصنَّفة `AppError` لا تُنشأ أبداً — إحداها تحمل ثقلاً قانونياً
- Severity: MEDIUM
- Category: Maintainability
- Location: `lib/core/error/app_error.dart:414-437` (`TimeUnavailableError`), `:444-467` (`StorageError`), `:344-372` (`UnsupportedCapabilityError`)
- Evidence:
```dart
/// Trusted time is unavailable. HOS calculations must be suspended.
final class TimeUnavailableError extends AppError {
```
- Current behavior: بحث في كامل `lib/` (خارج تعريفات الملف نفسه) وجد **0** بناء لـ`TimeUnavailableError`، `StorageError`، `UnsupportedCapabilityError`. أي: التعاقد «HOS calculations must be suspended» لا يوجد له أي تنفيذ. بينما `ConflictError` و`ValidationError` يُستخدمان فعلاً في `core/network/error_mapper.dart:132,134,102,104,141,150,159,161`.
- Why problematic: وجود نوع خطأ بلا منتج يجعل القارئ (والمدقق) يفترض وجود آلية إيقاف فعّلي. ويعني أن HOS يُحسب فعلاً حتى عند انعدام الثقة — وهو خلفيّة CORE-006/007. كما أن التوثيق يوحي بأن `StorageError` و`UnsupportedCapabilityError` كلمتان مناسبتان لكنهما غير مربوطتين.
- Violated principle: YAGNI مقابل السلامة — التغطية الوهمية ليست تغطية.
- Current owner: `lib/core/error/app_error.dart`
- Correct owner: نفس الملف (للتصنيف) + مواقع الاستهلاك التي يجب أن تُنشئها (`core/time`، `core/storage`، `backend`).
- Consequences: ثلاثة آثار: (أ) ضياع صلة التنفيذ التي كان يفترضها التعاقد مع HOS؛ (ب) تسطيح التعاقد؛ (ج) فخ صيانة.
- Recommended correction: إمّا ابدأ في بناء `TimeUnavailableError` من `MonotonicTrustedTimeProvider` عند `state != trusted` (مع ربطه بـCORE-006)، أو احذف الأنواع الثلاثة مع تعليق صريح.
- Related files: `lib/core/error/user_facing_message.dart:39-47` (لا case لـ`TimeUnavailableError` ⇒ يسقط إلى `_ => loc.errGeneric`), `lib/core/time/trusted_time_provider.dart`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-010: نظامان متنافسان للخطأ — `AppError`/`Result` مقابل `Failure`/`Either`
- Severity: MEDIUM
- Category: Architecture
- Location: `lib/core/result/result.dart:16` مقابل `lib/core/error/failure.dart:4`; `lib/core/network/error_mapper.dart:15` مقابل `lib/core/utils/repository_helper.dart:10`
- Evidence:
```dart
typedef Result<T> = fp.Either<AppError, T>;
```
```dart
final _defaultNetworkInfo = NetworkInfoImpl();

/// Helper function to standardize error handling across all repositories.
Future<Either<Failure, T>> executeWithHandling<T>(
```
```dart
/// This is the **single point** where HTTP errors are translated.
AppError mapDioException(DioException e) {
```
- Current behavior: `Result<T>` (نوع `AppError`) يُستخدم في 13 مورداً من `lib/backend/adapters/**`، بينما كل المستودعات في `lib/features/**` تُرجع `Either<Failure, T>` وتُغلَّف بـ`guardedNetwork` أو `executeWithHandling`. `mapDioException`claimed كـ«نقطة ترجمة وحيدة» لكنها تعمل على مستوى Dio فقط؛ ثم يُطبَّق تحويل ثانٍ (`executeWithHandling`) فوق نتيجتها.
- Why problematic: تسريب استثناء من العقد الثاني إلى الأول مثبت في الكود:
```dart
return response.fold((error) => throw ServerException(message: error.code), (json) {
```
  (`lib/features/logs/data/repositories/log_repository_impl.dart:270`). أي أن طبقة `AppError` تغني راية `Failure` عبر استثناء، ثم يمسكه `executeWithHandling` الذي يعيد بناء `Failure`. ثلاث طبقات لنفس المشكلة. كما أن `error_mapper.dart` و`user_facing_message.dart` لا يعرفان `Failure`، و`repository_helper.dart` لا يعرف `AppError` — فالنظامان لا يتقاطعان أبداً ولا يغطيان بعضهما.
- Violated principle: Single error contract عبر الطبقات؛ قاعدة «لا ترمِ عبر حدود طبقة».
- Current owner: `lib/core/result/result.dart`, `lib/core/error/failure.dart`
- Correct owner: عقد واحد على مستوى `core` — غالباً `Result<T>` — مع تحويل `Failure` إلى adapter في المودال.
- Consequences: كل مستودع جديد يختار عشوائياً؛ إمكانية وصول `DioException`/`ServerException` لواجهة المستخدم؛ ورسائل خطأ غير متسقة.
- Recommended correction: اختر `Result<T>` كعقد وحيد، احذف `exception.dart`، وحوّل `executeWithHandling`/`guardedNetwork` لتُعيد `Result`. إن أبقبيت `Failure`، فاجعل `AppError` subclass لـ`Failure` (ورثة) بدل تصنيفين متماهيين.
- Related files: `lib/core/error/exception.dart`, `lib/core/network/network_guard.dart:20`, `lib/core/error/user_facing_message.dart:7-25`, `lib/features/logs/data/repositories/log_repository_impl.dart:270`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-011: `core/error/exception.dart` شبه ميت — موقع `throw` واحد مقابل 7 فئات
- Severity: MEDIUM
- Category: Maintainability
- Location: `lib/core/error/exception.dart:2-77`; `lib/core/utils/repository_helper.dart:28-52`
- Evidence:
```dart
/// استثناء المتابعة
class SyncException implements Exception {
  final String? message;

  const SyncException([this.message]);

  @override
  String toString() => 'SyncException: $message';
}
```
```dart
  } on ServerException catch (e) {
    ...
  } on OfflineException catch (e) {
    ...
  } on UnauthorizedException catch (e) {
    ...
  } on CacheException catch (e) {
```
- Current behavior: بحث في كامل `lib/` وجد موقع `throw` واحد فقط يستعمل أيًّا من هذه السبعة: `lib/features/logs/data/repositories/log_repository_impl.dart:270` (`throw ServerException`). وبقية الفئات (Sync, Tracking, Permission) لا تُرمى إطلاقاً. ومع ذلك `executeWithHandling` يبني 4 معالجات `on <X> catch`.
- Why problematic: الملف يبدو واجهة خطأ حيّة (بلا `sealed`، وبلا تحويل إلى `AppError`، وبلا استيراد `dio`)، فيوحي بأنه الطبقة المعمتمدة — بينما هو مسار ميت يترك `executeWithHandling` يبدو كأنه يلتقط أخطاء حقيقية. كما أن وجود معالج `on X catch` لاستثناء لا يُرمى هو كود لا يمكن اختباره.
- Violated principle: إزالة الكود الميت؛ وقاعدة DIP — استثناءات المستوى الأعلى بلا متطلب مطابق في `core`.
- Current owner: `lib/core/error/exception.dart`
- Correct owner: احذفه (بعد توحيد العقد — CORE-010)، أو اجعله `final class ... extends AppError` حتى يدخل في نفس النظام.
- Consequences: صيانة مهدورة، وقارئ يظن أن هناك طبقتَي خطأ نشطتين بينما هناك نصف طبقة.
- Recommended correction: احذف `exception.dart` وكل معالجات `on <X> catch` المرتبطة به بعد توحيد العقد على `Result`.
- Related files: `lib/core/utils/repository_helper.dart:28-52`, `lib/core/error/failure.dart`, `lib/features/logs/data/repositories/log_repository_impl.dart:270`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-012: كاشف «تراكمات الخادم» مكرر في ملفين بقائمتين مختلفتين
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/network/error_mapper.dart:212-221` مقابل `lib/core/error/user_facing_message.dart:64-78`
- Evidence (`error_mapper.dart`):
```dart
bool _looksLikeServerDump(String text) {
  final lower = text.toLowerCase();
  return lower.contains('org.hibernate') ||
      lower.contains('org.postgresql') ||
      lower.contains('eldpersistenceexception') ||
      lower.contains('psqlexception') ||
      lower.contains('could not execute statement') ||
      lower.contains('\tat ') ||
      text.length > 280;
}
```
- Evidence (`user_facing_message.dart`):
```dart
bool _looksLikeServerDump(String text) {
  final lower = text.toLowerCase();
  return lower.contains('hibernate') ||
      lower.contains('dioexception') ||
      lower.contains('org.postgresql') ||
      lower.contains('org.springframework') ||
      lower.contains('java.lang.') ||
      lower.contains('kotlin.') ||
      lower.contains('eldpersistenceexception') ||
      lower.contains('exception:') ||
      lower.contains('stacktrace') ||
      lower.contains('\tat ') ||
      lower.contains('instance of') ||
      lower.contains('package:');
}
```
- Current behavior: دالة بنفس الاسم والنية في طبقتين مختلفتين، بنفس الحجم، وقائمتا أسطر مختلفة مع اختلاف في الحد (`text.length > 280` مقابل `trimmed.length > 140`).
- Why problematic: كشف الإTEXTIII عن تسريب الخادم هو ضابط أمني للمحتوى الذي يصل للسائق؛ ازدواجه يعني أن إصلاحاً في أحدهما لا يصل للآخر. فمثلاً `dioexception` مرشَّح في `user_facing_message` لكنه ليس في `error_mapper` — فـ`error_mapper` قد يضع نصاً فيه `DioException` في `context['serverMessage']`، ثم `user_facing_message` يرفضه عند العرض — سلوك متفق عليه لكنه عرضي لا مقصود.
- Violated principle: DRY؛ مصدر واحد لسياسة التنقية الأمنية.
- Current owner: ملفان في `core` بنفس `_looksLikeServerDump`.
- Correct owner: `core/error/user_facing_message.dart` (سياسة العرض) — يستورد منه `error_mapper` دالة واحدة.
- Consequences: انحراف سلوكي مستقبلي، وصعوبة مراجعة سياسة الخصوصية في مكان واحد.
- Recommended correction: اجعل `error_mapper` يستورد `_looksLikeServerDump` كـ`@visibleForTesting` عام من `user_facing_message`، واحذف النسخة المكرّرة؛ وحّد عتبة الطول في ثابت واحد.
- Related files: `lib/core/network/error_mapper.dart:195-227`, `lib/core/error/user_facing_message.dart:50-99`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-013: `localization_helper` تمرر رسائل الخطأ عبر قناة ثانية موازية لـ`user_facing_message`
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/utils/localization_helper.dart:11-50`
- Evidence:
```dart
    switch (key) {
      case 'emailRequired':
        return loc.emailRequired;
      ...
      case 'permissionDenied':
        return loc.permissionDenied;
      default:
        // Not an l10n key: a backend error code such as
        // `network.connectionFailed`, `server.unavailable`, `server_error`.
        // The driver never sees the code itself.
        final loc = AppLocalizations.of(this)!;
        final lower = key.toLowerCase();
        if (lower.startsWith('network.') || lower.contains('connection')) {
          return anyErrorUserMessage('noInternet', loc: loc);
        }
        if (lower.startsWith('server') ||
            lower.endsWith('_error') ||
            lower.contains('.') ||
            lower.contains('_')) {
          return anyErrorUserMessage(Object(), loc: loc);
        }
        return anyErrorUserMessage(key, loc: loc);
    }
```
- Current behavior: دالة تمديد على `BuildContext` تختار نصاً للمستخدم عبر (أ) `switch` على 12 مفتاح l10n، ثم (ب) تخمين مبني على شكل النص (`startsWith('network.')`، `contains('_')`) يُمرِّر النص إلى `anyErrorUserMessage` للتحقق. هذا يعني وجود **منطق** في طبقة UIwm ودالة التحقق في طبقة `core/error`.
- Why problematic: منطق الترجمة في ثلاث أماكن: `user_facing_message.appErrorUserMessage` (`switch` على نوع `AppError`)، و`localization_helper` (`switch` على نص + تخمين)، و`context_extensions.translateStatus` (`switch` آخر). كما أن التخمين في الفرع `default` هشّ: أي مفتاح يحوي `.` أو `_` يُعامَل كخطأ عام. وهو يجلب `AppLocalizations` مرتين (`loc` في السطر 9 ثم `final loc` في السطر 38 — متغيّر مظِلّ).
- Violated principle: SRP في عرض الأخطاء؛ قاعدة «طبقة العرض لا تقرر ما هو آمن للعرض».
- Current owner: `lib/core/utils/localization_helper.dart`
- Correct owner: `lib/core/error/user_facing_message.dart` يجب أن تملك التحويل الوحيد من (نوع/رمز) → نص، ويكون `localization_helper` نداءً واحداً بلا `switch`.
- Consequences: نفس رمز الخطأ قد يُترجم إلى نصين مختلفين حسب المسار؛ وصعوبة إضافة رمز جديد.
- Recommended correction: احذف الـ`switch` من `localization_helper` واجعله `return anyErrorUserMessage(key, loc: loc)`، ووسّع `appErrorUserMessage` ليقبل `String code` أيضاً عبر سجل مركزي.
- Related files: `lib/core/error/user_facing_message.dart:27-48`, `lib/core/extensions/context_extensions.dart:22-32`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-014: عنوان السيرفر الثابت مُعرَّف في مكانين
- Severity: MEDIUM
- Category: Hardcoding
- Location: `lib/core/config/runtime_selection.dart:23`; `lib/core/services/local_storage_service.dart:94`
- Evidence:
```dart
const String fallbackServerOrigin = 'https://snsoft.cloud';
```
```dart
    // وضع الإعدادات الافتراضية إذا لم تكن موجودة
    const String defaultServer = 'https://snsoft.cloud';
    final currentUrl = _prefs.getString('url');
        
    if (currentUrl == null || currentUrl.isEmpty) {
      await _prefs.setString('url', defaultServer);
      await _prefs.setString('backend_type', 'eld');
      AppLogger.info('Server URL and Backend Type set to default settings');
    }
```
- Current behavior: نفس العنوان الحرفي في مكانين مستقلين تماماً. `local_storage_service` يكتبه في `SharedPreferences` عند أول تشغيل، فيصبح المدخل المحفوظ يتغلّب على `fallbackServerOrigin` في `resolveRuntimeBackend` (لأن `saved.isNotEmpty` يُقدَّم على `build`). أي أن أول تشغيل يثبّت العنوان محلياً، ولا-central Changes.
- Why problematic: مصدران للحقيقة؛ وتغيير `fallbackServerOrigin` لن يؤثر على أي جهاز ثُبّت بالفعل لأن `url` محفوظ. والأخطر: `local_storage_service` يكتب `'backend_type', 'eld'` بينما `tracking_config_storage_service.dart:40` يستخدم `'traccar'` كقيمة افتراضية للقراءة:
```dart
  String get backendType => _prefs.getString(_backendTypeKey) ?? 'traccar';
```
- Violated principle: Single Source of Truth on configuration؛ قاعدة «الإعدادات من مصدر واحد».
- Current owner: `lib/core/services/local_storage_service.dart` (كاتب) + `lib/core/config/runtime_selection.dart` (قارئ)
- Correct owner: `lib/core/config/runtime_selection.dart` — يتولّى كتابة الـdefaults أيضاً.
- Consequences: اختلاف السلوك بين جهاز جديد وجهاز مُرقّع؛ عدم القدرة على تدوير الخادم الافتراضي.
- Recommended correction: اجعل `local_storage_service` يستدعي `resolveRuntimeBackend` (أ) constante واحدة من `runtime_selection.dart`، واحذف `'traccar'` كقيمة افتراضية للقراءة في `tracking_config_storage_service.dart:40` — دع `resolveBackendType` في `core_providers.dart:58-66` هيsole صاحبة القرار.
- Related files: `lib/core/network/core_providers.dart:44-66`, `lib/core/services/tracking_config_storage_service.dart:40`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-015: ملف `.env` متتبَّع في git بينما يقرأ منه التطبيق بيانات اعتماد
- Severity: MEDIUM
- Category: Security
- Location: `lib/core/config/app_environment.dart:29,84-89`; `.gitignore` (سطر «Environment»)
- Evidence:
```dart
  static String get apiBaseUrl => _getEnv('API_BASE_URL') ?? '';
  static String get traccarUsername => _getEnv('TRACCAR_USERNAME') ?? '';
  static String get traccarPassword => _getEnv('TRACCAR_PASSWORD') ?? '';
  static String get traccarDeviceId => _getEnv('TRACCAR_DEVICE_ID') ?? '';
```
- Evidence (`.gitignore`):
```
# Environment: .env is a TRACKED non-secret default (server URL only ??
# no credentials live here). Local overrides go to .env.local (ignored).
.env.local
.env.*.local
```
- Current behavior: `git ls-files` يؤكد أن `.env` و`.env.example` و`.env.test` **كلها متتبَّعة**. محتوى `.env` الحالي لا يحتوي أسراراً (`TRACCAR_ENVIRONMENT=production` و`API_BASE_URL=https://snsoft.cloud` فقط). لكن الواجهة البرمجية تقرأ خمسة متغيرات منها اسم مستخدم وكلمة مرور، و`isValidTemporaryTraccarConfig` يطلب كلمة المرور صراحةً:
```dart
  static bool get isValidTemporaryTraccarConfig {
    ...
    final valid = apiBaseUrl.isNotEmpty &&
        traccarUsername.isNotEmpty &&
        traccarPassword.isNotEmpty &&
```
- Why problematic: حراسة الـsecrets تعتمد على **انضباط بشري** («لا تضع أسراراً هنا») لا على آلية. `.env.local` هو المسار المُتجاهَل الوحيد؛ أي مطوّر يضع `TRACCAR_PASSWORD` في `.env` سريُكود إلى المستودع فوراً. ولا يوجد فحص CI يمنع ذلك.
- Violated principle: Never commit secrets؛ الفصل بين القيم العامة والأسرار بالآلية لا بالتعليق.
- Current owner: `lib/core/config/app_environment.dart` + `.gitignore`
- Correct owner: `core/config/app_environment.dart` يجب أن يقرأ الأسرار من `SecureStoragePort` أو من `String.fromEnvironment` (build-time)؛ و`.env` يبقى-nonsecret فقط ويُتحقق منه آلياً.
- Consequences: تسريب `TRACCAR_USERNAME`/`TRACCAR_PASSWORD`/`TRACCAR_DEVICE_ID` إلى تاريخ git عند أول خطأ بشري.
- Recommended correction: (أ) `git rm --cached .env` وأضفه لـ`.gitignore`، واحتفظ بـ`.env.example` كقالب؛ (ب) انقل `traccarPassword`/`traccarUsername`/`traccarDeviceId` إلى `SecureStoragePort` أو `dart-define`؛ (ج) أضف فحصاً آلياً (مثل `gitleaks`) للمرحلة.
- Related files: `.env`, `.env.example`, `lib/core/config/app_environment.dart:91-105`
- Confidence: POTENTIAL (لا يوجد سر في الوضع الحالي — الخطر في الواجهة البرمجية)
--------------------------------------------------

### ISSUE CORE-016: رفع توكن الإشعار يتجاوز طبقة الشبكة كلياً عبر `HttpClient` خام
- Severity: HIGH
- Category: Security
- Location: `lib/app/services/push_notification_service.dart:129-146`
- Evidence:
```dart
  Future<void> _uploadToken(String? token) async {
    if (token == null) return;
    final id = _storage.deviceId;
    final url = _storage.serverUrl;
    if (id.isEmpty || url.isEmpty) return;

    try {
      final request = await HttpClient().postUrl(Uri.parse(url));
      request.headers.contentType =
          ContentType.parse('application/x-www-form-urlencoded');
      request.write(
          'id=${Uri.encodeComponent(id)}&notificationToken=${Uri.encodeComponent(token)}');
      await request.close();
      AppLogger.info('📤 Token uploaded to server');
    } catch (e) {
      AppLogger.error('Failed to upload token', e);
    }
  }
```
- Current behavior: طلب POST مباشر عبر `dart:io`'s `HttpClient` (ليس Dio)، إلى **جذر** عنوان السيرفر المحفوظ (`_storage.serverUrl` — بلا مسار `/api` ولا endpoint)، بدون `AuthInterceptor` (فلا كوكي/جلسة)، بدون `RequestLogger`، ومع كائن `HttpClient` لا يُغلق أبداً. والتوكن يُرسَل في جسم الطلب.
- Why problematic: (1) **تجاوز كامل لطبقة الشبكة**: لا `baseUrl` مُدار، لا مهلات، لا إعادة محاولة، لا تحويل خطأ إلى `AppError` — استثناء خام يمسكه `catch` ويُسجَّل فقط. (2) الطلب بلا مصادقة على مورد حسّاس (تسجيل توكن جهاز). (3) `HttpClient()` ينشئ connection pool جديداً في كل نداء (عند كل `onTokenRefresh`) ولا يُغلق — تسريب مقابض. (4) لا يوجد تعريف للنقطة؛ أي إعادة تسمية endpoint تعني صمتاً.
- Violated principle: Layered Architecture — كل I/O يمر عبر `ApiClient`؛ Encapsulation of transport concerns.
- Current owner: `lib/app/services/push_notification_service.dart`
- Correct owner: `core/network/api_client.dart` عبر `ApiClient.post` (مع مسار endpoint مُعلن)، أو `backend/adapters/...` إن كان خاصاً بجهاز.
- Consequences: تسريب توكن إلى وجهة غير متوقعة إن عُدِّل `serverUrl` محلياً؛ استنزاف موارد الشبكة؛absence logs موحّدة.
- Recommended correction: استبدل بـ`ref.read(apiClientProvider).post('/eld/hardware/notification-token', data: {...})` (أو المسار الصحيح)، واحذف `dart:io` من الملف.
- Related files: `lib/core/network/api_client.dart:91-119`, `lib/backend/providers/backend_network_providers.dart:26-74`, `lib/core/network/core_providers.dart:13-14`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-017: نسخة `NetworkInfoImpl` عامة على مستوى الوحدة تُنشأ بالاستيراد ولا تُتلف
- Severity: MEDIUM
- Category: Maintainability
- Location: `lib/core/utils/repository_helper.dart:7,17`
- Evidence:
```dart
final _defaultNetworkInfo = NetworkInfoImpl();
```
```dart
  if (checkNetworkFirst) {
    final checker = networkInfo ?? _defaultNetworkInfo;
    if (!(checker.isConnected)) {
```
- Current behavior: متغير top-level في `repository_helper.dart` يُنشئ `NetworkInfoImpl()` **عند أول استيراد للملف**، فيفتح اشتراكاً على قناة منصّة `connectivity_plus` — حتى لو لم يُستدعَ `executeWithHandling` ولا مرة مع `checkNetworkFirst: true`. الكائن لا يملك مسار disposal (لا `ref`، لا `onDispose`).
- Why problematic: (1) تسريب اشتراك عالمي مدى الحياة العملية، مكرر عن `networkInfoProvider` في `core_providers.dart:29-34` الذي يتعامل مع `dispose` بشكل صحيح (`ref.onDispose(networkInfo.dispose)`). (2) وجود مصدرين لقراءة حالة الشبكة — واحد حيّ في `Provider` وآخر حيّ دائم — وقد ينحرفان. (3) تهيئة المنصة في وقت الاستيراد (import time) سلوك غير متوقع في بيئة الاختبار.
- Violated principle: DI / Dependency Injection — اعتناد على المورد عبر الحاوية لا على global variable؛ إدارة دورة حياة المورد.
- Current owner: `lib/core/utils/repository_helper.dart`
- Correct owner: `core/network/core_providers.dart` (المزوود الموجود فعلاً).
- Consequences: استيراد `repository_helper.dart` من أي ملف يفتح قناة منصّة لا تُغلق؛ تسريب في الاختبارات (FakesAsync).
- Recommended correction: احذف `_defaultNetworkInfo` واجعل `networkInfo` **مطلوباً** في `executeWithHandling` (اجعلها معاملاً إجبارياً)، أو انقل الدالة لتصبح امتداداً على `Ref` تمرير `ref.watch(networkInfoProvider)`.
- Related files: `lib/core/network/network_info.dart:29-45`, `lib/core/network/core_providers.dart:29-34`, `lib/core/network/network_guard.dart:20-28`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-018: استيراد دائري بين `local_storage_service` و`tracking_config_storage_service`
- Severity: MEDIUM
- Category: Maintainability
- Location: `lib/core/services/local_storage_service.dart:11`; `lib/core/services/tracking_config_storage_service.dart:4`
- Evidence:
```dart
import 'tracking_config_storage_service.dart';
```
```dart
import '../constants/app_constants.dart';
import 'local_storage_service.dart';
```
- Current behavior: `local_storage_service.dart` يستورد `tracking_config_storage_service.dart` (لينشئه في `init()`)، و`tracking_config_storage_service.dart` يستورد `local_storage_service.dart` (لينشئ مزوّده في السطر 101-107). دورتان في نفس حزمة `core/services`.
- Why problematic: الاعتماد المتبادل بين facade وتطبيقه يمنع استخراج التطبيق إلى وحدة مستقلة، ويجعل أي refactor في أحدهما يتمسّ الآخر. الدليل على أن هذا ضروري فعلاً موجود في `tracking_config_storage_service.dart` نفسه:
```dart
final trackingConfigStorageProvider =
    Provider<TrackingConfigStorageService>((ref) {
  // We temporarily read from the existing local storage provider to get the shared prefs instance.
  // In the future, this should depend on a dedicated SharedPreferences provider.
  final localStorage = ref.watch(localStorageProvider);
  return TrackingConfigStorageService(localStorage.prefs);
});
```
  الاعتراف المؤقت في تعليق ما زال مستبدلاً.
- Violated principle: Acyclic Dependencies (DAG) — قاعدة العقوديات البنيوية.
- Current owner: `lib/core/services/tracking_config_storage_service.dart`
- Correct owner: مزوّد `SharedPreferencesWithCache` مستقل في `core/services/` أو `core/storage/`، تعتمد عليه كل الخدمات.
- Consequences: صعوبة استبدال طبقة التخزين؛ حالات تهيئة هشّة (انظر CORE-033 على `static late _prefs`).
- Recommended correction: عرّف `sharedPreferencesProvider` يعيد `SharedPreferencesWithCache`، واحذف `trackingConfigStorageProvider` بالكامل (لا مستهلك له خارج الملف)، واحذف الاستيراد من `local_storage_service` إن لم يعد لازماً.
- Related files: `lib/core/services/local_storage_service.dart:16-38,223-225`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-019: مزوّدان بالاسم نفسه `secureStorageProvider` في `core`، واحد ميت
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/network/core_providers.dart:40-42`; `lib/core/storage/storage_providers.dart:10-12`
- Evidence:
```dart
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});
```
```dart
final secureStorageProvider = Provider<SecureStoragePort>((ref) {
  return const FlutterSecureStorageAdapter();
});
```
- Current behavior: اسمان متطابقان، نوعان مختلفان، في مجلدين مختلفان من `core`. المستهلَك الوحيد (`server_config_store.dart:13`) يستورد `../storage/storage_providers.dart` ويأخذ نسخة `SecureStoragePort`. نسخة `FlutterSecureStorage` في `core_providers.dart` **لا تُستهلك من أي مكان** (بحث: `secureStorageProvider` يظهر في 4 مواضع فقط: تعريفه، تعريف الآخر، الاستخدام في `server_config_store.dart`، واسم الملف في تعليقات الاستيراد).
- Why problematic: اسم واحد ل.Dependency مختلفة النوعية في نفس الطبقة = فخ استيراد صامت. لو استورد ملف `core_providers.dart` و`storage_providers.dart` معاً، يفوز أحدهما بصمت (أو يظهر تعارض). والأهم: وجود `FlutterSecureStorage` في `core/network/` يكسرHexagonal — يُخالف نفس الـport الذي صُمّم لـ.
- Violated principle: Dependency Inversion —_port واحد، تنفيذ واحد؛ تسمية فريدة للمزوّدات.
- Current owner: `lib/core/network/core_providers.dart:40-42`
- Correct owner: `lib/core/storage/storage_providers.dart` (المُبقى).
- Consequences: احتمال أن يمرر كودٌ ما `FlutterSecureStorage` مكشوفاً بدل المنفذ، فتتحقق القاعدة «لا أسرار إلا عبر `SecureStoragePort`» بالإهمال لا بالبنية.
- Recommended correction: احذف `secureStorageProvider` من `core_providers.dart`، وسمِّ الأ Ableton. أي مستهلك يحتاج `FlutterSecureStorage` مباشرة يجب أن يمر عبر المنفذ.
- Related files: `lib/core/storage/ports/secure_storage_port.dart`, `lib/core/config/server_config_store.dart:11-15`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-020: مفاتيح التخزين مُعرَّفة في أربعة أماكن
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/constants/app_constants.dart:27-32`; `lib/core/constants/storage_constants.dart:3-5`; `lib/core/services/tracking_config_storage_service.dart:12-23`; `lib/core/services/user_preferences_storage_service.dart:9-16`; `lib/core/localization/locale_provider.dart:19,23`
- Evidence:
```dart
  // مفاتيح التخزين
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String languageKey = 'language_code';
  static const String themeKey = 'theme_mode';
```
```dart
class StorageConstants {
  // SharedPreferences Keys
  static const String serverUrl = 'url';
  static const String deviceId = 'id';
  static const String eventLogs = 'event_logs';
```
```dart
  static const String _languageKey = 'language';
  static const String _themeKey = 'theme';
```
```dart
  static const String _oldLanguageKey = 'language_code';
```
- Current behavior: `'url'` و`'id'` في `StorageConstants` **و** في `tracking_config_storage_service`؛ `'language'` في `user_preferences_storage_service` و`'language_code'` في `AppConstants` و`'language_code'` في `locale_provider` كمفتاح قديم؛ `'theme'` مقابل `'theme_mode'`. و7 ثوابت من `AppConstants` (المفاتيح كلها) لا تُستخدم إلا `appVersion` في `features/about/presentation/pages/about_page.dart:92`.
- Why problematic: مفتاح preferences تالف يصمتاً (يكتب في مكان ويقرأ من آخر) لأن الاسم الحرفي مكرر؛ والأسوأ أن `AppConstants.tokenKey`/`refreshTokenKey` تُوحي بمكان تخزين التوكن — وهو في الواقع `FlutterSecureStorage` (تحققت: `auth_local_data_source.dart:36,61` يستعمل `FlutterSecureStorage`).
- Violated principle: DRY؛ Single Source of Truth لأسماء المدخلات.
- Current owner: `lib/core/constants/app_constants.dart` + `lib/core/constants/storage_constants.dart`
- Correct owner: `lib/core/constants/storage_constants.dart` كمصدر وحيد لأسماء `SharedPreferences`، مع حذف ثوابت التوكن الميتة.
- Consequences: فقد تفضيلات عند أي إعادة تسمية؛ وحالة زائدة تُوحي بتخزين غير آمن.
- Recommended correction: (أ) احذف مفاتيح التخزين كلها من `AppConstants` (`tokenKey`..`themeKey`) — تحقّقت أنها غير مستخدمة؛ (ب) اجعل `StorageConstants` التعريف الوحيد لكل مفتاح، واستورده في `tracking_config_storage_service` و`user_preferences_storage_service`؛ (ج) احذف `StorageConstants.eventLogs` (ميت).
- Related files: `lib/core/constants/storage_constants.dart`, `lib/features/auth/data/datasources/auth_local_data_source.dart:36-132`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-021: ثوابت `AppConstants` الميتة توحي بتخزين التوكن خارج المخزن الآمن
- Severity: LOW
- Category: Security
- Location: `lib/core/constants/app_constants.dart:27-30`
- Evidence:
```dart
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
```
- Current behavior: أربعة ثوابت تدل على أسماء مفاتيح لتخزين التوكن في `SharedPreferences`. البحث في `lib/` وجد **0** استخدام لها. التخزين الفعلي للتوكن في `FlutterSecureStorage` (متحقَّق منه في `features/auth/data/datasources/auth_local_data_source.dart:36,61,76,106`).
- Why problematic: ليست مخالفة نافعة بذاتها (التخزين الفعلي صحيح)، لكنها **محفّز معماري**: أي مطوّر يريد quickest path سيستخدم `AppConstants.tokenKey` مع `LocalStorageService.prefs` ويعيدintroduce تخزين التوكن في preferences العادية. وجود الاسم يجعل الطريق الخاطئ يبدو معتمداً.
- Violated principle: Secure-by-default naming؛ قاعدة «لا تركن الأسرار في storage غير آمن».
- Current owner: `lib/core/constants/app_constants.dart`
- Correct owner: لا مكان له — يُحذف.
- Consequences: احتمال تسريب جلسة عند استخدام لاحق غير واعٍ.
- Recommended correction: احذف `tokenKey`, `refreshTokenKey`, `userIdKey`, `userRoleKey` من `AppConstants`. لا تضف مفتاح توكن في ملف ثوابت عام.
- Related files: `lib/core/storage/ports/secure_storage_port.dart:5-6` (القاعدة مكتوبة صراحة), `lib/core/config/server_config_store.dart:11-15`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-022: حدود HOS التنظيمية مُعرَّفة في مكانين بقيم متطابقة يدوياً
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/config/hos_configuration.dart:25-50`; `lib/core/constants/fmcsa_constants.dart:18-34`
- Evidence:
```dart
  factory HosConfiguration.usa70_8() {
    return const HosConfiguration(
      drivingLimitMinutes: 11 * 60,
      shiftLimitMinutes: 14 * 60,
      cycleLimitHours: 70,
      breakDurationMinutes: 30,
      movingSpeedThresholdKmh: 8.0,
      driveBeforeBreakMinutes: 8 * 60,
      maxConsecutiveDays: 8, // 70 hours in 8 days
      weeklyRestartHours: 34,
    );
  }
```
```dart
  /// Maximum consecutive driving hours before 10-hour rest requirement: 11 hours.
  static const int maxDrivingHours = 11;
  /// Maximum duty window duration after coming on duty: 14 hours.
  static const int maxDutyWindowHours = 14;
  static const int cycle8DaysLimitHours = 70;
  static const int cycleRestartHours = 34;
```
- Current behavior: نفس الأرقام التنظيمية (11، 14، 70، 30، 8، 34) مكتوبة مرة في `FmcsaConstants` ومرة في `HosConfiguration.usa70_8()/usa60_7()`، بصيغ مختلفة (`maxDrivingHours` ساعة مقابل `drivingLimitMinutes: 11 * 60` دقيقة). كذلك `FmcsaConstants.drivingSpeedThresholdMps = 2.235` مقابل `HosConfiguration.movingSpeedThresholdKmh = 8.0` (نفس العتبة بوحدتين مختلفتين، تحويل غير موثّق).
- Why problematic: في تطبيق ELD خاضع لتنظيم 49 CFR، تكرار رقم تنظيمي في مكانين هو خطر امتثال مباشر: تصحيح `FmcsaConstants` لا يسري على `HosConfiguration` التي تحرّك `LocalStorageService.hosConfiguration` (والمخزّنة في `'hos_configuration'` — أي أن القيم القديمة تبقى في أجهزة المستخدمين).
- Violated principle: DRY؛ مصدر واحد للحقيقة التنظيمية.
- Current owner: `lib/core/config/hos_configuration.dart`
- Correct owner: `lib/core/constants/fmcsa_constants.dart` —|source واحد يُبنى منه `HosConfiguration.usa70_8()`.
- Consequences: خطر انحراف حدود القيادة على أجهزة مُرقّعة؛ وصعوبة المراجعة التنظيمية.
- Recommended correction: اجعل مصانع `HosConfiguration` تقرأ من `FmcsaConstants` (تحويلات صريحة `maxDrivingHours * 60`)، أو اجعل `FmcsaConstants` مشتقاً من `HosConfiguration`. وثّق وحدة `movingSpeedThresholdKmh` مقابل Mps.
- Related files: `lib/core/constants/fmcsa_constants.dart`, `lib/core/services/local_storage_service.dart:183-198`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-023: `UtcSyncService` بنية ميتة — لا مرجع خادمي ولا مستهلك
- Severity: MEDIUM
- Category: Maintainability
- Location: `lib/core/services/utc_sync_service.dart:5,15-32,35-49`; `lib/app/app_initializer.dart:22,82-83,92`
- Evidence:
```dart
  Future<void> syncWithUtc({DateTime? serverTime}) async {
    final now = DateTime.now();
    if (serverTime == null) {
      AppLogger.warning(
          'UTC sync skipped: no server reference time (device clock must not anchor trusted time)');
      return;
    }
```
- Current behavior: `AppInitializer` ينشئ `UtcSyncService` ويحقنه في `ProviderContainer` عبر `utcSyncServiceProvider.overrideWithValue(utcSync)` ثم يستدعي `await utcSync.syncWithUtc();` **بلا `serverTime`**. النتيجة: return فوري مع تحذير في كل إقلاع. و`_drift` يبقى `null` دائماً، فيصبح `syncedTime` و`utcNow` مجرد `DateTime.now()` + `.toUtc()`. **بحث في `lib/` وجد 0 استهلاك خارجي لـ`utcNow` أو `syncedTime`.**
- Why problematic: بنية كاملة (صنف + مزوّد + حقن في الـcontainer + استدعاء إقلاع) لا تفعل شيئاً. وهي توأم مع نظام `TimeAuthority` (CORE-008)، ما يضاعف الالتباس: القارئ يرى ثلاث خدمات زمنية في `core` اثنتان منها ميتتان.
- Violated principle: Dead code removal؛ SRP.
- Current owner: `lib/core/services/utc_sync_service.dart`
- Correct owner: لا مكان له — يُحذف، أو يُدمج في `TrustedTimeProvider` (المالك الوحيد للمراسي).
- Consequences: عبء إقلاع مضاعف، وضوضاء في السجلات (`AppLogger.warning` في كل إقلاع)، وطبقة زمنية ثالثة يدعها المطوّرون.
- Recommended correction: احذف `UtcSyncService` و`utcSyncServiceProvider` وسطر `overrideWithValue` من `app_initializer.dart:92`، واحذف `utcSync` من الحقول (22، 82-83). المرساة الخادمية يوفّرها `TimeDriftInterceptor` وحده.
- Related files: `lib/app/app_initializer.dart:22,82-83,92`, `lib/core/time/trusted_time_provider.dart`, `lib/backend/http/interceptors/time_drift_interceptor.dart:62`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-024: ابتلاع الأخطاء في التهيئة يقطع مسار الفشل
- Severity: MEDIUM
- Category: ErrorHandling
- Location: `lib/app/app_initializer.dart:29-35,71-78`; `lib/app/services/push_notification_service.dart:52-54,143-145`; `lib/app/services/quick_actions_initializer.dart:39-41`
- Evidence:
```dart
    try {
      await Firebase.initializeApp();
      AppLogger.info('Firebase initialized successfully');
    } catch (e) {
      AppLogger.warning(
          'Firebase initialization failed (App will continue without Firebase services): $e');
    }
```
```dart
      } on PlatformException {
        // permission denied or startup error
      }
```
- Current behavior: أربعة مواضع تبتلع الاستثناءات وتكمل: تهيئة Firebase، و`PushNotificationService.init`، و`_uploadToken`، واختصارات `quick_actions` (الذي يبتلع `PlatformException` **فارغاً بلا تعليق**). لا راية degraded mode، ولا مؤثر في الحالة، ولا مسار فشل ظاهر للواجهة.
- Why problematic: (1) العطل الذي يُبتلَع في الإقلاع لا يظهر في أي شاشة — السائق يرى تطبيقاً يعمل لكن لا إشعارات ولا استعادة. (2) `quick_actions_initializer.dart:39-41` يبتلع الاستثناء بصمت تام (`on PlatformException { }`)، فيفشل زر SOS بصمت. (3) لا يوجد تمييز بين فشل اختياري (Firebase) وفشل وظيفي.
- Violated principle: Fail loud on non-optional paths؛ قاعدة «لا تبتلع الاستثناء بلا أثر».
- Current owner: الملفات الأربعة أعلاه.
- Correct owner: `AppInitializer` يجب أن يُرجع **حالة تهيئة** (`AppInitReport`) يحمل أي خدمات معطوبة، ويعرضها في `about_page`/إشارة `AppFeedback`.
- Consequences: أخطاء إنتاج غير قابلة للتشخيص من داخل التطبيق؛ زر SOS قد لا يعمل دون أي مؤشر.
- Recommended correction: اجمع التحذيرات في `AppInitializer` كقائمة، مرّرها إلى `CriticalErrorApp` أو إلى شاشة إعدادات، وسجّل السبب. في `quick_actions` استعمل `AppLogger.error` على الأقل.
- Related files: `lib/main.dart:55-63`, `lib/core/utils/logger.dart:26-32`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-025: المنسّق يحمل سياسات HTTP وحدوداً تنظيمية داخل `Provider<void>`
- Severity: MEDIUM
- Category: SOLID
- Location: `lib/app/orchestrators/tracking_orchestrator.dart:15,28-67`
- Evidence:
```dart
final trackingOrchestratorProvider = Provider<void>((ref) {
  final notifier = ref.read(trackingStateProvider.notifier);
```
```dart
    if (isSpeedTrigger || isTimeTrigger) {
      lastTelemetrySent = now;
      lastSpeedSent = speed;

      final reading = TelemetryReading(
        driverId: DriverId(int.tryParse(auth.user!.id) ?? 0),
        speedMps: speed,
        engineOn: speed > 0,
      );

      ref.read(hardwareBackendProvider).sendTelemetry(reading).then((result) {
```
- Current behavior: `Provider<void>` يقوم بأربع مسؤوليات غير مترابطة: (1) ربط `isDrivingChecker`، (2) سياسة **إرسال** HTTP للـtelemetry (عتبة السرعة، فترة 30 ثانية، `FmcsaConstants`) وهي **حالة محلية قابلة للضياع** (`lastTelemetrySent`, `lastSpeedSent` داخل الإغلاق)، (3) تحويل `TelemetryReading` ووسم المالك بـ`int.tryParse(...) ?? 0`، (4) بدء/إيقاف التتبع آلياً عند تغيّر الحالة.
- Why problematic: (1) حالة الـthrottle عالقة داخل الإغلاق، فلا يمكن اختبارها ولا تعليلها ولا الاعتماد عليها. (2) `?? 0` في `DriverId` — إذا فشل `int.tryParse` فإن معرّف السائق يُرسَل الطلب بمعرّف `0` أي **لسائق آخر**؛ ولا يوجد رفض. (3) مزوّد بنوع `void` لا يمكن لأحد التحقق منه أو نسخه. (4) `Provider` يُعدم مرة واحدة عند الإقلاع ولا يُعاد إنشاؤه.
- Violated principle: SRP؛ Dependency Inversion (سياسة الاتصال بشبكة خارجة داخل منسّق فيزيائي)؛ Fail-fast بدل `?? 0`.
- Current owner: `lib/app/orchestrators/tracking_orchestrator.dart`
- Correct owner: (1) البصمة/العتبة ← `features/telemetry` أو `core/services` كخدمة `TelemetryThrottle` قابلة للاختبار؛ (2) تحويل `TelemetryReading` ← mapper في `backend/adapters`؛ (3) الإرسال ← `features/hardware` use-case؛ يبقى في المنسّق ربط الإشارات فقط.
- Consequences: استعابال محتمل فيTelemetry (معرّف `0`)، وصعوبة إثبات سلوك الإرسال في اختبار.
- Recommended correction: استخرج `class TelemetryBurstGate { bool shouldSend({required double speed, required DateTime now}); }` واختبرها وحدها، وارفض الطلب إن كان `driverId` غير قابل للتحليل. غيّر نوع المزوّد إلى `Provider<TelemetryOrchestratorHandle>` يحمل `dispose`.
- Related files: `lib/core/constants/fmcsa_constants.dart:7,13`, `lib/domain/hardware/telemetry_reading.dart`, `lib/domain/shared/value_objects.dart`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-026: جذر التطبيق يحمل آثار جانبيةpresentation ونصوصاً صلبة
- Severity: LOW
- Category: Maintainability
- Location: `lib/app.dart:49-64,55-61`
- Evidence:
```dart
    ref.listen<HosEngineResult>(hosStatusProvider, (previous, next) {
      if (next is HosEngineReady) {
        final prevStatus =
            (previous is HosEngineReady) ? previous.update.currentStatus : null;
        if (next.update.currentStatus == DutyStatus.driving &&
            prevStatus != DutyStatus.driving) {
          final feedbackContext = rootNavigatorKey.currentContext;
          if (feedbackContext != null) {
            AppFeedback.success(
              feedbackContext,
              'بدأت خدمة التتبع تلقائياً لتسجيل حالة القيادة',
            );
          }
        }
      }
    });
```
- Current behavior: `GoldenFeatherApp` (ConsumerWidget) يستمع لحالة HOS ليُظهر تنبيهاً، وفي نفس الملف نص عربي **غير مترجم** مضمّن (بينما `AppLocalizations` مستخدم في نفس الملف في السطر 82-83).
- Why problematic: (1) نص عربي صلب في جذر التطبيق — بينما التطبيق كامل الترجمة ويستخدم `l10n/app_localizations.dart`؛ سيظهر للمستخدم على الجهاز الإنجليزي. (2) منطق «متى أُعلم السائق» في الجذر لا في use-case أو `hos_provider` — يصعب اختباره ويعاد بناؤه في `tracking_orchestrator.dart:97-109` بنفس الشرط (`currentStatus == DutyStatus.driving && prevStatus != driving`) — **نفس القاعدة مكرّرة في مكانين**.
- Violated principle: SRP في الجذر؛ i18n completeness.
- Current owner: `lib/app.dart:49-64` (والتكرار في `tracking_orchestrator.dart:97-109`)
- Correct owner: مستخدمcase داخل `features/hos` يستمع ويصدر حدثاً؛ الجذر يربطه بـ`AppFeedback` فقط بنص مترجم.
- Consequences: نص غير مترجم؛ وقاعدة منطقية واحدة في مكانين قد تنحرف.
- Recommended correction: انقل النص إلى `l10n`، واستخرج شرط «الانتقال إلى قيادة» إلى دالة نقية مشتركة (مثل `enteredDriving(prev, next)`) يستعملها الطرفان.
- Related files: `lib/app/orchestrators/tracking_orchestrator.dart:97-109`, `lib/routes.dart:63` (`rootNavigatorKey` مستورد من `routes.dart` في `app.dart`)
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-027: تمرير كيان عبر `state.extra` بـcast غير محمي
- Severity: LOW
- Category: Architecture
- Location: `lib/routes/logs_routes.dart:37-40`
- Evidence:
```dart
          builder: (context, state) {
            final event = state.extra as LogEvent?; // تمرير الـ event كـ extra
            return EditLogPage(event: event);
          },
```
- Current behavior: `state.extra` هو `Object?` غير مُنمَّط؛ `as LogEvent?` يرمي `TypeError` إن مُرِّر أي شيء آخر (deep link، استعادة حالة، اختبار).
- Why problematic: مسار التنقل يعتمد على تمرير كائن حيّ عبر حاوية UI غير مُنمَّطة بدل `pathParam` (`AppRoutes.editLog = '/logs/:id/edit'` يحمل `:id` أصلاً لكنه غير مستخدم). أي محاولة لفتح الرابط مباشرة تسقط.
- Violated principle: Type safety on boundaries؛ لا Passing typed object through untyped channel.
- Current owner: `lib/routes/logs_routes.dart:37-40`
- Correct owner: النمط نفسه في `lib/routes/logs_routes.dart` مع `state.pathParameters['id']` ومصدر بيانات.
- Consequences: انهيار عند التنقل المباشر/الاستعادة.
- Recommended correction: استخدم `:id` من `state.pathParameters`، أو على الأقل `state.extra is LogEvent ? state.extra as LogEvent : null`، أو أضف `errorBuilder`.
- Related files: `lib/routes.dart:26`, `lib/features/logs/presentation/pages/edit_log_page.dart`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-028: `RouterNotifier` و`GoRouter` بلا مسار تفكيك
- Severity: LOW
- Category: Riverpod
- Location: `lib/routes.dart:55-61,66-72`
- Evidence:
```dart
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}

final rootNavigatorKey = GlobalKey<NavigatorState>();

/// تكوين GoRouter
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
```
- Current behavior: `RouterNotifier` يحمل مرجعاً لـ`Ref` ويستمع لـ`authStateProvider`، ولا يُستدعى `dispose()` له. `GoRouter` لا يُسجَّل له `ref.onDispose(router.dispose)` (الاعتماد Riverpod التلقائي على `dispose()` لا ينطبق لأن `Provider` بلا `autoDispose` يُعطَّل فقط عند إبطال صريح — وهو ما لا يحدث).
- Why problematic: نمط `ChangeNotifier` داخل `Ref` هو جسر يدوي؛ و`dispose` غير موجود يعني أن `listen` يستمر لو أُعيد بناء الـrouter يوماً ما. كما أن `AppRoutes.publicRoutes` يعتمد على `matchedLocation` الدقيق، فقد لا يطابق المسارات ذات المعاملات.
- Violated principle: proper lifecycle management for Riverpod/GoRouter bridge.
- Current owner: `lib/routes.dart:55-61`
- Correct owner: نفس الملف — لكن باستخدام `ref.listen` في مزوّد `Provider<RefreshNotifier>` مع `ref.onDispose`.
- Consequences: تسريب اشتراك (منخفض الأثر لأن المزوّد مدى الحياة).
- Recommended correction: اجعل `RouterNotifier` `@implements` عبر `ref.listen` داخل جسم المزوّد، وسجّل `ref.onDispose(router.dispose)`، واستخدم `state.matchedLocation` مع نمط بدل التطابق الحرفي (أو اجعل `publicRoutes`incluse prefixes).
- Related files: `lib/routes.dart:44-51,73-91`, `lib/main.dart:49-54`
- Confidence: POTENTIAL
--------------------------------------------------

### ISSUE CORE-029: إسقاط.payload صامت في `ApiResponse` يُنتج `data == null` بلا خطأ
- Severity: MEDIUM
- Category: ErrorHandling
- Location: `lib/core/network/api_response.dart:136-151,100-101`
- Evidence:
```dart
  static T? _parsePayload<T>(
    dynamic payload,
    T Function(dynamic)? parser,
  ) {
    if (payload == null) return null;

    if (parser != null) {
      return parser(payload);
    }

    if (payload is T) {
      return payload;
    }

    return null;
  }
```
- Current behavior: عند عدم تمرير `parser`، إن لم يكن `payload` من النوع `T` المتوقّع، يُعاد `null` **دون خطأ**. و`ApiClient._execute` يعيد `fp.Right(apiResponse)` دائماً في مسار 2xx:
```dart
        final apiResponse = ApiResponse.fromBody<T>(
          statusCode: response.statusCode ?? 0,
          rawBody: response.data,
          parser: parser,
        );

        return fp.Right(apiResponse);
```
  إذاً استجابة 200 بجسم من نوع خاطئ تُقرأكنجاح، ثم يفشل `parser`/الاستخدام لاحقاً خارج حدود الشبكة.
- Why problematic: كتم الفشل ينقله إلى طبقة أبعد (repositories/widgets)، حيث يُ.handler كـ`null` ويُقرأ كـ«لا توجد بيانات» — صامت تماماً. القاعدة المعلنة في نفس الملف (`:9-11` من `app_error.dart`) «No raw exceptions should escape» صامدة، لكن العكس لم يُفرض: **الأخطاء UASILE لا تُنتج `AppError`**.
- Violated principle: Fail fast at boundaries؛ لا `null` كقناة خطأ صامتة.
- Current owner: `lib/core/network/api_response.dart:136-151`
- Correct owner: نفس الملف — يجب أن يُنتج `ValidationError`/ServerError عبر `Result` بدل `null`.
- Consequences: تشخيصBug على الواجهة بدل الشبكة.
- Recommended correction: اجعل `_parsePayload` يرمي `FormatException` (ول��د في `mapDioException` كـ`server.malformedResponse`)، أو اجعل `fromBody` يُعيد `Either<AppError, ApiResponse<T>>`.
- Related files: `lib/core/network/api_client.dart:276-329`, `lib/core/network/error_mapper.dart:59-69`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-030: مسارانBuild نفس الصفحة
- Severity: LOW
- Category: Duplication
- Location: `lib/routes/home_routes.dart:21-26`
- Evidence:
```dart
        GoRoute(
          path: AppRoutes.status,
          name: 'status',
          builder: (context, state) => const StatusDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.hos,
          name: 'hos',
          builder: (context, state) => const StatusDashboardPage(),
        ),
```
- Current behavior: `AppRoutes.status = '/status'` و`AppRoutes.hos = '/hos'` يبنمان نفس الـWidget. ومع منطق `redirect` القائم على `matchedLocation` الدقيق، فإن كليهما خاص (ليس ضمن `publicRoutes`) فيمرّان بقاعدة التوجيه نفسها بلا فرق.
- Why problematic: ازدواج في مسمّى URL بلا فرق سلوكي؛ ويخلق لبساً في التحليلات (أيّهما «الصحيح»؟) وفي سجلّ الروابط المستخدَمة.
- Violated principle: DRY in navigation surface.
- Current owner: `lib/routes/home_routes.dart`
- Correct owner: مسار واحد، والآخر `redirect` إليه.
- Consequences:رابط ميت محتمل، وت-reporting موزّع.
- Recommended correction: اجعل `/hos` redirect إلى `/status`، أو احذف أحدهما من `AppRoutes`.
- Related files: `lib/routes.dart:23,35`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-031: جذر التركيب يركّب مستودعاً واحداً من نحو عشرة
- Severity: MEDIUM
- Category: Architecture
- Location: `lib/core/di/app_providers.dart:21-33`
- Evidence:
```dart
// ==========================================================================
// Auth Feature
// ==========================================================================


final traccarAuthRepositoryProvider = Provider<AuthRepository>((ref) {
```
- Current behavior: ملف يدّعي أنه «Composition Root for all Domain Repositories»، لكنه يحتوي مستودعاً واحداً. ملفات تركيب أخرى منتشرة عبر 10 مسارات داخل `features/*/data/providers/` (auth, codriver, dvir, hos/audit, hos/status_dashboard, inspection, logs, sync, tracking, vehicle).
- Why problematic: الحDijI غير مركزي فعلاً: الحد لمعرفة أي طبقة تركّب ماذا يتطلب تصفح `lib/` كاملاً. النتيجة تبعثر في اقتران كل feature بمستودعاته، وصعوبة استبدال implementations عالمياً.
- Violated principle: Composition Root centrality.
- Current owner: `lib/core/di/app_providers.dart` + 10 ملفات `features/**/data/providers/*`
- Correct owner: `lib/di/` واحد.
- Consequences: استبدال استراتيجي (مثلاً mock لكل المستودعات في اختبار) يتطلب N تعديلاً.
- Recommended correction: جمّع المزوّدات الـ10 في `lib/di/repositories_providers.dart`، واحذف `core/di` من النطاق.
- Related files: `lib/features/logs/data/providers/log_repository_providers.dart`, `lib/features/tracking/data/providers/tracking_providers.dart`, `lib/backend/providers/backend_providers.dart`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-032: `ApiClient` لا يثبّت اعتراضاته فيُنشأ غير صالح بذاته
- Severity: LOW
- Category: Architecture
- Location: `lib/core/network/api_client.dart:41-60`
- Evidence:
```dart
  ApiClient({
    required ApiConfig config,
    Dio? dio,
    this.maxRetries = 2,
    this.retryBackoff = const Duration(milliseconds: 400),
  })  : _config = config.normalized(),
        _dio = dio ?? Dio() {
    _dio.transformer = LenientJsonTransformer();
    ...
    // Logging lives in one interceptor (`RequestLogger`, debug only, redacted).
    // The former `LogInterceptor(requestBody: true, responseBody: true)` was a
    // second logger that printed the login body and every response twice.
  }
```
- Current behavior: `ApiClient` يهيّئ الترويسة والتحويل فقط. إضافة `AuthInterceptor` و`RequestLogger` و`TimeDriftInterceptor` تتم خارجاً في `lib/backend/providers/backend_network_providers.dart:56-71` عبر `client.dio`. لا يوجد مسار `ApiClient` مكتمل بذاته؛ والوصول exposes عبر `Dio get dio => _dio;`.
- Why problematic: من يبني `ApiClient` مباشرة (اختبار، أداة، feature جديد) يحصل على عميل **بلا مصادقة وبلا تثبيت وقت** — وهو في تطبيق ELD مikoالأسوأ: يُرسل طلبات بلا جلسة، ولا تثبيت الوقت. `// Not responsible for: Auth token injection (see interceptors)` في الترويسة يجعلها تبدو قراراً مقصوداً، لكن ليس فيها عقد يفرضه.
- Violated principle: Self-contained abstraction؛ Principle of Least Surprise in a compliance-critical path.
- Current owner: `lib/core/network/api_client.dart` + `lib/backend/providers/backend_network_providers.dart`
- Correct owner: `ApiClient` يقبل `List<Interceptor>` في المُنشئ (أو في `factory`) — فيظل التركيب فيComposition root دون أن يصبح سهل النسيان.
- Consequences: احتمال عميل شبكة غير مُهيأ في مسار جديد.
- Recommended correction: `ApiClient({required ApiConfig config, List<Interceptor> interceptors = const [], Dio? dio, ...})` ثم `dio.interceptors.addAll(interceptors)` في المُنشئ؛ واحتفظ بالتركيب في `backend_network_providers.dart`.
- Related files: `lib/backend/providers/backend_network_providers.dart:48-73`, `lib/core/network/core_providers.dart:13-14`
- Confidence: POTENTIAL
--------------------------------------------------

### ISSUE CORE-033: معرّفات تخزين ثابتة على مستوى الفئة قبل التهيئة + معرفة `Traccar` داخل `core`
- Severity: MEDIUM
- Category: Architecture
- Location: `lib/core/services/local_storage_service.dart:17-18,24`; `lib/core/data/models/user_model.dart:32-69,71-83`
- Evidence:
```dart
class LocalStorageService implements ServerConfigProvider {
  static Future<void>? _initFuture;
  static late SharedPreferencesWithCache _prefs;
  bool _initialized = false;
...
  SharedPreferencesWithCache get prefs => _prefs;
```
```dart
  factory UserModel.fromJson(Map<String, dynamic> json,
      {String? defaultEmail}) {
    // Traccar API returns id as int, name, email, administrator boolean
    final idValue = json['id']?.toString() ?? '';
...
    UserRole userRole = UserRole.fieldWorker;
    if (json['administrator'] == true) {
      userRole = UserRole.admin;
```
- Current behavior: (1) `LocalStorageService` يحفظ `SharedPreferencesWithCache` في **`static late`** مشترك بين كل النسخ في الـisolate، بينما التهيئة (`_initialized`, `_trackingStorage`, `_preferencesStorage`) **على مستوى النسخة** — فحال واحد مختلط. أي قراءة لـ`prefs` قبل `init()` ترمي `LateInitializationError`؛ وهذا بالضبط ما يصطاده `trusted_time_provider.dart:203-212` بـ`catch (_) { return null; }`. (2) `UserModel` — وهو `core/data/models` — يعرف صيغة `Traccar` السلكية (`administrator`, `disabled`, `name`)؛ كما أن معاملي `defaultEmail` غير مستخدمين تماماً.
- Why problematic: (1) الحالة الساكنة تجعل الخدمة غير آمنة في `build()` العابر أو عند بناء مُزوّد قبل التهيئة — وتُخفى بـcatch مطوّل في `trusted_time_provider`. (2) `core/data/models/user_model.dart` يعرف صيغة `features/tracking` عبر `fromJson` — عدم احترام حدود الطبقة (مرتبط بـCORE-004). (3) معاملان ميتان (`defaultEmail` في `fromJson` و`fromMetadata`).
- Violated principle: لا حالة ساكنة لحالات مُعتمَدة على التهيئة؛ Encapsulation of transport-format knowledge.
- Current owner: `lib/core/services/local_storage_service.dart:17-18`; `lib/core/data/models/user_model.dart`
- Correct owner: `lib/core/storage/` لـSharedPreferences؛ و`features/tracking/data/models` أو `backend/adapters/.../mappers` لـ`UserModel.fromJson` (صيغة Traccar).
- Consequences: `LateInitializationError` مُخفي؛ و`core` يحمل معرفة بـvendor.
- Recommended correction: (أ) اجعل `prefs` nullable مع `get isReady`، أو انقل `trustedTimeProvider` إلى ما بعد التهيئة؛ (ب) انقل `UserModel.fromJson` إلى mapper في `backend/adapters/eld_engine/mappers/` أو `features/tracking/data/models/`، واحذف `defaultEmail` إن لم يُستخدم.
- Related files: `lib/core/time/trusted_time_provider.dart:200-229`, `lib/app/app_initializer.dart:53-54`, `lib/core/services/tracking_config_storage_service.dart:101-107`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-034: كيان نطاقي يحمل عضواً دائماً `null`
- Severity: LOW
- Category: Maintainability
- Location: `lib/core/domain/entities/hos_models.dart:141-149`
- Evidence:
```dart
  Duration get duration => endTime.difference(startTime);
  double? get distanceKm {
    if (startLat != null &&
        startLon != null &&
        endLat != null &&
        endLon != null) {
      return null; // سيتم استخدامه لاحقا مع Haversine
    }
    return null;
  }
```
- Current behavior: `distanceKm` يفحص أربعة حقول ثم يعيد `null` في الحالتين — الفرعان متطابقان.
- Why problematic: كيان نطاقي يحمل عضواً ميتاً يوحي بأن المسافة متاحة. في سياق ELD (مسافة مقطوعة رهن 49 CFR) وجود عضو يُقرأ `distanceKm` ويُتوقع منه رقم — قد يدفع مطوّراً لاستخدامه لاحقاً.
- Violated principle: Dead code؛ لا false affordances في طبقة النطاق.
- Current owner: `lib/core/domain/entities/hos_models.dart:141-149`
- Correct owner: يُحذف، أو يُطبَّع فعلياً (Haversine) في `features/logs/domain`.
- Consequences:لا أثر تنفيذي؛ خطر فهم.
- Recommended correction: احذف `distanceKm`، أو نفّذ `Haversine` في خدمة حساب المسافة في `features/logs/domain` واعرضها.
- Related files: `lib/core/domain/entities/hos_models.dart:117-150`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-035: مرساة الزمن الموثوق تُحفظ في `SharedPreferences` عادي رغم وجود `SecureStoragePort`
- Severity: LOW
- Category: Security
- Location: `lib/core/time/trusted_time_provider.dart:203-224`
- Evidence:
```dart
  String? readAnchor() {
    try {
      return ref
          .read(localStorageProvider)
          .prefs
          .getString('trusted_time_anchor');
    } catch (_) {
      return null;
    }
  }

  void writeAnchor(String json) {
    try {
      ref
          .read(localStorageProvider)
          .prefs
          .setString('trusted_time_anchor', json)
          .ignore();
    } catch (_) {
```
- Current behavior: المرساة تُقرأ وتُكتب في preferences غير مشفّرة. وهي تقنياً بيانات غير حسّاسة (وقت + وقت الجهاز)، لكن **التلاعب بها هو بالضبط ما يزيح الزمن القانوني** — وهذا خندق أمني مباشرةً.
- Why problematic: التعديل اليدوي لـ`trusted_time_anchor` (root/backup restore) يزيح كل الطوابع المشتقة. كما أن `catch (_)` هنا يبتلع أي خطأ إما بالتزامن (CORE-024).
- Violated principle: الحياة الحرجة → تخزين محمي؛ والافتراضي الآمن.
- Current owner: `lib/core/time/trusted_time_provider.dart:203-224`
- Correct owner: `core/storage/ports/secure_storage_port.dart` — حتى وإن لم تكن سراً، هي **مدخل قانوني**.
- Consequences: قابلية تعديل مصدر التوقيت من خارج التطبيق.
- Recommended correction: انقل `trusted_time_anchor` إلى `SecureStoragePort`، وأضف تحققاً (HMAC على الجهاز أو على الأقل تحققاً من تق plausibility) عند الاستعادة.
- Related files: `lib/core/storage/storage_providers.dart:10-12`, `lib/core/time/time_authority.dart:20-35`
- Confidence: POTENTIAL
--------------------------------------------------

### ISSUE CORE-036: `isConnected` يبتلع الاستثناء ويعيد `false`
- Severity: LOW
- Category: ErrorHandling
- Location: `lib/core/services/bluetooth_service.dart:83-91`
- Evidence:
```dart
  /// Check if the device is currently connected via BLE.
  Future<bool> isConnected() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      AppLogger.error('Error checking isConnected', e);
      return false;
    }
  }
```
- Current behavior: فشل القناة الأصلية يُترجم إلى `false` (غير متصل) بعد تسجيل فقط، بينما بقية الدوال (`startScan`, `connect`, ...) **ترمي** `BluetoothException`.
- Why problematic: التوحيد على مستوى الصنف منكسر: هذا العضو وحده يبتلع. المستدعي لا يستطيع التمييز بين «غير متصل فعلاً» و«القناة الأصلية معطوبة» — وهذا تمييز مهم لتطبيق ELD (قد يمنع التتبع تلقائياً بصمت).
- Violated principle: اتساق العقد على مستوى الصنف؛ Fail-loud.
- Current owner: `lib/core/services/bluetooth_service.dart:83-91`
- Correct owner: نفس الملف — إمّا يرمي `BluetoothException` كبقية الأعضاء، أو يُرجع نتيجة مُصنَّفة (`BluetoothStatus`).
- Consequences: فشل صامت في فحص الاتصال.
- Recommended correction: اجعلها ترمي `BluetoothException(e.code, ...)` كبقية دوال الصنف، أو وثّق الاستثناء صراحة.
- Related files: `lib/core/services/bluetooth_service.dart:47-80`, `lib/core/network/core_providers.dart:16-20`
- Confidence: CONFIRMED
--------------------------------------------------

### ISSUE CORE-037: تكرار داخل منسّق الوقت
- Severity: LOW
- Category: Duplication
- Location: `lib/core/time/time_formatter.dart:7-14,37-44`
- Evidence:
```dart
  static String formatTime12Hour(DateTime time) {
    final h24 = time.hour;
    final h12 = h24 > 12 ? h24 - 12 : (h24 == 0 ? 12 : h24);
    final h = h12.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final period = h24 < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
```
```dart
  static String formatTimeOfDay12Hour(TimeOfDay time) {
    final h24 = time.hour;
    final h12 = h24 > 12 ? h24 - 12 : (h24 == 0 ? 12 : h24);
    final h = h12.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final period = h24 < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
```
- Current behavior: الدالتان متطابقتان سطرياً عدا نوع المُدخل. (`formatCurrentTime12Hour` ثالثة بنفس النواة + ثوانٍ.)
- Why problematic: ثلاث نسخ من نفس الخوارزمية؛ تقسيم `int` بلا حد أعلى (لا تحقّق من أن `hour` ضمن 0..23).
- Violated principle: DRY.
- Current owner: `lib/core/time/time_formatter.dart`
- Correct owner: دالة داخلية `_format12(int hour, int minute, int? second)`.
- Consequences: لا أثر تنفيذي؛ تكلفة صيانة صغيرة.
- Recommended correction: ادمج الثلاث في دالة واحدة تدعم أرقام الثواني الاختيارية.
- Related files: `lib/core/utils/duration_format.dart` (نفس النمط: موحّد لكن بمحتوى مختلف — لا تعارض)
- Confidence: CONFIRMED
--------------------------------------------------

## C. Cross-file observations within this group

**(1) ما بدا خطراً وانكشف سليماً — يُوثَّق صراحةً:**

- **لا يوجد تكرار في الاعتراضات.** رغم أن العنوان يوحي باحتمال، فقد تحققت: `ApiClient` لا يضيف أي `Interceptor` (`lib/core/network/api_client.dart:41-60`)، والإضافات الثلاثة (`AuthInterceptor`, `RequestLogger`, `TimeDriftInterceptor`) تُضاف مرة واحدة في `lib/backend/providers/backend_network_providers.dart:56-71`. لا ازدواج. (**مهاكلة** هي أن `ApiClient` غير صالح بذاته — CORE-032 — لا التكرار.)
- **لا يوجد `Dio` مُنشأ في أكثر من مكان.** بحث في كامل `lib/` وجد `Dio()` واحداً فقط: `lib/core/network/api_client.dart:47` (`_dio = dio ?? Dio()`). أفضل من المتوقع.
- **`baseUrl` غير مكتوب في `core/network` بشكل صريح.** `ApiConfig` يقرأ من `String.fromEnvironment` ثم `AppEnvironmentConfig` (`lib/core/network/api_config.dart:46-53`)؛ و`backend_network_providers.dart:30-39` يضيف `/api`. لا تكرار بين الملفين.
- **لا يوجد `print()` في `lib/`.** البحث عن `^\s*print(` أعاد صفر نتيجة. `AppLogger` هو القناة الوحيدة.
- **إعادة التصدير من `core/network/core_providers.dart:13-14`** (`apiClientProvider`, `traccarNativeClientProvider`) هي محاولة **مقصودة**prevent_features من استيراد `backend/` مباشرة. النية معمارية صحيحة؛ الخلل أن التنفيذ نصّفه تحت `core/` (CORE-004).
- **`app_error.dart` ليس dumping ground.** 14 فئة، كلها متجانسة التصنيف (شبكة/مصادقة/تحقق/صلاحية/العثور/تعارض/قدرة/خادم/زمن/تخزين/مزامنة/ملكية/غير معروف). التكرار الميكانيكي في `_copyWith` هو **أثر ثانوي لكون الصنف مغلقاً ولكل فئة حقولها**، لا ازدواج تصميمي. المشكلة ليست الحجم بل **ثلاثة أنواع منها لا تُستخدم** (CORE-009) و**ازدواج النظام مع `Failure`** (CORE-010).
- **`network_guard.dart` و`user_facing_message.dart` و`api_response.dart` و`ports/secure_storage_port.dart` و`runtime_selection.dart`** كلّها مصمَّمة جيداً وتستحق الثناء — موثّقة بالعقد، نقية، وقابلة للاختبار.

**(2) الأنماط العرضية عبر المجموعة:**

- **`// ignore_architecture` على الاستيرادات التي تعبر حدود الطبقات** في `core/di/app_providers.dart`، و`core/di/auth_local_data_source_provider.dart`، و`core/config/server_config_store.dart`، و`core/network/api_client.dart`، و`core/network/error_mapper.dart`، و`core/network/lenient_json_transformer.dart` — بينما `core/providers/driver_rules_provider.dart` و`core/events/eld_events_provider.dart` (الأسوأ) **بلا علامة أصلاً**. هذا نمط بحد ذاته: الانتهاكات «المعلَنة» أخفّ خطورةً ظاهرياً من غير المعلَنة لأنها توحي بأنها روجعت.
- **حالة ثابتة عامة** في موضعين فقط: `SessionEpoch._value` (`lib/core/session/session_epoch.dart:19`) — مقصود وموثّق، وقابل للاختبار؛ و`_defaultNetworkInfo` (`lib/core/utils/repository_helper.dart:7`) — غير مقصود ولا مُدار (CORE-017).
- **`catch (_)` / `catch (e)` يبتلع بصمت** في: `network_info.dart:42` (مع تعليق)، `server_config_store.dart:36`، `trusted_time_provider.dart:82,121,209,221`، `user_preferences_storage_service` لا، `app_date_utils.dart:12` (fallback)، `quick_actions_initializer.dart:39-41` (فارغ تماماً — **الوحيد الفارغ**)، `bluetooth_service.dart:88`. أربعة منها في مسار زمني/قانوني.
- **خمس مفاتيح preferences معرَّفة حرفياً في أكثر من مكان**: `'url'`, `'id'`, `'language'`, `'theme'`, `'hos_configuration'`, `'trusted_time_anchor'` (CORE-020، CORE-035).
- **ثلاث خدمات في `core/services` متشابهة الغرض**: `tracking_config_storage_service`، و`user_preferences_storage_service` (كلاهما فوق `SharedPreferencesWithCache`)، و`local_storage_service` (واجهة facade لهما). التقسيم مقصود لكنه ينتج استيراداً دائرياً (CORE-018).
- **`app/` يستورد `core/` و`features/` و`backend/` بحرية** — وهذا **مقبول**: `app/` هي طبقة التطبيق (composition + orchestration)، والاعتماد من أعلى إلى أسفل مسموح على `features`. المشكلة الوحيدة: `app/` يبني كائنات يدوياً (CORE-005) ويستخدم `HttpClient` خاماً (CORE-016).

**(3) خريطة الاعتماد الفعلية المستخرجة (بدقة):**

```
lib/core/  ──▶  features/**        (5 استيرادات: driver_rules_provider, eld_events_provider,
                                    di/app_providers, di/auth_local_data_source_provider,
                                    + widgets/connection_status_indicator خارج النطاق)
lib/core/  ──▶  backend/           (server_config_store عبر domain/config؛ app_providers؛ core_providers re-export)
lib/app/   ──▶  features/**, core/**            (مسموح)
lib/routes/ ──▶ features/**/presentation/pages  (مسموح)
lib/core/  ──▶  l10n/              (user_facing_message, localization_helper, context_extensions)
lib/core/  ──▶  core/theme/        (context_extensions, design_system) — جسر معلن في design_system.dart:1-6
```

**(4) المسارات الميتة المؤكدة بالبحث النصي:**
- `core/error/exception.dart`: 7 فئات، موقع `throw` واحد في `lib/` كله.
- `AppConstants`: 7 ثوابت تخزين + 3 ثوابت إعدادات + `maxRetryAttempts`, `retryDelay`, `syncInterval`, `maxOfflineInspections`, `maxLocalImages` — الاستعمال الوحيد المؤكد `appVersion`.
- `StorageConstants.serverUrl`, `deviceId`, `eventLogs`: غير مستخدمة.
- `core/network/core_providers.dart:40-42` (`secureStorageProvider` من نوع `FlutterSecureStorage`): غير مستخدم.
- `core/services/utc_sync_service.dart`: لا مستهلك لـ`utcNow`/`syncedTime`.
- `TimeUnavailableError`, `StorageError`, `UnsupportedCapabilityError`: لا بنّاء واحد.
- `TrustLevel`/`trustLevel`: لا قارئ خارج ملف التعريف.
- `UserModel.fromJson({String? defaultEmail})`, `fromMetadata({String? defaultEmail})`: المعاملان غير مستخدمين.
- `location_point.dart` (12 سطراً): لم أتحقق من وجود منافس لها في features (خارج نطاق القراءة) — **يقتصر الانتباه عليه**.
- `lib/backend/http/api_config.dart` و`lib/backend/http/api_response.dart`: **ملفان ميتان كلياً — كل محتواهما معلَّق بـ`//`**، رغم أن ترويسة الملفين تقول «DEPRECATED». (خارج نطاق القراءة — لُوحظا كدليل مساند.)

---

## D. List of every file you read (proof of coverage)

**70 ملفاً — 4,812 سطراً غير فارغ — كلها مقروءة بالكامل.**

### Entry points & app shell (3)
1. `lib/main.dart` (64 / 54)
2. `lib/app.dart` (114 / 103)
3. `lib/routes.dart` (100 / 86)

### `lib/app/` (4)
4. `lib/app/app_initializer.dart` (119 / 101)
5. `lib/app/orchestrators/tracking_orchestrator.dart` (110 / 96)
6. `lib/app/services/push_notification_service.dart` (156 / 137)
7. `lib/app/services/quick_actions_initializer.dart` (77 / 68)

### `lib/routes/` (5)
8. `lib/routes/account_routes.dart` (46 / 44)
9. `lib/routes/auth_routes.dart` (39 / 37)
10. `lib/routes/dvir_routes.dart` (33 / 31)
11. `lib/routes/home_routes.dart` (38 / 36)
12. `lib/routes/logs_routes.dart` (43 / 41)

### `lib/core/network/` (9)
13. `lib/core/network/api_client.dart` (345 / 318)
14. `lib/core/network/api_config.dart` (109 / 93)
15. `lib/core/network/api_response.dart` (157 / 138)
16. `lib/core/network/error_mapper.dart` (228 / 204)
17. `lib/core/network/lenient_json_transformer.dart` (34 / 30)
18. `lib/core/network/network_guard.dart` (29 / 27)
19. `lib/core/network/network_info.dart` (57 / 49)
20. `lib/core/network/core_providers.dart` (66 / 56)

### `lib/core/error/` (4)
21. `lib/core/error/app_error.dart` (565 / 504)
22. `lib/core/error/exception.dart` (77 / 57)
23. `lib/core/error/failure.dart` (136 / 113)
24. `lib/core/error/user_facing_message.dart` (99 / 92)

### `lib/core/result/` (1)
25. `lib/core/result/result.dart` (104 / 86)

### `lib/core/config/` (5)
26. `lib/core/config/app_environment.dart` (106 / 90)
27. `lib/core/config/hos_configuration.dart` (99 / 93)
28. `lib/core/config/runtime_selection.dart` (61 / 53)
29. `lib/core/config/server_config_provider.dart` (8 / 7)
30. `lib/core/config/server_config_store.dart` (79 / 67)

### `lib/core/di/` (3)
31. `lib/core/di/app_providers.dart` (33 / 25)
32. `lib/core/di/auth_local_data_source_provider.dart` (11 / 9)
33. `lib/core/di/id_generator_provider.dart` (6 / 5)

### `lib/core/providers/` + `lib/core/session/` (2)
34. `lib/core/providers/driver_rules_provider.dart` (24 / 21)
35. `lib/core/session/session_epoch.dart` (31 / 28)

### `lib/core/storage/` (3)
36. `lib/core/storage/storage_providers.dart` (12 / 10)
37. `lib/core/storage/adapters/flutter_secure_storage_adapter.dart` (29 / 21)
38. `lib/core/storage/ports/secure_storage_port.dart` (17 / 13)

### `lib/core/services/` (6)
39. `lib/core/services/bluetooth_service.dart` (97 / 83)
40. `lib/core/services/local_database_service.dart` (31 / 26)
41. `lib/core/services/local_storage_service.dart` (225 / 190)
42. `lib/core/services/tracking_config_storage_service.dart` (107 / 98)
43. `lib/core/services/user_preferences_storage_service.dart` (40 / 32)
44. `lib/core/services/utc_sync_service.dart` (50 / 44)

### `lib/core/time/` (5)
45. `lib/core/time/monotonic_time_authority.dart` (56 / 50)
46. `lib/core/time/time_authority.dart` (70 / 61)
47. `lib/core/time/time_authority_provider.dart` (31 / 29)
48. `lib/core/time/time_formatter.dart` (45 / 41)
49. `lib/core/time/trusted_time_provider.dart` (230 / 197)

### `lib/core/utils/` (8)
50. `lib/core/utils/app_date_utils.dart` (16 / 15)
51. `lib/core/utils/duration_format.dart` (21 / 20)
52. `lib/core/utils/id_generator.dart` (12 / 9)
53. `lib/core/utils/localization_helper.dart` (52 / 50)
54. `lib/core/utils/logger.dart` (37 / 31)
55. `lib/core/utils/provider_cache.dart` (18 / 16)
56. `lib/core/utils/repository_helper.dart` (61 / 58)
57. `lib/core/utils/status_color_helper.dart` (8 / 7)

### `lib/core/events/` + `extensions` + `localization` + design system (5)
58. `lib/core/events/app_events.dart` (18 / 15)
59. `lib/core/events/eld_events_provider.dart` (18 / 15)
60. `lib/core/extensions/context_extensions.dart` (112 / 94)
61. `lib/core/localization/locale_provider.dart` (41 / 34)
62. `lib/core/design_system.dart` (19 / 17)

### `lib/core/constants/` (4)
63. `lib/core/constants/app_constants.dart` (53 / 45)
64. `lib/core/constants/channel_constants.dart` (5 / 5)
65. `lib/core/constants/fmcsa_constants.dart` (41 / 30)
66. `lib/core/constants/storage_constants.dart` (15 / 13)

### `lib/core/data/` + `lib/core/domain/` (4)
67. `lib/core/data/models/user_model.dart` (99 / 91)
68. `lib/core/domain/entities/hos_models.dart` (316 / 278)
69. `lib/core/domain/entities/location_point.dart` (12 / 11)
70. `lib/core/domain/entities/user.dart` (77 / 64)

---

### مُلحق — ملفات خارج النطاق قُرئت كدليل مساند (لا تدخل في التغطية)

قرأتُ هذه للتحقق من ادعاءات عبر-الملفات فقط، ولم أُدرجها في قائمة التغطية ولا في مخرجات Per-file:

- `lib/backend/providers/backend_network_providers.dart` (82 سطراً) — ضروري لإثبات CORE-005 (نسختا `TrackingService`) وCORE-032 (تثبيت الاعتراضات خارج `ApiClient`) وCORE-016.
- `lib/backend/http/interceptors/auth_interceptor.dart` (144) — للتحقق من عدم تكرار الاعتراضات وسلوك 401/epoch.
- `lib/backend/http/interceptors/request_logger.dart` (134) — للتحقق من وجود إخفاء (`_redactSensitiveData`) بدل `print()`.
- `lib/backend/http/interceptors/time_drift_interceptor.dart` (67) — للتحقق من أن المرساة الخادمية تمر عبر `Date` header فقط.
- `lib/features/tracking/data/services/tracking_service.dart:190-204` — للتحقق من تعريف `trackingServiceProvider` الثاني.
- `lib/features/tracking/data/providers/tracking_providers.dart` (51) — للتحقق من `trackingServiceFullProvider`.
- `lib/features/auth/data/datasources/auth_local_data_source.dart` (مقتطفات بالبحث) — للتحقق من أن التوكن في `FlutterSecureStorage` لا في preferences.
- `lib/backend/http/api_config.dart`, `lib/backend/http/api_response.dart` (7 لكلٍّ) — ملفان ميتان (محتواهما تعليقات فقط).
- `analysis_options.yaml`, `.gitignore`, `.env`, `.env.example`, `.env.test` — للتحقق من CORE-004 وCORE-015.

### التحقق المتقاطع المنفَّذ

| ما دُعي في النطاق | نتيجة البحث الفعلي |
|---|---|
| `Dio()` في أكثر من مكان | 1 فقط: `core/network/api_client.dart:47` |
| اعتراضات مكرّرة بين `api_client` و`backend/http/interceptors` | 0 — التقسيم صحيح (لكن `ApiClient` غير مكتمل بذاته، CORE-032) |
| `core/` يستورد `features/` | 5 ملفات (CORE-001، CORE-002، CORE-003 ×2) |
| `print(` في `lib/` | 0 |
| `throw <X>Exception` من `core/error/exception.dart` | 1 فقط في كامل `lib/` |
| `TrustLevel` / `trustLevel` مستهلَك | 0 خارج ملف التعريف |
| بنّاءو `TimeUnavailableError` / `StorageError` / `UnsupportedCapabilityError` | 0 |
| بنّاءو `ConflictError` / `ValidationError` | مستخدَمان في `core/network/error_mapper.dart` |
| مستهلكو `utcNow` / `syncedTime` | 0 خارج `utc_sync_service.dart` |
| الاستيراد من `core/result/result.dart` | 35 ملفاً — العقد مُستخدم فعلاً، لكن مع تسرّب إلى `Failure` (CORE-010) |
| مستهلكو `guardedNetwork` / `executeWithHandling` | 39 استدعاءً في 6 مستودعات — كلاهما حيّ |
| `.env` متتبَّعة في git؟ | نعم: `git ls-files` يُرجع `.env`, `.env.example`, `.env.test` |

---

## ملخص تنفيذي

**الأخطر (4):**
1. **CORE-006** — ساعة الجهاز (`MonotonicTimeAuthority`) هي المزوّد الافتراضي الذي يوقّع أحداث `SyncEngine` القانونية، و`TrustLevel` لا يقرأه أحد. الحظر المكتوب في `app_initializer.dart:98-100` طُبِّق على `UtcSyncService` فقط، لا على المزوّد المستهلَك فعلياً.
2. **CORE-016** — رفع توكن الإشعارات يتجاوز `ApiClient`/`Dio` كلياً عبر `HttpClient` خام، بلا مصادقة، بلا مسار endpoint، مع تسريب connection pool.
3. **CORE-005** — كائنان حيّان من `TrackingService`، أحدهما يتجاهل منطق `mock` فيذهب إلى Traccar حقيقي في بيئة الاختبار.
4. **CORE-003 / CORE-001 / CORE-002** — `core/di` يستورد تنفيذ `features/auth/data`، و`core/providers` يستورد `features/account/presentation`، و`core/events` يستورد `features/tracking/data`.

**الأهم بنيوياً:** **CORE-004** — لا يوجد أي lint للطبقات؛ 19 تعليق `// ignore_architecture` لا تفعل شيئاً لأن `analysis_options.yaml` لا يعرّف قاعدة اسمها `architecture`. هذا ما يسمح ببقاء العشرة أعلاه.

**ما هو سليم فعلاً (يُوثَّق لمنع الإصلاح الزائد):** `Dio` واحد في المشروع، لا اعتراضات مكرّرة، لا `print()`، التوكن في `FlutterSecureStorage`، `network_guard.dart`/`user_facing_message.dart`/`runtime_selection.dart`/`secure_storage_port.dart` مصمَّمة بإتقان، و`app_error.dart` ليس dumping ground رغم حجمه.

**العدد الإجمالي:** 37 ملاحظة مُصنَّفة — **8 HIGH**، **19 MEDIUM**، **10 LOW**؛ منها **32 CONFIRMED** و**5 POTENTIAL**. التغطية: **70 ملفاً / 4,812 سطراً غير فارغ** في المجموعة.
