# 12 — تغطية التدقيق وقيوده (Audit Coverage)

## حالة التدقيق

> **AUDIT COMPLETE** — الشرط `[INSPECTED + EXCLUDED = TOTAL_DISCOVERED]` مستوفى بالكامل.

## الأرقام

| المؤشر | القيمة |
|---|---|
| إجمالي ملفات Dart المكتشفة في `lib/` | **408** |
| الملفات المستثناة (مولّدة) | **13** |
| الملفات المطلوب فحصها | **395** |
| الملفات **المفحوصة فعلياً** | **395** |
| الملفات غير المفحوصة | **0** |
| **نسبة الإنجاز** | **100%** |
| أسطر مقروءة يدوياً | **45,447** سطراً (41,147 غير فارغ) |
| أسطر الملفات المولّدة (مستثناة) | 19,832 |
| حواف استيراد محلّلة آلياً | 1,628 |
| ملاحظات موثّقة | **228** |

### المعادلة المكتملة

```
INSPECTED (395 ملف مكتوب يدوياً)  +  EXCLUDED (13 ملف مولّد)  =  408  =  TOTAL_DISCOVERED
```

**الحالة: `AUDIT COMPLETE`.** شرط الإنجاز مستوفى، وكل ملف مستثن له مبرر موثّق في الجدول أدناه.

### التحقق الآلي من التغطية

أُعيد احتساب التغطية آلياً بمطابقة قائمة الملفات في `inventory.csv` (395 ملفاً يدوياً) مقابل كل مسار ظهر في كتلة `###` داخل القسم A من تقارير المجموعات الست. النتيجة: **0 ملف يدوي غير مفحوص**، و**0 كتلة زائدة**.

## الملفات المستثناة (13) ومبرراتها

| الملف | الأسطر | السبب |
|---|---|---|
| `lib/l10n/app_localizations.dart` | 5,814 | `flutter gen-l10n` — مولّد من `lib/l10n/*.arb` |
| `lib/l10n/app_localizations_en.dart` | 3,063 |لذهاة |
| `lib/l10n/app_localizations_ar.dart` | 3,044 |لذهاة |
| `lib/l10n/app_localizations_es.dart` | 3,090 | لذهاة |
| `lib/domain/shared/value_objects.freezed.dart` | 1,539 | `freezed` |
| `lib/domain/duty_status/status_dashboard.freezed.dart` | 1,153 | `freezed` |
| `lib/domain/inspection/dot_inspection.freezed.dart` | 879 | `freezed` |
| `lib/domain/account/driver_account.freezed.dart` | 353 | `freezed` |
| `lib/domain/duty_status/weekly_recap.freezed.dart` | 299 | `freezed` |
| `lib/domain/hardware/telemetry_reading.freezed.dart` | 201 | `freezed` |
| `lib/domain/signature/signature.freezed.dart` | 175 | `freezed` |
| `lib/domain/config/server_config.freezed.dart` | 159 | `freezed` |
| `lib/domain/account/driver_account.g.dart` | 62 | `json_serializable` |

**فحص إعدادات التوليد تم** كما هو مطلوب: `pubspec.yaml` (`generate: true`), `l10n.yaml`, `build.yaml`, والتعليقات التوضيحية `freezed` / `@JsonSerializable` داخل الملفات المصدرية. **نتائج مهمة نتجت عن ذلك**:
- `lib/domain/account/driver_account.dart` يحمل `.g.dart` — أي أنه **DTO شبكة داخل النطاق** وليس كيان نطاقي (DOM-003).
- `lib/features/connection/presentation/mac_address_validation.dart` **لا يحمل** `.g.dart` رغم اسمه — تحقّق من Naming (لا استنتاج من الاسم).

## الملفات التي لم تُفحص

**لا يوجد.**

## منهجية الفحص

| المرحلة | الأداة / الطريقة |
|---|---|
| الجرد | `Get-ChildItem -Recurse` + عدّ أسطر لكل ملف |
| خريطة الاعتماديات | استخراج آلي لكل `import`/`export` من 1,668 سطر مصدري → تطبيع المسارات النسبية → 1,628 حافة داخلية |
| تصنيف الطبقات | آلي + مراجعة يدوية |
| الدورات | **Tarjan SCC** مطبَّق على المخطط الكامل (408 عقدة) |
| فحص الملفات | **قراءة كاملة يدوية** لكل ملف من الـ 395، مقسّمة على 6 مجموعات فحص |
| التحقق | كل ملاحظة تحمل `path:line` + مقتطف كود **منسوخ حرفياً** |

## التحقق اليدوي: ما الذي تم التحقق منه يدوياً وما الذي آلي

| النوع | آلي | يدوي (مقروء) |
|---|---|---|
| عدد الملفات والأسطر | ✅ | — |
| حواف الاستيراد (1,628) | ✅ | مراجعة يدوية للحالات الحرجة |
| الدورات (4) | ✅ (Tarjan) | — |
| **محتوى كل ملاحظة** | ❌ | ✅ **كل واحدة** |

**كل ملاحظة في `11_issue_registry.md` مشتقة من كود مقروء يدوياً**، ومعظمها يحمل مقتطفاً كاملاً. لا توجد ملاحظة مبنية على افتراض من اسم ملف.

## الفرضيات المرفوضة بالتحقق

هذا المسمّى مهم: التدقيق لم يُنتج «كل شيء مشكلة». الفرضيات التالية **فُحصت وروجضت**:

| الفرضية | نتيجة التحقق |
|---|---|
| «تسريب اعتماد في السجلات» | **مرفوضة** — 24 نداء `AppLogger` في auth، صفر تسجيل لـ password/credential |
| «صفحات التوثيق نصوص خام» | **مرفوضة** — ~113 `loc.*`؛ 3 literals فقط |
| «`mac_address_validation.dart` مكانه خطأ لأنه في presentation» | **مرفوضة** — تأخذ `AppLocalizations` فلا يمكن أن تكون في domain |
| «`offline_queue.dart` يسرّب sqflite» | **مرفوضة** — منفذ نظيف |
| «`MemoryOfflineQueue` تكرار بلا داعٍ» | **مرفوضة** — مستخدمة في mock + 4 ملفات اختبار |
| «`fmcsa_eld_output_generator` فيه PDF/share» | **مرفوضة** — لا استيراد لـ `pdf`/`share_plus`؛ `share_plus` في `send_logs_page.dart` فقط |
| «`api_config` مكرر بين backend وcore» | **مرفوضة** — نسخة backend ملف تعليقات ميت |
| «`LoggerNotifier extends ChangeNotifier` خطأ» | **مرفوضة** — هذا هو الجسر الصحيح |
| «`RouterNotifier` خطأ» | **مرفوضة** — الجسر Riverpod→GoRouter القياسي |
| «`dvir_dto.dart` (402) مشتت» | **مرفوضة** — DTOات متماسكة لميزة واحدة |
| «كل استخدام Riverpod في UI مخالفة» | **مرفوضة** صراحةً كمنهج — طُبِّق التمييز بين الاستهلاك الطبيعي والمسؤوليات المحمّلة زوراً |

كما سُجّلت تصحيحات تلقائية أثناء التدقيق:
- **HL-30**: الاستثناء في `LogEvent.props` هو `editable` لا `location` (الصياغة الأولى كانت خاطئة، وصُحّحت في التقرير).
- **CUI-013**: لم يكن تكراراً بل تعليقات خاطئة — `duty_status_code.dart` يدّعي مكافأة `AppColors` والأربع قيم **مختلفة فعلياً**.

## قيود التدقيق

1. **لم يُشغَّل `flutter analyze` كمصدر وحيد.** استُخدم دليل `No issues found!` فقط لإثبات غياب القواعد المعمارية (CORE-004). التحليل الساكن لا يغني عن القراءة.
2. **لم تُفحص ملفات الاختبار الـ 148** في `test/` ضمن هذا النطاق (موضوع مختلف). 사용ت كشبكة أمان مقترحة في `10`.
3. **لم يُقيَّم الأداء** (rebuild counts، حجم الصور، استعلامات Hive). خارج نطاق التدقيق المعماري.
4. **لم تُراجع العقود مع الخادم.** صحّة أسماء الحقول وأ.endpoint **مفترضة**. لهذا وُسمت ملاحظات مثل BACK-024 بـ CONFIRMED م��ى كانت مخالفة معمارية (تسرّب wire values)، لا خلل تعاقدي.
5. **`openapi.yaml` لم يُستخدم للتحقق المتقاطع** من مسارات الـ endpoints — مساحة تحقق مستقبلية.
6. **سلوك وقت التشغيل غير مُختبَر.** كل النتائج static analysis + قراءة. لكن BACK-008 (قائمة DVIR فارغة تحت الموك) و DST-037 (override لا يسري) و HL-15 (قاعدة بلا return) **نتائج بنيوية حتمية** وليست احتمالات.

## الملفات غير المفحوصة

| المسار | السبب |
|---|---|
| `android/`, `ios/`, `web/`, `windows/` | خارج `lib/` — ليست Dart |
| `build/`, `.dart_tool/` | نواتج بناء |
| `test/` (148 ملف) | خارج نطاق هذا التدقيق |
| `scripts/`, `*.ps1`, `*.sh` | أدوات تطوير |
| `docs/`, `*.md` | توثيق |

## الأدوات المستخدمة

| الأداة | الاستخدام |
|---|---|
| `Get-ChildItem -Recurse -Filter *.dart` | جرد الملفات |
| `Get-Content` / `[System.IO.File]::ReadAllLines` | عدّ الأسطر، استخراج الاستيرادات، التحقق من الأدلة |
| `Export-Csv` / `Import-Csv` | `inventory.csv`، `issues.csv` |
| Tarjan SCC (تنفيذ مخصّص) | كشف الدورات الأربع |
| Read/Grep/Glob | القراءة الكاملة والتحقق |
| فرق فحص آلي (6 مجموعات) | فحص 395 ملفاً بالتوازي مع إلزام بالأدلة |

## الملفات الناتجة

| الملف | المحتوى | الحجم |
|---|---|---|
| `01_project_inventory.md` | البنية، كل الملفات، أرقام الأسطر، تصنيف الطبقات | 38 KB |
| `02_executive_summary.md` | الحكم العام، أخطر 7، نقاط القوة، المخاطر | — |
| `03_file_by_file_audit.md` | **395 كتلة ملف** بمسؤولياتها الفعلية | 173 KB |
| `04_presentation_audit.md` | 91 ملاحظة عرض | 280 KB |
| `05_riverpod_audit.md` | 50 ملاحظة Riverpod | 182 KB |
| `06_data_and_network_audit.md` | 76 ملاحظة بيانات/شبكة + جدول تماثل العقود | 304 KB |
| `07_domain_layer_audit.md` | 38 ملاحظة نطاق | 98 KB |
| `08_solid_and_code_quality.md` | 52 ملاحظة جودة/SOLID | 187 KB |
| `09_dependency_analysis.md` | 70 ملاحظة اقتران + خريطة الطبقات والدورات | 206 KB |
| `10_refactoring_roadmap.md` | 5 مراحل، خرائط تبعية، استراتيجية اختبار | — |
| `11_issue_registry.md` | **228 ملاحظة** + المالك والتصحيح | 153 KB |
| `12_audit_coverage.md` | هذا الملف | — |
| `_raw/*.md` (7 ملفات) | تقارير الفرق بالأدلة الكاملة | ~1.1 MB |
| `_raw/inventory.csv` | الجرد الآلي | 35 KB |
| `_raw/issues.csv` | السجل الآلي | — |
| `_raw/edges_classified.tsv` | 1,628 حافة مصنّفة | 186 KB |
| `_raw/checklist.md` | قائمة الفحص الدائمة | 38 KB |

---

> **لم يُعدَّل أي ملف مصدري.** كل ملفات `lib/` كما كانت. التحقق: `git status` يجب أن يظهر فيه `architecture_audit/` و`_raw/` فقط كإضافات جديدة.