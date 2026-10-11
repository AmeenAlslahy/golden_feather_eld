# 04 — أنماط Riverpod (Riverpod Patterns)

> فحص كل مزودات المشروع (123 مرجع `flutter_riverpod`). الاستهلاك داخل `ConsumerWidget` **ليس** مخالفة — ولا يُحتسب هنا.

## 1. أربعة أنماط متعايشة لنفس المسؤولية

| النمط | أين | مثال | الحكم |
|---|---|---|---|
| **A. StateNotifier + State يدوي** | auth, account, codriver, dvir, logs, inspection, change_status | `AuthNotifier` (330)، `CoDriverNotifier` (238)، `DvirNotifier` (325) | مهيمن ومتماسك |
| **B. StateNotifierProvider يُبنى بقراءة عبر-ميزات** | dvir, codriver, logs | `dvirProvider` يقرأ `vehicleProvider` + `dashboardDataProvider` | طبيعي لكنه coupling مُعلن |
| **C. FutureProvider يضرب backend مباشرة** | codriver(team_status), connection(hardware_*), account(rules) | `team_status_provider.dart:16-35` (عمليتان + تحليل JSON) | **منطق data في presentation** |
| **D. Notifier يحمل `Ref` وينسّق ميزات** | hos, logs | `HosNotifier(engine, tracker, ref)`، `LogsNotifier(repo, driverId, ref)` | منسّق تطبيقي بلا اسم |

## 2. حقن الاعتماديات — 5 آليات

| الآلية | مثال | ملاحظة |
|---|---|---|
| `ref.watch(provider)` في مصنع المزود | الغالبية | سليم |
| بناء يدوي في `app_initializer` + `overrideWithValue` | `TrackingService`، التخزين | سليم المبدأ؛ **المثال المزدوج يجعله مكسوراً** (DST-037) |
| `ref.read` داخل مستمعين | orchestrator، app.dart | سليم |
| حفظ `Ref` كحقل (`final Ref _ref`) | `HosNotifier:25`، `AccountNotifier:34`، `ChangeStatusNotifier:215` | شائع؛ يمكّن التنسيق العابر |
| `_ref?` اختياري (nullable) | `LogsNotifier` (HL-31) | **خطير**: الكتابة العابرة تتوقف بصمت عند null |

## 3. دورة الحياة — غير متسقة

| السلوك | أين |
|---|---|
| `autoDispose` + إعادة بناء طازجة | dvir, change_status, team_status, hardware_* |
| `Provider` دائم بلا إبطال | inspection/codriver repos، dashboard، tracking services |
| إبطال يدوي عند الجلسة | `app.dart:42-44` (3 مزودات فقط) |
| سياج owner/epoch يدوي | account, codriver notifiers (لا dashboard، لا dvir، لا logs) |
| `keepAlive` + مؤقت 30 دقيقة | `dvirCatalogProvider` (مع `onDispose` — سليم) |
| مؤقت دوري دائم | `HosNotifier` (دقيقة)، `SyncNotifier` (دقيقة) — مع `dispose` سليم |

**لا قاعدة موحدة** لمتى يُعاد البناء ومتى يُحفَظ. كل ميزة تبتكر سياستها.

## 4. تسرب الحالة بين الميزات

| القناة | الاتجاه | الدليل |
|---|---|---|
| قراءة مزود ميزة أخرى | dvir→vehicle/home، logs→auth، connection→vehicle، codriver→auth | عشرات `ref.watch` العابرة |
| **كتابة** في مزود ميزة أخرى | logs→home (5 مواقع `dashboardDataProvider.notifier`)، dvir→dashboard | HL-25 مؤكد |
| `ref.invalidate` عابر | app→hos (3 مزودات) | مقصود (حدود جلسة) |
| حالة عامة | `SessionEpoch`, `rootNavigatorKey` | مقصود/وقود دورة |

## 5. التناقض الجوهري

النظام يستخدم Riverpod **كأداة حقن + حالة عرض + منسق أعمال** في آن واحد، دون تسمية الأدوار:
- `hosStatusProvider` يُبنى من `hosEngineProvider` + `dutyStatusTrackerProvider` (تركيب في presentation).
- `trackingServiceFullProvider` مقابل `trackingServiceProvider` (تركيب مكرر).
- `updateRulesUseCaseProvider` داخل ملف use-case (تركيب في application).

**النتيجة:** لا يمكن تمييز "مزود حالة" من "مزود تركيب" من "مزود تنسيق" — فتُقرأ كلها كحالة، وتُختبر كحالة، وتُعاد بناؤها كحالة.
