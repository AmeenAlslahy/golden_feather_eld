# 05 — تدقيق Riverpod

## نطاق التدقيق

كل استخدام لـ `flutter_riverpod` في المشروع: `Provider`, `FutureProvider`, `StreamProvider`, `StateProvider`, `Notifier`, `AsyncNotifier`, `NotifierProvider`, `Provider.family`, المزوّدات المولّدة (`riverpod_generator`)، وأنماط `overrideWithValue`، إضافة إلى دورة حياة `ProviderContainer` في `main.dart` / `AppInitializer`.

## الحكم الأساسي على Riverpod في هذا المشروع

**Riverpod ليس سبب المشكلة.** البنية الشاملة sound: `ProviderContainer` واحد، جذر تركيب واحد، لا يوجد `ServiceLocator` عام، ولا حالة global قابلة للكتابة من خارج (`CORE-018` ملاحظة: `tracking_provider.dart:67-74` يحفظ `Ref` داخل Notifier وحقلاً عام قابلاً للكتابة — استثناء وحيد).

المشكلة ليست في **نمط الاستخدام** بل في **موقع المزوّدات على الطبقات**. هذا هو المقياس الحاكم:

| مكان المزوّد | الحكم |
|---|---|
| `features/*/presentation/providers/` | صحيح — layer application عملياً |
| `features/*/data/providers/` | مقبول — مرتبط ب constructing المستودع |
| `lib/core/providers/`, `lib/core/events/`, `lib/core/di/` | **خطأ** — قلب النطاق يستورد features |
| `lib/app/orchestrators/` | **خطأ** — منسّق محلي في `Provider<void>` يحمل سياسات HTTP |
| `lib/backend/providers/` | **خطأ** — طبقة محوّل تحتوي ميزتين كاملتين (mock selection + feature wiring) |
| `lib/core/theme/app_theme_provider.dart` | خطأ طفيف — `core` presentation |

### التوزيع الفعلي للمزوّدات (مقيس)

من 399 ملف Dart، يحتوي المزوّدات موزّعة على **7 مجلدات** مختلفة. الاستنتاج الحاسم: `DST-029` — داخل ميزة `tracking` وحدها، مزوّدات Riverpod موزّعة على **أربع طبقات** (`data/datasources`, `data/services`, `data/providers`, `presentation/providers`). هذا ليس فصل مسؤوليات بل تفكك في جذر التركيب.

## المشكلات الجوهرية المكتشفة

### 1. تجاوز `app_initializer` لا يسري (DST-037, CORE-005) — عقدة حقيقية

`lib/app/app_initializer.dart:91` يمرّر:
```dart
trackingServiceProvider.overrideWithValue(trackingService),
```
لكن `lib/features/tracking/data/providers/tracking_providers.dart:41` يستهلك `trackingServiceFullProvider` — وهو مزوّد **مختلف** بنفس الاسم المعنى (CORE-005: كائنان حيّان من `TrackingService` في نفس الملف).

النتيجة المؤكدة: **الـ override الذي يظنه المطبّق هو DI المخصص للإقلاع لا يصل إلى المستودع.** كل ما يظن أنه تهيئة مبكّرة هو في الواقع استخدام المسار البديل الذي ينشئ `TraccarNativeClientImpl` مباشرة (`app_initializer.dart:67`) متجاوزاً `traccarNativeClientProvider` الواعي بالـ mock.

**الأثر**: في بيئة mock، مسار التتبع الذي يعمل هو المسار غير المُحقون — اختبار البيئة لا يختبر ما يُشحن. هذا نمط صامت؛ لا يُصدره المحلل ولا يفشل عند التشغيل.

### 2. `core` يستورد presentation و data (CORE-001, CORE-002, DST-030)

```dart
// lib/core/providers/driver_rules_provider.dart:2
import '../../features/account/presentation/providers/rules_screen_provider.dart';

// lib/core/events/eld_events_provider.dart:3
import '../../features/tracking/data/datasources/live_tracking_data_source.dart';
```
التعليق في `eld_events_provider.dart:9` يقول «هذا يفصل نطاقات HOS/Sync/Logs عن الاستيراد المباشر لمصدر بيانات التتبع» — لكن الاستيراد المباشر لم ينتقل إلى عقد مشترك، بل إلى **مصدر بيانات**. النتيجة: `core` لم يعد innermost، ودورة `features → core → features` مغلقة.

### 3. `autoDispose` في `core` مربوط بعمر صفحة (CORE-001)

`driverRulesProvider` من نوع `Provider.autoDispose`، لكنه يراقب مزوّداً من `presentation`aged بـ `RulesPage`. عمر `core` أصبح مشروطاً بعمر واجهة. لا يوجد خطأ ظاهر — فقط إعادة تحميل صامتة عند إعادة تركيب الشاشة.

### 4. `core_providers.dart` ↔ `backend_network_providers.dart` دورة ثنائية

حساب Tarjan على 408 ملفاً يعطي **دورة من ملفين** تعبر حدود الطبقات:
```
lib/core/network/core_providers.dart            -> lib/backend/providers/backend_network_providers.dart
lib/backend/providers/backend_network_providers.dart -> lib/core/network/core_providers.dart
```
لا يمكن تحميل `core` بمعزل عن `backend`. بالتالي **اختبار أي شيء في `core/network` يتطلب fake للـ backend** — وهذا يفسّر جزئياً لماذا `core/network` غير مغطّى باختبارات وحدة فعالة.

### 5. ثلاثة أنظمة خطأ متنافسة تتعايش مع Riverpod (CORE-009, CORE-010, CORE-011)

```
AppError + Result<T>        (core/error/app_error.dart, core/result/result.dart)
Failure + Either<...>        (core/error/failure.dart, core/utils/repository_helper.dart)
Exception hierarchy          (core/error/exception.dart — موقع throw واحد مقابل 7 فئات)
```
المزوّدات تُرجع `AsyncValue<Model>` في ثلاث مسارات مختلفة، والواجهة تحتاج معرفة أي نظام. ثلاث فئات `AppError` **لا تُنشأ أبداً** (CORE-009): `TimeUnavailableError` (ذات ثقل قانوني)، `StorageError`، `UnsupportedCapabilityError`.

### 6. شفافية مصدر الخطأ مفقودة (ACC-003)

```dart
// lib/features/account/presentation/providers/rules_screen_provider.dart:22
(failure) => throw Exception(failure.l10nKey),
```
`anyErrorUserMessage` (`lib/core/error/user_facing_message.dart:7-25`) لا يملك فرع لـ `Exception`. النتيجة المؤكدة: **كل فشل في شاشة القواعد يُعرض للسائق كـ«خطأ شبكة»** مهما كان سببه (تفويض، شبكة، خادم، غير معروف). لا يمكن للمستخدم التمييز، والفريق لا يستطيع تشخيص.

### 7. `_ref` اختياري يقمع الكتابة العابرة للميزات (HL-31)

```dart
// lib/features/logs/presentation/providers/logs_provider.dart:94,162,192,214
Ref? _ref;   // اختياري
```
الكتابة العابرة للميزات (HL-25، 7 مواقع) تمر عبر `ref?.write(...)`. **إذا كان `_ref` null تتوقف العملية بصمت** — لا استثناء، لا log. سلوك correct-by-accident لا upheld by design.

### 8. استنساخ غير مقصود: `Ref` محفوظ، حقل عام (DST-043)

`tracking_provider.dart:67-74` — `Ref` يُحفظ داخل الـ Notifier ويستخدم كـ Service Locator، مع حقل عام قابل للكتابة من خارج. نمط service-locator متسلل.

### 9. الحاجة إلى `copyWith` غير موجودة (CORE-032)

`ApiClient` لا يثبّت اعتراضاته عند الإنشاء. `ApiClient()` المُنشأ يدوياً (خارج DI) **غير صالح بذاته** — يفشل صامتاً. لا يوجد حارس في المُنشئ.

## متى يكون Riverpod «مخطئاً» ومتى لا يكون

- **ليس خطأ**: `ref.watch(stateProvider)` في `build` (نمط صحيح في 178 موضعاً).
- **ليس خطأ**:， تنسيق مستودع داخل `FutureProvider` عندما لا توجد قاعدة عمل — `dashboard_provider.dart` و`status_dashboard_provider` على حدّ مقبول.
- **ليس خطأ**: `ref.invalidate` على تغيّر هوية (app.dart:40-46) — نمط دقيق ومقصود.
- **خطأ مؤكد**: مزوّد داخل `core` يراقب مزوّد presentation.
- **خطأ مؤكد**: `Provider<void>` يُحمل سياسات HTTP وحدوداً تنظيمية (CORE-025, `tracking_orchestrator.dart:15,28-67`).
- **خطأ مؤكد**: override لا يصل إلى المستهلك الفعلي (DST-037).

## جدول تفصيلي

جميع الملاحظات المرتبطة بـ Riverpod أدناه مع أدلتها الكاملة.
tmp

**عدد الملاحظات في هذا القسم: 50**

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
### ISSUE AUTH-002: طبقة `usecase` في auth طقسية، و`LogoutUseCase` يُسقط نتيجة العملية
- **Severity:** Medium
- **Category:** Meaningless abstraction / Information loss
- **Location:** `lib/features/auth/domain/usecases/check_auth_status_usecase.dart:12-14`, `lib/features/auth/domain/usecases/logout_usecase.dart:9-11`, مقارنةً بـ `lib/features/auth/presentation/providers/auth_state_provider.dart:135-329`
- **Evidence:**
```dart
// lib/features/auth/domain/usecases/check_auth_status_usecase.dart:12
  Future<Either<Failure, User>> call() async {
    return await repository.checkAndRestoreSession();
  }

// lib/features/auth/domain/usecases/logout_usecase.dart:9
  Future<void> call() async {
    await repository.logout();
  }
```
- **Current behavior:** `CheckAuthStatusUseCase` لا يضيف أي قيمة (تحويل منطقي صفر). `LogoutUseCase` يحوّل `Future<Either<Failure, Unit>>` إلى `Future<void>` في **يُهمل الفشل نهائياً**، بينما `AuthNotifier.logout()` (`:301-324`) يبني حالته على افتراض النجاح دائماً.
- **Why problematic:** طبقة application وهمية تُنتج تكلفة تسمية بلا عائد، والأخطر: `Either<Failure, Unit>` كان القناة الوحيدة التي كان يمكن بها الإبلاغ عن فشل الخروج؛ إتلافها يجعل `logout()` غير قابل للإ(report) عن الفشل.
- **Violated principle:** "Use-case must carry domain policy" + "Don't hide information in pass-through wrappers".
- **Current owner:** `logout_usecase.dart`.
- **Correct owner:** إما حذف `CheckAuthStatusUseCase` (استدعاء `AuthRepository.checkAndRestoreSession()` مباشرة)، وإما أن يحمل `LogoutUseCase` `Either<Failure, Unit>` كما هو.
- **Consequences:** (1) صفر قيمة مضافة مقابل 12–15 سطراً لكل use-case؛ (2) فقدان إمكانية عرض "تعذّر تسجيل الخروج على الخادم" للسائق؛ (3) تضليل المراجعKenzie candle sefurther على وجود طبقة use-case غير موجودة فعلاً.
- **Recommended correction:** احذف `CheckAuthStatusUseCase`، وغيّر توقيع `LogoutUseCase.call()` إلى `Future<Either<Failure, Unit>>`.
- **Related files:** `lib/features/auth/presentation/providers/auth_state_provider.dart:294`, `:314`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE AUTH-006: `auth_providers.dart`presentation يعيد تصدير جذر التركيب
- **Severity:** Low
- **Category:** Dependency direction (barrel abuse)
- **Location:** `lib/features/auth/presentation/providers/auth_providers.dart:3`
- **Evidence:**
```dart
// lib/features/auth/presentation/providers/auth_providers.dart:3
export '../../../../core/di/app_providers.dart' show traccarAuthRepositoryProvider, authLocalDataSourceProvider;
```
- **Current behavior:** `core/di/app_providers.dart` هو الـ composition root الوحيد المسموح له باستيراد `*_impl.dart` (حسب تعليق الملف نفسه، السطر 17–19). هذا الـ barrel يجعل مستهلكي presentation_guid الم Orchid unaware أنهم يتكلمون مع root.
- **Why problematic:** نمط شائع لكنه يخفي حدود DI الحقيقية ويجعل `presentation` يبدو مسموحاً باستيراد `core/di`. كل مستورد لـ `auth_providers.dart` وراثياً مرتبط بكل ما يُضاف إلى `app_providers.dart` لاحقاً.
- **Violated principle:** Barrels يجب أن تعكس حدود Mughal المodule لا تُخفيها.
- **Current owner:** presentation barrel.
- **Correct owner:** import مباشر من `core/di/app_providers.dart` عند الحاجة، أو إعادة تسمية الملف إلى `auth_di.dart` في `core/di/`.
- **Consequences:** تلاصق مؤجل، لا عطل حالي.
- **Recommended correction:** احذف الملف واستورد مباشرة، أو انقله إلى `core/di/auth_di.dart`.
- **Related files:** `lib/core/di/app_providers.dart:10`, `lib/core/di/auth_local_data_source_provider.dart`
- **Confidence:** CONFIRMED (الأثر منخفض)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE ACC-003: `rules_screen_provider.dart` يرمي `Exception(l10nKey)` ⇒ كل أخطاء القواعد تُعرض كـ«خطأ شبكة»
- **Severity:** High
- **Category:** Error-contract violation (نموذج) + bug سلوكي مؤكد
- **Location:** `lib/features/account/presentation/providers/rules_screen_provider.dart:13`, `:22`؛ 소비자: `lib/features/account/presentation/pages/rules_page.dart:229-232`؛ المُصيِّر: `lib/core/error/user_facing_message.dart:7-25`
- **Evidence:**
```dart
// lib/features/account/presentation/providers/rules_screen_provider.dart:13
  if (user == null) {
    throw Exception('User not authenticated');
  }

// :21-24
  return result.fold(
    (failure) => throw Exception(failure.l10nKey),
    (model) => model,
  );
```
```dart
// lib/core/error/user_facing_message.dart:7
String anyErrorUserMessage(Object error, {required AppLocalizations loc}) {
  if (error is AppError) return appErrorUserMessage(error, loc: loc);
  if (error is Failure) { ... }
  if (error is String) { ... }
  return loc.errRequestFailedNetwork;   // ← السقوط هنا
}
```
- **Current behavior:** `getRulesScreen` يرجع `AppError` (لديه `l10nKey`)، لكن الـ provider يحوّله إلى `Exception`. في `rules_page.dart` يُمرَّر إلى `anyErrorUserMessage(err, ...)`، وهو لا يتعامل مع `Exception` ⇒ **يسقط دائماً إلى `loc.errRequestFailedNetwork`**.
- **Why problematic:** ثلاث مشاكل: (أ) **السلوك**: كل فشل في شاشة القواعد — صلاحية، notFound، تعارض — يُعرض للسائق كـ«فشل طلب عبر الشبكة»؛ (ب) مفتاح الترجمة يُرمى في `Exception.toString()` ويتجاهَل تماماً؛ (ج) الفقدان محتمل أيضاً في `throw Exception('User not authenticated')`.
- **Violated principle:** خطأ typed يعبر channel typed — لا تحوّل `AppError` إلى `Exception` في provider.
- **Current owner:** `rules_screen_provider.dart`.
- **Correct owner:** `throw failure;` مباشرة (الـ `FutureProvider` يحمل `Object`، و`AppError` типه كافٍ لـ `appErrorUserMessage`).
- **Consequences:** (1) **خطأ مؤكد للمستخدم**: رسالة خاطئة تماماً؛ (2) `l10nKey` مكتوب ومهمَل — ازدواج؛ (3) النمط نفسه متكرر في `logs/data/repositories/log_repository_impl.dart` (6 مواضع) ⇒ عيب نظامي.
- **Recommended correction:** استبدل `throw Exception(failure.l10nKey)` بـ `throw failure;` في كل الملفات المتأثرة.
- **Related files:** `lib/features/logs/data/repositories/log_repository_impl.dart:85,115,372,450,471,492`
- **Confidence:** CONFIRMED (المسار من `Exception` إلى `errRequestFailedNetwork` تم التحقق منه سطراً سطراً في `user_facing_message.dart`)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE ACC-004: `account_provider` يخزّن `l10nKey`/`e.toString()` في الحالة، والصفحة تعرضه خاماً
- **Severity:** High
- **Category:** Localization bypass + Raw exception exposure
- **Location:** `lib/features/account/presentation/providers/account_provider.dart:90`, `:95`, `:119`, `:130`؛ المستهلك: `lib/features/account/presentation/pages/account_page.dart:101-105`
- **Evidence:**
```dart
// lib/features/account/presentation/providers/account_provider.dart:90
        (failure) => state = state.copyWith(isLoading: false, error: failure.l10nKey),

// :95
      state = state.copyWith(isLoading: false, error: e.toString());

// :130
      state = state.copyWith(isLoading: false, error: e.toString());
```
```dart
// lib/features/account/presentation/pages/account_page.dart:101
                          child: Text(
                            accountState.error!,
                            style: context.styles.error,
                            textAlign: TextAlign.center,
                          ),
```
- **Current behavior:** عند فشل `getMyAccount`، يُخزَّن **مفتاح الترجمة** (`networkTimeout`, `sessionExpired`, `notFound`, …) في `AccountState.error` ثم يُعرض كـ`Text` خام. وفي حال الاستثناء العام يُخزَّن `e.toString()` ويُعرض كذلك.
- **Why problematic:** السائق يرى حرفياً `networkTimeout` أو `Exception: ...` على الشاشة. هذا يناقض بوضوح قرار المشروع المعلن في `user_facing_message.dart:6`: «Never the exception, stack, or `toString()`».
- **Violated principle:** Localization boundary + raw exception policy.
- **Current owner:** provider + page.
- **Correct owner:** (أ) `AccountState.error` يحمل `AppError` لا `String`؛ (ب) `account_page.dart` يمرّره إلى `anyErrorUserMessage(err, loc: context.loc)`.
- **Consequences:** (1) **خطأ مؤكد**: رسائل غير مترجمة وغير مقروءة؛ (2) تسريب استثناءات إلى UI؛ (3) تكرار: `AppError` → `l10nKey` في provider ثم `l10nKey` → نص في UI = نقرتان بلا فائدة.
- **Recommended correction:** `final AppError? error;` في `AccountState`، واعرض عبر `appErrorUserMessage`.
- **Related files:** `lib/core/error/app_error.dart:49`, `lib/core/error/user_facing_message.dart:6`
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
### ISSUE COD-003: رسائل إنجليزية hardcoded تُستعمل كـ `Failure.message` / `state.error` وتُعرض خاماً
- **Severity:** Medium
- **Category:** Localization bypass + wrong error channel
- **Location:** `lib/features/codriver/data/repositories/codriver_repository_impl.dart:52`, `:81`, `:92`, `:110`, `:130`، `:40`؛ `lib/features/codriver/presentation/providers/codriver_provider.dart:213`, `:215`, `:224`؛ العرض: `lib/features/codriver/presentation/pages/codriver_page.dart:167`
- **Evidence:**
```dart
// lib/features/codriver/data/repositories/codriver_repository_impl.dart:108-112
      if (coDriverId <= 0) {
        return const Left(
          ServerFailure(message: 'Select a co-driver before switching.'),
        );
      }

// lib/features/codriver/presentation/providers/codriver_provider.dart:213-217
    final id = int.tryParse(state.selectedCoDriver?.id ?? '');
    if (id == null || id <= 0) {
      const message = 'Select a co-driver before switching.';
      state = state.copyWith(isSwitching: false, error: message);
      return message;
    }

// lib/features/codriver/presentation/pages/codriver_page.dart:166-168
                           Text(
                             codriverState.error!,
```
- **Current behavior:** خطأ تحقق **محلي** (السائق لم يختر سائقاً) يُعاد كـ`ServerFailure` — أي كخطأ خادم — برسالة إنجليزية. نفس الجملة مكرَّرة في المستودع وفي الـ provider، وتُعرض خاماً في الواجهة.
- **Why problematic:** (أ) misuse قناة `ServerFailure` لتحقق local؛ (ب) **ازدواج** نفس الجملة في موضعين؛ (ج) لا ترجمة — السائق العربي يرى إنجليزية؛ (د) `anyErrorUserMessage` ستعتبره نصاً آمناً لو مرّ عبره (لأنه ServerFailure + `_isSafeUserFacingText`) فيُعرض كما هو.
- **Violated principle:** Domain error codes ≠ user strings; single source of message.
- **Current owner:** مستودع + provider.
- **Correct owner:** رمز خطأ (`'coDriverNotSelected'`) في `Failure.message`، والترجمة في `codriver_page.dart` عبر `context.translateErrorKey(...)` أو getter في extension.
- **Consequences:** رسائل غير مترجمة + التصنيف الخاطئ (client error labelled server error).
- **Recommended correction:** استبدل الجملة برمز، وأضف الحالات إلى `localization_helper.dart`.
- **Related files:** `lib/core/utils/localization_helper.dart:11-33`, `lib/features/codriver/data/repositories/codriver_repository_impl.dart:130` (`'Co-driver shift change'` — payload فعلي للنظام، مقبول)
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE COD-005: `team_status_provider.dart` ينسّق عمليتين على الخادم ويستخرج JSON يدوياً داخل presentation
- **Severity:** Medium
- **Category:** Data orchestration in presentation
- **Location:** `lib/features/codriver/presentation/providers/team_status_provider.dart:16`, `:20-32`, `:35`
- **Evidence:**
```dart
// lib/features/codriver/presentation/providers/team_status_provider.dart:20-32
  final listed = await backend.list(
    driverId: DriverId(driverId),
    startDate: today,
    endDate: today,
    limit: 1,
  );
  final logId = listed.fold<int?>((failure) => throw failure, (json) {
    final items = json['data'];
    if (items is! List || items.isEmpty) return null;
    final first = items.first;
    final id = first is Map ? first['id'] : null;
    return id is num ? id.toInt() : int.tryParse('$id');
  });

// :35
  final result = await backend.getTeamStatus(DailyLogId(logId));
```
- **Current behavior:** الـ provider يقرأ `dailyLogsBackendProvider`، يبني نطاق اليوم، يستخرج `id` من حمولة raw، ثم ينادي `getTeamStatus`. كل ذلك في presentation.
- **Why problematic:** (أ) knowledge بالشكل الخام لـ endpoint السجلات (`json['data'][0]['id']`) في presentation؛ (ب) تنسيق (orchestration) من presentation؛ (ج) `throw failure` هنا أفضل من siblings، لكنه ما زال presentation يتكلم مع backend مباشرة.
- **Violated principle:** Presentation must not orchestrate multi-call backend flows.
- **Current owner:** `team_status_provider.dart`.
- **Correct owner:** `GetTeamStatusUseCase` في `codriver/domain/usecases/` (يستهلك `DailyLogsQuery` + `DriverSessionBackend`)،/provider يصبح `FutureProvider` ساذج.
- **Consequences:** (1) منطق استخراج id غير قابل لإعادة الاستخدام؛ (2) presentation مربوط بـ contractين بدل واحد.
- **Recommended correction:** استخرج use-case.
- **Related files:** `lib/features/codriver/domain/team_status.dart` (المستهلك)
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CON-003: `hardware_alerts_provider.dart` يقوم بـ JSON mapping + استدعاء backend داخل presentation
- **Severity:** Medium
- **Category:** Data mapping + backend access in presentation
- **Location:** `lib/features/connection/presentation/providers/hardware_alerts_provider.dart:9-19`, `:41-68`, `:71-78`
- **Evidence:**
```dart
// lib/features/connection/presentation/providers/hardware_alerts_provider.dart:7-9
/// تحليل رد التنبيهات — يبقى هنا حتى موجة نقل الـ parsing إلى
/// data/mappers؛ الكيان نفسه نقي في domain.
HardwareAlert _hardwareAlertFromJson(Map<String, dynamic> json) {
```
- **Current behavior:** الملف يحتوي mapper كامل (`_hardwareAlertFromJson` + `_alertList` مع تفرّع على `alerts`/`data.alerts`/سجل فارغ) ويستدعي `hardwareBackendProvider` مباشرة.
- **Why problematic:** (أ) knowledge بشكل wire في presentation؛ (ب) **الملف يعترف بالديون** في تعليقاته ⇒-technical debt معترف به لا مُصلَح؛ (ج) نفس النمط يتكرر في `rules_screen_provider.dart` و`team_status_provider.dart` ⇒ **نمط نظامي عبر المشروع** (provider كـ repository).
- **Violated principle:** Presentation must not contain data mapping.
- **Current owner:** provider.
- **Correct owner:** `features/connection/data/mappers/hardware_alert_mapper.dart` + `ConnectionRepository` + provider thin.
- **Consequences:** mapping غير قابل لإعادة الاستخدام/الاختبار؛ توحيد-shape ضائع.
- **Recommended correction:** استخرج mapper + repository (ينضم لـ CON-001).
- **Related files:** `lib/features/connection/presentation/providers/hardware_status_provider.dart:18-24`, `lib/features/account/presentation/providers/rules_screen_provider.dart:19-24`, `lib/features/codriver/presentation/providers/team_status_provider.dart:20-40`
- **Confidence:** CONFIRMED (مع الإقرار بأنه **مُعلَن** في التعليق — أي debt معروف)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HOM-001: `dashboard_provider.dart` تحوّل HOME إلى "طبقة ترويسة جلسة مشتركة" تستهلكها 3ميزات
- **Severity:** High
- **Category:** Accidental shared module / cross-feature hub
- **Location:** `lib/features/home/presentation/providers/dashboard_provider.dart:2-8`, `:174-224`؛ المستهلكون: `account_page.dart:7`, `eld_connection_page.dart:11`, `home_page.dart:40`
- **Evidence:**
```dart
// lib/features/home/presentation/providers/dashboard_provider.dart:2-8
import '../../../logs/domain/daily_form_rules.dart';
import '../../../logs/domain/entities/daily_form_data.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../codriver/domain/entities/codriver.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../../codriver/presentation/providers/codriver_provider.dart';
```
```dart
// :174-224 (مقتطف)
//Listen to Auth State
  ref.listen(authStateProvider, ...)
// Listen to Vehicle State
  ref.listen(vehicleProvider, ...)
// Listen to CoDriver State
  ref.listen(codriverProvider, ...)
```
- **Current behavior:** مزوّد داخل `features/home/presentation/providers/` يستمع لثلاثة features ويجمعها في `DashboardData`. ثم **ACCOUNT** (`account_page.dart:7`) و**CONNECTION** (`eld_connection_page.dart:11`) يستوردانه لعرض اسم السائق/اسم المركبة.
- **Why problematic:** (أ) `dashboardDataProvider` **ليس** مفهوم HOME — هو "ترويسة جلسة" مفهوم عابر للميزات؛ (ب) موضوعه في `home/` يعني أن أي feature تعتمد عليه ⇒ **home تتحول إلى provider common** (السبب الجذري لـ ACC-007 و CON-001 coupling)؛ (c) presence of `logs/domain` import — home presentation يعتمد على logs domain rules (`joinFormList`).
- **Violated principle:** A feature is a vertical slice; shared cross-cutting state belongs to `core`/`shared`, not to a feature that others depend on.
- **Current owner:** `features/home/presentation/providers/dashboard_provider.dart`.
- **Correct owner:** `lib/core/session/session_header_provider.dart` (أو `lib/app/` layer) — يجمع auth+vehicle+codriver ويخدم الجميع.
- **Consequences:** (1) circular-feel: home→codriver→auth؛ account→home؛ connection→home؛ (2) تغيير واحد في HOME يكسر 3 شاشات؛ (3) تسمية مضلّلة.
- **Recommended correction:** انقل إلى `core/session/` أو `app/` layer، ودع `home` يستهلكه كأي consumer.
- **Related files:** `lib/features/account/presentation/pages/account_page.dart:32`, `lib/features/connection/presentation/pages/eld_connection_page.dart:312`
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
### ISSUE DOM-001: `lib/domain/duty_status/duty_status_code.dart` يستورد Flutter + logger ويحمل ألواناً — وينتشر إلى `backend/contracts`
- **Severity:** High
- **Category:** Domain purity breach (Flutter in shared domain)
- **Location:** `lib/domain/duty_status/duty_status_code.dart:7-8`, `:75-88`؛ الانتشار: `lib/backend/contracts/status_dashboard_backend.dart:2`, `lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart:1`, `lib/features/hos/presentation/providers/hos_provider.dart:12`, **و18 ملفاً آخر**
- **Evidence:**
```dart
// lib/domain/duty_status/duty_status_code.dart:7-8
import 'package:flutter/widgets.dart';
import '../../../core/utils/logger.dart';

// :74-88
  /// UI Color representation mapping
  Color get displayColor {
    switch (this) {
      case DutyStatusCode.onDutyNotDriving:
      case DutyStatusCode.yardMove:
      case DutyStatusCode.personalConveyance:
        return const Color(0xFFFBBF24); // AppColors.primaryGold
      case DutyStatusCode.offDuty:
        return const Color(0xFF6B7280); // AppColors.textSecondary
      case DutyStatusCode.driving:
        return const Color(0xFF10B981); // AppColors.successGreen
      case DutyStatusCode.sleeperBerth:
        return const Color(0xFFF59E0B); // AppColors.warningYellow
    }
  }
```
- **Current behavior:** **8 من 9 ملفات في `lib/domain/` نقي تماماً** (لا Flutter، لا Riverpod، لا Dio، لا features — تم التحقق من **كل** استيرادات الملفات التسعة). الملف التاسع `duty_status_code.dart` يخالف: (أ) يستورد `flutter/widgets.dart` (سطر 7)، (ب) يستورد `core/utils/logger.dart` (سطر 8)، (ج) يحمل `Color get displayColor` بـ hex **مكرَّرة حرفياً من `core/theme/app_colors.dart`** (تعليق السطر 80 يؤكد التكرار). أستورد `lib/backend/contracts/status_dashboard_backend.dart:2` و`lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart:1` ⇒ **نوع Flutter `Color` يُسحب إلى طبقة عقود البنية التحتية**.
- **Why problematic:** (أ) عقد الـ backend لم يعد نقيا؛ (ب) `displayColor` **ليس** قرار نطاق (business) — قرار عرض؛ (ج) القيم الستاسية مكرَّرة: تعديل لون في `AppColors.primaryGold` لن ينعكس على `DutyStatusCode.displayColor`.
- **Violated principle:** **"verify it imports nothing from Flutter/Riverpod/Dio/features"** — الملف الوحيد من التسعة الذي ينتهك.
- **Current owner:** `lib/domain/duty_status/duty_status_code.dart`.
- **Correct owner:** (أ) `displayColor` → `core/theme/status_color_mapper.dart` أو `core/utils/status_color_helper.dart` (الموجود!). (ب) `AppLogger.warning` → نبذه من domain (يمسح الاستيراد).
- **Consequences:** (1) `backend/contracts` و`backend/adapters` يعتمدان transitively على Flutter؛ (2) قيم لونية غير قابلة للتحديث؛ (3) `lib/domain/` غير صالحة كـ "domain مستقل".
- **Recommended correction:** احذف `flutter/widgets.dart` و`core/utils/logger.dart` من الملف؛ انقل `displayColor` إلى `core/utils/status_color_helper.dart` (المستورد أصلاً في `lib/core/utils/status_color_helper.dart:2`).
- **Related files:** `lib/core/utils/status_color_helper.dart:2`, `lib/backend/contracts/status_dashboard_backend.dart:2`
- **Confidence:** CONFIRMED (كل استيرادات الملفات التسعة تم فحصها)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DOM-005: لا يوجد أي فحص معماري آلي؛ علامات `// ignore_architecture` أصبحت بلا أثر
- **Severity:** Low
- **Category:** Missing guardrail
- **Location:** `analysis_options.yaml` (فحصه كاملاً: `linter: rules:` فارغ عملياً)؛ `lib/core/di/app_providers.dart:3,7,10`
- **Evidence:**
```dart
// lib/core/di/app_providers.dart:3
import 'package:golden_feather_eld/backend/providers/backend_providers.dart'; // ignore_architecture
...
// :10
import 'package:golden_feather_eld/features/auth/data/repositories/auth_repository_impl.dart'; // ignore_architecture
```
- **Current behavior:** المشروع يستخدم وسم `// ignore_architecture` كوَسم مهني في `app_providers.dart`، لكن `analysis_options.yaml` لا يعرّف أي lint باسم architecture (تم التحقق: `linter: rules:` لا يحتوي شيء). ⇒ الوسم **لا يفعل شيئاً** — حماية زائفة.
- **Why problematic:** بدون أداة، كل المخالفات أعلاه (SUI/aip provider = repository، domain→Flutter، application→presentation) تمر بلا إنذار. `custom_lint` أو `dependency_rules` أو `dart_code_metrics` من `analysis_options.yaml` كان كفيلاً بكشف 6 من 9 ملاحظات High.
- **Violated principle:** Executable architecture.
- **Current owner:** — (missing)
- **Correct owner:** `analysis_options.yaml` + `dependency_rules`-style config.
- **Recommended correction:** فعّل `dependency_rules` بالحدود: `lib/domain/**` ⊅ `flutter/`, `features/*/presentation/**` ⊅ `features/*/data/**` و `backend/adapters/**`.
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-013: عقدة `SignatureBackend` ميتة بالكامل — لا مزوّد ولا مستهلك
- **Severity:** MEDIUM
- **Category:** Maintainability
- **Location:** `lib/backend/providers/backend_providers.dart:59-117`
- **Evidence:** التعداد الفعلي للمزوّدات في الملف = 13، بينما `BackendAdapter` يعرّف 14 عقدة:
```dart
// lib/backend/core/backend_adapter.dart:56
  SignatureBackend? get signature;
```
```dart
// lib/backend/adapters/eld_engine/sub/eld_signature_backend.dart:24-32
    return err(
      const ServerError(
        code: 'eld.signature_endpoint_absent',
        context: {
          'message':
              'The server contract has no signature upload path. Certify the daily log instead.',
        },
      ),
    );
```
- **السلوك الحالي:** تحققت بالبحث النصي في `lib/` بالكامل: `SignatureBackend` يظهر **فقط** في `contracts/signature_backend.dart`، `core/backend_adapter.dart:56`، `eld_signature_backend.dart`، `mock_signature_backend.dart`، `eld_engine_adapter.dart:58`، `mock_adapter.dart:62`. **لا يوجد أي `signatureBackendProvider`**، ولا أي مستهلك. رغم أن `mock_signature_backend.dart` بني منطقًا حقيقيًا كاملًا (49 سطرًا: تخزين، hash، شهادة).
- **لماذا هو مشكل:** طبقة كاملة (عقدة + محوّلان + getter في الـ adapter + منطق mock) موجودة لتعمل في الفراغ. هذا يوهم Maintenance بأن «التوقيعات مدعومة عبر المنفذ»، بينما هي غير مربوطة إطلاقًا.
- **المبدأ المنتهك:** Dead code removal / YAGNI على مستوى العقد.
- **العواقب:** 4 ملفات + منطق mock تُصان بلا مستفيد؛ قرّاء الكود يفترضون وجود مسار توقيع.
- **التصحيح المقترح:** إما (أ) **حذف العقدة والمحوّلين** بالكامل (بما في ذلك `mock_signature_backend.dart`) لأن الاعتماد يتم عبر `daily-logs/{id}/certify`؛ أو (ب) إن كانت هناك نية لإحيائها: أضف `signatureBackendProvider` وموضع استهلاك. التوصية: (أ)، لأن `EldSignatureBackend` نفسه يقرّ بأن المسار غير موجود في العقد الحي.
- **الملفات ذات الصلة:** `signature_backend.dart`، `backend_adapter.dart:56`، `eld_signature_backend.dart`، `mock_signature_backend.dart`، `eld_engine_adapter.dart:58`، `mock_adapter.dart:62`، `backend_providers.dart`
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
### ISSUE BACK-036: `update_rules_use_case.dart` يرمي استثناءً داخل جسم Provider ويقرن العقد بالتخزين والمصادقة
- **Severity:** MEDIUM
- **Category:** Riverpod
- **Location:** `lib/features/account/application/usecases/update_rules_use_case.dart:52-61`
- **Evidence:**
```dart
// update_rules_use_case.dart:52-61
final updateRulesUseCaseProvider = Provider<UpdateRulesUseCase>((ref) {
  final backend = ref.watch(rulesScreenBackendProvider);
  final storage = ref.watch(localStorageProvider);
  final user = ref.watch(authStateProvider).user;
   
  if (user == null) {
    throw Exception('User not authenticated');
  }

  return UpdateRulesUseCase(backend, storage, user.id);
});
```
- **السلوك الحالي:** الـ use-case (طبقة `application`) يحتجز **ثلاثة** اعتمادات: العقد + التخزين + المصادقة، ويُرمى استثناء عند غياب المستخدم.
- **لماذا هو مشكل:** (أ) `throw Exception(...)` داخل `Provider` body = خطأ **بناء شجرة Riverpod**، لا حالة خطأ قابلة للاستخدام في الواجهة؛ كل `ref.watch(updateRulesUseCaseProvider)` في وقت غير مصادَق يرمي. (ب) اقتران `localStorageProvider` و`authStateProvider` داخل use-case يخلط «منطق حالة القاعدة» بـ«منطق الجلسة والتخزين» — SRP.
- **المبدأ المنتهك:** Riverpod best practices (لا ترمي من Provider body)، SRP.
- **العواقب:** شاشة إعدادات القاعدة تنهار بدل أن تعرض «سجّل الدخول».
- **التصحيح المقترح:** جعل `UpdateRulesUseCase` يعتمد على `AuthState` (nullable) أو على `DriverId` اختياري، وتحويل غياب المستخدم إلى `Either<Failure, ...>` بدل `throw`.
- **الملفات ذات الصلة:** `update_rules_use_case.dart`، `rules_screen_backend.dart`، `core/di/core_providers.dart`
- **Confidence:** CONFIRMED

---

## C. جدول تناظر العقود (`eld_engine` مقابل `mock`)

**إجمالي دوال العقد: 58.** كل صف = دالة عقد واحدة.
«✅» = يُرجع قيمة `Result` صحيحة | «❌» = `throw UnimplementedError` | «⚠️» = منفَّذ لكن بتناظر دلالي/شكلي مختلف.

| العقد | الدالة | `eld_engine` | `mock` | حالة التناظر |
|---|---|---|---|---|
| **AuthBackend**<br>4/4 ✅ | `login` | `eld_auth_backend.dart:17` | `mock_auth_backend.dart:9` ✅ | تناظر تام — نفس المفاتيح `credential/user/serverOrigin` |
| | `validateSession` | `eld_auth_backend.dart:100` | `mock_auth_backend.dart:23` ✅ | تناظر تام |
| | `logout` | `eld_auth_backend.dart:142` | `mock_auth_backend.dart:36` ✅ | تناظر تام |
| | `requestPasswordReset` | `eld_auth_backend.dart:165` | `mock_auth_backend.dart:45` ✅ | تناظر تام |
| **AccountBackend**<br>2/2 ✅ | `getMyAccount` | `eld_account_backend.dart:51` | `mock_account_backend.dart:15` ⚠️ | الموك لا يطبّق `_mapAccountJson` (BACK-019) |
| | `updatePreferences` | `eld_account_backend.dart:64` | `mock_account_backend.dart:20` ⚠️ | نفس الملاحظة |
| **DailyLogsBackend**<br>7/11 ✅ | `list` | `eld_daily_logs_backend.dart:17` | `mock_daily_logs_backend.dart:14` ✅ | تناظر شكلي |
| | `getById` | `eld_daily_logs_backend.dart:47` | `mock_daily_logs_backend.dart:51` ❌ | `UnimplementedError` |
| | `getTeamStatus` | `eld_daily_logs_backend.dart:56` | `mock_daily_logs_backend.dart:55` ✅ | تناظر |
| | `respondToCarrierEdit` | `eld_daily_logs_backend.dart:65` | `mock_daily_logs_backend.dart:67` ✅ | تناظر |
| | `certify` | `eld_daily_logs_backend.dart:83` | `mock_daily_logs_backend.dart:77` ✅ | تناظر (يستورد DTO المحرك — BACK-035) |
| | `reassignDriving` | `eld_daily_logs_backend.dart:97` | `mock_daily_logs_backend.dart:89` ✅ | تناظر |
| | `getForm` | `eld_daily_logs_backend.dart:114` | `mock_daily_logs_backend.dart:99` ❌ | `UnimplementedError` |
| | `saveForm` | `eld_daily_logs_backend.dart:123` | `mock_daily_logs_backend.dart:103` ❌ | `UnimplementedError` |
| | `getGraphGrid` | `eld_daily_logs_backend.dart:138` | `mock_daily_logs_backend.dart:111` ✅ | تناظر |
| | `lock` | `eld_daily_logs_backend.dart:147` | `mock_daily_logs_backend.dart:115` ❌ | `UnimplementedError` |
| | `getReadiness` | `eld_daily_logs_backend.dart:155` | `mock_daily_logs_backend.dart:119` ✅ | تناظر |
| **DriverSessionBackend**<br>1/5 ✅ | `getActiveSession` | `eld_driver_session_backend.dart:17` | `mock_driver_session_backend.dart:13` ❌ | `UnimplementedError` |
| | `getAvailableDrivers` | `eld_driver_session_backend.dart:39` | `mock_driver_session_backend.dart:24` ✅ | الموك `[]` دائمًا |
| | `getCurrentCoDriver` | `eld_driver_session_backend.dart:26` | `mock_driver_session_backend.dart:19` ❌ | `UnimplementedError` («no invented co-driver») |
| | `connect` | `eld_driver_session_backend.dart:50` | `mock_driver_session_backend.dart:29` ❌ | `UnimplementedError` |
| | `switchPrimaryDriver` | `eld_driver_session_backend.dart:66` | `mock_driver_session_backend.dart:36` ❌ | `UnimplementedError` |
| **DutyStatusBackend**<br>4/5 ✅ | `record` | `eld_duty_status_backend.dart:15` | `mock_duty_status_backend.dart:12` ⚠️ | **`DateTime.now()` ⇒ غير حتمي** (BACK-021) |
| | `update` | `eld_duty_status_backend.dart:25` | `mock_duty_status_backend.dart:16` ⚠️ | نفس الملاحظة |
| | `getGraphGrid` | `eld_duty_status_backend.dart:38` | `mock_duty_status_backend.dart:23` ❌ | `UnimplementedError` |
| | `submitLegacyDutyStatusEvent` | `eld_duty_status_backend.dart:54` | `mock_duty_status_backend.dart:30` ✅ | تناظر |
| | `submitLegacyGenericEvent` | `eld_duty_status_backend.dart:73` | `mock_duty_status_backend.dart:39` ✅ | تناظر |
| **DvirBackend**<br>6/8 ✅ | `list` | `eld_dvir_backend.dart:16` | `mock_dvir_backend.dart:12` ⚠️ **❗** | **شكل مختلف: `'data'` vs `'reports'`** (BACK-008) |
| | `create` | `eld_dvir_backend.dart:52` | `mock_dvir_backend.dart:24` ✅ | تناظر (`ok(null)`) |
| | `getById` | `eld_dvir_backend.dart:71` | `mock_dvir_backend.dart:32` ❌ | `UnimplementedError` |
| | `review` | `eld_dvir_backend.dart:82` | `mock_dvir_backend.dart:38` ❌ | `UnimplementedError` |
| | `getDefectsCatalog` | `eld_dvir_backend.dart:104` | `mock_dvir_backend.dart:46` ✅ | تناظر (11 عنصرًا) |
| | `getPreviousDvir` | `eld_dvir_backend.dart:113` | `mock_dvir_backend.dart:63` ✅ | تناظر |
| | `getDefectDetails` | `eld_dvir_backend.dart:122` | `mock_dvir_backend.dart:68` ✅ | تناظر (`{}` فارغ) |
| | `getVehicleDefects` | `eld_dvir_backend.dart:131` | `mock_dvir_backend.dart:72` ✅ | تناظر |
| **HardwareBackend**<br>3/6 ✅ | `getAlerts` | `eld_hardware_backend.dart:20` | `mock_hardware_backend.dart:12` ❌ | `async`-throw (BACK-022) |
| | `setManualMode` | `eld_hardware_backend.dart:30` | `mock_hardware_backend.dart:17` ✅ | تناظر |
| | `getReadiness` | `eld_hardware_backend.dart:51` | `mock_hardware_backend.dart:30` ✅ | تناظر |
| | `connectSession` | `eld_hardware_backend.dart:68` | `mock_hardware_backend.dart:51` ❌ | `async`-throw |
| | `getStatus` | `eld_hardware_backend.dart:85` | `mock_hardware_backend.dart:59` ❌ **❗** | `async`-throw ⇒ **انهيار `hardwareStatusProvider`** |
| | `sendTelemetry` | `eld_hardware_backend.dart:106` | `mock_hardware_backend.dart:67` ✅ | تناظر |
| **InspectionBackend**<br>3/8 ✅ | `getScreen` | `eld_inspection_backend.dart:17` | `mock_inspection_backend.dart:14` ✅ | الموك يعلن `canStart/canSend/canEmail/canView = false` بوعي |
| | `getCycle` | `eld_inspection_backend.dart:34` | `mock_inspection_backend.dart:43` ✅ | تناظر |
| | `getLogs` | `eld_inspection_backend.dart:59` | `mock_inspection_backend.dart:87` ✅ | تناظر (مع تخزين في الذاكرة) |
| | `emailLogs` | `eld_inspection_backend.dart:103` | `mock_inspection_backend.dart:152` ❌ | `UnimplementedError` |
| | `getInformationPacket` | `eld_inspection_backend.dart:128` | `mock_inspection_backend.dart:164` ❌ | `UnimplementedError` |
| | `sendLogs` | `eld_inspection_backend.dart:139` | `mock_inspection_backend.dart:168` ❌ | `UnimplementedError` |
| | `startInspection` | `eld_inspection_backend.dart:166` | `mock_inspection_backend.dart:181` ❌ | `UnimplementedError` |
| | `getTransfers` | `eld_inspection_backend.dart:185` | `mock_inspection_backend.dart:192` ❌ | `UnimplementedError` |
| **RulesScreenBackend**<br>2/2 ✅ | `getRulesScreen` | `eld_rules_screen_backend.dart:18` | `mock_rules_screen_backend.dart:55` ✅ | تناظر — لكن كلاهما يمرّ بـ `eld_engine` DTO+mapper (BACK-035) |
| | `saveRulesScreen` | `eld_rules_screen_backend.dart:28` | `mock_rules_screen_backend.dart:61` ✅ | تناظر |
| **SignatureBackend**<br>1/1 ⚠️ | `save` | `eld_signature_backend.dart:18` | `mock_signature_backend.dart:19` ⚠️ **❗** | **تباين تام**: المحرك يُرجع `err` دائمًا، الموك يُصدر شهادة. **ولا يوجد provider ولا مستهلك للاثنتين** (BACK-013) |
| **StatusDashboardBackend**<br>3/3 ✅ | `getDashboard` | `eld_status_dashboard_backend.dart:21` | `mock_status_dashboard_backend.dart:29` ✅ | تناظر كامل — نماذج domain مُحاطة |
| | `updateDutyStatus` | `eld_status_dashboard_backend.dart:37` | `mock_status_dashboard_backend.dart:34` ✅ | تناظر كامل |
| | `getWeeklyRecap` | `eld_status_dashboard_backend.dart:95` | `mock_status_dashboard_backend.dart:43` ✅ | تناظر كامل |
| **UnidentifiedEventsBackend**<br>**0/3** ❗ | `list` | `eld_unidentified_events_backend.dart:43` | `mock_unidentified_events_backend.dart:13` ❌ | `UnimplementedError` |
| | `claim` | `eld_unidentified_events_backend.dart:61` | `mock_unidentified_events_backend.dart:23` ❌ | `UnimplementedError` |
| | `reject` | `eld_unidentified_events_backend.dart:73` | `mock_unidentified_events_backend.dart:31` ❌ | `UnimplementedError` |
| **VehicleBackend**<br>2/2 ✅ | `getCompanyFleet` | `eld_vehicle_backend.dart:19` | `mock_vehicle_backend.dart:14` ✅ | تناظر — كلاهما `{'data': []}` |
| | `getMyVehicles` | `eld_vehicle_backend.dart:34` | `mock_vehicle_backend.dart:18` ✅ | تناظر |

### ملخص التناظر

| المقياس | القيمة |
|---|---|
| إجمالي دوال العقد | **58** |
| منفَّذة بالكامل في الموك | **36** (62%) |
| `throw UnimplementedError` في الموك | **22** (38%) — BACK-020 |
| عقود بنسبة تنفيذ 0% | **1** من 13 (`UnidentifiedEventsBackend`) |
| عقود بنسبة تنفيذ 100% | **5** من 13 (`AuthBackend`, `VehicleBackend`, `RulesScreenBackend`, `StatusDashboardBackend`, `AccountBackend` تنازليًا) |
| دوال بتباين **دلالي صامت** (تنجح لكن بشكل مختلف) | **3**: `DvirBackend.list` (❗ BACK-008)، `DutyStatusBackend.record/update` (BACK-021)، `AccountBackend.*` (BACK-019) |
| دوال بتباين **كامل** | **1**: `SignatureBackend.save` (❗ BACK-013، وهي ميتة أصلًا) |
| getterات في `BackendAdapter` بلا `Provider` | **1 من 14**: `signature` (BACK-013) |
| صنف في `MockAdapter` بلا تنفيذ جوهري | **1**: `MockSignatureBackend` (49 سطرًا منطق لا يُستدعى) |

**الحكم على التماثل:** المحوّلان **متماثلان على مستوى التوقيع** (كل الـ 13 عقدة تُنفَّذ في `MockAdapter`، ولا يوجد getter ناقص — عدا `signature` الميت في الاثنين). لكن **التناظر على مستوى السلوك ضعيف**: 38% من الدوال ترمي استثناءً، و3 دوال «تنجح» بشكل مختلف دون أن يعلم أحد.

---

## D. ملاحظات عبر الملفات

### D.1 — طبقات تستهلك `lib/backend/contracts/` (نتيجة بحث نصي على `lib/` بالكامل)
| الملف | السطر | نوع الطبقة | العقد المستورد | الحكم |
|---|---|---|---|---|
| `features/codriver/data/repositories/codriver_repository_impl.dart` | 8, 9 | data | `contract_enums`, `driver_session_backend` | ✅ صحيح |
| `features/codriver/data/providers/codriver_repository_providers.dart` | 3 | data | `driver_session_backend` | ✅ صحيح |
| `features/inspection/data/repositories/inspection_repository_impl.dart` | 9, 10 | data | `inspection_backend`, `contract_enums` | ✅ صحيح |
| `features/vehicle/data/repositories/vehicle_repository_impl.dart` | 8, 9 | data | `raw_json`, `vehicle_backend` | ⚠️ يستورد `raw_json` مباشرة (BACK-001) |
| `features/vehicle/data/providers/vehicle_repository_providers.dart` | 3 | data | `vehicle_backend` | ✅ صحيح |
| `features/dvir/data/repositories/dvir_repository_impl.dart` | 14, 15 | data | `dvir_backend`, `raw_json` | ⚠️ + يستورد `eld_engine` DTO (BACK-007) |
| **`features/hos/domain/engine/tracking/duty_status_tracker.dart`** | **13** | **domain** | `status_dashboard_backend` | ❌ **انقلاب طبقة** (BACK-001) |
| `features/hos/data/repositories/status_dashboard_repository_impl.dart` | 2 | data | `status_dashboard_backend` | ✅ صحيح |
| `features/sync/data/repositories/traccar_remote_event_dispatcher.dart` | 9, 11, 12, 13, 14 | data | 4 عقود | ✅ صحيح |
| `features/auth/data/repositories/auth_repository_impl.dart` | 11 | data | `auth_backend` | ✅ صحيح |
| **`features/logs/presentation/pages/unidentified_events_page.dart`** | **6** | **presentation** | `contract_enums` | ❌ **خرق** (BACK-024) |
| **`features/logs/presentation/providers/unidentified_events_provider.dart`** | **3** | **presentation** | `contract_enums` | ❌ **خرق** (BACK-024) + يستدعي العقد مباشرة (BACK-023) |
| `features/logs/data/repositories/log_repository_impl.dart` | 12, 13 | data | `daily_logs_backend`, `duty_status_backend` | ✅ صحيح |
| **`features/account/presentation/providers/account_provider.dart`** | **3** | **presentation** | `account_backend` | ❌ **خرق** (BACK-023) |
| `features/account/application/usecases/update_rules_use_case.dart` | 3 | application | `rules_screen_backend` | ⚠️ مقبول (use-case يعتمد على port)، لكن `throw` في Provider body (BACK-036) |

**الخلاصة:** 15 ملفًا. **10 منها في `data`** (الصحيح). **1 في `domain`** (انقلاب مؤكد). **1 في `application`** (مقبول). **3 في `presentation`** (خرق مؤكد).

### D.2 — الحواف المعكوسة من `lib/backend` إلى `lib/features` (سجل كامل)
| الملف | السطر | العمود المستورد | نوع الخرق |
|---|---|---|---|
| `contracts/rules_screen_backend.dart` | 3 | `features/account/application/models` | layer inversion |
| `adapters/eld_engine/sub/eld_rules_screen_backend.dart` | 3 | `features/account/application/models` | layer inversion |
| `adapters/eld_engine/mappers/rules_screen_mapper.dart` | 1 | `features/account/application/models` | layer inversion |
| `adapters/mock/sub/mock_rules_screen_backend.dart` | 4 | `features/account/application/models` | layer inversion |
| `http/interceptors/auth_interceptor.dart` | 2 | `features/auth/**data**` | concrete dependency (الأخطر) |
| `http/interceptors/auth_interceptor.dart` | 3 | `features/auth/domain/entities` | عديم الخطر نسبيًا |
| `providers/backend_network_providers.dart` | 11-13 | `features/tracking/data/datasources/traccar_sdk` | misplaced feature |

**لا يوجد import دائري حقيقي داخل `lib/backend`** — تحققت من الرسم البياني: `contracts → adapters/eld_engine/models` ثم `models → (لا شيء)`، و`adapters/mock → adapters/eld_engine` ثم `eld_engine → contracts`؟ لا: `eld_engine/sub/*` يستورد `contracts/*`، و`contracts/*` لا يستورد أي `sub/*`. لذلك لا دورة import فعلية؛ المشكلة **اتجاه** وليس **دورة**.

### D.3 — إجابات مباشرة على أسئلة التدقيق المطلوبة

**س: هل تتسرّب أنواع Dio أو رموز HTTP أو أشكال JSON أو أسماء حقول خاصة بالـ backend إلى كود النطاق؟**
- **أنواع Dio: لا.** صفر استيراد لـ `package:dio` في أي ملف تحت `lib/backend/contracts/` (تحققت بقراءة الـ 15 ملفًا كاملة). ✅
- **رموز HTTP: نعم، بشكل مقبول.** `eld_endpoints.dart` مصدر واحد منظَّم للمسارات، والاستخدام محصور في مجلد `adapters/`. لكن `expectedOwnerDriverId` (سياسة جدولة) تسرّب إلى 4 عقد (BACK-012).
- **أسماء حقول الخادم: نعم، وبشكل واسع.** `contract_enums.dart` (5 enums بـ`wire`)، `AuthBackend` (`credential/user/serverOrigin`)، `RawJson` (37 موضع استيراد). **CONFIRMED**.
- **كم الترجمة الفعلية في المappers؟** من الـ 58 دالة عقد: **12 ترجع نوعًا مُحاطًا** (3 account/status_dashboard/signature + 3 inspection + 2 daily_logs + 1 rules_screen + …) أي **≈21% ترجمة حقيقية**، والباقي تمرير خام. المappers المجردة (`status_dashboard_mapper.dart` 215 سطرًا، `dot_inspection_mapper.dart` 151، `rules_screen_mapper.dart` 33) ممتازة في عملها؛ المشكلة في **تغطيتها** لا في **جودتها**.

**س: هل التجريد (`BackendAdapter` / `backend_registry`) حقيقي أم زخرفي؟**
- `BackendAdapter`: **حقيقي**. مُستهلك في 13 provider (`backend_providers.dart:60-116`)، وله استبدال فعلي في `activeBackendProvider` (45-52). لكن **بنيته متكسرة**: 14 getter كلها `?` مع تحويل `null → StateError` في 13 مكانًا (BACK-025)، و`signature` بلا provider (BACK-013).
- `BackendRegistry`: **زخرفة**. 129 سطرًا، **7 أعضاء بلا أي استدعاء إنتاجي**، والمصنع المستخدم هو `single()` الذي يلغي التعدّد (BACK-027).

**س: هل يوجد ازدواج في base-URL / endpoint / timeout بين `lib/backend/http/api_config.dart` و`lib/core/network/api_config.dart`؟**
- **لا.** الملف في `backend/http/` **كله تعليقات** (7 أسطر) ولا يستورده أي كود. تم اقتباس الملفين بالكامل في BACK-028.
- **الازدواج الحقيقي في مكان آخر**: تطبيع URL **3 نسخ** عبر طبقتين (`BACK-026`). أما الـ endpoints (مصدر واحد) والـ timeouts (مصدر واحد) فسليمان.

**س: هل `contracts/*` تكشف raw JSON / Map / dynamic للمستهلكين، وهل يتسرّب إلى domain/UI؟**
- **نعم في 11 من 13 عقدة**، ويوجد `List<dynamic>` إضافي في `driver_session_backend.dart:12`.
- **التسرّب مؤكَّد إلى طبقتين**: `domain` (ملف واحد، BACK-001) و`presentation` (7 مواقع، BACK-001 + BACK-023).

**س: هلتفوّق بين `eld_engine` و`mock`؟**
- على مستوى التوقيع: **لا** (13/13 عقدة، 14 getter مع `signature`).
- على مستوى التنفيذ: **نعم، حادًا** — 22/58 دالة ترمي (BACK-020).
- على مستوى شكل البيانات: **نعم، بصمت** — `DvirBackend.list` (BACK-008).

### D.4 — أنماط ثابتة تستحق إشادة (للتوازن)
1. **`mappers/json_primitives.dart`**: توحيد يدوي لمساعدة كانت مكرّرة في ملفين. قرار عالٍ الجودة.
2. **`mappers/hardware_mapper.dart`**: 27 سطرًا، مسؤولية واحدة، تحويل وحدات موثّق. مثال للمعيار.
3. **`sub/eld_account_backend.dart`**: `_mapAccountJson` ترجمة حقيقية تحل انحرافات الـ wire داخل المحوّل — بالضبط ما يجب أن يفعله mapper.
4. **`contracts/status_dashboard_backend.dart`**: أنقى عقدة في المشروع (0 `RawJson`، 0 Dio، 0 نص).
5. **`sub/eld_auth_backend.dart` + `auth_interceptor.dart`**: تعامل ناضج مع `JSESSIONID` ككوكي (لا Bearer)، حماية من التسريب عبر الأصول (106)، ومعالجة 401 بثلاثة أجيال. موثّق بالعربية وبتعليقات تُشرح «لماذا».
6. **`sub/mock_inspection_backend.dart:30-35`**: تعليق يشرح قرارًا تصميميًا صعبًا (إعلان `false` بدل `true` للأزرار غير المنفَّذة). هذا بالضبط ما يجب أن يُكتب.
7. **`RequestLogger` مقيَّد بـ `kDebugMode`** (`backend_network_providers.dart:67`) — يمنع تسرب PII في الإنتاج رغم أن `AppLogger.error` يُكتب في release.
8. **`AuthInterceptor` يرفض الإرسال تحت جلسة مختلفة قبل مغادرة أي بايت** (87-98) — سلوك تنفيذي نادر ودقيق.

### D.5 — نمط متكرر: `parser: (data) => data is Map<String, dynamic> ? data : {}`
هذا اللمboa يتكرر **20+ مرة** عبر `eld_daily_logs_backend.dart`، `eld_dvr_backend.dart`، `eld_duty_status_backend.dart`، `eld_hardware_backend.dart`، `eld_vehicle_backend.dart`. تأثيره:
- **يمحو كل انحرافات الـ wire بصمت**: جسم من نوع `List` أو `String` يُستبدل بـ `{}`، فيُبلَّغ， المستهلك كـ «نجاح» بجسم فارغ. مثال ملموس: `eld_daily_logs_backend.dart:41` يحوّل `List` إلى `{'data': data}` — لكن `eld_dvir_backend.dart:34` يفعل الشيء نفسه. هذا يعني أن **`RawJson` لا يحمل أي ضمان شكل**، وهو ما جعل BACK-008 ممكنًا.
- التوصية: مصدر مشترك `coerceToMap` (BACK-015) +، الأهم، **استبدال `RawJson` بنوع مُحاط** (BACK-001).

### D.6 — ترتيب الإصلاح المقترح (حسب الأثر ÷ الجهد)
1. **نقل DTOات إلى `contracts/dto/`** → يحل BACK-004 + BACK-035 + يزيح جزءًا من BACK-002. (جهد صغير، أثر معماري كبير.)
2. **إضافة `signatureBackendProvider` أو حذف العقدة** → يحسم BACK-013 (لا ambiguitiy).
3. **حذف `BackendRegistry`** + إضافة `signature` للنطاق الصحيح + توحيد `SessionStore` → يحل BACK-027 + BACK-009.
4. **توحيد `url` في `ApiConfig`** → يحل BACK-026 + يبسّط BACK-011.
5. **حظر `RawJson` في `presentation` عبر lint** → يمنع توسّع BACK-001 قبل إصلاحه جذريًا.
6. **اختبار تناظر آلي + تغيير `throw` إلى `err`** → يحل BACK-020 ويحوّل الرقم في القسم C إلى مؤشر أداء مُراقَب.
7. **نقل `RulesScreenModel` إلى `domain`** + `SessionStore` → BACK-002.
8. **التحقق من `anchor()` + opt-out للمسارات الخارجية** → BACK-033 (الأمان، لكنه أقل انتشارًا).

---

## E. قائمة شاملة بالملفات التي قُرئت (إثبات التغطية)

**عدد الملفات: 66/66 — تغطية 100%.**
الأرقام: `N` = إجمالي الأسطر، `M` = الأسطر غير الفارغة.

### `lib/backend/adapters/eld_engine/` (24 ملفًا)
| # | المسار | N | M |
|---|---|---|---|
| 1 | `lib/backend/adapters/eld_engine/eld_engine_adapter.dart` | 118 | 97 |
| 2 | `lib/backend/adapters/eld_engine/mappers/dot_inspection_mapper.dart` | 151 | 135 |
| 3 | `lib/backend/adapters/eld_engine/mappers/hardware_mapper.dart` | 27 | 23 |
| 4 | `lib/backend/adapters/eld_engine/mappers/json_primitives.dart` | 72 | 64 |
| 5 | `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart` | 33 | 32 |
| 6 | `lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart` | 215 | 188 |
| 7 | `lib/backend/adapters/eld_engine/models/certify_dto.dart` | 50 | 45 |
| 8 | `lib/backend/adapters/eld_engine/models/dvir_dto.dart` | 432 | 401 |
| 9 | `lib/backend/adapters/eld_engine/models/readiness_dto.dart` | 86 | 81 |
| 10 | `lib/backend/adapters/eld_engine/models/rules_screen_dto.dart` | 103 | 94 |
| 11 | `lib/backend/adapters/eld_engine/models/rules_screen_options.dart` | 29 | 29 |
| 12 | `lib/backend/adapters/eld_engine/sub/eld_account_backend.dart` | 81 | 72 |
| 13 | `lib/backend/adapters/eld_engine/sub/eld_auth_backend.dart` | 200 | 183 |
| 14 | `lib/backend/adapters/eld_engine/sub/eld_daily_logs_backend.dart` | 162 | 149 |
| 15 | `lib/backend/adapters/eld_engine/sub/eld_driver_session_backend.dart` | 92 | 85 |
| 16 | `lib/backend/adapters/eld_engine/sub/eld_duty_status_backend.dart` | 89 | 82 |
| 17 | `lib/backend/adapters/eld_engine/sub/eld_dvir_backend.dart` | 138 | 124 |
| 18 | `lib/backend/adapters/eld_engine/sub/eld_hardware_backend.dart` | 114 | 101 |
| 19 | `lib/backend/adapters/eld_engine/sub/eld_inspection_backend.dart` | 195 | 182 |
| 20 | `lib/backend/adapters/eld_engine/sub/eld_rules_screen_backend.dart` | 51 | 46 |
| 21 | `lib/backend/adapters/eld_engine/sub/eld_signature_backend.dart` | 34 | 31 |
| 22 | `lib/backend/adapters/eld_engine/sub/eld_status_dashboard_backend.dart` | 126 | 119 |
| 23 | `lib/backend/adapters/eld_engine/sub/eld_unidentified_events_backend.dart` | 83 | 75 |
| 24 | `lib/backend/adapters/eld_engine/sub/eld_vehicle_backend.dart` | 47 | 42 |

### `lib/backend/adapters/mock/` (15 ملفًا)
| # | المسار | N | M |
|---|---|---|---|
| 25 | `lib/backend/adapters/mock/mock_adapter.dart` | 109 | 87 |
| 26 | `lib/backend/adapters/mock/fixtures/account_fixtures.dart` | 65 | 63 |
| 27 | `lib/backend/adapters/mock/sub/mock_account_backend.dart` | 30 | 27 |
| 28 | `lib/backend/adapters/mock/sub/mock_auth_backend.dart` | 51 | 46 |
| 29 | `lib/backend/adapters/mock/sub/mock_daily_logs_backend.dart` | 131 | 119 |
| 30 | `lib/backend/adapters/mock/sub/mock_driver_session_backend.dart` | 44 | 38 |
| 31 | `lib/backend/adapters/mock/sub/mock_duty_status_backend.dart` | 45 | 39 |
| 32 | `lib/backend/adapters/mock/sub/mock_dvir_backend.dart` | 74 | 63 |
| 33 | `lib/backend/adapters/mock/sub/mock_hardware_backend.dart` | 70 | 63 |
| 34 | `lib/backend/adapters/mock/sub/mock_inspection_backend.dart` | 195 | 182 |
| 35 | `lib/backend/adapters/mock/sub/mock_rules_screen_backend.dart` | 72 | 68 |
| 36 | `lib/backend/adapters/mock/sub/mock_signature_backend.dart` | 49 | 41 |
| 37 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart` | 191 | 178 |
| 38 | `lib/backend/adapters/mock/sub/mock_unidentified_events_backend.dart` | 39 | 35 |
| 39 | `lib/backend/adapters/mock/sub/mock_vehicle_backend.dart` | 21 | 17 |

### `lib/backend/contracts/` (15 ملفًا)
| # | المسار | N | M |
|---|---|---|---|
| 40 | `lib/backend/contracts/account_backend.dart` | 17 | 15 |
| 41 | `lib/backend/contracts/auth_backend.dart` | 29 | 25 |
| 42 | `lib/backend/contracts/contract_enums.dart` | 51 | 41 |
| 43 | `lib/backend/contracts/daily_logs_backend.dart` | 72 | 61 |
| 44 | `lib/backend/contracts/driver_session_backend.dart` | 31 | 25 |
| 45 | `lib/backend/contracts/duty_status_backend.dart` | 35 | 30 |
| 46 | `lib/backend/contracts/dvir_backend.dart` | 50 | 39 |
| 47 | `lib/backend/contracts/hardware_backend.dart` | 37 | 31 |
| 48 | `lib/backend/contracts/inspection_backend.dart` | 65 | 56 |
| 49 | `lib/backend/contracts/raw_json.dart` | 10 | 9 |
| 50 | `lib/backend/contracts/rules_screen_backend.dart` | 15 | 13 |
| 51 | `lib/backend/contracts/signature_backend.dart` | 13 | 12 |
| 52 | `lib/backend/contracts/status_dashboard_backend.dart` | 20 | 17 |
| 53 | `lib/backend/contracts/unidentified_events_backend.dart` | 27 | 24 |
| 54 | `lib/backend/contracts/vehicle_backend.dart` | 12 | 9 |

### `lib/backend/core/` (4 ملفات)
| # | المسار | N | M |
|---|---|---|---|
| 55 | `lib/backend/core/backend_adapter.dart` | 61 | 42 |
| 56 | `lib/backend/core/backend_identity.dart` | 94 | 81 |
| 57 | `lib/backend/core/backend_kind.dart` | 19 | 17 |
| 58 | `lib/backend/core/backend_registry.dart` | 129 | 111 |

### `lib/backend/http/` (6 ملفات)
| # | المسار | N | M |
|---|---|---|---|
| 59 | `lib/backend/http/api_config.dart` | 7 | 6 |
| 60 | `lib/backend/http/api_response.dart` | 7 | 6 |
| 61 | `lib/backend/http/eld_endpoints.dart` | 150 | 137 |
| 62 | `lib/backend/http/interceptors/auth_interceptor.dart` | 144 | 130 |
| 63 | `lib/backend/http/interceptors/request_logger.dart` | 134 | 124 |
| 64 | `lib/backend/http/interceptors/time_drift_interceptor.dart` | 67 | 57 |

### `lib/backend/providers/` (2 ملفان)
| # | المسار | N | M |
|---|---|---|---|
| 65 | `lib/backend/providers/backend_network_providers.dart` | 82 | 70 |
| 66 | `lib/backend/providers/backend_providers.dart` | 117 | 99 |

**المجموع: 66 ملفًا.**

### ملفات خارج النطاق قُرئت للتحقق من السياق (قراءة فقط)
| المسار | سبب القراءة |
|---|---|
| `lib/core/network/api_config.dart` | مقارنة ازدواج الإعداد مع `lib/backend/http/api_config.dart` (BACK-026، BACK-028) |
| `lib/core/network/api_client.dart` (جزئي) | فهم `expectedOwnerDriverId` و`ApiResponse` و`rawBody` المشار إليها في العقود |
| `lib/core/time/trusted_time_provider.dart` | التحقق من سلسلة الثقة التي يخدمها `TimeDriftInterceptor` (BACK-033) |
| `lib/core/utils/logger.dart` | التحقق من أن `AppLogger.error` يُكتب في الإنتاج (BACK-032) |
| `lib/core/di/app_providers.dart` | تتبّع `authBackendProvider` في جذر التكوين (BACK-013) |
| `analysis_options.yaml` | التحقق من عدم وجود lint معماري يفرض `ignore_architecture` (BACK-003) |
| `lib/features/dvir/data/repositories/dvir_repository_impl.dart` (جزئي) | التحقق من استهلاك `DvirDto` وشكل `rawJson['data']` (BACK-007، BACK-008) |
| `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` (استخراج) | إثبات انقلاب طبقة domain → backend (BACK-001) |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` (جزئي) | إثبات استهلاك مفاتيح `RawJson` الخام (BACK-010) |
| `lib/features/account/application/usecases/update_rules_use_case.dart` (جزئي) | إثبات `throw` داخل Provider body (BACK-036) |
| `lib/features/connection/presentation/providers/hardware_status_provider.dart` | إثبات تسريب `RawJson` إلى presentation (BACK-001، BACK-023) |
| `lib/features/logs/presentation/providers/unidentified_events_provider.dart` (جزئي) | إثبات استدعاء presentation للعقد مباشرة (BACK-023) |

### ملاحظات منهجية
- **لم يُعدَّل أي ملف تحت `lib/`.** الإجراء الوحيد المُنفَّذ هو `flutter analyze lib/backend` (قراءة فقط).
- **لم يُستدعَ `custom_lint` ولا أي أداة تحليل معماري** — لا يوجد في المشروع (`analysis_options.yaml` لا يشير إلى أي حزمة إضافية).
- **البحث النصي** تم عبر أداة `grep` المدمجة على `lib/` بالكامل، وليس على مجلد `lib/backend` فقط، لمنع تفويت الحواف.
- **كل رقم سطر في هذا التقرير** مأخوذ من قراءة الملف نفسه، وكل مقتطف كود منسوخ حرفيًا من الملف المشار إليه.

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


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

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


--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-008: `app_theme_provider.dart` يحمل ترحيل بيانات من `SharedPreferences` ووسطي تخزين
- Severity: **MODERATE**
- Category: Misplaced responsibility / Legacy data migration in presentation state
- Location `lib/core/theme/app_theme_provider.dart:3-4`, `:20`, `:22-40`
- Evidence code block:
```dart
 1: import 'package:flutter/material.dart';
 2: import 'package:flutter_riverpod/flutter_riverpod.dart';
 3: import 'package:shared_preferences/shared_preferences.dart';
 4: import '../services/local_storage_service.dart';
```
```dart
20:   static const String _oldThemeKey = 'theme_mode';
21:
22:   Future<void> _loadThemeMode() async {
23:     // ترحيل من SharedPreferences القديم.
24:     final oldPrefs = await SharedPreferences.getInstance();
25:     if (oldPrefs.containsKey(_oldThemeKey)) {
26:       final oldIndex = oldPrefs.getInt(_oldThemeKey);
27:       if (oldIndex != null &&
28:           oldIndex >= 0 &&
29:           oldIndex < ThemeMode.values.length) {
30:         await _storage.setTheme(ThemeMode.values[oldIndex].name);
31:       }
32:       await oldPrefs.remove(_oldThemeKey);
33:     }
```
- Current behavior: صنف **حالة ثيم** يقوم بثلاثة أعمال: (أ) قراءة `ThemeMode`، (ب) **ترحيل بيانات من مستودع قديم إلى آخر**، (ج) **التعامل مع محرك تخزين ثانٍ مباشرة** عبر `SharedPreferences.getInstance()` في `:24`، رغم وجود `LocalStorageService` كمنفذ وحيد. كما يستخدم `StateNotifier` (واجهة Riverpod قديمة) بينما يستخدم المشروع `Notifier` في مواضع أخرى.
- Why problematic:
  1. **مسؤولية ترحيل بيانات** داخل طبقة حالة في `core/theme`؛ لا مكانها هنا.
  2. **اعتماد مزدوج على التخزين**: `SharedPreferences` (إضافة خارجية) + `LocalStorageService`. دورة حياة الإضافة не تُدار في هذا الملف.
  3. **`_loadThemeMode()` بلا حارس**: تُستدعى من المُنشئ (`:17`)، و`ThemeMode.values.firstWhere` في `:36-39` يكتب `state` قبل اكتمال التهيئة الأولى.
- Violated principle: Single Responsibility / Explicit dependency — لا استدعاء إضافة خارجية مباشرة من حامل حالة.
- Current owner: `lib/core/theme/app_theme_provider.dart`
- Correct owner: `lib/core/services/local_storage_service.dart` (عملية الترحيل) أو `lib/app/app_initializer.dart` (خطوة تهيئة).
- Consequences: اختبارات `ThemeModeNotifier` تتطلب محاكاة `SharedPreferences`؛ بقاء كود ترحيل عتيق في مسار حرج؛ ازدواج محركات تخزين.
- Recommended correction: انقل منطق الترحيل إلى `LocalStorageService.migrateLegacyTheme()` واستدعِه في `app_initializer`؛ واحذف الاستيراد المباشر لـ`shared_preferences`؛ وانتقل إلى `Notifier`.
- Related files: `lib/core/services/local_storage_service.dart`, `lib/app/app_initializer.dart`, `lib/app.dart:66,95-97`, `lib/main.dart:40-46`
- Confidence: **CONFIRMED** (تعدد المسؤوليات) / **POTENTIAL** (خطورة سلوك `firstWhere` عند تغيّر تسمية القيمة)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-003: قاعدة عمل §396.13 داخل `State` في طبقة presentation
- **Severity:** High
- **Category:** Business Logic in Presentation
- **Location:** `lib/features/dvir/presentation/providers/dvir_provider.dart:45-57`
- **Evidence:**
```dart
  DvirReport? previousToReview(String vehicleId) {
    if (previousLookupDone && !previousLookupFailed && previousVehicleId == vehicleId) {
      final p = previousDvir;
      return (p != null && p.nextDriverReviewed != true) ? p : null;
    }
    return reports
        .where((r) => r.vehicleId == vehicleId)
        .cast<DvirReport?>()
        .firstWhere(
          (r) => r!.nextDriverReviewed != true,
          orElse: () => null,
        );
  }
```
- **Current behavior:** **قاعدة قانونية** (من هو التقرير المعلَّق على مراجعة §396.13، وأولوية مصدر `pre-trip` على القائمة) مُنفَّذة كطريقة على class الحالة داخل مجلد providers.
- **Why problematic:** (أ) لا يمكن اختبارها إلا عبر Riverpod container. (ب) حالتها (`previousLookupDone` / `previousLookupFailed` / `previousVehicleId`) جزء من `DvirState` فتُعاد تقييمها في كل `copyWith`. (ج) القاعدة بلا use-case خاص بها.
- **Violated principle:** Domain Model، SRP.
- **Current owner:** `DvirState` (presentation)
- **Correct owner:** use-case نقي في `dvir/domain/usecases/` يعيد `DvirReport?` من `(DvirReport? fromEndpoint, List<DvirReport> list, LookupOutcome)`.
- **Consequences:** لا ضمان اتساق بين الواجهة والتطبيقات الأخرى (مثل reporting) لنفس القاعدة.
- **Recommended correction:** استخراج `previousToReview` إلى دالة pure top-level في domain، وتبقى `DvirState` حاوية بيانات فقط.
- **Related files:** `dvir_form_page.dart:485-487` (المستهلك الوحيد)
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
### ISSUE DST-015: قاعدة PIN ميتة + ثابت عمل `days: 8` في presentation
- **Severity:** Low
- **Category:** Dead Code / Business Constants in Presentation
- **Location:** `lib/features/inspection/presentation/providers/inspection_provider.dart:19-24` و `:226`
- **Evidence:**
```dart
/// قاعدة رمز التفتيش (SRS 7.5): أربعة أرقام بالضبط — واحدة للحوارين
/// (الإنشاء والخروج)، نقية وقابلة للاختبار بلا widget.
bool isValidInspectionPin(String pin) {
  final value = pin.trim();
  return value.length == 4 && int.tryParse(value) != null;
}
```
```dart
// inspection_provider.dart:226
    final cycleResult = await _repository.getCycle(driverId: driver, days: 8);
```
- **Current behavior:** (أ) دالة قاعدة أعمال **غير مستخدمة** — بحث شامل على `lib/` لم يجد أي استدعاء لـ `isValidInspectionPin`. (ب) ثابت `days: 8` (نافذة 8 أيام، 49 CFR §395.8(d)) مكرَّر في `inspection_provider.dart:226` و `dot_inspection_providers.dart:57`.
- **Why problematic:** قاعدة ميتة توحي بأنها مُطبَّقة؛ وتعديل نافذة الـ days يستلزم تعديل موضعين في presentation.
- **Violated principle:** Dead Code، Business Constants Placement.
- **Current owner:** ملف providers.
- **Correct owner:** `inspection/domain/dot_inspection_rules.dart` مع `kDotCycleDays = 8`.
- **Consequences:** مطوّر قد يضيف تحقق PIN في presentation معتقداً أنه مُفعّل.
- **Recommended correction:** نقل القاعدة والثابت إلى domain؛ إما تفعيل القاعدة أو حذفها.
- **Related files:** `dot_inspection_providers.dart:57`, `inspection_start_view.dart:53-61`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-017: اعتماد محقون غير مستخدم في Provider التتبع
- **Severity:** Low
- **Category:** Dead Dependency
- **Location:** `lib/features/dvir/presentation/providers/dvir_provider.dart:96` و `:117-125`
- **Evidence:**
```dart
  final storageService = ref.watch(trackingConfigStorageProvider);
  final selectedVehicle = ref.watch(vehicleProvider).selectedVehicle;
```
```dart
  DvirNotifier({
    required DvirRepository repository,
    required TrackingConfigStorageService storageService,
    String? vehicleId,
  })  : _repository = repository,
        _vehicleId = vehicleId,
```
- **Current behavior:** `TrackingConfigStorageService` يُقرأ ويُمرَّر إلى الـ Notifier ثم **لا يُخزَّن ولا يُستخدم إطلاقاً** — لا حقل له ولا مرجع في جسم الـ class.
- **Why problematic:** اعتماد زائد يوحي بارتباط غير موجود بين DVIR وتخزين إعدادات التتبع، ويصعّب الاختبار بتزويد خدمة غير مستعملة.
- **Violated principle:** Dead Code / Undeclared Effective Dependency.
- **Current owner:** `dvirProvider` + `DvirNotifier`
- **Correct owner:** — (يُحذف)
- **Consequences:** `DvirNotifier` غير قابل للاختبار دون تزويده بخدمة لا يستخدمها.
- **Recommended correction:** حذف السطرين.
- **Related files:** `lib/core/services/tracking_config_storage_service.dart`
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
### ISSUE DST-023: أصناف Mock داخل كود الإنتاج
- **Severity:** Medium
- **Category:** Test Code in Production / Environment Switching
- **Location:** `lib/features/tracking/domain/usecases/tracking_event_processor.dart:48-78`، `lib/features/tracking/data/datasources/live_tracking_data_source.dart:24-98`، `lib/features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart:3`، `lib/features/sync/data/providers/sync_providers.dart:42-49`
- **Evidence:**
```dart
// tracking_event_processor.dart:47-56  ← داخل domain/usecases
  // --- Mock Support للمحافظة على التوافق مع وضع التطوير القديم ---
  void _startMockProcessing() {
    // محاكاة الاتصال الناجح في وضع Mock
    _connectionStatusController.add(ConnectionStatus.connected);

    double mockSpeed = 0.0;
    double mockLat = 24.7136;
    double mockLon = 46.6753;

    _mockTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      mockSpeed = (mockSpeed < 60.0) ? mockSpeed + 5.0 : 60.0;
```
  ومعه في نفس الدالة (سطر 63-70):
```dart
      _eldEventsController.add(EldEvent(
        timestamp: now,
        speedMph: mockSpeed,
        speedDurationSeconds: 5,
        odometerMiles: null,
        engineHours: null,
        fromEcm: true, // مهم جداً: جعل محرك HOS يعتقد أن هذه الأحداث حقيقية لاختبار التحويل للقيادة
      ));
```
- **Current behavior:** **أربع** شُعَب بيانات وهمية داخل `lib/`: مولّد في الـ **domain usecase**، مولّد ثانٍ في data datasource، mock client في traccar_sdk، وmock dispatcher في providers. المولّدان **يتكرران** نفس المنطق (مؤقّت 5 ثوانٍ + إحداثيات مثبتة).
- **Why problematic:** (أ) **domain layer تحتوي `Timer.periodic`** — use-case كان يجب أن يكون نقياً. (ب) **خطر سلامة حقيقي**: المولّد يُصدر `fromEcm: true` أي أن محرك HOS يعتبرها **قيادة حقيقية** (كما يصرّح تعليق السطر 69). (ج) mockان متطابقان يمكن أن يُشغَّلا معاً.
- **Violated principle:** Layer Purity (domain)، Environment Configuration.
- **Current owner:** 4 ملفات إنتاجية.
- **Correct owner:** `test/` مع `ProviderScope` overrides في اختبارات التكامل فقط.
- **Consequences:** في أي مسار يفشل، **بيانات GPS وهمية** تدخل سجلات HOS كـ driving فعلي — مخالفة FMCSA مباشرة.
- **Recommended correction:** نقل جميع الأصناف إلى `test/helpers/`؛ الإنتاج يعتمد على `TraccarNativeClientImpl` وحده.
- **Related files:** `core/events/eld_events_provider.dart:12` (المستهلك الفعلي)
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-029: مزوّدات Riverpod موزّعة على أربع طبقات في الميزة نفسها
- **Severity:** Medium
- **Category:** Composition Root Placement
- **Location:** `lib/features/tracking/data/datasources/live_tracking_data_source.dart:129`، `lib/features/tracking/data/services/tracking_service.dart:200`، `lib/features/tracking/presentation/providers/tracking_providers.dart:10`
- **Evidence:**
```dart
// live_tracking_data_source.dart:129-136  ← داخل data/datasources
final liveTrackingDataSourceProvider = Provider<LiveTrackingDataSource>((ref) {
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    final dataSource = MockLiveTrackingDataSource();
    dataSource.start();
    ref.onDispose(() {
      dataSource.dispose();
    });
    return dataSource;
```
```dart
// tracking_providers.dart:151-157  (data/datasources)
    // Start processing (starts native tracking)
    dataSource.start();
```
- **Current behavior:** أربعة مواقع لـ Riverpod providers في نفس الميزة: `data/datasources/`, `data/services/`, `data/providers/`, `presentation/providers/`.
- **Why problematic:** (أ) **DI خارج composition root**: `liveTrackingDataSourceProvider` يُستهلك من `core/events/eld_events_provider.dart:12` ⇒ `core` يعتمد على data feature (DST-030). (ب) `Provider` **بدون `autoDispose`** ⇒ حي طوال عمر التطبيق ويبدأ التتبع تلقائياً عند أول watch. (ج) `dataSource.start()` غير-awaited في جسم المزوّد ⇒ استثناء غير ملتقَط.
- **Violated principle:** Composition Root, Layer Direction.
- **Current owner:** 4 ملفات.
- **Correct owner:** `data/providers/tracking_providers.dart` **وحده**، أو `app/` للـ cross-feature.
- **Consequences:** فشل بدء التتبع في provider غير مُبلَّغ عنه.
- **Recommended correction:** نقل المزوّدات إلى `data/providers/tracking_providers.dart`؛ إضافة `.autoDispose` حيث يلزم؛ معالجة خطأ `start()`.
- **Related files:** `core/events/eld_events_provider.dart:12,17`, `tracking/presentation/providers/tracking_providers.dart:10`
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
### ISSUE DST-037: مزوّدان لنفس الخدمة — تجاوز `app_initializer` لا يسري
- **Severity:** High
- **Category:** DI Duplication / Dead Override
- **Location:** `lib/features/tracking/data/services/tracking_service.dart:200` مقابل `lib/features/tracking/data/providers/tracking_providers.dart:22`
- **Evidence:**
```dart
// tracking_service.dart:199-204
/// مزود خدمة التتبع
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final storage = ref.watch(localStorageProvider);
  final tracker = ref.watch(traccarNativeClientProvider);
  return TrackingService(storage: storage, tracker: tracker);
});
```
```dart
// tracking_providers.dart:21-26
/// مزود خدمة التتبع
final trackingServiceFullProvider = Provider<TrackingService>((ref) {
  final storage = ref.watch(localStorageProvider);
  final tracker = ref.watch(traccarNativeClientProvider);
  return TrackingService(storage: storage, tracker: tracker);
});
```
```dart
// tracking_providers.dart:40-42
final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final service = ref.watch(trackingServiceFullProvider);
```
```dart
// app/app_initializer.dart:64-69
  Future<void> _initDependentServices() async {
    trackingService = TrackingService(
      storage: localStorageService,
      tracker: TraccarNativeClientImpl(),
    );
    await trackingService.init();
```
```dart
// app/app_initializer.dart:86-95
  ProviderContainer createProviderContainer() {
    return ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(localStorageService),
        localDatabaseServiceProvider.overrideWithValue(localDatabaseService),
        trackingServiceProvider.overrideWithValue(trackingService),
```
- **Current behavior — تحقُّق الفرضية المطلوبة:** (1) `app_initializer.dart:65-69` ينشئ `TrackingService` بـ `TraccarNativeClientImpl()` **يدوياً** ويستدعي `init()`. (2) `app_initializer.dart:91` يتجاوز **`trackingServiceProvider`**. (3) لكن `trackingRepositoryProvider` (سطر 41) يستهلك **`trackingServiceFullProvider`** — **مزوّد مختلف**. ⇒ **التجاوز لا يسري على المستودع**؛ بينما `app/services/quick_actions_initializer.dart:29` يقرأ `trackingServiceProvider` (المتجاوز) فيحصل على النسخة المُهيّأة.
- **Why problematic:** نسختان من نفس البنية، أحدهما مُتجاوز في bootstrap والآخر لا. النتيجة: **الخدمة التي يهيئها التطبيق ويحقنها ليست نفس التي يستخدمها `TrackingRepositoryImpl`** ⇒ حالة `_isInitialized` و`TraccarNativeClient` مختلفان ⇒ `configure()` و`start()` على method-channel clients مختلفة.
- **Violated principle:** DRY، Composition Root Single Source، Least Surprise.
- **Current owner:** ملفان في `data/` + `app/app_initializer.dart`.
- **Correct owner:** مزوّد واحد في `data/providers/tracking_providers.dart`.
- **Consequences:** صعوبة تشخيص التتبع؛ تهيئة مزدوجة؛ سلوك غير متوقع عند أي إضافة.
- **Recommended correction:** حذف `trackingServiceProvider` من `tracking_service.dart` وتوجيه كل الاستهلاك إلى `trackingServiceFullProvider` (أو العكس: حذف `Full` وجعل `app_initializer` يتجاوز `trackingServiceProvider`).
- **Related files:** `lib/app/app_initializer.dart:65-69, 91`, `lib/app/services/quick_actions_initializer.dart:29`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-043: `Ref` محفوظ داخل Notifier وحقل عام قابل للكتابة من الخارج
- **Severity:** Low
- **Category:** Service Locator Smell / Encapsulation
- **Location:** `lib/features/tracking/presentation/providers/tracking_provider.dart:67-74`
- **Evidence:**
```dart
class TrackingNotifier extends StateNotifier<TrackingState> {
  final TrackingRepository _repository;
  final Ref ref;
  bool Function()? isDrivingChecker;
  StreamSubscription<LocationEntity>? _locationSubscription;
  Timer? _gpsTimeoutTimer;

  TrackingNotifier(this._repository, this.ref) : super(const TrackingState());
```
  ويُملأ من الخارج في `app/orchestrators/tracking_orchestrator.dart:16-22`:
```dart
  final notifier = ref.read(trackingStateProvider.notifier);

  notifier.isDrivingChecker = () {
    final hosState = ref.read(hosStatusProvider);
    return hosState is HosEngineReady &&
        hosState.update.currentStatus == DutyStatus.driving;
  };
```
- **Current behavior:** الـ notifier يحتفظ بـ `Ref` كاملاً (لالتقاط `currentVehicleSpeedProvider` في `tracking_provider.dart:155`)، و`isDrivingChecker` حقل عام قابل للكتابة يُملأ من orchestrator.
- **Why problematic:** (أ) **service locator**: الـ notifier يعرف المزوّدات بدل الاعتماد على ما يُمرَّر. (ب) **قاعدة أعمال في orchestrator**: «السائق لا يستطيع إيقاف التتبع أثناء القيادة (§395)» مُنفَّذة كـ callback مخزَّن، فتُختبر فقط عبر integration.
- **Violated principle:** Encapsulation، Dependency Inversion.
- **Current owner:** `TrackingNotifier` + `tracking_orchestrator.dart`.
- **Correct owner:** use-case في domain يقبل `isDriving` كمدخل، أو `ref.keepAlive()` مع مزوّد `isDrivingProvider` محقون.
- **Consequences:** `TrackingNotifier` غير قابل للاختبار دون container؛ سلوك مرتبط بترتيب التهيئة.
- **Recommended correction:** تمرير `isDrivingProvider` كمُعامل للـ Notifier بدل الحقل القابل للكتابة؛-roll استبدال `Ref` المحفوظ بمزوّد السرعة كمُعامل أو `Ref` للقراءة فقط.
- **Related files:** `app/orchestrators/tracking_orchestrator.dart:16-22, 97-109`, `tracking/presentation/providers/tracking_provider.dart:155, 173-180`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-045: قاعدة اختيار مركبة مكرَّرة يدوياً في presentation مع دالة domain ميتة
- **Severity:** Medium
- **Category:** Duplicated Business Rule / Dead Domain Code
- **Location:** `lib/features/vehicle/presentation/providers/vehicle_provider.dart:228-245` مقابل `lib/features/vehicle/domain/vehicle_selection.dart:29-48`
- **Evidence:**
```dart
// vehicle_selection.dart:29-48  (domain — لا يُستدعى من أي مكان في lib/)
VehicleOperateRefusal? refuseVehicleOperate({
  required double? speedMps,
  required double thresholdKmh,
  required String? uniqueId,
}) {
  if (!thresholdKmh.isFinite || thresholdKmh <= 0) {
    return VehicleOperateRefusal.thresholdMissing;
  }
  if (speedMps == null || !speedMps.isFinite) {
    return VehicleOperateRefusal.motionUnknown;
  }
  if (speedMps * 3.6 >= thresholdKmh) {
    return VehicleOperateRefusal.vehicleMoving;
  }
  final id = uniqueId?.trim() ?? '';
  if (id.isEmpty || id == 'unknown' || id == 'No Vehicle') {
    return VehicleOperateRefusal.identifierMissing;
  }
  return null;
}
```
```dart
// vehicle_provider.dart:228-245  (presentation — إعادة تنفيذ يدوية)
    // SRS 9.4: المركبة قيد الحركة فعلياً (تيار موقع حي) — رفض فوري.
    if (trackingLive && speedMps != null && speedMps * 3.6 >= thresholdKmh) {
      state = state.copyWith(isLoading: false, error: 'vehicleMoving');
      return;
    }

    // SRS 9.3: حارس التبديل يعمل فقط حين يكون تيار الموقع حياً —
    // تتبع مغلق يعني لا دليل قيادة أصلاً؛ الاختيار هو بدء الجلسة الجديدة
    // والتحقق القانوني يتكفل به الخادم عند connectSession.
    final hasActiveSession =
        state.vehicles.any((v) => v.activeForCurrentDriver == true) ||
        (state.selectedVehicle != null &&
            state.selectedVehicle?.id != 'No Vehicle');

    if (hasActiveSession && trackingLive && speedMps == null) {
      state = state.copyWith(isLoading: false, error: 'motionUnknown');
      return;
    }
```
- **Current behavior:** `VehicleOperateRefusal` و `refuseVehicleOperate` **معزوفان في domain وم-touching by any code في `lib/`** (بحث شامل على المشروع). `VehicleNotifier.selectVehicle` يعيد تنفيذ القاعدتين **بنصوص خطأ حرفية** `'vehicleMoving'` و `'motionUnknown'` و `'No Vehicle'`.
- **Why problematic:** (أ) **دالة domain ميتة** بينما presentation يكرّر منطقها — بالضبط الحالة التي يفحصها التدقيق. (ب) **البدلالات تختلف**: domain يفحص `thresholdKmh.isFinite` و`uniqueId`؛ presentation **لا يفحصهما إطلاقاً** ⇒ `thresholdKmh` غير منتهٍ يتجاوز الحارس. (ج) sentinel `'No Vehicle'` مطابق حرفياً في presentation (DST-012 sibling).
- **Violated principle:** DRY， Dead Code، Single Source of Truth.
- **Current owner:** presentation يدوياً؛ domain معزوف.
- **Correct owner:** `refuseVehicleOperate` في domain كما هي — على presentation استدعاؤها.
- **Consequences:** قاعدة أمان حارس المركبة (SRS 9.3/9.4) غير مطبَّقة بالكامل؛ تعديل domain لا يؤثر على السلوك الفعلي.
- **Recommended correction:** في `selectVehicle`: `final refusal = refuseVehicleOperate(speedMps: speedMps, thresholdKmh: thresholdKmh, uniqueId: vehicle.uniqueId ?? vehicle.id); if (refusal != null) { state = ...(refusal.name); return; }` مع إبقاء شرط `trackingLive` كشرط منفصل في presentation.
- **Related files:** `vehicle/domain/vehicle_selection.dart:3-8, 29-48`, `vehicle/presentation/pages/select_vehicle_page.dart:55-94`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-047: منطق «المركبة المحددة من الخادم» مكرَّر في domain و data و presentation
- **Severity:** Medium
- **Category:** Duplicated Business Rule
- **Location:** `lib/features/vehicle/data/repositories/vehicle_repository_impl.dart:61-68` مقابل `lib/features/vehicle/presentation/providers/vehicle_provider.dart:203-211`
- **Evidence:**
```dart
// vehicle_repository_impl.dart:60-69  (data)
  Future<Either<Failure, Vehicle?>> getSelectedVehicle() async {
    final listed = await getVehicles();
    return listed.fold((failure) => Left(failure), (vehicles) {
      for (final vehicle in vehicles) {
        if (vehicle.activeForCurrentDriver == true ||
            vehicle.selectedByServer == true) {
          return Right(vehicle);
        }
      }
      return const Right(null);
    });
  }
```
```dart
// vehicle_provider.dart:203-211  (presentation)
  Vehicle? _serverSelected(List<Vehicle> vehicles) {
    for (final vehicle in vehicles) {
      if (vehicle.activeForCurrentDriver == true ||
          vehicle.selectedByServer == true) {
        return vehicle;
      }
    }
    return null;
  }
```
- **Current behavior:** **نفس الحلقة تماماً** في data و presentation. مع ملاحظة أن `getSelectedVehicle()` في العقد **لا يُستدعى من أي مكان في `lib/`** (بحث شامل) ⇒ هو نفسه **كود ميت يكرّر** منطقاً حيّاً في presentation.
- **Why problematic:** (أ) نفس القاعدة (معيار «المركبة النشطة») في طبقتين. (ب) العقد الميت `getSelectedVehicle` يوحي بوجود مسار قراءة رسمي غير مستخدم. (ج) `VehicleState.copyWith` (سطر 50-52) بتحويل `clearSelected` له منطق غامض.
- **Violated principle:** DRY، Dead Code.
- **Current owner:** presentation (حي) + data (ميت).
- **Correct owner:** domain — `Vehicle? findServerSelected(List<Vehicle>)` في `vehicle_selection.dart`.
- **Consequences:** تعديل معيار التحديد في مكان واحد يجعل presentation ينحرف عن العقد.
- **Recommended correction:** استخراج الدالة في domain؛ `getSelectedVehicle()` في المستودع يستدعيها؛ presentation يستدعيها أيضاً.
- **Related files:** `vehicle/domain/vehicle_selection.dart`, `vehicle/domain/repositories/vehicle_repository.dart:13-14`, `vehicle/presentation/providers/vehicle_provider.dart:169-177`
- **Confidence:** **CONFIRMED**

---

## C. Cross-feature import table

| # | From → To | Path:line | ما هو المستورد | الحكم |
|---|---|---|---|---|
| 1 | DVIR → HOME | `dvir/presentation/providers/dvir_provider.dart:10` | `home/presentation/providers/dashboard_provider.dart` | **سليمة** — presentation→presentation (قراءة `vehicleId` فقط). ملاحظة: نفس الملف يستورد `trackingConfigStorageProvider` غير المستخدم (DST-017). الحكم: **مقبولة** (قراءة فقط) |
| 2 | DVIR → HOME (2) | `dvir/presentation/pages/dvir_form_page.dart:7` | نفس المزوّد | **مقبولة** |
| 3 | DVIR → HOME (3) | `dvir/presentation/widgets/dvir_form_sections.dart:9` | `DashboardData` | **مقبولة** |
| 4 | DVIR → SYNC | `dvir/data/repositories/dvir_repository_impl.dart:3` | `sync/domain/entities/pending_event.dart` | **سليمة** — data→**domain** الميزة الأخرى (عقد مشترك) |
| 5 | DVIR → SYNC (2) | `dvir/data/repositories/dvir_repository_impl.dart:4` | `sync/domain/repositories/offline_queue.dart` | **سليمة** — عقد Port |
| 6 | DVIR → SYNC (3) | `dvir/data/providers/dvir_repository_providers.dart:5` | `sync/data/providers/sync_providers.dart` | **مقبولة** — data→data لتركيب `offlineQueueProvider` (DI). لكن `sync_providers.dart` نفسه يحمل انحرافاته (DST-018) |
| 7 | DVIR → ACCOUNT | `dvir/presentation/pages/dvir_form_page.dart:8` | `account/presentation/providers/account_provider.dart` | **مقبولة** — presentation→presentation لقراءة `carrier` |
| 8 | DVIR → VEHICLE | `dvir/presentation/providers/dvir_provider.dart:11` | `vehicle/presentation/providers/vehicle_provider.dart` | **مقبولة** |
| 9 | DVIR → VEHICLE (2) | `dvir/presentation/pages/dvir_form_page.dart:10` | نفس المزوّد | **مقبولة** |
| 10 | DVIR → VEHICLE (3) | `dvir/presentation/pages/dvir_form_page.dart:32` | `vehicle/domain/entities/vehicle.dart` | **سليمة** — presentation→**domain** |
| 11 | DVIR → AUTH | `dvir/presentation/pages/dvir_form_page.dart:12` | `auth/presentation/providers/auth_state_provider.dart` | **مقبولة** — قراءة `currentDriverIdProvider` |
| 12 | DVIR → TRACKING | `dvir/presentation/pages/dvir_form_page.dart:9` | `tracking/presentation/providers/tracking_provider.dart` | **مقبولة** — قراءة `trackingStateProvider.currentLocation`؛ لكن **تركيب نص إحداثيات في Widget** (`dvir_form_page.dart:344-352`, `596-605`) = business formatting in presentation |
| 13 | DVIR → LOGS | `dvir/presentation/pages/dvir_form_page.dart:30-31` | `logs/presentation/widgets/vehicle_picker_dialog.dart`, `logs/presentation/pages/trailers_page.dart` | **مقبولة** — Widgets مشتركة بين الشاشات |
| 14 | INSPECTION → LOGS | `inspection/presentation/pages/send_logs_page.dart:10-11` | `logs/domain/entities/audit_entry.dart` + `logs/data/providers/log_repository_providers.dart` | **انحراف مؤكَّد** — presentation يستورد **data layer** لميزة أخرى (DST-021) |
| 15 | INSPECTION → SYNC | `inspection/data/repositories/inspection_repository_impl.dart:12` | `sync/domain/entities/pending_event.dart` | **مقبولة** — data→domain؛ لكن **تسييل حدث داخل مستودع** (use-case في data) |
| 16 | INSPECTION → SYNC (2) | `inspection/data/repositories/inspection_repository_impl.dart:13` | `sync/domain/usecases/sync_engine.dart` | **مقبولة** — استخدام use-case؛ لكن **بوسيط اختياري nullable** |
| 17 | INSPECTION → SYNC (3) | `inspection/data/providers/inspection_repository_providers.dart:4` | `sync/data/providers/sync_providers.dart` | **مقبولة** (DI) |
| 18 | INSPECTION → AUTH | `inspection/presentation/providers/inspection_provider.dart:7` | `auth/presentation/providers/auth_state_provider.dart` | **مقبولة** |
| 19 | INSPECTION → AUTH (2) | `inspection/presentation/providers/dot_inspection_providers.dart:5` | نفس المزوّد | **مقبولة** |
| 20 | INSPECTION → AUTH (3) | `inspection/presentation/pages/send_logs_page.dart:9` | نفس المزوّد | **مقبولة** |
| 21 | INSPECTION → LOGS (2) | `inspection/presentation/pages/send_logs_page.dart:10` | `audit_entry.dart` (domain) | **مقبولة** — كيان مشترك؛ لكن الإنشاء في Widget |
| 22 | SYNC → TRACKING | `sync/data/providers/sync_providers.dart:13` | `tracking/domain/entities/connection_status.dart` | **سليمة** — data→**domain** الميزة الأخرى (عقد مشترك) |
| 23 | SYNC → TRACKING (2) | `sync/data/providers/sync_providers.dart:12` | `core/events/eld_events_provider.dart` → يستورد بدوره `tracking/data/datasources/live_tracking_data_source.dart` | **انحراف مؤكَّد** — data→core→**data feature** (انقلاب اتجاه، DST-030) |
| 24 | SYNC → LOGS | `sync/data/providers/sync_providers.dart:8` | `logs/data/datasources/log_local_data_source.dart` مع `// ignore_architecture` | **انحراف مؤكَّد** — data→data لـ feature أخرى مع suppression (DST-018) |
| 25 | SYNC → AUTH | `sync/data/providers/sync_providers.dart:7` | `auth/presentation/providers/auth_state_provider.dart` مع `// ignore_architecture` | **انحراف مؤكَّد** — data→**presentation** (DST-018) |
| 26 | SYNC → DVIR (عكسي) | `sync/data/repositories/traccar_remote_event_dispatcher.dart:12` | `backend/contracts/dvir_backend.dart` | **سليمة** — data→عقد backend مشترك (shared kernel)، لا تنفيذ feature |
| 27 | SYNC → INSPECTION (عكسي) | `sync/data/repositories/traccar_remote_event_dispatcher.dart:13` | `backend/contracts/inspection_backend.dart` | **سليمة** — عقد backend مشترك |
| 28 | SYNC → AUTH (2) | `sync/data/repositories/traccar_remote_event_dispatcher.dart:16` | `auth/data/datasources/auth_local_data_source.dart` | **مقبولة** — data→data (عقد مخزن)، لكن `getSession()` قراءة مباشرة بدل بوابة |
| 29 | TRACKING → (core) | `sync/data/providers/sync_providers.dart:13` | — | (مغطى في #23) |
| 30 | VEHICLE → AUTH | `vehicle/presentation/providers/vehicle_provider.dart:6` | `auth/presentation/providers/auth_state_provider.dart` | **مقبولة** — `ref.listen(authStateProvider)`Implementing سياج الجلسة؛ **نمط ممتاز** |
| 31 | VEHICLE → HOME | `vehicle/presentation/pages/select_vehicle_page.dart:10` | `home/presentation/providers/dashboard_provider.dart` | **مقبولة** مع DST-019 |
| 32 | VEHICLE → HOME (2) | `vehicle/presentation/pages/select_vehicle_page.dart:9` | `home/presentation/widgets/eld_drawer.dart` | **سليمة** — widget مشترك |
| 33 | VEHICLE → TRACKING | `vehicle/presentation/pages/select_vehicle_page.dart:15` | `tracking/presentation/providers/tracking_provider.dart` | **مقبولة** — قراءة `currentVehicleSpeedProvider` و`trackingStateProvider.isTracking` |
| 34 | VEHICLE → HOS | `vehicle/presentation/pages/select_vehicle_page.dart:14` | `hos/presentation/providers/hos_engine_provider.dart` | **مقبولة** — قراءة `movingSpeedThresholdKmh`؛ لكن **العتبة يجب أن تأتي من domain لا presentation** |
| 35 | TRACKING → CORE | `tracking/presentation/providers/tracking_providers.dart:2` | `package:geolocator/geolocator.dart` | **مقبولة** — StreamProvider لحالة GPS؛ لكن **الاستعلام عن المنصة في presentation** (يُفترض أن يكون في data) |

**ملاحظة على الأحكام:** أربعة استثناءات **مؤكدة** (الصفوف 14، 23، 24، 25)، والباقي **مقبولة** لأن اتجاهها presentation→presentation أو data→domain مع عقد مشترك. الحافة **الأخطر** في المجموعة هي `SYNC → AUTH` (data→presentation مع suppression).

---

## D. Exhaustive list of files read (proof of coverage)

**dvir — 25 files (100%):**
1. `lib/features/dvir/data/mappers/dvir_defect_mappers.dart` (91)
2. `lib/features/dvir/data/mappers/dvir_mappers.dart` (208)
3. `lib/features/dvir/data/providers/dvir_repository_providers.dart` (17)
4. `lib/features/dvir/data/repositories/dvir_repository_impl.dart` (388)
5. `lib/features/dvir/domain/defect_enums.dart` (37)
6. `lib/features/dvir/domain/dvir_catalog.dart` (64)
7. `lib/features/dvir/domain/dvir_list_summary.dart` (33)
8. `lib/features/dvir/domain/dvir_signature.dart` (9)
9. `lib/features/dvir/domain/dvir_vehicle.dart` (8)
10. `lib/features/dvir/domain/entities/dvir_defect.dart` (73)
11. `lib/features/dvir/domain/entities/dvir_report.dart` (266)
12. `lib/features/dvir/domain/repositories/dvir_repository.dart` (43)
13. `lib/features/dvir/presentation/extensions/dvir_catalog_extensions.dart` (9)
14. `lib/features/dvir/presentation/extensions/dvir_status_extensions.dart` (37)
15. `lib/features/dvir/presentation/pages/dvir_detail_page.dart` (486)
16. `lib/features/dvir/presentation/pages/dvir_form_page.dart` (690)
17. `lib/features/dvir/presentation/pages/dvir_list_page.dart` (340)
18. `lib/features/dvir/presentation/providers/dvir_provider.dart` (325)
19. `lib/features/dvir/presentation/widgets/active_defects_section.dart` (257)
20. `lib/features/dvir/presentation/widgets/defect_card.dart` (58)
21. `lib/features/dvir/presentation/widgets/defects_modal.dart` (153)
22. `lib/features/dvir/presentation/widgets/dvir_form_components.dart` (199)
23. `lib/features/dvir/presentation/widgets/dvir_form_sections.dart` (498)
24. `lib/features/dvir/presentation/widgets/previous_dvir_review_modal.dart` (74)
25. `lib/features/dvir/presentation/widgets/status_modal.dart` (81)

**inspection — 15 files (100%):**
1. `lib/features/inspection/data/mappers/inspection_mappers.dart` (120)
2. `lib/features/inspection/data/providers/inspection_repository_providers.dart` (15)
3. `lib/features/inspection/data/repositories/inspection_repository_impl.dart` (266)
4. `lib/features/inspection/data/services/fmcsa_eld_output_generator.dart` (208)
5. `lib/features/inspection/domain/inspection_transfer.dart` (58)
6. `lib/features/inspection/domain/transfer_audit.dart` (31)
7. `lib/features/inspection/domain/repositories/inspection_repository.dart` (43)
8. `lib/features/inspection/presentation/pages/dot_inspection_page.dart` (73)
9. `lib/features/inspection/presentation/pages/inspection_active_view.dart` (145)
10. `lib/features/inspection/presentation/pages/inspection_start_view.dart` (210)
11. `lib/features/inspection/presentation/pages/send_logs_page.dart` (332)
12. `lib/features/inspection/presentation/providers/dot_inspection_providers.dart` (60)
13. `lib/features/inspection/presentation/providers/inspection_provider.dart` (367)
14. `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart` (176)
15. `lib/features/inspection/presentation/widgets/inspection_log_header_table.dart` (259)

**sync — 18 files (100%):**
1. `lib/features/sync/data/datasources/sync_local_data_source.dart` (60)
2. `lib/features/sync/data/models/sync_item_model.dart` (56)
3. `lib/features/sync/data/providers/sync_providers.dart` (148)
4. `lib/features/sync/data/repositories/memory_offline_queue.dart` (145)
5. `lib/features/sync/data/repositories/sqlite_offline_queue.dart` (382)
6. `lib/features/sync/data/repositories/sync_repository_impl.dart` (156)
7. `lib/features/sync/data/repositories/traccar_remote_event_dispatcher.dart` (322)
8. `lib/features/sync/domain/entities/dispatch_auth.dart` (19)
9. `lib/features/sync/domain/entities/event_ownership.dart` (109)
10. `lib/features/sync/domain/entities/pending_event.dart` (72)
11. `lib/features/sync/domain/entities/quarantine_record.dart` (41)
12. `lib/features/sync/domain/entities/sync_item.dart` (100)
13. `lib/features/sync/domain/repositories/offline_queue.dart` (49)
14. `lib/features/sync/domain/repositories/sync_repository.dart` (25)
15. `lib/features/sync/domain/usecases/sync_engine.dart` (226)
16. `lib/features/sync/presentation/providers/sync_engine_provider.dart` (4)
17. `lib/features/sync/presentation/providers/sync_provider.dart` (76)
18. `lib/features/sync/presentation/widgets/sync_status_indicator.dart` (46)

**tracking — 25 files (100%):**
1. `lib/features/tracking/data/datasources/live_tracking_data_source.dart` (168)
2. `lib/features/tracking/data/datasources/native_event_channel_client.dart` (164)
3. `lib/features/tracking/data/datasources/traccar_data_source.dart` (135)
4. `lib/features/tracking/data/datasources/tracking_data_source.dart` (26)
5. `lib/features/tracking/data/datasources/tracking_local_data_source.dart` (69)
6. `lib/features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart` (30)
7. `lib/features/tracking/data/datasources/traccar_sdk/traccar_api_client.dart` (19)
8. `lib/features/tracking/data/datasources/traccar_sdk/traccar_api_client_impl.dart` (131)
9. `lib/features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart` (24)
10. `lib/features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart` (79)
11. `lib/features/tracking/data/datasources/traccar_sdk/traccar_websocket_client.dart` (21)
12. `lib/features/tracking/data/datasources/traccar_sdk/traccar_websocket_client_impl.dart` (156)
13. `lib/features/tracking/data/models/location_model.dart` (59)
14. `lib/features/tracking/data/providers/tracking_providers.dart` (51)
15. `lib/features/tracking/data/repositories/tracking_repository_impl.dart` (243)
16. `lib/features/tracking/data/services/tracking_service.dart` (204)
17. `lib/features/tracking/domain/entities/connection_status.dart` (8)
18. `lib/features/tracking/domain/entities/location_entity.dart` (141)
19. `lib/features/tracking/domain/entities/native_location_event.dart` (75)
20. `lib/features/tracking/domain/entities/tracking_event.dart` (98)
21. `lib/features/tracking/domain/repositories/tracking_data_source_port.dart` (8)
22. `lib/features/tracking/domain/repositories/tracking_repository.dart` (36)
23. `lib/features/tracking/domain/usecases/tracking_event_processor.dart` (124)
24. `lib/features/tracking/presentation/providers/tracking_provider.dart` (252)
25. `lib/features/tracking/presentation/providers/tracking_providers.dart` (15)

**vehicle — 8 files (100%):**
1. `lib/features/vehicle/data/providers/vehicle_repository_providers.dart` (23)
2. `lib/features/vehicle/data/repositories/vehicle_repository_impl.dart` (81)
3. `lib/features/vehicle/domain/vehicle_selection.dart` (153)
4. `lib/features/vehicle/domain/entities/vehicle.dart` (68)
5. `lib/features/vehicle/domain/repositories/vehicle_repository.dart` (15)
6. `lib/features/vehicle/presentation/pages/select_vehicle_page.dart` (299)
7. `lib/features/vehicle/presentation/providers/vehicle_provider.dart` (254)
8. `lib/features/vehicle/presentation/widget/vehicle_card.dart` (124)

**الإجمالي: 91 ملف — تم استيعاب كل واحد.**

---

## ملخص تنفيذي

| Level | Issue IDs | Count |
|---|---|---|
| **Critical** | DST-001, DST-002 | 2 |
| **High** | DST-003, DST-005, DST-006, DST-018, DST-021, DST-025, DST-027, DST-030, DST-032, DST-035, DST-037, DST-038 | 12 |
| **Medium** | DST-004, DST-005b, DST-007, DST-008, DST-010, DST-011, DST-012, DST-013, DST-014, DST-016, DST-020, DST-021, DST-022, DST-023, DST-026, DST-028, DST-029, DST-031, DST-034, DST-035, DST-039, DST-040, DST-044, DST-045, DST-047 | 25 |
| **Low** | DST-009, DST-015, DST-017, DST-019, DST-024, DST-033, DST-041, DST-042, DST-043, DST-046 | 10 |

**أسوأ ثلاث نقاط في المجموعة:**
1. **DST-001** — اختراع `deviceId` قانوني من regex داخل Widget DVIR.
2. **DST-002** — كاش `static` في مستودع التفتيش بلا إبطال ⇒ تسريب سجلات بين جلسات السائقين.
3. **DST-035 + DST-025** — ابتلاع الأخطاء عبر ثلاث طبقات يعرض «فارغ» بينما المنصة فشلت، **مع منظومة طابور ثانية مكرَّرة لا تمثّل الإنتاج**.

**الملاحظات الإيجابية (نماذج صالحة داخل المشروع):**
- `sync/domain/repositories/offline_queue.dart` — عقد نقي بلا تسريب sqflite (نموذج مرجعي).
- `sync/domain/entities/event_ownership.dart` — استخراج ملكية pure في domain.
- `dvir/domain/entities/dvir_report.dart` — قواعد §396.11 retention و out-of-service في مكانها الصحيح.
- `vehicle/presentation/providers/vehicle_provider.dart` — سياج session + تسلسل ردود متأخر (نموذج لتعميمه على `InspectionRepositoryImpl`).
- `dvir/data/mappers/dvir_defect_mappers.dart` — mapper نقي بلا اختراع قيم.

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-07: `TrustedTimeProvider` (مستهلك محرك HOS) يُعرِّف Riverpod Provider داخل نفس الملف
- **Severity:** Medium
- **Category:** Domain Purity (transitive)
- **Location:** `lib/features/hos/domain/engine/hos_calculator.dart:2` → `lib/core/time/trusted_time_provider.dart:3-4` و `:200`
- **Evidence:**
```dart
// hos_calculator.dart:2
import '../../../../core/time/trusted_time_provider.dart';
```
```dart
// trusted_time_provider.dart:3-4
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
...
200: final trustedTimeProvider = Provider<TrustedTimeProvider>((ref) {
```
- **Current behavior:** ملف واحد يجمع الواجهة + التنفيذ + DI + `FakeTrustedTimeProvider` للاختبار.
- **Why problematic:** محرك HOS (`hos_calculator`, `hos_rules_engine`, `hos_state_machine`, `duty_status_tracker`) لا يستطيع أن يُستورد دون أن يجرّ Riverpod و SharedPreferences. أي أن «نقاء domain» موروث ومخترق.
- **Violated principle:** Dependency Rule.
- **Current owner:** `core/time/trusted_time_provider.dart` (ملف واحد بأربعة أدوار).
- **Correct owner:** الواجهة في `trusted_time_provider.dart` فقط، التنفيذ في `trusted_time_provider_impl.dart`، DI في `core/time/providers/`.
- **Consequences:** لا يمكن اختبار محرك HOS مع `FakeTrustedTimeProvider` دون تحميل Riverpod؛ اقتران غير مقصود.
- **Recommended correction:** قسّم الملف إلى ثلاثة.
- **Related files:** `lib/features/hos/domain/engine/hos_state_machine.dart:5`, `lib/features/hos/domain/engine/hos_rules_engine.dart:6`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-08: قيد طول النص ورسائل الرفض مكتوبة يدوياً داخل presentation
- **Severity:** Medium
- **Category:** Business Validation in Presentation + i18n Bypass
- **Location:** `lib/features/hos/presentation/providers/change_status_provider.dart:174`، `:182`، `:284`، `:289`؛ `lib/features/hos/presentation/pages/change_status_page.dart:149`
- **Evidence:**
```dart
173:  bool get hasValidCustomLocation =>
174:      customLocation.length >= 5 && customLocation.length <= 60;
...
182:  bool get isValid => isLocationValid && (!isAnnotationRequired || notes.length >= 4);
```
```dart
284:      return const DutyChangeEngineRefusal('Personal Conveyance is not permitted');
...
289:      return const DutyChangeEngineRefusal('Yard Move is not permitted');
```
```dart
149:                      ? 'Letters, numbers, punctuation 5 - 60 symbols are allowed.'
```
- **Current behavior:** حدود `[5..60]` و `>=4` مُشفَّرة في الـ StateNotifier، ورسائل الرفض إنجليزية صريحة تُعرض للمستخدم، ورسالة تحقق إنجليزية داخل `InputDecoration`.
- **Why problematic:** (1) نفس قاعدة «الطول 5..60» موجودة في `lib/features/inspection/domain/inspection_transfer.dart:20` — تكرار ثالث. (2) النصوص الثلاثة **غير مترجمة** بينما كل ملف يستورد `context.loc`. (3) `line 149` نص إنجليزي لا يمرّ بـ `context.loc` إطلاقاً.
- **Violated principle:** DRY + Single Localization Source.
- **Current owner:** presentation.
- **Correct owner:** `hos/domain/rules/` لقواعد الطول؛ `context.loc` للنصوص.
- **Consequences:** مستخدم عربي/إسباني يرى رسالة إنجليزية؛ تعديل القاعدة يتطلب لمس 3 ملفات.
- **Recommended correction:** نقل `hasValidCustomLocation`/`isValid` إلى `HosChangeValidation` في domain يُعيد `String? errorKey`؛ استبدال النصوص بـ `context.loc.*`.
- **Related files:** `lib/features/inspection/domain/inspection_transfer.dart:20`, `lib/features/logs/domain/daily_form_rules.dart:46-59` (نفس النمط لكن في المكان الصحيح)
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
### ISSUE HL-29: بناء حمولة الشهادة القانونية داخل presentation provider
- **Severity:** Medium
- **Category:** Business/Transport in Presentation
- **Location:** `lib/features/logs/presentation/providers/certify_log_provider.dart:173-181`
- **Evidence:**
```dart
173:    final result = await _repository.certifyLog(
174:      logId: _logId,
175:      driverId: driverId,
176:      // DateFormat is used for the API payload contract, not for UI display.
177:      logDate: DateFormat('yyyy-MM-dd').format(log.date),
178:      signatureCertificateId: 'local_drawn',
179:      signatureConfirmation: true,
180:      certifiedTrue: true,
181:    );
```
- **Current behavior:** presentation يحدد **قيمة السجل** `signatureCertificateId: 'local_drawn'` (سلسلة حرفية تعاقدية) ويثبّت `certifiedTrue: true` **دون أي تحقق من السائق**.
- **Why problematic:** (1) `certifiedTrue: true` ثابت — أي استدعاء يصبح «توثيقاً». (2) `'local_drawn'` قيمة يجب أن يعرفها الخادم؛ وضعها في presentation يعني أن أي feature آخر يرسل قيمة مختلفة. (3) `certify_tab.dart:99` يولّد `toPngBytes()` ثم لا يُرسله إطلاقاً (السطر `163` يقرّ: `// The live contract has no signature-upload path`) — **الملف المعدَّل يدّعي أنه يرسل توقيعاً مستخدماً**.
- **Violated principle:** Contract values belong to the contract owner.
- **Current owner:** presentation provider.
- **Correct owner:** `data/repositories/log_repository_impl.dart` (يُنشئ `CertifyRequestDto` في `line 440` — المكان الصحيح).
- **Consequences:** تعديل عقد التوثيق يتطلب تعديل presentation.
- **Recommended correction:** انقل `signatureCertificateId` و`certifiedTrue` إلى `LogRepositoryImpl.certifyLog`، ومرّر `hasDrawnSignature: bool` فقط.
- **Related files:** `lib/features/logs/data/repositories/log_repository_impl.dart:439-448`, `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart:99-105`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-30: `LogEvent.props` يُسقط `location` وأربع حقول من مفتاح family
- **Severity:** Medium
- **Category:** Correctness (Riverpod identity)
- **Location:** `lib/features/logs/domain/entities/daily_log.dart:248-250` مستهلَك في `lib/features/logs/presentation/providers/edit_log_form_provider.dart:55-56`
- **Evidence:**
```dart
// daily_log.dart:248-250
  @override
  List<Object?> get props =>
      [id, status, startTime, duration, location, isExpanded];
```
```dart
// edit_log_form_provider.dart:55-56
final editLogFormProvider = StateNotifierProvider.autoDispose
    .family<EditLogFormNotifier, EditLogFormState, LogEvent?>((ref, event) {
```
- **Current behavior:** `LogEvent` هو **مفتاح family**. عندما يصل التحديث من الخادم وتختلف `location` فقط — والقيمة مستثناة من `props` — deems Riverpod الكيانين متساويين ولا يعيد بناء الـ provider. لكن `location` **نعم** مُدرجة في props في السطر أعلاه.
- **ملاحظة مقدَّرة:** بعد مراجعة دقيقة — `location` **موجود** في `props`. الحقول المستثناة فعلاً: `odometer`, `engineHours`, `automatedDriving`, `editable`. الاستثناء الحاسم هو **`editable`**، وهو الحقل الذي يحدد **`خط القلم في `events_tab.dart:78-79`**:
```dart
                      onEdit: (event.automatedDriving == true ||
                              event.editable == false)
                          ? null
```
فإذا تغيّر `editable` من الخادم، deems الكيانان متساويين ⇒ لا إعادة بناء ⇒ **قلم التعديل على حدث مقفل قانونياً يبقى ظاهراً** (أو العكس).
- **Why problematic:** سعة `props` غير مكتملة بينما الكيان يُستخدم كمفتاح هوية.
- **Violated principle:** Value-object identity completeness.
- **Current owner:** `daily_log.dart:248`
- **Correct owner:** نفس الملف — إما إكمال `props`، أو تحويل family key إلى `String? eventId`.
- **Consequences:** زر تعديل على حدث لا يجوز تعديله.
- **Recommended correction:** أكمل `props`، أو اجعل family key معرّفاً صريحاً.
- **Related files:** `lib/features/logs/presentation/widgets/log_detail_tabs/events_tab.dart:78-85`
- **Confidence:** **POTENTIAL** (الأثر الخاطئ محتمل؛ لم يُشغَّل الكود)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-31: `LogsNotifier._ref` اختياري — الكتابة العابرة للميزات تتوقف بصمت
- **Severity:** Medium
- **Category:** Error Handling / Defensive nullability
- **Location:** `lib/features/logs/presentation/providers/logs_provider.dart:94` و `:162` و `:192` و `:214`
- **Evidence:**
```dart
 94:  final Ref? _ref;
...
162:      _ref?.read(dashboardDataProvider.notifier).applyServerForm(
...
192:        _ref?.read(dashboardDataProvider.notifier).applyServerForm(form);
...
214:          _ref?.read(dashboardDataProvider.notifier).applyServerForm(
```
- **Current behavior:** `LogsNotifier` يحمل `Ref` كمعامل ثالث اختياري `[this._ref]`. الموضع في `line 78` يمرّره دائماً — لكن **أي استدعاء آخر** لـ `LogsNotifier(repository, driverId)` يConstruct'd بلا `ref` فتُفوَّت 3 عمليات كتابة بصمت.
- **Why problematic:** (1) `?.` في **قاعدة بيانات** يُخفي خطأً بصمت. (2) `selectLog` هو المسار الحرج لشاشة التفاصيل — فلو فُقد المرجع فإن التبويب يعرض بيانات قديمة بلا مؤشر.
- **Violated principle:** Explicit dependencies + fail loudly.
- **Current owner:** الملف.
- **Correct owner:** نفس الملف — `final Ref _ref;` إلزامي.
- **Consequences:** صعوبة تشخيص «البيانات لا تتحدث».
- **Recommended correction:** اجعل المعامل إلزامياً، وأضف `assert(_ref != null)` في debug.
- **Related files:** `lib/features/logs/presentation/providers/logs_provider.dart:78`
- **Confidence:** **CONFIRMED** (التصميم)، **POTENTIAL** (حدوثه)

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



