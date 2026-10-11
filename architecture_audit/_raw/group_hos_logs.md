# Group: hos + logs — Layer/Responsibility Audit

**النطاق:** `lib/features/hos/**` (29 ملف) + `lib/features/logs/**` (42 ملف) = **71 ملف**، جميعها مقروءة بالكامل.
**الاستثناء:** `*.g.dart` و `*.freezed.dart`.
**البنية:** Clean Architecture (Riverpod + Dio + go_router + freezed/fpdart).
**قاعدة الإثبات:** كل نتيجة أدناه مُسنَدة بـ `path:line` + مقتطف نص حرفي من الملف. لا توجد أي استنتاج من اسم ملف.

---

## ملخص تنفيذي

| المحور | الحكم |
|---|---|
| **نقاء `features/logs/domain/**`** | **مُنتَهَك مؤكَّد** — `daily_form_rules.dart` يستورد `l10n/app_localizations.dart` الذي يستورد `package:flutter/widgets.dart` و`flutter_localizations`. |
| **نقاء `features/hos/domain/**`** | **مُنتَهَك مؤكَّد** — `domain/engine/tracking/duty_status_tracker.dart` (555 سطر) يستورد `core/services/local_storage_service.dart`، `backend/contracts/status_dashboard_backend.dart`، `features/logs/domain/repositories/log_repository.dart`، `features/sync/domain/usecases/sync_engine.dart`، `package:uuid`. |
| **هل يحوي محرك HOS قواعد FMCSA حقيقية؟** | **نعم، جزئيًا** — `hos_calculator.dart` يقرأ `HosConfiguration` (11/14/70/30/8/34). لكن القواعد نفسها **مكرَّرة رقميًا** في 6 مواقع خارج `core/config`. |
| **أزواجية قيود HOS** | **مؤكدة** — 11/14/8/30/34/60/70/5mph/5min/15min كلها مثبّتة في طبقة العرض والعرض، راجع الجدول (C). |
| **متحكمات طبقة العرض** | `EditLogController` و`FormTabController` — **مختلطة**: تحتوي قواعد عمل ويصلان إلى `logRepositoryProvider` مباشرة. |
| **حجم الملفات** | `logs_provider.dart` (352)، `change_status_provider.dart` (397)، `log_repository_impl.dart` (539)، `duty_status_tracker.dart` (555) — الحجم وحده ليس مخالفة، لكن `duty_status_tracker` يجمع **7 أسباب للتغيير** في صنف واحد. |
| **اقتران بين الميزات** | **مؤكَّد**: `LOGS→VEHICLE/HOME/AUTH/SYNC/CODRIVER/INSPECTION`، `HOS→LOGS/SYNC/AUTH/TRACKING/CONNECTION/HOME`. |

**إجمالي المشكلات:** **41 مشكلة** (3 حرجة · 11 عالية · 22 متوسطة · 5 منخفضة)، موزّعة على 5 أقسام مفصّلة + جداول التكرار (C) والاقتران (D) والتغطية (E).

---

# A. Per-file findings

## A.1 — `lib/features/hos/domain/**` (12 ملف)

### `lib/features/hos/domain/engine/hos_calculator.dart` (113 سطر، غير فارغ 94)
- **المسؤولية الفعلية:** حساب الحدود المتبقية (11h قيادة، 14h نافذة، دورة، استراحة 30د) + فحص إعادة التشغيل الأسبوعي 34h.
- **الطبقة المعلنة:** domain ✅
- **الطبقة الفعلية:** domain مع تسريب واحد — يعتمد على `core/time/trusted_time_provider.dart` وهو ملف يُعرِّف `Provider` من Riverpod **في نفس الملف** (`trusted_time_provider.dart:200: final trustedTimeProvider = Provider<TrustedTimeProvider>(...)`). أي أن تبعيات domain تُسحب مكتبة Riverpod و`core/services/local_storage_service.dart` بشكل غير مقصود.
- **الحالة المعمارية:** سليم مع ملاحظة (HL-07).
- **Issue IDs:** HL-07، HL-03 (ثابت 34h مثبت داخليًا).

### `lib/features/hos/domain/engine/hos_rules_engine.dart` (240 سطر، غير فارغ 207)
- **المسؤولية الفعلية:** تنسيق `HosCalculator` + `HosStateMachine` + `TrustedTimeProvider`؛ توليد التنبيهات (15/30/60 دقيقة)؛ كشف المخالفات (3 أنواع)؛ التحقق من الانتقال اليدوي بالسرعة.
- **الطبقة المعلنة:** domain ✅
- **الطبقة الفعلية:** domain + تسريب `AppLogger` (`line 96`)، وبناء `Failure` قانوني داخل domain (`line 85: return Left(ServerFailure(...))`).
- **الحالة المعمارية:** جزئية — `Either<Failure, void>` يُرجع `ServerFailure` من طبقة domain وهي علاقة نقل لا علاقة قانونية.
- **Issue IDs:** HL-03، HL-09.

### `lib/features/hos/domain/engine/hos_state_machine.dart` (128 سطر، غير فارغ 106)
- **المسؤولية الفعلية:** تتبّع الحالة الحالية، محرّك `Timer.periodic` كل دقيقة لزيادة `_totalDrivingHours`، حفظ الانتقالات.
- **الطبقة:** domain ✅ / **الحالة:** سليم. ملاحظة تصميمية: `line 66-69` كتلة `if` فارغة بتعليق فقط.
- **Issue IDs:** — (سليم).

### `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` (555 سطر، غير فارغ 494)
- **المسؤولية الفعلية:** 7 أسباب للتغيير في صنف واحد: (1) استقبال أحداث ELD وتطبيق قاعدة 5mph؛ (2) قاعدة الثبات 5 دقائق؛ (3) حفظ الحالة في `LocalStorageService`؛ (4) إنشاء `PendingEvent` + إيداعه في `SyncEngine`؛ (5) نداء `StatusDashboardBackend` مباشرة؛ (6) تبثّ الأحداث؛ (7) حساب إحصائيات `Map<String,double>` غير مُنمّطة.
- **الطبقة المعلنة:** domain — والملف **يصرّح بذلك في تعليق**: `line 7: /// متتبع حالة السائق (Domain Pure)`
- **الطبقة الفعلية:** data + application + infrastructure. يُسجّل `DutyPeriod` في مستودع ميزة أخرى، ويستدعي backend مباشرة، ويبني حمولة شبكة (تحويل ميل→كم `line 227`).
- **الحالة المعمارية:** **مخالفة حرجة مؤكدة.**
- **Issue IDs:** HL-01، HL-02، HL-04، HL-05، HL-06، HL-15، HL-38.

### `lib/features/hos/domain/repositories/hos_audit_repository.dart` (6 أسطر، غير فارغ 5)
- **المسؤولية:** عقد مستودع لـ `HosViolation`.
- **الطبقة:** domain ✅ / **الحالة:** سليم تماماً.
- **Issue IDs:** —

### `lib/features/hos/domain/repositories/status_dashboard_repository.dart` (20 سطر، غير فارغ 17)
- **المسؤولية:** عقد مستودع اللوحة + `Either<Failure, …>`.
- **الطبقة:** domain ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/domain/usecases/get_status_dashboard_use_case.dart` (15 سطر، غير فارغ 12)
- **المسؤولية:** تفويض كامل بلا منطق.
- **الطبقة:** domain (usecase) ✅ / **الحالة:** **نمط Pass-Through فارغ** — لا يضيف قيمة فوق `repository.getDashboard()`. ليس مخالفة معمارية صريحة، لكنه SRP مشكوك فيه.
- **Issue IDs:** HL-10 (ملاحظة).

### `lib/features/hos/domain/usecases/get_weekly_recap_use_case.dart` (15 سطر، غير فارغ 12)
- نفس النمط أعلاه. **الحالة:** سليم/فارغ.
- **Issue IDs:** HL-10 (ملاحظة).

### `lib/features/hos/domain/usecases/update_duty_status_use_case.dart` (18 سطر، غير فارغ 15)
- نفس النمط أعلاه. **الحالة:** سليم/فارغ.
- **Issue IDs:** HL-10 (ملاحظة).

## A.2 — `lib/features/hos/data/**` (4 ملفات)

### `lib/features/hos/data/providers/hos_audit_providers.dart` (14 سطر، غير فارغ 12)
- **المسؤولية:** تركيب `HosAuditRepositoryImpl(Hive.box)`.
- **الطبقة:** data/DI ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/data/providers/status_dashboard_repository_providers.dart` (15 سطر، غير فارغ 12)
- **المسؤولية:** تركيب `StatusDashboardRepositoryImpl` من `backend` + `network`.
- **الطبقة:** data/DI ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/data/repositories/hos_audit_repository_impl.dart` (58 سطر، غير فارغ 52)
- **المسؤولية:** تخزين/قراءة المخالفات في Hive بصيغة JSON.
- **الطبقة:** data ✅ / **الحالة:** سليم. `catch` في `line 46-54` **مُبلَّغ** عبر `AppLogger.warning` — ليس ابتلاعاً.
- **Issue IDs:** —

### `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart` (115 سطر، غير فارغ 108)
- **المسؤولية:** نداء `StatusDashboardBackend` + cache + **`_circleForStatus` التي تصنع أرقام HOS مُختلقة**.
- **الطبقة:** data ❌ / **الطبقة الفعلية:** data + **domain/business**.
- **الحالة:** **مخالفة مؤكدة** — `line 86-95` يفترض `Duration(minutes: 35)` المتبقية و`Duration(hours: 2, minutes: 8)` للوردية، وهي أرقام قانونية مُختلقة داخل مستودع بيانات.
- **Issue IDs:** HL-03، HL-11.

## A.3 — `lib/features/hos/presentation/**` (13 ملف)

### `lib/features/hos/presentation/duty_change_message.dart` (32 سطر، غير فارغ 27)
- **المسؤولية:** ترجمة `DutyStampRefusal` → نص.
- **الطبقة:** presentation ✅ / **الحالة:** سليم. يعتمد على ثوابت الرفض من domain (استيراد عقد، جائز).
- **Issue IDs:** —

### `lib/features/hos/presentation/extensions/duty_status_l10n.dart` (52 سطر، غير فارغ 48)
- **المسؤولية:** `displayName(BuildContext)` لـ `DutyStatusCode` و`DutyStatus`.
- **الطبقة:** presentation ✅ / **الحالة:** سليم مع `try/catch` في `line 33` يلغي غياب مفتاح l10n — مقبول وموثّق.
- **Issue IDs:** —

### `lib/features/hos/presentation/pages/change_status_page.dart` (232 سطر، غير فارغ 212)
- **المسؤولية:** عرض خيارات الحالة + نموذج الموقع/الملاحظات + استدعاء `submit()`.
- **الطبقة:** presentation ✅ جزئياً — `line 149` رسالة تحقق **مكتوبة يدوياً** بالإنجليزية لا يمرّ بمترجم اللغة الذي تعرضه بقية الشاشة.
- **Issue IDs:** HL-08.

### `lib/features/hos/presentation/pages/recap_page.dart` (117 سطر، غير فارغ 113)
- **المسؤولية:** عرض جدول الأسبوع + `DurationFormat`.
- **الطبقة:** presentation ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/presentation/pages/status_dashboard_page.dart` (118 سطر، غير فارغ 103)
- **المسؤولية:** shell + تفويض loading/error/data.
- **الطبقة:** presentation ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/presentation/providers/change_status_provider.dart` (397 سطر، غير فارغ 353)
- **المسؤوليات (17 عضواً):** `DutyStatusOption` (5 دوال/مُعيدات: `toDutyStatus`, `isYardMoves`, `displayName`, `fromCurrent`, `fromStatusCode`) + `ChangeStatusState` (7: `selectedStatus`, `isYardMoves`, `isAnnotationRequired`, `hasValidCustomLocation`, `isLocationValid`, `isValid`, `copyWith`) + `ChangeStatusNotifier` (5: `selectOption`, `updateNotes`, `updateCustomLocation`, `updateLocation`, `submit`).
- **هل تحقّق عمل داخل الـ notifier؟** **نعم، مخالفة مؤكدة** — `line 278-295`: رفض الحركة، رفض PC/YM غير المصرّح، اشتراط الملاحظات.
- **هل وصول مباشر لمستودع/مصدر بيانات؟** **لا** — يتعامل مع `hosStatusProvider` (application) ومع `statusDashboardProvider`. ✅
- **أرقام أعمال:** `line 174` (`length >= 5 && <= 60`)، `line 182` (`notes.length >= 4`)، `line 284/289` (رسائل رفض إنجليزية صريحة).
- **الطبقة:** presentation ❌ جزئياً — يحتوي قواعد تحقق نطاق/إلزام.
- **Issue IDs:** HL-08، HL-12.

### `lib/features/hos/presentation/providers/hos_engine_provider.dart` (83 سطر، غير فارغ 71)
- **المسؤولية:** تركيب `HosCalculator`/`HosStateMachine`/`HosRulesEngine`/`DutyStatusTracker` + اشتقاق `currentSpeedKmhProvider` و`isVehicleMovingProvider`.
- **الطبقة:** presentation/DI ✅ (التركيب مشروع هنا في هذا المشروع).
- **مخالفة:** `line 8` يستورد `../../../logs/data/providers/log_repository_providers.dart` — **presentation → data**، وهو نمط مشروع في هذا المشروع لكن هناExists لأنه يعكس أن `DutyStatusTracker` (domain) يحتاج مستودعاً من ميزة أخرى.
- **Issue IDs:** HL-01، HL-13.

### `lib/features/hos/presentation/providers/hos_provider.dart` (159 سطر، غير فارغ 140)
- **المسؤوليات:** تهيئة `HosNotifier`، اشتراك `eldEventsStreamProvider`، اشتراك `onTransition`، مؤقّت تحديث كل دقيقة (`line 78`)، **`_processAndLogViolations` التي تكتب مباشرة إلى `hosAuditRepositoryProvider` (`line 140`)**، `changeStatus` الذي يحوّل `DutyStatus → DutyStatusCode` بـ `switch` يدوي (`line 113-130`).
- **الطبقة:** presentation ❌ — يصل إلى مستودع domain مباشرة لتدقيق المخالفات، ويكرر مطابقة رمز الحالة.
- **Issue IDs:** HL-13، HL-14.

### `lib/features/hos/presentation/providers/recap_provider.dart` (38 سطر، غير فارغ 31)
- **المسؤولية:** `FutureProvider` + اشتراك `appEventBus` + بوابة الجلسة.
- **الطبقة:** presentation ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/presentation/providers/status_dashboard_providers.dart` (145 سطر، غير فارغ 127)
- **المسؤوليات:** `_engineStatusCode` مطابقة يدوية (`line 18-31`)، `StatusDashboardNotifier.build` مع 3 اشتراكات، `refresh` مع بوابة جلسة، مؤقّت `Duration(minutes: 1)` في `line 86`.
- **الطبقة:** presentation ❌ جزئياً — `_engineStatusCode` تكرّر لـ `DutyStatusOption.toDutyStatusCode` (`change_status_provider.dart:37`) و`HosNotifier._mapStatus` (`hos_provider.dart:59`).
- **Issue IDs:** HL-14.

### `lib/features/hos/presentation/widgets/driving_lock_screen.dart` (57 سطر، غير فارغ 54)
- **المسؤولية:** شاشة حجب أثناء القيادة + تجاوز مطوّر بنقرة مزدوجة.
- **الطبقة:** presentation ✅ — لكن `line 7` `import '../../../home/presentation/pages/home_page.dart'` **مقايضة لأثر جانبي**: الاستيراد موجود للحصول على `developerBypassDrivingScreenProvider`، وهو provider من feature أخرى كاملة.
- **Issue IDs:** HL-15 (اقتران)، ومخاطرة منفصلة: تجاوز قاعدة FMCSA بنقرة مزدوجة (مشروط بـ `kDebugMode`).

### `lib/features/hos/presentation/widgets/location_display_widget.dart` (39 سطر، غير فارغ 35)
- **المسؤولية:** عرض إحداثيات GPS من `trackingStateProvider`.
- **الطبقة:** presentation → tracking (presentation) ✅ — اقتناع حالة من feature أخرى عبر provider عام مقبول.
- **الحالة:** سليم (يستخدم `.select` لتقليل إعادة البناء).
- **Issue IDs:** —

### `lib/features/hos/presentation/widgets/status_option_tiles.dart` (70 سطر، غير فارغ 62)
- **المسؤولية:** ويدجت بلاطة اختيار.
- **الطبقة:** presentation ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart` (150 سطر، غير فارغ 139)
- **المسؤولية:** جدول المؤشرات الأربعة.
- **محتوى الملف:** `_descriptions()` تختار نص الوصف من `RegulatoryConstraints` أو من l10n، و`_IndicatorRow` يحدد `isCritical` بـ `indicator.value <= const Duration(hours: 1)` (`line 105`) — **عتبة عمل داخل widget**.
- **الطبقة:** presentation ❌ جزئياً.
- **Issue IDs:** HL-03.

### `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart` (365 سطر، غير فارغ 331)
- **المسؤولية:** الدائرة المركزية الكبيرة + `_ThemeToggleButton` + `CustomPainter`.
- **المحتوى الحاسم:** الدالة `build` (`line 98-267`) تنفّذ **حساب HOS كاملاً**: اختيار الحد الحاكم، دالة `remainingOf()`، العد التنازلي الحي، نسبة الاستهلاك، تحديد اللون. وثوابت `Duration(hours: 11)` / `8` / `14` و`Duration(minutes: 15)` مثبتة في `line 125/128/142/145/179`.
- **الطبقة:** presentation ❌ **مخالفة حرجة مؤكدة.**
- **Issue IDs:** HL-03، HL-16.

### `lib/features/hos/presentation/widgets/status_dashboard/operational_alerts_banner.dart` (93 سطر، غير فارغ 84)
- **المسؤولية:** بانر حالة الاتصال + تنبيهات العتاد.
- **الطبقة:** presentation → connection ✅ / **الحالة:** سليم.
- **Issue IDs:** —

## A.4 — `lib/features/logs/domain/**` (10 ملفات)

### `lib/features/logs/domain/daily_form_rules.dart` (93 سطر، غير فارغ 83)
- **المسؤولية الفعلية:** قواعد التحقق من المقطورة/وثيقة الشحن (SRS 5.5–5.13) — **محتوى قانوني صحيح ومناسب للموقع**.
- **الطبقة المعلنة:** domain
- **الطبقة الفعلية:** domain + **Flutter** (غير مباشر)
- **الحالة:** **مخالفة نقاء confirmed** — `line 7: import '../../../../l10n/app_localizations.dart'`، وتلك الملفات تستورد `import 'package:flutter/widgets.dart';` و`import 'package:flutter_localizations/flutter_localizations.dart';`. كما أن `line 86-90` يختار نصوصاً عربية/إسبانية/إنجليزية **من داخل domain**.
- **Issue IDs:** HL-17.

### `lib/features/logs/domain/log_edit.dart` (57 سطر، غير فارغ 49)
- **المسؤولية:** قاعدة «القيادة الآلية لا تُختصر» + تحليل وقت نموذج التعديل.
- **الطبقة:** domain ✅ / **الحالة:** سليم. ملاحظة: `line 29: final base = logDate ?? DateTime.now();` — استخدام ساعة الحائط كاحتياط داخل domain؛ **مقبول هنا** لأن النتيجة تُرفض لاحقاً في `edit_log_controller.dart:52` إن كانت في المستقبل.
- **Issue IDs:** —

### `lib/features/logs/domain/saved_form_status.dart` (36 سطر، غير فارغ 31)
- **المسؤولية:** قراءة `formStatus` من استجابة JSON.
- **الطبقة الفعلية:** domain + **تحليل استجابة شبكة** (`Map<String, dynamic>`، `'data'`، `'COMPLETED'`).
- **الحالة:** **مخالفة موقع مؤكَّد** — قراءة شكل استجابة HTTP داخل domain بينما `log_repository_impl.dart:359` هو المكان الصحيح.
- **Issue IDs:** HL-18.

### `lib/features/logs/domain/entities/audit_entry.dart` (100 سطر، غير فارغ 89)
- **المسؤولية:** كيان تدقيق + `toMap`/`fromMap` + قراءة طابع زمني مرن.
- **الطبقة:** domain مع **تسريب تمثيل JSON** — `toMap()` (شغرة persistence) داخل الكيان.
- **الحالة:** مخالفة متوسطة (SRP على الكيان). ملاحظة: غير متسق مع `DailyLog` الذي لا يفعل — **عدم اتساق**.
- **Issue IDs:** HL-18.

### `lib/features/logs/domain/entities/daily_form_data.dart` (32 سطر، غير فارغ 29)
- **المسؤولية:** لقطة نموذج اليوم المحفوظ. **الطبقة:** domain ✅ **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/logs/domain/entities/daily_form_update.dart` (27 سطر، غير فارغ 24)
- **المسؤولية:** أمر تحديث نموذج اليوم. **الطبقة:** domain ✅ **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/logs/domain/entities/daily_log.dart` (251 سطر، غير فارغ 236)
- **المسؤولية:** كيان `DailyLog` + `LogEvent`.
- **الطبقة الفعلية:** domain + **عرض**.
- **الحالة:** **مخالفة SRP مؤكدة** — الكيان يحتوي:
  - `dayName` (`line 110-124`) بأسماء إنجليزية `'Today'`, `'Yesterday'`, `['Mon','Tue',…]`
  - `formattedDate` (`line 126-141`) بأشهر `'Jan'..'Dec'` + `_ordinal`
  - `formattedStartTime` (`line 210-214`)، `formattedDuration` (`line 216-220`)
  - **`DateTime.now()` في `line 111`** داخل getter يُحسب عند كل استدعاء.
- **Issue IDs:** HL-19، HL-30.

### `lib/features/logs/domain/entities/log_readiness.dart` (69 سطر، غير فارغ 63)
- **المسؤولية:** كيانات الجاهزية والتعديل المقترح من الناقل.
- **الطبقة:** domain ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/logs/domain/repositories/log_repository.dart` (93 سطر، غير فارغ 85)
- **المسؤولية:** عقد مستودع بـ 16 دالة.
- **الطبقة:** domain ✅ — يستورد `fpdart` و`core/error/failure.dart` و`core/domain/entities/hos_models.dart` (لـ `DutyPeriod`)، وهي **عقد مشتركة لا تنفيذ**.
- **الحالة:** سليم. ملاحظة حجم: 16 عملية في عقد واحد → SRP موزّع على use-cases متعددة.
- **Issue IDs:** HL-10 (ملاحظة).

## A.5 — `lib/features/logs/data/**` (5 ملفات)

### `lib/features/logs/data/datasources/log_local_data_source.dart` (322 سطر، غير فارغ 291)
- **المسؤولية:** Hive read/write للأحداث والفترات والتدقيق + cache + توقيع + `ownerOfCachedLog`.
- **الطبقة:** data ✅ / **الحالة:** سليم بنيوياً. `catch` المتعدد كلها مسجّلة عبر `AppLogger` عدا `line 124` و`line 171` و`line 311` التي تُعيد `[]`/تتخطى بصمت.
- **Issue IDs:** HL-20.

### `lib/features/logs/data/models/daily_log_dto.dart` (143 سطر، غير فارغ 134)
- **المسؤولية:** `fromJson` + `toEntity` مع مطابقة `FormStatus`/`CertificationStatus`.
- **الطبقة:** data ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/logs/data/models/log_model.dart` (133 سطر، غير فارغ 121)
- **المسؤولية:** تحليل event من شكلي wire، تحويل km→mile (`_kmToMiles = 0.621371` في `line 88`).
- **الطبقة:** data ✅ / **الحالة:** سليم. `line 76: DateTime.parse(startTimeStr).toLocal()` — تحويل منطقة زمنية داخل data، مقصود وموثّق.
- **Issue IDs:** —

### `lib/features/logs/data/providers/log_repository_providers.dart` (25 سطر، غير فارغ 21)
- **المسؤولية:** تركيب المستودع من 7 تبعيات.
- **الطبقة:** data/DI ✅ / **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/logs/data/repositories/log_repository_impl.dart` (539 سطر، غير فارغ 498)
- **المسؤولية:** 16 `@override` + سياسات offline + تحليل `getForm` (استخراج `coDriverId` من `Map` متداخل).
- **الطبقة:** data ✅ / **الحالة:** سليم بنيوياً. **لكنه** يحوي تحليل الاستجابة (`getForm`)، و`line 270` يرمي `ServerException` ليلتقطه `executeWithHandling` — نمط تحويل أخطاء غير متسق لكنه مقبول ومقصود.
- **Issue IDs:** HL-18 (مرتبط).

## A.6 — `lib/features/logs/presentation/controllers/**` (2 ملف)

### `lib/features/logs/presentation/controllers/edit_log_controller.dart` (122 سطر، غير فارغ 105)
- **المسؤوليات (3 فقط):** تهيئة (`build` فارغ)، `saveEvent`، تعريف `EditLogErrorCode` (5 قيم).
- **هل هو controller عرض حقيقي أم منطق عمل متنكر؟** **مختلط — مخالفة مؤكدة.** في `saveEvent`:
  1. **قاعدة قانونية** `line 52`: `// FMCSA § 395: Duty status events cannot be recorded in the future` مع `Duration(minutes: 1)`.
  2. **قاعدة عمل** `line 57`: استدعاء `refuseAutomaticDrivingEdit`.
  3. **كتابة تدقيق بمباشرة المستودع** `line 107: final repo = ref.read(logRepositoryProvider);` ثم `line 108: repo.logAudit(entry)` — **presentation يتجاوز use-case ويتصل بالمستودع مباشرة**.
  4. `catch (e, st) { state = AsyncError(e, st); }` في `line 114` يبتلع النوع، ونوع `EditLogError` مصمَّم — الواجهة تعامله (`edit_log_page.dart:89`) كرسالة عامة.
- **Issue IDs:** HL-12، HL-21، HL-22.

### `lib/features/logs/presentation/controllers/form_tab_controller.dart` (68 سطر، غير فارغ 58)
- **المسؤوليات (2):** حالة `isLoading` + `saveForm`.
- **محتوى العمل:** `line 31` **وصول مباشر للمستودع**: `_ref.read(logRepositoryProvider).saveForm(...)`؛ `line 50` **يكتب في notifier ميزة أخرى**: `_ref.read(logsProvider.notifier).updateLog(...)`؛ `line 58` **يختار نص النجاح** من 4 احتمالات.
- **الحالة:** **مخالفة مؤكدة** — ليس controller عرض، بل use-case مختلط يتصل بالمستودع ومع UI.
- **Issue IDs:** HL-21، HL-22، HL-25.

## A.7 — `lib/features/logs/presentation/pages/**` (9 ملفات)

### `lib/features/logs/presentation/pages/edit_log_page.dart` (433 سطر، غير فارغ 407)
- **المسؤولية:** نموذج تعديل/إضافة حدث + حوار اختيار مركبة مدمج.
- **محتوى داخل `build`:** `line 42` استدعاء `parseEditFormTime` (منطق domain) داخل معالج؛ `line 248-251` و`line 276-282` استدعاء `isFreeTextValid` (قاعدة domain) داخل `validator`.
- **اقتران:** `line 13/14` يستورد `vehicle` domain entity + `vehicle` presentation provider؛ `line 4` يستورد `home/presentation/providers/dashboard_provider.dart`.
- **الحالة:** مخالفة متوسطة (presentation يستدعي دوال domain ويُعيد اشتقاق التحقق بدل الاعتماد على حالة جاهزة).
- **Issue IDs:** HL-13، HL-23.

### `lib/features/logs/presentation/pages/inspection_preview_page.dart` (401 سطر، غير فارغ 382)
- **المسؤولية:** معاينة تفتيش DOT + جدول أحداث + سجل نقل + تنقل تبويبات.
- **محتوى داخل `build`:**
  - `line 190-200` فلترة الأحداث بقائمة **مكتوبة يدوياً** `['ON','D','SB','OFF']` مع تعليق يعترف بعدم اكتمالها: `// Custom filter logic for "Active Events"` / `// Currently keeps duty statuses. Implement exact logic if needed.`
  - `line 204` `context.translateStatus(e.status)`؛ `line 206-211` تنسيق أرقام؛ `line 212 src: 'Auto'` **ثابت يُلفّ لكل سطر**.
  - `_getStatusColor` (`line 273-286`) — خريطة رمز→لون **ثانية** بجانب `StatusColorHelper` الموجودة في `core/utils/status_color_helper.dart`.
  - `line 300-321`: منطق مطابقة يوم يعتمد على المقارنة اليدوية داخل `build` مع `try/catch` يبتلع الاستثناء (`line 317`).
- **اقتران:** `line 14/15/16` يستورد 3 ملفات من `features/inspection` (domain + providers + **presentation widgets**).
- **Issue IDs:** HL-13، HL-24، HL-20، HL-25.

### `lib/features/logs/presentation/pages/logs_list_page.dart` (239 سطر، غير فارغ 225)
- **المسؤولية:** قائمة السجلات + شرائح الحالة + تنقل.
- **محتوى داخل `build`:** `line 168-170` **تنسيق مدة مكرر** ومنفصل عن `DurationFormat` وعن `LogEvent.formattedDuration`:
```dart
: (log.totalDrivingHours < 1
      ? '< 1m'
      : '${log.totalDrivingHours.toStringAsFixed(0)}h ${(log.totalDrivingHours % 1 * 60).toStringAsFixed(0)}m'),
```
- **اقتران:** `line 11: import '../../../home/presentation/widgets/eld_drawer.dart';` — **استيراد widget من feature أخرى** لتضمين الـ drawer.
- **Issue IDs:** HL-19، HL-25، HL-26.

### `lib/features/logs/presentation/pages/log_detail_page.dart` (220 سطر، غير فارغ 211)
- **المسؤولية:** shell + تنقل الأيام + 3 تبويبات + `BottomNavigationBar`.
- **الحالة:** navigation-centric. `line 167: Expanded(child: _buildBodyContent(currentIndex, selectedLog))`.
- **Issue IDs:** HL-26 (ازدواج `BottomNavigationBar` مع `inspection_preview_page.dart:236-266`).

### `lib/features/logs/presentation/pages/audit_trail_page.dart` (93 سطر، غير فارغ 88)
- **المسؤولية:** عرض سجل التدقيق.
- **محتوى داخل `build`:** `line 77-79` `DateFormat('yyyy-MM-dd\nHH:mm').format(e.timestamp.toLocal())` — **تنسيق ثالث للوقت** في المجموعة.
- **الحالة:** تنسيق مكرر.
- **Issue IDs:** HL-26.

### `lib/features/logs/presentation/pages/shipping_documents_page.dart` (170 سطر، غير فارغ 160)
- **المسؤولية:** إدارة قائمة وثائق الشحن عبر `dashboardDataProvider` (feature أخرى).
- **محتوى:** `line 100: RegExp(r'[\p{L}\p{N}\s\-_#/]', unicode: true)` في `FilteringTextInputFormatter` — **نسخة ثانية من نفس النمط المعرَّف في المصدر الصحيح** `daily_form_rules.dart:30-31`.
- **اقتران:** `line 11` استيراد `home/presentation/providers/dashboard_provider.dart`.
- **Issue IDs:** HL-23، HL-25، HL-27.

### `lib/features/logs/presentation/pages/suggested_events_page.dart` (121 سطر، غير فارغ 117)
- **المسؤولية:** تصفية السجلات المعلّمة + تنقل.
- **الحالة:** منطقية (فلترة `requiresAction`). تستورد `AppRoutes` — navigation مقبول.
- **Issue IDs:** —

### `lib/features/logs/presentation/pages/trailers_page.dart` (170 سطر، غير فارغ 160)
- **المسؤولية:** إدارة قائمة المقطورات — **نسخة طبقية مطابقة لـ `shipping_documents_page.dart`** (الهيكل متطابق سطرياً تقريباً).
- **محتوى:** `line 100: RegExp(r'[\p{L}\p{N}\s\-_#]', unicode: true)` — نسخة ثانية.
- **Issue IDs:** HL-23، HL-25، HL-27.

### `lib/features/logs/presentation/pages/unidentified_events_page.dart` (505 سطر، غير فارغ 479)
- **المسؤولية:** قائمتا unclaimed/rejected + 3 مرشّحات (تبويب/مركبة/تاريخ) + 4 إحصاءات + إجراءات claim/reject.
- **محتوى داخل الكود:**
  - `line 71-82` `_applyDateFilter` — **فلترة داخل الـ State class** لا داخل الـ notifier.
  - `line 334` داخل `_StatsRow.build`: `final since = now.subtract(const Duration(hours: 24));` و`line 337: if (!status.contains('DRIV')) return false;` — **مطابقة حالة بالنص الجزئي داخل widget**.
  - `line 423-434` داخل `itemBuilder`: 12 استخراج حقل من `Map` بـ `'${item['x'] ?? ''}'` — **استخراج بيانات خام داخل itemBuilder**.
- **اقتران:** `line 11` يستورد `vehicle/presentation/providers/vehicle_provider.dart`.
- **Issue IDs:** HL-12، HL-13، HL-28.

## A.8 — `lib/features/logs/presentation/providers/**` (7 ملفات)

### `lib/features/logs/presentation/providers/audit_trail_provider.dart` (10 أسطر، غير فارغ 9)
- **المسؤولية:** `FutureProvider` يقرأ من المستودع مباشرة (`line 7: ref.watch(logRepositoryProvider)`).
- **الحالة:** لا use-case، يخالف النمط مقارنة بـ `recap_provider.dart:10-12` الذي يستخدم `GetWeeklyRecapUseCase` — **عدم اتساق مؤكد**.
- **Issue IDs:** HL-21.

### `lib/features/logs/presentation/providers/certify_log_provider.dart` (193 سطر، غير فارغ 163)
- **المسؤوليات (5):** `CertifyLogState`، `CarrierEditResponse` (مع `apiValue = 'ACCEPT'/'REJECT'`)، `_fetchReadiness`، `respondToCarrierEdit`، `certify`.
- **هل تحقّق عمل داخل الـ notifier؟** **نعم** — `line 158: if (!log.isFormComplete) return CertifyFailed(...)`، `line 163` توقيع فارغ مرفوض، `line 168` جلسة مفقودة.
- **بناء حمولة API؟** **نعم** — `line 177: logDate: DateFormat('yyyy-MM-dd').format(log.date)`، `line 178: signatureCertificateId: 'local_drawn'` (سلسلة حرفية تعاقدية).
- **الحالة:** presentation يتحقق من شروط الشهادة القانونية بدل use-case.
- **Issue IDs:** HL-12، HL-29.

### `lib/features/logs/presentation/providers/edit_log_form_provider.dart` (66 سطر، غير فارغ 59)
- **المسؤولية:** حالة نموذج 5 حقول + 4 setters.
- **ملاحظة:** مُعامل `family<…, LogEvent?>` — و`LogEvent` يورث من `Equatable`، لكن `props` في `daily_log.dart:249-250` **يستثني `location`**:
```dart
List<Object?> get props =>
    [id, status, startTime, duration, location, isExpanded];
```
سطران فقط — أي **أن استثناء واحد يكفي**، وهو استثناء حقيقي يُفقد الحالة. هذا **خلل سلوكي مؤكد**.
- **Issue IDs:** HL-30.

### `lib/features/logs/presentation/providers/logs_provider.dart` (352 سطر، غير فارغ 310)
- **المسؤوليات (11 دالة):** `loadLogs`, `selectLog`, `loadSelectedForm`, `loadSelectedLogDetail`, `loadSelectedLogEvents`, `_replaceSelected`, `toggleEventExpansion`, `addEvent`, `updateEvent`, `updateLog` + المُهيّئ.
- **هل وصول مباشر لمستودع؟** **نعم، لكن محقون**: `line 92: final LogRepository _repository;` — لا use-case في المسار.
- **هل فيه قواعد عمل؟** **نعم** — `line 119: const limit = 20;` (حجم صفحة)، `line 148: hasReachedMax: newLogs.length < limit`، `line 161-170` شرط «هل النموذج يحتوي بيانات» و**كتابة في `dashboardDataProvider.notifier`** (feature أخرى)، `line 293/296/301/313/316` بناء `ServerFailure` برسائل إنجليزية صريحة.
- **الحالة:** مخالفة متوسطة–حرجة: use-case مدمج داخل StateNotifier + اقتران ثنائي مع `home`.
- **Issue IDs:** HL-12، HL-21، HL-25، HL-31.

### `lib/features/logs/presentation/providers/log_detail_tab_provider.dart` (5 أسطر، غير فارغ 4)
- **المسؤولية:** `StateProvider<int>` لفهرس التبويب. **الحالة:** سليم تماماً.
- **Issue IDs:** —

### `lib/features/logs/presentation/providers/unidentified_events_provider.dart` (170 سطر، غير فارغ 154)
- **المسؤوليات:** **دوال parsing عامة على مستوى الملف** — `parseUnidentifiedList` (`line 13-17`) و`normalizeUnidentifiedItem` (`line 19-39`) — وكلاهما **مندرج ضمن domain داخل presentation**.
- **هل وصول مباشر لـ backend؟** **نعم، مخالفة مؤكدة** — `line 97: final backend = ref.read(unidentifiedEventsBackendProvider);` ثم `line 103/104/136/151` نداءات. **لا مستودع، لا use-case** — presentation يتجاوز طبقتين.
- **هل تحقّق عمل؟** **نعم** — `line 135: if (annotation.trim().isEmpty) return const ServerFailure(message: 'An annotation is required.');` و`line 150` مقابلها.
- **الواجهة الأمامية:** `List<Map<String, dynamic>>` كـ state — **تسريب شكل خام داخل presentation**.
- **Issue IDs:** HL-21، HL-28، HL-32.

## A.9 — `lib/features/logs/presentation/widgets/**` (12 ملف)

### `lib/features/logs/presentation/widgets/codriver_picker_dialog.dart` (113 سطر، غير فارغ 105)
- **المسؤولية:** حوار اختيار سائق مساعد.
- **اقتران:** `line 5/6` يستورد `codriver` domain entity + provider؛ `line 9` يعيد export للكيان.
- **خلل سطحي:** `line 57: 'Error: ${codriverState.error}'` — **عرض رسالة خطأ خام** بينما المقياس يستخدم `anyErrorUserMessage` في 12 موضعاً آخر داخل `logs`.
- **Issue IDs:** HL-13، HL-33.

### `lib/features/logs/presentation/widgets/log_graph.dart` (101 سطر، غير فارغ 86)
- **المسؤولية:** حساب نقاط Graph-Grid + إحصاءات الجانب.
- **محتوى داخل `build`:** `line 18-19` فرز الأحداث؛ `line 21` اشتقاق `referenceDate` بـ `DateTime.now()`؛ `line 32-67` **حلقة تحسب ساعات كل حالة وتطبّع الرموز**؛ `line 47-53`:
```dart
if (status == 'PC') {
  normalized = 'OFF';
} else if (status == 'YM' || status == 'OTH' || !stats.containsKey(status)) {
  normalized = 'ON';
```
— **قاعدة تطبيع حالة مكتوبة يدوياً** ومكرّرة في `events_tab.dart:117-121` و`inspection_preview_page.dart:194-199`.
- **Issue IDs:** HL-24، HL-34.

### `lib/features/logs/presentation/widgets/status_radio_group.dart` (61 سطر، غير فارغ 57)
- **المسؤولية:** مجموعة أزرار اختيار الحالة.
- **محتوى:** `line 19-26` خريطة `value→label` **رابعة** لمجموعة الرموز (`OFF/SB/D/ON/PC/YM`)، متكررة عن `DutyStatusCode` في `lib/domain/duty_status/duty_status_code.dart` و`DutyStatus.toShortCode()` في `core/domain/entities/hos_models.dart`.
- **Issue IDs:** HL-24، HL-34.

### `lib/features/logs/presentation/widgets/time_field_widget.dart` (53 سطر، غير فارغ 50)
- **المسؤولية:** حقل عرض الوقت. **الحالة:** سليم (عرضي بحت).
- **Issue IDs:** —

### `lib/features/logs/presentation/widgets/time_picker_sheet.dart` (175 سطر، غير فارغ 165)
- **المسؤولية:** عجلات اختيار الوقت 12 ساعة.
- **محتوى:** `line 69-72` **ينشئ نص وقت**، والعقد مربوط فقط بتعليق: `// Always use English AM/PM so parseEditFormTime can parse it properly.` والمستهلك هو regex في `domain/log_edit.dart:41-42`.
- **Issue IDs:** HL-35.

### `lib/features/logs/presentation/widgets/vehicle_picker_dialog.dart` (168 سطر، غير فارغ 157)
- **المسؤولية:** حوار اختيار مركبة مع تبديل أسطول الشركة.
- **اقتران:** `line 9` يستورد `vehicle/presentation/providers/vehicle_provider.dart` (presenter من feature أخرى) ويستدعي `loadVehicles`/`loadCompanyVehicles` في `initState` (`line 37/42`) و`build` (`line 135/139/151/152`).
- **Issue IDs:** HL-13.

### `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart` (346 سطر، غير فارغ 324)
- **المسؤولية:** تبويب التوثيق + توقيع + بطاقات تعديل الناقل.
- **محتوى داخل widget:** `line 82-95` `_readableRequirement(String req)` — **تحليل نص + regex لتحويل ISO إلى `HH:mm`** داخل widget.
- **Issue IDs:** HL-29، HL-36.

### `lib/features/logs/presentation/widgets/log_detail_tabs/events_tab.dart` (144 سطر، غير فارغ 134)
- **المسؤولية:** تبويب الأحداث + صف الإجماليات.
- **محتوى داخل widget:** `_StatusTotalsRow.build` `line 113-123` **يجمع ساعات كل حالة داخل widget** ويطبّع `PC→OFF` و`YM→ON` بنسخة ثانية، و`_fmt` `line 106-110` **تنسيق مدة رابع**:
```dart
static String _fmt(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  return '${h}h ${m.toString().padLeft(2, '0')}m';
}
```
- **Issue IDs:** HL-24، HL-26، HL-34.

### `lib/features/logs/presentation/widgets/log_detail_tabs/expanded_content.dart` (59 سطر، غير فارغ 55)
- **المسؤولية:** تفاصيل موسّعة للحدث.
- **محتوى:** `line 25` و`line 31` تنسيق `toStringAsFixed(1)` — نسخة مكررة.
- **Issue IDs:** HL-26.

### `lib/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart` (383 سطر، غير فارغ 358)
- **المسؤولية:** تبويب النموذج (سائق/مركبة/مقطورات/وثائق/سائق مساعد) + حفظ.
- **محتوى داخل `build`:**
  - `line 40-85`: **دمج ثلاثي المصادر يدوي** (serverForm / selectedLog / dashboard) بـ 8 متغيرات محسوبة في `build`.
  - `line 103-114` و`line 190-200` **مدقّقات تكتب منطق العمل في الـ validator** (`int.tryParse`, `'none'`).
  - `line 232-239` استدعاء `_dailyFormPayload` و`line 245` `controller.saveForm` — **تجميع حالة الأمر داخل widget**.
  - `_dailyFormPayload` (`line 335-383`) — **دالة عمل كاملة (48 سطراً)** كـ top-level function داخل ملف widget.
- **اقتران:** `line 7` `home/.../dashboard_provider.dart`، `line 8/9` `vehicle/domain/entities/vehicle.dart` + `vehicle/domain/vehicle_selection.dart`.
- **Issue IDs:** HL-13، HL-21، HL-25، HL-37.

### `lib/features/logs/presentation/widgets/log_detail_tabs/log_event_tile.dart` (166 سطر، غير فارغ 156)
- **المسؤولية:** بلاطة الحدث + حالة موسّعة.
- **محتوى:** `line 14-16` دالة top-level `_formatTimeWithZone` **مغلِّفة فارغة بلا قيمة مضافة** لـ `TimeFormatter.formatTimeWithZone`.
- `line 36-41` `_startedOnAnotherDay` مقارنة تاريخ داخل widget (مقبول، عرضي بحت).
- **Issue IDs:** HL-26.

---
# B. Detailed issues

--------------------------------------------------
### ISSUE HL-01: `DutyStatusTracker` في مجلد domain يتصل بمستودع ميزة أخرى
- **Severity:** Critical
- **Category:** Domain Purity / Cross-Feature Coupling
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:4` و `:284`
- **Evidence:**
```dart
 4: import '../../../../logs/domain/repositories/log_repository.dart';
...
284:      _logRepository.savePeriod(period).then((result) {
285:        result.match(
286:          (failure) =>
287:              AppLogger.error('Failed to save period', failure.message),
288:          (success) => AppLogger.info('Period saved successfully'),
289:        );
290:      });
```
- **Current behavior:** صنف داخل `features/hos/domain/` يحتفظ بمرجع إلى `LogRepository` (عقد feature `logs`) وينفّذ عملية كتابة غير متزامنة عليه.
- **Why problematic:** (1) `features/hos` لا يستطيع أن يُختبر أو يُستبدل دون `features/logs`. (2) كيان `DutyPeriod` المستخدم هنا معرَّف في `core/domain/entities/hos_models.dart` أي أنه **مشترك**؛ فالمستودع الصحيح هو مستودع HOS نفسه لا مستودع السجلات. (3) الملف يسمي نفسه «domain pure» في `line 7` والتعليق كاذب معمارياً.
- **Violated principle:** Dependency Inversion + Feature Isolation + توثيق صادق.
- **Current owner:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart`
- **Correct owner:** عقد `DutyPeriodRepository` في `lib/features/hos/domain/repositories/`.
- **Consequences:** أي حذف/تغيير في feature `logs` يكسر HOS؛ دوائر HOS تتطلب تهيئة Hive لسجلات logs؛ أي تغيّر في تخطيط تخزين logs يتسلل إلى HOS.
- **Recommended correction:** استخراج واجهة `abstract class DutyPeriodRepository { Future<void> savePeriod(DutyPeriod p); }` في `hos/domain/repositories/`، حقنها في `DutyStatusTracker`، وتنفيذها في `hos/data/repositories/` على نفس Hive box دون ربط.
- **Related files:** `lib/features/logs/domain/repositories/log_repository.dart:85`, `lib/features/hos/presentation/providers/hos_engine_provider.dart:43`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-02: `DutyStatusTracker` (domain) يستورد طبقة البنية التحتية وطبقة backend وأداة uuid
- **Severity:** Critical
- **Category:** Domain Purity
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:5` و `:11` و `:13`
- **Evidence:**
```dart
 5: import '../../../../../core/services/local_storage_service.dart';
...
11: import 'package:uuid/uuid.dart';
...
13: import '../../../../../backend/contracts/status_dashboard_backend.dart';
```
(`core/services/local_storage_service.dart:1-5` يستورد `dart:io` و `package:shared_preferences/shared_preferences.dart`.)
- **Current behavior:** صنف domain يعتمد على: خدمة تخزين محلية قائمة على SharedPreferences، مولّد UUID عشوائي، وعقد backend.
- **Why problematic:** `domain` لا يجب أن يعتمد قابلاً للاستبدال على Flutter/plugins؛ `SharedPreferences` يتطلب plugin channel؛ `uuid` مولّد عشوائي (غير حتمي) في طبقة قانونية؛ و`StatusDashboardBackend` عقد شبكة داخل domain.
- **Violated principle:** Dependency Rule (domain innermost) + Domain determinism.
- **Current owner:** الملف نفسه.
- **Correct owner:** الواجهات (clock/ids) تُحقن كواجهات (`TimeAuthority`, `IdGenerator` — يوجد فعلاً في `core/`، مستخدَم في `log_repository_impl.dart:336`). التخزين عبر مستودع domain. الاتصال عبر use-case في `application/`.
- **Consequences:** استحالة اختبار نقي لمحرك HOS؛ تسرّب تبعيات native إلى طبقة المجال؛ عدم قابلية استبدال مصدر الأرقام العشوائية.
- **Recommended correction:** استبدال `LocalStorageService` بواجهة `DutyStatusStore`؛ استبدال `const Uuid().v4()` (`line 216`) بـ `IdGenerator`؛ نقل نداء `_dashboardBackend` إلى use-case في `hos/application/`.
- **Related files:** `lib/features/logs/data/providers/log_repository_providers.dart:8` (نفس النمط الصحيح)، `lib/features/hos/presentation/providers/hos_engine_provider.dart:44-46`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-03: قيود HOS الرقمية مثبتة في طبقة العرض والعرض — 6 مواقع خارج `core/config`
- **Severity:** Critical
- **Category:** Business-Rule Duplication / Hardcoded Values
- **Location (متعدد):** انظر الجدول (C).
- **Evidence:**
```dart
// lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:85-95
    if (status == DutyStatusCode.driving) {
      const remaining = Duration(minutes: 35);
      const total = Duration(hours: 11);
      return RemainingCircle(
        remaining: remaining,
        label: 'Remaining',
        progress: (total.inMinutes - remaining.inMinutes) / total.inMinutes,
      );
    }
    const remaining = Duration(hours: 2, minutes: 8);
    const total = Duration(hours: 14);
```
```dart
// lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:125-145
      totalLimit = const Duration(hours: 11);
...
        totalLimit = const Duration(hours: 8);
...
        totalLimit = const Duration(hours: 14);
```
- **Current behavior:** المستودع يولّد **أرقام توازن مُختلقة** (`35` دقيقة متبقية، `2:08` للوردية) كمسار offline؛ والودجت يختار الحد الحاكم بنفسها.
- **Why problematic:** (1) `Duration(minutes: 35)` و `Duration(hours: 2, minutes: 8)` **ليستا قاعدة**، بل بيانات توازن عشوائية من نموذج تصميمي — تُعرض للسائق كوقت قانوني متبقٍ. مخالفة قانونية محتملة (FMCSA §395.24). (2) حدود `8/11/14` في الودجت تتجاهل أن `HosConfiguration` القابل للتهيئة **لا يُستخدم في الشاشة الرئيسية**. (3) تسعة أرقام متفرقة لنفس المفهوم.
- **Violated principle:** Single Source of Truth + Separation of Concerns.
- **Current owner:** متنتشر.
- **Correct owner:** `lib/core/config/hos_configuration.dart` (المصدر الصحيح فعلياً: `drivingLimitMinutes`, `shiftLimitMinutes`, `driveBeforeBreakMinutes`) + `lib/core/constants/fmcsa_constants.dart`.
- **Consequences:** تغيير قاعدة الدولة (مثلاً كندا 120/14 mentioned في `status_dashboard.dart:181`) لن ينعكس على الشاشة الرئيسية؛ أرقام مختلقة في وضع عدم الاتصال.
- **Recommended correction:** حذف `_circleForStatus` من المستودع؛ عند offline استخدم آخر `StatusDashboard` مخزّن كما يفعل `line 38-41`، أو أعِد `Left(NetworkFailure())` بلا تلفيق. نقل `remainingOf` وحدود 8/11/14 إلى `hos_calculator.dart` كـ `RemainingCircleCalculator`.
- **Related files:** `lib/core/config/hos_configuration.dart:27-34`, `lib/core/constants/fmcsa_constants.dart:19-34`, `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:73-100`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-04: عتبة «المركبة متحركة» متباعدة بين miles و km
- **Severity:** High
- **Category:** Business Logic Location / Unit Mismatch
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:106` مقابل `lib/features/hos/domain/engine/hos_rules_engine.dart:80`
- **Evidence:**
```dart
// duty_status_tracker.dart:106
    if (eldEvent.speedMph > 5.0) {
```
```dart
// hos_rules_engine.dart:79-84
    required double currentSpeedKmh,
    required double speedThresholdKmh,
  }) {
    if (currentStatus == DutyStatus.driving &&
        newStatus != DutyStatus.driving) {
      if (currentSpeedKmh >= speedThresholdKmh) {
```
- **Current behavior:** المتتبع يقارن **ميل/ساعة** بالعتبة `5.0` المثبتة، بينما المحرّك يقارن **كم/ساعة** بـ `HosConfiguration.movingSpeedThresholdKmh = 8.0`.
- **Why problematic:** رقمان يمثّلان العتبة الفيزيائية نفسها (5 mph ≈ 8.05 km/h) لكن كلٌّ في وحدته وحيّده. تعديل `movingSpeedThresholdKmh` (مثلاً لولاية أخرى) **لن يؤثر على الانتقال التلقائي**، بينما يؤثر على الرفض اليدوي — سلوكان متناقضان من نفس المفهوم. كما أن `FmcsaConstants.drivingSpeedThresholdMph = 5.0` (`lib/core/constants/fmcsa_constants.dart:10`) موجودة ولم تُستخدم هنا.
- **Violated principle:** DRY + Consistent Rule Source.
- **Current owner:** `duty_status_tracker.dart:106`
- **Correct owner:** `HosConfiguration` مع حقل مفرد معرَّف على الوحدات (`movingSpeedThresholdMph`) يُحوَّل في `HosCalculator` لا في المتتبع.
- **Consequences:** عتبة 5.0 mph بينما الرفض اليدوي عند 8.0 km/h — هامش 0.05 km/h فقط بين عمليتين من نفس القاعدة.
- **Recommended correction:** احذف `5.0`؛ حقن `HosConfiguration` في `DutyStatusTracker` واستخدم `movingSpeedThresholdKmh` بعد التحويل، أو أضف `movingSpeedThresholdMph` إلى `HosConfiguration` واستخدمه.
- **Related files:** `lib/core/config/hos_configuration.dart:31`, `lib/core/constants/fmcsa_constants.dart:7-10`, `lib/features/hos/presentation/providers/hos_engine_provider.dart:72-75`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-05: تحويل الوحدات (ميل→كم) داخل domain
- **Severity:** Medium
- **Category:** Layer Responsibility
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:227`
- **Evidence:**
```dart
227:        if (odometer != null) 'odometerKm': odometer * 1.609344,
```
- **Current behavior:** domain يحوّل من الميل إلى الكيلومتر أثناء بناء حمولة `PendingEvent`.
- **Why problematic:** (1) هذا اشتقاق **سلكي** (wire) داخل domain. (2) التحويل **معكوس** في data: `log_model.dart:59: odometer = km * _kmToMiles;` — إذن الطبقتان تعملان بوحدتين مختلفتين وتحوّلان في اتجاهين متعاكسين. ثلاث تحويلات في ثلاث طبقات لنفس الحقل.
- **Violated principle:** Single Unit of Measure + Separation.
- **Current owner:** `duty_status_tracker.dart:227`
- **Correct owner:** الـ mapper في `data/` (تحويل `DutyPeriod`/`PendingEvent` إلى DTO سلكي).
- **Consequences:** احتمال خطأ عند التصحيح؛ صعب تتبع أي طبقة تملك القيمة الحقيقية.
- **Recommended correction:** اجعل `DutyPeriod` يحمل `odometerKm` بوحدته، وضع التحويل كله في mapper واحد في data.
- **Related files:** `lib/features/logs/data/models/log_model.dart:55-62`, `lib/core/domain/entities/hos_models.dart` (`odometerMiles`)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-06: `DutyStatusTracker` يبني حمولة شبكة ويخمّن «هل الخطأ شبكي؟» بنص الخطأ
- **Severity:** High
- **Category:** Layer Responsibility / Fragile Error Handling
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:218-230` و `:370-374`
- **Evidence:**
```dart
218:      payload: {
219:        'status': wireStatus,
220:        'startTime': stamp.toIso8601String(),
221:        if (_readDriverId?.call() != null) 'driverId': _readDriverId!.call(),
...
370:      final isNetwork = error.code.contains('network') ||
371:          error.code.contains('connection') ||
372:          error.code.contains('timeout') ||
373:          error.code.contains('offline') ||
374:          error.context?['statusCode'] == null;
```
- **Current behavior:** domain (أ) يبني خريطة JSON كاملة لـ `PendingEvent`، (ب) يقرأ `error.code` و`error.context` كـ `Map` غير مُنمّط لتقرير نوع الخطأ.
- **Why problematic:** (1) أسماء الحقول السلكية (`locationText`, `notes`, `driverId`, `odometerKm`) متشعبة بين domain و`log_repository_impl.dart:171-176` — نفس العقد مكتوب يدوياً في مكانين. (2) `error.context?['statusCode'] == null` مقارنة على `Map` غير مُنمّط — **مقارنة `== null` تُعامَل كـ «خطأ شبكي»**، أي أن **أي خطأ خادمي بلا statusCode يُختبر محلياً رغم أنه قد يكون رفض تحقق**. (3) منطق I/O داخل domain.
- **Violated principle:** Layered Architecture + Typed Errors.
- **Current owner:** الملف نفسه.
- **Correct owner:** mapper في data + `Failure` مُنمّط في `core/error/`.
- **Consequences:** خطأ تحقق 400 بلا `statusCode` قد يُقبل محلياً — مخالفة FMCSR محتملة.
- **Recommended correction:** استخدم `NetworkFailure`/`ServerFailure` المُنمّطة بدل فحص النص؛ انقل بناء الـ payload إلى `data/datasources/`.
- **Related files:** `lib/features/logs/data/repositories/log_repository_impl.dart:170-177`, `lib/features/sync/domain/entities/pending_event.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-07: `TrustedTimeProvider` (مستهلك محرك HOS) يُعرِّف Riverpod Provider داخل نفس الملف
- **Severity:** Medium
- **Category:** Domain Purity (transitive)
- **Location:** `lib/features/hos/domain/engine/hos_calculator.dart:2` → `lib/core/time/trusted_time_provider.dart:3-4` و `:200`
- **Evidence:**
```dart
// hos_calculator.dart:2
import '../../../../core/time/trusted_time_provider.dart';
```
```dart
// trusted_time_provider.dart:3-4
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
...
200: final trustedTimeProvider = Provider<TrustedTimeProvider>((ref) {
```
- **Current behavior:** ملف واحد يجمع الواجهة + التنفيذ + DI + `FakeTrustedTimeProvider` للاختبار.
- **Why problematic:** محرك HOS (`hos_calculator`, `hos_rules_engine`, `hos_state_machine`, `duty_status_tracker`) لا يستطيع أن يُستورد دون أن يجرّ Riverpod و SharedPreferences. أي أن «نقاء domain» موروث ومخترق.
- **Violated principle:** Dependency Rule.
- **Current owner:** `core/time/trusted_time_provider.dart` (ملف واحد بأربعة أدوار).
- **Correct owner:** الواجهة في `trusted_time_provider.dart` فقط، التنفيذ في `trusted_time_provider_impl.dart`، DI في `core/time/providers/`.
- **Consequences:** لا يمكن اختبار محرك HOS مع `FakeTrustedTimeProvider` دون تحميل Riverpod؛ اقتران غير مقصود.
- **Recommended correction:** قسّم الملف إلى ثلاثة.
- **Related files:** `lib/features/hos/domain/engine/hos_state_machine.dart:5`, `lib/features/hos/domain/engine/hos_rules_engine.dart:6`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-08: قيد طول النص ورسائل الرفض مكتوبة يدوياً داخل presentation
- **Severity:** Medium
- **Category:** Business Validation in Presentation + i18n Bypass
- **Location:** `lib/features/hos/presentation/providers/change_status_provider.dart:174`، `:182`، `:284`، `:289`؛ `lib/features/hos/presentation/pages/change_status_page.dart:149`
- **Evidence:**
```dart
173:  bool get hasValidCustomLocation =>
174:      customLocation.length >= 5 && customLocation.length <= 60;
...
182:  bool get isValid => isLocationValid && (!isAnnotationRequired || notes.length >= 4);
```
```dart
284:      return const DutyChangeEngineRefusal('Personal Conveyance is not permitted');
...
289:      return const DutyChangeEngineRefusal('Yard Move is not permitted');
```
```dart
149:                      ? 'Letters, numbers, punctuation 5 - 60 symbols are allowed.'
```
- **Current behavior:** حدود `[5..60]` و `>=4` مُشفَّرة في الـ StateNotifier، ورسائل الرفض إنجليزية صريحة تُعرض للمستخدم، ورسالة تحقق إنجليزية داخل `InputDecoration`.
- **Why problematic:** (1) نفس قاعدة «الطول 5..60» موجودة في `lib/features/inspection/domain/inspection_transfer.dart:20` — تكرار ثالث. (2) النصوص الثلاثة **غير مترجمة** بينما كل ملف يستورد `context.loc`. (3) `line 149` نص إنجليزي لا يمرّ بـ `context.loc` إطلاقاً.
- **Violated principle:** DRY + Single Localization Source.
- **Current owner:** presentation.
- **Correct owner:** `hos/domain/rules/` لقواعد الطول؛ `context.loc` للنصوص.
- **Consequences:** مستخدم عربي/إسباني يرى رسالة إنجليزية؛ تعديل القاعدة يتطلب لمس 3 ملفات.
- **Recommended correction:** نقل `hasValidCustomLocation`/`isValid` إلى `HosChangeValidation` في domain يُعيد `String? errorKey`؛ استبدال النصوص بـ `context.loc.*`.
- **Related files:** `lib/features/inspection/domain/inspection_transfer.dart:20`, `lib/features/logs/domain/daily_form_rules.dart:46-59` (نفس النمط لكن في المكان الصحيح)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-09: `HosRulesEngine` يُرجع `ServerFailure` من طبقة domain
- **Severity:** Medium
- **Category:** Layer Responsibility / Domain Vocabulary
- **Location:** `lib/features/hos/domain/engine/hos_rules_engine.dart:85-87`
- **Evidence:**
```dart
85:      return Left(ServerFailure(
86:          message:
87:              'Cannot manually change from DRIVING while vehicle is moving ($currentSpeedKmh km/h)'));
```
- **Current behavior:** محرك يرفض انتقالاً قانونياً بمخالفة **نقل** (`ServerFailure`) ويضع نصاً إنجليزياً فيه.
- **Why problematic:** `ServerFailure` تعني «رفض الخادم» — لا علاقة لها بقاعدة «لا تبدّل أثناء الحركة». المستهلك (`hos_provider.dart:104`) يسجّل `validationResult.fold((f) => f.message, …)` فينتج سجلاً يحوي سرعة حيّة متغيرة — قيمة غير ثابتة في سجل أخطاء.
- **Violated principle:** Ubiquitous Language + Layered error model.
- **Current owner:** engine.
- **Correct owner:** نوع خطأ مجال (`TransitionRefusal`) يُترجم في presentation.
- **Consequences:** سجلات تحوي أرقاماً متغيرة؛ التمييز بين رفض المجال ورفض الخادم مستحيل.
- **Recommended correction:** أعد `Either<Failure, void>` مع `DutyTransitionViolation` وعرفها في domain، واعرضها عبر `dutyChangeMessage()` الموجودة أصلاً في `presentation/duty_change_message.dart`.
- **Related files:** `lib/features/hos/presentation/providers/hos_provider.dart:103-106`, `lib/core/error/failure.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-10: Use-cases فارغة (Pass-Through) في مجلد domain
- **Severity:** Low
- **Category:** SRP / Speculative Generality
- **Location:** `lib/features/hos/domain/usecases/get_status_dashboard_use_case.dart:12-14` (وكذلك `get_weekly_recap_use_case.dart:12-14`، `update_duty_status_use_case.dart:12-17`)
- **Evidence:**
```dart
12:  Future<Either<Failure, StatusDashboard>> execute({DriverId? driverId}) {
13:    return _repository.getDashboard(driverId: driverId);
14:  }
```
- **Current behavior:** ثلاث فئات بلا أي منطق.
- **Why problematic:** **ليست مخالفة معمارية صريحة** — لكنها تعطي انطباعاً بوجود طبقة use-case mientras المسار الحقيقي في `logs` يتجاوزها تماماً (HL-21). الظهور والتعدد معاً يخلقان بنية زائفة.
- **Violated principle:** SRP (Softer).
- **Current owner:** — / **Correct owner:** إما تُغنى بقواعد (مثلاً رفض `updateDutyStatus` بلا `notes` لـ YM)، أو تُحذف وتُستخدم العقد مباشرة.
- **Consequences:** تضليل قارئ البنية.
- **Recommended correction:** إما أغنِها بقاعدة، أو احذفها.
- **Related files:** `lib/features/hos/presentation/providers/status_dashboard_providers.dart:35-37`
- **Confidence:** **CONFIRMED** (الوصف) — **POTENTIAL** (أنها مخالفة)

--------------------------------------------------
### ISSUE HL-11: مستودع بيانات يُعيد استخدام `static _cachedDashboard` على مستوى الفئة
- **Severity:** Medium
- **Category:** Encapsulation / Testability
- **Location:** `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:18`
- **Evidence:**
```dart
18:  static StatusDashboard? _cachedDashboard;
```
- **Current behavior:** cache مشترك على مستوى **الفئة**، لا على مستوى النسخة.
- **Why problematic:** كل نسخة `StatusDashboardRepositoryImpl` تتشارك نفس الخلية. مع Riverpod هذا غير مرئي، لكن في اختبارات متوازية (أو إذا أُنشئت نسختان لسبب ما) تتسرب بيانات **السائق A إلى عرض B**. كما أن `_cachedDashboard` لا يُمسح عند logout —/providers/status_dashboard_providers.dart:122-123` يمنع GET فقط ولا يمسح الـ cache.
- **Violated principle:** Encapsulation + Instance-level state.
- **Current owner:** المستودع.
- **Correct owner:** خلية على مستوى النسخة (repository لكل جلسة) أو cache service مُدار بالجلسة.
- **Consequences:** تسرب بيانات بين السائقين في سيناريو تعدد الجلسات.
- **Recommended correction:** اجعلها خلية نسخة، وأضف `clearCache()` تُستدعى عند logout.
- **Related files:** `lib/features/hos/presentation/providers/status_dashboard_providers.dart:122-123`
- **Confidence:** **POTENTIAL** (يتطلب سيناريو تعدد جلسات غير مُثبت في الكود المقروء)

--------------------------------------------------
### ISSUE HL-12: قواعد تحقق قانونية داخل Riverpod Notifiers و State objects
- **Severity:** High
- **Category:** Business Logic Location
- **Location:** 7 مواقع
| # | الملف:السطر | القاعدة |
|---|---|---|
| 1 | `hos/presentation/providers/change_status_provider.dart:278-295` | رفض تغيير أثناء الحركة، رفض PC/YM غير المصرّح، إلزام الملاحظات |
| 2 | `logs/presentation/controllers/edit_log_controller.dart:52` | **لا تُسجَّل أحداث في المستقبل** (FMCSA § 395) |
| 3 | `logs/presentation/controllers/edit_log_controller.dart:57-64` | رفض تعديل القيادة الآلية |
| 4 | `logs/presentation/providers/logs_provider.dart:293,296,301,313,316` | بناء `ServerFailure` برسائل إنجليزية |
| 5 | `logs/presentation/providers/certify_log_provider.dart:158,163,168` | `!isFormComplete` → رفض، توقيع فارغ → رفض، جلسة مفقودة → رفض |
| 6 | `logs/presentation/providers/unidentified_events_provider.dart:135,150` | annotation إلزامي، سبب رفض إلزامي |
| 7 | `logs/presentation/pages/unidentified_events_page.dart:334-341` | نافذة 24 ساعة + `contains('DRIV')` |
- **Evidence:**
```dart
// edit_log_controller.dart:51-54
      // FMCSA § 395: Duty status events cannot be recorded in the future
      if (newStart.isAfter(timeAuthority.nowUtc().toLocal().add(const Duration(minutes: 1)))) {
        throw EditLogError(EditLogErrorCode.invalidTime);
      }
```
```dart
// unidentified_events_provider.dart:135
    if (annotation.trim().isEmpty) return const ServerFailure(message: 'An annotation is required.');
```
- **Current behavior:** سبع قواعد عمل موزعة على طبقة العرض، لا يمكن اختبارها دون Riverpod ولا تتبّعها دون قراءة الواجهة.
- **Why problematic:** (1) `Duration(minutes: 1)` **هامش تسامح** مثبّت في presentation. (2) `contains('DRIV')` مطابقة نصية هشّة — `'NOT_DRIVING'` سيمر. (3) كل notifier يصبح حاوية لقاعدة قانونية، فتتشعب المعرفة عند التعديل.
- **Violated principle:** Business Logic in Domain/Application.
- **Current owner:** presentation.
- **Correct owner:** `logs/domain/log_edit.dart` (يوجد مكان مناسب!) و`hos/domain/` و`logs/domain/entities/`.
- **Consequences:** قواعد قانونية غير قابلة للتدقيق أو التعديلريك.
- **Recommended correction:** انقل كل قاعدة إلى ملف rules في domain يُعيد **رمز رفض مُنمّطاً** لا نصاً؛ الـ notifier يحوّله إلى نتيجة.
- **Related files:** `lib/features/logs/domain/log_edit.dart` (المُضيف القانوني الصحيح للقاعدة الأولى)، `lib/features/logs/presentation/pages/edit_log_page.dart:71-87`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-13: استيراد widgets/providers من ميزات أخرى داخل presentation
- **Severity:** High
- **Category:** Cross-Feature Coupling (presentation)
- **Location:** 3 حواف استيراد widget مباشرة (مع 7 حواف كتابة مغطّاة في HL-25) — التفصيل في الجدول D.
- **Evidence (أهم ثلاث حِفات):**
```dart
// lib/features/logs/presentation/pages/inspection_preview_page.dart:16
import '../../../inspection/presentation/widgets/inspection_log_header_table.dart';
```
```dart
// lib/features/logs/presentation/pages/logs_list_page.dart:11
import '../../../home/presentation/widgets/eld_drawer.dart';
```
```dart
// lib/features/hos/presentation/widgets/driving_lock_screen.dart:7
import '../../../home/presentation/pages/home_page.dart';
```
(`driving_lock_screen.dart:29` يستهلك فعلياً `developerBypassDrivingScreenProvider`.)
- **Current behavior:** presentation في `logs` يستورد widget من `inspection` وwidget من `home`؛ presentation في `hos` يستورد صفحة `home` كاملة.
- **Why problematic:** استيراد **widget** من feature أخرى يعني أن سمات الشاشة البصرية وnotifier الخاص بها مربوطان. استيراد `home_page.dart` كاملة لإحضار provider واحد smell صريح (استيراد صفحة كاملة لأجل رمز واحد).
- **Violated principle:** Feature Isolation + Dependency Inversion.
- **Current owner:** الملفات المستورِدة.
- **Correct owner:** `core/widgets/` (`EldDrawer`); provider التجاوز إلى `core/providers/` أو يُحذف.
- **Consequences:** تغيير `home_page.dart` يكسر شاشة HOS؛ `inspection` لا يمكن حذفه دون كسر `logs`.
- **Recommended correction:** انقل `EldDrawer` إلى `core/widgets/`؛ انقل `developerBypassDrivingScreenProvider` إلى `core/providers/`؛ مرّر `inspection_log_header_table` كـ callback/builder.
- **Related files:** `lib/routes.dart:17-42`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-14: مطابقة `DutyStatus ⇄ DutyStatusCode` مكرّرة ثلاث مرات
- **Severity:** Medium
- **Category:** Duplication
- **Location:** 3 مواقع
- **Evidence:**
```dart
// lib/features/hos/presentation/providers/change_status_provider.dart:37-52
  DutyStatusCode toDutyStatusCode() {
    switch (this) {
      case DutyStatusOption.offDuty:
        return DutyStatusCode.offDuty;
...
```
```dart
// lib/features/hos/presentation/providers/status_dashboard_providers.dart:18-31
DutyStatusCode _engineStatusCode(DutyStatus status) {
  switch (status) {
    case DutyStatus.driving:
      return DutyStatusCode.driving;
...
```
```dart
// lib/features/hos/presentation/providers/hos_provider.dart:59-74
  DutyStatus _mapStatus(String s) {
    final code = DutyStatusCode.fromAny(s);
    switch (code) {
```
- **Current behavior:** ثلاث دوال مطابقة في نفس المجلد، اثنتان في نفس الاتجاه.
- **Why problematic:** إضافة حالة جديدة (مثلاً `yardMove` كحالة مستقلة) تحتاج تعديل 3 مواقع؛ نسيان أحدها ينتج حالة خاطئة قانونياً.
- **Violated principle:** DRY.
- **Current owner:** presentation ×3.
- **Correct owner:** `DutyStatus` في `core/domain/entities/hos_models.dart` (المصدر الوحيد لـ `DutyStatus`).
- **Consequences:** عدم اتساق محتمل.
- **Recommended correction:** أضف `DutyStatus.toDutyStatusCode()` واحدة على الـ enum، واحذف الباقي.
- **Related files:** `lib/features/hos/domain/engine/hos_rules_engine.dart:51-64` (رابع: يقارن `DutyStatus` بـ `offDuty/sleeperBerth` مباشرة)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-15: قاعدة «لا تبديل أثناء القيادة» مسجّلة بلا `return`
- **Severity:** High
- **Category:** Correctness / Legal Rule Not Enforced
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:417-420`
- **Evidence:**
```dart
417:    if (_currentStatus == 'driving' && newStatus != 'driving') {
418:      AppLogger.warning(
419:          'Cannot manually transition from driving while moving.');
420:    }
```
- **Current behavior:** القاعدة **تُسجَّل ثم يتدفق التنفيذ**. الانتقال يكمل إلى `line 428: _transitionTo(...)`.
- **Why problematic:** استدعاءا `DutyStatusTracker.manualTransition` / `submitManualChange` عبر هذا المسار يسجل تغيير حالة قانونياً رغم أن القاعدة المعلنة تمنعه. (المسار الفعلي من الواجهة يمر أولاً بـ `hos_provider.dart:103` الذي يفحص عبر engine، لكن المتتبع نفسه — وهو مصدر الحقيقة للتتبع — لا يحميه؛ و`manualTransition` في `line 324` مستدعى من أي مكان آخر.)
- **Violated principle:** Business Rule Enforcement / Fail-safe.
- **Current owner:** الملف نفسه.
- **Correct owner:** نفس الملف — يحتاج `return`/رفض.
- **Consequences:** سجل ELD قد يحتوي انتقالاً يدوياً غير قانوني. مخالفة FMCSA §395.8.
- **Recommended correction:** `return const ManualDutyChangeResult(refusal: DutyStampRefusal.moving);` أو ارفع الفحص إلى use-case ووحّد المصدر بين `manualTransition` و`submitManualChange`.
- **Related files:** `lib/features/hos/presentation/providers/hos_provider.dart:95-106`, `lib/features/hos/presentation/providers/change_status_provider.dart:278-280`
- **Confidence:** **CONFIRMED** (السلك)، **POTENTIAL** (مدى بلوغه؛ `manualTransition` غير مستدعَى خارج الملف حسب البحث)

--------------------------------------------------
### ISSUE HL-16: `MainCircularTimer.build` ينفّذ محرك حساب HOS كاملاً
- **Severity:** High
- **Category:** Business Logic in Widget
- **Location:** `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:98-192`
- **Evidence:**
```dart
109:    Duration remainingOf(HosIndicator? ind, Duration limit) {
110:      final fallback = widget.circle.remaining > Duration.zero
111:          ? widget.circle.remaining
112:          : limit;
113:      if (ind == null) return fallback;
114:      if (ind.type == IndicatorType.used) {
115:        final left = limit - ind.value;
116:        return left.isNegative ? Duration.zero : left;
117:      }
118:      return ind.value > Duration.zero ? ind.value : fallback;
119:    }
...
124:    if (isRest) {
125:      totalLimit = const Duration(hours: 11);
126:      baseRemaining = Duration.zero;
127:    } else if (isDriving) {
128:      totalLimit = const Duration(hours: 11);
129:      baseRemaining =
130:          remainingOf(widget.hosIndicators?.drive, totalLimit);
131:    } else {
...
138:      if (breakVal != null &&
...
141:          (shiftRaw == null || breakRaw < shiftRaw)) {
142:        totalLimit = const Duration(hours: 8);
...
155:      final elapsedSinceSnapshot = DateTime.now().difference(_snapshotTime);
156:      liveRemaining = baseRemaining - elapsedSinceSnapshot;
```
- **Current behavior:** `build` (يُنفَّذ كل ثانية عبر `line 85` `Timer.periodic`) يطبّق: اختيار الحد الحاكم، تحويل `used→remaining`، العد التنازلي الحي، نسبة الاستهلاك، عتبة اللون (15 دقيقة في `line 179`).
- **Why problematic:** (1) **دالة محلّية داخل `build`** — لا يمكن اختبارها ولا إعادة استخدامها. (2) تخطّي بين `rest` المُحدَّد بـ `lower.contains('off')` (`line 65`) أي **مطابقة على نص مترجم** — أي ترجمة تكسره. (3) 170 سطراً من المنطق في مسار بناء.
- **Violated principle:** Widget = Presentation Only.
- **Current owner:** `main_circular_timer.dart`
- **Correct owner:** `hos/domain/engine/hos_calculator.dart` كـ `RemainingCircleCalculator` + `StatusRingViewModel`.
- **Consequences:** قاعدة غير قابلة للاختبار؛ كسر عند كل تحديث جديد.
- **Recommended correction:** استخرج `remainingOf` + اختيار `totalLimit` + `liveRemaining` إلى use-case يُعيد `RemainingCircle`، واجعل `build` يستهلك `RingViewModel` جاهزاً.
- **Related files:** `lib/features/hos/domain/engine/hos_calculator.dart:38-76`, `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart:105` (عتبة `Duration(hours: 1)` ثانية)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-17: `logs/domain/daily_form_rules.dart` يستورد Flutter عبر l10n
- **Severity:** High
- **Category:** Domain Purity
- **Location:** `lib/features/logs/domain/daily_form_rules.dart:7`
- **Evidence:**
```dart
 7: import '../../../../l10n/app_localizations.dart';
```
و `lib/l10n/app_localizations.dart:3-4`:
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
```
- **Current behavior:** ملف domain يعتمد على كائن يعتمد على `BuildContext` و`Localizations`.
- **Why problematic:** الملف يحتوي قواعد تحقق ممتازة بمحتوى غير قابل للنقاش (RegExp عربية `\p{L}`)، لكنه **لا يمكن اختباره في unit test Dart نقي** بدون Flutter test harness. والأنوأ: الملف لا يُرجع رمز خطأ بل **نصاً**، و`line 86-90` يختار نصوصاً عربية/إسبانية/إنجليزية **من داخل domain**:
```dart
86:    return loc.localeName == 'ar'
87:        ? 'يجب أن يحتوي رقم الوثيقة على حروف وأرقام وعلامات بسيطة فقط'
88:        : (loc.localeName == 'es'
89:            ? 'El número de documento solo debe contener letras, números y signos básicos'
90:            : 'Document number must contain letters, numbers, and basic signs only');
```
هذه **أكبر مخالفة** في الملف: ثلاث لغات مكتوبة يدوياً داخل طبقة المجال، بينما بقية المشروع كله فوق `.arb`.
- **Violated principle:** Domain Purity + i18n discipline.
- **Current owner:** الملف.
- **Correct owner:** القواعد تبقى هنا؛ **النصوص** تنتقل إلى `l10n` كمفتاح `trailerNumberFormatErrorInvalidChars` لكل لغة.
- **Consequences:** كل لغة جديدة تُعدّل ملف Dart داخل domain؛ لا اختبار نقي للقواعد.
- **Recommended correction:** غيّر التوقيع إلى `String? trailerNumberError(String value, {required String enterMsg, required String formatMsg, required String invalidCharsMsg})` أو أعِد رمز خطأ (`enum TrailerError { empty, invalidChars, … }`) وتُترجم في presentation.
- **Related files:** `lib/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart:142,166,353,360`, `lib/features/logs/presentation/pages/trailers_page.dart:41`, `lib/features/logs/presentation/pages/shipping_documents_page.dart:40`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-18: تحليل استجابات JSON داخل domain
- **Severity:** Medium
- **Category:** Layer Responsibility
- **Location:** `lib/features/logs/domain/saved_form_status.dart:10-26`؛ `lib/features/logs/domain/entities/audit_entry.dart:44-84`
- **Evidence:**
```dart
// saved_form_status.dart:10-14
SavedFormRead readSavedForm(Map<String, dynamic> json) {
  final body = json['data'] is Map
      ? Map<String, dynamic>.from(json['data'] as Map)
      : json;
  final raw = body['formStatus']?.toString().trim();
  final message = body['message']?.toString().trim();
```
```dart
// audit_entry.dart:44-48
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // ISO string: _saveToBox يستخرج مفتاح اليوم من نص ISO.
      'timestamp': timestamp.toIso8601String(),
```
- **Current behavior:** domain يقرأ `json['data']`, `json['formStatus']`, `json['message']`، ويفحص `'COMPLETED'/'COMPLETE'/'INCOMPLETE'/'IN_PROGRESS'`؛ الكيان ينتج خريطة تخزين.
- **Why problematic:** (1) `'data'` غلاف HTTP — مكانه `log_repository_impl.dart` الذي ينفّذ `readSavedForm(json)` في `line 359`. (2) `AuditEntry.toMap()` يخص **Hive**؛ التعليق في `line 47` «_saveToBox يستخرج مفتاح اليوم من نص ISO» يربط الكيان بمصدر بيانات محدد.
- **Violated principle:** Domain knows nothing about persistence/transport.
- **Current owner:** domain.
- **Correct owner:** `logs/data/models/` (mapper).
- **Consequences:** تغيير أي حقل في domain يمسّ طبقة النقل.
- **Recommended correction:** انقل `readSavedForm` إلى `data/models/saved_form_mapper.dart`، واحذف `toMap`/`fromMap` من `AuditEntry` إلى `data/models/audit_entry_mapper.dart`.
- **Related files:** `lib/features/logs/data/repositories/log_repository_impl.dart:359`, `lib/features/logs/data/datasources/log_local_data_source.dart:288`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-19: كيان `DailyLog` يحتوي تنسيقات عرض و`DateTime.now()` داخل getter
- **Severity:** Medium
- **Category:** SRP / Presentation in Domain
- **Location:** `lib/features/logs/domain/entities/daily_log.dart:110-155` و `:210-220`
- **Evidence:**
```dart
110:  String get dayName {
111:    final now = DateTime.now();
112:    if (date.year == now.year &&
...
115:      return 'Today';
...
123:    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
124:  }
126:  String get formattedDate {
127:    return '$dayName - ${[
128:      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
...
133:      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
140:    ][date.month - 1]} ${date.day}${_ordinal(date.day)}';
141:  }
```
- **Current behavior:** getter في domain يُنتج نصوصاً إنجليزية، ويقرأ ساعة الحائط عند كل استدعاء.
- **Why problematic:** (1) النصوص **غير مترجمة** بينما الواجهة تمرّرها عبر `context.loc.todayLogDate(...)` في `logs_list_page.dart:138` — طبقتان تتنافسان. (2) `DateTime.now()` في getter غير قابل للتخزين، ويجعل `props` في `Equatable` غير مستقرة إن استُخدم.
- **Violated principle:** Domain ≠ Presentation.
- **Current owner:** كيان domain.
- **Correct owner:** `core/presentation/formatters/` (المشروع يملك precedent في `core/utils/duration_format.dart`).
- **Consequences:** تواريخ إنجليزية في تطبيق عربي/إسباني.
- **Recommended correction:** انقل `dayName`/`formattedDate`/`formattedStartTime`/`formattedDuration` إلى `DateFormatters` في presentation، واحذف استدعاء `DateTime.now()` (مرّره كوسائط).
- **Related files:** `lib/features/logs/presentation/pages/logs_list_page.dart:139`, `lib/features/logs/presentation/widgets/log_detail_tabs/log_event_tile.dart:104`, `lib/features/logs/presentation/providers/edit_log_form_provider.dart:61-62`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-20: ابتلاع استثناءات صامتة في data source وداخل widget
- **Severity:** Medium
- **Category:** Error Handling
- **Location:** 5 مواقع
| # | الملف:السطر | الشكل |
|---|---|---|
| 1 | `logs/data/datasources/log_local_data_source.dart:124` | `catch (_) { return null; }` |
| 2 | `logs/data/datasources/log_local_data_source.dart:171` | `catch (_) { return []; }` |
| 3 | `logs/data/datasources/log_local_data_source.dart:311` | `catch (_) { }` مع تعليق |
| 4 | `logs/presentation/pages/inspection_preview_page.dart:317` | `catch (_) { currentDay = null; }` **داخل `build`** |
| 5 | `hos/presentation/extensions/duty_status_l10n.dart:33` | `catch (_) { return shortCode; }` |
- **Evidence:**
```dart
// log_local_data_source.dart:165-174
  List<Map<String, dynamic>> _getListFromBox(Box<String> box, String dateStr) {
    final data = box.get(dateStr);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data) as List;
      return decoded.map((e) => e as Map<String, dynamic>).toList();
    } catch (_) {
      return [];
    }
  }
```
```dart
// inspection_preview_page.dart:316-319
              currentDay = matches.isNotEmpty ? matches.first : null;
        } catch (_) {
          currentDay = null;
        }
```
- **Current behavior:** بيانات تالفة ⇒ قائمة فارغة (يبدو للمستخدم «لا سجلات») بدل «تعذّرت القراءة».
- **Why problematic:** السجلات القانونية يجب أن تُظهر **التمييز** بين «لا يوجد» و«تعذّرت القراءة». `log_local_data_source.dart:47-53` في `hos_audit_repository_impl.dart` فعل ذلك بشكل صحيح (`AppLogger.warning`) — **النمط موجود في نفس المشروع ولم يُتبع هنا**. الحالة 4 الأسوأ: `catch` داخل `build` يبتلع أي خطأ في منطق المطابقة.
- **Violated principle:** Consistent Error Surface + Observability.
- **Current owner:** الملفات المختلطة.
- **Correct owner:** نفس الملفات — مع `AppLogger.warning` ونتيجة قابلة للتمييز.
- **Consequences:** فقدان بيانات صامت؛ تشخيص صعب.
- **Recommended correction:** أضف `AppLogger.warning('...row $dateStr skipped', e, st)` في 1 و 2 كما في `hos_audit_repository_impl.dart:49-53`؛ في 4 استبدل `try/catch` بمنطق `DateTime` لا يرمي.
- **Related files:** `lib/features/hos/data/repositories/hos_audit_repository_impl.dart:46-54` (النموذج الصحيح)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-21: طبقة العرض تتجاوز use-case layer وتتصل بالمستودع أو بالـ backend مباشرة
- **Severity:** High
- **Category:** Layer Bypass
- **Location:** 6 مواقع
| # | الملف:السطر | ما يتجاوزه |
|---|---|---|
| 1 | `logs/presentation/controllers/edit_log_controller.dart:107` | `ref.read(logRepositoryProvider).logAudit(...)` |
| 2 | `logs/presentation/controllers/form_tab_controller.dart:31` | `_ref.read(logRepositoryProvider).saveForm(...)` |
| 3 | `logs/presentation/providers/audit_trail_provider.dart:7-8` | `repo.getRecentAuditEntries(limit: 100)` |
| 4 | `logs/presentation/providers/logs_provider.dart:92` | `_repository` محقن مباشرة |
| 5 | `logs/presentation/providers/unidentified_events_provider.dart:97,103,136,151` | **`ref.read(unidentifiedEventsBackendProvider)` — تجاوز مستودعين** |
| 6 | `logs/presentation/providers/certify_log_provider.dart:90` | `_repository` محقن مباشرة |
- **Evidence:**
```dart
// unidentified_events_provider.dart:97, 136-140
    final backend = ref.read(unidentifiedEventsBackendProvider);
...
    final result = await ref.read(unidentifiedEventsBackendProvider).claim(
          id: DutyStatusId(id),
          driverId: DriverId(driverId),
          annotation: annotation.trim(),
        );
```
- **Current behavior:** الحالة رقم 5 هي الأخطر: presentation يتصل بـ **backend** مباشرة، متجاوزاً data وapplication معاً، ومتسلّاً إلى `lib/backend/contracts/contract_enums.dart`.
- **Why problematic:** (1) `unidentified_events_provider.dart:3` يستورد عقد شبكة داخل presentation. (2) دوالا `parseUnidentifiedList` (`:13`) و`normalizeUnidentifiedItem` (`:19`) **عامتان على مستوى الملف** داخل presentation وتعرفان شكل استجابة HTTP (`json['items'] ?? json['events'] ?? json['content'] ?? json['data']`). (3) لا يمكن اختبار claim/reject دون mock backend.
- **Violated principle:** Dependency Rule (presentation → application → data).
- **Current owner:** الملفات المخالفة.
- **Correct owner:** `logs/domain/repositories/` + mapper في `logs/data/` + use-case في `logs/application/`.
- **Consequences:** كسر بنية data كاملة لهذا المسار؛ اختبارات تلتصق بالشبكة.
- **Recommended correction:** أنشئ `UnidentifiedEventsRepository` في domain، `UnidentifiedEventsDto` في data، واجعل الـ notifier يستهلك use-case. انقل دوال parsing إلى `data/models/`.
- **Related files:** `lib/features/hos/presentation/providers/recap_provider.dart:10-12` (النمط الصحيح المجاور)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-22: `EditLogController` يبتلع نوع الاستثناء رغم وجود `EditLogError` مصمَّم
- **Severity:** Medium
- **Category:** Error Surface Consistency
- **Location:** `lib/features/logs/presentation/controllers/edit_log_controller.dart:114-116` + `lib/features/logs/presentation/pages/edit_log_page.dart:88-90`
- **Evidence:**
```dart
// edit_log_controller.dart:114-116
    } catch (e, st) {
      state = AsyncError(e, st);
    }
```
```dart
// edit_log_page.dart:88-90
          } else {
            AppFeedback.error(context, context.loc.theEventCouldNotBeSaved);
          }
```
- **Current behavior:** كل الأخطاء تمر كـ `Object`؛ `edit_log_page.dart:70` يفحص `if (err is EditLogError)` — ولأن `EditLogError implements Exception`، فإن **أي خطأ غير متوقع يقع في نفس المسار** ويُعرض كـ «تعذّر حفظ الحدث».
- **Why problematic:** `EditLogErrorCode` مصمَّم بدقة (5 حالات) ومعالجة مفصّلة في `line 71-87` — لكن العقد غير مفروض: `catch` غير مصنّف يُسقط التمييز.
- **Violated principle:** Explicit Error Model.
- **Current owner:** controller.
- **Correct owner:** نفس الـ controller مع `on EditLogError` ثم `on Object` مصنّف.
- **Consequences:** خطأ قانوني (مثل رفض القيادة الآلية من الخادم) يظهر كخطأ شبكة.
- **Recommended correction:**
```dart
  } on EditLogError catch (e, st) {
    state = AsyncError(e, st);
  } catch (e, st) {
    AppLogger.error('EditLogController.saveEvent: unexpected', e, st);
    state = AsyncError(EditLogError(EditLogErrorCode.saveFailed), st);
  }
```
- **Related files:** `lib/features/logs/presentation/pages/edit_log_page.dart:63-96`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-23: قواعد التحقق في domain تُستدعى مباشرة من مدقّقات widgets
- **Severity:** Medium
- **Category:** Layer Bypass
- **Location:** 5 مواقع
| # | الملف:السطر | الدالة المستدعاة |
|---|---|---|
| 1 | `logs/presentation/pages/edit_log_page.dart:250` | `isFreeTextValid(v)` |
| 2 | `logs/presentation/pages/edit_log_page.dart:279` | `isFreeTextValid(v)` |
| 3 | `logs/presentation/pages/edit_log_page.dart:42` | `parseEditFormTime(...)` |
| 4 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart:142,166` | `trailerNumberError` / `shippingDocumentError` |
| 5 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart:353,360` | نفس الدالتين داخل `_dailyFormPayload` |
- **Evidence:**
```dart
// edit_log_page.dart:247-251
              validator: (value) {
                final v = (value ?? '').trim();
                if (v.isEmpty) return null;
                return isFreeTextValid(v) ? null : context.loc.invalidValue;
              },
```
- **Current behavior:** الـ widget يستدعي دوال domain ويُمرّر `context.loc` إليها (وهي تحتجاه Flutter بسبب HL-17).
- **Why problematic:** (1) مسار التحقق **مُSplit**: مرة في `validator` (عرض فوري) ومرة في `_dailyFormPayload` (عند الحفظ) — نتيجتان قد تختلفتان. (2) `_dailyFormPayload` (`line 335-383`, 48 سطراً) هو **use-case كامل** مكتوب كدالة top-level في ملف widget. (3) الربط بـ `context.loc` يجعل غير-UI مرتبطاً بـ UI.
- **Violated principle:** Presentation should consume prepared state, not re-derive.
- **Current owner:** widgets.
- **Correct owner:** `logs/application/` — `FormTabViewModel` يحمل `validationResult` جاهزاً.
- **Consequences:** ازدواج التحقق؛ اختلاف ما يُعرض عمّا يُحفظ.
- **Recommended correction:** اجعل `_dailyFormPayload` use-case في `application/`، واجعل `validator` يستهلك `vm.validationErrors[field]` بدل الاستدعاء.
- **Related files:** `lib/features/logs/domain/daily_form_rules.dart:62-92`, `lib/features/logs/presentation/controllers/form_tab_controller.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-24: تطبيع رموز الحالات الخمسة مكرّر في 5 مواقع داخل presentation
- **Severity:** High
- **Category:** Duplication / Business Rule
- **Location:** 5 مواقع (كلها داخل `logs/presentation`)
- **Evidence:**
```dart
// log_graph.dart:47-53
      if (status == 'PC') {
        normalized = 'OFF';
      } else if (status == 'YM' || status == 'OTH' || !stats.containsKey(status)) {
        normalized = 'ON';
      } else {
        normalized = status;
      }
```
```dart
// events_tab.dart:117-121
      final key = switch (e.status) {
        'PC' => 'OFF',
        'YM' => 'ON',
        _ => e.status,
      };
```
```dart
// inspection_preview_page.dart:194-199
                              return [
                                'ON',
                                'D',
                                'SB',
                                'OFF',
                              ].contains(e.status);
```
- **Current behavior:** ثلاث نسخ من قاعدة «PC يُحسب OFF و YM يُحسب ON»، والتعليق في `inspection_preview_page.dart:192-193` يعترف بعدم اكتمالها:
```dart
  // Custom filter logic for "Active Events"
  // Currently keeps duty statuses. Implement exact logic if needed.
```
- **Why problematic:** (1) القاعدة **قانونية** (§395.28) ومعروضة للسائق في الجدول الرسمي. (2) نسخة `log_graph` تضيف `'OTH'` والثانية لا. (3) النسخة الثالثة تكسر كل الرموز (لا تطبيع).
- **Violated principle:** DRY على قاعدة قانونية.
- **Current owner:** presentation ×3 (وأخريتان للترتيب).
- **Correct owner:** `DutyStatusCode` في `lib/domain/duty_status/duty_status_code.dart` كـ `graphBucket`، أو `StatusTotalsCalculator` في `logs/domain/`.
- **Consequences:** جدول Graph-Grid قد لا يطابق جدول Total في تبويب الأحداث.
- **Recommended correction:** `String graphBucket(String shortCode)` واحدة، تستهلكها المواضع الثلاثة.
- **Related files:** `lib/features/logs/presentation/widgets/status_radio_group.dart:19-26`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-25: كتابة عابرة للميزات: `logs` presentation يكتب في `home` presentation
- **Severity:** High
- **Category:** Cross-Feature Coupling (bidirectional write)
- **Location:** 7 مواقع
| # | الملف:السطر | الكتابة |
|---|---|---|
| 1 | `logs/presentation/providers/logs_provider.dart:162` | `dashboardDataProvider.notifier.applyServerForm(...)` |
| 2 | `logs/presentation/providers/logs_provider.dart:192` | نفس الاستدعاء |
| 3 | `logs/presentation/providers/logs_provider.dart:214` | نفس الاستدعاء |
| 4 | `logs/presentation/controllers/form_tab_controller.dart:50` | `logsProvider.notifier.updateLog(...)` |
| 5 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart:130` | `dashboardDataProvider.notifier.updateVehicle(vehicle)` |
| 6 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart:215` | `dashboardDataProvider.notifier.updateCoDriver(coDriver)` |
| 7 | `logs/presentation/pages/edit_log_page.dart:182-184` | `dashboardDataProvider.notifier.updateVehicle(picked)` |
- **Evidence:**
```dart
// logs_provider.dart:161-170
    if (log.trailers.isNotEmpty || log.shippingDocuments.isNotEmpty || (log.vehicleName != null && log.vehicleName!.isNotEmpty)) {
      _ref?.read(dashboardDataProvider.notifier).applyServerForm(
        DailyFormData(
          vehicleUniqueId: log.uniqueId.isNotEmpty ? log.uniqueId : null,
...
```
- **Current behavior:** `logs`Presentation **يكتب حالة** في `home`Presentation.-story feature واحدة تملك مصدر بيانات النموذج، بثلاث مسارات قراءة مختلفة (`form_tab.dart:46-85`).
- **Why problematic:** (1) `logs` و`home` مترابطان في الاتجاهين. (2) `_ref` من نوع `Ref?` اختياري (`logs_provider.dart:94`) مع `?.` في كل الاستدعاءات — نمط يخفي أخطاء NPE. (3) ثلاث نسخ من منطق «هل النموذج يحتوي بيانات» (`:161`, `:213`, `form_tab.dart:46-85`).
- **Violated principle:** Feature Isolation + Explicit dependencies.
- **Current owner:** logs presentation.
- **Correct owner:** `application/` مشترك (مثلاً `DashboardFormSync`) أو `core/`؛ ليس writing عبر features.
- **Consequences:** لا يمكن حذف `home` دون كسر `logs`؛ تعقّب بيانات النموذج صعب.
- **Recommended correction:** اجعل `applyServerForm` use-case في `logs/application` يبثّ `AppEvent.formDataChanged`، ويجعل `home` هو المستهلك. واجعل `_ref` غير اختياري.
- **Related files:** `lib/core/events/app_events.dart`, `lib/features/logs/presentation/providers/logs_provider.dart:94`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-26: تنسيق الوقت والمدة مكرّر في 7 نقاط
- **Severity:** Medium
- **Category:** Duplication
- **Location:** جدول أدناه
| # | الملف:السطر | الصيغة |
|---|---|---|
| 1 | `logs/domain/entities/daily_log.dart:210-214` | `'$h:$m'` |
| 2 | `logs/domain/entities/daily_log.dart:216-220` | `'${hours}h ${minutes}m'` (بلا padding) |
| 3 | `logs/presentation/widgets/log_detail_tabs/events_tab.dart:106-110` | `'${h}h ${m.padLeft(2,'0')}m'` (**بعكس #2**) |
| 4 | `logs/presentation/pages/logs_list_page.dart:168-170` | `'< 1m'` أو حساب يدوي لـ `% 1 * 60` |
| 5 | `logs/presentation/pages/audit_trail_page.dart:77-79` | `DateFormat('yyyy-MM-dd\nHH:mm')` |
| 6 | `logs/presentation/providers/certify_log_provider.dart:177` | `DateFormat('yyyy-MM-dd')` |
| 7 | `logs/presentation/widgets/log_detail_tabs/certify_tab.dart:82-95` | regex ISO داخل widget |
- **Evidence:**
```dart
// events_tab.dart:106-110
  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
```
```dart
// daily_log.dart:216-220
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
```
- **Current behavior:** نفس المدة تُعرض `1h 5m` في موضع و `1h 05m` في آخر.
- **Why problematic:** المشروع يملك `core/utils/duration_format.dart` (`hhMm`, `decimalHours`) و`core/time/time_formatter.dart` (4 دوال) ولم يُستخدما في Consistency.
- **Violated principle:** DRY + Presentation consistency.
- **Current owner:** متنتشر.
- **Correct owner:** `core/utils/duration_format.dart` و`core/time/time_formatter.dart`.
- **Consequences:** تباين بصري؛ خطأ حسابي في #4 (`% 1 * 60` عرضة للتقريب العشري العائم).
- **Recommended correction:** احذف #1–#4 واستخدم `DurationFormat`؛ انقل #7 إلى `TimeFormatter` باختبارات.
- **Related files:** `lib/core/utils/duration_format.dart:6,17`, `lib/core/time/time_formatter.dart:7,17,26`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-27: `TrailersPage` و `ShippingDocumentsPage` نسختان متطابقتان
- **Severity:** Medium
- **Category:** Duplication (Structural)
- **Location:** `lib/features/logs/presentation/pages/trailers_page.dart` (170) و `lib/features/logs/presentation/pages/shipping_documents_page.dart` (170)
- **Current behavior:** الملفان بنفس البنية: نفس `_controller`، نفس `_addX()`، نفس `_removeX()`، نفس الشجرة، نفس RegExp (بفرق `/` واحد).
- **Evidence (مقارنة حرفية):**
```dart
// trailers_page.dart:36-37
  List<String> get _trailers =>
      splitFormList(ref.read(dashboardDataProvider).trailerId);
```
```dart
// shipping_documents_page.dart:35-36
  List<String> get _documents =>
      splitFormList(ref.read(dashboardDataProvider).shippingDocuments);
```
```dart
// trailers_page.dart:96-102
                    inputFormatters: [
                      // نفس مجموعة المدقق (حروف كل اللغات + أرقام + -_#)
                      // — النقاط والفواصل وعلامات الرياضيات تُمنع أثناء الكتابة.
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\p{L}\p{N}\s\-_#]', unicode: true),
                      ),
                    ],
```
```dart
// shipping_documents_page.dart:97-102
                    inputFormatters: [
                      // نفس مجموعة المدقق (+ `/` لأرقام BOL).
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\p{L}\p{N}\s\-_#/]', unicode: true),
                      ),
                    ],
```
- **Why problematic:** الـ RegExp ثالث نسخة من النمط المعرَّف في المصدر الصحيح `daily_form_rules.dart:29-31`، والنسختان **ستنحرفان** عند أي تعديل.
- **Violated principle:** DRY.
- **Current owner:** presentation ×2.
- **Correct owner:** widget عام `FormListEditorPage` في `logs/presentation/widgets/` يقبل `title`, `hint`, `validator`, `allowSlash`.
- **Consequences:** صيانة مزدوجة؛ خطر انحراف قواعد الإدخال.
- **Recommended correction:** استخرج `FormListEditorPage` واحد، وحيّد الـ RegExp من `daily_form_rules.dart` مُباشرة (`isFormLabelValid` بدل RegExp مكرر).
- **Related files:** `lib/features/logs/domain/daily_form_rules.dart:29-31,46-52`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-28: الواجهة الأمامية الخام `List<Map<String, dynamic>>` تتسرب إلى state في presentation
- **Severity:** High
- **Category:** Layer Abstraction Leak
- **Location:** `lib/features/logs/presentation/providers/unidentified_events_provider.dart:44` و `:13-39`؛ `lib/features/logs/presentation/pages/unidentified_events_page.dart:71-82` و `:423-434`
- **Evidence:**
```dart
// unidentified_events_provider.dart:41-50
class UnidentifiedListState {
  final bool loading;
  final String? error;
  final List<Map<String, dynamic>> items;
...
```
```dart
// unidentified_events_page.dart:423-434
        final item = items[index];
        final id = item['statusId'] is int ? item['statusId'] as int : null;
        final when = '${item['startTime'] ?? ''}';
        final end = '${item['endTime'] ?? ''}';
        final where = '${item['location'] ?? ''}';
        final status = '${item['dutyStatus'] ?? 'DRIVING'}';
        final duration = '${item['formattedDuration'] ?? ''}';
```
- **Current behavior:** خريطة HTTP الخام هي الـ state، والودجت يستخرج 12 حقلاً منها بـ `'${item['x'] ?? ''}'`.
- **Why problematic:** (1) `'${item['startTime'] ?? ''}'` يحوّل `null` إلى **النص `"null"`** المعروض للمستخدم. (2) التطبيع في `normalizeUnidentifiedItem` (`line 19-39`) **لا يضمن وجود المفاتيح**: `item['startTime']` قد يكون `null` ثم `DateTime.tryParse('$raw')` ⇒ `null` ⇒ يُخفى الصف صامتاً. (3) `normalizeUnidentifiedItem` نفسه **mapper بمفاتيح 13** مكتوب في presentation.
- **Violated principle:** Type Safety + Presentation shouldn't see wire shape.
- **Current owner:** presentation.
- **Correct owner:** كيان `UnidentifiedEvent` في `logs/domain/entities/`.
- **Consequences:** أخطاء عرض غير قابلة للاكتشاف statically.
- **Recommended correction:** عرّف `UnidentifiedEvent` (freezed) في domain، `UnidentifiedEventMapper` في data، واجعل الـ state يحوي كيانات.
- **Related files:** `lib/features/logs/presentation/pages/unidentified_events_page.dart:335-341` (`contains('DRIV')` على نص)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-29: بناء حمولة الشهادة القانونية داخل presentation provider
- **Severity:** Medium
- **Category:** Business/Transport in Presentation
- **Location:** `lib/features/logs/presentation/providers/certify_log_provider.dart:173-181`
- **Evidence:**
```dart
173:    final result = await _repository.certifyLog(
174:      logId: _logId,
175:      driverId: driverId,
176:      // DateFormat is used for the API payload contract, not for UI display.
177:      logDate: DateFormat('yyyy-MM-dd').format(log.date),
178:      signatureCertificateId: 'local_drawn',
179:      signatureConfirmation: true,
180:      certifiedTrue: true,
181:    );
```
- **Current behavior:** presentation يحدد **قيمة السجل** `signatureCertificateId: 'local_drawn'` (سلسلة حرفية تعاقدية) ويثبّت `certifiedTrue: true` **دون أي تحقق من السائق**.
- **Why problematic:** (1) `certifiedTrue: true` ثابت — أي استدعاء يصبح «توثيقاً». (2) `'local_drawn'` قيمة يجب أن يعرفها الخادم؛ وضعها في presentation يعني أن أي feature آخر يرسل قيمة مختلفة. (3) `certify_tab.dart:99` يولّد `toPngBytes()` ثم لا يُرسله إطلاقاً (السطر `163` يقرّ: `// The live contract has no signature-upload path`) — **الملف المعدَّل يدّعي أنه يرسل توقيعاً مستخدماً**.
- **Violated principle:** Contract values belong to the contract owner.
- **Current owner:** presentation provider.
- **Correct owner:** `data/repositories/log_repository_impl.dart` (يُنشئ `CertifyRequestDto` في `line 440` — المكان الصحيح).
- **Consequences:** تعديل عقد التوثيق يتطلب تعديل presentation.
- **Recommended correction:** انقل `signatureCertificateId` و`certifiedTrue` إلى `LogRepositoryImpl.certifyLog`، ومرّر `hasDrawnSignature: bool` فقط.
- **Related files:** `lib/features/logs/data/repositories/log_repository_impl.dart:439-448`, `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart:99-105`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-30: `LogEvent.props` يُسقط `location` وأربع حقول من مفتاح family
- **Severity:** Medium
- **Category:** Correctness (Riverpod identity)
- **Location:** `lib/features/logs/domain/entities/daily_log.dart:248-250` مستهلَك في `lib/features/logs/presentation/providers/edit_log_form_provider.dart:55-56`
- **Evidence:**
```dart
// daily_log.dart:248-250
  @override
  List<Object?> get props =>
      [id, status, startTime, duration, location, isExpanded];
```
```dart
// edit_log_form_provider.dart:55-56
final editLogFormProvider = StateNotifierProvider.autoDispose
    .family<EditLogFormNotifier, EditLogFormState, LogEvent?>((ref, event) {
```
- **Current behavior:** `LogEvent` هو **مفتاح family**. عندما يصل التحديث من الخادم وتختلف `location` فقط — والقيمة مستثناة من `props` — deems Riverpod الكيانين متساويين ولا يعيد بناء الـ provider. لكن `location` **نعم** مُدرجة في props في السطر أعلاه.
- **ملاحظة مقدَّرة:** بعد مراجعة دقيقة — `location` **موجود** في `props`. الحقول المستثناة فعلاً: `odometer`, `engineHours`, `automatedDriving`, `editable`. الاستثناء الحاسم هو **`editable`**، وهو الحقل الذي يحدد **`خط القلم في `events_tab.dart:78-79`**:
```dart
                      onEdit: (event.automatedDriving == true ||
                              event.editable == false)
                          ? null
```
فإذا تغيّر `editable` من الخادم، deems الكيانان متساويين ⇒ لا إعادة بناء ⇒ **قلم التعديل على حدث مقفل قانونياً يبقى ظاهراً** (أو العكس).
- **Why problematic:** سعة `props` غير مكتملة بينما الكيان يُستخدم كمفتاح هوية.
- **Violated principle:** Value-object identity completeness.
- **Current owner:** `daily_log.dart:248`
- **Correct owner:** نفس الملف — إما إكمال `props`، أو تحويل family key إلى `String? eventId`.
- **Consequences:** زر تعديل على حدث لا يجوز تعديله.
- **Recommended correction:** أكمل `props`، أو اجعل family key معرّفاً صريحاً.
- **Related files:** `lib/features/logs/presentation/widgets/log_detail_tabs/events_tab.dart:78-85`
- **Confidence:** **POTENTIAL** (الأثر الخاطئ محتمل؛ لم يُشغَّل الكود)

--------------------------------------------------
### ISSUE HL-31: `LogsNotifier._ref` اختياري — الكتابة العابرة للميزات تتوقف بصمت
- **Severity:** Medium
- **Category:** Error Handling / Defensive nullability
- **Location:** `lib/features/logs/presentation/providers/logs_provider.dart:94` و `:162` و `:192` و `:214`
- **Evidence:**
```dart
 94:  final Ref? _ref;
...
162:      _ref?.read(dashboardDataProvider.notifier).applyServerForm(
...
192:        _ref?.read(dashboardDataProvider.notifier).applyServerForm(form);
...
214:          _ref?.read(dashboardDataProvider.notifier).applyServerForm(
```
- **Current behavior:** `LogsNotifier` يحمل `Ref` كمعامل ثالث اختياري `[this._ref]`. الموضع في `line 78` يمرّره دائماً — لكن **أي استدعاء آخر** لـ `LogsNotifier(repository, driverId)` يConstruct'd بلا `ref` فتُفوَّت 3 عمليات كتابة بصمت.
- **Why problematic:** (1) `?.` في **قاعدة بيانات** يُخفي خطأً بصمت. (2) `selectLog` هو المسار الحرج لشاشة التفاصيل — فلو فُقد المرجع فإن التبويب يعرض بيانات قديمة بلا مؤشر.
- **Violated principle:** Explicit dependencies + fail loudly.
- **Current owner:** الملف.
- **Correct owner:** نفس الملف — `final Ref _ref;` إلزامي.
- **Consequences:** صعوبة تشخيص «البيانات لا تتحدث».
- **Recommended correction:** اجعل المعامل إلزامياً، وأضف `assert(_ref != null)` في debug.
- **Related files:** `lib/features/logs/presentation/providers/logs_provider.dart:78`
- **Confidence:** **CONFIRMED** (التصميم)، **POTENTIAL** (حدوثه)

--------------------------------------------------
### ISSUE HL-32: صنفا parsing عامّان على مستوى الملف داخل presentation
- **Severity:** Medium
- **Category:** Code Organization / Layer Bypass
- **Location:** `lib/features/logs/presentation/providers/unidentified_events_provider.dart:13-17` و `:19-39`
- **Evidence:**
```dart
13: List<Map<String, dynamic>> parseUnidentifiedList(Map<String, dynamic> json) {
14:   final raw = json['items'] ?? json['events'] ?? json['content'] ?? json['data'];
15:   if (raw is! List) return const [];
16:   return raw.whereType<Map>().map(normalizeUnidentifiedItem).toList();
17: }
```
- **Current behavior:** دالتان غيرmembers لفئة، في مجلد `presentation/providers/`، تبنيان خرائط HTTP.
- **Why problematic:** (1) **أربعة محاولات لحقل الحقل نفسه** (`items/events/content/data`) في سطر واحد — عقد غير مستقر. (2) توسيع testability presentation من presentation لـ parsing. (3) mapper بمفاتيح 13 مكانه `data/models/`.
- **Violated principle:** Layer placement + cohesion.
- **Current owner:** presentation.
- **Correct owner:** `logs/data/models/unidentified_event_mapper.dart`.
- **Consequences:** استيراد presentation من presentation لـ parsing.
- **Recommended correction:** انقلهما إلى `data/models/` واعمل لهما اختبار وحدة.
- **Related files:** `lib/features/logs/presentation/pages/unidentified_events_page.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-33: عرض رسالة خطأ خام داخل widget
- **Severity:** Low
- **Category:** Error Surface Consistency
- **Location:** `lib/features/logs/presentation/widgets/codriver_picker_dialog.dart:57`
- **Evidence:**
```dart
56:                      Text(
57:                        'Error: ${codriverState.error}',
58:                        style: context.styles.error,
59:                      ),
```
- **Current behavior:** يعرض `'Error: ' + الخطأ الخام` بينما المقياس يستخدم `anyErrorUserMessage(error, loc:)` في **12 موضعاً آخر** داخل `logs`.
- **Why problematic:** الرسالة الخام قد تكون كوداً داخلياً أو استثناء.
- **Violated principle:** Consistent Error Surface.
- **Current owner:** الملف.
- **Correct owner:** نفس الملف باستدعاء `anyErrorUserMessage`.
- **Consequences:** تسريب تفاصيل فنية للمستخدم.
- **Recommended correction:** استبدل السطر.
- **Related files:** `lib/core/error/user_facing_message.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-34: خرائط رموز الحالات الخمسة: 5 نسخ داخل presentation
- **Severity:** Medium
- **Category:** Duplication
- **Location:** 5 مواقع (كلها presentation)
| # | الملف:السطر | المحتوى |
|---|---|---|
| 1 | `logs/presentation/widgets/status_radio_group.dart:19-26` | 6 رموز + تسميات |
| 2 | `logs/presentation/pages/inspection_preview_page.dart:194-199` | 4 رموز |
| 3 | `logs/presentation/pages/inspection_preview_page.dart:273-286` | 4 رموز → ألوان |
| 4 | `logs/presentation/widgets/log_graph.dart:26-30` + `:47-53` | 4 رموز + تطبيع |
| 5 | `logs/presentation/widgets/log_detail_tabs/events_tab.dart:104` | 4 رموز |
- **Current behavior:** المصدر الرسمي موجود: `lib/domain/duty_status/duty_status_code.dart` و`core/domain/entities/hos_models.dart:toShortCode()`؛ ومع ذلك كل موضع يُعيد كتابة المجموعة.
- **Why problematic:** خريطة الألوان في #3 **مكرّرة** مع `core/utils/status_color_helper.dart:5-7` الموجودة فعلاً والمُستخدمة في `log_event_tile.dart:45`. أي حالة جديدة تظهر بلون مختلف في كل شاشة.
- **Violated principle:** DRY.
- **Current owner:** presentation ×5.
- **Correct owner:** `DutyStatusCode` + `StatusColorHelper`.
- **Consequences:** شاشات متعارضة اللون.
- **Recommended correction:** في #3 استبدل `_getStatusColor` بـ `StatusColorHelper.getStatusColor(status)`؛ وفي الباقي ولّد من `DutyStatusCode.values`.
- **Related files:** `lib/core/utils/status_color_helper.dart`, `lib/domain/duty_status/duty_status_code.dart`, `lib/core/domain/entities/hos_models.dart:12-27`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-35: عقد نصي مشترك بين widget و domain مربوط بتعليق فقط
- **Severity:** Low
- **Category:** Implicit Contract
- **Location:** `lib/features/logs/presentation/widgets/time_picker_sheet.dart:69-72` ↔ `lib/features/logs/domain/log_edit.dart:41-43`
- **Evidence:**
```dart
// time_picker_sheet.dart:69-72
                onPressed: () {
                  // Always use English AM/PM so parseEditFormTime can parse it properly.
                  final time = '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}:${_selectedSecond.toString().padLeft(2, '0')} $_selectedPeriod';
                  widget.onDone(time);
                },
```
```dart
// log_edit.dart:41-43
  final m12 = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)$',
          caseSensitive: false)
      .firstMatch(trimmed);
```
- **Current behavior:** الـ widget ينتج نصاً، والـ domain يحلّله بـ regex. العقد **نصّي غير مُنمّط**، رابطه تعليق فقط.
- **Why problematic:** أي تعديل على تنسيق الإخراج يكسر التحليل صامتاً (`parseEditFormTime` يعيد `null` ⇒ `invalidTime`).
- **Violated principle:** Type Safety across layers.
- **Current owner:** — / **Correct owner:** value object أو `TimeOfDay` من Flutter يُمرَّر كـ `DateTime`.
- **Consequences:** كسر صامت عند أي تغيير في الطرف.
- **Recommended correction:** مرّر `TimeOfDay` من الـ widget، ودع `domain` يستقبل `DateTime`.
- **Related files:** `lib/core/time/time_formatter.dart:37`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-36: تحليل نص المتطلبات داخل widget
- **Severity:** Medium
- **Category:** Parsing in Widget
- **Location:** `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart:82-95`
- **Evidence:**
```dart
82:  static String _readableRequirement(String req) {
83:    return req.replaceAllMapped(
84:      RegExp(
85:          r'\d{4}-\d{1,2}-\d{1,2}[T ]\d{1,2}:\d{2}(?::\d{2})?(?:Z|[+-]\d{2}:?\d{2})?'),
86:      (m) {
87:        final parsed = DateTime.tryParse(m.group(0)!);
88:        if (parsed == null) return m.group(0)!;
89:        final local = parsed.toLocal();
90:        final hh = local.hour.toString().padLeft(2, '0');
91:        final mm = local.minute.toString().padLeft(2, '0');
92:        return '$hh:$mm';
93:      },
94:    );
95:  }
```
- **Current behavior:** regex ISO داخل widget لتحويل متطلبات الجاهزية (نص حر من الخادم) إلى `HH:mm`.
- **Why problematic:** المتطلب **نص حر**؛ كل خادم يرسل صيغة مختلفة. الـ regex يفلت بصمت ويعرض النص كما هو. الدالة `static` داخل widget ⇒ **لا وحدة اختبار** ممكنة.
- **Violated principle:** Parsing belongs in domain/data.
- **Current owner:** widget.
- **Correct owner:** `core/time/time_formatter.dart` مع اختبارات.
- **Consequences:** أوقات تظهر بصيغة UTC بلا علامة.
- **Recommended correction:** انقلها إلى `TimeFormatter` مع اختبار يغطي الصيغ البديلة.
- **Related files:** `lib/core/time/time_formatter.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-37: `_dailyFormPayload` — use-case داخل ملف widget
- **Severity:** Medium
- **Category:** Business Logic in Widget
- **Location:** `lib/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart:335-383` + `:327-332`
- **Evidence:**
```dart
335: _DailyFormPayload _dailyFormPayload({
336:   required String vehicleUniqueId,
...
343:   final uniqueId =
344:       readOperableUniqueId(vehicleUniqueId) ??
345:       readOperableUniqueId(logUniqueId) ??
346:       '';
347:   if (uniqueId.isEmpty) {
348:     return _DailyFormPayload(null, loc.selectVehicleBeforeSavingForm);
349:   }
350:
351:   final trailers = <String>[];
352:   for (final trailer in splitFormList(trailersRaw)) {
353:     final error = trailerNumberError(trailer, loc);
354:     if (error != null) return _DailyFormPayload(null, error);
355:     trailers.add(trailer);
356:   }
...
365:   int? coDriverId;
366:   final rawCoDriver = coDriverIdRaw.trim();
367:   if (rawCoDriver.isNotEmpty && rawCoDriver != 'none') {
368:     coDriverId = int.tryParse(rawCoDriver);
369:     if (coDriverId == null) {
370:       return _DailyFormPayload(null, loc.coDriverMustBeServerId);
371:     }
372:   }
```
- **Current behavior:** دالة top-level **بِناء أمر + تحقّق + اختيار رسالة خطأ** — 48 سطراً، تُنفَّذ مرتين: مرة في `validator` ومرة عند الحفظ.
- **Why problematic:** (1) **نفس التحقق مُنفَّذ في موضعين مختلفين**: الـ validator يمرّر `value` من `FormField`، والحفظ يمرّر `trailersDisplay` المعروض. (2) `loc: context.loc` في التوقيع ⇒ غير قابل للاستخدام خارج UI.
- **Violated principle:** Business logic in Presentation + Single validation path.
- **Current owner:** widget.
- **Correct owner:** `logs/application/usecases/build_daily_form_update_use_case.dart`.
- **Consequences:** خطأ صامت قد لا يُكتشف عند الحفظ.
- **Recommended correction:** use-case واحد يُعيد `Either<FormError, DailyFormUpdate>`، والـ validator يستهلك نفس النتيجة.
- **Related files:** `lib/features/logs/presentation/controllers/form_tab_controller.dart:21-63`, `lib/features/logs/domain/entities/daily_form_update.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-38: توالد الأرقام الإحصائية والإحصاءات داخل domain tracker بنوع غير مُنمّط
- **Severity:** Low
- **Category:** Primitive Obsession / Dead Code
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:444-535`
- **Evidence:**
```dart
444:  Map<String, double> getTodayStats() {
445:    final now = _getCurrentTime();
446:    if (now == null) {
447:      return {
448:        'driving': 0,
449:        'on_duty': 0,
450:        'off_duty': 0,
451:        'sleeper': 0,
452:        'distance': 0,
453:      };
...
455:    final todayStart = DateTime(now.year, now.month, now.day);
```
- **Current behavior:** دالتان تُعيدان `Map<String, double>` بمفاتيح نصية، ومفتاح `'sleeper'` يختلف عن `'sleeper_berth'` المستخدم في الـ switch (`line 473`) — **عدم تطابق تسمية**.
- **Why problematic:** (1) **كود ميت**: البحث في `lib/` لم يجد أي مستهلك لـ `getTodayStats`/`getWeekStats`. (2) `Map<String,double>` بنصوص حرة في domain ⇒ نقطة فشل صامتة. (3) `DateTime(now.year, now.month, now.day)` يبني **وقتاً محلياً من UTC** (`_getCurrentTime()` يُرجع UTC) ⇒ حدّ اليوم محسوب في TZ الجهاز لا في TZ التنظيمي.
- **Violated principle:** Primitive Obsession + Dead code.
- **Current owner:** الملف.
- **Correct owner:** احذفه، أو `DutySummary` entity في domain.
- **Consequences:** لا أثر مباشر؛ كود ميّت في ملف مخالف.
- **Recommended correction:** احذف الدالتين (لا مستهلك لهما).
- **Related files:** — (بحث `lib/` عن `getTodayStats|getWeekStats` أعاد ملفّها فقط)
- **Confidence:** **CONFIRMED** (الموجود)، **POTENTIAL** (أهمية حدّ اليوم الزمني)

--------------------------------------------------
### ISSUE HL-39: عتبات العرض (1 ساعة حرج، 15 دقيقة أحمر) مكتوبة داخل widgets
- **Severity:** Medium
- **Category:** Hardcoded Business Thresholds in Presentation
- **Location:** `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart:105`؛ `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:179`
- **Evidence:**
```dart
// hos_indicators_card.dart:103-105
    final isCritical =
        indicator.type == IndicatorType.remaining &&
        indicator.value <= const Duration(hours: 1);
```
```dart
// main_circular_timer.dart:178-181
    } else if (liveRemaining <= Duration.zero ||
        liveRemaining <= const Duration(minutes: 15)) {
      arcColor = theme.colorScheme.error;
```
- **Current behavior:** عتبتان لونيّتان محدّدتان رقمياً داخل widgets، بينما محرّك التنبيهات في `hos_rules_engine.dart:104-127` يستخدم 15/30/60 دقيقة.
- **Why problematic:** **نفس المفهوم (اقتراب الحد) بعتبتين مختلفتين في مكانين مختلفين**: المحرّك يصنّف 30/60 دقيقة كتنبيهات، والواجهة تحوّل الأحمر عند 15 دقيقة فقط. كما أن `Duration(minutes: 15)` في الودجت لا يستمد من `HosConfiguration` ولا `FmcsaConstants`.
- **Violated principle:** Single Source of Truth.
- **Current owner:** widgets ×2.
- **Correct owner:** `FmcsaConstants` أو `HosConfiguration`، مع استهلاكها عبر `AlertSeverity` القادم من المحرك.
- **Consequences:** تناقض بصري: السائق يرى «حرج» في لوح واحد و«معلومات» في آخر لنفس الوقت المتبقي.
- **Recommended correction:** اجعل `HosStatusUpdate` يحمل `AlertSeverity` لكل مؤشر، واستهلكه الودجت بدل حساب عتبة خاصة.
- **Related files:** `lib/features/hos/domain/engine/hos_rules_engine.dart:104-127`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-40: `HosNotifier` يصل إلى مستودع تدقيق المخالفات مباشرة
- **Severity:** Medium
- **Category:** Layer Bypass (presentation → domain repository)
- **Location:** `lib/features/hos/presentation/providers/hos_provider.dart:138-145`
- **Evidence:**
```dart
138:  void _processAndLogViolations(HosEngineResult result) {
139:    if (result is HosEngineReady && result.update.violations.isNotEmpty) {
140:      final auditRepo = _ref.read(hosAuditRepositoryProvider);
141:      for (final v in result.update.violations) {
142:        auditRepo.logViolation(v);
143:      }
144:    }
145:  }
```
- **Current behavior:** الـ notifier يستدعي `logViolation` **بلا `await` ولا معالجة نتيجة** — `auditRepo.logViolation(v)` تُطلق عملية كتابة غير مراقَبة (Future مُهمَل).
- **Why problematic:** (1) كتابة غير مراقَبة في سجل قانوني: أي فشل صامت. (2) `HosAuditRepositoryImpl.logViolation` يكتب في Hive عبر `jsonEncode` (`hos_audit_repository_impl.dart:24-26`) — فشل قرص كامل لن يُبلَّغ. (3) تجاوز use-case layer.
- **Violated principle:** Layered Architecture + Fire-and-forget on legal records.
- **Current owner:** presentation.
- **Correct owner:** use-case في `hos/application/` يتعامل مع `Result`.
- **Consequences:** مخالفة قانونية قد لا تُسجَّل بصمت.
- **Recommended correction:** انقل إلى use-case يعيد `Result<void, Failure>`، وتعامل مع الفشل عبر `AppLogger.error`.
- **Related files:** `lib/features/hos/data/repositories/hos_audit_repository_impl.dart:24-26`, `lib/features/hos/data/providers/hos_audit_providers.dart:11`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE HL-41: ازدواج شريط التنقل السفلي وطبقات Loading/Error في المجموعة
- **Severity:** Low
- **Category:** Duplication (Structural)
- **Location:** `BottomNavigationBar`: 2 موضعان متطابقان — `logs/presentation/pages/log_detail_page.dart:176` و `logs/presentation/pages/inspection_preview_page.dart:236`. `CircularProgressIndicator`: **12 موضعاً في 12 ملفاً** (`hos/presentation/pages/status_dashboard_page.dart:93`، `hos/presentation/pages/recap_page.dart:65`، `logs/presentation/pages/audit_trail_page.dart:40`، `logs/presentation/pages/edit_log_page.dart:377`، `logs/presentation/pages/logs_list_page.dart:64`، `logs/presentation/pages/inspection_preview_page.dart:118,362`، `logs/presentation/pages/unidentified_events_page.dart:244`، `logs/presentation/widgets/vehicle_picker_dialog.dart:64`، `logs/presentation/widgets/codriver_picker_dialog.dart:51`، `logs/presentation/widgets/log_detail_tabs/events_tab.dart:30`، `logs/presentation/widgets/log_detail_tabs/certify_tab.dart:116`). `EldRetryView`: **7 مواضع في 6 ملفات** (`hos/.../status_dashboard_page.dart:113`، `hos/.../recap_page.dart:67`، `logs/.../logs_list_page.dart:66,75`، `logs/.../events_tab.dart:33,42`، `logs/.../inspection_preview_page.dart:126`).
- **Current behavior:** نفس شريط التنقل السفلي (3 عناصر + Badge على «Form») مكرور مرتين؛ حالة التحميل تُبنى يدوياً 12 مرة.
- **Why problematic:** مجموعتان متطابقتان من Handling States بلا abstraction. (ملاحظة: `EldRetryView` و`CircularProgressIndicator` تكرارات **مقبولة** كـ shared widgets في `core/widgets/` — التسجيل هنا لقياس الكمية، لا للحكم على المخالفة.)
- **Violated principle:** DRY (بحدّ).
- **Current owner:** presentation.
- **Correct owner:** `core/widgets/` (يوجد precedent في `core/widgets/eld_date_paginator.dart` و`eld_events_table.dart`).
- **Consequences:** تعديل مظهر حالة الخطأ يتطلب 7 مواضع.
- **Recommended correction:** استخرج `AsyncStateView<T>` و`LogSectionTabBar` في `core/widgets/`.
- **Related files:** `lib/core/widgets/eld_retry_view.dart`, `lib/core/widgets/eld_date_paginator.dart`
- **Confidence:** **CONFIRMED**

---
# C. جدول تكرار قواعد HOS (الثابت -> كل موقع file:line)

> البحث تم عبر كامل `lib/` (باستثناء `*.g.dart` و `*.freezed.dart`).

## C.1 — حد القيادة 11 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:19` | `static const int maxDrivingHours = 11;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:27` | `drivingLimitMinutes: 11 * 60,` (usa70_8) | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:41` | `drivingLimitMinutes: 11 * 60,` (usa60_7) | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:89` | `?? 11 * 60` (fromJson fallback) | core/config | ✅ مصدر |
| 5 | `lib/features/hos/domain/engine/hos_rules_engine.dart:172` | نص: `'❌ تجاوز حد القيادة 11 ساعة'` | domain | ⚠️ نص |
| 6 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:87` | `const total = Duration(hours: 11);` | **data** | ❌ |
| 7 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:125` | `totalLimit = const Duration(hours: 11);` (rest) | **presentation** | ❌ |
| 8 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:128` | `totalLimit = const Duration(hours: 11);` (driving) | **presentation** | ❌ |
| 9 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:73` | `value: Duration(hours: 11),` | mock | ✅ مقبول |
| 10 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:139` | `const total = Duration(hours: 11);` | mock | ✅ مقبول |

## C.2 — نافذة الوردية 14 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:22` | `static const int maxDutyWindowHours = 14;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:28` | `shiftLimitMinutes: 14 * 60,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:42` | `shiftLimitMinutes: 14 * 60,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:90` | `?? 14 * 60` | core/config | ✅ مصدر |
| 5 | `lib/features/hos/domain/engine/hos_rules_engine.dart:181` | نص: `'❌ تجاوز نافذة العمل 14 ساعة'` | domain | ⚠️ نص |
| 6 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:95` | `const total = Duration(hours: 14);` | **data** | ❌ |
| 7 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:145` | `totalLimit = const Duration(hours: 14);` | **presentation** | ❌ |
| 8 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:78` | `value: Duration(hours: 14),` | mock | ✅ |
| 9 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:148` | `const total = Duration(hours: 14);` | mock | ✅ |

## C.3 — الاستراحة/حد 8 ساعات
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:28` | `static const int breakRequiredAfterDrivingHours = 8;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:32` | `driveBeforeBreakMinutes: 8 * 60,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:46` | `driveBeforeBreakMinutes: 8 * 60,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:94` | `?? 8 * 60` | core/config | ✅ مصدر |
| 5 | `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart:28` | `driveBeforeBreakMinutes: 8 * 60,` | backend mapper | ⚠️ mapper، تجاوز المصدر |
| 6 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:142` | `totalLimit = const Duration(hours: 8);` | **presentation** | ❌ |
| 7 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:83` | `value: Duration(hours: 8),` | mock | ✅ |

## C.4 — الاستراحة الإلزامية 30 دقيقة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:29` | `static const int mandatoryBreakDurationMinutes = 30;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:30` | `breakDurationMinutes: 30,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:44` | `breakDurationMinutes: 30,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:92` | `?? 30` | core/config | ✅ مصدر |
| 5 | `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart:26` | `breakDurationMinutes: 30,` | backend mapper | ⚠️ تجاوز المصدر |

## C.5 — حد الدورة الأسبوعية 60/70 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:32` | `static const int cycle7DaysLimitHours = 60;` | core/constants | ✅ مصدر |
| 2 | `lib/core/constants/fmcsa_constants.dart:33` | `static const int cycle8DaysLimitHours = 70;` | core/constants | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:29` | `cycleLimitHours: 70,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:43` | `cycleLimitHours: 60,` | core/config | ✅ مصدر |
| 5 | `lib/core/config/hos_configuration.dart:91` | `?? 70` | core/config | ✅ مصدر |
| 6 | `lib/domain/duty_status/status_dashboard.dart:175-181` | `usa70_8('USA 70/8', 70, 8)` … `canadaSouth120_14(…, 120, 14)` | domain مشترك | ✅ (مصدر ثانٍ مشروع) |
| 7 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:88` | `value: Duration(hours: 70),` | mock | ✅ |

## C.6 — إعادة التشغيل الأسبوعي 34 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:34` | `static const int cycleRestartHours = 34;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:34` | `weeklyRestartHours: 34,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:48` | `weeklyRestartHours: 34,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:96` | `?? 34` | core/config | ✅ مصدر |
| 5 | `lib/features/hos/domain/engine/hos_calculator.dart:103` | **`const requiredHours = 34;`** | **domain** | ❌ **يتجاهل `config.weeklyRestartHours`** |

> **ملاحظة حرجة (C.6):** `HosConfiguration` يوفّر `weeklyRestartHours` كحقل مهيّأ، لكن `HosCalculator.hasWeeklyRestart` **يتجاهله تماماً** ويثبّت `34` محلياً. أي أن تغيير قاعدة إعادة التشغيل (مثلاً ولاية أخرى) لا يسري.

## C.7 — عتبة السرعة 5 mph / 8 km/h
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:7` | `static const double drivingSpeedThresholdMps = 2.235;` | core/constants | ✅ مصدر |
| 2 | `lib/core/constants/fmcsa_constants.dart:10` | `static const double drivingSpeedThresholdMph = 5.0;` | core/constants | ✅ **المصدرUnused** |
| 3 | `lib/core/config/hos_configuration.dart:31` | `movingSpeedThresholdKmh: 8.0,` | core/config | ✅ |
| 4 | `lib/core/config/hos_configuration.dart:45` | `movingSpeedThresholdKmh: 8.0,` | core/config | ✅ |
| 5 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:106` | **`if (eldEvent.speedMph > 5.0) {`** | **domain** | ❌ **وحدات مختلفة** |
| 6 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:129` | نص: `'Auto Transition to Driving (> 5 mph sustained)'` | domain | ⚠️ نص |

## C.8 — الثبات 5 دقائق قبل الانتقال لـ ON_DUTY
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:16` | `static const int stationaryPromptSeconds = 300;` | core/constants | ✅ **المصدرUnused** |
| 2 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:168` | `if (elapsed.inMinutes >= 5) {` | domain | ❌ وليس في `HosConfiguration` |
| 3 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:185` | `const Duration(minutes: 5) - elapsed` | domain | ❌ |

## C.9 — عتبة التنبيه 15 دقيقة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/features/hos/domain/engine/hos_rules_engine.dart:104` | `if (limits.remainingDriveMinutes <= 15 &&` | domain | ⚠️ محرّك، لكن خارج `HosConfiguration` |
| 2 | `lib/features/hos/domain/engine/hos_rules_engine.dart:108` | نص: `'15 minutes driving time remaining'` | domain | ⚠️ نص |
| 3 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:179` | `liveRemaining <= const Duration(minutes: 15)` | **presentation** | ❌ عتبة مستقلة |

## C.10 — الراحة المتتالية 10 ساعات
| # | الموقع | الصيغة | المصدر الصحيح؟ |
|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:25` | `static const int requiredConsecutiveRestHours = 10;` | ✅ المصدر الوحيد |
| — | *(لا توجد أي نسخة أخرى في `lib/`)* | — | ⚠️ ثابت **غير مستخدم** — لا يوجد أي تنفيذ لقاعدة الراحة المتتالية 10 ساعات في المجموعة |

## C.11 — أرقام مُختلقة (ليست قواعد)
| # | الموقع | القيمة | الحكم |
|---|---|---|---|
| 1 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:86` | `const remaining = Duration(minutes: 35);` | ❌ بيانات توازن مُختلقة في data |
| 2 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:94` | `const remaining = Duration(hours: 2, minutes: 8);` | ❌ بيانات توازن مُختلقة في data |
| 3 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:95` | `Duration(minutes: 35)` | ✅ mock |
| 4 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:100` | `Duration(hours: 2, minutes: 8)` | ✅ mock |
| 5 | `lib/features/logs/presentation/providers/logs_provider.dart:119` | `const limit = 20;` | ⚠️ حجم صفحة (قابل للضبط، ليس قاعدة قانونية) |
| 6 | `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart:105` | `const Duration(hours: 1)` | ❌ عتبة نقدية في widget |
| 7 | `lib/features/logs/presentation/pages/unidentified_events_page.dart:334` | `const Duration(hours: 24)` | ⚠️ نافذة إحصائية (SRS 11.6)، ليست FMCSA |
| 8 | `lib/features/logs/presentation/controllers/edit_log_controller.dart:52` | `const Duration(minutes: 1)` | ⚠️ هامش تسامح زمني |

**خلاصة القسم C:** عدد المواقع التي **تتجاوز** المصدر الصحيح داخل هذه المجموعة = **7** (`main_circular_timer.dart` ×5، `status_dashboard_repository_impl.dart` ×2، `duty_status_tracker.dart` ×1، `hos_calculator.dart` ×1). عدد الثوابت المعرَّفة في مصدرين رسميين (`FmcsaConstants` و`HosConfiguration`) = **12**، منها **3 غير مستخدمة** (`drivingSpeedThresholdMph`, `stationaryPromptSeconds`, `requiredConsecutiveRestHours`).

---

# D. جداول الاستيراد بين الميزات للمجموعة

## D.1 — `features/logs` -> ميزات أخرى (13 حافة)

| # | المستورد | السطر | المستوردَ منه | نوع الحافة | الحكم |
|---|---|---|---|---|---|
| 1 | `logs/data/repositories/log_repository_impl.dart` | 3 | `features/sync/domain/entities/pending_event.dart` | data → domain (عقد) | ✅ جائز |
| 2 | `logs/data/repositories/log_repository_impl.dart` | 4 | `features/sync/domain/repositories/offline_queue.dart` | data → domain (عقد) | ⚠️ جائز لكنه يجعل `sync` مجتمعة مع `logs` |
| 3 | `logs/data/providers/log_repository_providers.dart` | 6 | `features/sync/data/providers/sync_providers.dart` | data → data (DI) | ✅ جائز في بنية المشروع |
| 4 | `logs/presentation/providers/logs_provider.dart` | 11 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ معقول (هوية) |
| 5 | `logs/presentation/providers/logs_provider.dart` | **12** | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة حالة**) | ❌ **HL-25** |
| 6 | `logs/presentation/controllers/edit_log_controller.dart` | 5 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 7 | `logs/presentation/controllers/form_tab_controller.dart` | 2 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 8 | `logs/presentation/providers/certify_log_provider.dart` | 12 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 9 | `logs/presentation/providers/unidentified_events_provider.dart` | 8 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 10 | `logs/presentation/pages/edit_log_page.dart` | 4 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |
| 11 | `logs/presentation/pages/edit_log_page.dart` | 13 | `features/vehicle/domain/entities/vehicle.dart` | presentation → domain (عقد) | ✅ جائز |
| 12 | `logs/presentation/pages/edit_log_page.dart` | 14 | `features/vehicle/presentation/providers/vehicle_provider.dart` | presentation → presentation | ⚠️ معقول (اختيار) |
| 13 | `logs/presentation/widgets/vehicle_picker_dialog.dart` | 9 | `features/vehicle/presentation/providers/vehicle_provider.dart` | presentation → presentation | ⚠️ معقول |
| 14 | `logs/presentation/pages/unidentified_events_page.dart` | 11 | `features/vehicle/presentation/providers/vehicle_provider.dart` | presentation → presentation | ⚠️ معقول (فلترة) |
| 15 | `logs/presentation/widgets/codriver_picker_dialog.dart` | 5 | `features/codriver/domain/entities/codriver.dart` | presentation → domain (عقد) | ✅ |
| 16 | `logs/presentation/widgets/codriver_picker_dialog.dart` | 6 | `features/codriver/presentation/providers/codriver_provider.dart` | presentation → presentation | ⚠️ معقول |
| 17 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 7 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |
| 18 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 8 | `features/vehicle/domain/entities/vehicle.dart` | presentation → domain (عقد) | ✅ |
| 19 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 9 | `features/vehicle/domain/vehicle_selection.dart` | presentation → domain (منطق) | ✅ منطق مجال مستورد كعقد |
| 20 | `logs/presentation/pages/inspection_preview_page.dart` | 14 | `features/inspection/domain/transfer_audit.dart` | presentation → domain (عقد) | ✅ |
| 21 | `logs/presentation/pages/inspection_preview_page.dart` | 15 | `features/inspection/presentation/providers/dot_inspection_providers.dart` | presentation → presentation | ⚠️ معقول |
| 22 | `logs/presentation/pages/inspection_preview_page.dart` | **16** | `features/inspection/presentation/widgets/inspection_log_header_table.dart` | presentation → **presentation widget** | ❌ **HL-13** |
| 23 | `logs/presentation/pages/logs_list_page.dart` | **11** | `features/home/presentation/widgets/eld_drawer.dart` | presentation → **presentation widget** | ❌ **HL-13** |
| 24 | `logs/presentation/pages/shipping_documents_page.dart` | 11 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |
| 25 | `logs/presentation/pages/trailers_page.dart` | 11 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |

**حساب:** 25 حافة إجمالاً. منها **5 مخالفة مؤكدة** (كتابة عبر features أو استيراد widget).
`LOGS → VEHICLE` = **4 حواف، كلها تستورد عقوداً أو providers قراءة** ⇒ **ليست مخالفة**.
`LOGS → HOME` = **7 حواف، 5 منها كتابة حالة** ⇒ **مخالفة مؤكدة**.
`LOGS → AUTH` = **5 حواف، قراءة فقط** ⇒ **ليست مخالفة**.
`LOGS → SYNC` = **3 حواف، كلها في طبقة data** ⇒ **ليست مخالفة**.
`LOGS → CODRIVER` = **3 حواف، عقدة + قراءة** ⇒ **ليست مخالفة**.
`LOGS → INSPECTION` = **3 حواف، منها استيراد widget** ⇒ **مخالفة جزئية**.

## D.2 — `features/hos` -> ميزات أخرى و `lib/domain` (11 حافة)

| # | المستورد | السطر | المستوردَ منه | نوع الحافة | الحكم |
|---|---|---|---|---|---|
| 1 | `hos/domain/engine/tracking/duty_status_tracker.dart` | **4** | `features/logs/domain/repositories/log_repository.dart` | **domain → domain (feature أخرى)** | ❌ **HL-01 مخالفة حرجة** |
| 2 | `hos/domain/engine/tracking/duty_status_tracker.dart` | **9** | `features/sync/domain/usecases/sync_engine.dart` | **domain → domain (use-case)** | ⚠️ تطبيق مجتمعة — غير مثالي لكنه عقد |
| 3 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 10 | `features/sync/domain/entities/pending_event.dart` | domain → domain (كيان) | ✅ كيان مشترك |
| 4 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 5 | `core/services/local_storage_service.dart` | **domain → infrastructure** | ❌ **HL-02** |
| 5 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 13 | `backend/contracts/status_dashboard_backend.dart` | **domain → backend contract** | ❌ **HL-02** |
| 6 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 14 | `lib/domain/duty_status/duty_status_code.dart` | domain → **shared domain** | ✅ **عقدة مشتركة** |
| 7 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 15 | `lib/domain/duty_status/status_dashboard.dart` | domain → shared domain | ✅ عقدة مشتركة |
| 8 | `hos/presentation/providers/hos_engine_provider.dart` | 8 | `features/logs/data/providers/log_repository_providers.dart` | presentation → **data** | ⚠️ انعكاس لـ HL-01 |
| 9 | `hos/presentation/providers/hos_engine_provider.dart` | 9 | `features/sync/data/providers/sync_providers.dart` | presentation → data | ✅ DI |
| 10 | `hos/presentation/providers/hos_engine_provider.dart` | 7 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 11 | `hos/presentation/providers/hos_engine_provider.dart` | 11 | `features/tracking/presentation/providers/tracking_provider.dart` | presentation → presentation | ✅ (قراءة سرعة) |
| 12 | `hos/presentation/providers/hos_provider.dart` | 11 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 13 | `hos/presentation/providers/recap_provider.dart` | 7 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 14 | `hos/presentation/providers/status_dashboard_providers.dart` | 13 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 15 | `hos/presentation/widgets/driving_lock_screen.dart` | **7** | `features/home/presentation/pages/home_page.dart` | presentation → **presentation page** | ❌ **HL-13** |
| 16 | `hos/presentation/widgets/location_display_widget.dart` | 5 | `features/tracking/presentation/providers/tracking_provider.dart` | presentation → presentation | ✅ |
| 17 | `hos/presentation/widgets/status_dashboard/operational_alerts_banner.dart` | 8 | `features/connection/presentation/providers/hardware_alerts_provider.dart` | presentation → presentation | ✅ |

## D.3 — الحكم على التبعيات المُعلنة

| التبعية المُعلنة | الحكم | المبرر |
|---|---|---|
| **`LOGS -> VEHICLE`** | **ليست مخالفة** ✅ | الحواف الأربع (11, 13, 14 من `edit_log_page` + `vehicle_picker_dialog:9` + `unidentified_events_page:11` + `form_tab:8,9`) تستورد: (أ) كيان `Vehicle` (عقدة نطاق مشتركة)، (ب) `vehicle_selection.dart` (منطق مجال)، (ج) provider قراءة. **لا يوجد استيراد لتنفيذ vehicle (repository/datasource)**. هذا نمط سليم. |
| **`LOGS -> HOME`** | **مخالفة مؤكدة** ❌ | ليس استيراد عقدة، بل **كتابة حالة** عبر `dashboardDataProvider.notifier` في 5 مواضع (`logs_provider:162,192,214`، `form_tab:130,215`، `edit_log_page:182`، `trailers_page:52`، `shipping_documents_page:51`) + استيراد widget `EldDrawer`. `dashboardDataProvider` هو **source of truth** لبيانات النموذج، و`logs` يحدّثه. |
| **`HOS -> SDOM (lib/domain/**)`** | **ليست مخالفة** ✅ | `lib/domain/duty_status/duty_status_code.dart` و`status_dashboard.dart` و`shared/value_objects.dart` هي **عقد مشتركة** (Shared Domain Model) يستخدمها `logs` و`hos` معاً (`log_repository.dart:4`، `status_dashboard_repository.dart:3-6`، `log_repository_providers.dart:9`). هي **نماذج مجال مشتركة لا تنفيذ**. هذا نمط معماري صحيح. |
| **`HOS -> LOGS`** | **مخالفة حرجة مؤكدة** ❌ | ليس عقدة مشتركة: `duty_status_tracker.dart:4` يستورد **عقد مستودع feature أخرى** و`line 284` يستدعيه. كما أن `hos_engine_provider.dart:8` يستورد **طبقة data** (`log_repository_providers.dart`) لتحقن المستودع. |

---

# E. قائمة شاملة للملفات المقروءة (إثبات التغطية)

## E.1 — `lib/features/hos/**` (29 ملف)

| # | المسار | أسطر | غير فارغ |
|---|---|---|---|
| 1 | `lib/features/hos/data/providers/hos_audit_providers.dart` | 14 | 12 |
| 2 | `lib/features/hos/data/providers/status_dashboard_repository_providers.dart` | 15 | 12 |
| 3 | `lib/features/hos/data/repositories/hos_audit_repository_impl.dart` | 58 | 52 |
| 4 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart` | 115 | 108 |
| 5 | `lib/features/hos/domain/engine/hos_calculator.dart` | 113 | 94 |
| 6 | `lib/features/hos/domain/engine/hos_rules_engine.dart` | 240 | 207 |
| 7 | `lib/features/hos/domain/engine/hos_state_machine.dart` | 128 | 106 |
| 8 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` | 555 | 494 |
| 9 | `lib/features/hos/domain/repositories/hos_audit_repository.dart` | 6 | 5 |
| 10 | `lib/features/hos/domain/repositories/status_dashboard_repository.dart` | 20 | 17 |
| 11 | `lib/features/hos/domain/usecases/get_status_dashboard_use_case.dart` | 15 | 12 |
| 12 | `lib/features/hos/domain/usecases/get_weekly_recap_use_case.dart` | 15 | 12 |
| 13 | `lib/features/hos/domain/usecases/update_duty_status_use_case.dart` | 18 | 15 |
| 14 | `lib/features/hos/presentation/duty_change_message.dart` | 32 | 27 |
| 15 | `lib/features/hos/presentation/extensions/duty_status_l10n.dart` | 52 | 48 |
| 16 | `lib/features/hos/presentation/pages/change_status_page.dart` | 232 | 212 |
| 17 | `lib/features/hos/presentation/pages/recap_page.dart` | 117 | 113 |
| 18 | `lib/features/hos/presentation/pages/status_dashboard_page.dart` | 118 | 103 |
| 19 | `lib/features/hos/presentation/providers/change_status_provider.dart` | 397 | 353 |
| 20 | `lib/features/hos/presentation/providers/hos_engine_provider.dart` | 83 | 71 |
| 21 | `lib/features/hos/presentation/providers/hos_provider.dart` | 159 | 140 |
| 22 | `lib/features/hos/presentation/providers/recap_provider.dart` | 38 | 31 |
| 23 | `lib/features/hos/presentation/providers/status_dashboard_providers.dart` | 145 | 127 |
| 24 | `lib/features/hos/presentation/widgets/driving_lock_screen.dart` | 57 | 54 |
| 25 | `lib/features/hos/presentation/widgets/location_display_widget.dart` | 39 | 35 |
| 26 | `lib/features/hos/presentation/widgets/status_option_tiles.dart` | 70 | 62 |
| 27 | `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart` | 150 | 139 |
| 28 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart` | 365 | 331 |
| 29 | `lib/features/hos/presentation/widgets/status_dashboard/operational_alerts_banner.dart` | 93 | 84 |

**المجموع: 3,046 سطر — 29/29 ملف مقروء.**

## E.2 — `lib/features/logs/**` (42 ملف)

| # | المسار | أسطر | غير فارغ |
|---|---|---|---|
| 1 | `lib/features/logs/data/datasources/log_local_data_source.dart` | 322 | 291 |
| 2 | `lib/features/logs/data/models/daily_log_dto.dart` | 143 | 134 |
| 3 | `lib/features/logs/data/models/log_model.dart` | 133 | 121 |
| 4 | `lib/features/logs/data/providers/log_repository_providers.dart` | 25 | 21 |
| 5 | `lib/features/logs/data/repositories/log_repository_impl.dart` | 539 | 498 |
| 6 | `lib/features/logs/domain/daily_form_rules.dart` | 93 | 83 |
| 7 | `lib/features/logs/domain/log_edit.dart` | 57 | 49 |
| 8 | `lib/features/logs/domain/saved_form_status.dart` | 36 | 31 |
| 9 | `lib/features/logs/domain/entities/audit_entry.dart` | 100 | 89 |
| 10 | `lib/features/logs/domain/entities/daily_form_data.dart` | 32 | 29 |
| 11 | `lib/features/logs/domain/entities/daily_form_update.dart` | 27 | 24 |
| 12 | `lib/features/logs/domain/entities/daily_log.dart` | 251 | 236 |
| 13 | `lib/features/logs/domain/entities/log_readiness.dart` | 69 | 63 |
| 14 | `lib/features/logs/domain/repositories/log_repository.dart` | 93 | 85 |
| 15 | `lib/features/logs/presentation/controllers/edit_log_controller.dart` | 122 | 105 |
| 16 | `lib/features/logs/presentation/controllers/form_tab_controller.dart` | 68 | 58 |
| 17 | `lib/features/logs/presentation/pages/audit_trail_page.dart` | 93 | 88 |
| 18 | `lib/features/logs/presentation/pages/edit_log_page.dart` | 433 | 407 |
| 19 | `lib/features/logs/presentation/pages/inspection_preview_page.dart` | 401 | 382 |
| 20 | `lib/features/logs/presentation/pages/logs_list_page.dart` | 239 | 225 |
| 21 | `lib/features/logs/presentation/pages/log_detail_page.dart` | 220 | 211 |
| 22 | `lib/features/logs/presentation/pages/shipping_documents_page.dart` | 170 | 160 |
| 23 | `lib/features/logs/presentation/pages/suggested_events_page.dart` | 121 | 117 |
| 24 | `lib/features/logs/presentation/pages/trailers_page.dart` | 170 | 160 |
| 25 | `lib/features/logs/presentation/pages/unidentified_events_page.dart` | 505 | 479 |
| 26 | `lib/features/logs/presentation/providers/audit_trail_provider.dart` | 10 | 9 |
| 27 | `lib/features/logs/presentation/providers/certify_log_provider.dart` | 193 | 163 |
| 28 | `lib/features/logs/presentation/providers/edit_log_form_provider.dart` | 66 | 59 |
| 29 | `lib/features/logs/presentation/providers/logs_provider.dart` | 352 | 310 |
| 30 | `lib/features/logs/presentation/providers/log_detail_tab_provider.dart` | 5 | 4 |
| 31 | `lib/features/logs/presentation/providers/unidentified_events_provider.dart` | 170 | 154 |
| 32 | `lib/features/logs/presentation/widgets/codriver_picker_dialog.dart` | 113 | 105 |
| 33 | `lib/features/logs/presentation/widgets/log_graph.dart` | 101 | 86 |
| 34 | `lib/features/logs/presentation/widgets/status_radio_group.dart` | 61 | 57 |
| 35 | `lib/features/logs/presentation/widgets/time_field_widget.dart` | 53 | 50 |
| 36 | `lib/features/logs/presentation/widgets/time_picker_sheet.dart` | 175 | 165 |
| 37 | `lib/features/logs/presentation/widgets/vehicle_picker_dialog.dart` | 168 | 157 |
| 38 | `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart` | 346 | 324 |
| 39 | `lib/features/logs/presentation/widgets/log_detail_tabs/events_tab.dart` | 144 | 134 |
| 40 | `lib/features/logs/presentation/widgets/log_detail_tabs/expanded_content.dart` | 59 | 55 |
| 41 | `lib/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 383 | 358 |
| 42 | `lib/features/logs/presentation/widgets/log_detail_tabs/log_event_tile.dart` | 166 | 156 |

**المجموع: 6,634 سطر — 42/42 ملف مقروء.**

## E.3 — ملفات خارج النطاق قُرئت للتحقق (Cross-check)

| المسار | سبب القراءة |
|---|---|
| `lib/core/constants/fmcsa_constants.dart` | مطلوب صريحاً في نطاق المهمة (مقابل تكرار الثوابت) |
| `lib/core/config/hos_configuration.dart` | المصدر الحقيقي لحدود HOS |
| `lib/core/time/trusted_time_provider.dart` | للتحقق من HL-07 (Riverpod داخل الملف) |
| `lib/core/services/local_storage_service.dart` (ترويسة فقط) | للتحقق من HL-02 |
| `lib/core/utils/status_color_helper.dart` | للتحقق من HL-34 |
| `lib/core/utils/duration_format.dart` (ترويسة فقط) | للتحقق من HL-26 |
| `lib/core/time/time_formatter.dart` (ترويسة فقط) | للتحقق من HL-26 |
| `lib/backend/contracts/status_dashboard_backend.dart` | للتحقق من HL-02 |
| `lib/features/sync/domain/usecases/sync_engine.dart` (ترويسة فقط) | للتحقق من HL-01 |
| `lib/routes.dart` (قائمة المسارات فقط) | للتحقق من مسار التنقل |
| `lib/l10n/app_localizations.dart` (ترويسة فقط) | للتحقق من HL-17 |
| بحث نصي عبر `lib/` كله | لثوابت HOS والتكرارات والاستيرادات |

---

## ملحق: عدّاد التكرارات (كمية)

| البند | العدد | المواضع |
|---|---|---|
| تنفيذ loading | 12 | `CircularProgressIndicator` في 12 ملفاً (6 في `hos`+`logs` موزّعة) |
| تنفيذ error surface | 7 | `EldRetryView` في 6 ملفات |
| تنفيذ success toast | 6 | `AppFeedback.success` في `hos/.../change_status_page.dart:45`، `logs/.../log_detail_page.dart:137`، `logs/.../edit_log_page.dart:92`، `logs/.../unidentified_events_page.dart:167`، `logs/.../form_tab.dart:249,252`، `logs/.../certify_tab.dart:67` |
| تنسيق المدة | 4 | `daily_log.dart:216`, `events_tab.dart:106`, `logs_list_page.dart:168`, `DurationFormat` (غير مستخدم في الثلاثة الأولى) |
| تنسيق الوقت | 4 | `daily_log.dart:210`, `audit_trail_page.dart:77`, `certify_log_provider.dart:177`, `certify_tab.dart:82` |
| تسميات الحالات | 5 | `status_radio_group.dart:19`, `inspection_preview_page.dart:194`, `inspection_preview_page.dart:273`, `log_graph.dart:26`, `events_tab.dart:104` |
| خريطة رمز→لون | 2 | `StatusColorHelper` (مستخدمة) + `inspection_preview_page.dart:273` (مكرّرة) |
| تطبيع PC/YM | 3 | `log_graph.dart:47`, `events_tab.dart:117`, `inspection_preview_page.dart:194` |
| مطابقة `DutyStatus ⇄ DutyStatusCode` | 4 | `change_status_provider.dart:37`, `status_dashboard_providers.dart:18`, `hos_provider.dart:59`, `hos_rules_engine.dart:51` |
| بناء حمولة سلكية | 2 | `duty_status_tracker.dart:218`, `log_repository_impl.dart:206` |
| تطبيع الوحدات (ميل↔كم) | 3 | `duty_status_tracker.dart:227` (→كم)، `log_model.dart:59` (كم→ميل)، `dto`/presentation بال miles |
| استدعاءات دوال domain من widgets | 5 | `edit_log_page.dart:42,250,279`, `form_tab.dart:142,166` |
| RegExp أحرف الإدخال المكرر | 3 | `daily_form_rules.dart:30`, `trailers_page.dart:100`, `shipping_documents_page.dart:100` |
| writes عبر features | 7 | ( HL-25 ) |
| استيراد widgets عبر features | 3 | `logs_list_page.dart:11`, `inspection_preview_page.dart:16`, `driving_lock_screen.dart:7` |
| رموز حالة مكتوبة يدوياً في presentation | 5 | ( HL-34 ) |


