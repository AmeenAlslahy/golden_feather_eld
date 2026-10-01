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

## 🔴 المشاكل الحقيقية داخل نطاق تطبيق السائق (وسوم المواصفة 01–15)

### P1 — عيوب مؤكدة
1. **تسريبات استثناءات Java نصاً + تصنيف حالة خاطئ (400 بدل 500)** على مسارات إنتاج السائق:
   - `POST /eld/duty-status` و `POST /eld/status/duty-status` و `POST /eld/dot-inspection/send-logs` و `/start` و `PUT /eld/rules-screen`: `ELDPersistenceException: Database transaction failed…` في جسم الرد.
   - `POST /eld/daily-logs/{id}/carrier-edits` [05]: NPE (`Cannot invoke Long.longValue()…`).
   - التطبيق يصفيها بقائمة السماح، لكن الخادم يجب أن يعيد 500 برسالة نظيفة.
2. **مواصفة تعلن ما لم يُنشر على الخادم** (404 بمعرف حقيقي 106) [11.1 Driver HOS Rules]:
   - `GET /eld/drivers/{id}/rules/effective`
   - `POST /eld/drivers/{id}/hos/wellsite-waiting` + `adverse-conditions`
   - `GET /eld/drivers/{id}/rules` → **405 Method Not Allowed** (المواصفة GET والخادم يقبل PUT فقط)
   → تحديث المواصفة أو نشر المسارات.
3. **GET /eld/rules/{ruleSetId}/versions غير قابل للاستعمال أصلاً** [11. HOS Rules Engine]: ruleSetId يحتوي شرطة مائلة (`USA 70/8`) — حتى بترميز `%2F` يرفضها Jersey (`Ambiguous URI path separator`). يحتاج معرفاً بديلاً أو معالجة خادمية.

## ⚠️ اكتشاف نطاق: التطبيق يستدعي endpoint خارج نطاق السائق عند كل إقلاع
`RemoteConfigService.fetchOnStartup → GET /eld/config/settings` — المسار موسوم
**19. System Configuration** (ليس للتطبيق) **ويرد 500 NPE دائماً**، فيسقط التطبيق
صامتاً إلى الإعداد المحلي (`Using local config`). الإعداد عن بُعد عملياً معطّل.
القرار المطلوب: إما مسار config داخل نطاق السائق من الخادم، أو إزالة الاستدعاء.

## خارج نطاق السائق (وسوم 16–19 + Fleet Dashboard) — سُجلت للخادم لا للتطبيق
- [19] `GET /eld/config/settings → 500 NPE` — لم يُعد إصلاحه عائقاً للتطبيق.
- [17] `stats/driver/{id}` يختلق امتثالاً 100% لمعرفات سائقين غير موجودين.
- [Fleet] `dashboard/stream → 400 NPE` (SSE).

### 🟡 ملاحظات
- `POST /eld/transfer → 409 BUSINESS_RULE_VIOLATION` (بجسم فارغ) — سلوك سليم؛ موثق لأن المواصفة تعرض مسار transfer موازياً لـ dot-inspection/send-logs (الازدواجية نقطة لبس توثيقية).
- `POST /eld/hardware/connect → 503` مع قائمة تشخيص عربية منسقة — شكل استجابة ممتاز يُحتذى.
- 24 من 404 كانت «مسار موجود/مورد غير موجود» — دليل أن كل مسارات المواصفة منشورة ما عدا 5 أعلاه.

### ✅ ما ثبتت سلامته (43 نقطة)
تسجيل الدخول بالجلسة، account، profile/106، daily-logs وقائمة/تفاصيل/form/readiness/team/graph-grid لليوم، status + recap + status/duty-status (تحقق)، duty-status POST/PUT/إडيت-فورم، dvir catalog/list، dot-inspection cycle/logs/transfers/packet/send-logs/start/email-logs (تحقق)، unidentified-events، rules-screen (PUT تحقق)، hardware readiness/status/alerts/telemetry/manual-mode (تحقق)، drivers/{id}/rules/applied، reports/{id}/csv,pdf,html,xml بمحتوى حقيقي، company-vehicles، stats.

## توصيات
1. الخادم (داخل نطاق السائق): تصنيف 500 وتصفية استثناءات Java على مسارات الإنتاج الخمسة؛ نشر أو حسم مسارات 11.1؛ معالجة الشرطة المائلة في ruleSetId.
2. الخادم (خارج النطاق): settings NPE، تحقق stats، SSE — لفريق البوابة/النظام.
3. التطبيق (قرار مالك): إيقاف استدعاء `/eld/config/settings` عند الإقلاع أو انتظار مسار config داخل نطاق السائق — الإعداد عن بُعد معطّل فعلياً.
4. التوثيق: تعليم `/eld/transfer*` كمسار موازٍ لصالح dot-inspection.
