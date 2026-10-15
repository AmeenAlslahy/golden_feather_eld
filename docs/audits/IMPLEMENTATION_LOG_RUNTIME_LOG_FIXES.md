# سجل التنفيذ — إصلاح أعطال Runtime المُبلَّغة (Task 04)

**التاريخ:** 2026-10-14
**المدخل:** سجل جهاز حقيقي حوى استثناء متكرر وطلب `409` متكرر.
**الحالة:** مُنفَّذ ومُختبَر — `848 passed`, `2 skipped`, `0 failed`،
`flutter analyze lib/` نظيف.

---

## العطل 1 — تعطّل سجل مخالفات HOS

### العرض

```
type 'String' is not a subtype of type 'int' of 'index'
  #0 HosAuditRepositoryImpl.getViolations.<anonymous closure>  (:37:77)
⚠️ HosAuditRepositoryImpl: skipping unreadable audit row "2026-10-07"
```

يتكرر كل ~60 ثانية (نبضة `HosNotifier._startRefreshTimer`).

### السبب الجذري — تصادم صندوق Hive

كلا المستودعين كانا يستخدمان `StorageConstants.auditBox`_one_، بتنسيقين
مختلفين:

| | المفتاح | القيمة |
|---|---|---|
| `LogLocalDataSource` | `2026-10-07` | **قائمة** JSON `[ {...} ]` |
| `HosAuditRepositoryImpl` | `2026-10-07_dailyDrivingExceeded` | **كائن** JSON `{...}` |

السطر `hos_audit_repository_impl.dart:37` كان:

```dart
final map = jsonDecode(jsonStr);          // List فعلياً، لا Map
HosViolationType.values.firstWhere((e) => e.name == map['type']);
```

`ListBase.operator[]` يقبل `int` فقط ⇒ خطأ `String is not a subtype of
int of 'index'`.

### الأثر

| # | الأثر | الشدة |
|---|---|---|
| 1 | سجل المخالفات القانوني لا يعمل إطلاقاً | حرج |
| 2 | `logViolation` يعتمد على `getViolations()` لمنع التكرار ⇒ التكرار معطّل | عالٍ |
| 3 | عشرات الـ stack traces كل دقيقة | متوسط |

الاستثناء كان **مُمسكاً** في `catch`، فلم ينهار التطبيق — لكن السجل كان فارغاً دائماً.

### الإصلاح

1. **فصل الصندوق** — `StorageConstants.hosAuditBox = 'hos_audit_box'`.
   `local_database_service.dart` يفتحه ثم يشغّل الترحيل.
   `hos_audit_providers.dart` يقرأ من الصندوق الجديد.

2. **ترحيل آمن** — `lib/core/services/hos_audit_migration.dart`:
   - التمييز بمعيارين مستقلين: مفتاح `${dateStr}_${type}` **و** كائن يحمل
     `type`/`level`/`timestamp`. صفوف السجلات قوائم ⇒ لا يمكن أن تُطابق.
   - الحذف من الصندوق القديم **بعد** نجاح الكتابة في الجديد ⇒ الأسوأ تكرار
     الصف لا فقده.
   - `dryRun` للفحص، وتشغيل متكرر بلا أثر (idempotent).
   - فشل الترحيل **لا يمنع الإقلاع**.

3. **دفاع عميق** — `getViolations()` صار يتحقق من النوع:
   `decoded is! Map<String, dynamic>` ⇒ تخطّي الصف، والتحقق من التعدادات
   والتاريخ قبل البناء. لا صف غريب يُسقط بقية السجل.

---

## العطل 2 — إعادة محاولة لا تنتهي لطلب مرفوض نهائياً

### العرض

```
PUT /eld/daily-logs/20/form
409 BUSINESS_RULE_VIOLATION
السجل اليومي معتمد مسبقاً، لا يمكن تعديل بيانات النموذج قبل إلغاء الاعتماد
```

### السبب الجذري —-chain من عيبين

1. **`_mapResult` كان يطوي كل خطأ** في `ServerFailure` قابل لإعادة
   المحاولة، بما فيها `ConflictError` (وهو أصلاً مُعرَّف في
   `app_error.dart` بتعليق "E.g. duplicate trailer number, **already
   certified**").

2. **`RetryPolicy.calculateNextRetry` لا يُرجع `null` أبداً:**
   ```dart
   final effectiveRetries = currentRetries >= maxRetries ? maxRetries : (currentRetries + 1);
   return nowUtc.add(...);   // دائماً non-null
   ```
   ففرع `moveToDeadLetter` في `_settle` **ميت**.

   النتيجة: حدث مرفوض نهائياً يُعاد كل ~50 ثانية **إلى الأبد**، بلا أي
   احتمال للنجاح، مع إغراق السجلات واستنزاف الشبكة.

**لماذا `RetryPolicy` ليست هي الخطأ:** قاعدة FMCSA «لا تُفقد بيانات HOS»
صحيحة لحدث ضائع بسبب الشبكة. وهي كارثية لحدث مرفوض بنيوياً.

### الإصلاح

1. **`RejectedFailure`** في `core/error/failure.dart` — رفض نهائي، بلا retry.

2. **`isTerminalDispatchRejection(AppError)`** — دالة نقية قابلة للاختبار في
   `traccar_remote_event_dispatcher.dart`:

   | الخطأ | HTTP | نهائي؟ |
   |---|---|---|
   | `ConflictError` | 409 | ✅ |
   | `ValidationError` | 400 / 422 | ✅ |
   | `NotFoundError` | 404 | ✅ |
   | `PermissionError` | 403 | ✅ |
   | `NetworkError` | — | ❌ عابر |
   | `ServerError` | 5xx | ❌ عابر |
   | `SessionExpiredError` | 401 | ❌ عابر |
   | `SyncError` | طابور | ❌ عابر |

3. **`_settle`** ينقل `RejectedFailure` إلى `dead-letter` فوراً، **قبل**
   استشارة `RetryPolicy`. ما عداه يحتفظ بحماية FMCSA كاملة.

### أثر الـ dead-letter (ملاحظة مهمة)

الحدث المُنقول إلى `dead-letter` **لم يُحذف** — يبقى قابلاً للمراجعة.
لكنه لم يعد يُرسل تلقائياً ولا يُغلق الطابور.

⚠️ **يبقى خطر يفوق العطلين الأصليين:** إن كان الطابور ممتلئاً، فالحدث
المحجوز يبقى يحتل خانة. يحتاج مراجعة يدوية أو تنظيفاً دورياً
لـ dead-letter. **هذه ثغرة قائمة لم تُعالج هنا.**

---

## الاختبارات

`test/audit_task04/runtime_log_fixes_test.dart` — 13 اختباراً:

**العطل 1 (9)**
- قراءة المخالفات من صندوق نظيف.
- **الانحدار المُبلَّغ**: صفوف السجلات (قوائم، مفاتيح تواريخ) لا تُسقط
  القراءة — نفس بيانات سجل الجهاز.
- صفوف غريبة (قائمة، نص، `null`، تالف، تعداد مجهول، تاريخ سيئ) ⇒ الصف
  الصحيح الوحيد يُقرأ.
- منع التكرار (نفس النوع/اليوم)، وفصل الأيام المختلفة.

**الترحيل (4)**
- نقل المخالفات فقط، وترك صفوف السجلات في صندوقها.
- idempotency، `dryRun`، وتمييز الصفوف.

**العطل 2 (3)**
- جدول التصنيف النهائي/العابر لكل نوع خطأ.
- المرفوض نهائياً ⇒ dead-letter، **إرسال واحد فقط** عبر 3 دورات مزامنة.
- العابر ⇒ يبقى في الطابور ويُعاد بعد `backoff` (FMCSA محفوظة).

> ملاحظة: أول محاولة لاختبار «العابر» **علّقت الاختبار** لأن الـ fake queue
> كان يعيد الحدث فوراً — أي أنها **أعادت إنتاج حلقة لا نهائية بنجاح**.

---

## ملفات مُعدَّلة

| الملف | التغيير |
|---|---|
| `lib/core/constants/storage_constants.dart` | إضافة `hosAuditBox` |
| `lib/core/services/hos_audit_migration.dart` | **جديد** — الترحيل |
| `lib/core/services/local_database_service.dart` | فتح الصندوق الجديد + الترحيل |
| `lib/core/error/failure.dart` | إضافة `RejectedFailure` |
| `lib/features/hos/data/providers/hos_audit_providers.dart` | توجيه الصندوق |
| `lib/features/hos/data/repositories/hos_audit_repository_impl.dart` | حاجز النوع + تحقّق |
| `lib/features/sync/data/repositories/traccar_remote_event_dispatcher.dart` | تصنيف الرفض |
| `lib/features/sync/domain/usecases/sync_engine.dart` | dead-letter فوري |
| `test/audit_task04/runtime_log_fixes_test.dart` | **جديد** — 13 اختباراً |

---

## ما لم يُعالج

1. **تنظيف `dead-letter` دوري** — مذكور أعلاه.
2. **رسالة للسائق** — الـ 409 يصل للمستخدم الآن كـ `ServerFailure` عادي من
   مسار `form_tab_provider`. يُستحسن عرض «السجل معتمد، ألغِ الاعتماد أولاً»
   وتعطيل زر الحفظ. (يتطلب `lib/l10n/*` المتعدَّل من طرف ثالث.)
3. **فرع `RetryPolicy` الميت** — فرع `moveToDeadLetter` الميت ما زال
   موجوداً ويخدم الأخطاء العابرة كشبكة أمان مستقبلية.
4. **ECM/OBD** — لم يُفعَّل (لا يوجد جسر BLE → `EldEvent`).