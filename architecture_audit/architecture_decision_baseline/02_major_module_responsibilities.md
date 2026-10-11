# 02 — مسؤوليات الوحدات الكبرى (Major Module Responsibilities)

> المقصود مقابل الفعلي، لكل وحدة: المكوّنات المكشوفة، الداخليات، الداخل/الخارج من الاعتماديات، التشغيل، الحقن، الحالة، الحدود، القوة، الخرق، الافتراضات. الأدلة من الشجرة الحالية.

## 1. `lib/app/` + `lib/main.dart` + `lib/app.dart` — الإقلاع والتنسيق العام

| البند | المحتوى |
|---|---|
| المقصود | إقلاع التطبيق وتهيئة الخدمات وحاوية الاعتماديات |
| الفعلي | ذلك + **تنسيق عابر للميزات**: `trackingOrchestratorProvider` (4 مستمعين: tracking/auth/vehicle/hos)، مستمعا `app.dart` (إبطال HOS عند الجلسة + سناك القيادة)، `QuickActionsInitializer` |
| مكشوف | `AppInitializer` (تهيئة + `createProviderContainer` مع 4 تجاوزات)، `trackingOrchestratorProvider`، `PushNotificationService` |
| داخلي | ترتيب التهيئة (env → firebase → hive → tracking → sync)، تأخير 500ms لإحماء المزامنة |
| وارد | لا شيء (الجذر) |
| صادر | `features/tracking` (مباشر: `TraccarNativeClientImpl`)، `features/sync`، `core/*`، `features/hos+auth+vehicle` (المنسق) |
| التشغيل | بناء `TrackingService` يدوياً + حقنه عبر `overrideWithValue` |
| الحقن | **جذر تركيب حقيقي** (`ProviderContainer` + overrides) — لكنه يُجاوَز `traccarNativeClientProvider` الواعي بالبيئة |
| الحالة | لا حالة (تنسيق عبر مستمعين فقط) |
| الحدود | **مخترَقة**: `app/` يستورد تنفيذ `features/tracking/data` مباشرة (`app_initializer.dart`) |
| قوة مؤكدة | ترتيب إقلاع موثق، فصل `initialize/postContainer`، معالجة آمنة لفشل Firebase |
| خرق مؤكد | V-BND-01: بناء `TraccarNativeClientImpl()` يدوياً (§11) |
| افتراض غير متحقق | أن تجاوز `trackingServiceProvider` يغطي المستودع (لا يغطيه — يغطي `quick_actions` فقط؛ المستودع يقرأ `trackingServiceFullProvider`) |

## 2. `lib/backend/` — التكامل الخلفي المركزي

| البند | المحتوى |
|---|---|
| المقصود | عقود + محوّلات (حقيقي/وهمي) + بنية HTTP + اختيار التنفيذ |
| الفعلي | ذلك فعلاً — **أوضح وحدة حدوداً في المشروع** |
| مكشوف | 15 عقداً (`contracts/`)، `BackendAdapter` (مجمّع 13 عقداً nullable)، `activeBackendProvider` + مزودات العقود، `apiClientProvider`، `traccarNativeClientProvider` |
| داخلي | `sub/*` (13+13)، mappers، DTOs، interceptors الثلاثة |
| وارد | كل `features/*/data` + `presentation` (14 حافة) + `core/di` |
| صادر | `core` (شبكة/تخزين/وقت/إعدادات) + `domain` (كيانات/قيم) + `features/{account,tracking,auth}` (9 حواف: 4 rules-screen + 2 auth + 3 traccar) |
| التشغيل | Dio واحد + 3 interceptors (مصادقة/تسجيل-debug/انحراف زمني)؛ `JSESSIONID` عبر كوكي |
| الحقن | `backend_providers` + `backend_network_providers` (اختيار mock/حقيقي من البيئة + URL المحفوظ) |
| الحالة | بلا حالة (مزودات عديمة الحالة؛ `StreamController` لحدث 401) |
| الحدود | **مخترَقة**: العقود تستورد DTO المحوّل (`daily_logs_backend:3-4`)؛ `RawJson` عملة سائلة (33 مستورداً)؛ `expectedOwnerDriverId?` في 4 عقود |
| قوة مؤكدة | محوّل `EldEngineAdapter` مجمّع نقي (تجميع فقط)؛ `mapDioException` نقطة ترجمة واحدة معلنة؛ اختيار mock/حقيقي مركزي |
| خرق مؤكد | V-BND-02 (عقد←DTO)، V-BND-03 (موك غير مكتمل 22/60) |
| افتراض غير متحقق | أن `driver` موجود في استجابات cycle/logs (العقد يوثّقه للسجلات دون `required`؛ للدورة لا يوثّقه أصلاً) |

## 3. `lib/core/` — البنية التحتية المشتركة (19 مجلداً فرعياً)

| المجلد | الدور الفعلي | الحكم |
|---|---|---|
| `network` | Dio + interceptors wiring + `guardedNetwork` + `NetworkInfo` | بنية حقيقية؛ يعيد تصدير مزودات `backend` (دورة C2) |
| `error` + `result` | نظاما خطأ متوازيان (`AppError`/`Result` مقابل `Failure`/`Either`) + بوابة عرض | ازدواج مؤكد؛ البوابة سليمة التصميم |
| `config` | بيئة + HOS + عناوين + مخزن إعدادات | بنية؛ تطبيع URL مكرر مع 3 مواضع |
| `di` | تركيب auth فقط (25 سطراً) رغم الادعاء الشامل | جذر ناقص |
| `domain/entities` | `user` + `hos_models` + `location_point` (جذر موازٍ لـ `lib/domain`) | ازدواج موضعي |
| `services` | تخزين (3) + بلوتوث + UTC + قاعدة محلية | بنية؛ دورة C4 بين خدمتي تخزين |
| `session` | `SessionEpoch` (31 سطراً، موثّق) | بنية سليمة |
| `storage` | منفذ/محول SecureStorage + مزودان مكررا الاسم | بنية + تكرار |
| `time` | سلطتان متوازيتان + الافتراضي ساعة الجهاز | ازدواج + خطر مُوثّق سابقاً |
| `theme`/`widgets`/`localization`/`extensions` | نظام تصميم + ودجات مشتركة | بنية عرض سليمة غالباً |
| `providers` | `driverRulesProvider` (يراقب presentation) | **خرق**: V-BND-04 |
| `events` | بث أحداث ELD من مصدر tracking ملموس | **خرق**: V-BND-05 |
| `utils`/`constants`/`data` | مساعدات + ثوابت + `user_model` | بنية؛ مفاتيح تخزين ×4 أماكن |

## 4. `lib/domain/` + `lib/core/domain/` — النطاق المشترك

| البند | المحتوى |
|---|---|
| المقصود | كيانات الأعمال المشتركة (غير واضح التوزيع بين الجذرين) |
| الفعلي | `lib/domain/`: account/config/duty_status/hardware/inspection/shared/signature (كيانات freezed + `value_objects` + `DutyStatusCode`)؛ `core/domain/entities`: user/hos_models/location_point |
| وارد | `backend` (45+19 حافة) + كل الميزات |
| صادر | `core` (utils/logger) + Flutter (`duty_status_code:7`) |
| الحدود | **مخترَقة جزئياً**: `duty_status_code.dart` يستورد `flutter/widgets` + logger ويحمل ألواناً (V-BND-06)؛ جذر موازٍ غير مبرر |
| قوة مؤكدة | `value_objects` (أنواع مميزة تمنع خلط المعرفات)؛ كيانات freezed مُنمَّطة |
| افتراض غير متحقق | معيار توزيع الكيانات بين الجذرين (لا توثيق) |

## 5. `lib/features/` — 16 ميزة بثلاثة أشكال

| الشكل | الميزات | الملاحظة |
|---|---|---|
| ثلاثي الطبقات | auth, codriver, dvir, hos, inspection, logs, sync, tracking, vehicle (9) | متفاوتة العمق: hos/domain محرك حقيقي؛ vehicle/domain تحليل فقط |
| عرض + application | account | `application/` الوحيدة في المشروع (نموذج + use-case بمزوده) |
| عرض فقط | home, about, onboarding, permissions, settings (5) | **مشروع**: لا طبقات فارغة مُختلقة |
| نطاق + عرض بلا data | connection | تستهلك `backend/*` مباشرة من العرض |

## 6. `lib/routes/` + `routes.dart` — التوجيه

| البند | المحتوى |
|---|---|
| الفعلي | ثوابت 30 مساراً + `publicRoutes` + `RouterNotifier` (يستمع auth) + `redirect` (حراسة دخول) + 5 ملفات تسجيل + `rootNavigatorKey` عام |
| وارد | 7 صفحات/ودجات (للملاحة والمفتاح) |
| صادر | الصفحات (للتسجيل) + `auth_state_provider` |
| الحدود | **مخترَقة هيكلياً**: دورة 25 ملفاً (C1) — التسجيل يتطلب الصفحات والعكس |
| قوة مؤكدة | حراسة الدخول مركزية؛ `RouterNotifier` الجسر القياسي؛ `publicRoutes` معلنة |
| افتراض غير متحقق | كلفة كسر الدورة الفعلية (تقديرية) |
