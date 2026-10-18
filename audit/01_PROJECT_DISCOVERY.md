# تقرير 01 — اكتشاف المشروع (Project Discovery)

**التاريخ:** 2026-10-17
**النطاق:** مستودع `golden_feather_eld` كامل — قراءة فقط (Audit Mode)، بدون أي تعديل على الكود المصدري.
**المنهجية:** فحص شجرة الملفات، قراءة ملفات الإعداد والتوثيق، أوامر تحقق آمنة (analyze / test / build debug)، إحصاءات ثابتة. أي نتيجة بلا دليل مباشر وُسمت `NOT TESTED`.

---

## 1. هوية التطبيق

| البند | القيمة | الدليل |
|---|---|---|
| الاسم | Golden Feather ELD — تطبيق سائق ELD (Electronic Logging Device) | `lib/core/constants/app_constants.dart` (`appName`) |
| الوصف | تتبع امتثال FMCSA للقيادة وساعات الخدمة (HOS) | `pubspec.yaml` سطر 2 |
| الإصدار | `1.0.0+1` | `pubspec.yaml` سطر 4 |
| النطاق | تطبيق السائق فقط — بوابة الناقل/الأسطول خارج النطاق | `PROJECT_STATE.md`، `docs/REMAINING_GAPS_2026-09-25.md` |
| اللغات | العربية (قالب أساسي) + الإنجليزية + الإسبانية (مورّدة) | `l10n.yaml`، `lib/l10n/app_*.arb` |
| المنصات | Android + iOS (ويوجد مجلدا `web/` و`windows/` لكن التطبيق يعتمد قنوات أصلية) | الشجرة |

## 2. التقنيات المكتشفة

| الطبقة | التقنية | الدليل |
|---|---|---|
| الإطار | Flutter (stable) — محلياً 3.47.2 / Dart 3.13.2، والـ CI مثبّت على 3.41.9 | `flutter --version`، `.github/workflows/verify.yml` |
| اللغة | Dart (SDK `>=3.8.0 <4.0.0`) + Kotlin (Android native plugins) + Swift (iOS background managers) | `pubspec.yaml`، `android/app/src/main/kotlin/**`، `ios/Runner/*.swift` |
| إدارة الحالة | Riverpod 2.6.1 (`flutter_riverpod`, `riverpod_annotation`) | `pubspec.lock` |
| التنقل | go_router 14.8.1، مع حارس مصادقة في `redirect` | `lib/routes.dart:74` |
| الشبكة | Dio 5.11.1 + interceptors (Auth / TimeDrift / RequestLogger في debug فقط) | `lib/core/network/api_client.dart`، `lib/backend/providers/backend_network_providers.dart:56` |
| التخزين الآمن | flutter_secure_storage 10.3.4 (Keychain / Keystore) للجلسة وبيانات المستخدم | `lib/core/storage/adapters/flutter_secure_storage_adapter.dart`، `lib/features/auth/data/datasources/auth_local_data_source.dart` |
| التخزين المحلي | Hive (صناديق String غير مشفّرة) + SharedPreferences + SQLite (طابور المزامنة) | `lib/core/services/local_database_service.dart`، `lib/features/sync/data/repositories/sqlite_offline_queue.dart` |
| Firebase | firebase_core 2.32.0، crashlytics 3.5.7، messaging 14.9.4 + إضافات Gradle (BoM 34.18.0) | `pubspec.lock`، `android/app/build.gradle.kts:76` |
| الموقع والتتبع | geolocator 12.0.0 + خدمة أصلية (Foreground Service + قناة EventChannel + رفع OsmAnd port 5055) | `lib/features/tracking/**`، `app_environment.dart:18` |
| الصلاحيات | permission_handler 11.4.0 | `pubspec.yaml` |
| أخرى | signature (توقيع DVIR)، share_plus، package_info_plus، quick_actions، freezed + json_serializable، fpdart (Result/Either) | `pubspec.yaml` |

## 3. المعمارية المعلنة

- **5 طبقات، imports للأسفل فقط** (`docs/architecture.md`، `PROJECT_STATE.md` سطر 17–20):
  1. `lib/features/*` — 16 ميزة، كل ميزة بمجلدات `data/ domain/ presentation` عند الحاجة.
  2. `lib/backend/` — طبقة محولات (Adapters) + عقود (Contracts) + HTTP.
  3. `lib/core/` — خدمات مشتركة (network, storage, time, theme, error...).
  4. `lib/domain/` — كيانات مشتركة.
  5. `lib/app/` — التهيئة والمنسّقات (AppInitializer, TrackingOrchestrator).

- **نقطة التبديل الخلفي:** `activeBackendProvider` يختار `EldEngineAdapter` أو `MockAdapter` حسب `runtime_selection.dart` — الـ Mock مستحيل في production/staging.

- **عقد الـ Backend:** 14 واجهة في `lib/backend/contracts/` (auth, account, dailyLogs, dutyStatus, dvir, hardware, inspection, rulesScreen, statusDashboard, unidentifiedEvents, vehicle, driverSession, signature, rawJson).

- **منسّقات (Orchestrators):** `TrackingOrchestrator`, `QuickActionsInitializer`, `PushNotificationService`, `SyncEngine` + `TraccarRemoteEventDispatcher`.

## 4. الميزات الرئيسية (16 ميزة)

| # | الميزة | الوصف المختصر |
|---|---|---|
| 1 | auth | تسجيل دخول بجلسة JSESSIONID، استعادة جلسة، إنهاء جلسة |
| 2 | onboarding | شاشات الترحيب للإقلاع الأول |
| 3 | permissions | الموقع (Always) + البلوتوث + الإشعارات + استثناء البطارية |
| 4 | connection | الاتصال بجهاز ELD عبر MAC/BLE + وضع Continue Disconnected + التسجيل اليدوي §395.34 + لوحة الجاهزية/التشخيص |
| 5 | home | القائمة الجانبية + لوحة الحالة (الواجهة الرئيسية بعد الدخول) |
| 6 | hos | محرك HOS: عدّاد دائري، تغيير الحالة، Recap، القيود التنظيمية |
| 7 | logs | السجلات اليومية: قائمة، تفاصيل، نموذج Form، Graph-Grid، تعديل الأحداث، الاعتماد (Certify) |
| 8 | dvir | تقارير DVIR: إنشاء، عيوب من كتالوج §396.11، توقيع، مراجعة §396.13 |
| 9 | inspection | تفتيش DOT: بدء/إنهاء، عرض السجلات، حزمة المعلومات، إرسال/بريد السجلات، سجل النقل |
| 10 | codriver | السائق المساعد: ربط/فك، تبديل الأدوار، حالة الفريق، عزل HOS |
| 11 | account | الحساب، القواعد (Rules)، حزمة المعلومات، الأدلة الإرشادية |
| 12 | vehicle | اختيار المركبة (View/Select/Operate) + أسطول الشركة للعرض |
| 13 | sync | طابور أحداث الواجب (SQLite) + إعادة محاولة + حجر الملكية + Dead-letter |
| 14 | tracking | تتبع خلفي (Foreground Service) + الأحداث غير المحددة (Unidentified) |
| 15 | settings | الخادم واللغة والثيم |
| 16 | about | حول التطبيق والتشخيصات (متاح بدون مصادقة وفق SRS §17) |

المسارات: 26 مساراً في `lib/routes.dart:14-43`، منها 5 مسارات عامة (`publicRoutes`).

## 5. رحلة المستخدم الكاملة (كما تنعكس في الكود والوثائق)

1. Splash → فحص صلاحيات → Onboarding (أول تشغيل) → إعداد الخادم → تسجيل الدخول.
2. اختيار المركبة → الاتصال بجهاز ELD (BLE/MAC) أو Continue Disconnected.
3. لوحة الحالة: حالة الواجب (Driving/ON/SB/OFF) + العدّادات + التنبيهات + المزامنة التلقائية.
4. تغيير الحالة مع Annotation؛ تبديل المساعد عند الحركة ممنوع.
5. تسجيل تلقائي للقيادة عند عتبة السرعة (المحرك لديه اختبارات HOS).
6. نهاية اليوم: مراجعة السجلات → Form → Certify (إقرار قانوني).
7. DVIR: فحص ما قبل الرحلة/بعدها، عيوب، توقيع.
8. تفتيش DOT: عرض للضابط، نقل السجلات (Email/Telematics)، حزمة المعلومات.
9. Unidentified Events: مراجعة وتصنيف القيادة غير المحددة.
10. Logout لا يوقف التتبع (قيادة غير محددة تُسجَّل خادمياً).

## 6. التبعيات الحرجة (Critical Dependencies)

| التبعية | الأثر عند الفشل | حالة التحقق |
|---|---|---|
| `https://snsoft.cloud` (خادم ELD Engine + Traccar) | تعطّل كل الوظائف الخادمية | **VERIFIED جزئياً** — تقارير حية سابقة `docs/ENDPOINT_LIVE_REPORT_2026-10-01.md`؛ لم يُعد الاختبار في هذه الجولة |
| جهاز ELD عبر BLE + TraccarPlugin الأصلي | لا بيانات ECM حقيقية | **NOT TESTED** — مركون بقرار المالك (PROJECT_STATE سطر 246–249) |
| Firebase (Config + FCM + Crashlytics) | فقدان الدفع والتقارير | **VERIFIED تهيئة**، التقارير معطوبة جزئياً (انظر تقرير 07/08) |
| إصدار الإصلاح: مجموعة مفاتيح التوقيع | لا يمكن نشر نسخة إنتاجية | **VERIFIED غياب** — `android/key.properties` غير موجود |

## 7. الـ CI/CD والمراقبة والتوثيق

- **CI:** GitHub Actions `.github/workflows/verify.yml` — تثبيت Flutter 3.41.9، `dart format`، `flutter analyze`، `flutter test --coverage`، بناء Debug APK، رفع تغطية. **لا يوجد** أي job لبناء/نشر نسخة release، ولا فحص ثغرات تبعيات.
- **Git remotes:** أصلان — GitHub (`AmeenAlslahy/golden_feather_eld`) وGitLab (`salahisoft-group/golden-feather-eld`).
- **المراقبة:** Crashlytics موجود كتبعية لكن ربط أخطاء Dart غير مُنفَّذ (تفصيل في 07). لا APM ولا Sentry.
- **التوثيق:** غزير جداً — `PROJECT_STATE.md` (سجل 38 دفعة)، `docs/` (15 وثيقة)، تقارير تدقيق سابقة في `architecture_audit/` (أربع مجموعات كاملة) + `FORENSIC_AUDIT_REPORT.md`.

## 8. حالة المستودع الحالية (Git)

- **آخر 5 commits:** جميعها موجودة محلياً (آخرها `967981c` "تم اجراء بعض التعديلات في التصميم والمنطق ومعتمدة من مالك المشروع").
- **شجرة العمل غير نظيفة:** أكثر من 100 ملف معدّل غير مُلتزم + عشرات الملفات غير المتعقَّبة (U) — من بينها كود إنتاجي كامل (`lib/features/account/data/repositories/`، `lib/features/settings/presentation/server_url_validation.dart` وغيرها).
- **الأثر:** لا يمكن تتبع الإصدار المُختبَر بأمان، ولا الرجوع (rollback) لنسخة معروفة، وCI على الفروع المنشورة قد لا يعكس حالة العمل المحلية.

## 9. مقاييس الشجرة

| المقياس | القيمة |
|---|---|
| ملفات Dart في `lib` (بلا generated) | 433 |
| إجمالي الأسطر | ~58,589 |
| ملفات الاختبار | 186 |
| عدد الاختبارات المنفّذة | **1035 ناجح + 2 متخطى** (تنفيذ فعلي في هذه الجولة) |
| أكبر الملفات | `inspection_repository_impl.dart` (~26k بايت)، `log_repository_impl.dart` (~24.6k)، `dvir_form_page.dart` (~23.7k) |

## 10. قيود هذه المرحلة (Discovery Limitations)

- لا جهاز Android/iOS حقيقي متصل في بيئة التدقيق → لا فحص زمن تشغيل، لا Bluetooth، لا GPS.
- iOS لم يُبنَ ولم يُختبر إطلاقاً في هذه الجولة.
- الخادم الحي لم يُختبَر مباشرة (الاعتماد على تقارير حية موثقة سابقاً وسيتم وسمها كذلك).
- مشروع Firebase: `golden-feather-eld` مع مفتاح API عميل قياسي (غير حساس بطبيعته) — لم تُستخرج أي قيم حساسة في هذا التقرير.
