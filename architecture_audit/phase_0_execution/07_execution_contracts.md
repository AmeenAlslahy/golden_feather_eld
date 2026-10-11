# 07 — عقود التنفيذ (Execution Contracts)

> كل عقد مستقل وقابل للتنفيذ والتراجع بمفرده.
> **لم يُنفَّذ أي مما يلي.**

---

## EC-0.1b · تصحيح رسالة الحارس المضلّلة

```
ISSUE ID:        HL-15 (جزئي) — أعيد تصنيفه
SEVERITY:        LOW
RISK:            LOW RISK
```

**PROBLEM**
الحارس في `duty_status_tracker.dart:417-420` يسجّل رسالة `Cannot manually transition from driving while moving.`، لكن شرطه **لا يفحص الحركة إطلاقاً** — فحصه فقط `_currentStatus == 'driving' && newStatus != 'driving'`. الرسالة تصف قاعدة مختلفة عن القواعد المنفَّذة في `hos_rules_engine.dart:82-89`.

**FILES TO MODIFY**
- `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` (السطور 418-419 — نص فقط)

**FILES TO VERIFY**
- `lib/features/hos/domain/engine/hos_rules_engine.dart:76-91` — القواعد الحقيقية
- `lib/features/hos/presentation/providers/hos_provider.dart:95-106` — نقطة الاستدعاء

**PROPOSED CHANGE**
تغيير نص `AppLogger.warning` فقط. **لا `return`. لا تغيير منطق.**

**BEHAVIOR TO PRESERVE**
- انتقال `driving → X`_qsud mismatch عبر `manualTransition` (المزامنة التلقائية من ELD) يبقى يعمل.
- `AppLogger.warning` يبقى يُصدر عند نفس الشرط.

**TESTS**
لا حاجة — صفر تغيير سلوك. التحقق بمراجعة سجل.

**ACCEPTANCE CRITERIA**
1. `grep "while moving"` لا يعيد السطر 419.
2. `duty_status_tracker_test.dart` يبقى بنفس النتيجة (13 ثابتة).
3. `git diff` يُظهر سطرين فقط.

**RISKS**
صفر. `AppLogger.warning` لا يملك أثراً على الحالة.

**ROLLBACK**
`git diff -- <file>` يعكس سطرين يدوياً. **لا تستخدم `git checkout`** — الملف معدَّل مسبقاً.

**DEPENDENCIES**
يُدمج مع EC-0.1a في تمريرة واحدة (نفس الملف المعدَّل).

---

## EC-0.1a · إصلاح تصنيف خطأ تغيير حالة الخدمة

```
ISSUE ID:        HL-06 (بُعد جديد — لم يُسجَّل في التدقيق الأصلي)
SEVERITY:        HIGH
RISK:            MEDIUM RISK
VERIFIED BY:     اختبار فاشل فعلي (Baseline #1)
```

**PROBLEM**
`duty_status_tracker.dart:374` يقرأ `error.context?['statusCode'] == null` كدليل على «خطأ شبكة». لكن:
- `AppError` صنف **مختوم** بلا حقل `statusCode`.
- `ServerError` يملك حقلاً مسمّى `statusCode` (`app_error.dart:381`) **مستقل** عن `context`.
- أي `ServerError` يُبنى بالحقل المسمّى **بلا** `context` ⇒ يقرأه `null` ⇒ يصنَّف شبكة ⇒ **يُطبَّق محلياً ويُدرج في الطابور**.

الأثر: **رفض خادم لحالة الخدمة قد يُنفَّذ محلياً كأنه مقبول** — انحراف في السجل القانوني.

**FILES TO MODIFY**
- `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` (السطور 370-374)
- `test/core/engine/tracking/duty_status_tracker_test.dart` — **لا يُعدَّل**؛ الاختبار القائم يجب أن ينجح كما هو

**FILES TO VERIFY**
- `lib/core/error/app_error.dart:34` (`sealed`), `:379-381` (`ServerError.statusCode`)
- `lib/core/network/error_mapper.dart:93-97, 168-190` (كلاهما يمرّر `context` + `statusCode`)
- `lib/features/sync/domain/usecases/sync_engine.dart` (طابور offline)

**PROPOSED CHANGE**
```dart
final hasHttpStatus = error.context?['statusCode'] != null ||
    (error is ServerError && error.statusCode != null);
final isNetwork = !hasHttpStatus &&
    (error.code.contains('network') ||
     error.code.contains('connection') ||
     error.code.contains('timeout') ||
     error.code.contains('offline'));
```
> `ServerError` مُستورَد أصلاً في هذا الملف (يُستخدم في `result.fold`).

**BEHAVIOR TO PRESERVE**
- خطأ شبكة حقيقي ⇒ لا `hasHttpStatus` ⇒ `isNetwork == true` ⇒ طابور offline كما قبل.
- خطأ HTTP من `error_mapper` (400/401/5xx) ⇒ `context['statusCode']` موجود ⇒ تصنيف صحيح كما قبل.
- **يتغيّر**: `ServerError` بلا `context` ⇒ ينتقل من «offline» إلى «serverRejected». **هذا هو الإصلاح المطلوب.**

**TESTS**
1. **قائم — يجب أن ينجح**: `duty_status_tracker_test.dart:739` (`Expected 'server_rejected' / Actual <null>`).
2. **جديد — `duty_status_tracker_error_classification_test.dart`**:
   - `NetworkError` ⇒ طابور محلي (حماية ضد الإفراط في التصحيح).
   - `ServerError(statusCode: 409)` بلا `context` ⇒ `serverRejected`.
   - `ValidationError` (400) ⇒ ليس offline.

**ACCEPTANCE CRITERIA**
1. Baseline #1 ينتقل من ✗ إلى ✓.
2. الاختبارات الثلاثة الجديدة تنجح.
3. المجموع الكلي يبقى **13 failing** (ينقص واحد = 12، لأن Baseline #1 صار ناجحاً ⇒ **المعيار 12**).
4. `sync.submitted` في اختبار الرفض يبقى `isEmpty`.

**RISKS**
- **قصور في الإصلاح**: لو وُجد `ServerError` يُبنى بلا `statusCode` وبلا `context`uba لخطأ شبكة، سيُصنَّف رفضاً.probability منخفضة.
- **تغيّر سلوك مرئي**: مستخدم يرى الآن «رفض الخادم» حيث كان يرى نجاحاً. هذا **تصحيح** لكنه يحتاج تواصلاً.

**ROLLBACK**
عكس سطرين يدوياً. **لا `git checkout`** — الملف معدَّل مسبقاً.

**DEPENDENCIES**
يُنفَّذ مع EC-0.1b (نفس الملف).

---

## EC-0.2a · عزل كاش `InspectionRepositoryImpl`

```
ISSUE ID:        DST-002
SEVERITY:        CRITICAL
RISK:            HIGH RISK
```

**PROBLEM**
أربعة كاشات `static` على مستوى العملية (الأسطر 29-32). **لا مسار إبطال في `lib/`**، والمزوّد دائم غير `autoDispose`. النتيجة: **السائق B على جهاز ELD مشترك يقرأ كاش السائق A.**

**الأخطر**: مفتاح `_cachedLogs` (السطر 78) **لا يشمل `driverId`** رغم أن `getLogs` يستقبله. والسطر 92 يُرجع `_cachedLogs.values.first` — سجل أي سائق. والأسوأ: السطور 145-151 تُولّد **ملف FMCSA 395.24** من هذه الكاشات مع `fallbackDriverId` للسائق **الحالي** ⇒ هوية B بمحتوى A.

**FILES TO MODIFY**
- `lib/features/inspection/data/repositories/inspection_repository_impl.dart` (29-32، 78)
- `lib/features/inspection/data/providers/inspection_repository_providers.dart` (9-15)

**FILES TO VERIFY**
- `lib/core/session/session_epoch.dart` · `lib/core/session/session_epoch.dart` re-exported as `sessionEpochProvider`
- `lib/features/inspection/data/services/fmcsa_eld_output_generator.dart` (146-148 مستهلك)
- `lib/features/inspection/presentation/providers/inspection_provider.dart`
- كل مستهلك: `inspection_repository_providers.dart`Consumers

**PROPOSED CHANGE** — ثلاث ركائز

| # | التغيير |
|---|---|
| أ | `static` ⇒ حقول instance (4 أسطر) |
| ب | المفتاح: `'${driverId.value}:${date…}'` بدل `'${date…}'` |
| ج | `ref.watch(sessionEpochProvider)` في المزوّد ⇒ إعادة بناء عند كل هوية جديدة |

> **لا إبطال عام للكاش.** المسح الشامل أثناء عمليات متزامنة يُنتج حالات سباق؛ الإبطال المُقيَّد بالـ epoch + المفتاح المقيَّد بالسائق يحلّها دون لمس عابر.

**BEHAVIOR TO PRESERVE**
- وضع Offline: لا يزال يعرض **بيانات السائق الحالي**.
- النجاح عبر الإنترنت: لا يتغير.
- إعادة البناء عند `sessionEpoch` **تزيد** التصحيح ولا تنقصه.

**TESTS**
`test/features/inspection/data/repositories/inspection_repository_isolation_test.dart` (جديد) — 4 سيناريوهات في `05_regression_test_plan.md` §T-0.2a.
**يجب أن تفشل قبل وت国安 بعد.**

**ACCEPTANCE CRITERIA**
1. `grep -n "static.*_cached" inspection_repository_impl.dart` ⇒ **0 نتيجة**.
2. `T-0.2a` الأربعة تنجح.
3. `FmcsaEldOutputGenerator` لا يُمرَّر له محتوى سائق آخر.
4. المجموع 13 failing (أو 12 إن نجح Baseline #1).

**RISKS**
- **تغيّر سلوك offline**: قد يفقد السائق سجلاته المخزنة عند أول انقطاع بعد التحديث. مقبول — الأمان أهم.
- `TestWidgetsFlutterBinding` قد يكون مطلوباً بسبب `path_provider`.
- **تعارض مع تعديلات قائمة**: الملف **غير معدَّل** مسبقاً ⇒ تعارض صفري.

**ROLLBACK**
عكس ~10 أسطر. الملف غير معدَّل مسبقاً ⇒ `git diff` آمن كمرجع.

**DEPENDENCIES**
تقرير عن فشل `codriver_page_test.dart` السبعة (لا強Depends تقنياً، لكن معرفياً).

---

## EC-0.2b · عزل كاش `CoDriverRepositoryImpl`

```
ISSUE ID:        COD-001
SEVERITY:        HIGH
RISK:            MEDIUM RISK
```

**PROBLEM**
كاشان `static` (17-18) بلا إبطال. `_cachedCurrentCoDriver` يحمل **العلاقة بين سائقين** — عرضه لسائق آخر تسريب هوية زميل. الكاشا **أسفل** حواجز المالك التي فرضتها الـ 4 notifiers في `codriver_provider.dart`.

**FILES TO MODIFY**
- `lib/features/codriver/data/repositories/codriver_repository_impl.dart` (17-18 + 6 مواقع قراءة/كتابة)
- `lib/features/codriver/data/providers/codriver_repository_providers.dart` (15-20)

**FILES TO VERIFY**
- `codriver_provider.dart` (حواجز المالك/الـepoch القائمة)
- `codriver_repository_impl_test.dart` (لا يُعدَّل)

**PROPOSED CHANGE**
نفس ثلاث ركائز (instance + `driverId` في المفتاح + `sessionEpoch`).

**BEHAVIOR TO PRESERVE**
- عرض قائمة السائقين المتاحة أثناء انقطاع الشبكة — للسائق الحالي فقط.

**TESTS**
`test/features/codriver/data/repositories/codriver_repository_isolation_test.dart` (جديد) — 3 سيناريوهات.

**ACCEPTANCE CRITERIA**
1. `grep -n "static.*_cached" codriver_repository_impl.dart` ⇒ 0.
2. الاختبارات الثلاثة تنجح.
3. `codriver_repository_impl_test.dart` القائم يبقى ناجحاً.
4. **Baseline #2-#9 تبقى 7 فشل** (لا تتحسن ولا تسوء).

**RISKS**
⚠️ **الأعلى في Phase 0 من حيث حساسية الاختبار**: `codriver_page_test.dart` فيه 7 إخفاقات سابقة. الفارق بينها وبين التعديل يجب أن يكون **مفهوماً** لا مُتوَقَّعاً فقط.

**ROLLBACK**
عكس ~8 أسطر.

**DEPENDENCIES**
ينفَّذ بالتوازي مع EC-0.2a (ملفات مختلفة).

---

## EC-0.3 · مطابقة شكل استجابة DVIR في الموك

```
ISSUE ID:        BACK-008
SEVERITY:        HIGH (بيئي)
RISK:            LOW RISK
```

**PROBLEM**
`mock_dvir_backend.dart:20` يرجع `{'reports': []}`؛ `dvir_repository_impl.dart:54` يقرأ `rawJson['data']` ⇒ `?? []` ⇒ **قائمة فارغة بلا خطأ**. الإنتاج يطبّع إلى `{'data': ...}` في `eld_dvir_backend.dart:34`.

**FILES TO MODIFY**
- `lib/backend/adapters/mock/sub/mock_dvir_backend.dart` (السطر 20)

**FILES TO VERIFY**
- `dvir_repository_impl.dart:54, 80`
- `eld_dvir_backend.dart:34`
- بحث شامل: لا يوجد قارئ لـ `'reports'`

**PROPOSED CHANGE**
```dart
- return ok({'reports': []});
+ return ok({'data': <dynamic>[]});
```

**BEHAVIOR TO PRESERVE**
- الإنتاج لم يُمس.
- `getDefectsCatalog` (السطر 46) لم يُمس — يطبّع بالفعل إلى `{'items'}`.

**TESTS**
`test/backend/adapters/mock/sub/mock_dvir_backend_test.dart` (قائم — يُضاف اختبار).

**ACCEPTANCE CRITERIA**
1. `grep -n "'reports'" mock_dvir_backend.dart` ⇒ 0.
2. الاختبار الجديد ينجح.
3. Baseline #10 و #11 يبقيان فاشلين (13 ثابتة).

**RISKS**
منخفض جداً. mocks فقط.

**ROLLBACK**
سطر واحد.

**DEPENDENCIES**
لا شيء.

---

## EC-0.4 · استعادة هوية `Failure`

```
ISSUE ID:        ACC-003
SEVERITY:        HIGH
RISK:            LOW RISK
```

**PROBLEM**
`rules_screen_provider.dart:22` يرمي `Exception(failure.l10nKey)` — تحويل `Failure` ← نص ← `Exception`. `anyErrorUserMessage` (`user_facing_message.dart:8-24`) يفحص `AppError` و`Failure` و`String` فقط ⇒ `Exception` يهبط للسطر 24 ⇒ **كل خطأ يُعرض كخطأ شبكة**.

**FILES TO MODIFY**
- `lib/features/account/presentation/providers/rules_screen_provider.dart` (السطر 22)

**FILES TO VERIFY**
- `lib/core/error/failure.dart:4-15` — تأكد من `Failure extends Equatable` ✓ **تم التحقق**
- `lib/core/error/user_facing_message.dart:9` — فرع `Failure` موجود ✓
- `lib/features/account/presentation/pages/rules_page.dart:230`

**PROPOSED CHANGE**
```dart
- (failure) => throw Exception(failure.l10nKey),
+ (failure) => throw failure,
```

**BEHAVIOR TO PRESERVE**
- سلوك `Exception` في `anyErrorUserMessage` **لم يُمسّ** — يبقى يعرض رسالة شبكة للأخطاء غير المصنّفة. هذا صحيح.

**TESTS**
`test/features/account/presentation/rules_screen_error_test.dart` (جديد) + اختبار وحدة لـ `anyErrorUserMessage`.

**ACCEPTANCE CRITERIA**
1. `grep -n "Exception(failure" rules_screen_provider.dart` ⇒ 0.
2. فشل `ServerFailure` ⇒ `errRequestFailed` لا `errRequestFailedNetwork`.
3. فشل شبكة ⇒ `errNoInternet`.
4. Baseline #12 و #13 يبقيان فاشلين.

**RISKS**
منخفض. `Failure` يحمل `statusCode` مسمّى ويمرّ بفرع `is Failure`.

**ROLLBACK**
سطر واحد.

**DEPENDENCIES**
لا شيء.

---

## EC-0.5 · نقل حراسة تجاوز قفل القيادة

```
ISSUE ID:        HOM-002 (أُعيد تصنيفه: HIGH → LOW)
SEVERITY:        LOW
RISK:            LOW RISK
```

**PROBLEM**
`developerBypassDrivingScreenProvider` دائم بلا `autoDispose`. الحماية (`kDebugMode`) في **الكاتب** (`driving_lock_screen.dart:29`) لا في القارئ ⇒ الخطر يعتمد على نزاهة كل كاتب مستقبلي.

> **تصحيح**: تقرير التدقيق وصفه بـ«غير مقيّد» — **غير دقيق**. `kDebugMode` يقيّده بالفعل في الإنتاج.

**FILES TO MODIFY**
- `lib/features/home/presentation/pages/home_page.dart` (السطر 212)

**FILES TO VERIFY**
- `lib/features/hos/presentation/widgets/driving_lock_screen.dart:26-30`

**PROPOSED CHANGE**
```dart
- if (isDriving && isMoving && !developerBypass)
+ if (isDriving && isMoving &&
+     !(kDebugMode && ref.watch(developerBypassDrivingScreenProvider)))
```
+ `import 'package:flutter/foundation.dart';`

**BEHAVIOR TO PRESERVE**
- الإنتاج: `kDebugMode == false` ⇒Term لم تتغيّر إطلاقاً.
- التطوير: `bypass == true` ⇒ القفل يختفي كما كان.

**TESTS**
اختبار آلي جزئي + **تحقق يدوي إلزامي على بناء release**.

**ACCEPTANCE CRITERIA**
1. سلوك debug لم يتغير.
2. بناء release: double-tap على أيقونة السيارة **لا** يزيل القفل.
3. `home_page_test.dart` ينجح.

**RISKS**
**صفر** — لا تغيير سلوكي ممكن.

**ROLLBACK**
سطران.

**DEPENDENCIES**
لا شيء.

---

## EC-0.6 · توحيد مصدر `TrackingService`

```
ISSUE ID:        DST-037 + CORE-005
SEVERITY:        MEDIUM
RISK:            MEDIUM RISK
```

**PROBLEM**
مزوّدان بنفس الاسم المعنى (`trackingServiceProvider` في `tracking_service.dart:200`، `trackingServiceFullProvider` في `tracking_providers.dart:22`) بجسم متطابق حرفياً. `app_initializer.dart:91` يحقن الأول؛ `quick_actions_initializer.dart:29` يقرأ الأول؛ `trackingRepositoryProvider` يقرأ الثاني. ⇒ **حالتا تتبّع مستقلتان**.

**FILES TO MODIFY**
- `lib/features/tracking/data/providers/tracking_providers.dart` (حذف 22-26؛ تعديل السطر 41)

**FILES TO VERIFY**
- `lib/app/app_initializer.dart:65-68, 91`
- `lib/app/services/quick_actions_initializer.dart:29`
- `lib/features/tracking/data/services/tracking_service.dart:200-204`

**PROPOSED CHANGE**
```dart
// tracking_providers.dart
- final trackingServiceFullProvider = Provider<TrackingService>(...) { ... };   // حذف

// tracking_providers.dart:41
- final service = ref.watch(trackingServiceFullProvider);
+ final service = ref.watch(trackingServiceProvider);
```

**لماذا الحذف وليس تعديل `app_initializer`:** تعديل `app_initializer` وحده **لا يحل** — `quick_actions_initializer` سيحصل على مثال جديد. المصدر الواحد هو الحل.

**BEHAVIOR TO PRESERVE**
- `app_initializer` لم يتغيّر (سلطة كاملة على `trackingServiceProvider`).
- تهيئة Mock: `app_initializer.dart:67` يُنشئ `TraccarNativeClientImpl()` مباشرة — **يبقى** (خارج نطاق هذا العقد؛ يُذكر في Q3).

**TESTS**
`test/features/tracking/data/providers/tracking_provider_unification_test.dart` (جديد).

**ACCEPTANCE CRITERIA**
1. `grep -rn "trackingServiceFullProvider" lib/` ⇒ **0**.
2. `identical(c.read(trackingServiceProvider), c.read(trackingServiceProvider))` ⇒ true.
3. `app_initializer.dart` **غير معدَّل**.
4. `tracking_orchestrator_test.dart` و `tracking_provider_test.dart` يبقان ناجحين.

**RISKS**
- انقطاع طفيف أثناء `trackingOrchestratorProvider` المهيّأ مسبقاً.
- `tracking_providers.dart` غير معدَّل مسبقاً ⇒ تعارض صفري.

**ROLLBACK**
إعادة 5 أسطر. **لا weakens `app_initializer`**.

**DEPENDENCIES**
لا شيء.

---

## EC-0.7 · منع تتبّع ملف البيئة

```
ISSUE ID:        CORE-015 (أُعيد تصنيفه: سرٌّ متسرّب → سلوك افتراضي مُخاطر)
SEVERITY:        LOW
RISK:            LOW RISK
```

**PROBLEM**
`.env` متتبَّع في git، و`app_environment.dart:86` يقرأ منه `TRACCAR_PASSWORD`.

**FILES TO MODIFY**
- `.gitignore`

**FILES TO VERIFY**
- `.env` (محتواه الحالي: `TRACCAR_ENVIRONMENT`, `API_BASE_URL` — **بلا أسرار**)
- `.env.example`

**PROPOSED CHANGE**
```diff
  # Environment: .env is a TRACKED non-secret default (server URL only —
  # no credentials live here). Local overrides go to .env.local (ignored).
+ .env
  .env.local
```

> **لا `git rm --cached`** — هذا يكسر بناء CI حيث يُقرأ `.env` كasset.
> **لا تدوير** — لا يوجد secret متسرّب.

**BEHAVIOR TO PRESERVE**
- `pubspec.yaml` يُدرج `.env` كasset — يعمل محلياً و في CI.
- المطوّرون المحليون يستطيعون تجاوز بـ `.env.local`.

**TESTS**
يدوي: `git check-ignore -v .env` ⇒ يجب أن يُرجع match بعد التغيير.

**ACCEPTANCE CRITERIA**
1. `git check-ignore -v .env` ⇒ match.
2. `git status --short` لم يتغيّر بخلاف إضافة سطر في `.gitignore`.
3. التطبيق يبني (`.env` ما زال موجوداً على القرص).

**RISKS**
منخفض جداً.

**ROLLBACK**
حذف سطر.

**DEPENDENCIES**
لا شيء.

---

## EC-0.8 · تصحيح استثناء مسار الجلسة

```
ISSUE ID:        BACK-031 (أُعيد تصنيفه: HIGH → LOW)
SEVERITY:        LOW
RISK:            MEDIUM RISK ⚠️ (سلوك يتغير)
```

**PROBLEM**
`auth_interceptor.dart:64` يقارن `options.path == '/session'`. `EldAuthBackend` يمرّر `'$baseUrl/api/session'` — **مسار مطلق** ⇒ `options.path` = السلسلة الكاملة ⇒ الشرط لا يتحقق أبداً.

> **الأثر الحالي = صفر**: عند أول تسجيل دخول `session == null` ⇒ كتلة الإرفاق تُتجاوز أصلاً.

**FILES TO MODIFY**
- `lib/backend/http/interceptors/auth_interceptor.dart` (السطر 64)

**FILES TO VERIFY**
- `lib/backend/adapters/eld_engine/sub/eld_auth_backend.dart:29-30, 107, 156`
- `lib/backend/http/eld_endpoints.dart:15, 73-82`
- `test/backend/http/interceptors/auth_interceptor_test.dart`

**PROPOSED CHANGE**
```dart
- if (options.path == EldEndpoints.session) {
+ if (options.uri.path.endsWith(EldEndpoints.session)) {
```

**BEHAVIOR TO PRESERVE**
- تسجيل الخروج / إنشاء الجلسة يعملان.
- `/eld/sessions/123` و`/eld/sessions/connect` **لا** يُستثنيان (`endsWith` لا يطابقهما).

**TESTS**
اختبار حارس ضد الانحدار المستقبلي: طلب إنشاء جلسة **مع وجود جلسة سابقة** يجب ألا يُرفق كوكي قديماً.

**ACCEPTANCE CRITERIA**
1. تسجيل الدخول والخروج يعملان.
2. `/eld/sessions/123/members` يُرفق له الكوكي (لا استثناء خاطئ).
3. الاختبارات القائمة تنجح.

**RISKS**
⚠️ **يتغير سلوك**: إذا كان `auth_interceptor.dart` معدَّلاً (وهو **معدَّل**)، Execute أولاً على `git diff` القائم.
⚠️ **شرط**: الموافقة على أن الاستثناء كان مقصوداً.

**ROLLBACK**
سطر واحد، **لكن يدوياً** — الملف معدَّل مسبقاً.

**DEPENDENCIES**
🔴 **قرار المالك مطلوب** — انظر `09_open_questions.md` Q2.

---

## EC-0.9 · إغلاق `HttpClient` (جزئي)

```
ISSUE ID:        CORE-016
SEVERITY:        MEDIUM
STATUS:          ⛔ جزئي — الباقي محجوب
RISK:            LOW RISK (للجزء القابل للتنفيذ)
```

**PROBLEM**
`push_notification_service.dart:135-145` يُنشئ `HttpClient()` في كل نداء **ولا يُغلقه أبداً**، بلا مهلة، بلا فحص رد، وبلا مسار endpoint.

**FILES TO MODIFY**
- `lib/app/services/push_notification_service.dart` (السطور 135-145)

**FILES TO VERIFY**
- بحث شامل: `notificationToken`, `/devices`, `/notifications` ⇒ **0 في `lib/` و `openapi.yaml`**

**PROPOSED CHANGE** — الجزء القابل للتنفيذ فقط
```dart
try {
  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    final request = await client.postUrl(Uri.parse(url)).timeout(const Duration(seconds: 10));
    request.headers.contentType = ContentType.parse('application/x-www-form-urlencoded');
    request.write('id=${Uri.encodeComponent(id)}&notificationToken=${Uri.encodeComponent(token)}');
    final response = await request.close();
    AppLogger.info('Token upload responded ${response.statusCode}');
  } finally {
    client.close(force: true);
  }
}
```

**⛔ غير مشمول**: التحويل إلى `ApiClient` — محجوب حتى يُحدَّد الـ endpoint.

**BEHAVIOR TO PRESERVE**
- الرفع الناجع يستمر.
- لا يتغيّر شيء آخر — لا مصادقة ولا مسار.

**TESTS**
صعب — `HttpClient` خام غير قابل لـ mock بـ `http_mock_adapter`. **هذا في حد ذاته حجة للتحويل إلى `ApiClient` لاحقاً.**

**ACCEPTANCE CRITERIA**
1. لا `HttpClient()` غير مغلق.
2. `timeout` موجود.
3. `statusCode` يُسجَّل.

**RISKS**
منخفض. أسوأ حالة: تسجيل إضافي.

**ROLLBACK**
استعادة الدالة كما كانت (بتراجع يدوي).

**DEPENDENCIES**
🔴 **الجزء الكامل محجوب** — انظر `09_open_questions.md` Q1.

---

## ملخص العقود

| العقد | البند | المخاطرة | التنفيذ | محجوب |
|---|---|---|---|---|
| EC-0.1b | 0.1b | LOW | ✅ | — |
| EC-0.1a | 0.1a | MEDIUM | ✅ | — |
| EC-0.2a | 0.2 | **HIGH** | ✅ | — |
| EC-0.2b | 0.2 | MEDIUM | ✅ | — |
| EC-0.3 | 0.3 | LOW | ✅ | — |
| EC-0.4 | 0.4 | LOW | ✅ | — |
| EC-0.5 | 0.5 | LOW | ✅ | — |
| EC-0.6 | 0.6 | MEDIUM | ✅ | — |
| EC-0.7 | 0.7 | LOW | ✅ | — |
| EC-0.8 | 0.8 | MEDIUM | ✅ | ⏳ قرار |
| EC-0.9 | 0.9 | LOW (جزئي) | ✅ جزئياً | ⛔ عقد |

**10 عقود · 8 جاهزة · 1 يحتاج قراراً · 1 جزئي**