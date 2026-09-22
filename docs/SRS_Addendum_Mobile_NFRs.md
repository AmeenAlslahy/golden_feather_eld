# ملحق وثيقة المتطلبات — المتطلبات غير الوظيفية للتطبيق المحمول
### Top Compliance ELD SRS v2.0 — Addendum: Mobile NFRs
**التاريخ:** 2026-09-21 | **الإصدار:** 1.0 | **الحالة:** مقترح لسد الفجوات | **النطاق:** Frontend (دور السائق) + mobile platform

> هذا الملحق لا يلغي SRS v2.0، بل يسد الفجوات التي حددتها المراجعة في المحاور: Background / Performance / Battery / Store / Observability. كل بند هنا قابل للاختبار (Testable) ومُرقم للمتابعة في مصفوفة التغطية.

---

## 1. الهدف

توضيح **كيف** يحقق التطبيق المحمول (Flutter - Android/iOS) المتطلبات الوظيفية المذكورة صراحةً في SRS (مثل التسجيل الآلي، Offline، HOS) عندما يكون الجهاز في حالات الهاتف الواقعية: قفل الشاشة، التطبيق في الخلفية، انقطاع الشبكة، وضع توفير البطارية.

## 2. المرجع

- Top Compliance ELD SRS v2.0 — الأقسام 6.8 Offline ، 6.x ELD Device/ECM/HOS، Security، Data Integrity
- التحليل السابق: الفجوات في Background / GPS / Performance / Store (مراجعة 2026-09-21)

---

## 3. متطلبات العمل في الخلفية (Background Execution)

| المعرف | النص | الأولوية | الاختبار |
| :--- | :--- | :--- | :--- |
| **NFR-MOB-BG-001** | يجب أن يستمر التطبيق في **تسجيل حالة القيادة ومراقبة ECM** حتى عندما يكون في الخلفية أو الشاشة مقفلة | Must | اختبار قيادة 30 دقيقة مع قفل الشاشة → سجل HOS لا يفقد أي ثانية |
| **NFR-MOB-BG-002** | على **Android**: يعمل عبر `Foreground Service` مع إشعار دائم `ONGOING` لا يمكن إزالته أثناء القيادة | Must | التحقق من Notification + `adb shell dumpsys activity services` |
| **NFR-MOB-BG-003** | على **iOS**: يستخدم `Background Modes: Location + Background Fetch + Processing` مع الحفاظ على تحديث الموقع كل 1-5 ثوانٍ أثناء القيادة | Must | اختبار على iOS 16+ مع قفل الشاشة |
| **NFR-MOB-BG-004** | عند تفعيل توفير البطارية/ Doze، يجب أن يطلب التطبيق استثناء `Ignore Battery Optimizations` ويحافظ على التسجيل | Must | اختبار مع Battery Saver مفعل |
| **NFR-MOB-BG-005** | عند قتل النظام للتطبيق، يجب إعادة التشغيل التلقائي واستئناف التسجيل خلال <15 ثانية واستعادة الحالة من `Local Store` | Must | قتل التطبيق يدوياً أثناء القيادة |

**التطبيق الحالي:** مغطى في `live_tracking_data_source.dart` + `battery_optimization_service.dart` + `tracking_provider.dart` (مؤشر 100% ضمن نطاقنا).

## 4. متطلبات الموقع في الخلفية (Background Location)

| المعرف | النص | الاختبار |
| :--- | :--- | :--- |
| **NFR-MOB-LOC-001** | التسجيل الآلي لا يعتمد على GPS وحده (ECM هو المصدر) لكن GPS يستمر في الخلفية كـ مصدر ثانوي للتحقق | مقارنة GPS vs ECM log |
| **NFR-MOB-LOC-002** | دقة الموقع في الخلفية ≤ 50m، وتحديث ≤ 5 ثوانٍ أثناء الحركة | رحلة قيادة 10km |
| **NFR-MOB-LOC-003** | عند فشل GPS >60 ثانية أثناء القيادة → تسجيل Diagnostic/Malfunction حسب SRS | محاكاة GPS off |

## 5. متطلبات الأداء (Performance SLAs)

| المعرف | المقياس | الهدف | البيئة |
| :--- | :--- | :--- | :--- |
| **NFR-MOB-PERF-001** | Cold start (نقر الأيقونة → أول شاشة تفاعلية) | **< 2.0 ثانية** | جهاز متوسط (Android 11 / iOS 14) |
| **NFR-MOB-PERF-002** | انتقال بين الشاشات / فتح اليومية | **< 300ms** (AppDurations.normal) |  |
| **NFR-MOB-PERF-003** | استجابة API (p95) | **< 500ms** عبر 4G، < 1.5s عبر 3G |  |
| **NFR-MOB-PERF-004** | معدل الإطارات | **≥ 55 FPS** أثناء التمرير والخريطة |  |
| **NFR-MOB-PERF-005** | استهلاك الذاكرة (PSS) | **< 250 MB** في القيادة المستمرة |  |
| **NFR-MOB-PERF-006** | حجم التطبيق | **< 50 MB** (Android AAB) / < 80 MB (iOS) |  |

**المرتبط بهويتنا:** `AppDurations` (fast 200ms / normal 300ms / slow 400ms) يضمن ثبات الأداء.

## 6. البطارية والموارد

| المعرف | النص |
| :--- | :--- |
| **NFR-MOB-BAT-001** | استهلاك البطارية أثناء القيادة المستمرة **< 3% / ساعة** مع GPS + Foreground Service |
| **NFR-MOB-BAT-002** | في وضع `OFF / Sleeper` مع عدم الحركة → تقليل تردد GPS إلى 60 ثانية لتوفير البطارية |

## 7. المتطلبات الخاصة بالمنصات والمتاجر

| المعرف | النص |
| :--- | :--- |
| **NFR-MOB-STORE-001** | **Android:** يتوافق مع Google Play `Location in background` disclosure + `Foreground Service types: location` |
| **NFR-MOB-STORE-002** | **iOS:** يتوافق مع App Store `Privacy - Location Always` + وصف واضح للمستخدم لماذا نحتاج الخلفية |
| **NFR-MOB-STORE-003** | إمكانية الوصول (Accessibility): دعم TalkBack/VoiceOver، تباين ≥ 4.5:1، حجم خط قابل للتكبير |
| **NFR-MOB-STORE-004** | التحديث والترحيل: ترحيل `Local Store` بدون فقدان سجلات عند تحديث التطبيق (اختبار ترقية vN → vN+1) |

## 8. المراقبة والتشخيص (Observability)

| المعرف | النص |
| :--- | :--- |
| **NFR-MOB-OBS-001** | تسجيل كل `AppError` مع `code + l10nKey + context` إلى Crashlytics بدون بيانات حساسة |
| **NFR-MOB-OBS-002** | معدل ANR/Crash **< 0.5%** للجلسات |
| **NFR-MOB-OBS-003** | تتبع `Audit Trail` محلياً حتى في Offline ويُزامن عند الاتصال |

## 9. معايير القبول (Acceptance)

يعتبر هذا الملحق **مُحققاً** عندما:
1.  يجتاز اختبار قيادة 30 دقيقة مع قفل الشاشة + Battery Saver دون فقدان ثانية واحدة
2.  يحقق SLAs أعلاه على جهازين مرجعيين
3.  يُقبل إفصاح الموقع في Play Console و App Store Review
4.  `grep -r "EdgeInsets\.all\([0-9]" lib | grep -v AppSpacing` = 0 (لا قيم يدوية) و `AppSnackBar` يترجم كل `l10nKey`

---

**التوقيع:** فريق الواجهات (السائق فقط) — هذا الملحق يغطي **الفجوات** التي كانت غير منصوصة صراحةً في SRS v2.0 ويُسلم مع مصفوفة التغطية المرفقة.
