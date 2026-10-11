# 09 — تسوية التدقيق السابق (Audit Reconciliation)

> رُوجعت النتائج الـ 228 واحدة واحدة مقابل الشجرة الحالية. لا إسقاط صامت: كل صف أدناه يحمل تصنيفاً ومنهج تحقق.

## 1. المنهجية (قابلة لإعادة الإنتاج)

| الخطوة | الأداة |
|---|---|
| استخراج الأدلة من `issues.csv` (كتل ```dart + أسطر `import`) | سكربت `reconcile2.ps1` |
| فهرس استيرادات الشجرة كاملة (1,726 حافة) | `depgraph.ps1` |
| مطابقة الأدلة: استيراد موجود في الملف المستشهد؟ سطر شيفرة موجود؟ | آلي |
| بحث شجري للشواهد بلا مسار (`reconcile3.ps1`) | آلي |
| فحص يدوي مباشر للحرجة + المتناقضة + الملفات المعدّلة | `Read`/`Grep` + تشغيل اختبار واحد |

**فرضية الاستمرارية** (مصرّح بها): الشجرة الحالية ≡ شجرة التدقيق **عدا** `inspection_repository_impl.dart` (تعديلي) وملفات الاختبار الجديدة. الدليل: مجموعة الملفات المعدّلة مطابقة لمجموعة خط الأساس (63) + ملفي.

**معاني التحقق:** `HAND` = فحصت الشيفرة/شغّلت الاختبار بنفسي هذه المهمة. `TREE` = وجدت الشاهد بحثاً شجرياً. `AUTO-FULL` = كل أدلة البند مطابقة حرفياً. `AUTO-PART` = جزء مطابق (غالباً: كتل متعددة الملفات أو أسطر تعليقية `// file:line` لا تُطابق عمداً).

## 2. الخلاصة

| التصنيف | العدد | الأعضاء |
|---|---|---|
| CONFIRMED | 156 | الجدول |
| PARTIALLY_CONFIRMED | 69 | الجدول (معظمه AUTO-PART: الدليل جزئي المطابقة لطبيعة الاستخراج، لا لنفي الجوهر) |
| INVALID | 1 | CORE-015 |
| SUPERSEDED | 1 | DST-002 (أصلحه EC-0.2a: لا `static`، ملكية مُتحقَّقة، 20 اختباراً) |
| NEEDS_MORE_EVIDENCE | 1 | CON-005 (صف مشوّه في السجل؛ العائلة مغطاة بـ COD-006 المؤكد) |

### تصحيحات جوهرية على التدقيق السابق

| البند | حكم التدقيق | الحكم بعد التحقق |
|---|---|---|
| CORE-015 (`.env` متتبَّع = تسريب) | HIGH/CONFIRMED | **INVALID** — الملف بلا أسرار وموثّق كافتراضي غير سرّي |
| HL-15 (قاعدة بلا `return`) | CRITICAL + "أضف return" | **PARTIALLY** — الواقعة صحيحة والتوصية **خاطئة** (تكسر المزامنة التلقائية)؛ العيب الحقيقي تصنيف الخطأ (مُثبت باختبار فاشل أعدت تشغيله) |
| HOM-002 (تجاوز القيادة) | HIGH "غير مقيّد" | **PARTIALLY** — مقيّد بـ `kDebugMode` (`driving_lock_screen.dart:29`)؛ LOW فعلياً |
| DST-025 (طابور ميت) | HIGH | **PARTIALLY** — النظامان **حيّان** (`sync_provider` يستهلك `SyncRepository`)؛ الازدواج حقيقي والموت مبالغ فيه |
| CON-001 (لا نطاق إطلاقاً) | HIGH | **PARTIALLY** — `connection/domain` **موجود ومُستخدم**؛ الصحيح: التنسيق في الصفحة لا النطاق |
| DST-044 (HTTP في النطاق) | MEDIUM | **PARTIALLY** — تحليل wire مؤكد؛ **لا استدعاء HTTP** في الملف |
| BACK-001 (تسرّب RawJson للنطاق) | HIGH | **PARTIALLY** — الـ typedef والانتشار الخلفي مؤكدان؛ **لا ملف domain يستورده** |
| BACK-031 (استثناء الجلسة) | MEDIUM | **CONFIRMED مع تدقيق الأثر: صفري وظيفياً** (ميت لا مكسور) |
| DST-002 | CRITICAL | **SUPERSEDED** — أُصلح |
| BACK-008/BACK-004/DST-001/HL-01/HL-02/HL-03/CUI-001/COD-001 | كما وردت | **CONFIRMED** (أُعيد فحص كل منها) |

### أخطاء عدّية صُحّحت

| الادعاء | القياس الجديد |
|---|---|
| "6 حواف backend→features" | **9** (3 لشبكة Traccar فاتها محلل التدقيق — نفس خلل `package:` الذي أصاب قياسي أولاً) |
| "7 نسخ تنسيق زمني" (HL-26) | موقع `_fmt` واحد متبقٍّ — تقلّص |
| "12+ use-case شكلية" | **7 ملفات use-case** في المشروع كله، 3 منها تمريرية (12-15 سطراً) |
| "5 خرائط حالات" | مؤكد الاتجاه؛ المواقع الدقيقة متفاوتة (خرائط تسميات + تطبيع + تحويلات) |

## 3. الجدول الكامل (228)

| ID | Sev | Classification | Verification | Note |
|---|---|---|---|---|
| ACC-001 | HIGH | CONFIRMED | HAND |  |
| ACC-002 | HIGH | CONFIRMED | AUTO-FULL |  |
| ACC-003 | HIGH | CONFIRMED | HAND |  |
| ACC-004 | HIGH | CONFIRMED | HAND |  |
| ACC-005 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| ACC-006 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| ACC-007 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| ACC-008 | MEDIUM | CONFIRMED | HAND |  |
| AUTH-001 | HIGH | CONFIRMED | AUTO-FULL |  |
| AUTH-002 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| AUTH-003 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| AUTH-004 | HIGH | CONFIRMED | AUTO-FULL |  |
| AUTH-005 | HIGH | CONFIRMED | AUTO-FULL |  |
| AUTH-006 | LOW | CONFIRMED | AUTO-FULL |  |
| AUTH-007 | LOW | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-001 | HIGH | PARTIALLY_CONFIRMED | HAND+PHASE0 | typedef + backend-wide use confirmed; domain-leak sub-claim not found |
| BACK-002 | HIGH | CONFIRMED | HAND |  |
| BACK-003 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| BACK-004 | CRITICAL | CONFIRMED | HAND |  |
| BACK-005 | LOW | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-006 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| BACK-007 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| BACK-008 | HIGH | CONFIRMED | HAND |  |
| BACK-009 | HIGH | CONFIRMED | HAND |  |
| BACK-010 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-011 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| BACK-012 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-013 | MEDIUM | CONFIRMED | HAND |  |
| BACK-014 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| BACK-015 | LOW | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-016 | LOW | CONFIRMED | AUTO-FULL |  |
| BACK-017 | LOW | CONFIRMED | AUTO-FULL |  |
| BACK-018 | LOW | CONFIRMED | HAND |  |
| BACK-019 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-020 | HIGH | CONFIRMED | HAND |  |
| BACK-021 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| BACK-022 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-023 | HIGH | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-024 | MEDIUM | CONFIRMED | HAND |  |
| BACK-025 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-026 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-027 | MEDIUM | CONFIRMED | HAND |  |
| BACK-028 | LOW | CONFIRMED | HAND |  |
| BACK-029 | LOW | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-030 | LOW | CONFIRMED | AUTO-FULL |  |
| BACK-031 | MEDIUM | CONFIRMED | HAND |  |
| BACK-032 | LOW | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-033 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-034 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| BACK-035 | MEDIUM | CONFIRMED | HAND |  |
| BACK-036 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| COD-001 | HIGH | CONFIRMED | HAND |  |
| COD-002 | HIGH | CONFIRMED | HAND |  |
| COD-003 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| COD-004 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| COD-005 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| COD-006 | MEDIUM | CONFIRMED | HAND |  |
| CON-001 | HIGH | PARTIALLY_CONFIRMED | HAND+PHASE0 | page-level orchestration confirmed; "no domain at all" contradicted |
| CON-002 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CON-003 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CON-004 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CON-005 | MEDIUM | NEEDS_MORE_EVIDENCE | HAND+PHASE0 | malformed registry row; family covered by COD-006 |
| CON-006 | LOW | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CON-007 | LOW | CONFIRMED | AUTO-FULL |  |
| CORE-001 | HIGH | CONFIRMED | AUTO-FULL |  |
| CORE-002 | HIGH | CONFIRMED | AUTO-FULL |  |
| CORE-003 | HIGH | CONFIRMED | AUTO-FULL |  |
| CORE-004 | HIGH | CONFIRMED | HAND |  |
| CORE-005 | HIGH | CONFIRMED | HAND |  |
| CORE-006 | HIGH | CONFIRMED | HAND |  |
| CORE-007 | HIGH | CONFIRMED | AUTO-FULL |  |
| CORE-008 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CORE-009 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CORE-010 | MEDIUM | CONFIRMED | HAND |  |
| CORE-011 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CORE-012 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CORE-013 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CORE-014 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CORE-015 | MEDIUM | INVALID | HAND+PHASE0 | .env holds no secrets; documented non-secret default |
| CORE-016 | HIGH | CONFIRMED | HAND |  |
| CORE-017 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CORE-018 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CORE-019 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CORE-020 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CORE-021 | LOW | CONFIRMED | AUTO-FULL |  |
| CORE-022 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CORE-023 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CORE-024 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CORE-025 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CORE-026 | LOW | CONFIRMED | AUTO-FULL |  |
| CORE-027 | LOW | CONFIRMED | AUTO-FULL |  |
| CORE-028 | LOW | CONFIRMED | AUTO-FULL |  |
| CORE-029 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CORE-030 | LOW | CONFIRMED | AUTO-FULL |  |
| CORE-031 | MEDIUM | CONFIRMED | HAND |  |
| CORE-032 | LOW | CONFIRMED | AUTO-FULL |  |
| CORE-033 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CORE-034 | LOW | CONFIRMED | AUTO-FULL |  |
| CORE-035 | LOW | CONFIRMED | AUTO-FULL |  |
| CORE-036 | LOW | CONFIRMED | AUTO-FULL |  |
| CORE-037 | LOW | CONFIRMED | AUTO-FULL |  |
| CTN-001 | Informational (ظ„ط§ ظ…ط®ط§ظ„ظپط©) â€” CONFIRMED CLEAN | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-001 | CRITICAL | CONFIRMED | HAND |  |
| CUI-002 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CUI-003 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CUI-004 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CUI-005 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-006 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CUI-007 | MINOR | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-008 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CUI-009 | MINOR | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-010 | MINOR | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-011 | MINOR | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-012 | MINOR | CONFIRMED | AUTO-FULL |  |
| CUI-013 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| CUI-014 | MINOR | CONFIRMED | AUTO-FULL |  |
| CUI-015 | MINOR | CONFIRMED | AUTO-FULL |  |
| CUI-016 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-017 | MINOR | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-018 | MINOR | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-019 | MINOR | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-020 | MINOR | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-021 | MINOR | PARTIALLY_CONFIRMED | AUTO-PART |  |
| CUI-022 | MINOR | CONFIRMED | AUTO-FULL |  |
| DOM-001 | HIGH | CONFIRMED | HAND |  |
| DOM-002 | MEDIUM | CONFIRMED | HAND |  |
| DOM-003 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DOM-004 | LOW | CONFIRMED | AUTO-FULL |  |
| DOM-005 | LOW | CONFIRMED | AUTO-FULL |  |
| DST-001 | CRITICAL | CONFIRMED | HAND |  |
| DST-002 | CRITICAL | SUPERSEDED | HAND+PHASE0 | EC-0.2a removed the static cache; ownership enforced + tested |
| DST-003 | HIGH | CONFIRMED | AUTO-FULL |  |
| DST-004 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-005 | HIGH | PARTIALLY_CONFIRMED | AUTO-PART |  |
| DST-006 | HIGH | CONFIRMED | AUTO-FULL |  |
| DST-007 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-008 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-009 | LOW | PARTIALLY_CONFIRMED | AUTO-PART |  |
| DST-010 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-011 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| DST-012 | MEDIUM | CONFIRMED | HAND |  |
| DST-013 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-014 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| DST-015 | LOW | CONFIRMED | AUTO-FULL |  |
| DST-016 | HIGH | CONFIRMED | HAND |  |
| DST-017 | LOW | CONFIRMED | AUTO-FULL |  |
| DST-018 | HIGH | CONFIRMED | HAND |  |
| DST-019 | LOW | PARTIALLY_CONFIRMED | AUTO-PART |  |
| DST-020 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-021 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-022 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| DST-023 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-024 | LOW | CONFIRMED | AUTO-FULL |  |
| DST-025 | HIGH | PARTIALLY_CONFIRMED | HAND+PHASE0 | two queue systems confirmed; "dead/no producers" contradicted by sync_provider |
| DST-026 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| DST-027 | HIGH | PARTIALLY_CONFIRMED | AUTO-PART |  |
| DST-028 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-029 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-030 | HIGH | CONFIRMED | AUTO-FULL |  |
| DST-031 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-032 | HIGH | CONFIRMED | HAND |  |
| DST-033 | LOW | CONFIRMED | AUTO-FULL |  |
| DST-034 | LOW | CONFIRMED | AUTO-FULL |  |
| DST-035 | HIGH | CONFIRMED | TREE |  |
| DST-036 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-037 | HIGH | CONFIRMED | HAND |  |
| DST-038 | HIGH | CONFIRMED | AUTO-FULL |  |
| DST-039 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-040 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| DST-041 | LOW | CONFIRMED | AUTO-FULL |  |
| DST-042 | LOW | CONFIRMED | AUTO-FULL |  |
| DST-043 | LOW | PARTIALLY_CONFIRMED | AUTO-PART |  |
| DST-044 | MEDIUM | PARTIALLY_CONFIRMED | HAND+PHASE0 | JSON-shape parsing in domain confirmed; no HTTP calls found |
| DST-045 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| DST-046 | LOW | CONFIRMED | AUTO-FULL |  |
| DST-047 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| HL-01 | CRITICAL | CONFIRMED | HAND |  |
| HL-02 | CRITICAL | CONFIRMED | HAND |  |
| HL-03 | CRITICAL | CONFIRMED | TREE |  |
| HL-04 | HIGH | PARTIALLY_CONFIRMED | AUTO-PART |  |
| HL-05 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| HL-06 | HIGH | CONFIRMED | AUTO-FULL |  |
| HL-07 | MEDIUM | CONFIRMED | HAND |  |
| HL-08 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| HL-09 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| HL-10 | LOW | CONFIRMED | HAND |  |
| HL-11 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| HL-12 | HIGH | CONFIRMED | HAND |  |
| HL-13 | HIGH | CONFIRMED | HAND |  |
| HL-14 | MEDIUM | CONFIRMED | TREE |  |
| HL-15 | HIGH | PARTIALLY_CONFIRMED | HAND+PHASE0 | fact true; "add return" recommendation wrong; real defect is error classification |
| HL-16 | HIGH | CONFIRMED | HAND |  |
| HL-17 | HIGH | CONFIRMED | HAND |  |
| HL-18 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| HL-19 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| HL-20 | MEDIUM | CONFIRMED | TREE |  |
| HL-21 | HIGH | CONFIRMED | HAND |  |
| HL-22 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| HL-23 | MEDIUM | CONFIRMED | TREE |  |
| HL-24 | HIGH | CONFIRMED | HAND |  |
| HL-25 | HIGH | CONFIRMED | HAND |  |
| HL-26 | MEDIUM | PARTIALLY_CONFIRMED | HAND+PHASE0 | only 1 _fmt site now; duplication reduced vs claim of 7 |
| HL-27 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| HL-28 | HIGH | PARTIALLY_CONFIRMED | AUTO-PART |  |
| HL-29 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| HL-30 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| HL-31 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| HL-32 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| HL-33 | LOW | CONFIRMED | AUTO-FULL |  |
| HL-34 | MEDIUM | CONFIRMED | HAND |  |
| HL-35 | LOW | PARTIALLY_CONFIRMED | AUTO-PART |  |
| HL-36 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| HL-37 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| HL-38 | LOW | CONFIRMED | AUTO-FULL |  |
| HL-39 | MEDIUM | PARTIALLY_CONFIRMED | HAND+PHASE0 | indicators card is config-driven; hardcoded durations live in timer widget |
| HL-40 | MEDIUM | CONFIRMED | HAND |  |
| HL-41 | LOW | CONFIRMED | HAND |  |
| HOM-001 | HIGH | CONFIRMED | HAND |  |
| HOM-002 | HIGH | PARTIALLY_CONFIRMED | HAND+PHASE0 | kDebugMode guard exists; latent risk only, severity overstated |
| HOM-003 | MEDIUM | CONFIRMED | HAND |  |
| HOM-004 | LOW | CONFIRMED | AUTO-FULL |  |
| PERM-001 | MEDIUM | CONFIRMED | AUTO-FULL |  |
| ROU-001 | MEDIUM | PARTIALLY_CONFIRMED | AUTO-PART |  |
| ROU-002 | LOW | CONFIRMED | AUTO-FULL |  |
| ROU-003 | LOW | PARTIALLY_CONFIRMED | AUTO-PART |  |
| SEC-001 | Informational (ظ„ط§ ظ…ط®ط§ظ„ظپط©) â€” CONFIRMED CLEAN | CONFIRMED | TREE |  |
| SEC-002 | LOW | CONFIRMED | HAND |  |
| SET-001 | LOW | CONFIRMED | AUTO-FULL |  |
