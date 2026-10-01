# تقرير الفحص الحي الشامل لنقاط النهاية — 2026-10-01

**النطاق**: كل مسارات openapi.yaml (86 مساراً / 91 طريقة) على snsoft.cloud بجلسة admin.
**المنهجية الآمنة**: القراءات بمعرفات حقيقية (driverId=106, logId=17)؛ الطفرات بأجسام فارغة أو معرفات وهمية (تثبت وجود المسار دون مساس بالبيانات).

## التوزيع العام
| الحالة | العدد | الدلالة |
|---|---|---|
| 200 | 43 | سليمة ومستجيبة |
| 404 | 24 | المسار موجود والمورد غير موجود (بمعرفات وهمية) — **صحة** |
| 400 | 15 | رفض تحقق — سليمة ما عدا تسريبات الاستثناءات أدناه |
| 406 | 5 | تقارير تحتاج Accept الصحيح — **عبرة الفحص لا الخادم** (أعيد اختبارها 200) |
| 409/503/500/0 | 4 | انظر المشاكل |

## 🔴 المشاكل الحقيقية (مرتبة بالأثر)

### P1 — عيوب خادم مؤكدة
1. **GET /eld/config/settings → 500 NPE**
   `SettingsRepository.findAll() because "this.settingsRepository" is null` — تكرر مرتين بيومين مختلفين. يعيق إعدادات التطبيق عن طريق RemoteConfig.
2. **GET /eld/stats/driver/{id} يختلق بيانات لسائق غير موجود**
   `stats/driver/999999999 → 200 {complianceScore: 100.0, statusCategory: COMPLIANT}` — لا تحقق من وجود السائق؛ أي معرف يرجع امتثالاً كاملاً. خطر تدقيق.
3. **تسريبات استثناءات Java نصاً + تصنيف حالة خاطئ (400 بدل 500)** على مسارات الإنتاج:
   - `POST /eld/duty-status` و `POST /eld/status/duty-status` و `POST /eld/dot-inspection/send-logs` و `/start` و `PUT /eld/rules-screen`: `ELDPersistenceException: Database transaction failed…` في جسم الرد.
   - `POST /eld/daily-logs/{id}/carrier-edits`: NPE (`Cannot invoke Long.longValue()…`).
   - التطبيق يصفيها بقائمة السماح، لكن الخادم يجب أن يعيد 500 برسالة نظيفة.
4. **GET /eld/dashboard/stream → 400 NPE** (`Sse.newBroadcaster() because "sse" is null`) — بث SSE غير عامِل + تصنيف خطأ خاطئ.
5. **GET /eld/rules/{ruleSetId}/versions غير قابل للاستعمال أصلاً**: ruleSetId يحتوي شرطة مائلة (`USA 70/8`) — حتى بترميز `%2F` يرفضها Jersey (`Ambiguous URI path separator`). يحتاج معرفاً بديلاً أو معالجة خادمية.
6. **مواصفة تعلن ما لم يُنشر على الخادم** (404 بمعرف حقيقي 106):
   - `GET /eld/drivers/{id}/rules/effective`
   - `POST /eld/drivers/{id}/hos/wellsite-waiting` + `adverse-conditions`
   - `GET /eld/drivers/{id}/rules` → **405 Method Not Allowed** (المواصفة تقول GET والخادم يقبل PUT فقط)
   → تحديث المواصفة أو نشر المسارات.

### 🟡 ملاحظات
- `POST /eld/transfer → 409 BUSINESS_RULE_VIOLATION` (بجسم فارغ) — سلوك سليم؛ موثق لأن المواصفة تعرض مسار transfer موازياً لـ dot-inspection/send-logs (الازدواجية نقطة لبس توثيقية).
- `POST /eld/hardware/connect → 503` مع قائمة تشخيص عربية منسقة — شكل استجابة ممتاز يُحتذى.
- 24 من 404 كانت «مسار موجود/مورد غير موجود» — دليل أن كل مسارات المواصفة منشورة ما عدا 5 أعلاه.

### ✅ ما ثبتت سلامته (43 نقطة)
تسجيل الدخول بالجلسة، account، profile/106، daily-logs وقائمة/تفاصيل/form/readiness/team/graph-grid لليوم، status + recap + status/duty-status (تحقق)، duty-status POST/PUT/إडيت-فورم، dvir catalog/list، dot-inspection cycle/logs/transfers/packet/send-logs/start/email-logs (تحقق)، unidentified-events، rules-screen (PUT تحقق)، hardware readiness/status/alerts/telemetry/manual-mode (تحقق)، drivers/{id}/rules/applied، reports/{id}/csv,pdf,html,xml بمحتوى حقيقي، company-vehicles، stats.

## توصيات
1. الخادم: إصلاح settings NPE + stats validation + SSE + تصنيف 500 وتصفية الاستثناءات.
2. الخادم/المواصفة: حسم مواصفة/نشر مسارات drivers/{id}/rules* والاستثناءات، ومعالجة الشرطة المائلة في ruleSetId.
3. التوثيق: تعليم `/eld/transfer*` كمسار موازٍ/مهجور لصالح dot-inspection.
4. التطبيق: لا تغيير مطلوب — طبقة الخطأ تُصفّي كل التسريبات أعلاه (قائمة السماح موثقة).
