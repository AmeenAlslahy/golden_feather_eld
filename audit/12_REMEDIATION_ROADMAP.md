# 12 — خارطة الإصلاح (Remediation Roadmap)

**التصنيف:** P0 = يجب قبل الإطلاق · P1 = يجب قبل التوسع · P2 = تحسين مهم · P3 = مستقبلي
**الحقول إلزامية لكل بند:** معرّف، شدة، ملفات، دليل، أثر تجاري، إصلاح موصى به، أولوية، تعقيد تقديري، طريقة تحقق.

---

## أولاً: P0 — حاجز الإطلاق (8 بنود)

### RM-01 — إصلاح خادم: بدء تفتيش DOT (400)
| الحقل | القيمة |
|---|---|
| الشدة | Critical |
| الملفات | خادم فقط: Hibernate mapping لـ `eld_inspections.photos` (jsonb) — لا ملفات تطبيق |
| الدليل | CB-01؛ ENDPOINT_LIVE_REPORT §P1#1 |
| الأثر التجاري | تعطّل قلب وظيفة التفتيش — لا إطلاق ELD بدونه |
| الإصلاح | ربط العمود كـ jsonb (type 1111) أو cast في الاستعلام؛ اختبار تكامل حي |
| الأولوية | P0 |
| التعقيد | منخفض (خادم) |
| التحقق | `POST /eld/dot-inspection/start` بجسم صالح → 200/201 + صف في DB؛ ثم Smoke من التطبيق (READY_CHECK خطوة 9) |

### RM-02 — إصلاح خادم: إرسال السجلات (400 — قيد status SUCCESS)
| الحقل | القيمة |
|---|---|
| الشدة | Critical |
| الملفات | خادم: قيد `eld_data_transfers_status_check` / منطق كتابة الحالة |
| الدليل | CB-02؛ ENDPOINT_LIVE_REPORT §P1#1 |
| الأثر التجاري | تعطّل نقل سجلات الامتثال (بريد/Telematics) |
| الإصلاح | إضافة `SUCCESS` (أو الحالة الصحيحة) إلى القيد + اختبار حي |
| الأولوية | P0 |
| التعقيد | منخفض (خادم) |
| التحقق | `POST .../send-logs` → 200 + سطر transfer بحالة ناجحة؛ Smoke من التطبيق |

### RM-03 — إصلاح خادم/Traccar: ربط السائق↔الجهاز (My Vehicles)
| الحقل | القيمة |
|---|---|
| الشدة | Critical |
| الملفات | خادم/Traccar: ربط driver 106 ↔ device 1006 |
| الدليل | CB-03؛ PROJECT_STATE:208 |
| الأثر التجاري | مسار اختيار وتشغيل المركبات معطّل للأسطول الحقيقي |
| الإصلاح | ربط في Traccar (traccar-device-driver association) أو تعديل استعلام my-vehicles |
| الأولوية | P0 |
| التعقيد | منخفض–متوسط (خادم/بيانات) |
| التحقق | `GET /eld/company-vehicles/my-vehicles` → غير فارغ للسائق التجريبي؛ Smoke اختيار مركبة → Connection |

### RM-04 — توقيع الإصدار ومخرج AAB
| الحقل | القيمة |
|---|---|
| الشدة | Critical |
| الملفات | `android/key.properties` (يُنشأ، خارج git)، keystore إنتاجي، توثيق Play App Signing |
| الدليل | CB-04؛ `build.gradle.kts:50-68` |
| الأثر التجاري | لا توزيع متجر بدونها |
| الإصلاح | إنشاء upload keystore (EAS/يدوي)، تفعيل Play App Signing، توليد AAB موقّع، حفظ النسخ احتياطياً خارج المستودع |
| الأولوية | P0 |
| التعقيد | منخفض–متوسط (إجراءات) |
| التحقق | `flutter build appbundle --release` → AAB موقّع بـ CN صحيح (`apksigner verify --print-certs`)، رفع Internal Testing |

### RM-05 — ربط Crashlytics بأخطاء Dart + Gradle Plugin
| الحقل | القيمة |
|---|---|
| الشدة | High |
| الملفات | `lib/main.dart` (FlutterError.onError، PlatformDispatcher.onError، recordError)، `android/app/build.gradle.kts` + `android/build.gradle.kts` (plugin crashlytics)، رفع mapping عند Obfuscation |
| الدليل | CB-05؛ REL-01/REL-02 |
| الأثر التجاري | استحالة رؤية الأعطال الميدانية = تأخير اكتشاف أي عطل إنتاجي |
| الإصلاح | تسجيل `recordFlutterFatalError` + `recordError` مع stackTraceFilter، إضافة plugin، اختبار بث خطأ متعمد والتأكد من ظهوره في Firebase Console |
| الأولوية | P0 (تشغيلي) |
| التعقيد | منخفض |
| التحقق | قتل اصطناعي (throw في debug فقط ثم release تجريبي) → ظهور التقرير خلال دقائق |

### RM-06 — حزمة المتجر: خصوصية + إقرارات + label + SDK مثبت
| الحقل | القيمة |
|---|---|
| الشدة | High |
| الملفات | `android/app/src/main/AndroidManifest.xml` (`android:label`)، `android/app/build.gradle.kts` (min/target)، صفحات سياسة خصوصية منشورة + رابط داخلي في `settings_page`/`about_page` |
| الدليل | CB-07؛ تقرير 09 §3 |
| الأثر التجاري | منع الرفض + شرط قانوني لجمع الموقع الخلفي |
| الإصلاح | تصحيح label، تثبيت minSdk/targetSdk، نشر Policy (موقع + بيانات ELD + الاحتفاظ)، ملء Data Safety + App Privacy، تجهيز إقرار Background Location (فيديو شرح) |
| الأولوية | P0 |
| التعقيد | متوسط (إجراءات++ محتوى) |
| التحقق | Package Inspection في Play Console لا يرفع أخطاء؛ مراجعة تفتيشية داخلية للوثائق |

### RM-07 — ضبط شجرة Git ونقطة رجوع
| الحقل | القيمة |
|---|---|
| الشدة | High |
| الملفات | مئات مواضع — مراجعة + commit structured (قد تحوي دفعات عدة) |
| الدليل | CB-09؛ `git status` |
| الأثر التجاري | قدرة رجوع وموثوقية CI ومطابقة "ما اختُبر = ما نُشر" |
| الإصلاح | جلسة مراجعة diff + commits ذات رسائل ذات معنى + tag إصدار `v1.0.0-rc1`؛ دمج الفروع في الريموتين |
| الأولوية | P0 |
| التعقيد | متوسط (مراجعة بشرية) |
| التحقق | `git status` نظيف؛ CI أخضر على الفرع المُدمج؛ `git tag` يشير إلى ما بُني عليه AAB |

### RM-08 — قرار نطاق عتاد ELD (إدارة) + محضر قرار
| الحقل | القيمة |
|---|---|
| الشدة | High (نطاق) |
| الملفات | وثيقة قرار + إجابات Q1–Q13 (`docs/QUESTIONS_FOR_PM_AND_BACKEND...`) |
| الدليل | CB-08؛ PROJECT_STATE:246-249 |
| الأثر التجاري | يرسم صحة ادعاء "ELD" التسويقي ومتطلبات الشهادة |
| الإصلاح | جلسة حسم: النطاق المعلن الآن (شبه-ELD/موافقة لاحقة) + خطة تكامل ECM بجدولة |
| الأولوية | P0 (قرار) |
| التعقيد | منخفض (قرار) — مرتفع (تنفيذ لاحق) |
| التحقق | وثيقة قرار موقّعة بتاريخ ومرجع في `PROJECT_STATE.md` |

---

## ثانياً: P1 — قبل التوسع (8 بنود)

### RM-09 — تشفير التخزين المحلي الحساس
- **الشدة:** Medium | **الملفات:** `local_database_service.dart` (HiveAesCipher)، `sqlite_offline_queue.dart` (SQLCipher) | **الدليل:** SEC-28
- **الأثر:** حماية البيانات القانونية على أجهزة مسروقة/مخترقة | **الإصلاح:** مفتاح AES في secure storage، ترحيل الهجرات دون فقدان صفوف
- **P1 | متوسط | التحقق:** فتح صندوق/DB من أداة خارجية على جهاز debug → مشفّر؛ اختبارات الترحيل تمر

### RM-10 — تأكيد Idempotency لأحداث HOS
- **الشدة:** High | **الملفات:** `traccar_remote_event_dispatcher.dart` (تمرير eventId) + وثيقة عقد الخادم | **الدليل:** CB-10
- **الإصلاح:** توثيق/فرض تفرد `eventId` خادمياً + اختبار إعادة إرسال نفس الحدث
- **P1 | منخفض–متوسط | التحقق:** إرسال نفس الحدث مرتين → سطر واحد في الخادم

### RM-11 — إغلاق فجوة الاعتماد/الفورم أوفلاين (6.8)
- **الملفات:** `certify_tab.dart`, `daily_form` مسار الحفظ، اختبار `hos_offline_continuity_test` توسعة | **الدليل:** CB-11
- **P1 | متوسط | التحقق:** سيناريو جهاز بلا شبكة: الاعتماد يوضح "سيُرسل لاحقاً"/يُرفض بوضوح + اختبار جديد

### RM-12 — توحيد Toolchain والإصدارات
- **الملفات:** `pubspec.yaml` (رفع `>=`)، `verify.yml`، وثيقة `docs/BUILD.md` | **الدليل:** ARC-07
- **P1 | منخفض | التحقق:** CI = محلي على نفس الإصدار؛ البناء ينجح على clean clone

### RM-13 — تحسين بناء Android (Jetifier/heap)
- **الملفات:** `android/gradle.properties` (رفع heap/config cache)، تقييم إزالة `android.enableJetifier` | **الدليل:** REL-03
- **P1 | منخفض | التحقق:** 3 عمليات clean build متتالية بلا OOM

### RM-14 — Analytics أساسي + قياس رحلة
- **الملفات:** pubspec (+firebase_analytics)، نقاط حدث للدخول/الاتصال/الاعتماد/التفتيش | **الدليل:** MKT-01
- **P1 | متوسط | التحقق:** Funnel يظهر في Console بعد Smoke مسار كامل

### RM-15 — بوابة Release في CI
- **الملفات:** `.github/workflows/verify.yml` (job إضافي: build appbundle موقّع من Secrets) | الدليل: تقرير 09 §6
- **P1 | متوسط | التحقق:** tag جديد → AAB مرفوع كـ artifact تلقائياً

### RM-16 — تقليص الحجم + Hardening (split-per-abi / obfuscation)
- **الملفات:** سكربتات إصدار/توثيق | الدليل: PERF حزمة، SEC resilience
- **P1 | منخفض | التحقق:** قياس قبل/بعد (حجم AAB) وحفظ symbols في Crashlytics

---

## ثالثاً: P2 — تحسينات مهمة (6 بنود)

| ID | البند | الملفات | الدليل | الشدة | التعقيد | التحقق |
|---|---|---|---|---|---|---|
| RM-17 | إصلاح رفع FCM Token (endpoint موثق + مصادقة + تحقق نتيجة + retry) | `push_notification_service.dart` | SEC-21/REL-06 | Medium | منخفض | وصول أوامر push على جهاز حقيقي |
| RM-18 | محاكاة فشل أعمق (لوحة أعمال): dead-letter UI/تشخيص للسائق | `sync widgets` + صفحة تشخيص | REL-04 | Medium | متوسط | اختبار Widget جديد + Smoke |
| RM-19 | تقليل المسؤوليات المزدوجة للمؤقتات (تنسيق/jitter) | `sync_provider`, `dashboard_reconciler`, `hos_provider` | PERF-02/SCL §7 | Low–Medium | متوسط | قياس استدعاءات موحد + اختبارات زمن وهمي |
| RM-20 | إزالة Dead code + تنظيف تحذيرات Kotlin المهجورة | `sync_providers.dart:52`, `api_config.dart` (stub), `BluetoothPlugin.kt` | تقرير 05 §7 | Low | منخفض | analyze نظيف + بناء بلا تحذيرات جديدة |
| RM-21 | ضبط التجربة: Force-update / Kill-switch بسيط | إعدادات + config endpoint | MKT-04 | Medium | متوسط | سيناريو إصدار قديم يُجبر للتحديث |
| RM-22 | قفل التطبيق البيومتري/الرمز السري | pubspec + auth | SEC-09 | Medium | متوسط | اختبار جهاز: قفل عند العودة للمقدمة |

## رابعاً: P3 — مستقبلي (4 بنود)

| ID | البند | الدليل |
|---|---|---|
| RM-23 | سياسة خصوصية متعددة اللغات + مركز مساعدة | MKT-02/MKT-03 |
| RM-24 | مسارات 11.1 (wellsite/adverse conditions) بعد نشرها خادمياً | ENDPOINT_LIVE_REPORT |
| RM-25 | Certificate Pinning + كشف Root (حسب حساسية النشر) | SEC-17/34 |
| RM-26 | دعم تعدد المستأجرين/SaaS إن تغيّر النموذج التجاري | MKT-05 |

---

## مصفوفة الأولوية/الأثر (P0/P1 فقط)

| البند | يفتح بوابة | مالك | جهد تقديري |
|---|---|---|---|
| RM-01, RM-02 | G1/G6 (امتثال) | خادم | أيام |
| RM-03 | G1/G6 (مركبات) | خادم | أيام |
| RM-04, RM-06, RM-07 | G3/G7 | تطبيق+مالك | أسبوع–أسبوعان |
| RM-05 | G8/تشغيل | تطبيق | يوم |
| RM-08 | نطاق تجاري | إدارة | جلسة |
| RM-09..RM-16 | G5/G6/G7 hardening | تطبيق | 2–4 أسابيع |
