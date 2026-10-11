# 05 — خطة حماية الانحدار (Regression Test Plan)

## 0. القواعد الحاكمة

1. **اختبار يفشل قبل الإصلاح وينجح بعده** هو المطلوب. اختبار ينجح قبله وبعده **لا يحمي** من الانحدار.
2. **خط الأساس 13 فشلاً** (`01_baseline.md` §1.5). المعيار: `13 failing → 13 failing`. أي فشل جديد = انحدار مُحدَث.
3. **لا تعديل على اختبارات فاشلة مسبقاً** إلا بموافقة المالك — هي الدليل على خلل قائم (خاصة `duty_status_tracker_test.dart:739`).
4. أي اختبار جديد يوضع في `test/` بنفس اصطلاح المجلد القائم (`test/features/...`, `test/backend/...`).
5. `SessionEpoch.resetForTests()` متاح，已有 (`session_epoch.dart:28`) — استخدمه في كل اختبار عزل.

---

## 1. الاختبارات المطلوبة لكل إصلاح

### T-0.2a · عزل كاش `InspectionRepositoryImpl` — **الأولوية 1**

```dart
// test/features/inspection/data/repositories/inspection_repository_isolation_test.dart
```

| البند | القيمة |
|---|---|
| **النوع** | `test` (وحدة) — يحتاج `TestWidgetsFlutterBinding` بسبب `FmcsaEldOutputGenerator` (path_provider) |
| **ي��.fail قبل**؟ | ✅ نعم |
| **يمر بعد**؟ | ✅ نعم |

**السيناريو 1 — منع القراءة عبر السائق (فشل قبل / نجاح بعد)**

```dart
test('driver B must not receive driver A cached logs when offline', () async {
  SessionEpoch.resetForTests();
  final backend = _FakeInspectionBackend();
  final net = _AlwaysOffline();
  final repoA = InspectionRepositoryImpl(backend, net);
  final repoB = InspectionRepositoryImpl(backend, net);

  await repoA.getLogs(driverId: const DriverId(101), date: DateTime.utc(2026, 9, 23));
  // backend نجح للسائق A ⇒ _cachedLogs['101:2026-09-23']

  final b = await repoB.getLogs(driverId: const DriverId(202), date: DateTime.utc(2026, 9, 23));

  expect(b.isLeft(), isTrue, reason: 'B لا يجوز أن يقرأ كاش A');
});
```

**السيناريو 2 — بادئة `driverId` في المفتاح (فشل قبل)**

```dart
test('cache key is driver-scoped, not date-only', () async {
  // بعد الإصلاح: مفتاحان منفصلان لـ driverId مختلف لنفس التاريخ
  // قبل: مفتاح واحد ⇒ تداخل
});
```

**السيناريو 3 — إبطال عند تغيّر الـ epoch (فشل قبل)**

```dart
test('new session epoch resets inspection cache', () async {
  // ارفع الـ epoch عبر SessionEpoch.bump() وأعد البناء
  // النتيجة: B لا يرى كاش A حتى لو كان driverId متطابقاً
});
```

**السيناريو 4 — منع التسرّب في ملف FMCSA (فشل قبل)**

```dart
test('generated FMCSA file uses only the requesting driver cache', () async {
  // يلتقط محتوى الملف المولّد ويتأكد أنه لا يحتوي سجلات السائق A
});
```

**المحاكيات المطلوبة:**

```dart
class _FakeInspectionBackend implements InspectionBackend { ... }
class _AlwaysOffline implements NetworkInfo { bool get isConnected => false; }
```

> ⚠️ **تنبيه**: `InspectionRepositoryImpl` يستورد `FmcsaEldOutputGenerator` الذي يستورد `path_provider`. قد يحتاج `TestWidgetsFlutterBinding.ensureInitialized()` + mock قناة المنصة.

---

### T-0.2b · عزل كاش `CoDriverRepositoryImpl` — **الأولوية 1**

```dart
// test/features/codriver/data/repositories/codriver_repository_isolation_test.dart
```

| السيناريو | يfail قبل؟ |
|---|---|
| `getAvailableDrivers()` للسائق B لا تُرجع كاش A عند offline | ✅ |
| `getCurrentCoDriver()` لا يعيد كاش A | ✅ |
| بعد `SessionEpoch.bump()` + إعادة بناء ⇒ كاش جديد | ✅ |

**الفرق الجوهري عن 0.2a:** الموك هنا أخطر فعلياً — `_cachedCurrentCoDriver` يحمل **العلاقة بين سائقين**، وعرضه لسائق آخر يعني **تسريب هوية زميل**.

> ⚠️ `codriver_repository_impl_test.dart` موجود — يضاف الملف الجديد بجانبه ولا يُعدَّل.

---

### T-0.1a · رفض الخادم لا يُطبَّق محلياً — **الأولوية 1**

```dart
// تعديل إلزامي على: test/core/engine/tracking/duty_status_tracker_test.dart
// الاختبار موجود بالفعل عند السطر 739 ولا يحتاج جديداً.
```

| البند | القيمة |
|---|---|
| **النوع** | `test` (وحدة) — موجود |
| **فشل قبل**؟ | ✅ مُثبت — `Expected 'server_rejected' / Actual <null>` |
| **يمر بعد**؟ | ✅ إذا كان RC-1 مُطبَّقاً |

**هذا الاختبار هو نفسه دليل الخلل.** تنفيذه = إثبات الإصلاح.

**اختبار مكمّل مطلوب** (يكشف اتجاه التصحيح الخاطئ):

```dart
// test/core/engine/tracking/duty_status_tracker_error_classification_test.dart
test('network error still enqueues locally (guard against over-correction)',
    () async {
  // خطأ NetworkError ⇒ refusal == null والطابور حوى الحدث
});

test('ServerError with named statusCode but no context is NOT network',
    () async {
  // هذا هوCase الذي يفشل قبل الإصلاح ولا يغطيه الاختبار القائم
  final e = ServerError(code: 'server.rejected', statusCode: 409);
  // متوقع: refusal == serverRejected
});

test('ValidationError from 400 is not treated as offline', () async {
  // ا�� preventing انعكاس الخلل
});
```

> **هذا الاختبار المكمّل هو الأهم** — يحمي من «إصلاح» يحوّل الأخطاء الحقيقية إلى رفض.

---

### T-0.1b · رسالة السطر 417 — **لا يحتاج اختبار**

لا تغيير سلوك ⇒ لا اختبار. **يُتحقق بمراجعة سجل `AppLogger` فقط.**

---

### T-0.3 · تطابق شكل استجابة DVIR — **الأولوية 2**

```dart
// test/backend/adapters/mock/sub/mock_dvir_backend_test.dart  (ملف قائم — يُضاف إليه)
```

| السيناريو | يfail قبل؟ |
|---|---|
| `MockDvirBackend.list()` يرجع مفتاح `data` | ✅ |
| `DvirRepositoryImpl.getDvirReports` مع موك ⇒ `Right([])` بلا NullCast | ✅ |
| الإنتاج (`EldDvirBackend`) لم يتغيّر | — |

```dart
test('mock list response shape matches production contract', () async {
  final r = await const MockDvirBackend().list();
  expect(r.data, containsPair('data', isA<List>()));
  expect(r.data, isNot(contains('reports')));
});
```

**اختبار تكامل (اختياري):** `DvirRepositoryImpl` + `MockDvirBackend` ⇒ لا استثناء، `Right([])`.

---

### T-0.4 · استعادة هوية `Failure` — **الأولوية 2**

```dart
// test/features/account/presentation/rules_screen_error_test.dart   (جديد)
```

| السيناريو | يfail قبل؟ |
|---|---|
| فشل شبكة ⇒ `loc.errNoInternet` | ✅ (قبل: `errRequestFailedNetwork`) |
| فشل خادم ⇒ `loc.errRequestFailed` أو نص آمن | ✅ |
| غير مُصنَّف ⇒ رسالة عامة **لا** «شبكة» | ✅ |

```dart
testWidgets('server failure is not shown as a network error', (t) async {
  // override rulesScreenBackendProvider ليعيد Left(ServerFailure(...))
  // النصوص المعروضة لا تحتوي على errRequestFailedNetwork
});
```

**اختبار وحدة مستقل (أسرع):**

```dart
test('anyErrorUserMessage distinguishes Failure from raw Exception', () {
  expect(anyErrorUserMessage(ServerFailure(message: 'x'), loc: loc),
         loc.errRequestFailed);
  expect(anyErrorUserMessage(Exception('x'), loc: loc),
         loc.errRequestFailedNetwork);   // سلوك_EXCEPTIONS يبقى كما هو عمداً
});
```

---

### T-0.5 · نقل حراسة التجاوز — **الأولوية 3**

```dart
// test/features/home/presentation/pages/home_page_bypass_test.dart   (جديد)
```

| السيناريو | الهدف |
|---|---|
| في `kDebugMode=false`،_setting_ `developerBypass=true` ⇒ القفل يبقى | **لا يمكن محاكاة `kDebugMode=false` في `flutter test`** (يكون `true` دائماً) |

> ⚠️ **قيد الاختبار الآلي**: `kDebugMode` ثابت `true` في بيئة الاختبار. لذلك:
> - **الاختبار الآلي القابل للكتابة**: في debug، `bypass=true` ⇒ القفل يختفي (يتحقق أن السلوك محفوظ).
> - **الاختبار اليدوي الإلزامي**: بناء release والتأكد أن double-tap لا يُزيل القفل.

---

### T-0.6 · توحيد `TrackingService` — **الأولوية 2**

```dart
// test/features/tracking/data/providers/tracking_provider_unification_test.dart  (جديد)
```

| السيناريو | يfail قبل؟ |
|---|---|
| `app_initializer` override يصل إلى `trackingRepositoryProvider` | ✅ |
| `quick_actions_initializer` و`trackingRepositoryProvider` يستخدمان نفس الـ instance | ✅ |
| `trackingServiceFullProvider` لم يعد موجوداً | ✅ (ترميز build-time) |

```dart
test('trackingServiceProvider is the single source', () {
  final c = ProviderContainer();
  final a = c.read(trackingServiceProvider);
  final b = c.read(trackingServiceProvider);
  expect(identical(a, b), isTrue);
});
```

---

### T-0.7 · `.env` — **لا اختبار**

تغيير `.gitignore` لا يمس وقت التشغيل. **تحقق يدوي**: `git check-ignore -v .env.local` ⇒ يجب أن يُرجع match.

---

### T-0.8 · استثناء `/session` — **الأولوية 3**

```dart
// test/backend/http/interceptors/auth_interceptor_test.dart  (قائم — يُضاف إليه)
```

| السيناريو | يfail قبل؟ |
|---|---|
| `POST https://host/api/session` يتجاوز إرفاق الجلسة | ❌ **لا يفشل** — السلوك متطابق لأن `session == null` أصلاً |
| `POST https://host/eld/sessions/123/members` **لا** يُخطئMatched | ❌ لا — لأن `endsWith('/session')` لا يطابق |

> ⚠️ **التحدي**: الإصلاح هنا **تحسين وضوح** لا إصلاح خلل. الاختبار **لا يمكن أن يفشل قبل الإصلاح** لأن السلوك متطابق.

**البديل**: اختبار **حارس ضد الانحدار المستقبلي**:
```dart
test('session-creating path is exempted from cookie attachment', () {
  //Arrange: session موجود مسبقاً + طلب إلى /api/session
  // قبل الإصلاح: يُرفق الكوكي (خطأ صامت)
  // بعد الإصلاح: لا يُرفق
});
```
⚠️ **هذا يغيّر السلوك!** قد يكون الإصلاح في 0.8 **تغييراً وظيفياً** لا إصلاح ميت. **يلزم تأكيد من المالك.**

---

### T-0.9 · `HttpClient` — **محجوب**

لا يمكن كتابة اختبار meaningfully قبل معرفة الـ endpoint. الاختبارات الممكنة الآن:

```dart
test('push token upload closes its HttpClient', ...);       // غير قابل للـ mock بسهولة
test('push token upload respects a timeout', ...);
```

**تقييم**: بنية الاختبار رديئة (`HttpClient` خام غير قابل للـ mock بـ `http_mock_adapter`). **هذا في حد ذاته حجة إضافية للتحويل إلى `ApiClient`** — لكنه محجوب.

---

## 2. جدول التنفيذ

| الأولوية | الاختبار | ملف | يfail قبل؟ | يمر بعد؟ |
|---|---|---|---|---|
| **1** | T-0.1a (قائم) | `duty_status_tracker_test.dart:739` | ✅ مُثبت | ✅ |
| **1** | T-0.1a-2 (جديد) | `duty_status_tracker_error_classification_test.dart` | ✅ | ✅ |
| **1** | T-0.2a | `inspection_repository_isolation_test.dart` | ✅ | ✅ |
| **1** | T-0.2b | `codriver_repository_isolation_test.dart` | ✅ | ✅ |
| **2** | T-0.3 | `mock_dvir_backend_test.dart` | ✅ | ✅ |
| **2** | T-0.4 | `rules_screen_error_test.dart` | ✅ | ✅ |
| **2** | T-0.6 | `tracking_provider_unification_test.dart` | ✅ | ✅ |
| **3** | T-0.5 | `home_page_bypass_test.dart` | ❌ | ✅ |
| **3** | T-0.8 | `auth_interceptor_test.dart` | ❌* | ✅ |
| **—** | T-0.7 | يدوي فقط | — | — |
| **—** | T-0.9 | محجوب | — | — |

`*` يعتمد على قرار المالك بشأن تغيير سلوك 0.8.

---

## 3. أوامر التحقق

```bash
# بعد كل إصلاح — المدى المحدد
flutter test test/core/engine/tracking/ test/features/inspection/ \
            test/features/codriver/data/ --reporter=compact

# بعد كل إصلاح — خط الأساس الكامل (يجب أن يبقى 13)
flutter test test/features/session/ test/core/engine/tracking/duty_status_tracker_test.dart \
            test/features/codriver/ test/features/dvir/ \
            test/backend/http/interceptors/ test/features/account/ --reporter=compact

# فحص الساكن (مرشَّح على الملفات المعدَّلة)
flutter analyze lib/features/hos/domain/engine/tracking/duty_status_tracker.dart \
                lib/features/inspection/data/ lib/features/codriver/data/ \
                lib/backend/adapters/mock/sub/mock_dvir_backend.dart \
                lib/features/account/presentation/providers/rules_screen_provider.dart
```

> `flutter analyze` لن يلتقط أي انقلاب طبقي (لا توجد قاعدة `architecture` — `01_baseline.md` §1.4)، لكنه **سي** يلتقط أخطاء التصريف التي قد ينتجها الإصلاح.

---

## 4. فجوات التغطية التي لن تُغلق في Phase 0

| الفجوة | السبب | متى تُعالج |
|---|---|---|
| `openapi.yaml` لا يحتوي مسار توكن الإشعار | عقد مفقود | **مُعيق — قرار المالك** |
| 7 اختبارات `codriver_page_test.dart` فاشلة | خلل قائم | قبل أي توسّع في codriver |
| `info_packet_page_test.dart` (2 فاشلة) | خلل قائم | خارج Phase 0 |
| `dvir_form_defects_test.dart` + `dvir_list_page_test.dart` | خلل قائم | قبل 0.3IF couverture |
| لا اختبار لـ `push_notification_service` | بنية غير قابلة للاختبار | مع 0.9 |
| لا قاعدة lint معمارية | `analysis_options.yaml` | Phase 5 |

> **توصية صريحة**: قبل تنفيذ 0.2، يجب **تقرير** عن سبب فشل `codriver_page_test.dart` السبعة — لأنه في نفس الميزة. إصلاح العزل فوق واجهة مُكسورة اختبارياً ينتج مقارنة غير ذات معنى.