# 04 — تحليل الأثر (Impact Analysis)

> لكل بند: السبب الجذري ← الملفات المباشرة/غير المباشرة ← المزوّدات ← المستودعات ← الـ data sources ← العقود ← الـ endpoints ← النماذج ← الاختبارات ← كسر محتمل.

---

## 0.1 (أ) —RC-1 · تصنيف خطأ تغيير حالة الخدمة

| # | البند |
|---|---|
| **السبب الجذري** | `error.context?['statusCode'] == null` يُعامل كدليل على «خطأ شبكة»، بينما `AppError` مختوم و`statusCode` مسمّى متاح على `ServerError` فقط |

| البُعد | المحتوى |
|---|---|
| **الملفات المباشرة** | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` (السطر 370-374) — **معدَّل بالفعل في شجرة العمل** |
| **الملفات غير المباشرة** | `hos_provider.dart`، `change_status_provider.dart`، `change_status_page.dart`، `sync_engine.dart` (يُستدعى بـ `enqueue: true`) |
| **المزوّدات** | `hosEngineProvider`، `hosProvider`، `syncEngineProvider` |
| **المستودعات** | `hos/domain/repositories/status_dashboard_repository.dart` → `StatusDashboardBackend` |
| **الـ data sources** | `_dashboardBackend.updateDutyStatus` |
| **العقود** | `backend/contracts/status_dashboard_backend.dart` |
| **الـ endpoints** | `POST /eld/status/duty-status` |
| **النماذج** | `ManualDutyChangeResult`، `DutyStampRefusal`، `PendingEvent(type: 'duty_status')` |
| **الاختبارات الحالية** | `test/core/engine/tracking/duty_status_tracker_test.dart` — **756 سطراً، 1 اختبار فاشل (Baseline #1)** |
| **الاختبارات الناقصة** | لا يوجد اختبار لـ: خطأ `ValidationError` (400) يجب ألا يُعامل كـ offline · خطأ `ServerError` بـ `statusCode` مسمّى بلا `context` |
| **كسر محتمل** | إذا أُضيف `hasHttpStatus` بشكل خاطئ، قد يُعامَل خطأ شبكة حقيقي كخطأ خادم ⇒ **فقد الطابور offline** — أي أن خللاً في اتجاه المعالجة يؤتي另一种 |

### 🔄 أثر عكسي يجب الانتباه له

الإصلاح يجعل رفض الخادم **لا يُطبَّق محلياً** — أي أن `submitManualChange` سيُعيد `serverRejected` بدل تطبيق الانتقال. هذا **هو السلوك الصحيح** لكنه **تغيير سلوك ملموس**:

| السيناريو | قبل | بعد |
|---|---|---|
| خادم يرفض 409 Conflict، بلا `context` | انتقال مُطبَّق + حدث في الطابور | **رفض، لا انتقال** |
| خادم يرفض 409 مع `context` | رفض (سليم) | رفض (بلا تغيير) |
| انقطاع شبكة حقيقي | طابور offline | طابور offline (بلا تغيير) |

**الملفات التي ستتأثر سلوكياً:** `change_status_page.dart` (رسالة الخطأ تتغيّر من نجاح كاذب إلى رفض حقيقي).

---

## 0.1 (ب) — RC-2 · رسالة مضلّلة

| # | البند |
|---|---|
| **السبب الجذري** | الحارس لم يُحذف عند نقل السياسة إلى `validateManualTransition` |
| **الملفات** | `duty_status_tracker.dart:417-420` فقط |
| **الأثر السلوكي** | **صفر** — `AppLogger.warning` لا حالة |
| **الأثر التشخيصي** | رسالة تقول `while moving` لكن الشرط لا يفحص الحركة ⇒ **خداع أثناء التشخيص** |
| **الاختبارات** | لا حاجة — لا تغيير سلوك |
| **كسر محتمل** | لا شيء. **الإصلاح الأدنى هنا صفر مخاطر** |

---

## 0.2 — RC-3 · الكاش العابر للحدود

| # | البند |
|---|---|
| **السبب الجذري** | ثلاث طبقات: `static` + مفتاح بلا `driverId` + لا إبطال |

### تفصيل الأثر لكل مستودع

#### أ) `InspectionRepositoryImpl`

| البُعد | المحتوى |
|---|---|
| **الملفات المباشرة** | `lib/features/inspection/data/repositories/inspection_repository_impl.dart` (29-32، 63، 78، 86، 92، 146-148، 191، 199-200، 206، 218، 223) |
| **الملفات غير المباشرة** | `inspection_repository_providers.dart` (مزوّد DI) · `inspection_provider.dart` · `dot_inspection_page.dart` · `send_logs_page.dart` · `inspection_duty_graph.dart` |
| **المزوّدات** | `inspectionRepositoryProvider` — **`Provider` دائم، غير `autoDispose`** |
| **الـ data sources** | `InspectionBackend` (`eld_inspection_backend.dart` / `mock_inspection_backend.dart`) |
| **العقود** | `backend/contracts/inspection_backend.dart` |
| **الـ endpoints** | `GET /eld/dot-inspection/cycle` · `GET /eld/dot-inspection/logs` · `POST /eld/dot-inspection/transfer` · `GET /eld/info-packet` |
| **النماذج** | `DotInspectionScreen`، `DotInspectionCycleDay`، `DotInspectionLog`، `InformationPacketView` |
| **الأبعاد المتسربة** | `_cachedScreen`، `_cachedCycle`، `_cachedLogs`، `_cachedPacket` — **أربعة أبعاد، كلٌّ فاقد `driverId`** |

**مسارات الاستهلاك — كلها بلا حارس هوية:**

| السطر | الاستهلاك |
|---|---|
| 59-60 | `getCycle` fallback عند خطأ |
| 82-84، 91-92 | `getLogs` fallback عند خطأ + offline |
| **146-148** | **توليد ملف FMCSA** من 3 كاشات |
| 187، 199-200، 206 | `getPacket` fallback |
| 216، 223 | `getScreen` fallback |

#### ب) `CoDriverRepositoryImpl`

| البُعد | المحتوى |
|---|---|
| **الملفات المباشرة** | `lib/features/codriver/data/repositories/codriver_repository_impl.dart` (17-18، 32، 46، 51، 55-57، 84، 119-122، 135-138) |
| **المزوّد** | `coDriverRepositoryProvider` — دائم |
| **الاختبارات** | `codriver_repository_impl_test.dart` موجود — **لا يغطي العزل بين سائقين** |
| **الاختبارات الناقصة** | اختبار «السائق B لا يرى كاش السائق A» — **غير موجود** |

> ⚠️ **تعارض تشغيلي**: `codriver_page_test.dart` فيه **7 اختبارات فاشلة أصلاً** (Baseline #2-#9). أي إصلاح هنا يُقاس على قاعدة متكسورة.

### 🇹 catastrophe vector (ناقل الكارثة)

```dart
// inspection_repository_impl.dart:145-151
final filePath = await Fmcsa_eld_output_generator.generateAndSave(
  screen: _cachedScreen,        // سائق A
  cycleDays: _cachedCycle,      // سائق A
  logs: _cachedLogs,            // سائق A
  fallbackDriverId: driverId.value.toString(),   // السائق B الحالي
);
```

ملف FMCSA 395.24 يحمل هوية B ومحتوى A. **هذا هو(vector) الأعلى خطورة في Phase 0 كله.**

| البُعد | المحتوى |
|---|---|
| **مخاطر إفساد البيانات** | **قصوى** — سجل نظامي مزيّف |
| **تعرّض بيانات بين مستخدمين** | **مؤكد** — سجلات DOT وoffline packet |
| **أثر المصادقة** | لا |
| **توافق الخادم** | لا يمس |
| **اتساق الحالة** | ينكسر عند التبديل بين سائقين |
| **احتمال الانحدار** | متوسط — يحتاج اختبار عزل |
| **تعقيد التراجع** | منخفض — حقل بدل `static` |

---

## 0.3 — RC-4 · تباين شكل DVIR

| # | البند |
|---|---|
| **السبب الجذري** | لا نوع استجابة يفرض الشكل؛ التطبيع موزّع على 3 مواضع |
| **الملفات المباشرة** | `lib/backend/adapters/mock/sub/mock_dvir_backend.dart` (السطر 20) |
| **ملفات للتحقق** | `dvir_repository_impl.dart:54, 80` · `eld_dvir_backend.dart:34` |
| **المستودع** | `DvirRepositoryImpl` |
| **العقد** | `backend/contracts/dvir_backend.dart` → `list()` تُرجع `Result<RawJson>` |
| **الـ endpoints** | `GET /eld/dvir` |
| **الاختبارات** | `mock_dvir_backend_test.dart`، `dvir_list_page_test.dart` (**فاشل — Baseline #11**)، `dvir_form_defects_test.dart` (**فاشل — Baseline #10**) |
| **الأثر** | بيئة mock/اختبار فقط — **لا مسار إنتاج** |
| **كسر محتمل** | منخفض جداً — الإصلاح يطابق الموك للإنتاج |

---

## 0.4 — RC-5 · فقدان هوية `Failure`

| # | البند |
|---|---|
| **السبب الجذري** | تحويل `Failure` ← `String` ← `Exception` في `rules_screen_provider.dart:22` |
| **الملفات المباشرة** | `lib/features/account/presentation/providers/rules_screen_provider.dart` |
| **الملفات غير المباشرة** | `rules_page.dart:229-232` (العرض) · `core/error/user_facing_message.dart` (المصنّف) |
| **المزوّد** | `rulesScreenProvider` — **`FutureProvider.autoDispose`** |
| **المستودع** | عبر `rulesScreenBackendProvider` |
| **العقد** | `backend/contracts/rules_screen_backend.dart` |
| **الـ endpoints** | `GET /eld/rules-screen` (غير مؤكد — لم يُتحقق) |
| **النماذج** | `RulesScreenModel`، `ServerFailure` |
| **الاختبارات** | `rules_page_test.dart` موجود |
| **الأثر** | كل خطأRules يُعرض «تعذّر الاتصال بالشبكة» — **misleading تشخيصي للمستخدم والفريق** |
| **كسر محتمل** | **منخفض** — `anyErrorUserMessage` لديه فرع `Failure` بالفعل |

---

## 0.5 — RC-9 · حراسة التجاوز

| # | البند |
|---|---|
| **السبب الجذري** | `kDebugMode` في الـ writer، لا في القارئ |
| **الملفات المباشرة** | `home_page.dart:212` (القارئ) |
| **ملف للتحقق** | `driving_lock_screen.dart:29` (الـ writer الوحيد) |
| **المزوّد** | `developerBypassDrivingScreenProvider` — **`StateProvider` دائم** |
| **الاختبارات** | `home_page_test.dart` |
| **الأثر الحقيقي** | **صفر في الإنتاج** — مقيّد بـ `kDebugMode` |
| **الخطر الكامن** | الدائم + الاعتماد على نزاهة كل writer مستقبلي |
| **كسر محتمل** | **صفر** — نقل الشرط لا يغيّر السلوك |

---

## 0.6 — RC-7 · `TrackingService` المزدوج

| # | البند |
|---|---|
| **السبب الجذري** | تصنيف-حسب-المجلد أنشأ صنفين بنسخة واحدة |
| **الملفات المباشرة** | `tracking_providers.dart:22-26` (المكرر) · `tracking_service.dart:200-204` (المصدر) |
| **الملفات غير المباشرة** | `app_initializer.dart:91` · `quick_actions_initializer.dart:29` · `tracking_repository_providers` |
| **المزوّدات** | `trackingServiceProvider`، `trackingServiceFullProvider`، `trackingRepositoryProvider` |
| **الـ data sources** | `traccarNativeClientProvider`، `nativeEventChannelClientProvider` |
| **الاختبارات** | `tracking_orchestrator_test.dart`، `tracking_provider_test.dart` |
| **الأثر** | حالتان مستقلتان في `TrackingService` (`_isInitialized`, `_locationSubscription`) |
| **كسر محتمل** | متوسط — لمسة DI في `app_initializer` |

> ⚠️ **`app_initializer.dart` ليس معدَّلاً** في شجرة العمل ⇒ التغيير آمن من ناحية التعارض.

---

## 0.7 — RC-10 · `.env` متتبَّع

| # | البند |
|---|---|
| **السبب الجذري** | ملف environment متتبَّع يقرأ منه التطبيق `TRACCAR_PASSWORD` |
| **الملفات** | `.env` (مُتتبَّع) · `.gitignore:49-52` · `app_environment.dart:86` |
| **الأثر الحالي** | **صفر** — لا أسرار في الملف |
| **الأثر المستقبلي** | أي مطوّر يضيف `TRACCAR_PASSWORD` محلياً ⇒ يُودَع |
| **الاختبارات** | لا ينطبق |
| **كسر محتمل** | **لا شيء** — تغيير `.gitignore` لا يمس وقت التشغيل |

> ⚠️ **لا تدوير مطلوب**: لا يوجد credential مُتسرّب ليتدوّر.

---

## 0.8 — RC-6 · استثناء `/session` الميت

| # | البند |
|---|---|
| **السبب الجذري** | `options.path` ≠ `options.uri.path` عند تمرير URL مطلق |
| **الملفات** | `auth_interceptor.dart:64` — **معدَّل بالفعل** في شجرة العمل |
| **الاختبارات** | `auth_interceptor_test.dart`، `auth_interceptor_epoch_test.dart` |
| **الأثر** | **صفر وظيفي** — الشيفرة ميتة |
| **كسر محتمل** | منخفض — لكن `endsWith` قد يطابق مسارات غير مقصودة (يلزم فحص `EldEndpoints`) |

---

## 0.9 — RC-8 · `HttpClient` خام

| # | البند |
|---|---|
| **السبب الجذري** | طبقة شبكة ثانية خارج `ApiClient`، بلا عقد |
| **الملفات** | `push_notification_service.dart:135-145` |
| **الأثر** | تسريب `HttpClient` + لا مهلة + بلا مصادقة + بلا endpoint |
| **مُعيق** | 🔴 **المسار الصحيح غير معروف** (0 نتيجة في `lib/` و`openapi.yaml`) |
| **كسر محتمل** | **غير محدد** — لا يمكن تقديره قبل معرفة العقد |

---

## مصفوفة الاعتماد بين البنود

```
        0.1a  0.1b  0.2   0.3  0.4   0.5  0.6   0.7  0.8  0.9
0.1a     —     ·    ·     ·    ·     ·    ·     ·    ·    ·
0.1b     ·     —    ·     ·    ·     ·    ·     ·    ·    ·
0.2      ·     ·    —     ·    ·     ·    ·     ·    ·    ·
0.3      ·     ·    ·     —    ·     ·    ·     ·    ·    ·
0.4      ·     ·    ·     ·    —     ·    ·     ·    ·    ·
0.5      ·     ·    ·     ·    ·     —    ·     ·    ·    ·
0.6      ·     ·    ·     ·    ·     ·    —     ·    ·    ·
0.7      ·     ·    ·     ·    ·     ·    ·     —    ·    ·
0.8      ·     ·    ·     ·    ·     ·    ·     ·    —    ·
0.9      ·     ·    ·     ·    ·     ·    ·     ·    ·    —
```

✅ **لا يوجد أي تب屿 تنفيذ بين البنود التسعة.** الاستقلال كامل — وهذا يسمح بتنفيذ متوازٍ أو بترتيب مرن. التفاصيل في `06_execution_order.md`.

### تداخل **ملفّي** وحيد (ليس منطقياً)

| الملف | بنود متداخلة |
|---|---|
| `duty_status_tracker.dart` | 0.1a + 0.1b — **معدَّل مسبقاً** ⇒ نفّذهما معاً في تمريرة واحدة |
| `codriver_repository_impl.dart` + `inspection_repository_impl.dart` | 0.2 (موحّد) |

---

## ملخص toughest: البنود التي لا يجب تنفيذها قبل اختبار

| البند | لماذا |
|---|---|
| **0.2** | تغيير سلوك عزل الجلسات — أعلى خطر بيانات |
| **0.1a** | يغيّر مسار offline/رفض ⇒ يؤثر على الطابور القانوني |
| 0.6 | يمس DI في `app_initializer` |
| 0.4 | يمس طبقة تصيير الأخطاء المشتركة |
| 0.9 | محجوب — لا يمكن تقييمه |

**آمنة للتنفيذ فوراً:** 0.1b · 0.3 · 0.5 · 0.7 · 0.8