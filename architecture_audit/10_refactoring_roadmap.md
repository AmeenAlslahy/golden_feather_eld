# 10 — خارطة الطريق الآمنة لإعادة الهيكلة (Safe Refactoring Roadmap)

> **تنبيه:** هذا المستند **خطة مقترحة فقط**. لم يُنفَّذ أي تغيير على أي ملف مصدري.
> الأولوية مبنية على: (1) أثر البيانات/الامتثال، (2) عدد الملفات المتأثرة، (3) علاقة الاعتماد، (4) تعقيد التنفيذ، (5) قدرة الاختبار على الحماية.

---

## المبدأ الحاكم

**لا إعادة كتابة.** المشروع يملك بنية صالحة أساساً (نطاق نقي 8/9، `Dio` واحد، جذر DI مركزي، م(domain)apters متماسكة). الهدف **إغلاق التسرّبات** لا إعادة البناء. أي خطوة تُعيد ترتيب جذر المشروع بلا حاجة هي فقد لا استثمار.

كذلك: **لا يُقترح إضافة Use Cases أو واجهات جديدة.** السجل يوصي بـ**حذف** التجريدات الفارغة القائمة، لا بإضافة غيرها.

---

## المراحل الخمس

### المرحلة 0 — إيقاف النزيف (لا تغيير سلوك، يوم واحد)

كل بند هنا **إصلاح خلل قائم**، لا تحسين معماري. لا يعتمد على أي مرحلة لاحقة.

| # | الإجراء | الملاحظات | السطر | لماذا أول |
|---|---|---|---|---|
| 0.1 | إضافة `return` بعد `AppLogger.warning` | HL-15 | `duty_status_tracker.dart:417-420` | قاعدة قانونية مكتوبة وغير منفّذة — إصلاح سطر واحد |
| 0.2 | كاش DVIR وcodriver `static` → instance + تبديل على `sessionEpoch` | DST-002, COD-001 | `inspection_repository_impl.dart:28-32`, `codriver_repository_impl.dart:17-18` | تسريب سجلات نظامية بين سائقين على جهاز مشترك |
| 0.3 | توحيد مفتاح استجابة DVIR بين `eld_engine` و`mock` | BACK-008 | `mock_dvir_backend.dart:20`, `dvir_repository_impl.dart:54` | Environmental موك يحذف DVIR بصمت |
| 0.4 | إضافة فرع `Exception` في `anyErrorUserMessage` | ACC-003 | `rules_screen_provider.dart:22` | كل أخطاء القواعد تظهر كخطأ شبكة |
| 0.5 | إزالة `developerBypassDrivingScreenProvider` من كود الإنتاج | HOM-002 | `home_page.dart:24` | تعطيل قفل القيادة FMCSA غير مقيّد |
| 0.6 | تصحيح `TrackingService` المزدوج / توحيد المزوّد | CORE-005, DST-037 | `tracking_providers.dart:22,41`, `app_initializer.dart:91` | الـ override المخصص للإقلاع لا يسري |
| 0.7 | `.env` من تتبّع git + تدوير أي credential مُتسرّب | CORE-015 | `.gitignore`, `app_environment.dart:29,84-89` | أمني، لا وصلة |
| 0.8 | إصلاح استثناء مسار الجلسة في `AuthInterceptor` | BACK-031 | `auth_interceptor.dart:64` | مقارنة `'/session'` لا تتحقق مع مسار مطلق |
| 0.9 | تغيير `HttpClient()` الخام إلى `ApiClient` + إغلاق العميل | CORE-016 | `push_notification_service.dart:136` | تجاوز كامل لشبكة DI، و`HttpClient` لا يُغلق |

**الملفات المتأثرة:** 9.
**خطر الانحدار:** منخفض جداً (0.1–0.5 هي إصلاحات، و0.6–0.9 في البنية التحتية).
**الاختبارات الواجبة:** اختبار عزل الجلسة لـ DVIR/codriver قبل وبعد 0.2 — هذا هو الاختبار الذي كان يجب أن يمنع أصلاً.

---

### المرحلة 1 — استعادة اتجاه الاعتماد (الشريحة الأقوى عائداً)

الهدف: **إخراج `features` من `core`**. هذا يفتح كل ما بعده.

**1.1** `core/events/eld_events_provider.dart:3` — استبدال استيراد `features/tracking/data/datasources/live_tracking_data_source.dart` بعقد في `core/domain`. الملف نفسه يشرح الحل في تعليقاته (`lines 9-10`) ولم يُطبَّق.
**1.2** `core/providers/driver_rules_provider.dart:2` — نقل `DriverRules` + المزوّد إلى `features/account/domain/`.
**1.3** `core/di/app_providers.dart:3,7,10` — إما نقله إلى `lib/app/di/` (وهو جذر تركيب حقيقي) أو توثيقه كاستثناء وحيد مسموح.
**1.4** `lib/backend/contracts/rules_screen_backend.dart:3` — نقل `RulesScreenModel` من `features/account/application/models/` إلى مكان ينتمي لنطاق واحد. هذا يحل 6 استيرادات دفعة واحدة (BACK-002).
**1.5** `auth_interceptor.dart:2-3` — تمرير التبعيات بدل الاستيراد.

**الملفات:** 8. **الاعتماد:** يجب إكمال 1.1–1.4 معاً (.Back-002 يفتح استيرادين).
**الاختبارات الواجبة:** اختبار وحدة لكل عقد مستخرج، بلا حاجة إلى Widget.

---

### المرحلة 2 — إغلاق دورة `routes ⇄ features` (25 ملفاً)

السبب الجذري: الصفحات تستورد `lib/routes.dart` للحصول على `rootNavigatorKey`.

**2.1** نقل `rootNavigatorKey` إلى ملف مستقل `lib/routes/navigator_keys.dart` لا يستورد أي صفحة.
**2.2** تحديث الملفات السبعة المستورِكة: `eld_connection_page.dart`, `home_page.dart`, `eld_drawer.dart`, `inspection_start_view.dart`, `logs_list_page.dart`, `suggested_events_page.dart`, `select_vehicle_page.dart`.
**2.3** `core/widgets/connection_status_indicator.dart:3,7` — بعد 2.1–2.2 يخرج `core` من الدورة تلقائياً.

**الملفات:** 9. **الاعتماد:** 2.1 أولاً وإلا لا يكتمل شيء.
**خطر الانحدار:** متوسط — يمسّ التنقل. **الاختبار الواجب:** اختبار تكامل للتوجيه يغطي كل مسار في `AppRoutes` (23 مساراً) قبل التغيير.
**توصية إضافية بنفس المرحلة:** `acc_account_page.dart` — نقل `EldDrawer` من `features/home` إلى `lib/app/shell/` (ACC-008)؛ هيكل التطبيق ليس ملك feature.

---

### المرحلة 3 — ردّ الفوضى إلى البيت الصحيح (مسؤوليات، لا بنية)

الهدف: نقل **مسؤوليات** إلى **أصحابها**. لا تغيير في العقود ولا في الواجهات العامة.

| # | من | إلى | الملاحظة |
|---|---|---|---|
| 3.1 | `eld_connection_page.dart:61-251` | `features/connection/{domain,application}` | CON-001 — أنشئ `connection/application`؛ هذا يجعل الميزة قابلة للاختبار |
| 3.2 | `duty_status_tracker.dart:5,11,13` + `:218-230` | `hos/data` | HL-02, HL-06 — `LocalStorageService` و`uuid` وبناء الحمولة |
| 3.3 | `duty_status_tracker.dart:4` | عقد `hos/domain/repositories/` | HL-01 — `DutyPeriodRepository` |
| 3.4 | `vehicle_selection.dart:52-119` | `vehicle/data` | DST-044 — HTTP في domain |
| 3.5 | `main_circular_timer.dart:98-192` | `HosRulesEngine` | HL-16 — الحساب خارج `build()` |
| 3.6 | `dvir_form_page.dart:463-476` | mapper/مستودع | DST-001 — **إزالة اختراع القيمة** |
| 3.7 | `current_codriver.dart`, `team_status.dart`, `connectivity_status.dart`, `hardware_readiness.dart` | `*/data` | COD-006 — JSON parsing خارج domain |
| 3.8 | `daily_form_rules.dart:7,86-90` | حدّ رقمي في domain + مفتاح ترجمة | HL-17 — القاعدة نصية لا قانونية |
| 3.9 | `duty_status_code.dart:7-8,75-88` | `core/theme` | DOM-001/CUI-013 — يُزيل `Color` من النطاق ويُصلح تعليقات `AppColors` الخاطئة |
| 3.10 | `inspection_repository_impl.dart:169-172` ↔ `send_logs_page.dart:267-268` | عقد typed | DST-016 — بروتوكول `OFFLINE_GENERATED:` النصي |

**الملفات:** ~20. **الاعتماد:** 3.3 يجب أن يسبق أي تغيير في `logs/domain/repositories`.
**الاختبارات الواجبة:** اختبارات وحدة لـ `HosRulesEngine` و`vehicle_selection` **قبل** النقل — هي الاختبارات التي كانت ستكشف 3.2.

---

### المرحلة 4 — توحيد المصادر (خفض التكرار والنظام الميت)

| # | الإجراء | الملاحظة |
|---|---|---|
| 4.1 | `HosLimits` كمصدر وحيد + حذف التسعير الزائد | HL-03, CORE-022 — 9 مواقع |
| 4.2 | خريطة واحدة لتطبيع رموز الحالات | HL-24, HL-34 — 5 خرائط |
| 4.3 | `EldRetryView` في مسارات إعادة المحاولة | HL-41 — 7 مواضع |
| 4.4 | حذف التجرريدات الميتة | `BackendRegistry` (BACK-027), `SignatureBackend` (BACK-013), `api_config.dart`/`api_response.dart` (BACK-028), `refreshTokenKey` (CORE-021), `UtcSyncService` (CORE-023), `refuseVehicleOperate`, `isValidInspectionPin`, `accountProfileFixture` (BACK-016) |
| 4.5 | توحيد `Result`/`Failure` | CORE-010/011 — **اختر نظاماً واحداً ولا تضف نظاماً ثالثاً** |
| 4.6 | النظامان المتوازيان للزمن | CORE-008 — `TimeAuthority` vs `TrustedTimeProvider` |
| 4.7 | ازدواج طابور المزامنة | DST-025 — `SyncEngine` (226، حيّ) مقابل `SyncRepositoryImpl` (156، بلا منتجين) — **احذف الثاني** |
| 4.8 | `secureStorageProvider` المكرر | CORE-019 |

**الملفات:** ~30، لكن معظمها حذف.

---

### المرحلة 5 — الحارس المعماري (يمنع الانحدار)

**5.1** تفعيل `architecture` في `analysis_options.yaml` بصيغ `flutter_lints` المعتمدة، مع `exclude` لـ `**/*.g.dart`, `**/*.freezed.dart`, `lib/l10n/**`.
**5.2** تحويل الـ 19 علامة `// ignore_architecture` من زخرفة إلى تنبيهات فعّالة، أو حذفها.
**5.3** بعد 1.x–3.x: **القاعدة الوحيدة التي يجب تذكّرها** — `core` لا يستورد `features`؛ `domain` لا يستورد `data`/`presentation`/Flutter.
**5.4** اختبار معماري بسيط يعتمد على `edges_classified.tsv` (المخطط المستخدم في هذا التدقيق) كخط أساس.

---

## خرائط التبعية بين المراحل

```
المرحلة 0  (تصحيح أخطاء)          ← مستقلة تماماً. ابدأ هنا.
   │
   ▼
المرحلة 1  (إخراج features من core)
   │  requires: لا شيء من 0 (لكن 0.6 يمنعWorking داخل نفس الملفات)
   ▼
المرحلة 2  (دورة routes)           ← requires: 1.x (تنظيف edges)
   │  requires: 2.1 أولاً
   ▼
المرحلة 3  (نقل المسؤوليات)        ← requires: 1.4 (تنظيم RulesScreenModel)
   │  requires: 3.3 قبل أي تعديل في logs/domain
   ▼
المرحلة 4  (توحيد + حذف ميت)       ← requires: 3.x (تثبيت المالك قبل الدمج)
   │
   ▼
المرحلة 5  (الحارس)                ← requires: 1.x–3.x كلها
```

---

## ملفHighest-risk التغييران

| التغيير | الخطر | لماذا | الحماية الإلزامية |
|---|---|---|---|
| 0.2 كاش `static` → instance | **عالٍ** | يغيّر سلوك session isolation — **هذا هو المقصود**، لكن أي مسار يعتمد على الكاش القديم سينهار | اختبار عزل جلسات: سائق A ثم B على نفس العملية |
| 2.x كسر دورة `routes` | **متوسط-عالٍ** | يمسّ التنقل في كل شاشة | اختبار توجيه يغطي 23 مساراً + `redirect` |
| 3.5 نقل حساب HOS من `build()` | **متوسط** | المخرجات يجب أن تكون **مطابقة تماماً** | تثبيت golden output من `HosRulesEngine` قبل النقل |
| 3.6 إزالة اختراع `deviceId` | **متوسط** | يغيّر DVIR المُرسَل — يمكن أن يفشل إرسال كان «ينجح» | تأكيد مع propiedad أن behavior السابق كان خاطئاً |

---

## ما يجب الحفاظ عليه (لا تلمسه)

- `core/network/api_client.dart` — موقع `Dio` الوحيد، ولا اعتراضات مكرّرة.
- `backend/adapters/eld_engine/mappers/**` — أعلى موضع في المشروع.
- `core/error/app_error.dart` — متماسك، عيوبه محدّدة لا بنيوية.
- `routes.dart` — `RouterNotifier extends ChangeNotifier` **هو** جسر Riverpod→GoRouter الصحيح.
- `features/auth` — لا تسريب اعتماد في السجلات؛ القيمة-objects تحتاج قاعدة لا 제거.
- صفحات `instructions_page` / `user_manual_page` / `rules_page` — ترجمة كاملة، ليست مشكلة.
- `sync/domain/usecases/sync_engine.dart` — حيّ ومستخدم؛ **البديل عنه** هو الميت.
- `offline_queue.dart` و`MemoryOfflineQueue` — منفذ نظيف ومُستخدم فعلاً.

## ما يُحذف بلا تردد

انظر 4.4. الإجمالي: **~9 تجريدات ميتة و~4 ملفات** لا تمثل منفذاً حقيقياً.

---

## استراتيجية الاختبار

**قبل المرحلة 0:** أضف اختباري الانحدار الأوّليين فقط:
1. عزل جلسة DVIR/codriver (يحمي 0.2).
2. تطابق استجابة DVIR بين `eld_engine` و`mock` (يحمي 0.3).

**قبل المرحلة 3:** اختبارات وحدة لـ `HosRulesEngine` و`vehicle_selection` و`DutyStatusTracker` أولاً. هذا ما كان سيمنع 5 من أصل 7 ملاحظات حرجة.

**قبل المرحلة 2:** اختبار توجيه شامل.

**قبل المرحلة 4:** اختبارات characterization لسلوك المزامنة وطابور SQLite (`MemoryOfflineQueue` يختلف في `nextRetryAt` عن SQLite — يجب تثبيت أيّهما هو المعتمد).

**بعد كل مرحلة:** `flutter analyze` + الاختبارات القائمة (148 ملف اختبار موجودة — استخدمها كشبكة أمان).

---

## ما لم يقترحه هذا التدقيق عمداً

- **لا Use Cases جديدة.** السجل يوصي بحذف الفارغة.
- **لا تقسيم `dvir_dto.dart` (402).** DTOات متماسكة لميزة واحدة.
- **لا تقسيم صفحات التوثيق الكبيرة.** هي محتوى، لا مسؤوليات.
- **لا تحويل كل ثابت إلى dynamic.** القسم 8 من هذا التدقيق يصنّف الثوابت إلى خمس فئات؛ فقط **الفئتان A وB** تستحقان مركزية.
- **لا إعادة هيكلة `lib/l10n`.** مولّدة.
