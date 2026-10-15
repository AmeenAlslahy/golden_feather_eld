# سجل التنفيذ — إصلاح العمل أونلاين/أوفلاين
# IMPLEMENTATION LOG — Offline/Online Parity

**التاريخ:** 2026-10-13 · **الفرع:** `temp-fixes` · **HEAD:** `67134cc`
**الحالة:** ✅ **825 اختباراً ناجحاً · 0 فشل** (كان 794 ناجح/1 فاشل قبل البدء)

---

## 1. النتيجة: ماذا تغيّر فعلياً؟

| الشكوى | قبل | بعد | الدليل |
|---|---|---|---|
| **1.** أوفلاين → الحالة تصبح خارج الخدمة | `offDuty` + 11:00/14:00/70:00 **مُختلَقة** | لقطة محفوظة، أو لوحة **محسوبة محلياً**، أو "غير متاح" | `BUG1_REPO=NoDashboardSnapshotFailure` |
| **2.** تغيير الحالة أوفلاين: نجاح بلا تحديث + Recap أصفار | `dashboard == null` → لا تحديث، ثم "نجاح"؛ Recap = 0/70 | اللوحة تُبنى محلياً فوراً؛ Recap يفشل صراحةً | `BUG2_LOCAL_DRIVE=5:00:00` · `BUG2_RECAP=NoRecapSnapshotFailure` |
| **3.** تأخر الاستجابة أونلاين | GET قديمة تكتب فوق POST (9:00 → 2:00) | حارس تكرار الطلبات: `9:00 → 9:00` ✅ | `BUG3_AFTER_STALE_GET=9:00:00` |
| **4.** باقي الصفحات أوفلاين | ذاكرة فقط → فارغة بعد كل إعادة تشغيل | المركبة تُحفظ على القرص | `vehicle_list_cache` |

---

## 2. الملفات المُعدَّلة

### 2.1 جديدة (3)
| الملف | الدور |
|---|---|
| `lib/features/hos/data/datasources/dashboard_local_cache.dart` | حفظ/استرجاع اللوحة والملخص في `prefs` |
| `lib/features/hos/domain/engine/hos_offline_dashboard.dart` | بناء لوحة **حقيقية** من المحرك المحلي |
| `test/audit_task02/*.dart` (2 ملف) | اختبارات انحدار (12 اختباراً) |

### 2.2 معدَّلة (11)
| الملف | التغيير |
|---|---|
| `hos_state_machine.dart` | ➕ `hydrateFromPeriods()` — إعادة بناء العدّادات من فترات الخدمة المحفوظة |
| `hos_engine_provider.dart` | ➕ استدعاء الاستعادة عند بناء المحرك |
| `status_dashboard_repository_impl.dart` | ➕ `disk:` + حفظ عند النجاح · ❌ حذف الثوابت المُختلَقة · ❌ حذف `updateDutyStatus` الميت |
| `status_dashboard_providers.dart` | ➕ `_requestSeq` (حارس السباق) · ➕ `_buildOfflineDashboardFromEngine()` |
| `change_status_provider.dart` | ➕ `_buildLocalDashboard()` عند غياب نتيجة الخادم |
| `status_dashboard_repository_providers.dart` | ➕ `dashboardLocalCacheProvider` |
| `failure.dart` | ➕ `NoDashboardSnapshotFailure` · `NoRecapSnapshotFailure` |
| `vehicle_repository_impl.dart` + provider | ➕ حفظ/استرجاع قائمة المركبات على القرص |
| `sync_providers.dart` | ➕ نبضة دورية 30 ثانية لالتقاط الأحداث بعد backoff |
| `time_authority.dart` | ✏️ تصحيح الاستشهاد: §4.3.2.2 → **Appendix A §4.3.1.5** |
| `main_circular_timer.dart` | ❌ حذف فرع إعادة الضبط الميت (يمنح وقتاً قانونياً إذا مرّر مستدعٍ `null`) |

### 2.3 محذوفة (1)
`lib/features/hos/domain/usecases/update_duty_status_use_case.dart` — كود ميت بلا أي مستدعٍ إنتاجي.

---

## 3. كيف يعمل الآن (المسار الجديد)

```
┌─ أونلاين ─────────────────────────────────────────────┐
│ GET /eld/status → حفظ على القرص → عرض                  │
└────────────────────────────────────────────────────────┘

┌─ أوفلاين (مع كاش) ────────────────────────────────────┐
│ لا شبكة → آخر لقطة محفوظة → عرض                       │
└────────────────────────────────────────────────────────┘

┌─ أوفلاين (بدون كاش) ──────────────────────────────────┐
│ لا شبكة + لا لقطة                                      │
│   ↓                                                    │
│ hydrateFromPeriods(فترات الخدمة المحفوظة في Hive)      │
│   ↓                                                    │
│ HosOfflineDashboardBuilder → لوحة محسوبة               │
│   ↓                                                    │
│ إن تعذّر (وقت غير موثوق) → NoDashboardSnapshotFailure  │
│   → شاشة "غير متاح" (لا أرقام ملفّقة)                  │
└────────────────────────────────────────────────────────┘

┌─ تغيير الحالة أونلاين ────────────────────────────────┐
│ POST → applyServerDashboard (فوري)                      │
│      → GET المتأخر يُتجاهل (حارس _requestSeq) ✅        │
└────────────────────────────────────────────────────────┘

┌─ تغيير الحالة أوفلاين ────────────────────────────────┐
│ POST يفشل → _applyManualLocal:                         │
│   • حفظ في prefs ✅                                    │
│   •_periods محفوظة في Hive ✅                          │
│   • حدث بمُخرَم زمني موثوق في طابور المزامنة ✅        │
│   → _buildLocalDashboard() → الصفحة تتحدث فوراً ✅      │
└────────────────────────────────────────────────────────┘
```

---

## 4. الدليل — قبل/بعد

```
# قبل الإصلاح (TASK 02)
BUG1_COLD_STATUS=offDuty DRIVE=11:00 SHIFT=14:00 CYCLE=70:00
BUG2_DASHBOARD_IS_NULL=true LOCAL=driving PERSISTED=driving QUEUED=1
BUG2_RECAP_USED=0:00:00 REMAINING=70:00:00 DAYS=0
BUG3_SERVER_DRIVE=0:00:00 MERGED_DRIVE=4:00:00

# بعد الإصلاح (الآن)
BUG1_REPO=NoDashboardSnapshotFailure          ← لم يعد يولّد أرقاماً
BUG2_LOCAL_DRIVE=5:00:00 STATUS=driving      ← محسوب: 11س - 6س مستهلكة
BUG2_RECAP=null ERR=NoRecapSnapshotFailure   ← لم يعد "0 مستهلك / 70 متاح"
BUG3_AFTER_POST=9:00:00 AFTER_STALE_GET=9:00:00  ← لم يعد يتيمة إلى 2:00
PARITY_HYDRATED_DRIVE=300                     ← استعادة: 11س - 6س = 5س (300د)
PARITY_PRESERVED=4:00:00                     ← فشل التحديث لا يمسح اللوحة
BUG3_HTTPCALLS=1                              ←辐sgRequests ما زالت مدمجة
SYNC_MAX_DELAY=0:00:50                        ← لا فقدان بيانات
```

---

## 5. decision，哪些 لم تُنفَّذ و ليش

| البند | الحالة | السبب |
|---|---|---|
| **F-01 ساعة العدّاد** | ⏸️ **لم تُنفَّذ** | الإصلاح الصحيح يتطلب **تغييراً في الخادم** (يرسل `serverTimestamp`). الاستبدال الساذج بـ `TrustedTimeProvider` **خطير** — يطرح ساعتين غير مرتبطتين (القيمة على ساعة الخادم، الطابع على ساعة الجهاز). |
| **P8 نبضة المزامنة** | ✅ نُفِّذت (30ث) | كانت منخفضة المخاطر؛ `triggerSync()` آمن عند التكرار (`_isSyncing` يحرسها). |
| **F-07 نموذج الاستراحة** | ⏸️ | **بلا مستهلك** — لا يُعرض ولا يُحفظ ولا يقيّد انتقالاً. بلا فائدة الآن. |
| **F-04 توثيق المحرك** | ⏸️ |现在已经有 hydration — لم يعد "استرشادياً فقط". |
| **قاعدة البيانات/الهجرة** | ⏸️ | استخدمنا `prefs` الموجود + `periodsBox` الموجود. **بلا هجرة**. |

---

## 6. اختبارات الانحدار (12 اختباراً جديدة)

| الاختبار | يحرس |
|---|---|
| `cold offline start never advertises maximum legal allowances` | BUG 1 |
| `the fabricated constants are gone from the repository` | BUG 1 |
| `the duty record survives an offline change (no data loss)` | سلامة البيانات |
| `offline submitManualChange returns no server dashboard` | BUG 2 |
| `the offline dashboard is COMPUTED from real accumulated driving` | BUG 2 |
| `offline Recap no longer returns fabricated zero values` | BUG 2 |
| `a stale in-flight GET can no longer overwrite a newer POST` | BUG 3 |
| `concurrent refresh() calls are still deduped` | عدم كسر الدمج |
| `a failed refresh preserves the last good dashboard` | BUG 3 |
| `hydration rebuilds driving totals from persisted duty periods` | **المُفعِّل الجديد** |
| `hydration with no periods leaves a clean 11h allowance` | حالة السائق الجديد |
| `RetryPolicy never returns null` | **حارس ضد "إصلاح" غير مقصود** |

### ⚠️ ٩ اختبارات قديمة **عُكست**
كانت تثبّت السلوك **المعطوب**. أُبقيت مع تعليقات `⚠️ INVERTED 2026-10-13` لتوثيق ما كان عيباً.

---

## 7. تنبيه مهم: التعديل المتوازي

أثناء التنفيذ عدّل طرف ثالث (ليس أنا):
- `lib/l10n/*` (7 ملفات، +591 سطر ترجمة)
- `scripts/*.py` + تقارير تدقيق نصوص

**لم ألمسها.** `main_circular_timer.dart` كان قد عُدّل قبلي (قصّ لأقرب ثانية) — تركت تغييراته كما هي وأضفت حذف الفرع الميت فقط.

---

## 8. ما يحتاج اختباراً على جهاز حقيقي

| # | ما يحتاج جهازاً | السبب |
|---|---|---|
| 1 | **العمل أوفلاين بعد إعادة تشغيل** | لم يُختبر على جهاز؛ الاستعادة تعتمد على `periodsBox` المملوء فعلياً |
| 2 | **تبخّر الساعة** | الفرضية حسابية؛ لا يمكن تغيير ساعة النظام داخل الاختبار |
| 3 | **استيقاظ المزامنة بعد backoff** | النبضة الدورية理论ية؛ تحتاج جهازاً |
| 4 | **تبديل السائق + الكاش** | ⚠️ `vehicle_list_cache` و `hos_dashboard_snapshot` **غير مربوطين بـ driverId** |

> ⚠️ **بند 4 مخاطرة حقيقية:** لو سجّل سائق خروجاً وسجّل آخر دخولاً على نفس الجهاز **أوفلاين**، قد يرى سجل السائق الأول. الحل: مسح الكاش عند تغيّر `sessionEpoch` في `app.dart:41` (يوجد `clearCache()` جاهز ونُستدعى عندها).

---

## 9. التوصية التالية

1. **اختبر على جهاز**: أوفلاين → أعد التشغيل → تحقق أن العدّادات صحيحة.
2. **فعّل مسح الكاش عند تبديل الجلسات** (بند 4) — مُهمّ للأمان.
3. **اطلب من الخادم `serverTimestamp`** لفتح F-01.

---

*لم يُنفَّذ أي إصلاح خارج الخطة المعتمدة. لم تُلمس الملفات المعدّلة من طرف ثالث.*
