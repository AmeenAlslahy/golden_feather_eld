# 07 — التناقضات العابرة للميزات (Cross-Feature Inconsistencies)

> مقارنة فقط — بلا ترجيح نمط. "مبرر" تعني: الاختلاف له سبب تقني مشروع.

## 1. حقن المستودعات

| الميزة | النمط | مبرر؟ |
|---|---|---|
| auth | جذر مركزي `core/di` + use-cases رفيعة | — (المرجع الضمني) |
| hos/logs/inspection/dvir/vehicle/codriver | مزود تركيب في `data/providers` يراقَبه presentation | ⚠️ يعمل، لكنه يجعل "الاستهلاك الطبيعي" يبدو تجاوزاً |
| account/rules | use-case يحمل مزوده الخاص (`updateRulesUseCaseProvider` في ملف الـ use-case) | ❌ لا — تركيب في application |
| tracking | مزودان متطابقان (`trackingServiceProvider` مقابل `Full`) + override على أحدهما | ❌ لا — انقسام غير مقصود |

## 2. سياج الجلسات/الملكية

| الميزة | النمط |
|---|---|
| auth | `SessionEpoch` + `_operationId` + `_storageChain` |
| account/codriver | owner/epoch/seq منسوخ + `bindOwner/reset/_isCurrent` |
| inspection | epoch + owner tags + تحقق مُعلَن (بعد EC-0.2a) |
| dashboard/dvir/logs/hos | **بلا سياج** (يعتمد `autoDispose` أو لا شيء) |
| sync dispatcher | `expectedOwnerDriverId` مُمرَّر كمعامل |

ثلاثة مذاهب + غياب في 4 ميزات. **التباين نفسه هو الخطر** (codriver يسيّج التحميل لا التبديل).

## 3. معالجة أخطاء الشبكة مقابل الرفض

| المسار | السلوك عند الفشل |
|---|---|
| `duty_status_tracker.submitManualChange` | تخمين نصي (`network/connection/timeout/offline` أو غياب statusCode) ⇒ شبكي ⇒ يُطبَّق محلياً |
| `inspection_repository` (بعد الإصلاح) | تحقق ملكية + رفض صريح (`inspectionOwnerMismatch`, `inspectionNoVerifiedData`) |
| `account/codriver` notifiers | إسقاط صامت للردود المتأخرة (`return` بلا خطأ) |
| `dvir_provider` | `failure.message` خام في الحالة |

أربعة مذاهب للحدث نفسه (فشل/رفض). **مُثبت باختبار فاشل** للأول.

## 4. التخزين المؤقت

`guardedNetwork` + `offline:` يدوي (الكل) مقابل `cacheFor` بمدد مختلفة (30ث/5د/30د) مقابل epoch/owner (inspection) مقابل لا شيء (بعض القراءات). لا سياسة موحدة.

## 5. تحويل الحالات (`DutyStatus ⇄ DutyStatusCode`)

`change_status_provider` (تحويلان) مقابل `hos_provider._mapStatus` مقابل `DutyStatusCode.fromAny` (النطاق). ثلاثة مذاهب — **مبرر جزئياً** (خيارات العرض أوسع من حالات النطاق: `yardMoves`، `onDuty`)، لكن التحويلين اليدويين قابلان للتوحيد حول `fromAny`/`fromStatusCode`.

## 6. تحليل الاستجابات

mappers مركزية (eld_engine، عالية الجودة) مقابل تحليل مبعثر (`team_status_provider`، `hardware_status_provider`، `_asMap` ×5، `vehicle_selection`) مقابل `parse*` في النطاق. **غير مبرر** — نفس الشاغل بثلاثة مواضع طب قية مختلفة.

## 7. بناء الهوية للطلبات

`currentDriverIdProvider` (قراءة من auth) في الغالب، مقابل `int.tryParse(auth.user!.id)` يدوياً (orchestrator، account)، مقابل `DriverId(driverId)` المُمرَّر. تباين شكلي لا دلالي — **مخاطره منخفضة**.

## 8. ما هو متسق فعلاً (يُحفظ)

- `guardedNetwork` كبوابة شبكة في كل المستودعات.
- `Result`/`Either` + `fold` كأسلوب إرجاع.
- `AppLogger` للتسجيل (بلا `print` — لم يُعثر على أي).
- الترجمة عبر `AppLocalizations` في العرض (باستثناءات موثقة).
- بنية المجلدات `domain/data/presentation` في كل ميزة (الشكل متسق؛ المحتوى متفاوت).
