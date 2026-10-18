# تقرير 08 — تدقيق التكاملات (Integration Audit)

**النطاق:** كل تكامل خارجي (خادم، Firebase، Traccar SDK الأصلي، iOS native، مكتبات الطرف الثالث). لا اتصالات شبكة أُجريت في هذه الجولة — نتائج الخادم منقولة من أدلة موثقة بتاريخ أكتوبر 2026 ووسمت كذلك.

---

## 1. خريطة التكاملات

| # | التكامل | الاتجاه | الحالة العامة |
|---|---|---|---|
| INT-1 | خادم ELD Engine (Spring، `snsoft.cloud`) عبر REST + JSESSIONID | حرج جداً — كل الوظائف | ⚠️ عيوب عقد مؤكدة (حي سابقاً) |
| INT-2 | Traccar Server (نفس الخادم؛ تتبع الموقع port 5055 + إدارة الأجهزة/السائقين) | حرج — التتبع والمركبات | ⚠️ بيانات ربط ناقصة (FUN-03) |
| INT-3 | Firebase Core | متوسط (يستوعب الفشل) | ✅ يعمل ويفشل بأمان |
| INT-4 | Firebase Crashlytics | عالٍ (تشغيلي) | ⚠️ نصف مهيأ (REL-01/02) |
| INT-5 | Firebase Messaging (FCM) | متوسط (أوامر عن بُعد/إشعارات) | ⚠️ رفع token غير متحقق (SEC-21/REL-06) |
| INT-6 | Android Native: TraccarPlugin + BluetoothPlugin + LocationDatabase + NetworkUploader + Foreground Service + BootReceiver | حرج — التتبع/البلوتوث | ✅ يترجم وينجو البناء؛ ❌ غير مختبر على جهاز |
| INT-7 | iOS Native: AppDelegate + BackgroundTaskManager + LocationBackgroundManager | حرج على iOS | ❌ لم يُبنَ/يُختبر إطلاقاً |
| INT-8 | الخطوط المحلية + share_plus + quick_actions + package_info | ثانوي | ✅ |

## 2. تقييم تفصيلي لكل تكامل

### INT-1 — خادم ELD (الأهم)

| المعيار | التقييم | الدليل |
|---|---|---|
| صحة الإعداد | ✅ الرابط من `.env`/إعدادات المستخدم، بدون `/api` مزدوجة (تُعالج في `api_client` و`eld_auth_backend`) | `backend_network_providers.dart:32-39` |
| توافق العقد | ⚠️ المشاكل المؤكدة (حي 2026-10-01): بدء التفتيش 400، إرسال السجلات 400، 405 على `GET /eld/drivers/{id}/rules`، 404 لمسارات 11.1 | ENDPOINT_LIVE_REPORT |
| تسريب الأخطاء | ⚠️ استثناءات Java (Hibernate/NPE) تعود داخل الردود؛ التطبيق يعقّم بقائمة سماح نصية | `request_logger.dart:108-122` (كشف نصوص Hibernate) |
| المصادقة | ✅ JSESSIONID عبر `POST /api/session` (form-urlencoded — JSON يرفض 415 حياً) | `eld_auth_backend.dart:27-38` |
| Timeouts/Retry | ✅ 12/30/30 + retry للـ GET فقط | `api_client.dart` |
| Time drift | ✅ اعتماد ساعة الخادم فقط (`TimeDriftInterceptor` + تعليق صريح برفض ساعة الجهاز في الحراس) | `app_initializer.dart:98-100`، `time_drift_interceptor.dart` |
| المراقبة | ❌ لا Health-check دوري ولا تنبيه تدهور | لا شيء |
| التكلفة التشغيلية | مجهولة من المستودع | — |

### INT-2 — Traccar

- قناة التتبع الأصلي ترفع المواقع إلى port 5055 (OsmAnd) — عقد قديم نمطي لـ Traccar؛ يفشل بأمان على العميل (طابور SQLite أصلي في Kotlin).
- ربط السائق/الجهاز غير مكتمل خادمياً (`my-vehicles` فارغ) — يحطّم مسار "My Vehicles".
- حدود معدل/سعة Traccar غير موثقة.

### INT-3/4/5 — Firebase

| البند | النتيجة |
|---|---|
| تهيئة آمنة للفشل | ✅ `try/catch` مع استمرار التطبيق (VERIFIED بكود) |
| FCM: استقبال أوامر (`positionSingle/Periodic/Stop`) | ✅ منطق موجود؛ أمر `factoryReset` TODO |
| FCM Token upload | ⚠️ POST خام إلى جذر Server URL (انظر SEC-21) — يحتاج تأكيد العقد مع Traccar الحديث |
| Crashlytics | ⚠️ `log()` فقط لنصوص تشخيصية؛ لا `recordError` — أخطاء Dart غير مرئية مركزياً |
| Analytics | ❌ غير موجود (لا `firebase_analytics` في pubspec) |
| Google Services | ✅ متسق: package `com.goldenfeather.golden_feather_eld` مطابق، مشروع `golden-feather-eld` |

### INT-6 — Android Native (Kotlin)

- 9 ملفات Kotlin: `MainActivity`, `TraccarPlugin`, `BluetoothPlugin`, `BatteryPlugin`, `LocationDatabaseHelper`, `NetworkUploader`, `TrackingForegroundService`, `TrackingServiceManager`, `BootReceiver`.
- تحذيرات المُصرّف: APIs Bluetooth مهجورة (موثقة في مخرجات البناء) — دين تقني منخفض.
- **لا تست/CI يغطي Kotlin** (لا وحدة اختبار Android ظاهرة) → التكامل الأصلي `POTENTIAL/NOT TESTED` عملياً.
- للتحقق الميداني إلزامياً: اقتران BLE، كتابة المعاملات على GATT، الاستمرارية بعد إعادة التشغيل (BootReceiver)، رفع الشبكة بعد انقطاع.

### INT-7 — iOS Native

- ملفات `LocationBackgroundManager.swift` و`BackgroundTaskManager.swift` + UIBackgroundModes + BGTaskSchedulerPermittedIdentifiers معرفة.
- **لم يُنفَّذ `flutter build ios` ولا تشغيل محاكي** في هذه البيئة (Windows) → `NOT TESTED` تماماً، ولا يمكن اعتبار iOS منصة مدعومة إنتاجياً بلا بوابة بناء حقيقية على macOS.

### INT-8 — مكتبات مساعدة

- `share_plus`, `quick_actions`, `package_info_plus`, `signature`: استخدام منضبط؛ لا مخاطر تكامل ظاهرة.
- الشريحة الإسبانية في l10n مزودة لكن غير معلن دعمها رسمياً (SRS: لغة عربية/إنجليزية) — حذفها أو اعتمادها قرار أصحاب المنتج.

## 3. تكاملات لا يمكن التحقق منها في هذه البيئة (Declaration)

| التكامل | السبب |
|---|---|
| الاتصال الفعلي بجهاز ELD (BLE/GATT) | لا عتاد، ومسار الاتصال مركون بقرار المالك |
| التتبع الخلفي طويل الأمد | يحتاج جهازاً ومدة تشغيل |
| Firebase الحقيقي (Crashlytics/FCM) | يحتاج جهازاً وبيانات Firebase حية |
| خادم ELD الحالي | سياسة عدم إجراء اتصالات في هذه الجولة |
| iOS بالكامل | بنية الأدوات (Windows) |

## 4. اكتشافات التكامل

| ID | الاكتشاف | الشدة |
|---|---|---|
| INT-A1 | مسارات التفتيش والنقل الحساسة (بدء/إرسال) تفشل 400 على الخادم الحي | **حرجة** |
| INT-A2 | Crashlytics نصف مهيأ (لا أخطاء Dart + لا Gradle plugin) | عالية |
| INT-A3 | رفع FCM token غير موثق النهاية/بلا مصادقة/بلا تحقق نتيجة | متوسطة |
| INT-A4 | ربط السائق↔الجهاز في Traccar ناقص (my-vehicles فارغ) | عالية |
| INT-A5 | لا Analytics مطلقاً | متوسطة (منتج/تسويق) |
| INT-A6 | iOS بلا بوابة بناء/اختبار | عالية إذا كان iOS هدف إصدار |
| INT-A7 | لا Health/مراقبة خادم من التطبيق (عدا About التشخيصي اليدوي) | متوسطة |

## 5. الحكم على التكاملات

التطبيق يتعامل مع طرفي التكامل الأهم (خادم ELD وTraccar) بعقود منظمة واختبارات Mock ممتازة، لكن **العقد الحي به عيوب مؤكدة تعطّل مسارات تنظيمية حرجة**، وFirebase نصف مستغل، وiOS ليس جاهزاً — لذلك بوابة "التكاملات الحرجة متحققة" (G6) **FAIL**.
