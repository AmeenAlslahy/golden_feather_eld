# EC-0.2a — تطبيق عزل كاش `InspectionRepositoryImpl`

**الحالة: مُنفَّذ ومتحقَّق منه.**
**النطاق: ملف إنتاج واحد + ملف اختبار واحد.** لم يُنفَّذ أي عقد آخر.

---

## 1. السبب الجذري — مُتحقَّق مقابل الشيفرة الحالية

### 1.1 الثغرة المؤكَّدة

قبل الإصلاح، `lib/features/inspection/data/repositories/inspection_repository_impl.dart`:

```dart
static DotInspectionScreen? _cachedScreen;
static List<DotInspectionCycleDay> _cachedCycle = [];
static final Map<String, DotInspectionLog> _cachedLogs = {};
static InformationPacketView? _cachedPacket;
```

ثلاثة أخطاء مستقلة تتراكب:

| # | الخطأ | الدليل |
|---|---|---|
| **1** | `static` = نطاق **العملية** | لا إبطال، والمزوّد `Provider` دائم غير `autoDispose` |
| **2** | المفتاح **بلا `driverId`** | السطر 78: `final key = date != null ? '...Y-M-D' : 'latest';` رغم أن `getLogs({required DriverId driverId})` يستقبله |
| **3** | هبوط **«أي سجل»** | السطر 92: `if (_cachedLogs.isNotEmpty) return Right(_cachedLogs.values.first);` |

### 1.2 ناقل الكارثة — ملف FMCSA

```dart
// sendLogs(...) → offline branch
final filePath = await FmcsaEldOutputGenerator.generateAndSave(
  screen: _cachedScreen,          // ← غير مقيّد بسائق
  cycleDays: _cachedCycle,        // ← غير مقيّد بسائق
  logs: _cachedLogs,              // ← كل السجلات، كل السائقين
  outputFileComment: comment,
  fallbackDriverId: driverId.value.toString(),   // السائق الحالي
);
```

والمولّد يشتقّ **هوية الملف** من الكاش قبل الـ fallback:

```dart
// fmcsa_eld_output_generator.dart:75-79
final driverIdStr = screen?.driverId.value.toString() ??
    firstLog?.driverId.value.toString() ??
    firstCycle?.driverId.value.toString() ??
    fallbackDriverId ?? '';
```

عمود `DriverID` في السطر `1,...` من ملف CSV **-legally** كان يأتي من سائق آخر.

### 1.3 البرهان التشغيلي (قبل الإصلاح)

```
TEST 2: Expected <101>  Actual <202>   ← السائق B استلم سجل السائق A
TEST 6: Expected <202>  Actual <101>   ← العكس عند تغيّر ترتيب الإنجاز
TEST 4: Expected false   Actual true    ← هوية A داخل ملف B
```

ومحتوى الملف المُنتج قبل الإصلاح (مأخوذ حرفياً من المُشغّل):

```
1,REG-101,ELD-101,VEH-101,VIN-101,"carrier-101",USDOT-101,"driver-101","driver-101",101,"","","",,101026,170139,"B roadside"
                                                          ^^^^ DriverID = 101، والمطلوب 202
```

### 1.4 اكتشاف حاسم أثناء التحليل

الكايشة **لا تحتاج مفاتيح جديدة** لأن الكيانات نفسها تحمل مالكها:

```dart
// lib/domain/inspection/dot_inspection.dart
DotInspectionScreen     → required DriverId driverId   (سطر 23)
DotInspectionCycleDay   → required DriverId driverId   (سطر 46)
DotInspectionLog        → required DriverId driverId   (سطر 86)
```

**لكن** `InformationPacketView` (`inspection_transfer.dart:42`) **لا يحمل** `driverId` — ولهذا نحتاج وسم مالك خارجي لهذه الشقّة وحدها.

> **قرار تصميمي موثَّق:** اعتمدت على **وسم المالك المُمرَّر من المتصل** لا على `entity.driverId`، لسبب مُتحقَّق منه:
> ```dart
> // dot_inspection_mapper.dart:19,43,78
> driverId: DriverId(JsonPrimitives.asInt(json['driver']?['id'])),
> // json_primitives.dart:21-26  →  fallback = 0
> ```
> أي أن `driverId` القادمة من الخادم قد تكون `DriverId(0)`. الاعتماد عليها للتحقق كان **سيُفشل توليد ملف FMCSA بالكامل** في الإنتاج — انحدار وظيفي أسوأ من الثغرة. هكذا كان سيحدث.

---

## 2. الملفات المُغيَّرة

| الملف | النوع | الأسطر |
|---|---|---|
| `lib/features/inspection/data/repositories/inspection_repository_impl.dart` | إنتاج | **+92 / −19** |
| `test/features/inspection/data/repositories/inspection_repository_isolation_test.dart` | اختبار جديد | 474 |

**لم يتغيّر:** أي عقد API، أي واجهة نطاق، المولّد، المزوّدات، أي ملف مولّد، أي ملف آخر في `lib/`.

---

## 3. الحل المختار ولماذا

> **لم أُطبِّق الحل الثلاثي المقترح في التدقيق آلياً.** التحليل الفعلي أثبت أن متطلبين من الثلاثة غير كافيين/غير لازمين:

### القواعد المنفَّذة

| # | القاعدة | السبب |
|---|---|---|
| **1** | الكاش **على مستوى الكائن** لا الصنف | `static` يعبر حدود الجلسات والأمثلة |
| **2** | ختم **جيل الجلسة** عند البناء + `_dropCacheIfSessionChanged()` قبل كل عملية | الكائن وحده لا يُبطَل عند تغيّر الهوية، والمزوّد غير `autoDispose` |
| **3** | **وسم مالك** لكل شقّة، تُقارن **بصرامة** بماطلبه المتصل | داخل الجلسة الواحدية يمكن تبديل السائق الرئيسي (`switchPrimaryDriver` موجود في العقد) — فالملكية **ضرورية** لا اختيارية |
| **4** | في مسار FMCSA: **لا يمرّ إلا المُثبت** | تطبيق صريح لمبدأ «افشل بأمان» |

### لماذا صбира�� `SessionEpoch.current` داخل المستودع بدل إعادة بناء المزوّد

الخيار البديل كان `ref.watch(sessionEpochProvider)` في `inspection_repository_providers.dart`.

**رُفض لأسباب مقيسة:**
1. `sessionEpochProvider` معرَّف في `features/auth/presentation/providers/` — استيراده من `data/providers/` **انقلاب طبقي جديد** (النمط نفسه الذي رصده التدقيق كـ DST-018).
2. `SessionEpoch.current` في `lib/core/session/` — استيراد `data ← core` **سليم**.
3. الختم الداخلي يعمل حتى لو أُعيد بناء المستودع أو لم يُعد — **دفاع أعمق**.

> **النتيجة: لم يُعدَّل ملف المزوّدات أصلاً.**

### لماذا استُبعد تبديل مفتاح `_cachedLogs` وحده

كان سيحلّ TEST 2 و 6 فقط. ويبقى:
- `_cachedScreen` و `_cachedCycle` بلا مفتاح ⇒ تسريبهما إلى `sendLogs` مستمر.
- تغيّر جلسة كامل يحمل كل المفاتيح.

### دالة المطابقة — صارمة عمداً

```dart
bool _ownedBy(int? cachedOwner, DriverId? requestedDriverId) =>
    cachedOwner == requestedDriverId?.value;
```

`null` (غير منسوب) **لا يطابق أي سائق محدَّد**. لو كانت `cachedOwner == null || owner == id` لأمكن لسائق B التقاط شاشة سائق A.

---

## 4. قواعد الملكية (Cache Ownership Rules)

| الكاشة | المالك يُسجَّل من | يُقدَّم لـ | عند `driverId == null` في الطلب |
|---|---|---|---|
| `_cachedScreen` | `getScreen(driverId)` | نفس السائق فقط | نعم (ملكية على مستوى الجلسة) |
| `_cachedCycle` | `getCycle(driverId)` | نفس السائق فقط | نعم |
| `_cachedPacket` | `getInformationPacket(driverId)` | نفس السائق فقط | نعم |
| `_cachedLogs` | **بادئة المفتاح** `'<driverId>:'` | نفس السائق + نفس التاريخ | — (المتطلب) |
| **الجميع** | يُسقط بالكامل عند `SessionEpoch` ≠ الختم | — | — |

### مسار FMCSA — القاعدة الأشد

```dart
final ownedLogs  = _logsOwnedBy(driverId);                       // بادئة '<driverId>:'
final ownedScreen = _ownedBy(_ownerScreen, driverId) ? _cachedScreen : null;
final ownedCycle  = _ownedBy(_ownerCycle,  driverId) ? _cachedCycle  : null;
```

**الأثر الجانبي المقبول والمقصود:** `getScreen()` يُستدعى **بدون** `driverId` (`dot_inspection_providers.dart:22`) ⇒ مالكه `null` ⇒ **لا يدخل** ملف FMCSA. المولّد يتراجع عندئذٍ إلى `firstLog` (مُفلتر بالسائق ⇒ هوية صحيحة) ثم `fallbackDriverId`.

**هذا تحسّن لا تراجع:** قبل الإصلاح كان الملف يُنسب لغير صاحبه.

### حذف البديل arbitré

```dart
- if (_cachedLogs.isNotEmpty) return Right(_cachedLogs.values.first);
```
حُذف كلياً — لا يوجد بديل «أي سجل» بعد الآن.

---

## 5. اختبارات الانحدار المضافة

`test/features/inspection/data/repositories/inspection_repository_isolation_test.dart` — 6 اختبارات.

| الاختبار | السيناريو | قبل | بعد |
|---|---|---|---|
| **TEST 1** | A يحمّل، B يطلب non-online | ❌ **فشل** | ✅ نجاح |
| **TEST 2** | سائقان، نفس التاريخ | ❌ **فشل** (`101` ↔ `202`) | ✅ نجاح |
| **TEST 3** | تغيّر `SessionEpoch` | ❌ **فشل** | ✅ نجاح |
| **TEST 4** | ملف FMCSA لسائق B | ❌ **فشل** | ✅ نجاح |
| **TEST 5** | نفس السائق non-online (حفظ سلوك) | ✅ نجاح | ✅ نجاح |
| **TEST 6** | طلبان متداخلان، ترتيب إنجاز معكوس | ❌ **فشل** (`101` ↔ `202`) | ✅ نجاح |

### كيف حاكيت القواعد المطلوبة

| القاعدة | التنفيذ |
|---|---|
| «ي��بح أثناء التعبئة، يفشل بعد» | `_ScriptedBackend.failAll` — **ليس** offline دائماً |
| **بيانات مميّزة لكل سائق** | كل حقل في الكيانات يحمل وسم السائق (`carrier-101`, `VIN-101`…) |
| **استجابات متأخرة للتزامن** | `Map<int, Completer<void>> gates` |

> **TEST 4 يفحص البيانات الفعلية لا حالة `Result`:** يقرأ ملف CSV من القرص، ويفحص عمود `DriverID` بفهرسة الحقل العاشر، ويفشل عند أي رمز مميّز لسائق A.

### تصحيح oligonucleotide أثناء التطوير

التأكيد الأول كان `expect(csv.contains('101'), isFalse)` — وفشل **خطأً** لأن تاريخ الملف `MMddyy` = `101026`. استُبدل بتأكيدات رموز مُميَّزة (`carrier-101`, `VIN-101`, …) وفحص العمود بفهرسته. الاختبار كان يمر على كود نظيف لسبب خاطئ — وهذا خطير.

---

## 6. الاختبارات الفاشلة قبل الإصلاح — الدليل

أُعيد تشغيل نفس ملف الاختبار على نسخة **HEAD الأصلية** من المستودع (بلا أي أمر git مدمر — استُخرج المحتوى بـ `git show` وأُعيدت الكتابة، ثم أُعيد الإصلاح):

```
00:03 +0 -1: TEST 1: driver B offline never receives driver A cached inspection data [E]
00:03 +0 -2: TEST 2: two drivers requesting the same date keep separate records [E]
00:03 +0 -3: TEST 3: data cached in a previous session epoch is never returned [E]
00:03 +0 -4: TEST 4: FMCSA generation for driver B never embeds driver A data [E]
00:03 +1 -5: TEST 6: overlapping requests for different drivers stay isolated [E]
00:03 +1 -5: Some tests failed.
```

**5 من 6 تفشل**، وTEST 5 ينجح (وهو المطلوب — اختبار حفظ سلوك).
**بعد الإصلاح:** `00:03 +6: All tests passed!`

---

## 7. نتائج الاختبارات القائمة

### مجموعة التفتيش — مقارنة بالهوية لا بالعدد

| | قبل | بعد |
|---|---|---|
| **الإخفاقات** (بالمعرّف الكامل) | 5 | **5 — مطابقة حرفياً** |

```
M dot_inspection_page_test.dart: driver exit directly ends inspection, no server call
M send_logs_page_test.dart: a transport error never leaks raw text to the driver
M send_logs_page_test.dart: email mode: invalid address refused; valid → email endpoint
M send_logs_page_test.dart: send mode: valid comment → send-logs (WEB SERVICES default)
M send_logs_page_test.dart: server FAILED status is a refusal, not a success screen
```

`Compare-Object` على قائمتي الفشل: **الفرق الوحيد هو سطر الملخّص `Some tests failed.`**. لا إخفاق اختفى ولا ظهر.

### مجموعة الانحدار الأوسع (Phase-0 baseline)

```
flutter test test/features/session/ test/core/engine/tracking/... test/features/codriver/
            test/features/dvir/ test/backend/http/interceptors/ test/features/account/
```

**13 إخفاقاً — مطابقة تماماً لخط الأساس في `01_baseline.md`.**

**إخفاقات جديدة: صفر.**

---

## 8. نتائج التحليل الساكن

```
flutter analyze lib/features/inspection/ test/features/inspection/data/
→ No issues found! (ran in 37.4s)
```

ملف الإنتاج `inspection_repository_impl.dart` **صفر مشاكل** (فحص منفرد أولاً).

---

## 9. ملخص `git diff`

```diff
 lib/features/inspection/data/repositories/inspection_repository_impl.dart | 111 +++++++++++++++++----
 1 file changed, 92 insertions(+), 19 deletions(-)
```

### التحقق الحاسم — بصمات SHA-256 لكل ملفات `lib/`

| القياس | النتيجة |
|---|---|
| ملفات `lib/` **مُتغيّرة** | **1** |
| ملفات `lib/` **محذوفة** | **0** (الفرق المُبلَّغ هو تغيّر البصمة للملف نفسه) |
| `git status` — مُعدَّل | 63 → **64** (فرق = 1، ملفي) |
| `git status` — entries جديدة | `M lib/.../inspection_repository_impl.dart` و `?? test/features/inspection/data/` |

### تأكيد عدم المساس بالتعديلات القائمة

| الملف | كان مُعدَّلاً قبل؟ |
|---|---|
| `lib/backend/contracts/inspection_backend.dart` | **نعم** — ضمن الـ 63 الأصلية |
| `lib/l10n/*.arb` + `app_localizations*` | **نعم** — ضمن الـ 63 الأصلية |

`Compare-Object` بين `git status` قبل/بعد: **الإدخالات الجديدة = ملفاي فقط.**

### منفورات STAGE 5

| الفحص | النتيجة |
|---|---|
| ملفات غير مرتبطة تغيّرت؟ | **لا** — بصمة واحدة |
| تعديلات سابقة فُقدت؟ | **لا** — لا `checkout` ولا `reset` ولا `stash`؛ التعديلات تمّت على ملفات نظيفة فقط |
| عقد API تغيّر؟ | **لا** — `InspectionBackend` و`InspectionRepository` و`FmcsaEldOutputGenerator` **لم يُمس** |
| سلوك UI غير مرتبط؟ | **لا** |
| ملفات مولّدة؟ | **لا** — لم يُشغَّل `build_runner` |
| انقلابات معمارية جديدة؟ | **لا** — الاستيراد الجديد `core/session` من `data/` هو اتجاه سليم |

---

## 10. المخاطر المتبقية

| # | المخاطر | التقييم | الحالة |
|---|---|---|---|
| R-1 | **فقد بيانات offline شرعية**: السائق في ضعف تغطية يرى شاشة فارغة بدل آخر سجل | مؤكد | **مقبول** — في نظام امتثال، الصحة أهم من الراحة. الواجهة تتعامل مع `Left(NetworkFailure)` أصلاً عبر `EldRetryView` |
| R-2 | شاشة تفتيش غير مُسندة لا تدخل ملف FMCSA | مؤكد | **مقصود** — يفرض نسبةً صحيحة. فقدان محتمل لبيانات `carrierName` إذا لم يكن هناك سجل مُخزَّن |
| R-3 | `SessionEpoch` يُقزَم في الاختبار فقط؛ في الإنتاج يُدار من `AuthNotifier` | منخفض | **مُتحقَّق** — مُختبَر في `session_epoch_401_test.dart` و`auth_interceptor_epoch_test.dart` |
| R-4 | استدعاءات متزامنة لنفس السائق تكتب في نفس مفتاح الكاش | منخفض | **مقبول** — الكتابة الاخيرة تفوز؛ لا خلط بين سائقين |
| R-5 | 5 إخفاقات سابقة في `send_logs_page_test.dart` (StateError) | — | **خارج النطاق** — سابقة ومُوثَّقة، لم تتأثر |

### ما **لم** يُصلَح (خارج النطاق)

| العنصر | السبب |
|---|---|
| `JsonPrimitives.asInt` fallback `0` ⇒ `driverId` مُضلِّل | ملف مشترك في `backend/`, خارج EC-0.2a |
| `DotInspectionScreen.driverId` غير موثوق | يعتمد على استجابة الخادم |
| 4 إخفاقات في `send_logs_page_test.dart` | خلل قائم، غير متعلق بالكاش |

---

## 11. ملاحظات على العملية

**الانحرافات المسجَّلة:**
1. خطأ في أول صياغة للاختبار (`getOrNull` غير موجود في `fpdart 1.2.0`، وتلف ترميز أثناء تحرير برمجي) — أُصلح وأُعيد التحقق.
2. تأكيد TEST 4 الأول كان **خاطئ التمرير** (يطابق تاريخ الملف) — استُبدل قبل اعتماد النتيجة.
3. ملف خط الأساس `inspection_tests_before.txt` كُتب باسم ناقص حرف — أُعيدت تسميته.

**الأوامر المدمِّرة المستخدمة: صفر.** لم يُشغَّل `git reset` ولا `checkout` ولا `clean` ولا `stash` ولا `commit`. لم يُشغَّل `build_runner`.

---

## 12. الأثر مقابل فرضية التدقيق

| فرضية التدقيق (EC-0.2a) | النتيجة |
|---|---|
| `static` ⇒ instance | ✅ **مُثبت ضروري** |
| `driverId` في مفتاح `_cachedLogs` | ✅ **مُثبت، لكنه غير كافٍ وحده** |
| `ref.watch(sessionEpochProvider)` في المزوّد | ⚠️ **استُبدل** بـ `SessionEpoch.current` داخل المستودع (سببه: تفادي انقلاب طبقي + دفاع أعمق) |
| «كاش واحد يكفي» | ❌ **مُنتقض** — ثغرة `values.first` لم تكن في الفرضية |

> **الفرضية الثالثة كانت خاطئة الصلة، والفرضية الرابعة كانت ناقصة.** التنفيذ اتبع المتطلبات الفعلية كما مُوجَّه.