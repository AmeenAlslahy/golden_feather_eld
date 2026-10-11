# 02 — توزيع المسؤوليات (Responsibility Distribution)

> لكل طبقة: تملك / يجب أن تملك / تشارك خطأً / مكرر / بلا مالك. الدليل: ملف:سطر مقاس في هذه المهمة.

## 1. مصفوفة الطبقات

| الطبقة | تملك فعلاً | يجب أن تملك | تشارك خطأً | مكرر في مكان آخر |
|---|---|---|---|---|
| **presentation/pages** | عرض + تنسيق رحلات + قراءة مزودات data/backend مباشرة (20+14 حافة) | عرض + تنسيق رحلة الواجهة فقط | استدعاء backend (team_status:16-35، hardware_alerts)، تحليل JSON خام (team_status:26-32)، حل deviceId (dvir_form:440-476) | كتابة حالة ميزة أخرى (5 مواقع في dashboard) |
| **presentation/providers** | حالة عرض + **تنسيق أعمال** (hos changeStatus، dvir create/review، codriver switch) + **سياج جلسات** (3 ملفات) + DI جزئي | حالة عرض + تفويض للأعمال | قواعد FMCSA (change_status:278-295 مكررة مع المحرك)، رسم خرائط JSON، بناء حمولات شبكة | سياج owner/epoch منسوخ في 3 مزودات |
| **domain (features)** | كيانات + عقود + محركات HOS حقيقية | سياسات الأعمال النقية | تحليل wire (`_asMap`/`parseTeamStatus` في 4 ملفات)، `LocalStorageService` + `uuid` + عقد backend في tracker، `vehicleOperateFailure` يرمّز HTTP 400/403/404/503/409 | — |
| **domain (lib/domain)** | كيانات مشتركة | كيانات نقية | `Color` + `logger` في `duty_status_code.dart:7-8,75-88` (ينتشر لـ backend/contracts) | جذر موازٍ `core/domain/entities` (3 ملفات) |
| **data/repositories** | HTTP عبر backend + تخزين محلي + خرائط + fallback لكل طريقة | تنسيق مصادر البيانات فقط | توليد ملفات FMCSA (inspection)، تدفق صلاحيات النظام (tracking:50-80)، سياسات HTTP في المنسق | نظاما طابور (SyncItem مقابل PendingEvent) |
| **data/providers** | تركيب المستودعات | تركيب فقط | استيراد presentation/data لميزة أخرى (`sync_providers.dart:7-8` مع `ignore_architecture`) | — |
| **backend/contracts** | عقود + `RawJson` + قيم wire | عقود مجردة | استيراد نماذج `eld_engine` (4 حواف)، `expectedOwnerDriverId` مُمرَّر في 4 عقود (شاغل横切ي في العقد) | — |
| **backend/adapters** | HTTP + تحليل + mock غير مكتمل (22 `UnimplementedError`) | تنفيذ العقود | منطق أعمال في `DvirDto.fromJson/toJson` (BACK-006)، نصوص عرض إنجليزية في mapper | تطبيع URL ×3، `_asMap` ×5 بسلوكين |
| **core** | شبكة + خطأ + تخزين + وقت + إعدادات + تركيب + تصميم + أحداث | بنية تحتية قابلة لإعادة الاستخدام فقط | **يستورد features** (7 حواف)، تركيب auth، مزودا `secureStorageProvider` مكرران، مفاتيح تخزين ×4 أماكن | نظاما خطأ، نظاما زمن، حدود HOS ×2 |
| **app/routes** | توجيه + تنسيق عابر + `Provider<void>` منسق | بدء التشغيل والتوجيه | سياسات HTTP وحدود تنظيمية في المنسق، آثار presentation في `app.dart:49-64` | تنسيق موزّع على 3 مواضع |

## 2. أصناف متعددة المسؤوليات (مؤكدة)

| الصنف | المسؤوليات المعدودة | الدليل |
|---|---|---|
| `DutyStatusTracker` (hos/domain) | تتبع حالة + بناء حمولة شبكة + تخمين "هل الخطأ شبكي" بنصه + قراءة Hive + `uuid` + عتبة حركة + إحصاءات | `duty_status_tracker.dart:218-230,370-374` + الاستيرادات 4,5,11,13 |
| `AuthStateNotifier` (auth/pres) | سياسات هوية + ترتيب تخزين (`_storageChain`) + fencing زمني (`_operationId`) + تحويل أخطاء + epoch | `auth_state_provider.dart:140-151,175-324` (330 سطراً، نما من 293) |
| `ChangeStatusNotifier` (hos/pres) | خيارات عرض + 3 خرائط تحويل + تحقق + تنسيق hos+dashboard + دمج تعليقات | `change_status_provider.dart:13-111,273-359` (397 سطراً، نما من 353) |
| `InspectionRepositoryImpl` (insp/data) | backend + كاش + ملكية + توليد FMCSA + تحقق CSV + حذف ملفات + مزامنة | الملف بعد EC-0.2a (341 سطر diff) |
| `DvirNotifier` (dvir/pres) | حالة + §396.13 اختيار سابق + إرسال + مراجعة + طفرة محلية | `dvir_provider.dart:45-57,184-262` |
| `EldConnectionNotifier` (conn/page) | نموذج + notifier + مزود + 5 تبعيات بنية في **ملف صفحة** | `eld_connection_page.dart:27-248` + 24 استيراداً |
| `TrackingService` (tracking/data) | تخزين + متتبع أصلي + قناة أحداث + قراءة بيئة + خريطة نصية | `tracking_service.dart:32-95` |
| `HosNotifier` (hos/pres) | تنسيق محرك+متتبع + مؤقت + مستمعان + خرائط + تدقيق مخالفات مباشر | `hos_provider.dart:22-158` |

## 3. مسؤوليات بلا مالك واضح

| المسؤولية | الوضع |
|---|---|
| سياسة التخزين المؤقت الموحدة | **مفقودة** — كل مستودع يبتكر fallback |
| مالك `RulesScreenModel` | **متنازع عليه** — في `account/application` ويستهلكه `backend` (سبب 6 حواف backend→features) |
| مصدر `DriverRules` | **متنازع عليه** — `core/providers` يشتقه من presentation |
| مالك `EldDrawer` (app shell) | **في المكان الخطأ** — داخل `features/home`، يُستورد من 5 صفحات |
| مالك `rootNavigatorKey` | في `routes.dart` — تستورده 7 صفحات (وقود الدورة) |
| مالك زمن الثقة | متنازع: `TimeAuthority` مقابل `TrustedTimeProvider` + `MonotonicTimeAuthority` افتراضياً |
| مالك endpoint توكن الإشعار | **غير معروف** — 0 نتيجة في `lib/` و`openapi.yaml` |

## 4. ازدواج مقاس (يستحق الدمج)

| المكرر | المواقع | الحكم |
|---|---|---|
| سياج owner/epoch/seq | `account_provider:36-63` ≈ `codriver_provider:98-132` | **نفس الآلية منسوخة** — مرشح استخراج |
| فحص "المركبة تتحرك" | `change_status:278` + `hos_provider:95-106` (عبر المحرك) | مكرر عبر طبقتين |
| خرائط `DutyStatus ⇄ DutyStatusCode` | `change_status:37-52,95-110` + `hos_provider:59-74` + `DutyStatusCode.fromAny` | 3 آليات لنفس التحويل |
| تطبيع رموز الحالات (`PC/YM/SB…`) | `log_graph` + `inspection_duty_graph` (+ خرائط التسميات في `status_radio_group` و`inspection_preview`) | مكرر عبر ميزتين |
| تنسيق المدة (`_fmt`) | بقي موقع واحد (`events_tab:106`) — **تقلّص** منذ التدقيق | راقب لا تستخرج |
| `CircularProgressIndicator` | 12 موقعاً + `EldRetryView` في 11 موقعاً | **نفس المسؤولية** — مرشح توحيد |
| نظاما الطابور | `SyncItem`+`SyncRepositoryImpl` (حي: `sync_provider` يستهلكه) مقابل `PendingEvent`+`SyncEngine` | ازدواج حقيقي، والثاني هو المعتمد للمسار القانوني |
| حدود HOS | `hos_configuration.dart` مقابل `fmcsa_constants.dart` + `Duration(hours:11)` في واجهة | مصدر مركزي + نسخ يدوية |

## 5. ملاحظة منهجية

الحجم وحده لم يُستخدم دليلاً: `app_error.dart` (504) متماسك، و`dvir_dto.dart` (402) DTOات متماسكة، بينما `vehicle_selection.dart` (153) يحوي تحليل wire و`mac_address_validation.dart` (12) سليم. كل حكم أعلاه مربوط بسلوك لا بعدد أسطر.
