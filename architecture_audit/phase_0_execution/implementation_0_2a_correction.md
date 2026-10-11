# EC-0.2a — التصحيح (Corrective Implementation)

**الحالة: `READY_FOR_TECHNICAL_REVIEW`**

> وُجدت العيوب الخمسة وأُصلحت كلها داخل النطاق المُصرَّح به: **ملف إنتاج واحد**.
> لم يُعدَّل أي عقد، أي DTO، أي مخطّط، أي كيان نطاقي، ولا بنية مصادقة.

---

## 1. الأسباب الجذرية المؤكَّدة

| # | السبب الجذري | الدليل البنيوي |
|---|---|---|
| **D1** | `_dropCacheIfSessionChanged()` تُستدعى **عند الدخول فقط**؛ الكتابة تقع بعد `await` بلا فحص | الاستدعاءات عند `101/127/168/245/280` والكتابات عند `109/136/255/288` (أرقام ما قبل التصحيح) |
| **D2** | `final int _sessionEpoch` لا يُسند إليه أبداً ⇒ الشرط `current == _sessionEpoch` يبقى خاطئاً **للأبد** ⇒ مسح عند كل نداء | `final` + لا يوجد أي إسناد لاحق |
| **D3** | وسم الملكية كان من **الطلب** لا من **البيانات**: `_cachedLogs[key] = log` بلا فحص `log.driverId` | المفتاح `'<driverId>:'` فقط |
| **D4** | المولّد يشتقّ `DriverID` من الشاشة ثم السجل قبل `fallbackDriverId` | `fmcsa_eld_output_generator.dart:75-79` |
| **D5** | لا بوابة بعد التوليد: `generateAndSave` يُرجع مساراً ويُبلَّغ عنه نجاحاً دائماً | `sendLogs → offline` |

---

## 2. التصحيح المطبَّق

### 2.1 PART 1 — أمان الجلسة

```dart
int _sessionEpoch = SessionEpoch.current;          // لم يعد final

void _adoptSessionIfChanged() {                     // مرة واحدة لكل انتقال
  final current = SessionEpoch.current;
  if (current == _sessionEpoch) return;
  _sessionEpoch = current;                          // ← التبني يوقف المسح المتكرر
  ... مسح الكاش ...
}

int _captureEpoch() => _sessionEpoch;               // عند بدء العملية
bool _isStale(int operationEpoch) =>                // بعد كل await
    SessionEpoch.current != operationEpoch;
```

**كل حدّ `await` فُحص** — لا مسار استثنائي:

| العملية | الفحص بعد `await` |
|---|---|
| `getCycle` | ✅ قبل `result.fold` |
| `getLogs` | ✅ قبل `result.fold` |
| `getInformationPacket` | ✅ قبل `result.fold` |
| `getScreen` | ✅ قبل `result.fold` |
| `sendLogs` (online) | ✅ قبل `result.fold` |
| `sendLogs` (offline) | ✅ قبل جمع المدخلات |

**السياسة المطبَّقة على نتيجة متقادمة**: تُعاد `Left(ServerFailure('inspectionStaleSession'))` — لا تخزين، ولا نجاح. (Property #4)

**عدم المسح المتكرر**: `_adoptSessionIfChanged()` تتبنّى الحقبة الجديدة، فتكاش البقاء داخل الحقبة (Property #6 + #7).

### 2.2 PART 2 — سياسة ملكية الخادم

مستويات **مفصولة صراحةً**:

| المفهوم | التعريف | الاستخدام |
|---|---|---|
| **ملكية الطلب** | `driverId` مرّره المتصل | وسم الكاش `_owner*` |
| **ملكية البيانات المُتحقَّق منها** | `record.driverId != null && > 0 && == المطلوب` | **الشرط الوحيد** لمسار FMCSA |

```dart
bool _acceptsDataFrom(DriverId? declared, DriverId? requested) {
  if (declared == null || declared.value <= 0) return true;  // غير معروف ≠ رفض
  if (requested == null) return true;
  return declared.value == requested.value;                    // تطابق ⇒ قبول
}

bool _isVerifiedFor(DriverId? declared, DriverId requested) =>
    declared != null && declared.value > 0 && declared.value == requested.value;
```

| حالة البيانات | التخزين | التقديم لسائق محدَّد | FMCSA |
|---|---|---|---|
| موجبة مطابقة | ✅ | ✅ | ✅ |
| **موجبة مختلفة** | ❌ **رفض** `inspectionOwnerMismatch` | ❌ | ❌ |
| **غير معروفة (0/مفقود)** | ✅ بوسم الطلب | ❌ | ❌ |

> **لم يُحوَّل «غير معروف» إلى «مُتحقَّق» أبداً** (Property صريحة في التوجيه).

### 2.3 PART 3 — بوابات FMCSA

**قبل التوليد:**
```dart
final ownedLogs = _logsOwnedBy(driverId);                  // مُتحقَّق لكل سجل
final ownedScreen = _isVerifiedFor(screen?.driverId, driverId) ? screen : null;
final ownedCycle  = _isVerifiedFor(..., driverId) ? cycle : null;

if (ownedScreen == null && ownedCycle == null && ownedLogs.isEmpty) {
  return const Left(ServerFailure(message: 'inspectionNoVerifiedData'));
}
```

**بعد التوليد** — «إنشاء الملف ليس دليلاً على صلاحيته»:
```dart
final problem = _invalidIdentifyingFields(filePath);
if (problem != null) {
  _deleteQuietly(filePath);                                // لا أثر متبقٍّ
  return const Left(ServerFailure(message: 'inspectionIncompleteOutput'));
}
```

الحقول المفحوصة في سطر النوع 1 (فهارس 1-4، 6-9): `ELDRegistrationId`, `ELDIdentifier`, `CMVPowerUnitNumber`, `VIN`, `USDOTNumber`, `DriverLastName`, `DriverFirstName`, `DriverID`.

---

## 3. سلوك دورة حياة الجلسة

```
┌─ E1 ────────────────────────────────┐
│  سجلات A تُخزَّن                    │
│  استجابة A معلّقة ────────────┐     │
└───────────────────────────────┼─────┘
                                │ SessionEpoch.bump()
                                ▼
┌─ E2 ────────────────────────────┼─────┐
│ _adoptSessionIfChanged():        │     │
│   يتبنّى 2 · يمسح كاش E1         │     │
│                                   ▼     │
│  سجلات B تُخزَّن                  استجابة A تعود
│                                   → _isStale(1) = true
│                                   → Left('inspectionStaleSession')
│                                   → لا كتابة  ✗ لا تمحو كاش B  ✓
└─────────────────────────────────────────┘
```

| الخاصية المطلوبة | الحالة |
|---|---|
| #1 التقاط `operationEpoch` | ✅ |
| #2 مقارنة بعد `await` | ✅ كل المسارات |
| #3 عدم تخزين نتائج حقبة أقدم | ✅ |
| #4 عدم إرجاع بيانات متقادمة كنجاح | ✅ `Left` |
| #5 المتقادم **لا يمحو** بيانات حقبة أحدث | ✅ (لا مسح في مسار التقادم) |
| #6 إبطال مرة لكل انتقال | ✅ `_adoptSessionIfChanged` تتبنّى |
| #7 بقاء بيانات الحقبة الحالية | ✅ مُثبت بـ V1-c و V4-b |
| #8 عزل الطلبات المتزامنة | ✅ مُثبت بـ TEST 6 و V4-a |

---

## 4.Partition 5 — نطاق

| الملف | الإجراء |
|---|---|
| `lib/features/inspection/data/repositories/inspection_repository_impl.dart` | **إنتاج — معدَّل (المصرَّح به)** |
| `test/.../inspection_repository_isolation_test.dart` | اختبار — معدَّل (المصرَّح به) |
| `test/.../inspection_repository_final_review_test.dart` | اختبار — معدَّل (المصرَّح به) |

**مُتحقَّق بالبصمات — لم يُمسّ:**
`InspectionBackend` · `InspectionRepository` · `FmcsaEldOutputGenerator` · `DotInspectionScreen/Log/CycleDay` · `inspection_mappers.dart` · أي ملف آخر في `lib/`.

---

## 5. الاختبارات — قبل وبعد

### 5.1 أخطاء توقّع مُوثَّقة قبل تعديل أي اختبار

> التوجيه: «لا تُضعَف التأكيدات لجعل الاختبارات تمر. إذا تعارض توقّع اختبار مع عقد خلفي مُتحقَّق منه، وثّق التعارض قبل تغيير الاختبار.»

| # | الاختبار | التعارض | القرار |
|---|---|---|---|
| **1** | **V1-a** | توقّع `staleResult.isRight()` — أي **تسليم بيانات متقادمة كنجاح** | التوجيه #4 يفرض العكس. حُوِّل إلى `isLeft` + `inspectionStaleSession`. **أقوى** |
| **2** | **V2-a** | توقّع `requested.isRight()` لردّ مُوسَم بسائق آخر | التوجيه: «موجبة مختلفة ⇒ ارفض». حُوِّل إلى `isLeft` + `inspectionOwnerMismatch`. **أقوى** |
| **3** | **V3-a** | توقّع **إنشاء ملف** رغم غياب بيانات مُتحقَّق منها | التوجيه PART 3: «أعِد Failure، ولا تُرجع `OFFLINE_GENERATED`». حُوِّل إلى: رفض + **غياب الأثر**. **أقوى** |
| **4** | **V2-b / TEST 4** | توقّع ملفاً لسائق B **لا يملك بيانات** | أُعيد بناء السيناريو: B يملك سجله، ثم يصل ردّ **مُسمَّم**. **أقوى** (يثبت الت是对的 + عدم التلويث) |

**لم يُضعَف أي تأكيد.** أربعة تعارضات، كلها لصالح صارم.

> خطأ بياناتfixture اكتُشف وأُصلح: أسماء السائقين كانت كلمة واحدة ⇒ `DriverLastName` فارغ ⇒ **البوابة رفضت الملف بشكل صحيح**. حُوِّلت إلى `driver-<id> Said`.

### 5.2 النتائج

| المجموعة | قبل التصحيح | بعد |
|---|---|---|
| `inspection_repository_isolation_test.dart` | 6/6 ✅ | **6/6 ✅** |
| `inspection_repository_final_review_test.dart` | 3 ✅ / **5 ❌** | **14 ✅ / 0 ❌** |
| **الإجمالي** | 9 ✅ / 5 ❌ | **20 ✅ / 0 ❌** |

**اختبارات V1/V2/V3 المطلوبة كلها تمرّ الآن** (V1-a/b/c · V2-a/b · V3-a/b/c).

### 5.3 الاختبارات المضافة (V4) — التغطية الناقصة المطلوبة

| الاختبار | التغطية المطلوبة |
|---|---|
| **V4-a** | حقبتا جلسة متداخلتان |
| **V4-b** | بقاء الكاش عبر نداءات متكررة داخل حقبة واحدة |
| **V4-c** | تعارض ملكية في **الشاشة** |
| **V4-d** | تعارض ملكية في **الدورة** |
| **V4-e** | هوية سائق **غير معروفة** — تُخزَّن ولا تُعدّ مُتحقَّقة، ولا تصل إلى ملف نظامي |

---

## 6. نتائج الاختبارات القائمة — مقارنة بالهوية

| | |
|---|---|
| اختبارات التفتيش القائمة | 5 إخفاقات — **مطابقة حرفياً** بخط الأساس |
| خط أساس Phase-0 الأوسع (13) | **مطابق تماماً** |
| **إخفاقات جديدة** | **صفر** |
| `flutter analyze` | **No issues found** |

---

## 7. النتائج قبل/بعد — البرهان

```
قبل التصحيح:   +3 -5
  V1-a [E]  V1-c [E]  V2-a [E]  V2-b [E]  V3-a [E]

بعد التصحيح:   +20    All tests passed!
```

وأصلًا (HEAD):

```
+6 -5    (5 of 6 original isolation tests failed on HEAD)
```

---

## 8. ملخص `git diff`

```diff
 lib/features/inspection/data/repositories/inspection_repository_impl.dart | 341 ++++++++++++++++
 1 file changed, 310 insertions(+), 31 deletions(-)
```

| الفحص | النتيجة |
|---|---|
| ملفات `lib/` مُتغيّرة | **1** |
| `git status` delta | إدخالان فقط: الملف + `?? test/features/inspection/data/` |
| **commits** | **0** — `HEAD` = `e113129` |
| أوامر git مدمِّرة | **0** |
| التعديلات الـ 63 القائمة | **سليمة** |

---

## 9. قيود عقد الخادم — غير محلولة وموثّقة

| # | القيد | الأثر |
|---|---|---|
| **C1** | `DotInspectionScreenResponse` / `InspectionLogDisplayResponse` يُعلنان `driver → DriverResponse` لكن **`id` ليس `required`** | استجابة بلا `driver` ⇒ «غير معروف» ⇒ تُخزَّن ولا تُقدَّم لسائق محدَّد ولا تدخل FMCSA |
| **C2** | استجابة `GET /eld/dot-inspection/cycle` **لا تعلن** `driver` أصلاً | التحقق للدورة يعتمد على القيمة المُشاهَدة وقت التشغيل فقط. إن كانت `0` ⇒ تُستبعد |
| **C3** | `InformationPacketView` **لا يحمل** `driverId` إطلاقاً | `\"ملكية الطلب\"` فقط، و**لا تدخل FMCSA إطلاقاً** |
| **C4** | `driverId == 0` غير مُميَّز في `DriverId` (لا notion للصلاحية) | استُخدم كـ«غير معروف» بالاتفاق مع `asInt` fallback |
| **C5** | لا يوجد حقل ownership مستقل، ولا `expectedOwnerDriverId` في GETs | لا يمكن التحقق إلا بمقارنة الهوية المُعلَنة |
| **C6** | `JsonPrimitives.asInt` fallback = `0` يحوّل «الحقل مفقود» إلى «القيمة صفر» | سبب اعتماد C4 |

**لم يُختلق أي حقل خلفي.**

---

## 10. قيود إخراج FMCSA — غير محلولة

| # | القيد |
|---|---|
| **F1** | **ليس اختبار مطابقة كاملاً.** المشروع لا يملك مخطط ملف FMCSA موثّقاً ولا اختبارات مطابقة لنسخة `Appendix A` معيّنة. الحقول المفحوصة هي **الهوية الحاملة فقط**. رقم الرخصة و`coDriver` قد يكونان فارغين بشرعية ولم يُفحصا |
| **F2** | `FmcsaEldOutputGenerator` لم يُعدَّل (خارج النطاق). التحقق يجري في المستودع **بعد** الكتابة |
| **F3** | عند غياب بيانات مُتحقَّقة، التطبيق **يفشل** بدل إنتاج ملف ناقص. **تغيير سلوكي مقصود** يحتاج تأكيداً واعياً |
| **F4** | إذا كانت استجابات الإنتاجcycle/screen بلا `driver`، سيتوقف توليد FMCSA الميداني. **خطر تشغيلي حقيقي يحتاج تأكيداً من الخادم** |

---

## 11. المخاطر المتبقية

| # | المخاطر | التقييم |
|---|---|---|
| R-1 | **F4**: توقّف توليد FMCSA إذا كانت البيانات بلا `driver` | **عالٍ الأثر** — يحتاج جولة واحدة على بيانات الإنتاج |
| R-2 | **F3**: الفشل بدل ملف ناقص | مقصود ومُوثَّق |
| R-3 | `inspectionStaleSession` و`inspectionOwnerMismatch` و`inspectionNoVerifiedData` و`inspectionIncompleteOutput` **غير مترجَمة** — ستظهر كمفاتيح خام | يحتاج `l10n` (خارج النطاق) |
| R-4 | التحقق악는 على `driverId` المُعلَن الذي قد يكون كاذباً من الخادم نفسه | حدّه **العقد**؛ المستودع لا يستطيع أكثر |
| R-5 | 5 إخفاقات سابقة في `send_logs_page_test.dart` | خارج النطاق، لم تتأثر |

---

## 12. التعديلات على ملفات الإنتاج

`surgical` — ملف واحد، 310 إضافة / 31 حذفاً:

| القسم | السطور | الغرض |
|---|---|---|
| `_adoptSessionIfChanged` / `_captureEpoch` / `_isStale` / `_staleFailure` | ~30 | D1, D2 |
| `_acceptsDataFrom` / `_isVerifiedFor` / `_verifiedOwnerMatches` | ~25 | D3, D4 |
| `_cycleFallback` / `_logsFallback` / `_screenFallback` / `_packetFallback` | ~45 | استخراج + بوابة التحقق |
| `_invalidIdentifyingFields` / `_deleteQuietly` | ~45 | D5 |
| بوابات `await` الست | ~12 | D1 |
| `import 'dart:io'` | 1 | D5 |

---

## 13. الحالة النهائية

# `READY_FOR_TECHNICAL_REVIEW`

- D1–D5 مُصلَحة ومُثبَتة باختبارات.
- 20/20 اختبار EC-0.2a ناجح.
- صفر إخفاق جديد.
- صفر ملف خارج النطاق.
- `READY_FOR_TECHNICAL_REVIEW` لا تعني «مُغلق» — **قرار الإغلاق yours**.

**بانتظار قرارك.** لم أبدأ EC-0.2b.