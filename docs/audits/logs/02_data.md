# جرد طبقة `data` — ميزة `logs`

## نطاق الملف

- **7 ملفات**، **1742 سطرًا**، **2 Providers**.
- كل ملف قُرئ كاملًا.
- كل استشهاد بالسطر تم التحقق منه بفتح الملف حول السطر.
- الملفات المولّدة غير موجودة في هذه الطبقة.
- لا توجد تعديلات على ملفات المصدر.
- تصحيح: عددا أسطر ملفَي الاختبار `daily_log_dto_test.dart` و`log_repository_offline_test.dart` في `00_index.md` كانا منسوخين من ملفات المصدر بالخطأ، وصُحّحا إلى **186** و**310**.

## ملخص الطبقة

| الملف | الأسطر | الكلاسات | الـEnums | الدوال والـMethods | الحقول | الثوابت | Providers |
|---|---:|---:|---:|---:|---:|---:|---:|
| `data/codecs/signature_draft_codec.dart` | 51 | 1 | 0 | 3 | 0 | 0 | 0 |
| `data/datasources/log_local_data_source.dart` | 469 | 2 | 0 | 54 | 0 | 0 | 1 |
| `data/models/daily_log_dto.dart` | 215 | 1 | 0 | 3 | 20 | 0 | 0 |
| `data/models/log_model.dart` | 158 | 1 | 0 | 5 | 0 | 1 | 0 |
| `data/models/saved_form_dto.dart` | 42 | 1 | 0 | 1 | 0 | 0 | 0 |
| `data/providers/log_repository_providers.dart` | 24 | 0 | 0 | 0 | 0 | 0 | 1 |
| `data/repositories/log_repository_impl.dart` | 783 | 1 | 0 | 26 | 7 | 0 | 0 |
| **الإجمالي** | **1742** | **7** | **0** | **92** | **27** | **1** | **2** |

ملاحظة العدّ: الحقول 27 = 20 حقلًا في `DailyLogDto` + 7 حقول في `LogRepositoryImpl`. الـgetters الأربعة في `LogLocalDataSourceImpl` محسوبة داخل الدوال الـ54 لا داخل الحقول. الثابت الوحيد هو `LogEventModel._kmToMiles`.

---

## 1. `lib/features/logs/data/codecs/signature_draft_codec.dart`

- **الطبقة:** data
- **المسؤولية في جملة واحدة:** تسلسل نقاط التوقيع المرسوم إلى نص JSON وفك تسلسلها عند استعادة المسودة.
- **عدد الأسطر:** 51
- **الاعتمادات:**
  - داخل الميزة: لا يوجد.
  - من `core/`: لا يوجد.
  - حزم خارجية: `dart:convert`، `dart:ui`، `package:signature/signature.dart`.
- **من يستورد هذا الملف؟**
  - داخل `lib/features/logs`: `presentation/providers/log_draft_signature_provider.dart:7`.
  - خارج الميزة: لا يوجد.
  - الاختبارات: `test/features/logs/data/codecs/signature_draft_codec_test.dart:2`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `SignatureDraftCodec` | class بأداة بناء خاصة | ترميز وفك ترميز نقاط `Point` | 7 |

### الحقول

لا يوجد أي حقل في هذا الملف.

### الدوال والـMethods

| الاسم | التوقيع الكامل | الكلاس المالك | الغرض | المدخلات | المخرجات | الآثار الجانبية | Providers | من يستدعيها |
|---|---|---|---|---|---|---|---|---|
| `SignatureDraftCodec._` | `const SignatureDraftCodec._()` | `SignatureDraftCodec` | منع إنشاء كائنات من الأداة | لا يوجد | كائن | لا يوجد | لا يوجد | لا يوجد استدعاء صريح |
| `encodePoints` | `static String encodePoints(List<Point> points)` | `SignatureDraftCodec` | تحويل النقاط إلى JSON | قائمة `Point` | `String` | لا يوجد | لا يوجد | `log_draft_signature_provider.dart:43`، `signature_draft_codec_test.dart:13`، `signature_draft_codec_test.dart:32` |
| `decodePoints` | `static List<Point> decodePoints(String? jsonString)` | `SignatureDraftCodec` | استعادة النقاط من JSON | نص أو null | `List<Point>` | لا يوجد | لا يوجد | `log_draft_signature_provider.dart:24`، `signature_draft_codec_test.dart:18`، `signature_draft_codec_test.dart:33`، `signature_draft_codec_test.dart:34`، `signature_draft_codec_test.dart:35`، `signature_draft_codec_test.dart:36` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- ابتلاع كامل للأخطاء: `catch (_) { return const []; }` في الأسطر 47-49 يعيد قائمة فارغة لأي JSON تالف أو استثناء داخلي دون أي إشارة للداعي.
- العناصر غير الخريطية تُتجاهل بصمت: `if (item is Map)` في السطر 34 بلا عدّاد أو تحذير.
- النوع غير المعروف يتحول إلى `PointType.move` في الأسطر 38-41، أي أن ضغطة قلم تالفة تصبح فاصل سطر.
- القيم الناقصة تُخترع كأصفار: `x` و`y` افتراضيان `0.0` في السطرين 35-36، والضغط افتراضي `1.0` في السطر 42.
- اعتماد على أنواع واجهة Flutter داخل data: `dart:ui` في السطر 2 و`Point`/`Offset`/`PointType` في الأسطر 11-44.
- التغطية الاختبارية: `signature_draft_codec_test.dart:7-29` تختبر جولة كاملة بنقطتين مع النوع والضغط، و`:31-37` تختبر القائمة الفارغة و`null` والنص الفارغ و`invalid-json` والخريطة `{}`.
- غير مغطى بالاختبار: عنصر غير خريطي داخل المصفوفة، اسم نوع غير معروف، إحداثيات نصية بدل رقمية، وقيم ناقصة.

---

## 2. `lib/features/logs/data/datasources/log_local_data_source.dart`

- **الطبقة:** data
- **المسؤولية في جملة واحدة:** عقد التخزين المحلي لكل ما تحفظه ميزة السجلات (أحداث، فترات خدمة، تدقيق، لقطات شبكية، نماذج، تواقيع)، وتنفيذه فوق صناديق Hive.
- **عدد الأسطر:** 469
- **الاعتمادات:**
  - داخل الميزة: `domain/entities/daily_log.dart` (السطر 9)، `domain/entities/audit_entry.dart` (السطر 10).
  - من `core/` وشجرة `lib` العامة: `core/utils/logger.dart` (السطر 4)، `core/error/exception.dart` (السطر 5)، `core/utils/app_date_utils.dart` (السطر 6)، `core/constants/storage_constants.dart` (السطر 7)، `domain/shared/value_objects.dart` (السطر 8)، `core/domain/entities/hos_models.dart` (السطر 11).
  - حزم خارجية: `dart:convert`، `package:flutter_riverpod/flutter_riverpod.dart`، `package:hive_flutter/hive_flutter.dart`.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/providers/log_repository_providers.dart:9`، `data/repositories/log_repository_impl.dart:18`.
  - خارج الميزة: `lib/app.dart:20`، `lib/features/sync/data/providers/sync_providers.dart:9` (موسوم `// ignore_architecture`).
  - الاختبارات: `test/audit_task06/driver_isolation_test.dart:6`، `test/features/logs/data/log_repository_offline_test.dart:8`، `test/features/logs/data/repositories/log_repository_impl_form_test.dart:11`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `LogLocalDataSource` | abstract class | عقد التخزين المحلي بـ22 دالة | 13 |
| `LogLocalDataSourceImpl` | class ينفّذ العقد فوق Hive | التنفيذ الفعلي | 66 |

### عقد `LogLocalDataSource` (22 دالة)

| الاسم | التوقيع الكامل | الغرض | من يستدعيها فعليًا |
|---|---|---|---|
| `getEvents` | `Future<List<LogEvent>> getEvents(DateTime date)` | قراءة الأحداث المحلية ليوم | `log_repository_impl.dart:184` |
| `addEvent` | `Future<bool> addEvent(LogEvent event)` | إضافة حدث محلي | `log_repository_impl.dart:207` |
| `updateEvent` | `Future<bool> updateEvent(LogEvent event)` | تعديل حدث محلي | `log_repository_impl.dart:268` |
| `getPeriods` | `Future<List<DutyPeriod>> getPeriods(DateTime date, [DateTime? referenceNow])` | قراءة فترات الخدمة | `log_repository_impl.dart:730` |
| `savePeriod` | `Future<bool> savePeriod(DutyPeriod period)` | حفظ فترة خدمة | `log_repository_impl.dart:738` |
| `logAudit` | `Future<bool> logAudit(AuditEntry entry)` | كتابة إدخال تدقيق | `log_repository_impl.dart:746` |
| `getAuditEntries` | `Future<List<AuditEntry>> getAuditEntries(DateTime date)` | إدخالات تدقيق يوم | `log_repository_impl.dart:754` |
| `getRecentAuditEntries` | `Future<List<AuditEntry>> getRecentAuditEntries({int limit = 100})` | أحدث الإدخالات عبر الأيام | `log_repository_impl.dart:764` |
| `cacheDailyLogs` | `Future<void> cacheDailyLogs(int driverId, List<Map<String, dynamic>> logsJson)` | تخزين لقطة قائمة السجلات | `log_repository_impl.dart:98` |
| `getCachedDailyLogs` | `Future<List<Map<String, dynamic>>?> getCachedDailyLogs(int driverId)` | قراءة لقطة القائمة | `log_repository_impl.dart:75`، `log_repository_impl.dart:134`، `log_repository_impl.dart:538` |
| `cacheLogEvents` | `Future<void> cacheLogEvents(DailyLogId logId, List<Map<String, dynamic>> eventsJson)` | تخزين لقطة أحداث سجل | `log_repository_impl.dart:175` |
| `getCachedLogEvents` | `Future<List<Map<String, dynamic>>?> getCachedLogEvents(DailyLogId logId)` | قراءة لقطة الأحداث | `log_repository_impl.dart:183` |
| `saveSignature` | `Future<void> saveSignature(DailyLogId logId, String base64Signature)` | تخزين توقيع base64 | **لا يوجد أي مستدعٍ في `lib` أو `test`** |
| `getSignature` | `Future<String?> getSignature(DailyLogId logId)` | قراءة توقيع base64 | **لا يوجد أي مستدعٍ في `lib` أو `test`** |
| `saveDraftSignature` | `Future<void> saveDraftSignature(DailyLogId logId, String pointsJson)` | تخزين مسودة النقاط | `log_repository_impl.dart:771` |
| `getDraftSignature` | `Future<String?> getDraftSignature(DailyLogId logId)` | قراءة مسودة النقاط | `log_repository_impl.dart:776` |
| `deleteDraftSignature` | `Future<void> deleteDraftSignature(DailyLogId logId)` | حذف المسودة | `log_repository_impl.dart:781` |
| `cacheDailyForm` | `Future<void> cacheDailyForm(DailyLogId logId, Map<String, dynamic> formJson)` | تخزين نموذج اليوم | `log_repository_impl.dart:390`، `log_repository_impl.dart:473` |
| `getCachedDailyForm` | `Future<Map<String, dynamic>?> getCachedDailyForm(DailyLogId logId)` | قراءة النموذج المخزّن | `log_repository_impl.dart:369` |
| `markCachedDailyLogFormComplete` | `Future<void> markCachedDailyLogFormComplete({required int driverId, required DailyLogId logId, required bool isComplete})` | تحديث اكتمال سجل داخل اللقطة | `log_repository_impl.dart:477`، `log_repository_impl.dart:518` |
| `ownerOfCachedLog` | `Future<int?> ownerOfCachedLog(int logId)` | إيجاد مالك السجل المخزّن | `log_repository_impl.dart:132`، `log_repository_impl.dart:536`، `sync_providers.dart:117` |
| `clearPeriods` | `Future<void> clearPeriods()` | مسح كل فترات الخدمة المخزنة | `app.dart:40` |

### أعضاء `LogLocalDataSourceImpl` (32 عضوًا + Provider)

| الاسم | السطر | النوع | الغرض | من يستدعيها |
|---|---:|---|---|---|
| `_eventsBox` | 67 | getter خاص | صندوق أحداث Hive | `getEvents`، `addEvent`، `updateEvent` |
| `_periodsBox` | 68 | getter خاص | صندوق فترات Hive | `getPeriods`، `savePeriod`، `clearPeriods` |
| `_auditBox` | 69 | getter خاص | صندوق تدقيق Hive | `logAudit`، `getAuditEntries`، `getRecentAuditEntries` |
| `_cacheBox` | 70 | getter خاص | صندوق لقطات Hive | كل دوال `cache` و`getCached` والتواقيع |
| `cacheDailyLogs` | 76 | override | `put('logs:$driverId', jsonEncode(...))` | `log_repository_impl.dart:98` |
| `getCachedDailyLogs` | 88 | override | `_readCachedList('logs:$driverId')` | `log_repository_impl.dart:75`، `:134`، `:538` |
| `cacheLogEvents` | 92 | override | `put('events:${logId.value}', ...)` | `log_repository_impl.dart:175` |
| `getCachedLogEvents` | 104 | override | `_readCachedList('events:...')` | `log_repository_impl.dart:183` |
| `saveSignature` | 109 | override | `put('sig:...')` | لا يوجد |
| `getSignature` | 118 | override | `get('sig:...')` | لا يوجد |
| `saveDraftSignature` | 123 | override | `put('sig_draft:...')` | `log_repository_impl.dart:771` |
| `getDraftSignature` | 132 | override | `get('sig_draft:...')` | `log_repository_impl.dart:776` |
| `deleteDraftSignature` | 137 | override | `delete('sig_draft:...')` | `log_repository_impl.dart:781` |
| `cacheDailyForm` | 146 | override | `put('form:...', jsonEncode(...))` | `log_repository_impl.dart:390`، `:473` |
| `getCachedDailyForm` | 158 | override | فك JSON النموذج | `log_repository_impl.dart:369` |
| `markCachedDailyLogFormComplete` | 169 | override | تعديل `formStatus` و`isFormComplete` داخل اللقطة | `log_repository_impl.dart:477`، `:518` |
| `ownerOfCachedLog` | 203 | override | مسح مفاتيح `logs:` كلها | `log_repository_impl.dart:132`، `:536`، `sync_providers.dart:117` |
| `_readCachedList` | 227 | helper خاص | فك قائمة JSON من مفتاح | `getCachedDailyLogs`، `getCachedLogEvents`، `markCachedDailyLogFormComplete`، `ownerOfCachedLog` |
| `_saveToBox` | 242 | helper خاص | إضافة عنصر إلى قائمة اليوم وحفظها | `addEvent`، `savePeriod`، `logAudit` |
| `_getFromBox` | 263 | helper خاص | قراءة قائمة اليوم | `getEvents`، `getPeriods`، `getAuditEntries` |
| `_getListFromBox` | 277 | helper خاص | فك قائمة JSON ليوم | `_saveToBox`، `_getFromBox`، `updateEvent` |
| `getEvents` | 291 | override | بناء `LogEvent` من الخرائط | لا يوجد خارجيًا؛ عبر المستودع |
| `_readDurationSeconds` | 330 | helper خاص | قراءة `durationSeconds` أو `duration` | `getEvents` |
| `_eventMap` | 335 | helper خاص | تحويل حدث إلى خريطة تخزين | `addEvent`، `updateEvent` |
| `addEvent` | 349 | override | `_saveToBox(...)` | `log_repository_impl.dart:207` |
| `updateEvent` | 354 | override | استبدال بالمعرّف أو إضافة | `log_repository_impl.dart:268` |
| `getPeriods` | 374 | override | بناء `DutyPeriod` من الخرائط | `log_repository_impl.dart:730` |
| `savePeriod` | 409 | override | `_saveToBox(...)` | `log_repository_impl.dart:738` |
| `clearPeriods` | 425 | override | `clear()` على صندوق الفترات | `app.dart:40` |
| `logAudit` | 434 | override | `_saveToBox(...)` | `log_repository_impl.dart:746` |
| `getAuditEntries` | 439 | override | تحويل خرائط اليوم إلى `AuditEntry` | `log_repository_impl.dart:754` |
| `getRecentAuditEntries` | 445 | override | مسح كل المفاتيح ثم ترتيب | `log_repository_impl.dart:764` |
| `logLocalDataSourceProvider` | 467 | `Provider<LogLocalDataSource>` | إنشاء `LogLocalDataSourceImpl` | `log_repository_providers.dart:16`، `app.dart:40`، `sync_providers.dart:117` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- دالتان ميتتان في العقد والتنفيذ: `saveSignature` و`getSignature` لا يستدعيهما أي ملف في `lib` أو `test`.
- عقد بـ22 دالة يخلط سبعة اختصاصات: الأحداث، فترات الخدمة، التدقيق، لقطات القائمة، لقطات الأحداث، النماذج، التواقيع.
- الاعتماد على صناديق Hive عامة: الأسطر 67-71 تستدعي `Hive.box<String>(...)` مباشرة، ولا يوجد constructor يحقن الصناديق. النتيجة أن التنفيذ غير قابل للاستبدال في الاختبار، ولهذا تستخدم الاختبارات `Mock` على الواجهة في `log_repository_offline_test.dart:22` و`log_repository_impl_form_test.dart:23`.
- خلط DI بالتنفيذ: `logLocalDataSourceProvider` معرّف في السطر 467 داخل ملف مصدر البيانات نفسه.
- فقدان يوم كامل عند تلف عنصر واحد: `_getListFromBox` في الأسطر 277-286 يستخدم `decoded.map((e) => e as Map<String, dynamic>)` داخل `try`، وأي عنصر غير خريطي يرمي `TypeError` فيُلتقط في السطر 283 ويُعاد `[]` لكل اليوم. هذا يطال الأحداث والفترات والتدقيق.
- مقارنة: `_readCachedList` في الأسطر 227-238 يستخدم `whereType<Map>()` فيتجاوز العنصر التالف ويحتفظ بالبقية. أي أن سلوك الملف نفسه غير متسق بين المسارين.
- فقدان حقول الأحداث عند التخزين المحلي:
  - `_eventMap` في الأسطر 335-346 يكتب ثمانية مفاتيح فقط: `id`، `status`، `startTime`، `durationSeconds`، `location`، `odometer`، `engineHours`، `timestamp`.
  - لا يكتب `automatedDriving` ولا `editable` ولا `startedOnPreviousDay` ولا `isExpanded`.
  - `getEvents` في الأسطر 291-327 يبني `LogEvent` بلا هذه الحقول أيضًا.
  - الأثر الفعلي محصور في الأحداث المسجلة محليًا، لأن لقطة الخادم تُقرأ عبر `LogEventModel.fromJson` الذي يحفظ `automatedDriving` و`editable`.
- نص بديل غير موحّد للموقع: `getEvents` يستخدم `'Unknown'` في السطر 313، بينما `LogEventModel.fromJson` يستخدم `'Unknown Location'` في `log_model.dart:101`.
- `_readDurationSeconds` في الأسطر 330-333 يفضّل `durationSeconds` بقيمة `0` على `duration` بقيمة صحيحة، لأن `??` لا يعتبر الصفر غيابًا.
- `updateEvent` في الأسطر 354-371: إذا لم يجد المعرّف يضيف الحدث (`currentList.add(map)` في السطر 363)، أي أن التعديل يتحول إلى إنشاء صامت.
- `savePeriod` في الأسطر 409-422 يضيف دائمًا عبر `_saveToBox` بلا بحث عن فترة بنفس وقت البداية، بخلاف `updateEvent`.
- `getPeriods` في الأسطر 374-406 يستدعي `DateTime.parse(e['startTime'] as String)` في السطر 393 بلا حماية. أي إدخال تالف يرمي `FormatException` بعد خروج القائمة من `_getFromBox`، فيصل إلى `executeWithHandling` ويُصنّف `ServerFailure` لا `CacheFailure`.
- `_saveToBox` في الأسطر 242-261 يرمي `CacheException` عند الفشل، بينما توقيع `addEvent` و`savePeriod` و`logAudit` هو `Future<bool>`. أي أن الفشل قد يظهر كاستثناء لا كقيمة `false`.
- `logAudit` في الأسطر 434-436 يضيف الإدخال بلا فحص تكرار بالمعرّف.
- `getRecentAuditEntries` في الأسطر 445-464 يمسح كل مفاتيح الصندوق ثم يفك كل JSON ثم يرتب كل الإدخالات في الذاكرة، ويطبّق `limit` بعد الفرز الكامل.
- اللقطات تُكتب بأفضل جهد وتُبتلع أخطاؤها: `cacheDailyLogs` (82-84)، `cacheLogEvents` (98-100)، `saveSignature` (111-114)، `saveDraftSignature` (126-128)، `deleteDraftSignature` (140-142)، `cacheDailyForm` (152-154)، `markCachedDailyLogFormComplete` (197-199)، `ownerOfCachedLog` (221-224)، `clearPeriods` (428-430). كلها تسجل تحذيرًا وتعيد بلا إعلام للداعي.
- `markCachedDailyLogFormComplete` في الأسطر 169-200 يكتب مفتاحين: `formStatus` في السطر 187 و`isFormComplete` في السطر 188. لكن `DailyLogDto.fromJson` يحسب `isFormComplete` من `formStatus` في السطر 198 ولا يقرأ المفتاح المكتوب. أي أن الكتابة الثانية ميتة.
- `ownerOfCachedLog` في الأسطر 203-225 يمسح كل مفاتيح `logs:` لكل السائقين، ويعيد `null` عند التعدد أو الغياب.
- المسح الكامل في `clearPeriods` يستهدف كل فترات كل السائقين لأن المفاتيح أيام بلا مالك، وهو موثق في الأسطر 57-63.
- بادئات مفاتيح مكتوبة يدويًا: `'logs:'` في الأسطر 81 و175 و207، `'events:'` في السطر 97، `'sig:'` في السطر 111، `'sig_draft:'` في السطر 125، `'form:'` في السطر 151.
- نصوص مكتوبة يدويًا: `'COMPLETED'` و`'INCOMPLETE'` في السطر 187، `'off_duty'` في السطر 392، `'Unknown'` في السطر 313.
- دوال أطول من 40 سطرًا: `ownerOfCachedLog` من 203 إلى 225 بطول 23 سطرًا، و`getEvents` من 291 إلى 327 بطول 37 سطرًا. لا توجد دالة تتجاوز 40 سطرًا.
- لا يوجد `build` لأنه ليس ملف واجهة.

---

## 3. `lib/features/logs/data/models/daily_log_dto.dart`

- **الطبقة:** data
- **المسؤولية في جملة واحدة:** فك استجابة السجل اليومي من الخادم وتحويلها إلى كيان `DailyLog`.
- **عدد الأسطر:** 215
- **الاعتمادات:**
  - داخل الميزة: `domain/entities/daily_log.dart` (السطر 1)، `log_model.dart` (السطر 3).
  - من `core/` وشجرة `lib` العامة: `domain/shared/value_objects.dart` (السطر 2).
  - حزم خارجية: لا يوجد.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/repositories/log_repository_impl.dart:25`.
  - خارج الميزة: لا يوجد.
  - الاختبارات: `test/features/logs/data/models/daily_log_dto_test.dart:2`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `DailyLogDto` | class عادي غير Equatable | DTO السجل اليومي | 5 |

### الحقول (20 حقلًا)

| الاسم | النوع | public/private | final | الغرض | السطر | أين يُقرأ | أين يُكتب |
|---|---|---|---|---|---|---|---|
| `id` | `int` | public | final | معرف السجل | 6 | `toEntity` في السطر 189 | constructor في السطر 122 |
| `uniqueId` | `String` | public | final | المعرف النصي | 7 | السطر 190 | السطر 123 |
| `logDate` | `String` | public | final | تاريخ اليوم الخام | 8 | السطر 192 | السطر 124 |
| `formattedTotalWorkTime` | `String` | public | final | إجمالي وقت العمل جاهز العرض | 9 | السطر 194 | السطر 125 |
| `totalDurationMinutes` | `int` | public | final | إجمالي الدقائق | 10 | السطر 195 | السطر 129 |
| `formStatus` | `String` | public | final | حالة النموذج النصية | 11 | السطر 156 | السطر 132 |
| `certificationStatus` | `String` | public | final | حالة الاعتماد النصية | 12 | السطر 171 | السطر 133 |
| `today` | `bool` | public | final | هل اليوم هو اليوم | 13 | السطر 201 | السطر 134 |
| `events` | `List<Map<String, dynamic>>` | public | final | أحداث خام | 14 | السطر 202 | السطر 135 |
| `requiresAction` | `bool` | public | final | هل يحتاج إجراءً | 15 | السطر 200 | السطر 140 |
| `driverName` | `String?` | public | final | اسم السائق | 19 | السطر 203 | السطر 141 |
| `vehicleName` | `String?` | public | final | اسم المركبة | 20 | السطر 204 | السطر 142 |
| `vin` | `String?` | public | final | رقم VIN | 21 | السطر 205 | السطر 143 |
| `licensePlate` | `String?` | public | final | رقم اللوحة | 22 | السطر 206 | السطر 144 |
| `carrierName` | `String?` | public | final | اسم الناقل | 23 | السطر 207 | السطر 145 |
| `usdotNumber` | `String?` | public | final | رقم USDOT | 24 | السطر 208 | السطر 146 |
| `mainOfficeAddress` | `String?` | public | final | عنوان المكتب الرئيسي | 25 | السطر 209 | السطر 147 |
| `homeTerminalAddress` | `String?` | public | final | عنوان المحطة | 26 | السطر 210 | السطر 148 |
| `trailers` | `List<String>` | public | final | المقطورات | 27 | السطر 211 | السطر 149 |
| `shippingDocuments` | `List<String>` | public | final | وثائق الشحن | 28 | السطر 212 | السطر 150 |

### الدوال والـMethods

| الاسم | التوقيع الكامل | الكلاس المالك | الغرض | المدخلات | المخرجات | الآثار الجانبية | Providers | من يستدعيها |
|---|---|---|---|---|---|---|---|---|
| `DailyLogDto` | `const DailyLogDto({required int id, required String uniqueId, required String logDate, required String formattedTotalWorkTime, required int totalDurationMinutes, required String formStatus, required String certificationStatus, required bool today, List<Map<String, dynamic>> events = const [], bool requiresAction = false, String? driverName, String? vehicleName, String? vin, String? licensePlate, String? carrierName, String? usdotNumber, String? mainOfficeAddress, String? homeTerminalAddress, List<String> trailers = const [], List<String> shippingDocuments = const []})` | `DailyLogDto` | إنشاء DTO | الحقول أعلاه | `DailyLogDto` | لا يوجد | لا يوجد | `fromJson` في السطر 121 |
| `fromJson` | `factory DailyLogDto.fromJson(Map<String, dynamic> json)` | `DailyLogDto` | فك استجابة الخادم | خريطة JSON | `DailyLogDto` | لا يوجد | لا يوجد | `log_repository_impl.dart:127`، `:144`، `:154`، `:548`، `daily_log_dto_test.dart:15`، `:49`، `:64`، `:85`، `:96`، `:104`، `:118`، `:135`، `:149`، `:161`، `:170` |
| `toEntity` | `DailyLog toEntity()` | `DailyLogDto` | تحويل DTO إلى كيان | لا يوجد | `DailyLog` | لا يوجد | لا يوجد | `log_repository_impl.dart:127`، `:144`، `:154`، `:548`، `daily_log_dto_test.dart:18`، `:49` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- `logDate` إلزامي: غيابه أو فراغه يرمي `FormatException` في الأسطر 55-59، وعدم قابليته للتحليل يرمي في السطرين 191-193. الاختبار يثبت الحالتين في `daily_log_dto_test.dart:75-99`.
- حقول تُخترع عند غيابها:
  - `id` يصبح `0` في السطر 122.
  - `uniqueId` يصبح `''` في السطر 123.
  - `today` يصبح `false` في السطر 134.
  - `requiresAction` يصبح `false` في السطر 140.
  - `formStatus` و`certificationStatus` يصبحان `'UNKNOWN'` في السطرين 132-133.
- سلسلة استنتاج حالة النموذج في الأسطر 84-97: الحقل النصي، ثم `formIndicator.status`، ثم `positive` أو اللون `GREEN` و`RED`.
- سلسلة استنتاج الاعتماد في الأسطر 101-116: الحقل النصي، ثم `certified`، ثم `logStatus` بالقيم `CERTIFIED` و`RE_CERTIFICATION_REQUIRED` و`REVOKED` و`NOT_READY` و`READY`.
- `READY` و`NOT_READY` كلاهما يتحول إلى `CertificationStatus.uncertified` في الأسطر 175-178.
- `INVALID` يتحول إلى `FormStatus.incomplete` في السطر 163.
- الأحداث تُحوّل بتحويل قسري: `(json['events'] as List<dynamic>?)?.map((e) => e as Map<String, dynamic>)` في الأسطر 136-139. أي عنصر غير خريطي يرمي `TypeError` لا `FormatException`، ولا يُتجاوز.
- `driverName` يُقرأ من `driver.name` فقط في السطر 141. لا يقرأ `driver` كسلسلة.
- `vehicleName` يُقرأ من الحقل المسطح `json['vehicleName']` فقط في السطر 142، ولا يقرأ `vehicle.name` المتداخل الذي يقرأه `_parseDailyFormData` في `log_repository_impl.dart:442-445`.
- `vin` و`licensePlate` و`carrierName` و`usdotNumber` و`mainOfficeAddress` و`homeTerminalAddress` تُقرأ مسطحة فقط في الأسطر 143-148.
- `trailers` و`shippingDocuments` تُحوّل عبر `stringList` في السطرين 62-63 بتحويل قسري `raw as List?`؛ قيمة نصية بدل قائمة ترمي `TypeError`.
- `totalDurationMinutes` يُشتق من `totals.total.seconds / 60` بتقريب `round()` في السطرين 129-131.
- `formattedTotalWorkTime` يفضّل الحقل المسطح ثم `totals.total.formatted` في الأسطر 118-128.
- لا يوجد `toJson` ولا `copyWith` ولا `Equatable` في هذا الـDTO.
- لا توجد اختبارات للحقول `mainOfficeAddress` و`homeTerminalAddress` و`usdotNumber` و`licensePlate` و`vin` سوى ما ورد في اختبار التفاصيل `daily_log_dto_test.dart:24-62`.
- دوال أطول من 40 سطرًا: `fromJson` من 53 إلى 152 بطول 100 سطر. `toEntity` من 154 إلى 214 بطول 61 سطرًا.

---

## 4. `lib/features/logs/data/models/log_model.dart`

- **الطبقة:** data
- **المسؤولية في جملة واحدة:** فك أشكال حدث السجل الثلاثة (العقد الموحّد، `GraphGridEvent` القديم، الشكل المحلي المضغوط) إلى `LogEvent`.
- **عدد الأسطر:** 158
- **الاعتمادات:**
  - داخل الميزة: `domain/entities/daily_log.dart` (السطر 1).
  - من `core/` وشجرة `lib` العامة: `domain/duty_status/duty_status_code.dart` (السطر 2)، `core/utils/logger.dart` (السطر 3).
  - حزم خارجية: لا يوجد.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/models/daily_log_dto.dart:3`، `data/repositories/log_repository_impl.dart:19`.
  - خارج الميزة: لا يوجد.
  - الاختبارات: `test/features/logs/data/log_event_model_test.dart:2`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `LogEventModel` | class يرث `LogEvent` | نموذج حدث السجل | 5 |

### الحقول

لا يملك `LogEventModel` أي حقل خاص؛ يرث الحقول الأحد عشر من `LogEvent` الموثقة في `01_domain.md`. يملك ثابتًا واحدًا:

| الاسم | النوع | الكلاس المالك | public/private | final / late | الغرض | السطر | أين يُقرأ |
|---|---|---|---|---|---|---|---|
| `_kmToMiles` | `double` | `LogEventModel` | private | `static const` | معامل تحويل الكيلومتر إلى الميل | 112 | السطر 75 |

### الدوال والـMethods

| الاسم | التوقيع الكامل | الكلاس المالك | الغرض | المدخلات | المخرجات | الآثار الجانبية | Providers | من يستدعيها |
|---|---|---|---|---|---|---|---|---|
| `LogEventModel` | `const LogEventModel({required super.id, required super.status, required super.startTime, required super.duration, required super.location, super.odometer, super.engineHours, super.isExpanded, super.automatedDriving, super.editable, super.startedOnPreviousDay})` | `LogEventModel` | إنشاء نموذج حدث | حقول `LogEvent` | `LogEventModel` | لا يوجد | لا يوجد | `fromJson` في السطر 96، `fromEntity` في السطر 144 |
| `fromJson` | `factory LogEventModel.fromJson(Map<String, dynamic> json)` | `LogEventModel` | فك أي شكل من أشكال الحدث | خريطة JSON | `LogEventModel` | يسجل تحذيرًا عبر `DutyStatusCode` عند حالة غير معروفة | لا يوجد | `log_repository_impl.dart:327`، `log_event_model_test.dart:13`، `:37`، `:52`، `:67` |
| `parseList` | `static List<LogEventModel> parseList(Iterable<Map<String, dynamic>> raw, {required String source})` | `LogEventModel` | فك قائمة وتجاوز التالف | قائمة خرائط ومصدر نصي | `List<LogEventModel>` | `AppLogger.warning` لكل عنصر متجاوز في السطر 125 | لا يوجد | `daily_log_dto.dart:202`، `log_repository_impl.dart:176`، `:188` |
| `toJson` | `Map<String, dynamic> toJson()` | `LogEventModel` | تحويل الحدث إلى الشكل المحلي المضغوط | لا يوجد | `Map<String, dynamic>` | لا يوجد | لا يوجد | `log_event_model_test.dart:75` فقط؛ لا يوجد مستدعٍ في `lib` |
| `fromEntity` | `factory LogEventModel.fromEntity(LogEvent entity)` | `LogEventModel` | تحويل كيان إلى نموذج | `LogEvent` | `LogEventModel` | لا يوجد | لا يوجد | **لا يوجد أي مستدعٍ في `lib` أو `test`** |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- الهوية والوقت إلزاميان: غياب `id` يرمي `FormatException('LogEvent without id')` في الأسطر 32-34، وغياب وقت البداية يرمي في الأسطر 42-44. الاختبار يغطي الحالتين ضمنًا عبر `parseList` وليس مباشرة.
- الحالة غير المعروفة تتحول إلى راحة: `fromShortCode(rawStatus) ?? fromWire(rawStatus)` في الأسطر 47-49. `fromWire` يستدعي `fromAny` الذي يعيد `offDuty` لأي قيمة غير معروفة مع تسجيل تحذير في `duty_status_code.dart:49-52`. النتيجة أن أي رمز جديد من الخادم يظهر `OFF` بدل رفضه.
- أولوية المدة في الأسطر 51-69: `timeRange.durationSeconds`، ثم `durationMinutes`، ثم `durationSeconds`، ثم `duration`. أي قيمة غير قابلة للتحليل تصبح `0`.
- تحويل المسافة في الأسطر 72-78: `odometerKm` يُضرب في `0.621371`، و`odometer` يُقرأ كما هو.
- القيادة الآلية في الأسطر 80-83: من `automatedDriving` إذا كان `bool`، وإلا من `origin` الذي يبدأ بـ`AUTO`.
- `location` في الأسطر 87-94: `description` إذا كان كائنًا، أو النص، ثم `locationText`.
- اختراع موقع افتراضي: `location ?? 'Unknown Location'` في السطر 101. التعليق في الأسطر 28-29 يقول إن السجل لا يُمنح هوية أو وقتًا مخترعين، لكن الموقع يُمنح قيمة مخترعة.
- `DateTime.parse(startTimeStr).toLocal()` في السطر 99 يرمي `FormatException` إذا كان النص غير صالح؛ `parseList` يلتقطه ويستبعد الحدث في الأسطر 122-127.
- `editable` يبقى `null` إذا لم يكن `bool` في السطر 107، و`startedOnPreviousDay` يشترط `== true` في السطر 108.
- `toJson` في الأسطر 131-141 يكتب سبعة مفاتيح فقط ويُسقط `automatedDriving` و`editable` و`startedOnPreviousDay` و`isExpanded`. جولة `toJson` ثم `fromJson` تفقدها، والاختبار في `log_event_model_test.dart:65-80` لا يتحقق منها.
- `LogEventModel` يرث `LogEvent` من domain، أي أن نموذج data هو نوع فرعي من كيان domain. هذا يجعل حدود الطبقتين غير صريحة.
- التغطية الاختبارية: `log_event_model_test.dart:11-63` تغطي `DRIVING` و`durationMinutes` و`odometerKm` و`origin` وست حالات wire، و`:65-80` تغطي جولة الشكل المحلي.
- غير مغطى بالاختبار: حالة wire غير معروفة، `timeRange`، `durationSeconds`، `location` ككائن، غياب `id`، غياب `startTime`، و`startedOnPreviousDay`.
- دوال أطول من 40 سطرًا: `fromJson` من 30 إلى 110 بطول 80 سطرًا.

---

## 5. `lib/features/logs/data/models/saved_form_dto.dart`

- **الطبقة:** data
- **المسؤولية في جملة واحدة:** فك استجابة حفظ النموذج اليومي إلى `SavedFormRead`.
- **عدد الأسطر:** 42
- **الاعتمادات:**
  - داخل الميزة: `domain/saved_form_status.dart` (السطر 1).
  - من `core/`: لا يوجد.
  - حزم خارجية: لا يوجد.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/repositories/log_repository_impl.dart:26`.
  - خارج الميزة: لا يوجد.
  - الاختبارات: `test/features/logs/saved_form_status_test.dart:2`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `SavedFormDto` | class عادي | أداة فك استجابة الحفظ | 4 |

### الحقول

لا يوجد أي حقل في هذا الملف.

### الدوال والـMethods

| الاسم | التوقيع الكامل | الكلاس المالك | الغرض | المدخلات | المخرجات | الآثار الجانبية | Providers | من يستدعيها |
|---|---|---|---|---|---|---|---|---|
| `fromJson` | `static SavedFormRead fromJson(Map<String, dynamic> json)` | `SavedFormDto` | فك حالة النموذج من الاستجابة | خريطة JSON | `SavedFormRead` | لا يوجد | لا يوجد | `log_repository_impl.dart:516`، `saved_form_status_test.dart:6`، `:16`، `:22` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- فك الغلاف: إن وُجد `json['data']` كخريطة يُستخدم بدلًا من الجذر في الأسطر 7-9.
- استنتاج الحالة في الأسطر 10-16: `formStatus` أولًا، ثم `formIndicator.status`.
- خريطة `complete` في الأسطر 26-30:
  - `COMPLETED` و`COMPLETE` تعني `true`.
  - `INCOMPLETE` و`IN_PROGRESS` و`DRAFT` و`INVALID` تعني `false`.
  - أي قيمة أخرى تعني `null`، ثم يُستخدم `formIndicator.positive` أو اللون في الأسطر 32-38.
- إذا كانت الحالة نصًا معروفًا لكن `formIndicator` غائبًا وقيمة الحالة خارج القائمتين، يبقى `complete` مساويًا `null`، ولا يُحدَّث كاش الاكتمال لأن المستودع يفحص `read.complete != null` في `log_repository_impl.dart:517`.
- `message` تُقرأ من `body['message']` فقط في السطر 17، ولا تُقرأ من الجذر عند وجود غلاف `data`.
- التغطية الاختبارية: `saved_form_status_test.dart:5-12` تختبر `COMPLETED` مع رسالة، و`:14-19` تختبر `INCOMPLETE`، و`:21-26` تختبر غياب الحالة.
- غير مغطى بالاختبار: `IN_PROGRESS`، `INVALID`، الاعتماد على `formIndicator` وحده، ورسالة داخل `data`.
- لا يوجد `toJson` ولا `Equatable` في هذا الـDTO.
- نصوص مكتوبة يدويًا: `'data'` في السطر 7، `'formStatus'` في السطر 10، `'formIndicator'` في السطر 11، `'status'` في السطر 15، `'message'` في السطر 17، `'positive'` في السطر 20، `'color'` في السطر 21، `'GREEN'` و`'RED'` في السطرين 33 و35.
- دوال أطول من 40 سطرًا: لا يوجد.

---

## 6. `lib/features/logs/data/providers/log_repository_providers.dart`

- **الطبقة:** data
- **المسؤولية في جملة واحدة:** تركيب `LogRepositoryImpl` من سبعة اعتماديات عبر Riverpod.
- **عدد الأسطر:** 24
- **الاعتمادات:**
  - داخل الميزة: `domain/repositories/log_repository.dart` (السطر 8)، `datasources/log_local_data_source.dart` (السطر 9)، `repositories/log_repository_impl.dart` (السطر 10).
  - من `core/` وشجرة `lib` العامة: `backend/providers/backend_providers.dart` (السطر 3)، `core/network/core_providers.dart` (السطر 4)، `features/sync/data/providers/sync_providers.dart` (السطر 5)، `core/time/time_authority_provider.dart` (السطر 6)، `core/di/id_generator_provider.dart` (السطر 7).
  - حزم خارجية: `package:flutter_riverpod/flutter_riverpod.dart`.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `presentation/providers/audit_trail_provider.dart:2`، `presentation/providers/certify_log_provider.dart:16`، `presentation/providers/edit_log_provider.dart:14`، `presentation/providers/form_tab_provider.dart:4`، `presentation/providers/logs_provider.dart:7`، `presentation/providers/log_draft_signature_provider.dart:8`، و`data/repositories/log_repository_impl.dart:37` (تصدير).
  - خارج الميزة: `lib/features/hos/data/providers/duty_period_store_providers.dart:3`، `lib/features/inspection/presentation/pages/send_logs_page.dart:11`.
  - الاختبارات: `test/features/logs/presentation/pages/edit_log_page_logic_test.dart:21`، `test/features/logs/presentation/pages/trailers_page_test.dart:17`، `test/features/logs/presentation/providers/form_tab_provider_test.dart:8`، `test/features/logs/presentation/providers/logs_provider_form_race_test.dart:10`.

### الكلاسات

لا يوجد أي كلاس في هذا الملف.

### المتغيرات والحقول

| الاسم | النوع | المستوى | public/private | final | الغرض | السطر | أين يُقرأ | أين يُكتب |
|---|---|---|---|---|---|---|---|---|
| `logRepositoryProvider` | `Provider<LogRepository>` | top-level | public | `final` | توفير نسخة `LogRepositoryImpl` | 14 | `duty_period_store_providers.dart:8`، `send_logs_page.dart:125`، `audit_trail_provider.dart:9`، `certify_log_provider.dart:132`، `edit_log_provider.dart:156`، `form_tab_provider.dart:318`، `logs_provider.dart:85`، `log_draft_signature_provider.dart:62`، وأحد عشر اختبارًا عبر `overrideWithValue` | `log_repository_providers.dart:14` فقط |

### المزوّد واعتمادياته الداخلية

`logRepositoryProvider` يقرأ سبعة مزوّدات عبر `ref.watch`:

| المزوّد المقروء | السطر في هذا الملف |
|---|---:|
| `logLocalDataSourceProvider` | 16 |
| `dailyLogsBackendProvider` | 17 |
| `dutyStatusBackendProvider` | 18 |
| `networkInfoProvider` | 19 |
| `offlineQueueProvider` | 20 |
| `timeAuthorityProvider` | 21 |
| `idGeneratorProvider` | 22 |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- النوع `Provider<LogRepository>` وليس `autoDispose`، فالمستودع يبقى حيًا طول عمر الحاوية.
- كل تغيير في أي من المزوّدات السبعة يعيد إنشاء `LogRepositoryImpl` بالكامل. المستودع بلا حالة داخلية، فإعادة الإنشاء لا تفقد بيانات، لكنها تعيد بناء الكائن.
- التعليق في السطر 12 يسمّي هذا الملف «المرحلة 3b».
- التصدير العكسي من `log_repository_providers.dart` موجود في `log_repository_impl.dart:34-37` بتعليق صريح أنه جسر توافق للاختبارات القديمة.
- لا توجد أي حماية من إعادة الإنشاء المتكرر أثناء تغيّر حالة الشبكة.
- لا يوجد `keepAlive` صريح ولا `autoDispose`.

---

## 7. `lib/features/logs/data/repositories/log_repository_impl.dart`

- **الطبقة:** data
- **المسؤولية في جملة واحدة:** تنفيذ عقد `LogRepository` فوق مصدر البيانات المحلي وواجهات الخادم وطابور المزامنة.
- **عدد الأسطر:** 783
- **الاعتمادات:**
  - داخل الميزة: `domain/repositories/log_repository.dart` (السطر 17)، `datasources/log_local_data_source.dart` (18)، `models/log_model.dart` (19)، `domain/entities/daily_log.dart` (20)، `domain/entities/daily_log_page.dart` (21)، `domain/entities/audit_entry.dart` (22)، `models/daily_log_dto.dart` (25)، `models/saved_form_dto.dart` (26)، `domain/entities/log_readiness.dart` (28)، `domain/entities/log_certify_state.dart` (29)، `domain/saved_form_status.dart` (30)، `domain/entities/daily_form_data.dart` (31)، `domain/entities/daily_form_update.dart` (32)، وتصدير `providers/log_repository_providers.dart` (37).
  - من `core/` وشجرة `lib` العامة: `core/utils/id_generator.dart` (3)، `core/error/exception.dart` (7)، `core/error/app_error.dart` (8)، `core/error/failure.dart` (9)، `core/time/time_authority.dart` (10)، `core/utils/logger.dart` (11)، `core/network/network_info.dart` (12)، `core/domain/entities/hos_models.dart` (23)، `domain/shared/value_objects.dart` (24)، `domain/duty_status/duty_status_code.dart` (16)، `core/utils/repository_helper.dart` (38)، `features/sync/domain/entities/pending_event.dart` (4)، `features/sync/domain/repositories/offline_queue.dart` (5).
  - من `backend/`: `backend/contracts/daily_logs_backend.dart` (14)، `backend/contracts/duty_status_backend.dart` (15)، `backend/adapters/eld_engine/models/certify_dto.dart` (27).
  - حزم خارجية: `dart:async`، `package:intl/intl.dart`، `package:fpdart/fpdart.dart`.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/providers/log_repository_providers.dart:10`.
  - خارج الميزة: لا يوجد.
  - الاختبارات: `test/features/logs/data/log_repository_offline_test.dart:9`، `test/features/logs/data/repositories/log_repository_impl_form_test.dart:12`، `test/features/logs/presentation/pages/logs_list_page_test.dart:10`، `test/features/logs/presentation/pages/log_detail_page_indexed_stack_test.dart:10`، `test/features/logs/presentation/pages/log_detail_page_route_test.dart:13`، `test/features/logs/presentation/pages/unidentified_events_page_test.dart:15`، `test/features/logs/presentation/providers/logs_provider_events_test.dart:7`، `test/features/logs/presentation/widgets/log_detail_tabs/certify_tab_errors_test.dart:9`، `test/features/logs/presentation/widgets/log_detail_tabs/certify_tab_signature_draft_test.dart:9`، `test/features/logs/presentation/widgets/log_detail_tabs/certify_tab_test.dart:13`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `LogRepositoryImpl` | class ينفّذ `LogRepository` | مستودع السجلات | 40 |

### الحقول (7 حقول)

| الاسم | النوع | public/private | final | الغرض | السطر | أين يُقرأ | أين يُكتب |
|---|---|---|---|---|---|---|---|
| `_localDataSource` | `LogLocalDataSource` | private | final | التخزين المحلي | 41 | `:75`، `:98`، `:132`، `:175`، `:183`، `:207`، `:268`، `:369`، `:390`، `:473`، `:477`، `:518`، `:536`، `:538`، `:730`، `:738`، `:746`، `:754`، `:764`، `:771`، `:776`، `:781` | constructor في السطر 57 |
| `_dailyLogsBackend` | `DailyLogsBackend` | private | final | واجهة السجلات | 42 | `:84`، `:151`، `:166`، `:377`، `:504`، `:567`، `:606`، `:670`، `:692`، `:713` | constructor في السطر 58 |
| `_dutyStatusBackend` | `DutyStatusBackend` | private | final | واجهة حالات الخدمة | 43 | `:232`، `:306`، `:312` | constructor في السطر 59 |
| `_networkInfo` | `NetworkInfo` | private | final | فحص الاتصال | 44 | `:71`، `:131`، `:164`، `:204`، `:266`، `:368`، `:484`، `:532`، `:603`، `:649` | constructor في السطر 60 |
| `_offlineQueue` | `OfflineQueue` | private | final | طابور المزامنة | 45 | `:212`، `:278`، `:485`، `:651` | constructor في السطر 61 |
| `_timeAuthority` | `TimeAuthority` | private | final | وقت موثوق | 46 | `:227`، `:292`، `:497`، `:664`، `:730` | constructor في السطر 62 |
| `_idGenerator` | `IdGenerator` | private | final | توليد معرفات | 47 | `:214`، `:280`، `:487`، `:653` | constructor في السطر 63 |

### الدوال والـMethods (26 دالة)

| الاسم | التوقيع الكامل | الغرض | المدخلات | المخرجات | الآثار الجانبية | Providers | من يستدعيها |
|---|---|---|---|---|---|---|---|
| `LogRepositoryImpl` | `LogRepositoryImpl({required LogLocalDataSource localDataSource, required DailyLogsBackend dailyLogsBackend, required DutyStatusBackend dutyStatusBackend, required NetworkInfo networkInfo, required OfflineQueue offlineQueue, required TimeAuthority timeAuthority, required IdGenerator idGenerator})` | إنشاء المستودع | سبعة اعتماديات | `LogRepositoryImpl` | لا يوجد | لا يوجد | `log_repository_providers.dart:15`، `log_repository_offline_test.dart:74`، `log_repository_impl_form_test.dart:60` |
| `getDailyLogs` | `Future<Either<Failure, DailyLogPage>> getDailyLogs({required int driverId, int page = 0, int size = 20})` | جلب صفحة سجلات | معرف السائق، الصفحة، الحجم | صفحة أو فشل | كتابة كاش الصفحة الأولى، قراءة كاش عند الأوفلاين | لا يوجد | `logs_provider.dart:132` |
| `_cacheQuietly` | `void _cacheQuietly(Future<void> write)` | تنفيذ كتابة كاش بلا انتظار وبلا فشل | مستقبل | لا يوجد | `unawaited` مع `catchError` فارغ | لا يوجد | `:98`، `:175` |
| `_toDailyLogs` | `List<DailyLog> _toDailyLogs(List<Map<String, dynamic>> logsJson)` | تحويل قائمة JSON إلى كيانات | قائمة خرائط | `List<DailyLog>` | لا يوجد | لا يوجد | `:77`، `:104` |
| `getLogById` | `Future<Either<Failure, DailyLog>> getLogById(DailyLogId logId)` | جلب تفاصيل سجل | معرف السجل | سجل أو فشل | قراءة كاش عند الأوفلاين | لا يوجد | `logs_provider.dart:333` |
| `getEvents` | `Future<Either<Failure, List<LogEvent>>> getEvents(DailyLogId logId, DateTime date)` | جلب أحداث سجل | معرف السجل والتاريخ | أحداث أو فشل | كتابة كاش الأحداث، قراءة كاش ومحلي | لا يوجد | `logs_provider.dart:353` |
| `addEvent` | `Future<Either<Failure, bool>> addEvent(LogEvent event, {String? reason, int? ownerDriverId})` | إضافة حدث | الحدث والسبب والمالك | نجاح أو فشل | كتابة محلية، إدراج في طابور الأوفلاين أو POST | لا يوجد | `logs_provider.dart:423`، `:428` |
| `updateEvent` | `Future<Either<Failure, LogEvent?>> updateEvent(LogEvent event, {required String reason, DailyLogId? logId, int? ownerDriverId})` | تعديل حدث | الحدث والسبب والسجل والمالك | الحدث المؤكد أو null أو فشل | كتابة محلية، إدراج في الطابور أو POST/PUT | لا يوجد | `logs_provider.dart:456`، `:462` |
| `_mapFormUpdateToJson` | `Map<String, dynamic> _mapFormUpdateToJson(DailyFormUpdate form)` | تحويل أمر الحفظ إلى جسم الخادم | `DailyFormUpdate` | خريطة | لا يوجد | لا يوجد | `:472` |
| `getForm` | `Future<Either<Failure, DailyFormData?>> getForm(DailyLogId logId)` | قراءة نموذج اليوم | معرف السجل | نموذج أو null أو فشل | كتابة كاش عند النجاح | لا يوجد | `logs_provider.dart:229` |

| `_parseDailyFormData` | `DailyFormData _parseDailyFormData(Map<String, dynamic> data)` | تحويل خريطة النموذج إلى كيان | خريطة | `DailyFormData` | لا يوجد | لا يوجد | `:371`، `:391` |
| `saveForm` | `Future<Either<Failure, FormSaveResult>> saveForm({required DailyLogId logId, required DailyFormUpdate form, int? ownerDriverId})` | حفظ النموذج | السجل والنموذج والمالك | نتيجة حفظ أو فشل | كتابة كاش، تحديث اكتمال اللقطة، إدراج في الطابور أو PUT | لا يوجد | `form_tab_provider.dart:319` |
| `getReadiness` | `Future<Either<Failure, LogReadiness>> getReadiness(DailyLogId logId)` | قراءة جاهزية السجل | معرف السجل | جاهزية أو فشل | قراءة كاش عند الأوفلاين | لا يوجد | `certify_log_provider.dart:168` |
| `getCertifyState` | `Future<Either<Failure, LogCertifyState>> getCertifyState(DailyLogId logId)` | قراءة حالة الاعتماد | معرف السجل | حالة أو فشل | لا يوجد | لا يوجد | `certify_log_provider.dart:174` |
| `_isEndpointUnsupported` | `static bool _isEndpointUnsupported(AppError error)` | كشف 404 أو 405 | خطأ | `bool` | لا يوجد | لا يوجد | `:610` |
| `certifyLog` | `Future<Either<Failure, bool>> certifyLog({required DailyLogId logId, required int driverId, bool certified = true, String? signatureImageBase64})` | اعتماد السجل | السجل والسائق والتوقيع | نجاح أو فشل | إدراج في الطابور عند الأوفلاين أو POST | لا يوجد | `certify_log_provider.dart:279` |
| `respondToCarrierEdit` | `Future<Either<Failure, bool>> respondToCarrierEdit({required DailyLogId logId, required String editId, required String action, String? driverNotes})` | الرد على تعديل الناقل | السجل والتعديل والإجراء والملاحظات | نجاح أو فشل | نداء شبكي فقط | لا يوجد | `certify_log_provider.dart:208` |
| `reassignDriving` | `Future<Either<Failure, bool>> reassignDriving({required DailyLogId logId, required int statusId, required int targetCoDriverId, required String annotation})` | إعادة تعيين وقت القيادة | السجل والحالة والسائق والملاحظة | نجاح أو فشل | نداء شبكي فقط | لا يوجد | **لا يوجد أي مستدعٍ في `lib`** |
| `getPeriods` | `Future<Either<Failure, List<DutyPeriod>>> getPeriods(DateTime date)` | قراءة فترات الخدمة | التاريخ | فترات أو فشل | قراءة محلية | لا يوجد | `log_duty_period_store.dart:12` خارج الميزة |
| `savePeriod` | `Future<Either<Failure, bool>> savePeriod(DutyPeriod period)` | حفظ فترة خدمة | الفترة | نجاح أو فشل | كتابة محلية | لا يوجد | `log_duty_period_store.dart:21` خارج الميزة |
| `logAudit` | `Future<Either<Failure, bool>> logAudit(AuditEntry entry)` | كتابة إدخال تدقيق | الإدخال | نجاح أو فشل | كتابة محلية | لا يوجد | `edit_log_provider.dart:157`، `send_logs_page.dart:126` خارج الميزة |
| `getAuditEntries` | `Future<Either<Failure, List<AuditEntry>>> getAuditEntries(DateTime date)` | قراءة تدقيق يوم | التاريخ | إدخالات أو فشل | قراءة محلية | لا يوجد | **لا يوجد أي مستدعٍ في `lib` أو `test`** |
| `getRecentAuditEntries` | `Future<Either<Failure, List<AuditEntry>>> getRecentAuditEntries({int limit = 100})` | قراءة أحدث الإدخالات | الحد | إدخالات أو فشل | قراءة محلية كاملة | لا يوجد | `audit_trail_provider.dart:10` |
| `saveDraftSignature` | `Future<void> saveDraftSignature(DailyLogId logId, String pointsJson)` | حفظ مسودة التوقيع | السجل والنقاط | لا يوجد | كتابة محلية مباشرة بلا `executeWithHandling` | لا يوجد | `log_draft_signature_provider.dart:41` |
| `getDraftSignature` | `Future<String?> getDraftSignature(DailyLogId logId)` | قراءة مسودة التوقيع | السجل | نص أو null | قراءة محلية مباشرة | لا يوجد | `log_draft_signature_provider.dart:22` |
| `deleteDraftSignature` | `Future<void> deleteDraftSignature(DailyLogId logId)` | حذف المسودة | السجل | لا يوجد | حذف محلي مباشر | لا يوجد | `log_draft_signature_provider.dart:39`، `:50` |

### حقائق مرصودة

- كود معلّق: السطر 302 يحتوي نداءً معلّقًا `// final unifiedResult = await _dailyLogsBackend.updateEvent(...);`. الأسطر 301 و303 و304 و305 تعليقات تفسيرية حول المسار البديل.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد. `dart:async` مستخدم في `unawaited` بالسطر 124، و`intl` مستخدم في السطر 555، و`app_error` مستخدم في الأسطر 636-637.
- جسر توافق: الأسطر 34-37 تصدّر `providers/log_repository_providers.dart` بتعليق يصرّح أن السبب إبقاء الاختبارات القديمة تعمل.
- ابتلاع أخطاء الكاش: `_cacheQuietly` في الأسطر 123-124 ينفّذ `unawaited(write.catchError((Object _) {}))`، فلا يظهر أي فشل كتابة.
- `getDailyLogs` عند الأوفلاين:
  - الصفحة الأولى فقط تُخدم من الكاش في الأسطر 74-79.
  - الصفحة الناتجة تُبنى بـ`DailyLogPage(logs: ...)` فقط، فتبقى `page` صفرًا و`hasNext` خطأً بقيمها الافتراضية، أي أن الواجهة تتلقى إشارة «لا مزيد» بلا دليل.
  - أي صفحة أكبر من صفر تعيد `NetworkFailure` في السطر 80.
- `getDailyLogs` عند الأونلاين:
  - تُخزَّن الصفحة الأولى فقط في الأسطر 96-99.
  - `hasNext` يُشتق من `pagination` أو من امتلاء الصفحة في الأسطر 107-109.
  - أي صف تالف في `_toDailyLogs` يرمي استثناءً يلتقطه `executeWithHandling` كخطأ عام فيُفشل الصفحة كلها برسالة `'An unexpected error occurred'` من `repository_helper.dart:63`.
- `getLogById` عند الأوفلاين يبحث عن المالك أولًا في السطر 132 ثم يقرأ لقطة ذلك المالك في السطر 134.
- `getEvents` يخفي فشل الخادم:
  - النداء في السطر 166 لا يمر عبر `executeWithHandling`.
  - `result.fold((_) => null, ...)` في الأسطر 167-172 يحوّل أي فشل إلى `null`.
  - عند `remoteJson == null` ينتقل مباشرة إلى الكاش والمحلي في الأسطر 182-191.
  - النتيجة أن خطأ 500 أو 401 يظهر كبيانات قديمة ناجحة، ولا يصل أي `Failure` للواجهة.
- `getEvents` يخزن لقطة الأحداث عند نجاح الشبكة في السطر 175.
- `getEvents` يدمج اللقطة مع الأحداث المحلية ويستبعد المكرر بالمعرّف في الأسطر 186-190.
- `addEvent` عند الأوفلاين:
  - يكتب محليًا في الأسطر 206-209.
  - يدرج في الطابور في الأسطر 212-229.
  - لا توجد معاملة تجمع الكتابة والإدراج: إذا فشل الإدراج يبقى الحدث محليًا بلا مزامنة.
  - الحمولة تضم `driverId` و`ownerDriverId` في السطرين 224-225.
- `addEvent` عند الأونلاين لا يضم `driverId` ولا `ownerDriverId` في الأسطر 232-239، بخلاف مسار الأوفلاين.
- `addEvent` يحوّل الحالة عبر `DutyStatusCode.fromShortCode(event.status)?.wire ?? DutyStatusCode.offDuty.wire` في السطرين 200-202، فأي حالة غير معروفة تُرسل `OFF_DUTY`.
- `updateEvent`:
  - `statusId = int.tryParse(event.id)` في السطر 253.
  - إذا كان المعرّف UUID (حدث محلي) يذهب إلى `record` أي POST في الأسطر 305-311، فينشئ حدثًا جديدًا بدل تعديل الحدث. التعليق في الأسطر 298-300 يصرّح بذلك.
  - عند الأوفلاين يعيد `Right(event)` مهما كانت قيمة نجاح الكتابة المحلية، لأن `fold` في الأسطر 271-276 يتجاهل القيمة المنطقية.
  - عند الأونلاين إذا كان جسم 200 غير قابل للتحليل يعيد `Right(null)` في السطر 338 بعد تسجيل خطأ في الأسطر 332-337.
  - الحمولة عند الأوفلاين تضم `statusId` و`logId` و`notes` و`driverId` و`ownerDriverId` في الأسطر 282-291. وعند الأونلاين تضم `editReason` فقط مع `base` في السطر 314.
- `_mapFormUpdateToJson` في الأسطر 353-364:
  - `uniqueId` يُقصّ في السطر 355.
  - `coDriverId` يُرسل دائمًا حتى لو كان `null` في السطر 356.
  - المقطورات تُحوّل إلى `{'trailerNumber': t}` في السطر 357.
  - وثائق الشحن تُحوّل إلى `{'documentNumber': d}` في الأسطر 358-360.
  - `notes` تُرسل فقط إذا كانت غير فارغة في الأسطر 361-362.
- `getForm` عند الأوفلاين يعيد `Right(null)` إذا لا يوجد كاش في السطر 373.
- `getForm` عند الأونلاين يكتب الكاش بلا `await` وبلا `unawaited` في السطر 390، فأي استثناء غير متزامن لا يُلتقط.
- `_parseDailyFormData` يحتوي دالة محلية مسماة `extractList` في الأسطر 398-402:
  - تعيد القائمة كما هي إذا كانت `List`.
  - تقسم النص على `,` إذا كان نصًا غير فارغ.
  - تعيد قائمة فارغة لغير ذلك.
- `extractList` لا تُسقط القيمة `'None'`: `_parseDailyFormData` يرشّح الفراغ فقط في السطرين 410 و419. أي أن القيمة `'None'` التي يكتبها `joinFormList` في `daily_form_rules.dart:26` تصبح مقطورة أو وثيقة باسم `None` عند قراءتها من الخادم. هذا يخالف قاعدة domain التي تعتبر `None` قيمة غياب.
- `_parseDailyFormData` يقرأ `vehicle.identifier` ثم `vehicle.uniqueId` ثم `data.uniqueId` في الأسطر 438-441، ويقرأ `vehicle.name` ثم `vehicle.displayName` ثم `data.vehicleName` في الأسطر 442-445. أي أنه يدعم الشكل المتداخل الذي لا يدعمه `DailyLogDto`.
- `saveForm`:
  - يرفض `vehicleUniqueId` الفارغ قبل أي أثر جانبي في الأسطر 466-470.
  - يكتب الكاش في السطر 473 ويحدّث اكتمال اللقطة في الأسطر 476-482 **قبل** أي نداء شبكي.
  - `hasVehicle` في السطر 474 صحيح دائمًا بعد البوابة، لأن البوابة منعت الفراغ.
  - الاكتمال المحلي يُحسب `hasVehicle && hasDocs` في السطر 480، أي أن غياب وثائق الشحن يجعل السجل غير مكتمل في الكاش.
  - عند الأوفلاين يدرج `daily_log_form` في الأسطر 485-500 ويعيد `FormSaveResult.offline()` في السطر 500.
  - عند الأونلاين يقرأ الاستجابة عبر `SavedFormDto` في السطر 516، ويعيد تحديث الاكتمال إذا كانت `complete` غير null في الأسطر 517-523، ثم يعيد `FormSaveResult.online(read)` في السطر 524.
  - إذا فشل الحفظ الأونلاين يبقى الكاش مكتوبًا بحالة مكتملة محتملة، لأن الكتابة سبقت النداء.
- `getReadiness` عند الأوفلاين:
  - يشتق الحالة من السجل المخزّن في الأسطر 536-549.
  - يكتب `readinessStatus` بالقيمتين `'READY'` و`'NOT_READY'` في السطر 556.
  - يكتب متطلبًا ناقصًا إنجليزيًا ثابتًا `'The daily form is not complete for this day.'` في السطر 559، بينما مسار الأونلاين يمرر رموز الخادم كما هي.
  - يكتب `legalStatement: ''` في السطر 561 اعتمادًا على أن الواجهة ستستخدم النص المترجم.
  - يكتب `availableActions: const ['CERTIFY']` في السطر 562 حتى عندما تكون الحالة `NOT_READY`، أي أن الإجراء المتاح يناقض الحالة المانعة.
- `getReadiness` عند الأونلاين يمرر كل الحقول من الخادم في الأسطر 571-593، ويحوّل التعديلات المعلقة في الأسطر 581-592.
- `getCertifyState` عند الأوفلاين يعيد `NetworkFailure` في السطر 604.
- `getCertifyState` يفحص 404 و405 قبل `executeWithHandling` في الأسطر 606-614، ويعيد `ServerFailure(message: 'certify_state_unavailable', statusCode: 404)` في السطر 612.
- `certifyLog` يرفض `driverId <= 0` برسالة إنجليزية ثابتة `'Driver session is missing'` في السطرين 646-648.
- `certifyLog` عند الأوفلاين يدرج `certification` في الطابور في الأسطر 651-666 ثم يعيد `Right(true)` في السطر 667، أي نجاحًا قبل تأكيد الخادم.
- `certifyLog` عند الأونلاين يعيد `data.isCertified` من استجابة الخادم في السطر 679.
- `respondToCarrierEdit` في الأسطر 685-703 لا يفحص الشبكة ولا يدرج في الطابور، فالردّ يُفقد عند الأوفلاين ويظهر كفشل من `executeWithHandling`.
- `reassignDriving` في الأسطر 706-724 لا يفحص الشبكة ولا يدرج في الطابور، ولا يوجد له أي مستدعٍ في `lib`.
- `getPeriods` يمرر `_timeAuthority.nowUtc().toLocal()` كمرجع للوقت في السطر 730.
- `getAuditEntries` في الأسطر 752-757 لا مستدعٍ له، بينما `audit_trail_provider.dart:10` يستخدم `getRecentAuditEntries`.
- دوال المسودة تتجاوز `executeWithHandling`:
  - `saveDraftSignature` في الأسطر 770-772.
  - `getDraftSignature` في الأسطر 775-777.
  - `deleteDraftSignature` في الأسطر 780-782.
  - النتيجة أن أي استثناء محلي يخرج من المستودع مباشرة، خلافًا لعقد `Either` في بقية الدوال.
- `DateFormat('yyyy-MM-dd')` مستخدم مرة واحدة في السطر 555.
- نصوص مكتوبة يدويًا: `'certify_state_unavailable'` في السطر 612، `'Driver session is missing'` في السطر 647، `'The daily form is not complete for this day.'` في السطر 559، `'CERTIFY'` في السطر 562، `'READY'` و`'NOT_READY'` في السطر 556، `'daily_log_form'` في السطر 488، `'duty_status'` في السطرين 215 و281، `'certification'` في السطر 654، `'MANUAL'` في الأسطر 222 و237 و287 و309.
- أرقام مكتوبة يدويًا: `statusCode: 404` في السطر 612، `size = 20` في السطر 69، `limit = 100` في السطر 761.
- دوال أطول من 40 سطرًا:
  - `getDailyLogs` من 66 إلى 120 بطول 55 سطرًا.
  - `updateEvent` من 247 إلى 341 بطول 95 سطرًا.
  - `_parseDailyFormData` من 397 إلى 456 بطول 60 سطرًا.
  - `saveForm` من 459 إلى 528 بطول 70 سطرًا.
  - `getReadiness` من 531 إلى 597 بطول 67 سطرًا.
  - `certifyLog` من 640 إلى 682 بطول 43 سطرًا.
- Widget `build` أطول من 80 سطرًا: لا ينطبق.
- `ref.read` أو `ref.watch`: لا يوجد في هذا الملف.
- `Navigator` أو `showDialog` أو `showModalBottomSheet`: لا يوجد.
- تكرار شبه حرفي:
  - منطق البحث عن سجل داخل لقطة مخزّنة يتكرر في `getLogById` (الأسطر 134-146) و`getReadiness` (الأسطر 538-548).
  - منطق بناء `LogReadiness` يتكرر بين مسار الأوفلاين (الأسطر 550-563) ومسار الأونلاين (الأسطر 571-593) بصيغتين مختلفتين.

---

## تغطية الاختبارات لطبقة `data`

| الملف | الأسطر | ما يغطيه فعلًا |
|---|---:|---|
| `test/features/logs/data/codecs/signature_draft_codec_test.dart` | 39 | جولة ترميز وفك ترميز بنقطتين مع النوع والضغط، والقائمة الفارغة، و`null`، والنص الفارغ، و`invalid-json`، والخريطة `{}` |
| `test/features/logs/data/log_event_model_test.dart` | 82 | `DRIVING` مع `durationMinutes` و`odometerKm` و`origin`، وست حالات wire، و`origin: DRIVER` مع `locationText`، وجولة `toJson` ثم `fromJson` |
| `test/features/logs/data/models/daily_log_dto_test.dart` | 186 | `logDate` الصالح والمفقود والتالف، وحقول التفاصيل، وصف القائمة بلا تفاصيل، و`COMPLETE` و`DRAFT`، و`formIndicator` بالأخضر والأحمر، و`READY` و`REVOKED` و`INVALID` |
| `test/features/logs/data/log_repository_offline_test.dart` | 310 | `getDailyLogs` أونلاين وأوفلاين وفشل الكاش، و`getEvents` أونلاين وأوفلاين ودمج المكرر، و`getReadiness` أوفلاين بحالات READY وNOT_READY وغياب اللقطة |
| `test/features/logs/data/repositories/log_repository_impl_form_test.dart` | 287 | `getForm` بصيغة الوثيقة وبصيغة `Swagger 05.3` وبجسم فارغ وبخطأ خادم، و`saveForm` أونلاين وأوفلاين ورفض `uniqueId` الفارغ |
| `test/features/logs/saved_form_status_test.dart` | 27 | `SavedFormDto.fromJson` مع `COMPLETED` و`INCOMPLETE` وغياب الحالة |

ملاحظات التغطية:

- `LogLocalDataSourceImpl` لا يُختبر مباشرة إلا في سطر واحد: `test/audit_task06/driver_isolation_test.dart:60` يستدعي `clearPeriods()`. بقية الاختبارات تستخدم `Mock` على الواجهة.
- لا اختبار لـ`getDailyLogs` عندما يفشل الخادم أو عندما تكون الصفحة أكبر من صفر.
- لا اختبار لدلالة `hasNext` في مسار الكاش.
- لا اختبار لمسار `getEvents` عندما يعيد الخادم فشلًا، وهو المسار الذي يخفي الخطأ.
- لا اختبار لـ`updateEvent` بمعرّف UUID ولا لمسار `Right(null)`.
- لا اختبار لـ`saveForm` عندما يفشل الحفظ الأونلاين بعد كتابة الكاش.
- لا اختبار لقيمة `availableActions` في مسار الجاهزية الأوفلاين.
- لا اختبار لدوال مسودة التوقيع الثلاث في المستودع.
- لا اختبار لـ`respondToCarrierEdit` ولا `certifyLog` ولا `reassignDriving` على مستوى المستودع.
- لا اختبار لقيمة `'None'` في `_parseDailyFormData`.

---

## الملاحظات الأولية (آراء — تُجمع هنا فقط)

هذه ليست الخلاصة النهائية؛ الخلاصة النهائية مؤجلة إلى `06_summary.md` بعد اكتمال طبقة `presentation`. هذه ملاحظات `data` فقط.

| المشكلة | الدليل (ملف:سطر) | التصنيف | الخطورة | نطاق التأثير |
|---|---|---|---|---|
| عقد تخزين محلي بـ22 دالة يخلط سبعة اختصاصات | `log_local_data_source.dart:13-64` | معمارية | عالية | `LogRepositoryImpl`، كل الاختبارات التي تستخدم `Mock` على الواجهة، وأي إعادة هيكلة للتخزين |
| فشل الخادم في `getEvents` يتحول إلى بيانات كاش ناجحة | `log_repository_impl.dart:166-178` | إدارة أخطاء/جودة بيانات | عالية | شاشة الأحداث، شاشة التفاصيل، أي قرار يعتمد على حداثة البيانات |
| `saveForm` يكتب الكاش ويعلّم الاكتمال قبل تأكيد الخادم | `log_repository_impl.dart:473-482` | سلامة بيانات | عالية | قائمة السجلات، شاشة التفاصيل، الجاهزية الأوفلاين، الاعتماد |
| `certifyLog` الأوفلاين يعيد `Right(true)` قبل أي تأكيد | `log_repository_impl.dart:649-667` | امتثال/سلامة بيانات | عالية | شاشة الاعتماد، سجل التدقيق، تقارير FMCSA |
| `updateEvent` بمعرّف UUID ينشئ حدثًا جديدًا بدل تعديل | `log_repository_impl.dart:253`، `log_repository_impl.dart:305-311` | منطق أعمال | عالية | تعديل الأحداث المسجلة محليًا، سجل الحالات، احتساب ساعات القيادة |
| عنصر تالف واحد يُسقط كل يوم من الأحداث والفترات والتدقيق | `log_local_data_source.dart:277-286` | جودة بيانات | عالية | الأحداث المحلية، فترات HOS، سجل التدقيق |
| نموذج data يرث كيان domain | `log_model.dart:5` | معمارية | متوسطة | `DailyLogDto`، `LogRepositoryImpl`، أي فصل مستقبلي للطبقتين |
| `LogLocalDataSourceImpl` يعتمد على صناديق Hive عامة بلا حقن | `log_local_data_source.dart:67-71` | اختبار/معمارية | متوسطة | كل اختبارات التخزين، إمكانية استبدال التنفيذ |
| `logLocalDataSourceProvider` معرّف داخل ملف مصدر البيانات | `log_local_data_source.dart:467` | معمارية/DI | منخفضة | `app.dart`، `sync_providers.dart` |
| `app.dart` و`sync_providers.dart` يستوردان data من خارج الميزة | `app.dart:20`، `sync_providers.dart:9` | حدود | عالية | أي إعادة هيكلة لطبقة data في logs |
| `hos` و`inspection` يستوردان `log_repository_providers.dart` | `duty_period_store_providers.dart:3`، `send_logs_page.dart:11` | حدود | عالية | `hos`، `inspection` |
| دالتان ميتتان في التخزين: `saveSignature` و`getSignature` | `log_local_data_source.dart:37-38`، `:109-120` | جودة | منخفضة | العقد والتنفيذ فقط |
| `LogEventModel.fromEntity` ميتة | `log_model.dart:143-157` | جودة | منخفضة | `log_model.dart` فقط |
| `LogEventModel.toJson` مستخدمة في الاختبار فقط | `log_model.dart:131-141` | جودة | منخفضة | `log_model.dart` والاختبار |
| `LogRepositoryImpl.getAuditEntries` بلا مستدعٍ | `log_repository_impl.dart:752-757` | جودة | منخفضة | العقد والمستودع |
| `LogRepositoryImpl.reassignDriving` بلا مستدعٍ | `log_repository_impl.dart:706-724` | جودة | منخفضة | العقد والمستودع |
| مفتاح `isFormComplete` يُكتب في الكاش ولا يُقرأ | `log_local_data_source.dart:188` مقابل `daily_log_dto.dart:198` | جودة | منخفضة | الكاش المحلي |
| `extractList` تُبقي `'None'` كمقطورة | `log_repository_impl.dart:398-420` مقابل `daily_form_rules.dart:26` | عقد/اتساق | متوسطة | صفحة المقطورات، صفحة وثائق الشحن، حفظ النموذج |
| الجاهزية الأوفلاين تعرض `CERTIFY` مع `NOT_READY` | `log_repository_impl.dart:556-562` | منطق أعمال/واجهة | متوسطة | شاشة الاعتماد |
| الجاهزية الأوفلاين تكتب متطلبًا إنجليزيًا ثابتًا | `log_repository_impl.dart:559` | توطين | متوسطة | شاشة الاعتماد بالعربية والإسبانية |
| نصوص إنجليزية ثابتة في أخطاء المستودع | `log_repository_impl.dart:612`، `:647` | توطين | منخفضة | رسائل الخطأ |
| دوال المسودة تتجاوز `Either` وتترك الاستثناءات تخرج | `log_repository_impl.dart:770-782` | إدارة أخطاء | متوسطة | `log_draft_signature_provider`، شاشة الاعتماد |
| `updateEvent` الأوفلاين يعيد نجاحًا مهما كانت نتيجة الكتابة | `log_repository_impl.dart:271-276` | إدارة أخطاء | متوسطة | تعديل الأحداث أوفلاين |
| `getForm` يكتب الكاش بلا انتظار وبلا التقاط | `log_repository_impl.dart:390` | جودة | منخفضة | النموذج اليومي |
| `DailyLogDto` يخترع `id = 0` و`uniqueId = ''` و`false` | `daily_log_dto.dart:122-140` | جودة بيانات | متوسطة | `logs_provider`، أي شاشة تعتمد على المعرّف |
| `DailyLogDto` لا يقرأ `vehicle.name` المتداخل | `daily_log_dto.dart:142` مقابل `log_repository_impl.dart:442-445` | اتساق عقد | متوسطة | اسم المركبة في القائمة والتفاصيل |
| الحالة غير المعروفة تصبح `OFF` | `log_model.dart:47-49` مع `duty_status_code.dart:49-52` | امتثال/عرض | متوسطة | الرسم البياني، الأحداث، الاحتساب |
| `toJson` يفقد أربعة حقول في الجولة | `log_model.dart:131-141` | جودة بيانات | منخفضة | الشكل المحلي المضغوط |
| `_readDurationSeconds` يفضّل صفرًا على قيمة صحيحة | `log_local_data_source.dart:330-333` | منطق بيانات | منخفضة | الأحداث المحلية |
| `savePeriod` يضيف تكرارًا بلا فحص | `log_local_data_source.dart:409-422` | جودة بيانات | متوسطة | فترات HOS |
| `getRecentAuditEntries` يمسح كل الصندوق ويرتب في الذاكرة | `log_local_data_source.dart:445-464` | أداء/توسع | متوسطة | سجل التدقيق مع تراكم الأيام |
| `getDailyLogs` الأوفلاين يوحي بانتهاء الصفحات | `log_repository_impl.dart:74-79` | واجهة/عقد | منخفضة | قائمة السجلات أوفلاين |
| `respondToCarrierEdit` بلا مسار أوفلاين | `log_repository_impl.dart:685-703` | وظيفة/مرونة | متوسطة | شاشة الاعتماد أوفلاين |

## ما يمكن إصلاحه بأمان الآن دون كسر أي شيء

1. حذف `saveSignature` و`getSignature` من عقد `LogLocalDataSource` وتنفيذه: لا مستدعي في `lib` ولا `test`، والدليل بحث كامل أعاد تعريفين فقط.
2. حذف `LogEventModel.fromEntity`: لا مستدعي في `lib` ولا `test`.
3. إضافة `unawaited` والتقاط للخطأ في `cacheDailyForm` داخل `getForm`: تغيير لا يمس أي سلوك ظاهر.
4. حذف المتغير `hasVehicle` واستخدام `true` مباشرة: قيمته صحيحة دائمًا بعد بوابة السطر 466.
5. إضافة اختبارات للحالات غير المغطاة دون تغيير المصدر: فشل `getEvents`، مسار UUID في `updateEvent`، فشل `saveForm` بعد الكاش، `availableActions` في الجاهزية الأوفلاين.
6. توثيق أن `toJson` لا يمثل جولة كاملة، أو إضافة الحقول الأربعة الناقصة: لا مستدعي إنتاجي لـ`toJson`.

## ما يحتاج قرارًا قبل التنفيذ

1. **تقسيم عقد التخزين:** هل نقسم `LogLocalDataSource` إلى `LogEventStore` و`DutyPeriodStore` و`AuditStore` و`LogSnapshotStore` و`DailyFormStore` و`SignatureStore`؟ كل قسم سيغيّر `LogRepositoryImpl` والاختبارات.
2. **مصير `getAuditEntries` و`reassignDriving`:** هل نحذفهما من العقد أم نوصلهما بشاشة قائمة؟ حذفهما يمس `LogRepository` و`LogRepositoryImpl`.
3. **سلوك `updateEvent` بمعرّف UUID:** هل نفشل صراحةً، أم نرسل POST ونقبل الحدث الجديد، أم نحتفظ بمعرّف محلي ونربطه بعد المزامنة؟ الخيار الثالث يمس طابور المزامنة.
4. **`saveForm` والكاش قبل الشبكة:** هل نؤخر تعليم الاكتمال حتى نجاح الخادم، أم نُبقي السلوك المتسامح مع الأوفلاين ونميّز الحالة في الواجهة؟
5. **`certifyLog` الأوفلاين:** هل نعيد حالة «معلّق» بدل `true`، أم نُبقي النجاح التفاؤلي مع علامة غير معتمد في الواجهة؟
6. **`getEvents` وفشل الخادم:** هل نُظهر الفشل، أم نستخدم الكاش مع علامة «بيانات قديمة»؟
7. **`_getListFromBox`:** هل نتجاوز العنصر التالف ونحتفظ بالبقية، أم نفشل اليوم كاملًا؟ الخيار الأول يغيّر دلالة الفشل الحالية.
8. **قيمة `'None'`:** هل نستخدم `splitFormList` من domain داخل data، أم نُبقي التصفية المحلية؟ استخدام domain من data يعكس اتجاه الاعتماد الحالي.
9. **الجاهزية الأوفلاين:** هل نولّد `availableActions` من الحالة بدل ثابت `['CERTIFY']`؟
10. **ملكية النصوص:** هل تبقى رسائل `certify_state_unavailable` و`Driver session is missing` مفاتيح ترجمة أم نصوصًا؟
11. **صناديق Hive:** هل نحقن `Box<String>` عبر constructor لتسهيل الاختبار، أم نُبقي الاعتماد العام؟

## أسئلة مفتوحة

1. هل `saveSignature` و`getSignature` مخصصان لشاشة توقيع مستقبلية أم بقايا تنفيذ؟
2. هل يستخدم أي شاشة `getAuditEntries` ليوم محدد، أم أن `getRecentAuditEntries` يكفي؟
3. هل `reassignDriving` مطلوب في واجهة قادمة أم بقايا عقد؟
4. هل يمكن أن يصل حدث بمعرّف UUID إلى `updateEvent` في الإنتاج، أم أن المسار محجوب في الواجهة؟
5. هل يعتبر الخادم `None` قيمة صالحة في `trailers` أو `shippingDocuments`؟
6. هل `certificationStatus` يمكن أن يعيد `PENDING` أو قيمة غير المعروفة في الخريطة الحالية؟
7. هل يجب أن يظهر خطأ الخادم في شاشة الأحداث، أم أن الكاش هو السلوك المقصود؟
8. هل `daily_log_form` في طابور المزامنة يعيد تشغيل الحفظ كاملًا أم يدمج الحقول؟
9. هل `ownerDriverId` متاح دائمًا عند الحفظ، أم أن `null` حالة مقصودة؟

## ترتيب مقترح للتنفيذ

1. **تثبيت السلوك باختبارات:** إضافة اختبارات للمسارات العشرة غير المغطاة قبل أي تعديل.
2. **إزالة الميت الآمن:** `saveSignature`، `getSignature`، `fromEntity`، و`hasVehicle`.
3. **توحيد التعامل مع الأخطاء:** دوال المسودة، وكتابة الكاش في `getForm`، وإعادة قيمة `updateEvent` الأوفلاين.
4. **إظهار فشل الخادم في `getEvents`:** أصغر تغيير يمنع عرض بيانات قديمة كأنها حديثة.
5. **إصلاح سلامة الكاش في `saveForm`:** فصل «محفوظ محليًا» عن «مكتمل على الخادم».
6. **حسم `certifyLog` الأوفلاين:** لأنه يمس امتثالًا قانونيًا قبل كونه تقنيًا.
7. **إصلاح `_getListFromBox`:** لأن فقدان يوم كامل أخطر من فشل صريح.
8. **تقسيم عقد التخزين:** بعد تثبيت السلوك وإزالة الميت.
9. **معالجة الحدود الخارجية:** `app.dart` و`sync_providers.dart` و`hos` و`inspection`، لأنها تحدد ما يمكن تغييره لاحقًا.
10. **تحسينات الاتساق:** `'None'`، والحالة غير المعروفة، واسم المركبة المتداخل، والجاهزية الأوفلاين.


