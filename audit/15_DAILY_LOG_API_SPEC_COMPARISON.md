# 15 — مقارنة وثيقة الـ API مع الكود الفعلي (Daily Logs Spec vs Code)

**المصدر المقارَن:** `daily_log_api_specification-1.md` (وثيقة "دليل وتوثيق واجهات السجلات اليومية وقواعد HOS لمطور التطبيقات — Flutter & Web").
**الطرف الآخر:** كود التطبيق الفعلي في `lib/` (المسار الحقيقي المستدعى وقت التشغيل: `EldDailyLogsBackend` + `LogRepositoryImpl`).
**المنهجية:** مقارنة ساكنة بند-ببند. لا اتصالات شبكة أُجريت في هذه الجولة؛ كل أثر على الخادم مصنّف كـ"أثر متوقع إذا كان الخادم يطبق الوثيقة حرفياً".
**تنبيه:** تعليق `eld_endpoints.dart:5-7` يقول إن المسارات مطابقة لـ `openapi.yaml` المسحوب في 2026-09-23 — وثيقة الوصف الحالية أحدث، أي أن الاختلافات التالية هي **انحراف عقد (Contract Drift)** بين ما بُني عليه التطبيق وما توثقه الوثيقة.

---

## 0. جدول الاختلافات الموجز

| # | البند | الوثيقة | الكود | النوع | الخطورة |
|---|---|---|---|---|---|
| D1 | ترقيم القائمة | `page`/`size` + كائن `pagination` | `limit`/`offset`، ولا قراءة لـ `pagination` إطلاقاً | تعارض جوهري | **عالية** |
| D2 | معاملات فلترة القائمة | deviceId, formStatus, logDate, page, size | ruleId, requiresAction, limit, offset (وبعض معاملات الوثيقة غائبة) | انحراف | متوسطة |
| D3 | شكل عنصر السجل | `totals.total.{seconds,formatted}` + `certified` + `logStatus` | `formattedTotalWorkTime`, `totalDurationMinutes` + حقول مسطحة أخرى | تعارض أشكال | **عالية** |
| D4 | أحداث اليوم | `GET /{id}/events` (timeRange متداخل + segments + applicableExceptions) | `GET /{id}/graph-grid` (أحداث مسطحة: startTime/durationMinutes/odometerKm) | مسار وشكل مختلفان | **عالية** |
| D5 | تفاصيل/تعديل حدث | `GET`+`PUT /{id}/events/{eventId}` (editRestrictions, vehicleId, location{}) | لا يستخدمهما؛ التعديل عبر `/eld/duty-status/{id}` بحقول مختلفة | مسار مختلف كلياً | **عالية** |
| D6 | خيارات شاشة الأحداث | `GET /{id}/events/options` | غير موجود (حالات ثابتة بالكود + company-vehicles) | غائب | متوسطة |
| D7 | قراءة النموذج | `vehicle{id,identifier,vin,licensePlate,eldIdentifier}` متداخل | يقرأ `uniqueId`/`vehicleName` مسطّحين فقط | تعارض أشكال | **عالية** |
| D8 | حفظ النموذج | Body: `vehicleId` رقمي + `notes` | Body: `uniqueId` نصي، بلا `notes` | تعارض جوهري | **عالية** |
| D9 | حالة الاعتماد | `GET /{id}/certify` (statement/signature/canCertify/validationCodes) | `GET /{id}/readiness` (readinessStatus/missingRequirements/availableActions) | مسار وشكل مختلفان | **عالية** |
| D10 | تنفيذ الاعتماد | Body: `{certified, signatureImage}` / Response: `certification{}` متداخل | Body: `{dailyLogId,driverId,logDate,signatureCertificateId,signatureConfirmation,certifiedTrue}` / يقرأ حقولاً مسطحة | تعارض جوهري | **عالية** |
| D11 | ملخصات السجلات | `GET /{id}summary` (ملفوفة/مفصّلة) | لا يُستدعى إطلاقاً | غير مستخدم | منخفضة |
| D12 | بنية الغلاف | `pagination`, `errors[]`, `requestId` قواعد إلزامية | تُقرأ `success/data/message/error` فقط — الثلاثة مهمَلة | ناقص | متوسطة |

---

## 1. نقاط الاتفاق المؤكدة (Matches)

| البند | الدليل |
|---|---|
| المسار الأساسي `/api/eld/daily-logs` | `backend_network_providers.dart:33-38` يضمن لاحقة `/api` + `eld_endpoints.dart:51` ✅ |
| المغلف: الاعتماد على `success == true` + حالة 2xx | `api_response.dart:94-101` ✅ |
| مصادقة Session Cookie عبر `POST /session` (form-urlencoded) | خيار من ثلاثة في الوثيقة؛ التطبيق يستخدمه — متوافق ✅ |
| `GET /daily-logs` + `GET /daily-logs/{id}` موجودان بنفس المسار | `eld_endpoints.dart:51-53` ✅ |
| `GET|PUT /daily-logs/{id}/form` بنفس المسار | `eld_endpoints.dart:61` ✅ |
| `POST /daily-logs/{id}/certify` بنفس المسار | `eld_endpoints.dart:57` ✅ |
| شكل `trailers[{trailerNumber}]` و`shippingDocuments[{documentNumber}]}` في الطلب والاستجابة | `log_repository_impl.dart:309-317, 355-371` ✅ |
| `coDriver{id,name}` المتداخل مقروء (مع Flat fallback) | `log_repository_impl.dart:373-381` ✅ |
| حقل `editable` لكل حدث مقروء | `log_model.dart:84` ✅ |

---

## 2. التحليل التفصيلي

### D1 — الترقيم: `page/size + pagination` (وثيقة) مقابل `limit/offset` (كود)
- **الوثيقة:** معاملات `page=0`, `size=20`، والاستجابة تعيد كائن `pagination{page,size,totalElements,totalPages,hasNext,hasPrevious}` مع قاعدة إلزامية (بندها #2) باستخدام `hasNext` لمعرفة وجود المزيد.
- **الكود:** يرسل `'limit': limit, 'offset': offset` (`eld_daily_logs_backend.dart:38-39`)؛ واجهة القائمة تستخدم `limit=20` وتزيد `offset += عدد السجلات العائد` وتحسب `hasReachedMax = newLogs.length < limit` محلياً (`logs_provider.dart:118-125, 148-154`).
- **`pagination` لا يُقرأ في أي مكان:** `ApiResponse` لا يحتوي أي معالجة له (grep على `lib/` كامل: لا نتائج خارج تعليق توثيقي في `api_response.dart:21,131`).
- **الأثر المتوقع إذا اتبع الخادم الوثيقة:** تجاهل `limit/offset` ⇒ إعادة الصفحة الأولى دائماً؛ إزالة التكرار في `logs_provider` تخفي الأعراض لكن التمرير اللانهائي سيعيد نفس الصفحة بلا نهاية، ولا يتوفر `totalElements`.
- **التصنيف:** تعارض جوهري — يحتاج حسم عقد مع الخادم + تعديل `DailyLogsBackend.list` و`logs_provider`.

### D2 — انحراف معاملات القائمة
| موجود في الوثيقة | في الكود؟ | موجود في الكود وليس الوثيقة |
|---|---|---|
| `page`, `size` | ❌ (بديلهما limit/offset) | `ruleId` (`eld_daily_logs_backend.dart:36`) |
| `deviceId` | ❌ | `requiresAction` (:37) |
| `formStatus` | ❌ | `limit`/`offset` |
| `logDate` | ❌ | |
| `driverId/status/certificationStatus/startDate/endDate` | ✅ (:31-35) | |

- ملاحظة: `getDailyLogs` في المستودع لا يمرّر سوى `driverId/limit/offset` (`log_repository_impl.dart:81-85`) — بقية المعاملات موجودة في العقد لكن غير مستخدمة من واجهة القائمة.

### D3 — شكل عنصر السجل (القائمة والتفاصيل)
- **الوثيقة:** `{id, logDate, driver{id,name}, totals{total{seconds,formatted}}, formStatus, certificationStatus, certified, logStatus}`.
- **الكود يقرأ** (`daily_log_dto.dart:53-104`): `id` ✅، `logDate` ✅، `driver.name` ✅، لكن بدلاً من `totals`:
  - `formattedTotalWorkTime` (نصي مسطّح) و`totalDurationMinutes` (رقمي مسطّح) — **غير موجودين في مثال الوثيقة**.
  - استنتاج `isCertified` من `certificationStatus == 'CERTIFIED'` بدلاً من قراءة `certified` (الموجود في الوثيقة ومهمَل).
  - `logStatus` مهمَل كلياً.
  - fallback لـ `formIndicator{status,positive,color}` (:63-78) — غير موجود في الوثيقة.
- **الأثر المعروض:** قائمة السجلات تعرض الوقت من `formattedTotalWorkTime` مع fallback إلى `totalDrivingHours` (`logs_list_page.dart:165-169`)؛ إذا أرسل الخادم شكل الوثيقة حرفياً ستُعرض "0h 0m" لكل يوم.

### D4 — أحداث اليوم: مسار وشكل مختلفان
- **الوثيقة:** `GET /daily-logs/{id}/events` → غلاف يضم `graphGrid{totals{offDuty,sleeperBerth,driving,onDuty,total}, segments[{status, timeRange{startTime,endTime,durationSeconds,durationFormatted}}]}` + `applicableExceptions[{code,applicable}]` + `events[{id,status,startedOnPreviousDay,timeRange{...},editable}]`.
- **الكود:** يستدعي `GET /eld/daily-logs/{id}/graph-grid` (`log_repository_impl.dart:143` عبر `eld_endpoints.dart:63`) ويقرأ `data['events']` فقط، بأحداث **مسطّحة**: `startTime`, `durationMinutes`/`durationSeconds`/`duration`, `odometerKm→miles`, `origin`, `location/locationText`, `engineHours`, `editable`, `automatedDriving` (`log_model.dart:19-86`).
- **الاختلافات:**
  1. مسار مختلف (`/events` غير موجود في التطبيق إطلاقاً).
  2. الزمن متداخل في الوثيقة (`timeRange.startTime`) ومسطّح في الكود — إذا أرسل الخادم شكل الوثيقة، `LogEventModel.fromJson` يرمي `FormatException` لكل حدث فيُتخطى بصمت (سجل تحذير فقط، `log_model.dart:100-102`) ⇒ **رسم اليوم سيظهر فارغاً**.
  3. `startedOnPreviousDay`, `segments`, `totals`, `applicableExceptions` غير مقروءة (grep مؤكد: لا نتائج).
  4. حقول في الكود غير موجودة بالوثيقة: `odometerKm`, `origin`, `engineHours`, `automatedDriving`.
- ملاحظة: التطبيق أيضاً يستدعي `GET /eld/duty-status/graph-grid` (`eld_endpoints.dart:92`) لشريط HOS — مسار ثالث مختلف غير مذكور في الوثيقة.

### D5 — تفاصيل وتعديل الحدث: مجموعة مسارات مختلفة كلياً
- **الوثيقة:** `GET /{id}/events/{eventId}` يعيد `editableFields[]` و`editRestrictions{minStartTime,maxEndTime,cannotOverlap}` و`vehicle{id,identifier}` و`location{description,lat,lng,source}` و`specialCategory`؛ و`PUT /{id}/events/{eventId}` بجسم `{status, specialCategory, notes, vehicleId, location{latitude,longitude}}`.
- **الكود:** لا يستدعي أي مسار من هذين إطلاقاً. مسار التعديل الفعلي:
  - `PUT /eld/duty-status/{statusId}` بجسم `{status, startTime, locationText, editReason}` (`log_repository_impl.dart:281-284`).
  - `POST /eld/duty-status` بجسم `{status, startTime, locationText, notes, origin:'MANUAL', clientId}` (`:208-215`).
  - `EldEndpoints.editDutyStatusForm` (`eld_endpoints.dart:90`) **مُعرَّف لكنه ميت** — لا استدعاء.
- **الأثر:** قيود التحرير الزمنية المحسوبة خادمياً (`editRestrictions`) لا تصل للتطبيق؛ حادثة منع التداخل `cannotOverlap` تُدار حالياً عبر قواعد عميل/خادم أخرى (والـ 409 يعالج بالرفض النهائي — موثق في `IMPLEMENTATION_LOG_RUNTIME_LOG_FIXES.md`). ولا يوجد حقل `vehicleId` في تعديل الأحداث.

### D6 — `events/options` غائب
- الوثيقة: `GET /{id}/events/options` يعيد `statuses[{code,baseStatus}]` (بما فيها `PERSONAL_CONVEYANCE`/`YARD_MOVE` مع baseStatus) و`vehicles[]` و`locationSources[ELD_AUTO, MANUAL]`.
- الكود: لا يوجد أي استدعاء. الحالات ثابتة client-side في `DutyStatusCode` (`duty_status_code.dart:11+`)، والمركبات من `/eld/company-vehicles` (`vehicle_picker_dialog.dart:42` → `loadCompanyVehicles`)، ولا وجود لمفهوم `locationSources`.

### D7 — `GET /{id}/form`: شكل السيارة
- **الوثيقة:** `driver{...,licenseNumber,licenseState}`, `coDriver{id,name}`, `vehicle{id,identifier,vin,licensePlate,eldIdentifier}`, معلَقات/وثائق، `formStatus, editable, updatedAt, timeZone, logDate, dailyLogId`.
- **الكود** (`log_repository_impl.dart:348-394`) يقرأ:
  - `uniqueId` مسطّح (:383) و`vehicleName` مسطّح (:384) — **بدلاً من** `vehicle.identifier`.
  - `coDriverId` مسطّح مع fallback إلى `coDriver.id` (:373-381) ✅ جزئياً.
  - يهمل: `vin`, `licensePlate`, `eldIdentifier`, `licenseNumber`, `licenseState`, `updatedAt`, `editable`, `timeZone`, `dailyLogId`.
- **الأثر المتوقع إذا اتبع الخادم الوثيقة:** تبويب النموذج يفتح بلا مركبة محددة (`vehicleUniqueId=null`) وقد يعاد حفظ النموذج فارغاً من هذه الناحية.

### D8 — `PUT /{id}/form`: تعارض أسماء الحقول
- **الوثيقة:** `{vehicleId: 502 (رقمي), coDriverId, trailers, shippingDocuments, notes}`.
- **الكود** (`log_repository_impl.dart:309-318` و`daily_form_update.dart`): `{uniqueId: "<نصي>", coDriverId, trailers:[...], shippingDocuments:[...]}` — **بلا** `notes`، ومع مفتاح مختلف تماماً (`uniqueId` بدل `vehicleId`).
- نفس الحمولة تُخزَّن في الطابور أوفلاين وتُعاد في المزامنة (`traccar_remote_event_dispatcher.dart:346`) ⇒ أي تعارض يسري على المسارين.
- **الأثر المتوقع:** إذا تطلب الخادم الجديد `vehicleId`، فالحفظ الفوري والمؤجَّل يفشلان أو يحفظان بلا مركبة (400/تجاهل حقل).

### D9 — قراءة حالة الاعتماد: `/certify` (وثيقة) مقابل `/readiness` (كود)
- **الوثيقة:** `GET /{id}/certify` → `statement{text,ruleReference:"§395.30(b)(1)"}`, `signature{imageData,hasSignature}`, `certificationStatus, certified, canCertify`, `validationCodes[]` (`FORM_NOT_FINAL`, `SIGNATURE_REQUIRED`).
- **الكود:** `GET /eld/daily-logs/{id}/readiness` (`eld_endpoints.dart:67`؛ `log_repository_impl.dart:493`) → `readinessStatus, missingRequirements[], legalStatement, availableActions[]` + `pendingCarrierEdits` (`readiness_dto.dart`).
- **الاختلافات:**
  - نموذج المانع مختلف: `validationCodes` مقابل `missingRequirements` النصية.
  - حالة التوقيع (`hasSignature`) غير مرصودة من الخادم — التطبيق لا يرفع توقيعاً أصلاً (`eld_signature_backend.dart:24-33`: لا مسار رفع توقيع في العقد القديم).
  - `canCertify` غير مقروء؛ الأهلية تُحسب محلياً في `CertifyLogState.isReady` (`certify_log_provider.dart:35-42`).
  - `ruleReference` غير مقروء (النص القانوني يُعرض من `legalStatement`/الترجمة المحلية).
  - مسار `/certify` بـ GET غير موجود في التطبيق (فقط POST).

### D10 — `POST /{id}/certify`: جسم واستجابة مختلفان
- **الطلب:**
  - الوثيقة: `{ "certified": true, "signatureImage": null }`.
  - الكود (`certify_dto.dart:18-28`): `{dailyLogId, driverId, logDate, signatureCertificateId: 'local_drawn', signatureConfirmation: true, certifiedTrue: true}` — الأسماء مختلفة تماماً و`signatureImage` لا يُرسل أبداً (`certify_log_provider.dart:210`).
- **الاستجابة:**
  - الوثيقة: `{dailyLogId, logDate, certification{status, certified, certifiedAt, certificateId}, logStatus}`.
  - الكود يقرأ (`certify_dto.dart:43-49`): `dailyLogId` ✅، لكن `certificationStatus` و`isCertified` **مسطّحين** — مع شكل الوثيقة يسقط إلى القيم الافتراضية `'UNCERTIFIED'`/`false`.
  - الأثر العملي مُخفَّف جزئياً لأن `certify_log_provider.dart:216-224` يتجاهل قيمة الإرجاع ويعتبر أي نجاح اعتماداً — لكن أي استخدام مستقبلي لـ `isCertified` سيقرأ false، و`certificateId` (رقم الشهادة) **لا يُلتقط ولا يُعرض في أي مكان** (grep: لا نتائج في `lib/`).

### D11 — `GET /daily-logs/summary` غير مستخدم
- الوثيقة تعرضه كواجهة رقم 2 بقائمة ملخصات + ترقيم وفلترة.
- الكود: لا يوجد أي استدعاء (grep على `/summary`: لا نتائج في `lib/`). القائمة الكاملة `GET /daily-logs` تستخدم لعرض الملخصات (شاشة السجلات).

### D12 — قواعد المغلف: `pagination` / `errors[]` / `requestId`
- الوثيقة تفرض ثلاث "قواعد معمارية إلزامية": قراءة `hasNext` من `pagination`، عرض أخطاء الحقول من `errors[]`، وحفظ `requestId` للدعم.
- الكود يقرأ فقط `success/status/code/data/message/error` (`api_response.dart:92-119`):
  - `pagination` → مهمَل (D1).
  - `errors[]` (مصفوفة أخطاء الحقول) → مهمَلة؛ `error_mapper` يبني الرسائل من كود HTTP/body النصي ⇒ رسائل التحقق الحقلي لا تصل للمستخدم.
  - `requestId` → لا يُقرأ ولا يُسجَّل ⇒ تعقّب الدعم يتطلب خطوات يدوية.

---

## 3. مقارنة إجمالية: ما الذي تغيّر فعلياً في العقد؟

الوثيقة تصف **موجة عقد جديدة** سمة أبرز فروقها:
1. **الترقيم المؤسسي:** `page/size/pagination` بدل `limit/offset`.
2. **أحداث اليوم كمورد رسمي:** `/events` بزمن `timeRange` متداخل + `segments` + `applicableExceptions` بدل `/graph-grid` المسطّح.
3. **تعديل الأحداث عبر السجل** (`/daily-logs/{id}/events/{eventId}`) بدل `/duty-status/{id}`.
4. **العنونة الرقمية للمركبة** (`vehicleId`) بدل `uniqueId` النصي في النموذج.
5. **الاعتماد كمورد قابل للقراءة** (`GET /certify`) بنص القسم والنص القانوني ورموز التحقق.
6. **الغلاف الموحد الكامل** (`pagination/errors/requestId`) وقواعد استهلاك إلزامية.

بينما يعمل التطبيق تجريبياً ضد النمط القديم (OAS 2026-09-23) — وقد أثبتت قراءاته الحية في 2026-10-01 أن مسارات `daily-logs`، `/{id}`، `/form`، `/readiness`، `/team`، `/graph-grid` كانت **مستجيبة 200** (تقرير ENDPOINT_LIVE) — أي أن الوثيقة على الأرجح **وصف لخادم أحدث (أو مخطط تحديث موافق عليه) والتطبيق لم يُحدَّث إليه بعد**.

## 4. التوصيات حسب الأولوية

| الأولوية | البند | الإجراء |
|---|---|---|
| P0 | D4 (الأحداث) | حسم المسار المعتمد (`/events` أم `/graph-grid`)؛ إن كان `/events` قائماً فأضف DTO لشكل `timeRange` المتداخل مع مهلة انتقالية تقبل الشكلين |
| P0 | D8 (حفظ النموذج) | تحديد مفتاح الخادم الفعلي للمركبة (`vehicleId` أم `uniqueId`) وتوحيده في المسار الفوري والأوفلاين؛ سؤال الخادم عن `notes` |
| P0 | D10 (الاعتماد) | مطابقة جسم POST والاستجابة (قراءة `certification{}` المتداخل والتقاط `certificateId`) بعد تأكيد العقد الحي |
| P1 | D1/D2 (الترقيم والفلترة) | تأكيد دعم `limit/offset` أم `page/size`؛ إدخال قراءة `pagination` في طبقة الشبكة |
| P1 | D3 (شكل عنصر السجل) | قراءة `totals.total` مع الإبقاء على fallback المسطّح |
| P1 | D7 (شكل النموذج) | قراءة `vehicle{...}` المتداخل مع fallback إلى `uniqueId`/`vehicleName` |
| P1 | D9 (جاهزية/اعتماد GET) | توحيد النموذج مع الخادم (validationCodes أم missingRequirements) |
| P2 | D12 | التقاط `requestId` في سجلات الأخطاء و`errors[]` لرسائل التحقق الحقلي |
| P2 | D6/D11 | تقرير: هل `events/options` و`summary` ستُعتمد؟ إن نعم، إضافتهما للعميل |
| معلوماتي | D5 | اعتماد `editRestrictions` من الخادم إذا تحول تعديل الأحداث إلى مسار السجل الرسمي |

## 5. ما يحتاج تحققاً حياً (غير منفَّذ — لا اتصالات في هذه الجولة)

1. أي شكل استجابة يعيده `GET /daily-logs` فعلياً اليوم (`totals` أم `formattedTotalWorkTime`؟)
2. هل يستجيب الخادم الحالي لـ `limit/offset` أم `page/size` فقط؟
3. هل `/eld/daily-logs/{id}/events` منشور الآن؟ وما شكل `timeRange`؟
4. جسم POST certify المقبول حالياً، وهل يعيد `certification{}` المتداخل مع `certificateId`؟
5. هل `/daily-logs` الحالي يقبل `uniqueId` في PUT form أم `vehicleId`؟

**الخلاصة:** 12 اختلافاً مؤكداً (4 منها تعارض أشكال/أجسام مباشر قد يعطل الوظيفة إن تحوّل الخادم للوثيقة: D4، D7/D8، D10، D1)، والباقي فجوات تغطية وانحراف معاملات. التطبيق مبني على العقد الأقدم؛ أي ترحيل خادمي إلى مواصفات هذه الوثيقة يتطلب تحديثات عميل مقابلة قبل النشر.
