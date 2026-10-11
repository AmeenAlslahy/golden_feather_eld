# 09 — ملكية المسؤوليات المشتركة (Shared Responsibilities)

> لكل مسؤولية: المالك الحالي، المشاركون، الازدواج، التعارض، الحدود المفقودة، النتائج المرتبطة، الدليل. **لا إسناد مالك جديد** — تشخيص فقط.

## 1. جلسة المصادقة (Authentication session)

- **المالك:** `AuthNotifier` (`auth_state_provider.dart:135-324`) — epoch + انتقال + سلسلة تخزين.
- **المشاركون:** `AuthInterceptor` (كوكي + سياج مالك)، `app.dart` (إبطال)، `SessionEpoch` (العدّاد).
- **الازدواج:** لا — متسق.
- **التعارض:** لا.
- **المفقود:** لا شيء جوهري.
- **المرتبط:** RC-D (الشكل المبعثر للسياجات الأخرى، لا الجلسة نفسها).

## 2. هوية السائق (Driver identity)

- **المالك:** `authStateProvider.user.id` (نصي) + `currentDriverIdProvider` (تحويل عددي).
- **المشاركون:** كل مزود يقرأ الهوية؛ `int.tryParse` مبعثر (orchestrator، account، codriver).
- **الازدواج:** تحويل النص→رقم مكرر؛ `DriverId` المميزة تحدّ منه في العقود.
- **التعارض:** `fallbackDriverId` النصي في FMCSA مقابل `DriverId` المُنمَّط.
- **المفقود:** مصدر هوية رقمي واحد.

## 3. قواعد السائق (Driver rules)

- **المالك (مدّعى):** `driverRulesProvider` في `core/providers`.
- **المشاركون:** `rulesScreenProvider` (account/presentation) كمصدر؛ `change_status_provider` كمستهلك.
- **الازدواج:** لا.
- **التعارض:** المالك في `core` يراقب `presentation` — **حدود معكوسة** (V-BND-04).
- **المفقود:** موطن متفق عليه (account/domain مرشح طبيعي).

## 4. اختيار المركبة (Vehicle selection)

- **المالك:** `vehicleProvider` (الميزة).
- **المشاركون:** `dashboard_provider` (ينسخ الاختيار)، `dvir`/`connection` (يقرآن)، `hardware_status` (يقرأ uniqueId).
- **الازدواج:** قاعدة الاختيار مكررة 3× (نطاق معطّل + data + presentation — DST-045/047 سابقاً).
- **التعارض:** `select_vehicle_page:86` **يكتب** في dashboard مباشرة.
- **المفقود:** عقد قراءة/كتابة واحد.

## 5. حالة HOS (HOS state)

- **المالك:** `HosRulesEngine` (القواعد) + `DutyStatusTracker` (التتبع) + `HosNotifier` (التنسيق).
- **المشاركون:** `status_dashboard`/`recap`/`change_status` providers، `app.dart` (إبطال)، `trackingOrchestrator` (قراءة القيادة).
- **الازدواج:** فحص الحركة مرتين؛ خرائط التحويل ×3.
- **التعارض:** `_applyManualLocal` تُستدعى تلقائياً ويدوياً بلا تمييز (سبب بطلان توصية الـ return).
- **المفقود:** لا شيء بنيوي — التقسيم engine/tracker/notifier سليم المبدأ.

## 6. بيانات التفتيش (Inspection data)

- **المالك (بعد EC-0.2a):** `InspectionRepositoryImpl` — ملكية مُتحقَّقة + epoch.
- **المشاركون:** `inspection_provider`، `dot_inspection_providers`، `send_logs_page`.
- **الازدواج:** لا.
- **التعارض:** لا (بعد الإصلاح).
- **المفقود:** ترجمة 4 مفاتيح خطأ جديدة (تظهر خاماً).

## 7. المزامنة دون اتصال (Offline sync)

- **المالك:** **متنازع**: `SyncEngine`+`OfflineQueue` (أحداث قانونية) مقابل `SyncRepositoryImpl`+`SyncNotifier` (طابور واجهة).
- **المشاركون:** كل المستودعات تستورد `pending_event`/`offline_queue`.
- **الازدواج:** نظاما طابور كاملان — **مؤكد وحيّان**.
- **التعارض:** لا فصل موثّق بين "طابور الواجهة" و"الأحداث القانونية".
- **المفقود:** تعريف حدود النظامين.

## 8. خدمات التتبع (Tracking services)

- **المالك (مدّعى):** `trackingServiceProvider` (مُجاوَز) و`trackingServiceFullProvider` (مُستهلك).
- **المشاركون:** orchestrator، quick_actions، repository، initializer.
- **الازدواج:** **مثالان حيان** — V-BND الأشد تداخلاً.
- **التعارض:** أي مثال هو "الخدمة"؟ لا جواب.
- **المفقود:** مصدر وحيد + احترام `traccarNativeClientProvider`.

## 9. الملاحة (Navigation)

- **المالك:** `routerProvider` + `RouterNotifier` + `AppRoutes`.
- **المشاركون:** 9 ملفات تستدعي `AppRoutes.*`؛ `home_provider` يبني 10 وجهات.
- **الازدواج:** `Navigator.push` الالتفافي (ROU-001 سابقاً) بجانب go_router.
- **التعارض:** الصفحات تعرف `routes.dart` والعكس (C1).
- **المفقود:** طبقة ملاحة مجردة.

## 10. تصنيف الأخطاء (Error classification)

- **المالك:** `mapDioException` (نقطة واحدة معلنة) + `anyErrorUserMessage` (بوابة العرض).
- **المشاركون:** `duty_status_tracker` (تخمينه الخاص)، 17 موقع عرض خام، `rules_screen_provider` (رمي `Exception`).
- **الازدواج:** نظاما خطأ (`AppError`/`Failure`).
- **التعارض:** التخمين المحلي يتجاوز المترجم المركزي.
- **المفقود:** عقد تصنيف واحد يُحترم (الاختبار الفاشل يثبت الكلفة).

## 11. تعيين استجابات الخلفية (Backend mapping)

- **المالك:** مخططات `eld_engine` (عالية الجودة).
- **المشاركون:** `parse*` في النطاق (4 ملفات)، تحليل presentation، `_asMap` ×5.
- **الازدواج:** نفس الحمولة تُحلَّل في 3 طبقات.
- **التعارض:** `fallback: 0` يمحو "مفقود" (قرار مخطط بعواقب ملكية).
- **المفقود:** مخطط الاستجابة كمفهوم مُلزِم.

## 12. الإعدادات المشتركة (Shared configuration)

- **المالك:** `AppEnvironmentConfig` + `server_config_store` + `local_storage`.
- **المشاركون:** `apiConfigProvider`، `serverUrlProvider`، `backendTypeProvider`.
- **الازدواج:** تطبيع URL في 4 مواضع (طبقات مختلفة — ملاحظة لا خرق).
- **التعارض:** لا.
- **المفقود:** لا شيء حرج.
