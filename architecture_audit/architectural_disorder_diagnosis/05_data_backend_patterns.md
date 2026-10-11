# 05 — أنماط البيانات والخلفية (Data & Backend Patterns)

## 1. Dio — نقطة دخول واحدة، اعتراضات مركزية

| الحقيقة | الدليل |
|---|---|
| مُنشئ `Dio()` واحد | `ApiClient` فقط (بحث آلي: `package:dio` = 8 مراجع) |
| الاعتراضات على `ApiClient` | auth + logger + time-drift (عبر `backend_network_providers`) |
| **الاستثناء الوحيد** | `push_notification_service.dart:136` — `HttpClient()` خام بلا مهلة ولا إغلاق (CORE-016 مؤكد) |
| تجاوز `ApiClient` | `eld_auth_backend` يبني URL مطلقاً ويستدعي `dio.post` مباشرة |

## 2. المحوّلات — نمطان متوازيان

| `eld_engine` | `mock` |
|---|---|
| HTTP حقيقي + `DotInspectionMapper` يقرأ `driver.id` | 22 موقع `throw UnimplementedError` من ~60 دالة عقد (BACK-020 مؤكد بالعد) |
| تطبيع الشكل (`{'data': ...}`) | `mock_dvir_backend:20` يعيد `{'reports': []}` ⇒ قائمة فارغة صامتة (BACK-008 مؤكد) |
| `mock_rules_screen_backend:7-8` يستورد من `eld_engine` (BACK-035 مؤكد) | الموك **ليس بديلاً مستقلاً** |

## 3. العقود — مجردة شكلاً، مسرّبة مضموناً

| الظاهرة | الدليل |
|---|---|
| عقد يستورد تنفيذاً | `daily_logs_backend:3-4` ← `eld_engine/models/{certify,readiness}_dto` (BACK-004 مؤكد) |
| `RawJson = Map<String, dynamic>` عملة العقود | 34 مستورداً (كل subs + contracts + مستودعا dvir/vehicle)؛ **لا ملف domain يستورده** (BACK-001 مُصحَّح جزئياً) |
| قيم wire في العقد | `contract_enums.dart:5-12` (`InspectionTransferType.wire`) — مقصود توثيقياً ("mirror the wire values") |
| `expectedOwnerDriverId?` في 4 عقود | شاغل عزل مُمرَّر كمعامل (Stage 2B-1) — يعمل، لكنه **يلوّث سطح العقد** بشاغل横切ي |
| عقود nullable واسعة | `BackendAdapter`: 13 getter nullable + `dispose()` — و`BackendRegistry` (129 سطراً) **بلا مستهلك إنتاجي** (يستهلكه اختبار فقط) |

## 4. المستودعات — 3 مذاهب للتخزين المؤقت

| المذهب | أين | السياسة |
|---|---|---|
| fallback يدوي لكل طريقة | كل المستودعات عبر `guardedNetwork(action, offline:)` | لا توحيد |
| ملكية مُتحقَّقة + epoch | `inspection_repository_impl` (بعد EC-0.2a) | الأشد — ملف واحد فقط |
| سياج owner/seq | `account/codriver` notifiers (وليس المستودعات) | على مستوى presentation |
| `static` بلا إبطال | `codriver_repository_impl:17-18` (متبقٍّ) | الأخطر المتبقي |

## 5. نظاما الطابور — ازدواج مؤكد، و"الميت" مبالغ فيه

| النظام | المكوّنات | الحالة |
|---|---|---|
| A. `SyncItem` + `SyncLocalDataSource` + `SyncRepositoryImpl` + `SyncNotifier` (مؤقت دقيقة) | `sync/data + presentation` | **حي**: يغذي واجهة الطابور (`getPendingItems`, `processQueue`) |
| B. `PendingEvent` + `OfflineQueue` + `SyncEngine` + `RemoteEventDispatcher` | `sync/domain` + `traccar_remote_event_dispatcher` | **حي**: المسار القانوني (duty/tracking events) + سياج المالك الجديد |

الحقيقة أدق من "نظام ميت": **نظامان حيان متوازيان لنطاقين مختلفين** (طابور واجهة عام مقابل أحداث قانونية)، لكن **بلا حد فاصل موثّق** — وأي مستودع يستورد من B مباشرة (`dvir_repo → pending_event/offline_queue`) يخلطهما.

## 6. تحويل الأخطاء — شبكة التخمين

```
DioException → error_mapper → AppError(context؟) → repository → Failure(message)
     → provider state.error (String) → widget يعرض خاماً (17 موقعاً)
```

- `duty_status_tracker:370-374`: تصنيف "شبكي؟" بنص `code` + غياب `context['statusCode']` — **مُثبت باختبار فاشل** (`Expected: 'server_rejected', Actual: <null>`، أعدت تشغيله بنفسي).
- `vehicle_selection.dart:99-119`: رموز HTTP (400/403/404/503/409) تُرمَّز في **النطاق**.
- `rules_screen_provider:22`: `throw Exception(l10nKey)` ⇒ كل الأخطاء "شبكة".

## 7. افتراضات الجلسة المكررة

`SessionEpoch` (عام) + سياج owner/epoch (3 مزودات) + `expectedOwnerDriverId` (4 عقود) + `transitioning` (بوابة عرض) — **4 آليات لشاغل واحد**، مطبقة جزئياً (codriver يسيّج التحميل لا التبديل).
