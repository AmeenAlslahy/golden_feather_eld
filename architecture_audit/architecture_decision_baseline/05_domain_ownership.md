# 05 — ملكية النطاق (Domain Ownership)

## 1. لماذا ثلاثة مواقع؟ (الواقع المقاس)

| الموقع | المحتوى الفعلي | التفسير الأدق |
|---|---|---|
| `lib/domain/` (7 مجلدات) | كيانات freezed + `value_objects` + `DutyStatusCode` + `server_config` + `telemetry_reading` | النطاق المشترك **الأصلي** — أنواع تعبر الميزات والخلفية |
| `lib/core/domain/entities/` (3 ملفات) | `user`، `hos_models`، `location_point` | امتداد لاحق بلا توثيق توزيع — **ازدواج موضعي** لا دلالي (لا تكرار كيانات) |
| `lib/features/*/domain/` | كيانات الميزة + عقود المستودعات + محركات/سياسات + تحليل wire في 4 ملفات | نطاق الميزات — متفاوت النقاء |

## 2. المفاهيم المشتركة مقابل العرضية

| مشترك مشروع | الدليل |
|---|---|
| `DriverId`/`DvirId`/`DailyLogId` المميزة | تمنع خلط المعرفات عبر 45+ حافة backend→domain |
| `DutyStatusCode` | حلقة الوصل HOS↔backend↔عرض (رغم شائبة Flutter) |
| `TelemetryReading`، `PendingEvent`، `server_config` | تعبر backend/data/presentation |

| عالمي عرضي | الدليل |
|---|---|
| `hos_models.dart` في `core/domain` مقابل `lib/domain/duty_status/*` | مجال واحد (HOS) مقسّم على جذرين بلا معيار |
| `InformationPacketView` بلا `driverId` | كيان نطاقي ناقص الهوية (قبلها EC-0.2a كـ"ملكية طلب فقط") |

## 3. الكيانات المكررة

**لا تكرار كيانات مؤكد.** الازدواج موضعي (جذران) لا دلالي. `user.dart` (core) مقابل `driver_account.dart` (domain/account) و`user_model.dart` (core/data): ثلاث طبقات تمثيل (كيان/عقد/نموذج) — **مشروع** لا مكرر.

## 4. تبعيات النطاق العابرة

| الاتجاه | الحالة |
|---|---|
| `domain → data` | **صفر** — لم يُعثر على أي استيراد (نظيف) |
| `domain → presentation` | **صفر** — نظيف |
| `domain → Flutter` | **ملف واحد**: `duty_status_code.dart:7` (+ logger) — V-BND-06 |
| `domain → Dio/Riverpod` | **صفر** |
| `features/domain → backend contracts` | `duty_status_tracker → status_dashboard_backend` — **مخالفة نقاء** (النطاق يعرف عقد البنية) |
| `features/domain → core services` | `tracker → LocalStorageService` + `uuid` — **مخالفة نقاء** |

## 5. العقود والقواعد

- عقود المستودعات (`repositories/*.dart`) في كل ميزة ثلاثية — سليمة ورفيعة.
- القواعد الحقيقية: `HosRulesEngine.validateManualTransition`، `hos_calculator`، `refuseVehicleOperate`، `previousToReview` (الأخيرة في كائن حالة عرض — misplaced).
- `parse*` في النطاق (4 ملفات) + `vehicleOperateFailure` برموز HTTP — تحليل/ترميز نقل في النطاق (V-BND-08).

## 6. الحكم

النطاق **نقي بنسبة عالية** والاستثناءات معدودة وموضّعة. لا يُنصح بنقل كيانات حسب المجلد — يُنصح بـ: (أ) إخراج Flutter من `duty_status_code`، (ب) توثيق معيار الجذرين أو دمجهما، (ج) إخراج تحليل الـ wire من النطاق إلى المخططات.
