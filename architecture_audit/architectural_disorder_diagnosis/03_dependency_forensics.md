# 03 — تشريح الاعتماديات (Dependency Forensics)

> أُعيد بناء مخطط الاستيراد كاملاً في هذه المهمة: **1,726 حافة داخلية فريدة** (408 ملفات).
> الفرق عن رقم التدقيق (1,628) سببه: إصلاح خلل محلل (مسارات `package:` النسبية من ملفات الجذر) + احتساب `export`.
> كل حافة أدناه موجودة في الشجرة الحالية — تحققت منها سطراً بسطر.

## 1. `core` يستورد `features` — 7 حواف (مؤكد)

| # | المصدر | الهدف | لماذا توجد | مبررة؟ | خطر الإزالة |
|---|---|---|---|---|---|
| 1 | `core/di/app_providers.dart:7` | `features/auth/domain/repositories/auth_repository.dart` | جذر تركيب auth | ⚠️ جزئياً — الملف **يدّعي** أنه الوحيد المسموح، وهو فعلاً الجذر الوحيد من نوعه | كسر DI لـ auth |
| 2 | `core/di/app_providers.dart:10` | `features/auth/data/repositories/auth_repository_impl.dart` | تركيب التنفيذ | ⚠️ نفس السياق — مقصود ومعلن (`ONLY ALLOWED IN THIS FILE`) | كسر DI |
| 3 | `core/di/auth_local_data_source_provider.dart:3` | `features/auth/data/datasources/auth_local_data_source.dart` | تركيب مصدر محلي | ⚠️ نفس السياق | كسر DI |
| 4 | `core/events/eld_events_provider.dart:3` | `features/tracking/data/datasources/live_tracking_data_source.dart` | بث الأحداث الحية | ❌ لا — مصدر بيانات ملموس بدل عقد؛ التعليق يدّعي فصلاً لم يتحقق | متوسط (يُستبدل بعقد في `core`) |
| 5 | `core/events/eld_events_provider.dart:5` | `features/tracking/domain/entities/connection_status.dart` | نوع البث | ❌ لا — مع (4) | منخفض |
| 6 | `core/providers/driver_rules_provider.dart:2` | `features/account/presentation/providers/rules_screen_provider.dart` | اشتقاق قواعد السائق | ❌ لا — `core` يراقب **presentation**؛ العمر `autoDispose` مربوط بعمر صفحة | متوسط (انظر W7) |
| 7 | `core/widgets/connection_status_indicator.dart:7` | `lib/routes.dart` | `rootNavigatorKey`؟ (تحقق: يستورد `routes.dart` + `connection_status.dart`) | ❌ لا — مكوّن `core` يعتمد على `app` ويُغلق الدورة الكبرى | منخفض (نقل المفتاح لملف مستقل) |

**الخلاصة:** 3 حواف تركيب معلن (مقبول موثّق)، و4 حواف انقلاب حقيقي. الرقم "7" صحيح لكنه يخلط فئتين مختلفتين تماماً.

## 2. الدورات — 4 حقيقية + 1 مولّدة (مؤكد بخوارزمية Tarjan)

### C1 — الدورة الكبرى (25 ملفاً)

العمود الفقري (دورة دنيا من 3):

```
lib/routes.dart
  → lib/routes/home_routes.dart          (routes.dart:8)
  → lib/features/home/presentation/pages/home_page.dart   (home_routes يستورد الصفحة)
  → lib/routes.dart                       (home_page.dart يستورد routes.dart)
```

وبقية الـ 25 ملفاً ملتحقة عبر:
- `routes/*_routes.dart` تستورد الصفحات + `routes.dart` (5 ملفات توجيه).
- 7 صفحات/ودجات تستورد `routes.dart` (`connection_status_indicator`، `eld_drawer`، `eld_connection_page`، `home_page`، `inspection_start_view`، `logs_list_page`، `suggested_events_page`، `select_vehicle_page`).
- `home_page ↔ driving_lock_screen` **استيراد متبادل مباشر** (الأضيق والأخطر).
- `account/rules/info_packet/user_manual/about/settings/codriver/dvir_list/dot_inspection` عبر `eld_drawer` وملفات التوجيه.
- `eld_diagnostics_section`/`manual_recording_section` عبر `about_page` و`eld_connection_page`.

**الآلية الجذرية:** الصفحات تحتاج `routes.dart` (لـ `AppRoutes.*` و`rootNavigatorKey`)، وملفات التوجيه تحتاج الصفحات (لتسجيل المسارات). لا توجد طبقة توجيه مجردة بينهما.

**الأثر العملي:** لا يمكن تحميل أي صفحة من الـ 17 بمعزل عن `routes.dart`، ولا `routes.dart` بمعزل عن كل الصفحات — الاختبار المعزول للتنقل مستحيل.

### C2 — `core_providers ↔ backend_network_providers` (آلية: barrel متبادل)

```
core/network/core_providers.dart  --export-->  backend/providers/backend_network_providers.dart
backend/providers/backend_network_providers.dart  --import-->  core/network/core_providers.dart
```

`core` يعيد تصدير مزودات `backend` ("ملفات تحتاج استيراد core_providers فقط"). النية تنظيمية، والنتيجة دورة. الإزالة آمنة: حذف سطر `export` واستيراد المصدر مباشرة.

### C3 — `log_repository_providers ↔ log_repository_impl` (آلية: export خلفي)

```
data/providers/log_repository_providers.dart  --import-->  data/repositories/log_repository_impl.dart
data/repositories/log_repository_impl.dart    --export-->  data/providers/log_repository_providers.dart
```

ملف التنفيذ يُصدّر ملف المزودات (على الأرجح لتسهيل الاستيراد). الإزالة آمنة.

### C4 — `local_storage_service ↔ tracking_config_storage_service` (تبعية متبادلة حقيقية)

```
tracking_config_storage_service.dart:4  →  local_storage_service.dart
local_storage_service.dart:10           →  tracking_config_storage_service.dart
```

خدمتا تخزين في `core/services` تعتمد كل منهما على الأخرى. هذه الوحيدة التي قد تخفي منطقاً دائرياً وقت التشغيل (تهيئة متبادلة) — تستحق فحص ترتيب البناء في `app_initializer`.

### (مستثناة) — `l10n/*` الأربعة: دورة ملفات مولّدة، ليست عيباً معمارياً.

## 3. `presentation → data` — 20 حافة (مؤكد، لكن التوصيف يحتاج تدقيقاً)

**جميعها العشرون** تستهدف ملفات `data/providers/*.dart` — أي ملفات **تركيب** لا تنفيذاً (`*_impl.dart` ولا `datasources/*` ولا `models/*`).

| النمط الغالب (17/20) | مثال |
|---|---|
| `presentation/providers/X` يراقب `data/providers/x_repository_providers` | `logs_provider → log_repository_providers` |

هذا **النمط الطبيعي في Riverpod** (الواجهة تستهلك مزود المستودع). تسميته "تجاوزاً" مضلِّل جزئياً — المشكلة الحقيقية ليست الاستهلاك بل **مكان تعريف المزود**: التركيب يعيش داخل `data/` بدل جذر تركيب، فيبدو الاستهلاك الطبيعي كعبور طبقي.

**الاستثناءات الحقيقية (3/20)** — عبور لميزة أخرى:
- `eld_connection_page → tracking/data/providers` (صفحة connection تستهلك تركيب tracking)
- `hos_engine_provider → logs/data + sync/data providers`
- `send_logs_page → logs/data/providers` (صفحة inspection تستهلك تركيب logs)

## 4. `presentation → backend` — 14 حافة (مؤكد)

| الفئة | الحواف |
|---|---|
| مزودو العقود عبر `backend_providers` (طبيعي: حقن عقد مجرد) | `account_provider`، `rules_screen_provider`، `forgot_password_form`، `team_status_provider`، `eld_connection_page`، `hardware_alerts_provider`، `hardware_status_provider`، `hos_engine_provider`، `unidentified_events_provider` (9) |
| عقد مباشر | `account_provider → account_backend`، `unidentified_events_* → contract_enums` (3) |
| **تنفيذ/DTO مباشر** | `rules_page → eld_engine/models/rules_screen_dto`، `auth_state_provider → backend_network_providers` (2 — هذه هي المخالفات) |

**التدقيق:** 9/14 حقن عقود عبر المزودات (مقبول)، 3 عقود مباشرة (مقبول حدودياً)، **2 عبور للتنفيذ** (مخالفة).

## 5. `backend → features` — 9 حواف (التدقيق قال 6؛ الصحيح 9)

| الحواف الأربع الموثقة | `rules_screen_*` (mapper + eld + mock + contract) → `account/application/models/rules_screen_model` |
|---|---|
| الحافتان الموثقتان | `auth_interceptor` → `auth/data + auth/domain` |
| **3 حواف لم يرصدها التدقيق** | `backend_network_providers` → `traccar_native_client{,_impl,_mock}` (3 ملفات SDK في `features/tracking/data`) |

سبب الفوت: خلل محلل التدقيق في مسارات `package:` (مؤكد بإعادة البناء). **السبب الجذري واحد في الحالات التسع: لا يوجد مالك متفق عليه لنماذج `RulesScreen` وواجهات Traccar** — فكل طبقة تستورد من حيث وجدت الشيء.

## 6. تبعيات خفية إضافية (مقاسة)

| الحافة | الدلالة |
|---|---|
| `log_repository_impl → eld_engine/models/certify_dto` | مستودع data يعتمد DTO محوّل ملموس (تجاوز العقد) |
| `dvir_repository_impl → eld_engine/models/dvir_dto` | نفس النمط |
| `*_impl → sync/domain/*` (pending_event, offline_queue) | المستودعات تُدخل أحداث المزامنة مباشرة — coupling خفي بين كل الميزات وsync |
| `app.dart → hos/* + auth/*` (4 استيرادات) | جذر التطبيق يعرف تفاصيل 2 ميزة (مقصود جزئياً: إبطال الجلسة) |
| `tracking_orchestrator (app) → 6 مزودات ميزات` | التنسيق العابر مركّز هنا — لكن `app.dart` ينسّق أيضاً (مستمعان) |

## 7. تبعيات عامة (global mutable state)

| الحالة | الموقع |
|---|---|
| `SessionEpoch._value` (static) | `core/session` — عداد أحادي، مُدار من `AuthNotifier` فقط (موثّق ومقصود) |
| `rootNavigatorKey` (global) | `routes.dart` — وقود الدورة الكبرى |
| كاشات `static` متبقية | `codriver_repository_impl:17-18` (مؤكد) |
| `TrackingService` مزدوج | مثالان حيان (مؤكد) |
