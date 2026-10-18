# تقرير 07 — تدقيق الموثوقية (Reliability Audit)

**المنهجية:** فحص آليات الفشل في الكود + أدلة الاختبارات المنفَّذة (1035 ناجح) + توثيق سلوك حي سابق. لا محاكاة شبكة فعلية في هذه الجولة.

---

## 1. أنماط الفشل المدروسة (Failure Modes)

| السيناريو | الآلية في التطبيق | التقييم | الدليل |
|---|---|---|---|
| انقطاع شبكة أثناء إرسال حدث واجب | الطابور SQLite الدائم + RetryPolicy لا نهائي (حماية FMCSA) + backoff | ✅ قوي | `sync_engine.dart:216-229` |
| عودة الشبكة | فحص عند الاقتران + تغيّر الشبكة + عند الإقلاع | ✅ | `app_initializer.dart:118-129`، `sync_provider.dart` |
| رفض خادمي نهائي (409/4xx) | Dead-letter فوري (لا عاصفة retry) + cap 200 صف | ✅ مدروس | `sync_engine.dart:187-193`، `sqlite_offline_queue.dart:17` |
| تبديل جلسة أثناء طيران عملية مزامنة | رفض قبل إرسال أي بايت (OwnerMismatch) + حجر deferred | ✅ متقدم | `auth_interceptor.dart:80-99` |
| 401 من جلسة قديمة أثناء جلسة جديدة | تجاهل بجيل الاعتماد (credentialGeneration) | ✅ | `auth_interceptor.dart:122-140` |
| انقطاع أثناء جمع البيانات أوفلاين | كاش Hive للسجلات + قوائم المركبات + لوحات | ✅ جزئي — الاعتماد/الفورم أوفلاين غير مؤكد | `log_repository_offline_test.dart` |
| فقدان عملية دفعة كاملة | رفض نهائي يزال من الطابور ليُعرض للسائق (لا فشل صامت) | ✅ | `sync_engine.dart:56-84` |
| Crash أثناء تشغيل | قاعدة البيانات (SQLite) + Hive تنجو — لا آلية إعادة تشغيل تلقائي للخدمة الخلفية بعد موت العملية (Linux OOM killer / إخلاء) بلا إعادة BOOT؟ | ⚠️ غير مؤكد | `BootReceiver` يغطي الإقلاع؛ لا `START_STICKY` متحقق |
| هجرة مخطط Hive/SQLite | ترقيات إضافية فقط (لا ALTER/backfill) — آمنة وقابلة للاستئناف | ✅ | `sqlite_offline_queue.dart:104-120` |
| ترقية التطبيق مع بيانات قديمة | مهاجرة hos_audit + عدم مسح صندوقي قديم | ✅ موثق | `local_database_service.dart:18-20` |

## 2. اكتشافات الموثوقية

| ID | العنوان | الشدة | الدليل | التصنيف |
|---|---|---|---|---|
| REL-01 | **تقارير الأعطال (Crashlytics) لا تستقبل أخطاء Dart**: لا استدعاء `recordError/recordFlutterFatalError`، ولا ربط `PlatformDispatcher.onError`؛ `FlutterError.onError` يذهب للسجل المحلي فقط | **عالية** | `main.dart:31-34`، grep: لا يوجد `recordError` في `lib/`؛ `FirebaseCrashlytics.instance.log` فقط (نصوص) | VERIFIED (كود) |
| REL-02 | **إضافة Crashlytics Gradle Plugin غائبة** (`com.google.firebase.crashlytics`) — لا رفع Mapping/NDK symbols، وتقارير Java/Kotlin أقل دقة | متوسطة | `android/app/build.gradle.kts:4-11` (فقط google-services) | VERIFIED |
| REL-03 | **هشاشة بناء Android محلياً**: فشل أول `assembleDebug` بـ Java heap space (JetifyTransform) مع heap 2GB في `gradle.properties` + `enableJetifier=true` (قديم)؛ نجح بعد تصفير daemons | متوسطة (بيئة/إعادة إنتاجية) | مخرجات البناء (محاولتان) | VERIFIED |
| REL-04 | **الدقة القانونية أوفلاين (6.8)**: أحداث الواجب مضمونة عبر الطابور؛ لكن سلوك التصديق/الفورم بلا شبكة غير مؤكد ولا مغطّى كاملاً باختبارات | متوسطة | `SRS_DRIVER_AUDIT` سطر 108 (`جزئي`) | POTENTIAL |
| REL-05 | **Factory Reset لا ينفّذ شيئاً** رغم تسجيل "password cleared" | منخفضة | `push_notification_service.dart:91-93` | VERIFIED |
| REL-06 | **رفع توكن FCM بلا تحقق من النتيجة** (لا status check ولا retry) — احتمال فشل صامت لوصول أوامر التنبيه | منخفضة | `push_notification_service.dart:135-145` | VERIFIED |
| REL-07 | **إشعارات داخل التطبيق تُعرض بلا حماية من تكرار Push** (لا إزالة تكرار على معرف message) | منخفضة | `push_notification_service.dart:100-127` | POTENTIAL |
| REL-08 | **سلوك الاستيقاظ بعد قتل النظام (OEM killers)**: لا Battery-optimization exemption مضمون إلا بمسار المستخدم؛ شركات الصينية قد تجهض التتبع الخلفي | متوسطة (مجال حي) | `permissions` + `REQUEST_IGNORE_BATTERY_OPTIMIZATIONS`؛ لا اختبار ميداني | NOT TESTED |

## 3. نقاط قوة موثوقية مؤكدة (Evidence-backed strengths)

1. **Fail-closed philosophy**: عند الشك تُحفظ البيانات ولا تُحذف — أي فشل غير معروف يعيد جدولة الحدث (`sync_engine.dart` + اختبار `sync_data_loss_prevention_test.dart`).
2. **Quarantine للملكية**: أحداث جلسة غير مستقرة تُحجَر deferred/quarantined ولا تُرسَل تحت جلسة خاطئة — مع اختبارات عزل (`dispatch_ownership_test`, `session_isolation_test`).
3. **إزالة تكرار الجلسة**: Deadlock secure storage Android موثق ومعالج (`app_initializer.dart:108`).
4. **إصلاحات crash تاريخية موثقة**: TextEditingController dispose (باتجاهين)، VIN substring RangeError — كلها باختبارات.
5. **Readiness checks**: `startup_checks` + اختباراته (`startup_checks_test.dart`).

## 4. قابلية الفشل لإنتاج عواقب محددة (Risk-to-Impact Matrix)

| العاقبة | السيناريو الأمثلة | احتمالها الحالي |
|---|---|---|
| فقدان بيانات (Data loss) | ضعيف جداً — الطابور fail-closed؛ الاستثناء الوحيد النظري: تلف ملف/مسح cloud backup (allowBackup=false يعني لا نسخ) | منخفض |
| معاملات مكررة | إعادة إرسال ممكنة نظرياً إذا سجل الخادم النجاح وانقطع الرد — لا مفتاح idempotency موثق على خادم الأحداث | **متوسط — POTENTIAL** |
| قفل حساب | لا آلية قفل محلي؛ الخادم قد يقفل بعد محاولات فاشلة (غير موثق) | غير معروف |
| أعطال تطبيق (Crashes) | غير قابل للرؤية مركزياً بسبب REL-01 | **مرتفع أثراً — خطير** |
| تعرّض أمني | انظر تقرير 04 — لا حرج | منخفض |
| كسر مسارات سائق | مسارات التفتيش/الإرسال مكسورة خادمياً (تقرير 03) | مؤكد |

## 5. احتمال تكرار العمليات (Idempotency)

- `ApiClient` لا يعيد المحاولة للـ POST/PUT إطلاقاً (قرار سليم) — لكن عند "نجاح خادمي + انقطاع الرد" ستُعاد المحاولة لاحقاً من الطابور. **هل خادم ELD يدعم مفاتيح idempotency على أحداث الواجب؟** لا ذكر لذلك في `openapi.yaml` المحلي → **POTENTIAL عالي الأثر: ازدواج أحداث HOS.**
- توصية تحقق: مطابقة حقل `eventId` المُولّد عميلاً (`uuid`) مع سلوك الخادم عند تكرار نفس المعرّف. الاختبارات المحلية تفترض معرّفات UUID؛ سلوك الخادم غير موثق.

## 6. الفجوات الحياتية (NOT TESTED)

- لا اختبار شبكة حقيقية (تبديل Wi-Fi/4G/لا شبكة) في هذه الجولة.
- لا اختبار قتل العملية تحت ضغط ذاكرة.
- لا اختبار إعادة تشغيل الجهاز مع أحداث معلقة.
- لا اختبار ترقية نسخة فوق نسخة ببيانات (Migration E2E).

## 7. الحكم الموثوقي

منظومة المزامنة والاستمرارية **من أقوى ما فُحص في هذا المستودع** (fail-closed, ownership, dead-letter, migrations additive). الاعتماد الأكبر: **غياب مراقبة الأعطال المركزية (REL-01/REL-02)** — وهو ما يحوّل أي عطل ميداني إلى أعمى تشغيلي، إضافة إلى احتمال ازدواج الأحداث عند إعادة المحاولة (يحتاج تأكيداً من عقد الخادم).
