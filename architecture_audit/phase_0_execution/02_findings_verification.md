# 02 — التحقق من نتائج Phase 0 (Findings Verification)

> كل بند **أُعيد فحصه مقابل الكود الحالي**، لا نقلاً عن `11_issue_registry.md`.
> المرجع المنهجي: `architecture_audit/11_issue_registry.md`.

## 0. خلاصة التحقق

| # | البند | الحكم | التغيّر عن تقرير التدقيق |
|---|---|---|---|
| 0.1 | `return` مفقود في `_applyManualLocal` | **PARTIALLY_CONFIRMED** | **توصية التدقيق خاطئة** — ستجرّح مساراً يعمل |
| 0.2 | كاش `static` في مستودعين | **CONFIRMED** | **أسوأ مما وُصف**: `driverId` غير جزء من المفتاح |
| 0.3 | `{'reports':[]}` مقابل `rawJson['data']` | **CONFIRMED** | مطابق |
| 0.4 | `Exception` بلا فرع | **CONFIRMED** | مطابق |
| 0.5 | `developerBypassDrivingScreenProvider` | **PARTIALLY_CONFIRMED** | **مُحرَّض بـ `kDebugMode`** — غير قابل للوصول في الإنتاج |
| 0.6 | `TrackingService` مزدوج | **CONFIRMED** | — |
| 0.7 | `.env` متتبَّع | **INVALID (كجزم أمني)** | `.env` لا يحتوي بيانات اعتماد — لكن الخطر الشرطي قائم |
| 0.8 | استثناء `/session` لا يتحقق | **CONFIRMED** | **الأثر وظيفياً صفري** — ميت لا مكسور |
| 0.9 | `HttpClient` خام | **CONFIRMED** | **المسار الصحيح غير معروف — مُعيق** |

**الإجمالي: 5 CONFIRMED · 3 PARTIALLY_CONFIRMED · 1 INVALID**

> **الخلاصة الحاكمة:** توصيات Phase 0 كما كُتبت في `10_refactoring_roadmap.md` **غير صالحة للتنفيذ الحرفي**. بندان (0.1, 0.5) يحملان توصية مضلّلة، وواحد (0.7) يستند إلى افتراض غير قائم. البند 0.1 تحديداً **يانتج عن تطبيقه خللاً جديداً**.

---

## 0.1 — `duty_status_tracker.dart:417-420`

**الحكم: PARTIALLY_CONFIRMED — fact صحيح، تفسير خاطئ، والتوصية خاطئة.**

### حقيقة الشيفرة (مؤكدة)

```dart
// lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:417-420
if (_currentStatus == 'driving' && newStatus != 'driving') {
  AppLogger.warning(
      'Cannot manually transition from driving while moving.');
}
// ← لا return. التنفيذ يكمل إلى _transitionTo(...) في السطر 428.
```

`AppLogger.warning` فقط، ثم السطر 428 ينفّذ `_transitionTo` الذي يستدعي عنده `_currentStatus = newStatus` (السطر 293). هذا صحيح.

### لكن القاعدة القانونية **ليست هنا** — بل مُنفَّذة في موضع أعلى

```dart
// lib/features/hos/presentation/providers/hos_provider.dart:95-106
final validationResult = _engine.validateManualTransition(
  currentStatus: currentHosStatus,
  newStatus: newStatus,
  currentSpeedKmh: currentSpeedKmh,
  speedThresholdKmh: _ref.read(hosConfigurationProvider).movingSpeedThresholdKmh,
);
if (validationResult.isLeft()) {
  return const ManualDutyChangeResult(refusal: DutyStampRefusal.moving);
}
```

والمحرك:

```dart
// lib/features/hos/domain/engine/hos_rules_engine.dart:82-89
if (currentStatus == DutyStatus.driving && newStatus != DutyStatus.driving) {
  if (currentSpeedKmh >= speedThresholdKmh) {
    return Left(ServerFailure(message: 'Cannot manually change from DRIVING while vehicle is moving ...'));
  }
}
```

**القاعدة مُطبَّقة فعلاً، قبل** الوصول إلى `submitManualChange`. و`_legalRefusal()` في المتتبع (السطر 192) يتحقق من الوقت والجلسة فقط — وهو سلوك صحيح.

### لماذا إضافة `return` **ستُحدث خللاً**

`_applyManualLocal` لها **3 مستدعين**، واحد منهم ليس يدوياً:

| السطر | المستدعي | الطبيعة |
|---|---|---|
| 331 | `manualTransition(...)` | — |
| 379 | `submitManualChange` — مسار offline fallback | يدوي |
| 396 | `submitManualChange` — مسار النجاح | يدوي |

و`manualTransition` يُستدعى من:

```dart
// hos_provider.dart:38-43  (مزامنة تلقائية من أحداث ELD)
if (currentStatus != status) {
  _engine.manualTransition(status, annotation: transition.annotation);
}
```

هذا يعني: **عند وصول حدث ELD ينقل الحالة من `driving` إلى `sleeper`، و`manualTransition` يمر عبر `_applyManualLocal`.** إضافة `return` عند السطر 420 **تمنع تطبيق انتقال شرعي قادم من الجهاز**.

**النتيجة: توصية التدقيق "أضف return" تُنتج انحداراً وظيفياً مباشراً.** تُصنَّف `PARTIALLY_CONFIRMED` لأ reasons这三个.

### الخلل الحقيقي القائم في نفس الدالة — **وهذا الأخطر**

```
اختبار فاشل فعلياً (خط الأساس §1.5، الفشل #1):
  Expected: 'server_rejected'
  Actual:   <null>
  test/core/engine/tracking/duty_status_tracker_test.dart:739
```

السبب الجذري في السطر 370-374:

```dart
final isNetwork = error.code.contains('network') ||
    error.code.contains('connection') ||
    error.code.contains('timeout') ||
    error.code.contains('offline') ||
    error.context?['statusCode'] == null;      // ← السطر 474
```

`ServerError` التحويلي يحمل حقل `statusCode` **مسمّى**، لكن السطر 374 يقرأ `error.context?['statusCode']` أي **خريطة `context`**. مَن ينشئ `ServerError` **بدون** `context` ⇒ `statusCode == null` ⇒ يُصنَّف **خطأ شبكة** ⇒ يُطبَّق محلياً ويُدرج في الطابور.

> **الأثر:** رفض الخادم لحالة الخدمة قد يُنفَّذ محلياً كأنه مُقبول. هذا انحراف **في السجل القانوني**، وليس مجرد خطأ UX.
>
> **نطاق التأكيد:** أخطاء HTTP القادمة من `error_mapper` تمرّر `context` (الأسطر 93-97، 107، 173، 183، 190) فتُصنَّف صحيحة. الخلل يظهر مع الأخطاء المُنشأة محلياً — **وهو ما يثبته الاختبار الفاشل**.

### الحكم النهائي

| | |
|---|---|
| هل الشيفرة كما وُصفت؟ | ✅ نعم |
| هل هي ثغرة قانونية未被 enforcement؟ | ❌ **لا** — `validateManualTransition` تُطبِّقها |
| هل "أضف return" هو الإصلاح؟ | ❌ **خطأ — يُكسر المزامنة التلقائية** |
| هل يوجد خلل حقيقي قريب؟ | ✅ **نعم — تصنيف الخطأ في السطر 374** |

**التوصية:** يُخرج البند 0.1 من Phase 0 بصيغته الحالية، ويُستبدل بمشغلتين منفصلتين — انظر `03_root_cause_analysis.md` §RC-1 و §RC-2.

---

## 0.2 — كاش `static` (inspection + codriver)

**الحكم: CONFIRMED — وأسوأ خطورة مما وثّقه التدقيق.**

### 0.2.a `inspection_repository_impl.dart`

```dart
// الأسطر 29-32
static DotInspectionScreen? _cachedScreen;
static List<DotInspectionCycleDay> _cachedCycle = [];
static final Map<String, DotInspectionLog> _cachedLogs = {};
static InformationPacketView? _cachedPacket;
```

**اكتشاف جديد لا يذكره التدقيق:** المفتاح لا يشمل `driverId`.

```dart
// السطر 74-78
Future<Either<Failure, DotInspectionLog>> getLogs({
  required DriverId driverId,          // ← مُستقبَل
  DateTime? date,
}) {
  final key = date != null ? date.toIso8601String().split('T').first : 'latest';
  // ↑ '2026-09-23' أو 'latest' — لا driverId
```

`driverId` يُمرَّر إلى الـ backend (السطر 80) لكن **لا يُدخل المفتاح**. النتيجة: سجلات السائق A تُخزَّن تحت `'latest'`، والسائق B يقرأها في مسار offline.

وأخطر من ذلك — السطر 92:

```dart
if (_cachedLogs.containsKey(key)) return Right(_cachedLogs[key]!);
if (_cachedLogs.isNotEmpty) return Right(_cachedLogs.values.first);
// ↑ يُرجع سجل أي سائق كان
```

**والأخطر**: السطر 145-151 — توليد ملف **FMCSA 395.24** من هذه الكاشات:

```dart
final filePath = await FmcsaEldOutputGenerator.generateAndSave(
  screen: _cachedScreen,
  cycleDays: _cachedCycle,
  logs: _cachedLogs,
  outputFileComment: comment,
  fallbackDriverId: driverId.value.toString(),
);
```

`fallbackDriverId` هو معرّف السائق **الحالي**، بينما المحتوى من **سائق آخر**. هذا ملف يُقدَّم للجهة التنظيمية.

### 0.2.b `codriver_repository_impl.dart`

```dart
// الأسطر 17-18
static List<CoDriver> _cachedDrivers = [];
static CurrentCoDriverRead? _cachedCurrentCoDriver;
```

مؤكد. يُقرأ في 6 مواضع (`32`, `51`, `55-57`, `84`, `119-122`, `135-138`).

###Paths الإبطال — **بحث شامل**

| السؤال | الجواب |
|---|---|
| هل يوجد `invalidate` يواحد منهما؟ | ❌ لا |
| هل يُعاد بناء المستودع عند تسجيل الخروج؟ | ❌ لا — `inspectionRepositoryProvider` و `coDriverRepositoryProvider` كلاهما `Provider` عادي **غير autoDispose** |
| هل يوجد `clearCache` / `reset`؟ | ❌ لم يُعثر عليه في `lib/` |
| هل `SessionEpoch.bump()` يمسّهما؟ | ❌ لا — الكاش لا تقرأ `SessionEpoch` إطلاقاً |

`inspectionRepositoryProvider` (`inspection_repository_providers.dart:9`) و `coDriverRepositoryProvider` (`codriver_repository_providers.dart:15`) — كلاهما `Provider<...>` دائم طوال عمر التطبيق.

### إشارة الإبطال **جاهزة وموجودة**

```dart
// lib/core/session/session_epoch.dart
abstract final class SessionEpoch {
  static int get current => _value;
  static int bump() => ++_value;          // يُستدعى عند logout/login فقط
  static void resetForTests() { ... }
}
```

موجود ومُختبَر (`auth_interceptor_epoch_test.dart`, `session_isolation_test.dart`). **لا حاجة لبنية إبطال جديدة** — الإصلاح يستعمل إشارة موجودة.

---

## 0.3 — تباين شكل استجابة DVIR

**الحكم: CONFIRMED.**

```dart
// mock_dvir_backend.dart:20
return ok({'reports': []});
```

```dart
// dvir_repository_impl.dart:54
final rawReports = (rawJson['data'] as List<dynamic>?) ?? [];
```

```dart
// eld_dvir_backend.dart:34  ← التطبيع الفعلي للإنتاج
parser: (data) => data is List ? {'data': data} : (data is Map<String, dynamic> ? data : {}),
```

المسار الكامل: `mock` ← `{'reports': []}` ← المستودع يقرأ `data` ← `?? []` ← **قائمة فارغة بلا خطأ**.

**المقارنة مع DVIR-09**: نفس المستودع يستخدم `raw['data']` أيضاً في `getPreviousDvir` (السطر 80). فالنمط متسق — **الذي يتعارض هو الموك وحده**.

**ملاحظة تخفف من الأثر:** الموك بيئة تطوير/اختبار فقط. لا يوجد مسار إنتاج يمرّ من هنا. لكن الموك هو **البيئة التي يُختبر فيها السلوك** ⇒ الاختبارات تعطي ثقة زائفة.

---

## 0.4 — `rules_screen_provider.dart:22`

**الحIGO: CONFIRMED — سلسلة كاملة متحققة.**

```dart
// rules_screen_provider.dart:21-24
return result.fold(
  (failure) => throw Exception(failure.l10nKey),   // ← لاصFundamentalKey كـ String
  (model) => model,
);
```

```dart
// rules_page.dart:230
message: anyErrorUserMessage(err, loc: AppLocalizations.of(context)!),
```

```dart
// user_facing_message.dart:7-25
String anyErrorUserMessage(Object error, {required AppLocalizations loc}) {
  if (error is AppError) return appErrorUserMessage(error, loc: loc);
  if (error is Failure) { ... }
  if (error is String) { ... }
  return loc.errRequestFailedNetwork;      // ← السطر 24: هبوط.Exception لا يوجد
}
```

`Exception` ليس `AppError` ولا `Failure` ولا `String` ⇒ يهبط للسطر 24 ⇒ **كل فشل — شبكة أو تفويض أو خادم أو غير مصنّف — يُعرض كـ«تعذّر الاتصال بالشبكة»**.

نفس النمط في السطر 14 (`throw Exception('User not authenticated')`) ⇒ خطأ المصادقة يُعرض أيضاً كخطأ شبكة.

---

## 0.5 — `developerBypassDrivingScreenProvider`

**الحكم: PARTIALLY_CONFIRMED — التوصيف «غير مقيّد» خاطئ.**

```dart
// home_page.dart:24
final developerBypassDrivingScreenProvider = StateProvider<bool>((ref) => false);
```

```dart
// home_page.dart:212
if (isDriving && isMoving && !developerBypass)
  const Positioned.fill(child: DrivingLockScreen()),
```

**الكتابة الوحيدة** في المشروع كلها:

```dart
// lib/features/hos/presentation/widgets/driving_lock_screen.dart:26-30
GestureDetector(
  onDoubleTap: () {
    // UI Bypass: Just hide the screen locally so we can test other pages
    if (kDebugMode) ref.read(developerBypassDrivingScreenProvider.notifier).state = true;
  },
  child: const Icon(Icons.directions_car, ...),
)
```

> `kDebugMode` = `false` في بناء الإصدار (release). إذاً **التجاوز غير قابل للوصول في الإنتاج**.

**الحكم:** الخلل قائم لكنه **LOW لا HIGH**. تقارير التدقيق وصفه بـ«تعطيل قفل القيادة FMCSA غير مقيّد» — والصياغة تُوهم بعدم وجود حراسة، والحراسة موجودة.

**يبقى خطراً حقيقياً (-latent)** لأن:
1. `StateProvider` دائم بلا `autoDispose` — الحالة تصمد بين الجلسات.
2. أي `ProviderScope(overrides:)` في المستقبل ي.Skip الحارس.
3. لا يوجد اختبار يمنع إعادة الاستخدام.

---

## 0.6 — `TrackingService` المزدوج

**الحكم: CONFIRMED.**

```dart
// lib/features/tracking/data/services/tracking_service.dart:200
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final storage = ref.watch(localStorageProvider);
  final tracker = ref.watch(traccarNativeClientProvider);
  return TrackingService(storage: storage, tracker: tracker);
});

// lib/features/tracking/data/providers/tracking_providers.dart:22
final trackingServiceFullProvider = Provider<TrackingService>((ref) {
  final storage = ref.watch(localStorageProvider);
  final tracker = ref.watch(traccarNativeClientProvider);
  return TrackingService(storage: storage, tracker: tracker);
});
```

**جسمان متطابقان حرفياً.**

### المستهلكون — الفعلي الآن

| المزوّد |abela | السطر |
|---|---|---|
| `trackingRepositoryProvider` | `trackingServiceFullProvider` | `tracking_providers.dart:41` |
| `quick_actions_initializer` | `trackingServiceProvider` | `quick_actions_initializer.dart:29` |

### وأثر الـ override

```dart
// app_initializer.dart:91
trackingServiceProvider.overrideWithValue(trackingService),
```

هذا يُسري على `quick_actions_initializer` فقط. **لا يسري على المستودع.**

### الأثر الفعلي (ليس نظرياً)

```dart
// quick_actions_initializer.dart:31-38
switch (shortcutType) {
  case 'start': await trackingService.start();
  case 'stop':  await trackingService.stop();
  case 'sos':   await trackingService.requestPosition(alarm: 'sos');
}
```

اختصار «start» يستدعي `start()` على **المثال A**، بينما `TrackingRepositoryImpl` يقرأ من **المثال B**. حالة التتبع (running/initialized) منفصلة. في بيئة mock، `app_initializer.dart:67` يُنشئ `TraccarNativeClientImpl()` مباشرة — أي يتجاوز `traccarNativeClientProvider` الواعي بالبيئة.

---

## 0.7 — `.env` متتبَّع في git

**الحكم: INVALID كجزم أمني — الخطر_conditional حقيقي.**

### ما يقوله `.gitignore` (الأسطر 49-52)

```
# Environment: .env is a TRACKED non-secret default (server URL only —
# no credentials live here). Local overrides go to .env.local (ignored).
.env.local
.env.*.local
```

هذا **تعليق توثيفي صريح** من فريق المشروع.

### محتوى `.env` الفعلي (كامل)

```
TRACCAR_ENVIRONMENT=production
API_BASE_URL=https://snsoft.cloud
```

`git ls-files --error-unmatch .env` ⇒ **متتبَّع فعلاً**. ومحتواه **بلا أسرار**.

### لكن الخطر الشرطي قائم

```dart
// lib/core/config/app_environment.dart:86
static String get traccarPassword => _getEnv('TRACCAR_PASSWORD') ?? '';
```

التطبيق **يقرأ** `TRACCAR_PASSWORD` من البيئة. `TRACCAR_PASSWORD` **غير موجود** في `.env` الحالي — لكنه **مُدرج في `app_environment.dart` كمدخل مُتوقع**، وأي مطوّر يضيفه محلياً سيدخل إلى الـ commit لأن `.env` متتبَّع و`.env.local` هو المكان الصحيح.

**التصنيف:** ليس تسرّباً حالياً. هو **سلوك افتراضي مُخاطر**: الملف الذي يقرأ منه التطبيق بيانات اعتماد هو ملف مُتتبَّع.

---

## 0.8 — استثناء مسار الجلسة في `AuthInterceptor`

**الحكم: CONFIRMED (العلامة ميتة) — لكن الأثر الوظيفي صفري.**

### العطل

```dart
// auth_interceptor.dart:64-66
if (options.path == EldEndpoints.session) {     // EldEndpoints.session = '/session'
  return super.onRequest(options, handler);
}
```

```dart
// eld_auth_backend.dart:29-30
final response = await _apiClient.dio.post(
  '$baseUrl/api${EldEndpoints.session}',        // 'https://host/api/session' — مسار مطلق
```

في Dio، تمرير URL مطلق إلى `post()` يجعل `options.path` = السلسلة الكاملة، لا `/session`. **إذن الشرط لا يتحقق أبداً**.

### لكن — لماذا لا يكسر تسجيل الدخول؟

```dart
// auth_interceptor.dart:101
if (session != null && session.sessionCredential.isNotEmpty) { ... attach cookie ... }
```

الاستثناء كان الغرض منه **تخطّي** إرفاق الجلسة. عند أول تسجيل دخول `session == null` ⇒ الكتلة تُتجاوز أصلاً ⇒ لا كوكي يُرفق ⇒ الطلب يمرّ سليماً. **لا يوجد رفض، ولا خطأ**.

الأثر الفعلي = **شيفرة ميتة مضلّلة**. أي تعديل مستقبلي يفترض أنها تعمل سيفشل بصمت.

---

## 0.9 — `HttpClient` خام

**الحIGO: CONFIRMED — مع مُعيق في التصميم.**

```dart
// lib/app/services/push_notification_service.dart:135-145
try {
  final request = await HttpClient().postUrl(Uri.parse(url));
  request.headers.contentType = ContentType.parse('application/x-www-form-urlencoded');
  request.write('id=${Uri.encodeComponent(id)}&notificationToken=${Uri.encodeComponent(token)}');
  await request.close();
  AppLogger.info('✅ Token uploaded to server');
} catch (e) {
  AppLogger.error('Failed to upload token', e);
}
```

### المشكلات المؤكدة

| # | المشكلة | الدليل |
|---|---|---|
| 1 | يتجاوز `ApiClient`/`Dio` بالكامل | استدعاء مباشر على `HttpClient()` |
| 2 | `HttpClient()` **لا يُغلق أبداً** | لا `close()` في أي مسار — تسريب مقابض |
| 3 | لا مهلة (timeout) | `postUrl` بلا `timeout` — قد يعلّق إلى الأبد |
| 4 | لا كوكي/مصادقة | الطلب يذهب بلا `JSESSIONID` |
| 5 | **بلا مسار endpoint** | `url` = `_storage.serverUrl` = **الجذر** |
| 6 | لا تحقق من نجاح العملية | `request.close()` يُهمَل ردّه |

### 🔴 مُعيق: المسار الصحيح غير معروف

| البحث | النتيجة |
|---|---|
| `notificationToken` في `lib/` | **0 نتيجة** |
| `notificationToken` في `openapi.yaml` | **0 نتيجة** |
| `/devices` أو `/notifications` في `openapi.yaml` | **0 نتيجة** |

**لا يوجد أي عقد** — لا في الشيفرة ولا في `openapi.yaml` — يحدد أين يُرفع توكن الإشعار.

> **قاعدة صريحة:** لن أقترح مساراً بديلاً. اختراع مسار = اختراع عقد، وهو ممنوع في هذه المهمة.
> **هذا البند محجوب عن التنفيذ حتى的决定 من مالك المشروع.**

---

## خلاصة ما يجب تغييره في خطة التنفيذ

| البند | حالة الخطة الحالية | المطلوب |
|---|---|---|
| 0.1 | «أضف `return`» | **إلغاء** واستبدال بمشغلتين منفصلتين |
| 0.5 | «أزل من كود الإنتاج» (ضمن Critical) | **إعادة تصنيف إلى LOW** |
| 0.7 | «`.env` من git + تدوير» | **إعادة صياغة**: لا تدوير (لا سر)، بل منع افتراضي |
| 0.8 | ضمن Critical | **إعادة تصنيف إلى LOW** (ميت لا مكسور) |
| 0.9 | «حوّل إلى ApiClient» | **محجوب** حتى يُحدَّد الـ endpoint |
| 0.2 | كما هي | **توسيع**: أضف `driverId` للمفتاح، لا إبطال فقط |
| 0.3, 0.4, 0.6 | كما هي | سليمة |

**النتيجة: Phase 0 كما مكتوبة لا Zeng ready للتنفيذ. 5 من 9 بنود قابلة للتنفيذ فوراً، 2 تحتاج إعادة صياغة، 1 محجوبة، 1 خارج النطاق.**