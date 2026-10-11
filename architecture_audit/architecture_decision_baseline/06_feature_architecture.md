# 06 — بنية الميزات (Feature Architecture)

> 9 ميزات ممثلة + 4 عرضية + ملاحظة connection. "لا طبقات فارغة مختلقة" — والشجرة ملتزمة بذلك فعلاً (5 ميزات عرضية بلا data/domain).

## 1. المصفوفة

| الميزة | الطبقات | الحالة | الأعمال | المستودع | مسار الخلفية | الحقن | عابر | الأخطاء | الكاش | الاختبار |
|---|---|---|---|---|---|---|---|---|---|---|
| auth | 3 | StateNotifier + use-cases رفيعة + epoch | UseCase شكلي مكرر | تركيب مركزي + تخزين جلسة آمن | عقد→محوّل | مركزي | — | مصنّفة | جلسة مُسيَّجة | epoch tests |
| hos | 3 | Notifiers منسقة + محرك حقيقي + متتبع مثقل | محرك نقي + ازدواج فحص الحركة | 108 سطر (رفيع؟) | عقد→محوّل | مزود data | →logs/sync تركيباً | تخمين شبكي | مؤقت دقيقة | 14✅/1❌ (الفاشل يثبت عيباً) |
| inspection | 3 | providers + مستودع مُحكَم (بعد EC-0.2a) | تحقق ملكية في المستودع | **504**: backend+ملكية+FMCSA+بوابة | عقد→محوّل | مزود data | →logs تركيباً | مرفوضات صريحة | epoch+owner | 20+8 جديدة ✅ |
| dvir | 3 | Notifier منسق + حالة تحمل قاعدة §396.13 | حل الهوية في الصفحة (RegExp) | خرائط + طابور | عقد→محوّل | مزود data | →vehicle/home | خام | autoDispose | 7 ملفات اختبار |
| logs | 3 | Notifiers + `Ref?` + كتابة عابرة | تحقق/تحويل في العرض والمتحكمات | 501 سطر (مكتظ) + مصادر Hive | عقدان→محوّل | مزود data (7 حقن!) | →home كتابةً | خام | fallback يدوي | موجودة |
| codriver | 3 | Notifier مسيّج جزئياً + حارس أدوار عابر | اختيار/تبديل في المزود | static بلا إبطال | عقد جلسة | مزود data | →HOS/TRACKING (5 ملفات) | خام | static ميت الإبطال | 7 إخفاقات سابقة |
| tracking | 3 | Notifier + قناة أصلية + SDK | جودة موقع في مصدر البيانات | تنسيق 4 مداخل + صلاحيات | SDK أصلي + عقد | **مزدوج مكسور** | منسق app | مبتلَعة جزئياً | — | orchestrator tests |
| vehicle | 3 | مزود + اختيار مكرر 3× | تحليل wire في النطاق + قاعدة مكررة | 74 سطر (رفيع مشروع) | عقد→محوّل | مزود data + alias أعمى | →home | رموز HTTP في النطاق | — | — |
| account | pres+app | مزود مسيّج + use-case بمزوده | دمج إعدادات في use-case | عبر `backend/*` مباشرة (بلا data!) | عقد مباشر من العرض | مزود use-case محلي | →auth/home | `Exception(l10nKey)` | owner/seq | rules_page tests |

## 2. الميزات العرضية (about/onboarding/permissions/settings/home)

- بلا `data/` ولا `domain/` — **صحيح**: لا طبقات فارغة.
- الاستثناء: `home` تحمل `dashboard_provider` (ترويسة جلسة تُكتب من 3 ميزات) + `EldDrawer` (يُستورد من 5 صفحات) — `home` هي shell التطبيق متنكراً كميزة.

## 3. `connection`: الحالة الخاصة

- `domain/` **موجود** (3 ملفات تحليل/قراءة) ومُستخدم (`hardware_status_provider` + `about_page` + خلفية hardware).
- لكن التنسيق (`EldConnectionNotifier` + 5 تبعيات بنية) يعيش في ملف الصفحة (494 سطراً: حالة+notifier+صفحة+checklist).
- الحكم: ليست "بلا نطاق" — بل **التنسيق يتجاوز النطاق الموجود**.

## 4. أنماط الحقن عبر الميزات

| النمط | أين |
|---|---|
| مزود تركيب `data/providers` يراقَبه العرض | logs, hos, inspection, dvir, vehicle, codriver, tracking, sync (المعيار الفعلي) |
| تركيب مركزي خارجي | auth فقط (`core/di`) |
| مزود محلي بجانب المنطق | account (`updateRulesUseCaseProvider`)، tracking (`trackingServiceProvider`) |
| alias تمريري | `vehicleBackendProviderAlias` (يمرر فقط — بلا مبرر ظاهر) |

## 5. معالجة الأخطاء والتخزين عبر الميزات

- الأخطاء: خام في الحالة (logs/dvir/codriver/account) مقابل مصنّفة (hos engine) مقابل مرفوضة صريحة (inspection بعد الإصلاح).
- الكاش: `guardedNetwork`+`offline:` في الكل؛ السياسات (epoch/owner/`cacheFor`/static/لا شيء) مختلفة لكل ميزة.
