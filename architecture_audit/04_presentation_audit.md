# 04 — تدقيق طبقة العرض (Presentation Layer Audit)

## نطاق التدقيق

جميع الملفات الواقعة تحت `lib/features/**/presentation/**` (pages, widgets, providers, controllers, extensions)، إضافة إلى `lib/core/widgets/**` و`lib/core/theme/**` بوصفها مكوّنات عرض مشتركة، و`lib/routes.dart` + `lib/routes/**` لتنسيق التوجيه.

**العدد: 195 ملف عرض** فُحصت كاملة (انظر `03_file_by_file_audit.md`).

## المنهجية

القاعدة المتبنّاة في هذا التدقيق: **استخدام Riverpod داخل `ConsumerWidget` ليس مخالفة معمارية**. الاستهلاك الطبيعي للمزوّدات من الواجهة هو النمط الصحيح. المخالفة تحدث عندما تُحمَّل في الـ Widget م responsibilities لا تملكها طبقة العرض:

| المسؤولية | المالك الصحيح | إن وُجدت في Widget فـ |
|---|---|---|
| استدعاء `Dio` / HTTP مباشرة | data source | مخالفة مؤكدة |
| تحليل JSON / تحويل DTO→entity | mapper في data | مخالفة مؤكدة |
| قاعدة عمل (FMCSA / HOS / DVIR) | domain أو use-case | مخالفة |
| كتابة حالة في مزوّد ميزة أخرى | coordinator في app | مخالفة |
| نصوص 사용자 غير مترجَمة | `AppLocalizations` | مخالفة |
| قراءة `AppEnvironmentConfig` | طبقة config | مخالفة |

## الخلاصة التنفيذية للعرض

أهم ما اكتُشف في التوزيع الفعلي للمسؤوليات:

**1. غياب طبقة `domain/` كاملة في ميزتين.** الميزة `connection` لا تحتوي `domain/` ولا `application/` إطلاقاً: use-case «وصلة الـ ELD» كله مكتوب داخل `eld_connection_page.dart:61-251` — النموذج، الـ notifier، المزوّد، واستدعاءات البنية التحتية (ACC/CON-001). النتيجة أن اختبار الوصلة يتطلب بناء شجرة Widget كاملة.

**2. قواعد قانونية مُنفَّذة داخل `build()`.** أوضح مثال `MainCircularTimer.build` (`lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:98-192`) الذي ينفّذ محرك حساب HOS كاملاً داخل عملية البناء — أي أن كل إعادة بناء (timer، تغيير ثيم، تغيّر shard) تُعيد الحساب.ourse الحالة-compliance تُستنتج داخل Widget لا داخل `HosRulesEngine`.

**3. Widget واحد يصنع قيمة نظامية.** `dvir_form_page.dart:463-476` يستخرج أرقاماً من **اسم المركبة** عبر `RegExp(r'\d+')` ويرسلها كـ `deviceId` رسمي في DVIR — مخالفة مباشرة صرّح نفيها نفس الفريق في `dvir_mappers.dart:119-121` («لا جسم ناقص ولا اختراع قيمة»). انظر DST-001 (CRITICAL).

**4. تجاوز حدّ الـ port في طبقة العرض.** `unidentified_events_provider.dart:97` يستدعي عقد `backend` مباشرة، و`send_logs_page.dart:126-141` يكتب سجل تدقيق عبر data layer لميزة أخرى، و`settings_page.dart:116-125` يزامن تفضيل اللغة عبر presentation لميزة ACCOUNT.

**5. اقتحام عابر للميزات من داخل Widget.** ‏`codriver_page.dart:15-18` يستورد خمسة ملفات من HOS وTRACKING لتغذية حارس واحد (COD-002)؛ و`LOGS` presentation يكتب في `HOME` presentation عبر 7 مواقع (HL-25).

**6. Widgets تشارك في دورة استيراد من 25 ملفاً.** ‏`lib/core/widgets/connection_status_indicator.dart` يستورد `lib/routes.dart`، و7 صفحات تستورد `lib/routes.dart`، بينما `lib/routes.dart` يستورد صفحات الميزات —Component واحد في `core` يُغلق دورة تعتمد على `app` (CUI-001). تفاصيلها في `09_dependency_analysis.md`.

**7. مكونات عرض سليمة — موثّق عمداً.** ‏`lib/core/widgets/eld_card.dart`, `eld_info_row.dart`, `eld_retry_view.dart`, `eld_date_paginator.dart`, `eld_events_table.dart`, `app_status_badge.dart`, `app_status_pill.dart` كلها **COMPLIANT**: تأخذ `String` فقط ولا تستورد أي نوع نطاقي ولا تحوي قواعد. الاستثناء الوحيد `eld_graph_grid.dart:330-338` الذي يثبّت رموز FMCSA وترتيب الصفوف داخل painter مشترك.

## جدول تفصيلي

في ما يلي كل ملاحظة تمس طبقة العرض مع أدلتها الكاملة.
tmp

**عدد الملاحظات في هذا القسم: 91**

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
### ISSUE AUTH-007: التحقق من المدخلات مكرَّر حرفياً بين الـ Widget والـ UseCase
- **Severity:** Low
- **Category:** Duplicated policy / DRY
- **Location:** `lib/features/auth/presentation/widgets/login_form.dart:65-74`, `:96-105` مقابل `lib/features/auth/domain/usecases/login_usecase.dart:19-29`
- **Evidence:**
```dart
// lib/features/auth/presentation/widgets/login_form.dart:69
              final identifierObj = LoginIdentifier(v);
              if (!identifierObj.isValid) {
                return context.translateErrorKey(identifierObj.errorMessage);
              }

// lib/features/auth/domain/usecases/login_usecase.dart:19
    if (!identifierObj.isValid) ...
```
- **Current behavior:** نفس القواعد مُطبَّقة مرتين بنفس الـ value objects، بنفس ترتيب الفحص.
- **Why problematic:** عند إضافة قاعدة (مثلاً `password.length >= 8`)، هناك احتمال أن يُعدَّل أحد الموقعين فقط — والـ widget يُعطي， المستخدم رسالة "قصيرة" بينما الـ usecase يرفض بصمت.
- **Violated principle:** مصدر واحد للحقيقة على مستوى القاعدة.
- **Current owner:** كلاهما.
- **Correct owner:** `LoginUseCase` (المصدر الوحيد)؛ الـ widget يستدعيه ويتلقى `ValidationFailure` ويفحصه لعرضه حقل-بـحقل.
- **Consequences:** ازدواج صيانة؛ احتمال انحراف سلوكي.
- **Recommended correction:** اجعل `LoginUseCase` يُرجع `ValidationFailure(fieldErrors: …)` واربطه بـ `FormField` validator عبر `Form.of(context)`.
- **Related files:** `lib/core/error/failure.dart:92-99` (يوجد `fieldErrors` — غير مستخدم في auth!)
- **Confidence:** CONFIRMED (ملاحظة: حقل `fieldErrors` في `ValidationFailure` غير مستخدم في أي مكان — راجع §C-3)

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
### ISSUE ACC-005: `rules_screen_model` (application) يعتمد على `core/config`، والمنطق مكرَّر مع الصفحة
- **Severity:** Medium
- **Category:** Wrong dependency + duplicated interpretation
- **Location:** `lib/features/account/application/models/rules_screen_model.dart:1`, `:59-69`؛ المكرر: `lib/features/account/presentation/pages/rules_page.dart:97-112`
- **Evidence:**
```dart
// lib/features/account/application/models/rules_screen_model.dart:1
import '../../../../core/config/hos_configuration.dart';

// :59
  bool _isSettingAllowed(List<String> keys) {
    for (final key in keys) {
      final v = fixedSettings[key];
      if (v == null) continue;
      if (v is bool) return v;
      final t = v.toString().trim().toLowerCase();
      if (t == 'allowed' || t == 'true') return true;
      if (t == 'forbidden' || t == 'false' || t.isNotEmpty) return false;
    }
    return false;
  }
```
```dart
// lib/features/account/presentation/pages/rules_page.dart:97
  String _serverSetting(
    BuildContext context,
    Map<String, dynamic> settings,
    List<String> keys,
  ) {
```
- **Current behavior:** نموذج application يستورد `HosConfiguration` (إعداد بنية تحتية في `core/config`). وفي الوقت نفسه، **نفس منطق تفسير الأسماء البديلة** (`personalConveyance` / `personalConveyanceEnabled`، …) مُنفَّذ مرتين: مرة في النموذج (`_isSettingAllowed`) ومرة في الصفحة (`_serverSetting`).
- **Why problematic:** (أ) نموذج application يعتمد على طبقة إعداد؛ (ب) منطق تفسير حمولة الخادم المرنة (سِلّمWire: `bool` أو `"Allowed"` أو `"true"`) — **وهذا عمل mapper** — مكتوب في نموذج application وآخر في presentation؛ أي تعديل في الخادم يحتاج تعديلاً في موضعين ن divergently.
- **Violated principle:** Mapper-layered parsing belongs to data; application models depend on contracts.
- **Current owner:** `application/models` + `presentation/pages`.
- **Correct owner:** `lib/features/account/data/mappers/rules_settings_mapper.dart` ينتج `Map<String, SettingVerdict>` مطبَّعاً (enum: allowed/forbidden/unknown)؛ النموذج والصفحة يستهلكان نفس النوع.
- **Consequences:** ازدواج + مسارات تفسّر مختلفة لنفس الحمولة (`"Allowed"` → true في موضع، ونص في موضع آخر).
- **Recommended correction:** استخرج `SettingVerdict` mapper واحد.
- **Related files:** `lib/features/account/presentation/pages/rules_page.dart:373-417`, `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart`
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
### ISSUE ACC-007: `account_page.dart` يقرأ اسم السائق من مزوّد HOME، ويطابق أسماء اللغات بنصوص حرفية
- **Severity:** Medium
- **Category:** Cross-feature dependency + presentation-side mapping logic
- **Location:** `lib/features/account/presentation/pages/account_page.dart:7`, `:32`, `:115-119`, `:179-182`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/account_page.dart:7
import '../../../home/presentation/providers/dashboard_provider.dart';

// :32
    final dashboard = ref.watch(dashboardDataProvider);

// :116-118
                      _buildInfoRow(
                        context,
                        loc.sortByName,
                        dashboard.driverName,
                      ),

// :179-182
                                       String code = 'en';
                                       if (newValue.toLowerCase() == 'arabic' || newValue == 'العربية') code = 'ar';
                                       if (newValue.toLowerCase() == 'spanish' || newValue == 'español') code = 'es';
                                       ref.read(localeProvider.notifier).setLocale(code);
```
- **Current behavior:** (أ) الصفحة تعرض اسم السائق من `dashboardDataProvider` (HOME) — بينما نفس الصفحة تملك `authStateProvider.user!.fullName` عبر `accountProvider`، و`accountState.accountData.email`؛ (ب) منطق ترجمة **اسم اللغة النصي إلى رمز اللغة** مكتوب داخل معالج `onChanged` في الـ Widget.
- **Why problematic:** (أ) ACCOUNT صارت تعتمد على تجميع HOME — وهو ما يجعل HOME "طبقة علوية" غير معلنة (انظر HOM-001)؛ (ب) منطق mapping اللغة (سلوك تطبيق) في Widget؛ (ج) النصوص الحرفية `'arabic'`، `'العربية'`، `'español'` لا تغطي أي لغة أخرى — DAO يسقط بصمت إلى `'en'`.
- **Violated principle:** presentation يعرض، لا يقرّر. + duplicate source of truth.
- **Current owner:** page.
- **Correct owner:** (أ) `authStateProvider.user.fullName` مباشرة؛ (ب) `LanguageCodeMapper` في `core/localization/` يقبل `DriverAccount.availableLanguages` ويعيد رمز.
- **Consequences:** (1) ثلاث مصادر للاسم؛ (2) تعطُّل صامت عند إضافة لغة جديدة؛ (3) خيوط coupling متسلسلة.
- **Recommended correction:** احذف الاستيراد 7 واستخدم `ref.watch(authStateProvider).user?.fullName`.
- **Related files:** `lib/features/account/presentation/providers/account_provider.dart:5`, `lib/features/home/presentation/providers/dashboard_provider.dart:4`
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
### ISSUE COD-004: `codriver_page.dart` ينتقل بمسار literal خام `'/'home'` بـ `context.go`
- **Severity:** Medium
- **Category:** Routing bypass / fragile navigation
- **Location:** `lib/features/codriver/presentation/pages/codriver_page.dart:304`
- **Evidence:**
```dart
// lib/features/codriver/presentation/pages/codriver_page.dart:302-304
                                       ref.invalidate(teamStatusProvider);
                                       ref.invalidate(statusDashboardProvider);
                                       context.go('/home');
```
- **Current behavior:** بعد نجاح التبديل، تستخدم الصفحة `context.go('/home')` — **نص حر** بدل `AppRoutes.home`، و`go` (استبدال الحزمة) بدل `pop()`.
- **Why problematic:** (أ) كسر التماسك: تعديل `AppRoutes.home` في `routes.dart:22` لا Affect هذا الاستدعاء ⇒ route point إلى لا شيء (silent 404 حسب redirect)؛ (ب) الصفحة وصلت إلى `codriver` عبر `context.push` من `EldDrawer` (`eld_drawer.dart:68`)، فالـ `go('/home')` يمسح الحزمة كلها — سلوك مختلف عن `pop()` المتوقع بعد "successful action".
- **Violated principle:** Route constants centralization; GoRouter stack semantics.
- **Current owner:** page.
- **Correct owner:** `context.go(AppRoutes.home)` على الأقل، والأفضل: إما `context.pop()` (إن كانت modal) أو `context.go(AppRoutes.home)` موحّد.
- **Consequences:** drift كامن + سلوك back غير متوقع.
- **Recommended correction:** استبدل بالحرف `'/'` → `AppRoutes.home` وفعّل قاعد Dart lint تمنع string literals في `context.go/push`.
- **Related files:** `lib/routes.dart:22`, `lib/features/home/presentation/widgets/eld_drawer.dart:68`
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
### ISSUE CON-002: `AppLocalizations` يُمرَّر كوسيط إلى `StateNotifier` (presentation logic يتلقى كائن ترجمة)
- **Severity:** Medium
- **Category:** Localization leakage  presented as non-UI logic
- **Location:** `lib/features/connection/presentation/pages/eld_connection_page.dart:139-160`
- **Evidence:**
```dart
// lib/features/connection/presentation/pages/eld_connection_page.dart:139-147
  Future<String?> setManualMode({
    required bool enable,
    required String reason,
    required AppLocalizations loc,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return loc.enterAReasonForManualRecording;
    }
```
- **Current behavior:** منطق العمل (trim، تحقق، نداء backend) يستقبل كائن ترجمة كامل كوسيط، ويُرجع **نصاً جاهزاً للعرض** بدلاً من رمز خطأ.
- **Why problematic:** (أ) الحالة/المنطق صار غير قابل لإعادة الاستخدام (يحتاج `BuildContext` أو `AppLocalizations` كامل)؛ (ب) القرار «ماذا يُعرض» صار داخل notifier؛ (ج) هذا يقوّض نمط `anyErrorUserMessage` الموجود أصلاً.
- **Violated principle:** Non-UI code returns codes; presentation localizes.
- **Current owner:** `EldConnectionNotifier`.
- **Correct owner:** الكود يُرجع `Either<Failure, Unit>` أو enum؛ presentation يترجم.
- **Consequences:** تكرار منطق الترجمة في كل مستهلك.
- **Recommended correction:** أعد `Future<Either<Failure, Unit>> setManualMode(...)`.
- **Related files:** `lib/features/connection/presentation/widgets/manual_recording_section.dart:107-111` (المستهلك)، `lib/core/error/user_facing_message.dart`
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
### ISSUE CON-004: `manual_recording_section.dart` يستورد صفحة (وليس provider) للحصول على حالة الاتصال
- **Severity:** Medium
- **Category:** Wrong import (widget → page)
- **Location:** `lib/features/connection/presentation/widgets/manual_recording_section.dart:9`, `:107`
- **Evidence:**
```dart
// lib/features/connection/presentation/widgets/manual_recording_section.dart:9
import '../pages/eld_connection_page.dart';
...
// :107
    final error = await ref.read(eldConnectionProvider.notifier).setManualMode(
```
- **Current behavior:** Widget يستورد ملف صفحة ليستخدم `eldConnectionProvider` المعرَّف داخلها (سطر 248 من الصفحة).
- **Why problematic:** (أ) layering معكوس داخل presentation نفسها؛ (b)Makes `eldConnectionPage.dart` (529 سطر) **ملف hub** لا يمكن تقسيمه؛ (c) `AboutPage` يستورد هذا القسم، فيسحب ضمناً صفحة الاتصال كاملة إلى About.
- **Violated principle:** Provider should live in `providers/`, not in a page file.
- **Current owner:** `eld_connection_page.dart`.
- **Correct owner:** `lib/features/connection/presentation/providers/eld_connection_provider.dart`.
- **Consequences:** استيراد صفحة كاملة لمجرّد provider؛ circular-risk.
- **Recommended correction:** انقل `EldConnectionState/Notifier/Provider` إلى `presentation/providers/`.
- **Related files:** `lib/features/connection/presentation/pages/eld_connection_page.dart:248-251`, `lib/features/connection/presentation/pages/eld_connection_page.dart:9` (المتناقض: `mac_address_validation` من presentation, لكن provider من page)
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CON-006: تقسيم قاعدة MAC غير متسق بين domain و presentation (والـ formatter يضيق القاعدة)
- **Severity:** Low
- **Category:** Split validation policy / Inconsistent UX
- **Location:** `lib/features/connection/presentation/pages/eld_connection_page.dart:436-444` مقابل `lib/features/connection/domain/connectivity_status.dart:150`
- **Evidence:**
```dart
// lib/features/connection/presentation/pages/eld_connection_page.dart:436-443
                      maxLength: 17,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F:]')),
                      ],
                      onSubmitted: (_) => _attemptConnection(),
                      validator: (v) => macAddressError(
                        v,
                        loc: context.loc,
                      ),
```
```dart
// lib/features/connection/domain/connectivity_status.dart:148-151
/// `AA:BB:CC:DD:EE:FF` (or `-` separated). Shared by prefill and the
/// connection form so both agree on what a MAC looks like.
bool isMacAddress(String value) =>
    RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$').hasMatch(value.trim());
```
- **Current behavior:** (أ) `isMacAddress` (accepts `:` أو `-`) موجودة في domain وتُستخدم للـ prefill (`eld_connection_page.dart:316`)؛ (ب) الـ `validator` في presentation **لا يتحقق من الصيغة إطلاقاً** (illowing فقط) — وهذا **مقصود وموثّق** في `mac_address_validation.dart:4-5`؛ (c) لكن الـ `FilteringTextInputFormatter` في presentation **يحذف** أي حرف خارج `[0-9a-fA-F:]` أثناء الكتابة/اللصق.
- **Why problematic:** عدم اتساق: لو لصق السائق معرّفاً بصيغة `AA-BB-CC-...` (يقبله `isMacAddress` صراحةً كـ "valid MAC")، فإن الـ formatter **يحذف الشرطات** قبل التحقق. النتيجة: قيمة مُحوّلة تُرسل للخادم بشكل مختلف عن ما كُتب.
- **Violated principle:** Single source of validation truth.
- **Current owner:** presentation.
- **Correct owner:** مشتق واحد في domain (أو presentation) يُستخدم في الثلاثة (prefill + formatter + validator).
- **Consequences:**driver pastes a MAC, the field silently changes; server sees different value.
- **Recommended correction:** إمّا احذف الـ formatter (دع `isMacAddress` يتحقق)، أو اجعله يقبل `[0-9A-Fa-f:-]` ليطابق النطاق.
- **Related files:** `lib/features/connection/presentation/mac_address_validation.dart`
- **Confidence:** POTENTIAL (النية التصميمية — "لا ترفض الصيغة في العميل" — صحيحة؛ لكن الـ formatter يتعارض معها)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CON-007: قاعدة تصنيف MALFUNCTION في صفحة + زر debug بلا أثر في الإنتاج
- **Severity:** Low
- **Category:** Domain rule in presentation / dead debug affordance
- **Location:** `lib/features/connection/presentation/pages/diagnostics_page.dart:23-24`, `:81-91`
- **Evidence:**
```dart
// lib/features/connection/presentation/pages/diagnostics_page.dart:23
  bool _isMalfunction(HardwareAlert a) =>
      a.type.toUpperCase().contains('MALFUNCTION');
```
```dart
// :81-91
              if (kDebugMode) ...[
                ...
                OutlinedButton(
                  onPressed: () => AppFeedback.info(
                      context, loc.simulatedMalfunctionRecorded),
                  child: Text(loc.simulateMalfunction),
                ),
              ],
```
- **Current behavior:** (أ) تصنيف «هل هذا عطل أم data diagnostic؟» — قاعدة SRS 7.14 — عبر `contains('MALFUNCTION')` داخل الصفحة؛ (ب) كتلة `kDebugMode` بزر "محاكاة عطل" لا يفعل شيئاً سوى Toast.
- **Why problematic:** (أ) قاعدة نطاق (presentation-readable) في presentation؛ (ب) زر معلومات مضلّل في وضع debug (يقترح محاكاة ولا يحاكي) — risky أثناء اختبار roadside.
- **Violated principle:** Domain rules belong to domain.
- **Current owner:** page.
- **Correct owner:** `extension on HardwareAlert { bool get isMalfunction; }` في `connection/domain/entities/hardware_alert.dart`؛ أما الزر — يُحذف أو يُنفَّذ فعلياً.
- **Recommended correction:** انقل التصنيف إلى كيان `HardwareAlert`، واحذف/نفّذ كتلة kDebugMode.
- **Confidence:** CONFIRMED (الموضع والأكواد)

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
### ISSUE HOM-002: `home_page.dart` يستضيف صفحات HOS كتبويبات ويملك `developerBypassDrivingScreenProvider`
- **Severity:** High (compliance)
- **Category:** Feature composition + bypass affordance in presentation
- **Location:** `lib/features/home/presentation/pages/home_page.dart:24`, `:30-35`, `:212-215`
- **Evidence:**
```dart
// lib/features/home/presentation/providers/home_page.dart:24
final developerBypassDrivingScreenProvider = StateProvider<bool>((ref) => false);

// :30-35
  List<Widget> _pagesFor(WidgetRef ref) {
    return const [
      StatusDashboardPage(),
      RecapPage(),
    ];
  }

// :212-215
        if (isDriving && isMoving && !developerBypass)
          const Positioned.fill(
            child: DrivingLockScreen(),
          ),
```
- **Current behavior:** (أ) HOME يحتضن صفحتي feature HOS (`StatusDashboardPage`, `RecapPage`) كـ تبويبات داخلية، و`DrivingLockScreen` (HOS) كطبقة علوية؛ (ب) **`developerBypassDrivingScreenProvider`** — `StateProvider<bool>` داخل presentation، يمكن لأي كود في التطبيق (أو console debug عبر Riverpod) قلبه لتعطيل **قفل القيادة** أثناء القيادة.
- **Why problematic:** (أ) قفل القيادة (`DrivingLockScreen`) هو **ضمان امتثال HOS**؛ تجاوزه Sitting في presentation بلا `kDebugMode` ولا تسجيل — riesgo امتثال مباشر؛ (ب) HOME behaving as a `Shell`， بينما نمط shell صريح — صفحات HOS تُدار بـ state محلي (`homeNavIndexProvider`) لا عبر GoRouter ⇒ لا deep-link ولا history.
- **Violated principle:** Compliance-critical invariants must not be presentation-toggleable; shell navigation belongs to router.
- **Current owner:** `home_page.dart`.
- **Correct owner:** (أ) `developerBypass` → ينتقل إلى `kDebugMode`-guarded `Provider` في `app/` مع تسجيل؛ أو يُحذف؛ (ب) تبويبات HOME → `StatefulShellRoute.indexedStack` في `routes/home_routes.dart`.
- **Consequences:** (1) في تطبيق ELD منظَّم، إمكانية تعطيل قفل القيادة غير مقصودة = خطر تنظيمي؛ (2) التبويبات بلا deep-link.
- **Related files:** `lib/features/hos/presentation/widgets/driving_lock_screen.dart`, `lib/routes/home_routes.dart:11-37`
- **Confidence:** CONFIRMED (الرمز مقتبس حرفياً؛ التقييم عالي لكن **ليس style nit** — concerns الامتثال + بنية router)

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
### ISSUE HOM-004: منطق تجميع نص الترويسة (أولوية 3 مصادر) داخل Widget
- **Severity:** Low
- **Category:** Presentation deciding data priority
- **Location:** `lib/features/home/presentation/pages/home_page.dart:56-65`
- **Evidence:**
```dart
// lib/features/home/presentation/pages/home_page.dart:56-65
    // الأولوية: بيانات الـ API → بيانات Auth المحلية → نص افتراضي
    final driverText = statusDashboardState.valueOrNull?.driver.displayText ??
        // SRS 4.2 — `Name - <driver id>`; the vehicle is not part of the header.
        (dashboard.driverName != 'Unknown'
            ? (ref.watch(currentDriverIdProvider) != null
                ? '${dashboard.driverName} - ${ref.watch(currentDriverIdProvider)}'
                : dashboard.driverName)
            : null) ??
        ref.watch(authStateProvider).user?.fullName ??
        '';
```
- **Current behavior:** الـ Widget يقرر أولوية عرض الاسم عبر 3 مصادر + مقارنات بالنصوص `'Unknown'`، ويبني نصاً مركّباً يدوياً (concatenation)، ويقارن بـ `'Unknown'` (magic string من `dashboard_provider.dart:65`).
- **Why problematic:** (أ) Formatting (`'Name - id'`) قرار عرض — مقبول هنا؛ لكن (ب) **مقارنة `!= 'Unknown'`** هشّة: الاسم الفعلي للسائق إن كان "Unknown" سيُسقط إلى auth fallback — سلوك خفي؛ (c) `dashboard.driverName` من feature-account-coupled-aggregation.
- **Violated principle:** No magic-string state comparison.
- **Current owner:** page.
- **Correct owner:** `DashboardData.isDriverNameKnown` (bool) أو `String?` بدل sentinel.
- **Recommended correction:** استبدل sentinel `'Unknown'` بـ `null`.
- **Related files:** `lib/features/home/presentation/providers/dashboard_provider.dart:65`, `lib/features/connection/presentation/pages/eld_connection_page.dart:365-367` (نفس نمط `'No Vehicle'`).
- **Related files note:** النمط نفسه يتكرر في `eld_connection_page.dart:365` و`dashboard_provider.dart:67-68`.
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
### ISSUE ROU-001: تجاوز GoRouter فعلي واحد: `UserManualPage` تُفتح بـ `Navigator.push` رغم وجود مسار مسجّل
- **Severity:** Medium
- **Category:** Router bypass
- **Location:** `lib/features/account/presentation/pages/info_packet_page.dart:45-49` مقابل `lib/routes/account_routes.dart:30-34`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/info_packet_page.dart:45-49
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManualPage()),
              );
```
```dart
// lib/routes/account_routes.dart:30-34
        GoRoute(
          path: AppRoutes.userManual,
          name: 'userManual',
          builder: (context, state) => const UserManualPage(),
        ),
```
- **Current behavior:** `UserManualPage` لها مسار GoRouter مسجّل (`/user-manual`)، لكنها **لا تُفتح عبره** من صفحة حزمة المعلومات، بل عبر `Navigator.push` بـ MaterialPageRoute. أما `DiagnosticsPage` (`about_page.dart:267`) و`ZoomableSectionPage` (`instructions_page.dart:77`) فلا مسار لهما — تجاوز مقبول تقنياً لكن غير مسجّل.
- **Why problematic:** (أ) نسختان مختلفتان mental model for navigation (router + navigator stack)؛ (b) `UserManualPage` عند فتحها عبر router-vs-push تنتج back-stack مختلفة؛ (c) `context.push` على `/user-manual` لم يُستخدم أبداً رغم تسجيله ⇒ **المسار Dead عملياً**.
- **Violated principle:** Single navigation authority.
- **Current owner:** `info_packet_page.dart`.
- **Correct owner:** `context.push(AppRoutes.userManual)` / `context.goNamed('userManual')`.
- **Consequences:** (1) المسار المسجّل غير مستخدم؛ (2) back-stack غير متوقع؛ (3) hard coupling للصفحات.
- **Recommended correction:** استبدل `Navigator.push` بـ `context.push(AppRoutes.userManual)`.
- **Related files:** `lib/routes/account_routes.dart:30-34`, `lib/features/about/presentation/pages/about_page.dart:267`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE ROU-002: `InstructionsPage` يمتلك 4 أقسام لكن 3 منها غير قابلة للوصول
- **Severity:** Low
- **Category:** Dead configuration / over-specification
- **Location:** `lib/features/account/presentation/pages/instructions_page.dart:12`, `:15`, `:19-24`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/instructions_page.dart:12
enum InstructionsSection { all, inspection, sendLogs, malfunction }

// :19-24
  String _title(AppLocalizations loc) => switch (section) {
    InstructionsSection.all => loc.instructions,
    InstructionsSection.inspection => loc.inspectionMode,
    InstructionsSection.sendLogs => loc.dataTransferInstructionSheet,
    InstructionsSection.malfunction => loc.malfunctionManual39534,
  };
```
- **Current behavior:** `InstructionsPage` مع 4 أقسام، لكن **لا يوجد أي استدعاء بـ `section:`** (تم البحث الشامل: `InstructionsPage(` يظهر مرتين فقط — المرساة 15، والاستخدام في `info_packet_page.dart:59` بدون section). و**لا يوجد GoRoute لـ `/instructions`**. ⇒ 3 أقسام + عناوينها المترجمة dead code.
- **Why problematic:** configuration زائدة تُوهم أن الأقسام قابلة للوصول فرادى (SRS 8.2 يذكر 3 عناصر منفصلة)، بينما الواجهة فقط تعرضها مجتمعة.
- **Violated principle:** — (لا مبالغة)
- **Current owner:** page.
- **Correct owner:** إمّا أضف مسارات (`.inspection`, `.sendLogs`, `.malfunction`) أو احذف الـ enum.
- **Consequences:**_code ميت؛ localizations زائدة عن الحاجة.
- **Recommended correction:** استكمل المسارات أو احذف الـ enum.
- **Related files:** `lib/features/account/presentation/pages/info_packet_page.dart:52-62`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE SET-001: `settings_page.dart` يزامن تفضيل اللغة عبر feature ACCOUNT presentation
- **Severity:** Low
- **Category:** Cross-feature write through presentation
- **Location:** `lib/features/settings/presentation/pages/settings_page.dart:14`, `:116-125`
- **Evidence:**
```dart
// lib/features/settings/presentation/pages/settings_page.dart:14
import '../../../account/presentation/providers/account_provider.dart';

// :116-125
                      final accountState = ref.read(accountProvider);
                      // If user is logged in, sync to server
                      if (accountState.accountData != null) {
                        final langName = code == 'ar' ? 'Arabic' : (code == 'es' ? 'Spanish' : 'English');
                        final currentOdo = accountState.accountData?.odometer ?? 'mi';
                        await ref.read(accountProvider.notifier).updatePreferences(
                          language: langName,
                          odometerUnit: currentOdo,
                        );
                      }
```
- **Current behavior:** صفحة SETTINGS تكتب في `AccountNotifier` (presentation لميزة أخرى)، وتحوّل رمز اللغة إلى اسم نصي بمقارنة if/else داخل الـ Widget.
- **Why problematic:** (أ) SETTINGS → ACCOUNT presentation write path؛ (ب) نفس mapping مكرَّر في `account_page.dart:180-181` بترميز مختلف؛ (ج) `ref.read(accountProvider)` دون `watch` ⇒ لا إعادة بناء عند تغيّر الحساب.
- **Violated principle:** Cross-feature writes go through the owning feature's use-case.
- **Current owner:** page.
- **Correct owner:** use-case في `features/account/application/usecases/update_preferences_use_case.dart` + mapper لغة مشترك.
- **Consequences:** ازدواج mapping اللغة؛ تسرّب في الكتابة.
- **Recommended correction:** mapper لغة واحد + use-case مشترك.
- **Related files:** `lib/features/account/presentation/pages/account_page.dart:179-182`, `lib/features/account/presentation/providers/account_provider.dart:99`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE PERM-001: صفحة الصلاحيات rely على نصوص عربية hardcoded بالكامل في تطبيق يدعم 3 لغات
- **Severity:** Medium (compliance/UX) — ليس style nit
- **Category:** Localization bypass (feature-level)
- **Location:** `lib/features/permissions/presentation/pages/permissions_page.dart:61-64`, `:77-80`, `:141`, `:179`, `:185`, `:194-195`, `:204-205`, `:214-215`, `:224-225`, `:234-235`, `:249-250`, `:286`
- **Evidence:**
```dart
// lib/features/permissions/presentation/pages/permissions_page.dart:61-64
        title: 'صلاحية الموقع مطلوبة',
        message: 'يحتاج تطبيق ELD إلى الوصول للموقع الجغرافي بشكل دائم '
            'لتسجيل مسار المركبة وساعات القيادة تلقائياً.\n\n'
            'هذا متطلب قانوني من FMCSA ولا يمكن عمل التطبيق بدونه.',
```
```dart
// :141
            child: Text(isRequired ? 'منح الصلاحية' : 'موافق'),

// :286
                label: 'مطلوب',
```
- **Current behavior:** الصفحة **كلها** بالعربية hardcoded (بما فيها نصوص قانونية: «هذا متطلب قانوني من FMCSA ولا يمكن عمل التطبيق بدونه»)، بينما نفس الصفحة تستخدم `context.loc.continueWithout` (سطر 129) و`context.loc.grant` (سطر 296). ⇒ الترجمة **جزئية**.
- **Why problematic:** (أ) سائق English/Español يرى واجهة صلاحيات بالعربية بالكامل مع نصوص قانونية؛ (ب) التطبيق يعلن دعم ar/en/es في `settings_page.dart:95-110`؛ (ج) عدم اتساق داخل نفس الملف (بعضها `context.loc` وبعضها حرف).
- **Violated principle:** Localization completeness — `AppLocalizations` هو المصدر الوحيد.
- **Current owner:** page.
- **Correct owner:** `l10n/arb` + `AppLocalizations` (كل النصوص).
- **Consequences:** توهُم السائق؛ المسار الإلزامي غير مفهوم لغير العربية.
- **Recommended correction:** ترجمة كل النصوص إلى `AppLocalizations` (نفس نهج `forgot_password_form.dart` لكن **بـ l10n** لا بـ if/else).
- **Related files:** `lib/l10n/app_localizations*.dart`, `lib/features/settings/presentation/pages/settings_page.dart:95-110`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CTN-001: صفحات الحaccount (instructions / user_manual / rules) مترجمة بشكل صحيح — فرضية «صفحات نص خام» مرفوضة
- **Severity:** Informational (لا مخالفة) — **CONFIRMED CLEAN**
- **Category:** Localization — تحقق إيجابي
- **Location:** `lib/features/account/presentation/pages/instructions_page.dart` (502 سطر)، `user_manual_page.dart` (559)، `rules_page.dart` (502)
- **Evidence (نماذج):**
```dart
// instructions_page.dart:125
                  loc.goldenFeatherEldInspectionMode,
// instructions_page.dart:135
                  text: loc.tapDotInspectionInTheMenuPress,
// user_manual_page.dart:129-131
                    Text(
                      'Golden Feather ELD',          // ← الاستثناء الوحيد
                      style: context.styles.body
                          .copyWith(fontSize: 24, fontWeight: FontWeight.w400),
                    ),
// user_manual_page.dart:169
        'title': loc.recordsOfDutyStatus,
```
- **Current behavior:** كل النصوص الطويلة في الصفحات الثلاث تمر عبر `context.loc` / `loc.*` (عشرات المطابقات). **النصوص الحرفية الوحيدة**: `'Golden Feather ELD'` (user_manual:129)، `'www.topceld.com'` (instructions:374)، `'AA:BB:CC:DD:EE:FF'` (eld_connection:433 — placeholder MAC مقصود).
- **Why problematic:** لا شيء جوهري. ملاحظة فقط: `'Golden Feather ELD'` يمكن استبداله بـ `loc.appName` الموجود.
- **Violated principle:** — (غير منتهك)
- **Current owner:** — | **Correct owner:** `loc.appName`.
- **Confidence:** CONFIRMED — **الفرضية المرفوضة بشكل صريح**.

--------------------------------------------------

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
### ISSUE CUI-002: `connection_status_indicator.dart` يُعيد بناء `AppStatusBadge` يدوياً بدل استهلاكه
- Severity: **MODERATE**
- Category: Duplication inside core / Missed design-system adoption
- Location `lib/core/widgets/connection_status_indicator.dart:60-99`
- Evidence code block:
```dart
60:    return Center(
61:      child: Container(
62:        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
63:        margin: const EdgeInsets.symmetric(horizontal: 4),
64:        decoration: BoxDecoration(
65:          color: color.withValues(alpha: 0.1),
66:          borderRadius: BorderRadius.circular(16),
67:          border: Border.all(color: color.withValues(alpha: 0.3)),
68:        ),
69:        child: Row(
70:          mainAxisSize: MainAxisSize.min,
...
82:              Icon(icon, size: 14, color: color),
83:            const SizedBox(width: 6),
84:            Flexible(
85:              child: Text(
86:                text,
87:                overflow: TextOverflow.ellipsis,
88:                style:
89:                    (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
90:                        .copyWith(
91:                  color: color,
92:                  fontWeight: FontWeight.bold,
93:                ),
```
- Current behavior: حاوية `BoxDecoration` بخلفية شفافة وحدّ و`Row` ونص ملوّن — وهو بالضبط ما يقدّمه `AppStatusBadge` في `app_status_badge.dart:65-94`. الملف لا يستورد `app_status_badge.dart` إطلاقاً، بينما الملفات الشقيقة في `features` تفعل ذلك بشكل صحيح (`features/sync/presentation/widgets/sync_status_indicator.dart:27`).
- Why problematic: وجود بديلين للشارة داخل نفس الحزمة (CUI-010) مع ثالث داخل `core`؛ وقيم `alpha 0.1 / 0.3` و`radius 16` و`fontWeight: bold` مثبّتة خارج نظام التصميم، فأي تعديل على `AppStatusBadge` لن ينعكس.
- Violated principle: DRY / Single source of truth for visual tokens.
- Current owner: `lib/core/widgets/connection_status_indicator.dart:60-99`
- Correct owner: `lib/core/widgets/app_status_badge.dart` (المصدّر القياسي للشارة)
- Consequences: ثلاث تنفيذات متنافسة للشارة؛ تفاوت بصري بين شارة المزامنة وشارة الاتصال.
- Recommended correction: استبدل الحاوية بـ`AppStatusBadge(label: text, type: ..., icon: icon)`، أو — إن لزم عنصر جانبي — مرّر `AppStatusBadge` مع أيقونة `CircularProgressIndicator` في `icon`.
- Related files: `lib/core/widgets/app_status_badge.dart:65-94`, `lib/features/sync/presentation/widgets/sync_status_indicator.dart:27-42`, `lib/core/theme/app_radius.dart:21-30`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-003: `AppButton` يكشف نوايا عمل ELD في واجهة نظام التصميم
- Severity: **MODERATE**
- Category: Misplaced responsibility / Domain vocabulary in shared design-system
- Location `lib/core/widgets/app_button.dart:6-25` و `:55-59`
- Evidence code block:
```dart
 6: enum EldButtonType {
 7:   /// الزر الأساسي بلون الهوية الذهبي (Golden Feather Primary Gold)
 8:   primary,
 9:
10:   /// الزر الثانوي المؤطر (Outlined) بإطار ولون ذهبي أنيق وخلفية شفافة
11:   secondary,
12:
13:   /// زر الاتصال والإجراءات الإيجابية والاعتماد (Success Green)
14:   connect,
15:   agree,
16:
17:   /// الزر التحذيري أو الحذف أو الإلغاء الحرج (Danger Red)
18:   danger,
19:
20:   /// للمطابقة مع الاستخدامات السابقة وتوجيهها للمظهر المناسب:
21:   continueDisconnected,
22:   send,
23:   dark,
24:   muted,
25: }
```
```dart
55:  bool get _isOutlined =>
56:      widget.type == EldButtonType.secondary ||
57:      widget.type == EldButtonType.continueDisconnected ||
58:      widget.type == EldButtonType.dark ||
59:      widget.type == EldButtonType.muted;
```
- Current behavior: تعداد في نظام التصميم يحمل **نوايا تطبيقية** (`continueDisconnected`, `agree`, `send`, `connect`) لا أنماطاً بصرية. و`continueDisconnected` و`agree` و`send` **لا تقابل أي فرق بصري** في `build`: `_isOutlined` يجمع `continueDisconnected` فقط، و`_base`/`_foreground` يعاملان `send` و`agree` تماماً كـ`primary` (السطران 64-66 و 85-87). أي أنها **أسماء أعمال تجارية بلا أثر سلوكي**.
- Why problematic:
  1. واجهة نظام التصميم يجب أن تصف **المظهر** (primary / secondary / danger / outlined)، لا **قرار العمل**.
  2. كل قيمة جديدة بمسمّى من مجال العمل تفرض تعديل `core` — وهو نفس الفخّ الذي أنتج CUI-001.
  3. بادئة `Eld` داخل `core/` توهم بأن `core` مربوط بمجال ELD.
- Violated principle: Interface Segregation / Tell-Don't-Ask — نظام التصميم لا يجب أن يعرف نوايا المجال.
- Current owner: `lib/core/widgets/app_button.dart`
- Correct owner: `lib/core/widgets/app_button.dart` بأنواع **بصرية بحتة** (`primary|secondary|danger|success|outline`)؛ أما اختيار النوع فيبقى قرار الصفحة.
- Consequences: استحالة إعادة استخدام `AppButton` في تطبيق آخر؛ تسرّب مفردات المجال إلى نظام التصميم؛ وخداع أي فحص exhaustiveness لأن قيماً لا تقابل فروعاً حقيقية في السلوك.
- Recommended correction: استبدل `EldButtonType` بـ`AppButtonVariant { primary, success, danger, outlined }` واحذف `connect` و`agree` و`send` و`continueDisconnected` و`dark` و`muted`. الصفحات تختار `AppButtonVariant.success` عند الحاجة.
- Related files: `lib/core/widgets/app_button.dart:55-111`, `lib/features/auth/presentation/widgets/login_form.dart:4`, `lib/features/hos/presentation/pages/change_status_page.dart:6`, `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart:7`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-004: `eld_graph_grid.dart` يُضمّن رموز الحالة التنظيمية FMCSA وترتيب صفوف المخطط داخل `core`
- Severity: **MODERATE**
- Category: Domain leakage  presented as presentation primitive / Hardcoded regulatory vocabulary
- Location `lib/core/widgets/eld_graph_grid.dart:8-9`, `:23`, `:79`, `:104-106`, `:160`, `:177`, `:330-338`
- Evidence code block:
```dart
 8:   final String status; // 'OFF', 'SB', 'D', 'ON'
 9:   final String? tag; // e.g. 'PC', 'YM'
```
```dart
23:   final Map<String, double>? rightSideStats; // Map of 'OFF', 'SB', 'D', 'ON' to hours
```
```dart
79:    final rowHeight = chartHeight / 4.0; // 4 rows: OFF, SB, D, ON
```
```dart
102:  void _drawTimeAxis(Canvas canvas, double offsetX, double chartWidth, double height) {
103:    final hours = [
104:      'M', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11',
105:      'N', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', 'M'
106:    ];
```
```dart
330:  double _getYPosition(String status, double rowHeight) {
331:    switch (status) {
332:      case 'OFF': return rowHeight * 0.5;
333:      case 'SB':  return rowHeight * 1.5;
334:      case 'D':   return rowHeight * 2.5;
335:      case 'ON':  return rowHeight * 3.5;
336:      default:    return rowHeight * 0.5;
337:    }
338:  }
```
- Current behavior: `core` يحمل (أ) مفردات الحالة التنظيمية كـ`String` حرة، و(ب) **ترتيب صفوف مخطط ساعات العمل**. ملاحظة تقنية: `_getYPosition` يستعمل `rowHeight * N.5` وليس `rowHeight * N`، فالمقادير الفعلية `0.5r / 1.5r / 2.5r / 3.5r`؛ وبما أن الرسم يبدأ بـ`canvas.translate(0, timeAxisHeight)` تُقصّ الصفوف العليا والسفلى جزئياً خارج `chartHeight`. وبغض النظر عن ذلك، **الترتيب مقصود ومثبّت**.
- Why problematic:
  1. **`_getYPosition` تكرار منطقي**: توجد خريطتان مستقلتان لنفس المعرفة — `inspection_duty_graph.dart:130-162` (`_rowOf`) و`log_graph.dart:46-53` (`normalized`) — وكلتاهما تفرض **نفس** الترتيب. ثلاث نسخ من قاعدة واحدة.
  2. **الترتيب قرار تنظيمي**: مخطط Graph of Duty Status في 49 CFR 395.8 يحدّد الترتيب `OFF / SB / D / ON`. وضعه في `core` يعني أن `core` يحمل معرفة تنظيمية.
  3. **`default:` يبتلع أي رمز جديد بصمت** (السطر 336): رمز غير معروف يُرسم كـ`OFF` — وهو خطأ صامت في سياق تنظيمي.
  4. **نصوص إنجليزية مُشفّرة** (`:104-106`, `:160`, `:177`) لا تمرّ بـ`AppLocalizations`، وهي عناوين المخطط المعروضة للضابط على الطريق. وبالمقابل `eld_events_table.dart` يمرّر عناوينه عبر `context.loc` (`:62-99`)، فهناك تباين غير مبرَّر.
- Violated principle: Domain model must not be re-encoded in the UI layer; Policy (regulatory row order) belongs to domain.
- Current owner: `lib/core/widgets/eld_graph_grid.dart`
- Correct owner: `DutyStatusCode` (`lib/domain/duty_status/duty_status_code.dart:10-16`، وهو يملك `shortCode`) يوفّر الترتيب؛ و`core` يستقبل ترتيب الصفوف جاهزاً كمعامل.
- Consequences: إضافة حالة جديدة كصف مستقل تتطلب تعديل `core`؛ انحراف بصري صامت عند رموز غير معروفة؛ خطر اختلاف ترتيب الصفوف بين المخططات الثلاثة دون ضابط.
- Recommended correction: مرّر `required List<String> rowOrder` و`required Map<String, int> rowIndex` إلى `EldGraphGrid`؛ واجعل `switch` يُبرز الحالات غير المعروفة بدل ابتلاعها؛ وانقل نصوص المحاور إلى `AppLocalizations`.
- Related files: `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart:22-29,130-162`, `lib/features/logs/presentation/widgets/log_graph.dart:25-30,46-53`, `lib/domain/duty_status/duty_status_code.dart:10-16,53-56`
- Confidence: **CONFIRMED** (للرموز والترتيب) / **POTENTIAL** (هل يجب أن يكون الرسم قابلاً لإعادة الاستخدام خارج ELD — قد يكون مقصوداً)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-005: `critical_error_app.dart` يعرض نصاً عربياً مُشفّراً ويتجاوز نظام الترجمة بالكامل
- Severity: **MODERATE**
- Category: Localization bypass / Root-level responsibility in shared widget
- Location `lib/core/widgets/critical_error_app.dart:17`, `:26-30`, `:32-39`, `:44-47`
- Evidence code block:
```dart
15:    return MaterialApp(
16:      debugShowCheckedModeBanner: false,
17:      title: 'Golden Feather ELD - Error',
```
```dart
26:                const Icon(
27:                  Icons.error_outline,
28:                  color: Colors.red,
29:                  size: 64,
30:                ),
31:                const SizedBox(height: 24),
32:                const Text(
33:                  'عذراً، حدث خطأ حرج',
34:                  style: TextStyle(
35:                    fontSize: 24,
36:                    fontWeight: FontWeight.bold,
37:                    color: Colors.black87,
38:                  ),
39:                ),
```
```dart
44:                  style: const TextStyle(
45:                    fontSize: 16,
46:                    color: Colors.black54,
47:                  ),
```
- Current behavior: **إجابة مباشرة على السؤال 5 — نعم، `lib/core/widgets/critical_error_app.dart:33` هو النص `'عذراً، حدث خطأ حرج'`.** هذا النص **لا يمرّ بـ`AppLocalizations`** ولا بـ`context.loc`. التطبيق يدعم ثلاث لغات (`app.dart:82-83`) ويجبر العربية افتراضياً (`app.dart:85,91`)، فهذه الشاشة تُعرض للمستخدم النهائي فتُجبره على العربية مهما كانت لغة الجهاز. كذلك `title` في السطر 17 إنجليزي ثابت. والرسالة الثانية مُشفّرة في `lib/main.dart:59-60`:
```dart
58:      const CriticalErrorApp(
59:        message:
60:            'تعذر تهيئة الخدمات الأساسية للتطبيق.\nيرجى التحقق من اتصالك وإعادة التشغيل.',
```
- Why problematic:
  1. **تجاوز الترجمة** في النافذة الوحيدة التي يراها السائق عند فشل الإقلاع.
  2. **`MaterialApp` متداخل** (السطر 15) داخل `core/widgets`: هذا تطبيق جذر لا widget مشترك، ما يجعل `core/widgets` تعتمد على بنية التطبيق لا على التصميم.
  3. **ألوان خام خارج `AppColors`**: `Colors.red` (28)، `Colors.black87` (37)، `Colors.black54` (46)، `backgroundColor: Colors.white` (19) — لا تحترم الوضع الداكن ولا لوحة الهوية.
  4. `title: 'Golden Feather ELD - Error'` بينما `app.dart:77` يستخدم `AppConstants.appName` — مصدران لاسم التطبيق.
- Violated principle: Presentation abstraction / Design-system single source of truth.
- Current owner: `lib/core/widgets/critical_error_app.dart`
- Correct owner: `lib/app/fallback/fallback_app.dart`؛ والنصوص إلى `lib/l10n/app_*.arb` عبر `AppLocalizations`.
- Consequences: استثناء ترجمة في تجربة حرجة؛ حد أدنى من الصيانة البصرية في أبغد شاشة؛ ولا يمكن اختبار النصوص آلياً.
- Recommended correction: انقل الملف إلى `lib/app/fallback/fallback_app.dart`؛ واستورد `AppTheme` فيه؛ واجعل العنوان والنصّين من `AppLocalizations`.
- Related files: `lib/main.dart:55-63`, `lib/app.dart:77,82-92`, `lib/core/theme/app_colors.dart:38,70`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-006: `app_feedback.dart` قناة إشعار موازية تتجاوز `snackBarTheme` وتستخدم حالة عامة ثابتة
- Severity: **MODERATE**
- Category: Design-system bypass / Global mutable state in presentation
- Location `lib/core/widgets/app_feedback.dart:11`, `:48`, `:67-79`, `:88-92`, `:109`
- Evidence code block:
```dart
11:   static OverlayEntry? _activeEntry;
```
```dart
47:          child: Padding(
48:            padding: const EdgeInsets.all(16.0),
```
```dart
67:                  child: Container(
68:                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
69:                    decoration: BoxDecoration(
70:                      color: color ?? const Color(0xFF323232),
71:                      borderRadius: BorderRadius.circular(8),
72:                      boxShadow: const [
73:                        BoxShadow(
74:                          color: Colors.black26,
75:                          blurRadius: 8,
76:                          offset: Offset(0, 4),
77:                        )
78:                      ],
79:                    ),
```
```dart
86:                          child: Text(
87:                            message,
88:                            style: const TextStyle(
89:                              color: Colors.white,
90:                              fontSize: 14,
91:                              fontWeight: FontWeight.w500,
92:                            ),
```
```dart
109:    Future.delayed(const Duration(seconds: 3), () {
```
- Current behavior:
  - **إجابة السؤال 4 (النصوص)**: الملف **لا يُشفّر أي نص مستخدم** — كل النصوص تمرّ كمعامل `message` (`:13-23`)، ومواضع الاستدعاء في `features` ترسل `context.loc.*`. فالجانب اللغوي سليم.
  - **لكنه يتجاوز نظام التصميم بالكامل**: `app_theme.dart:141-151` يعرّف `snackBarTheme` كاملة (خلفية `AppColors.secondary`، زوايا `AppRadius.card`، `SnackBarBehavior.floating`). و`AppFeedback` يبني واجهة **مختلفة تماماً** بقيم مُشفّرة: `0xFF323232` (70) قيمة خارج `AppColors`، و`radius: 8` (71) بدل `AppRadius.card = 12`، وظل `black26/blur 8/offset(0,4)` (73-77) نسخة مُكرَّرة من `AppShadows.raised` (`app_shadows.dart:21-27`)، و`fontSize: 14` (90) و`EdgeInsets.all(16.0)` (48) بدل رموز `AppSpacing`.
  - **حالة عامة ثابتة**: `static OverlayEntry? _activeEntry` (11) حالة قابلة للتغيير على مستوى التطبيق كله داخل صنف واجهة، بلا Riverpod ولا حقن ولا `dispose`.
- Why problematic:
  1. **قناتان للرسالة**: `snackBarTheme` مُعرَّف لكنه غير مستخدم من `AppFeedback`، فتوجد فجوة بصرية مقصودة غير موثّقة.
  2. **قاعدة `AppColors` مكسورة**: `app_colors.dart:13` ينصّ على عدم إنشاء `Color(0x…)` جديد في الواجهات — والمُنتَج هنا واجهة.
  3. **`Future.delayed` غير قابل للإلغاء** (109): لا `Timer` يمكن إلغاؤه، فالإزالة قد تتنافس مع `onTap` أو مع السحب؛ والحالة العامة تسرّب بين الاختبارات.
  4. مستهلكوه يمتدّ إلى **خدمة نظام**: `lib/app/services/push_notification_service.dart:125` يستدعي `AppFeedback.info(context, '$title\n$body')` — أي أن خدمة في `app` تعتمد على صنف في `core/widgets` لعرض الإشعارات.
- Violated principle: Open/Closed + Dependency Inversion — خدمة الواجهة يجب أن تعتمد على نظام التصميم لا أن تعيد تطبيقه.
- Current owner: `lib/core/widgets/app_feedback.dart` (كصنف عرض)
- Correct owner: طبقة `core/presentation/feedback` كمزوّد Riverpod يعتمد على `Theme.of(context)` / `SnackBarThemeData`، أو استخدام `ScaffoldMessenger` مع `snackBarTheme` المعرَّف أصلاً.
- Consequences: ازدواج في التصميم، حالة عابرة للتطبيق، صعوبة في الاختبار، وسلوك عرض غير متسق مع الثيم.
- Recommended correction: استبدل البناء اليدوي بـ`ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: ...))` مع `snackBarTheme`؛ أو على الأقل اسحب كل القيم من `AppColors` و`AppRadius` و`AppSpacing` و`AppShadows` و`AppTypography`، واستبدل `_activeEntry` بمزوّد Riverpod، واستبدل `Future.delayed` بـ`Timer`.
- Related files: `lib/core/theme/app_theme.dart:141-151`, `lib/core/theme/app_shadows.dart:21-27`, `lib/core/theme/app_radius.dart:24`, `lib/core/theme/app_spacing.dart:10`, `lib/app/services/push_notification_service.dart:125`, `lib/app.dart:57-60`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-007: `app_theme.dart` يحمل قيم `Color(0x...)` خارج `AppColors` — أحدها تكرار حرفي
- Severity: **MINOR**
- Category: Design-token rule violation / Duplication
- Location `lib/core/theme/app_theme.dart:175`, `:215`, `:220`
- Evidence code block:
```dart
170:    radioTheme: RadioThemeData(
171:      fillColor: WidgetStateProperty.resolveWith((states) {
172:        if (states.contains(WidgetState.selected)) {
173:          return AppColors.primaryGold;
174:        }
175:        return const Color(0xFFC7C7CC);
176:      }),
```
```dart
214:    dividerTheme: light.dividerTheme.copyWith(
215:      color: const Color(0xFF48484A),
216:    ),
...
220:    disabledColor: const Color(0xFF8E8E93),
```
- Current behavior: `app_colors.dart:3` يعلن صراحةً أنه **الملف الوحيد الذي يحمل قيمة `Color(0x...)`** ويكررها في السطر 13. ثلاثة انتهاكات في نفس الملف:
  - `:175` قيمة `0xFFC7C7CC` بلا اسم ولا معنى دلالي.
  - `:215` قيمة `0xFF48484A` — فاصل داكن بلا رمز (يقابله `AppColors.darkBorder` في `:147` و`AppColors.border` في `:67`).
  - `:220` قيمة `0xFF8E8E93` — **تكرار حرفي كامل** لـ`app_colors.dart:124`.
- Evidence for the duplication:
```dart
// lib/core/theme/app_colors.dart
124:   static const Color navBarInactive = Color(0xFF8E8E93);
```
- Why problematic: وجود قيمة واحدة بلا اسم دلالي (`disabledColor`) وأخرى باسمها (`navBarInactive`) في الملفين يجعل «المصدر الوحيد» غير صحيح؛ وتغيير لون معطّل واحد يجب أن يمرّ بمكانين.
- Violated principle: Single source of truth — القاعدة التي أعلنها المشروع نفسه.
- Current owner: `lib/core/theme/app_theme.dart`
- Correct owner: `lib/core/theme/app_colors.dart` بأسماء دلالية (`radioUnselected`, `darkDivider`, `disabledGrey`).
- Consequences: انجراف لوني صامت؛ استثناءات متكررة بنفس القيمة.
- Recommended correction: أضف `radioUnselected = Color(0xFFC7C7CC)` و`darkDivider = Color(0xFF48484A)` و`disabledGrey = Color(0xFF8E8E93)` في `AppColors`، واستبدل `:220` بـ`AppColors.navBarInactive`.
- Related files: `lib/core/theme/app_colors.dart:3,13,67,124,147`, `lib/core/theme/app_typography.dart:2`, `lib/core/theme/press_feedback.dart:32-33`, `lib/core/theme/app_shadows.dart:14,23`, `lib/core/widgets/app_feedback.dart:70`
- Confidence: **CONFIRMED**

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
### ISSUE CUI-009: `eld_card.dart` يُعيد تعريف قيم `cardTheme` بدل استهلاك `AppDecorations.card`
- Severity: **MINOR**
- Category: Duplication inside core / Design-system bypass
- Location `lib/core/widgets/eld_card.dart:20-30`
- Evidence code block:
```dart
20:    return Card(
21:      clipBehavior: Clip.antiAlias,
22:      color: Theme.of(context).cardTheme.color ??
23:          Theme.of(context).colorScheme.surface,
24:      elevation: 0.5,
25:      shadowColor:
26:          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
27:      margin: EdgeInsets.zero,
28:      shape: RoundedRectangleBorder(
29:        borderRadius: BorderRadius.circular(AppRadius.card),
30:      ),
```
- Current behavior: **`eld_card.dart` يكرّر القيم الخمس نفسها حرفاً بحرف** كما في `app_theme.dart:50-58`:
```dart
50:    cardTheme: CardThemeData(
51:      color: AppColors.surface,
52:      elevation: 0.5,
53:      shadowColor: Colors.black.withValues(alpha: 0.05),
54:      shape: RoundedRectangleBorder(
55:        borderRadius: BorderRadius.circular(AppRadius.card),
56:      ),
57:      margin: EdgeInsets.zero,
58:    ),
```
  أي أن `eld_card.dart` **يلغي** ما عرّفه الثيم، ويجعل `shadowColor` مشتقاً من `onSurface` بدل `black` كما في الثيم.
- Why problematic: صنف في `core` يعيد تعريف نفس القيم الخمس؛ أي تعديل على `cardTheme` لن ينعكس على البطاقات الأكثر استخداماً.
- Violated principle: DRY / single source of truth for visual tokens.
- Current owner: `lib/core/widgets/eld_card.dart:20-30`
- Correct owner: `lib/core/theme/app_theme.dart:50-58` للقيم، و`lib/core/theme/app_decorations.dart:18-28` للزخرفة.
- Consequences: ازدواج بصري محتمل بين بطاقات `Card` وبطاقات `Container`.
- Recommended correction: احذف الصفات الخمس من `EldCard` واعتمد على `cardTheme`؛ أو استخدم `AppDecorations.card(context)` مع `Material`.
- Related files: `lib/core/theme/app_theme.dart:50-58`, `lib/core/theme/app_decorations.dart:18-28`, `lib/features/about/presentation/pages/about_page.dart:13`, `lib/features/settings/presentation/pages/settings_page.dart:11`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-010: نظام التصميم فيه بديلان متداخلان للشارة (`AppStatusBadge` و`AppStatusPill`)
- Severity: **MINOR**
- Category: Duplication inside core / Overlapping primitives
- Location `lib/core/widgets/app_status_pill.dart:28-51` و `lib/core/widgets/app_status_badge.dart:65-94`
- Evidence code block:
```dart
// lib/core/widgets/app_status_pill.dart
28:    return Container(
29:      padding: const EdgeInsets.symmetric(
30:        horizontal: AppSpacing.sm,
31:        vertical: 4,
32:      ),
33:      decoration: AppDecorations.tinted(color),
34:      child: Row(
35:        mainAxisSize: MainAxisSize.min,
36:        children: [
37:          if (icon != null) ...[
38:            Icon(icon, size: iconSize, color: color),
39:            const SizedBox(width: 6),
40:          ],
41:          Text(
42:            label,
43:            style: TextStyle(
44:              color: color,
45:              fontSize: 12,
46:              fontWeight: AppTypography.semiBold,
47:            ),
48:          ),
```
```dart
// lib/core/widgets/app_status_badge.dart
65:    return Container(
66:      padding: const EdgeInsets.symmetric(
67:        horizontal: AppSpacing.sm,
68:        vertical: AppSpacing.xs,
69:      ),
70:      decoration: BoxDecoration(
71:        color: _getBackgroundColor(brightness),
72:        borderRadius: BorderRadius.circular(AppRadius.badge),
73:      ),
74:      child: Row(
75:        mainAxisSize: MainAxisSize.min,
76:        children: [
77:          if (icon != null) ...[
78:            Icon(icon, size: 14, color: textColor),
```
- Current behavior: كلاهما: `Container` + `EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4)` + `Row(mainAxisSize: .min)` + أيقونة اختيارية + نص ملوّن. الفرق الوحيد: مصدر اللون (نوع محسوم داخلياً مقابل لون مُمرَّر) و`borderRadius` (`AppRadius.badge = 8` مقابل `AppRadius.pill = 999`).
- Why problematic: لا يوجد دليل في الملفات على أيّهما هو المعيار: `AppStatusPill` مُصدَّر من `core/design_system.dart:19` بينما `AppStatusBadge` لا. والاستهلاك في `features` منقسم: `app_status_badge` في أربعة ملفات، `app_status_pill` في ملف واحد (`features/dvir/presentation/pages/dvir_list_page.dart:11`).
- Violated principle: DRY / clear design-system API.
- Current owner: `lib/core/widgets/` (الاثنين)
- Correct owner: `lib/core/widgets/app_status_badge.dart` كوحيد، مع `variant: {pill, badge}`.
- Consequences: تباين بصري بين شارات في شاشات مختلفة؛ عبء معرفي للمطوّر.
- Recommended correction: ادمجهما في صنف واحد بأسلوب (`radius`) كمعامل؛ واحذف التصدير المفرد من `design_system.dart`.
- Related files: `lib/core/design_system.dart:19`, `lib/features/dvir/presentation/pages/dvir_list_page.dart:11,204`, `lib/features/vehicle/presentation/widget/vehicle_card.dart:4`, `lib/features/permissions/presentation/pages/permissions_page.dart:8`, `lib/features/codriver/presentation/pages/codriver_page.dart:7`, `lib/features/sync/presentation/widgets/sync_status_indicator.dart:5`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-011: `app_button.dart` يُعيد تنفيذ منطق الضغط بدل استهلاك `PressFeedback.pressed`
- Severity: **MINOR**
- Category: Duplication inside core / Design-system bypass
- Location `lib/core/widgets/app_button.dart:124-132` مقابل `lib/core/theme/press_feedback.dart:25-30`
- Evidence code block:
```dart
124:    final overlay = _isOutlined
125:        ? AppColors.primaryGold.withValues(alpha: 0.12)
126:        : (widget.type == EldButtonType.danger
127:            ? Colors.white.withValues(alpha: 0.28)
128:            : Colors.black.withValues(alpha: 0.24));
...
130:    final color = _pressed && _enabled
131:        ? (_isOutlined ? overlay : Color.alphaBlend(overlay, base))
132:        : base;
```
```dart
// lib/core/theme/press_feedback.dart
25:  static Color pressed(Color base, {bool onDark = false}) {
26:    return Color.alphaBlend(
27:      (onDark ? Colors.white : Colors.black).withValues(alpha: 0.20),
28:      base,
29:    );
30:  }
```
- Current behavior: `AppButton` يحمل حالته `_pressed` (`:51`) ويدمج `overlay` بنفسه بقيمة `alpha 0.24`، بينما `PressFeedback.pressed` تستخدم `0.20`. **قيمتان مختلفتان في ملفين لنفس التأثير**، و`app_button.dart` لا يستورد `press_feedback.dart` إطلاقاً رغم أنه في نفس `core`.
- Why problematic: صنفان في نفس المجلد يُعطيان استجابة ضغط مختلفة قليلاً، بينما الثيم كله يستورد `PressFeedback` (`app_theme.dart:32,70,81,89,99,108`).
- Violated principle: DRY / consistent color token.
- Current owner: `lib/core/widgets/app_button.dart:124-132`
- Correct owner: `lib/core/theme/press_feedback.dart:25-30`
- Consequences: تفاوت بصري بين أزرار `AppButton` وأزرار الثيم.
- Recommended correction: استدعِ `PressFeedback.pressed(base, onDark: ...)` واحذف الدمج اليدوي، أو وحّد قيمة `alpha` في مكان واحد.
- Related files: `lib/core/theme/press_feedback.dart:8-30`, `lib/core/theme/app_theme.dart:32-33,70-73`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-012: `app_signature_canvas.dart` يكسر الوضع الداكن بألوان خام وأحجام خطوط مُشفّرة
- Severity: **MINOR**
- Category: Theme-awareness defect / Design-token bypass
- Location `lib/core/widgets/app_signature_canvas.dart:71`, `:94`, `:137-138`, `:120`, `:157`
- Evidence code block:
```dart
70:            decoration: BoxDecoration(
71:              color: Colors.white,
72:              border: Border.all(
```
```dart
93:                          style: placeholderStyle ??
94:                              context.styles.subtitle.copyWith(fontSize: 16),
```
```dart
134:                      child: Text(
135:                        loc.clearSignature,
136:                        style: context.styles.body.copyWith(
137:                          fontSize: 14,
138:                          color: Colors.black,
139:                          decoration: TextDecoration.underline,
140:                          decorationStyle: TextDecorationStyle.dotted,
141:                        ),
142:                      ),
```
```dart
171:                      child: Text(
172:                        loc.clearSignature,
173:                        style: context.styles.subtitle.copyWith(
174:                          decoration: TextDecoration.underline,
175:                          decorationStyle: TextDecorationStyle.dotted,
176:                        ),
```
- Current behavior: اللوحة **بيضاء دائماً** (`:71`) لأن الحبر يجب أن يكون داكناً — وهو قرار عملي مشروع. لكن **رابط «مسح» في فرع `centerClear` يُكتب بـ`Colors.black` صراحةً** (`:138`) بينما النسخة الممتدة في `:173` تستخدم `context.styles.subtitle` — أي أن **فرعين من نفس الرابط ينتجان ألواناً مختلفة في الوضع الداكن**. كذلك `fontSize: 16` (`:94`) و`fontSize: 14` (`:137`) و`fontSize: 12` (`:120`, `:157`) تتجاوز رموز `AppTypography`.
- Why problematic: الملف موثّق في تروسته (`:9-10`) على أنه theme-aware، لكن هذا الفرع يكسر الوضع الداكن، والفرعان غير متسقين.
- Violated principle: Design-system consistency / Dark-mode correctness.
- Current owner: `lib/core/widgets/app_signature_canvas.dart:138`
- Correct owner: `context.styles.subtitle.color` أو رمز جديد في `AppColors` (على نمط `AppColors.checkSquare` في `app_colors.dart:106`).
- Consequences: نص أسود على خلفية داكنة في فرع واحد فقط.
- Recommended correction: استبدل `color: Colors.black` بـ`color: context.styles.subtitle.color`، واحذف أحجام `fontSize` الصريحة لصالح `AppStyles`.
- Related files: `lib/core/theme/app_typography.dart:11-18`, `lib/core/theme/app_colors.dart:104-106`, `lib/features/dvir/presentation/widgets/dvir_form_sections.dart:8`, `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart:6`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-014: `eld_info_row.dart` يُعيد تنفيذ ألوان الضغط بدل `PressFeedback`
- Severity: **MINOR**
- Category: Design-system bypass / Hardcoded interaction colors
- Location `lib/core/widgets/eld_info_row.dart:23-26`
- Evidence code block:
```dart
23:    return InkWell(
24:      onTap: onTap,
25:      splashColor: Colors.black.withValues(alpha: 0.12),
26:      highlightColor: Colors.black.withValues(alpha: 0.06),
```
- Current behavior: قيم تفاعل مُشفّرة (0.12 و0.06)، بينما `PressFeedback.overlay()` في `press_feedback.dart:8-23` يقدّم 0.18 و0.06 — والدالة موجودة ومستخدمة في كل الثيم (`app_theme.dart:73,84,94,102,111,202`). والملف لا يستورد `press_feedback.dart`.
- Why problematic: صنف مشترك في `core` يخالف القاعدة التي يعلنها `app_shadows.dart:6-7` (عدم كتابة قيم التصميم مباشرة في الشاشات)، بمثلها في اللون.
- Violated principle: DRY / design-token adoption.
- Current owner: `lib/core/widgets/eld_info_row.dart:25-26`
- Correct owner: `lib/core/theme/press_feedback.dart:8-23`
- Consequences: تفاوت طفيف في الاستجابة بين الصفوف وبقية التطبيق.
- Recommended correction: احذف السطرين أو استخدم `PressFeedback.overlay()`.
- Related files: `lib/core/theme/press_feedback.dart:8-23`, `lib/core/theme/app_theme.dart:73`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-015: `dashed_line_painter.dart` لا يُعيد الرسم أبداً عند تغيّر اللون
- Severity: **MINOR**
- Category: Functional defect in design-system primitive
- Location `lib/core/widgets/dashed_line_painter.dart:4-5`, `:22-23`
- Evidence code block:
```dart
3: class DashedLinePainter extends CustomPainter {
4:   final Color color;
5:   DashedLinePainter({required this.color});
```
```dart
22:   @override
23:   bool shouldRepaint(CustomPainter oldDelegate) => false;
```
- Current behavior: `color` حقل `final` يُقرأ في `paint` (`:10`) لكن `shouldRepaint` يُرجع `false` دائماً. أي تغيير في اللون (فاتح/داكن/كيان مختلف) **لن يُعيد البناء البصري**؛ ستبقى الطبقة الملوّنة القديمة.
- Why problematic: أصل وظيفي في `core` مستهلك من `lib/features/logs/presentation/pages/edit_log_page.dart:20`.
- Violated principle: Correctness of a reusable design-system primitive.
- Current owner: `lib/core/widgets/dashed_line_painter.dart:23`
- Correct owner: نفس الملف (إصلاح)
- Consequences: خط متقطع بلون قديم بعد تبديل الوضع أو الكيان.
- Recommended correction: `bool shouldRepaint(covariant DashedLinePainter old) => old.color != color;`
- Related files: `lib/features/logs/presentation/pages/edit_log_page.dart:20`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-016: مواضع في `features/**` تُعيد تنفيذ ما تقدمه `core/widgets` (تكميم)
- Severity: **MODERATE**
- Category: Duplication / Shared-widget bypass
- Location المرجع: `lib/core/widgets/eld_retry_view.dart:22-50` مقابل خمسة مواضع في `features`
- Evidence code block:
```dart
// المرجع — lib/core/widgets/eld_retry_view.dart:36-45
36:            IconButton(
37:              tooltip: context.loc.retryButton,
38:              iconSize: 40,
39:              color: context.styles.gold.color,
40:              onPressed: onRetry,
41:              icon: Icon(
42:                Icons.refresh,
43:                color: context.styles.gold.color,
44:              ),
45:            ),
```
```dart
// إعادة تنفيذ 1 — lib/features/logs/presentation/pages/edit_log_page.dart:379-395
379:            : vehicleState.error != null && vehicles.isEmpty
380:                ? Column(
381:                    mainAxisSize: MainAxisSize.min,
382:                    children: [
383:                      Text(
384:                        vehicleState.error!,
385:                        style: context.styles.error,
386:                      ),
387:                      const SizedBox(height: 8),
388:                      TextButton(
389:                        onPressed: () => ref
390:                            .read(vehicleProvider.notifier)
391:                            .loadVehicles(forceRefresh: true),
392:                        child: Text(context.loc.retryButton),
393:                      ),
394:                    ],
395:                  )
```
```dart
// إعادة تنفيذ 2 — lib/features/logs/presentation/pages/unidentified_events_page.dart:247-258
247:                if (state.error != null)
248:                  MaterialBanner(
249:                    content: Text(state.error!, style: context.styles.error),
250:                    actions: [
251:                      TextButton(
252:                        onPressed: _load,
253:                        child: Text(
254:                          context.loc.retryButton,
255:                        ),
256:                      ),
257:                    ],
258:                  ),
```
- Current behavior: التكميم الكامل في القسم C. الخلاصة: **`EldRetryView` مُستخدم في ثمانية ملفات**، ومع ذلك **خمسة مواضع** في `features` تُصمّم واجهة «رسالة + إعادة محاولة» يدوياً.
- Why problematic: عدم اتساق في الشكل والحجم والموضع بين الشاشات؛ وصعوبة تطبيق أي تحسين مركزي.
- Violated principle: DRY / shared-component adoption.
- Current owner: الصفحات في `features`
- Correct owner: `lib/core/widgets/eld_retry_view.dart`
- Consequences: خمسة أنماط مختلفة للخطأ نفسه.
- Recommended correction: وحّد الاستخدام؛ واعتمد `AppStatusPill` أو `AppStatusBadge` بدلاً من البطاقات اليدوية في `active_defects_section.dart`.
- Related files: انظر جدول القسم C.
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-017: خمسة عناصر في `core/widgets` تحمل بادئة `Eld` دون أن تحمل مسؤولية ELD
- Severity: **MINOR**
- Category: Naming / cohesion (ليست مخالفة مسؤولية)
- Location `lib/core/widgets/eld_card.dart:5-6`, `eld_info_row.dart:4-5`, `eld_retry_view.dart:6-7`, `eld_date_paginator.dart:5`, `eld_events_table.dart:6-26`
- Evidence code block:
```dart
// lib/core/widgets/eld_card.dart
 5: /// بطاقة بيانات ELD - خلفية بيضاء مع ظل خفيف
 6: class EldCard extends StatelessWidget {
```
```dart
// lib/core/widgets/eld_info_row.dart
 4: /// صف معلومات - عنوان رمادي على اليسار، قيمة سوداء على اليمين
 5: class EldInfoRow extends StatelessWidget {
```
```dart
// lib/core/widgets/eld_retry_view.dart
 6: /// Empty/error placeholder: short message + circular retry.
 7: class EldRetryView extends StatelessWidget {
```
- Current behavior: **تأكيد صريح: هذه الملفات متوافقة.** `EldCard` هي `Card` مع `InkWell` (لا ELD)، و`EldInfoRow` صف عنوان وقيمة (لا ELD)، و`EldRetryView` خطأ وزر (لا ELD)، و`EldDatePaginator` تنقّل بين تاريخين (لا ELD). البادئة **تسمية زائفة فقط**؛ المسؤوليات كلها عرضية محضة.
- Why problematic: بادئة `Eld` داخل مجلد `core/` توحي بأن `core` مربوط بمجال ELD، وهو ما يفتح الباب أمام تسرّب مثل CUI-001 و CUI-004.
- Violated principle: Clear naming / cohesion signaling — ولا يُعد مخالفة تصميمية بحد ذاته.
- Current owner: `lib/core/widgets/*.dart`
- Correct owner: نفس الملفات بأسماء عامة (`AppCard`, `AppInfoRow`, `AppRetryView`, `AppDatePaginator`)؛ ويُبقي `EldEventsTable` و `EldGraphGrid` على حالهما لأنهما فعلاً تخصصيان.
- Consequences: الالتباس بين المعمارية والاسم.
- Recommended correction: إعادة تسمية تدريجية؛ ليست أولوية قصوى.
- Related files: `lib/core/widgets/eld_card.dart`, `lib/core/widgets/eld_info_row.dart`, `lib/core/widgets/eld_retry_view.dart`, `lib/core/widgets/eld_date_paginator.dart`
- Confidence: **CONFIRMED** (وقائعها) — **لا يُعد مخالفة مسؤولية**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-018: قياسات ومقاسات مُشفّرة تتجاوز رموز `AppTypography` و `AppSpacing`
- Severity: **MINOR**
- Category: Design-token bypass
- Location `lib/core/theme/app_styles.dart:157`، `lib/core/widgets/app_status_badge.dart:84`، `app_status_pill.dart:21,31,45`
- Evidence code block:
```dart
// lib/core/theme/app_styles.dart
156:      number: TextStyle(
157:        fontSize: 18,
158:        fontWeight: AppTypography.bold,
```
```dart
// lib/core/widgets/app_status_badge.dart
81:          Text(
82:            label,
83:            style: const TextStyle(
84:              fontSize: 11,
85:              fontWeight: AppTypography.bold,
86:            ).copyWith(color: textColor),
```
```dart
// lib/core/widgets/app_status_pill.dart
21:    this.iconSize = 8.0,
...
29:      padding: const EdgeInsets.symmetric(
30:        horizontal: AppSpacing.sm,
31:        vertical: 4,
32:      ),
...
45:              fontSize: 12,
```
- Current behavior: `AppTypography` يعرّف سلماً كاملاً (`smallSize = 12.0` و `captionSize = 13.0` في `app_typography.dart:14-18`)، و`AppSpacing.xs = 4.0` في `app_spacing.dart:6`. ومع ذلك تُكتب `18` و`11` و`8.0` و`4` و`12` يدوياً.
- Why problematic: `11` و`12` و`8` تعني قياسات الشارات؛ لو أُضيف مقاس «شارة» للسلّم لبُني على `AppStyles` وحده.
- Violated principle: Design tokens.
- Current owner: الملفات المذكورة
- Correct owner: `AppTypography` و `AppSpacing`
- Consequences: صعوبة تغيير مقاس موحد للشارات.
- Recommended correction: أضف `badgeSize = 11.0` واستبدل؛ واستخدم `AppSpacing.xs` بدل `4`.
- Related files: `lib/core/theme/app_typography.dart:11-18`, `lib/core/theme/app_spacing.dart:6-10`
- Confidence: **CONFIRMED**

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
### ISSUE CUI-020: رموز تصميمية ميتة وشيفرات توافق غير مستخدمة في `core/theme`
- Severity: **MINOR**
- Category: Dead code in design system
- Location `lib/core/theme/app_typography.dart:9`، `app_colors.dart:28-29,95,109-111`، `press_feedback.dart:33`، `app_styles.dart:174-178`
- Evidence code block:
```dart
// lib/core/theme/app_typography.dart
 9:   static const String fontFamilyIOS = 'SF Pro Text';
```
```dart
// lib/core/theme/app_styles.dart
173:   /// توافق خلفي — استخدم [AppStyles.fromBrightness].
174:   // ignore: deprecated_member_use_from_same_package
175:   static AppStyles light() => AppStyles.fromBrightness(Brightness.light);
176:
177:   /// توافق خلفي — استخدم [AppStyles.fromBrightness].
178:   static AppStyles dark() => AppStyles.fromBrightness(Brightness.dark);
```
- Current behavior: بحث على `lib/**/*.dart` أعطى:
  - `fontFamilyIOS` — **1** استخدام (التعريف نفسه).
  - `goldLight` — **1**، `goldDark` — **1**، `darkGoldBg` — **1**، `rodsHeaderBg` و `rodsHeaderText` و `rodsHeaderSubtext` — **1** لكل منها (تعريف فقط).
  - `inkOnDark` — **1** (تعريف فقط).
  - `AppStyles.light()` و `AppStyles.dark()` — **صفر** استدعاء في كامل المشروع.
  - كما أن `// ignore: deprecated_member_use_from_same_package` في `:174` **لا مبرر له**: لا يوجد رمز مهمَل في نفس الحزمة.
- Why problematic: واجهة نظام التصميم تعلن رموزاً غير مستخدمة، و`AppStyles.light()/dark()` موصوفة كـ«توافق خلفي» دون أي مستهلكين.
- Violated principle: YAGNI / accurate API surface.
- Current owner: الملفات المذكورة
- Correct owner: — (حذف)
- Consequences: فوضى في وثائق التصميم؛ وخطر استخدام رمز ميت لاحقاً.
- Recommended correction: احذف الرموز الميتة وشيفرة التوافق، أو وثّقها بوضوح كـ«reserved».
- Related files: `lib/core/design_system.dart:8-17`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-021: `eld_date_paginator.dart` يعتمد افتراضياً على رمز لوني مخصص لمعاينة التفتيش
- Severity: **MINOR**
- Category: Cohesion / design-token misuse
- Location `lib/core/widgets/eld_date_paginator.dart:31`
- Evidence code block:
```dart
29:  @override
30:  Widget build(BuildContext context) {
31:    final effectiveBgColor = backgroundColor ?? context.previewBand;
```
```dart
// lib/core/extensions/context_extensions.dart
110:  /// شريط رأس معاينة التفتيش — داكن في الوضعين بدرجة لكل وضع.
111:  Color get previewBand => isDark ? AppColors.darkBorder : AppColors.surfaceDark;
```
- Current behavior: widget عام في `core` ينسب خلفيته الافتراضية إلى رمز موصوف صراحةً بأنه «شريط رأس معاينة التفتيش»، وهو سياق صفحة واحدة من `features/inspection`. وقيمته داكنة في الوضعين.
- Why problematic: نقل رمز مخصص لصفحة إلى صنف مشترك يجعل تغيّر تصميم صفحة التفتيش يكسر التباين في الصفحات الأخرى التي تستخدم `EldDatePaginator` مثل `inspection_active_view.dart:13`.
- Violated principle: Correct token ownership / no page-specific tokens in shared widgets.
- Current owner: `lib/core/widgets/eld_date_paginator.dart:31`
- Correct owner: `lib/core/theme/app_colors.dart` برمز محايد، أو اجعل `backgroundColor` مطلوباً.
- Consequences: ارتباط غير مقصود.
- Recommended correction: مرّر اللون إجبارياً، أو عرّف رمزاً محايداً في `AppColors`.
- Related files: `lib/core/extensions/context_extensions.dart:102-111`, `lib/core/theme/app_colors.dart:98-101,147`, `lib/features/inspection/presentation/pages/inspection_active_view.dart:13`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-001: اختراع `deviceId` المركبة من regex داخل Widget
- **Severity:** Critical
- **Category:** Business Logic in Presentation / Data Integrity
- **Location:** `lib/features/dvir/presentation/pages/dvir_form_page.dart:463-476`
- **Evidence:**
```dart
    if (resolvedDeviceId == null) {
      final directInt = int.tryParse(reportVehicleId);
      if (directInt != null && directInt > 0) {
        resolvedDeviceId = directInt;
      } else {
        final match = RegExp(r'\d+').firstMatch(reportVehicleId);
        if (match != null) {
          final digits = int.tryParse(match.group(0)!);
          if (digits != null && digits > 0) {
            resolvedDeviceId = digits;
          }
        }
      }
    }
```
- **Current behavior:** إذا لم يُعثر على `deviceId` من `dashboard` أو `selectedVehicle` أو قائمة المركبات، تستخرج الـ Widget **أول سلسلة أرقام من نص اسم/معرّف المركبة** وتستخدمها كـ Traccar `deviceId` في جسم DVIR الرسمي.
- **Why problematic:** (أ) مخالفة مباشرة للمبدأ المعلن في **نفس الـ feature**: `dvir_mappers.dart:119-121` يقول «الخادم يرفض إنشاء الفحص بلا معرف جهاز المركبة (deviceId) — لا جسم ناقص ولا اختراع قيمة». (ب) أي رقم في الاسم (سنة الصنع، رقم اللوحة) يصبح **معرّف جهاز قانوني مزيّف** في سجل CMV. (ج) قاعدة سلامة بيانات في وثيقة رسمية، غير قابلة للاختبار ولا للوحدة.
- **Violated principle:** SRP (Widget = عرض)، Domain Model Integrity، «لا قيم مخترعة».
- **Current owner:** `_DvirFormPageState._handleSubmit`
- **Correct owner:** `DvirRepositoryImpl` أو use-case في `dvir/domain/usecases/`
- **Consequences:** DVIR official record قد يشير إلى جهاز غير موجود؛ احتمال رفض أو قبول خاطئ لـ `POST /eld/dvir`؛ قاعدة غير قابلة للاختبار.
- **Recommended correction:** حذف فرع الـ regex كاملاً؛ الاكتفاء بـ `dashboard.deviceId` / `selectedVehicle.deviceId` / `vehicles.firstWhere((v) => v.deviceId != null && v.deviceId! > 0)`؛ عند الغياب → `Left(ServerFailure('deviceId required'))`. نقل القاعدة إلى domain.
- **Related files:** `dvir_mappers.dart:119-125`, `dvir_repository_impl.dart:245-263`
- **Confidence:** **CONFIRMED**

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
### ISSUE DST-006: قاعدة DVIR-09 مثبتة ثلاث مرات (widget + data + data)
- **Severity:** High
- **Category:** Duplicated Business Rule
- **Location:** `lib/features/dvir/presentation/pages/dvir_form_page.dart:202-206` (ومكرّر في `:231-235` و `:259-263`)
- **Evidence:**
```dart
    setState(() {
      _selectedDefects = [...picked, ...trailerDefects];
      _vehicleDefectsController.text =
          picked.map((d) => d.item.label(context.loc)).join(', ');
      if (_selectedDefects.isNotEmpty) {
        _selectedStatus = DvirConditionStatus.hasDefects;
      } else if (_trailerDefectsController.text.trim().isEmpty) {
        _selectedStatus = DvirConditionStatus.satisfactory;
      }
    });
```
- **Current behavior:** Widget يعيد اشتقاق الحالة القانونية من الاختيارات — ثلاث مرات في نفس الملف.
- **Why problematic:** قاعدة **قانونية** (DVIR-09، SRS 7.1/7.6) لها **خمس نسخ** في نفس الـ feature (Widget×3 + Repository + Mapper). تغيير معيار «العيوب غير المعالجة» في مكان واحد يجعل الأربع الأخرى غير متسقة.
- **Violated principle:** DRY، Single Source of Truth، Business Logic in Presentation.
- **Current owner:** Widget ×3 + Repository + Mapper.
- **Correct owner:** دالة في `dvir/domain/` مثل `resolveConditionStatus({required DvirConditionStatus chosen, required bool hasAnyDefect})`.
- **Consequences:** DVIR قد يُرسل بحالة `Satisfactory` مع عيوب مسجلة لو أُزيل فرع من Widget فقط.
- **Recommended correction:** استخراج الدالة إلى domain واستدعاؤها من المواضع الخمسة.
- **Related files:** `dvir_repository_impl.dart:235-239`, `dvir_mappers.dart:137-141`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-008: ابتلاع الاستثناءات بلا أثر
- **Severity:** Medium
- **Category:** Swallowed Exception
- **Location:** `lib/features/dvir/presentation/widgets/active_defects_section.dart:123-126`
- **Evidence:**
```dart
    setState(() {
      _refreshing = false;
      result.fold((_) {}, (fresh) => _defect = fresh);
    });
```
- **Current behavior:** فشل `getDefectDetails` **يُسقط بصمت** — لا سجل ولا واجهة.
- **Why problematic:** الملف نفسه يَعِد بـ «فشل التحديث يُبقي المعروض» (سطر 98)، وهو صحيح وظيفياً، لكن **الفشل غير مرئي إطلاقاً** ⇒ لا تشخيص ميداني لأعطال «التفاصيل لا تتحدّث».
- **Violated principle:** Error Handling / Observability.
- **Current owner:** Widget
- **Correct owner:** Widget مع تسجيل، أو `dvirProvider` مع حالة خطأ صريحة.
- **Consequences:** لا يمكن تشخيص العطل ميدانياً.
- **Recommended correction:** إضافة `AppLogger.warning` على فرع `Left`، واعتماد `if (result case Right(:final fresh))` لزيادة الوضوح.
- **Related files:** `dvir/data/providers/dvir_repository_providers.dart:1-17`, `sync/data/datasources/sync_local_data_source.dart:25-30`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-009: رقمان مختلفان لنفس التحويل الفيزيائي داخل نفس الـ feature
- **Severity:** Low
- **Category:** Hardcoded Value (Business/Environment)
- **Location:** `lib/features/inspection/data/services/fmcsa_eld_output_generator.dart:118` و `:144` مقابل `lib/features/inspection/presentation/widgets/inspection_log_header_table.dart:96-97`
- **Evidence:**
```dart
// fmcsa_eld_output_generator.dart:118
      '3,$seq,1,1,1,$fileDate,000000,${(startOdo * 0.621371).toStringAsFixed(1)},...
// fmcsa_eld_output_generator.dart:144
        final miles = (event.odometer * 0.621371).toStringAsFixed(1);
// inspection_log_header_table.dart:96-97
  static const double _kmPerMile = 1.609344;
  static String _mi(double km) => (km / _kmPerMile).toStringAsFixed(0);
```
- **Current behavior:** تحويل km→mile بـ **0.621371** في مولّد الملف (data) وبـ **1.609344** في جدول العرض (presentation) — داخل نفس الميزة.
- **Why problematic:** (أ) **قيمة أعمال** (وحدات ملف 49 CFR A.3.1.1) في data بلا مرجع. (ب) **رقمان مختلفان** لنفس التحويل ⇒ انحراف بين الملف الرسمي وما يعرضه الضابط على الشاشة.
- **Violated principle:** DRY، Business Constants Placement.
- **Current owner:** ملفان في طبقتين.
- **Correct owner:** `core/constants/fmcsa_constants.dart` (موجود ويستخدمه `tracking_orchestrator.dart:40-47`).
- **Consequences:** ملف CSV وورقة RODS يعرضان مسافات مختلفة لنفس البيانات.
- **Recommended correction:** ثابت واحد `kmToMiles` في `FmcsaConstants`.
- **Related files:** `lib/core/constants/fmcsa_constants.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-010: ~25 getter اشتقاقية داخل Widget جدول
- **Severity:** Medium
- **Category:** Business Logic in Presentation
- **Location:** `lib/features/inspection/presentation/widgets/inspection_log_header_table.dart:33-127`
- **Evidence:**
```dart
  List<String> get _diagList => {
        ...?day?.activeDataDiagnostics,
        ...?log?.activeDataDiagnostics,
      }.toList();
  List<String> get _malfList => {
        ...?day?.activeDeviceMalfunctions,
        ...?log?.activeDeviceMalfunctions,
      }.toList();
  ...
  // 395.8(k)/8.3 — an indicator that is ON must say which code(s) are active.
  String get _diagCodes => _diagList.join(', ');
  String get _malfCodes => _malfList.join(', ');
```
- **Current behavior:** Widget يحوي `_pick` (سلسلة أفضلية log→day→screen)، `_num` (اختيار القيمة غير الصفرية)، `_odometer` (تركيب نطاق)، `_diagList`/`_malfList` (اتحاد)، `_carrier` (تركيب name + DOT#)، `_unidentified` (دمج منطقين).
- **Why problematic:** (أ) قواعد 49 CFR §395.8(k) و SRS 8.3 **مطبَّقة في Widget**. (ب) غير قابلة للاختبار إلا بـ widget test. (ج) أي مسار آخر يحتاج ورقة RODS (طباعة/تصدير) سيكرّر القاعدة يدوياً.
- **Violated principle:** Domain Model، SRP.
- **Current owner:** Widget.
- **Correct owner:** view-model نقي في `inspection/domain/` مثل `RodsRow.from(log, day, screen)`.
- **Consequences:** تكرار القاعدة عند أي مخرج آخر.
- **Recommended correction:** استخراج view-model إلى domain؛ يبقى Widget عارضاً فقط.
- **Related files:** `inspection_active_view.dart:83-90`
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
### ISSUE DST-014: تصنيف حالة/شدة العيب بمقارنة نصوص داخل Widget
- **Severity:** Medium
- **Category:** Business Logic in Presentation / Duplicated Rule
- **Location:** `lib/features/dvir/presentation/pages/dvir_list_page.dart:145-147` و `lib/features/dvir/presentation/widgets/active_defects_section.dart:66-71`
- **Evidence:**
```dart
// dvir_list_page.dart:145-147
    final openCount = activeDefects != null
        ? activeDefects.where((d) => d.stage?.toUpperCase() == 'OPEN').length
        : summary.openDefects;
```
```dart
// active_defects_section.dart:66-71
    final text = (severity ?? '').toUpperCase();
    final color = text.contains('HIGH')
        ? AppColors.dangerRed
        : text.contains('MED')
            ? AppColors.warningYellow
            : AppColors.successGreen;
```
- **Current behavior:** (أ) Widget يقارن `'OPEN'` نصياً بينما `DefectLifecycleStage.open.wire == 'OPEN'` موجود في domain. (ب) Widget يصنّف الشدة بـ **substring match** (`contains('MED')`) بينما `DefectSeverity.fromWire` موجود ويستخدم `==`.
- **Why problematic:** قيمة جديدة مثل `'MEDIUM_CRITICAL'` أو `'off_duty'` تُصنَّف خطأً؛ والمطابقة بالسلسلة الفرعية هشّة بطبيعتها.
- **Violated principle:** DRY، Type Safety، Business Logic in Presentation.
- **Current owner:** Widget ×2
- **Correct owner:** `DefectSeverity.fromWire` / `DefectLifecycleStage.fromWire` (موجودان في `defect_enums.dart:11-16` و `30-36`).
- **Consequences:** تلوين خاطئ لشدة العيب — مؤشر سلامة ظاهر للسائق.
- **Recommended correction:** في mapper: `severity: DefectSeverity.fromWire(json['severity'])`؛ ثم `switch` على الـ enum في الـ Widget.
- **Related files:** `dvir/domain/defect_enums.dart:11-36`, `dvir/data/mappers/dvir_defect_mappers.dart:21-22`
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
### ISSUE DST-019: صفحات تُطلق side-effects على مزوّدات features أخرى
- **Severity:** Low
- **Category:** Cross-Feature Side Effects from UI
- **Location:** `lib/features/inspection/presentation/pages/dot_inspection_page.dart:63-65`، `lib/features/vehicle/presentation/pages/select_vehicle_page.dart:84-92`
- **Evidence:**
```dart
// dot_inspection_page.dart:63-65
    if (ref.read(inspectionProvider).isInspectionMode) {
      ref.read(accountProvider.notifier).fetchMyAccount();
    }
```
```dart
// select_vehicle_page.dart:84-92
    final state = ref.read(vehicleProvider);
    if (state.isSuccess && state.selectedVehicle != null) {
      final v = state.selectedVehicle!;
      ref.read(dashboardDataProvider.notifier).updateVehicle(v);
      final uid = v.uniqueId;
      if (v.deviceId != null) {
        ref.read(localStorageProvider).setDeviceId(v.deviceId.toString());
      } else if (uid != null && uid.isNotEmpty) {
        ref.read(localStorageProvider).setDeviceId(uid);
      }
    }
```
- **Current behavior:** صفحات presentation تستدعي notifiers لميزات أخرى كأثر جانبي، وصفحة **`select_vehicle_page` تكتب تخزين الجهاز مباشرة**.
- **Why problematic:** (أ) `setDeviceId` من Widget = side effect على device storage خارج دورة حياة أي feature. (ب) لا orchestrator ينسّق هذه الإجراء رغم وجود `app/orchestrators/tracking_orchestrator.dart` كنموذج صالح.
- **Violated principle:** UI Purity، Orchestration Placement.
- **Current owner:** Widgets.
- **Correct owner:** `app/orchestrators/*.dart` يستمع للحالة.
- **Consequences:** إعادة تحميل حساب عند كل تفتيش؛ تغيّر `deviceId` من صفحة بلا event.
- **Recommended correction:** نقل الـ trigger إلى orchestrator يستمع `vehicleProvider` / `inspectionProvider`.
- **Related files:** `app/orchestrators/tracking_orchestrator.dart:87-95` (النمط الصحيح موجود)
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-020: parsing الوقت وتصنيف رموز duty داخل Widget
- **Severity:** Medium
- **Category:** Business Logic / Parsing in Presentation
- **Location:** `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart:75-162`
- **Evidence:**
```dart
  static String _rowOf(DotInspectionEvent event) {
    // The standard duty code is authoritative; free-text matching below is
    // only a fallback for servers that send descriptive codes.
    switch (event.eventCode.trim().toUpperCase()) {
      case '1':
      case 'OFF':
        return 'OFF';
```
  و `_hourOf` (سطر 75) يحلل **5 صيغ وقت**: ISO، epoch (10/13 رقماً)، AM/PM بـ regex، `HH:mm`، و`HHMM`.
- **Current behavior:** Widget (أ) يحلل نص الوقت القادم من الخادم إلى ساعة عشرية، (ب) يصنّف كود الحالة بنص حر مع 5 regex احتياطية، ويعيد `'OFF'` كقيمة fallback افتراضية (سطر 161).
- **Why problematic:** (أ) `DutyStatusCode.fromAny(...)` **موجود في domain** ويستخدمه `fmcsa_eld_output_generator.dart:206`. (ب) تحليل الوقت **مكرر المنطق** مع `FmcsaEldOutputGenerator._parseTimeToHHmmss:191-203`. (ج) fallback `'OFF'` يخفي فشل التصنيف بصمت.
- **Violated principle:** DRY، Parsing Layer Placement.
- **Current owner:** Widget.
- **Correct owner:** `lib/domain/duty_status/` للرمز؛ `core/time/` لتحليل الوقت.
- **Consequences:** رسم بياني خاطئ عند أي صيغة جديدة من الخادم، بصمت.
- **Recommended correction:** `_rowOf` → `DutyStatusCode.fromAny(event.eventCode).wire`؛ `_hourOf` → دالة في `core/time/parse_eld_time.dart`.
- **Related files:** `lib/domain/duty_status/duty_status_code.dart`, `inspection/data/services/fmcsa_eld_output_generator.dart:191-206`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DST-021: صفحة التفتيش تكتب سجل تدقيق عبر data layer لميزة أخرى
- **Severity:** Medium
- **Category:** Cross-Feature Implementation Dependency
- **Location:** `lib/features/inspection/presentation/pages/send_logs_page.dart:11` و `:126-141`
- **Evidence:**
```dart
import '../../../../features/logs/data/providers/log_repository_providers.dart';
```
```dart
      await ref
          .read(logRepositoryProvider)
          .logAudit(
            AuditEntry(
              id: 'transfer-${DateTime.now().millisecondsSinceEpoch}',
              timestamp: DateTime.now(),
              driverId: driverId?.toString() ?? '',
              newStatus: outcome.accepted ? 'SENT' : 'FAILED',
              reason: errorText ?? _commentController.text,
              action: widget.isEmailMode ? 'email_logs' : 'send_logs',
              entityType: 'transfer',
```
- **Current behavior:** صفحة presentation في `inspection` تستدعي **مزوّد data** من `logs` مباشرة وتبني كيان `AuditEntry` من `logs/domain`.
- **Why problematic:** (أ) استيراد `data/providers` من presentation = **تجاوز طبقي**؛ الواجهة يجب أن talk إلى use-case أو عقد لا إلى data layer. (ب) `id` مولّد بـ `millisecondsSinceEpoch` ⇒ **احتمال تصادم** عند إرسالين في نفس المللي ثانية. (ج) ثلاث جهات محتملة لكتابة التدقيق بلا عقد موحد.
- **Violated principle:** Dependency Rule، Feature Isolation.
- **Current owner:** Widget.
- **Correct owner:** use-case في `logs/domain/usecases/record_transfer_audit.dart` خلف عقد `TransferAuditPort`.
- **Consequences:** سجل التدقيق SRS 8.10 يعتمد على نية الواجهة؛ فقدان سجل عند إغلاق الشاشة.
- **Recommended correction:** رفع الاستدعاء إلى `InspectionNotifier.sendLogs`؛ استخدام معرّف فريد بدل الطابع الزمني.
- **Related files:** `logs/data/providers/log_repository_providers.dart`, `logs/domain/entities/audit_entry.dart`
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
### ISSUE DST-046: صفحة تكتب device storage مباشرة
- **Severity:** Low
- **Category:** Side Effect in Presentation
- **Location:** `lib/features/vehicle/presentation/pages/select_vehicle_page.dart:86-92`
- **Evidence:** (انظر DST-019 لأداء الكود الكامل) — تحديداً:
```dart
      final uid = v.uniqueId;
      if (v.deviceId != null) {
        ref.read(localStorageProvider).setDeviceId(v.deviceId.toString());
      } else if (uid != null && uid.isNotEmpty) {
        ref.read(localStorageProvider).setDeviceId(uid);
      }
```
- **Current behavior:** صفحة presentation تكتب `deviceId` في التخزين المحلي، وتحدّث `dashboardDataProvider`، ثم `context.go(...)`.
- **Why problematic:** (أ) الكتابة على تخزين الجهاز **أثر جانبي دائم** يُنفَّذ من Widget. (ب) المنطق ي duplicate بـ `dvir_form_page.dart:444-476` الذي يحاول قراءة `deviceId` من **fallbacks متعددة** — لأن التخزين قد لا يكون متسقاً.
- **Violated principle:** UI Purity.
- **Current owner:** Widget.
- **Correct owner:** orchestrator يستمع `vehicleProvider`.
- **Recommended correction:** نقل الكتابة إلى `app/orchestrators/tracking_orchestrator.dart` (نفس النمط المستخدم في `vehicle_provider.dart`).
- **Related files:** `vehicle/presentation/providers/vehicle_provider.dart:203-211`, `app/orchestrators/tracking_orchestrator.dart:87-95`
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
### ISSUE HL-16: `MainCircularTimer.build` ينفّذ محرك حساب HOS كاملاً
- **Severity:** High
- **Category:** Business Logic in Widget
- **Location:** `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:98-192`
- **Evidence:**
```dart
109:    Duration remainingOf(HosIndicator? ind, Duration limit) {
110:      final fallback = widget.circle.remaining > Duration.zero
111:          ? widget.circle.remaining
112:          : limit;
113:      if (ind == null) return fallback;
114:      if (ind.type == IndicatorType.used) {
115:        final left = limit - ind.value;
116:        return left.isNegative ? Duration.zero : left;
117:      }
118:      return ind.value > Duration.zero ? ind.value : fallback;
119:    }
...
124:    if (isRest) {
125:      totalLimit = const Duration(hours: 11);
126:      baseRemaining = Duration.zero;
127:    } else if (isDriving) {
128:      totalLimit = const Duration(hours: 11);
129:      baseRemaining =
130:          remainingOf(widget.hosIndicators?.drive, totalLimit);
131:    } else {
...
138:      if (breakVal != null &&
...
141:          (shiftRaw == null || breakRaw < shiftRaw)) {
142:        totalLimit = const Duration(hours: 8);
...
155:      final elapsedSinceSnapshot = DateTime.now().difference(_snapshotTime);
156:      liveRemaining = baseRemaining - elapsedSinceSnapshot;
```
- **Current behavior:** `build` (يُنفَّذ كل ثانية عبر `line 85` `Timer.periodic`) يطبّق: اختيار الحد الحاكم، تحويل `used→remaining`، العد التنازلي الحي، نسبة الاستهلاك، عتبة اللون (15 دقيقة في `line 179`).
- **Why problematic:** (1) **دالة محلّية داخل `build`** — لا يمكن اختبارها ولا إعادة استخدامها. (2) تخطّي بين `rest` المُحدَّد بـ `lower.contains('off')` (`line 65`) أي **مطابقة على نص مترجم** — أي ترجمة تكسره. (3) 170 سطراً من المنطق في مسار بناء.
- **Violated principle:** Widget = Presentation Only.
- **Current owner:** `main_circular_timer.dart`
- **Correct owner:** `hos/domain/engine/hos_calculator.dart` كـ `RemainingCircleCalculator` + `StatusRingViewModel`.
- **Consequences:** قاعدة غير قابلة للاختبار؛ كسر عند كل تحديث جديد.
- **Recommended correction:** استخرج `remainingOf` + اختيار `totalLimit` + `liveRemaining` إلى use-case يُعيد `RemainingCircle`، واجعل `build` يستهلك `RingViewModel` جاهزاً.
- **Related files:** `lib/features/hos/domain/engine/hos_calculator.dart:38-76`, `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart:105` (عتبة `Duration(hours: 1)` ثانية)
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-22: `EditLogController` يبتلع نوع الاستثناء رغم وجود `EditLogError` مصمَّم
- **Severity:** Medium
- **Category:** Error Surface Consistency
- **Location:** `lib/features/logs/presentation/controllers/edit_log_controller.dart:114-116` + `lib/features/logs/presentation/pages/edit_log_page.dart:88-90`
- **Evidence:**
```dart
// edit_log_controller.dart:114-116
    } catch (e, st) {
      state = AsyncError(e, st);
    }
```
```dart
// edit_log_page.dart:88-90
          } else {
            AppFeedback.error(context, context.loc.theEventCouldNotBeSaved);
          }
```
- **Current behavior:** كل الأخطاء تمر كـ `Object`؛ `edit_log_page.dart:70` يفحص `if (err is EditLogError)` — ولأن `EditLogError implements Exception`، فإن **أي خطأ غير متوقع يقع في نفس المسار** ويُعرض كـ «تعذّر حفظ الحدث».
- **Why problematic:** `EditLogErrorCode` مصمَّم بدقة (5 حالات) ومعالجة مفصّلة في `line 71-87` — لكن العقد غير مفروض: `catch` غير مصنّف يُسقط التمييز.
- **Violated principle:** Explicit Error Model.
- **Current owner:** controller.
- **Correct owner:** نفس الـ controller مع `on EditLogError` ثم `on Object` مصنّف.
- **Consequences:** خطأ قانوني (مثل رفض القيادة الآلية من الخادم) يظهر كخطأ شبكة.
- **Recommended correction:**
```dart
  } on EditLogError catch (e, st) {
    state = AsyncError(e, st);
  } catch (e, st) {
    AppLogger.error('EditLogController.saveEvent: unexpected', e, st);
    state = AsyncError(EditLogError(EditLogErrorCode.saveFailed), st);
  }
```
- **Related files:** `lib/features/logs/presentation/pages/edit_log_page.dart:63-96`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-24: تطبيع رموز الحالات الخمسة مكرّر في 5 مواقع داخل presentation
- **Severity:** High
- **Category:** Duplication / Business Rule
- **Location:** 5 مواقع (كلها داخل `logs/presentation`)
- **Evidence:**
```dart
// log_graph.dart:47-53
      if (status == 'PC') {
        normalized = 'OFF';
      } else if (status == 'YM' || status == 'OTH' || !stats.containsKey(status)) {
        normalized = 'ON';
      } else {
        normalized = status;
      }
```
```dart
// events_tab.dart:117-121
      final key = switch (e.status) {
        'PC' => 'OFF',
        'YM' => 'ON',
        _ => e.status,
      };
```
```dart
// inspection_preview_page.dart:194-199
                              return [
                                'ON',
                                'D',
                                'SB',
                                'OFF',
                              ].contains(e.status);
```
- **Current behavior:** ثلاث نسخ من قاعدة «PC يُحسب OFF و YM يُحسب ON»، والتعليق في `inspection_preview_page.dart:192-193` يعترف بعدم اكتمالها:
```dart
  // Custom filter logic for "Active Events"
  // Currently keeps duty statuses. Implement exact logic if needed.
```
- **Why problematic:** (1) القاعدة **قانونية** (§395.28) ومعروضة للسائق في الجدول الرسمي. (2) نسخة `log_graph` تضيف `'OTH'` والثانية لا. (3) النسخة الثالثة تكسر كل الرموز (لا تطبيع).
- **Violated principle:** DRY على قاعدة قانونية.
- **Current owner:** presentation ×3 (وأخريتان للترتيب).
- **Correct owner:** `DutyStatusCode` في `lib/domain/duty_status/duty_status_code.dart` كـ `graphBucket`، أو `StatusTotalsCalculator` في `logs/domain/`.
- **Consequences:** جدول Graph-Grid قد لا يطابق جدول Total في تبويب الأحداث.
- **Recommended correction:** `String graphBucket(String shortCode)` واحدة، تستهلكها المواضع الثلاثة.
- **Related files:** `lib/features/logs/presentation/widgets/status_radio_group.dart:19-26`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-27: `TrailersPage` و `ShippingDocumentsPage` نسختان متطابقتان
- **Severity:** Medium
- **Category:** Duplication (Structural)
- **Location:** `lib/features/logs/presentation/pages/trailers_page.dart` (170) و `lib/features/logs/presentation/pages/shipping_documents_page.dart` (170)
- **Current behavior:** الملفان بنفس البنية: نفس `_controller`، نفس `_addX()`، نفس `_removeX()`، نفس الشجرة، نفس RegExp (بفرق `/` واحد).
- **Evidence (مقارنة حرفية):**
```dart
// trailers_page.dart:36-37
  List<String> get _trailers =>
      splitFormList(ref.read(dashboardDataProvider).trailerId);
```
```dart
// shipping_documents_page.dart:35-36
  List<String> get _documents =>
      splitFormList(ref.read(dashboardDataProvider).shippingDocuments);
```
```dart
// trailers_page.dart:96-102
                    inputFormatters: [
                      // نفس مجموعة المدقق (حروف كل اللغات + أرقام + -_#)
                      // — النقاط والفواصل وعلامات الرياضيات تُمنع أثناء الكتابة.
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\p{L}\p{N}\s\-_#]', unicode: true),
                      ),
                    ],
```
```dart
// shipping_documents_page.dart:97-102
                    inputFormatters: [
                      // نفس مجموعة المدقق (+ `/` لأرقام BOL).
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\p{L}\p{N}\s\-_#/]', unicode: true),
                      ),
                    ],
```
- **Why problematic:** الـ RegExp ثالث نسخة من النمط المعرَّف في المصدر الصحيح `daily_form_rules.dart:29-31`، والنسختان **ستنحرفان** عند أي تعديل.
- **Violated principle:** DRY.
- **Current owner:** presentation ×2.
- **Correct owner:** widget عام `FormListEditorPage` في `logs/presentation/widgets/` يقبل `title`, `hint`, `validator`, `allowSlash`.
- **Consequences:** صيانة مزدوجة؛ خطر انحراف قواعد الإدخال.
- **Recommended correction:** استخرج `FormListEditorPage` واحد، وحيّد الـ RegExp من `daily_form_rules.dart` مُباشرة (`isFormLabelValid` بدل RegExp مكرر).
- **Related files:** `lib/features/logs/domain/daily_form_rules.dart:29-31,46-52`
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
### ISSUE HL-33: عرض رسالة خطأ خام داخل widget
- **Severity:** Low
- **Category:** Error Surface Consistency
- **Location:** `lib/features/logs/presentation/widgets/codriver_picker_dialog.dart:57`
- **Evidence:**
```dart
56:                      Text(
57:                        'Error: ${codriverState.error}',
58:                        style: context.styles.error,
59:                      ),
```
- **Current behavior:** يعرض `'Error: ' + الخطأ الخام` بينما المقياس يستخدم `anyErrorUserMessage(error, loc:)` في **12 موضعاً آخر** داخل `logs`.
- **Why problematic:** الرسالة الخام قد تكون كوداً داخلياً أو استثناء.
- **Violated principle:** Consistent Error Surface.
- **Current owner:** الملف.
- **Correct owner:** نفس الملف باستدعاء `anyErrorUserMessage`.
- **Consequences:** تسريب تفاصيل فنية للمستخدم.
- **Recommended correction:** استبدل السطر.
- **Related files:** `lib/core/error/user_facing_message.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-34: خرائط رموز الحالات الخمسة: 5 نسخ داخل presentation
- **Severity:** Medium
- **Category:** Duplication
- **Location:** 5 مواقع (كلها presentation)
| # | الملف:السطر | المحتوى |
|---|---|---|
| 1 | `logs/presentation/widgets/status_radio_group.dart:19-26` | 6 رموز + تسميات |
| 2 | `logs/presentation/pages/inspection_preview_page.dart:194-199` | 4 رموز |
| 3 | `logs/presentation/pages/inspection_preview_page.dart:273-286` | 4 رموز → ألوان |
| 4 | `logs/presentation/widgets/log_graph.dart:26-30` + `:47-53` | 4 رموز + تطبيع |
| 5 | `logs/presentation/widgets/log_detail_tabs/events_tab.dart:104` | 4 رموز |
- **Current behavior:** المصدر الرسمي موجود: `lib/domain/duty_status/duty_status_code.dart` و`core/domain/entities/hos_models.dart:toShortCode()`؛ ومع ذلك كل موضع يُعيد كتابة المجموعة.
- **Why problematic:** خريطة الألوان في #3 **مكرّرة** مع `core/utils/status_color_helper.dart:5-7` الموجودة فعلاً والمُستخدمة في `log_event_tile.dart:45`. أي حالة جديدة تظهر بلون مختلف في كل شاشة.
- **Violated principle:** DRY.
- **Current owner:** presentation ×5.
- **Correct owner:** `DutyStatusCode` + `StatusColorHelper`.
- **Consequences:** شاشات متعارضة اللون.
- **Recommended correction:** في #3 استبدل `_getStatusColor` بـ `StatusColorHelper.getStatusColor(status)`؛ وفي الباقي ولّد من `DutyStatusCode.values`.
- **Related files:** `lib/core/utils/status_color_helper.dart`, `lib/domain/duty_status/duty_status_code.dart`, `lib/core/domain/entities/hos_models.dart:12-27`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-35: عقد نصي مشترك بين widget و domain مربوط بتعليق فقط
- **Severity:** Low
- **Category:** Implicit Contract
- **Location:** `lib/features/logs/presentation/widgets/time_picker_sheet.dart:69-72` ↔ `lib/features/logs/domain/log_edit.dart:41-43`
- **Evidence:**
```dart
// time_picker_sheet.dart:69-72
                onPressed: () {
                  // Always use English AM/PM so parseEditFormTime can parse it properly.
                  final time = '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}:${_selectedSecond.toString().padLeft(2, '0')} $_selectedPeriod';
                  widget.onDone(time);
                },
```
```dart
// log_edit.dart:41-43
  final m12 = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)$',
          caseSensitive: false)
      .firstMatch(trimmed);
```
- **Current behavior:** الـ widget ينتج نصاً، والـ domain يحلّله بـ regex. العقد **نصّي غير مُنمّط**، رابطه تعليق فقط.
- **Why problematic:** أي تعديل على تنسيق الإخراج يكسر التحليل صامتاً (`parseEditFormTime` يعيد `null` ⇒ `invalidTime`).
- **Violated principle:** Type Safety across layers.
- **Current owner:** — / **Correct owner:** value object أو `TimeOfDay` من Flutter يُمرَّر كـ `DateTime`.
- **Consequences:** كسر صامت عند أي تغيير في الطرف.
- **Recommended correction:** مرّر `TimeOfDay` من الـ widget، ودع `domain` يستقبل `DateTime`.
- **Related files:** `lib/core/time/time_formatter.dart:37`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-36: تحليل نص المتطلبات داخل widget
- **Severity:** Medium
- **Category:** Parsing in Widget
- **Location:** `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart:82-95`
- **Evidence:**
```dart
82:  static String _readableRequirement(String req) {
83:    return req.replaceAllMapped(
84:      RegExp(
85:          r'\d{4}-\d{1,2}-\d{1,2}[T ]\d{1,2}:\d{2}(?::\d{2})?(?:Z|[+-]\d{2}:?\d{2})?'),
86:      (m) {
87:        final parsed = DateTime.tryParse(m.group(0)!);
88:        if (parsed == null) return m.group(0)!;
89:        final local = parsed.toLocal();
90:        final hh = local.hour.toString().padLeft(2, '0');
91:        final mm = local.minute.toString().padLeft(2, '0');
92:        return '$hh:$mm';
93:      },
94:    );
95:  }
```
- **Current behavior:** regex ISO داخل widget لتحويل متطلبات الجاهزية (نص حر من الخادم) إلى `HH:mm`.
- **Why problematic:** المتطلب **نص حر**؛ كل خادم يرسل صيغة مختلفة. الـ regex يفلت بصمت ويعرض النص كما هو. الدالة `static` داخل widget ⇒ **لا وحدة اختبار** ممكنة.
- **Violated principle:** Parsing belongs in domain/data.
- **Current owner:** widget.
- **Correct owner:** `core/time/time_formatter.dart` مع اختبارات.
- **Consequences:** أوقات تظهر بصيغة UTC بلا علامة.
- **Recommended correction:** انقلها إلى `TimeFormatter` مع اختبار يغطي الصيغ البديلة.
- **Related files:** `lib/core/time/time_formatter.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-37: `_dailyFormPayload` — use-case داخل ملف widget
- **Severity:** Medium
- **Category:** Business Logic in Widget
- **Location:** `lib/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart:335-383` + `:327-332`
- **Evidence:**
```dart
335: _DailyFormPayload _dailyFormPayload({
336:   required String vehicleUniqueId,
...
343:   final uniqueId =
344:       readOperableUniqueId(vehicleUniqueId) ??
345:       readOperableUniqueId(logUniqueId) ??
346:       '';
347:   if (uniqueId.isEmpty) {
348:     return _DailyFormPayload(null, loc.selectVehicleBeforeSavingForm);
349:   }
350:
351:   final trailers = <String>[];
352:   for (final trailer in splitFormList(trailersRaw)) {
353:     final error = trailerNumberError(trailer, loc);
354:     if (error != null) return _DailyFormPayload(null, error);
355:     trailers.add(trailer);
356:   }
...
365:   int? coDriverId;
366:   final rawCoDriver = coDriverIdRaw.trim();
367:   if (rawCoDriver.isNotEmpty && rawCoDriver != 'none') {
368:     coDriverId = int.tryParse(rawCoDriver);
369:     if (coDriverId == null) {
370:       return _DailyFormPayload(null, loc.coDriverMustBeServerId);
371:     }
372:   }
```
- **Current behavior:** دالة top-level **بِناء أمر + تحقّق + اختيار رسالة خطأ** — 48 سطراً، تُنفَّذ مرتين: مرة في `validator` ومرة عند الحفظ.
- **Why problematic:** (1) **نفس التحقق مُنفَّذ في موضعين مختلفين**: الـ validator يمرّر `value` من `FormField`، والحفظ يمرّر `trailersDisplay` المعروض. (2) `loc: context.loc` في التوقيع ⇒ غير قابل للاستخدام خارج UI.
- **Violated principle:** Business logic in Presentation + Single validation path.
- **Current owner:** widget.
- **Correct owner:** `logs/application/usecases/build_daily_form_update_use_case.dart`.
- **Consequences:** خطأ صامت قد لا يُكتشف عند الحفظ.
- **Recommended correction:** use-case واحد يُعيد `Either<FormError, DailyFormUpdate>`، والـ validator يستهلك نفس النتيجة.
- **Related files:** `lib/features/logs/presentation/controllers/form_tab_controller.dart:21-63`, `lib/features/logs/domain/entities/daily_form_update.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-39: عتبات العرض (1 ساعة حرج، 15 دقيقة أحمر) مكتوبة داخل widgets
- **Severity:** Medium
- **Category:** Hardcoded Business Thresholds in Presentation
- **Location:** `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart:105`؛ `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:179`
- **Evidence:**
```dart
// hos_indicators_card.dart:103-105
    final isCritical =
        indicator.type == IndicatorType.remaining &&
        indicator.value <= const Duration(hours: 1);
```
```dart
// main_circular_timer.dart:178-181
    } else if (liveRemaining <= Duration.zero ||
        liveRemaining <= const Duration(minutes: 15)) {
      arcColor = theme.colorScheme.error;
```
- **Current behavior:** عتبتان لونيّتان محدّدتان رقمياً داخل widgets، بينما محرّك التنبيهات في `hos_rules_engine.dart:104-127` يستخدم 15/30/60 دقيقة.
- **Why problematic:** **نفس المفهوم (اقتراب الحد) بعتبتين مختلفتين في مكانين مختلفين**: المحرّك يصنّف 30/60 دقيقة كتنبيهات، والواجهة تحوّل الأحمر عند 15 دقيقة فقط. كما أن `Duration(minutes: 15)` في الودجت لا يستمد من `HosConfiguration` ولا `FmcsaConstants`.
- **Violated principle:** Single Source of Truth.
- **Current owner:** widgets ×2.
- **Correct owner:** `FmcsaConstants` أو `HosConfiguration`، مع استهلاكها عبر `AlertSeverity` القادم من المحرك.
- **Consequences:** تناقض بصري: السائق يرى «حرج» في لوح واحد و«معلومات» في آخر لنفس الوقت المتبقي.
- **Recommended correction:** اجعل `HosStatusUpdate` يحمل `AlertSeverity` لكل مؤشر، واستهلكه الودجت بدل حساب عتبة خاصة.
- **Related files:** `lib/features/hos/domain/engine/hos_rules_engine.dart:104-127`
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

--------------------------------------------------
### ISSUE HL-41: ازدواج شريط التنقل السفلي وطبقات Loading/Error في المجموعة
- **Severity:** Low
- **Category:** Duplication (Structural)
- **Location:** `BottomNavigationBar`: 2 موضعان متطابقان — `logs/presentation/pages/log_detail_page.dart:176` و `logs/presentation/pages/inspection_preview_page.dart:236`. `CircularProgressIndicator`: **12 موضعاً في 12 ملفاً** (`hos/presentation/pages/status_dashboard_page.dart:93`، `hos/presentation/pages/recap_page.dart:65`، `logs/presentation/pages/audit_trail_page.dart:40`، `logs/presentation/pages/edit_log_page.dart:377`، `logs/presentation/pages/logs_list_page.dart:64`، `logs/presentation/pages/inspection_preview_page.dart:118,362`، `logs/presentation/pages/unidentified_events_page.dart:244`، `logs/presentation/widgets/vehicle_picker_dialog.dart:64`، `logs/presentation/widgets/codriver_picker_dialog.dart:51`، `logs/presentation/widgets/log_detail_tabs/events_tab.dart:30`، `logs/presentation/widgets/log_detail_tabs/certify_tab.dart:116`). `EldRetryView`: **7 مواضع في 6 ملفات** (`hos/.../status_dashboard_page.dart:113`، `hos/.../recap_page.dart:67`، `logs/.../logs_list_page.dart:66,75`، `logs/.../events_tab.dart:33,42`، `logs/.../inspection_preview_page.dart:126`).
- **Current behavior:** نفس شريط التنقل السفلي (3 عناصر + Badge على «Form») مكرور مرتين؛ حالة التحميل تُبنى يدوياً 12 مرة.
- **Why problematic:** مجموعتان متطابقتان من Handling States بلا abstraction. (ملاحظة: `EldRetryView` و`CircularProgressIndicator` تكرارات **مقبولة** كـ shared widgets في `core/widgets/` — التسجيل هنا لقياس الكمية، لا للحكم على المخالفة.)
- **Violated principle:** DRY (بحدّ).
- **Current owner:** presentation.
- **Correct owner:** `core/widgets/` (يوجد precedent في `core/widgets/eld_date_paginator.dart` و`eld_events_table.dart`).
- **Consequences:** تعديل مظهر حالة الخطأ يتطلب 7 مواضع.
- **Recommended correction:** استخرج `AsyncStateView<T>` و`LogSectionTabBar` في `core/widgets/`.
- **Related files:** `lib/core/widgets/eld_retry_view.dart`, `lib/core/widgets/eld_date_paginator.dart`
- **Confidence:** **CONFIRMED**

---
# C. جدول تكرار قواعد HOS (الثابت -> كل موقع file:line)

> البحث تم عبر كامل `lib/` (باستثناء `*.g.dart` و `*.freezed.dart`).

## C.1 — حد القيادة 11 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:19` | `static const int maxDrivingHours = 11;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:27` | `drivingLimitMinutes: 11 * 60,` (usa70_8) | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:41` | `drivingLimitMinutes: 11 * 60,` (usa60_7) | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:89` | `?? 11 * 60` (fromJson fallback) | core/config | ✅ مصدر |
| 5 | `lib/features/hos/domain/engine/hos_rules_engine.dart:172` | نص: `'❌ تجاوز حد القيادة 11 ساعة'` | domain | ⚠️ نص |
| 6 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:87` | `const total = Duration(hours: 11);` | **data** | ❌ |
| 7 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:125` | `totalLimit = const Duration(hours: 11);` (rest) | **presentation** | ❌ |
| 8 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:128` | `totalLimit = const Duration(hours: 11);` (driving) | **presentation** | ❌ |
| 9 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:73` | `value: Duration(hours: 11),` | mock | ✅ مقبول |
| 10 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:139` | `const total = Duration(hours: 11);` | mock | ✅ مقبول |

## C.2 — نافذة الوردية 14 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:22` | `static const int maxDutyWindowHours = 14;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:28` | `shiftLimitMinutes: 14 * 60,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:42` | `shiftLimitMinutes: 14 * 60,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:90` | `?? 14 * 60` | core/config | ✅ مصدر |
| 5 | `lib/features/hos/domain/engine/hos_rules_engine.dart:181` | نص: `'❌ تجاوز نافذة العمل 14 ساعة'` | domain | ⚠️ نص |
| 6 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:95` | `const total = Duration(hours: 14);` | **data** | ❌ |
| 7 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:145` | `totalLimit = const Duration(hours: 14);` | **presentation** | ❌ |
| 8 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:78` | `value: Duration(hours: 14),` | mock | ✅ |
| 9 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:148` | `const total = Duration(hours: 14);` | mock | ✅ |

## C.3 — الاستراحة/حد 8 ساعات
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:28` | `static const int breakRequiredAfterDrivingHours = 8;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:32` | `driveBeforeBreakMinutes: 8 * 60,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:46` | `driveBeforeBreakMinutes: 8 * 60,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:94` | `?? 8 * 60` | core/config | ✅ مصدر |
| 5 | `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart:28` | `driveBeforeBreakMinutes: 8 * 60,` | backend mapper | ⚠️ mapper، تجاوز المصدر |
| 6 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:142` | `totalLimit = const Duration(hours: 8);` | **presentation** | ❌ |
| 7 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:83` | `value: Duration(hours: 8),` | mock | ✅ |

## C.4 — الاستراحة الإلزامية 30 دقيقة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:29` | `static const int mandatoryBreakDurationMinutes = 30;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:30` | `breakDurationMinutes: 30,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:44` | `breakDurationMinutes: 30,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:92` | `?? 30` | core/config | ✅ مصدر |
| 5 | `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart:26` | `breakDurationMinutes: 30,` | backend mapper | ⚠️ تجاوز المصدر |

## C.5 — حد الدورة الأسبوعية 60/70 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:32` | `static const int cycle7DaysLimitHours = 60;` | core/constants | ✅ مصدر |
| 2 | `lib/core/constants/fmcsa_constants.dart:33` | `static const int cycle8DaysLimitHours = 70;` | core/constants | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:29` | `cycleLimitHours: 70,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:43` | `cycleLimitHours: 60,` | core/config | ✅ مصدر |
| 5 | `lib/core/config/hos_configuration.dart:91` | `?? 70` | core/config | ✅ مصدر |
| 6 | `lib/domain/duty_status/status_dashboard.dart:175-181` | `usa70_8('USA 70/8', 70, 8)` … `canadaSouth120_14(…, 120, 14)` | domain مشترك | ✅ (مصدر ثانٍ مشروع) |
| 7 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:88` | `value: Duration(hours: 70),` | mock | ✅ |

## C.6 — إعادة التشغيل الأسبوعي 34 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:34` | `static const int cycleRestartHours = 34;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:34` | `weeklyRestartHours: 34,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:48` | `weeklyRestartHours: 34,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:96` | `?? 34` | core/config | ✅ مصدر |
| 5 | `lib/features/hos/domain/engine/hos_calculator.dart:103` | **`const requiredHours = 34;`** | **domain** | ❌ **يتجاهل `config.weeklyRestartHours`** |

> **ملاحظة حرجة (C.6):** `HosConfiguration` يوفّر `weeklyRestartHours` كحقل مهيّأ، لكن `HosCalculator.hasWeeklyRestart` **يتجاهله تماماً** ويثبّت `34` محلياً. أي أن تغيير قاعدة إعادة التشغيل (مثلاً ولاية أخرى) لا يسري.

## C.7 — عتبة السرعة 5 mph / 8 km/h
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:7` | `static const double drivingSpeedThresholdMps = 2.235;` | core/constants | ✅ مصدر |
| 2 | `lib/core/constants/fmcsa_constants.dart:10` | `static const double drivingSpeedThresholdMph = 5.0;` | core/constants | ✅ **المصدرUnused** |
| 3 | `lib/core/config/hos_configuration.dart:31` | `movingSpeedThresholdKmh: 8.0,` | core/config | ✅ |
| 4 | `lib/core/config/hos_configuration.dart:45` | `movingSpeedThresholdKmh: 8.0,` | core/config | ✅ |
| 5 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:106` | **`if (eldEvent.speedMph > 5.0) {`** | **domain** | ❌ **وحدات مختلفة** |
| 6 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:129` | نص: `'Auto Transition to Driving (> 5 mph sustained)'` | domain | ⚠️ نص |

## C.8 — الثبات 5 دقائق قبل الانتقال لـ ON_DUTY
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:16` | `static const int stationaryPromptSeconds = 300;` | core/constants | ✅ **المصدرUnused** |
| 2 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:168` | `if (elapsed.inMinutes >= 5) {` | domain | ❌ وليس في `HosConfiguration` |
| 3 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:185` | `const Duration(minutes: 5) - elapsed` | domain | ❌ |

## C.9 — عتبة التنبيه 15 دقيقة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/features/hos/domain/engine/hos_rules_engine.dart:104` | `if (limits.remainingDriveMinutes <= 15 &&` | domain | ⚠️ محرّك، لكن خارج `HosConfiguration` |
| 2 | `lib/features/hos/domain/engine/hos_rules_engine.dart:108` | نص: `'15 minutes driving time remaining'` | domain | ⚠️ نص |
| 3 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:179` | `liveRemaining <= const Duration(minutes: 15)` | **presentation** | ❌ عتبة مستقلة |

## C.10 — الراحة المتتالية 10 ساعات
| # | الموقع | الصيغة | المصدر الصحيح؟ |
|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:25` | `static const int requiredConsecutiveRestHours = 10;` | ✅ المصدر الوحيد |
| — | *(لا توجد أي نسخة أخرى في `lib/`)* | — | ⚠️ ثابت **غير مستخدم** — لا يوجد أي تنفيذ لقاعدة الراحة المتتالية 10 ساعات في المجموعة |

## C.11 — أرقام مُختلقة (ليست قواعد)
| # | الموقع | القيمة | الحكم |
|---|---|---|---|
| 1 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:86` | `const remaining = Duration(minutes: 35);` | ❌ بيانات توازن مُختلقة في data |
| 2 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:94` | `const remaining = Duration(hours: 2, minutes: 8);` | ❌ بيانات توازن مُختلقة في data |
| 3 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:95` | `Duration(minutes: 35)` | ✅ mock |
| 4 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:100` | `Duration(hours: 2, minutes: 8)` | ✅ mock |
| 5 | `lib/features/logs/presentation/providers/logs_provider.dart:119` | `const limit = 20;` | ⚠️ حجم صفحة (قابل للضبط، ليس قاعدة قانونية) |
| 6 | `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart:105` | `const Duration(hours: 1)` | ❌ عتبة نقدية في widget |
| 7 | `lib/features/logs/presentation/pages/unidentified_events_page.dart:334` | `const Duration(hours: 24)` | ⚠️ نافذة إحصائية (SRS 11.6)، ليست FMCSA |
| 8 | `lib/features/logs/presentation/controllers/edit_log_controller.dart:52` | `const Duration(minutes: 1)` | ⚠️ هامش تسامح زمني |

**خلاصة القسم C:** عدد المواقع التي **تتجاوز** المصدر الصحيح داخل هذه المجموعة = **7** (`main_circular_timer.dart` ×5، `status_dashboard_repository_impl.dart` ×2، `duty_status_tracker.dart` ×1، `hos_calculator.dart` ×1). عدد الثوابت المعرَّفة في مصدرين رسميين (`FmcsaConstants` و`HosConfiguration`) = **12**، منها **3 غير مستخدمة** (`drivingSpeedThresholdMph`, `stationaryPromptSeconds`, `requiredConsecutiveRestHours`).

---

# D. جداول الاستيراد بين الميزات للمجموعة

## D.1 — `features/logs` -> ميزات أخرى (13 حافة)

| # | المستورد | السطر | المستوردَ منه | نوع الحافة | الحكم |
|---|---|---|---|---|---|
| 1 | `logs/data/repositories/log_repository_impl.dart` | 3 | `features/sync/domain/entities/pending_event.dart` | data → domain (عقد) | ✅ جائز |
| 2 | `logs/data/repositories/log_repository_impl.dart` | 4 | `features/sync/domain/repositories/offline_queue.dart` | data → domain (عقد) | ⚠️ جائز لكنه يجعل `sync` مجتمعة مع `logs` |
| 3 | `logs/data/providers/log_repository_providers.dart` | 6 | `features/sync/data/providers/sync_providers.dart` | data → data (DI) | ✅ جائز في بنية المشروع |
| 4 | `logs/presentation/providers/logs_provider.dart` | 11 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ معقول (هوية) |
| 5 | `logs/presentation/providers/logs_provider.dart` | **12** | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة حالة**) | ❌ **HL-25** |
| 6 | `logs/presentation/controllers/edit_log_controller.dart` | 5 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 7 | `logs/presentation/controllers/form_tab_controller.dart` | 2 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 8 | `logs/presentation/providers/certify_log_provider.dart` | 12 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 9 | `logs/presentation/providers/unidentified_events_provider.dart` | 8 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 10 | `logs/presentation/pages/edit_log_page.dart` | 4 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |
| 11 | `logs/presentation/pages/edit_log_page.dart` | 13 | `features/vehicle/domain/entities/vehicle.dart` | presentation → domain (عقد) | ✅ جائز |
| 12 | `logs/presentation/pages/edit_log_page.dart` | 14 | `features/vehicle/presentation/providers/vehicle_provider.dart` | presentation → presentation | ⚠️ معقول (اختيار) |
| 13 | `logs/presentation/widgets/vehicle_picker_dialog.dart` | 9 | `features/vehicle/presentation/providers/vehicle_provider.dart` | presentation → presentation | ⚠️ معقول |
| 14 | `logs/presentation/pages/unidentified_events_page.dart` | 11 | `features/vehicle/presentation/providers/vehicle_provider.dart` | presentation → presentation | ⚠️ معقول (فلترة) |
| 15 | `logs/presentation/widgets/codriver_picker_dialog.dart` | 5 | `features/codriver/domain/entities/codriver.dart` | presentation → domain (عقد) | ✅ |
| 16 | `logs/presentation/widgets/codriver_picker_dialog.dart` | 6 | `features/codriver/presentation/providers/codriver_provider.dart` | presentation → presentation | ⚠️ معقول |
| 17 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 7 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |
| 18 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 8 | `features/vehicle/domain/entities/vehicle.dart` | presentation → domain (عقد) | ✅ |
| 19 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 9 | `features/vehicle/domain/vehicle_selection.dart` | presentation → domain (منطق) | ✅ منطق مجال مستورد كعقد |
| 20 | `logs/presentation/pages/inspection_preview_page.dart` | 14 | `features/inspection/domain/transfer_audit.dart` | presentation → domain (عقد) | ✅ |
| 21 | `logs/presentation/pages/inspection_preview_page.dart` | 15 | `features/inspection/presentation/providers/dot_inspection_providers.dart` | presentation → presentation | ⚠️ معقول |
| 22 | `logs/presentation/pages/inspection_preview_page.dart` | **16** | `features/inspection/presentation/widgets/inspection_log_header_table.dart` | presentation → **presentation widget** | ❌ **HL-13** |
| 23 | `logs/presentation/pages/logs_list_page.dart` | **11** | `features/home/presentation/widgets/eld_drawer.dart` | presentation → **presentation widget** | ❌ **HL-13** |
| 24 | `logs/presentation/pages/shipping_documents_page.dart` | 11 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |
| 25 | `logs/presentation/pages/trailers_page.dart` | 11 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |

**حساب:** 25 حافة إجمالاً. منها **5 مخالفة مؤكدة** (كتابة عبر features أو استيراد widget).
`LOGS → VEHICLE` = **4 حواف، كلها تستورد عقوداً أو providers قراءة** ⇒ **ليست مخالفة**.
`LOGS → HOME` = **7 حواف، 5 منها كتابة حالة** ⇒ **مخالفة مؤكدة**.
`LOGS → AUTH` = **5 حواف، قراءة فقط** ⇒ **ليست مخالفة**.
`LOGS → SYNC` = **3 حواف، كلها في طبقة data** ⇒ **ليست مخالفة**.
`LOGS → CODRIVER` = **3 حواف، عقدة + قراءة** ⇒ **ليست مخالفة**.
`LOGS → INSPECTION` = **3 حواف، منها استيراد widget** ⇒ **مخالفة جزئية**.

## D.2 — `features/hos` -> ميزات أخرى و `lib/domain` (11 حافة)

| # | المستورد | السطر | المستوردَ منه | نوع الحافة | الحكم |
|---|---|---|---|---|---|
| 1 | `hos/domain/engine/tracking/duty_status_tracker.dart` | **4** | `features/logs/domain/repositories/log_repository.dart` | **domain → domain (feature أخرى)** | ❌ **HL-01 مخالفة حرجة** |
| 2 | `hos/domain/engine/tracking/duty_status_tracker.dart` | **9** | `features/sync/domain/usecases/sync_engine.dart` | **domain → domain (use-case)** | ⚠️ تطبيق مجتمعة — غير مثالي لكنه عقد |
| 3 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 10 | `features/sync/domain/entities/pending_event.dart` | domain → domain (كيان) | ✅ كيان مشترك |
| 4 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 5 | `core/services/local_storage_service.dart` | **domain → infrastructure** | ❌ **HL-02** |
| 5 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 13 | `backend/contracts/status_dashboard_backend.dart` | **domain → backend contract** | ❌ **HL-02** |
| 6 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 14 | `lib/domain/duty_status/duty_status_code.dart` | domain → **shared domain** | ✅ **عقدة مشتركة** |
| 7 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 15 | `lib/domain/duty_status/status_dashboard.dart` | domain → shared domain | ✅ عقدة مشتركة |
| 8 | `hos/presentation/providers/hos_engine_provider.dart` | 8 | `features/logs/data/providers/log_repository_providers.dart` | presentation → **data** | ⚠️ انعكاس لـ HL-01 |
| 9 | `hos/presentation/providers/hos_engine_provider.dart` | 9 | `features/sync/data/providers/sync_providers.dart` | presentation → data | ✅ DI |
| 10 | `hos/presentation/providers/hos_engine_provider.dart` | 7 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 11 | `hos/presentation/providers/hos_engine_provider.dart` | 11 | `features/tracking/presentation/providers/tracking_provider.dart` | presentation → presentation | ✅ (قراءة سرعة) |
| 12 | `hos/presentation/providers/hos_provider.dart` | 11 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 13 | `hos/presentation/providers/recap_provider.dart` | 7 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 14 | `hos/presentation/providers/status_dashboard_providers.dart` | 13 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 15 | `hos/presentation/widgets/driving_lock_screen.dart` | **7** | `features/home/presentation/pages/home_page.dart` | presentation → **presentation page** | ❌ **HL-13** |
| 16 | `hos/presentation/widgets/location_display_widget.dart` | 5 | `features/tracking/presentation/providers/tracking_provider.dart` | presentation → presentation | ✅ |
| 17 | `hos/presentation/widgets/status_dashboard/operational_alerts_banner.dart` | 8 | `features/connection/presentation/providers/hardware_alerts_provider.dart` | presentation → presentation | ✅ |

## D.3 — الحكم على التبعيات المُعلنة

| التبعية المُعلنة | الحكم | المبرر |
|---|---|---|
| **`LOGS -> VEHICLE`** | **ليست مخالفة** ✅ | الحواف الأربع (11, 13, 14 من `edit_log_page` + `vehicle_picker_dialog:9` + `unidentified_events_page:11` + `form_tab:8,9`) تستورد: (أ) كيان `Vehicle` (عقدة نطاق مشتركة)، (ب) `vehicle_selection.dart` (منطق مجال)، (ج) provider قراءة. **لا يوجد استيراد لتنفيذ vehicle (repository/datasource)**. هذا نمط سليم. |
| **`LOGS -> HOME`** | **مخالفة مؤكدة** ❌ | ليس استيراد عقدة، بل **كتابة حالة** عبر `dashboardDataProvider.notifier` في 5 مواضع (`logs_provider:162,192,214`، `form_tab:130,215`، `edit_log_page:182`، `trailers_page:52`، `shipping_documents_page:51`) + استيراد widget `EldDrawer`. `dashboardDataProvider` هو **source of truth** لبيانات النموذج، و`logs` يحدّثه. |
| **`HOS -> SDOM (lib/domain/**)`** | **ليست مخالفة** ✅ | `lib/domain/duty_status/duty_status_code.dart` و`status_dashboard.dart` و`shared/value_objects.dart` هي **عقد مشتركة** (Shared Domain Model) يستخدمها `logs` و`hos` معاً (`log_repository.dart:4`، `status_dashboard_repository.dart:3-6`، `log_repository_providers.dart:9`). هي **نماذج مجال مشتركة لا تنفيذ**. هذا نمط معماري صحيح. |
| **`HOS -> LOGS`** | **مخالفة حرجة مؤكدة** ❌ | ليس عقدة مشتركة: `duty_status_tracker.dart:4` يستورد **عقد مستودع feature أخرى** و`line 284` يستدعيه. كما أن `hos_engine_provider.dart:8` يستورد **طبقة data** (`log_repository_providers.dart`) لتحقن المستودع. |

---

# E. قائمة شاملة للملفات المقروءة (إثبات التغطية)

## E.1 — `lib/features/hos/**` (29 ملف)

| # | المسار | أسطر | غير فارغ |
|---|---|---|---|
| 1 | `lib/features/hos/data/providers/hos_audit_providers.dart` | 14 | 12 |
| 2 | `lib/features/hos/data/providers/status_dashboard_repository_providers.dart` | 15 | 12 |
| 3 | `lib/features/hos/data/repositories/hos_audit_repository_impl.dart` | 58 | 52 |
| 4 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart` | 115 | 108 |
| 5 | `lib/features/hos/domain/engine/hos_calculator.dart` | 113 | 94 |
| 6 | `lib/features/hos/domain/engine/hos_rules_engine.dart` | 240 | 207 |
| 7 | `lib/features/hos/domain/engine/hos_state_machine.dart` | 128 | 106 |
| 8 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` | 555 | 494 |
| 9 | `lib/features/hos/domain/repositories/hos_audit_repository.dart` | 6 | 5 |
| 10 | `lib/features/hos/domain/repositories/status_dashboard_repository.dart` | 20 | 17 |
| 11 | `lib/features/hos/domain/usecases/get_status_dashboard_use_case.dart` | 15 | 12 |
| 12 | `lib/features/hos/domain/usecases/get_weekly_recap_use_case.dart` | 15 | 12 |
| 13 | `lib/features/hos/domain/usecases/update_duty_status_use_case.dart` | 18 | 15 |
| 14 | `lib/features/hos/presentation/duty_change_message.dart` | 32 | 27 |
| 15 | `lib/features/hos/presentation/extensions/duty_status_l10n.dart` | 52 | 48 |
| 16 | `lib/features/hos/presentation/pages/change_status_page.dart` | 232 | 212 |
| 17 | `lib/features/hos/presentation/pages/recap_page.dart` | 117 | 113 |
| 18 | `lib/features/hos/presentation/pages/status_dashboard_page.dart` | 118 | 103 |
| 19 | `lib/features/hos/presentation/providers/change_status_provider.dart` | 397 | 353 |
| 20 | `lib/features/hos/presentation/providers/hos_engine_provider.dart` | 83 | 71 |
| 21 | `lib/features/hos/presentation/providers/hos_provider.dart` | 159 | 140 |
| 22 | `lib/features/hos/presentation/providers/recap_provider.dart` | 38 | 31 |
| 23 | `lib/features/hos/presentation/providers/status_dashboard_providers.dart` | 145 | 127 |
| 24 | `lib/features/hos/presentation/widgets/driving_lock_screen.dart` | 57 | 54 |
| 25 | `lib/features/hos/presentation/widgets/location_display_widget.dart` | 39 | 35 |
| 26 | `lib/features/hos/presentation/widgets/status_option_tiles.dart` | 70 | 62 |
| 27 | `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart` | 150 | 139 |
| 28 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart` | 365 | 331 |
| 29 | `lib/features/hos/presentation/widgets/status_dashboard/operational_alerts_banner.dart` | 93 | 84 |

**المجموع: 3,046 سطر — 29/29 ملف مقروء.**

## E.2 — `lib/features/logs/**` (42 ملف)

| # | المسار | أسطر | غير فارغ |
|---|---|---|---|
| 1 | `lib/features/logs/data/datasources/log_local_data_source.dart` | 322 | 291 |
| 2 | `lib/features/logs/data/models/daily_log_dto.dart` | 143 | 134 |
| 3 | `lib/features/logs/data/models/log_model.dart` | 133 | 121 |
| 4 | `lib/features/logs/data/providers/log_repository_providers.dart` | 25 | 21 |
| 5 | `lib/features/logs/data/repositories/log_repository_impl.dart` | 539 | 498 |
| 6 | `lib/features/logs/domain/daily_form_rules.dart` | 93 | 83 |
| 7 | `lib/features/logs/domain/log_edit.dart` | 57 | 49 |
| 8 | `lib/features/logs/domain/saved_form_status.dart` | 36 | 31 |
| 9 | `lib/features/logs/domain/entities/audit_entry.dart` | 100 | 89 |
| 10 | `lib/features/logs/domain/entities/daily_form_data.dart` | 32 | 29 |
| 11 | `lib/features/logs/domain/entities/daily_form_update.dart` | 27 | 24 |
| 12 | `lib/features/logs/domain/entities/daily_log.dart` | 251 | 236 |
| 13 | `lib/features/logs/domain/entities/log_readiness.dart` | 69 | 63 |
| 14 | `lib/features/logs/domain/repositories/log_repository.dart` | 93 | 85 |
| 15 | `lib/features/logs/presentation/controllers/edit_log_controller.dart` | 122 | 105 |
| 16 | `lib/features/logs/presentation/controllers/form_tab_controller.dart` | 68 | 58 |
| 17 | `lib/features/logs/presentation/pages/audit_trail_page.dart` | 93 | 88 |
| 18 | `lib/features/logs/presentation/pages/edit_log_page.dart` | 433 | 407 |
| 19 | `lib/features/logs/presentation/pages/inspection_preview_page.dart` | 401 | 382 |
| 20 | `lib/features/logs/presentation/pages/logs_list_page.dart` | 239 | 225 |
| 21 | `lib/features/logs/presentation/pages/log_detail_page.dart` | 220 | 211 |
| 22 | `lib/features/logs/presentation/pages/shipping_documents_page.dart` | 170 | 160 |
| 23 | `lib/features/logs/presentation/pages/suggested_events_page.dart` | 121 | 117 |
| 24 | `lib/features/logs/presentation/pages/trailers_page.dart` | 170 | 160 |
| 25 | `lib/features/logs/presentation/pages/unidentified_events_page.dart` | 505 | 479 |
| 26 | `lib/features/logs/presentation/providers/audit_trail_provider.dart` | 10 | 9 |
| 27 | `lib/features/logs/presentation/providers/certify_log_provider.dart` | 193 | 163 |
| 28 | `lib/features/logs/presentation/providers/edit_log_form_provider.dart` | 66 | 59 |
| 29 | `lib/features/logs/presentation/providers/logs_provider.dart` | 352 | 310 |
| 30 | `lib/features/logs/presentation/providers/log_detail_tab_provider.dart` | 5 | 4 |
| 31 | `lib/features/logs/presentation/providers/unidentified_events_provider.dart` | 170 | 154 |
| 32 | `lib/features/logs/presentation/widgets/codriver_picker_dialog.dart` | 113 | 105 |
| 33 | `lib/features/logs/presentation/widgets/log_graph.dart` | 101 | 86 |
| 34 | `lib/features/logs/presentation/widgets/status_radio_group.dart` | 61 | 57 |
| 35 | `lib/features/logs/presentation/widgets/time_field_widget.dart` | 53 | 50 |
| 36 | `lib/features/logs/presentation/widgets/time_picker_sheet.dart` | 175 | 165 |
| 37 | `lib/features/logs/presentation/widgets/vehicle_picker_dialog.dart` | 168 | 157 |
| 38 | `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart` | 346 | 324 |
| 39 | `lib/features/logs/presentation/widgets/log_detail_tabs/events_tab.dart` | 144 | 134 |
| 40 | `lib/features/logs/presentation/widgets/log_detail_tabs/expanded_content.dart` | 59 | 55 |
| 41 | `lib/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 383 | 358 |
| 42 | `lib/features/logs/presentation/widgets/log_detail_tabs/log_event_tile.dart` | 166 | 156 |

**المجموع: 6,634 سطر — 42/42 ملف مقروء.**

## E.3 — ملفات خارج النطاق قُرئت للتحقق (Cross-check)

| المسار | سبب القراءة |
|---|---|
| `lib/core/constants/fmcsa_constants.dart` | مطلوب صريحاً في نطاق المهمة (مقابل تكرار الثوابت) |
| `lib/core/config/hos_configuration.dart` | المصدر الحقيقي لحدود HOS |
| `lib/core/time/trusted_time_provider.dart` | للتحقق من HL-07 (Riverpod داخل الملف) |
| `lib/core/services/local_storage_service.dart` (ترويسة فقط) | للتحقق من HL-02 |
| `lib/core/utils/status_color_helper.dart` | للتحقق من HL-34 |
| `lib/core/utils/duration_format.dart` (ترويسة فقط) | للتحقق من HL-26 |
| `lib/core/time/time_formatter.dart` (ترويسة فقط) | للتحقق من HL-26 |
| `lib/backend/contracts/status_dashboard_backend.dart` | للتحقق من HL-02 |
| `lib/features/sync/domain/usecases/sync_engine.dart` (ترويسة فقط) | للتحقق من HL-01 |
| `lib/routes.dart` (قائمة المسارات فقط) | للتحقق من مسار التنقل |
| `lib/l10n/app_localizations.dart` (ترويسة فقط) | للتحقق من HL-17 |
| بحث نصي عبر `lib/` كله | لثوابت HOS والتكرارات والاستيرادات |

---

## ملحق: عدّاد التكرارات (كمية)

| البند | العدد | المواضع |
|---|---|---|
| تنفيذ loading | 12 | `CircularProgressIndicator` في 12 ملفاً (6 في `hos`+`logs` موزّعة) |
| تنفيذ error surface | 7 | `EldRetryView` في 6 ملفات |
| تنفيذ success toast | 6 | `AppFeedback.success` في `hos/.../change_status_page.dart:45`، `logs/.../log_detail_page.dart:137`، `logs/.../edit_log_page.dart:92`، `logs/.../unidentified_events_page.dart:167`، `logs/.../form_tab.dart:249,252`، `logs/.../certify_tab.dart:67` |
| تنسيق المدة | 4 | `daily_log.dart:216`, `events_tab.dart:106`, `logs_list_page.dart:168`, `DurationFormat` (غير مستخدم في الثلاثة الأولى) |
| تنسيق الوقت | 4 | `daily_log.dart:210`, `audit_trail_page.dart:77`, `certify_log_provider.dart:177`, `certify_tab.dart:82` |
| تسميات الحالات | 5 | `status_radio_group.dart:19`, `inspection_preview_page.dart:194`, `inspection_preview_page.dart:273`, `log_graph.dart:26`, `events_tab.dart:104` |
| خريطة رمز→لون | 2 | `StatusColorHelper` (مستخدمة) + `inspection_preview_page.dart:273` (مكرّرة) |
| تطبيع PC/YM | 3 | `log_graph.dart:47`, `events_tab.dart:117`, `inspection_preview_page.dart:194` |
| مطابقة `DutyStatus ⇄ DutyStatusCode` | 4 | `change_status_provider.dart:37`, `status_dashboard_providers.dart:18`, `hos_provider.dart:59`, `hos_rules_engine.dart:51` |
| بناء حمولة سلكية | 2 | `duty_status_tracker.dart:218`, `log_repository_impl.dart:206` |
| تطبيع الوحدات (ميل↔كم) | 3 | `duty_status_tracker.dart:227` (→كم)، `log_model.dart:59` (كم→ميل)، `dto`/presentation بال miles |
| استدعاءات دوال domain من widgets | 5 | `edit_log_page.dart:42,250,279`, `form_tab.dart:142,166` |
| RegExp أحرف الإدخال المكرر | 3 | `daily_form_rules.dart:30`, `trailers_page.dart:100`, `shipping_documents_page.dart:100` |
| writes عبر features | 7 | ( HL-25 ) |
| استيراد widgets عبر features | 3 | `logs_list_page.dart:11`, `inspection_preview_page.dart:16`, `driving_lock_screen.dart:7` |
| رموز حالة مكتوبة يدوياً في presentation | 5 | ( HL-34 ) |



--------------------------------------------------



