# 03 — تحليل السبب الجذري (Root Cause Analysis)

> لكل سبب جذر: **الآلية ← الدليل ← لماذا لم يُكتشف ← الإصلاح الأدنى**.

---

## RC-1 — تصنيف أخطاءduty-status بالتخمين النصي

**البند:** 0.1 (بعد إعادة الصياغة) · **الخطورة:** HIGH · **ثقة:** CONFIRMED

### الآلية

```dart
// lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:370-374
final isNetwork = error.code.contains('network') ||
    error.code.contains('connection') ||
    error.code.contains('timeout') ||
    error.code.contains('offline') ||
    error.context?['statusCode'] == null;      // ← هبوط إلى «شبكة» عند غياب المعلومة
```

ثم:

```dart
if (isNetwork) {
  _applyManualLocal(newStatus: newStatus, enqueue: true);   // السطر 379
  return const ManualDutyChangeResult();                    // refusal = null
}
...
return const ManualDutyChangeResult(
    refusal: DutyStampRefusal.serverRejected);               // السطر 393 — لا يُ reaching
```

### الدليل التجريبي

```
test/core/engine/tracking/duty_status_tracker_test.dart:739
  Expected: 'server_rejected'
  Actual:   <null>
```

هذا **ليس اختباراً جديداً كُتب اليوم** — هو اختبار قائم في `test/` ومعدَّل في شجرة العمل الحالية، **وهو فاشل الآن**. أي أن الخلل مُثبت بالاختبار قبل هذه المهمة.

### السبب الجذري الحقيقي — انفصال между حقل وخريطة

```dart
// lib/core/error/app_error.dart:381-392
final class ServerError extends AppError {
  final int? statusCode;              // ← حقل مُسمّى
  const ServerError({
    required super.code,
    ...
    super.context,                     // ← خريطة منفصلة
    this.statusCode,
  });
}
```

المشكلة **ليست** غياب حالة `statusCode`، بل **وجود مكانين للتخزين وقراءة الموقع الخطأ**:

| البناء | الحقل `statusCode` | `context['statusCode']` |
|---|---|---|
| `error_mapper.dart:168-174` (503) | ✅ 503 | ✅ 503 |
| `error_mapper.dart:178-184` (≥500) | ✅ n | ✅ n |
| `error_mapper.dart:100-108` (400) → `ValidationError` | — | ✅ 400 |
| **`ServerError(code: 'x')` بلا `context`** | **null** | **null** |
| **`ServerError(code: 'x', statusCode: 400)` بلا `context`** | **400** | **null** ← يُقرأ كـ null! |

**آخر صف هو الخلل**: بناء معقول تماماً (`statusCode` كحقل مسمّى) يُقرأ على أنه «لا يوجد statusCode» ⇒ يُصنَّف خطأ شبكة.

### لماذا لم يُكتشف

1. الاختبار الفاشل موجود لكن ضمن مجموعة wider — لم يُقرأ.
2. لا يوجد اختبار في الاتجاه المعاكس: «خطأ **`ValidationError`** من الخادم يجب ألا يُعامل كـ offline».
3. `contains('network')` يبدو حمايةً، بينما هو في الواقع شرط **سالب** مبني على نص.

### الإصلاح الأدنى

⚠️ **تصحيح بعد تحقق إضافي:** `AppError` صنف **مختوم** (`sealed class AppError`، `app_error.dart:34`) و**لا يملك** `statusCode`. الحقل المسمّى موجود على `ServerError` فقط (`app_error.dart:379-381`). لذا `error.statusCode` **لن يُصرَّف**. الصيغة الصحيحة فحص نوع:

```dart
// السطر 370-374
final hasHttpStatus = error.context?['statusCode'] != null ||
    (error is ServerError && error.statusCode != null);
final isNetwork = !hasHttpStatus &&
    (error.code.contains('network') ||
     error.code.contains('connection') ||
     error.code.contains('timeout') ||
     error.code.contains('offline'));
```

**لماذا هذا الأدنى:**
- سطران.
- لا يمس المسار السليم (أخطاء HTTP من `error_mapper` تمرّر `context` و`statusCode` معاً).
- يجعل الاختبار القائم يمر دون تعديله.
- لا يفرض بنotype جديدة ولا يُغيّر `AppError`.

> ✅ **استُوفي التحقق**: `AppError` لا يحتاج تعديلاً — الفحص يتم في موقع الاستهلاك.

---

## RC-2 — إضافة `return` ستُكسر المزامنة التلقائية

**البند:** 0.1 (الجزء الثاني) · **الخطورة:** HIGH كخطر تنفيذ · **ثقة:** CONFIRMED

### الآلية

`_applyManualLocal` جديدة* واحدة*، ثلاثة مستدعين:

```
manualTransition()      ← hos_provider.dart:41   (مزامنة تلقائية من أحداث ELD)
submitManualChange()    ← hos_provider.dart:132  (إجراء المستخدم، مرّ عبر validateManualTransition)
```

المستدعي الأول **لا يمرّ عبر** `validateManualTransition` إطلاقاً —.validation في `HosNotifier.changeStatus` (السطر 95)، بينما `manualTransition` يُستدعى من مستمع `_trackerSub` (السطر 41).

### السيناريو الذي يتعطل

```
1. السائق في حالة driving
2. جهاز ELD يرسل حدثاً ينقل الحالة → sleeper
3. HosNotifier._trackerSub يستقبله (hos_provider.dart:32)
4. يستدعي _engine.manualTransition(sleeper)  ← السطر 41
5. manualTransition → _applyManualLocal(sleeper)
6. الشرط السطر 417: _currentStatus == 'driving' && 'sleeper' != 'driving' → TRUE
7. مع return: التنفيذ يتوقف → لا انتقال محلي
8. الواجهة تبقى تعرض "driving" ← تعارض مع الجهاز
```

### السبب الجذري

**الخلط بين دورين في نفس الدالة:**
- `_applyManualLocal` = **تنفيذ** (apply)
- التحققات القانونية = **سياسة** (policy)

الحارس في السطر 417 يبدو تطبيقاً للقانون، لكنه في الواقع **فحص تشخيصي متبقٍّ** بعد نقل السياسة إلى `validateManualTransition`. لم يُحذف عند النقل ⇒ يُقرأ كأنه مُفعَّل.

### الإصلاح الأدنى

**لا `return`.** بدلاً من ذلك — تصحيح الرسالة لأنها **لا تطابق الشرط**:

```dart
// السطر 417-420 — الحالي
if (_currentStatus == 'driving' && newStatus != 'driving') {
  AppLogger.warning('Cannot manually transition from driving while moving.');
}

// الأدنى
if (_currentStatus == 'driving' && newStatus != 'driving') {
  AppLogger.warning(
    'Manual transition out of DRIVING bypassed the moving-vehicle guard; '
    'source=${_sourceOf(newStatus)}',   // أو ببساطة: بدون ذكر "while moving"
  );
}
```

**لماذا هذا الأدنى:**
- **صفر** تغيير سلوك.
- يزيل التضليل: الرسالة تدّعي فحص حركة لم happens.
- يحوّل خللاً صامتاً إلى إشارة تشخيصية مفيدة.

> **خيار بديل (يُعرض على المالك):** حذف الكتلة بالكامل. النتيجة IDENTICAL فعلياً (`AppLogger.warning` ليس له أثر). يُوصى به إذا لم يكن هناك قيمة تشخيصية.

---

## RC-3 — كاش على مستوى العملية خارج حدّ هوية السائق

**البند:** 0.2 · **الخطورة:** CRITICAL · **ثقة:** CONFIRMED

### الآلية — ثلاث طبقات فشل متداخلة

```
الطبقة 1: التخزين      static  (static في صنف)
الطبقة 2: المفتاح      لا يتضمن driverId
الطبقة 3: الإبطال      غير موجود
```

أي طبقة وحدها كانت ستكفي للسماح بالعبور؛ الثلاث معاً تُنتج التسريب.

### الدليل — المفتاح

```dart
// inspection_repository_impl.dart:74-78
Future<Either<Failure, DotInspectionLog>> getLogs({
  required DriverId driverId,                                  // مُستقبَل
  DateTime? date,
}) {
  final key = date != null
      ? date.toIso8601String().split('T').first                 // '2026-09-23'
      : 'latest';                                              // ← لا driverId
```

### الدليل — الإبطال

| مسار الإبطال المحتمل | موجود؟ |
|---|---|
| `ref.invalidate(inspectionRepositoryProvider)` | ❌ |
| `autoDispose` على المزوّد | ❌ (`Provider` عادي) |
| `clearCache()` / `reset()` | ❌ |
| قراءة `SessionEpoch` في الكاش | ❌ |

### الدليل — التصعيد إلى ملف تنظيمي

```dart
// inspection_repository_impl.dart:145-151
final filePath = await FmcsaEldOutputGenerator.generateAndSave(
  screen: _cachedScreen,
  cycleDays: _cachedCycle,
  logs: _cachedLogs,                       // ← محتوى سائق آخر
  outputFileComment: comment,
  fallbackDriverId: driverId.value.toString(),   // ← معرّف السائق الحالي
);
```

الملف المُنتج يحمل **معرّف السائق الحالي** ومحتوى **سائق سابق**. هذا ملف يقدّم لـ FMCSA.

### لماذا لم يُكتشف

1. `static` صنف في مشروع Flutter يبدو نمط «cache for offline» مألوفاً.
2. لا يوجد مسار إبطال = لا يوجد سطر يمكن تتبّعه.
3. **لا يوجد أي اختبار** يلمس `InspectionRepositoryImpl` (تحقّق: `grep InspectionRepositoryImpl test/` ⇒ 0).

### السبب الجذري الأعمق

`SessionEpoch` **موجود ومُختبَر** (`lib/core/session/session_epoch.dart`) ومُصمَّم بالضبط لهذا الغرض — ووثيقته تقول حرفياً:

> *"The epoch is an invalidation signal... bumped only on real identity boundaries."*

الكاشا لا تستعمله. **السبب الجذري هو عدم تبنّي إشارة موجودة، لا غياب الإشارة.**

### الإصلاح الأدنى — ثلاث ركائز

| الركيزة | التغيير | الحجم |
|---|---|---|
| **أ. النطاق** | `static` ⇒ حقل instance | 4 كلمات |
| **ب. المفتاح** | إضافة `driverId` إلى مفتاح `_cachedLogs` | سطر واحد |
| **ج. الإبطال** | ربط `SessionEpoch.current` بمُنشئ المستودع | سطر واحد |

```dart
// أ.
class InspectionRepositoryImpl implements InspectionRepository {
  DotInspectionScreen? _cachedScreen;
  List<DotInspectionCycleDay> _cachedCycle = [];
  final Map<String, DotInspectionLog> _cachedLogs = {};   // مفتاح: 'drvId:date'
  InformationPacketView? _cachedPacket;

// ب.
final key = '${driverId.value}:${date?.toIso8601String().split('T').first ?? 'latest'}';

// ج. في inspection_repository_providers.dart
final inspectionRepositoryProvider = Provider<InspectionRepository>((ref) {
  ref.watch(sessionEpochProvider);          // إعادة بناء عند كل هوية جديدة
  return InspectionRepositoryImpl(...);
});
```

**لماذا هذا الأدنى:**
- **لا بنية إبطال جديدة** — يعيد استخدام إشارة موجودة ومُختبَرة.
- تغيير instance لا يمس `codriver` القريب تلقائياً (يُعالَج منفصلاً).
- **لا مسح عام للكاش** — يُsinkifier緊急 الأقسام فقط.

---

## RC-4 — مفتاح استجابة موك لا يطابق عقد الإنتاج

**البند:** 0.3 · **الخطورة:** HIGH (بيئي) · **ثقة:** CONFIRMED

### الآلية

```
┌─ الإنتاج ────────────────────────────┐        ┌─ الموك ──────────────────┐
│ EldDvirBackend.list (السطر 34)        │        │ MockDvirBackend.list      │
│ parser: list → {'data': list}         │        │ (السطر 20)                │
│          ↓                             │        │   ↓                        │
│       {'data': [...]}                  │        │ {'reports': []}            │
└────────────────┬───────────────────────┘        └──────────┬─────────────────┘
                 └──────────────┬───────────────────────────┘
                                ↓
                 dvir_repository_impl.dart:54
                 final rawReports = (rawJson['data'] as List?) ?? [];
                                ↓
                              []  ← بصمت
```

### الدليل — الموك يُطبِّع نفسَه في دالة أخرى

```dart
// mock_dvir_backend.dart:46
Future<Result<RawJson>> getDefectsCatalog() async => ok(<String, dynamic>{
  'items': [ ... ],
});
```

`getDefectsCatalog` **يُطبِّع** إلى `{'items': ...}`، والمستودع يقرأ `rawJson['items']`. أي أن الموك **يعرف** النمط في موضع ولا يطبّعه في آخر.

**الاستنتاج:** ليست حالة «موك غير مكتمل» عارفة — بل **تباين غير مقصود** بين ملفَّين في نفس الصنف.

### السبب الجذري

لا يوجد **نوع استجابة** يفرض الشكل. العقد يقول `RawJson` = خريطة مفتوحة، فأي مفتاح مقبولنوعاً.规范化 موزَّعة بين 3 مواضع (backend / mock / repository) بلا مصدر واحد.

### الإصلاح الأدنى

**تعديل سطر واحد** — مطابقة شكل الموك للإنتاج:

```dart
// mock_dvir_backend.dart:20
- return ok({'reports': []});
+ return ok({'data': <dynamic>[]});
```

**لماذا هذا الأدنى:** لا يمس الإنتاج، ويُصلح الموك ليطابقه. لا حاجة لأي استخراج `normalizedEmptyResponse()` لملف واحد.

> ⚠️ **تحذير**: قبل التنفيذ يلزم التحقق من وجود قارئ آخر لـ `'reports'` في `lib/`. (تم البحث — لا يوجد.)

---

## RC-5 — فقد هوية الخطأ في عبور الطبقات

**البند:** 0.4 · **الخطورة:** HIGH · **ثقة:** CONFIRMED

### الآلية — نوع يتجاهل Deliberately_contract

```dart
// rules_screen_provider.dart:22
(failure) => throw Exception(failure.l10nKey),     // Failure → String → Exception
```

ثلاثة أسوار ضائعة في سطر واحد:

```
Failure(message: 'serverError')
   ↓ إلىسلسلة نصية
Exception('serverError')
   ↓ يُستقبل كـ Object في anyErrorUserMessage
loc.errRequestFailedNetwork                        // خطأ شبكة
```

### الدليل — دال�� التصنيف لا فرع له

```dart
// user_facing_message.dart:8, 9, 18, 24
if (error is AppError) ...
if (error is Failure) ...
if (error is String)  ...
return loc.errRequestFailedNetwork;        // ← كل ما عدا ذلك
```

### لماذا لم يُكتشف

الدالة **صُمِّمت لتكون آمنة افتراضياً** — وهذا ممتاز. لكن العيب هو أن `Exception` يقع في «الأ.Unknown»، فيبدو سليماً بينما يربط **نوعاً خاطئاً** بدلالة خاطئة.

### الإصلاح الأدنى — **الخيار الموصى به**

**✅ استُوفي التحقق:** `Failure` يملك حقلاً مسمّى `statusCode` (`failure.dart:6`) ويرث `Equatable`، و`anyErrorUserMessage` يفحص `if (error is Failure)` في السطر 9. **إذن رمي `Failure` مباشرةً محسوب بشكل صحيح.**

```dart
// rules_screen_provider.dart:21-24
return result.fold(
- (failure) => throw Exception(failure.l10nKey),
+ (failure) => throw failure,
  (model) => model,
);
```

**ماذا يتغيّر:**
- قبل: `Exception('serverError')` ⇒ لا يطابق `AppError` ولا `Failure` ولا `String` ⇒ `loc.errRequestFailedNetwork`.
- بعد: `ServerFailure('serverError')` ⇒ يطابق `Failure` ⇒ `loc.errRequestFailed` (السطر 16)، أو `error.message` إن اجتاز `_isSafeUserFacingText` (السطر 13).

**لماذا هذا الأدنى:** سطر واحد، بلا نوع جديد، وبلا فرع جديد في `core`. `Failure` موجود ومُختبر.

**⚠️ ملاحظة على `props`:** `Failure extends Equatable` — `Equatable` يعيد تعريف `==` لكنه لا يمنع الرمي.-behavior سليم.

**خطة بديلة (إن رُفض الرمي المباشر لأي سبب)**: بدل `throw`، استخدم `AsyncValue.failure` — `FutureProvider` يدعمه أصلاً:

```dart
final result = await backend.getRulesScreen(driverId: DriverId(driverId));
return result.match(
  (failure) => throw failure,
  (model) => model,
);
```

**المهم**: نفس الجوهري — **إيقاف تحويل `Failure` إلى نص**، لا إضافة فرع يعالج `Exception`.

---

## RC-6 — مسار الشيفرة الميتة يوهم的非-.ToDO

**البند:** 0.8 · **الخطورة:** LOW · **ثقة:** CONFIRMED

### الآلية

```dart
// auth_interceptor.dart:64
if (options.path == EldEndpoints.session) { return super.onRequest(options, handler); }
//        ↑ 'https://host/api/session'      ↑ '/session'  → لا تطابق أبداً
```

### لماذا لا كسر تسجيل الدخول

```dart
// auth_interceptor.dart:101
if (session != null && session.sessionCredential.isNotEmpty) {
```

عند أول تسجيل دخول: `session == null` ⇒ الكتلة تُتجاوز ⇒ لا كوكي ⇒ الطلب صحيح.

**الأثر = صفر وظيفي.** الشيفرة ميتة وتضليلية فقط.

### الإصلاح الأدنى

استخدام `options.uri.path` بدلاً من `options.path`:

```dart
if (options.uri.path.endsWith(EldEndpoints.session)) {
  return super.onRequest(options, handler);
}
```

**لماذا `endsWith` لا `==`:** `/eld/sessions/123` و`/eld/sessions/connect`根本不 تنتهي بـ `/session`. `endsWith` آمنة对这些 الحالات.

---

## RC-7 — كاش بلا معرّف قِيم داخل خيار الشجرة

**البند:** 0.6 · **الخطورة:** MEDIUM · **ثقة:** CONFIRMED

### الآلية

مزوّدان بنفس الاسم المعنى:

```dart
// tracking_service.dart:200            trackingServiceProvider
// tracking_providers.dart:22           trackingServiceFullProvider
```

مستهلكان مختلفان، وحالة `TrackingService` داخلية:

```dart
// tracking_service.dart:192
void dispose() { _locationSubscription?.cancel(); _isInitialized = false; }
```

### الأثر

```
اختصار "start"  → trackingServiceProvider      (المثال A)
المستودع        → trackingServiceFullProvider   (المثال B)
```

`_isInitialized`, `_locationSubscription`, الحالة الداخلية — **منفصلة**.

### السبب الجذري

`trackingServiceProvider` وُضع في `data/services/` (مع الصنف)، ونسخة ثانية وُضعت في `data/providers/` (مع التركيب). **التصنيف-by-folder** أنشأ مزوّدين. `app_initializer.dart:91` کتب على الأول بافتراض أنهConsumersه.

### الإصلاح الأدنى — **الأصغر**

```dart
// app_initializer.dart:91
- trackingServiceProvider.overrideWithValue(trackingService),
+ trackingServiceFullProvider.overrideWithValue(trackingService),
```

سطر واحد. `quick_actions_initializer.dart:29` سيقرأ `trackingServiceProvider` (غير overridden) — فينشئ مثالاً **جديداً** ⇒ نفس المشكلة!

**إذن الأدنى الصحيح هو سطران**:
```dart
// tracking_providers.dart:22-26  (حذف trackingServiceFullProvider)
// tracking_service.dart:200      (يبقى المصدر الوحيد)
```
ثم `tracking_providers.dart:41` يستهلك `trackingServiceProvider`، و`app_initializer.dart:91` يعمل كما هو.

**الملفات:** 2. **السلوك:** يصبح هناك مثال واحد يُحقن من الإقلاع. **التوافق:** `app_initializer` لم يتغير.

---

## RC-8 — تجاوز一层 من نقطة 위로 متعدد

**البند:** 0.9 · **الخطورة:** MEDIUM (تقني) · **مُعيق: BLOCKED**

### آلية المؤكدات

```dart
final request = await HttpClient().postUrl(Uri.parse(url));
```

- `HttpClient()` جديد لكل نداء، **لا `close()`** ⇒ تسريب مقابض.
- لا `timeout` ⇒ تعليق محتمل.
- بلا مصادقة (لا كوكي).
- `url` = الجذر ⇒ **بلا مسار endpoint**.

### لماذا لا أستطيع اقتراح الإصلاح

البحث trifecta:

| البحث | النتيجة |
|---|---|
| `notificationToken` — `lib/**/*.dart` | **0** |
| `notificationToken` — `openapi.yaml` | **0** |
| `/devices`, `/notifications`, `/token` — `openapi.yaml` | **0** |
| `EldEndpoints` — أي ثابت مشابه | **0** |

**لا يوجد عقد.** أي مسار أقترحه سيكون **اختراعاً**، ومن熟了规则的 هذه المهمة تمنعه.

### قابل للتنفيذ الآن (جزئي)

| العنصر | الإجراء |桃源ool |
|---|---|---|
| إغلاق `HttpClient` | `final client = HttpClient()..connectionTimeout = ...; try {...} finally { client.close(force: true); }` | ✅ — لا يحتاج عقداً |
| مهلة | `request.close().timeout(Duration(seconds: 10))` | ✅ |
| قراءة الرد | فحص `response.statusCode` وتسجيله | ✅ |

**المحوّل إلى `ApiClient` يبقى محجوباً** حتى يُحدَّد الـ endpoint.

---

## RC-9 — تجاوز الحالة غير مقصود لتجاوز واجهة

**البند:** 0.5 · **الخطورة:** LOW (لا CRITICAL) · **ثقة:** CONFIRMED مع تحفّظ

### الدليل المعاكس للتقرير

```dart
// driving_lock_screen.dart:29
if (kDebugMode) ref.read(developerBypassDrivingScreenProvider.notifier).state = true;
```

### السبب الجذري الحقيقي

ليس «guard غير موجود»، بل **guard موجود في طبقة مختلفة عن طبقة الحالة**:

- الشرط `kDebugMode` في **الwriters**.
- الحالة نفسها `StateProvider<bool>` **دائمة بلا autoDispose** وبلا فحص.

أي أن الحماية تعتمد على **نزاهة كل writer مستقبلي**، لا على التصميم.

### الإصلاح الأدنى — **ليس الحذف**

| الخيار | التقييم |
|---|---|
| حذف المزوّد كلياً | ❌ يفقد قدرة devs الاختبار — مقبول لكنه ليس الأدنى |
| **نقل الشرط إلى القارئ** | ✅ الأدنى的正: `home_page.dart:212` |

```dart
// home_page.dart:212
- if (isDriving && isMoving && !developerBypass)
+ if (isDriving && isMoving &&
+     !(kDebugMode && ref.watch(developerBypassDrivingScreenProvider)))
```

**لماذا هذا هو الأدنى:**
- **سلوك الإنتاج لم يتغير إطلاقاً** (المتغير `false` في الإنتاج، والشرط الجديد يحافظ على `kDebugMode`).
- سلوك التطوير لم يتغير.
- **الحراسة أصبحت في القارئ** — لا يمكن لأي writer كسرها.
- سطران بدل حذف capability.

---

## ملخص الأسباب الجذرية

| # | السبب | البند | الخطورة | قابل للتنفيذ الآن |
|---|---|---|---|---|
| RC-1 | قراءة `context` بدل الحقل المسمّى | 0.1 | HIGH | ✅ نعم — استُوفي التحقق |
| RC-2 | خلط التنفيذ بالسياسة | 0.1 | — | ✅ نعم |
| RC-3 | كاش عابر للحدود + مفتاح بلا `driverId` | 0.2 | CRITICAL | ✅ نعم |
| RC-4 | تباين شكل الاستجابة | 0.3 | HIGH | ✅ نعم |
| RC-5 | فقدان هوية `Failure` | 0.4 | HIGH | ✅ نعم — استُوفي التحقق |
| RC-6 | مقارنة مسار غير قابلة للتحقق | 0.8 | LOW | ✅ نعم |
| RC-7 | صنفان بنفس الاسم المعنى | 0.6 | MEDIUM | ✅ نعم |
| RC-8 | تجاوز الشبكة + عقد غير معروف | 0.9 | MEDIUM | ⚠️ جزئي |
| RC-9 | guard في writer لا في reader | 0.5 | LOW | ✅ نعم |

**البنود 0.1 و0.4 و0.9 تحقّقت توصياتهما بعد فحص إضافي لـ `AppError` (مختوم `sealed`؛ `statusCode` على `ServerError` فقط) و`Failure` (حقل مسمّى، يرث `Equatable`، ويفحصه `anyErrorUserMessage`).**