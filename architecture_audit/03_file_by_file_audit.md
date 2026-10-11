# 03 — التقرير التفصيلي لكل ملف (File-by-File Audit)

> كل كتلة أدناه ناتجة عن قراءة **كاملة** لملف المصدر. الحقل Architectural status حكم المفتش على الملف ككل.
> رموز الملاحظات (مثل HL-12) تُفصَّل في 11_issue_registry.md، والتفاصيل الكاملة (Evidence + الأدلة) في _raw/group_*.md.

**إجمالي الملفات المفحوصة في هذا التقرير: 395 ملف Dart مكتوب يدوياً (100% من غير المولّد).**

---

# المجموعة (أ): البنية التحتية — `lib/main.dart`, `lib/app.dart`, `lib/routes.dart`, `lib/routes/**`, `lib/core/**` (عدا theme/widgets)

> المصدر: _raw/group_core.md — القسم A.

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


---

# المجموعة (أ-٢): نظام التصميم والعناصر المشتركة — `lib/core/theme/**`, `lib/core/widgets/**`

> المصدر: _raw/group_core_ui.md — القسم A.

## A. Per-file findings

### `lib/core/theme/app_colors.dart` (155 lines, non-empty 112)
- Actual responsibilities: رموز `Color(0x…)` للهوية (ذهبي/أسود)، عائلات تباين الحالات (نص فاتح/داكن/خلفيات)، المحايدات، وألوان الوضع الداكن، مع دوال `xxxFor(Brightness)`.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-007 (مُستهلَك كمرجع)، CUI-013 (الجهة المقابلة)

### `lib/core/theme/app_decorations.dart` (71 lines, non-empty 64)
- Actual responsibilities: مصانع `BoxDecoration` المشتركة (`card` / `tinted` / `solid` / `band` / `outlined`). تستهلك `AppColors` + `AppRadius` + `AppShadows` فقط.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-009 (لم يُستعمل في `eld_card.dart`)

### `lib/core/theme/app_radius.dart` (31 lines, non-empty 22)
- Actual responsibilities: تسعة رموز زوايا (`button`, `card`, `pill`, `badge`, …) بلا أي استيراد.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: none

### `lib/core/theme/app_shadows.dart` (28 lines, non-empty 25)
- Actual responsibilities: رمزان للظلال (`card`, `raised`)، مع قرار تصميمي موثَّق (إخفاء الظل في الوضع الداكن).
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-006 (سلوك موازٍ في `app_feedback.dart` يتجاهله)

### `lib/core/theme/app_spacing.dart` (18 lines, non-empty 16)
- Actual responsibilities: سلّم المسافات + `screenPadding` / `cardPadding` / `buttonHeight` / `dividerHeight` / `iconSize`.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-018 (غير مُحترَم في `app_status_pill.dart`)

### `lib/core/theme/app_styles.dart` (244 lines, non-empty 234)
- Actual responsibilities: `ThemeExtension<AppStyles>` بستة عشر نمطاً دلالياً، مبنيّة من `AppTypography` + `AppColors` عبر `fromBrightness`، مع `copyWith` و`lerp` صحيحين.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-018 (`fontSize: 18` مكتوبة يدوياً)، CUI-020 (دالتا توافق ميّتة)

### `lib/core/theme/app_theme.dart` (222 lines, non-empty 211)
- Actual responsibilities: `ThemeData light` و`ThemeData dark` كاملان (ColorScheme، AppBar، Card، خمسة أنواع أزرار، InputDecoration، SnackBar، Divider، BottomNav، Radio).
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-007
- **لا توجد أي قيم بيئة ولا نقاط نهاية ولا ألوان ذات دلالة تنظيمية** — كل الألوان هوية/محايدة/حالات عامة. مُجيب على السؤال 6: **لا مخالفة في هذا الجانب**.

### `lib/core/theme/app_theme_provider.dart` (48 lines, non-empty 40)
- Actual responsibilities: `StateNotifierProvider<ThemeModeNotifier, ThemeMode>` + **ترحيل بيانات من `SharedPreferences` القديم** + استدعاء `LocalStorageService`.
- Declared layer / actual layer: معلن كـ theme state -> فعلياً **theme state + data migration + two storage backends**.
- Architectural status: **MODERATE**
- Issue IDs: CUI-008

### `lib/core/theme/app_typography.dart` (75 lines, non-empty 67)
- Actual responsibilities: سلّم الخطوط + `TextTheme` فاتح/داكن من مصدر واحد (`_base` ثم `_colored`).
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-020 (`fontFamilyIOS` رمز ميّت)، CUI-018 (مُتجاوَز في widgets)

### `lib/core/theme/press_feedback.dart` (34 lines, non-empty 30)
- Actual responsibilities: `InkRipple.splashFactory`، مولّد `overlayColor` حسب حالة pressed/hovered/focused، `pressed()` للدمج، وحبرَي `ink` / `inkOnDark`.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-011 (مُتجاوَز في `app_button.dart`)، CUI-014 (مُتجاوَز في `eld_info_row.dart`)، CUI-007 (رمزَي حبر خارج `AppColors`)

### `lib/core/widgets/app_button.dart` (194 lines, non-empty 174)
- Actual responsibilities: زر موحّد بحالات pressed/disabled/loading، بأشكال Stadium، وتطبيق `AppStyles.button`.
- Declared layer / actual layer: core/design-system -> core/design-system مع **تسرّب نوايا ELD في الـAPI**.
- Architectural status: **MODERATE**
- Issue IDs: CUI-003، CUI-011، CUI-018

### `lib/core/widgets/app_feedback.dart` (116 lines, non-empty 104)
- Actual responsibilities: قناة إشعار عبر `OverlayEntry` مع `Dismissible` + `GestureDetector` + **مؤخّر ذاتي الإزالة 3 ثوانٍ** + **متغير عام ثابت `_activeEntry`**.
- Declared layer / actual layer: معلن كـ shared widget -> فعلياً **خدمة عرض عامة داخل مجلد widgets**.
- Architectural status: **MODERATE**
- Issue IDs: CUI-006
- مُجيب على السؤال 4: **لا نصوص مستخدم مُشفّرة داخل الملف** (يستقبل `message` من المستدعي)، لكن **يتجاوز `snackBarTheme`** المعرَّف في `app_theme.dart:141-151` ويستخدم قيم بصرية مُشفّرة.

### `lib/core/widgets/app_signature_canvas.dart` (232 lines, non-empty 218)
- Actual responsibilities: لوحة توقيع + غلاف `FormField` (`AppSignatureFormField`). **لا قواعد عمل، ولا حفظ، ولا شبكة، ولا إدخال/إخراج بيانات** — تحقّقت من الملف كاملاً (232 سطراً).
- Declared layer / actual layer: core/shared-widget -> core/shared-widget (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-012
- **COMPLIANT مع السؤال 8**: لا يتجاوز العرض. ومُعرَّف بالكامل (`loc.drawYourSignatureHere`, `loc.clearSignature` في السطرين 135 و172).

### `lib/core/widgets/app_status_badge.dart` (96 lines, non-empty 89)
- Actual responsibilities: شارة حالة عامة بأربعة أنواع (`success/error/warning/info`) + اختيار زوج تباين حسب `Brightness`. **دلالات عامة لا تعني HOS.**
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-010، CUI-018 (`fontSize: 11`)، CUI-002 (مُتجاوَز داخل core نفسه)
- **COMPLIANT مع السؤال 2**: لا قواعد HOS ولا عتبات تنظيمية.

### `lib/core/widgets/app_status_pill.dart` (53 lines, non-empty 49)
- Actual responsibilities: شارة صغيرة (أيقونة + نص) بخلفية مشتقّة من لون المقدمة عبر `AppDecorations.tinted`.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-010، CUI-018، CUI-016 (مُعاد تنفيذها يدوياً في `active_defects_section.dart`)

### `lib/core/widgets/app_text_field.dart` (125 lines, non-empty 121)
- Actual responsibilities: غلاف `TextFormField` يقرأ `theme.inputDecorationTheme` ويمرّر كل خصائصه. لا يستورد `AppColors` إطلاقاً — يعتمد على الثيم.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-016 (يُعاد تنفيذه بشكل مسطّح في `DvirFlatTextField`)
- **COMPLIANT مع السؤال 7**: لا نصوص مُشفّرة إطلاقاً — كلها معاملات.

### `lib/core/widgets/connection_status_indicator.dart` (101 lines, non-empty 92)
- Actual responsibilities: `ConsumerWidget` يراقب مزوّد تتبّع حيّ، **ينتقل إلى `AppRoutes.connection`**، ويبني شارة حالة يدوياً.
- Declared layer / actual layer: معلن كـ shared widget -> فعلياً **core widget مربوط ب-feature domain + الموجّه العام**.
- Architectural status: **CRITICAL**
- Issue IDs: CUI-001، CUI-002، CUI-016

### `lib/core/widgets/critical_error_app.dart` (58 lines, non-empty 55)
- Actual responsibilities: تطبيق طوارئ كامل (`MaterialApp` متداخل) يُعرض عند فشل التهيئة في `main.dart:58`.
- Declared layer / actual layer: معلن كـ shared widget -> فعلياً **root application + شاشة طوارئ**.
- Architectural status: **MODERATE**
- Issue IDs: CUI-005

### `lib/core/widgets/dashed_line_painter.dart` (24 lines, non-empty 21)
- Actual responsibilities: `CustomPainter` يرسم خطاً متقطعاً أفقياً بلون مُمرَّر.
- Declared layer / actual layer: core/design-system -> core/design-system (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-015

### `lib/core/widgets/eld_card.dart` (41 lines, non-empty 38)
- Actual responsibilities: `Card` themed مع `InkWell`. **يستهلك `child` المُمرَّر فقط — لا منطق ELD إطلاقاً.**
- Declared layer / actual layer: core/shared-widget -> core/shared-widget (مطابق؛ البادئة `Eld` تسمية فقط)
- Architectural status: **MINOR**
- Issue IDs: CUI-009، CUI-017
- **COMPLIANT مع السؤال 2**.

### `lib/core/widgets/eld_date_paginator.dart` (73 lines, non-empty 69)
- Actual responsibilities: شريط تنقّل بين تاريخين (سابق/تالٍ) مع مؤشّر تحميل. **يستهلك `dateLabel` و`canGoOlder/Newer` كمعاملات — لا يقيّم أي تاريخ ولا يعبر منتصف الليل.**
- Declared layer / actual layer: core/shared-widget -> core/shared-widget مع **تسريب رمز دلالي خاص بمعاينة التفتيش**.
- Architectural status: **MINOR**
- Issue IDs: CUI-017، CUI-021
- **COMPLIANT مع السؤال 2** (لا منطق نطاق ولا HOS).

### `lib/core/widgets/eld_events_table.dart` (187 lines, non-empty 178)
- Actual responsibilities: جدول أحداث من ستّة أعمدة، يستقبل `List<EldTableRow>` وكل حقوله `String` جاهزة. **صفر استيراد لـ domain، صفر حساب، صفر عتبة.**
- Declared layer / actual layer: core/shared-widget -> core/shared-widget (شكل جدول RODS مبسّط)
- Architectural status: **MINOR**
- Issue IDs: CUI-017، CUI-019
- **COMPLIANT مع السؤال 2** (يرسم البيانات المُمرَّرة فقط). ومُعرَّف بالكامل (`loc.time/status/location/odom/eng/src/noData`).

### `lib/core/widgets/eld_graph_grid.dart` (348 lines, non-empty 289)
- Actual responsibilities: `EldGraphPoint` (السطر 5، صنف بيانات) + `EldGraphGrid` (السطر 21، `StatelessWidget`) + `_EldGraphGridPainter` (السطر 54، `CustomPainter`) = **ثلاثة أصناف / إحدى عشرة دالة**: `paint`, `_drawTimeAxis`, `_drawGridLines`, `_drawYAxisLabels`, `_drawRightSideStats`, `_drawStepLine`, `_drawLiveMarker`, `_drawDashedLine`, `_drawTag`, `_getYPosition`, `shouldRepaint`.
- Declared layer / actual layer: معلن كـ reusable painter -> فعلياً **مكوّن شبكة ساعات الحالة التنظيمية (FMCSA graph)**.
- Architectural status: **MODERATE**
- Issue IDs: CUI-004، CUI-018
- **مُجيب على السؤال 10**: عدد الأصناف والدوال أعلاه بأرقام أسطرها. **لا يحسب فترات HOS** (لا `Duration` ولا عتبات ولا 11/14/60 دقيقة) — الحساب كله في المستهلكين (`log_graph.dart:37-55` و `inspection_duty_graph.dart:19-51`). **لكنه يُضمّن ترميز رموز الحالة التنظيمية `OFF/SB/D/ON` وترتيب صفوف مخطط 24 ساعة** — انظر CUI-004.

### `lib/core/widgets/eld_info_row.dart` (63 lines, non-empty 60)
- Actual responsibilities: صف `label` / `value` / `trailing` / `onTap`. **يستهلك النصوص جاهزة.**
- Declared layer / actual layer: core/shared-widget -> core/shared-widget (مطابق)
- Architectural status: **MINOR**
- Issue IDs: CUI-014، CUI-017
- **COMPLIANT مع السؤال 2**.

### `lib/core/widgets/eld_retry_view.dart` (51 lines, non-empty 46)
- Actual responsibilities: شاشة خطأ/فراغ: رسالة + زر إعادة محاولة دائري. **يستهلك `message` و`onRetry` — لا منطق.**
- Declared layer / actual layer: core/shared-widget -> core/shared-widget (مطابق)
- Architectural status: **COMPLIANT**
- Issue IDs: CUI-016 (مُعاد تنفيذه يدوياً في خمسة مواضع بـfeatures)
- **COMPLIANT مع السؤال 2**، ومُعرَّف (`context.loc.retryButton` في السطر 37).

---


---

# المجموعة (ب): طبقة Backend — `lib/backend/**` (contracts, adapters, core, http, providers)

> المصدر: _raw/group_backend.md — القسم A.

## A. نتائج لكل ملف

### `lib/backend/adapters/eld_engine/eld_engine_adapter.dart` (118 سطر، غير فارغ 97)
- **المسؤوليات الفعلية:** مجمّع (aggregator) صِرف لـ 13 عقدة فرعية عبر `late final`؛ يحمل `ApiClient`؛ يبني `BackendIdentity`؛ `dispose()` فارغ.
- **الطبقة المعلنة/الفعلية:** `adapters/eld_engine` → `adapters` (بنية تحتية). مطابق تمامًا.
- **الحالة المعمارية:** COMPLIANT
- **Issue IDs:** none

### `lib/backend/adapters/eld_engine/mappers/dot_inspection_mapper.dart` (151، 135)
- **المسؤوليات الفعلية:** تحليل 3 payloads (`screen`, `cycle`, `logs`) إلى `domain/inspection`؛ تحليل `events` المتداخلة؛ 25 حقلًا في `fromCycleDayJson` و28 حقلًا في `fromLogJson`.
- **الحالة:** COMPLIANT — ترجمة JSON→domain حقيقية وفعّالة، وهي سمة جيدة.
- **ملاحظة حجم:** الأسطر 141-151 فارغة تمامًا (قسم `// Primitives` لم يُحذف بعد نقله إلى `JsonPrimitives`). تجميلي، لا يُبلَّغ كـ issue معماري.
- **Issue IDs:** none

### `lib/backend/adapters/eld_engine/mappers/hardware_mapper.dart` (27، 23)
- **المسؤوليات الفعلية:** تحويل `TelemetryReading` (domain) → صيغة السلك: `m/s → km/h`، `miles → km`.
- **الحالة:** COMPLIANT — translator نقي ومركّز (SRP ممتازة).
- **Issue IDs:** none

### `lib/backend/adapters/eld_engine/mappers/json_primitives.dart` (72، 64)
- **المسؤوليات الفعلية:** مساعدات تحليل JSON مشتركة (`asString/asInt/asBool/asDate/asLocalTime`).
- **الحالة:** COMPLIANT — توحيد ناجح لمساعدة كانت مكرّرة (مذكور صراحةً في توثيق الملف نفسه، الأسطر 3-5).
- **Issue IDs:** none

### `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart` (33، 32)
- **المسؤوليات الفعلية:** `RulesScreenDto → RulesScreenModel` + حقن قيم افتراضية (`breakDurationMinutes: 30`, `weeklyRestartHours: 34`).
- **الطبقة الفعلية:** mapper في `adapters/` لكنه يُخرج نوعًا من `features/account/application/models` — انقلاب تبعية.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-002، BACK-003

### `lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart` (215، 188)
- **المسؤوليات الفعلية:** تحليل 3 endpoints إلى `StatusDashboard` / `WeeklyRecap`؛ 9 parsers متداخلة؛ محللات بدائية (`_parseDuration`, `_parseDate`, `_asStringList`).
- **الحالة:** MODERATE — Mapper ممتاز وظيفيًا، لكنه **يحمل قيم عرض إنجليزية** (BACK-005).
- **Issue IDs:** BACK-005

### `lib/backend/adapters/eld_engine/models/certify_dto.dart` (50، 45)
- **المسؤوليات الفعلية:** `CertifyRequestDto` (طلب) + `CertifyResponseDto` (استجابة) — DTOان في ملف واحد.
- **الطبقة الفعلية:** نموذج داخل `adapters/eld_engine/models`، لكنه **مستورد من `contracts/daily_logs_backend.dart:3`** — أي أن العقد نفسه يستورد من مجلد محوّل.
- **الحالة:** MAJOR (المسؤول عن الخطأ هو المالك/الاستيراد، لا الملف)
- **Issue IDs:** BACK-004

### `lib/backend/adapters/eld_engine/models/dvir_dto.dart` (432، 401)
- **المسؤوليات الفعلية:** 6 فئات: `DvirDto`، `DvirDriverDto`، `DvirDefectDto`، `CreateDvirRequestDto`، `ReviewDvirRequestDto`، `DvirTrailerDto`.
- **لماذا هو كبير؟** ليس ملفًا مبالغًا في توحيد المسؤوليات، بل **جدار DTO لنطاق ميزة واحدة (DVIR) كامل**. كل فئة منها مسؤولية واحدة (فك ترميز/ترميز سلكي). **التقسيم هنا لا يفيد، وقد يجزّئ التماسك**؛ مكانه الحالي داخل `adapters/eld_engine/models/` هو المكان الصحيح.
- **لكن الملف يحتوي مشكلات حقيقية:** (أ) **منطق أعمال مدمج في `fromJson`** عند 107-114: `hasDefects` و`defectsCount` ودمج ثلاث قوائم عيوب (`flatDefects`, `vehicleDefects`, `trailerDefects`) — اشتقاق تجاري يجب أن يكون في mapper، لا في DTO سلكي. (ب) `toJson()` (128-164) يعيد كتابة حقول يملكها الخادم (`id`, `certified`, `createdAt`, `formattedTime`, `defectsCount`, `retentionDaysRemaining`). (ج) الملف **لا يستخدمه أي شيء داخل `lib/backend`**؛ المستهلك الوحيد هو `lib/features/dvir/data/repositories/dvir_repository_impl.dart` (الأسطر 56، 100، 138، 279، 313، 327).
- **الحالة:** MODERATE
- **Issue IDs:** BACK-006، BACK-007

### `lib/backend/adapters/eld_engine/models/readiness_dto.dart` (86، 81)
- **المسؤوليات الفعلية:** `CarrierProposedEdit` + `ReadinessDto` مع تحليل `pendingCarrierEdits` المتداخلة.
- **الحالة:** MODERATE — نفس المشكلة: مُستورد من `contracts/daily_logs_backend.dart:4`.
- **Issue IDs:** BACK-004

### `lib/backend/adapters/eld_engine/models/rules_screen_dto.dart` (103، 94)
- **المسؤوليات الفعلية:** 3 فئات: `RulesScreenDto`، `RulesScreenLimitsDto`، `RulesScreenUpdateRequest`.
- **الحالة:** COMPLIANT (موقعه صحيح) — لكنه يُستورد من مجلد **mock** أيضًا (انقلاب أفقي، BACK-003 / BACK-035).
- **Issue IDs:** BACK-003

### `lib/backend/adapters/eld_engine/models/rules_screen_options.dart` (29، 29)
- **المسؤوليات الفعلية:** دالة علوية واحدة `readRulesOptions` تربط أسماء مفاتيح الخادم (`availableCycleRules` → `cycleRule`).
- **الحالة:** COMPLIANT وظيفيًا — لكنه يُستورد من مجلد mock (BACK-035).
- **Issue IDs:** BACK-035

### `lib/backend/adapters/eld_engine/sub/eld_account_backend.dart` (81، 72)
- **المسؤوليات الفعلية:** نداءان + دالة تطبيع `_mapAccountJson` (15-48) بثلاث مسؤوليات فرعية (driverId fallback، تحويل `license` من نص `"MI, A350622298913"` إلى Map، توحيد `timezone`/`timeZone`). حجم 81 سطرًا معقول ولا يحتاج تقسيمًا.
- **نقطة جيدة:** التطبيع هنا حقيقي ولا يتسرّب — تحققت أن المخرجات `DriverAccount` مُحاط بالكامل.
- **الحالة:** COMPLIANT
- **Issue IDs:** none

### `lib/backend/adapters/eld_engine/sub/eld_auth_backend.dart` (200، 183)
- **المسؤوليات الفعلية:** 4 عمليات؛ استخراج `JSESSIONID` من ترويسات `set-cookie` (62-73)؛ فك `responseType.plain` بـ `jsonDecode` (48-57)؛ فك غلاف `{status, data}` (79-85)؛ **بناء عنوان URL مطلق يدويًا** `'${baseUrl}/api${EldEndpoints.session}'` (30، 107، 156، 174)؛ تطبيع URL خاص به يختلف عن المعياري (24-26)؛ **إعادة بناء ترويسة الجلسة يدويًا** `'Cookie': 'JSESSIONID=$sessionCredential'` (109، 149).
- **الحالة:** MAJOR — يتجاوز `ApiClient` بالكامل ويستخدم `_apiClient.dio` مباشرة، ويكرّر منطق تهيئة العنوان.
- **Issue IDs:** BACK-009، BACK-010، BACK-011

### `lib/backend/adapters/eld_engine/sub/eld_daily_logs_backend.dart` (162، 149)
- **المسؤوليات الفعلية:** 11 عملية؛ **9 منها مجرد** `parser: (data) => data is Map ? data : {}` + `mapValue((r) => r.data ?? {})` — أي تمرير JSON خام بلا ترجمة؛ فقط `certify` (83) و`getReadiness` (155) مترجمان إلى DTO. نسبة الترجمة الفعلية ≈ 18%.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001، BACK-004

### `lib/backend/adapters/eld_engine/sub/eld_driver_session_backend.dart` (92، 85)
- **المسؤوليات الفعلية:** 5 عمليات؛ `getAvailableDrivers()` (39) يُرجع `Result<List<dynamic>>` — تسريب `dynamic` كامل عبر العقد؛ `switchPrimaryDriver` يرسل نفس الـ payload في `queryParameters` **و** `data` معًا (78-79).
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001، BACK-012

### `lib/backend/adapters/eld_engine/sub/eld_duty_status_backend.dart` (89، 82)
- **المسؤوليات الفعلية:** 5 عمليات؛ 3 منها تمرير خام؛ دالتان `submitLegacy*` تستدعيان **نفس نقطة النهاية** `recordDutyStatus` (60) بدون أي تمييز عملي بينهما.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001

### `lib/backend/adapters/eld_engine/sub/eld_dvir_backend.dart` (138، 124)
- **المسؤوليات الفعلية:** 8 عمليات + مساعد `_asMap` (96-101) + `_accepted` (39-49)؛ استخراج `deviceId` من جسم التقرير لوضعه في query string (57-59) — قراءة من JSON المُدخل لتوجيه الطلب.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001، BACK-008

### `lib/backend/adapters/eld_engine/sub/eld_hardware_backend.dart` (114، 101)
- **المسؤوليات الفعلية:** 6 عمليات؛ أول سطر `// ignore_for_file: unused_field, unused_import` (1) — قناع analyzer على ملف **ليس فيه** unused فعليًا (تحققت: لا بلاغ من `flutter analyze`).
- **الحالة:** MINOR
- **Issue IDs:** BACK-001

### `lib/backend/adapters/eld_engine/sub/eld_inspection_backend.dart` (195، 182)
- **المسؤوليات الفعلية:** 8 عمليات؛ 3 مترجمة إلى domain (screen/cycle/logs)، 5 خام؛ مساعدان `_asMap`/`_postJson`.
- **ملاحظة:** لا يحمل `// ignore_architecture`، وهو أنظف ملف في مجلد `sub`.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001

### `lib/backend/adapters/eld_engine/sub/eld_rules_screen_backend.dart` (51، 46)
- **المسؤوليات الفعلية:** `getRulesScreen` مترجم بالكامل؛ `saveRulesScreen` يكتشف "جسم PUT فارغ/جزئي" heuristically (40-47) ثم **يعيد الجلب** كـ fallback (48) — منطق تكافؤ منطقي داخل المحوّل.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-002

### `lib/backend/adapters/eld_engine/sub/eld_signature_backend.dart` (34، 31)
- **المسؤوليات الفعلية:** **لا شيء** — دالة واحدة تُرجع `err(ServerError(code: 'eld.signature_endpoint_absent'))` دائمًا (24-32)؛ والحقل `_apiClient` مُعلَّم `// ignore: unused_field` (12).
- **الحالة:** MAJOR (ميت تمامًا — لا provider ولا مستهلك)
- **Issue IDs:** BACK-013

### `lib/backend/adapters/eld_engine/sub/eld_status_dashboard_backend.dart` (126، 119)
- **المسؤوليات الفعلية:** 3 عمليات مترجمة؛ `_defaultNoteFor` (110-125) — نصوص عرض إنجليزية داخل المحوّل؛ تعامل مع `ResponseType.plain`؛ **تعليق شخصي مكتوب داخل الكود** (60-62)؛ حقن `currentDutyStatus` محليًا إذا غاب عن الاستجابة (86-88) — إخفاء تعطّل العقد.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-005، BACK-014

### `lib/backend/adapters/eld_engine/sub/eld_unidentified_events_backend.dart` (83، 75)
- **المسؤوليات الفعلية:** 3 عمليات + `_asMap` + `_postVoid`.
- **الحالة:** MINOR
- **Issue IDs:** BACK-001

### `lib/backend/adapters/eld_engine/sub/eld_vehicle_backend.dart` (47، 42)
- **المسؤوليات الفعلية:** عمليتان فقط، لكن كلٌّ منهما يعرّف lambda `parser` مكرّرة أسفل الحالة (23-28 و 38-43) بدل استيراد `_asMap` الموجود أصلًا في نفس الحزمة — تكرار فُرصة.
- **الحالة:** MINOR
- **Issue IDs:** BACK-015

### `lib/backend/adapters/mock/fixtures/account_fixtures.dart` (65، 63)
- **المسؤوليات الفعلية:** ثابتان: `accountProfileFixture` (12-32) و`accountMyAccountFixture` (34-65).
- **الحالة:** MINOR — **`accountProfileFixture` كود ميت**: تحققت بالبحث النصي؛ المستهلك الوحيد هو `accountMyAccountFixture` في `mock_account_backend.dart:16`. الـ fixture الأول (21 سطرًا من البيانات) لا يقرأه أي كود.
- **Issue IDs:** BACK-016

### `lib/backend/adapters/mock/mock_adapter.dart` (109، 87)
- **المسؤوليات الفعلية:** مجمّع صِرف لـ 13 عقدة؛ كل الـ `late final`.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-017، BACK-018

### `lib/backend/adapters/mock/sub/mock_account_backend.dart` (30، 27)
- **المسؤوليات الفعلية:** عمليتان تمرّران الـ fixture إلى `DriverAccount.fromJson` مباشرة.
- **الحالة:** MINOR — **عدم تماثل دلالي**: `EldAccountBackend` يطبّق `_mapAccountJson` قبل `fromJson` (eld_account_backend.dart:57-60)، والموك لا يطبّقه إطلاقًا (16).
- **Issue IDs:** BACK-019

### `lib/backend/adapters/mock/sub/mock_auth_backend.dart` (51، 46)
- **المسؤوليات الفعلية:** 4 عمليات، كلها `ok(...)` ثابتة.
- **الحالة:** COMPLIANT — **تناظر كامل مع `EldAuthBackend`** في المفاتيح (`credential`, `user`, `serverOrigin`). أفضل حالة تناظر في المجموعة.
- **Issue IDs:** none

### `lib/backend/adapters/mock/sub/mock_daily_logs_backend.dart` (131، 119)
- **المسؤوليات الفعلية:** 11 عملية؛ 4 منها `throw UnimplementedError` (52، 100، 108، 116).
- **الحالة:** MODERATE — والأسطر 5-6 **يستوردان من `../../eld_engine/models/`** (انقلاب أفقي بين المحوّلين).
- **Issue IDs:** BACK-035، BACK-020

### `lib/backend/adapters/mock/sub/mock_driver_session_backend.dart` (44، 38)
- **المسؤوليات الفعلية:** 5 عمليات؛ 4 منها `UnimplementedError` (14، 19، 33، 41).
- **الحالة:** MAJOR
- **Issue IDs:** BACK-020

### `lib/backend/adapters/mock/sub/mock_duty_status_backend.dart` (45، 39)
- **المسؤوليات الفعلية:** 5 عمليات؛ `record` يُرجع `{'id': DateTime.now().millisecondsSinceEpoch, ...event}` (13).
- **الحالة:** MODERATE — **عدم تماثل دلالي مؤكد**: استخدام `DateTime.now()` يناقض صراحةً قاعدتين معلنتين: `mock_adapter.dart:36` (`**Rule:** No network access. No timers.`) وترويسة التوثيق في `mock_status_dashboard_backend.dart:12` (`Deterministic output`).
- **Issue IDs:** BACK-021

### `lib/backend/adapters/mock/sub/mock_dvir_backend.dart` (74، 63)
- **المسؤوليات الفعلية:** 8 عمليات؛ 2 `UnimplementedError` (33، 43)؛ كتالوج عيوب بـ 11 عنصرًا وثلاث حقول عربية/إنجليزية لكل عنصر (48-58).
- **الحالة:** MAJOR — **`list()` يُرجع `{'reports': []}`** (20) بينما المستهلك يقرأ `rawJson['data']` — تباين صامت (BACK-008).
- **Issue IDs:** BACK-008، BACK-020

### `lib/backend/adapters/mock/sub/mock_hardware_backend.dart` (70، 63)
- **المسؤوليات الفعلية:** 6 عمليات؛ **3 منها `async` + `throw UnimplementedError` داخل جسم `async`** (13، 55، 63).
- **الحالة:** MAJOR — `getStatus` غير منفَّذ بينما `hardwareStatusProvider` في طبقة presentation يستدعيه مباشرة → انهيار شاشة الاتصال في وضع الموك.
- **Issue IDs:** BACK-020، BACK-022

### `lib/backend/adapters/mock/sub/mock_inspection_backend.dart` (195، 182)
- **المسؤوليات الفعلية:** 3 عمليات مطبَّقة (بناء domain entities كاملة) + 5 `UnimplementedError` (161، 165، 178، 189، 193) + `_formatDate` (144-149).
- **الحالة:** MODERATE — يبني كائنات domain بنصوص عرض إنجليزية (`'DOT Inspection'`, `'Review the driver records'`, `'Golden Feather Transport'`, `'Riyadh'`)، وهي بيانات موك لا نصوص عرض مباشرة.
- **Issue IDs:** BACK-020

### `lib/backend/adapters/mock/sub/mock_rules_screen_backend.dart` (72، 68)
- **المسؤوليات الفعلية:** حالة `_state` داخلية + PUT بسيط (دمج shallow عند 65-68).
- **الحالة:** MODERATE — يستورد **مستودع تحويلات المحرك الحقيقي**: `../../eld_engine/models/rules_screen_dto.dart` (7) و`../../eld_engine/mappers/rules_screen_mapper.dart` (8).
- **Issue IDs:** BACK-035

### `lib/backend/adapters/mock/sub/mock_signature_backend.dart` (49، 41)
- **المسؤوليات الفعلية:** تخزين في الذاكرة + إصدار شهادة deterministic (base64 hash).
- **الحالة:** MINOR — منطق نظيف، لكنه **ميت تمامًا**: لا يوجد `signatureBackendProvider` ولا أي مستهلك (BACK-013).
- **Issue IDs:** BACK-013

### `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart` (191، 178)
- **المسؤوليات الفعلية:** حالة `_currentStatus` + 3 بناة (dashboard/circle/recap) + `_dayOfWeek`.
- **الحالة:** COMPLIANT وظيفيًا — fully typed domain، **تناظر كامل مع المحرك الحقيقي** في التوقيع.
- **Issue IDs:** BACK-005

### `lib/backend/adapters/mock/sub/mock_unidentified_events_backend.dart` (39، 35)
- **المسؤوليات الفعلية:** 3 عمليات، **كلها** `UnimplementedError` (18، 28، 36).
- **الحالة:** MAJOR — العقد الوحيد بنسبة تنفيذ 0%، ومع ذلك presentation يستهلكه مباشرة.
- **Issue IDs:** BACK-020، BACK-023

### `lib/backend/adapters/mock/sub/mock_vehicle_backend.dart` (21، 17)
- **المسؤوليات الفعلية:** عمليتان ترجعان `{'data': []}`.
- **الحالة:** COMPLIANT — تصحيح واعٍ ومُعلَن (11-12) لسبب حقيقي.
- **Issue IDs:** none

### `lib/backend/contracts/account_backend.dart` (17، 15)
- **المسؤوليات الفعلية:** عقدة منظَّمة، تُرجع `domain/account/DriverAccount`.
- **الحالة:** COMPLIANT — **النموذج الملهم**: العقدة الوحيدة (مع `signature_backend` و`status_dashboard_backend`) التي ترجع نوعًا مُحاطًا بدل `RawJson`.
- **Issue IDs:** none

### `lib/backend/contracts/auth_backend.dart` (29، 25)
- **المسؤوليات الفعلية:** 4 عمليات؛ `login` و`validateSession` تُرجعان `RawJson`.
- **الحالة:** MODERATE — **ثلاثة تسريبات في عقدة واحدة**: (1) `RawJson`؛ (2) **مفتاح `backendType`** كمُعامل (9، 15، 21) — تسمية داخلية خاصة بـ backend تدخل العقد؛ (3) بنية مفاتيح `credential/user/serverOrigin` تصبح عقدًا ضمنيًا عبر الاستهلاك في `auth_repository_impl.dart:60-64`.
- **Issue IDs:** BACK-001، BACK-010

### `lib/backend/contracts/contract_enums.dart` (51، 41)
- **المسؤوليات الفعلية:** 5 enums مغلّفة، كل واحد يحمل حقل `wire`.
- **الحالة:** MODERATE — **تسرّب قيم wire إلى طبقة العقد**: `DutyStatusAction.switchPrimary('switch-primary')` (46) و`legacySwitch('legacy-switch')` (47) حرفيًا قيم Swagger، و`UnidentifiedTab.unclaimed('UNCLAIMED')` (38) تسمية خادم. والاستهلاك يصل إلى **طبقة presentation**: `unidentified_events_page.dart:6`.
- **Issue IDs:** BACK-024

### `lib/backend/contracts/daily_logs_backend.dart` (72، 61)
- **المسؤوليات الفعلية:** 11 عملية؛ **6 منها `RawJson`**؛ تستورد DTOs من مجلد المحوّل (3-4).
- **الحالة:** CRITICAL — الملف نفسه يوثّق المشكلة عبر `// TODO(P2): replace with List<DailyLog>` في 6 مواضع، لكن الأهم أن **العقدة تعتمد على `adapters/eld_engine/models/`** — انقلاب اتجاه الاعتمادية في قلب طبقة الـ port.
- **Issue IDs:** BACK-001، BACK-004

### `lib/backend/contracts/driver_session_backend.dart` (31، 25)
- **المسؤوليات الفعلية:** 5 عمليات؛ `getAvailableDrivers()` تُرجع `Result<List<dynamic>>` (12).
- **الحالة:** MODERATE — **`dynamic` مكشوف في توقيع عقدة**؛ لا نوع يمكن للمستهلك الاعتماد عليه.
- **Issue IDs:** BACK-001، BACK-012

### `lib/backend/contracts/duty_status_backend.dart` (35، 30)
- **المسؤوليات الفعلية:** 5 عمليات؛ **5 منها `RawJson`** (لا استثناء)؛ دالتان موسومتان `// --- Legacy methods for P5.5 ---` (25).
- **الحالة:** MAJOR — عقدة بأقل ترجمة في المجموعة؛ `record(RawJson event)` و`update(RawJson update)` تعني أن **بناء جسم الطلب يحدث خارج طبقة البنية التحتية**، أي أن كود تشكيل الحقول الويبرية يعيش في مستهلكي العقد.
- **Issue IDs:** BACK-001

### `lib/backend/contracts/dvir_backend.dart` (50، 39)
- **المسؤوليات الفعلية:** 8 عمليات؛ **8 منها `RawJson`**؛ 3 منها تحمل `expectedOwnerDriverId` (23، 35).
- **الحالة:** MAJOR — وجود `int? expectedOwnerDriverId` في عقدة يعني أن **مفهوم جدولة الطابور وربط المالك (queue-dispatch owner binding) تسرّب من طبقة النقل إلى طبقة العقد**؛ وهو مفهوم تنفيذية بحت معرَّف في `auth_interceptor.dart:45`.
- **Issue IDs:** BACK-001، BACK-012

### `lib/backend/contracts/hardware_backend.dart` (37، 31)
- **المسؤوليات الفعلية:** 6 عمليات؛ 5 `RawJson` وواحدة `TelemetryReading` (مُحاط جيدًا).
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001

### `lib/backend/contracts/inspection_backend.dart` (65، 56)
- **المسؤوليات الفعلية:** 8 عمليات؛ 3 مُحاطة بنماذج domain (`getScreen`, `getCycle`, `getLogs`)، و5 `RawJson`.
- **الحالة:** MODERATE — أفضل عقدتين من حيث الترجمة بعد `account`، لكن التوثيق يصرّح بضعفها: «Kept as RawJson until Phase 4» (26).
- **Issue IDs:** BACK-001

### `lib/backend/contracts/raw_json.dart` (10، 9)
- **المسؤوليات الفعلية:** `typedef RawJson = Map<String, dynamic>;` (10) + وثيقة تطلب `// TODO(P2)` على كل دالة تُرجعه.
- **الحالة:** MAJOR — **هذا أقرب شيء لـ«عقد زجاجي» في التصميم**: يصدّر نوعًا غير مُحاط إلى 11 عقدة، ويستهلكه presentation وdomain فعليًا. كما أن `vehicle_repository_impl.dart:36` و`dvir_repository_impl.dart:70` يستوردانه مباشرة إلى طبقة `data`.
- **Issue IDs:** BACK-001

### `lib/backend/contracts/rules_screen_backend.dart` (15، 13)
- **المسؤوليات الفعلية:** عمليتان تُرجعان `RulesScreenModel`؛ `saveRulesScreen` تأخذ `RawJson update` (13).
- **الحالة:** MODERATE — **هذه هي الحافة المعروفة `backend → features`**: السطر 3 يستورد من `features/account/application/models`.
- **Issue IDs:** BACK-002

### `lib/backend/contracts/signature_backend.dart` (13، 12)
- **المسؤوليات الفعلية:** دالة واحدة `save` مُحاطة بـ `SignatureCertificate`.
- **الحالة:** MINOR — العقد نظيف تمامًا، لكنه **ميت**: لا provider ولا مستهلك.
- **Issue IDs:** BACK-013

### `lib/backend/contracts/status_dashboard_backend.dart` (20، 17)
- **المسؤوليات الفعلية:** 3 عمليات، **كلها** مُحاطة بنماذج domain (`StatusDashboard`, `DutyStatusCode`, `WeeklyRecap`).
- **الحالة:** COMPLIANT — أنقى عقدة في المجموعة، بلا أي `RawJson` ولا Dio ولا سلاسل نصية. **النموذج الذي تُبنى عليه بقية العقود.**
- **Issue IDs:** none

### `lib/backend/contracts/unidentified_events_backend.dart` (27، 24)
- **المسؤوليات الفعلية:** 3 عمليات؛ `list()` تُرجع `RawJson` (8)، و`claim`/`reject` تُرجعان `void`.
- **الحالة:** MAJOR — العقد الوحيد الذي تكون فيه **نسبة التنفيذ في الموك 0%** بينما presentation يستهلكه مباشرة.
- **Issue IDs:** BACK-001، BACK-020

### `lib/backend/contracts/vehicle_backend.dart` (12، 9)
- **المسؤوليات الفعلية:** عمليتان، كلاهما `RawJson`.
- **الحالة:** MODERATE — عقدة شبه فارغة؛ تسمية `RawJson` بلا حتى `TODO(P2)`، أي أنها تتجاوز حتى قاعدة التوثيق التي وضعها `raw_json.dart:4-5`.
- **Issue IDs:** BACK-001

### `lib/backend/core/backend_adapter.dart` (61، 42)
- **المسؤوليات الفعلية:** واجهة مجمّعة بـ **14 getter كلها nullable** (31-56) + `identity` + `dispose()`.
- **الحالة:** MODERATE — الـ nullability ليست مرونة بل **غياب أنواع**: `backend_providers.dart:61` يحوّل `null` إلى `StateError` في كل getter.
- **Issue IDs:** BACK-025

### `lib/backend/core/backend_identity.dart` (94، 81)
- **المسؤوليات الفعلية:** value object ثابت؛ مصنعان (`eldEngine`, `mock`)؛ تطبيع URL خاص به `_normalizeUrl` (84-93).
- **الحالة:** MODERATE — التطبيع هنا **مكرَّر** من `ApiConfig.normalized()` بمنطق **متطابق حرفيًا**.
- **Issue IDs:** BACK-026

### `lib/backend/core/backend_kind.dart` (19، 17)
- **المسؤوليات الفعلية:** enum من قيمتين مع توثيق قاعدة التوسعة.
- **الحالة:** COMPLIANT
- **Issue IDs:** none

### `lib/backend/core/backend_registry.dart` (129، 111)
- **المسؤوليات الفعلية:** خريطة adapters + `activeIdentity`؛ مصنعان مع تحققين؛ 7 API للقراءة/البحث؛ `disposeAll` مع تجميع أخطاء.
- **الحالة:** MAJOR — **زخرفة مؤكدة**: المستهلك الوحيد هو `backend_providers.dart:27-29` الذي يستدعي `BackendRegistry.single(...)`.
- **Issue IDs:** BACK-027

### `lib/backend/http/api_config.dart` (7، 6)
- **المسؤوليات الفعلية:** **صفر** — الملف كله تعليقات، بما فيها `library;` و`export`.
- **الحالة:** MINOR — **ملف ميت** معلَن كـ DEPRECATED، لا يستورده أي كود (تحققت).
- **Issue IDs:** BACK-028

### `lib/backend/http/api_response.dart` (7، 6)
- **المسؤوليات الفعلية:** **صفر** — نفس الحالة، كله تعليقات DEPRECATED.
- **الحالة:** MINOR — ملف ميت.
- **Issue IDs:** BACK-028

### `lib/backend/http/eld_endpoints.dart` (150، 137)
- **المسؤوليات الفعلية:** 40+ ثابت مسار؛ **20 منها دوال** مبنية على `int`/`String`.
- **الحالة:** MODERATE — **مصدر واحد جيد للمسارات** (COMPLIANT من حيث DRY)، لكنه مقيَّد بـ `int` بينما طبقة العقد تستخدم Value Objects — أي أن **التحويل إلى int يحدث يدويًا بـ `.value` عند كل استدعاء**.
- **Issue IDs:** BACK-029

### `lib/backend/http/interceptors/auth_interceptor.dart` (144، 130)
- **المسؤوليات الفعلية:** (1) وسم كل طلب بـ epoch وcredential generation (57-59)؛ (2) **استثناء مسار إنشاء الجلسة** (64)؛ (3) قراءة الجلسة و**إنفاذ ربط المالك قبل الإرسال** (80-99)؛ (4) **منع تسريب الكوكي عبر الأصول** (102-113)؛ (5) **معالجة 401 بثلاثة أجيال** (119-143).
- **الحالة:** MODERATE — منطق 401 المتعدد الأجيال والاستثنائي (session cookie لا Bearer) **ممتاز تقنيًا وموثّق بالعربية**؛ لكن الملف ينتهك الاتجاه مرتين (السطران 2-3).
- **Issue IDs:** BACK-009، BACK-010، BACK-030، BACK-031

### `lib/backend/http/interceptors/request_logger.dart` (134، 124)
- **المسؤوليات الفعلية:** تسجيل الطلب/الاستجابة/الخطأ؛ إخفاء 15 مفتاح حساس (21-37)؛ تحليل أجسام HTML وأخطاء قاعدة البيانات (99-127).
- **الحالة:** MINOR/MODERATE — **مقيَّد بـ `kDebugMode`** فلا يتسرب للإنتاج؛ لكن **مسار `onError` يطبع الجسم الخام بلا إخفاء** عند 128-130.
- **Issue IDs:** BACK-032

### `lib/backend/http/interceptors/time_drift_interceptor.dart` (67، 57)
- **المسؤوليات الفعلية:** قراءة `Date` من الترويسة (نجاحًا وفشلًا)؛ تثبيت (throttling) بميلاد 30 ثانية / 5 دقائق (50-60)؛ استدعاء `timeProvider.anchor(serverUtc)` (62).
- **الحالة:** MODERATE — **سلسلة الثقة ناقصة التحقق**: أول استجابة تُثبّت بلا أي فحص، و`anchor()` لا تتحقق من القيمة، والاعتراض مربوط بالـ Dio المشترك بلا opt-out لكل طلب.
- **Issue IDs:** BACK-033

### `lib/backend/providers/backend_network_providers.dart` (82، 70)
- **المسؤوليات الفعلية:** بناء `ApiClient` مع **تطبيع رابط ثالث** (30-39)؛ تركيب 3 اعتراضات؛ مزوّد `StreamController` لأحداث 401؛ ومزوّد عميل Traccar الأصلي (77-82).
- **الحالة:** MODERATE — ومزوّد Traccar **وظيفة تتبع** موضوعة في `backend/providers`.
- **Issue IDs:** BACK-026، BACK-034

### `lib/backend/providers/backend_providers.dart` (117، 99)
- **المسؤوليات الفعلية:** `backendRegistryProvider` + `activeBackendProvider` (اختيار الموك/ELD Engine) + **13** `*BackendProvider`.
- **الحالة:** MODERATE — **13 من 14**: لا يوجد `signatureBackendProvider`.
- **Issue IDs:** BACK-013، BACK-025

---


---

# المجموعة (ج): المصادقة، الحساب، المرافقة، الاتصال، الرئيسية، onboarding، الأذونات، الإعدادات، `lib/domain/**`

> المصدر: _raw/group_auth_account_misc.md — القسم A.

## A.1 `lib/features/auth/**` (19 ملفاً)

### `lib/features/auth/data/datasources/auth_local_data_source.dart` (137 سطر، غير فارغ 117)
- **المسؤولية الفعلية:** ثنائي التوصيف (Abstract + Impl) لتخزين `AuthSession` و`User` في `FlutterSecureStorage`، مع كاش ذاكرة `_sessionCache` وعدّاد `credentialGeneration` لتوسيم الطلبات.
- **الطبقة المعلنة:** data ✓
- **الطبقة الفعلية:** data ✓
- **الحالة المعمارية:** سليم. الاستيراد elegiblity: `core/domain/entities/user.dart` و`core/data/models/user_model.dart` — عبور `data`→`core.data.models` مقبول.
- **ملاحظة أمنية إيجابية (CONFIRMED CLEAN):** لا يطبع أي سرّ. `AppLogger.info('Session securely stored for origin: ${session.serverOrigin}')` — يطبع الـ origin فقط.
- **Issue IDs:** —

### `lib/features/auth/data/models/auth_session_dto.dart` (65، 58)
- **المسؤولية:** DTO للتسلسل، مع `fromEntity/toEntity`.
- **المعلنة/الفعلية:** data ✓ / data ✓
- **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/auth/data/repositories/auth_repository_impl.dart` (195، 175)
- **المسؤولية:** تنفيذ `AuthRepository`: `login`، `checkAndRestoreSession` (+`guardedNetwork` مع مسار offline)، `logout`، `getCurrentSession`، وفحص صلاحية الـ origin.
- **المعلنة/الفعلية:** data ✓ / data ✓
- **الحالة:** سليم. تحقّق الـ origin مُطبَّق قبل استعادة الجلسة (`_isValidOrigin`) ✓، والمسار دون-شبكي لا يُعيد جلسة من خادم مختلف ✓.
- **Issue IDs:** —

### `lib/features/auth/domain/entities/auth_session.dart` (53، 44)
- **المسؤولية:** كيان جلسة equatable مع `belongsTo()` وحجب السر في `toString()`.
- **المعلنة/الفعلية:** domain ✓ / domain ✓
- **الحالة:** نقي تماماً (استيرادان فقط: `equatable` + `core/domain/entities/user.dart`).
- **Issue IDs:** —

### `lib/features/auth/domain/entities/value_objects/email_regex.dart` (8، 8)
- **المسؤولية:** ثابت نمط بريد مبسّط.
- **الحالة:** نقي ✓.
- **Issue IDs:** —

### `lib/features/auth/domain/entities/value_objects/login_identifier.dart` (41، 36)
- **المسؤولية:** value object للمُعرف + `errorMessage`.
- **المعلنة/الفعلية:** domain / domain + **تسريب مفاتيح l10n من domain** (يرجّع `'emailRequired'`، `'invalidEmailFormat'`, `'invalidValue'` كنصوص).
- **الحالة:** مخالفة طبقة (منخفضة) — domain لا يعرف مفاتيح الترجمة.
- **Issue IDs:** **AUTH-003**

### `lib/features/auth/domain/entities/value_objects/password.dart` (21، 18)
- **المسؤولية:** value object لكلمة المرور.
- **المسؤولية الفعلية:** **فارغة قانونياً**: `final isValid = input.isNotEmpty;` — لا قاعدة تعقيد، لا `==`/`hashCode`، لا `toString` حاجب.
- **المعلنة/الفعلية:** domain / domain + تسريب l10n key (`'passwordRequired'`).
- **Issue IDs:** **AUTH-003**

### `lib/features/auth/domain/repositories/auth_repository.dart` (20، 16)
- **المسؤولية:** عقد مستودع (4 عمليات، كلها `Either<Failure, …>`).
- **الحالة:** سليم ✓.
- **Issue IDs:** —

### `lib/features/auth/domain/usecases/check_auth_status_usecase.dart` (15، 12)
- **المسؤولية الفعلية:** `return await repository.checkAndRestoreSession();` — **تمرير بلا أي سلوك**.
- **الحالة:** طبقة use-case طقسية.
- **Issue IDs:** **AUTH-002**

### `lib/features/auth/domain/usecases/login_usecase.dart` (37، 32)
- **المسؤولية الفعلية:** فحص `identifier.isValid` و`password.isValid` ثم تمرير — 37 سطراً منها 12 استيراداً وتعليقاً.
- **الحالة:** السلوك الوحيد مكرَّر حرفياً داخل الـ widget ⇒ **AUTH-007**.
- **Issue IDs:** **AUTH-002**, **AUTH-007**

### `lib/features/auth/domain/usecases/logout_usecase.dart` (12، 9)
- **المسؤولية الفعلية:** `await repository.logout();` مع **إسقاط** `Either<Failure, Unit>` كاملة (الدالة تُرجع `Future<void>`).
- **الحالة:** طبقة use-case تُفقد معلومات — مخالفة.
- **Issue IDs:** **AUTH-002**

### `lib/features/auth/presentation/pages/auth_page.dart` (160، 150)
- **المسؤولية:** تخطيط شاشة المصادقة + تبديل الوضع بين `LoginForm`/`ForgotPasswordForm`.
- **الحالة:** presentation سليمة. استخدام Riverpod هنا سليم.
- **Issue IDs:** —

### `lib/features/auth/presentation/pages/splash_page.dart` (97، 86)
- **المسؤولية الفعلية:** **مُنسّق إقلاع على مستوى التطبيق**: يفحص `onboardingSeen`، ثم يستدعي `Permission.location/bluetooth` مباشرةً، ثم `checkAuthStatus()`، ثم يقرّر الوجهة بـ `context.goNamed(...)`.
- **المعلنة:** presentation (صفحة)
- **الفعلية:** **application bootstrap orchestrator** + وصول مباشر لـ `permission_handler`
- **الحالة:** مخالفة طبقة (عالية). يوجد بالفعل مجلد `lib/app/orchestrators/` تحوي `tracking_orchestrator.dart` — فالنمط متاح ومُهمَل هنا.
- **Issue IDs:** **AUTH-005**

### `lib/features/auth/presentation/providers/auth_mode_provider.dart` (14، 12)
- **المسؤولية:** `StateProvider<AuthMode>` لتبديل نموذج الواجهة.
- **الحالة:** presentation ✓ سليم.
- **Issue IDs:** —

### `lib/features/auth/presentation/providers/auth_providers.dart` (3، 2)
- **المسؤولية الفعلية:** سطر `export '../../../../core/di/app_providers.dart' show traccarAuthRepositoryProvider, authLocalDataSourceProvider;`
- **المعلنة/الفعلية:** presentation/providers / **إعادة تصدير جذر التركيب (composition root)**
- **الحالة:** smell طبقي منخفض: providersシーン الـ DI تُقدَّم وكأنها تخصّ auth presentation.
- **Issue IDs:** **AUTH-006**

### `lib/features/auth/presentation/providers/auth_state_provider.dart` (330، 292)
- **المسؤولية الفعلية (7 مهام):**
  1. `enum AuthStatus` (5 حالات).
  2. `class AuthState` + `copyWith` + `isAuthenticated`.
  3. `authStateProvider`: ربط `unauthenticatedEventProvider` (حدث 401 من `backend/providers`) بمنبّه `forceLogout`.
  4. إدارة تسلسل العمليات (`_operationId`, `_isOperationInProgress`).
  5. **سلسلة تسلسل عمليات التخزين** `_storageChain` / `_runOrdered()` (سياج ضد `clear(A)` المتأخر).
  6. **حدود الهوية** عبر `SessionEpoch.bump()` (كائن `static` قابل للتغيّر في `core/session`).
  7. اشتقاقات: `sessionEpochProvider`, `sessionTransitionProvider`, `currentDriverIdProvider`.
- **المعلنة:** presentation
- **الفعلية:** presentation + **سياسات identity-boundary + سياسات تسلسل التخزين**
- **الحالة:** مخالفة (متوسطة–عالية). يلاحظ أن **تخزين الـ token ليس هنا** ✓؛ ما هنا هو *سياسة* التوسيع.
- **Issue IDs:** **AUTH-001**

### `lib/features/auth/presentation/providers/login_form_provider.dart` (33، 26)
- **المسؤولية:** `obscurePassword` فقط.
- **الحالة:** presentation ✓.
- **Issue IDs:** —

### `lib/features/auth/presentation/widgets/login_form.dart` (134، 121)
- **المسؤولية:** نموذج الدخول + استدعاء `notifier.login(...)`.
- **الحالة:** presentation ✓، لكن **يكرّر التحقق** بنفس `LoginIdentifier`/`Password` (وهو نفس ما يفعله `LoginUseCase`).
- **Issue IDs:** **AUTH-007**

### `lib/features/auth/presentation/widgets/forgot_password_form.dart` (133، 125)
- **المسؤولية الفعلية:** استدعاء **`ref.read(authBackendProvider).requestPasswordReset(...)` مباشرة**، مع `AppError` + `anyErrorUserMessage` + كتالوج `AppLocalizations`، وبناء النصوص عبر `_arabic ? '…' : '…'`.
- **المعلنة:** presentation widget
- **الفعلية:** presentation + **وصول مباشر لعقد البنية التحتية (backend contract)** + تجاوز كامل لطبقتَي data/domain في feature auth
- **الحالة:** مخالفة عالية + تجاوز الترجمة.
- **Issue IDs:** **AUTH-004**

---

## A.2 `lib/features/account/**` (9 ملفات)

### `lib/features/account/application/models/rules_screen_model.dart` (70، 59)
- **المسؤولية:** نموذج read-projection لشاشة القواعد + `_isSettingAllowed()` الذي يفسّر حمولات الخادم المرنة.
- **المعلنة/الفعلية:** application/models / application + **اعتماد على `core/config/hos_configuration.dart`** (طبقة بنية تحتية)
- **الحالة:** مخالفة متوسطة؛ كما أن منطق تفسير الأسماء البديلة **مكرَّر** في `rules_page.dart:97 _serverSetting()`.
- **Issue IDs:** **ACC-005**

### `lib/features/account/application/usecases/update_rules_use_case.dart` (62، 51)
- **المسؤولية الفعلية:** `saveRulesScreen` على الخادم ثم **دمج** `HosConfiguration` في `LocalStorageService` وحفظه.
- **المعلنة:** application/usecases
- **الفعلية:** application + **`import 'package:flutter_riverpod/flutter_riverpod.dart';` (سطر 1) + تعريف `updateRulesUseCaseProvider` (سطر 52) = DI داخل طبقة application** + **اعتماد على presentation لميزة أخرى**: `../../../auth/presentation/providers/auth_state_provider.dart` (سطر 9)
- **الحالة:** مخالفة عالية (اتجاه تبعية معكوس + DI في application).
- **Issue IDs:** **ACC-001**

### `lib/features/account/presentation/pages/account_page.dart` (352، 336)
- **المسؤولية:** عرض بيانات الحساب + قائمة اللغة/العداد.
- **المسؤولية الفعلية الزائدة:** (أ) `ref.watch(dashboardDataProvider)` — مزوّد من feature **HOME** (سطر 7) لعرض اسم السائق؛ (ب) مطابقة أسماء اللغات بنصوص حرفية (سطور 180–181)؛ (ج) `Scaffold.of(context).openDrawer()` + استيراد `EldDrawer` من HOME.
- **الحالة:** مخالفات متوسطة.
- **Issue IDs:** **ACC-007**, **ACC-008**, **ACC-004** (عرض `error` الخام)

### `lib/features/account/presentation/pages/info_packet_page.dart` (150، 139)
- **المسؤولية:** صفحة "حزمة المعلومات".
- **المسؤولية الفعلية الزائدة:** `ref.watch(informationPacketProvider)` وهو مزوّد **presentation** من feature **INSPECTION** (سطور 7–8، 39).
- **الحالة:** مخالفة متوسطة (تبعية عابرة للميزات نحو تنفيذ الأخرى feature).
- **Issue IDs:** **ACC-006**, **ROU-001**

### `lib/features/account/presentation/pages/instructions_page.dart` (502، 475)
- **المسؤولية:** ثلاث أقسام تعليمات + `ZoomableSectionPage`.
- **النصوص:** **مترجَمة بالكامل عبر `context.loc`** — الفرضية المرفوضة. النص الوحيد الخشن: `'www.topceld.com'` (سطر 374).
- **ملاحظة معمارية:** `enum InstructionsSection { all, inspection, sendLogs, malfunction }` — **3 من 4 أقسام غير قابلة للوصول** (لا يوجد GoRoute، ولا أي استدعاء بـ `section:`) ⇒ كود ميت وإعداد زائد.
- **Issue IDs:** **ROU-002**

### `lib/features/account/presentation/pages/rules_page.dart` (502، 476)
- **المسؤولية:** نموذج قواعد HOS قابل للتحرير + عرض الحدود.
- **المسؤولية الفعلية الزائدة:** `import '../../../../backend/adapters/eld_engine/models/rules_screen_dto.dart';` (سطر 13) — presentation يستهلك **DTO محوّل (adapter) من طبقة البيانات**.
- **Issue IDs:** **ACC-002**, **ACC-005**, **ACC-008**

### `lib/features/account/presentation/pages/user_manual_page.dart` (559، 538)
- **المسؤولية:** دليل مستخدم مرجعي كثيف النصوص.
- **النصوص:** **مترجَم بالكامل عبر `context.loc`** — الفرضية المرفوضة. النص الخشن الوحيد: `'Golden Feather ELD'` (سطر 129) — اسم العلامة التجارية، وقد يكون مقصوداً لكنه يخرق `context.loc.appName` الموجود.
- **Issue IDs:** — (فرضية "نصوص إنجليزية غير مترجمة" **مرفوضة**)

### `lib/features/account/presentation/providers/account_provider.dart` (157، 136)
- **المسؤولية:** جلب `DriverAccount` + `updatePreferences` + سياج `owner/epoch/seq`.
- **المسؤولية الفعلية الزائدة:** يكتب `failure.l10nKey` و`e.toString()` **في حقل `error`** المShowر خاماً في `account_page.dart:102`.
- **Issue IDs:** **ACC-004**

### `lib/features/account/presentation/providers/rules_screen_provider.dart` (25، 21)
- **المسؤولية الفعلية:** `FutureProvider` + **تحليل استجابة الخادم محلياً** + `throw Exception(failure.l10nKey)`.
- **المسؤولية_Zائدة:**استدعاء `rulesScreenBackendProvider` مباشرة + `throw Exception('User not authenticated')`.
- **الحالة:** مخالفة عالية — أيضاً **خطأ سلوكي مؤكد** (انظر ACC-003).
- **Issue IDs:** **ACC-003**, **CON-003** (نمط مكرر عبر المشروع)

---

## A.3 `lib/features/codriver/**` (10 ملفات)

### `lib/features/codriver/data/providers/codriver_repository_providers.dart` (20، 16)
- **المسؤولية:** تركيب `CoDriverRepositoryImpl` (نمط DI في data ✓).
- **ملاحظة:** `driverSessionBackendProviderAlias` (سطر 11) غلاف بلا قيمة لوغظية.
- **Issue IDs:** —

### `lib/features/codriver/data/repositories/codriver_repository_impl.dart` (144، 136)
- **المسؤولية:** 3 عمليات على `DriverSessionBackend` مع cache.
- **المسؤولية الفعلية الحرجة:** `static List<CoDriver> _cachedDrivers = [];` و`static CurrentCoDriverRead? _cachedCurrentCoDriver;` — **حالة mutables على مستوى العملية، لا تُبطل عند logout، ولا تتأثر بـ owner/epoch**.
- **Issue IDs:** **COD-001**, **COD-003**

### `lib/features/codriver/domain/current_codriver.dart` (51، 46)
- **المسؤولية الفعلية:** كيان + **`parseCurrentCoDriver(dynamic)` — تحليل حمولة JSON داخل `domain/`**.
- **Issue IDs:** **COD-006**

### `lib/features/codriver/domain/role_switch_guard.dart` (40، 38)
- **المسؤولية:** حارس تبديل الأدوار (نقي تماماً، صفر استيرادات).
- **الحالة:** domain نقي ✓. لكن **عقده يجبر المتصل على تزويده بحالة HOS + إعداد HOS + حالة التتبع** ⇒ التسرّب يقع في المتصل (الـ widget) ⇒ COD-002.
- **Issue IDs:** **COD-002** (كطرف مساهم)

### `lib/features/codriver/domain/team_status.dart` (56، 51)
- **المسؤولية:** كيان + **`parseTeamStatus(dynamic)` — تحليل JSON داخل domain**.
- **Issue IDs:** **COD-006**

### `lib/features/codriver/domain/entities/codriver.dart` (10، 8)
- **المسؤولية:** كيان `CoDriver` + ثابت `none = CoDriver(id: 'none', name: 'No One')`.
- **الحالة:** `'No One'` نص إنجليزي في domain يُعرض كخيار في الواجهة ⇒ §C.
- **Issue IDs:** — (ملاحظة محتوى)

### `lib/features/codriver/domain/repositories/codriver_repository.dart` (15، 12)
- **المسؤولية:** عقد مستودع ✓.
- **Issue IDs:** —

### `lib/features/codriver/presentation/pages/codriver_page.dart` (541، 521)
- **المسؤولية الفعلية الزائدة (5 استيرادات خارجية):** `hos/domain/engine/hos_rules_engine.dart` (15)، `hos/presentation/providers/hos_engine_provider.dart` (16)، `hos/presentation/providers/hos_provider.dart` (17)، `tracking/presentation/providers/tracking_provider.dart` (18)، `hos/presentation/providers/status_dashboard_providers.dart` (23) — كلها Feeding لـ `refuseRoleSwitch` داخل `onPressed`.
- **الحالة:** مخالفة عالية (الـ widgetActs كـ orchestrator لـ feature أخرى).
- **Issue IDs:** **COD-002**, **COD-003**, **COD-004**, **ACC-008**

### `lib/features/codriver/presentation/providers/codriver_provider.dart` (238، 219)
- **المسؤولية:** حالة + سياج `owner/epoch/seq` + `reload()` + `switchDrivers()`.
- **المسؤولية_Zائدة:** رسائل إنجليزية hardcoded تُخزَّن في `state.error` وتُعرض خاماً؛ استيراد `authStateProvider` presentation من feature أخرى (سطر 3).
- **Issue IDs:** **COD-003**, **COD-001** (كطرف متضرر)

### `lib/features/codriver/presentation/providers/team_status_provider.dart` (41، 37)
- **المسؤولية الفعلية:** **تنسيق عمليتين على الخادم**: `backend.list(...)` لاستخراج أول `id`، ثم `backend.getTeamStatus(...)`، مع **استخراج JSON يدوي** (`json['data']`, `first['id']`).
- **المعلنة/الفعلية:** presentation/providers / **data + domain orchestration**
- **Issue IDs:** **COD-005**, **COD-006**

---

## A.4 `lib/features/connection/**` (16 ملفاً)

### `lib/features/connection/domain/connectivity_status.dart` (151، 136)
- **المسؤولية الفعلية:** كيان + **`parseConnectivityStatus(dynamic)` (تحليل JSON في domain)** + `isMacAddress()` (نمط MAC).
- **Issue IDs:** **CON-005**, **CON-006** (التبعية العكسية للقرار)

### `lib/features/connection/domain/hardware_readiness.dart` (75، 67)
- **المسؤولية:** كيان + **`parseHardwareReadiness(dynamic)`** + 5 دوال `_asMap/_text` خاصة.
- **Issue IDs:** **CON-005**

### `lib/features/connection/domain/entities/hardware_alert.dart` (15، 14)
- **المسؤولية:** كيان نقي بلا JSON ✓ (التعليق في الملف يصرّح بذلك).
- **Issue IDs:** —

### `lib/features/connection/presentation/mac_address_validation.dart` (13، 12)
- **المسؤولية الفعلية:** فحص "غير فارغ" فقط + إرجاع `loc.macAddressRequired`.
- **الحكم الصريح:** **ليس مخالفة معمارية.** الدالة تعتمد على `AppLocalizations` بالتوقيع ⇒ لا يمكن أن تعيش في `domain` بصدق. الموضع في `presentation/` صحيح والتعليق في الملف (سطر 7) يشرح التاريخ.
- **لكن:** التقسيم غير متسق — قاعدة *صيغة* MAC في `domain/connectivity_status.dart:150`، بينما الواجهة تفرض صيغة *أضيق* في `eld_connection_page.dart:436–439`.
- **Issue IDs:** **CON-006** (منخفض/POTENTIAL)

### `lib/features/connection/presentation/pages/diagnostics_page.dart` (101، 92)
- **المسؤولية:** فرز التنبيهات إلى diagnostic/malfunction وعرضها.
- **المسؤولية_Zائدة:** `bool _isMalfunction(HardwareAlert a) => a.type.toUpperCase().contains('MALFUNCTION');` (سطر 23–24) — **قاعدة تصنيف نطاق (SRS 7.14) داخل صفحة**. وكتلة `kDebugMode` (سطور 81–91) بزر "محاكاة عطل" لا يفعل شيئاً سوى `AppFeedback.info`.
- **Issue IDs:** **CON-007**

### `lib/features/connection/presentation/pages/eld_connection_page.dart` (529، 492)
- **المسؤولية الفعلية (4 أشياء في ملف واحد):**
  1. `EldConnectionState` (27–59).
  2. `EldConnectionNotifier` (61–246): `attemptConnection` (Bluetooth + hardware backend + local storage + tracking repo + tracking state)، `setManualMode`، `continueDisconnected`.
  3. `eldConnectionProvider` (248–251).
  4. `EldConnectionPage` widget (253–529).
- **المعلنة:** presentation/pages
- **الفعلية:** presentation + **application use-case كامل** + وصول مباشر للبنية التحتية (`bluetoothServiceProvider`, `hardwareBackendProvider`, `localStorageProvider`, `trackingRepositoryProvider`)
- **الحالة:** feature `connection` **لا تملك طبقة `domain/` ولا `application/` إطلاقاً** ⇒ Use case "وصلة الـ ELD" مكتوب كاملاً داخل ملف صفحة.
- **Issue IDs:** **CON-001**, **CON-002**, **CON-008**

### `lib/features/connection/presentation/providers/hardware_alerts_provider.dart` (83، 74)
- **المسؤولية الفعلية:** `AsyncNotifier` + **`_hardwareAlertFromJson()` و`_alertList()` — تحليل JSON** + استدعاء `hardwareBackendProvider` مباشرة.
- **ملاحظة:** تعليق الملف نفسه (سطور 7–8) يعترف بالديون: «يبقى هنا حتى موجة نقل الـ parsing إلى data/mappers».
- **Issue IDs:** **CON-003**

### `lib/features/connection/presentation/providers/hardware_status_provider.dart` (42، 39)
- **المسؤولية:** `FutureProvider` لحالة الاتصال + `hardwareReadinessProvider` + استدعاء backend مباشرة + استيراد `vehicleProvider` من feature **VEHICLE** (سطر 3).
- **Issue IDs:** — (نمط "provider يستدعي backend" متكرر عبر المشروع — يُعالَج مركزياً في CON-003)

### `lib/features/connection/presentation/widgets/eld_connectivity_panel.dart` (78، 74)
- **المسؤولية:** عرض أسطر الحالة المترجمة ✓.
- **Issue IDs:** —

### `lib/features/connection/presentation/widgets/eld_diagnostics_section.dart` (13، 12)
- **المسؤولية:** Barrel export فقط ✓.
- **Issue IDs:** —

### `lib/features/connection/presentation/widgets/eld_readiness_panel.dart` (117، 113)
- **المسؤولية:** عرض قائمة الجاهزية + `readinessCheckLabel()` (تحويل مفتاح خادم إلى تسمية) — presentation ✓.
- **Issue IDs:** —

### `lib/features/connection/presentation/widgets/manual_recording_section.dart` (131، 124)
- **المسؤولية:** قسم §395.34 + نداء `setManualMode`.
- **المسؤولية_Zائدة:** `import '../pages/eld_connection_page.dart';` (سطر 9) — **widget يستورد صفحة** للحصول على `eldConnectionProvider` (الذي مكانه الصحيح `presentation/providers/`).
- **Issue IDs:** **CON-004**

### `lib/features/connection/presentation/widgets/diagnostics/active_malfunction_actions.dart` (41، 37)
- **المسؤولية:** 3 أزرار إرشادية.
- **Issue IDs:** —

### `lib/features/connection/presentation/widgets/diagnostics/event_card.dart` (72، 65)
- **المسؤولية:** بطاقة حدث.
- **النصوص الخشنة:** `'DETECTED'` (سطر 55)، `'MALFUNCTION'`/`'DATA_DIAGNOSTIC'` (سطر 25) ⇒ §C.
- **Issue IDs:** — (محتوى)

### `lib/features/connection/presentation/widgets/diagnostics/stat_row.dart` (58، 51)
- **المسؤولية:** 5 بطاقات إحصائية.
- **النصوص الخشنة:** `'ACTIVE DIAG'`, `'ACTIVE MALF'`, `'TOTAL DIAG'`, `'TOTAL MALF'` (سطور 24–27)، بينما `'active'` وحده مترجَم (سطر 23) ⇒ §C.
- **Issue IDs:** — (محتوى)

### `lib/features/connection/presentation/widgets/dialogs/manual_mode_reason_dialog.dart` (57، 51)
- **المسؤولية:** حوار سبب §395.34، مترجَم بالكامل ✓.
- **Issue IDs:** —

---

## A.5 `lib/features/home/**` (5 ملفات)

### `lib/features/home/presentation/providers/dashboard_provider.dart` (224، 202)
- **المسؤولية الفعلية:** تجميع **ثلاث features** في `DashboardData`: يستمع لـ `authStateProvider` (AUTH)، `vehicleProvider` (VEHICLE)، `codriverProvider` (CODRIVER)، ويستورد من LOGS: `logs/domain/daily_form_rules.dart` (`joinFormList`) و`logs/domain/entities/daily_form_data.dart`.
- **المعلنة:** home/presentation/providers
- **الفعلية:** **وحدة "ترويسة جلسة التطبيق" مشتركة بفعل الأمر** — يستهلكها `account_page.dart:7` و`eld_connection_page.dart:11` و`home_page.dart:40`.
- **الحالة:** مخالفة عالية (HOME تحوّل إلى طبقة समनاد غير معلنة).
- **Issue IDs:** **HOM-001**, **HOM-004**

### `lib/features/home/presentation/providers/home_provider.dart` (66، 63)
- **المسؤولية:** تعريف قائمة الكشّاف + `menuProvider`.
- **المسؤولية_Zائدة:** `import '../../../../../routes.dart';` (سطر 3) —/providers داخل feature يستورد جذر التطبيق ⇒ **دورة** مع `routes/home_routes.dart` الذي يستورد صفحات home.
- **Issue IDs:** **HOM-003**

### `lib/features/home/presentation/pages/home_page.dart` (219، 206)
- **المسؤولية الفعلية:** (أ) استضافة صفحتي HOS كتبويبات داخلية: `StatusDashboardPage()`, `RecapPage()` (سطور 30–35)؛ (ب) `DrivingLockScreen` من HOS؛ (ج) `developerBypassDrivingScreenProvider` (سطر 24) — **مفتاح تجاوز لشاشة منع القيادة** بلا حارس `kDebugMode`؛ (د) منطق تجميع نص الترووية (سطور 56–65).
- **ملاحظة:** `import 'package:geolocator/geolocator.dart';` (سطر 17) غير مستخدم في الملف.
- **Issue IDs:** **HOM-002**, **HOM-004**, **HOM-003**

### `lib/features/home/presentation/widgets/eld_drawer.dart` (149، 146)
- **المسؤولية:** الكشّاف + حوار تسجيل الخروج الذي ينفّذ `authStateProvider.notifier.logout()` ثم `router.go(AppRoutes.login)`.
- **المسؤولية_Zائدة:** widget داخل feature يستورد `routes.dart` + يستدعي mutation في feature AUTH ⇒ **الهيكلي (shell) مملوك لميزة**.
- **Issue IDs:** **HOM-003**, **HOM-005**

### `lib/features/home/presentation/widgets/eld_bottom_nav.dart` (100، 92)
- **المسؤولية:** شريط تبويب Available/Recap ✓ مترجَم بالكامل.
- **Issue IDs:** —

---

## A.6 ميزات متنوعة

### `lib/features/onboarding/presentation/pages/onboarding_page.dart` (183، 170)
- **المسؤولية:** 3 شرائح Onboarding + `setOnboardingSeen()` + `context.goNamed('splash')`.
- **المسؤولية_Zائدة:** كتابة في `LocalStorageService` من widget (مقبولة: أمر تهيئة لمرة واحدة)، والتنقّل صحيح عبر GoRouter ✓.
- **Issue IDs:** —

### `lib/features/permissions/presentation/pages/permissions_page.dart` (301، 276)
- **المسؤولية الفعلية:** استدعاء **`permission_handler` مباشرةً** (5 صلاحيات) + كتابة `setState` + تجاوز التنقل إلى `login` بـ `goNamed`.
- **الحالة:** presentation-only feature بلا طبقة data ⇒ لا يمكنها العمل بشكل نظيف؛ لكن الحجم صغير. المشكلة الحقيقية: **الصفحة كلها عربية hardcoded** بينما التطبيق يدعم ar/en/es ⇒ §C.
- **Issue IDs:** — (محتوى؛ §C)

### `lib/features/settings/presentation/pages/settings_page.dart` (214، 202)
- **المسؤولية:** اللغة، السمة، عنوان الخادم (`setServerUrl` + `setBackendType('eld')`).
- **المسؤولية_Zائدة:** يستورد `home/presentation/widgets/eld_drawer.dart` (سطر 12) و`account/presentation/providers/account_provider.dart` (سطر 14)؛ ويشتقّ لغة الخادم بالنصوص الحرفية (سطر 119).
- **Issue IDs:** **ACC-008**, **ACC-007** (نمط)

### `lib/features/about/presentation/pages/about_page.dart` (330، 314)
- **المسؤولية:** معلومات التطبيق + بطاقات حالة الاتصال/التشخيص.
- **المسؤولية_Zائدة:** يستورد **feature CONNECTION كاملاً**: `diagnostics_page.dart`، `hardware_alerts_provider.dart`، `hardware_status_provider.dart`، `eld_diagnostics_section.dart` (سطور 16–19) — أي نبني واجهة feature أخرى داخل صفحة About.
- **Issue IDs:** **ACC-008** (نمط QUEST: shell widget owned by feature)، **ROU-001**

---

## A.7 `lib/domain/**` (9 ملفات — الدومين المشترك)

> **ملاحظة التوليد المُطلَبة:** كل الملفات تعتمد `freezed_annotation` مع `part '*.freezed.dart'`. **`driver_account.dart` وحده يحمل `part 'driver_account.g.dart'`** (أي `json_serializable`) — ⇒ **DOM-003**.

### `lib/domain/account/driver_account.dart` (36، 31)
- **الاستيرادات (كاملة):** `freezed_annotation` فقط.
- **المسؤولية الفعلية:** DTO شبكة صريح: `@freezed abstract class DriverAccount` + `factory DriverAccount.fromJson(...)` مع `part 'driver_account.g.dart'` (سطور 3–4).
- **الطبقة الفعلية:** **data (DTO) داخل مجلد domain**.
- **Issue IDs:** **DOM-003**

### `lib/domain/config/server_config.dart` (85، 71)
- **الاستيرادات (كاملة):** `freezed_annotation` فقط ✓.
- **المسؤولية:** `enum BackendType` + `ServerConfig` (بدون `.g.dart`).
- **المسؤولية_Zائدة:** `static String normalizeUrl(String url)` (سطور 49–58) **سياسة تطبيع عنوان** داخل DTO، وتضيف `https://` افتراضياً (سطر 52) — قرار أمني في domain.
- **Issue IDs:** **DOM-004** (منخفض)

### `lib/domain/duty_status/duty_status_code.dart` (99، 84)
- **الاستيرادات (كاملة — مخالفة):**
  ```dart
  7: import 'package:flutter/widgets.dart';
  8: import '../../../core/utils/logger.dart';
  ```
- **المسؤولية_Zائدة:** `Color get displayColor` (السطور 75–88) بـ **قيم hex مكرَّرة حرفياً من `core/theme/app_colors.dart`**، و`AppLogger.warning(...)` داخل `fromAny` (سطر 45).
- **الطبقة الفعلية:** presentation + logging داخل **نواة دومين مشتركة** يستوردها `backend/contracts` و`backend/adapters`.
- **Issue IDs:** **DOM-001** (عالٍ)

### `lib/domain/duty_status/status_dashboard.dart` (202، 167)
- **الاستيرادات (كاملة):** `freezed_annotation`، `../shared/value_objects.dart`، `duty_status_code.dart`.
- **الحالة:** نقي ✓ (والت970 dépendance على `duty_status_code.dart` تنقل Colour إلى العقد).
- **Issue IDs:** يرث أثر **DOM-001**

### `lib/domain/duty_status/weekly_recap.dart` (45، 40)
- **الاستيرادات (كاملة):** `freezed_annotation`، `status_dashboard.dart show CycleRule`.
- **الحالة:** نقي ✓.
- **Issue IDs:** —

### `lib/domain/hardware/telemetry_reading.dart` (47، 39)
- **الاستيرادات (كاملة):** `freezed_annotation`، `../shared/value_objects.dart`.
- **الحالة:** نقي ✓.
- **Issue IDs:** —

### `lib/domain/inspection/dot_inspection.dart` (142، 131)
- **الاستيرادات (كاملة):** `freezed_annotation`، `../shared/value_objects.dart`.
- **الحالة:** نقي ✓. **لكنه DTO شبكة صريح بحقول نصية جاهزة للعرض (`screenTitle`, `guidanceText`, `carrierComplianceStatement`)** — أي "read projection" لا كيان نطاقي ⇒ يتقاطع مع DOM-003.
- **Issue IDs:** —

### `lib/domain/shared/value_objects.dart` (70، 56)
- **الاستيرادات (كاملة):** `freezed_annotation` فقط ✓.
- **المسؤولية:** 12 معرّفاً مميَّزاً (`DriverId`, `DeviceId`, …).
- **الحالة:** نقي ✓ ومتماسك — **النواة الصلحة الوحيدة في `lib/domain/`**.
- **Issue IDs:** —

### `lib/domain/signature/signature.dart` (43، 35)
- **الاستيرادات (كاملة):** `freezed_annotation`، `../shared/value_objects.dart`.
- **الحالة:** نقي ✓.
- **Issue IDs:** —

---


---

# المجموعة (د): ميزتا HOS و Logs

> المصدر: _raw/group_hos_logs.md — القسم A.

## A.1 — `lib/features/hos/domain/**` (12 ملف)

### `lib/features/hos/domain/engine/hos_calculator.dart` (113 سطر، غير فارغ 94)
- **المسؤولية الفعلية:** حساب الحدود المتبقية (11h قيادة، 14h نافذة، دورة، استراحة 30د) + فحص إعادة التشغيل الأسبوعي 34h.
- **الطبقة المعلنة:** domain ✅
- **الطبقة الفعلية:** domain مع تسريب واحد — يعتمد على `core/time/trusted_time_provider.dart` وهو ملف يُعرِّف `Provider` من Riverpod **في نفس الملف** (`trusted_time_provider.dart:200: final trustedTimeProvider = Provider<TrustedTimeProvider>(...)`). أي أن تبعيات domain تُسحب مكتبة Riverpod و`core/services/local_storage_service.dart` بشكل غير مقصود.
- **الحالة المعمارية:** سليم مع ملاحظة (HL-07).
- **Issue IDs:** HL-07، HL-03 (ثابت 34h مثبت داخليًا).

### `lib/features/hos/domain/engine/hos_rules_engine.dart` (240 سطر، غير فارغ 207)
- **المسؤولية الفعلية:** تنسيق `HosCalculator` + `HosStateMachine` + `TrustedTimeProvider`؛ توليد التنبيهات (15/30/60 دقيقة)؛ كشف المخالفات (3 أنواع)؛ التحقق من الانتقال اليدوي بالسرعة.
- **الطبقة المعلنة:** domain ✅
- **الطبقة الفعلية:** domain + تسريب `AppLogger` (`line 96`)، وبناء `Failure` قانوني داخل domain (`line 85: return Left(ServerFailure(...))`).
- **الحالة المعمارية:** جزئية — `Either<Failure, void>` يُرجع `ServerFailure` من طبقة domain وهي علاقة نقل لا علاقة قانونية.
- **Issue IDs:** HL-03، HL-09.

### `lib/features/hos/domain/engine/hos_state_machine.dart` (128 سطر، غير فارغ 106)
- **المسؤولية الفعلية:** تتبّع الحالة الحالية، محرّك `Timer.periodic` كل دقيقة لزيادة `_totalDrivingHours`، حفظ الانتقالات.
- **الطبقة:** domain ✅ / **الحالة:** سليم. ملاحظة تصميمية: `line 66-69` كتلة `if` فارغة بتعليق فقط.
- **Issue IDs:** — (سليم).

### `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` (555 سطر، غير فارغ 494)
- **المسؤولية الفعلية:** 7 أسباب للتغيير في صنف واحد: (1) استقبال أحداث ELD وتطبيق قاعدة 5mph؛ (2) قاعدة الثبات 5 دقائق؛ (3) حفظ الحالة في `LocalStorageService`؛ (4) إنشاء `PendingEvent` + إيداعه في `SyncEngine`؛ (5) نداء `StatusDashboardBackend` مباشرة؛ (6) تبثّ الأحداث؛ (7) حساب إحصائيات `Map<String,double>` غير مُنمّطة.
- **الطبقة المعلنة:** domain — والملف **يصرّح بذلك في تعليق**: `line 7: /// متتبع حالة السائق (Domain Pure)`
- **الطبقة الفعلية:** data + application + infrastructure. يُسجّل `DutyPeriod` في مستودع ميزة أخرى، ويستدعي backend مباشرة، ويبني حمولة شبكة (تحويل ميل→كم `line 227`).
- **الحالة المعمارية:** **مخالفة حرجة مؤكدة.**
- **Issue IDs:** HL-01، HL-02، HL-04، HL-05، HL-06، HL-15، HL-38.

### `lib/features/hos/domain/repositories/hos_audit_repository.dart` (6 أسطر، غير فارغ 5)
- **المسؤولية:** عقد مستودع لـ `HosViolation`.
- **الطبقة:** domain ✅ / **الحالة:** سليم تماماً.
- **Issue IDs:** —

### `lib/features/hos/domain/repositories/status_dashboard_repository.dart` (20 سطر، غير فارغ 17)
- **المسؤولية:** عقد مستودع اللوحة + `Either<Failure, …>`.
- **الطبقة:** domain ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/domain/usecases/get_status_dashboard_use_case.dart` (15 سطر، غير فارغ 12)
- **المسؤولية:** تفويض كامل بلا منطق.
- **الطبقة:** domain (usecase) ✅ / **الحالة:** **نمط Pass-Through فارغ** — لا يضيف قيمة فوق `repository.getDashboard()`. ليس مخالفة معمارية صريحة، لكنه SRP مشكوك فيه.
- **Issue IDs:** HL-10 (ملاحظة).

### `lib/features/hos/domain/usecases/get_weekly_recap_use_case.dart` (15 سطر، غير فارغ 12)
- نفس النمط أعلاه. **الحالة:** سليم/فارغ.
- **Issue IDs:** HL-10 (ملاحظة).

### `lib/features/hos/domain/usecases/update_duty_status_use_case.dart` (18 سطر، غير فارغ 15)
- نفس النمط أعلاه. **الحالة:** سليم/فارغ.
- **Issue IDs:** HL-10 (ملاحظة).

## A.2 — `lib/features/hos/data/**` (4 ملفات)

### `lib/features/hos/data/providers/hos_audit_providers.dart` (14 سطر، غير فارغ 12)
- **المسؤولية:** تركيب `HosAuditRepositoryImpl(Hive.box)`.
- **الطبقة:** data/DI ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/data/providers/status_dashboard_repository_providers.dart` (15 سطر، غير فارغ 12)
- **المسؤولية:** تركيب `StatusDashboardRepositoryImpl` من `backend` + `network`.
- **الطبقة:** data/DI ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/data/repositories/hos_audit_repository_impl.dart` (58 سطر، غير فارغ 52)
- **المسؤولية:** تخزين/قراءة المخالفات في Hive بصيغة JSON.
- **الطبقة:** data ✅ / **الحالة:** سليم. `catch` في `line 46-54` **مُبلَّغ** عبر `AppLogger.warning` — ليس ابتلاعاً.
- **Issue IDs:** —

### `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart` (115 سطر، غير فارغ 108)
- **المسؤولية:** نداء `StatusDashboardBackend` + cache + **`_circleForStatus` التي تصنع أرقام HOS مُختلقة**.
- **الطبقة:** data ❌ / **الطبقة الفعلية:** data + **domain/business**.
- **الحالة:** **مخالفة مؤكدة** — `line 86-95` يفترض `Duration(minutes: 35)` المتبقية و`Duration(hours: 2, minutes: 8)` للوردية، وهي أرقام قانونية مُختلقة داخل مستودع بيانات.
- **Issue IDs:** HL-03، HL-11.

## A.3 — `lib/features/hos/presentation/**` (13 ملف)

### `lib/features/hos/presentation/duty_change_message.dart` (32 سطر، غير فارغ 27)
- **المسؤولية:** ترجمة `DutyStampRefusal` → نص.
- **الطبقة:** presentation ✅ / **الحالة:** سليم. يعتمد على ثوابت الرفض من domain (استيراد عقد، جائز).
- **Issue IDs:** —

### `lib/features/hos/presentation/extensions/duty_status_l10n.dart` (52 سطر، غير فارغ 48)
- **المسؤولية:** `displayName(BuildContext)` لـ `DutyStatusCode` و`DutyStatus`.
- **الطبقة:** presentation ✅ / **الحالة:** سليم مع `try/catch` في `line 33` يلغي غياب مفتاح l10n — مقبول وموثّق.
- **Issue IDs:** —

### `lib/features/hos/presentation/pages/change_status_page.dart` (232 سطر، غير فارغ 212)
- **المسؤولية:** عرض خيارات الحالة + نموذج الموقع/الملاحظات + استدعاء `submit()`.
- **الطبقة:** presentation ✅ جزئياً — `line 149` رسالة تحقق **مكتوبة يدوياً** بالإنجليزية لا يمرّ بمترجم اللغة الذي تعرضه بقية الشاشة.
- **Issue IDs:** HL-08.

### `lib/features/hos/presentation/pages/recap_page.dart` (117 سطر، غير فارغ 113)
- **المسؤولية:** عرض جدول الأسبوع + `DurationFormat`.
- **الطبقة:** presentation ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/presentation/pages/status_dashboard_page.dart` (118 سطر، غير فارغ 103)
- **المسؤولية:** shell + تفويض loading/error/data.
- **الطبقة:** presentation ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/presentation/providers/change_status_provider.dart` (397 سطر، غير فارغ 353)
- **المسؤوليات (17 عضواً):** `DutyStatusOption` (5 دوال/مُعيدات: `toDutyStatus`, `isYardMoves`, `displayName`, `fromCurrent`, `fromStatusCode`) + `ChangeStatusState` (7: `selectedStatus`, `isYardMoves`, `isAnnotationRequired`, `hasValidCustomLocation`, `isLocationValid`, `isValid`, `copyWith`) + `ChangeStatusNotifier` (5: `selectOption`, `updateNotes`, `updateCustomLocation`, `updateLocation`, `submit`).
- **هل تحقّق عمل داخل الـ notifier؟** **نعم، مخالفة مؤكدة** — `line 278-295`: رفض الحركة، رفض PC/YM غير المصرّح، اشتراط الملاحظات.
- **هل وصول مباشر لمستودع/مصدر بيانات؟** **لا** — يتعامل مع `hosStatusProvider` (application) ومع `statusDashboardProvider`. ✅
- **أرقام أعمال:** `line 174` (`length >= 5 && <= 60`)، `line 182` (`notes.length >= 4`)، `line 284/289` (رسائل رفض إنجليزية صريحة).
- **الطبقة:** presentation ❌ جزئياً — يحتوي قواعد تحقق نطاق/إلزام.
- **Issue IDs:** HL-08، HL-12.

### `lib/features/hos/presentation/providers/hos_engine_provider.dart` (83 سطر، غير فارغ 71)
- **المسؤولية:** تركيب `HosCalculator`/`HosStateMachine`/`HosRulesEngine`/`DutyStatusTracker` + اشتقاق `currentSpeedKmhProvider` و`isVehicleMovingProvider`.
- **الطبقة:** presentation/DI ✅ (التركيب مشروع هنا في هذا المشروع).
- **مخالفة:** `line 8` يستورد `../../../logs/data/providers/log_repository_providers.dart` — **presentation → data**، وهو نمط مشروع في هذا المشروع لكن هناExists لأنه يعكس أن `DutyStatusTracker` (domain) يحتاج مستودعاً من ميزة أخرى.
- **Issue IDs:** HL-01، HL-13.

### `lib/features/hos/presentation/providers/hos_provider.dart` (159 سطر، غير فارغ 140)
- **المسؤوليات:** تهيئة `HosNotifier`، اشتراك `eldEventsStreamProvider`، اشتراك `onTransition`، مؤقّت تحديث كل دقيقة (`line 78`)، **`_processAndLogViolations` التي تكتب مباشرة إلى `hosAuditRepositoryProvider` (`line 140`)**، `changeStatus` الذي يحوّل `DutyStatus → DutyStatusCode` بـ `switch` يدوي (`line 113-130`).
- **الطبقة:** presentation ❌ — يصل إلى مستودع domain مباشرة لتدقيق المخالفات، ويكرر مطابقة رمز الحالة.
- **Issue IDs:** HL-13، HL-14.

### `lib/features/hos/presentation/providers/recap_provider.dart` (38 سطر، غير فارغ 31)
- **المسؤولية:** `FutureProvider` + اشتراك `appEventBus` + بوابة الجلسة.
- **الطبقة:** presentation ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/presentation/providers/status_dashboard_providers.dart` (145 سطر، غير فارغ 127)
- **المسؤوليات:** `_engineStatusCode` مطابقة يدوية (`line 18-31`)، `StatusDashboardNotifier.build` مع 3 اشتراكات، `refresh` مع بوابة جلسة، مؤقّت `Duration(minutes: 1)` في `line 86`.
- **الطبقة:** presentation ❌ جزئياً — `_engineStatusCode` تكرّر لـ `DutyStatusOption.toDutyStatusCode` (`change_status_provider.dart:37`) و`HosNotifier._mapStatus` (`hos_provider.dart:59`).
- **Issue IDs:** HL-14.

### `lib/features/hos/presentation/widgets/driving_lock_screen.dart` (57 سطر، غير فارغ 54)
- **المسؤولية:** شاشة حجب أثناء القيادة + تجاوز مطوّر بنقرة مزدوجة.
- **الطبقة:** presentation ✅ — لكن `line 7` `import '../../../home/presentation/pages/home_page.dart'` **مقايضة لأثر جانبي**: الاستيراد موجود للحصول على `developerBypassDrivingScreenProvider`، وهو provider من feature أخرى كاملة.
- **Issue IDs:** HL-15 (اقتران)، ومخاطرة منفصلة: تجاوز قاعدة FMCSA بنقرة مزدوجة (مشروط بـ `kDebugMode`).

### `lib/features/hos/presentation/widgets/location_display_widget.dart` (39 سطر، غير فارغ 35)
- **المسؤولية:** عرض إحداثيات GPS من `trackingStateProvider`.
- **الطبقة:** presentation → tracking (presentation) ✅ — اقتناع حالة من feature أخرى عبر provider عام مقبول.
- **الحالة:** سليم (يستخدم `.select` لتقليل إعادة البناء).
- **Issue IDs:** —

### `lib/features/hos/presentation/widgets/status_option_tiles.dart` (70 سطر، غير فارغ 62)
- **المسؤولية:** ويدجت بلاطة اختيار.
- **الطبقة:** presentation ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart` (150 سطر، غير فارغ 139)
- **المسؤولية:** جدول المؤشرات الأربعة.
- **محتوى الملف:** `_descriptions()` تختار نص الوصف من `RegulatoryConstraints` أو من l10n، و`_IndicatorRow` يحدد `isCritical` بـ `indicator.value <= const Duration(hours: 1)` (`line 105`) — **عتبة عمل داخل widget**.
- **الطبقة:** presentation ❌ جزئياً.
- **Issue IDs:** HL-03.

### `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart` (365 سطر، غير فارغ 331)
- **المسؤولية:** الدائرة المركزية الكبيرة + `_ThemeToggleButton` + `CustomPainter`.
- **المحتوى الحاسم:** الدالة `build` (`line 98-267`) تنفّذ **حساب HOS كاملاً**: اختيار الحد الحاكم، دالة `remainingOf()`، العد التنازلي الحي، نسبة الاستهلاك، تحديد اللون. وثوابت `Duration(hours: 11)` / `8` / `14` و`Duration(minutes: 15)` مثبتة في `line 125/128/142/145/179`.
- **الطبقة:** presentation ❌ **مخالفة حرجة مؤكدة.**
- **Issue IDs:** HL-03، HL-16.

### `lib/features/hos/presentation/widgets/status_dashboard/operational_alerts_banner.dart` (93 سطر، غير فارغ 84)
- **المسؤولية:** بانر حالة الاتصال + تنبيهات العتاد.
- **الطبقة:** presentation → connection ✅ / **الحالة:** سليم.
- **Issue IDs:** —

## A.4 — `lib/features/logs/domain/**` (10 ملفات)

### `lib/features/logs/domain/daily_form_rules.dart` (93 سطر، غير فارغ 83)
- **المسؤولية الفعلية:** قواعد التحقق من المقطورة/وثيقة الشحن (SRS 5.5–5.13) — **محتوى قانوني صحيح ومناسب للموقع**.
- **الطبقة المعلنة:** domain
- **الطبقة الفعلية:** domain + **Flutter** (غير مباشر)
- **الحالة:** **مخالفة نقاء confirmed** — `line 7: import '../../../../l10n/app_localizations.dart'`، وتلك الملفات تستورد `import 'package:flutter/widgets.dart';` و`import 'package:flutter_localizations/flutter_localizations.dart';`. كما أن `line 86-90` يختار نصوصاً عربية/إسبانية/إنجليزية **من داخل domain**.
- **Issue IDs:** HL-17.

### `lib/features/logs/domain/log_edit.dart` (57 سطر، غير فارغ 49)
- **المسؤولية:** قاعدة «القيادة الآلية لا تُختصر» + تحليل وقت نموذج التعديل.
- **الطبقة:** domain ✅ / **الحالة:** سليم. ملاحظة: `line 29: final base = logDate ?? DateTime.now();` — استخدام ساعة الحائط كاحتياط داخل domain؛ **مقبول هنا** لأن النتيجة تُرفض لاحقاً في `edit_log_controller.dart:52` إن كانت في المستقبل.
- **Issue IDs:** —

### `lib/features/logs/domain/saved_form_status.dart` (36 سطر، غير فارغ 31)
- **المسؤولية:** قراءة `formStatus` من استجابة JSON.
- **الطبقة الفعلية:** domain + **تحليل استجابة شبكة** (`Map<String, dynamic>`، `'data'`، `'COMPLETED'`).
- **الحالة:** **مخالفة موقع مؤكَّد** — قراءة شكل استجابة HTTP داخل domain بينما `log_repository_impl.dart:359` هو المكان الصحيح.
- **Issue IDs:** HL-18.

### `lib/features/logs/domain/entities/audit_entry.dart` (100 سطر، غير فارغ 89)
- **المسؤولية:** كيان تدقيق + `toMap`/`fromMap` + قراءة طابع زمني مرن.
- **الطبقة:** domain مع **تسريب تمثيل JSON** — `toMap()` (شغرة persistence) داخل الكيان.
- **الحالة:** مخالفة متوسطة (SRP على الكيان). ملاحظة: غير متسق مع `DailyLog` الذي لا يفعل — **عدم اتساق**.
- **Issue IDs:** HL-18.

### `lib/features/logs/domain/entities/daily_form_data.dart` (32 سطر، غير فارغ 29)
- **المسؤولية:** لقطة نموذج اليوم المحفوظ. **الطبقة:** domain ✅ **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/logs/domain/entities/daily_form_update.dart` (27 سطر، غير فارغ 24)
- **المسؤولية:** أمر تحديث نموذج اليوم. **الطبقة:** domain ✅ **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/logs/domain/entities/daily_log.dart` (251 سطر، غير فارغ 236)
- **المسؤولية:** كيان `DailyLog` + `LogEvent`.
- **الطبقة الفعلية:** domain + **عرض**.
- **الحالة:** **مخالفة SRP مؤكدة** — الكيان يحتوي:
  - `dayName` (`line 110-124`) بأسماء إنجليزية `'Today'`, `'Yesterday'`, `['Mon','Tue',…]`
  - `formattedDate` (`line 126-141`) بأشهر `'Jan'..'Dec'` + `_ordinal`
  - `formattedStartTime` (`line 210-214`)، `formattedDuration` (`line 216-220`)
  - **`DateTime.now()` في `line 111`** داخل getter يُحسب عند كل استدعاء.
- **Issue IDs:** HL-19، HL-30.

### `lib/features/logs/domain/entities/log_readiness.dart` (69 سطر، غير فارغ 63)
- **المسؤولية:** كيانات الجاهزية والتعديل المقترح من الناقل.
- **الطبقة:** domain ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/logs/domain/repositories/log_repository.dart` (93 سطر، غير فارغ 85)
- **المسؤولية:** عقد مستودع بـ 16 دالة.
- **الطبقة:** domain ✅ — يستورد `fpdart` و`core/error/failure.dart` و`core/domain/entities/hos_models.dart` (لـ `DutyPeriod`)، وهي **عقد مشتركة لا تنفيذ**.
- **الحالة:** سليم. ملاحظة حجم: 16 عملية في عقد واحد → SRP موزّع على use-cases متعددة.
- **Issue IDs:** HL-10 (ملاحظة).

## A.5 — `lib/features/logs/data/**` (5 ملفات)

### `lib/features/logs/data/datasources/log_local_data_source.dart` (322 سطر، غير فارغ 291)
- **المسؤولية:** Hive read/write للأحداث والفترات والتدقيق + cache + توقيع + `ownerOfCachedLog`.
- **الطبقة:** data ✅ / **الحالة:** سليم بنيوياً. `catch` المتعدد كلها مسجّلة عبر `AppLogger` عدا `line 124` و`line 171` و`line 311` التي تُعيد `[]`/تتخطى بصمت.
- **Issue IDs:** HL-20.

### `lib/features/logs/data/models/daily_log_dto.dart` (143 سطر، غير فارغ 134)
- **المسؤولية:** `fromJson` + `toEntity` مع مطابقة `FormStatus`/`CertificationStatus`.
- **الطبقة:** data ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/logs/data/models/log_model.dart` (133 سطر، غير فارغ 121)
- **المسؤولية:** تحليل event من شكلي wire، تحويل km→mile (`_kmToMiles = 0.621371` في `line 88`).
- **الطبقة:** data ✅ / **الحالة:** سليم. `line 76: DateTime.parse(startTimeStr).toLocal()` — تحويل منطقة زمنية داخل data، مقصود وموثّق.
- **Issue IDs:** —

### `lib/features/logs/data/providers/log_repository_providers.dart` (25 سطر، غير فارغ 21)
- **المسؤولية:** تركيب المستودع من 7 تبعيات.
- **الطبقة:** data/DI ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/logs/data/repositories/log_repository_impl.dart` (539 سطر، غير فارغ 498)
- **المسؤولية:** 16 `@override` + سياسات offline + تحليل `getForm` (استخراج `coDriverId` من `Map` متداخل).
- **الطبقة:** data ✅ / **الحالة:** سليم بنيوياً. **لكنه** يحوي تحليل الاستجابة (`getForm`)، و`line 270` يرمي `ServerException` ليلتقطه `executeWithHandling` — نمط تحويل أخطاء غير متسق لكنه مقبول ومقصود.
- **Issue IDs:** HL-18 (مرتبط).

## A.6 — `lib/features/logs/presentation/controllers/**` (2 ملف)

### `lib/features/logs/presentation/controllers/edit_log_controller.dart` (122 سطر، غير فارغ 105)
- **المسؤوليات (3 فقط):** تهيئة (`build` فارغ)، `saveEvent`، تعريف `EditLogErrorCode` (5 قيم).
- **هل هو controller عرض حقيقي أم منطق عمل متنكر؟** **مختلط — مخالفة مؤكدة.** في `saveEvent`:
  1. **قاعدة قانونية** `line 52`: `// FMCSA § 395: Duty status events cannot be recorded in the future` مع `Duration(minutes: 1)`.
  2. **قاعدة عمل** `line 57`: استدعاء `refuseAutomaticDrivingEdit`.
  3. **كتابة تدقيق بمباشرة المستودع** `line 107: final repo = ref.read(logRepositoryProvider);` ثم `line 108: repo.logAudit(entry)` — **presentation يتجاوز use-case ويتصل بالمستودع مباشرة**.
  4. `catch (e, st) { state = AsyncError(e, st); }` في `line 114` يبتلع النوع، ونوع `EditLogError` مصمَّم — الواجهة تعامله (`edit_log_page.dart:89`) كرسالة عامة.
- **Issue IDs:** HL-12، HL-21، HL-22.

### `lib/features/logs/presentation/controllers/form_tab_controller.dart` (68 سطر، غير فارغ 58)
- **المسؤوليات (2):** حالة `isLoading` + `saveForm`.
- **محتوى العمل:** `line 31` **وصول مباشر للمستودع**: `_ref.read(logRepositoryProvider).saveForm(...)`؛ `line 50` **يكتب في notifier ميزة أخرى**: `_ref.read(logsProvider.notifier).updateLog(...)`؛ `line 58` **يختار نص النجاح** من 4 احتمالات.
- **الحالة:** **مخالفة مؤكدة** — ليس controller عرض، بل use-case مختلط يتصل بالمستودع ومع UI.
- **Issue IDs:** HL-21، HL-22، HL-25.

## A.7 — `lib/features/logs/presentation/pages/**` (9 ملفات)

### `lib/features/logs/presentation/pages/edit_log_page.dart` (433 سطر، غير فارغ 407)
- **المسؤولية:** نموذج تعديل/إضافة حدث + حوار اختيار مركبة مدمج.
- **محتوى داخل `build`:** `line 42` استدعاء `parseEditFormTime` (منطق domain) داخل معالج؛ `line 248-251` و`line 276-282` استدعاء `isFreeTextValid` (قاعدة domain) داخل `validator`.
- **اقتران:** `line 13/14` يستورد `vehicle` domain entity + `vehicle` presentation provider؛ `line 4` يستورد `home/presentation/providers/dashboard_provider.dart`.
- **الحالة:** مخالفة متوسطة (presentation يستدعي دوال domain ويُعيد اشتقاق التحقق بدل الاعتماد على حالة جاهزة).
- **Issue IDs:** HL-13، HL-23.

### `lib/features/logs/presentation/pages/inspection_preview_page.dart` (401 سطر، غير فارغ 382)
- **المسؤولية:** معاينة تفتيش DOT + جدول أحداث + سجل نقل + تنقل تبويبات.
- **محتوى داخل `build`:**
  - `line 190-200` فلترة الأحداث بقائمة **مكتوبة يدوياً** `['ON','D','SB','OFF']` مع تعليق يعترف بعدم اكتمالها: `// Custom filter logic for "Active Events"` / `// Currently keeps duty statuses. Implement exact logic if needed.`
  - `line 204` `context.translateStatus(e.status)`؛ `line 206-211` تنسيق أرقام؛ `line 212 src: 'Auto'` **ثابت يُلفّ لكل سطر**.
  - `_getStatusColor` (`line 273-286`) — خريطة رمز→لون **ثانية** بجانب `StatusColorHelper` الموجودة في `core/utils/status_color_helper.dart`.
  - `line 300-321`: منطق مطابقة يوم يعتمد على المقارنة اليدوية داخل `build` مع `try/catch` يبتلع الاستثناء (`line 317`).
- **اقتران:** `line 14/15/16` يستورد 3 ملفات من `features/inspection` (domain + providers + **presentation widgets**).
- **Issue IDs:** HL-13، HL-24، HL-20، HL-25.

### `lib/features/logs/presentation/pages/logs_list_page.dart` (239 سطر، غير فارغ 225)
- **المسؤولية:** قائمة السجلات + شرائح الحالة + تنقل.
- **محتوى داخل `build`:** `line 168-170` **تنسيق مدة مكرر** ومنفصل عن `DurationFormat` وعن `LogEvent.formattedDuration`:
```dart
: (log.totalDrivingHours < 1
      ? '< 1m'
      : '${log.totalDrivingHours.toStringAsFixed(0)}h ${(log.totalDrivingHours % 1 * 60).toStringAsFixed(0)}m'),
```
- **اقتران:** `line 11: import '../../../home/presentation/widgets/eld_drawer.dart';` — **استيراد widget من feature أخرى** لتضمين الـ drawer.
- **Issue IDs:** HL-19، HL-25، HL-26.

### `lib/features/logs/presentation/pages/log_detail_page.dart` (220 سطر، غير فارغ 211)
- **المسؤولية:** shell + تنقل الأيام + 3 تبويبات + `BottomNavigationBar`.
- **الحالة:** navigation-centric. `line 167: Expanded(child: _buildBodyContent(currentIndex, selectedLog))`.
- **Issue IDs:** HL-26 (ازدواج `BottomNavigationBar` مع `inspection_preview_page.dart:236-266`).

### `lib/features/logs/presentation/pages/audit_trail_page.dart` (93 سطر، غير فارغ 88)
- **المسؤولية:** عرض سجل التدقيق.
- **محتوى داخل `build`:** `line 77-79` `DateFormat('yyyy-MM-dd\nHH:mm').format(e.timestamp.toLocal())` — **تنسيق ثالث للوقت** في المجموعة.
- **الحالة:** تنسيق مكرر.
- **Issue IDs:** HL-26.

### `lib/features/logs/presentation/pages/shipping_documents_page.dart` (170 سطر، غير فارغ 160)
- **المسؤولية:** إدارة قائمة وثائق الشحن عبر `dashboardDataProvider` (feature أخرى).
- **محتوى:** `line 100: RegExp(r'[\p{L}\p{N}\s\-_#/]', unicode: true)` في `FilteringTextInputFormatter` — **نسخة ثانية من نفس النمط المعرَّف في المصدر الصحيح** `daily_form_rules.dart:30-31`.
- **اقتران:** `line 11` استيراد `home/presentation/providers/dashboard_provider.dart`.
- **Issue IDs:** HL-23، HL-25، HL-27.

### `lib/features/logs/presentation/pages/suggested_events_page.dart` (121 سطر، غير فارغ 117)
- **المسؤولية:** تصفية السجلات المعلّمة + تنقل.
- **الحالة:** منطقية (فلترة `requiresAction`). تستورد `AppRoutes` — navigation مقبول.
- **Issue IDs:** —

### `lib/features/logs/presentation/pages/trailers_page.dart` (170 سطر، غير فارغ 160)
- **المسؤولية:** إدارة قائمة المقطورات — **نسخة طبقية مطابقة لـ `shipping_documents_page.dart`** (الهيكل متطابق سطرياً تقريباً).
- **محتوى:** `line 100: RegExp(r'[\p{L}\p{N}\s\-_#]', unicode: true)` — نسخة ثانية.
- **Issue IDs:** HL-23، HL-25، HL-27.

### `lib/features/logs/presentation/pages/unidentified_events_page.dart` (505 سطر، غير فارغ 479)
- **المسؤولية:** قائمتا unclaimed/rejected + 3 مرشّحات (تبويب/مركبة/تاريخ) + 4 إحصاءات + إجراءات claim/reject.
- **محتوى داخل الكود:**
  - `line 71-82` `_applyDateFilter` — **فلترة داخل الـ State class** لا داخل الـ notifier.
  - `line 334` داخل `_StatsRow.build`: `final since = now.subtract(const Duration(hours: 24));` و`line 337: if (!status.contains('DRIV')) return false;` — **مطابقة حالة بالنص الجزئي داخل widget**.
  - `line 423-434` داخل `itemBuilder`: 12 استخراج حقل من `Map` بـ `'${item['x'] ?? ''}'` — **استخراج بيانات خام داخل itemBuilder**.
- **اقتران:** `line 11` يستورد `vehicle/presentation/providers/vehicle_provider.dart`.
- **Issue IDs:** HL-12، HL-13، HL-28.

## A.8 — `lib/features/logs/presentation/providers/**` (7 ملفات)

### `lib/features/logs/presentation/providers/audit_trail_provider.dart` (10 أسطر، غير فارغ 9)
- **المسؤولية:** `FutureProvider` يقرأ من المستودع مباشرة (`line 7: ref.watch(logRepositoryProvider)`).
- **الحالة:** لا use-case، يخالف النمط مقارنة بـ `recap_provider.dart:10-12` الذي يستخدم `GetWeeklyRecapUseCase` — **عدم اتساق مؤكد**.
- **Issue IDs:** HL-21.

### `lib/features/logs/presentation/providers/certify_log_provider.dart` (193 سطر، غير فارغ 163)
- **المسؤوليات (5):** `CertifyLogState`، `CarrierEditResponse` (مع `apiValue = 'ACCEPT'/'REJECT'`)، `_fetchReadiness`، `respondToCarrierEdit`، `certify`.
- **هل تحقّق عمل داخل الـ notifier؟** **نعم** — `line 158: if (!log.isFormComplete) return CertifyFailed(...)`، `line 163` توقيع فارغ مرفوض، `line 168` جلسة مفقودة.
- **بناء حمولة API؟** **نعم** — `line 177: logDate: DateFormat('yyyy-MM-dd').format(log.date)`، `line 178: signatureCertificateId: 'local_drawn'` (سلسلة حرفية تعاقدية).
- **الحالة:** presentation يتحقق من شروط الشهادة القانونية بدل use-case.
- **Issue IDs:** HL-12، HL-29.

### `lib/features/logs/presentation/providers/edit_log_form_provider.dart` (66 سطر، غير فارغ 59)
- **المسؤولية:** حالة نموذج 5 حقول + 4 setters.
- **ملاحظة:** مُعامل `family<…, LogEvent?>` — و`LogEvent` يورث من `Equatable`، لكن `props` في `daily_log.dart:249-250` **يستثني `location`**:
```dart
List<Object?> get props =>
    [id, status, startTime, duration, location, isExpanded];
```
سطران فقط — أي **أن استثناء واحد يكفي**، وهو استثناء حقيقي يُفقد الحالة. هذا **خلل سلوكي مؤكد**.
- **Issue IDs:** HL-30.

### `lib/features/logs/presentation/providers/logs_provider.dart` (352 سطر، غير فارغ 310)
- **المسؤوليات (11 دالة):** `loadLogs`, `selectLog`, `loadSelectedForm`, `loadSelectedLogDetail`, `loadSelectedLogEvents`, `_replaceSelected`, `toggleEventExpansion`, `addEvent`, `updateEvent`, `updateLog` + المُهيّئ.
- **هل وصول مباشر لمستودع؟** **نعم، لكن محقون**: `line 92: final LogRepository _repository;` — لا use-case في المسار.
- **هل فيه قواعد عمل؟** **نعم** — `line 119: const limit = 20;` (حجم صفحة)، `line 148: hasReachedMax: newLogs.length < limit`، `line 161-170` شرط «هل النموذج يحتوي بيانات» و**كتابة في `dashboardDataProvider.notifier`** (feature أخرى)، `line 293/296/301/313/316` بناء `ServerFailure` برسائل إنجليزية صريحة.
- **الحالة:** مخالفة متوسطة–حرجة: use-case مدمج داخل StateNotifier + اقتران ثنائي مع `home`.
- **Issue IDs:** HL-12، HL-21، HL-25، HL-31.

### `lib/features/logs/presentation/providers/log_detail_tab_provider.dart` (5 أسطر، غير فارغ 4)
- **المسؤولية:** `StateProvider<int>` لفهرس التبويب. **الحالة:** سليم تماماً.
- **Issue IDs:** —

### `lib/features/logs/presentation/providers/unidentified_events_provider.dart` (170 سطر، غير فارغ 154)
- **المسؤوليات:** **دوال parsing عامة على مستوى الملف** — `parseUnidentifiedList` (`line 13-17`) و`normalizeUnidentifiedItem` (`line 19-39`) — وكلاهما **مندرج ضمن domain داخل presentation**.
- **هل وصول مباشر لـ backend؟** **نعم، مخالفة مؤكدة** — `line 97: final backend = ref.read(unidentifiedEventsBackendProvider);` ثم `line 103/104/136/151` نداءات. **لا مستودع، لا use-case** — presentation يتجاوز طبقتين.
- **هل تحقّق عمل؟** **نعم** — `line 135: if (annotation.trim().isEmpty) return const ServerFailure(message: 'An annotation is required.');` و`line 150` مقابلها.
- **الواجهة الأمامية:** `List<Map<String, dynamic>>` كـ state — **تسريب شكل خام داخل presentation**.
- **Issue IDs:** HL-21، HL-28، HL-32.

## A.9 — `lib/features/logs/presentation/widgets/**` (12 ملف)

### `lib/features/logs/presentation/widgets/codriver_picker_dialog.dart` (113 سطر، غير فارغ 105)
- **المسؤولية:** حوار اختيار سائق مساعد.
- **اقتران:** `line 5/6` يستورد `codriver` domain entity + provider؛ `line 9` يعيد export للكيان.
- **خلل سطحي:** `line 57: 'Error: ${codriverState.error}'` — **عرض رسالة خطأ خام** بينما المقياس يستخدم `anyErrorUserMessage` في 12 موضعاً آخر داخل `logs`.
- **Issue IDs:** HL-13، HL-33.

### `lib/features/logs/presentation/widgets/log_graph.dart` (101 سطر، غير فارغ 86)
- **المسؤولية:** حساب نقاط Graph-Grid + إحصاءات الجانب.
- **محتوى داخل `build`:** `line 18-19` فرز الأحداث؛ `line 21` اشتقاق `referenceDate` بـ `DateTime.now()`؛ `line 32-67` **حلقة تحسب ساعات كل حالة وتطبّع الرموز**؛ `line 47-53`:
```dart
if (status == 'PC') {
  normalized = 'OFF';
} else if (status == 'YM' || status == 'OTH' || !stats.containsKey(status)) {
  normalized = 'ON';
```
— **قاعدة تطبيع حالة مكتوبة يدوياً** ومكرّرة في `events_tab.dart:117-121` و`inspection_preview_page.dart:194-199`.
- **Issue IDs:** HL-24، HL-34.

### `lib/features/logs/presentation/widgets/status_radio_group.dart` (61 سطر، غير فارغ 57)
- **المسؤولية:** مجموعة أزرار اختيار الحالة.
- **محتوى:** `line 19-26` خريطة `value→label` **رابعة** لمجموعة الرموز (`OFF/SB/D/ON/PC/YM`)، متكررة عن `DutyStatusCode` في `lib/domain/duty_status/duty_status_code.dart` و`DutyStatus.toShortCode()` في `core/domain/entities/hos_models.dart`.
- **Issue IDs:** HL-24، HL-34.

### `lib/features/logs/presentation/widgets/time_field_widget.dart` (53 سطر، غير فارغ 50)
- **المسؤولية:** حقل عرض الوقت. **الحالة:** سليم (عرضي بحت).
- **Issue IDs:** —

### `lib/features/logs/presentation/widgets/time_picker_sheet.dart` (175 سطر، غير فارغ 165)
- **المسؤولية:** عجلات اختيار الوقت 12 ساعة.
- **محتوى:** `line 69-72` **ينشئ نص وقت**، والعقد مربوط فقط بتعليق: `// Always use English AM/PM so parseEditFormTime can parse it properly.` والمستهلك هو regex في `domain/log_edit.dart:41-42`.
- **Issue IDs:** HL-35.

### `lib/features/logs/presentation/widgets/vehicle_picker_dialog.dart` (168 سطر، غير فارغ 157)
- **المسؤولية:** حوار اختيار مركبة مع تبديل أسطول الشركة.
- **اقتران:** `line 9` يستورد `vehicle/presentation/providers/vehicle_provider.dart` (presenter من feature أخرى) ويستدعي `loadVehicles`/`loadCompanyVehicles` في `initState` (`line 37/42`) و`build` (`line 135/139/151/152`).
- **Issue IDs:** HL-13.

### `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart` (346 سطر، غير فارغ 324)
- **المسؤولية:** تبويب التوثيق + توقيع + بطاقات تعديل الناقل.
- **محتوى داخل widget:** `line 82-95` `_readableRequirement(String req)` — **تحليل نص + regex لتحويل ISO إلى `HH:mm`** داخل widget.
- **Issue IDs:** HL-29، HL-36.

### `lib/features/logs/presentation/widgets/log_detail_tabs/events_tab.dart` (144 سطر، غير فارغ 134)
- **المسؤولية:** تبويب الأحداث + صف الإجماليات.
- **محتوى داخل widget:** `_StatusTotalsRow.build` `line 113-123` **يجمع ساعات كل حالة داخل widget** ويطبّع `PC→OFF` و`YM→ON` بنسخة ثانية، و`_fmt` `line 106-110` **تنسيق مدة رابع**:
```dart
static String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}
```
- **Issue IDs:** HL-24، HL-26، HL-34.

### `lib/features/logs/presentation/widgets/log_detail_tabs/expanded_content.dart` (59 سطر، غير فارغ 55)
- **المسؤولية:** تفاصيل موسّعة للحدث.
- **محتوى:** `line 25` و`line 31` تنسيق `toStringAsFixed(1)` — نسخة مكررة.
- **Issue IDs:** HL-26.

### `lib/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart` (383 سطر، غير فارغ 358)
- **المسؤولية:** تبويب النموذج (سائق/مركبة/مقطورات/وثائق/سائق مساعد) + حفظ.
- **محتوى داخل `build`:**
  - `line 40-85`: **دمج ثلاثي المصادر يدوي** (serverForm / selectedLog / dashboard) بـ 8 متغيرات محسوبة في `build`.
  - `line 103-114` و`line 190-200` **مدقّقات تكتب منطق العمل في الـ validator** (`int.tryParse`, `'none'`).
  - `line 232-239` استدعاء `_dailyFormPayload` و`line 245` `controller.saveForm` — **تجميع حالة الأمر داخل widget**.
  - `_dailyFormPayload` (`line 335-383`) — **دالة عمل كاملة (48 سطراً)** كـ top-level function داخل ملف widget.
- **اقتران:** `line 7` `home/.../dashboard_provider.dart`، `line 8/9` `vehicle/domain/entities/vehicle.dart` + `vehicle/domain/vehicle_selection.dart`.
- **Issue IDs:** HL-13، HL-21، HL-25، HL-37.

### `lib/features/logs/presentation/widgets/log_detail_tabs/log_event_tile.dart` (166 سطر، غير فارغ 156)
- **المسؤولية:** بلاطة الحدث + حالة موسّعة.
- **محتوى:** `line 14-16` دالة top-level `_formatTimeWithZone` **مغلِّفة فارغة بلا قيمة مضافة** لـ `TimeFormatter.formatTimeWithZone`.
- `line 36-41` `_startedOnAnotherDay` مقارنة تاريخ داخل widget (مقبول، عرضي بحت).
- **Issue IDs:** HL-26.

---

---

# المجموعة (هـ): ميزات DVIR, Inspection, Sync, Tracking, Vehicle

> المصدر: _raw/group_dvir_sync_tracking.md — القسم A.

## A. Per-file findings

### `lib/features/dvir/domain/repositories/dvir_repository.dart` (43 lines, non-empty 43)
- **المسؤوليات:** عقد مجرّد لـ 7 عمليات DVIR.
- **الطبقة معلنة/فعلية:** domain / domain
- **الحالة:** سليم. `fpdart` + `core/error/failure.dart` مقبولان كـ shared kernel. صفر Flutter/Dio/Riverpod.
- **Issue IDs:** —

### `lib/features/dvir/domain/defect_enums.dart` (37, 37)
- **المسؤوليات:** `DefectSeverity` و `DefectLifecycleStage` + `fromWire`.
- **الطبقة:** domain / domain — سليم.
- **Issue IDs:** —

### `lib/features/dvir/domain/dvir_catalog.dart` (64, 64)
- **المسؤوليات:** `DvirCatalogItem`، `DvirDefectSelection`، وثابت `kStandardTrailerDefectItems` (15 عنصر §396.11 للمقطورات).
- **الطبقة:** domain / domain — سليم. ملاحظة Low: `props` (سطر 43) يتجاهل `severity` و`stage`.
- **Issue IDs:** —

### `lib/features/dvir/domain/dvir_list_summary.dart` (33, 33)
- **المسؤوليات:** `DvirListSummary` + `summarizeDvirReports` (عدّاد اشتقاقي).
- **الطبقة:** domain / domain — سليم (تجميع في الـ domain لا في Widget).
- **Issue IDs:** —

### `lib/features/dvir/domain/dvir_signature.dart` (9, 9)
- **المسؤوليات:** `dvirSignatureData(bytes)` → base64.
- **الطبقة:** domain / domain (`dart:convert` فقط) — سليم.
- **Issue IDs:** —

### `lib/features/dvir/domain/dvir_vehicle.dart` (8, 8)
- **المسؤوليات:** `noVehicleSentinel = 'No Vehicle'` + `isUnassignedVehicleId`.
- **الطبقة:** domain — سليم منطقياً، لكن الحرفي يُستهلك في ثلاث طبقات.
- **Issue IDs:** DST-012

### `lib/features/dvir/domain/entities/dvir_defect.dart` (73, 73)
- **المسؤوليات:** `DvirDefect` + `DvirRepairAction` + `DvirDefectCertification`.
- **الطبقة:** domain — سليم، لكن `severity`/`stage` نصّان خامان رغم وجود enums.
- **Issue IDs:** DST-013

### `lib/features/dvir/domain/entities/dvir_report.dart` (266, 266)
- **المسؤوليات:** كيان + 3 enums + `DvirTrailer` + مشتقّان (`vehicleOperationalStatus`, `retentionUntil` 3 أشهر) + `copyWith` (30 حقلاً).
- **الطبقة:** domain — سليم: قواعد العمل في مكانها الصحيح.
- **Issue IDs:** —

### `lib/features/dvir/data/mappers/dvir_mappers.dart` (208, 208)
- **المسؤوليات:** `parseDvirCatalog`، `_findList`، `defectSelectionToWire`، `_defects`، `buildDvirCreateBody` (+ `extractDetects` داخلي).
- **الطبقة:** data / data — لكن `buildDvirCreateBody` يطبّع قاعدة عمل DVIR-09.
- **Issue IDs:** DST-005, DST-006

### `lib/features/dvir/data/mappers/dvir_defect_mappers.dart` (91, 91)
- **المسؤوليات:** `parseDvirDefect`، `parseDvirDefectList`، helpers.
- **الطبقة:** data / data — **نظيف تماماً**.
- **Issue IDs:** —

### `lib/features/dvir/data/repositories/dvir_repository_impl.dart` (388, 388)
- **المسؤوليات:** 7 عمليات + `guardedNetwork` + بناء جسم الإنشاء + **DTO→entity mapping داخلي** (`_mapDtoToEntity`, 61 سطراً) + `_parseDate`/`_parseInspectionType`/`_parseVehicleCondition`.
- **الطبقة:** data / data + business rule (انحراف جزئي).
- **Issue IDs:** DST-004, DST-005, DST-006, DST-007

### `lib/features/dvir/data/providers/dvir_repository_providers.dart` (17, 17)
- **المسؤوليات:** تركيب `DvirRepositoryImpl`.
- **الطبقة:** data/DI — سليم؛ يستورد `sync/data/providers` (data-to-data).
- **Issue IDs:** DST-018

### `lib/features/dvir/presentation/extensions/dvir_catalog_extensions.dart` (9, 9)
- **المسؤوليات:** `label(loc)` لعنصر الكتالوج.
- **الطبقة:** presentation / presentation — سليم (تعليق الملف يبرر الموقع).
- **Issue IDs:** —

### `lib/features/dvir/presentation/extensions/dvir_status_extensions.dart` (37, 37)
- **المسؤوليات:** `label` + `color` لـ `VehicleOperationalStatus` و `DvirConditionStatus`.
- **الطبقة:** presentation — سليم بنيوياً؛ يحوي نصوصاً خارج l10n.
- **Issue IDs:** DST-011

### `lib/features/dvir/presentation/pages/dvir_list_page.dart` (340, 340)
- **المسؤوليات:** Scaffold + `_DvirSummaryRow` + `ActiveDefectsSection` + `_DvirCard`.
- **الطبقة:** presentation — تصنيف حالة العيب بمقارنة نص wire داخل Widget.
- **Issue IDs:** DST-014

### `lib/features/dvir/presentation/pages/dvir_form_page.dart` (690, 690) — **الأخطر في المجموعة**
- **المسؤوليات المقاسة (11):** 6 `TextEditingController`؛ `SignatureController` + listener؛ 3 دوال فتح كتالوج العيوب؛ نافذة الحالة؛ منتقي الوقت؛ منتقي المركبة؛ صفحة المقطورات؛ تدفق مراجعة §396.13؛ **حلّ `deviceId`**؛ بناء `DvirReport`؛ تنسيق الإرسال.
- **الطبقة:** presentation / presentation + business validation + **اختراع معرّف**.
- **Issue IDs:** DST-001, DST-006, DST-012

### `lib/features/dvir/presentation/pages/dvir_detail_page.dart` (486, 486)
- **المسؤوليات:** عرض قراءة فقط + `_DetailBody` + 5 widgets فرعية.
- **الطبقة:** presentation — سليم؛ `_DefectCard` يستخدم `DefectLifecycleStage.values` بشكل صحيح؛ `catch (_)` مع بديل عرض = guard مقبول.
- **Issue IDs:** —

### `lib/features/dvir/presentation/providers/dvir_provider.dart` (325, 325)
- **المسؤوليات:** `DvirState` + `DvirNotifier` (5 عمليات) + `dvirCatalogProvider` + `activeVehicleDefectsProvider`.
- **الطبقة:** presentation — قاعدة §396.13 داخل State؛ تحقق توقيع؛ اعتماد ميت.
- **Issue IDs:** DST-003, DST-017

### `lib/features/dvir/presentation/widgets/active_defects_section.dart` (257, 257)
- **المسؤوليات:** قائمة العيوب النشطة + حوار تفاصيل يتحدّث من الخادم.
- **الطبقة:** presentation + **وصول مباشر لمستودع data**؛ تصنيف شدة بـ substring؛ ابتلاع الفشل.
- **Issue IDs:** DST-008, DST-014

### `lib/features/dvir/presentation/widgets/defects_modal.dart` (153, 153)
- **المسؤوليات:** حوار checkbox للكتالوج الحي + ملاحظة لكل بند.
- **الطبقة:** presentation — **سليم** (يقرأ `dvirCatalogProvider` لا المستودع).
- **Issue IDs:** —

### `lib/features/dvir/presentation/widgets/defect_card.dart` (58, 58)
- **المسؤوليات:** عرض عيب + زر إزالة.
- **الطبقة:** presentation — **نظيف**.
- **Issue IDs:** —

### `lib/features/dvir/presentation/widgets/dvir_form_components.dart` (199, 199)
- **المسؤوليات:** 5 widgets تخطيطية.
- **الطبقة:** presentation — **نظيف** (ألوان مثبتة = مرئية لا معمارية).
- **Issue IDs:** —

### `lib/features/dvir/presentation/widgets/dvir_form_sections.dart` (498, 498)
- **المسؤوليات:** 10 أقسام نموذج + `_ReadOnlySignature`.
- **الطبقة:** presentation + **تحقق عمل بنصوص ثلاثية اللغة مكتوبة يدوياً**.
- **Issue IDs:** DST-011

### `lib/features/dvir/presentation/widgets/previous_dvir_review_modal.dart` (74, 74)
- **المسؤوليات:** حوار عرض المراجعة السابقة (يستقبل `previousDefects` جاهزةً).
- **الطبقة:** presentation — **نظيف**.
- **Issue IDs:** —

### `lib/features/dvir/presentation/widgets/status_modal.dart` (81, 81)
- **المسؤوليات:** اختيار `DvirConditionStatus` (يعيد enum لا نص wire).
- **الطبقة:** presentation — **سليم**.
- **Issue IDs:** —

### `lib/features/inspection/data/mappers/inspection_mappers.dart` (120, 120)
- **المسؤوليات:** `readTransferOutcome`، `parseInformationPacket`، `parseTransferAudit`.
- **الطبقة:** data / data — **نظيف**.
- **Issue IDs:** —

### `lib/features/inspection/data/providers/inspection_repository_providers.dart` (15, 15)
- **المسؤوليات:** تركيب `InspectionRepositoryImpl(backend, networkInfo, syncEngine)`.
- **الطبقة:** data/DI — تمرير `SyncEngine` كوسيط ثالث اختياري إلى مستودع.
- **Issue IDs:** DST-018

### `lib/features/inspection/data/repositories/inspection_repository_impl.dart` (266, 266)
- **المسؤوليات:** 7 عمليات + **كاش `static` عام (4 حقول)** + **توليد ملف FMCSA CSV داخل مسار offline** + تسييل حدث للمزامنة.
- **الطبقة:** data / data + global mutable state + بروتوكول نصي للواجهة.
- **Issue IDs:** DST-002, DST-016

### `lib/features/inspection/data/services/fmcsa_eld_output_generator.dart` (208, 208)
- **المسؤوليات:** توليد CSV متوافق 49 CFR Part 395 Appendix A وكتابته على القرص.
- **الطبقة:** data/service.
- **الحالة — نتيجة الفحص المطلوب:** **الفرضية مرفوضة**: لا `import 'package:pdf'` ولا `'package:printing'` ولا `'package:share_plus'` في هذا الملف. بحث شامل على `lib/` أثبت أن `share_plus` يظهر **حصرياً** في `send_logs_page.dart:2`. الاستيرادات الفعلية: `dart:io` + `path_provider` + `intl` + `logger` + domain entities. **لا طبقة عرض داخل طبقة البيانات هنا.**
- **Issue IDs:** DST-009

### `lib/features/inspection/domain/inspection_transfer.dart` (58, 58)
- **المسؤوليات:** `TransferMethod` + `isValidInspectionComment` (4–60) + `TransferOutcome` + `PacketLine` + `InformationPacketView`.
- **الطبقة:** domain / domain — نظيف؛ لكن التحقق مُكرَّر في presentation.
- **Issue IDs:** DST-015

### `lib/features/inspection/domain/transfer_audit.dart` (31, 31)
- **المسؤوليات:** `TransferAuditRow` + `isEmpty`.
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/inspection/domain/repositories/inspection_repository.dart` (43, 43)
- **المسؤوليات:** عقد مجرّد لـ 7 عمليات.
- **الطبقة:** domain — سليم.
- **Issue IDs:** —

### `lib/features/inspection/presentation/pages/dot_inspection_page.dart` (73, 73)
- **المسؤوليات:** Scaffold + `PopScope` + تبديل start/active.
- **الطبقة:** presentation — يستدعي `accountProvider.notifier.fetchMyAccount()` كأثر جانبي.
- **Issue IDs:** DST-019

### `lib/features/inspection/presentation/pages/inspection_active_view.dart` (145, 145)
- **المسؤوليات:** عرض السجل النشط + تنقّل الأيام + جدول + رسم بياني.
- **الطبقة:** presentation — `coDriverId` يُبنى بinterpolation حرفية معطّلة (`'\${...}'`) = عيب سلوكي محتمل لا مخالفة معمارية.
- **Issue IDs:** —

### `lib/features/inspection/presentation/pages/inspection_start_view.dart` (210, 210)
- **المسؤوليات:** 4 أقسام صلاحيات fail-closed + `inspectionDisplayText` (دالة pure) + `_push`.
- **الطبقة:** presentation — **في الغالب نظيف**.
- **Issue IDs:** —

### `lib/features/inspection/presentation/pages/send_logs_page.dart` (332, 332)
- **المسؤوليات:** نموذج بريد/تعليق + قناة + **كتابة سجل تدقيق عبر مستودع logs** + **مشاركة عبر `share_plus`** + تفكيك `OFFLINE_GENERATED:`.
- **الطبقة:** presentation + **اعتماد على data layer لميزة أخرى**.
- **Issue IDs:** DST-016, DST-021

### `lib/features/inspection/presentation/providers/inspection_provider.dart` (367, 367)
- **المسؤوليات:** `InspectionState` + `InspectionNotifier` (start/selectDay/end/sendLogs) + `informationPacketProvider` + `isValidInspectionPin`.
- **الطبقة:** presentation — قاعدة عمل **ميتة**؛ ثابت `days: 8`.
- **Issue IDs:** DST-015

### `lib/features/inspection/presentation/providers/dot_inspection_providers.dart` (60, 60)
- **المسؤوليات:** 3 providers عبر `InspectionRepository`.
- **الطبقة:** presentation — سليم؛ `days: 8` مكرر.
- **Issue IDs:** DST-015

### `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart` (176, 176)
- **المسؤوليات:** رسم 24h + `_hourOf` (5 صيغ وقت) + `_rowOf` (تصنيف duty code بنص حر و5 regex).
- **الطبقة:** presentation + **parsing وتصنيف أعمال**.
- **Issue IDs:** DST-020

### `lib/features/inspection/presentation/widgets/inspection_log_header_table.dart` (259, 259)
- **المسؤوليات:** جدول RODS + **~25 getter اشتقاقية** (سلسلة أفضلية log→day→screen، دمج القوائم، تركيبcarrier).
- **الطبقة:** presentation + قواعد اشتقاق وقواعد 49 CFR §395.8(k).
- **Issue IDs:** DST-010

### `lib/features/sync/data/datasources/sync_local_data_source.dart` (60, 60)
- **المسؤوليات:** عقد + Impl على `SharedPreferences` بمفتاحَي `'sync_queue'` و `'last_sync_time'`.
- **الطبقة:** data / data — `catch (e) { return []; }` (سطر 28) ابتلاع صامت لتلف JSON.
- **Issue IDs:** DST-008, DST-025

### `lib/features/sync/data/models/sync_item_model.dart` (56, 56)
- **المسؤوليات:** `SyncItemModel extends SyncItem` + `fromJson`/`toJson`/`fromEntity`.
- **الطبقة:** data / data — النموذج **يرث** كيان الـ domain.
- **Issue IDs:** DST-022

### `lib/features/sync/data/providers/sync_providers.dart` (148, 148)
- **المسؤوليات:** تركيب 5 providers + **تعريف `MockRemoteEventDispatcher` و `FailClosedRemoteEventDispatcher`** داخل ملف DI + اشتراكات شبكة.
- **الطبقة:** data/DI + أصناف سلوكية.
- **Issue IDs:** DST-018, DST-023

### `lib/features/sync/data/repositories/memory_offline_queue.dart` (145, 145)
- **المسؤوليات:** تنفيذ ثانٍ لـ `OfflineQueue` في الذاكرة.
- **الطبقة:** data / data — **مطلوب فعلاً**: يُستخدم في بيئة `mock` (`sync_providers.dart:64-67`) وفي 4 ملفات اختبار. **ليس تكراراً زائداً.** تباين سلوكي واحد مع SQLite.
- **Issue IDs:** DST-005b

### `lib/features/sync/data/repositories/sqlite_offline_queue.dart` (382, 382)
- **المسؤوليات:** 3 جداول + ترقية v1→v3 + معاملتان ذريتان (`_park`, `releaseToPending`).
- **الطبقة:** data / data — **خلاصة الفحص المطلوب: نظيف معمارياً**. منطق retry/idempotency **ليس** هنا بل في `SyncEngine` + `RetryPolicy` = قرار صحيح. الاستثناء الوحيد: `assert()` كقاعدة عمل.
- **Issue IDs:** DST-005b, DST-024

### `lib/features/sync/data/repositories/sync_repository_impl.dart` (156, 156)
- **المسؤوليات:** **طابور مزامنة ثانٍ بالكامل** على `SharedPreferences` + retry بـ `_maxRetries = 3`.
- **الطبقة:** data / data — ازدواجية منظومة كاملة + سياسة retry متعارضة.
- **Issue IDs:** DST-025

### `lib/features/sync/data/repositories/traccar_remote_event_dispatcher.dart` (322, 322)
- **المسؤوليات:** توجيه 6 أنواع أحداث + سياج الملكية `_authorize` + حل الملكية `_resolveOwnership` + `_mapResult` موحّد.
- **الطبقة:** data / data + security fence — السياج قرار تصميمي مقصود؛ التوجيه بـ `switch` على `String`.
- **Issue IDs:** DST-026

### `lib/features/sync/domain/entities/dispatch_auth.dart` (19, 19)
- **المسؤوليات:** `DispatchAuthContext` value object.
- **الطبقة:** domain — **نظيف تماماً**.
- **Issue IDs:** —

### `lib/features/sync/domain/entities/event_ownership.dart` (109, 109)
- **المسؤوليات:** `OwnerEvidence` + `EventOwnership` + `EventOwnershipResolver.resolve`.
- **الطبقة:** domain — قرار ممتاز (استخراج pure)، لكن `_directDriverId` يفحص أنواعاً بنصوص خام.
- **Issue IDs:** DST-026

### `lib/features/sync/domain/entities/pending_event.dart` (72, 72)
- **المسؤوليات:** `SyncPriority` + `PendingEvent` + `RetryPolicy.calculateNextRetry`.
- **الطبقة:** domain — **`calculateNextRetry` لا يملك أي مسار يُعيد `null`** رغم نوعه `DateTime?`.
- **Issue IDs:** DST-027

### `lib/features/sync/domain/entities/quarantine_record.dart` (41, 41)
- **المسؤوليات:** `StoredEventState` + `OwnershipProof` + `QuarantineRecord`.
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/sync/domain/entities/sync_item.dart` (100, 100)
- **المسؤوليات:** `SyncEventType` + `SyncStatus` + `SyncItem` + `SyncState`.
- **الطبقة:** domain — نظيف (لكن ضمن منظومة مكرَّرة).
- **Issue IDs:** DST-025

### `lib/features/sync/domain/repositories/offline_queue.dart` (49, 49) — **المطلوب مقتبساً**
- **المسؤوليات:** عقد الطابور: `enqueue`، `getReadyEvents`، `updateEvent`، `removeEvent`، `count`، `moveToDeadLetter`، `moveToDeferred`، `moveToQuarantine`، `getDeferred`، `getQuarantined`، `releaseToPending`.
- **الطبقة:** domain / domain.
- **خلاصة الفحص المطلوب:** ❌ **لا تتسرب أنواع sqflite إطلاقاً**. الاقتباس الحرفي:
```dart
// lib/features/sync/domain/repositories/offline_queue.dart:1-6
import '../entities/pending_event.dart';
import '../entities/quarantine_record.dart';

abstract class OfflineQueue {
  /// إضافة حدث للطابور
  Future<void> enqueue(PendingEvent event);
```
  العقد بالكامل مكتوب بنطاقات `PendingEvent`، `StoredEventState`، `OwnershipProof`، `QuarantineRecord`، `String`، `int`، `bool` — **صفر `Database`، صفر `sqflite`**. **الحكم: نظيف.**
- **Issue IDs:** —

### `lib/features/sync/domain/repositories/sync_repository.dart` (25, 25)
- **المسؤوليات:** عقد الطابور الثاني (`SyncItem`).
- **الحالة:** سليم لكنه مكرّر معرفياً مع `OfflineQueue`.
- **Issue IDs:** DST-025

### `lib/features/sync/domain/usecases/sync_engine.dart` (226, 226)
- **المسؤوليات:** `RemoteEventDispatcher` port + `SyncEngine` (submitEvent، submitEventAndReport، releaseEligible، triggerSync، _settle، _completeReport) + **تزامن داخلي بـ Completer**.
- **الطبقة:** domain/usecase.
- **Issue IDs:** DST-027, DST-028

### `lib/features/sync/presentation/providers/sync_engine_provider.dart` (4, 4)
- **المسؤوليات:** جسر توافق (`export '../../data/providers/sync_providers.dart';`).
- **الحالة:** بلا محتوى؛ يعكس أن providers انزلقت إلى data أصلاً.
- **Issue IDs:** DST-018

### `lib/features/sync/presentation/providers/sync_provider.dart` (76, 76)
- **المسؤوليات:** `syncStateProvider` + `SyncNotifier` + `Timer.periodic(1 minute)`.
- **الطبقة:** presentation — Riverpod داخل providers = **صحيح**؛ لا مخالفة.
- **Issue IDs:** DST-025

### `lib/features/sync/presentation/widgets/sync_status_indicator.dart` (46, 46)
- **المسؤوليات:** شارة حالة المزامنة.
- **الطبقة:** presentation — نظيف، لكنه يعرض طابوراً **غير مستخدم في الإنتاج**.
- **Issue IDs:** DST-025

### `lib/features/tracking/data/datasources/live_tracking_data_source.dart` (168, 168)
- **المسؤوليات:** منفذ `LiveTrackingDataSource` + `MockLiveTrackingDataSource` + `ProcessorLiveTrackingDataSource` + **مزوّد Riverpod**.
- **الطبقة:** data/datasource → data + DI.
- **الحالة:** مزوّد داخل `datasources/`؛ Mock في كود الإنتاج؛ منفذ يكشف `EldEvent`/`LocationPoint`؛ `start()` غير awaited.
- **Issue IDs:** DST-023, DST-029, DST-030

### `lib/features/tracking/data/datasources/native_event_channel_client.dart` (164, 164)
- **المسؤوليات:** `NativeLocationQualityValidator` (5 قواعد جودة) + `NativeEventChannelClient` (اشتراك EventChannel + `_parseEvent`).
- **الطبقة:** data — `_parseEvent` صحيح؛ **لكن قواعد الجودة (5 د، 60 د، ترتيب) أعمال**.
- **Issue IDs:** DST-031

### `lib/features/tracking/data/datasources/traccar_data_source.dart` (135, 135)
- **المسؤوليات:** adapter يدمج 4 عملاء Traccar + اشتقاق `ConnectionStatus` + بناء `TrackingEvent`.
- **الطبقة:** data — **نظيف**؛ `_apiClient` معلّم `// ignore: unused_field` و`getLastEvent` يُرجع `null` دائماً (كود ميت Low).
- **Issue IDs:** —

### `lib/features/tracking/data/datasources/tracking_data_source.dart` (26, 26)
- **المسؤوليات:** `TrackingDataSource implements TrackingDataSourcePort` + `start`/`stop`/`getLastEvent`.
- **الطبقة:** data — **نتيجة فحص الـ port**: الـ port حقيقي لكنه ناقص التغطية ⇒ الإضافات خارج العقد.
- **Issue IDs:** DST-032

### `lib/features/tracking/data/datasources/tracking_local_data_source.dart` (69, 69)
- **المسؤوليات:** عقد + Impl على `SharedPreferences` (`'last_location'`, `'tracking_logs'`).
- **الطبقة:** data — `_storage` محقون ومعلّم `// ignore: unused_field` ولا يُستخدم إطلاقاً.
- **Issue IDs:** DST-033

### `lib/features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart` (30, 30)
- **المسؤوليات:** بديل اختبار لـ `TraccarNativeClient`.
- **الحالة:** كود وهمي داخل `lib/data`.
- **Issue IDs:** DST-023

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_api_client.dart` (19, 19)
- **المسؤوليات:** عقد REST لـ Traccar (5 عمليات).
- **الطبقة:** data — `Map<String, dynamic>` نقي داخل data = **مقبول**.
- **Issue IDs:** —

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_api_client_impl.dart` (131, 131)
- **المسؤوليات:** 5 عمليات REST على `ApiClient` + `EldEndpoints`.
- **الحالة:** التفاف الاستثناءات مرتين في الدوال الخمس.
- **Issue IDs:** DST-034

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart` (24, 24)
- **المسؤوليات:** عقد MethodChannel (7 عمليات).
- **الطبقة:** data — نظيف.
- **Issue IDs:** —

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart` (79, 79)
- **المسؤوليات:** 7 نداءات `MethodChannel('com.goldenfeather.eld/traccar')`.
- **الحالة:** ابتلاع `PlatformException` في 3 دوال وإرجاع قيم نجاح زائفة.
- **Issue IDs:** DST-035

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_websocket_client.dart` (21, 21)
- **المسؤوليات:** عقد WebSocket (connect/disconnect/reconnect/3 streams).
- **الطبقة:** data — نظيف.
- **Issue IDs:** —

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_websocket_client_impl.dart` (156, 156)
- **المسؤوليات:** اتصال + backoff أسّي (`1 << attempts` بسقف 60s) + بث.
- **الحالة:** ابتلاع صامت لأخطاء فك التشفير (سطر 87-89).
- **Issue IDs:** DST-035

### `lib/features/tracking/data/models/location_model.dart` (59, 59)
- **المسؤوليات:** `LocationModel extends LocationEntity` + JSON.
- **الطبقة:** data — **وراثة** الكيان + اختراع قيم افتراضية.
- **Issue IDs:** DST-022, DST-036

### `lib/features/tracking/data/providers/tracking_providers.dart` (51, 51)
- **المسؤوليات:** 4 providers.
- **الحالة:** **مزوّدان منفصلان لنفس النوع**؛ `app_initializer` يتجاوز الأول بينما المستودع يستهلك الثاني.
- **Issue IDs:** DST-037

### `lib/features/tracking/data/repositories/tracking_repository_impl.dart` (243, 243)
- **المسؤوليات:** 9 عمليات + **تدفّق صلاحيات كامل** + fallback Geolocator + قراءة config من storage.
- **الطبقة:** data/repository.
- **Issue IDs:** DST-038, DST-039, DST-040

### `lib/features/tracking/data/services/tracking_service.dart` (204, 204)
- **المسؤوليات:** تهيئة config + تطبيع منفذ OsmAnd + 8 عمليات تغليف لـ `TraccarNativeClient` + **تعريف `trackingServiceProvider`**.
- **الطبقة:** data/service + DI.
- **Issue IDs:** DST-029, DST-037, DST-041

### `lib/features/tracking/domain/entities/connection_status.dart` (8, 8)
- **المسؤوليات:** enum خماسي.
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/tracking/domain/entities/location_entity.dart` (141, 141)
- **المسؤوليات:** `LocationEntity` + `TrackingConfigEntity` + `TrackingLogEntity`.
- **الطبقة:** domain — نظيف؛ `LocationEntity.empty()` مصنع пустой (Low).
- **Issue IDs:** —

### `lib/features/tracking/domain/entities/native_location_event.dart` (75, 75)
- **المسؤوليات:** `LocationQualityStatus` + `LocationSource` + `NativeLocationEvent`.
- **الطبقة:** domain — الـ enums هنا لكن منطق استخدامها في data.
- **Issue IDs:** DST-031

### `lib/features/tracking/domain/entities/tracking_event.dart` (98, 98)
- **المسؤوليات:** `TrackingEventSource` + `TrackingEvent` (16 حقلاً).
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/tracking/domain/repositories/tracking_data_source_port.dart` (8, 8)
- **المسؤوليات:** تدفّقان فقط.
- **الطبقة:** domain — **port حقيقي وموضعه صحيح** (domain-owned، نقي، له منفّذ ومستهلك) **لكنه ناقص التغطية**.
- **Issue IDs:** DST-032

### `lib/features/tracking/domain/repositories/tracking_repository.dart` (36, 36)
- **المسؤوليات:** عقد 9 عمليات.
- **الحالة:** سليم؛ لا يغطي دورة التتبع عبر الـ port.
- **Issue IDs:** DST-032

### `lib/features/tracking/domain/usecases/tracking_event_processor.dart` (124, 124)
- **المسؤوليات:** اشتراك في الـ port + توزيع على 3 تدفقات + `_mapToEldEvent` + **`_startMockProcessing`**.
- **الطبقة:** domain/usecase — **يحتوي `Timer.periodic` وبيانات وهمية بإحداثيات مثبتة `24.7136 / 46.6753` و`fromEcm: true`**.
- **Issue IDs:** DST-023, DST-042

### `lib/features/tracking/presentation/providers/tracking_provider.dart` (252, 252)
- **المسؤوليات:** `TrackingState` + `TrackingNotifier` (6 عمليات) + `currentVehicleSpeedProvider`.
- **الطبقة:** presentation — Riverpod في provider = **صحيح**. لكن `Ref` محفوظ داخل الـ notifier + `isDrivingChecker` قابل للكتابة من خارج ⇒ service-locator خفيف؛ ونصوص إنجليزية غير مترجمة تصل الواجهة.
- **Issue IDs:** DST-011, DST-043

### `lib/features/tracking/presentation/providers/tracking_providers.dart` (15, 15)
- **المسؤوليات:** جسر توافق (`export`) + `gpsStatusProvider`.
- **الحالة:** **مزوّد Riverpod في providers presentation** بينما بقية مزوّدات التتبع في data ⇒ ازدواج طبقتين.
- **Issue IDs:** DST-029

### `lib/features/vehicle/data/providers/vehicle_repository_providers.dart` (23, 23)
- **المسؤوليات:** `vehicleBackendProviderAlias` (تمرير صوري بلا قيمة) + `vehicleRepositoryProvider`.
- **الطبقة:** data/DI — سليم (Low في Alias).
- **Issue IDs:** —

### `lib/features/vehicle/data/repositories/vehicle_repository_impl.dart` (81, 81)
- **المسؤوليات:** 3 عمليات + `_readList` + `_message`.
- **الطبقة:** data — **نظيف**؛ `catch (_)` محوَّل إلى `Failure` مقبول.
- **Issue IDs:** DST-047

### `lib/features/vehicle/domain/entities/vehicle.dart` (68, 68)
- **المسؤوليات:** كيان `Vehicle` (14 حقلاً) + `displayName` + `shortDisplayName`.
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/vehicle/domain/repositories/vehicle_repository.dart` (15, 15)
- **المسؤوليات:** عقد 3 عمليات.
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/vehicle/domain/vehicle_selection.dart` (153, 153) — **المطلوب فحصه**
- **المسؤوليات الفعلية (3 مختلطة):** (1) قواعد أعمال صرفة: `listedVehicleIsOperable`، `refuseVehicleOperate`، `readOperableUniqueId`. (2) **قراءة جسم الخادم**: `parseVehicleList`، `readVehicle`، `_vehicleRows`، `_asMap`، `_text`، `_bool`. (3) **خريطة أخطاء HTTP**: `vehicleOperateFailure` (400→rejected، 403→unauthorized، 409→in_use…).
- **الطبقة:** domain / **مختلط**.
- **الحالة:** لا استيراد Flutter/Dio/Riverpod (✅)، لكن **قراءة JSON وربط HTTP في الـ domain**. والأسوأ: القواعد (1) **شابة** — `refuseVehicleOperate` و `VehicleOperateRefusal` لا يُستدعيان من أي مكان في `lib/`؛ `vehicle_provider.dart` يعيد تنفيذها يدوياً بدلالات مختلفة.
- **Issue IDs:** DST-044, DST-045

### `lib/features/vehicle/presentation/pages/select_vehicle_page.dart` (299, 299)
- **المسؤوليات:** Scaffold + بحث + حوار غير مُسند + تنسيق النجاح إلى dashboard و localStorage و go_router.
- **الطبقة:** presentation + side-effects عبر features.
- **Issue IDs:** DST-019, DST-046

### `lib/features/vehicle/presentation/providers/vehicle_provider.dart` (254, 254)
- **المسؤوليات:** `VehicleState` + `VehicleNotifier` + سياج session (bindOwner/reset) + تسلسل `_loadSeq` + `selectVehicle`.
- **الطبقة:** presentation + قاعدة عمل مكرَّرة.
- **Issue IDs:** DST-045, DST-047

### `lib/features/vehicle/presentation/widget/vehicle_card.dart` (124, 124)
- **المسؤوليات:** صف مركبة + شارة + دالة عامة `vehicleErrorText`.
- **الطبقة:** presentation — نظيف (تنظيم الملف فقط).
- **Issue IDs:** —

---



