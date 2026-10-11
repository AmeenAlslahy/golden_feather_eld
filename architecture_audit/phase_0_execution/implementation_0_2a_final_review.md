# EC-0.2a — المراجعة الأمنية النهائية (Final Safety Review)

**التوصية: `REQUIRES_CORRECTION`**

> الفحص الذي طلبته كشف **عيبين حقيقيين في تنفيذي**، أحدهما يعيد فتح السيناريو الأعلى أولوية الذي وُجد أصلاً拖累و Dashboards — **ملف FMCSA لسائق B ما زال يحمل هوية السائق A**. لم أُصلح أياً منهما: هم خارج ما يمكن تطبيقه بأمان دون موافقة.

---

## 1. الاختبارات المُضافة في هذه المراجعة

ملف جديد: `test/features/inspection/data/repositories/inspection_repository_final_review_test.dart` (369 سطراً، 7 اختبارات).

| # | الاختبار | ما يفحصه | V |
|---|---|---|---|
| **V1-a** | استجابة متأخرة قبل تغيّر الجلسة لا تمسح كاش الجلسة الجديدة | استجابةasync معلّقة | 1 |
| **V1-b** | سجل من حقبة سابقة لا يدخل كاش الحقبة الجديدة | تلويث الكاش | 1 |
| **V1-c** | بيانات مخزَّنة **داخل** الحقبة الجديدة تبقى صالحة | إتاحية الكاش | 1 |
| **V2-a** | استجابة مُوسَمة لسائق آخر لا تُخزَّن تحت السائق الطالب | ملكية البيانات | 2 |
| **V2-b** | بيانات مُوسَمة خطأً لا تصل إلى ملف FMCSA | FMCSA + هوية | 2 |
| **V3-a** | مع **لا** بيانات مُتحقَّقة، الحقول الإلزامية غير فارغة | اكتمال الملف | 3 |
| **V3-b** | بالسجلات وحدها، الهوية صحيحة | هوية | 3 |
| **V3-c** | كاش مختلط الملاك لا يدمج الهويات | خلط | 3 |

---

## 2. النتائج الفعلية

```
V1-a  [E]  Expected: true   Actual: <false>
             "B's own E2 screen must survive A's stale response"

V1-b  ✅ PASS

V1-c  [E]  Expected: true   Actual: <false>
             (الكاش يُمسح عند كل نداء بعد تغيّر الحقبة)

V2-a  [E]  Expected: true   Actual: <false>
             "driver-101 data must not be served to driver 202"

V2-b  [E]  Expected: '202'  Actual: '101'
             "DriverID must be the requesting driver 202, got 101"

V3-a  [E]  Expected: non-empty  Actual: ''
             "ELDRegistrationId must not be blank"

V3-b  ✅ PASS
V3-c  ✅ PASS

النتيجة: +3 -5
```

### تصحيح على نفسي

أول تشغيل لـ V1-a **نجح زوراً**. السبب: لم أضبط `failAll`/`connected=false` قبل القراءة الأخيرة، فخرج الطلب للشبكة بدل الكاش — أي أن الاختبار لم يختبر ما زعم. بعد التصحيح became يفشل. أسجّله لأن اختباراً يمر على كود معطوب أخطر من اختبار فاشل.

---

## 3. الأدلة من الشيفرة

### 3.1 الفحص عند الدخول فقط — مؤكَّد بنيوياً

```dart
// inspection_repository_impl.dart
final int _sessionEpoch = SessionEpoch.current;   // 38 — final، لا يُسند إليه أبداً

void _dropCacheIfSessionChanged() {               // 58
  if (SessionEpoch.current == _sessionEpoch) return;
  _cachedScreen = null;  _ownerScreen = null;
  ...
}
```

مواضع الاستدعاء (كلها **قبل** `await`):

```
101, 127, 168, 245, 280   ← _dropCacheIfSessionChanged()
109/110, 136, 255/256, 288/289  ← الكتابة (بعد await)
```

**النتيجة:** استجابة تتأخر عبر حدّ `await` تكتب في كاش الحقبة الجديدة.

### 3.2 عطب إتاحية لم أنتبه إليه — `_sessionEpoch` لا يُحدَّث

لأن `_sessionEpoch` `final`، فإن `_dropCacheIfSessionChanged()` تُمسح الكاش في **كل نداء** بعد أول `bump` — لا مرة واحدة.

**وهذا يعني أن TEST 3 في مجموعة الأصلية كان ينجح لسبب خاطئ**: كان يتوقع `isLeft` بعد `bump`، وكان الكاش **ميتاً دائماً** لا «محذوفاً بحقبة قديمة».

> **است同学们**: بعد أي تسجيل خروج/دخول، وضع التفتيش الميداني **بلا كاش إطلاقاً**. أُصلح هذا؟ لا — مُوثَّق هنا كعيب.

### 3.3 ملكية الطلب ≠ ملكية البيانات — مؤكَّد

```dart
// 133-137
final result = await _backend.getLogs(driverId: driverId, date: date);
return result.fold(
  (error) => ...,
  (log) {
    _cachedLogs[key] = log;     // ← key = '202:latest' لاinspection driverId!
    return Right(log);
  },
);
```

أُختم `driverId.value` على **الطلب**، بينما كيان السجل قد يعلن `driverId = 101`. لا فحص أيّ.

والمولّد يثق به:

```dart
// fmcsa_eld_output_generator.dart:75-79
final driverIdStr = screen?.driverId.value.toString() ??
    firstLog?.driverId.value.toString() ??      // ← 101
    ...
    fallbackDriverId ?? '';                    // ← 202 لا يُستخدم
```

### 3.4 إكمال الملف — مؤكَّد

```dart
// sendLogs → offline
final ownedLogs = _logsOwnedBy(driverId);   // فارغة إن لم يوجد شيء
final ownedScreen = ... ;                    // null غالباً
final ownedCycle = ... ;                     // فارغة
FmcsaEldOutputGenerator.generateAndSave(...)  // ← ينتج ملفاً ويُرجع مساره
```

مع لا بيانات، النتيجة المُقاسة:

```
1,,,,,"",,"","",202,"",,"","",,101026,170139,"review"
```

`succeeds` ويُرجع `OFFLINE_GENERATED:<path>`، لكن `ELDRegistrationId`, `ELDIdentifier`, `VIN`, `USDOTNumber`, `DriverLastName`, `DriverFirstName` **كلها فارغة**. هذا **ليس ملف FMCSA صالحاً**.

---

## 4. المخاطر المؤكَّدة

| # | العيب | الشاهد | الأثر |
|---|---|---|---|
| **D1** | استجابة متأخرة **تمحو** كاش الحقبة الجديدة | V1-a | تدمير بيانات شرعية لسائق شرعي |
| **D2** | الكاش **ميت دائماً** بعد أي `bump` | V1-c | وضع التفتيش الميداني بلا كاش بعد كل دخول/خروج |
| **D3** | بيانات سائق آخر تُوسَم بملكية الطالب | V2-a | **تسريب بين سائقين** عبر offline |
| **D4** | ملف FMCSA لسائق B يحمل `DriverID=101` | V2-b | **وثيقة نظامية مزيّفة** — السيناريو الأعلى أولوية |
| **D5** | ملف FMCSA يُنتَج بحقول إلزامية فارغة ويُعلَن نجاحاً | V3-a | ملف غير صالح يُقدَّم للجهة التنظيمية |

> **D4 هو بالضبط ما وُجد في EC-0.2a ولم يُغلق.** الإصلاح الأولي أغلق **مصدر** التسرّب (كاش `static` غير مقيّد) لكنه لم يفرض **تحقّقاً** من الاستجابة نفسها.

---

## 5. المخاطر غير المُحلّة (خارج نطاق EC-0.2a)

| # | البند | السبب |
|---|---|---|
| U1 | `JsonPrimitives.asInt` fallback = `0` ⇒ `driverId` من الخادم قد تكون `0` | ملف مشترك في `backend/` |
| U2 | لا يوجد تحقق (توقيع/ICA) من أن استجابة الخادم تخصّ السائق المطلوب | **لا يدعمه العقد** |
| U3 | 5 إخفاقات سابقة في اختبارات التفتيش | خارج النطاق |
| U4 | `FmcsaEldOutputGenerator` لا يتحقق من الحقول الإلزامية | خارج النطاق |

---

## 6. قيود عقد الخادم — موثّقة لا مُختلَقة

| السؤال | الإجابة المُتحقَّق منها |
|---|---|
| هل يوفّر العقد وسم مالك في الاستجابة؟ | **نعم، نظرياً** — `DotInspectionScreen/CycleDay/Log` تحمل `required DriverId driverId` |
| هل هو موثوق؟ | **ليس مضموناً** — `dot_inspection_mapper.dart:19,43,78` يبنيه من `json['driver']?['id']` عبر `asInt` ذو fallback `0` |
| هل يوجد حقل مالك مستقل؟ | **لا** |
| هل يوفّر العقد آلية ownership check؟ | **لا** — لا `expectedOwnerDriverId` في `getScreen`/`getCycle`/`getLogs` (يوجد في `sendLogs`/`emailLogs` فقط) |

**الخلاصة:** العقد يوفّر **أدلّة** على الملكية لا **ضماناً**. التحقق ممكن بمقارنة `entity.driverId` بالطلب **عندما تكون موجبة**. أما `0` فهي «غير معروف» ولا تصلح دليلاً — وهذه حالة يجب توثيقها لا اختراع حكم لها.

---

## 7. قيود إخراج FMCSA — موثّقة

| البند | الحالة |
|---|---|
| الهوية الصحيحة | مضمونة فقط إذا كانت `firstLog` مملوكة ومُتحقَّقة — **وهي ليست مضمونة اليوم** (D4) |
| الحقول الإلزامية_line 1 | **فارغة عند غياب بيانات** (D5) |
| المصدر (provenance) | المولّد يخلط `screen` → `firstLog` → `firstCycle` → `fallback*` — **لا يوجد تتبع مصدر** |
| `DriverID` | يُؤخذ من السجل قبل `fallbackDriverId` — أي أن **بيانات الخادم تتفوق على هوية الطلب** |

> **لم أستطع التحقق من صلاحية قانونية كاملة**: `openapi.yaml` لا يوثّق مخطط ملف FMCSA، و`FmcsaEldOutputGenerator` يوثّق نفسه بـ «49 CFR Part 395 Appendix A» دون اختبار conformance. **لن أدّعي أن الملف صالح قانونياً.**

---

## 8. سلامة شجرة العمل — ✅

| الفحص | النتيجة |
|---|---|
| ملفات `lib/` مُتغيّرة منذ خط الأساس | **1** — `inspection_repository_impl.dart` فقط |
| **لم يُكتب أي ملف إنتاج** في هذه المراجعة | **نعم** — لم أستعمل `git checkout` ولا `reset` ولا `clean` ولا `stash` |
| commits | **0** — `HEAD` لا يزال `e113129` |
| `git status` delta | إدخالان جديدان فقط: الملف المُعدَّل + `?? test/features/inspection/data/` |
| التعديلات الـ 63 القائمة | **سليمة** |
| ملفات مولّدة | **لا شيء** |
| اختبارات جديدة | 2، كلها ضمن EC-0.2a |
| `flutter analyze` | **No issues found** |
| اختبارات EC-0.2a الأصلية | 6/6 ✅ (لم تتأثر) |
| خط أساس التفتيش | 5 إخفاقات — مطابقة |

---

## 9. أصغر تصحيح آمن لكل عيب

> **لم أُطبِّق أياً منها.** كل واحد يحتاج موافقتك.

### D1 + D2 — دالة واحدة

```dart
// بدل final يُقارن للأبد:
int _sessionEpoch = SessionEpoch.current;

/// true إذا الختم ما زال صالحاً. تُستدعى بعد كل await وقبل كل كتابة.
bool _sessionIsCurrent() {
  if (SessionEpoch.current == _sessionEpoch) return true;
  _cachedScreen = null; _ownerScreen = null;
  _cachedCycle = <DotInspectionCycleDay>[]; _ownerCycle = null;
  _cachedLogs.clear();
  _cachedPacket = null; _ownerPacket = null;
  _sessionEpoch = SessionEpoch.current;   // ← إعادة الختم: يمنع المسح المتكرر
  return false;
}
```

- **بعد `await` في كل `fold`**: `if (!_sessionIsCurrent()) return Left(...)` قبل الكتابة.
- **عند الدخول**: `if (!_sessionIsCurrent()) return Left(...)` أو استدعاؤها فقط.
- **الملفات**: 1. **السطور**: ~15.
- **الأثر**: D1 يُغلق، D2 يُغلق، TEST 3 الأصلي يبقى ناجحاً (لسبب صحيح هذه المرة).

**السياسة المقترحة للاستجابة المتأخرة**: تُعاد النتيجة للطاعي (بياناته) **ولا تُخزَّن**. هذا需要在 قرار منك: هل يُرجَع `Left` أم النتيجة دون تخزين؟

### D3 + D4 — تحقق قبل الختم

```dart
// دالة واحدة في المستودع
/// null = غير متحقق منه (لا يُستخدم كدليل)
bool? _verifiedOwner(DriverId? declared, DriverId requested) {
  if (declared == null || declared.value <= 0) return null;   // 0 = غير معروف
  return declared.value == requested.value;
}
```

- `0` ⇒ **غير موثّق** ⇒ لا يُخزَّن، ولا يُستخدم في FMCSA.
- مطابقة ⇒ يُخزَّن ويُستخدم.
- عدم مطابقة ⇒ **يُسقط بوضوح** (لا يُخزَّن، ويعيد `Left`) مع تسجيل `AppLogger.warning`.

> ⚠️ **شرط مسبق حاسم**: يجب تأكيد أن الخادم يُرجع `driver.id` في استجابات `GET /eld/dot-inspection/*`. إن لم يكن، **كل** البيانات تصبح «غير موثّقة» ⇒ **توليد FMCSA يتعطل كلياً**. **هذا يحتاج معرفة بالخدمة لا أملكها.**

### D5 — بوابة قبل التوليد

```dart
// في sendLogs → offline، قبل generateAndSave
if (ownedLogs.isEmpty && ownedScreen == null && ownedCycle == null) {
  return Left(ServerFailure(message: 'inspectionNoVerifiedData'));
}
```

أو بديل أوسط: التحقق من اكتمال الحقول الإلزامية بعد التوليد عبر قراءة الملف وحذفه عند النقص.

> ⚠️ **هذا يغيّر سلوكاً وظيفياً**: اليوم يُنتَج ملف ويُبلَّغ عنه نجاحاً؛ بعده يفشل. **يحتاج قرارك** لأن الواجهة تعرض `OFFLINE_GENERATED:<path>`.

---

## 10. التوصية

# `REQUIRES_CORRECTION`

**السبب**: العيب D4 يعيد فتح السيناريو الذي وُجد أصلاً — **ملف FMCSA officially مولَّد لسائق B يحمل `DriverID=101`**. تصنيفه «مُغلق» سيكون تضليلاً.

**نطاق التصحيح المطلوب**: ملف واحد (`inspection_repository_impl.dart`)، ~35 سطراً، مع اختبارات V1/V2/V3 كضمان.

**ما لا يلزم**: لا تغيير عقد، لا تغيير مولّد، لا ملفات أخرى، لا تغيير بنية معمارية.

**محجوب بقرار منك**: التحقق من D3 يعتمد على ما يُرجعه الخادم فعلياً. **إن كان `driver.id` غير موجود في الاستجابات، فالتصحيح D3 سيُعطّل توليد FMCSA بالكامل** — وهذا قرار مشروع لا هندسي.

**بانتظار قرارك.** لم أبدأ EC-0.2b.