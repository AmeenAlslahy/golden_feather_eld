# خطة الحل — مشاكل الحالة والوقت أونلاين/أوفلاين
# REMEDIATION PLAN — HOS Status & Offline Defects

**Basis:** `TASK_01_HOS_TIME_DASHBOARD_AUDIT.md` + `TASK_02_INDEPENDENT_VERIFICATION.md`
**Repo:** `golden_feather_eld` · branch `temp-fixes` · HEAD `67134cc`
**Date:** 2026-10-13
**Status:** PLAN ONLY — لا يوجد أي تعديل مُنفَّذ على كود الإنتاج

---

## 0.0 لماذا هذه الخطة مختلفة عن توصيات TASK 01

TASK 01 اقترح７ إصلاحات. بعد التحقق المستقل تبيّن أن **٣ منها كانTU比其他**، لو نُفِّذت لأضرّت بالتطبيق:

| توصية TASK 01 | القرار | السبب |
|---|---|---|
| F-01: "استبدل `DateTime.now()` بـ `TrustedTimeProvider` مباشرة" | ⛔ **مُعدَّل** | يطرح الفرق بين **ساعتين غير مرتبطتين** (انظر §2.2) |
| F-06: "احذف `TimeAuthority` واستبدله بـ `TrustedTimeProvider`" | ⛔ **ملغاة** | `TimeAuthority` يخدم جدولة إعادة المحاولة + بيانات وصفية؛ حذفه يخلط两者 ويزيل مقاومة العبث بالساعة عن `PendingEvent.createdAt` |
| F-10: "أصلح ثابت 35 دقيقة" | ⛔ **ملغاة** | الكود **ميت** بلا مستدعٍ (§5)؛ إصلاحه يضيف مخاطرة بلا فائدة |

---

## 0.1 شرط مُلزم قبل التنفيذ: تجميد التعديلات المتوازية

أثناء TASK 02 تغيّر كود إنتاج **من طرف آخر** أثناء الجلسة:

| الملف | الأثر |
|---|---|
| `main_circular_timer.dart` | تغيّر سلوك `_computeElapsed` + `initState` (قصّ لأقرب ثانية) |
| `lib/l10n/*` (7 ملفات) | +591 سطر ترجمة |
| `scripts/*.py` + تقارير | أدوات تدقيق نصوص جديدة |

**الإجراء المطلوب قبل أي إصلاح:**
1.，确认 اكتمال التعديل المتوازي أووقفه.
2. إعادة تشغيل `test/audit_task01` + `test/audit_task02` (50 اختبار) بعد أي تعديل.
3. `git diff --stat lib/` ومقارنته بالخط الأساس قبل/بعد كل مرحلة.

> ⚠️ أي إصلاح في §2 و §4 يلمس `main_circular_timer.dart` — يجب تنسيقه مع التعديل المتوازي أولاً.

---

## 0.2 ترتيب التنفيذ المقترح

```
المرحلة 0  تجهيز وتجميد           (لا كود إنتاج)
   ↓
المرحلة 1  إصلاح الكذب في وضع أوفلاين   ← يعالج BUG 1 + 2 + 4b
   ↓
المرحلة 2  زمن الاستجابة أونلاين         ← يعالج BUG 3
   ↓
المرحلة 3  تغطية باقي الصفحات أوفلاين     ← يعالج BUG 4a
   ↓
المرحلة 4  متانة المزامنة                ← يعالج BUG 4c (غير مُثبت)
   ↓
المرحلة 5  تنظيف وتوثيق
```

المرحلة 1 وحدها تُزيل **٣ من ٤** شكاوى المستخدم.

---

# المرحلة 1 — إصلاح "الكذب" في وضع أوفلاين (حرج)

## 1.1 المشكلة P1 — اللوحة تعرض `offDuty` + أقصى حدود قانونية

**الدليل:**
```
BUG1_COLD_STATUS=offDuty DRIVE=11:00 SHIFT=14:00 CYCLE=70:00
```

**المسار:**
```
StatusDashboardPage → statusDashboardProvider → GetStatusDashboardUseCase
  → StatusDashboardRepositoryImpl._fetchDashboard  offline:
    → _defaultOfflineDashboard()                status_dashboard_repository_impl.dart:61-106
```
الملف: `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart`

**الإصلاح المقترح (3 خطوات مستقلة، نفّذها بالترتيب):**

### 1.1أ —Persist اللوحة بنجاح (يُمكّن 1.1ب و1.1ج)
```dart
// status_dashboard_repository_impl.dart
StatusDashboard? _cachedDashboard;     //现状: in-memory فقط
```
أضف:
```dart
final StatusDashboardRepositoryImpl(this._backend, this._networkInfo,
    {DreadCallback? onPersist, DloadCallback? onLoad});
```
- `onPersist` يُستدعى في النجاح داخل `_fetchDashboard` و`updateDutyStatus`
- `onLoad` يُستدعى في المُنشئ لإعادة)_cachedDashboard و`_cachedRecap`

التخزين: Hive box الموجود (نفسه المستخدم لـ `hos_audit`) أو `localStorageService.prefs`.
> **الأثر:** يحوّل P6 (MEDIUM) إلى مُحل كجزء من P1.

### 1.1ب — إزالة القيم المولَّدة من مسار العرض
```dart
// ❌ الحالي —lines 54-58
}, offline: () async {
  final dashboard = _cachedDashboard ?? _defaultOfflineDashboard(driverId);
  _cachedDashboard = dashboard;
  return Right(dashboard);
});

// ✅ المقترح
}, offline: () async {
  final cached = _cachedDashboard;              // مُستعاد من 1.1أ
  if (cached != null) return Right(cached);
  // لا بيانات → نُرجع فشلاً صريحاً، لا أرقاماً مُختلَقة
  return const Left(NoDashboardDataFailure()); // شغّالة جديدة
});
```
**وش 효과를؟** الدائرة تقف على شاشة خطأ بدل أن تعرض 11:00 — أأمن بكثير قانونياً.

### 1.1ج — حالة "غير متاح" بدل الأرقام
ملف العرض: `lib/features/hos/presentation/widgets/status_dashboard/circular_timer_logic.dart`

أضف فرعاً جديداً:
```dart
// حالة صريحة: نعرض "—" أو "--:--" بدل رقم
static const String unavailable = '—';
```
- `hos_indicators_card.dart:141` (`DurationFormat.hhMm(indicator.value)`) ← يُبدَّل بنص "—" عند غياب المؤشر
- `main_circular_timer.dart:160-162` (`timeString`) ← نفس المعالجة

> **لا تستخدم `Duration.zero` كـ"غير متاح"** — الصفر يعني "استُنفد الوقت قانونياً" وهو معنى مختلف تماماً ومُضلِّل.

### 1.1د — Recap أوفلاين (P4)
```dart
// status_dashboard_repository_impl.dart:108-114
static const WeeklyRecap _defaultOfflineRecap = WeeklyRecap(
  cycleUsed: Duration.zero,        // ❌ "كل شيء مستهلك"
  cycleRemaining: Duration(hours: 70), // ❌ "فارغ تماماً"
  ...
);
```
احذف الثابت واستخدم نفس `Left(...)` + حالة "غير متاح" في `recap_page.dart`.

**ملاحظة عاجلة:** `_cachedRecap` هو أيضاً in-memory فقط → نفس إصلاح 1.1أ يغطّيه.

---

## 1.2 المشكلة P2 — تغيير الحالة أوفلاين: نجاح ظاهر بلا تحديث

**الدليل:**
```
BUG2_ACCEPTED=true REFUSAL=null DASHBOARD_IS_NULL=true
BUG2_LOCAL_STATUS=driving PERSISTED=driving QUEUED=1
```

**السبب الجذري — تفاعل بين ملفَّين:**
```dart
// ① duty_status_tracker.dart:392  —Offline:أُرجع نتيجة بلا لقطة
return const ManualDutyChangeResult();   // dashboard == null

// ② change_status_provider.dart:356 —التحديث مُشروط بوجود لقطة
final serverDashboard = outcome.dashboard;
if (serverDashboard != null) {           // ⛔ false
  ...applyServerDashboard(...)
}
// ③ ثم رغم ذلك:
return const DutyChangeSuccess();       // ✅ يقول "نجاح"
```

**الإصلاح المقترح — خياران (اختر واحد):**

### الخيار أ (مُستحسن) — أعد بناء اللوحة محلياً
أضف في `DutyStatusTracker` لقطة محلية:
```dart
// ManualDutyChangeResult يُضيف:
class ManualDutyChangeResult {
  final String? refusal;
  final StatusDashboard? dashboard;       // قد يكون server أو local
  final bool isPendingSync;              // ← جديد
}
```
وفي الفرع الأوفلاين، ابنِ `StatusDashboard` من:
- `currentStatus` المحلي (المتوفّر دائماً)
- آخر `hosIndicators` معروف (من الذاكرة المؤقتة)

ثم `applyServerDashboard` يُستدعى دائماً → الصفحة تتحدث فوراً.

### الخيار ب (أبسط،-azمن法规ياً) — لا تكذب، أخبر السائق
في `change_status_provider.dart`، عند `outcome.dashboard == null`:
```dart
if (serverDashboard != null) {
  ...applyServerDashboard(...)
} else {
  // ⚠️ لم تصل لقطة من الخادم — نُبلغ السائق بدل ادّعاء النجاح
  return DutyChangePendingSync();        // نوع جديد
}
```
وفي `change_status_page.dart:44-58`:
```dart
case DutyChangePendingSync():
  AppFeedback.info(context, 'تم الحفظ محلياً وسيُرسل عند عودة الاتصال');
  Navigator.pop(context);
```

**الأثر:** يزيل "النجاح الكاذب" — وهذا **أهم جزء** في P2. بيانات السائق محفوظة ومُدرجة في الطابور بشكل صحيح (مُثبت: `PERSISTED=driving QUEUED=1`).

> **تنبيه:** الخيار ب لا يُحدّث الأرقام — لأن الأرقام الحقيقية **غير معروفة** بدون خادم. لا تختلق أرقاماً.

---

## 1.3 المشكلة P5 — سباق الكتابة على اللوحة

**الدليل:**
```
T02_F03_AFTER_POST=9:00:00
T02_F03_AFTER_STALE_GET=2:00:00      ← الأحدث دُمِّر بالأقدم
```

الملف: `lib/features/hos/presentation/providers/status_dashboard_providers.dart`

**الإصلاح — رمز تكرار الطلبات:**
```dart
class StatusDashboardNotifier extends AsyncNotifier<StatusDashboard> {
  int _requestSeq = 0;              // ← جديد

  Future<void> refresh({bool showLoading = true}) async {
    final mySeq = ++_requestSeq;   // ← خذ تذكرة
    ...
    final result = await useCase.execute();
    result.fold(
      (failure) { if (mySeq != _requestSeq) return; ... },   // ← متأخر: تجاهل
      (dashboard) {
        if (mySeq != _requestSeq) return;   // ← متأخر: تجاهل
        ref.read(...SnapshotTimestamp...).state = DateTime.now();
        state = AsyncValue.data(dashboard);
      },
    );
  }

  void applyServerDashboard(StatusDashboard d) {
    ++_requestSeq;                  // ← POST هو الأحدث دائماً
    ref.read(...SnapshotTimestamp...).state = DateTime.now();
    state = AsyncValue.data(d);
  }
}
```
> `getDashboard` يُعيد استخدام نفس الـ future عند التزامن (`_inFlightDashboard`) — لذا GET-vs-GET آمن ولا يحتاج هذا الإصلاح؛ المطلوب فقط تغطية GET-vs-POST.

---

## 1.4 المشكلة BUG 3 — `hasServerMetrics` يُبقي عدادات قديمة

**الدليل:**
```
BUG3_SERVER_DRIVE=0:00:00  MERGED_DRIVE=4:00:00  MERGED_STATUS=driving
```

الملف: `lib/features/hos/presentation/providers/change_status_provider.dart:360-370`

**المشكلة:** إذا ردّ الخادم `remaining == 0` (وارد جداً أثناء إعادة الحساب)، نحتفظ بالقديم — لكن `applyServerDashboard` **يُحدّث `snapshotTimestamp` لـ `now`**، فتبدأ الدائرة من 4:00 بدل 0:00.

**الإصلاح — اجعل القرار متسقاً:**
```dart
// الحالي
final hasServerMetrics = serverDashboard.remainingCircle.remaining > Duration.zero;
final updatedDashboard = currentDashboard.copyWith(
  currentDutyStatus: serverDashboard.currentDutyStatus,
  remainingCircle: hasServerMetrics ? serverDashboard.remainingCircle
                                    : currentDashboard.remainingCircle,
  hosIndicators:   hasServerMetrics ? serverDashboard.hosIndicators
                                    : currentDashboard.hosIndicators,
);
_ref.read(statusDashboardProvider.notifier).applyServerDashboard(updatedDashboard);
```
المشكلة ليست `hasServerMetrics` نفسه، بل أن `applyServerDashboard` **دائماً** يعيد ضبط الطابع الزمني.

**إصلاحان اثنان، نفّذهما معاً:**
1. مرّر "هل هذه لقطة جديدة فعلاً" إلى `applyServerDashboard`، أو
2. (أبسط) **لا تعِد ضبط `snapshotTimestamp` إن لم تتغيّر الأرقام** — لأن `snapshotTimestamp` يجب أن يمثّل لحظة البيانات، لا لحظة استلامها.

هذا في جوهره **نفس أصل خطأ F-01** (§2).

---

# المرحلة 2 — تصحيح ساعة العدّاد التنازلي (عالٍ)

## 2.1 المشكلة P3 — العدّاد يعتمد ساعة الجهاز

**الدليل:**
```
T02_F01_STAMP=2026-10-13 22:18:00 IS_UTC=false
T02_F01_BACKWARD=05:00        ← ساعة رجعت للخلف ⇒ العدّاد يتجمّد
```

الملف: `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:45-51`
```dart
final diff = DateTime.now().difference(widget.snapshotTimestamp!);
return diff.isNegative ? Duration.zero : Duration(seconds: diff.inSeconds);
```

## 2.2 ⚠️ لماذا لا يصلح استبدال `DateTime.now()` بـ `TrustedTimeProvider` مباشرة

المعادلة الحالية:
```
liveRemaining = serverRemaining − (clientNow − clientSnapshotStamp)
```
- `serverRemaining` ➜ حُسب على **ساعة الخادم** لحظة معالجة الطلب
- `clientSnapshotStamp` ➜ خُتم لحظة **وصول الرد** للجهاز

**هما لحظتان مختلفتان**، تفصلهما استجابة الشبكة. استبدال `clientNow` بساعة موثوقة **مربوطة بمرساة الخادم** ينتج طرحاً بين **ساعتين بإزاحتين مختلفتين**. والإزاحة ليست ثابتة — هي مشتقة من ساعة الجهاز عبر فترة الإغلاق (§4).

## 2.3 الخيارات الصحيحة (اختر واحداً)

### الخيار أ (مُوصى) — الخادم يرسل طابعه
أضف حقلاً في الاستجابة:
```json
{ "remainingCircle": { "time": "05:00", "serverTimestamp": "2026-10-13T22:18:04Z" } }
```
العميل:
```dart
elapsed = trustedNow.difference(serverTimestamp);   // طرح بين ساعتين متسقتين
```
- ✅ دقيق تماماً
- ⚠️ يتطلب تغييراً في الـ backend — **تحتاج موافقة**

### الخيار ب (بدون تغيير خادم) — احذف التكتّك المحلي
```dart
// اعرض قيمة الخادم كما هي؛حدّث فقط عند وصول لقطة جديدة
final liveRemaining = baseRemaining;   // لا طرح إطلاقاً
```
- ✅ يحذف تبعية الساعة نهائياً
- ⚠️ سيفقد Tick التنازلي — يجب موازنة UX مع trenب光环
- ⚠️ Breaking بصري

### الخيار ج (وسط) — استخدم Stopwatch مُوقَعاً
عند كل لقطة جديدة سجّل:
```dart
_stopwatch..reset()..start();     // لا ساعة جهاز
```
- ⚠️ **لا يحل المشكلة**: عند restartariالـ widget يضيع الـ stopwatch → underwriting
- ✅ يحل فقط انحراف الساعة أثناء الجلسة
- 💡 مفيد كطبقة أولى إن كان الخيار (أ) غير متاح

**التوصية:** اطلب (أ) من الـ backend؛ نفّذ (ج) كتحسين مؤقت.

---

# المرحلة 3 — تغطية باقي الصفحات في وضع أوفلاين (متوسط)

## 3.1 الوضع الحالي غير متجانس (المُستنبط من المصدر)

| المستودع | السلوك أوفلاين | الملف:السطر |
|---|---|---|
| `StatusDashboardRepositoryImpl` | يعرض قيم مُختلَقة ❌ | `…_impl.dart:54, 190` |
| `LogRepositoryImpl` | يخدم لقطة محلية ✅ | `:67, 110, 180, 240` |
| `VehicleRepositoryImpl` | **فشل صلب، بلا بديل** ❌ | `:41, 70` |
| `CodriverRepositoryImpl` | `guardedNetwork` بلا `offline:` ❌ | `:64, 107` |
| `DvirRepositoryImpl` | له بدائل ✅ | 8 مواقع |
| `InspectionRepositoryImpl` | له بدائل ✅ | 7 مواقع |

## 3.2 الإصلاح — وحّد النمط على `LogRepositoryImpl`

لكل مستودع ناقص، أضف فرعاً محلياً (نفس نمط السجلات):
```dart
// vehicle_repository_impl.dart — النموذج
if (!_networkInfo.isConnected) {
  final cached = _localCache.readVehicles();      // ← مصدر جديد
  if (cached != null) return Right(cached);
  return const Left(NoVehicleDataFailure());      // لا أرقام مُختلَقة
}
```
نفس المعالجة لـ `CodriverRepositoryImpl`.

**⚠️ تحذير مهم:** بعد جلب المركبات أونلاين، تُخزَّن **محلياً** — لكن استرجاعها عند تسجيل دخول **سائق مختلف** يسرّب بيانات. اربط الـ cache بـ `driverId`، واستخدم نمط العزل الموجود في `authStateProvider.sessionEpoch`.

---

# المرحلة 4 — متانة المزامنة (منخفض / غير مُثبت)

## 4.1 ⚠️ هذه المشكلة **غير مُثبتة** — لا تُنفّذ قبل التحقق على جهاز

**الشك (U-03):** `triggerSync()` يُستدعى مرة واحدة عند عودة الاتصال ثم يخرج إن كانت قائمة `getReadyEvents` فارغة. لا يوجد **مؤقّت دوري**. حدث فشلت أثناء أوفلاين بـ backoff 50 ثانية قد يبقى **خاملاً حتى 50 ثانية بعد عودة الاتصال**.

**قبل الإصلاح — نفّذ على جهاز حقيقي:**
1. اقطع النت
2. غيّر حالة السائق (حدث في الطابور)
3. أعد الاتصال وراقب الطابور خلال 60 ثانية
4. ✅ If لم يُرسل خلال ~60 ثانية → الشك مؤكد

**إذا تأكد:** أضف مؤقّتاً دورياً:
```dart
// sync_providers.dart:148 (قبل return engine)
final timer = Timer.periodic(const Duration(seconds: 30), (_) => engine.triggerSync());
ref.onDispose(timer.cancel);
```

## 4.2 سلوك إعادة المحاولة — **سلامة، لا عيب** (لا تُغيّره)

```
BUG4_RETRY_0..3 = +10s,20s,30s,40s
BUG4_RETRY_4..11 = +50s (مُقيَّد، لا يعيد null أبداً)
```
`RetryPolicy.calculateNextRetry` **لا تُرجع null أبداً** → `moveToDeadLetter` غير قابل للوصول → **لا فقدان بيانات**، تoit这是在 إعادة محاولة لا نهائي��. هذا سلوك متّسق مع "لا تُسقط بيانات HOS أبداً".

> **لا "أصلح" هذا.** إن أردت dead-lettering فليكن قراراً منفصلاً — لكنه يقلّل ضمان عدم الفقدان.

## 4.3 تحقّق منفصل: `releaseEligible` (U-04)
```dart
// sync_engine.dart:99
if (ctx.driverId == null || ctx.transitioning) return 0;
```
أحداث الـ parked **لا تُحرَّر** أثناء انتقالات الجلسة. تحقق بسيناريو خروج/دخول قبل أي تعديل.

---

# المرحلة 5 — تنظيف وتوثيق (منخفض)

| # | المطلوب | الملف | ملاحظة |
|---|---|---|---|
| 5.1 | **احذف فرع إعادة الضبط الميت** | `main_circular_timer.dart:74-81` | مُشروط بـ `snapshotTimestamp == null` — لا يحدث في الإنتاج. لو مرّر مستدعٍ مستقبلي `null` سيمنح وقتاً ق��ونياً |
| 5.2 | **احذف الكود الميت** | `UpdateDutyStatusUseCase` + `StatusDashboardRepositoryImpl.updateDutyStatus` + `_circleForStatus` | بلا مستدعٍ. **لا تُصلح الثوابت — احذف** |
| 5.3 | **صحّح الاستشهادات التنظيمية** | `status_dashboard_repository_impl.dart:16` و `time_authority.dart:4` | §395.24 **لا** يتطلب عرض الوقت أوفلاين (تحقّق: لا تحوي "display"/"offline"). المرجع الصحيح للزمن: **Appendix A §4.3.1.5** لا §4.3.2.2 |
| 5.4 | **وثّق المحرك كـ"استرشادي"** | `hos_engine_provider.dart:24-39` | عداداته في الذاكرة فقط، تُصفَّر عند ال��شغيل، **ولا تُعرض**. يمنع قارئاً من افتراض أنها مصدر الحقيقة |
| 5.5 | (اختياري) صحّح نموذج الاستراحة | `hos_calculator.dart:65` | `breakRequired` يلتصق ولا يُصفَر. **لا أثر حالياً** — لا يوجد مستهلك. نفّذه فقط إن أضفت مستهلكاً |
| 5.6 | أصلح الاختبار المُعرَض للتباين الزمني | `test/.../main_circular_timer_test.dart` | ✅ **أُصلح مسبقاً** بالتعديل المتوازي (8/8) |

---

# المرحلة 6 — اختبارات الانحدار المطلوبة

كل بند أعلاه يحتاج اختباراً يثبت **غياب العطل**، لا وجوده فقط:

| # | الاختبار | يغطي |
|---|---|---|
| R1 | بدء أوفلاين بلا كاش ⇒ **لا** تظهر `11:00/70:00`، بل حالة "غير متاح" | P1 |
| R2 | قراءة اللوحة بعد إعادة تشغيل ⇒ نفس القيم السابقة (لا تصفير) | P1/P6 |
| R3 | تغيير الحالة أوفلاين ⇒ الصفحة تعكس الحالة الجديدة **أو** رسالة "معلّق" صريحة | P2 |
| R4 | Recap أوفلاين ⇒ **لا** `cycleUsed == 0` | P4 |
| R5 | POST ثم GET متداخلان ⇒ الأحدث يبقى | P5 |
| R6 | ردّ POST بـ `remaining==0` ⇒ لا resurrect للوقت القديم | BUG 3 |
| R7 | `trustedNow − deviceNow = offset` ⇒ العدّاد صحيح | P3 |
| R8 | فاصل زمني بين الطابع والبيانات ⇒ لا قفزة | P3 |
| R9 | المركبة/co-driver أوفلاين ⇒ قائمة من الكاش لا `NetworkFailure` | BUG 4a |
| R10 | كاش الصفحات مربوط بـ `driverId` (عزل الجلسات) | BUG 4a |

**المتطلب:** كل اختبار جديد يجب أن يذكر صراحةً ما هو **حقيقي** و ما هو **مزيّف** (كما فعلت TASK 02).

---

# ملخّص الأولويات

| الأولوية | البند | الشدة | الحالة |
|---|---|---|---|
| **P1** | إلغاء قيم أوفلاين المُختلَقة + persist | **حرج** | مُثبَت |
| **P2** | إزالة "النجاح الكاذب" | **حرج** | مُثبَت |
| **P3** | تصحيح ساعة العدّاد | **عالٍ** | مُثبَت (يحتاج قرار خادم) |
| **P4** | Recap أوفلاين | **عالٍ** | مُثبَت |
| **P5** | سباق الكتابة | **متوسط** | مُثبَت |
| **P6** | cache دائم | **متوسط** | ضمن P1 |
| **P7** | صفحات أوفلاين | **متوسط** | مُثبَت |
| **P8** | مؤقّت المزامنة | **منخفض** | ⚠️ **غير مُثبت — اختبر أولاً** |
| **P9–P11** | تنظيف وتوثيق | **منخفض** | آمن |

---

## ما لا يجب فعله

1. ⛔ **لا** تستبدل `DateTime.now()` بـ `TrustedTimeProvider` مباشرة (§2.2).
2. ⛔ **لا** تحذف `TimeAuthority` — يخدم طبقات لا علاقة لها بالوقت القانوني.
3. ⛔ **لا** تُصلح ثابت 35 دقيقة — كود ميت.
4. ⛔ **لا** تغيّر `RetryPolicy` لتُضيف dead-letter — يقلّل ضمان عدم الفقدان.
5. ⛔ **لا** تستخدم `Duration.zero` كـ"بيانات غير متاحة" — تعني "استُنفد الوقت".
6. ⛔ **لا** تعرض أي رقم HOS غير معروف من الخادم — كهذا يسبّب للبBUG 1 أصلاً.

---

## الخطوة التالية المقترحة

ابدأ بـ **المرحلة 1** فقط (P1 + P2 + P4). هذه تحل **٣ من ٤** شكاوى المستخدم، ولا تتطلب أي تغيير في الـ backend.
عندها أعد `flutter test` كاملاً + `test/audit_task01` + `test/audit_task02` (50 اختباراً) قبل الانتقال للمرحلة 2.

**لم يُنفَّذ أي إصلاح بعد.** بانتظار موافقتك.