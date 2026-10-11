# 09 — تحليل الاعتماديات والاقتران

## المنهجية

تم بناء **مخطط استيراد كامل** آلياً من 399 ملف Dart مكتوب يدوياً: **1628 حافة داخلية** (بعد استبعاد استيرادات `package:` و`dart:`)، ثم تصنيف كل حافة حسب الطبقة، ثم تشغيل **خوارزمية Tarjan**Strongly Connected Components) لتحديد الدورات الحقيقية. كل الحواف المذكورة أدناه مأخوذة من هذا المخطط لا من التقدير.

## خريطة الطبقات الفعلية

| الطبقة (المصدر) | عدد الحواف الصادرة |
|---|---|
| `presentation` (كل الميزات) → `core` | 341 |
| `presentation` → `presentation` (عابر للميزات) | 207 |
| `backend` → `backend` | 189 |
| `presentation` → `domain` (نطاقات الميزات) | 110 |
| `core` → `core` | 108 |
| `data` → `domain` | 83 ✅ |
| `backend` → `core` | 78 |
| `data` → `core` | 77 |
| `backend` → `lib/domain` (مشترك) | 64 ✅ |
| `data` → `data` | 53 |
| `domain` → `domain` | 48 |
| `app` → `presentation` | 29 |
| `data` → `backend` | 29 |
| `domain` → `core` | 28 ⚠️ |
| **`presentation` → `data`** | **20** ⚠️ |
| **`presentation` → `backend`** | **14** ⚠️ |
| **`core` → `features`** | **7** ⚠️⚠️ |
| **`data` → `presentation`** | **1** ⚠️⚠️ |

## اتجاه الاعتماديات المرصود

```
routes.dart ──► 25 صفحة ميزة ──► core ──► features ──► routes.dart   ✗
backend    ──► core_providers ──► backend_network_providers           ✗
logs/data  ──► logs/data/providers ──► logs/data/repositories          ✗
core/services/local_storage ⇄ tracking_config_storage                 ✗
```

### 1. انقلاب `core` ← `features` (7 حواف — الأخطر بنيوياً)

`lib/core/` **هو الجذر الداخلي** لكل تطبيق Clean Architecture. وهو يستورد من `features`:

| الملف | السطر | يستورد |
|---|---|---|
| `core/providers/driver_rules_provider.dart` | 2 | `features/account/presentation/providers/rules_screen_provider.dart` |
| `core/events/eld_events_provider.dart` | 3, 5 | `features/tracking/data/datasources/live_tracking_data_source.dart` + `features/tracking/domain/entities/connection_status.dart` |
| `core/di/app_providers.dart` | 3, 7, 10 | `backend/providers/backend_providers.dart`، `features/auth/domain/...`، `features/auth/data/repositories/auth_repository_impl.dart` |

**النتيجة**: دورة `features → core → features`. عملياً: **لا يمكن استخراج أي feature بشكل مستقل**، ولا يمكن reuse لـ `core` في مشروع آخر، ولا يمكن اختبار `core/providers` أو `core/events` دون تحميل شجرة_features كاملة.

`core/di/app_providers.dart:17` يدّعي صراحة: «هذا هو الملف الوحيد المسموح له باستيراد `*impl.dart`» — لكن `presentation` في 14 موضعاً يتجاوزه (انظر جدول `presentation → data` أدناه).

### 2. دورة `routes ⇄ features` من 25 ملفاً

أكبر componente مترابط في المشروع (25 ملفاً). السبب الجذري واحد: **الملفات المولَّدة** (feature routes) تستورد الصفحات، والصفحات تستورد `lib/routes.dart` للحصول على `rootNavigatorKey`. تحقّق:
```dart
// lib/features/home/presentation/widgets/eld_drawer.dart:8
import '../../../../routes.dart';
// lib/routes/home_routes.dart:3
import '../../features/home/presentation/pages/home_page.dart';
```
الملف الوحيد في `core` داخل هذه الدورة: `lib/core/widgets/connection_status_indicator.dart` — مكوّن مشترك في `core` يستورد `app` (CUI-001).

### 3. دورتان ثنائيتان تعبران حدود الطبقات

```
lib/core/network/core_providers.dart
      → lib/backend/providers/backend_network_providers.dart
      → lib/core/network/core_providers.dart
```
و
```
lib/features/logs/data/providers/log_repository_providers.dart
      → lib/features/logs/data/repositories/log_repository_impl.dart
      → lib/features/logs/data/providers/log_repository_providers.dart
```
الأولى تعني أن `core` و`backend` **غير قابلين للتحميل بمعزل** — وهو ما يُفسّر غياب اختبار وحدة فعلي لشبكة `core`.

### 4. `presentation → data` (20 حافة) و `presentation → backend` (14 حافة)

العرض يتجاوز حدّ الـ repository ويستدعي التنفيذ أو عقد البنية التحتية مباشرة:

| الموقع | Nature |
|---|---|
| `logs/presentation/providers/unidentified_events_provider.dart:97` | يستدعي عقد backend |
| `account/presentation/pages/rules_page.dart:13` | يستورد DTO من `backend/adapters` |
| `auth/presentation/widgets/forgot_password_form.dart:4` | يتجاوز طبقات auth ويستدعي عقد بنية تحتية |
| `inspection/presentation/pages/send_logs_page.dart:126-141` | يكتب سجل تدقيق عبر data layer |
| `connection/presentation/providers/hardware_alerts_provider.dart:9-19` | JSON mapping + استدعاء backend |
| `codriver/presentation/providers/team_status_provider.dart:16-35` | ينسّق عمليتين على الخادم ويستخرج JSON |

### 5. `data → presentation` (حافة واحدة، لكن انقلاب كامل)

```
lib/features/sync/data/providers/sync_providers.dart:7-8
```
موسوم بـ `// ignore_architecture` — وهو **زخرفة بلا أي آلية إنفاذ** (CORE-004، BACK-003: `analysis_options.yaml` لا يعرّف أي قاعدة معمارية، و`flutter analyze lib/backend` يعطي `No issues found!`).

## Coupling عبر الميزات — الحكم لكل حافة

الأهم هنا هو **التمييز بين استيراد عقد مشترك واستيراد تنفيذ داخلي**:

| الحافة | الحكم | الدليل |
|---|---|---|
| `LOGS → VEHICLE` | **سليم** | عقود فقط (`VehicleRepository`) |
| `HOS → lib/domain/**` | **سليم** | عقود وقيم مشتركة (`DriverId`, `DutyStatusCode`) |
| `SYNC → BACK` | مقبول | عقود `backend` |
| **`backend → features/account`** | **مخالفة** | 6 استيرادات في 5 ملفات. الجذر: `RulesScreenModel` **لا ينتمي إلى أي طبقة** — هو feature model في `application` يستهلكه `backend/contracts` |
| **`LOGS → HOME`** | **مخالفة** | كتابة حالة في 7 مواضع، لا مجرد قراءة عقد |
| **`LOGS → AUTH`** | مخالفة | استيراد presentation |
| **`CODRIVER → HOS`, `→ TRACKING`** | **مخالفة** | استيراد 5 ملفات presentation لتغذية حارس واحد |
| **`HOME` كمركز مشترك** | **مخالفة بنيوية** | `dashboard_provider.dart` تحوّل HOME إلى «طبقة ترويسة جلسة» تستهلكها 3 ميزات (HOM-001) |
| **`EldDrawer` مملوك من HOME** | **مخالفة** | هيكل التطبيق (app shell) داخل feature، يستورده 5 صفحات (ACC-008) |

## اقتحام `core`

`lib/core/` يحتوي **83 ملفاً** تغطي: network, error, result, config, di, services, storage, time, theme, widgets, domain, providers, session, constants, events, utils, localization, extensions. أربعة منها (**providers, events, di, plus session**) تستورد features — أي أن `core` **ليس جذراً داخلياً، بل حاوية مشتركة مختلطة**. هذا explains لماذا CORE-003 (`app_providers.dart`) وُضع داخل `core` رغم أنه composition root منطقياً.

## الأثر على الأبعاد الأربعة

| البُعد | الأثر |
|---|---|
| **قابلية الاختبار** | `core/network` غير قابل للاختبار معزولاً (دورة مع backend). `MockDailyLogsBackend` مقيّد بنوع `eld_engine`. 38% من العقد غير منفّذ. |
| **قابلية الصيانة** | قاعدة FMCSA جديدة = 7–9 ملفات. حالة DVIR صامتة تحت الموك. فحوص DYIR تتكرر ثلاث مرات. |
| **قابلية التوسّع** | لا يمكن إضافة feature جديدة دون تعديل `core/di` و`app_initializer` (override لا يسري أصلاً — DST-037). |
| **عزل الميزات** | 14 feature موجودة، لكن **11 منها غير مستقلة** في المخطط الفعلي. |

##Force نقطة واحدة

تجميع كل ما سبق: **المشكلة ليست في اتجاه واحد، بل في عدم وجود جذر تركيب واحد**. المزوّدات موزّعة على 7 مجلدات، و`core/di` يجلب `features` مرة واحدة (CORE-031: root واحد من نحو عشرة مستودعات)، و`app_initializer` يفرض overrides على مزوّدات لا يستهلكها أحد.

## جدول تفصيلي
tmp

**عدد الملاحظات في هذا القسم: 70**

--------------------------------------------------
### ISSUE AUTH-001: سياسات حدود الهوية وتسلسل التخزين موضوعة داخل `presentation/providers`
- **Severity:** High
- **Category:** Layer inversion / State-management responsibility
- **Location:** `lib/features/auth/presentation/providers/auth_state_provider.dart:145`, `:147-151`, `:260`, `:292`, `:306`
- **Evidence:**
```dart
// lib/features/auth/presentation/providers/auth_state_provider.dart:145
  Future<void> _storageChain = Future<void>.value();

// :147-151
  Future<void> _runOrdered(Future<void> Function() op) {
    final run = _storageChain.then((_) => op());
    _storageChain = run.catchError((_) {});
    return run;
  }

// :260
          final epoch = SessionEpoch.bump();

// :292
    final epoch = SessionEpoch.bump();
```
- **Current behavior:** الـ `StateNotifier` الموجود في طبقة presentation يملك: (أ) سلسلة تسلسل تسلسلية لكل عمليات حفظ/مسح الجلسة لمنع `clear(A)` المتأخر من محو `save(B)`؛ (ب) صلاحية استدعاء `SessionEpoch.bump()` عند حدود الهوية (نجاح دخول، بدء خروج، طرد إجباري).
- **Why problematic:** هذان قراران *سياسيان* لا علاقة لهما بـ "عرض الحالة". إضافةً، `SessionEpoch` كائن `static` قابل للتغيّر في `core/session/session_epoch.dart:19` يُقرأ من طبقات أخرى (مثل `AuthInterceptor`)، فالقرار المملوك لـ presentation أصبح عقداً عامّاً لا يمكن اختباره أو تبديله دون طبقة العرض.
- **Violated principle:** قاعدة الاعتماد (Dependency Rule): `presentation` يجب أن تنسّق بين `domain`/`application`، لا أن تُعرّف سياستهما. + مبدأ "Policy vs. Mechanism".
- **Current owner:** `AuthNotifier` (presentation).
- **Correct owner:** `domain/session/session_boundary_policy.dart` أو `application/session/session_coordinator.dart`؛ يبقى `AuthNotifier` مستهلكاً لها.
- **Consequences:** (1) استخراج `AuthNotifier` في اختبار وحدة يفرض تهيئة Flutter/Riverpod؛ (2) أي مالك بديل للهوية (أمر طرد إداري مثلاً) سيحتاج لنسخ منطق الـ bump؛ (3) `_storageChain` مربوط بحNotifier واحد، بينما `_localDataSource` قد يُشارك.
- **Recommended correction:** استخرج `SessionCoordinator` في `features/auth/application/session/session_coordinator.dart` يحوي `bump()`, `_storageChain`, `_runOrdered`، واجعل `AuthNotifier` ينفّذ عبره.
- **Related files:** `lib/core/session/session_epoch.dart`, `lib/features/auth/domain/usecases/logout_usecase.dart`, `lib/features/auth/presentation/providers/auth_state_provider.dart`
- **Confidence:** CONFIRMED (المواضع والأكواد مقتبسة حرفياً).

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE AUTH-004: `forgot_password_form.dart` يتجاوز طبقات feature auth ويستدعي عقد البنية التحتية مباشرة، ويتجاوز الترجمة
- **Severity:** High
- **Category:** Layer skip / Localization bypass
- **Location:** `lib/features/auth/presentation/widgets/forgot_password_form.dart:4`, `:51-54`, `:38`
- **Evidence:**
```dart
// lib/features/auth/presentation/widgets/forgot_password_form.dart:4
import '../../../../backend/providers/backend_providers.dart';

// :51-54
    final result = await ref.read(authBackendProvider).requestPasswordReset(
          email: email,
          serverUrl: ref.read(localStorageProvider).serverUrl,
        );

// :38
    if (email.isEmpty || !email.contains('@')) {
```
- **Current behavior:** Widget داخل feature `auth` يتجاوز `domain/repositories` و`data/` بالكامل ويصل إلى `AuthBackend` (عقد بنية تحتية في `lib/backend/`)، ويقرأ `LocalStorageService` مباشرة، ويطبّق قاعدة تحقق مخصّصة (`contains('@')`) بدل `LoginIdentifier` الموجود في نفس الـ feature.
- **Why problematic:** هذه العملية (استعادة كلمة المرور) هي **use case م_missing تماماً** في `auth`. كل طبقة أعلى منها (usecase / repository / datasource) لا تعرف بوجودها ⇒ لا يمكن اختبارها ولا تتبّعها ولا توحيد أسلوب الأخطاء. كما أن قاعدة التحقق موحّدة في مكانين.
- **Violated principle:** لم تُخترق طبقة فقط، بل قُفزت **طبقتان** (domain + data). + مبدأ DRY في التحقق.
- **Current owner:** widget.
- **Correct owner:** `ResetPasswordUseCase` في `features/auth/domain/usecases/reset_password_use_case.dart` يمرّر `LoginIdentifier` ويستدعي `AuthRepository.requestPasswordReset()`؛ التنفيذ يغلّف `AuthBackend` ويطبّق `NetworkInfo`/`guardedNetwork`.
- **Consequences:** (1) استعادة كلمة المرور خارج أي مسار مراقبة/تحليل/تسلسل؛ (2) سلوكها يختلف عن `login` في معالجة الشبكة؛ (3) النصوص العربية/الإنجليزية مدمجة في الـ widget (§C-2).
- **Recommended correction:** أنشئ use-case + repository method، واجعل الـ widget يستهلك `Either<Failure, Unit>`.
- **Related files:** `lib/features/auth/presentation/pages/auth_page.dart:157`, `lib/features/auth/domain/repositories/auth_repository.dart`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE AUTH-005: `splash_page.dart` منسّق إقلاع على مستوى التطبيق موضوع داخل feature المصادقة
- **Severity:** High
- **Category:** Wrong layer / Cross-feature orchestration
- **Location:** `lib/features/auth/presentation/pages/splash_page.dart:32`, `:47-48`, `:62`, `:67`, `:9`
- **Evidence:**
```dart
// lib/features/auth/presentation/pages/splash_page.dart:9
import 'package:permission_handler/permission_handler.dart';

// :47-48
      final locationGranted = await Permission.location.isGranted;
      final bluetoothGranted = await Permission.bluetooth.isGranted;

// :67
    context.goNamed(isLoggedIn ? 'connection' : 'login');
```
- **Current behavior:** صفحة داخل feature `auth` تقرأ `localStorageProvider.onboardingSeen` (قرار feature onboarding)، ثم تستدعي `permission_handler` مباشرة (feature permissions)، ثم `authStateProvider.checkAuthStatus()` (auth)، ثم تختار الوجهة بين `/connection` (feature connection) و`/login`.
- **Why problematic:** Four features orchestrated from one page in feature #5. `permission_handler` يُستدعى مباشرة دون port في `core/services`، فيصبح Widget قابلاً للاختبار فقط عبر instrumentation. كما أن `SplashPage` هي فعلياً **نقطة دخول التطبيق** (`AppRoutes.splash = '/'`).
- **Violated principle:** Feature slice must be self-contained; app-level bootstrap belongs to `lib/app/`.
- **Current owner:** `features/auth/presentation/pages/splash_page.dart`.
- **Correct owner:** `lib/app/bootstrap/app_bootstrap.dart` (منسّق) + `lib/features/permissions/data/permissions_service.dart` (port التغليف).
- **Consequences:** (1) أي تغيير في ترتيب الإقلاع يمسّ feature auth؛ (2) permission_handler موزّع في مكانين (splash + permissions_page)؛ (3) اختبار unit لمسار الإقلاع مستحيل.
- **Recommended correction:** `AppBootstrap` في `lib/app/` يستهلك `PermissionsService` (من feature permissions) + `authStateProvider` + `localStorageProvider`، ويصدر نتيجة (`BootstrapResult`)؛ الصفحة مجرد عارض.
- **Related files:** `lib/features/permissions/presentation/pages/permissions_page.dart:36-40`, `lib/app/orchestrators/tracking_orchestrator.dart`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE ACC-001: `application/usecases/update_rules_use_case.dart` يستورد Riverpod ويعرّف DI ويعتمد على presentation لميزة أخرى
- **Severity:** High
- **Category:** Layer inversion (multi-directional)
- **Location:** `lib/features/account/application/usecases/update_rules_use_case.dart:1`, `:9`, `:52-61`
- **Evidence:**
```dart
// lib/features/account/application/usecases/update_rules_use_case.dart:1
import 'package:flutter_riverpod/flutter_riverpod.dart';

// :9
import '../../../auth/presentation/providers/auth_state_provider.dart';

// :52
final updateRulesUseCaseProvider = Provider<UpdateRulesUseCase>((ref) {
  ...
  final user = ref.watch(authStateProvider).user;
  if (user == null) {
    throw Exception('User not authenticated');
  }
  return UpdateRulesUseCase(backend, storage, user.id);
});
```
- **Current behavior:** Use-case في طبقة `application` (التي يجب أن تكون إطاراً-مستقلاً عن Flutter) يستورد `flutter_riverpod`، ويُعرّف `Provider` خاصاً به (حقن اعتماديات في نفس الطبقة)، ويسحب هوية السائق من **presentation** لميزة أخرى (AUTH).
- **Why problematic:** ثلاث انقلات في 62 سطراً: (أ) `application → framework DI`؛ (ب) `application → presentation(Auth)`؛ (ج) الـ provider يرمي `Exception` عند بناءه ⇒ **الخطأ يقع فيComposition لا في التشغيل**.
- **Violated principle:** Dependency Rule صارمة: `presentation → application → domain`. هنا `application → presentation`، وهو عكس المسار.
- **Current owner:** `UpdateRulesUseCase` file.
- **Correct owner:** (أ) المُركِّب في `core/di/` أو `features/account/data/providers/`؛ (ب) `driverId` يجب أن يُمرَّر كوسيط من presentation، أو يُؤخذ من `application`-level session abstraction لا من `authStateProvider`.
- **Consequences:** (1) `application` لا يمكن اختبارها خارج Flutter؛ (2) use-case مرتبطة ببنية Riverpod وحالة UI؛ (3) `throw Exception` في وقت البناء = فشل Composition لكل من يقرأ `rulesScreenProvider`.
- **Recommended correction:** احذف السطر 1 و52–61 من الملف؛ انقل `updateRulesUseCaseProvider` إلى `lib/features/account/data/providers/`، وغيّر `execute(request)` إلى `execute({required DriverId driverId, required RulesScreenUpdateRequest request})`.
- **Related files:** `lib/features/account/presentation/providers/rules_screen_provider.dart`, `lib/features/account/presentation/pages/rules_page.dart:57`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE ACC-002: `rules_page.dart` (presentation) يستورد DTO محوّل من `backend/adapters`
- **Severity:** High
- **Category:** Layer skip (presentation → data adapter)
- **Location:** `lib/features/account/presentation/pages/rules_page.dart:13`, `:65-73`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/rules_page.dart:13
import '../../../../backend/adapters/eld_engine/models/rules_screen_dto.dart';

// :65
      final request = RulesScreenUpdateRequest(
        cycleRule: _cycleRule!,
        cargoType: _cargoType!,
        restart: _restart!,
        restBreak: _restBreak!,
        sixteenHourException: sixteenEligible
            ? _sixteenHourException!
            : model.sixteenHourException,
      );
```
- **Current behavior:** Widget presentation ينشئ كائن طلب **من محوّل محوّل (adapter) محدد من `backend/adapters/eld_engine/`** — وهو ليس عقداً (contract) بل تنفيذ مباشر لـ التنفيذ لـ backend محدد.
- **Why problematic:** (أ) presentation أصبح مرتبطاً بتنفيذ backend واحد (ELD Engine) — تبديله إلى `mock` أو غيره يكسر الواجهة؛ (ب) `RulesScreenUpdateRequest` كان يجب أن يكون في `application/` (وهو فعلاً في نفس الحزمة المستورَدة من `application/usecases`)؛ (ج) هذا هو **الاستوراد الوحيد** الذي يكسر القاعدة، لكنه يكسرها في places حرجة.
- **Violated principle:** presentation يعتمد على contracts لا على adapters.
- **Current owner:** `rules_page.dart`.
- **Correct owner:** انقل `RulesScreenUpdateRequest` إلى `lib/features/account/application/models/` واستورده من هناك.
- **Consequences:** (1) ارتباط presentation بتنفيذ backend محدد؛ (2) difficulty اختبار الواجهة بـ fake.
- **Recommended correction:** نقل الكيان إلى `application/models/rules_screen_update_request.dart` وتحديث الاستيراد.
- **Related files:** `lib/features/account/application/usecases/update_rules_use_case.dart:23`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE ACC-006: `info_packet_page.dart` يستهلك provider من presentation لميزة INSPECTION
- **Severity:** Medium
- **Category:** Cross-feature coupling to implementation
- **Location:** `lib/features/account/presentation/pages/info_packet_page.dart:7-8`, `:39`؛ المزوّد: `lib/features/inspection/presentation/providers/inspection_provider.dart:124-136`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/info_packet_page.dart:7-8
import '../../../inspection/domain/inspection_transfer.dart';
import '../../../inspection/presentation/providers/inspection_provider.dart';

// :39
          _PacketStatus(packet: ref.watch(informationPacketProvider)),
```
- **Current behavior:** صفحة ACCOUNT تستورد **مزوّداً من طبقة presentation لميزة أخرى**، وهو بدوره يستورد `InspectionRepository` وينفّذ الطلب.
- **Why problematic:** `informationPacketProvider` هو ليس عقداً — هو implementation داخل `presentation`. النتيجة: (أ) ACCOUNT مربوط بالتنفيذ لا بالعقد؛ (ب) الـ lifecycle (autoDispose + cacheFor 5د) مملوك لـ INSPECTION؛ (ج) `_PacketStatus` يستهلك `AsyncValue<InformationPacketView>` مباشرة، فيضطر presentation Knowing about provider semantics.
- **Violated principle:** Cross-feature communication عبر العقد/المستودع، لا عبر provider implementations.
- **Current owner:** `informationPacketProvider` (inspection).
- **Correct owner:** إما (أ) shared read-contract في `lib/domain/shared/` مع implementation فيapiданьinspection، أو (ب) `InformationPacketPage` في feature inspection نفسها (لأن الحزمةInspection حسب SRS هي مالكها).
- **Consequences:** (1) لا يمكن لـ ACCOUNT الاختبار بدون pullsentireinspection؛ (2) تعديل cacheدقيقة في inspection يغيّر سلوك ACCOUNT.
- **Recommended correction:** انقل "حزمة المعلومات" إلى feature inspection (المالك rightful) أو استخرج provider إلى `lib/domain`/`core` مشترك مع عقد.
- **Related files:** `lib/routes/account_routes.dart:26-29` (المسار في account_routes لكن المضيف في inspection)
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE ACC-008: `EldDrawer` — هيكل التطبيق (app shell) مملوك داخل feature HOME ويُستورد من 5 صفحات
- **Severity:** Medium
- **Category:** Layering inversion (shared UI owned by a feature)
- **Location:** `lib/features/home/presentation/widgets/eld_drawer.dart` — مستورد من: `account_page.dart:8`, `info_packet_page.dart:6`, `rules_page.dart:10`, `codriver_page.dart:9`, `settings_page.dart:12`, `home_page.dart:12`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/account_page.dart:8
import '../../../home/presentation/widgets/eld_drawer.dart';

// lib/features/settings/presentation/pages/settings_page.dart:12
import '../../../home/presentation/widgets/eld_drawer.dart';
```
**و** `eld_drawer.dart:137` ينفّذ mutation في feature أخرى:
```dart
// lib/features/home/presentation/widgets/eld_drawer.dart:137
              await ref.read(authStateProvider.notifier).logout();
```
- **Current behavior:** Widget التنقّل الرئيسي (الدرج الجانبي + حوار الخروج) يعيش داخل `features/home/presentation/`، بينما **خمس صفحات من أربع ميزات** تستورده لتزويد نفسها للتنقّل.
- **Why problematic:** ينتج **نجمة مترابطة**: أي feature لا يستطيع امتلاك screen chrome خاصاً بها دون الاعتماد على HOME. كما أن `EldDrawer` ينفّذ `authStateProvider.notifier.logout()` — أي presentation widget في feature A يستدعي mutation في feature B.
- **Violated principle:** App shell / navigation chrome belongs to `lib/app/` or `core/widgets/`, not to a feature.
- **Current owner:** `features/home/presentation/widgets/eld_drawer.dart`.
- **Correct owner:** `lib/app/shell/app_drawer.dart` مع list menu تُمرَّر من `home_provider` أو `AppRoutes`.
- **Consequences:** (1) 6 استيرادات لـ HOME من Account/Settings/Codriver/InfoPacket؛ (2) تعديل تصميم الدرج يمسّ 4 ملفات؛ (3) الصفحات ترث سلوك logout دون أن تعرف.
- **Recommended correction:** انقل `EldDrawer` إلى `lib/app/shell/`.
- **Related files:** `lib/features/home/presentation/widgets/eld_drawer.dart:60-70, 137`, `lib/features/home/presentation/providers/home_provider.dart`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE COD-002: `codriver_page.dart` يستورد خمس ملفات من HOS + TRACKING لتغذية حارس واحد
- **Severity:** High
- **Category:** Cross-feature coupling (widget as orchestrator)
- **Location:** `lib/features/codriver/presentation/pages/codriver_page.dart:15-18`, `:23`, `:193-214`
- **Evidence:**
```dart
// lib/features/codriver/presentation/pages/codriver_page.dart:15-18
import '../../../hos/domain/engine/hos_rules_engine.dart';
import '../../../hos/presentation/providers/hos_engine_provider.dart';
import '../../../hos/presentation/providers/hos_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';

// :193-214
                                    final hos = ref.read(hosStatusProvider);
                                    final driving = hos is HosEngineReady
                                        ? hos.update.currentStatus ==
                                              DutyStatus.driving
                                        : null;
                                    final refusal = refuseRoleSwitch(
                                      currentDriverId: ref.read(currentDriverIdProvider),
                                      coDriverId: codriverState.selectedCoDriver?.id,
                                      speedMps: ref.read(currentVehicleSpeedProvider),
                                      thresholdKmh: ref
                                          .read(hosConfigurationProvider)
                                          .movingSpeedThresholdKmh,
                                      currentStatusIsDriving: driving,
                                      trackingLive: ref
                                          .read(trackingStateProvider)
                                          .isTracking,
                                    );
```
- **Current behavior:** الـ Widget يجمع 5 قطع من 3ميزات، منها نوع معقّد (`hos is HosEngineReady ? hos.update.currentStatus : null`) ويفكّ `Optional<bool?>` منطقياً. الحارس نفسه (`role_switch_guard.dart`) نقي تماماً — لكن **عقده** يفرض على المتصل معرفة HOS internals.
- **Why problematic:** حارس «الأمان» (FMCSA) في feature CODRIVER يعتمد على (أ) نموذج حالة HOS الداخلي (`HosEngineReady`), (ب) عتبة السرعة من إعدادات HOS المحفوظة, (ج) حالة التتبع من TRACKING. ⇒ (1) حذف/تغيير HOS يكسر COD؛ (2) `refuseRoleSwitch` غير قابل لإعادة الاستخدام خارج Widget؛ (3) منطق typedefarness غير قابل للاختبار إلا ببناء Widget.
- **Violated principle:** Cross-feature reads via shared contracts (e.g. `currentVehicleSpeedProvider` should live in a shared `session`/`telemetry` contract, not in tracking presentation).
- **Current owner:** `codriver_page.dart`.
- **Correct owner:** `features/codriver/application/role_switch/role_switch_guard_use_case.dart` يقرأ من عقود مشتركة (`SessionSpeedPort`, `DutyStatusQuery`, `TrackingLiveness`), ويبقى Widget مجرد مستدعٍ.
- **Consequences:** (1) 5 حواف صريحة CODRIVER→HOS/TRACKING؛ (2) منطق الامتثالnizصعب الاختبار؛ (3) ازدواج: `vehicle_provider.dart:220-253` ينسخ نفس قواعد الحراسة لتطبيق.
- **Recommended correction:** استخرج use-case يغلّف القراءة؛ اجعل الصفحة تنادي `ref.read(roleSwitchGuardProvider).guard(...)`.
- **Related files:** `lib/features/codriver/domain/role_switch_guard.dart`, `lib/features/vehicle/presentation/providers/vehicle_provider.dart:220-253`, `lib/features/hos/presentation/providers/hos_engine_provider.dart:18,80`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CON-001: `eld_connection_page.dart` يحتوي use-case "وصلة الـ ELD" كاملاً + استدعاءات بنية تحتية مباشرة
- **Severity:** High
- **Category:** Layer collapse / no domain layer in feature
- **Location:** `lib/features/connection/presentation/pages/eld_connection_page.dart:61-251` (النموذج والـ notifier والـ provider)، `:70`, `:87`, `:111`, `:114-116`, `:174-176`, `:224-226`
- **Evidence:**
```dart
// lib/features/connection/presentation/pages/eld_connection_page.dart:70
      final bluetoothService = _ref.read(bluetoothServiceProvider);
...
// :87
      final hardwareBackend = _ref.read(hardwareBackendProvider);
...
// :114-116
              final config = await _ref.read(trackingRepositoryProvider).getCurrentConfig();
              await _ref.read(trackingRepositoryProvider).updateConfig(config);
              await _ref.read(trackingStateProvider.notifier).startTracking();
```
- **Current behavior:** الملف الواحد يحتوي: (أ) `EldConnectionState` (27–59)، (ب) `EldConnectionNotifier` (61–246) ينسّق **5 مصادر بنية تحتية**: `bluetoothServiceProvider`, `hardwareBackendProvider`, `localStorageProvider`, `trackingRepositoryProvider`, `trackingStateProvider`، (ج) `eldConnectionProvider` (248–251)، (د) الـ Page (253–529).
- **Why problematic:** feature `connection` **لا تحتوي `domain/` ولا `application/` إطلاقاً** (الملفات الـ4 الأولى هي domain كيانات فقط، بلا usecase ولا repository). ⇒ **Use case "ConnectELD" مكتوب كاملاً داخل ملف Widget**، ويصل مباشرة إلى Bluetooth وbackend contracts ومستودع feature TRACKING. هذا نمط "fat notifier in page" أشد أشكال CLA(layer) violation.
- **Violated principle:** Presentation orchestrates, doesn't implement; Layer collapse.
- **Current owner:** `EldConnectionNotifier` في presentation.
- **Correct owner:** `features/connection/application/connect_eld/connect_eld_use_case.dart` + `features/connection/domain/repositories/connection_repository.dart`؛ يبقى presentation مجرد حالة عرض.
- **Consequences:** (1) منطق الاتصال (المهم قانونياً) غير قابل للاختبار بدون Flutter؛ (2) 5 حواف بنية تحتية من presentation؛ (3) `setManualMode` و`continueDisconnected` ينتميان لـ domain workflow لا presentation.
- **Recommended correction:** استخرج `ConnectEldUseCase` و`ManualModeUseCase` في `connection/application/`، واجعل `eldConnectionProvider` state-only.
- **Related files:** `lib/features/connection/presentation/providers/hardware_status_provider.dart` (نفس النمط), `lib/features/connection/presentation/widgets/manual_recording_section.dart:9`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HOM-003: دورة استيراد: `lib/routes.dart` ↔ `lib/features/home/`
- **Severity:** Medium
- **Category:** Circular dependency (app ↔ feature)
- **Location:** `lib/features/home/presentation/providers/home_provider.dart:3` و`lib/features/home/presentation/widgets/eld_drawer.dart:8` مقابل `lib/routes/home_routes.dart:3`
- **Evidence:**
```dart
// lib/features/home/presentation/providers/home_provider.dart:3
import '../../../../../routes.dart';

// lib/routes/home_routes.dart:3
import '../features/home/presentation/pages/home_page.dart';
```
- **Current behavior:** `routes.dart` → `routes/home_routes.dart` → `features/home/.../home_page.dart` → (عبر `home_provider.dart` و`eld_drawer.dart`) → `routes.dart`. ⇒ **دورة استيراد فعلية** بين جذر التطبيق و feature HOME.
- **Why problematic:** (أ) دورة كسر حدود  boundaries — كل feature يستورد `routes.dart` لكائن `AppRoutes`؛ (ب) `AppRoutes` يعتمد على features عبر `routes/*.dart`، و features تعتمد عليه ⇒ tight coupling in both directions؛ (c) يعقّب إعادة البناء والاختبار.
- **Violated principle:** App layer knows features; features must NOT know the app layer (they may know route *identifiers* via a leaf).
- **Current owner:** `home_provider.dart`, `eld_drawer.dart`.
- **Correct owner:** استخرج `lib/core/navigation/app_routes.dart` (leaf، بلا أي imports) يستهلكه الـ app والـ features معاً.
- **Consequences:** (1) inability to reason about the routing graph; (2) coupling كل feature تنوي الـ route constants.
- **Related files:** `lib/routes.dart:14-52`, `lib/features/account/presentation/providers/account_provider.dart` (يستورد auth presentation لا routes)
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-001: طبقة العقد تصدّر `RawJson` وتتسرب بها إلى domain وpresentation
- **Severity:** HIGH
- **Category:** Architecture
- **Location:** `lib/backend/contracts/raw_json.dart:10`
- **Evidence:**
```dart
typedef RawJson = Map<String, dynamic>;
```
والتسريب المؤكَّد في الاستهلاك من طبقتين أعلى:
```dart
// lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:13
import '../../../../../backend/contracts/status_dashboard_backend.dart';
// :46
  final StatusDashboardBackend _dashboardBackend;
```
```dart
// lib/features/connection/presentation/providers/hardware_status_provider.dart:15-23
  final backend = ref.read(hardwareBackendProvider);
  final uniqueId = ref.watch(vehicleProvider).selectedVehicle?.uniqueId;
  final result = await backend.getStatus(uniqueId: uniqueId);
  return result.fold((failure) => throw failure, (json) {
    final read = parseConnectivityStatus(json);
    if (read == null) {
      throw const FormatException('connectivity body is not an object');
    }
    return read;
  });
```
- **السلوك الحالي:** `RawJson` (= `Map<String, dynamic>`) هو النوع المُرجَع في 11 من 13 عقدة. الملفات التي تنتج هذه الخرائط هي بالضبط نفس الملفات التي يفترض في Clean Architecture أن تُنشئ نماذج مُحاطة.
- **لماذا هو مشكل:** النوع غير المُحاط يمرّر لأسفل حتى الطبقتين اللتين يفترض أنهما الأبعد عن السلك. النتيجة أن **اسم حقل من `openapi.yaml` صار واجهة برمجية** داخل `presentation`. مثال: `hardware_status_provider.dart:19` يستدعي `parseConnectivityStatus(json)` — محلل يفهم مفاتيح الخادم — من داخل `presentation`.
- **المبدأ المنتهك:** Dependency Inversion + Encapsulation. الـ port يجب أن يكون مكتوبًا بلغة النطاق (domain)، لا بلغة النقل (wire).
- **المالك الحالي:** `lib/backend/contracts/*` (النوع) و`lib/features/*` (الاستهلاك).
- **المالك الصحيح:** `lib/domain/**` — نماذج مُحاطة، مثل `DotInspectionScreen` في `inspection_backend.dart:9`، وهو يثبت أن الحل معمول به بالفعل داخل نفس المجلد.
- **العواقب:** تغيير اسم حقل في الخادم = كسر في `presentation`. لا يمكن كتابة اختبار نطاقي (domain test) بلا تشغيل خادم. `flutter analyze` لا يستطيع التقاط خطأ مفتاح.
- **التصحيح المقترح:** استبدال تدريجي لـ `RawJson` بنماذج domain مُحاطة، بالترتيب التصاعدي للاستخدام: `getAvailableDrivers` → `hardware.getStatus/getReadiness` → `unidentifiedEvents.list` → `dailyLogs.list`. وحظر أي `import` لـ `raw_json.dart` من `domain/` أو `presentation/` كقاعدة تحليل جذرية (انظر BACK-003).
- **الملفات المرتبطة:** `raw_json.dart`، `daily_logs_backend.dart`، `duty_status_backend.dart`، `dvir_backend.dart`، `hardware_backend.dart`، `inspection_backend.dart`، `vehicle_backend.dart`، `auth_backend.dart`، `driver_session_backend.dart`، `unidentified_events_backend.dart`، `duty_status_tracker.dart`، `hardware_status_provider.dart`، `unidentified_events_provider.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-002: الحافة المعروفة `lib/backend → lib/features` ليست حادثة بل نمط من 6 استيرادات
- **Severity:** HIGH
- **Category:** Coupling
- **Location:** `lib/backend/contracts/rules_screen_backend.dart:3`
- **Evidence:**
```dart
// lib/backend/contracts/rules_screen_backend.dart:3
import '../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
```
والتكرارات الخمس الأخرى (تحققت منها كلها بالبحث النصي):
```dart
// lib/backend/adapters/eld_engine/sub/eld_rules_screen_backend.dart:3
import '../../../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
// lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart:1
import '../../../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
// lib/backend/adapters/mock/sub/mock_rules_screen_backend.dart:4
import '../../../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
// lib/backend/http/interceptors/auth_interceptor.dart:2-3
import '../../../features/auth/data/datasources/auth_local_data_source.dart'; // ignore_architecture
import '../../../features/auth/domain/entities/auth_session.dart'; // ignore_architecture
// lib/backend/providers/backend_network_providers.dart:11-13
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart'; // ignore_architecture
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart'; // ignore_architecture
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart'; // ignore_architecture
```
- **السلوك الحالي:** `RulesScreenModel` — كائن من `features/account/application` — يتدفق عبر دورة كاملة: العقدة → المحوّل → الـ mapper → presentation، موزّعًا على 4 ملفات.
- **لماذا هو مشكل (الحكم المطلوب):** **ليست استيرادًا عارضًا.** الدليل أن `RulesScreenModel` لا يمكن نقله ببساطة: هو ليس `domain` ولا `application` مجرد حاوية، بل **كائن عابر للطبقات** يحمل `HosConfiguration limits` (`rules_screen_mapper.dart:19-30`) القادمة من `core/config`. الجذر ليس موقع الملف، بل أن **`RulesScreenModel` لا ينتمي لأي طبقة** — كان يجب أن يُوضع في `domain/account` أو `domain/hos`. كذلك `auth_interceptor.dart:2` يستورد من `features/auth/**data**` — أي أن طبقة البنية التحتية تعرف عن تنفيذ مصادقة ميزة ما. و`backend_network_providers.dart:11-13` يجعل `backend/providers` بوابة لعميل تتبّع native خاص بميزة.
- **المبدأ المنتهك:** Dependency Rule (طبقة البنية التحتية لا تعرف الميزات).
- **المالك الحالي:** `features/account/application/models/rules_screen_model.dart`. **المالك الصحيح:** `lib/domain/account/rules_screen_model.dart` أو `lib/domain/hos/`.
- **العواقب:** لا يمكن حذف feature `account` دون كسر `contracts`. لا يمكن اختبار `RulesScreenBackend` في عزلة عن الميزة. `AuthInterceptor` غير قابل لإعادة الاستخدام خارج هذا المشروع.
- **التصحيح المقترح:** (1) **نقل** `RulesScreenModel` إلى `lib/domain/`. (2) **نقل** `AuthLocalDataSource` و`AuthSession` خلف واجهة في `lib/core/session/` — وهي موجودة أصلًا (`core/session/session_epoch.dart`). (3) **نقل** `traccarNativeClientProvider` إلى `features/tracking/data/providers/`. (4) **حذف `// ignore_architecture`** لأنها ليست آلية (انظر BACK-003).
- **الملفات المرتبطة:** `rules_screen_backend.dart`، `eld_rules_screen_backend.dart`، `rules_screen_mapper.dart`، `mock_rules_screen_backend.dart`، `auth_interceptor.dart`، `backend_network_providers.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-004: العقد `daily_logs_backend.dart` يستورد نماذج من مجلد محوّل (انقلاب اتجاه)
- **Severity:** CRITICAL
- **Category:** Architecture
- **Location:** `lib/backend/contracts/daily_logs_backend.dart:3-4`
- **Evidence:**
```dart
// lib/backend/contracts/daily_logs_backend.dart:1-6
import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import '../adapters/eld_engine/models/certify_dto.dart';
import '../adapters/eld_engine/models/readiness_dto.dart';
import 'raw_json.dart';
```
```dart
// lib/backend/contracts/daily_logs_backend.dart:38-41
  Future<Result<CertifyResponseDto>> certify(
    CertifyRequestDto request, {
    int? expectedOwnerDriverId,
  });
```
والنتيجة المباشرة — الموك مُلزَم بتوقيع يحتوي على DTOات المحرك الحقيقي:
```dart
// lib/backend/adapters/mock/sub/mock_daily_logs_backend.dart:5-6
import '../../eld_engine/models/certify_dto.dart';
import '../../eld_engine/models/readiness_dto.dart';
```
- **السلوك الحالي:** طبقة الـ port (المحايدة المفترضة) تستورد من **محوّل محدّد بعينه** (`eld_engine`).
- **لماذا هو مشكل:** هذا هو **المعيار الحقيقي** لما إذا كان there port حقيقي: هل يستطيع mock أن يُنفَّذ دون أن يعرف المحرك الحقيقي؟ هنا الإجابة لا. كما أن `DailyLogsBackend` — وهي واجهة use-case — صارت **مرتبطة بتمثيل ELD المحدد**، ما يعني أن أي backend ثالث محكوم عليه بإعادة تعريف نفس الـ DTOs.
- **المبدأ المنتهك:** Dependency Inversion — تعتمد المصادر الداخلية (Abstract) على التفاصيل الخارجية.
- **المالك الحالي:** `adapters/eld_engine/models/*`. **المالك الصحيح:** `lib/domain/logs/` (أو `lib/backend/contracts/dto/` مشترك).
- **العواقب:** استبدال/حذف `eld_engine` يكسر العقدة. الرسم البياني للطبقات غير قابل للتحقق آليًا. أي backend ثالث مجبور على تبنّي DTOات غريبة عنه.
- **التصحيح المقترح:** نقل `certify_dto.dart` و`readiness_dto.dart` إلى `lib/domain/logs/` كنماذج domain مع `fromJson` في mapper المحوّل. بعد نقلها يصبح السطران 3-4 في العقدة استيرادًا محايدًا، ويُحلBACK-035 في نفس الوقت.
- **الملفات المرتبطة:** `daily_logs_backend.dart`، `certify_dto.dart`، `readiness_dto.dart`，`mock_daily_logs_backend.dart`، `eld_daily_logs_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-005: نصوص عرض إنجليزية داخل طبقة backend (mapper + محوّل)
- **Severity:** LOW
- **Category:** Architecture
- **Location:** `lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart:76`
- **Evidence:**
```dart
// status_dashboard_mapper.dart:73-84
    if (raw is! Map<String, dynamic>) {
      return const RemainingCircle(
        remaining: Duration.zero,
        label: 'Remaining',
        progress: 0.0,
      );
    }
    return RemainingCircle(
      remaining: _parseDuration(raw['time']),
      label: JsonPrimitives.asString(raw['label'], fallback: 'Remaining'),
      progress: JsonPrimitives.asDouble(raw['progress']).clamp(0.0, 1.0),
    );
```
```dart
// status_dashboard_mapper.dart:90-93
      drive: _parseIndicator(raw['drive'], fallbackLabel: 'DRIVE'),
      shift: _parseIndicator(raw['shift'], fallbackLabel: 'SHIFT'),
      breakTime: _parseIndicator(raw['breakTime'], fallbackLabel: 'BREAK'),
      cycle: _parseIndicator(raw['cycle'], fallbackLabel: 'CYCLE'),
```
```dart
// eld_status_dashboard_backend.dart:110-125
  static String _defaultNoteFor(DutyStatusCode status) {
    switch (status) {
      case DutyStatusCode.onDutyNotDriving:
        return 'Available';
      case DutyStatusCode.sleeperBerth:
        return 'Sleeper Berth';
```
- **السلوك الحالي:** سلاسل عرض مُحاط بها داخل domain (`RemainingCircle.label`، `HosIndicator.label`) ومُولَّدة في طبقة البنية التحتية.
- **لماذا هو مشكل:** التطبيق يدّع دعم العربية (الـ fixtures والموكات تحمل نصوصًا عربية)، لكن هذه القيم ستُعرض دائمًا بالإنجليزية لأن مَن يملك l10n هو presentation. هذا **خلط مسؤوليات** لا مجرد ترجمة ناقصة.
- **المبدأ المنتهك:** SRP على مستوى الطبقة.
- **العواقب:** لا يمكن ترجمة شاشات HOS. الفحص المتسق عند نقص البيانات يُنتج نصًا إنجليزيًا في بيئة عربية.
- **التصحيح المقترح:** جعل `label` nullable في النماذج وترجمتها في presentation عبر `AppLocalizations`، أو إطلاق الـ fallback كمفتاح ترجمة (`'hosIndicator.drive'`) لا كنص نهائي.
- **الملفات المرتبطة:** `status_dashboard_mapper.dart`، `eld_status_dashboard_backend.dart`، `mock_status_dashboard_backend.dart`، `mock_inspection_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-006: منطق أعمال داخل `DvirDto.fromJson` و`toJson` يعيد كتابة حقول الخادم
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/eld_engine/models/dvir_dto.dart:107`
- **Evidence:**
```dart
// dvir_dto.dart:107-114
      hasDefects: json['hasDefects'] == true || vehicleDefects.isNotEmpty || trailerDefects.isNotEmpty || flatDefects.isNotEmpty,
      defectsCount: flatDefects.length + vehicleDefects.length + trailerDefects.length,
      defectsSummary: json['defectsSummary']?.toString(),
      outOfService: json['outOfService'] == true,
      photos: photos,
      vehicleDefects: vehicleDefects,
      trailers: trailers,
      defects: [...flatDefects, ...vehicleDefects, ...trailerDefects],
```
```dart
// dvir_dto.dart:129-130
      'id': id,
      'driver': driver?.toJson(),
```
```dart
// dvir_dto.dart:154-155
      'certified': certified,
      'signatureData': signatureData,
```
- **السلوك الحالي:** `hasDefects` و`defectsCount` ودمج القوائم الثلاث **مشتقات** لا قيم مخزّنة. و`toJson()` يُعيد كتابة حقول الخادم (`id`, `certified`, `createdAt`, `formattedTime`, `defectsCount`, `retentionDaysRemaining`).
- **لماذا هو مشكل:** DTO السلكي يجب أن يكون faithful transcode فقط. الاشتقاق هنا **قاعدة DVIR** (هل يوجد عيب فعلي؟) داخل طبقة البنية التحتية؛ أي تعديل في الخادم على تعريف «العيب» يتطلب تعديلًا في هذا الملف. وإذا استُخدم `CreateDvirRequestDto.fromJson` (322) لتحويل حمولة واردة ثم `toJson()` (350) للإرسال، فسيتكرر `id` وحقول الخادم في جسم الطلب.
- **المبدأ المنتهك:** SRP / فصل DTO عن Mapper.
- **المالك الحالي:** `adapters/eld_engine/models/dvir_dto.dart`. **المالك الصحيح:** mapper في `adapters/eld_engine/mappers/dvir_mapper.dart` (المجلد موجود ويعمل).
- **العواقب:** عدم تناسق بين «ما يراه الخادم» و«ما يراه التطبيق». اختبار `hasDefects` يحتاج معرفة مصادر العيوب الثلاثة.
- **التصحيح المقترح:** نقل الاشتقاق إلى `DvirMapper.toEntity(DvirDto)`. وحذف `toJson()` من DTOات القراءة (`DvirDto`) لأنها غير مستخدمة — تحققت: `CreateDvirRequestDto` و`ReviewDvirRequestDto` هما المستخدمان فعليًا (المستهلك الوحيد `dvir_repository_impl.dart:279`).
- **الملفات ذات الصلة:** `dvir_dto.dart`، `lib/features/dvir/data/repositories/dvir_repository_impl.dart:327`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-007: `DvirDto` (نموذج `eld_engine`) يُستهلك من خارج مجلد المحوّل
- **Severity:** MEDIUM
- **Category:** Coupling
- **Location:** `lib/features/dvir/data/repositories/dvir_repository_impl.dart:56`
- **Evidence:**
```dart
// features/dvir/data/repositories/dvir_repository_impl.dart:54-58
        final rawReports = (rawJson['data'] as List<dynamic>?) ?? [];
        final reports = rawReports.map((json) {
          final dto = DvirDto.fromJson(json as Map<String, dynamic>);
          return _mapDtoToEntity(dto);
        }).toList();
```
- **السلوك الحالي:** `DvirDto` (و`ReviewDvirRequestDto` عند 279) معرّفان في `lib/backend/adapters/eld_engine/models/` ويُستهلكان في `lib/features/dvir/data/repositories/`. تحققت بالبحث النصي: **لا استيراد لـ `dvir_dto.dart` من أي مكان داخل `lib/backend/`**.
- **لماذا هو مشكل:** هذا يعني أن `DvirDto` ليس نوعًا داخليًا للمحوّل بل **حقيقة مشتركة** بين البنية التحتية والمستهلك. الموقع في `adapters/eld_engine/` مضلّل: أي كود في طبقة `data` يستطيع الوصول إلى تفاصيل ELD Engine بينما العقدة (`dvir_backend.dart`) تُرجع `RawJson`. عمليًا: طبقة `data` مربوطة بمحوّل واحد بالتزامًا مع `MockAdapter`.
- **المبدأ المنتهك:** Encapsulation (نوع مشترك وُضع في المكان الخطأ).
- **العواقب:** استبدال المحرك = كسر طبقة `data`. لا يمكن إعادة استخدام `DvirDto` مع backend ثالث.
- **التصحيح المقترح:** إما (أ) رفع `dvir_dto.dart` إلى `lib/backend/contracts/dto/` كـ port DTO مشترك (الأنسب، لأنه يُستخدم فعلاً من الطرفين)، أو (ب) الأفضل: نقل التحليل إلى mapper داخل المحوّل وإرجاع `DvirReport` (domain) من العقدة نفسها — وهذا يلغي `RawJson` أيضًا.
- **الملفات ذات الصلة:** `dvir_dto.dart`، `dvir_repository_impl.dart`، `dvir_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-008: تباين صامت في شكل استجابة `DvirBackend.list` بين المحرك والموك
- **Severity:** HIGH
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_dvir_backend.dart:20`
- **Evidence:**
```dart
// mock_dvir_backend.dart:19-21
  }) async {
    return ok({'reports': []});
  }
```
مقابل:
```dart
// eld_dvir_backend.dart:34
      parser: (data) => data is List ? {'data': data} : (data is Map<String, dynamic> ? data : {}),
```
والconsumer:
```dart
// features/dvir/data/repositories/dvir_repository_impl.dart:54
        final rawReports = (rawJson['data'] as List<dynamic>?) ?? [];
```
- **السلوك الحالي:** العقد نفسه يُرجع `RawJson`، لكن **شكله غير مُلزم**. المحرك الحقيقي يغلّف في `'data'`، والموك يغلّف في `'reports'`. المستهلك يقرأ `'data'` فقط.
- **لماذا هو مشكل:** هذا **ليس** مجرد نقص تناظر في التنفيذ، بل **عقد ضمني غير معلن** يعيش خارج الواجهة. النتيجة المؤكَّدة: `getDvirReports()` تحت الموك يُرجع **قائمة فارغة دائمًا** (`rawJson['data']` = null) — لا رسالة خطأ، لا تحذير. أي أن **اختبار العرض بكامل وظيفته يمرّ تحت الموك يكذب بهدوء**.
- **المبدأ المنتهك:** Contract completeness / Liskov Substitution.
- **العواقب:** شاشة DVIR فارغة في وضع الموك بلا أي مؤشر؛ اختبارات الواجهة تمرّ (قائمة فارغة) دون كشف الانحراف؛ أي إصلاح لاحق على الشاشة لا يُختبر على الموك.
- **التصحيح المقترح:** إما (أ) **الحظر الصريح**: `MockDvirBackend.list` يرجع `{'data': <dynamic>[]}` لمطابقة المحرك، أو (ب) الأفضل: استبدال `RawJson` بـ `List<DvirReport>` في العقدة — عندها يصبح الشكل جزءًا من النوع (مُجمَّع بالـ compiler) ولا يمكن أن يتباين.
- **الملفات ذات الصلة:** `mock_dvir_backend.dart`، `eld_dvir_backend.dart`، `dvir_repository_impl.dart`، `dvir_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-009: `auth_interceptor.dart` يستورد من طبقتي `features/auth` (data + domain)
- **Severity:** HIGH
- **Category:** Coupling
- **Location:** `lib/backend/http/interceptors/auth_interceptor.dart:2-3`
- **Evidence:**
```dart
// lib/backend/http/interceptors/auth_interceptor.dart:1-7
import 'package:dio/dio.dart';
import '../../../features/auth/data/datasources/auth_local_data_source.dart'; // ignore_architecture
import '../../../features/auth/domain/entities/auth_session.dart'; // ignore_architecture
import '../../../core/error/failure.dart';
import '../../../core/session/session_epoch.dart';
import '../../../core/utils/logger.dart';
import '../eld_endpoints.dart';
```
- **السلوك الحالي:** اعتراض HTTP — وهو البنية التحتية — يعتمد على `features/auth/data/datasources/auth_local_data_source.dart` (طبقة data كاملة، تشمل تخزين Keystore) وعلى كيان `features/auth/domain/entities/auth_session.dart`.
- **لماذا هو مشكل:** `AuthLocalDataSource` ليس عقدة (interface) بل **تنفيذ كامل** لطبقة data. بالتالي `AuthInterceptor` لا يعمل إلا مع `AuthLocalDataSource` حقيقي. والأسوأ: `AuthLocalDataSource` هو المكان الذي تعيش فيه سياسة تخزين الجلسة — وهي سياسة عالية المستوى التي يفترض أن `lib/backend` لا يعرفها.
- **المبدأ المنتهك:** Dependency Rule + Dependency Inversion (اعتماد concretes لا abstractions).
- **المالك الحالي:** `features/auth/data`. **المالك الصحيح:** عقدة في `lib/core/session/` — ولحسن الحظ `lib/core/session/session_epoch.dart` **موجود بالفعل**، فالجذر قائم والحدّ غائب.
- **العواقب:** لا يمكن اختبار `AuthInterceptor` بجلسة وهمية إلا بتبعية حقيقية على Keystore. استبدال سياسة تخزين الجلسة = تعديل `lib/backend`.
- **التصحيح المقترح:** تعريف `abstract interface class SessionStore { Future<AuthSession?> getSession(); int get credentialGeneration; }` داخل `lib/core/session/`، وتنفيذه في `features/auth/data`. يحوّل الاعتماد من concrete إلى abstraction دون تغيير سلوك.
- **الملفات ذات الصلة:** `auth_interceptor.dart`، `auth_local_data_source.dart`، `core/session/session_epoch.dart`، `backend_network_providers.dart:57`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-010: `AuthBackend` يمرّر `backendType` ومفاتيح JSON الخام كواجهة، ولا يوجد تدفّق refresh
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/contracts/auth_backend.dart:5-10`
- **Evidence:**
```dart
// lib/backend/contracts/auth_backend.dart:4-16
abstract interface class AuthBackend {
  Future<Result<RawJson>> login({
    required String identifier,
    required String password,
    required String serverUrl,
    required String backendType,
  });

  Future<Result<RawJson>> validateSession({
    required String serverOrigin,
    required String sessionCredential,
    required String backendType,
  });
```
والاستهلاك الذي يثبّت المفاتيح كعقد ضمني:
```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart:60-64
        final sessionDto = AuthSessionDto.create(
          serverOrigin: rawJson['serverOrigin'],
          sessionCredential: rawJson['credential'],
          userModel: UserModel.fromMetadata(rawJson['user'], defaultEmail: identifier),
        );
```
- **السلوك الحالي:** ثلاث ملاحظات في عقدة واحدة.
- **(أ) `backendType`**: اسم تسمية داخلية (`eldEngine` / `mock`) يُمرَّر كـ required parameter في 3 تواقيع، رغم أن تعليق `eld_auth_backend.dart:27-28` يقرّ صراحةً بأنه **لا يختار أي تسجيل دخول ثانٍ**. فهو معامل ميت في العقد.
- **(ب) `RawJson`**: بنية `{'credential', 'user', 'serverOrigin'}` تصبح عقدًا ضمنيًا يفهمه `auth_repository_impl` (60-64). لو غيّر `EldAuthBackend` اسم مفتاح، ينكسر `features/auth` — مع أن العقد لم يتغير.
- **(ج) لا يوجد `refreshSession`**: بحثت في `lib/` بالكامل — لا يوجد أي use لـ `refreshToken`/`refresh_token` عدا الثابت `app_constants.dart:28` (`refreshTokenKey`) وهو غير مستخدم، و`request_logger.dart:26` (قائمة حجب). **التقييم: هذه ليست مخالفة** — نموذج ELD يعتمد على `JSESSIONID` (cookie)، فالتجديد التلقائي غير مطلوب؛ بل الفقدان الصحيح للجلسة عند 401 هو السلوك الصحيح. وتأكيدًا لذلك: `auth_interceptor.dart:120-141` يعالج 401 بثلاثة أجيال (sessionAttached / credentialGeneration / epoch) وهو تصميم متين.
- **المبدأ المنتهك:** (أ) و(ب): Interface Segregation + Explicit contracts.
- **المالك الحالي / الصحيح:** `contracts/auth_backend.dart` — لكن بأنواع مُحاطة (`SessionGrant`) وبدون `backendType`.
- **العواقب:** تسمية داخلية تسرّبت للواجهة؛ عقد ضمني غير مرئي في التوقيع؛ `app_constants.refreshTokenKey` عتاد ميت يوحي بمعمارية لا وجود لها.
- **التصحيح المقترح:** حذف `backendType` من التواقيع الثلاثة؛ إرجاع `Result<SessionGrant>` (domain) بدل `RawJson`؛ حذف `refreshTokenKey` من `app_constants.dart`.
- **الملفات ذات الصلة:** `auth_backend.dart`، `eld_auth_backend.dart`، `mock_auth_backend.dart`، `auth_repository_impl.dart`، `app_constants.dart:28`
- **Confidence:** CONFIRMED (أ، ب، عدم وجود ج) / تقييم معماري صريح: قرار (ج) تصميمي مقصود وليس مخالفة


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-012: `expectedOwnerDriverId` و`List<dynamic>` يتسرّبان من طبقة النقل إلى العقد
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/contracts/dvir_backend.dart:21-24`
- **Evidence:**
```dart
// lib/backend/contracts/dvir_backend.dart:21-24
  Future<Result<void>> create(
    RawJson report, {
    int? expectedOwnerDriverId,
  });
```
```dart
// lib/backend/contracts/driver_session_backend.dart:11-12
  /// GET /api/drivers
  Future<Result<List<dynamic>>> getAvailableDrivers();
```
الأصل المفهومي:
```dart
// lib/backend/http/interceptors/auth_interceptor.dart:41-45
  /// P0 2B-1 — المالك المتوقع لعملية الطابور (يضعه الـ dispatcher عبر
  /// ApiClient حصراً لطلبات المزامنة). عند الإرسال الفعلي يُقارن بجلسة
  /// اللحظة: أي اختلاف (تبديل جلسة أثناء الـ awaits السابقة) يرفض
  /// الطلب قبل مغادرة أي بايت — فلا ترث عملية قديمة جلسة جديدة أبداً.
  static const expectedOwnerKey = 'gf_expected_owner';
```
- **السلوك الحالي:** (أ) `expectedOwnerDriverId` وارد في **4 عقد** (`dvir_backend`, `daily_logs_backend`, `duty_status_backend`, `inspection_backend`) ويمرّ إلى `ApiClient` الذي يحوله إلى `extra['gf_expected_owner']`. (ب) `List<dynamic>` في توقيع عقد.
- **لماذا هو مشكل:** (أ) **سياسة تنفيذية** (منع عملية قديمة من وراثة جلسة جديدة) صارت **جزءًا من توقيع واجهة النطاق**. كل من يستدعي `dvir.create` عليه أن يعرف مفهوم الـ queue-dispatch. (ب) `List<dynamic>` يلغي أي ضمان نوع: المستهلك لا يستطيع الوصول إلى `id`/`name` بدون cast يدوي في كل مكان.
- **المبدأ المنتهك:** Interface Segregation + Information Hiding.
- **المالك الحالي:** `contracts/*`. **المالك الصحيح:** `ApiClient`/الاعتراض (المالك الفعلي الآن).
- **العواقب:** كل use-case جديد يختار `expectedOwnerDriverId` اعتباطًا؛Philosophyالمعرفة موزّعة على طبقتين.
- **التصحيح المقترح:** (أ) نقل `expectedOwnerDriverId` من توقيع العقدة إلى `ApiClient` وحده، مع API مختلف للمسارات التي تحتاج ربطًا (`dispatcherClient` مخصص). (ب) تعريف `DriverRef` (موجود أصلًا في `domain/duty_status`) كعنصر `List<DriverRef>`.
- **الملفات ذات الصلة:** `dvir_backend.dart`، `daily_logs_backend.dart`، `duty_status_backend.dart`، `inspection_backend.dart`، `driver_session_backend.dart`، `auth_interceptor.dart`، `core/network/api_client.dart:102,263-272`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-019: الموك لا يمرّ بنفس تطبيع الحساب الذي يمرّ به المحرك الحقيقي
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_account_backend.dart:16`
- **Evidence:**
```dart
// mock_account_backend.dart:14-17
  @override
  Future<Result<DriverAccount>> getMyAccount({DriverId? driverId}) async {
    return ok(DriverAccount.fromJson(accountMyAccountFixture));
  }
```
مقابل المحرك الحقيقي:
```dart
// eld_account_backend.dart:15-16
  Map<String, dynamic> _mapAccountJson(Map<String, dynamic> json, {DriverId? fallbackDriverId}) {
    // 1. معالجة المعرف driverId
```
```dart
// eld_account_backend.dart:23-40
    if (json['license'] is String) {
      final licenseStr = json['license'] as String;
      final parts = licenseStr.split(',');
      final state = parts.isNotEmpty ? parts[0].trim() : '';
      final number = parts.length > 1 ? parts[1].trim() : licenseStr;
      
      json['license'] = {
        'state': state,
        'number': number,
        'formatted': licenseStr,
      };
    } else if (json['license'] == null) {
```
- **السلوك الحالي:** المحرك الحقيقي يطبّق 3 تحويلات قبل `fromJson` (driverId fallback، تحويل نص الرخصة `"MI, A350622298913"` إلى Map، توحيد `timezone`→`timeZone`). الموك يمرّر الـ fixture مباشرة.
- **لماذا هو مشكل:** الـ fixture الحالية مُصنوعة أصلًا بالشكل **بعد التطبيع** (`license` Map في `accountMyAccountFixture:39-43`، و`timeZone` في 64). أي أن الموك **يتجاوز تمامًا السلوك الذي صُمم لاختباره** — وهو في الواقع اختصار مسار التطبيع. عند فشل التطبيع في الإنتاج، لن يكتشفه أي اختبار يعمل على الموك.
- **المبدأ المنتهك:** Faithful test double.
- **العواقب:** مسار `_mapAccountJson` (26 سطرًا من منطق العمل) غير مغطى؛ بيانات الـ fixture الصحيحة تُخفي أخطاء التطبيع.
- **التصحيح المقترح:** (أ) نقل `_mapAccountJson` إلى مشترك في `mappers/account_mapper.dart` يناديه كلا المحوّلين، و(ب) إضافة fixture ثانٍ بصيغة **الخام** (`license` كنص + `timezone`) لاختبار التطبيع تحت الموك.
- **الملفات ذات الصلة:** `mock_account_backend.dart`، `eld_account_backend.dart`، `account_fixtures.dart`، `account_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-020: 22 من 58 دالة عقد (≈38%) غير منفَّذة في الموك
- **Severity:** HIGH
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_unidentified_events_backend.dart:18`
- **Evidence:** العقد الوحيد بنسبة تنفيذ 0%:
```dart
// mock_unidentified_events_backend.dart:12-20
  @override
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    String? uniqueId,
    DriverId? driverId,
  }) =>
      throw UnimplementedError(
        'MockUnidentifiedEventsBackend.list — Phase 2',
      );
```
```dart
// mock_daily_logs_backend.dart:51-52
  @override
  Future<Result<RawJson>> getById(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.getById — Phase 2');
```
```dart
// mock_hardware_backend.dart:62-64
  @override
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    throw UnimplementedError('MockHardwareBackend.getStatus — not implemented');
  }
```
```dart
// mock_inspection_backend.dart:163-165
  @override
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId}) =>
      throw UnimplementedError('MockInspectionBackend.getInformationPacket — Phase 2');
```
```dart
// mock_driver_session_backend.dart:13-16
  Future<Result<RawJson>> getActiveSession(DriverId driverId) =>
      throw UnimplementedError(
        'MockDriverSessionBackend.getActiveSession — Phase 2',
      );
```
- **السلوك الحالي:** العدد الدقيق (بتفصيله الكامل في القسم C): `dailyLogs` 4/11، `driverSession` 4/5، `dutyStatus` 1/5، `dvir` 2/8، `hardware` 3/6، `inspection` 5/8، `unidentifiedEvents` 3/3 = **22 دالة**.
- **لماذا هو مشكل:** ليس مجرد نقص تغطية، بل **أن الموك ليس بديلاً**؛ البديل يفشل بصمت أو بانفجار حيث ينجح الأصل. والأثر مباشر في الإنتاج: `hardware_status_provider.dart:17` يستدعي `getStatus` من `presentation`؛ تحت الموك هذا `UnimplementedError` غير معالَج (لا `try/catch`، فقط `fold` على `Result`). النتيجة: **شاشة حالة الجهاز تنهار في وضع الموك**.
- **المبدأ المنتهك:** Liskov Substitution.
- **العواقب:** (أ) لا يمكن عرض شاشات DVIR/التفتيش/الأحداث غير المعرّفة تحت الموك. (ب) انهيار في `presentation` لا في `data`. (ج) الوعد في التوثيق («filled in Phase 2») تجاوزه الزمن.
- **التصحيح المقترح:** استراتيجيتان: (أ) **قابل للتبديل**: كل دالة غير منفَّذة ترجع `err(ServerError(code: 'mock.not_implemented', context: {'method': '...'})` بدل `throw` — يحوّل الانهيار إلى حالة خطأ معروضة. (ب) **اختبار تناظر آلي**: ملف اختبار يمرّ على كل عضو في `BackendAdapter` ويفحص `MockAdapter.<x>` عبر `try/catch` ويفشل إن رمى — فيصبح الرقم في القسم C مُراقَبًا في CI.
- **الملفات ذات الصلة:** كل ملفات `mock/sub/*`، `hardware_status_provider.dart`، `unidentified_events_provider.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-021: الموك يستخدم `DateTime.now()` رغم قاعدة «لا مؤقتات / حتمية» المعلنة
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_duty_status_backend.dart:13`
- **Evidence:**
```dart
// mock_duty_status_backend.dart:11-13
  @override
  Future<Result<RawJson>> record(RawJson event) async =>
      ok(<String, dynamic>{'id': DateTime.now().millisecondsSinceEpoch, ...event});
```
والقاعدة العامة المعلنة:
```dart
// mock_adapter.dart:36
/// **Rule:** No network access. No timers. No platform channels.
```
- **السلوك الحالي:** `id` المُعاد يعتمد على ساعة الجهاز الحقيقية.
- **لماذا هو مشكل:** (أ) يخالف القاعدة الصريحة. (ب) **يكسر الحتمية**: نفس `event` يعطي `id` مختلفًا في كل تشغيل، فأي اختبار يعتمد على `id` يصبح متذبذبًا. (ج) في نظام HOS، توليد معرّف اعتماد حالة من ساعة جهاز **غير موثوقة** (انظر BACK-033) قرار خاطئ في حد ذاته. (د) **`DateTime.now()` في طبقة backend يتجاوز `TrustedTimeProvider`** الموجود والمتاح.
- **المبدأ المنتهك:** Determinism + Single source of truth للوقت.
- **العواقب:** اختبارات متذبذبة؛ معرّفات غير قابلة للتنبؤ في العرض التوضيحي.
- **التصحيح المقترح:** تمرير `TrustedTimeProvider` (أو `FakeTrustedTimeProvider` في الاختبارات) إلى `MockDutyStatusBackend`، أو عداد تصاعدي `int _nextId = 1000;`.
- **الملفات ذات الصلة:** `mock_duty_status_backend.dart`، `mock_adapter.dart:36`، `core/time/trusted_time_provider.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-023: طبقة presentation تستدعي عقود backend مباشرة (تجاوز حدّ الـ port)
- **Severity:** HIGH
- **Category:** Architecture
- **Location:** `lib/features/logs/presentation/providers/unidentified_events_provider.dart:97`
- **Evidence:** مواقع presentation التي تستهلك عقود الـ backend مباشرة (7 مواقع، تحققت من كلٍّ منها بالبحث النصي):
```dart
// unidentified_events_provider.dart:97
    final backend = ref.read(unidentifiedEventsBackendProvider);
```
```dart
// features/connection/presentation/pages/eld_connection_page.dart:87
    final hardwareBackend = _ref.read(hardwareBackendProvider);
```
```dart
// features/connection/presentation/providers/hardware_alerts_provider.dart:42
    final backend = ref.read(hardwareBackendProvider);
```
```dart
// features/connection/presentation/providers/hardware_status_provider.dart:15
    final backend = ref.read(hardwareBackendProvider);
```
```dart
// features/account/presentation/providers/rules_screen_provider.dart:17
    final backend = ref.read(rulesScreenBackendProvider);
```
```dart
// features/account/presentation/providers/account_provider.dart:138
    ref.watch(accountBackendProvider),
```
```dart
// features/hos/presentation/providers/hos_engine_provider.dart:46
  final dashboardBackend = ref.watch(statusDashboardBackendProvider);
```
```dart
// features/logs/presentation/providers/team_status_provider.dart:16
    final backend = ref.read(dailyLogsBackendProvider);
```
- **السلوك الحالي:** في كل هذه المواقع، `presentation` يتجاوز `domain` تمامًا: لا use-case، لا repository. يقرأ `RawJson` بنفسه — `unidentified_events_provider.dart:107`:
```dart
    final otherCount =
        results[1].fold<int?>((_) => null, (json) => _parse(json).length);
```
- **لماذا هو مشكل:** هذا **يكشف أن الـ port ليس حدًا معماريًا**: الواجهة موجودة في `backend/contracts`، لكن **حدود الطبقات سُيّرت من presentation أعدت اختراقها**. عمليًا: أسماء حقول الخادم (`json['data']`, `json['message']`, `json['hasPreviousDvir']`) تصل إلى الـ widgets. بين BACK-001 و BACK-023، **طبقة الـ port صارت شفافة**.
- **المبدأ المنتهك:** Dependency Rule — presentation يعتمد على domain فقط.
- **العواقب:** تغيير مفتاح في الخادم يكسر UI؛ منطق العمل (عدّ التبويبات، تفسير `hasPreviousDvir`) في presentation؛ اختبارات الواجهة تتطلب مزوّدات backend.
- **التصحيح المقترح:** لكل موقع من السبعة، إنشاء repository في `data/` + use-case في `domain/`، وربط presentation بالـ use-case فقط. **الأولوية:** `unidentified_events_provider` (3 دوال خام في presentation)، `hardware_status_provider` + `hardware_alerts_provider`.
- **الملفات ذات الصلة:** الملفات المذكورة أعلاه، `lib/backend/providers/backend_providers.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-024: قيم wire الخاصة بـ backend مسرّبة إلى طبقة العقد وإلى presentation
- **Severity:** MEDIUM
- **Category:** Coupling
- **Location:** `lib/backend/contracts/contract_enums.dart:45-51`
- **Evidence:**
```dart
// contract_enums.dart:45-51
enum DutyStatusAction {
  switchPrimary('switch-primary'),
  legacySwitch('legacy-switch');

  const DutyStatusAction(this.wire);
  final String wire;
}
```
```dart
// contract_enums.dart:37-43
enum UnidentifiedTab {
  unclaimed('UNCLAIMED'),
  rejected('REJECTED');
```
والاستهلاك في presentation:
```dart
// lib/features/logs/presentation/pages/unidentified_events_page.dart:6
import '../../../../backend/contracts/contract_enums.dart';
```
- **السلوك الحالي:** (أ) أسماء `DutyStatusAction` هي حرفيًا قيم Swagger: `'switch-primary'`، `'legacy-switch'` — ليست أسماء مفاهيمية بل أسماء مُعاملات. (ب) `UnidentifiedTab` قيمه `SCREAMING_SNAKE_CASE` مطابقة لتسمية الخادم. (ج) `presentation` يستورد `contract_enums.dart` مباشرة.
- **لماذا هو مشكل:** التسمية الجيدة لعقدة تجعل `DutyStatusAction.makePrimaryDriver` بدل `switchPrimary('switch-primary')`. الاسم الحالي **يقيد التصميم**: تغيير قيمة الخادم من `switch-primary` إلى `switch_to_primary` يجب أن يمسّ قيمة الـ enum — أو يدفع المطوّر لتغيير اسم الـ enum نفسه (وكل مستهلكيه)، وهو تغيير غير ضروري.
- **المبدأ المنتهك:** Naming as a design tool / Information hiding.
- **المالك الحالي:** العقدة. **المالك الصحيح:** التحويل (`wire`) يحدث حاليًا في المحوّل (`eld_unidentified_events_backend.dart:51`: `'tab': tab.wire`) — وهذا صحيح؛ المشكلة في اسم الـ enum نفسه وفي وصوله إلى presentation.
- **العواقب:** تعديل قيمة خادم = تعديل اسم كود في `presentation`. تهريب `backend/contracts` إلى UI.
- **التصحيح المقترح:** إعادة التسمية إلى أسماء سلوكية (`primaryDriverChange`, `legacySwitch`)، وإبقاء `wire` في المحوّل. ومنع استيراد `contracts/` من `presentation`.
- **الملفات ذات الصلة:** `contract_enums.dart`، `unidentified_events_page.dart`، `unidentified_events_provider.dart`، `codriver_repository_impl.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-025: `BackendAdapter` nullable + تحويل `null` إلى `StateError` في 13 مزوّدًا
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/core/backend_adapter.dart:28-31`
- **Evidence:**
```dart
// backend_adapter.dart:27-33
  // ==========================================================================
  // Contracts — all nullable (a backend may not support all features)
  // ==========================================================================

  AuthBackend? get auth;

  AccountBackend? get account;
```
والتحويل في كل مستهلك:
```dart
// backend_providers.dart:59-62
final authBackendProvider = Provider<AuthBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.auth ?? (throw StateError('AuthBackend not supported by active adapter'));
});
```
(يتكرر في 13 مزوّدًا: 61، 66، 71، 76، 81، 86، 91، 96، 101، 106، 111، 116).
- **السلوك الحالي:** الـ nullability **ليست** مرونة بل **غياب أنواع**. كلا المحوّلين ينفّذ **كل** الـ 14 getter كغير-null (`eld_engine_adapter.dart:52-93`، `mock_adapter.dart:56-99`)، فالـ `?` **لا يتحقق أبدًا**.
- **لماذا هو مشكل:** (أ) كل واحد من الـ 14 عقدة محاط بـ `?` — الـ compiler يسمح لـ `adapter.dvir!` في أي مكان. (ب) الاستبدال بـ `StateError` في 13 مكانًا يعني أن الكود **لا يستطيع معرفة** ما هي العقود غير المدعومة إلا بالتشغيل. (ج) **الغموض مستخدم فعليًا**: لا يوجد أي عقدة تُرجع null، فالثنائية «قد لا يدعم» وهمية.
- **المبدأ المنتهك:** Sound nullability / Honest type signatures.
- **العواقب:** 13× `StateError` غير معالَج أثناء بناء شجرة Riverpod. `throw` داخل Provider body يُنتج خطأ تحميل، لا حالة خطأ قابلة للتعامل.
- **التصحيح المقترح:** إمّا (أ) **اجعلها غير nullable**: `required DvirBackend get dvir;`، وافصل `supports(...)` إن لزم. أو (ب) إن كانت النية فعلًا أن يدعم backend ناقصًا، فالمسؤول عن الاستدعاء يجب أن يفحص قبل الاعتماد. **الاقتراح (أ)** هو الأنظف ويحذف 13 `throw`.
- **الملفات ذات الصلة:** `backend_adapter.dart`، `backend_providers.dart`، `eld_engine_adapter.dart`، `mock_adapter.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-027: `BackendRegistry` (129 سطرًا) بلا أي مستهلك إنتاجي
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/core/backend_registry.dart:17`
- **Evidence:**
```dart
// backend_registry.dart:78-100
  /// The currently active adapter.
  ///
  /// This is what features access.
  BackendAdapter get active => _adapters[activeIdentity.id]!;

  /// Returns the adapter with the given [id], or `null` if missing.
  BackendAdapter? getById(String id) => _adapters[id];

  /// Returns the adapter matching the given [identity], or `null`.
  BackendAdapter? getByIdentity(BackendIdentity identity) =>
      _adapters[identity.id];

  /// All registered adapters.
  Iterable<BackendAdapter> get all => _adapters.values;

  /// Whether an adapter with the given [id] is registered.
  bool has(String id) => _adapters.containsKey(id);

  /// The number of registered adapters.
  int get length => _adapters.length;

  /// Whether this registry contains only a mock adapter.
  bool get isMockOnly => _adapters.values.every((a) => a.isMock);
```
الاستهلاك الوحيد في `lib/`:
```dart
// backend_providers.dart:27-29
final backendRegistryProvider = Provider<BackendRegistry>((ref) {
  return BackendRegistry.single(ref.watch(activeBackendProvider));
});
```
- **السلوك الحالي:** بحثت في `lib/` بالكامل: `BackendRegistry` يظهر **فقط** في `backend_registry.dart` و`backend_providers.dart:27-28`. **لا يوجد أي مستهلك لـ `backendRegistryProvider`**. أي: `getById`، `getByIdentity`، `all`، `has`، `length`، `isMockOnly`، `disposeAll` — **سبعة أعضاء، صفر استدعاء إنتاجي**. و`single()` (71) يُلغي تمامًا تعدد الـ adapters الذي تبرره الترويسة (10-13).
- **لماذا هو مشكل:** هذا هو السؤال المطلوب («هل `BackendAdapter`/`backend_registry` تجريد حقيقي أم زخرفي؟»): **الإجابة: `BackendAdapter` حقيقي و`BackendRegistry` زخرفة**. الأول مُستخدم فعليًا (13 getter تُستهلك في 13 provider)، والثاني مصنع لا يحتاجه أحد.
- **المبدأ المنتهك:** YAGNI / Dead abstraction.
- **العواقب:** 129 سطرًا + ملف اختبار معزول (`test/backend/core/backend_registry_test.dart`) تُصان بلا فائدة؛ توثيق يَعِد ("قد تحتاج عدة backends") لا يتحقق.
- **ملاحظة أمانة:** يوجد `test/backend/core/backend_registry_test.dart` (10 إشارات) — أي أنه **مُختبر في عزلة** لا مستهلَك. لذلك بدقة: ليس بلا أي استخدام، بل **بلا أي استخدام إنتاجي**.
- **التصحيح المقترح:** حذف `BackendRegistry` و`backendRegistryProvider` بالكامل، والاكتفاء بـ `activeBackendProvider` من النوع `BackendAdapter`. إن كان التوسع المستقبلي مرغوبًا، يُعاد إحياؤه عند الحاجة الفعلية.
- **الملفات ذات الصلة:** `backend_registry.dart`، `backend_providers.dart:27-29`، `backend_adapter.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-029: `EldEndpoints` مبني على `int`/`String` الخام بينما العقدة تستخدم Value Objects
- **Severity:** LOW
- **Category:** Architecture
- **Location:** `lib/backend/http/eld_endpoints.dart:53`
- **Evidence:**
```dart
// eld_endpoints.dart:53-55
  static String dailyLogDetails(int logId) => '/eld/daily-logs/$logId';
  /// الرد على تعديلات الناقل
  static String respondCarrierEdit(int logId, String editId) => '/eld/daily-logs/$logId/carrier-edits/$editId/respond';
```
و18 موقعًا آخر بنفس النمط (57، 59، 61، 63، 65، 67، 69، 73، 75، 88، 90، 98، 101، 105، 107، 109، 133، 135). بينما العقدة تستخدم:
```dart
// daily_logs_backend.dart:24
  Future<Result<RawJson>> getById(DailyLogId logId);
```
والاستدعاء يتطلب `.value` يدويًا في كل موقع:
```dart
// eld_daily_logs_backend.dart:49
      EldEndpoints.dailyLogDetails(logId.value),
```
- **السلوك الحالي:** طبقة الـ endpoints تتوقف عند النوع البدائي، والنقاط تتوقف عند value object. `domain/shared/value_objects.dart` (المستوردة في كل عقدة) **لا تُستخدم في بناء المسار**.
- **لماذا هو مشكل:** الفصل بين الطبقتين لا يبرّر تجاهل أنواع النطاق: `EldEndpoints` في طبقة `http/` (الأدنى) يستطيع استيراد `domain/shared` كما تفعل المحوّلات. النتيجة: **≈20 استدعاء `.value` يدوي**، ولكل منها فرصة نسيان. في DVIR مثلًا: `DvirId.value` في 3 مواضع (73، 88، 100) — احتمال خلط `dvirId.value` مع `statusId.value` في نفس الاستدعاء لا يلتقطه الـ compiler.
- **المبدأ المنتهك:** Type safety at boundaries.
- **العواقب:** أخطاء نوعية في وقت التشغيل لا وقت الترجمة.
- **التصحيح المقترح:** جعل `EldEndpoints` يقبل الأنواع المحاطة مباشرة بعد إضافة `toString()` تُعيد القيمة في `DailyLogId`/`DvirId`/`EditId`/`DutyStatusId` — عندها تُحذف كل استدعاءات `.value`.
- **الملفات ذات الصلة:** `eld_endpoints.dart`، `lib/domain/shared/value_objects.dart`، كل `eld_*_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-034: `backend_network_providers.dart` يحتوي ميزةَين غير متعلقتين بالباك-إند ويكرّر منطق اختيار الموك
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/providers/backend_network_providers.dart:77-82`
- **Evidence:**
```dart
// backend_network_providers.dart:76-82
// Provider لعميل التتبع الخلفي (بديلاً عن trackingClientProvider)
final traccarNativeClientProvider = Provider<TraccarNativeClient>((ref) {
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    return MockTraccarNativeClient();
  }
  return TraccarNativeClientImpl();
});
```
مقابل المنطق المركزي الحاضر في الملف المجاور:
```dart
// backend_providers.dart:38-43
  final choice = resolveRuntimeBackend(
    environment: AppEnvironmentConfig.current,
    buildBaseUrl: AppEnvironmentConfig.apiBaseUrl,
    savedServerUrl: ref.watch(serverUrlProvider),
    savedBackendType: prefs.backendType,
  );
```
- **السلوك الحالي:** `backend/providers` يحوي **اختيارًا ثلاثيًا** (`eldEngine` vs `mock`) في `activeBackendProvider` (36-53)، **واختيارًا ثنائيًا** (`mock` vs `TraccarNativeClientImpl`) هنا. عمليتان مختلفتان تمامًا خلف ملف واحد. والأهم: فحص `AppEnvironmentConfig.current == AppEnvironment.mock` **مكرَّر** هنا بينما `activeBackendProvider` يستخدم الدالة المركزية `resolveRuntimeBackend(...)`.
- **لماذا هو مشكل:** (أ) الملف اسمه `backend_network_providers` لكن الأسطر 11-13 تستورد `features/tracking/data/datasources/traccar_sdk/*` — فمزوّد تتبّع في مجلد الباك-إند. (ب) **منطقان مختلفان لاتخاذ نفس القرار** في نفس المجلد — وهذا مصدر خلاف مستقبلي (مثل `serverUrl` محفوظ: `resolveRuntimeBackend` يحترمه، والفحص المباشر هنا لا).
- **المبدأ المنتهك:** SRP على مستوى الملف + DRY في القرار.
- **العواقب:** `traccarNativeClientProvider` يجب أن يُنقل إلى `features/tracking/data/providers/`؛ خطر أن يختلف شرط الموك بين المسارين.
- **التصحيح المقترح:** نقل المزوّد إلى `features/tracking/data/providers/traccar_native_client_provider.dart` واستخدام `resolveRuntimeBackend(...)` بدل فحص `AppEnvironment` مباشرة.
- **الملفات ذات الصلة:** `backend_network_providers.dart`، `backend_providers.dart:38-43`، `core/config/runtime_selection.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-035: `mock` يعتمد على تحويلات `eld_engine` — الموك ليس بديلاً مستقلاً
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_rules_screen_backend.dart:7-8`
- **Evidence:**
```dart
// mock_rules_screen_backend.dart:7-8
import '../../eld_engine/models/rules_screen_dto.dart';
import '../../eld_engine/mappers/rules_screen_mapper.dart';
```
```dart
// mock_daily_logs_backend.dart:5-6
import '../../eld_engine/models/certify_dto.dart';
import '../../eld_engine/models/readiness_dto.dart';
```
- **السلوك الحالي:** **4 ملفات** من مجلد `mock/` تستورد من مجلد `eld_engine/`. المحوّلان داخل نفس `BackendAdapter` لكن في فرعين مختلفين من الشجرة، وأحدهما يعتمد على الآخر.
- **لماذا هو مشكل:** الموك موجود ليختبر سلوكًا معزولًا عن المحرك الحقيقي. بجعل الموك يستخدم DTOات ومحوّل المحرك الحقيقي، صار: (1) الاختبار على الموك **لا يختبر العزل** بل يختبر المحرك عبر مسار بديل؛ (2) **تعديل DTO في `eld_engine` يكسر `mock`** — فالفصل البنيوي بين المحوّلين غير قائم؛ (3) الرسم البياني لطبقات الاعتمادية لم يعد شجريًا.
- **المبدأ المنتهك:** Parallel implementations / ISP.
- **العواقب:** إعادة استخدام DTOات (وهي الحل الصحيح لـ BACK-004) **ستُصلح** هذه المشكلة تلقائيًا، لأن DTO ستصبح في `contracts/dto/` ولا يبقى داعٍ للاستيراد العابر.
- **التصحيح المقترح:** نقل `certify_dto.dart`، `readiness_dto.dart`، `rules_screen_dto.dart`، `rules_screen_options.dart`، و`rules_screen_mapper.dart` إلى `lib/backend/contracts/dto/` + `lib/backend/contracts/mappers/` مشتركين. **تغيير واحد يحل BACK-004 و BACK-035 و BACK-002 جزئيًا.**
- **الملفات ذات الصلة:** `mock_rules_screen_backend.dart`، `mock_daily_logs_backend.dart`، `eld_engine/models/*`، `contracts/daily_logs_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-001: `core/widgets/connection_status_indicator.dart` يكسر استقلال الطبقة ويدخل في دورة استيراد من 25 ملفاً
- Severity: **CRITICAL**
- Category: Layer inversion / Import cycle / Dependency rule violation
- Location `lib/core/widgets/connection_status_indicator.dart:1-8`
- Evidence code block:
```dart
 1: import 'package:flutter/material.dart';
 2: import 'package:flutter_riverpod/flutter_riverpod.dart';
 3: import '../../features/tracking/domain/entities/connection_status.dart';
 4: import '../theme/app_colors.dart';
 5: import '../extensions/context_extensions.dart';
 6: import 'package:go_router/go_router.dart';
 7: import '../../routes.dart';
 8: import '../events/eld_events_provider.dart';
```
- Current behavior: هذا الملف هو **الملف الوحيد** في كامل `lib/core/theme/**` و `lib/core/widgets/**` (25 ملفاً) الذي يستورد من `lib/features/**` أو `lib/routes.dart`. تحقّقت بالأمر:
```
core\widgets\connection_status_indicator.dart:3: import '../../features/tracking/domain/entities/connection_status.dart';
core\widgets\connection_status_indicator.dart:7: import '../../routes.dart';
```
  الدورة المصغّرة (أربعة ملفات) بهذا التسلسل:
```
lib/core/widgets/connection_status_indicator.dart:7    -> import '../../routes.dart';
lib/routes.dart:8                                       -> import 'routes/home_routes.dart';
lib/routes/home_routes.dart:3                          -> import '../features/home/presentation/pages/home_page.dart';
lib/features/home/presentation/pages/home_page.dart:11 -> import '../../../../core/widgets/connection_status_indicator.dart';
```
  وبحث SCC كامل بخوارزمية Tarjan على **408 ملفات Dart**، تبيّن أن المكوّن المترابط تسلكياً بأكمله = **25 ملفاً بالضبط**، و`connection_status_indicator.dart` هو ملف `core` الوحيد داخله:
```
core\widgets\connection_status_indicator.dart       routes\account_routes.dart
routes.dart                                         routes\auth_routes.dart
routes\dvir_routes.dart                             routes\home_routes.dart
routes\logs_routes.dart                             features\home\presentation\pages\home_page.dart
features\home\presentation\widgets\eld_drawer.dart  features\hos\presentation\widgets\driving_lock_screen.dart
features\about\presentation\pages\about_page.dart   features\account\presentation\pages\account_page.dart
features\account\presentation\pages\info_packet_page.dart   features\account\presentation\pages\rules_page.dart
features\codriver\presentation\pages\codriver_page.dart     features\connection\presentation\pages\eld_connection_page.dart
features\connection\presentation\widgets\eld_diagnostics_section.dart
features\connection\presentation\widgets\manual_recording_section.dart
features\dvir\presentation\pages\dvir_list_page.dart
features\inspection\presentation\pages\dot_inspection_page.dart
features\inspection\presentation\pages\inspection_start_view.dart
features\logs\presentation\pages\logs_list_page.dart
features\logs\presentation\pages\suggested_events_page.dart
features\settings\presentation\pages\settings_page.dart
features\vehicle\presentation\pages\select_vehicle_page.dart
```
- Why problematic:
  1. **قاعدة الاتجاه معكوسة**: `core` لا يعلم `features` ولا `routes`. الملف يسحب طبقة التطبيق كاملة إلى ورقة تحتها.
  2. **`AppRoutes` غير قابلة للاختبار منفرداً**: السطر 39 `context.push(AppRoutes.connection)` يفرض إنشاء الرسم البياني الكامل للتصفح قبل اختبار هذا الـwidget.
  3. **حجم إعادة البناء إجباري**: أي تعديل في `routes.dart` أو في إحدى صفحات الـfeature العشرين يُجبر إعادة ترجمة هذا الملف ضمن `core`.
  4. **تسرّب أعمق عبر `core/events`**: `lib/core/events/eld_events_provider.dart:3` يستورد بدوره `features/tracking/data/datasources/live_tracking_data_source.dart` — أي أن `core` يستورد **طبقة data** لا مجرد كيان.
- Violated principle: Dependency Inversion (Dependency Rule) — Clean Architecture، الطبقات الداخلية لا تعرف الخارجية.
- Current owner: `lib/core/widgets/connection_status_indicator.dart`
- Correct owner: `lib/features/tracking/presentation/widgets/connection_status_indicator.dart` — كـwidget عرض تستهلكه الصفحة، مع تمرير `onTap` بدل `AppRoutes`.
- Consequences: استحالة اختبار الوحدة للـwidget دون تشغيل الموجّه؛ عواصف إعادة بناء؛ منع إعادة استخدام `core/widgets` في تطبيق آخر (white-label أو حزمة مشتركة)؛ خطر ترابط غير مقصود يبقي `core` غير قابل لإعادة الاستخدام.
- Recommended correction:
  1. انقل الملف كاملاً إلى `lib/features/tracking/presentation/widgets/`.
  2. احذف `import '../../routes.dart'`؛ وحوّل `onPressed` إلى معامل `VoidCallback? onTap` يمرّره المضيف.
  3. احذف `import '../../features/tracking/domain/entities/connection_status.dart'`؛ واجعل النوع يُمرَّر من المضيف.
  4. إن أصررت على بقائه في `core`: اعرض واجهة منظّمة في `core/events/eld_events_provider.dart` تحمل `String` بدل enum الـfeature.
- Related files: `lib/routes.dart:8`, `lib/routes/home_routes.dart:2-3`, `lib/features/home/presentation/pages/home_page.dart:11`, `lib/core/events/eld_events_provider.dart:3,5,16-18`, `lib/features/tracking/domain/entities/connection_status.dart:1-8`
- Confidence: **CONFIRMED** (الـ SCC محسوب آلياً؛ عدّ 25 ملفاً مُطابق)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-019: `eld_events_table.dart` يثبت شكل جدول RODS داخل `core`
- Severity: **MINOR**
- Category: Presentation shape locked in shared layer
- Location `lib/core/widgets/eld_events_table.dart:6-24`, `:59-100`
- Evidence code block:
```dart
 6: class EldTableRow {
 7:   final String time;
 8:   final String status;
 9:   final String location;
10:   final String odom;
11:   final String eng;
12:   final String src;
13:   final Color? statusColor;
```
```dart
// lib/core/theme/app_colors.dart (للإشارة: شكل الورقة الرسمية)
108:  // ========== جدول رأس السجل اليومي RODS (شكل الورقة الرسمية) ==========
109:  static const Color rodsHeaderBg = Color(0xFFF2F2F2);
110:  static const Color rodsHeaderText = Color(0xFF222222);
111:  static const Color rodsHeaderSubtext = Color(0xFF333333);
```
- Current behavior: **مُجيب على السؤال 2: الملف لا يُعيد حساب أي شيء.** كل الحقول `String` جاهزة من المستدعي، ولا استيراد لأي `domain` أو `features`. لكنه يثبت **ستة أعمدة** (`time/status/location/odom/eng/src`) وعروضاً (`60/2/3/60/55/40`) داخل `core`. ويُستهلك من صفحتين: `inspection_active_view.dart:14` و `inspection_preview_page.dart:18`.
- Why problematic: جدول RODS ورسم معاينة التفتيش ليسا نفس النموذج؛ وتثبيت الأعمدة في `core` يمنع إضافة أعمدة دون تعديل مشترك.
- Violated principle: Open/Closed for shared components.
- Current owner: `lib/core/widgets/eld_events_table.dart`
- Correct owner: `lib/features/inspection/presentation/widgets/` كجدول تخصصي — إلا إذا كان `core` هو المكان المقصود مركزياً.
- Consequences: ترابط إجباري عند اختلاف الأعمدة.
- Recommended correction: اجعل الأعمدة `List<_ColumnSpec>` قابلة للتمرير، أو انقل الملف إلى `features/inspection/`.
- Related files: `lib/features/inspection/presentation/pages/inspection_active_view.dart:14`, `lib/features/inspection/presentation/pages/inspection_preview_page.dart:18`, `lib/core/theme/app_colors.dart:108-111`
- Confidence: **POTENTIAL** (لم يُحسم هل القالب مطلوب مركزياً أم خاص بصفحة)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-022: `StatusColorHelper` في `core/utils` ثالث تنفيذ لخرائط الحالة إلى اللون
- Severity: **MINOR**
- Category: Triplicated mapping / Layer confusion
- Location `lib/core/utils/status_color_helper.dart:1-8`
- Evidence code block:
```dart
1: import 'package:flutter/material.dart';
2: import '../../domain/duty_status/duty_status_code.dart';
3:
4: class StatusColorHelper {
5:   static Color getStatusColor(String status) {
6:     return DutyStatusCode.fromAny(status).displayColor;
7:   }
8: }
```
- Current behavior: ثلاث خرائط مستقلة لنفس المعرفة:
  1. `lib/domain/duty_status/duty_status_code.dart:75-88` — `displayColor` بقيم مثل `0xFF10B981`.
  2. `lib/core/utils/status_color_helper.dart:5-7` — غلاف رقيق.
  3. `lib/features/logs/presentation/pages/inspection_preview_page.dart:273-286` — خريطة **مستقلة تماماً** بقيم مختلفة:
```dart
273:  Color _getStatusColor(BuildContext context, String? status) {
274:    switch (status) {
275:      case 'D':
276:        return AppColors.successGreen;
277:      case 'ON':
278:        return AppColors.warningYellow;
279:      case 'SB':
280:        return AppColors.infoBlue;
281:      case 'OFF':
282:        return AppColors.textSecondary;
283:      default:
284:        return AppColors.textPrimary;
285:    }
286:  }
```
  الخريطة (3) تعطي `D = 0xFF34C759` بينما الخريطة (1) تعطي `D = 0xFF10B981` — **لونان مختلفان لنفس الحالة في شاشتين**.
- Why problematic: `core/utils` ملف بلا مسؤولية واضحة (ليس util ولا widget ولا service)، ويؤسس نمط «طبقة ألوان» ثالثة.
- Violated principle: Single source of truth / clear module responsibility.
- Current owner: `lib/core/utils/status_color_helper.dart`
- Correct owner: خريطة واحدة في `core/presentation/` أو `lib/core/theme/` بعد إخراج اللون من `domain` (راجع CUI-013).
- Consequences: نفس الحالة تظهر بألوان مختلفة عبر التطبيق.
- Recommended correction: ادمج في خريطة واحدة؛ واحذف الملف أو اجعله طبقة رقيقة فوق `AppColors`.
- Related files: `lib/domain/duty_status/duty_status_code.dart:75-88`, `lib/features/logs/presentation/pages/inspection_preview_page.dart:273-286`
- Confidence: **CONFIRMED**

---

## C. Duplication table مع `lib/features/**`

| # | مكوّن `core/widgets` (المرجع) | إعادة التنفيذ في `features/**` | العدد | نوع التكرار |
|---|---|---|---|---|
| 1 | `eld_retry_view.dart:36-45` (رسالة + زر إعادة محاولة بـ`loc.retryButton`) | `logs/presentation/pages/edit_log_page.dart:379-395` | 1 | كامل |
| | | `logs/presentation/pages/unidentified_events_page.dart:247-258` | 2 | كامل |
| | | `logs/presentation/widgets/vehicle_picker_dialog.dart:153` | 3 | جزئي (زر فقط) |
| | | `logs/presentation/widgets/codriver_picker_dialog.dart:65` | 4 | جزئي |
| | | `logs/presentation/widgets/log_detail_tabs/certify_tab.dart:131` | 5 | جزئي |
| | **مقابل: مستخدمو `EldRetryView` الصحيحين** | `logs_list_page.dart:9,71,78`، `status_dashboard_page.dart:5,113`، `recap_page.dart:8,72`، `dvir_list_page.dart:12,75`، `inspection_preview_page.dart:6,128`، `events_tab.dart:11,38,45`، `select_vehicle_page.dart:6`، `rules_page.dart:8` | **8** | مرجع |
| 2 | `app_status_pill.dart:28-51` و `app_status_badge.dart:65-94` (شارة بلون) | `dvir/presentation/widgets/active_defects_section.dart:65-87` (`_severityPill`) | 1 | كامل (يدوي) |
| | | `core/widgets/connection_status_indicator.dart:60-99` (CUI-002، داخل `core`) | 1 | كامل |
| 3 | `app_text_field.dart:64-122` (غلاف `TextFormField`) | `dvir/presentation/widgets/dvir_form_components.dart:124-160` (`DvirFlatTextField`) و `:162-198` (`DvirDropdownField`) | 2 | جزئي (مسطح) |
| 4 | `eld_card.dart` + `app_decorations.dart:18-28` + `app_theme.dart:50-58` | `dvir/presentation/widgets/dvir_form_components.dart:16-42,61-88,102-122` (حدود `Color(0xFFE0E0E0)` يدوية ثلاث مرات) | 3 | كامل |
| 5 | `eld_graph_grid.dart:330-338` + `:160` (ترتيب `OFF/SB/D/ON`) | `inspection/presentation/widgets/inspection_duty_graph.dart:130-162` (`_rowOf`) | 1 | كامل |
| | | `logs/presentation/widgets/log_graph.dart:46-53` (`normalized`) | 2 | كامل |
| 6 | خريطة الحالة إلى اللون | `domain/duty_status/duty_status_code.dart:75-88` + `core/utils/status_color_helper.dart:5-7` + `inspection_preview_page.dart:273-286` | 3 خرائط | خريطة لون |
| 7 | `app_button.dart` (زر موحد) | `codriver_page.dart` (FilledButton مرتين)، `permissions_page.dart:8`، `unidentified_events_page.dart`، `codriver_picker_dialog.dart`، `diagnostics_page.dart:9` (OutlinedButton)، `dvir_form_sections.dart` (ElevatedButton) | 6 مواضع | جزئي |
| 8 | قاعدة `app_colors.dart:12-14` (عدم إنشاء `Color(0x...)` خارجي) | `dvir_form_components.dart:20,65,106,153,189`، `dvir_form_sections.dart:404,469`، `main_circular_timer.dart:184-185` | 9 قيم | قاعدة مكسورة |

**الإجمالي: 25+ موضعاً في `lib/features/**` تعيد تنفيذ ما يقدمه `lib/core/widgets/**` و `lib/core/theme/**`.**

---

## D. قائمة الملفات المقروءة (بأعداد أسطر حقيقية) — إثبات التغطية

| # | المسار | الأسطر | غير الفارغ |
|---|---|---|---|
| 1 | `lib/core/theme/app_colors.dart` | **155** | 112 |
| 2 | `lib/core/theme/app_decorations.dart` | **71** | 64 |
| 3 | `lib/core/theme/app_radius.dart` | **31** | 22 |
| 4 | `lib/core/theme/app_shadows.dart` | **28** | 25 |
| 5 | `lib/core/theme/app_spacing.dart` | **18** | 16 |
| 6 | `lib/core/theme/app_styles.dart` | **244** | 234 |
| 7 | `lib/core/theme/app_theme.dart` | **222** | 211 |
| 8 | `lib/core/theme/app_theme_provider.dart` | **48** | 40 |
| 9 | `lib/core/theme/app_typography.dart` | **75** | 67 |
| 10 | `lib/core/theme/press_feedback.dart` | **34** | 30 |
| 11 | `lib/core/widgets/app_button.dart` | **194** | 174 |
| 12 | `lib/core/widgets/app_feedback.dart` | **116** | 104 |
| 13 | `lib/core/widgets/app_signature_canvas.dart` | **232** | 218 |
| 14 | `lib/core/widgets/app_status_badge.dart` | **96** | 89 |
| 15 | `lib/core/widgets/app_status_pill.dart` | **53** | 49 |
| 16 | `lib/core/widgets/app_text_field.dart` | **125** | 121 |
| 17 | `lib/core/widgets/connection_status_indicator.dart` | **101** | 92 |
| 18 | `lib/core/widgets/critical_error_app.dart` | **58** | 55 |
| 19 | `lib/core/widgets/dashed_line_painter.dart` | **24** | 21 |
| 20 | `lib/core/widgets/eld_card.dart` | **41** | 38 |
| 21 | `lib/core/widgets/eld_date_paginator.dart` | **73** | 69 |
| 22 | `lib/core/widgets/eld_events_table.dart` | **187** | 178 |
| 23 | `lib/core/widgets/eld_graph_grid.dart` | **348** | 289 |
| 24 | `lib/core/widgets/eld_info_row.dart` | **63** | 60 |
| 25 | `lib/core/widgets/eld_retry_view.dart` | **51** | 46 |

**المجموع: 2354 سطراً** — تمت قراءة كل ملف كاملاً (لا استنتاج من الاسم).

### ملفات داعمة قرئت أيضاً (للأدلة فقط، خارج نطاق التدقيق)
`lib/domain/duty_status/duty_status_code.dart` (99)، `lib/core/extensions/context_extensions.dart` (112)، `lib/core/utils/status_color_helper.dart` (8)، `lib/core/design_system.dart` (19)، `lib/routes.dart` (100)، `lib/routes/home_routes.dart`، `lib/core/events/eld_events_provider.dart` (18)، `lib/features/tracking/domain/entities/connection_status.dart` (8)، `lib/features/logs/presentation/widgets/log_graph.dart` (101)، `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart` (176)، `lib/features/inspection/presentation/widgets/inspection_log_header_table.dart` (259)، `lib/features/sync/presentation/widgets/sync_status_indicator.dart` (46)، `lib/features/dvir/presentation/widgets/dvir_form_components.dart` (199)، `lib/features/dvir/presentation/widgets/active_defects_section.dart` (257)، `lib/features/hos/presentation/pages/status_dashboard_page.dart` (118)، `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart` (365)، `lib/features/logs/presentation/pages/{edit_log_page,unidentified_events_page,dvir_list_page,inspection_preview_page}.dart`، `lib/app.dart`، `lib/main.dart`.

### التحقق من دورة الـ 25 ملفاً (SCC)
حُسب المكوّن المترابط تسلكياً (Strongly Connected Component) آلياً بخوارزمية Tarjan على **408 ملفات Dart** داخل `lib/`:
- المكوّنات المترابطة بحجم أكبر من واحد: **5**، ومجموع عقدها **35**.
- المكوّن الأول بحجم **25 بالضبط**، وكل أعضائه مُدرجة في CUI-001، ويحتوي `core/widgets/connection_status_indicator.dart` كملف `core` وحيد.
- الثاني (4 ملفات): ملفات `l10n` المتبادلة فيما بينها.
- الثالث (ملفان): `core/services/local_storage_service.dart` و `core/services/tracking_config_storage_service.dart`.
- الرابع (ملفان): `backend/providers/backend_network_providers.dart` و `core/network/core_providers.dart`.
- الخامس (ملفان): `features/logs/data/providers/log_repository_providers.dart` و `features/logs/data/repositories/log_repository_impl.dart`.

### إجابات سريعة عن الأسئلة المفصلة
1. **هل يستورد `core/theme` أو `core/widgets` من `features` أو `app`؟** — نعم، **ملف واحد فقط**: `connection_status_indicator.dart:3` و `:7` (CUI-001، CONFIRMED، دورة من 25 ملفاً). الملفات الأربعة والعشرون الأخرى نقيّة من أي استيراد متعاكس.
2. **هل تتسرب قواعد ELD إلى widgets المشتركة؟** — `eld_card` و `eld_info_row` و `eld_retry_view` و `eld_date_paginator` و `eld_events_table`: **متوافقة (COMPLIANT)**، ترسم بيانات مُمررة فقط ولا تستورد `domain` ولا تحوي عتبات. الاستثناء الوحيد: `eld_graph_grid.dart` الذي يضمّن رموز `OFF/SB/D/ON` وترتيب الصفوف (CUI-004، MODERATE) — **ولا يحسب فترات HOS**؛ الحساب في `log_graph.dart:37-55` و `inspection_duty_graph.dart:19-51`.
3. **التكرار مع features** — 25+ موضعاً، موثق في القسم C (CUI-016).
4. **`app_feedback.dart`** — لا نصوص مشفرة (يمررها المستدعي)، **لكنه يتجاوز `snackBarTheme`** ويستخدم قيم `0xFF323232` و `8` و `black26` و `3 ثوان` مشفرة، ولديه `static OverlayEntry? _activeEntry` عام (CUI-006).
5. **`critical_error_app.dart`** — نعم: `lib/core/widgets/critical_error_app.dart:33` هو النص `'عذراً، حدث خطأ حرج'`، وعنوان ثابت إنجليزي في `:17` (CUI-005).
6. **`app_theme` و `app_styles` و `app_colors`** — **لا توجد أي نقطة نهاية ولا لون ذو دلالة تنظيمية ولا قيمة بيئة**؛ والـ`Color(0x...)` الوحيد خارج `AppColors` هو `:220` المكرر حرفيا عن `app_colors.dart:124` (CUI-007). وبخصوص `duty_status_code.dart:75-88`: **لا تكرار حرفي**، بل **أربع تعليقات مضللة** — كل قيمة تختلف عن الرمز الذي تدّعي مساواته (CUI-013).
7. **الترجمة** — مُعرَّفة في: `app_signature_canvas.dart:91,135,172`، `eld_events_table.dart:41,62,69,76,83,90,97`، `eld_retry_view.dart:37`، `connection_status_indicator.dart:51,55`. ومُتجاوَزة في: `critical_error_app.dart:17,33` و `eld_graph_grid.dart:104-106,160,177`.
8. **`app_signature_canvas.dart`** — **لا شيء خارج العرض**: لا قواعد عمل، ولا حفظ، ولا شبكة، ولا إدخال أو إخراج بيانات في الـ232 سطراً (CUI-012 — الألوان فقط).
9. **`app_theme_provider.dart`** — غير متماسك: حالة ثيم مع ترحيل بيانات ومحركَي تخزين (CUI-008).
10. **`eld_graph_grid.dart`** — **ثلاثة أصناف / إحدى عشرة دالة**؛ painter وgrid قابل لإعادة الاستخدام هندسياً، لكنه **يضمّن ترميز رموز الحالة التنظيمية وترتيب الصفوف** ولا يحسب فترات HOS (CUI-004).

> **ملاحظة منهجية**: لم يُبلَّغ عن عبارة «`core/widgets` يستورد `flutter/material`» — وهو نمط مشروع. كل مخالفة أعلاه مثبتة باقتباس حرفي ورقم سطر حقيقي.

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-004: المستودع يؤدّي DTO→entity mapping يدوياً رغم وجود مجلد `mappers/`
- **Severity:** Medium
- **Category:** Layer Responsibility (SRP)
- **Location:** `lib/features/dvir/data/repositories/dvir_repository_impl.dart:327-387`
- **Evidence:**
```dart
  DvirReport _mapDtoToEntity(DvirDto dto) {
    return DvirReport(
      id: dto.id.toString(),
      ...
      selectedDefects: [
        for (final defect in dto.defects)
          if ((defect.itemCode ?? '').trim().isNotEmpty || (defect.itemName ?? '').trim().isNotEmpty)
            DvirDefectSelection(
              item: DvirCatalogItem(
                code: defect.itemCode?.trim() ?? 'GENERIC',
```
- **Current behavior:** 61 سطراً من mapping + 3 دوال تحليل مساندة (`_parseDate:313`، `_parseInspectionType:375`، `_parseVehicleCondition:380`) **داخل المستودع**، بينما `data/mappers/dvir_mappers.dart` (208 سطر) و `dvir_defect_mappers.dart` (91 سطر)exists لهذا الغرض.
- **Why problematic:** انقسام **غير متسق**: قراءة الكتالوج والعيوب في mappers، وقراءة **التقرير الرئيسي** في المستودع؛ فالمستودع يجمع تنسيق الشبكة + mapping معاً.
- **Violated principle:** SRP، تماسك حدود الطبقة.
- **Current owner:** `DvirRepositoryImpl`
- **Correct owner:** `data/mappers/dvir_mappers.dart` كـ `DvirReport mapDtoToEntity(DvirDto)`
- **Consequences:** صعوبة اختبار mapping بمعزل؛ تكرار نمط السلسلة الهرمية الحرفية في كل mapping جديد.
- **Recommended correction:** نقل `_mapDtoToEntity` والـ 3 دوال إلى `data/mappers/dvir_mappers.dart`؛ يبقى المستودع تنسيقاً فقط.
- **Related files:** `data/mappers/dvir_mappers.dart`, `data/mappers/dvir_defect_mappers.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-005: هندسة مكرّرة للـ create body داخل نفس مسار النداء
- **Severity:** High
- **Category:** Duplicated Orchestration / Layer Leak
- **Location:** `lib/features/dvir/data/repositories/dvir_repository_impl.dart:229-264`
- **Evidence:**
```dart
  Map<String, dynamic>? _buildCreateBody(
    DvirReport report, {
    required int driverId,
    required DvirConditionStatus status,
  }) {
    // Reconcile status: if the report has defects, status cannot be satisfactory.
    final effectiveStatus =
        (report.hasDefects || report.selectedDefects.isNotEmpty) &&
                status == DvirConditionStatus.satisfactory
            ? DvirConditionStatus.hasDefects
            : status;
    ...
    return buildDvirCreateBody(
      ...
      status: effectiveStatus.wire,
```
- **Current behavior:** المستودع يحسب `effectiveStatus` ثم يمرره إلى `buildDvirCreateBody` الذي **يعيد تطبيق نفس القاعدة**:
```dart
// dvir_mappers.dart:137-141
  var wireStatus = status.trim();
  if (defects.isNotEmpty &&
      wireStatus == DvirConditionStatus.satisfactory.wire) {
    wireStatus = DvirConditionStatus.hasDefects.wire;
  }
```
- **Why problematic:** نفس القاعدة (DVIR-09) مطبَّقة **مرتين في نفس مسار التنفيذ**، وقبلهما مرة ثالثة في الـ Widget (انظر DST-006) ⇒ ثلاث نقاط فشل لسلامة قانونية واحدة.
- **Violated principle:** DRY، Single Source of Truth.
- **Current owner:** المستودع **و** الـ mapper **و** الـ Widget.
- **Correct owner:** `dvir/domain/usecases/reconcile_condition_status.dart` أو method على `DvirReport` في `dvir_report.dart`.
- **Consequences:** تعديل القاعدة في مكان واحد يجعل النسخة المرسلة/anتحقق المحلي يتباعدان.
- **Recommended correction:** إضافة method على `DvirReport` في domain؛ حذف التكرارين.
- **Related files:** `dvir_mappers.dart:135-141`, `dvir_form_page.dart:202-206`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-005b: تباين سلوكي بين `SQLiteOfflineQueue` و `MemoryOfflineQueue` في `releaseToPending`
- **Severity:** Medium
- **Category:** Contract Divergence / Test Fidelity
- **Location:** `lib/features/sync/data/repositories/sqlite_offline_queue.dart:370` مقابل `lib/features/sync/data/repositories/memory_offline_queue.dart:135-139`
- **Evidence:**
```dart
// sqlite_offline_queue.dart:362-372
      await txn.insert(
        _tableName,
        {
          'id': record.event.id,
          'type': record.event.type,
          'payload': jsonEncode(record.event.payload),
          'createdAt': record.event.createdAt.millisecondsSinceEpoch,
          'priority': record.event.priority.index,
          'retryCount': record.event.retryCount,
          'nextRetryAt': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
```
```dart
// memory_offline_queue.dart:135-139
  Future<void> releaseToPending(String eventId) async {
    final record = _parked.remove(eventId);
    if (record == null) return;
    await enqueue(record.event);
  }
```
- **Current behavior:** SQLite **يبطِل** `nextRetryAt` (إعادة محاولة فورية بعد الإفراج)؛ Memory **يحتفظ** بالقيمة الأصلية (تأخير حتى موعد backoff القديم).
- **Why problematic:** عقد واحد (`offline_queue.dart:46-48`)، تنفيذان بسلوكين مختلفين. الاختبارات المبنية على `MemoryOfflineQueue` **لا تختبر سلوك الإنتاج** في بند حسّاس (سياج الإفراج).
- **Violated principle:** Liskov Substitution، Test Fidelity.
- **Current owner:** تنفيذان مستقلان بلا عقد سلوكي موثّق.
- **Correct owner:** قاعدة صرفة مشتركة تُستدعى من الاثنين، مثل `PendingEvent rescheduledForImmediateRetry()`.
- **Consequences:** حدث مؤجَّل يُفرَج في الإنتاج يُرسل فوراً، وفي الاختبار ينتظر.
- **Recommended correction:** استخراج `PendingEvent immediateRetry()` في `sync/domain/entities/pending_event.dart` واستدعاؤها في الاثنين.
- **Related files:** `sync/domain/entities/pending_event.dart`, `sync/domain/repositories/offline_queue.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-011: نصوص مستخدم مثبتة في data/presentation خارج نظام l10n
- **Severity:** Medium
- **Category:** Hardcoded Presentation Values in Wrong Layer
- **Location:** `lib/features/tracking/data/repositories/tracking_repository_impl.dart:66-79`، `lib/features/dvir/presentation/widgets/dvir_form_sections.dart:165-171`، `lib/features/tracking/presentation/providers/tracking_provider.dart:136`
- **Evidence:**
```dart
// tracking_repository_impl.dart:65-69  (data layer)
      if (!locationStatus.isGranted) {
        return const Left(PermissionFailure(
          message: 'صلاحية الموقع في الخلفية مطلوبة',
        ));
      }
```
```dart
// dvir_form_sections.dart:164-171
          if (parsed == null || parsed.isNaN || parsed < 0) {
            return loc.localeName == 'ar'
                ? 'قيمة العداد غير صالحة'
                : (loc.localeName == 'es'
                    ? 'Lectura de odómetro no válida'
                    : 'Invalid odometer reading');
          }
```
```dart
// tracking_provider.dart:135-138
        state = state.copyWith(
          errorMessage: 'No GPS signal received from device',
          errorType: TrackingErrorType.technical,
        );
```
- **Current behavior:** ثلاث فئات: (1) **عربية داخل data layer** تصل للواجهة كما هي؛ (2) **ثلاثية اللغة مكتوبة يدوياً** في Widget بدل `.arb`؛ (3) **إنجليزية صريحة** في presentation providers.
- **Why problematic:** (أ) `failure.message` من data **يُعرض مباشرة** في `tracking_provider.dart:118` (`errorMessage: failure.message`) ⇒ **طبقة data تقرر نصاً مرئياً**. (ب) التفرع اللغوي اليدوي **ينمو** مع كل لغة جديدة (المشروع يدعم ar/en/es).
- **Violated principle:** i18n Centralization، Layer Separation.
- **Current owner:** data layer و Widget.
- **Correct owner:** `core/error/user_facing_message.dart` + `l10n/*.arb` بمفتاح بدل نص.
- **Consequences:** مستخدم غير عربي يرى نصاً عربياً على شاشة رفض الأذونات.
- **Recommended correction:** `PermissionFailure(l10nKey: 'tracking_permission_background_required')`؛ ويمرّر `tracking_provider` عبر `anyErrorUserMessage(failure, loc:)` كالموجود في `inspection_provider.dart:159-161`.
- **Related files:** `inspection_provider.dart:159-161`, `lib/core/error/user_facing_message.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-012: قيمة حرفية مشتركة ('No Vehicle' / 'None') تُستهلك في ثلاث طبقات
- **Severity:** Medium
- **Category:** Magic Value Across Layers
- **Location:** التعريف `lib/features/dvir/domain/dvir_vehicle.dart:3` → الاستهلاك `dvir_repository_impl.dart:47`، `dvir_mappers.dart:123`، `dvir_form_page.dart:531-535`
- **Evidence:**
```dart
// dvir_form_page.dart:531-535  (presentation layer)
      trailerId:
          (dashboard.trailerId == 'None' ||
              dashboard.trailerId?.trim().isEmpty == true)
          ? null
          : dashboard.trailerId,
```
- **Current behavior:** الـ **domain** يوفّر `noVehicleSentinel` و`isUnassignedVehicleId()` صراحةً لتفادي هذا النمط، لكن الـ Widget **لا يستخدم الدالة** ويطابق `'None'` حرفياً، بينما data يستخدم `'No Vehicle'`.
- **Why problematic:** (أ) الـ domain يوفّر واجهة صرفة بالضبط لتفادي هذا، والـ Widget يتجاهلها. (ب) حارس المُقطورة `'None'` معرَّف في **ثلاث أماكن** بلا مصدر واحد.
- **Violated principle:** DRY، Domain Model Adoption.
- **Current owner:** Widget + Repository + Mapper.
- **Correct owner:** `dvir/domain/dvir_vehicle.dart` — دالة `normalizeTrailerId(String?)` بجانب `isUnassignedVehicleId`.
- **Consequences:** تغيير نص Sentinel من لوحة القيادة يكسر DVIR بهدوء.
- **Recommended correction:** إضافة `String? normalizeTrailerId(String? raw)` في domain واستدعاؤها من الثلاثة.
- **Related files:** `dvir_repository_impl.dart:47`, `dvir_mappers.dart:122-123`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-016: بروتوكول نصي `OFFLINE_GENERATED:` بين data و presentation
- **Severity:** High
- **Category:** Layer Coupling via String Protocol
- **Location:** `lib/features/inspection/data/repositories/inspection_repository_impl.dart:169-172` → `lib/features/inspection/presentation/pages/send_logs_page.dart:267-268`
- **Evidence:**
```dart
// inspection_repository_impl.dart:169-172
        return Right(TransferOutcome(
          accepted: true,
          text: 'OFFLINE_GENERATED:$filePath',
        ));
```
```dart
// send_logs_page.dart:267-268
    final isOffline = message != null && message.startsWith('OFFLINE_GENERATED:');
    final localPath = isOffline ? message.substring('OFFLINE_GENERATED:'.length) : null;
```
- **Current behavior:** المستودع **يخزّن مسار ملف وسماً داخل حقل نص عرض**، والـ Widget **يفكّ الترميز** بـ `startsWith`/`substring` ثم يقرر UX (إظهار زر المشاركة).
- **Why problematic:** (أ) **Broken type smell مؤكَّد**: `TransferOutcome.text` مقصود للعرض وحُمِل عليه مسار آلة. (ب) الـ Widget يستنتج حالة النظام من نص. (ج) لا يمكن إضافة outcome ثالث دون تعديل المتصل. (د) مسار الملف ينتقل من data إلى Widget عبر نص.
- **Violated principle:** Information Hiding، Layer Separation، Primitive Obsession.
- **Current owner:** اتفاق ضمني صامت بين مستودع و Widget.
- **Correct owner:** كيان domain صريح، مثل `sealed class TransferOutcome { OnlineAccepted(text) | OfflineGenerated(filePath) | Rejected(reason) }`.
- **Consequences:** تغيير صيغة الوسم يكسر الشاشة بصمت؛ صفر تغطية اختبار على النوع.
- **Recommended correction:** تحويل `TransferOutcome` إلى sealed class في `inspection_transfer.dart`؛ يحذف تحليل النص من الـ Widget.
- **Related files:** `inspection/domain/inspection_transfer.dart:23-28`, `inspection/data/services/fmcsa_eld_output_generator.dart:14-24`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-018: `// ignore_architecture` على استيرادات تكسر عزل الميزات
- **Severity:** High
- **Category:** Cross-Feature Coupling (data → presentation)
- **Location:** `lib/features/sync/data/providers/sync_providers.dart:7-8`
- **Evidence:**
```dart
import '../../../auth/presentation/providers/auth_state_provider.dart'; // ignore_architecture
import '../../../logs/data/datasources/log_local_data_source.dart'; // ignore_architecture
```
- **Current behavior:** **طبقة data** في ميزة `sync` تستورد من **presentation** ميزة أخرى (`auth`) ومن **data** ميزة أخرى (`logs`).
- **Why problematic:** (أ) `data → presentation` انقلاب اتجاه صارم في Clean Architecture. (ب) `authStateProvider` مصدر حالة واجهة؛ ربط المزامنة به يربط دورة حياةها بعمر واجهة المصادقة. (ج) التعليق `// ignore_architecture` **يُخفي** الانحراف ولا يظهر في أي تقرير architecture.
- **Violated principle:** Dependency Rule (inward-only)، Feature Isolation.
- **Current owner:** `sync/data/providers`
- **Correct owner:** عقد في domain — `DispatchAuthContext` **موجود أصلاً** في `sync/domain/entities/dispatch_auth.dart:5`؛ يكفي تمرير closures من composition root، أو استخراج مزوّد الجلسة إلى `core/`.
- **Consequences:** لا يمكن اختبار `sync` بمفرده؛ تغيير auth presentation يكسر المزامنة بصمت.
- **Recommended correction:** نقل مزوّد الجلسة إلى `core/session/`، أو تمرير `observeAuth` من `app/orchestrators`.
- **Related files:** `sync/domain/entities/dispatch_auth.dart`, `sync/data/providers/sync_providers.dart:90-102`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-022: Data models ترث كيانات الـ domain
- **Severity:** Medium
- **Category:** Layer Design (Inheritance vs Composition)
- **Location:** `lib/features/tracking/data/models/location_model.dart:4` و `lib/features/sync/data/models/sync_item_model.dart:4`
- **Evidence:**
```dart
// location_model.dart:4
class LocationModel extends LocationEntity {
```
```dart
// sync_item_model.dart:4
class SyncItemModel extends SyncItem {
```
- **Current behavior:** النموذجان في طبقة data **يمتدان** من كيان الـ domain مباشرة، مع إضافة `fromJson`/`toJson` عليهما.
- **Why problematic:** (أ) **الوراثة** تجعل النموذج is-a الكيان؛ أي حقل جديد في الـ domain يفرض تغيّراً في data. (ب) دوال الحفظ (`fromJson`) تصبح جزءاً من الكيان. (ج) استحالة تغيير تمثيل الكيان دون كسر طبقة data.
- **Violated principle:** Composition over Inheritance، Model Independence.
- **Current owner:** `data/models/*`
- **Correct owner:** نموذج مستقل + `toEntity()`.
- **Consequences:** تسرّب منطق التخزين إلى كيان العمل.
- **Recommended correction:** `class LocationModel { ... LocationEntity toEntity() => ...; }`.
- **Related files:** `tracking/domain/entities/location_entity.dart`, `sync/domain/entities/sync_item.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-030: `core` يستورد من `features/*/data` (انقلاب اتجاه)
- **Severity:** High
- **Category:** Layer Direction Inversion
- **Location:** `lib/core/events/eld_events_provider.dart:3`
- **Evidence:**
```dart
import '../../features/tracking/data/datasources/live_tracking_data_source.dart';
import '../domain/entities/hos_models.dart';
import '../../features/tracking/domain/entities/connection_status.dart';

/// Domain-level provider exposing the live ELD events stream.
///
/// This decouples the HOS/Sync/Logs domains from directly importing
/// the tracking data source.
final eldEventsStreamProvider = StreamProvider<EldEvent>((ref) {
  return ref.watch(liveTrackingDataSourceProvider).events;
});
```
- **Current behavior:** حزمة `core` (النواة المشتركة) تستورد **طبقة data** لميزة `tracking` ثم تعيد تصدير `StreamProvider` منها.
- **Why problematic:** (أ) **انقلاب اتجاه صارم**: `core` أدنى الهرم ويُفترض أن يقدّم على الميزات لا أن يعتمد عليها. (ب) كل مستهلك لـ `eldEventsStreamProvider` (HOS، sync) **يحبس** كاملَ حزمة `tracking/data` في رسمه البياني. (ج) الملف يصف نفسه بـ«Domain-level provider» (سطر 7) وهو **ليس كذلك**.
- **Violated principle:** Dependency Rule، Layer Direction.
- **Current owner:** `core/events/eld_events_provider.dart`
- **Correct owner:** `tracking/presentation/providers/` أو `app/orchestrators/`؛ أو domain port مع implementation في data.
- **Consequences:** لا يمكن حذف feature tracking دون كسر `core`؛ خطر تصادم أسماء providers.
- **Recommended correction:** نقل الملف إلى `tracking/presentation/providers/`؛ composition في `app/orchestrators/tracking_orchestrator.dart`.
- **Related files:** `sync/data/providers/sync_providers.dart:12,127`, `app/app_initializer.dart:116`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-031: قواعد جودة موقع في طبقة datasource
- **Severity:** Medium
- **Category:** Business Rule in Data Layer
- **Location:** `lib/features/tracking/data/datasources/native_event_channel_client.dart:15-55`
- **Evidence:**
```dart
  NativeLocationEvent validate(
      NativeLocationEvent event, DateTime? lastRecordedAt) {
    // Basic coordinate bounds
    if (event.latitude < -90 ||
        event.latitude > 90 ||
        event.longitude < -180 ||
        event.longitude > 180) {
      return event.copyWith(qualityStatus: LocationQualityStatus.invalid);
    }
    ...
    // Time validation
    final now = _nowUtc();
    final timeDiff = event.recordedAt.difference(now).inMinutes;
    if (timeDiff > 5) {
      // Future timestamp (suspicious)
      return event.copyWith(qualityStatus: LocationQualityStatus.suspicious);
    }

    if (now.difference(event.recordedAt).inMinutes > 60) {
      // Very old (stale)
      return event.copyWith(qualityStatus: LocationQualityStatus.stale);
    }

    // Ordering validation
    if (lastRecordedAt != null && event.recordedAt.isBefore(lastRecordedAt)) {
      return event.copyWith(qualityStatus: LocationQualityStatus.outOfOrder);
    }
```
- **Current behavior:** **ست قواعد جودة** (حدود، NaN/Infinity، سالب، future > 5 د، stale > 60 د، ترتيب) مُنفَّذة داخل `datasources/`.
- **Why problematic:** (أ) العتبات **5 و 60 دقيقة قيم أعمال** (سلامة سجل ELD) لا دوال لغة. (ب) **غير قابلة للاختبار** دون EventChannel (لولا حقن `nowUtc` لكانت مرتبطة بساعة الجهاز). (ج) `LocationQualityStatus` و`LocationSource` **enums في domain** لكن منطق استخدامها في data.
- **Violated principle:** Domain Model، Layer Placement، Testability.
- **Current owner:** `NativeLocationQualityValidator` (data)
- **Correct owner:** `tracking/domain/services/location_quality_policy.dart` مع `const` للعتبات؛ data تحقّق منها فقط.
- **Consequences:** تغيير عتبة الـ stale لا يمكن التحقق منه؛ قاعدة غير مسجّلة في SRS.
- **Recommended correction:** نقل `validate()` إلى domain كدالة pure؛ إبقاء الـ data parser ناقلاً فقط.
- **Related files:** `tracking/domain/entities/native_location_event.dart:3-5`, `tracking/data/providers/tracking_providers.dart:32-34`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-032: الـ port ناقص التغطية ⇒ يُتجاوز عبر `TrackingService` (ازدواج مسارَي التتبع)
- **Severity:** High
- **Category:** Ports & Adapters (Dependency Inversion)
- **Location:** `lib/features/tracking/domain/repositories/tracking_data_source_port.dart:1-8`
- **Evidence:**
```dart
// tracking_data_source_port.dart — كامل الملف
import 'dart:async';
import '../entities/tracking_event.dart';
import '../entities/connection_status.dart';

abstract class TrackingDataSourcePort {
  Stream<TrackingEvent> get events;
  Stream<ConnectionStatus> get connectionStatusStream;
}
```
```dart
// tracking_data_source.dart:9-25  (data)
abstract class TrackingDataSource implements TrackingDataSourcePort {
  @override
  Stream<TrackingEvent> get events;

  @override
  Stream<ConnectionStatus> get connectionStatusStream;

  Future<void> start();

  Future<void> stop();

  Future<TrackingEvent?> getLastEvent();
}
```
- **Current behavior — إجابة فحص الـ port:** الـ port **حقيقي فعلاً** وموضعه صحيح: مُعرَّف في domain، نقي (لا Flutter/Dio/Riverpod)، وله **منفّذ** (`TraccarDataSource`) و**مستهلك** (`TrackingEventProcessor`). **لكنه ناقص**: يعرض التدفقين فقط، فلا يشمل `start/stop` ولا الإذن. لذلك `TrackingRepository` (domain) الذي يملك `startTracking/stopTracking` **لا يستطيع** الاعتماد عليه، فيلجأ `TrackingRepositoryImpl` إلى `TrackingService` (data/services) مباشرة (`tracking_repository_impl.dart:16`).
- **Why problematic — ازدواج المسارات:**
  - **المسار (أ):** `liveTrackingDataSourceProvider` → `TraccarDataSource` + `NativeEventChannelClient` → `TrackingEventProcessor` → `eldEventsStreamProvider` (يستهلكه HOS و sync).
  - **المسار (ب):** `trackingRepositoryProvider` → `TrackingRepositoryImpl` → `TrackingService` → `TraccarNativeClientImpl` + `NativeEventChannelClient` → `trackingStateProvider` (يستهلكه UI و orchestrator).
  كلاهما ينشئ **`TraccarNativeClientImpl` مستقلاً**: `live_tracking_data_source.dart:143` و `app_initializer.dart:67` ⇒ `configure()` و`startBackgroundTracking()` تُنفَّذان على method-channel clients مختلفة ⇒ **حالة native غير متسقة**.
- **Violated principle:** Dependency Inversion، Interface Segregation، Single Source of Truth.
- **Current owner:** port ناقص + `TrackingService` متجاوزَه.
- **Correct owner:** توسيع `TrackingDataSourcePort` بـ `start/stop/getLastEvent`؛ وحذف `TrackingService` كوسيط — `TrackingRepositoryImpl` يعتمد على Port لا على صنف تحكم.
- **Consequences:** مصدران للحقيقة للبيانات؛ خطر تهيئة مزدوجة لـ native.
- **Recommended correction:** (1) توسيع الـ port؛ (2) `TrackingRepositoryImpl` → `TrackingDataSourcePort`؛ (3) `TrackingService` يصبح adapter للـ port أو يختفي؛ (4) توحيد `liveTrackingDataSourceProvider` مع `trackingRepositoryProvider`.
- **Related files:** `tracking/data/repositories/tracking_repository_impl.dart:12,16`, `tracking/data/services/tracking_service.dart:10-20`, `tracking/presentation/providers/tracking_provider.dart:61`, `live_tracking_data_source.dart:143`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-038: تدفّق الصلاحيات (مع حوارات النظام) داخل مستودع data
- **Severity:** High
- **Category:** UI/Platform Policy in Data Layer
- **Location:** `lib/features/tracking/data/repositories/tracking_repository_impl.dart:50-80`
- **Evidence:**
```dart
      // ١. فحص صلاحية الموقع دائماً (الخلفية) - مطلوبة لعمل Traccar
      var locationStatus = await Permission.locationAlways.status;

      if (!locationStatus.isGranted) {
        // في أندرويد 10+ يجب طلب الصلاحية العادية أولاً ثم الخلفية
        var inUseStatus = await Permission.locationWhenInUse.status;
        if (!inUseStatus.isGranted) {
          inUseStatus = await Permission.locationWhenInUse.request();
        }

        if (inUseStatus.isGranted) {
          locationStatus = await Permission.locationAlways.request();
        }
      }

      if (!locationStatus.isGranted) {
        return const Left(PermissionFailure(
          message: 'صلاحية الموقع في الخلفية مطلوبة',
        ));
      }
```
- **Current behavior:** المستودع ينفّذ **حوارَي أذونات متدرّجين** عبر `permission_handler`، بما في ذلك استدعاء `.request()` الذي **يفتح واجهة نظام**.
- **Why problematic:** (أ) **طبقة data تُطلق UI** ⇒ `TrackingRepository` غير قابل للاختبار ويخالف الـ layering. (ب) **تناقض صريح مع تعليق المشروع**: `tracking_provider.dart:89-92` يقول «Battery-optimisation exemption is requested on the Permissions page (permission_handler); **no second dialog path lives here**» — لكن **المسار الثاني موجود هنا بالتحديد**. (ج) بحث شامل أثبت أن `permission_handler` يظهر في **ثلاثة** مواقع: `tracking_repository_impl.dart:3`، `lib/features/permissions/presentation/pages/permissions_page.dart:4`، `lib/features/auth/presentation/pages/splash_page.dart:9` ⇒ **ثلاثة مسارات أذونات**.
- **Violated principle:** Layer Separation، UI Concerns in Data.
- **Current owner:** `TrackingRepositoryImpl.startTracking()`
- **Correct owner:** `permissions/presentation` للحوار؛ ثم `startTracking()` يفحص الحالة فقط.
- **Consequences:** حوار مزدوج؛ و`Geolocator.isLocationServiceEnabled().catchError(...)` (سطر 73-75) يغلّف نتيجة خدمة الموقع في `Exception('Error updating position: $error')` — **رسالة خاطئة** تماماً.
- **Recommended correction:** استخراج `PermissionCoordinator` في presentation؛ تمرير `bool permissionAlreadyGranted` إلى `startTracking()`.
- **Related files:** `lib/features/permissions/presentation/pages/permissions_page.dart:4`, `lib/features/auth/presentation/pages/splash_page.dart:9`, `tracking/presentation/providers/tracking_provider.dart:89-92`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-039: مصدران للموقع + مسار غير مُتحقَّق منه الجودة
- **Severity:** Medium
- **Category:** Layer Responsibility / Redundant Fallback
- **Location:** `lib/features/tracking/data/repositories/tracking_repository_impl.dart:2` و `:130-142`
- **Evidence:**
```dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
```
```dart
      // Fallback to Geolocator
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final fallbackLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        altitude: position.altitude,
        bearing: position.heading,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
      await _localDataSource.saveLastLocation(fallbackLocation);
      return Right(fallbackLocation);
```
- **Current behavior:** `getCurrentLocation` و`requestPosition` (كلاهما) إذا لم يوجد `lastLocation` محفوظ، **يستدعيان `Geolocator.getCurrentPosition`** — أي **مصدر GPS ثانٍ** بجانب native Traccar.
- **Why problematic:** (أ) **مصدران للموقع** لا يُنسَّق بينهما: بيانات native (عبر `locationStream`) وGeolocator (مستقل) ⇒ **تعارض في سجل ELD**. (ب) **رقابة جودة غير متسقة**: المسار الأصلي يمر بـ `NativeLocationQualityValidator` (رقابة صارمة)، بينما مسار Geolocator **لا يمر بأي رقابة** ⇒ **موقع غير مُتحقَّق منه يدخل سجل ELD**. (ج) استهلاك إضافي للبattery خارج ما طلبه UI.
- **Violated principle:** SRP، Single Data Source، Consistency.
- **Current owner:** `TrackingRepositoryImpl`
- **Correct owner:** مصدر واحد (`NativeEventChannelClient`) خلف port.
- **Consequences:** موقع سيّئ الجودة يُسجَّل بلا تحقّق؛ بطارية تُستهلك دون داعٍ.
- **Recommended correction:** حذف الـ fallback، أو تغليفه بـ port منفصل في data يمر بنفس `LocationQualityValidator`.
- **Related files:** `tracking/data/datasources/native_event_channel_client.dart:15-55`, `tracking/presentation/providers/tracking_providers.dart:2` (geolocator في presentation أيضاً)
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-042: تحويل وحدة مثبت داخل domain usecase
- **Severity:** Low
- **Category:** Hardcoded Value (Business) / Layer Placement
- **Location:** `lib/features/tracking/domain/usecases/tracking_event_processor.dart:100`
- **Evidence:**
```dart
    return EldEvent(
      timestamp: event.timestampUtc,
      speedMph: event.speed * 2.23694,
```
- **Current behavior:** تحويل m/s → mph بمعامل مثبت داخل domain usecase.
- **Why problematic:** (أ) **قيمة فيزيائية أعمال** بلا مرجع ولا اختبار. (ب) استخدمها `FmcsaEldOutputGenerator` أيضاً بمعامل **مختلف** (`0.621371` km→mi). (ج) لو تغيّرت وحدة `LocationEntity` (مثلاً إلى km/h) لن تتغير.
- **Violated principle:** Business Constants Placement، DRY.
- **Current owner:** `TrackingEventProcessor._mapToEldEvent`
- **Correct owner:** `core/constants/` أو دالةUnits في domain مع اختبار.
- **Consequences:** انحراف صامت بين المسارات.
- **Recommended correction:** `Units.metersPerSecondToMilesPerHour(value)` في `core/constants/fmcsa_constants.dart`.
- **Related files:** `lib/features/inspection/data/services/fmcsa_eld_output_generator.dart:118,144`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-044: قراءة JSON وربط HTTP داخل domain في `vehicle_selection.dart`
- **Severity:** Medium
- **Category:** Layer Responsibility (Domain doing Data work)
- **Location:** `lib/features/vehicle/domain/vehicle_selection.dart:52-96` و `:99-119`
- **Evidence:**
```dart
/// A missing list is an error. An empty list is an empty success.
/// A row without `uniqueId` or `vehicleId` is not given an invented id.
List<Vehicle>? parseVehicleList(dynamic data) {
  final raw = _vehicleRows(data);
  if (raw == null) return null;
  final vehicles = <Vehicle>[];
  for (final item in raw) {
    final row = _asMap(item);
    if (row == null) return null;
    final vehicle = readVehicle(row);
    if (vehicle == null) return null;
    vehicles.add(vehicle);
  }
  return vehicles;
}

Vehicle? readVehicle(Map<String, dynamic> json) {
  final uniqueId = _text(json['uniqueId']);
  final vehicleId = _text(json['vehicleId'] ?? json['id']);
  final id = uniqueId ?? vehicleId;
  if (id == null) return null;
```
```dart
// vehicle_selection.dart:98-119
/// Prefer the server sentence. Otherwise name the HTTP result, do not invent a policy.
String vehicleOperateFailure({
  required String code,
  String? serverMessage,
  int? statusCode,
}) {
  final message = serverMessage?.trim();
  if (message != null && message.isNotEmpty) return message;
  switch (statusCode) {
    case 400:
      return 'rejected';
    case 403:
      return 'unauthorized';
```
- **Current behavior:** الملف يحتوي **ثلاثة أنواع مختلفة** من المسؤوليات: قواعد اختيار أعمال صرفة + **قراءة جسم خادم (JSON parsing)** + **خريطة رموز حالة HTTP**.
- **Why problematic:** (أ) **إجابة فحص المطلوب:** الموضع **ليس خطأً طبقياً صارماً** (لا استيراد Flutter/Dio/Riverpod — تحقّقت)، لكنه **مسؤولية مختلطة**: قراءة JSON ووصل HTTP من مسؤوليات  data داخل `domain/`. (ب) `readVehicle` يقرأ `'uniqueId'` و`'vehicleId'` و`'myVehicle'` و`'inUseByOtherDriver'` — أسماء حقول خادم wire داخل domain. (ج) `vehicleOperateFailure` خريطة HTTP، ويستهلكها `vehicle_repository_impl.dart:72-80`.
- **Violated principle:** SRP، Layer Cohesion.
- **Current owner:** `vehicle/domain/vehicle_selection.dart`
- **Correct owner:** `vehicle/data/mappers/vehicle_mappers.dart` لـ JSON + HTTP mapping؛ وتبقى القواعد الصرفة في domain.
- **Consequences:** تغيير اسم حقل في API يمسّ domain؛ لا يمكن تبديل strategy قراءة بلا تعديل domain.
- **Recommended correction:** فصل الملف إلى (1) `vehicle_selection_rules.dart` (domain: `listedVehicleIsOperable`, `refuseVehicleOperate`, `readOperableUniqueId`)، (2) `vehicle/data/mappers/vehicle_mappers.dart` (JSON)، (3) خريطة HTTP في `vehicle_repository_impl`.
- **Related files:** `vehicle/data/repositories/vehicle_repository_impl.dart:35-56, 72-80`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-01: `DutyStatusTracker` في مجلد domain يتصل بمستودع ميزة أخرى
- **Severity:** Critical
- **Category:** Domain Purity / Cross-Feature Coupling
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:4` و `:284`
- **Evidence:**
```dart
 4: import '../../../../logs/domain/repositories/log_repository.dart';
...
284:      _logRepository.savePeriod(period).then((result) {
285:        result.match(
286:          (failure) =>
287:              AppLogger.error('Failed to save period', failure.message),
288:          (success) => AppLogger.info('Period saved successfully'),
289:        );
290:      });
```
- **Current behavior:** صنف داخل `features/hos/domain/` يحتفظ بمرجع إلى `LogRepository` (عقد feature `logs`) وينفّذ عملية كتابة غير متزامنة عليه.
- **Why problematic:** (1) `features/hos` لا يستطيع أن يُختبر أو يُستبدل دون `features/logs`. (2) كيان `DutyPeriod` المستخدم هنا معرَّف في `core/domain/entities/hos_models.dart` أي أنه **مشترك**؛ فالمستودع الصحيح هو مستودع HOS نفسه لا مستودع السجلات. (3) الملف يسمي نفسه «domain pure» في `line 7` والتعليق كاذب معمارياً.
- **Violated principle:** Dependency Inversion + Feature Isolation + توثيق صادق.
- **Current owner:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart`
- **Correct owner:** عقد `DutyPeriodRepository` في `lib/features/hos/domain/repositories/`.
- **Consequences:** أي حذف/تغيير في feature `logs` يكسر HOS؛ دوائر HOS تتطلب تهيئة Hive لسجلات logs؛ أي تغيّر في تخطيط تخزين logs يتسلل إلى HOS.
- **Recommended correction:** استخراج واجهة `abstract class DutyPeriodRepository { Future<void> savePeriod(DutyPeriod p); }` في `hos/domain/repositories/`، حقنها في `DutyStatusTracker`، وتنفيذها في `hos/data/repositories/` على نفس Hive box دون ربط.
- **Related files:** `lib/features/logs/domain/repositories/log_repository.dart:85`, `lib/features/hos/presentation/providers/hos_engine_provider.dart:43`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-05: تحويل الوحدات (ميل→كم) داخل domain
- **Severity:** Medium
- **Category:** Layer Responsibility
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:227`
- **Evidence:**
```dart
227:        if (odometer != null) 'odometerKm': odometer * 1.609344,
```
- **Current behavior:** domain يحوّل من الميل إلى الكيلومتر أثناء بناء حمولة `PendingEvent`.
- **Why problematic:** (1) هذا اشتقاق **سلكي** (wire) داخل domain. (2) التحويل **معكوس** في data: `log_model.dart:59: odometer = km * _kmToMiles;` — إذن الطبقتان تعملان بوحدتين مختلفتين وتحوّلان في اتجاهين متعاكسين. ثلاث تحويلات في ثلاث طبقات لنفس الحقل.
- **Violated principle:** Single Unit of Measure + Separation.
- **Current owner:** `duty_status_tracker.dart:227`
- **Correct owner:** الـ mapper في `data/` (تحويل `DutyPeriod`/`PendingEvent` إلى DTO سلكي).
- **Consequences:** احتمال خطأ عند التصحيح؛ صعب تتبع أي طبقة تملك القيمة الحقيقية.
- **Recommended correction:** اجعل `DutyPeriod` يحمل `odometerKm` بوحدته، وضع التحويل كله في mapper واحد في data.
- **Related files:** `lib/features/logs/data/models/log_model.dart:55-62`, `lib/core/domain/entities/hos_models.dart` (`odometerMiles`)
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-06: `DutyStatusTracker` يبني حمولة شبكة ويخمّن «هل الخطأ شبكي؟» بنص الخطأ
- **Severity:** High
- **Category:** Layer Responsibility / Fragile Error Handling
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:218-230` و `:370-374`
- **Evidence:**
```dart
218:      payload: {
219:        'status': wireStatus,
220:        'startTime': stamp.toIso8601String(),
221:        if (_readDriverId?.call() != null) 'driverId': _readDriverId!.call(),
...
370:      final isNetwork = error.code.contains('network') ||
371:          error.code.contains('connection') ||
372:          error.code.contains('timeout') ||
373:          error.code.contains('offline') ||
374:          error.context?['statusCode'] == null;
```
- **Current behavior:** domain (أ) يبني خريطة JSON كاملة لـ `PendingEvent`، (ب) يقرأ `error.code` و`error.context` كـ `Map` غير مُنمّط لتقرير نوع الخطأ.
- **Why problematic:** (1) أسماء الحقول السلكية (`locationText`, `notes`, `driverId`, `odometerKm`) متشعبة بين domain و`log_repository_impl.dart:171-176` — نفس العقد مكتوب يدوياً في مكانين. (2) `error.context?['statusCode'] == null` مقارنة على `Map` غير مُنمّط — **مقارنة `== null` تُعامَل كـ «خطأ شبكي»**، أي أن **أي خطأ خادمي بلا statusCode يُختبر محلياً رغم أنه قد يكون رفض تحقق**. (3) منطق I/O داخل domain.
- **Violated principle:** Layered Architecture + Typed Errors.
- **Current owner:** الملف نفسه.
- **Correct owner:** mapper في data + `Failure` مُنمّط في `core/error/`.
- **Consequences:** خطأ تحقق 400 بلا `statusCode` قد يُقبل محلياً — مخالفة FMCSR محتملة.
- **Recommended correction:** استخدم `NetworkFailure`/`ServerFailure` المُنمّطة بدل فحص النص؛ انقل بناء الـ payload إلى `data/datasources/`.
- **Related files:** `lib/features/logs/data/repositories/log_repository_impl.dart:170-177`, `lib/features/sync/domain/entities/pending_event.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-09: `HosRulesEngine` يُرجع `ServerFailure` من طبقة domain
- **Severity:** Medium
- **Category:** Layer Responsibility / Domain Vocabulary
- **Location:** `lib/features/hos/domain/engine/hos_rules_engine.dart:85-87`
- **Evidence:**
```dart
85:      return Left(ServerFailure(
86:          message:
87:              'Cannot manually change from DRIVING while vehicle is moving ($currentSpeedKmh km/h)'));
```
- **Current behavior:** محرك يرفض انتقالاً قانونياً بمخالفة **نقل** (`ServerFailure`) ويضع نصاً إنجليزياً فيه.
- **Why problematic:** `ServerFailure` تعني «رفض الخادم» — لا علاقة لها بقاعدة «لا تبدّل أثناء الحركة». المستهلك (`hos_provider.dart:104`) يسجّل `validationResult.fold((f) => f.message, …)` فينتج سجلاً يحوي سرعة حيّة متغيرة — قيمة غير ثابتة في سجل أخطاء.
- **Violated principle:** Ubiquitous Language + Layered error model.
- **Current owner:** engine.
- **Correct owner:** نوع خطأ مجال (`TransitionRefusal`) يُترجم في presentation.
- **Consequences:** سجلات تحوي أرقاماً متغيرة؛ التمييز بين رفض المجال ورفض الخادم مستحيل.
- **Recommended correction:** أعد `Either<Failure, void>` مع `DutyTransitionViolation` وعرفها في domain، واعرضها عبر `dutyChangeMessage()` الموجودة أصلاً في `presentation/duty_change_message.dart`.
- **Related files:** `lib/features/hos/presentation/providers/hos_provider.dart:103-106`, `lib/core/error/failure.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-13: استيراد widgets/providers من ميزات أخرى داخل presentation
- **Severity:** High
- **Category:** Cross-Feature Coupling (presentation)
- **Location:** 3 حواف استيراد widget مباشرة (مع 7 حواف كتابة مغطّاة في HL-25) — التفصيل في الجدول D.
- **Evidence (أهم ثلاث حِفات):**
```dart
// lib/features/logs/presentation/pages/inspection_preview_page.dart:16
import '../../../inspection/presentation/widgets/inspection_log_header_table.dart';
```
```dart
// lib/features/logs/presentation/pages/logs_list_page.dart:11
import '../../../home/presentation/widgets/eld_drawer.dart';
```
```dart
// lib/features/hos/presentation/widgets/driving_lock_screen.dart:7
import '../../../home/presentation/pages/home_page.dart';
```
(`driving_lock_screen.dart:29` يستهلك فعلياً `developerBypassDrivingScreenProvider`.)
- **Current behavior:** presentation في `logs` يستورد widget من `inspection` وwidget من `home`؛ presentation في `hos` يستورد صفحة `home` كاملة.
- **Why problematic:** استيراد **widget** من feature أخرى يعني أن سمات الشاشة البصرية وnotifier الخاص بها مربوطان. استيراد `home_page.dart` كاملة لإحضار provider واحد smell صريح (استيراد صفحة كاملة لأجل رمز واحد).
- **Violated principle:** Feature Isolation + Dependency Inversion.
- **Current owner:** الملفات المستورِدة.
- **Correct owner:** `core/widgets/` (`EldDrawer`); provider التجاوز إلى `core/providers/` أو يُحذف.
- **Consequences:** تغيير `home_page.dart` يكسر شاشة HOS؛ `inspection` لا يمكن حذفه دون كسر `logs`.
- **Recommended correction:** انقل `EldDrawer` إلى `core/widgets/`؛ انقل `developerBypassDrivingScreenProvider` إلى `core/providers/`؛ مرّر `inspection_log_header_table` كـ callback/builder.
- **Related files:** `lib/routes.dart:17-42`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-18: تحليل استجابات JSON داخل domain
- **Severity:** Medium
- **Category:** Layer Responsibility
- **Location:** `lib/features/logs/domain/saved_form_status.dart:10-26`؛ `lib/features/logs/domain/entities/audit_entry.dart:44-84`
- **Evidence:**
```dart
// saved_form_status.dart:10-14
SavedFormRead readSavedForm(Map<String, dynamic> json) {
  final body = json['data'] is Map
      ? Map<String, dynamic>.from(json['data'] as Map)
      : json;
  final raw = body['formStatus']?.toString().trim();
  final message = body['message']?.toString().trim();
```
```dart
// audit_entry.dart:44-48
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // ISO string: _saveToBox يستخرج مفتاح اليوم من نص ISO.
      'timestamp': timestamp.toIso8601String(),
```
- **Current behavior:** domain يقرأ `json['data']`, `json['formStatus']`, `json['message']`، ويفحص `'COMPLETED'/'COMPLETE'/'INCOMPLETE'/'IN_PROGRESS'`؛ الكيان ينتج خريطة تخزين.
- **Why problematic:** (1) `'data'` غلاف HTTP — مكانه `log_repository_impl.dart` الذي ينفّذ `readSavedForm(json)` في `line 359`. (2) `AuditEntry.toMap()` يخص **Hive**؛ التعليق في `line 47` «_saveToBox يستخرج مفتاح اليوم من نص ISO» يربط الكيان بمصدر بيانات محدد.
- **Violated principle:** Domain knows nothing about persistence/transport.
- **Current owner:** domain.
- **Correct owner:** `logs/data/models/` (mapper).
- **Consequences:** تغيير أي حقل في domain يمسّ طبقة النقل.
- **Recommended correction:** انقل `readSavedForm` إلى `data/models/saved_form_mapper.dart`، واحذف `toMap`/`fromMap` من `AuditEntry` إلى `data/models/audit_entry_mapper.dart`.
- **Related files:** `lib/features/logs/data/repositories/log_repository_impl.dart:359`, `lib/features/logs/data/datasources/log_local_data_source.dart:288`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-21: طبقة العرض تتجاوز use-case layer وتتصل بالمستودع أو بالـ backend مباشرة
- **Severity:** High
- **Category:** Layer Bypass
- **Location:** 6 مواقع
| # | الملف:السطر | ما يتجاوزه |
|---|---|---|
| 1 | `logs/presentation/controllers/edit_log_controller.dart:107` | `ref.read(logRepositoryProvider).logAudit(...)` |
| 2 | `logs/presentation/controllers/form_tab_controller.dart:31` | `_ref.read(logRepositoryProvider).saveForm(...)` |
| 3 | `logs/presentation/providers/audit_trail_provider.dart:7-8` | `repo.getRecentAuditEntries(limit: 100)` |
| 4 | `logs/presentation/providers/logs_provider.dart:92` | `_repository` محقن مباشرة |
| 5 | `logs/presentation/providers/unidentified_events_provider.dart:97,103,136,151` | **`ref.read(unidentifiedEventsBackendProvider)` — تجاوز مستودعين** |
| 6 | `logs/presentation/providers/certify_log_provider.dart:90` | `_repository` محقن مباشرة |
- **Evidence:**
```dart
// unidentified_events_provider.dart:97, 136-140
    final backend = ref.read(unidentifiedEventsBackendProvider);
...
    final result = await ref.read(unidentifiedEventsBackendProvider).claim(
          id: DutyStatusId(id),
          driverId: DriverId(driverId),
          annotation: annotation.trim(),
        );
```
- **Current behavior:** الحالة رقم 5 هي الأخطر: presentation يتصل بـ **backend** مباشرة، متجاوزاً data وapplication معاً، ومتسلّاً إلى `lib/backend/contracts/contract_enums.dart`.
- **Why problematic:** (1) `unidentified_events_provider.dart:3` يستورد عقد شبكة داخل presentation. (2) دوالا `parseUnidentifiedList` (`:13`) و`normalizeUnidentifiedItem` (`:19`) **عامتان على مستوى الملف** داخل presentation وتعرفان شكل استجابة HTTP (`json['items'] ?? json['events'] ?? json['content'] ?? json['data']`). (3) لا يمكن اختبار claim/reject دون mock backend.
- **Violated principle:** Dependency Rule (presentation → application → data).
- **Current owner:** الملفات المخالفة.
- **Correct owner:** `logs/domain/repositories/` + mapper في `logs/data/` + use-case في `logs/application/`.
- **Consequences:** كسر بنية data كاملة لهذا المسار؛ اختبارات تلتصق بالشبكة.
- **Recommended correction:** أنشئ `UnidentifiedEventsRepository` في domain، `UnidentifiedEventsDto` في data، واجعل الـ notifier يستهلك use-case. انقل دوال parsing إلى `data/models/`.
- **Related files:** `lib/features/hos/presentation/providers/recap_provider.dart:10-12` (النمط الصحيح المجاور)
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-23: قواعد التحقق في domain تُستدعى مباشرة من مدقّقات widgets
- **Severity:** Medium
- **Category:** Layer Bypass
- **Location:** 5 مواقع
| # | الملف:السطر | الدالة المستدعاة |
|---|---|---|
| 1 | `logs/presentation/pages/edit_log_page.dart:250` | `isFreeTextValid(v)` |
| 2 | `logs/presentation/pages/edit_log_page.dart:279` | `isFreeTextValid(v)` |
| 3 | `logs/presentation/pages/edit_log_page.dart:42` | `parseEditFormTime(...)` |
| 4 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart:142,166` | `trailerNumberError` / `shippingDocumentError` |
| 5 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart:353,360` | نفس الدالتين داخل `_dailyFormPayload` |
- **Evidence:**
```dart
// edit_log_page.dart:247-251
              validator: (value) {
                final v = (value ?? '').trim();
                if (v.isEmpty) return null;
                return isFreeTextValid(v) ? null : context.loc.invalidValue;
              },
```
- **Current behavior:** الـ widget يستدعي دوال domain ويُمرّر `context.loc` إليها (وهي تحتجاه Flutter بسبب HL-17).
- **Why problematic:** (1) مسار التحقق **مُSplit**: مرة في `validator` (عرض فوري) ومرة في `_dailyFormPayload` (عند الحفظ) — نتيجتان قد تختلفتان. (2) `_dailyFormPayload` (`line 335-383`, 48 سطراً) هو **use-case كامل** مكتوب كدالة top-level في ملف widget. (3) الربط بـ `context.loc` يجعل غير-UI مرتبطاً بـ UI.
- **Violated principle:** Presentation should consume prepared state, not re-derive.
- **Current owner:** widgets.
- **Correct owner:** `logs/application/` — `FormTabViewModel` يحمل `validationResult` جاهزاً.
- **Consequences:** ازدواج التحقق؛ اختلاف ما يُعرض عمّا يُحفظ.
- **Recommended correction:** اجعل `_dailyFormPayload` use-case في `application/`، واجعل `validator` يستهلك `vm.validationErrors[field]` بدل الاستدعاء.
- **Related files:** `lib/features/logs/domain/daily_form_rules.dart:62-92`, `lib/features/logs/presentation/controllers/form_tab_controller.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-25: كتابة عابرة للميزات: `logs` presentation يكتب في `home` presentation
- **Severity:** High
- **Category:** Cross-Feature Coupling (bidirectional write)
- **Location:** 7 مواقع
| # | الملف:السطر | الكتابة |
|---|---|---|
| 1 | `logs/presentation/providers/logs_provider.dart:162` | `dashboardDataProvider.notifier.applyServerForm(...)` |
| 2 | `logs/presentation/providers/logs_provider.dart:192` | نفس الاستدعاء |
| 3 | `logs/presentation/providers/logs_provider.dart:214` | نفس الاستدعاء |
| 4 | `logs/presentation/controllers/form_tab_controller.dart:50` | `logsProvider.notifier.updateLog(...)` |
| 5 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart:130` | `dashboardDataProvider.notifier.updateVehicle(vehicle)` |
| 6 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart:215` | `dashboardDataProvider.notifier.updateCoDriver(coDriver)` |
| 7 | `logs/presentation/pages/edit_log_page.dart:182-184` | `dashboardDataProvider.notifier.updateVehicle(picked)` |
- **Evidence:**
```dart
// logs_provider.dart:161-170
    if (log.trailers.isNotEmpty || log.shippingDocuments.isNotEmpty || (log.vehicleName != null && log.vehicleName!.isNotEmpty)) {
      _ref?.read(dashboardDataProvider.notifier).applyServerForm(
        DailyFormData(
          vehicleUniqueId: log.uniqueId.isNotEmpty ? log.uniqueId : null,
...
```
- **Current behavior:** `logs`Presentation **يكتب حالة** في `home`Presentation.-story feature واحدة تملك مصدر بيانات النموذج، بثلاث مسارات قراءة مختلفة (`form_tab.dart:46-85`).
- **Why problematic:** (1) `logs` و`home` مترابطان في الاتجاهين. (2) `_ref` من نوع `Ref?` اختياري (`logs_provider.dart:94`) مع `?.` في كل الاستدعاءات — نمط يخفي أخطاء NPE. (3) ثلاث نسخ من منطق «هل النموذج يحتوي بيانات» (`:161`, `:213`, `form_tab.dart:46-85`).
- **Violated principle:** Feature Isolation + Explicit dependencies.
- **Current owner:** logs presentation.
- **Correct owner:** `application/` مشترك (مثلاً `DashboardFormSync`) أو `core/`؛ ليس writing عبر features.
- **Consequences:** لا يمكن حذف `home` دون كسر `logs`؛ تعقّب بيانات النموذج صعب.
- **Recommended correction:** اجعل `applyServerForm` use-case في `logs/application` يبثّ `AppEvent.formDataChanged`، ويجعل `home` هو المستهلك. واجعل `_ref` غير اختياري.
- **Related files:** `lib/core/events/app_events.dart`, `lib/features/logs/presentation/providers/logs_provider.dart:94`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-28: الواجهة الأمامية الخام `List<Map<String, dynamic>>` تتسرب إلى state في presentation
- **Severity:** High
- **Category:** Layer Abstraction Leak
- **Location:** `lib/features/logs/presentation/providers/unidentified_events_provider.dart:44` و `:13-39`؛ `lib/features/logs/presentation/pages/unidentified_events_page.dart:71-82` و `:423-434`
- **Evidence:**
```dart
// unidentified_events_provider.dart:41-50
class UnidentifiedListState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> items;
...
```
```dart
// unidentified_events_page.dart:423-434
        final item = items[index];
        final id = item['statusId'] is int ? item['statusId'] as int : null;
        final when = '${item['startTime'] ?? ''}';
        final end = '${item['endTime'] ?? ''}';
        final where = '${item['location'] ?? ''}';
        final status = '${item['dutyStatus'] ?? 'DRIVING'}';
        final duration = '${item['formattedDuration'] ?? ''}';
```
- **Current behavior:** خريطة HTTP الخام هي الـ state، والودجت يستخرج 12 حقلاً منها بـ `'${item['x'] ?? ''}'`.
- **Why problematic:** (1) `'${item['startTime'] ?? ''}'` يحوّل `null` إلى **النص `"null"`** المعروض للمستخدم. (2) التطبيع في `normalizeUnidentifiedItem` (`line 19-39`) **لا يضمن وجود المفاتيح**: `item['startTime']` قد يكون `null` ثم `DateTime.tryParse('$raw')` ⇒ `null` ⇒ يُخفى الصف صامتاً. (3) `normalizeUnidentifiedItem` نفسه **mapper بمفاتيح 13** مكتوب في presentation.
- **Violated principle:** Type Safety + Presentation shouldn't see wire shape.
- **Current owner:** presentation.
- **Correct owner:** كيان `UnidentifiedEvent` في `logs/domain/entities/`.
- **Consequences:** أخطاء عرض غير قابلة للاكتشاف statically.
- **Recommended correction:** عرّف `UnidentifiedEvent` (freezed) في domain، `UnidentifiedEventMapper` في data، واجعل الـ state يحوي كيانات.
- **Related files:** `lib/features/logs/presentation/pages/unidentified_events_page.dart:335-341` (`contains('DRIV')` على نص)
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-32: صنفا parsing عامّان على مستوى الملف داخل presentation
- **Severity:** Medium
- **Category:** Code Organization / Layer Bypass
- **Location:** `lib/features/logs/presentation/providers/unidentified_events_provider.dart:13-17` و `:19-39`
- **Evidence:**
```dart
13: List<Map<String, dynamic>> parseUnidentifiedList(Map<String, dynamic> json) {
14:   final raw = json['items'] ?? json['events'] ?? json['content'] ?? json['data'];
15:   if (raw is! List) return const [];
16:   return raw.whereType<Map>().map(normalizeUnidentifiedItem).toList();
17: }
```
- **Current behavior:** دالتان غيرmembers لفئة، في مجلد `presentation/providers/`، تبنيان خرائط HTTP.
- **Why problematic:** (1) **أربعة محاولات لحقل الحقل نفسه** (`items/events/content/data`) في سطر واحد — عقد غير مستقر. (2) توسيع testability presentation من presentation لـ parsing. (3) mapper بمفاتيح 13 مكانه `data/models/`.
- **Violated principle:** Layer placement + cohesion.
- **Current owner:** presentation.
- **Correct owner:** `logs/data/models/unidentified_event_mapper.dart`.
- **Consequences:** استيراد presentation من presentation لـ parsing.
- **Recommended correction:** انقلهما إلى `data/models/` واعمل لهما اختبار وحدة.
- **Related files:** `lib/features/logs/presentation/pages/unidentified_events_page.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-40: `HosNotifier` يصل إلى مستودع تدقيق المخالفات مباشرة
- **Severity:** Medium
- **Category:** Layer Bypass (presentation → domain repository)
- **Location:** `lib/features/hos/presentation/providers/hos_provider.dart:138-145`
- **Evidence:**
```dart
138:  void _processAndLogViolations(HosEngineResult result) {
139:    if (result is HosEngineReady && result.update.violations.isNotEmpty) {
140:      final auditRepo = _ref.read(hosAuditRepositoryProvider);
141:      for (final v in result.update.violations) {
142:        auditRepo.logViolation(v);
143:      }
144:    }
145:  }
```
- **Current behavior:** الـ notifier يستدعي `logViolation` **بلا `await` ولا معالجة نتيجة** — `auditRepo.logViolation(v)` تُطلق عملية كتابة غير مراقَبة (Future مُهمَل).
- **Why problematic:** (1) كتابة غير مراقَبة في سجل قانوني: أي فشل صامت. (2) `HosAuditRepositoryImpl.logViolation` يكتب في Hive عبر `jsonEncode` (`hos_audit_repository_impl.dart:24-26`) — فشل قرص كامل لن يُبلَّغ. (3) تجاوز use-case layer.
- **Violated principle:** Layered Architecture + Fire-and-forget on legal records.
- **Current owner:** presentation.
- **Correct owner:** use-case في `hos/application/` يتعامل مع `Result`.
- **Consequences:** مخالفة قانونية قد لا تُسجَّل بصمت.
- **Recommended correction:** انقل إلى use-case يعيد `Result<void, Failure>`، وتعامل مع الفشل عبر `AppLogger.error`.
- **Related files:** `lib/features/hos/data/repositories/hos_audit_repository_impl.dart:24-26`, `lib/features/hos/data/providers/hos_audit_providers.dart:11`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------



