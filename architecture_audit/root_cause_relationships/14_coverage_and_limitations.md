# 14 — التغطية والقيود (Coverage & Limitations)

## 1. قائمة التتبع — الجذور الثمانية ✅ 8/8

| RC | التحقق | الحكم |
|---|---|---|
| A | مفكك لـ A1/A2/A3 بأدلة منفصلة | COMPOSITE |
| B | 5 وقائع + 16 حافة مقاسة | CONFIRMED_SYSTEMIC |
| C | Tarjan + دورة دنيا + تبادل مباشر | CONFIRMED_SYSTEMIC |
| D | آلية + نسخ + فجوات مفصولة | COMPOSITE |
| E | 7 مسارات + 14 حافة + 5 كتابات | CONFIRMED_SYSTEMIC |
| F | عملة + تحليل + صيانة مفصولة | COMPOSITE |
| G | قناة + تخمين + اختبار فاشل مُشغَّل | CONFIRMED_SYSTEMIC |
| H | 19 علامة + غياب lint + تجريدات ميتة | PARTIALLY (مُمكِّن) |

## 2. قائمة التتبع — الأزواج الثمانية والعشرون ✅ 28/28

| الزوج | الحكم | الزوج | الحكم |
|---|---|---|---|
| A-B | SHARED | C-F | INDEPENDENT |
| A-C | INDEPENDENT | C-G | INDEPENDENT |
| A-D | INDEPENDENT | C-H | INDEPENDENT |
| A-E | SHARED | D-E | CORRELATED_ONLY |
| A-F | INDEPENDENT | D-F | INDEPENDENT |
| A-G | INDEPENDENT | D-G | INDEPENDENT |
| A-H | CORRELATED_ONLY | D-H | INDEPENDENT |
| B-C | INDEPENDENT | E-F | DIRECT (F→E) |
| B-D | INDEPENDENT | E-G | MUTUAL |
| B-E | INDEPENDENT | E-H | INDEPENDENT |
| B-F | SHARED | F-G | CORRELATED_ONLY |
| B-G | INDEPENDENT | F-H | INDEPENDENT |
| B-H | CORRELATED_ONLY | G-H | INDEPENDENT |
| C-D | INDEPENDENT | C-E | INDEPENDENT |

19 استقلال + 4 ترابط + 3 مشترك + 1 مباشر + 1 متبادل = 28. **صفر UNKNOWN** — كل زوج حُسم بدليل أو بدليل سلبي موثّق (B-C: تصحيح المفتاح؛ C-H/E-H/G-H: صفر علامات على ملفاتها).

## 3. قائمة التتبع — الآليات المشتركة ✅

M1 مؤكدة، M2 مؤكدة، M3 مدمجة، M4 مرفوضة، M5 تخصيص، M6 خلفية، M7 مؤكدة كخلفية.

## 4. قائمة التتبع — سلاسل المسؤولية الحرجة ✅

W1 (auth)، W2 (HOS)، W3 (inspection)، W4 (DVIR)، W5 (codriver)، W6 (tracking) — كلها متتبعة حلقة بحلقة مع الانحرافات.

## 5. القيود الصريحة

1. **ساكن فقط** (عدا اختبار واحد مُشغَّل). لا سلوك ميداني.
2. **لا فحص حيّ** للخادم. لا كود أصلي. لا أداء. لا `.arb`. لا `docs/`.
3. **فرضية الاستمرارية**: الشجرة ≡ شجرة التدقيق عدا ملفي (مبررة بتطابق مجموعة الـ63).
4. **تضارب المصالح**: مُدقق EC-0.2a هو مُنفذه — خُفف بتوثيق عيوب التنفيذ ضده (C8، المفاتيح الخام) وبتوصية غير مغلقة.
5. **السياق**: ~25 ملفاً قُرئت كاملة + ~60 مقاطع + قياسات آلية كاملة (1,726 حافة). ليست قراءة 408 ملفات من جديد — بل **إعادة تحقق مستهدفة** لكل ادعاء مستشهد به.
6. **الأدوات**: Read/Grep/Glob، `flutter test` (ملف واحد)، `git diff/status/log`، سكربتات PowerShell مؤقتة في `%TEMP%/opencode/diag` (تحليل فقط، ليست جزءاً من التسليم)، Tarjan.
7. **اللغة**: التقارير بالعربية؛ المصطلحات والمسارات والمعرفات بالإنجليزية. أسطر الشيفرة المقتبسة حرفية.
8. **عدم اكتمال مزعوم**: لا شيء أُجّل — كل البنود الإلزامية الـ14 مكتملة. البنود المفتوحة (Q1-Q8) أسئلة بحثية لا نقص تغطية.
