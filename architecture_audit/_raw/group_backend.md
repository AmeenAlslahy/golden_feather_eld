# Group: backend — تدقيق الطبقات والمسؤوليات

**نطاق التدقيق:** `lib/backend/**` بالكامل (66 ملف Dart، تمت قراءتها كلها سطرًا بسطر).
**الحزمة المستخدمة:** Flutter / Dart، Riverpod، Dio، go_router، freezed.
**قاعدة القراءة فقط:** لم يُعدَّل أو يُنشأ أو يُحذف أي ملف تحت `lib/`. تم التحقق من الصحة المُجمِّعة عبر `flutter analyze lib/backend` (النتيجة: `No issues found! ran in 13.3s`).

---

## 0. خلاصة تنفيذية

طبقة `lib/backend/` **ليست** طبقة "port" حقيقية بمعنى Clean Architecture المعتاد. هي عمليًا **غلاف HTTP (HTTP wrapper)** وُضع فوق `lib/core/network/ApiClient`، وواجهاتها (`contracts/`) متسلسلة جزئيًا مع `lib/core/network`. الخلاصة:

1. **الحافة المعروفة `backend → features` موجودة فعلًا وهي ليست استيرادًا عارضًا واحدًا**، بل **6 استيرادات موزّعة على 5 ملفات**، كلٌّ منها موسوم بـ `// ignore_architecture` وهو **تعليق لا تفرضه أي قاعدة تحليل** (تحققت: `analysis_options.yaml` لا يحتوي أي lint معماري أصلًا، و`flutter analyze` يمرّ نظيفًا). ليست حادثة؛ إنها نمط.
2. **`lib/backend/contracts/*` لا تستورد أي نوع Dio إطلاقًا** — وهذا إنجاز حقيقي يستحق التسجيل. لكنها **تتسرّب بـ `RawJson` (أي `Map<String, dynamic>`) في 11 من 13 عقدًا**، وبـ **قيم wire خاصة بـ ELD** في `contract_enums.dart`، وبـ **مفاتيح كيانات خام** في `AuthBackend`.
3. **تسريب `RawJson` إلى domain وpresentation مؤكَّد**: ملف واحد في طبقة `domain` (`duty_status_tracker.dart`) يحتجز `StatusDashboardBackend`، وسبعة مواقع في `presentation` تستدعي العقود مباشرة وتُحلّل JSON خامًا بنفسها.
4. **عدم تماثل حقيقي وكبير بين `eld_engine` و`mock`**: 22 من 58 دالة عقد (≈38%) تُنفّذ `throw UnimplementedError` في الموك، مع **تباين سلوكي صامت** في `DvirBackend.list` (شكل JSON مختلف بين الموك والمحرك الحقيقي).
5. **`BackendRegistry` زخرفة**: 129 سطرًا، صفر مستهلك إنتاجي في `lib/` بالكامل، واستُبدل فعليًا بـ `BackendRegistry.single(...)` في provider واحد.
6. **تسريب نصّ عرضي داخل طبقة البنية التحتية**: `status_dashboard_mapper.dart` و`eld_status_dashboard_backend.dart` يحتويان نصوصًا إنجليزية موحَّدة داخل طبقة backend.

---

## A. نتائج لكل ملف

### `lib/backend/adapters/eld_engine/eld_engine_adapter.dart` (118 سطر، غير فارغ 97)
- **المسؤوليات الفعلية:** مجمّع (aggregator) صِرف لـ 13 عقدة فرعية عبر `late final`؛ يحمل `ApiClient`؛ يبني `BackendIdentity`؛ `dispose()` فارغ.
- **الطبقة المعلنة/الفعلية:** `adapters/eld_engine` → `adapters` (بنية تحتية). مطابق تمامًا.
- **الحالة المعمارية:** COMPLIANT
- **Issue IDs:** none

### `lib/backend/adapters/eld_engine/mappers/dot_inspection_mapper.dart` (151، 135)
- **المسؤوليات الفعلية:** تحليل 3 payloads (`screen`, `cycle`, `logs`) إلى `domain/inspection`؛ تحليل `events` المتداخلة؛ 25 حقلًا في `fromCycleDayJson` و28 حقلًا في `fromLogJson`.
- **الحالة:** COMPLIANT — ترجمة JSON→domain حقيقية وفعّالة، وهي سمة جيدة.
- **ملاحظة حجم:** الأسطر 141-151 فارغة تمامًا (قسم `// Primitives` لم يُحذف بعد نقله إلى `JsonPrimitives`). تجميلي، لا يُبلَّغ كـ issue معماري.
- **Issue IDs:** none

### `lib/backend/adapters/eld_engine/mappers/hardware_mapper.dart` (27، 23)
- **المسؤوليات الفعلية:** تحويل `TelemetryReading` (domain) → صيغة السلك: `m/s → km/h`، `miles → km`.
- **الحالة:** COMPLIANT — translator نقي ومركّز (SRP ممتازة).
- **Issue IDs:** none

### `lib/backend/adapters/eld_engine/mappers/json_primitives.dart` (72، 64)
- **المسؤوليات الفعلية:** مساعدات تحليل JSON مشتركة (`asString/asInt/asBool/asDate/asLocalTime`).
- **الحالة:** COMPLIANT — توحيد ناجح لمساعدة كانت مكرّرة (مذكور صراحةً في توثيق الملف نفسه، الأسطر 3-5).
- **Issue IDs:** none

### `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart` (33، 32)
- **المسؤوليات الفعلية:** `RulesScreenDto → RulesScreenModel` + حقن قيم افتراضية (`breakDurationMinutes: 30`, `weeklyRestartHours: 34`).
- **الطبقة الفعلية:** mapper في `adapters/` لكنه يُخرج نوعًا من `features/account/application/models` — انقلاب تبعية.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-002، BACK-003

### `lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart` (215، 188)
- **المسؤوليات الفعلية:** تحليل 3 endpoints إلى `StatusDashboard` / `WeeklyRecap`؛ 9 parsers متداخلة؛ محللات بدائية (`_parseDuration`, `_parseDate`, `_asStringList`).
- **الحالة:** MODERATE — Mapper ممتاز وظيفيًا، لكنه **يحمل قيم عرض إنجليزية** (BACK-005).
- **Issue IDs:** BACK-005

### `lib/backend/adapters/eld_engine/models/certify_dto.dart` (50، 45)
- **المسؤوليات الفعلية:** `CertifyRequestDto` (طلب) + `CertifyResponseDto` (استجابة) — DTOان في ملف واحد.
- **الطبقة الفعلية:** نموذج داخل `adapters/eld_engine/models`، لكنه **مستورد من `contracts/daily_logs_backend.dart:3`** — أي أن العقد نفسه يستورد من مجلد محوّل.
- **الحالة:** MAJOR (المسؤول عن الخطأ هو المالك/الاستيراد، لا الملف)
- **Issue IDs:** BACK-004

### `lib/backend/adapters/eld_engine/models/dvir_dto.dart` (432، 401)
- **المسؤوليات الفعلية:** 6 فئات: `DvirDto`، `DvirDriverDto`، `DvirDefectDto`، `CreateDvirRequestDto`، `ReviewDvirRequestDto`، `DvirTrailerDto`.
- **لماذا هو كبير؟** ليس ملفًا مبالغًا في توحيد المسؤوليات، بل **جدار DTO لنطاق ميزة واحدة (DVIR) كامل**. كل فئة منها مسؤولية واحدة (فك ترميز/ترميز سلكي). **التقسيم هنا لا يفيد، وقد يجزّئ التماسك**؛ مكانه الحالي داخل `adapters/eld_engine/models/` هو المكان الصحيح.
- **لكن الملف يحتوي مشكلات حقيقية:** (أ) **منطق أعمال مدمج في `fromJson`** عند 107-114: `hasDefects` و`defectsCount` ودمج ثلاث قوائم عيوب (`flatDefects`, `vehicleDefects`, `trailerDefects`) — اشتقاق تجاري يجب أن يكون في mapper، لا في DTO سلكي. (ب) `toJson()` (128-164) يعيد كتابة حقول يملكها الخادم (`id`, `certified`, `createdAt`, `formattedTime`, `defectsCount`, `retentionDaysRemaining`). (ج) الملف **لا يستخدمه أي شيء داخل `lib/backend`**؛ المستهلك الوحيد هو `lib/features/dvir/data/repositories/dvir_repository_impl.dart` (الأسطر 56، 100، 138، 279، 313، 327).
- **الحالة:** MODERATE
- **Issue IDs:** BACK-006، BACK-007

### `lib/backend/adapters/eld_engine/models/readiness_dto.dart` (86، 81)
- **المسؤوليات الفعلية:** `CarrierProposedEdit` + `ReadinessDto` مع تحليل `pendingCarrierEdits` المتداخلة.
- **الحالة:** MODERATE — نفس المشكلة: مُستورد من `contracts/daily_logs_backend.dart:4`.
- **Issue IDs:** BACK-004

### `lib/backend/adapters/eld_engine/models/rules_screen_dto.dart` (103، 94)
- **المسؤوليات الفعلية:** 3 فئات: `RulesScreenDto`، `RulesScreenLimitsDto`، `RulesScreenUpdateRequest`.
- **الحالة:** COMPLIANT (موقعه صحيح) — لكنه يُستورد من مجلد **mock** أيضًا (انقلاب أفقي، BACK-003 / BACK-035).
- **Issue IDs:** BACK-003

### `lib/backend/adapters/eld_engine/models/rules_screen_options.dart` (29، 29)
- **المسؤوليات الفعلية:** دالة علوية واحدة `readRulesOptions` تربط أسماء مفاتيح الخادم (`availableCycleRules` → `cycleRule`).
- **الحالة:** COMPLIANT وظيفيًا — لكنه يُستورد من مجلد mock (BACK-035).
- **Issue IDs:** BACK-035

### `lib/backend/adapters/eld_engine/sub/eld_account_backend.dart` (81، 72)
- **المسؤوليات الفعلية:** نداءان + دالة تطبيع `_mapAccountJson` (15-48) بثلاث مسؤوليات فرعية (driverId fallback، تحويل `license` من نص `"MI, A350622298913"` إلى Map، توحيد `timezone`/`timeZone`). حجم 81 سطرًا معقول ولا يحتاج تقسيمًا.
- **نقطة جيدة:** التطبيع هنا حقيقي ولا يتسرّب — تحققت أن المخرجات `DriverAccount` مُحاط بالكامل.
- **الحالة:** COMPLIANT
- **Issue IDs:** none

### `lib/backend/adapters/eld_engine/sub/eld_auth_backend.dart` (200، 183)
- **المسؤوليات الفعلية:** 4 عمليات؛ استخراج `JSESSIONID` من ترويسات `set-cookie` (62-73)؛ فك `responseType.plain` بـ `jsonDecode` (48-57)؛ فك غلاف `{status, data}` (79-85)؛ **بناء عنوان URL مطلق يدويًا** `'${baseUrl}/api${EldEndpoints.session}'` (30، 107، 156، 174)؛ تطبيع URL خاص به يختلف عن المعياري (24-26)؛ **إعادة بناء ترويسة الجلسة يدويًا** `'Cookie': 'JSESSIONID=$sessionCredential'` (109، 149).
- **الحالة:** MAJOR — يتجاوز `ApiClient` بالكامل ويستخدم `_apiClient.dio` مباشرة، ويكرّر منطق تهيئة العنوان.
- **Issue IDs:** BACK-009، BACK-010، BACK-011

### `lib/backend/adapters/eld_engine/sub/eld_daily_logs_backend.dart` (162، 149)
- **المسؤوليات الفعلية:** 11 عملية؛ **9 منها مجرد** `parser: (data) => data is Map ? data : {}` + `mapValue((r) => r.data ?? {})` — أي تمرير JSON خام بلا ترجمة؛ فقط `certify` (83) و`getReadiness` (155) مترجمان إلى DTO. نسبة الترجمة الفعلية ≈ 18%.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001، BACK-004

### `lib/backend/adapters/eld_engine/sub/eld_driver_session_backend.dart` (92، 85)
- **المسؤوليات الفعلية:** 5 عمليات؛ `getAvailableDrivers()` (39) يُرجع `Result<List<dynamic>>` — تسريب `dynamic` كامل عبر العقد؛ `switchPrimaryDriver` يرسل نفس الـ payload في `queryParameters` **و** `data` معًا (78-79).
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001، BACK-012

### `lib/backend/adapters/eld_engine/sub/eld_duty_status_backend.dart` (89، 82)
- **المسؤوليات الفعلية:** 5 عمليات؛ 3 منها تمرير خام؛ دالتان `submitLegacy*` تستدعيان **نفس نقطة النهاية** `recordDutyStatus` (60) بدون أي تمييز عملي بينهما.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001

### `lib/backend/adapters/eld_engine/sub/eld_dvir_backend.dart` (138، 124)
- **المسؤوليات الفعلية:** 8 عمليات + مساعد `_asMap` (96-101) + `_accepted` (39-49)؛ استخراج `deviceId` من جسم التقرير لوضعه في query string (57-59) — قراءة من JSON المُدخل لتوجيه الطلب.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001، BACK-008

### `lib/backend/adapters/eld_engine/sub/eld_hardware_backend.dart` (114، 101)
- **المسؤوليات الفعلية:** 6 عمليات؛ أول سطر `// ignore_for_file: unused_field, unused_import` (1) — قناع analyzer على ملف **ليس فيه** unused فعليًا (تحققت: لا بلاغ من `flutter analyze`).
- **الحالة:** MINOR
- **Issue IDs:** BACK-001

### `lib/backend/adapters/eld_engine/sub/eld_inspection_backend.dart` (195، 182)
- **المسؤوليات الفعلية:** 8 عمليات؛ 3 مترجمة إلى domain (screen/cycle/logs)، 5 خام؛ مساعدان `_asMap`/`_postJson`.
- **ملاحظة:** لا يحمل `// ignore_architecture`، وهو أنظف ملف في مجلد `sub`.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001

### `lib/backend/adapters/eld_engine/sub/eld_rules_screen_backend.dart` (51، 46)
- **المسؤوليات الفعلية:** `getRulesScreen` مترجم بالكامل؛ `saveRulesScreen` يكتشف "جسم PUT فارغ/جزئي" heuristically (40-47) ثم **يعيد الجلب** كـ fallback (48) — منطق تكافؤ منطقي داخل المحوّل.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-002

### `lib/backend/adapters/eld_engine/sub/eld_signature_backend.dart` (34، 31)
- **المسؤوليات الفعلية:** **لا شيء** — دالة واحدة تُرجع `err(ServerError(code: 'eld.signature_endpoint_absent'))` دائمًا (24-32)؛ والحقل `_apiClient` مُعلَّم `// ignore: unused_field` (12).
- **الحالة:** MAJOR (ميت تمامًا — لا provider ولا مستهلك)
- **Issue IDs:** BACK-013

### `lib/backend/adapters/eld_engine/sub/eld_status_dashboard_backend.dart` (126، 119)
- **المسؤوليات الفعلية:** 3 عمليات مترجمة؛ `_defaultNoteFor` (110-125) — نصوص عرض إنجليزية داخل المحوّل؛ تعامل مع `ResponseType.plain`؛ **تعليق شخصي مكتوب داخل الكود** (60-62)؛ حقن `currentDutyStatus` محليًا إذا غاب عن الاستجابة (86-88) — إخفاء تعطّل العقد.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-005، BACK-014

### `lib/backend/adapters/eld_engine/sub/eld_unidentified_events_backend.dart` (83، 75)
- **المسؤوليات الفعلية:** 3 عمليات + `_asMap` + `_postVoid`.
- **الحالة:** MINOR
- **Issue IDs:** BACK-001

### `lib/backend/adapters/eld_engine/sub/eld_vehicle_backend.dart` (47، 42)
- **المسؤوليات الفعلية:** عمليتان فقط، لكن كلٌّ منهما يعرّف lambda `parser` مكرّرة أسفل الحالة (23-28 و 38-43) بدل استيراد `_asMap` الموجود أصلًا في نفس الحزمة — تكرار فُرصة.
- **الحالة:** MINOR
- **Issue IDs:** BACK-015

### `lib/backend/adapters/mock/fixtures/account_fixtures.dart` (65، 63)
- **المسؤوليات الفعلية:** ثابتان: `accountProfileFixture` (12-32) و`accountMyAccountFixture` (34-65).
- **الحالة:** MINOR — **`accountProfileFixture` كود ميت**: تحققت بالبحث النصي؛ المستهلك الوحيد هو `accountMyAccountFixture` في `mock_account_backend.dart:16`. الـ fixture الأول (21 سطرًا من البيانات) لا يقرأه أي كود.
- **Issue IDs:** BACK-016

### `lib/backend/adapters/mock/mock_adapter.dart` (109، 87)
- **المسؤوليات الفعلية:** مجمّع صِرف لـ 13 عقدة؛ كل الـ `late final`.
- **الحالة:** MODERATE
- **Issue IDs:** BACK-017، BACK-018

### `lib/backend/adapters/mock/sub/mock_account_backend.dart` (30، 27)
- **المسؤوليات الفعلية:** عمليتان تمرّران الـ fixture إلى `DriverAccount.fromJson` مباشرة.
- **الحالة:** MINOR — **عدم تماثل دلالي**: `EldAccountBackend` يطبّق `_mapAccountJson` قبل `fromJson` (eld_account_backend.dart:57-60)، والموك لا يطبّقه إطلاقًا (16).
- **Issue IDs:** BACK-019

### `lib/backend/adapters/mock/sub/mock_auth_backend.dart` (51، 46)
- **المسؤوليات الفعلية:** 4 عمليات، كلها `ok(...)` ثابتة.
- **الحالة:** COMPLIANT — **تناظر كامل مع `EldAuthBackend`** في المفاتيح (`credential`, `user`, `serverOrigin`). أفضل حالة تناظر في المجموعة.
- **Issue IDs:** none

### `lib/backend/adapters/mock/sub/mock_daily_logs_backend.dart` (131، 119)
- **المسؤوليات الفعلية:** 11 عملية؛ 4 منها `throw UnimplementedError` (52، 100، 108، 116).
- **الحالة:** MODERATE — والأسطر 5-6 **يستوردان من `../../eld_engine/models/`** (انقلاب أفقي بين المحوّلين).
- **Issue IDs:** BACK-035، BACK-020

### `lib/backend/adapters/mock/sub/mock_driver_session_backend.dart` (44، 38)
- **المسؤوليات الفعلية:** 5 عمليات؛ 4 منها `UnimplementedError` (14، 19، 33، 41).
- **الحالة:** MAJOR
- **Issue IDs:** BACK-020

### `lib/backend/adapters/mock/sub/mock_duty_status_backend.dart` (45، 39)
- **المسؤوليات الفعلية:** 5 عمليات؛ `record` يُرجع `{'id': DateTime.now().millisecondsSinceEpoch, ...event}` (13).
- **الحالة:** MODERATE — **عدم تماثل دلالي مؤكد**: استخدام `DateTime.now()` يناقض صراحةً قاعدتين معلنتين: `mock_adapter.dart:36` (`**Rule:** No network access. No timers.`) وترويسة التوثيق في `mock_status_dashboard_backend.dart:12` (`Deterministic output`).
- **Issue IDs:** BACK-021

### `lib/backend/adapters/mock/sub/mock_dvir_backend.dart` (74، 63)
- **المسؤوليات الفعلية:** 8 عمليات؛ 2 `UnimplementedError` (33، 43)؛ كتالوج عيوب بـ 11 عنصرًا وثلاث حقول عربية/إنجليزية لكل عنصر (48-58).
- **الحالة:** MAJOR — **`list()` يُرجع `{'reports': []}`** (20) بينما المستهلك يقرأ `rawJson['data']` — تباين صامت (BACK-008).
- **Issue IDs:** BACK-008، BACK-020

### `lib/backend/adapters/mock/sub/mock_hardware_backend.dart` (70، 63)
- **المسؤوليات الفعلية:** 6 عمليات؛ **3 منها `async` + `throw UnimplementedError` داخل جسم `async`** (13، 55، 63).
- **الحالة:** MAJOR — `getStatus` غير منفَّذ بينما `hardwareStatusProvider` في طبقة presentation يستدعيه مباشرة → انهيار شاشة الاتصال في وضع الموك.
- **Issue IDs:** BACK-020، BACK-022

### `lib/backend/adapters/mock/sub/mock_inspection_backend.dart` (195، 182)
- **المسؤوليات الفعلية:** 3 عمليات مطبَّقة (بناء domain entities كاملة) + 5 `UnimplementedError` (161، 165، 178، 189، 193) + `_formatDate` (144-149).
- **الحالة:** MODERATE — يبني كائنات domain بنصوص عرض إنجليزية (`'DOT Inspection'`, `'Review the driver records'`, `'Golden Feather Transport'`, `'Riyadh'`)، وهي بيانات موك لا نصوص عرض مباشرة.
- **Issue IDs:** BACK-020

### `lib/backend/adapters/mock/sub/mock_rules_screen_backend.dart` (72، 68)
- **المسؤوليات الفعلية:** حالة `_state` داخلية + PUT بسيط (دمج shallow عند 65-68).
- **الحالة:** MODERATE — يستورد **مستودع تحويلات المحرك الحقيقي**: `../../eld_engine/models/rules_screen_dto.dart` (7) و`../../eld_engine/mappers/rules_screen_mapper.dart` (8).
- **Issue IDs:** BACK-035

### `lib/backend/adapters/mock/sub/mock_signature_backend.dart` (49، 41)
- **المسؤوليات الفعلية:** تخزين في الذاكرة + إصدار شهادة deterministic (base64 hash).
- **الحالة:** MINOR — منطق نظيف، لكنه **ميت تمامًا**: لا يوجد `signatureBackendProvider` ولا أي مستهلك (BACK-013).
- **Issue IDs:** BACK-013

### `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart` (191، 178)
- **المسؤوليات الفعلية:** حالة `_currentStatus` + 3 بناة (dashboard/circle/recap) + `_dayOfWeek`.
- **الحالة:** COMPLIANT وظيفيًا — fully typed domain، **تناظر كامل مع المحرك الحقيقي** في التوقيع.
- **Issue IDs:** BACK-005

### `lib/backend/adapters/mock/sub/mock_unidentified_events_backend.dart` (39، 35)
- **المسؤوليات الفعلية:** 3 عمليات، **كلها** `UnimplementedError` (18، 28، 36).
- **الحالة:** MAJOR — العقد الوحيد بنسبة تنفيذ 0%، ومع ذلك presentation يستهلكه مباشرة.
- **Issue IDs:** BACK-020، BACK-023

### `lib/backend/adapters/mock/sub/mock_vehicle_backend.dart` (21، 17)
- **المسؤوليات الفعلية:** عمليتان ترجعان `{'data': []}`.
- **الحالة:** COMPLIANT — تصحيح واعٍ ومُعلَن (11-12) لسبب حقيقي.
- **Issue IDs:** none

### `lib/backend/contracts/account_backend.dart` (17، 15)
- **المسؤوليات الفعلية:** عقدة منظَّمة، تُرجع `domain/account/DriverAccount`.
- **الحالة:** COMPLIANT — **النموذج الملهم**: العقدة الوحيدة (مع `signature_backend` و`status_dashboard_backend`) التي ترجع نوعًا مُحاطًا بدل `RawJson`.
- **Issue IDs:** none

### `lib/backend/contracts/auth_backend.dart` (29، 25)
- **المسؤوليات الفعلية:** 4 عمليات؛ `login` و`validateSession` تُرجعان `RawJson`.
- **الحالة:** MODERATE — **ثلاثة تسريبات في عقدة واحدة**: (1) `RawJson`؛ (2) **مفتاح `backendType`** كمُعامل (9، 15، 21) — تسمية داخلية خاصة بـ backend تدخل العقد؛ (3) بنية مفاتيح `credential/user/serverOrigin` تصبح عقدًا ضمنيًا عبر الاستهلاك في `auth_repository_impl.dart:60-64`.
- **Issue IDs:** BACK-001، BACK-010

### `lib/backend/contracts/contract_enums.dart` (51، 41)
- **المسؤوليات الفعلية:** 5 enums مغلّفة، كل واحد يحمل حقل `wire`.
- **الحالة:** MODERATE — **تسرّب قيم wire إلى طبقة العقد**: `DutyStatusAction.switchPrimary('switch-primary')` (46) و`legacySwitch('legacy-switch')` (47) حرفيًا قيم Swagger، و`UnidentifiedTab.unclaimed('UNCLAIMED')` (38) تسمية خادم. والاستهلاك يصل إلى **طبقة presentation**: `unidentified_events_page.dart:6`.
- **Issue IDs:** BACK-024

### `lib/backend/contracts/daily_logs_backend.dart` (72، 61)
- **المسؤوليات الفعلية:** 11 عملية؛ **6 منها `RawJson`**؛ تستورد DTOs من مجلد المحوّل (3-4).
- **الحالة:** CRITICAL — الملف نفسه يوثّق المشكلة عبر `// TODO(P2): replace with List<DailyLog>` في 6 مواضع، لكن الأهم أن **العقدة تعتمد على `adapters/eld_engine/models/`** — انقلاب اتجاه الاعتمادية في قلب طبقة الـ port.
- **Issue IDs:** BACK-001، BACK-004

### `lib/backend/contracts/driver_session_backend.dart` (31، 25)
- **المسؤوليات الفعلية:** 5 عمليات؛ `getAvailableDrivers()` تُرجع `Result<List<dynamic>>` (12).
- **الحالة:** MODERATE — **`dynamic` مكشوف في توقيع عقدة**؛ لا نوع يمكن للمستهلك الاعتماد عليه.
- **Issue IDs:** BACK-001، BACK-012

### `lib/backend/contracts/duty_status_backend.dart` (35، 30)
- **المسؤوليات الفعلية:** 5 عمليات؛ **5 منها `RawJson`** (لا استثناء)؛ دالتان موسومتان `// --- Legacy methods for P5.5 ---` (25).
- **الحالة:** MAJOR — عقدة بأقل ترجمة في المجموعة؛ `record(RawJson event)` و`update(RawJson update)` تعني أن **بناء جسم الطلب يحدث خارج طبقة البنية التحتية**، أي أن كود تشكيل الحقول الويبرية يعيش في مستهلكي العقد.
- **Issue IDs:** BACK-001

### `lib/backend/contracts/dvir_backend.dart` (50، 39)
- **المسؤوليات الفعلية:** 8 عمليات؛ **8 منها `RawJson`**؛ 3 منها تحمل `expectedOwnerDriverId` (23، 35).
- **الحالة:** MAJOR — وجود `int? expectedOwnerDriverId` في عقدة يعني أن **مفهوم جدولة الطابور وربط المالك (queue-dispatch owner binding) تسرّب من طبقة النقل إلى طبقة العقد**؛ وهو مفهوم تنفيذية بحت معرَّف في `auth_interceptor.dart:45`.
- **Issue IDs:** BACK-001، BACK-012

### `lib/backend/contracts/hardware_backend.dart` (37، 31)
- **المسؤوليات الفعلية:** 6 عمليات؛ 5 `RawJson` وواحدة `TelemetryReading` (مُحاط جيدًا).
- **الحالة:** MODERATE
- **Issue IDs:** BACK-001

### `lib/backend/contracts/inspection_backend.dart` (65، 56)
- **المسؤوليات الفعلية:** 8 عمليات؛ 3 مُحاطة بنماذج domain (`getScreen`, `getCycle`, `getLogs`)، و5 `RawJson`.
- **الحالة:** MODERATE — أفضل عقدتين من حيث الترجمة بعد `account`، لكن التوثيق يصرّح بضعفها: «Kept as RawJson until Phase 4» (26).
- **Issue IDs:** BACK-001

### `lib/backend/contracts/raw_json.dart` (10، 9)
- **المسؤوليات الفعلية:** `typedef RawJson = Map<String, dynamic>;` (10) + وثيقة تطلب `// TODO(P2)` على كل دالة تُرجعه.
- **الحالة:** MAJOR — **هذا أقرب شيء لـ«عقد زجاجي» في التصميم**: يصدّر نوعًا غير مُحاط إلى 11 عقدة، ويستهلكه presentation وdomain فعليًا. كما أن `vehicle_repository_impl.dart:36` و`dvir_repository_impl.dart:70` يستوردانه مباشرة إلى طبقة `data`.
- **Issue IDs:** BACK-001

### `lib/backend/contracts/rules_screen_backend.dart` (15، 13)
- **المسؤوليات الفعلية:** عمليتان تُرجعان `RulesScreenModel`؛ `saveRulesScreen` تأخذ `RawJson update` (13).
- **الحالة:** MODERATE — **هذه هي الحافة المعروفة `backend → features`**: السطر 3 يستورد من `features/account/application/models`.
- **Issue IDs:** BACK-002

### `lib/backend/contracts/signature_backend.dart` (13، 12)
- **المسؤوليات الفعلية:** دالة واحدة `save` مُحاطة بـ `SignatureCertificate`.
- **الحالة:** MINOR — العقد نظيف تمامًا، لكنه **ميت**: لا provider ولا مستهلك.
- **Issue IDs:** BACK-013

### `lib/backend/contracts/status_dashboard_backend.dart` (20، 17)
- **المسؤوليات الفعلية:** 3 عمليات، **كلها** مُحاطة بنماذج domain (`StatusDashboard`, `DutyStatusCode`, `WeeklyRecap`).
- **الحالة:** COMPLIANT — أنقى عقدة في المجموعة، بلا أي `RawJson` ولا Dio ولا سلاسل نصية. **النموذج الذي تُبنى عليه بقية العقود.**
- **Issue IDs:** none

### `lib/backend/contracts/unidentified_events_backend.dart` (27، 24)
- **المسؤوليات الفعلية:** 3 عمليات؛ `list()` تُرجع `RawJson` (8)، و`claim`/`reject` تُرجعان `void`.
- **الحالة:** MAJOR — العقد الوحيد الذي تكون فيه **نسبة التنفيذ في الموك 0%** بينما presentation يستهلكه مباشرة.
- **Issue IDs:** BACK-001، BACK-020

### `lib/backend/contracts/vehicle_backend.dart` (12، 9)
- **المسؤوليات الفعلية:** عمليتان، كلاهما `RawJson`.
- **الحالة:** MODERATE — عقدة شبه فارغة؛ تسمية `RawJson` بلا حتى `TODO(P2)`، أي أنها تتجاوز حتى قاعدة التوثيق التي وضعها `raw_json.dart:4-5`.
- **Issue IDs:** BACK-001

### `lib/backend/core/backend_adapter.dart` (61، 42)
- **المسؤوليات الفعلية:** واجهة مجمّعة بـ **14 getter كلها nullable** (31-56) + `identity` + `dispose()`.
- **الحالة:** MODERATE — الـ nullability ليست مرونة بل **غياب أنواع**: `backend_providers.dart:61` يحوّل `null` إلى `StateError` في كل getter.
- **Issue IDs:** BACK-025

### `lib/backend/core/backend_identity.dart` (94، 81)
- **المسؤوليات الفعلية:** value object ثابت؛ مصنعان (`eldEngine`, `mock`)؛ تطبيع URL خاص به `_normalizeUrl` (84-93).
- **الحالة:** MODERATE — التطبيع هنا **مكرَّر** من `ApiConfig.normalized()` بمنطق **متطابق حرفيًا**.
- **Issue IDs:** BACK-026

### `lib/backend/core/backend_kind.dart` (19، 17)
- **المسؤوليات الفعلية:** enum من قيمتين مع توثيق قاعدة التوسعة.
- **الحالة:** COMPLIANT
- **Issue IDs:** none

### `lib/backend/core/backend_registry.dart` (129، 111)
- **المسؤوليات الفعلية:** خريطة adapters + `activeIdentity`؛ مصنعان مع تحققين؛ 7 API للقراءة/البحث؛ `disposeAll` مع تجميع أخطاء.
- **الحالة:** MAJOR — **زخرفة مؤكدة**: المستهلك الوحيد هو `backend_providers.dart:27-29` الذي يستدعي `BackendRegistry.single(...)`.
- **Issue IDs:** BACK-027

### `lib/backend/http/api_config.dart` (7، 6)
- **المسؤوليات الفعلية:** **صفر** — الملف كله تعليقات، بما فيها `library;` و`export`.
- **الحالة:** MINOR — **ملف ميت** معلَن كـ DEPRECATED، لا يستورده أي كود (تحققت).
- **Issue IDs:** BACK-028

### `lib/backend/http/api_response.dart` (7، 6)
- **المسؤوليات الفعلية:** **صفر** — نفس الحالة، كله تعليقات DEPRECATED.
- **الحالة:** MINOR — ملف ميت.
- **Issue IDs:** BACK-028

### `lib/backend/http/eld_endpoints.dart` (150، 137)
- **المسؤوليات الفعلية:** 40+ ثابت مسار؛ **20 منها دوال** مبنية على `int`/`String`.
- **الحالة:** MODERATE — **مصدر واحد جيد للمسارات** (COMPLIANT من حيث DRY)، لكنه مقيَّد بـ `int` بينما طبقة العقد تستخدم Value Objects — أي أن **التحويل إلى int يحدث يدويًا بـ `.value` عند كل استدعاء**.
- **Issue IDs:** BACK-029

### `lib/backend/http/interceptors/auth_interceptor.dart` (144، 130)
- **المسؤوليات الفعلية:** (1) وسم كل طلب بـ epoch وcredential generation (57-59)؛ (2) **استثناء مسار إنشاء الجلسة** (64)؛ (3) قراءة الجلسة و**إنفاذ ربط المالك قبل الإرسال** (80-99)؛ (4) **منع تسريب الكوكي عبر الأصول** (102-113)؛ (5) **معالجة 401 بثلاثة أجيال** (119-143).
- **الحالة:** MODERATE — منطق 401 المتعدد الأجيال والاستثنائي (session cookie لا Bearer) **ممتاز تقنيًا وموثّق بالعربية**؛ لكن الملف ينتهك الاتجاه مرتين (السطران 2-3).
- **Issue IDs:** BACK-009، BACK-010، BACK-030، BACK-031

### `lib/backend/http/interceptors/request_logger.dart` (134، 124)
- **المسؤوليات الفعلية:** تسجيل الطلب/الاستجابة/الخطأ؛ إخفاء 15 مفتاح حساس (21-37)؛ تحليل أجسام HTML وأخطاء قاعدة البيانات (99-127).
- **الحالة:** MINOR/MODERATE — **مقيَّد بـ `kDebugMode`** فلا يتسرب للإنتاج؛ لكن **مسار `onError` يطبع الجسم الخام بلا إخفاء** عند 128-130.
- **Issue IDs:** BACK-032

### `lib/backend/http/interceptors/time_drift_interceptor.dart` (67، 57)
- **المسؤوليات الفعلية:** قراءة `Date` من الترويسة (نجاحًا وفشلًا)؛ تثبيت (throttling) بميلاد 30 ثانية / 5 دقائق (50-60)؛ استدعاء `timeProvider.anchor(serverUtc)` (62).
- **الحالة:** MODERATE — **سلسلة الثقة ناقصة التحقق**: أول استجابة تُثبّت بلا أي فحص، و`anchor()` لا تتحقق من القيمة، والاعتراض مربوط بالـ Dio المشترك بلا opt-out لكل طلب.
- **Issue IDs:** BACK-033

### `lib/backend/providers/backend_network_providers.dart` (82، 70)
- **المسؤوليات الفعلية:** بناء `ApiClient` مع **تطبيع رابط ثالث** (30-39)؛ تركيب 3 اعتراضات؛ مزوّد `StreamController` لأحداث 401؛ ومزوّد عميل Traccar الأصلي (77-82).
- **الحالة:** MODERATE — ومزوّد Traccar **وظيفة تتبع** موضوعة في `backend/providers`.
- **Issue IDs:** BACK-026، BACK-034

### `lib/backend/providers/backend_providers.dart` (117، 99)
- **المسؤوليات الفعلية:** `backendRegistryProvider` + `activeBackendProvider` (اختيار الموك/ELD Engine) + **13** `*BackendProvider`.
- **الحالة:** MODERATE — **13 من 14**: لا يوجد `signatureBackendProvider`.
- **Issue IDs:** BACK-013، BACK-025

---

## B. المشكلات التفصيلية

### ISSUE BACK-001: طبقة العقد تصدّر `RawJson` وتتسرب بها إلى domain وpresentation
- **Severity:** HIGH
- **Category:** Architecture
- **Location:** `lib/backend/contracts/raw_json.dart:10`
- **Evidence:**
```dart
typedef RawJson = Map<String, dynamic>;
```
والتسريب المؤكَّد في الاستهلاك من طبقتين أعلى:
```dart
// lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:13
import '../../../../../backend/contracts/status_dashboard_backend.dart';
// :46
  final StatusDashboardBackend _dashboardBackend;
```
```dart
// lib/features/connection/presentation/providers/hardware_status_provider.dart:15-23
  final backend = ref.read(hardwareBackendProvider);
  final uniqueId = ref.watch(vehicleProvider).selectedVehicle?.uniqueId;
  final result = await backend.getStatus(uniqueId: uniqueId);
  return result.fold((failure) => throw failure, (json) {
    final read = parseConnectivityStatus(json);
    if (read == null) {
      throw const FormatException('connectivity body is not an object');
    }
    return read;
  });
```
- **السلوك الحالي:** `RawJson` (= `Map<String, dynamic>`) هو النوع المُرجَع في 11 من 13 عقدة. الملفات التي تنتج هذه الخرائط هي بالضبط نفس الملفات التي يفترض في Clean Architecture أن تُنشئ نماذج مُحاطة.
- **لماذا هو مشكل:** النوع غير المُحاط يمرّر لأسفل حتى الطبقتين اللتين يفترض أنهما الأبعد عن السلك. النتيجة أن **اسم حقل من `openapi.yaml` صار واجهة برمجية** داخل `presentation`. مثال: `hardware_status_provider.dart:19` يستدعي `parseConnectivityStatus(json)` — محلل يفهم مفاتيح الخادم — من داخل `presentation`.
- **المبدأ المنتهك:** Dependency Inversion + Encapsulation. الـ port يجب أن يكون مكتوبًا بلغة النطاق (domain)، لا بلغة النقل (wire).
- **المالك الحالي:** `lib/backend/contracts/*` (النوع) و`lib/features/*` (الاستهلاك).
- **المالك الصحيح:** `lib/domain/**` — نماذج مُحاطة، مثل `DotInspectionScreen` في `inspection_backend.dart:9`، وهو يثبت أن الحل معمول به بالفعل داخل نفس المجلد.
- **العواقب:** تغيير اسم حقل في الخادم = كسر في `presentation`. لا يمكن كتابة اختبار نطاقي (domain test) بلا تشغيل خادم. `flutter analyze` لا يستطيع التقاط خطأ مفتاح.
- **التصحيح المقترح:** استبدال تدريجي لـ `RawJson` بنماذج domain مُحاطة، بالترتيب التصاعدي للاستخدام: `getAvailableDrivers` → `hardware.getStatus/getReadiness` → `unidentifiedEvents.list` → `dailyLogs.list`. وحظر أي `import` لـ `raw_json.dart` من `domain/` أو `presentation/` كقاعدة تحليل جذرية (انظر BACK-003).
- **الملفات المرتبطة:** `raw_json.dart`، `daily_logs_backend.dart`، `duty_status_backend.dart`، `dvir_backend.dart`، `hardware_backend.dart`، `inspection_backend.dart`، `vehicle_backend.dart`، `auth_backend.dart`، `driver_session_backend.dart`، `unidentified_events_backend.dart`، `duty_status_tracker.dart`، `hardware_status_provider.dart`، `unidentified_events_provider.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-002: الحافة المعروفة `lib/backend → lib/features` ليست حادثة بل نمط من 6 استيرادات
- **Severity:** HIGH
- **Category:** Coupling
- **Location:** `lib/backend/contracts/rules_screen_backend.dart:3`
- **Evidence:**
```dart
// lib/backend/contracts/rules_screen_backend.dart:3
import '../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
```
والتكرارات الخمس الأخرى (تحققت منها كلها بالبحث النصي):
```dart
// lib/backend/adapters/eld_engine/sub/eld_rules_screen_backend.dart:3
import '../../../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
// lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart:1
import '../../../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
// lib/backend/adapters/mock/sub/mock_rules_screen_backend.dart:4
import '../../../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
// lib/backend/http/interceptors/auth_interceptor.dart:2-3
import '../../../features/auth/data/datasources/auth_local_data_source.dart'; // ignore_architecture
import '../../../features/auth/domain/entities/auth_session.dart'; // ignore_architecture
// lib/backend/providers/backend_network_providers.dart:11-13
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart'; // ignore_architecture
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart'; // ignore_architecture
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart'; // ignore_architecture
```
- **السلوك الحالي:** `RulesScreenModel` — كائن من `features/account/application` — يتدفق عبر دورة كاملة: العقدة → المحوّل → الـ mapper → presentation، موزّعًا على 4 ملفات.
- **لماذا هو مشكل (الحكم المطلوب):** **ليست استيرادًا عارضًا.** الدليل أن `RulesScreenModel` لا يمكن نقله ببساطة: هو ليس `domain` ولا `application` مجرد حاوية، بل **كائن عابر للطبقات** يحمل `HosConfiguration limits` (`rules_screen_mapper.dart:19-30`) القادمة من `core/config`. الجذر ليس موقع الملف، بل أن **`RulesScreenModel` لا ينتمي لأي طبقة** — كان يجب أن يُوضع في `domain/account` أو `domain/hos`. كذلك `auth_interceptor.dart:2` يستورد من `features/auth/**data**` — أي أن طبقة البنية التحتية تعرف عن تنفيذ مصادقة ميزة ما. و`backend_network_providers.dart:11-13` يجعل `backend/providers` بوابة لعميل تتبّع native خاص بميزة.
- **المبدأ المنتهك:** Dependency Rule (طبقة البنية التحتية لا تعرف الميزات).
- **المالك الحالي:** `features/account/application/models/rules_screen_model.dart`. **المالك الصحيح:** `lib/domain/account/rules_screen_model.dart` أو `lib/domain/hos/`.
- **العواقب:** لا يمكن حذف feature `account` دون كسر `contracts`. لا يمكن اختبار `RulesScreenBackend` في عزلة عن الميزة. `AuthInterceptor` غير قابل لإعادة الاستخدام خارج هذا المشروع.
- **التصحيح المقترح:** (1) **نقل** `RulesScreenModel` إلى `lib/domain/`. (2) **نقل** `AuthLocalDataSource` و`AuthSession` خلف واجهة في `lib/core/session/` — وهي موجودة أصلًا (`core/session/session_epoch.dart`). (3) **نقل** `traccarNativeClientProvider` إلى `features/tracking/data/providers/`. (4) **حذف `// ignore_architecture`** لأنها ليست آلية (انظر BACK-003).
- **الملفات المرتبطة:** `rules_screen_backend.dart`، `eld_rules_screen_backend.dart`، `rules_screen_mapper.dart`، `mock_rules_screen_backend.dart`، `auth_interceptor.dart`، `backend_network_providers.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-003: `// ignore_architecture` تعليق تزييني بلا أي آلية إنفاذ
- **Severity:** MEDIUM
- **Category:** Maintainability
- **Location:** `lib/backend/contracts/rules_screen_backend.dart:3` (و6 مواضع أخرى)
- **Evidence:**
```yaml
# analysis_options.yaml:18-20
include: package:flutter_lints/flutter.yaml

linter:
  # The lint rules applied to this project can be customized in the
```
و:
```dart
// lib/backend/contracts/rules_screen_backend.dart:3
import '../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
```
- **السلوك الحالي:** تحققت عمليًا: `flutter analyze lib/backend` ⇒ `No issues found!`. لا يوجد lint باسم `ignore_architecture` في `flutter_lints` ولا مضاف في `linter.rules` (المكان مذكور فقط كتعليق توضيحي، ولم يُفعَّل أي قاعدة).
- **لماذا هو مشكل:** تعليق يُقرأ كـ«هذا الاستيراد مسموح استثناءً موثّقًا» بينما هو **تعليق لا يفعل شيئًا** إطلاقًا. 9 occurrences في `lib/backend/` وحده. النتيجة: انطباع زائف بأن الحد المعماري مُراقَب، بينما كسره مجاني.
- **المبدأ المنتهك:** Defense in Depth / Governance.
- **المالك الحالي / الصحيح:** سجل استثناءات حقيقي (`docs/architecture_exceptions.md` مُراجَع من المالك) + custom lint عبر `custom_lint` و`arch_lints`.
- **العواقب:** كل «استثناء معتمد» في المشروع غير قابل للتدقيق ولا للتصحيح.
- **الملفات المرتبطة:** `analysis_options.yaml`، كل ملفات `lib/backend/**` الحاملة للتعليق
- **Confidence:** CONFIRMED

### ISSUE BACK-004: العقد `daily_logs_backend.dart` يستورد نماذج من مجلد محوّل (انقلاب اتجاه)
- **Severity:** CRITICAL
- **Category:** Architecture
- **Location:** `lib/backend/contracts/daily_logs_backend.dart:3-4`
- **Evidence:**
```dart
// lib/backend/contracts/daily_logs_backend.dart:1-6
import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import '../adapters/eld_engine/models/certify_dto.dart';
import '../adapters/eld_engine/models/readiness_dto.dart';
import 'raw_json.dart';
```
```dart
// lib/backend/contracts/daily_logs_backend.dart:38-41
  Future<Result<CertifyResponseDto>> certify(
    CertifyRequestDto request, {
    int? expectedOwnerDriverId,
  });
```
والنتيجة المباشرة — الموك مُلزَم بتوقيع يحتوي على DTOات المحرك الحقيقي:
```dart
// lib/backend/adapters/mock/sub/mock_daily_logs_backend.dart:5-6
import '../../eld_engine/models/certify_dto.dart';
import '../../eld_engine/models/readiness_dto.dart';
```
- **السلوك الحالي:** طبقة الـ port (المحايدة المفترضة) تستورد من **محوّل محدّد بعينه** (`eld_engine`).
- **لماذا هو مشكل:** هذا هو **المعيار الحقيقي** لما إذا كان there port حقيقي: هل يستطيع mock أن يُنفَّذ دون أن يعرف المحرك الحقيقي؟ هنا الإجابة لا. كما أن `DailyLogsBackend` — وهي واجهة use-case — صارت **مرتبطة بتمثيل ELD المحدد**، ما يعني أن أي backend ثالث محكوم عليه بإعادة تعريف نفس الـ DTOs.
- **المبدأ المنتهك:** Dependency Inversion — تعتمد المصادر الداخلية (Abstract) على التفاصيل الخارجية.
- **المالك الحالي:** `adapters/eld_engine/models/*`. **المالك الصحيح:** `lib/domain/logs/` (أو `lib/backend/contracts/dto/` مشترك).
- **العواقب:** استبدال/حذف `eld_engine` يكسر العقدة. الرسم البياني للطبقات غير قابل للتحقق آليًا. أي backend ثالث مجبور على تبنّي DTOات غريبة عنه.
- **التصحيح المقترح:** نقل `certify_dto.dart` و`readiness_dto.dart` إلى `lib/domain/logs/` كنماذج domain مع `fromJson` في mapper المحوّل. بعد نقلها يصبح السطران 3-4 في العقدة استيرادًا محايدًا، ويُحلBACK-035 في نفس الوقت.
- **الملفات المرتبطة:** `daily_logs_backend.dart`، `certify_dto.dart`، `readiness_dto.dart`，`mock_daily_logs_backend.dart`، `eld_daily_logs_backend.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-005: نصوص عرض إنجليزية داخل طبقة backend (mapper + محوّل)
- **Severity:** LOW
- **Category:** Architecture
- **Location:** `lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart:76`
- **Evidence:**
```dart
// status_dashboard_mapper.dart:73-84
    if (raw is! Map<String, dynamic>) {
      return const RemainingCircle(
        remaining: Duration.zero,
        label: 'Remaining',
        progress: 0.0,
      );
    }
    return RemainingCircle(
      remaining: _parseDuration(raw['time']),
      label: JsonPrimitives.asString(raw['label'], fallback: 'Remaining'),
      progress: JsonPrimitives.asDouble(raw['progress']).clamp(0.0, 1.0),
    );
```
```dart
// status_dashboard_mapper.dart:90-93
      drive: _parseIndicator(raw['drive'], fallbackLabel: 'DRIVE'),
      shift: _parseIndicator(raw['shift'], fallbackLabel: 'SHIFT'),
      breakTime: _parseIndicator(raw['breakTime'], fallbackLabel: 'BREAK'),
      cycle: _parseIndicator(raw['cycle'], fallbackLabel: 'CYCLE'),
```
```dart
// eld_status_dashboard_backend.dart:110-125
  static String _defaultNoteFor(DutyStatusCode status) {
    switch (status) {
      case DutyStatusCode.onDutyNotDriving:
        return 'Available';
      case DutyStatusCode.sleeperBerth:
        return 'Sleeper Berth';
```
- **السلوك الحالي:** سلاسل عرض مُحاط بها داخل domain (`RemainingCircle.label`، `HosIndicator.label`) ومُولَّدة في طبقة البنية التحتية.
- **لماذا هو مشكل:** التطبيق يدّع دعم العربية (الـ fixtures والموكات تحمل نصوصًا عربية)، لكن هذه القيم ستُعرض دائمًا بالإنجليزية لأن مَن يملك l10n هو presentation. هذا **خلط مسؤوليات** لا مجرد ترجمة ناقصة.
- **المبدأ المنتهك:** SRP على مستوى الطبقة.
- **العواقب:** لا يمكن ترجمة شاشات HOS. الفحص المتسق عند نقص البيانات يُنتج نصًا إنجليزيًا في بيئة عربية.
- **التصحيح المقترح:** جعل `label` nullable في النماذج وترجمتها في presentation عبر `AppLocalizations`، أو إطلاق الـ fallback كمفتاح ترجمة (`'hosIndicator.drive'`) لا كنص نهائي.
- **الملفات المرتبطة:** `status_dashboard_mapper.dart`، `eld_status_dashboard_backend.dart`، `mock_status_dashboard_backend.dart`، `mock_inspection_backend.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-006: منطق أعمال داخل `DvirDto.fromJson` و`toJson` يعيد كتابة حقول الخادم
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/eld_engine/models/dvir_dto.dart:107`
- **Evidence:**
```dart
// dvir_dto.dart:107-114
      hasDefects: json['hasDefects'] == true || vehicleDefects.isNotEmpty || trailerDefects.isNotEmpty || flatDefects.isNotEmpty,
      defectsCount: flatDefects.length + vehicleDefects.length + trailerDefects.length,
      defectsSummary: json['defectsSummary']?.toString(),
      outOfService: json['outOfService'] == true,
      photos: photos,
      vehicleDefects: vehicleDefects,
      trailers: trailers,
      defects: [...flatDefects, ...vehicleDefects, ...trailerDefects],
```
```dart
// dvir_dto.dart:129-130
      'id': id,
      'driver': driver?.toJson(),
```
```dart
// dvir_dto.dart:154-155
      'certified': certified,
      'signatureData': signatureData,
```
- **السلوك الحالي:** `hasDefects` و`defectsCount` ودمج القوائم الثلاث **مشتقات** لا قيم مخزّنة. و`toJson()` يُعيد كتابة حقول الخادم (`id`, `certified`, `createdAt`, `formattedTime`, `defectsCount`, `retentionDaysRemaining`).
- **لماذا هو مشكل:** DTO السلكي يجب أن يكون faithful transcode فقط. الاشتقاق هنا **قاعدة DVIR** (هل يوجد عيب فعلي؟) داخل طبقة البنية التحتية؛ أي تعديل في الخادم على تعريف «العيب» يتطلب تعديلًا في هذا الملف. وإذا استُخدم `CreateDvirRequestDto.fromJson` (322) لتحويل حمولة واردة ثم `toJson()` (350) للإرسال، فسيتكرر `id` وحقول الخادم في جسم الطلب.
- **المبدأ المنتهك:** SRP / فصل DTO عن Mapper.
- **المالك الحالي:** `adapters/eld_engine/models/dvir_dto.dart`. **المالك الصحيح:** mapper في `adapters/eld_engine/mappers/dvir_mapper.dart` (المجلد موجود ويعمل).
- **العواقب:** عدم تناسق بين «ما يراه الخادم» و«ما يراه التطبيق». اختبار `hasDefects` يحتاج معرفة مصادر العيوب الثلاثة.
- **التصحيح المقترح:** نقل الاشتقاق إلى `DvirMapper.toEntity(DvirDto)`. وحذف `toJson()` من DTOات القراءة (`DvirDto`) لأنها غير مستخدمة — تحققت: `CreateDvirRequestDto` و`ReviewDvirRequestDto` هما المستخدمان فعليًا (المستهلك الوحيد `dvir_repository_impl.dart:279`).
- **الملفات ذات الصلة:** `dvir_dto.dart`، `lib/features/dvir/data/repositories/dvir_repository_impl.dart:327`
- **Confidence:** CONFIRMED

### ISSUE BACK-007: `DvirDto` (نموذج `eld_engine`) يُستهلك من خارج مجلد المحوّل
- **Severity:** MEDIUM
- **Category:** Coupling
- **Location:** `lib/features/dvir/data/repositories/dvir_repository_impl.dart:56`
- **Evidence:**
```dart
// features/dvir/data/repositories/dvir_repository_impl.dart:54-58
        final rawReports = (rawJson['data'] as List<dynamic>?) ?? [];
        final reports = rawReports.map((json) {
          final dto = DvirDto.fromJson(json as Map<String, dynamic>);
          return _mapDtoToEntity(dto);
        }).toList();
```
- **السلوك الحالي:** `DvirDto` (و`ReviewDvirRequestDto` عند 279) معرّفان في `lib/backend/adapters/eld_engine/models/` ويُستهلكان في `lib/features/dvir/data/repositories/`. تحققت بالبحث النصي: **لا استيراد لـ `dvir_dto.dart` من أي مكان داخل `lib/backend/`**.
- **لماذا هو مشكل:** هذا يعني أن `DvirDto` ليس نوعًا داخليًا للمحوّل بل **حقيقة مشتركة** بين البنية التحتية والمستهلك. الموقع في `adapters/eld_engine/` مضلّل: أي كود في طبقة `data` يستطيع الوصول إلى تفاصيل ELD Engine بينما العقدة (`dvir_backend.dart`) تُرجع `RawJson`. عمليًا: طبقة `data` مربوطة بمحوّل واحد بالتزامًا مع `MockAdapter`.
- **المبدأ المنتهك:** Encapsulation (نوع مشترك وُضع في المكان الخطأ).
- **العواقب:** استبدال المحرك = كسر طبقة `data`. لا يمكن إعادة استخدام `DvirDto` مع backend ثالث.
- **التصحيح المقترح:** إما (أ) رفع `dvir_dto.dart` إلى `lib/backend/contracts/dto/` كـ port DTO مشترك (الأنسب، لأنه يُستخدم فعلاً من الطرفين)، أو (ب) الأفضل: نقل التحليل إلى mapper داخل المحوّل وإرجاع `DvirReport` (domain) من العقدة نفسها — وهذا يلغي `RawJson` أيضًا.
- **الملفات ذات الصلة:** `dvir_dto.dart`، `dvir_repository_impl.dart`، `dvir_backend.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-008: تباين صامت في شكل استجابة `DvirBackend.list` بين المحرك والموك
- **Severity:** HIGH
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_dvir_backend.dart:20`
- **Evidence:**
```dart
// mock_dvir_backend.dart:19-21
  }) async {
    return ok({'reports': []});
  }
```
مقابل:
```dart
// eld_dvir_backend.dart:34
      parser: (data) => data is List ? {'data': data} : (data is Map<String, dynamic> ? data : {}),
```
والconsumer:
```dart
// features/dvir/data/repositories/dvir_repository_impl.dart:54
        final rawReports = (rawJson['data'] as List<dynamic>?) ?? [];
```
- **السلوك الحالي:** العقد نفسه يُرجع `RawJson`، لكن **شكله غير مُلزم**. المحرك الحقيقي يغلّف في `'data'`، والموك يغلّف في `'reports'`. المستهلك يقرأ `'data'` فقط.
- **لماذا هو مشكل:** هذا **ليس** مجرد نقص تناظر في التنفيذ، بل **عقد ضمني غير معلن** يعيش خارج الواجهة. النتيجة المؤكَّدة: `getDvirReports()` تحت الموك يُرجع **قائمة فارغة دائمًا** (`rawJson['data']` = null) — لا رسالة خطأ، لا تحذير. أي أن **اختبار العرض بكامل وظيفته يمرّ تحت الموك يكذب بهدوء**.
- **المبدأ المنتهك:** Contract completeness / Liskov Substitution.
- **العواقب:** شاشة DVIR فارغة في وضع الموك بلا أي مؤشر؛ اختبارات الواجهة تمرّ (قائمة فارغة) دون كشف الانحراف؛ أي إصلاح لاحق على الشاشة لا يُختبر على الموك.
- **التصحيح المقترح:** إما (أ) **الحظر الصريح**: `MockDvirBackend.list` يرجع `{'data': <dynamic>[]}` لمطابقة المحرك، أو (ب) الأفضل: استبدال `RawJson` بـ `List<DvirReport>` في العقدة — عندها يصبح الشكل جزءًا من النوع (مُجمَّع بالـ compiler) ولا يمكن أن يتباين.
- **الملفات ذات الصلة:** `mock_dvir_backend.dart`، `eld_dvir_backend.dart`، `dvir_repository_impl.dart`، `dvir_backend.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-009: `auth_interceptor.dart` يستورد من طبقتي `features/auth` (data + domain)
- **Severity:** HIGH
- **Category:** Coupling
- **Location:** `lib/backend/http/interceptors/auth_interceptor.dart:2-3`
- **Evidence:**
```dart
// lib/backend/http/interceptors/auth_interceptor.dart:1-7
import 'package:dio/dio.dart';
import '../../../features/auth/data/datasources/auth_local_data_source.dart'; // ignore_architecture
import '../../../features/auth/domain/entities/auth_session.dart'; // ignore_architecture
import '../../../core/error/failure.dart';
import '../../../core/session/session_epoch.dart';
import '../../../core/utils/logger.dart';
import '../eld_endpoints.dart';
```
- **السلوك الحالي:** اعتراض HTTP — وهو البنية التحتية — يعتمد على `features/auth/data/datasources/auth_local_data_source.dart` (طبقة data كاملة، تشمل تخزين Keystore) وعلى كيان `features/auth/domain/entities/auth_session.dart`.
- **لماذا هو مشكل:** `AuthLocalDataSource` ليس عقدة (interface) بل **تنفيذ كامل** لطبقة data. بالتالي `AuthInterceptor` لا يعمل إلا مع `AuthLocalDataSource` حقيقي. والأسوأ: `AuthLocalDataSource` هو المكان الذي تعيش فيه سياسة تخزين الجلسة — وهي سياسة عالية المستوى التي يفترض أن `lib/backend` لا يعرفها.
- **المبدأ المنتهك:** Dependency Rule + Dependency Inversion (اعتماد concretes لا abstractions).
- **المالك الحالي:** `features/auth/data`. **المالك الصحيح:** عقدة في `lib/core/session/` — ولحسن الحظ `lib/core/session/session_epoch.dart` **موجود بالفعل**، فالجذر قائم والحدّ غائب.
- **العواقب:** لا يمكن اختبار `AuthInterceptor` بجلسة وهمية إلا بتبعية حقيقية على Keystore. استبدال سياسة تخزين الجلسة = تعديل `lib/backend`.
- **التصحيح المقترح:** تعريف `abstract interface class SessionStore { Future<AuthSession?> getSession(); int get credentialGeneration; }` داخل `lib/core/session/`، وتنفيذه في `features/auth/data`. يحوّل الاعتماد من concrete إلى abstraction دون تغيير سلوك.
- **الملفات ذات الصلة:** `auth_interceptor.dart`، `auth_local_data_source.dart`، `core/session/session_epoch.dart`، `backend_network_providers.dart:57`
- **Confidence:** CONFIRMED

### ISSUE BACK-010: `AuthBackend` يمرّر `backendType` ومفاتيح JSON الخام كواجهة، ولا يوجد تدفّق refresh
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/contracts/auth_backend.dart:5-10`
- **Evidence:**
```dart
// lib/backend/contracts/auth_backend.dart:4-16
abstract interface class AuthBackend {
  Future<Result<RawJson>> login({
    required String identifier,
    required String password,
    required String serverUrl,
    required String backendType,
  });

  Future<Result<RawJson>> validateSession({
    required String serverOrigin,
    required String sessionCredential,
    required String backendType,
  });
```
والاستهلاك الذي يثبّت المفاتيح كعقد ضمني:
```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart:60-64
        final sessionDto = AuthSessionDto.create(
          serverOrigin: rawJson['serverOrigin'],
          sessionCredential: rawJson['credential'],
          userModel: UserModel.fromMetadata(rawJson['user'], defaultEmail: identifier),
        );
```
- **السلوك الحالي:** ثلاث ملاحظات في عقدة واحدة.
- **(أ) `backendType`**: اسم تسمية داخلية (`eldEngine` / `mock`) يُمرَّر كـ required parameter في 3 تواقيع، رغم أن تعليق `eld_auth_backend.dart:27-28` يقرّ صراحةً بأنه **لا يختار أي تسجيل دخول ثانٍ**. فهو معامل ميت في العقد.
- **(ب) `RawJson`**: بنية `{'credential', 'user', 'serverOrigin'}` تصبح عقدًا ضمنيًا يفهمه `auth_repository_impl` (60-64). لو غيّر `EldAuthBackend` اسم مفتاح، ينكسر `features/auth` — مع أن العقد لم يتغير.
- **(ج) لا يوجد `refreshSession`**: بحثت في `lib/` بالكامل — لا يوجد أي use لـ `refreshToken`/`refresh_token` عدا الثابت `app_constants.dart:28` (`refreshTokenKey`) وهو غير مستخدم، و`request_logger.dart:26` (قائمة حجب). **التقييم: هذه ليست مخالفة** — نموذج ELD يعتمد على `JSESSIONID` (cookie)، فالتجديد التلقائي غير مطلوب؛ بل الفقدان الصحيح للجلسة عند 401 هو السلوك الصحيح. وتأكيدًا لذلك: `auth_interceptor.dart:120-141` يعالج 401 بثلاثة أجيال (sessionAttached / credentialGeneration / epoch) وهو تصميم متين.
- **المبدأ المنتهك:** (أ) و(ب): Interface Segregation + Explicit contracts.
- **المالك الحالي / الصحيح:** `contracts/auth_backend.dart` — لكن بأنواع مُحاطة (`SessionGrant`) وبدون `backendType`.
- **العواقب:** تسمية داخلية تسرّبت للواجهة؛ عقد ضمني غير مرئي في التوقيع؛ `app_constants.refreshTokenKey` عتاد ميت يوحي بمعمارية لا وجود لها.
- **التصحيح المقترح:** حذف `backendType` من التواقيع الثلاثة؛ إرجاع `Result<SessionGrant>` (domain) بدل `RawJson`؛ حذف `refreshTokenKey` من `app_constants.dart`.
- **الملفات ذات الصلة:** `auth_backend.dart`، `eld_auth_backend.dart`، `mock_auth_backend.dart`، `auth_repository_impl.dart`، `app_constants.dart:28`
- **Confidence:** CONFIRMED (أ، ب، عدم وجود ج) / تقييم معماري صريح: قرار (ج) تصميمي مقصود وليس مخالفة

### ISSUE BACK-011: `EldAuthBackend` يتجاوز `ApiClient` ويكرّر بناء العنوان وتطبيع URL
- **Severity:** MEDIUM
- **Category:** Dio
- **Location:** `lib/backend/adapters/eld_engine/sub/eld_auth_backend.dart:29-38`
- **Evidence:**
```dart
// eld_auth_backend.dart:24-26
      final baseUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;
```
```dart
// eld_auth_backend.dart:29-38
      final response = await _apiClient.dio.post(
        '$baseUrl/api${EldEndpoints.session}',
        data: {'email': identifier, 'password': password},
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
```
- **السلوك الحالي:** (1) يستخدم `_apiClient.dio` مباشرة بدل `_apiClient.post(...)`، متجاوزًا `ApiResponse.fromBody` و`error_mapper` الموحّدين. (2) يبني عنوانًا مطلقًا بـ `'${baseUrl}/api${EldEndpoints.session}'` — أي **نص `/api` مكتوب يدويًا في 4 مواضع** (30، 107، 156، 174) رغم أن `ApiConfig.baseUrl` أصلًا ينتهي بـ `/api` (مضمون في `backend_network_providers.dart:33-39`). (3) تطبيع URL هنا (24-26) **لا يضيف scheme**، بخلاف `BackendIdentity._normalizeUrl` (86-88) و`ApiConfig.normalized()` (68-70) اللذين يضيفان `https://`. (4) **لا يفرض TLS**.
- **لماذا هو مشكل:** في مسار المصادقة تحديدًا، تجاوز العميل الموحّد يعني فقدان `error_mapper` الموحد، واستخراج `ApiResponse`، وأي معالجة `expectedOwnerDriverId` منhigher. والأهم: **ثلاث نسخ مختلفة من تطبيع URL**، اثنتان منها تضيفان scheme وواحدة لا.
- **المبدأ المنتهك:** DRY + Centralized transport configuration.
- **العواقب:** خطر إرسال اعتماديات عبر HTTP صريح إذا أخطأ المستخدم؛ عدم اتساق في سلوك الأخطاء بين مسارات المصادقة؛ `/api` قد يتكرر.
- **التصحيح المقترح:** (1) نقل بناء العنوان إلى `ApiClient` كـ `postAbsolute(path, origin: serverUrl)`؛ (2) استخدام `ApiConfig.normalized()` بدل التطبيع المحلي؛ (3) رفض `http://` صراحةً في `EldAuthBackend.login` مع رسالة واضحة.
- **الملفات ذات الصلة:** `eld_auth_backend.dart`، `core/network/api_client.dart`، `core/network/api_config.dart:64-84`، `backend_network_providers.dart:33-39`
- **Confidence:** CONFIRMED (البنية) / POTENTIAL (خطورة TLS تعتمد على قيود input في شاشة الإعدادات — لم أقرأ `lib/features/settings` لأنها خارج النطاق)

### ISSUE BACK-012: `expectedOwnerDriverId` و`List<dynamic>` يتسرّبان من طبقة النقل إلى العقد
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/contracts/dvir_backend.dart:21-24`
- **Evidence:**
```dart
// lib/backend/contracts/dvir_backend.dart:21-24
  Future<Result<void>> create(
    RawJson report, {
    int? expectedOwnerDriverId,
  });
```
```dart
// lib/backend/contracts/driver_session_backend.dart:11-12
  /// GET /api/drivers
  Future<Result<List<dynamic>>> getAvailableDrivers();
```
الأصل المفهومي:
```dart
// lib/backend/http/interceptors/auth_interceptor.dart:41-45
  /// P0 2B-1 — المالك المتوقع لعملية الطابور (يضعه الـ dispatcher عبر
  /// ApiClient حصراً لطلبات المزامنة). عند الإرسال الفعلي يُقارن بجلسة
  /// اللحظة: أي اختلاف (تبديل جلسة أثناء الـ awaits السابقة) يرفض
  /// الطلب قبل مغادرة أي بايت — فلا ترث عملية قديمة جلسة جديدة أبداً.
  static const expectedOwnerKey = 'gf_expected_owner';
```
- **السلوك الحالي:** (أ) `expectedOwnerDriverId` وارد في **4 عقد** (`dvir_backend`, `daily_logs_backend`, `duty_status_backend`, `inspection_backend`) ويمرّ إلى `ApiClient` الذي يحوله إلى `extra['gf_expected_owner']`. (ب) `List<dynamic>` في توقيع عقد.
- **لماذا هو مشكل:** (أ) **سياسة تنفيذية** (منع عملية قديمة من وراثة جلسة جديدة) صارت **جزءًا من توقيع واجهة النطاق**. كل من يستدعي `dvir.create` عليه أن يعرف مفهوم الـ queue-dispatch. (ب) `List<dynamic>` يلغي أي ضمان نوع: المستهلك لا يستطيع الوصول إلى `id`/`name` بدون cast يدوي في كل مكان.
- **المبدأ المنتهك:** Interface Segregation + Information Hiding.
- **المالك الحالي:** `contracts/*`. **المالك الصحيح:** `ApiClient`/الاعتراض (المالك الفعلي الآن).
- **العواقب:** كل use-case جديد يختار `expectedOwnerDriverId` اعتباطًا؛Philosophyالمعرفة موزّعة على طبقتين.
- **التصحيح المقترح:** (أ) نقل `expectedOwnerDriverId` من توقيع العقدة إلى `ApiClient` وحده، مع API مختلف للمسارات التي تحتاج ربطًا (`dispatcherClient` مخصص). (ب) تعريف `DriverRef` (موجود أصلًا في `domain/duty_status`) كعنصر `List<DriverRef>`.
- **الملفات ذات الصلة:** `dvir_backend.dart`، `daily_logs_backend.dart`، `duty_status_backend.dart`، `inspection_backend.dart`، `driver_session_backend.dart`، `auth_interceptor.dart`، `core/network/api_client.dart:102,263-272`
- **Confidence:** CONFIRMED

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

### ISSUE BACK-014: المحوّل يحقن قيمة ناقصة في الاستجابة لإخفاء تعطّل العقد
- **Severity:** MEDIUM
- **Category:** ErrorHandling
- **Location:** `lib/backend/adapters/eld_engine/sub/eld_status_dashboard_backend.dart:84-89`
- **Evidence:**
```dart
// eld_status_dashboard_backend.dart:82-91
        .then((result) => result.mapValue(
          (response) {
            final json = response.data ?? const <String, dynamic>{};
            final map = Map<String, dynamic>.from(json);
            if (!map.containsKey('currentDutyStatus') || map['currentDutyStatus'] == null) {
              map['currentDutyStatus'] = status.wire;
            }
            return StatusDashboardMapper.fromDashboardJson(map);
          },
        ));
```
- **السلوك الحالي:** إذا رجعت استجابة الخادم بلا `currentDutyStatus` (انحراف عقد، أو 200 بجسم فارغ — وهو مسار مُعالَج في 53-80)، يقوم المحوّل **بملء القيمة من طلب العميل** ويُعيد نتيجة تبدو ناجحة.
- **لماذا هو مشكل:** التطبيق يعرض «حالة العمل الحالية»onto як的事实 المؤكَّد. لكن الحقيقة أن الخادم لم يؤكّدها. السائق يرى حالة واثقة وهي **مُختلَقة محليًا**. في نظام ELD متعلق بالامتثال، عرض حالة غير مؤكدة كموثوقة خطأ جسيم.
- **المبدأ المنتهك:** Fail loudly / Truthfulness.
- **المالك الحالي:** المحوّل. **المالك الصحيح:** نفس المحوّل، لكن مع **إشارة**: تسجيل + `ServerError` أو علم `unconfirmed` في `StatusDashboard`.
- **العواقب:** انحراف خادم غير مرئي؛ قد يُعرض سجل HOS اعتمادًا على قيمة لم يؤكدها الخادم.
- **التصحيح المقترح:** إضافة `bool confirmed` إلى `StatusDashboard` وضبطه `false` عند الحقن، وعرض مؤشر في الواجهة؛ أو إعادة `ServerError(code: 'eld.status_contract_violation')`.
- **الملفات ذات الصلة:** `eld_status_dashboard_backend.dart`، `status_dashboard_mapper.dart`، `lib/domain/duty_status/status_dashboard.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-015: تكرار `_asMap` في خمس مواضع بسلوكين مختلفين
- **Severity:** LOW
- **Category:** Duplication
- **Location:** `lib/backend/adapters/eld_engine/sub/eld_vehicle_backend.dart:23-28`
- **Evidence:**
```dart
// eld_vehicle_backend.dart:23-28
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        if (data is List) return {'items': data};
        throw const FormatException('vehicle list is not an object');
      },
```
```dart
// eld_vehicle_backend.dart:38-43
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        if (data is List) return {'items': data};
        return <String, dynamic>{};
      },
```
```dart
// eld_dvir_backend.dart:96-101
  RawJson _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }
```
```dart
// eld_unidentified_events_backend.dart:18-23
  RawJson _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }
```
```dart
// eld_inspection_backend.dart:81-86
  RawJson _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }
```
```dart
// eld_driver_session_backend.dart:29-33
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        throw const FormatException('co-driver body is not an object');
      },
```
- **السلوك الحالي:** نفس الدالة الحرفية في 3 ملفات، ونسختان lambda داخل `eld_vehicle_backend` — مع **اختلاف سلوكي مقصود**: نسخة `eld_vehicle_backend:27` **ترمي** `FormatException`، وبقية النسخ **تُعيد** `{}`. و`eld_driver_session_backend:32` نسخة سادسة ترمي بنص مختلف.
- **لماذا هو مشكل:** مساعدات تطبيع JSON **يجب** أن تكون متطابقة عبر كل المحوّلات وإلا صارت المقارنة بينها مستحيلة. وجود نسختين مختلفتين سلوكيًا في نفس الملف (`eld_vehicle_backend`) هو الدليل الأوضح.
- **المبدأ المنتهك:** DRY عبر حدود الملف.
- **العواقب:** تصحيح واحد يحتاج 6 تعديلات؛ انحراف سلوكي صامت عند تطبيق التصحيح.
- **التصحيح المقترح:** وضع `RawJson coerceToMap(Object? data, {bool throwOnNonObject})` في `mappers/json_primitives.dart` (المجلد موجود ومخصص للمساعدات المشتركة).
- **الملفات ذات الصلة:** `eld_vehicle_backend.dart`، `eld_dvir_backend.dart`، `eld_unidentified_events_backend.dart`، `eld_inspection_backend.dart`، `eld_driver_session_backend.dart`، `mappers/json_primitives.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-016: `accountProfileFixture` ثابت ميت (21 سطر بيانات)
- **Severity:** LOW
- **Category:** Maintainability
- **Location:** `lib/backend/adapters/mock/fixtures/account_fixtures.dart:12`
- **Evidence:**
```dart
// account_fixtures.dart:12-32
const accountProfileFixture = <String, dynamic>{
  'id': 101,
  'name': 'سعد بن محمد العتيبي',
  'email': 'driver101@eld.com',
  'phone': '+966501234567',
  'licenseNumber': 'TX-DL-123456',
  'licenseState': 'TX',
  'carrierName': 'Top Compliance Logistics LLC',
  'carrierUsdot': '1234567',
  'status': 'ACTIVE',
  'mainOfficeAddress': '100 Logistics Blvd, Dallas, TX 75001',
  'homeTerminalAddress': 'طريق الملك فهد، الرياض',
  'timezone': 'Asia/Riyadh',
  'language': 'ar',
  'availableLanguages': ['ar', 'en', 'es'],
  'odometer': 'mi',
  'availableOdometerUnits': ['mi', 'km'],
  'canEdit': false,
  'editRestrictionNotice':
      'لا يمكن تغيير معلومات الحساب إلا بواسطة مدير الأسطول',
};
```
- **السلوك الحالي:** تحققت بالبحث النصي: المستهلك الوحيد هو `accountMyAccountFixture` في `mock_account_backend.dart:16` و`:25`. `accountProfileFixture` لا يُقرأ من أي مكان في `lib/` ولا `test/`.
- **لماذا هو مشكل:** لا يُخالِف قاعدة معمارية، لكنه عقبة صيانة: ثابت بصيغة مختلفة (`timezone` لا `timeZone`، `licenseNumber`/`licenseState` لا `license` Map) يوحي بمسار بيانات كان موجودًا. ولاحظ التوثيق في 5-9: «المحاكي يعيد الحقول القانونية فقط» — وهو وصف لا يصف أي شيء مستخدم.
- **المبدأ المنتهك:** Dead code.
- **العواقب:** إغراء صيانة باستخدامه لاحقًا ← يكسر `MockAccountBackend` لأن `DriverAccount.fromJson` لا يتوقع تلك الصيغة (وهو بالضبط ما ينقصه! انظر BACK-019).
- **التصحيح المقترح:** حذفه وتحديث توثيق الملف؛ أو — وهو الأفضل — **استخدامه فعليًا** كـ fixture ثانٍ يغطي صيغة الـ API الخام (قبل `_mapAccountJson`)، فيصبح `mock_account_backend` يعكس تطبيع المحرك الحقيقي.
- **الملفات ذات الصلة:** `account_fixtures.dart`، `mock_account_backend.dart`، `eld_account_backend.dart:15-48`
- **Confidence:** CONFIRMED

### ISSUE BACK-017: `mock_adapter.dart` يحوي `@override` يتيمًا (أثر حذف)
- **Severity:** LOW
- **Category:** Maintainability
- **Location:** `lib/backend/adapters/mock/mock_adapter.dart:101-102`
- **Evidence:**
```dart
// mock_adapter.dart:98-107
  @override
  late final HardwareBackend hardware = MockHardwareBackend();

  @override

  // ==========================================================================

  @override
  Future<void> dispose() async {
    // Mocks hold only in-memory state; nothing to release.
  }
```
- **السلوك الحالي:** السطر 101 يحمل `@override` يتيمًا (لم يبقَ عضو يتبعه) بعد حذف عضو سابق. تحققت عمليًا: `flutter analyze lib/backend` ⇒ `No issues found!` — أي أن المحلل يتحمّله، لكنه **أثر حذف**.
- **لماذا هو مشكل:** ليس مخالفة معمارية (لا أبلّغه كـ HIGH)، لكنه دليل على أن الملف ليس مُراجَعًا بعد الحذف، ويُربك القارئ: يبدو كأن هناك getter ناقصًا.
- **المبدأ المنتهك:** وضوح المصدر.
- **العواقب:** تضليل قارئ؛ خطر أن يظن القارئ أن هناك getter ناقصًا.
- **التصحيح المقترح:** حذف السطر 101 (والأسطر الفارغة 102-104).
- **الملفات ذات الصلة:** `mock_adapter.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-018: توثيق `mock_adapter.dart` يناقض الواقع (17 عقدة مقابل 22 دالة)
- **Severity:** LOW
- **Category:** Maintainability
- **Location:** `lib/backend/adapters/mock/mock_adapter.dart:32-34`
- **Evidence:**
```dart
// mock_adapter.dart:30-36
/// In-memory backend for development, demos, and tests.
///
/// **Status in T1.8:**
/// - 2 contracts are fully mocked (account, statusDashboard).
/// - 17 contracts throw [UnimplementedError] (filled in Phase 2).
///
/// **Rule:** No network access. No timers. No platform channels.
```
- **السلوك الحالي:** الواقع (بعد قراءة الـ 13 mock sub-backend كاملة): عدد العقود **13**، منها عدد من الدوال منفَّذ، و**7 عقود** تحتوي `UnimplementedError`؛ بإجمالي **22 دالة غير منفَّذة من 58**. الوثيقة تقول «17 contracts».
- **لماذا هو مشكل:** التوثيق المعماري المنقوص أخطر من انعدامه، لأنه يُستخدم كمرجع لقرار «هل الموك جاهز؟».
- **المبدأ المنتهك:** Accurate documentation.
- **العواقب:** المطور يظن أن 17 عقدة معطّلة بينما 22 دالة كذلك؛ قرار «الموك كافٍ للتجربة» مبني على رقم خاطئ.
- **التصحيح المقترح:** تحديث التوثيق بالأرقام الفعلية، ويفضّل استبداله بتقرير يُولَّد آليًا من اختبار تناظر (انظر القسم C).
- **الملفات ذات الصلة:** `mock_adapter.dart`، كل ملفات `mock/sub/*`
- **Confidence:** CONFIRMED

### ISSUE BACK-019: الموك لا يمرّ بنفس تطبيع الحساب الذي يمرّ به المحرك الحقيقي
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_account_backend.dart:16`
- **Evidence:**
```dart
// mock_account_backend.dart:14-17
  @override
  Future<Result<DriverAccount>> getMyAccount({DriverId? driverId}) async {
    return ok(DriverAccount.fromJson(accountMyAccountFixture));
  }
```
مقابل المحرك الحقيقي:
```dart
// eld_account_backend.dart:15-16
  Map<String, dynamic> _mapAccountJson(Map<String, dynamic> json, {DriverId? fallbackDriverId}) {
    // 1. معالجة المعرف driverId
```
```dart
// eld_account_backend.dart:23-40
    if (json['license'] is String) {
      final licenseStr = json['license'] as String;
      final parts = licenseStr.split(',');
      final state = parts.isNotEmpty ? parts[0].trim() : '';
      final number = parts.length > 1 ? parts[1].trim() : licenseStr;
      
      json['license'] = {
        'state': state,
        'number': number,
        'formatted': licenseStr,
      };
    } else if (json['license'] == null) {
```
- **السلوك الحالي:** المحرك الحقيقي يطبّق 3 تحويلات قبل `fromJson` (driverId fallback، تحويل نص الرخصة `"MI, A350622298913"` إلى Map، توحيد `timezone`→`timeZone`). الموك يمرّر الـ fixture مباشرة.
- **لماذا هو مشكل:** الـ fixture الحالية مُصنوعة أصلًا بالشكل **بعد التطبيع** (`license` Map في `accountMyAccountFixture:39-43`، و`timeZone` في 64). أي أن الموك **يتجاوز تمامًا السلوك الذي صُمم لاختباره** — وهو في الواقع اختصار مسار التطبيع. عند فشل التطبيع في الإنتاج، لن يكتشفه أي اختبار يعمل على الموك.
- **المبدأ المنتهك:** Faithful test double.
- **العواقب:** مسار `_mapAccountJson` (26 سطرًا من منطق العمل) غير مغطى؛ بيانات الـ fixture الصحيحة تُخفي أخطاء التطبيع.
- **التصحيح المقترح:** (أ) نقل `_mapAccountJson` إلى مشترك في `mappers/account_mapper.dart` يناديه كلا المحوّلين، و(ب) إضافة fixture ثانٍ بصيغة **الخام** (`license` كنص + `timezone`) لاختبار التطبيع تحت الموك.
- **الملفات ذات الصلة:** `mock_account_backend.dart`، `eld_account_backend.dart`، `account_fixtures.dart`، `account_backend.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-020: 22 من 58 دالة عقد (≈38%) غير منفَّذة في الموك
- **Severity:** HIGH
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_unidentified_events_backend.dart:18`
- **Evidence:** العقد الوحيد بنسبة تنفيذ 0%:
```dart
// mock_unidentified_events_backend.dart:12-20
  @override
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    String? uniqueId,
    DriverId? driverId,
  }) =>
      throw UnimplementedError(
        'MockUnidentifiedEventsBackend.list — Phase 2',
      );
```
```dart
// mock_daily_logs_backend.dart:51-52
  @override
  Future<Result<RawJson>> getById(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.getById — Phase 2');
```
```dart
// mock_hardware_backend.dart:62-64
  @override
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    throw UnimplementedError('MockHardwareBackend.getStatus — not implemented');
  }
```
```dart
// mock_inspection_backend.dart:163-165
  @override
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId}) =>
      throw UnimplementedError('MockInspectionBackend.getInformationPacket — Phase 2');
```
```dart
// mock_driver_session_backend.dart:13-16
  Future<Result<RawJson>> getActiveSession(DriverId driverId) =>
      throw UnimplementedError(
        'MockDriverSessionBackend.getActiveSession — Phase 2',
      );
```
- **السلوك الحالي:** العدد الدقيق (بتفصيله الكامل في القسم C): `dailyLogs` 4/11، `driverSession` 4/5، `dutyStatus` 1/5، `dvir` 2/8، `hardware` 3/6، `inspection` 5/8، `unidentifiedEvents` 3/3 = **22 دالة**.
- **لماذا هو مشكل:** ليس مجرد نقص تغطية، بل **أن الموك ليس بديلاً**؛ البديل يفشل بصمت أو بانفجار حيث ينجح الأصل. والأثر مباشر في الإنتاج: `hardware_status_provider.dart:17` يستدعي `getStatus` من `presentation`؛ تحت الموك هذا `UnimplementedError` غير معالَج (لا `try/catch`، فقط `fold` على `Result`). النتيجة: **شاشة حالة الجهاز تنهار في وضع الموك**.
- **المبدأ المنتهك:** Liskov Substitution.
- **العواقب:** (أ) لا يمكن عرض شاشات DVIR/التفتيش/الأحداث غير المعرّفة تحت الموك. (ب) انهيار في `presentation` لا في `data`. (ج) الوعد في التوثيق («filled in Phase 2») تجاوزه الزمن.
- **التصحيح المقترح:** استراتيجيتان: (أ) **قابل للتبديل**: كل دالة غير منفَّذة ترجع `err(ServerError(code: 'mock.not_implemented', context: {'method': '...'})` بدل `throw` — يحوّل الانهيار إلى حالة خطأ معروضة. (ب) **اختبار تناظر آلي**: ملف اختبار يمرّ على كل عضو في `BackendAdapter` ويفحص `MockAdapter.<x>` عبر `try/catch` ويفشل إن رمى — فيصبح الرقم في القسم C مُراقَبًا في CI.
- **الملفات ذات الصلة:** كل ملفات `mock/sub/*`، `hardware_status_provider.dart`، `unidentified_events_provider.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-021: الموك يستخدم `DateTime.now()` رغم قاعدة «لا مؤقتات / حتمية» المعلنة
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_duty_status_backend.dart:13`
- **Evidence:**
```dart
// mock_duty_status_backend.dart:11-13
  @override
  Future<Result<RawJson>> record(RawJson event) async =>
      ok(<String, dynamic>{'id': DateTime.now().millisecondsSinceEpoch, ...event});
```
والقاعدة العامة المعلنة:
```dart
// mock_adapter.dart:36
/// **Rule:** No network access. No timers. No platform channels.
```
- **السلوك الحالي:** `id` المُعاد يعتمد على ساعة الجهاز الحقيقية.
- **لماذا هو مشكل:** (أ) يخالف القاعدة الصريحة. (ب) **يكسر الحتمية**: نفس `event` يعطي `id` مختلفًا في كل تشغيل، فأي اختبار يعتمد على `id` يصبح متذبذبًا. (ج) في نظام HOS، توليد معرّف اعتماد حالة من ساعة جهاز **غير موثوقة** (انظر BACK-033) قرار خاطئ في حد ذاته. (د) **`DateTime.now()` في طبقة backend يتجاوز `TrustedTimeProvider`** الموجود والمتاح.
- **المبدأ المنتهك:** Determinism + Single source of truth للوقت.
- **العواقب:** اختبارات متذبذبة؛ معرّفات غير قابلة للتنبؤ في العرض التوضيحي.
- **التصحيح المقترح:** تمرير `TrustedTimeProvider` (أو `FakeTrustedTimeProvider` في الاختبارات) إلى `MockDutyStatusBackend`، أو عداد تصاعدي `int _nextId = 1000;`.
- **الملفات ذات الصلة:** `mock_duty_status_backend.dart`، `mock_adapter.dart:36`، `core/time/trusted_time_provider.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-022: `MockHardwareBackend` يرمي داخل `async` فتتغير دلالة الخطأ
- **Severity:** MEDIUM
- **Category:** ErrorHandling
- **Location:** `lib/backend/adapters/mock/sub/mock_hardware_backend.dart:59-64`
- **Evidence:**
```dart
// mock_hardware_backend.dart:58-64
  @override
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    throw UnimplementedError('MockHardwareBackend.getStatus — not implemented');
  }
```
مقابل النسخة المتزامنة (سلوك مختلف عمدًا):
```dart
// mock_daily_logs_backend.dart:51-52
  @override
  Future<Result<RawJson>> getById(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.getById — Phase 2');
```
- **السلوك الحالي:** `getAlerts` (13)، `connectSession` (55)، `getStatus` (63) معلَّمة `async` وترمي **داخل** الجسم ⇒ `Future.error`. أما `mock_daily_logs` و`mock_dvir` و`mock_unidentified` و`mock_driver_session` فتستخدم `=> throw` المتزامنة.
- **لماذا هو مشكل:** في كلتا الحالتين يرمي الاستدعاء قبل الوصول إلى `fold` في المستهلك، لكن **التناقض أسلوبي يربك**: كأن أحدهم كتب `async` قصدًا أن يصير `Future`، أو نسي. dune dissatisfaction: `getStatus` يرمي بينما `getStatusProvider` في presentation لا يملك `try/catch` — في كلتا الحالتين هذا **انهيار**.
- **المبدأ المنتهك:** اتساق عقد معالجة الأخطاء.
- **العواقب:** سلوك مختلف ومربك لنفس الفكرة؛ دالة `async` بلا `await`.
- **التصحيح المقترح:** توحيد الأسلوب (الأفضل: `=> throw UnimplementedError(...)` متزامنًا كما في بقية الموكات) + تصحيح جذر: إرجاع `err(...)` بدل الرمي (BACK-020).
- **الملفات ذات الصلة:** `mock_hardware_backend.dart`، `mock_daily_logs_backend.dart`، `hardware_status_provider.dart`
- **Confidence:** CONFIRMED

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
- **لماذا هو مشكل:** هذا **يكشف أن الـ port ليس حدًا معماريًا**: الواجهة موجودة في `backend/contracts`، لكن **حدود الطبقات已经被 presentation أعدت اختراقها**. عمليًا: أسماء حقول الخادم (`json['data']`, `json['message']`, `json['hasPreviousDvir']`) تصل إلى الـ widgets. بين BACK-001 و BACK-023، **طبقة الـ port صارت شفافة**.
- **المبدأ المنتهك:** Dependency Rule — presentation يعتمد على domain فقط.
- **العواقب:** تغيير مفتاح في الخادم يكسر UI؛ منطق العمل (عدّ التبويبات، تفسير `hasPreviousDvir`) في presentation؛ اختبارات الواجهة تتطلب مزوّدات backend.
- **التصحيح المقترح:** لكل موقع من السبعة، إنشاء repository في `data/` + use-case في `domain/`، وربط presentation بالـ use-case فقط. **الأولوية:** `unidentified_events_provider` (3 دوال خام في presentation)، `hardware_status_provider` + `hardware_alerts_provider`.
- **الملفات ذات الصلة:** الملفات المذكورة أعلاه، `lib/backend/providers/backend_providers.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-024: قيم wire الخاصة بـ backend مسرّبة إلى طبقة العقد وإلى presentation
- **Severity:** MEDIUM
- **Category:** Coupling
- **Location:** `lib/backend/contracts/contract_enums.dart:45-51`
- **Evidence:**
```dart
// contract_enums.dart:45-51
enum DutyStatusAction {
  switchPrimary('switch-primary'),
  legacySwitch('legacy-switch');

  const DutyStatusAction(this.wire);
  final String wire;
}
```
```dart
// contract_enums.dart:37-43
enum UnidentifiedTab {
  unclaimed('UNCLAIMED'),
  rejected('REJECTED');
```
والاستهلاك في presentation:
```dart
// lib/features/logs/presentation/pages/unidentified_events_page.dart:6
import '../../../../backend/contracts/contract_enums.dart';
```
- **السلوك الحالي:** (أ) أسماء `DutyStatusAction` هي حرفيًا قيم Swagger: `'switch-primary'`، `'legacy-switch'` — ليست أسماء مفاهيمية بل أسماء مُعاملات. (ب) `UnidentifiedTab` قيمه `SCREAMING_SNAKE_CASE` مطابقة لتسمية الخادم. (ج) `presentation` يستورد `contract_enums.dart` مباشرة.
- **لماذا هو مشكل:** التسمية الجيدة لعقدة تجعل `DutyStatusAction.makePrimaryDriver` بدل `switchPrimary('switch-primary')`. الاسم الحالي **يقيد التصميم**: تغيير قيمة الخادم من `switch-primary` إلى `switch_to_primary` يجب أن يمسّ قيمة الـ enum — أو يدفع المطوّر لتغيير اسم الـ enum نفسه (وكل مستهلكيه)، وهو تغيير غير ضروري.
- **المبدأ المنتهك:** Naming as a design tool / Information hiding.
- **المالك الحالي:** العقدة. **المالك الصحيح:** التحويل (`wire`) يحدث حاليًا في المحوّل (`eld_unidentified_events_backend.dart:51`: `'tab': tab.wire`) — وهذا صحيح؛ المشكلة في اسم الـ enum نفسه وفي وصوله إلى presentation.
- **العواقب:** تعديل قيمة خادم = تعديل اسم كود في `presentation`. تهريب `backend/contracts` إلى UI.
- **التصحيح المقترح:** إعادة التسمية إلى أسماء سلوكية (`primaryDriverChange`, `legacySwitch`)، وإبقاء `wire` في المحوّل. ومنع استيراد `contracts/` من `presentation`.
- **الملفات ذات الصلة:** `contract_enums.dart`، `unidentified_events_page.dart`، `unidentified_events_provider.dart`، `codriver_repository_impl.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-025: `BackendAdapter` nullable + تحويل `null` إلى `StateError` في 13 مزوّدًا
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/core/backend_adapter.dart:28-31`
- **Evidence:**
```dart
// backend_adapter.dart:27-33
  // ==========================================================================
  // Contracts — all nullable (a backend may not support all features)
  // ==========================================================================

  AuthBackend? get auth;

  AccountBackend? get account;
```
والتحويل في كل مستهلك:
```dart
// backend_providers.dart:59-62
final authBackendProvider = Provider<AuthBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.auth ?? (throw StateError('AuthBackend not supported by active adapter'));
});
```
(يتكرر في 13 مزوّدًا: 61، 66، 71، 76، 81، 86، 91، 96، 101، 106، 111، 116).
- **السلوك الحالي:** الـ nullability **ليست** مرونة بل **غياب أنواع**. كلا المحوّلين ينفّذ **كل** الـ 14 getter كغير-null (`eld_engine_adapter.dart:52-93`، `mock_adapter.dart:56-99`)، فالـ `?` **لا يتحقق أبدًا**.
- **لماذا هو مشكل:** (أ) كل واحد من الـ 14 عقدة محاط بـ `?` — الـ compiler يسمح لـ `adapter.dvir!` في أي مكان. (ب) الاستبدال بـ `StateError` في 13 مكانًا يعني أن الكود **لا يستطيع معرفة** ما هي العقود غير المدعومة إلا بالتشغيل. (ج) **الغموض مستخدم فعليًا**: لا يوجد أي عقدة تُرجع null، فالثنائية «قد لا يدعم» وهمية.
- **المبدأ المنتهك:** Sound nullability / Honest type signatures.
- **العواقب:** 13× `StateError` غير معالَج أثناء بناء شجرة Riverpod. `throw` داخل Provider body يُنتج خطأ تحميل، لا حالة خطأ قابلة للتعامل.
- **التصحيح المقترح:** إمّا (أ) **اجعلها غير nullable**: `required DvirBackend get dvir;`، وافصل `supports(...)` إن لزم. أو (ب) إن كانت النية فعلًا أن يدعم backend ناقصًا، فالمسؤول عن الاستدعاء يجب أن يفحص قبل الاعتماد. **الاقتراح (أ)** هو الأنظف ويحذف 13 `throw`.
- **الملفات ذات الصلة:** `backend_adapter.dart`، `backend_providers.dart`، `eld_engine_adapter.dart`، `mock_adapter.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-026: تطبيع URL ثلاثي النسخ عبر طبقتين
- **Severity:** MEDIUM
- **Category:** Duplication
- **Location:** `lib/backend/core/backend_identity.dart:84-93`
- **Evidence:**
```dart
// lib/backend/core/backend_identity.dart:84-93
  static String _normalizeUrl(String url) {
    var normalized = url.trim();
    if (!normalized.contains('://')) {
      normalized = 'https://$normalized';
    }
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
```
```dart
// lib/core/network/api_config.dart:64-76
  ApiConfig normalized() {
    var normalizedUrl = baseUrl.trim();

    // Ensure scheme
    if (!normalizedUrl.contains('://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }

    // Remove trailing slash(es)
    while (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }
```
```dart
// lib/backend/providers/backend_network_providers.dart:30-39
  var effectiveUrl = serverUrl.isNotEmpty ? serverUrl : coreConfig.baseUrl;

  // ضمان أن الرابط يحتوي على /api
  if (effectiveUrl.isNotEmpty && !effectiveUrl.endsWith('/api')) {
    // إزالة أي / زائدة من النهاية
    while (effectiveUrl.endsWith('/')) {
      effectiveUrl = effectiveUrl.substring(0, effectiveUrl.length - 1);
    }
    effectiveUrl = '$effectiveUrl/api';
  }
```
- **السلوك الحالي:** ثلاث نسخ من «تطبيع الرابط»، أول اثنتان متطابقتان حرفيًا، والثالثة **تُطبِّق بعد** ولا تتصل بالأولتين إطلاقًا.
- **لماذا هو مشكل — الإجابة المباشرة على سؤال ازدواج `api_config`:** لا يوجد ازدواج **في** `lib/backend/http/api_config.dart` — الملف **كله تعليقات** (7 أسطر، DEPRECATED، لا يستورده أحد). **الازدواج الحقيقي موجود في مكان آخر**: تطبيع الرابط مكرر ثلاث مرات وموزَّع على **طبقتين** (`core/network` و`backend/core`). أما **الـ endpoints** فمصدرها **واحد** (`eld_endpoints.dart`) — لا ازدواج. والـ **timeouts** في **مكان واحد** (`ApiConfig` 38-40) — لا ازدواج هناك أيضًا. إذن: **لا ازدواج في base-URL/timeout بين الملفين؛ الازدواج في تطبيع URL فقط.**
- **المبدأ المنتهك:** DRY / Single source of truth للإعداد.
- **العواقب:** التصحيح في `BackendIdentity` لا يصل إلى `ApiClient`. النسخة الثالثة تفترض `/api` ثابتة وتُضيفها حتى لو لم تُطلب. سلوك غير متوقع إذا أدخل المستخدم `https://host/api/v2`.
- **التصحيح المقترح:** `ApiConfig.normalized()` هو المكان الطبيعي؛ `BackendIdentity` يجب أن يستقبل `baseUrl` **مُطبَّعًا** (لا يعيد التطبيع)، و`backend_network_providers` يجب أن يستدعي `normalized()` بدل الحلقة اليدوية.
- **الملفات ذات الصلة:** `backend_identity.dart:84-93`، `core/network/api_config.dart:64-84`، `backend_network_providers.dart:30-46`
- **Confidence:** CONFIRMED

### ISSUE BACK-027: `BackendRegistry` (129 سطرًا) بلا أي مستهلك إنتاجي
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/core/backend_registry.dart:17`
- **Evidence:**
```dart
// backend_registry.dart:78-100
  /// The currently active adapter.
  ///
  /// This is what features access.
  BackendAdapter get active => _adapters[activeIdentity.id]!;

  /// Returns the adapter with the given [id], or `null` if missing.
  BackendAdapter? getById(String id) => _adapters[id];

  /// Returns the adapter matching the given [identity], or `null`.
  BackendAdapter? getByIdentity(BackendIdentity identity) =>
      _adapters[identity.id];

  /// All registered adapters.
  Iterable<BackendAdapter> get all => _adapters.values;

  /// Whether an adapter with the given [id] is registered.
  bool has(String id) => _adapters.containsKey(id);

  /// The number of registered adapters.
  int get length => _adapters.length;

  /// Whether this registry contains only a mock adapter.
  bool get isMockOnly => _adapters.values.every((a) => a.isMock);
```
الاستهلاك الوحيد في `lib/`:
```dart
// backend_providers.dart:27-29
final backendRegistryProvider = Provider<BackendRegistry>((ref) {
  return BackendRegistry.single(ref.watch(activeBackendProvider));
});
```
- **السلوك الحالي:** بحثت في `lib/` بالكامل: `BackendRegistry` يظهر **فقط** في `backend_registry.dart` و`backend_providers.dart:27-28`. **لا يوجد أي مستهلك لـ `backendRegistryProvider`**. أي: `getById`، `getByIdentity`، `all`، `has`، `length`، `isMockOnly`، `disposeAll` — **سبعة أعضاء، صفر استدعاء إنتاجي**. و`single()` (71) يُلغي تمامًا تعدد الـ adapters الذي تبرره الترويسة (10-13).
- **لماذا هو مشكل:** هذا هو السؤال المطلوب («هل `BackendAdapter`/`backend_registry` تجريد حقيقي أم زخرفي؟»): **الإجابة: `BackendAdapter` حقيقي و`BackendRegistry` زخرفة**. الأول مُستخدم فعليًا (13 getter تُستهلك في 13 provider)، والثاني مصنع لا يحتاجه أحد.
- **المبدأ المنتهك:** YAGNI / Dead abstraction.
- **العواقب:** 129 سطرًا + ملف اختبار معزول (`test/backend/core/backend_registry_test.dart`) تُصان بلا فائدة؛ توثيق يَعِد ("قد تحتاج عدة backends") لا يتحقق.
- **ملاحظة أمانة:** يوجد `test/backend/core/backend_registry_test.dart` (10 إشارات) — أي أنه **مُختبر في عزلة** لا مستهلَك. لذلك بدقة: ليس بلا أي استخدام، بل **بلا أي استخدام إنتاجي**.
- **التصحيح المقترح:** حذف `BackendRegistry` و`backendRegistryProvider` بالكامل، والاكتفاء بـ `activeBackendProvider` من النوع `BackendAdapter`. إن كان التوسع المستقبلي مرغوبًا، يُعاد إحياؤه عند الحاجة الفعلية.
- **الملفات ذات الصلة:** `backend_registry.dart`، `backend_providers.dart:27-29`، `backend_adapter.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-028: ملفّا `lib/backend/http/api_config.dart` و`api_response.dart` ميتان بالكامل
- **Severity:** LOW
- **Category:** Maintainability
- **Location:** `lib/backend/http/api_config.dart:1-7`
- **Evidence:** الملف بأكمله:
```dart
// lib/backend/http/api_config.dart:1-7
// /// HTTP configuration for the ELD backend.
// ///
// /// **DEPRECATED**: This file is kept for backward compatibility.
// /// Please import `lib/core/network/api_config.dart` directly instead.
// library;

// export '../../core/network/api_config.dart';
```
```dart
// lib/backend/http/api_response.dart:1-7
// /// Unified HTTP response wrapper.
// ///
// /// **DEPRECATED**: This file is kept for backward compatibility.
// /// Please import `lib/core/network/api_response.dart` directly instead.
// library;

// export '../../core/network/api_response.dart';
```
- **السلوك الحالي:** لا يستوردهما أي كود (تحققت). الملفان **لا يولّدان أي رمز** (حتى `library;` معطّل) — أي أنهما ملفان نصّيان.
- **لماذا هو مشكل:** «kept for backward compatibility» بلا مستهلك = لا شيء maintained له توافق. وجودهما يربك البحث عن إعداد HTTP ويوحي بأن هناك مصدرين. **ملاحظة مهمة:** هذا **ليس** ازدواجًا فعليًا (انظر BACK-026)؛ هو **بقايا ميتة**.
- **العواقب:** ارتباك؛ احتمال أن يضيف مطوّر كودًا جديدًا ملفًا بلا فائدة.
- **التصحيح المقترح:** حذف الملفين.
- **الملفات ذات الصلة:** `lib/backend/http/api_config.dart`، `lib/backend/http/api_response.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-029: `EldEndpoints` مبني على `int`/`String` الخام بينما العقدة تستخدم Value Objects
- **Severity:** LOW
- **Category:** Architecture
- **Location:** `lib/backend/http/eld_endpoints.dart:53`
- **Evidence:**
```dart
// eld_endpoints.dart:53-55
  static String dailyLogDetails(int logId) => '/eld/daily-logs/$logId';
  /// الرد على تعديلات الناقل
  static String respondCarrierEdit(int logId, String editId) => '/eld/daily-logs/$logId/carrier-edits/$editId/respond';
```
و18 موقعًا آخر بنفس النمط (57، 59، 61، 63، 65، 67، 69، 73، 75، 88، 90، 98، 101، 105، 107، 109، 133، 135). بينما العقدة تستخدم:
```dart
// daily_logs_backend.dart:24
  Future<Result<RawJson>> getById(DailyLogId logId);
```
والاستدعاء يتطلب `.value` يدويًا في كل موقع:
```dart
// eld_daily_logs_backend.dart:49
      EldEndpoints.dailyLogDetails(logId.value),
```
- **السلوك الحالي:** طبقة الـ endpoints تتوقف عند النوع البدائي، والنقاط تتوقف عند value object. `domain/shared/value_objects.dart` (المستوردة في كل عقدة) **لا تُستخدم في بناء المسار**.
- **لماذا هو مشكل:** الفصل بين الطبقتين لا يبرّر تجاهل أنواع النطاق: `EldEndpoints` في طبقة `http/` (الأدنى) يستطيع استيراد `domain/shared` كما تفعل المحوّلات. النتيجة: **≈20 استدعاء `.value` يدوي**، ولكل منها فرصة نسيان. في DVIR مثلًا: `DvirId.value` في 3 مواضع (73، 88، 100) — احتمال خلط `dvirId.value` مع `statusId.value` في نفس الاستدعاء لا يلتقطه الـ compiler.
- **المبدأ المنتهك:** Type safety at boundaries.
- **العواقب:** أخطاء نوعية في وقت التشغيل لا وقت الترجمة.
- **التصحيح المقترح:** جعل `EldEndpoints` يقبل الأنواع المحاطة مباشرة بعد إضافة `toString()` تُعيد القيمة في `DailyLogId`/`DvirId`/`EditId`/`DutyStatusId` — عندها تُحذف كل استدعاءات `.value`.
- **الملفات ذات الصلة:** `eld_endpoints.dart`، `lib/domain/shared/value_objects.dart`، كل `eld_*_backend.dart`
- **Confidence:** CONFIRMED

### ISSUE BACK-030: توثيق `AuthInterceptor` يبالغ في ضمان الذرّية عبر `await`
- **Severity:** LOW
- **Category:** Security
- **Location:** `lib/backend/http/interceptors/auth_interceptor.dart:68-73`
- **Evidence:**
```dart
// auth_interceptor.dart:68-76
    // P0 2B-1 — قراءة جلسة واحدة لكل طلب: كل ما بعدها متزامن بحت
    // داخل نفس الـ microtask (أحادي الخيط: لا تداخل ممكن)، فيكون قرار
    // الإرفاق والتحقق من المالك ذرياً بالنسبة لتغيرات الجلسة.
    AuthSession? session;
    try {
      session = await localDataSource.getSession();
    } catch (e) {
      AppLogger.error('AuthInterceptor failed to read session for $backendType: $e');
    }
```
- **السلوك الحالي:** التعليق يدّعي أن القراءة + «كل ما بعدها متزامن» تُنتج قرارًا ذريًا. لكن `await localDataSource.getSession()` **يُنهي الـ microtask**، فبين خروجه وعودته (قراءة Keystore = I/O غير متزامن) يمكن أن يتغيّر مراقب الجلسة.
- **لماذا هو مشكل:** **هذا ليس خطأً مؤكدًا** — بعد `await` يعود التنفيذ، وكل الأسطر التالية (80-115) متزامنة فعلًا، فالكود يفعل ما يقول. لكن الاعتماد على «أحادي الخيط» غير كافٍ حين تكون القراءة نفسها غير متزامنة: الضمان الصحيح هو **snapshot** لا **تنفيذ متزامن**. عمليًا الخطر محدود لأن `credentialGeneration` (59، 122-129) يلتقط جيل الاعتماد **قبل** الـ await — وهذا **يحل** الحالة الفعلية.
- **المبدأ المنتهك:** دقة التوثيق للضمانات (SOLID على مستوى التوثيق).
- **التقييم:** finding بصيغة **POTENTIAL** لا CONFIRMED كخلل أمني: الحماية الفعلية (`credGenKey`) سليمة ومُتحقَّق منها في `onError`. المشكلة **توصيفية**.
- **التصحيح المقترح:** إعادة صياغة التعليق 68-70 لتذكر أن الحماية الحقيقية هي `credGenKey` (المأخوذ قبل الـ await) و`epochKey`، وأن الذرّية بعد الـ await تسبقها خطوة snapshot فقط.
- **الملفات ذات الصلة:** `auth_interceptor.dart`، `lib/core/session/session_epoch.dart`
- **Confidence:** POTENTIAL

### ISSUE BACK-031: استثناء مسار إنشاء الجلسة بمقارنة `options.path == '/session'` لا يتحقق مع المسارات المطلقة
- **Severity:** MEDIUM
- **Category:** Security
- **Location:** `lib/backend/http/interceptors/auth_interceptor.dart:64`
- **Evidence:**
```dart
// auth_interceptor.dart:60-66
    // لا نستثني إلا نقطة إنشاء الجلسة نفسها؛ contains('/session') كانت
    // تخطّي أي مسار يحتوي الكلمة (مثل /eld/sessions/123/members).
    // (حُذف استثناء POST /users — لم يعد له مستدعٍ وكان يسمح بمرور
    // طلبات إنشاء مستخدمين بلا جلسة، توسيعاً غير مبرر لسطح الهجوم.)
    if (options.path == EldEndpoints.session) {
      return super.onRequest(options, handler);
    }
```
بينما الاستدعاءات تمرّ بمسارات مطلقة:
```dart
// eld_auth_backend.dart:29-31
      final response = await _apiClient.dio.post(
        '$baseUrl/api${EldEndpoints.session}',
        data: {'email': identifier, 'password': password},
```
```dart
// eld_auth_backend.dart:106-107
      final response = await _apiClient.dio.get(
        '$serverOrigin/api${EldEndpoints.session}',
```
```dart
// eld_auth_backend.dart:156
      await _apiClient.dio.delete('$serverOrigin/api${EldEndpoints.session}', options: options);
```
- **السلوك الحالي:** الشرط يقارن `options.path` بـ `'/session'` (نسبة). لكن في المسارات الثلاثة أعلاه، `path` المُمرَّر إلى `dio` هو `'$baseUrl/api/session'` — **مطلق** — فلا يساوي `'/session'` أبدًا.
- **الأثر الفعلي:** الاستثناء لا يتحقق في `login` ولا `validateSession` ولا `logout`. في `login` (30) لا نريد كوكيًا أصلًا — لكن `getSession()` ستُقرأ، وعندها تحاول الشيفرة إرفاق `JSESSIONID` القديم بـ cookie على **نفس المضيف** (لأن `requestHost == baseHost`)، فيُرسل مع طلب إنشاء جلسة جديد. نفس الشيء في `logout`: يُرفَق كوكي مع طلب الإبطال.
- **لماذا هو مشكل:** حارس أمني مكتوب بافتراض `path` نسبي بينما الاستدعاء الفعلي مختلط. هذا نمط هشّ: أول من يغيّر بناء العنوان إلى نسبي (أو يضيف مسارًا) ينكسر صامتًا.
- **المبدأ المنتهك:** Correctness of a security guard.
- **خطورة الأثر:** منخفضة عمليًا (نفس المضيف، والتشويش فقط)، لكن المبدأ معطوب.
- **التصحيح المقترح:** استخدام `options.uri.path.endsWith('/api/session')`، أو — الأنظف — `options.extra['skip_session'] = true` يضعه `EldAuthBackend` صراحةً بدل الاستدلال من المسار.
- **الملفات ذات الصلة:** `auth_interceptor.dart`، `eld_auth_backend.dart`، `eld_endpoints.dart:15`
- **Confidence:** CONFIRMED

### ISSUE BACK-032: `request_logger` يطبع جسم الخطأ الخام بلا إخفاء (مقيّد بـ kDebugMode)
- **Severity:** LOW
- **Category:** Security
- **Location:** `lib/backend/http/interceptors/request_logger.dart:128-130`
- **Evidence:**
```dart
// request_logger.dart:96-130
    if (err.response?.data != null) {
      final data = err.response?.data;
      if (data is String) {
        ...
        } else {
          AppLogger.error('Data: ${data.length > 500 ? '${data.substring(0, 500)}...' : data}');
        }
      } else {
        AppLogger.error('Data: $data');
      }
    }
```
والإخفاء المطبَّق على الطلب والاستجابة:
```dart
// request_logger.dart:61-66
    if (response.data != null &&
        (response.requestOptions.uri.path.contains('/sessions') ||
            response.requestOptions.uri.path.contains('/drivers'))) {
      AppLogger.debug(
        '📦 Response data: ${_redactSensitiveData(response.data)}',
      );
    }
```
والتقييد بوضع التصحيح:
```dart
// backend_network_providers.dart:67
  if (kDebugMode) dio.interceptors.add(RequestLogger());
```
- **السلوك الحالي:** `RequestLogger` كله **مقيَّد بـ `kDebugMode`** (سطر 67) — وهذا **إنجاز أمني حقيقي**، لأن `AppLogger.error` يُكتب في الإنتاج (`logger.dart:30-32` يمرّر إلى `package:logger` الذي يُخرج `Level.info` فأعلى في release). **فلا يوجد تسرب PII في الإنتاج.**
- **لكن:** (أ) مسار `onError` (128-130) يطبع `$data` **بلا `_redactSensitiveData`** عندما يكون الجسم `Map` (وهو الافتراضي في Dio لـ JSON) — أي أن أجسام خطأ JSON تُطبع كما هي. (ب) `sensitiveKeys` (21-37) حجب **مفاتيح** فقط؛ قائمة `List<String>` أو نص خام يمرّ بلا حجب. (ج) شرط الاستجابة (61-63) يستهدف `/sessions` و`/drivers` — **أعلى مسارات PII** — بينما أجسام أخطاء DVIR/التفتيش/القيادة تُطبع بلا حجب.
- **لماذا هو مشكل:** في debug، على جهاز سائق في يد موظف، `flutter logs` يكشف أسماء وبيانات تشغيلية. ليس production leak لكنه **تسريب في بيئة التطوير/QA**.
- **المبدأ المنتهك:** Defense in depth.
- **العواقب:** كشف PII في سجلات التطوير؛ ضخامة السجلات (500 حرف لكل خطأ).
- **التصحيح المقترح:** (1) تمرير `_redactSensitiveData(err.response?.data)` في السطر 129. (2) توسيع `sensitiveKeys` بـ `'name','email','phone','license','vin','latitude','longitude','signature'`. (3) تخفيض سقف 500 إلى 200.
- **الملفات ذات الصلة:** `request_logger.dart`، `backend_network_providers.dart:67`، `core/utils/logger.dart:30`
- **Confidence:** CONFIRMED

### ISSUE BACK-033: سلسلة ثقة الوقت بلا تحقق من القيمة ولا opt-out لكل طلب
- **Severity:** MEDIUM
- **Category:** Security
- **Location:** `lib/backend/http/interceptors/time_drift_interceptor.dart:38-66`
- **Evidence:**
```dart
// time_drift_interceptor.dart:50-65
    final lastServer = _lastServerUtc;
    final lastAnchor = _lastAnchorLocal;
    if (lastServer != null && lastAnchor != null) {
      final now = DateTime.now().toUtc();
      final expected = lastServer.add(now.difference(lastAnchor));
      final drift = serverUtc.difference(expected).abs();
      if (drift < _driftTolerance &&
          now.difference(lastAnchor) < _minResyncInterval) {
        return;
      }
    }

    timeProvider.anchor(serverUtc);
    _lastServerUtc = serverUtc;
    _lastAnchorLocal = DateTime.now().toUtc();
```
و`anchor()` نفسها بلا تحقق:
```dart
// core/time/trusted_time_provider.dart:107-113
  @override
  void anchor(DateTime serverUtc) {
    _trustedServerUtcAtSync = serverUtc.toUtc();
    _restoredFromDisk = false;
    _restoredAnchorUtc = null;
    _restoredDeviceWallMs = null;
```
والاعتراض مربوط بالـ Dio **المشترك** بلا استثناء:
```dart
// backend_network_providers.dart:69-71
  dio.interceptors.add(
    TimeDriftInterceptor(timeProvider: ref.read(trustedTimeProvider)),
  );
```
- **السلوك الحالي — أربع ثغرات في سلسلة الثقة:**
  1. **لا تحقق من القيمة إطلاقًا**: `anchor()` يقبل أي `DateTime`. خادم يُرجع `Date: Mon, 01 Jan 1990...` أو `Sat, 01 Jan 2050...` يُثبّت ساعة الامتثال. الفحص الوحيد هو **تكرار** (throttling)، لا **صحة**.
  2. **الاستجابة الأولى غير محمية**: عند `lastServer == null` (50-51) يُثبَّت أي وقت بلا مقارنة؛ منطق الـ drift (52-60) لا يعمل إلا بعد أول مرساة.
  3. **أي مضيف**: `EldAuthBackend.login` يرسل إلى **عنوان يختاره المستخدم** (`'$baseUrl/api${EldEndpoints.session}'`) على نفس الـ Dio، فـ `Date` من مضيف غير موثوق يثبّت ساعة HOS. لا يوجد `Options.extra` يمنع ذلك.
  4. **الاستجابات الخطأ تُعالَج عمدًا** (31-36) — وهذا منطقي (الفرصة الوحيدة للمعايرة)، لكنه يوسّع سطح الهجوم: خادم يرد `401` بترويسة `Date` خبيثة يثبّت الساعة.
- **لماذا هو مشكل:** `TrustedTimeProvider` **مرجع الامتثال** (تواريخ HOS تُوقَّع به). في نظام ELD، تلاعب بالوقت = تفتيش فاشل. وبنية `MonotonicTrustedTimeProvider` تُخزّن المرساة على القرص (`trusted_time_provider.dart:115-120`) وتستعيدها عند الإقلاع لأيام — أي أن **مرساة واحدة سيئة تفسد 7 أيام** (وهو ما يعلنه `state` في 93-95).
- **المبدأ المنتهك:** Trust chain / Least privilege / Input validation عند حدود الثقة.
- **المالك الحالي:** `TimeDriftInterceptor` + `MonotonicTrustedTimeProvider`. **المالك الصحيح:** `TrustedTimeProvider` يجب أن يكون **المُتحقِّق** (validate + clamp)، والاعتراض مجرّد ناقل.
- **العواقب:** استضافة خبيثة → إزاحة ساعة الامتثال لأيام → تواريخ سجلات HOS خاطئة → مخالفة تنظيمية.
- **التصحيح المقترح:** (1) في `MonotonicTrustedTimeProvider.anchor()`: رفض `serverUtc` إذا كان أبعد من ±24 ساعة عن `DateTime.now()` (باستثناء أول مزامنة صريحة)؛ (2) في `TimeDriftInterceptor`: تخطّي الاستجاعات التي `err.requestOptions.uri.host != baseUrl.host` (أو مسارات `login`)، إلا إذا كانت مزامنة صريحة؛ (3) إضافة حد أقصى للقفز الأمامي؛ (4) تسجيل `TrustedTimeState` بعد كل مرساة لتشخيصها.
- **الملفات ذات الصلة:** `time_drift_interceptor.dart`، `core/time/trusted_time_provider.dart`، `backend_network_providers.dart:69-71`، `eld_auth_backend.dart:30`
- **Confidence:** CONFIRMED

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

### ISSUE BACK-035: `mock` يعتمد على تحويلات `eld_engine` — الموك ليس بديلاً مستقلاً
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_rules_screen_backend.dart:7-8`
- **Evidence:**
```dart
// mock_rules_screen_backend.dart:7-8
import '../../eld_engine/models/rules_screen_dto.dart';
import '../../eld_engine/mappers/rules_screen_mapper.dart';
```
```dart
// mock_daily_logs_backend.dart:5-6
import '../../eld_engine/models/certify_dto.dart';
import '../../eld_engine/models/readiness_dto.dart';
```
- **السلوك الحالي:** **4 ملفات** من مجلد `mock/` تستورد من مجلد `eld_engine/`. المحوّلان داخل نفس `BackendAdapter` لكن في فرعين مختلفين من الشجرة، وأحدهما يعتمد على الآخر.
- **لماذا هو مشكل:** الموك موجود ليختبر سلوكًا معزولًا عن المحرك الحقيقي. بجعل الموك يستخدم DTOات ومحوّل المحرك الحقيقي، صار: (1) الاختبار على الموك **لا يختبر العزل** بل يختبر المحرك عبر مسار بديل؛ (2) **تعديل DTO في `eld_engine` يكسر `mock`** — فالفصل البنيوي بين المحوّلين غير قائم؛ (3) الرسم البياني لطبقات الاعتمادية لم يعد شجريًا.
- **المبدأ المنتهك:** Parallel implementations / ISP.
- **العواقب:** إعادة استخدام DTOات (وهي الحل الصحيح لـ BACK-004) **ستُصلح** هذه المشكلة تلقائيًا، لأن DTO ستصبح في `contracts/dto/` ولا يبقى داعٍ للاستيراد العابر.
- **التصحيح المقترح:** نقل `certify_dto.dart`، `readiness_dto.dart`، `rules_screen_dto.dart`، `rules_screen_options.dart`، و`rules_screen_mapper.dart` إلى `lib/backend/contracts/dto/` + `lib/backend/contracts/mappers/` مشتركين. **تغيير واحد يحل BACK-004 و BACK-035 و BACK-002 جزئيًا.**
- **الملفات ذات الصلة:** `mock_rules_screen_backend.dart`، `mock_daily_logs_backend.dart`، `eld_engine/models/*`، `contracts/daily_logs_backend.dart`
- **Confidence:** CONFIRMED

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

**لا يوجد import دائري حقيقي داخل `lib/backend`** — تحققت من الرسم البياني: `contracts → adapters/eld_engine/models` ثم `models → (لا شيء)`، و`adapters/mock → adapters/eld_engine` ثم `eld_engine → contracts`؟ لا: `eld_engine/sub/*` يستورد `contracts/*`، و`contracts/*` لا يستورد أي `sub/*`.所以 لا دورة import فعلية؛ المشكلة **اتجاه** وليس **دورة**.

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
- **يمحو一切 انحرافات الـ wire بصمت**: جسم من نوع `List` أو `String` يُستبدل بـ `{}`، فيُبلَّغ，消费者 كـ «نجاح» بجسم فارغ. مثال ملموس: `eld_daily_logs_backend.dart:41` يحوّل `List` إلى `{'data': data}` — لكن `eld_dvir_backend.dart:34` يفعل الشيء نفسه. هذا يعني أن **`RawJson` لا يحمل أي ضمان شكل**، وهو ما جعل BACK-008 ممكنًا.
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
