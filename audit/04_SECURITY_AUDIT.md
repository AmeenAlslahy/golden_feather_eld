# تقرير 04 — التدقيق الأمني (Security Audit)

**المرجع:** OWASP MASVS (الأعمدة: STORAGE, CRYPTO, AUTH, NETWORK, PLATFORM, CODE, RESILIENCE, PRIVACY)
**النطاق:** فحص ساكن للكود والإعدادات — لم يُنفَّذ اختبار اختراق ولا فحص حي. لم يُكشف أي سرّ فعلي في هذا التقرير.

---

## 0. ملخص تنفيذي أمني

لا توجد ثغرة بأولوية CRITICAL.الوضعية الأمنية **جيدة أعلى من المتوسط**: مصادقة بجلسة خادمية، تخزين آمن للجلسة، لا أسرار في المستودع، لا HTTP غير مشفر، عزل جلسات متقدم ومدروس. الثغرات/المخاطر الموجودة متوسطة أو منخفضة ومرتبطة بالتعقيم المحلي والمرونة (resilience) وممارسات النقل الحي.

---

## 1. المصادقة وإدارة الجلسات (AUTH)

| # | البند | التقييم | الدليل |
|---|---|---|---|
| SEC-01 | دخول بجلسة خادمية JSESSIONID (وليس JWT مخزناً في الكود) | ✅ سليم | `eld_auth_backend.dart:29-77` |
| SEC-02 | كلمة المرور لا تُخزَّن محلياً بأي شكل — تُرسَل فقط وقت الدخول | ✅ سليم | `auth_repository_impl.dart:39-72`، لا أثر لتخزينها |
| SEC-03 | تخزين الجلسة في Keychain/Keystore عبر flutter_secure_storage | ✅ سليم | `auth_local_data_source.dart:57-69` |
| SEC-04 | عزل الأدوار/الجلسات ضد الالتباس (401 قديم لا يطرد جلسة جديدة) | ✅ متقدم | `auth_interceptor.dart` — `SessionEpoch` + `credentialGeneration` |
| SEC-05 | ربط عمليات الطابور بمالكها (منع تسريب عملية سائق لعملية سائق آخر) | ✅ متقدم — رفض قبل إرسال أي بايت | `auth_interceptor.dart:80-99`، `OwnerMismatchSignal` |
| SEC-06 | عدم إرسال كوكي الجلسة لخادم مختلف (منع تسريب cross-origin) | ✅ | `auth_interceptor.dart:101-113` (مقارنة host) |
| SEC-07 | مسح الكاشات المحلية عند تبديل هوية السائق (منع تسريب بين السائقين) | ✅ | `app.dart:91-115` |
| SEC-08 | استعادة الجلسة أوفلاين تعتمد على الملف المحلي فقط عند انعدام الشبكة | ⚠️ مقبول — السيناريو: جهاز مسروق مفتوح التطبيق أوفلاين يظل يعرض بيانات صاحب الجهاز | `auth_repository_impl.dart:111-115` |
| SEC-09 | لا قفل تطبيق (App PIN/Biometric) لحماية الجلسة المحلية | ⚠️ متوسط — جهاز بيد الضابط/الشريك يعرض البيانات بلا حاجز ثانٍ | لا مكتبة local_auth في `pubspec.yaml` |

## 2. الأسرار والإدارة الحساسة (Secrets Management)

| # | البند | التقييم | الدليل |
|---|---|---|---|
| SEC-10 | لا كلمات مرور أو مفاتيح API مبرمجة في `lib/` | ✅ VERIFIED (فحص شامل لـ `.env` وكود المصادقة) | `.env` يحتوي رابطاً فقط: `TRACCAR_ENVIRONMENT=production`, `API_BASE_URL=https://snsoft.cloud` |
| SEC-11 | ملف `.env` مُتتبَّع في git ومضمّن كأصل Flutter (ينشر في APK) | ⚠️ منخفض — لا يحوي أسراراً، لكنه يثبّت رابط الإنتاج داخلياً | `pubspec.yaml:108` (assets: - .env)، تعليق صريح في `.gitignore` أنه غير سري |
| SEC-12 | `google-services.json` في المستودع — يحتوي مفتاح API عميل Firebase | ⚠️ منخفض (طبيعي لـ Firebase؛ المفتاح ليس سراً، والتحكم عبر قواعد الخدمة والخادم) | `android/app/google-services.json` (project `golden-feather-eld`) |
| SEC-13 | `key.properties` (توقيع الإصدار) **غير موجود** في المستودع و**غير مرفوع** (سليم) | ✅ | `Test-Path` → False |
| SEC-14 | فحص ما إذا كان `key.properties` يُسجَّل في git: ملف `.example` فقط غير متعقّب | ✅ | `.gitignore` يستثنيه ضمنياً؛ `key.properties.example` untracked |

## 3. النقل والاتصال (NETWORK)

| # | البند | التقييم | الدليل |
|---|---|---|---|
| SEC-15 | لا يوجد أي `http://` صريح في الكود | ✅ VERIFIED (grep) | لا نتائج لـ `http://` في `lib/` |
| SEC-16 | HTTPS مفروض عبر `ApiConfig.normalized()` (يضيف https إن غاب scheme) | ✅ | `api_config.dart:64-75` |
| SEC-17 | لا تثبيت شهادة (Certificate Pinning) | ⚠️ منخفض–متوسط (MASVS-NETWORK L2 اختياري؛ يوصى به للبيانات القانونية) | لا حزمة pinning، لا `SecurityContext` مخصص |
| SEC-18 | لا ATS Exceptions في iOS | ✅ | `ios/Runner/Info.plist` لا يحتوي `NSAppTransportSecurity` |
| SEC-19 | لا `usesCleartextTraffic` في AndroidManifest | ✅ (الافتراضي false على Android 9+) | `AndroidManifest.xml` |
| SEC-20 | رفض send-time عند عدم تطابق الجلسة = "fail closed" | ✅ | `api_client.dart:299-307` |
| SEC-21 | رفع FCM Token يتم POST خام إلى جذر `serverUrl` بلا جلسة/مصادقة، ونتيجته لا تُفحص | ⚠️ متوسط — من المحتمل أن يكون endpoint قديماً؛ لا خطأ يُعرض، وقد لا يسجّل الجهاز فعلاً في الخادم | `push_notification_service.dart:129-146` |

## 4. التحقق من المدخلات وكشف التسريبات (Input/Leaks)

| # | البند | التقييم | الدليل |
|---|---|---|---|
| SEC-22 | تعقيم رسائل الأخطاء قبل العرض (لا `$err` خام في الواجهات — عدا حالة معروفة) | ✅ | `anyErrorUserMessage`, `translateErrorKey`؛ إصلاحات سابقة موثقة |
| SEC-23 | Logger يسجّل الحذر: `RequestLogger` في debug فقط مع redaction لمفاتيح حساسة | ✅ | `request_logger.dart:20-54`، `backend_network_providers.dart:67` |
| SEC-24 | تسريب استثناءات Java من الخادم (Hibernate/NPE) إلى جسم الردود — يعقّمها التطبيق لكن السجل قد يحتوي تفاصيل | ⚠️ متوسط (من جهة الخادم؛ كان يجب تصفيتها بجانب الخادم) | ENDPOINT_LIVE_REPORT سطر 17–21 |
| SEC-25 | `print()` واحد في `status_dashboard_providers.dart:226` — مخرجات تشخيصية غير معقّمة في مسار خطأ | ⚠️ منخفض | ملف واحد |
| SEC-26 | Validators لإدخال المستخدم: بريد، MAC، رابط خادم، رقم مقطورة، مستند شحن | ✅ | `server_url_validation.dart`، `connectivity_status.dart`، `daily_form_rules.dart` |
| SEC-27 | Cookie session لا يُرسل إلا لنفس الـ host — مع مقارنة host نصية (قابلة للخداع نظرياً بـ case/IDN) | ⚠️ منخفض (خطر نظري) | `auth_interceptor.dart:102-106` (مقارنة `==` ساذجة) |

## 5. بيانات محلية وحساسية (STORAGE / PRIVACY)

| # | البند | التقييم | الدليل |
|---|---|---|---|
| SEC-28 | صناديق Hive وطابور SQLite **غير مشفرة** — تحتوي: كاش السجلات اليومية، التدقيق، فترات HOS، أحداث واجب معلقة، حجر، dead letters | ⚠️ متوسط — على جهاز مصادَر/rooted يمكن قراءتها؛ تعويضه `allowBackup=false` وعزل النظام | `local_database_service.dart`، `sqlite_offline_queue.dart` |
| SEC-29 | `android:allowBackup="false"` | ✅ | `AndroidManifest.xml:25` |
| SEC-30 | العنصر التتبعي الوحيد المصدَّر في AndroidManifest: `BootReceiver` (لازم لـ BOOT_COMPLETED، نمطي) + `MainActivity` | ✅ لا سطح هجوم زائد | `AndroidManifest.xml:50-63` |
| SEC-31 | حفظ توكن FCM وdeviceId في SharedPreferences (غير حساسين عملياً) | ✅ منخفض | `local_storage_service.dart` |
| SEC-32 | لا سياسة خصوصية في المستودع ولا داخل التطبيق، مع جمع موقع دقيق + خلفي | ⚠️ مرتفع من ناحية Store compliance (تفصيل في تقرير 09/10) | لا ملف PRIVACY؛ لا رابط في الواجهة |
| SEC-33 | App PIN/Biometric lock: غير موجود (انظر SEC-09) | ⚠️ متوسط | — |
| SEC-34 | كشف Root/Jailbreak: غير موجود (MASVS-RESILIENCE اختياري) | ⚠️ منخفض | — |
| SEC-35 | الالتقاط الخلفي للموقع أثناء القيادة معروف ومقصود (منصوص في العقد مع المالك) | ℹ️ | PROJECT_STATE، SRS §1 |

## 6. التبعيات (Dependency Vulnerabilities)

- لا أداة فحص ثغرات مثبتة في CI (`pub audit` / `osv-scanner` غير مستخدَمين).
- إصدارات كبرى متأخرة عن الراهن (مؤشرات صيانة، وليست ثغرة مثبتة):
  - `firebase_core 2.32` / `crashlytics 3.5` / `messaging 14.9` — الجيل الحالي أصبح 4.x/5.x. **POTENTIAL** risk من مزيج إضافات Gradle 34.18 (BoM) مع Firebase SDK قديم؛ البناء ينجح (VERIFIED).
  - `flutter_riverpod 2.6.1` (الحالي 3.x)، `geolocator 12` (الحالي 14)، `permission_handler 11` (الحالي 12)، `go_router 14` (الحالي 16+).
- لم يُنفَّذ `dart pub outdated`/فحص CVE (يتطلب شبكة) — الصنف: **NOT TESTED**.

## 7. جدول الشدائد الأمنية

| الشدة | العدد | العناصر |
|---|---|---|
| CRITICAL | 0 | — |
| HIGH | 0 مؤكد | (SEC-21, SEC-28 يتراوحان متوسط؛ رُفِعت لو ثبت سوء استخدام) |
| MEDIUM | 5 | SEC-09, SEC-17, SEC-21, SEC-24, SEC-28 |
| LOW | 6 | SEC-11, SEC-12, SEC-25, SEC-27, SEC-31, SEC-34 |

## 8. توصيات أمنية مجمّعة (بلا تنفيذ — Audit Mode)

1. **SEC-28:** تفعيل تشفير Hive (AES عبر `HiveAesCipher` + مفتاح في secure storage) وتشفير SQLite (SQLCipher) — دفاع عمق للبيانات القانونية.
2. **SEC-09:** إضافة قفل محلي (PIN/Biometric) بجانب الجلسة لمطابقة توقعات ELD القانونية.
3. **SEC-21:** توجيه تسجيل FCM Token إلى endpoint خادمي موثق ومصادَق بدل POST خام لجذر الخادم.
4. **SEC-17:** تقييم Certificate Pinning لخادم الإنتاج (integration مع Mass).
5. **الأتمتة:** إدخال فحص ثغرات تبعيات في CI (`dart pub outdated` + أداة OSV).
6. **SEC-24 (خادم):** تصفية استثناءات Java وإرجاع 500 نظيف — التطبيق يعقّم حالياً بتخمين نصي.

## 9. الحكم الأمني

**PASS** بمعيار Gate 2 — "لا ثغرات أمنية حرجة غير محلولة": أُثبت غياب أي CRITICAL/HIGH مؤكد، مع قائمة مخاطر MEDIUM موثقة. لا مانع أمني جوهري أمام استخدام ميداني مضبوط، لكن المعالجات أعلاه شرط مُستحسن قبل التوسع.
