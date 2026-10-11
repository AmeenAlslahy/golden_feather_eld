# 06 — الأسباب الجذرية النظامية (Systemic Root Causes)

> ليست قائمة مخالفات. كل سبب أدناه **يولّد** مجموعة أعراض. الثقة: CONFIRMED تعني مثبتاً بشيفرة حالية + اختبار/عدّ؛ POTENTIAL تعني مرجّحاً بأدلة غير حاسمة.

## RC-A — لا جذر تركيب واحد (تشتت DI)

**الوصف:** التركيب موزّع على 4 مستويات (`core/di` لمستودع واحد، `backend/providers`، `features/*/data/providers`، مزودات محلية بجانب الأصناف). لا توجد قاعدة "أين يُعرَّف المزود".

**الأدلة:**
- `core/di/app_providers.dart` (25 سطراً) يدّعي "Composition Root for all Domain Repositories" ويُركّب **واحداً فقط** (`traccarAuthRepositoryProvider`).
- `trackingServiceProvider` معرَّف في `tracking_service.dart:200` و`trackingServiceFullProvider` في `tracking_providers.dart:22` — جسدان متطابقان، ومستهلكان مختلفان، وoverride لا يسري إلا على أحدهما (`app_initializer.dart:91` مقابل `tracking_providers.dart:41`).
- `updateRulesUseCaseProvider` معرَّف داخل `account/application/usecases/update_rules_use_case.dart:52-61`.
- `backend/providers` تُعرّف اختيار المحوّل + كل العقود + شبكة Traccar (99+70 سطراً).

**الأعراض المولّدة:** DST-037/CORE-005، ACC-001 (جزئياً)، حواف `presentation→data` العشرون (تبدو تجاوزاً وهي في الغالب استهلاك مزودات موضوعة في `data/`)، CORE-031.
**الملفات:** ~25 ملف مزودات. **الميزات:** الكل.
**الثقة: CONFIRMED.**

## RC-B — نماذج مشتركة بلا مالك متفق عليه

**الوصف:** كيانات تعبر الحدود (`RulesScreenModel`، `DriverRules`، `EldDrawer`، `rootNavigatorKey`، `connection_status`) لا يملكها أي طبقة، فيستوردها كل من يحتاجها من حيث وجدها.

**الأدلة:**
- `RulesScreenModel` في `account/application` ← يستورده `backend` (4 حواف: mapper + eld + mock + contract) — BACK-002.
- `driverRulesProvider` في `core` ← يراقب `account/presentation` — CORE-001.
- `EldDrawer` في `home` ← 5 صفحات من 4 ميزات — ACC-008.
- `rootNavigatorKey` في `routes.dart` ← 7 صفحات + `connection_status_indicator` — وقود C1.
- `connection_status` في `tracking/domain` ← `core/events` + `core/widgets` + `sync/providers` + `backend_network_providers`.

**الأعراض المولّدة:** 7 حواف core→features، 9 حواف backend→features، HOM-001، CUI-001، DST-030.
**الثقة: CONFIRMED.**

## RC-C — التوجيه بلا طبقة تجريد (المعرفة المتبادلة)

**الوصف:** الصفحات تعرف `routes.dart` (للملاحة والمفتاح العام)، وملفات `*_routes.dart` تعرف الصفحات (للتسجيل). لا وسيط.

**الأدلة:** الدورة الكبرى 25 ملفاً مُعادة الإنتاج بخوارزمية Tarjan على الشجرة الحالية؛ أصغر دورة دنيا: `routes.dart → home_routes.dart → home_page.dart → routes.dart`. وأضيقها: `home_page ↔ driving_lock_screen` استيراد متبادل مباشر.

**الأعراض المولّدة:** C1 كاملةً، HOM-003، ROU-001 (الالتفاف بـ Navigator)، استحالة اختبار التنقل معزولاً.
**الثقة: CONFIRMED.**

## RC-D — أمان الجلسات مُلصَق لاحقاً (retrofit) بلا تصميم موحد

**الوصف:** عزل الهوية طُبّق على دفعات (Stage 1، 2B-1، P0 leak fix) بثلاث آليات متوازية: `SessionEpoch` العام، سياج owner/epoch/seq **منسوخ** في 3 مزودات، ومعامل `expectedOwnerDriverId` في 4 عقود.

**الأدلة:**
- `account_provider:36-63` ≈ `codriver_provider:98-132` — نفس الآلية منسوخة حرفياً تقريباً.
- `codriver.switchDrivers` و`_refreshCurrent` **بلا سياج** (نفس الملف!) — الاتساق الداخلي ناقص.
- `dashboard/dvir/logs` بلا سياج أصلاً.
- `expectedOwnerDriverId?` اختياري في العقود — الالتزام طوعي.

**الأعراض المولّدة:** COD-001 (الكاش المتبقي)، DST-002 (قبل الإصلاح)، HL-31، BACK-031 (سياج جزئي)، avalanche التعديلات الـ 63 (معظمها سياجات).
**الثقة: CONFIRMED** (الآلية نفسها جيدة؛ المشكلة غياب التوحيد).

## RC-E — طبقة العرض هي طبقة التطبيق افتراضياً

**الوصف:** لا يوجد موضع متفق عليه لمنطق التنسيق/الأعمال، فيستقر تلقائياً في `presentation/providers` و`State` والواجهات: استدعاء backend مباشر، تحليل JSON خام (`team_status:26-32`، `hardware_status` mapping)، حل الهويات (`dvir_form:440-476`)، قواعد FMCSA (`change_status:278-295` مكررة مع المحرك)، بناء حمولات، كتابة حالة ميزة أخرى.

**الأدلة:** 14 حافة pres→backend (2 للتنفيذ)، 5 كتابات عابرة في `dashboardDataProvider`، `DvirState.previousToReview` (قاعدة §396.13 في كائن حالة)، `main_circular_timer:125-129` (`Duration(hours:11)` في `build`).

**الأعراض المولّدة:** عناقيد HL/DST/CON/AUTH-004/005، HL-24/HL-34 (خرائط الحالات في العرض).
**الثقة: CONFIRMED.**

## RC-F — شكل الـ wire موزّع بلا مالك

**الوصف:** `RawJson` عملة سائلة (34 مستورداً) + تحليل مبعثر (`_asMap` ×5 بسلوكين، `parse*` في النطاق، `json['data']` في presentation) + تطبيع مكرر (URL ×3). لا يوجد "مخطط الاستجابة" كمفهوم مطبّق.

**الأدلة:**
- `mock_dvir_backend:20` (`{'reports': []}`) مقابل `dvir_repository_impl:54` (`rawJson['data']`) — فشل صامت.
- `vehicle_selection.dart:52-153`: تحليل wire كامل في `domain` (بلا HTTP فعلي — تصحيح DST-044).
- `team_status_provider:26-32`: `json['data']` → `first['id']` في presentation.
- `log_repository_impl → certify_dto` و`dvir_repo → dvir_dto`: مستودعات تستورد DTO محوّل ملموس.

**الأعراض المولّدة:** BACK-008، BACK-006/007، COD-006/CON-005، HL-18، DST-012، BACK-015/026.
**الثقة: CONFIRMED.**

## RC-G — قناة الأخطاء نصية

**الوصف:** `Failure.message` / `e.toString()` / `l10nKey` تُخزَّن في الحالة (17 موقعاً) وتُعرض خاماً؛ و`anyErrorUserMessage` يهبط بكل `Exception` لرسالة شبكة.

**الأدلة:** `account_provider:90,95,119,130` + `account_page:98-102` (عرض خام)؛ `rules_screen_provider:22` (ACC-003)؛ الاختبار الفاشل `Expected: 'server_rejected', Actual: <null>` (أُعيد تشغيله: رفض الخادم يُصنَّف شبكياً في `duty_status_tracker:370-374`).

**الأعراض المولّدة:** ACC-003/004، HL-22/33، COD-003، RC-1 (الأخطر: انحراف سجل قانوني).
**الثقة: CONFIRMED.**

## RC-H — لا إنفاذ معماري (الانجراف غير المكلف)

**الوصف:** `analysis_options.yaml` بلا أي قاعدة بنيوية؛ 19 علامة `// ignore_architecture` في 13 ملفاً بلا آلية؛ تجريدات ميتة تتراكم (`BackendRegistry` + مزوده بلا مستهلك إنتاجي، `api_config.dart` المعلق، use-cases الشكلية).

**الأدلة:** العدّ المباشر (19 علامة)، `backendRegistryProvider` لا يستهلكه إلا اختبار، `get_status_dashboard_use_case.dart` (12 سطراً تمريراً صرفاً)، `LogoutUseCase` (9 أسطر تُسقط `Either` العائد).

**الأعراض المولّدة:** تراكم التجريدات الشكلية، وانعدام كلفة الانتهاك — كل RC أعلاه ينمو بحرية.
**الثقة: CONFIRMED.**

## خريطة الأعراض للجذور (ملخص)

| الجذر | عدد النتائج المرتبطة (تقريبي) |
|---|---|
| RC-A (تشتت DI) | ~25 |
| RC-B (نماذج بلا مالك) | ~20 |
| RC-C (التوجيه) | ~30 (الدورة الكبرى) |
| RC-D (سياج الجلسات) | ~15 + 63 ملف تعديل |
| RC-E (العرض=التطبيق) | ~60 |
| RC-F (شكل الـ wire) | ~25 |
| RC-G (قناة الأخطاء) | ~20 |
| RC-H (لا إنفاذ) | مُمكِّن الكل |
