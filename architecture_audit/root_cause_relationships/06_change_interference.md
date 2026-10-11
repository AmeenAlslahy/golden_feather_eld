# 06 — تداخل التغيير (Change Interference)

> تحقيق أثر، لا تخطيط. "التبعية لا تعني الكسر تلقائياً" — الآلية مذكورة لكل حكم.

## 1. `trackingService*` المزدوج (RC-A2)

| البند | المحتوى |
|---|---|
| الملفات المشتركة | `tracking_service.dart` (التعريف) + `tracking_providers.dart` (المكرر + المستهلك) + `app_initializer.dart:91` (التجاوز) + `quick_actions_initializer:29` |
| الآلية | أي تغيير في `trackingServiceProvider` يمس `quick_actions` دون المستودع والعكس |
| التصنيف | **DIRECT_INTERFERENCE** (مثيلان يتقاسمان الاسم المعنى) |

## 2. `SessionEpoch` العام (RC-D1)

| البند | المحتوى |
|---|---|
| الحالة المشتركة | عدّاد ساكن أحادي يقرأه interceptor + كل سياج + `sessionEpochProvider` |
| الآلية | تغيير دلالته (متى يُرفع) يمس كل السياجات دفعة واحدة |
| التصنيف | **SHARED_RUNTIME_STATE** (مقصود وموثّق — التداخل هنا **ميزة** لا عيب) |

## 3. `dashboardDataProvider` (RC-B/E)

| البند | المحتوى |
|---|---|
| الكتّاب | logs ×3، dvir_form، select_vehicle |
| الآلية | تغيير شكل `DashboardData` أو `applyServerForm` يكسر 5 مواقع في 3 ميزات دون إشارة نوعية (الكتابة عبر `notifier` مباشرة) |
| التصنيف | **TRANSITIVE_INTERFERENCE** (عبر مزود home) |

## 4. عقود `backend` (RC-F/B)

| البند | المحتوى |
|---|---|
| العقد المشترك | `RawJson` + `expectedOwnerDriverId?` + DTO المستوردة |
| الآلية | تغيير شكل استجابة (أو مفتاح `data`) يكسر كل محلل يدوي صامتاً (لا مساعدة مترجم)؛ تغيير `RulesScreenModel` يكسر `backend` (4 حواف معكوسة) |
| التصنيف | **SHARED_CONTRACT** (بالمعنى السلبي: عقد غير مُنمَّط مشترك) |

## 5. `routes.dart` المحوري (RC-C)

| البند | المحتوى |
|---|---|
| الآلية | أي تغيير في `AppRoutes`/المفتاح/الحارس يمس 17 صفحة + 5 ملفات توجيه (استيراد مباشر، لا تجريد) |
| التصنيف | **DIRECT_INTERFERENCE** (الأعلى اتساعاً والأقل خطراً سلوكياً — التغيير شكلي عادة) |

## 6. براميل إعادة التصدير (RC-C2/C3)

| البند | المحتوى |
|---|---|
| `core_providers ⇄ backend_network_providers` (export/import)؛ `log_repository_impl ⇄ log_repository_providers` | إزالة سطر `export` آمنة؛ إبقاؤها يخفي الاتجاه الحقيقي |
| التصنيف | **NO_DEMONSTRATED_INTERFERENCE** (تجميلية — لا سلوك وقت تشغيل) |

## 7. `log_repository_providers` البرميلي (RC-A/E)

| البند | المحتوى |
|---|---|
| يراقَبه: 5 مزودات logs + `hos_engine_provider` + `send_logs_page` | تغيير مُنشئ `LogRepositoryImpl` يمس 7 مستهلكين عبر طبقتين وميزتين |
| التصنيف | **TRANSITIVE_INTERFERENCE** |

## 8. حالات UNKNOWN المصرح بها

- أثر تغيير `Failure.message` على الـ17 موقع عرض: UNKNOWN (يحتاج تتبع كل موقع).
- أثر توحيد `TimeAuthority`/`TrustedTimeProvider`: UNKNOWN (لم يُفحص التكامل الزمني هذه الجولة).
- أثر إزالة `BackendRegistry`: UNKNOWN نظرياً، صفري عملياً (لا مستهلك إنتاجي) — يُذكر ولا يُحتسب.
