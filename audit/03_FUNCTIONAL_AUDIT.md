# تقرير 03 — التدقيق الوظيفي (Functional Audit)

**المنهجية:** جرد الميزات من الشجرة + مطابقة مع الوثائق المرجعية في المستودع (SRS_V2_APP_FULL_REVIEW.md، SRS_DRIVER_AUDIT_2026-10-02.md، REMAINING_GAPS_2026-09-25.md، PROJECT_STATE.md) + اختبارات آلية منفّذة فعلياً (1035 اختباراً). لم يُنفَّذ Smoketest على جهاز — المسارات الحية وُسمت بحسب أقوى دليل متوفر.

**رموز الحالة:** VERIFIED (منفّذ/مثبت بدليل) · POTENTIAL (التنفيذ موجود ولم يُختبر تشغيلياً) · NOT TESTED (لم يُختبر إطلاقاً).

---

## 1. حصيلة جرد الميزات

| الميزة | الاكتمال | معالجة الأخطاء | حالات التحميل | حالات الفراغ | اختبارات آلية |
|---|---|---|---|---|---|
| تسجيل الدخول/الجلسة | ✅ | ✅ | ✅ | ✅ | ✅ (auth_page, splash, session_epoch_401...) |
| الاستعادة والإنهاء | ✅ | ✅ | ✅ | ✅ | ✅ (logout_leak_regression, session_isolation) |
| الصلاحيات | ✅ | ✅ | ✅ | n/a | ✅ جزئي (splash + widgets) |
| الاتصال بالجهاز (BLE/MAC) | ✅ واجهة | ✅ | ✅ | n/a | ✅ widget؛ ❌ تكامل حقيقي |
| لوحة الحالة (HOS) | ✅ | ✅ | ✅ | ✅ | ✅ واسع |
| تغيير الحالة + PC/YM | ✅ | ✅ | ✅ | n/a | ✅ |
| السجلات اليومية + Graph-Grid | ✅ | ✅ | ✅ | ✅ | ✅ واسع |
| تعديل الأحداث | ✅ | ✅ | ✅ | n/a | ✅ |
| Certify + إعادة الاعتماد | ✅ | ✅ | ✅ | ✅ | ✅ |
| DVIR (إنشاء/عيوب/توقيع/مراجعة) | ✅ | ✅ | ✅ | ✅ | ✅ واسع |
| تفتيش DOT (عرض/بدء/نقل) | ✅ واجهة؛ ❌ خادم | ✅ | ✅ | ✅ | ✅ widget؛ ❌ حي |
| إرسال/بريد السجلات | ✅ واجهة؛ ❌ خادم | ✅ | ✅ | ✅ | ✅ widget؛ ❌ حي |
| المساعد (Co-driver) | ✅ | ✅ | ✅ | ✅ | ✅ |
| المركبات (اختيار/أسطول) | ✅ واجهة؛ ❌ بيانات خادم | ✅ | ✅ | ✅ | ✅ |
| المزامنة والطابور | ✅ | ✅ | ✅ | n/a | ✅ واسع |
| التتبع الخلفي | ✅ | ✅ | ✅ | n/a | ✅ جزئي (قناة أصلية mocked) |
| الأحداث غير المحددة | ✅ | ✅ | ✅ | ✅ | ✅ |
| القواعد (Rules) | ✅ | ✅ | ✅ | ✅ | ✅ |
| حزمة المعلومات/الأدلة | ✅ | ✅ | ✅ | ✅ | ✅ |
| الإعدادات (خادم/لغة/ثيم) | ✅ | ✅ | ✅ | n/a | ✅ |
| حول/التشخيص | ✅ | ✅ | ✅ | ✅ | ✅ |

**الخلاصة الكمية:** لا يوجدFeature بلا اختبار حزمة عرض. الاختبارات تغطي المحركات (HOS calculator, duty_status_tracker، sync engine) بعمق والأخطاء وتصفيتها.

## 2. مسارات مكسورة أو معطوبة — مؤكدة بدليل

| ID | المسار | الدليل | الشدة | الحالة |
|---|---|---|---|---|
| FUN-01 | **بدء تفتيش DOT** — `POST /eld/dot-inspection/start` يرد **400** (jsonb `photos`) | `PROJECT_STATE.md` سطر 33؛ `docs/ENDPOINT_LIVE_REPORT_2026-10-01.md` §P1؛ `REMAINING_GAPS` سطر 64 | **حرجة** | VERIFIED (خادم) |
| FUN-02 | **إرسال السجلات** — `POST /eld/dot-inspection/send-logs` يرد **400** (قيد `status SUCCESS`) | `PROJECT_STATE.md` سطر 34؛ نفس التقرير الحي | **حرجة** | VERIFIED (خادم) |
| FUN-03 | **المركبات المخصصة فارغة** — `GET /eld/company-vehicles/my-vehicles` = `[]` للسائق 106 رغم `ELD-PRO-1006` متصل (ربط Traccar ناقص) | `PROJECT_STATE.md` سطر 208؛ ENDPOINT_LIVE_REPORT سطر 66 | **عالية** | VERIFIED (خادم/بيانات) |
| FUN-04 | **ازدواجية/تسريب استثناءات Java** على مسارات إنتاج: `duty-status`, `rules-screen`, `carrier-edits` (NPE)، بتصنيف 400 بدل 500 | ENDPOINT_LIVE_REPORT سطر 17–21 | عالية | VERIFIED (خادم) |
| FUN-05 | **مسارات 11.1 غير منشورة**: `/eld/drivers/{id}/rules/effective`، `wellsite-waiting`, `adverse-conditions` → 404؛ و`GET /eld/drivers/{id}/rules` → 405 | ENDPOINT_LIVE_REPORT سطر 22–26 | متوسطة | VERIFIED (خادم) |
| FUN-06 | **شاشة الفحص الدوري (SRS 7.15)** غير منفذة إطلاقاً | `SRS_DRIVER_AUDIT` سطر 126, 162؛ تأكيد بـ grep: لا `PeriodicInspection` في `lib/` | متوسطة | VERIFIED (كود) |
| FUN-07 | **الفحص الدوري للجهاز 3.5/3.6** (عتبات كشف الأعطال) غير منفذ تطبيقياً | `SRS_DRIVER_AUDIT` سطر 61–62؛ `REMAINING_GAPS` فئة (ب) | متوسطة | POTENTIAL — قرار مالك معلّق |
| FUN-08 | **تفاصيل DVIR مستقلة (7.12)** — الفتح يذهب لنموذج التحرير (مع تحميل التفاصيل لاحقاً) | `SRS_DRIVER_AUDIT` سطر 123 | منخفضة | POTENTIAL |
| FUN-09 | **§7.14 شاشة تشخيصات مستقلة + Simulate Malfunction** — القسم مدمج في شاشة About | `SRS_DRIVER_AUDIT` سطر 125؛ `REMAINING_GAPS` سطر 19 | منخفضة | VERIFIED (نطاق) |
| FUN-10 | **Factory Reset عبر Push** لا يفعل شيئاً (تعليق `TODO(Phase5)`) رغم تسجيله "password cleared" | `push_notification_service.dart:91-93` | منخفضة | VERIFIED (كود) |
| FUN-11 | **اعتماد/فورم أوفلاين (6.8)** — أحداث الواجب مؤكدة عبر الطابور، لكن تصديق/فورم أوفلاين غير مؤكد | `SRS_DRIVER_AUDIT` سطر 108 | متوسطة | NOT TESTED |

## 3. تنفيذات Placeholder / Mock في مسارات الإنتاج

| الفحص | النتيجة | الدليل |
|---|---|---|
| استخدام MockAdapter في production | ❌ **مستحيل** — الشرط يمنعه صراحة | `runtime_selection.dart:31-32` (VERIFIED) |
| MemoryOfflineQueue في production | ❌ mock فقط | `sync_providers.dart:65-68` (VERIFIED) |
| MockRemoteEventDispatcher | ❌ mock فقط | `sync_providers.dart:74-76` |
| MockTraccarNativeClient | ❌ mock فقط | `backend_network_providers.dart:78-81` |
| FailClosedRemoteEventDispatcher | لا مستدعي (dead code) | `sync_providers.dart:52` |
| قيم وهمية `1402` / `BOL-2024-001` | أُزيلت سابقاً — الآن مصدر واحد `dashboardNotifier` | PROJECT_STATE سطر 190 (تم) |

**النتيجة:** لا يوجد أي Mock فعّال في مسارات الإنتاج — نقطة قوة مؤكدة.

## 4. التحقق العملي المُنفَّذ في هذه الجولة

| الأمر | النتيجة | التصنيف |
|---|---|---|
| `flutter analyze --no-fatal-infos --no-fatal-warnings` | **No issues found** (157.9s) | VERIFIED |
| `flutter test` (كامل) | **1035 نجاح + 2 تخطٍ** — المتخطيان: "Mapper exceptions are not caught by design" و"BUG-001: waiting for product decision" | VERIFIED |
| `flutter build apk --debug` محاولة 1 | **فشل** — Java heap space في JetifyTransform (daemon قديم بـ 2GB) | عيب بيئة (انظر 09) |
| `flutter build apk --debug` محاولة 2 (بعد إنهاء daemons) | **نجاح** — `app-debug.apk` بحجم 165.56 MB | VERIFIED |

## 5. Dead Code الشرعي

- `FailClosedRemoteEventDispatcher` (sync_providers.dart:52) — معرّف، بلا مستدعٍ.
- `lib/backend/http/api_config.dart` — ملف deprecated (كل محتواه تعليقات).
- مجلدا `web/`, `windows/` — انظر ARC-05.
- `print()` يتيم في `status_dashboard_providers.dart:226`.

## 6. ما تعذّر التحقق منه (Functional Limitations)

1. لا إختبار حي (live) ضد الخادم في هذه الجولة — لم أُصدر أي طلب شبكة؛ كل نتائج الخادم منقولة من توثيق حي سابق بتاريخ 2026-10-01.
2. لا جهاز حقيقي: الاتصال BLE، GPS الخلفي، الإشعارات، الاستيقاظ بعد Boot — كلها `NOT TESTED`.
3. iOS لم يُبنَ ولم يُختبر — `NOT TESTED`.

## 7. حكم المرحلة الوظيفية

الواجهة الوظيفية **ناضجة وواسعة**، وفحص المسارات الحرجة يبين أن العوائق المتبقية **معظمها خادمية أو مركونة بقرار**، وليست عيوب كود جديدة. لكن مسارين من صميم امتثال FMCSA (بدء التفتيش، إرسال السجلات) **يفشلان حياً**، والمركبات المخصصة لا تصل — ما يمنع وصف التطبيق بأنه "جاهز وظيفياً للإنتاج" اليوم.
