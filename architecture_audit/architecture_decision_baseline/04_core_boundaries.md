# 04 — حدود `core` (Core Boundaries)

> 19 مجلداً فرعياً، ~83 ملفاً. لكل مجلد: بنية حقيقية/خاصة بالميزات/اقتران خفي/حالة عامة. "المشترك ≠ يجب أن يكون في core" — يُحكم بالاستخدام لا الموضع.

## 1. بنية حقيقية قابلة لإعادة الاستخدام

| المجلد | الدليل |
|---|---|
| `network` | `ApiClient` + `guardedNetwork` + `NetworkInfo` + `error_mapper` — تُستهلك من backend و7+ مستودعات |
| `error` + `result` | نظاما خطأ + بوابة عرض — رغم الازدواج، الاستخدام عام |
| `storage` | منفذ/محول SecureStorage — تجريد نظيف (مع تكرار اسم مزود) |
| `session` | `SessionEpoch` — 31 سطراً موثقة، تُقرأ من interceptor والمزودات |
| `theme`/`widgets` (غالباً) | نظام تصميم + ودجات (`eld_retry_view` في 11 موقعاً) |
| `utils`/`constants`/`extensions`/`localization` | مساعدات عديمة الحالة |
| `time` (جزئياً) | `TimeAuthority` مجرد + `time_formatter` — مقابل ازدواج السلطات |

## 2. مسؤوليات خاصة بالميزات داخل `core` (مخالفات)

| الملف | المشكلة | التصنيف اللاحق |
|---|---|---|
| `core/providers/driver_rules_provider.dart` | يراقب `account/presentation` ويشتق `DriverRules` — منطق ميزة Account بغلاف core | V-BND-04 (مؤكد) |
| `core/events/eld_events_provider.dart` | يستورد مصدر بيانات tracking الملموس + كيان `connection_status` | V-BND-05 (مؤكد) |
| `core/widgets/connection_status_indicator.dart` | يستورد `routes.dart` (للملاحة) + كيان tracking | V-BND-06 (مؤكد؛ عضو الدورة C1) |
| `core/di/*` | تركيب auth حصراً (مستودع واحد) بادعاء شامل | V-BND-07 (جذر ناقص، لا خرق اتجاه) |
| `core/data/models/user_model.dart` | نموذج نطاق auth داخل `core/data` | ملاحظة (موضع مشكوك، وظيفة سليمة) |

## 3. اقتران خفي

| الزوج | الآلية |
|---|---|
| `core_providers ⇄ backend_network_providers` | `export` متبادل الاتجاه (C2) — تجميلي، يُخفي الاتجاه |
| `local_storage ⇄ tracking_config_storage` | استيراد متبادل حقيقي (C4) — ترتيب التهيئة UNKNOWN |
| `secureStorageProvider` مكرر الاسم | `core_providers` + `storage_providers` — التباس الاستيراد |
| مفاتيح التخزين ×4 أماكن | `app_constants` + `storage_constants` + خدمتان |

## 4. حالة عامة في `core`

| الحالة | الحكم |
|---|---|
| `SessionEpoch._value` (static) | **مشروع**: مالك وحيد (`AuthNotifier`)، موثّق، مُختبر (epoch tests) |
| `FlutterSecureStorage()` في مزود | عديم الحالة عملياً — مقبول |
| كاشات `static` | **لا شيء في `core`** (المتبقي في codriver/data) — يُسجَّل إيجاباً |

## 5. الخلاصة الحدودية

`core` بنية حقيقية بنسبة ~85% (بالملفات)، والتلوث مركّز في 4 ملفات + ازدواجين (زمن/خطأ) + جذر DI ناقص. **لا يُنصح بتفكيكه** — يُنصح بإخراج الملفات الأربعة وإكمال الجذر أو توثيق نطاقه.
