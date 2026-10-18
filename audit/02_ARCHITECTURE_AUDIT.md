# تقرير 02 — تدقيق المعمارية (Architecture Audit)

**الحالة العامة:** جيد مع دين تقني محدود — المعمارية الطبقاتية مصونة إلى حد كبير، والانحرافات موثقة ومتعقّبة.

---

## 1. فصل المسؤوليات (Separation of Concerns)

| المعيار | التقييم | الدليل |
|---|---|---|
| Feature-First Architecture | ✅ | 16 ميزة مستقلة تحت `lib/features/`، كل ميزة تحوي `data/domain/presentation` |
| طبقة Backend معزولة | ✅ | 14 عقداً في `lib/backend/contracts/` + محولا `EldEngineAdapter` و`MockAdapter` |
| Domain نقي نسبياً | ✅ جزئي | `lib/domain/` و`lib/features/*/domain` لا تستورد Flutter/UI في الغالب؛ توجد استثناءات موثقة بـ `// ignore_architecture` |
| Composition Root | ✅ | `AppInitializer` + `ProviderContainer` overrides في `lib/app/app_initializer.dart` |
| الاستثناءات (Known Violations) | ⚠️ | ملفات بـ `// ignore_architecture` (Interceptors تستورد `auth/data` و`tracking/data` — موثقة ومقصودة) |

## 2. حدود الوحدات وإدارة التبعيات (Module Boundaries & Dependencies)

- **قاعدة "imports للأسفل فقط"** منصوص عليها في `PROJECT_STATE.md` و`docs/architecture.md`، وتوجد آليات حماية: تعليقات توجيهية، وقوائم `_raw/import_edges.tsv` في تدقيق سابق، وملف `.agents/AGENTS.md` بقواعد صارمة ("لا PageV2، لا repos موازية، لا مالك ثانٍ لـ connectSession").
- **نقطة المخالفة المزمنة:** الحاجز بين `features/*/data` و`backend/` مقصود وموثّق (الـ adapters تستدعي repositories في اختبارات contract).
- **حقن مزدوج للطبقة البينية:** `core/network/core_providers.dart` يعيد تصدير `apiClientProvider` من `backend/providers/` — مقبول لكنه يربط `core` بـ `backend` بشكل دائري مفهومياً.

## 3. إدارة الحالة (State Management — Riverpod)

| النمط | الحالة |
|---|---|
| Providers موحدة الوصول | ✅ — لا توجد قراءات متزامنة خطرة واسعة |
| عزل الجلسات | ✅ قوي — `SessionEpoch` + `credentialGeneration` + `expectedOwner` (أقل من 3 طبقات حماية لمعرّف الجلسة) |
| Session-scoped invalidation | ✅ — `app.dart:66-117` يبطل مزودات HOS/Tracking ويصفّر الكاشات عند تبديل الهوية |
| كاش بمدد | ✅ — `provider_cache.dart` (5 دقائق للحزم والقواعد، 30 ثانية للحالة) |
| مسؤول مزدوج (Risk) | ⚠️ POTENTIAL — تدقيق داخلي سابق (`architecture_audit/architectural_disorder_diagnosis`) رصد "ازدواج مسؤوليات"؛ أُصلح أكثره لكن الـ `dashboard_reconciler` + `hos_provider` + `sync_provider` يعملون بمؤقتات متوازية (1د/1د/5د) — تحتاج مراقبة سلوكية على جهاز لرصد أي نزاعات تحديث |

## 4. تكرار الكود (Duplication)

- لا تكرار جوهري مُثبت في هذه الجولة. إصلاحات سابقة أزالت التكرار (Password/الـ dialogs، قوائم الشاشات المكررة).
- يقايا نظيفة معروفة: ملف `lib/backend/http/api_config.dart` مجرد هيكل معلّق (deprecated) لا يضر — يمكن حذفه.

## 5. معالجة الأخطاء (Error Handling)

- نمط `Result<T> = Either<Failure, T>` عبر `fpdart` موحّد في كل الطبقات.
- `error_mapper.dart` يحوّل DioException → AppError/Failure مع رسائل معقّمة (`anyErrorUserMessage`) — فحصت عينات عديدة ولا يوجد تسريب `$e` خام في الواجهات الحالية (سوى `print` واحد سُجل أدناه).
- **نقطة قوة:** التمييز بين الرفض النهائي (`RejectedFailure` → dead-letter) والفشل الشبكي (retry أبدي حمايةً لبيانات HOS) في `sync_engine.dart:175-229`.

## 6. إدارة الإعدادات (Configuration Management)

| البند | التقييم | الدليل |
|---|---|---|
| فصل البيئات | ✅ — `AppEnvironment {mock, development, staging, production}` + `resolveRuntimeBackend` | `runtime_selection.dart` |
| منع Mock في الإنتاج | ✅ VERIFIED — شرط صريح: mock فقط في mock/dev المحفوظ | `runtime_selection.dart:31-32` |
| رابط الخادم | ⚠️ — fallback مبرمج `https://snsoft.cloud` إن غاب كل شيء | `runtime_selection.dart:23` |
| أسرار البناء | ✅ — لا أسرار في `.env` (رابط خادم فقط) | `.env` سطر 1–2 |

## 7. القابلية للاختبار (Testability)

- **قوة واضحة:** 186 ملف اختبار، مزدوجات Mock كاملة لكل الواجهات الخادمية (`backend/adapters/mock/`)، `TestHelpers`، `FakeTimeAuthority`، `http_mock_adapter`.
- **VERIFIED:** `flutter test` → 1035 نجاح / 2 تخطٍ (منفّذ في هذه الجولة).
- **فجوة:** لا اختبارات تكامل حية (live) تُشغَّل آلياً في CI ضد الخادم؛ اختبار العقود الحي (`live_contract_2026_09_25_test.dart`) موجود لكنه على الأغلب مُعلَّق/موجّه يدوياً.

## 8. دين تقني مؤكد (Technical Debt)

| ID | الوصف | الشدة | الدليل |
|---|---|---|---|
| ARC-01 | TODO(P2) متكررة في عقود الـ backend (`raw_json` بدل النماذج) — دين موثق بتصنيف P2 | منخفض | `lib/backend/contracts/daily_logs_backend.dart:9` وغيرها (14 موضعاً) |
| ARC-02 | `FailClosedRemoteEventDispatcher` معرّف ولا يُستَخدم (dead code) | منخفض | `sync_providers.dart:52` |
| ARC-03 | `very_good_analysis` في dev_dependencies لكن `analysis_options.yaml` يستخدم `flutter_lints` الافتراضي فقط | منخفض | `analysis_options.yaml:18` |
| ARC-04 | `print()` واحد في مسار أخطاء HOS | منخفض | `status_dashboard_providers.dart:226` |
| ARC-05 | مجلدا `web/` و`windows/` موجودان بدون دعم فعلي (قنوات أصلية) — سطح صيانة زائد | منخفض | الشجرة |
| ARC-06 | 100+ ملف إنتاجي غير مُلتزم بالـ git (شجرة عمل ملوّثة) | مرتفع (عملية) | `git status` |
| ARC-07 | عدم تطابق toolchain: محلي 3.47.2 / CI 3.41.9 / قيد pubspec `>=3.32.0` | متوسط | `flutter --version` vs `verify.yml:18` |
| ARC-08 | `shared_preferences_android: any` — تبعية بلا قيد نسخة صريح | منخفض | `pubspec.yaml:64` |

## 9. Bottlenecks المعمارية وقابلية التوسّع الوظيفي

| السؤال | التقييم | السبب |
|---|---|---|
| إضافة ميزة جديدة | سهل نسبياً (3/5) | نمط الميزة موحّد + عقود backend إضافية + Mock مصاحب؛ لكن يتطلب تكرار ربط provider→adapter→mapper |
| استبدال مزوّد خلفي | سيحتاج إنشاء Adapter جديد لكل الـ 14 عقداً (~100+ دالة) لكن الواجهة محمية | العقد مفصولة جيداً؛ الاستبدال عملي لكنه عمل كبير لا تغيير جذري |
| إدخال نظام دفع | Will require طبقة جديدة كاملة + مراجعة store policy؛ لا بنية دفع حالية | لا يوجد أي أساس دفع في الكود |
| دعم لغات إضافية | سهل — إضافة `.arb` في `lib/l10n` (الإسبانية موجودة أصلاً) | `l10n.yaml` + `AppLocalizations` |
| توسيع البنية الخادمية | خارج نطاق التطبيق (خادم خارجي واحد) | — |
| الحفاظ على إصدارات متعددة | متوسط — لا feature flags في الـ runtime، ولا remote config فعّال | لا يوجد `RemoteConfig` بعد إزالة الاستدعاء |

## 10. الحكم المعماري

المعمارية **ناضجة مقارنة بمتوسط تطبيقات Flutter الإنتاجية**: طبقات واضحة، عقود خادمية معزولة، اختبارات واسعة، وعزل جلسات مدروس بعمق. أضعف النقاط معماريّاً: التزامن بين عدة مؤقتات تحديث، الدين الموثق (P2)، وتلوّث شجرة git الذي يهدد قابلية التتبع. **لا يوجد انهيار معماري يستوجب إعادة كتابة.**
