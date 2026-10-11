# 01 — خط الأساس: Git والشجرة المصدرية (Git & Source Baseline)

> كل الأرقام أدناه مقاسة بأوامر مباشرة على الشجرة الحالية. لا تعديل، لا التزام، لا أوامر مدمرة.

## 1. حالة Git

| البند | القيمة |
|---|---|
| الفرع | `temp-fixes` |
| HEAD | `e113129` — "Stage 2B-1 Part 1: event ownership foundation and durable quarantine storage" |
| ملفات معدّلة (غير مُرحّلة) | **66** (64 عند بدء المهمة + 2 تغيّرا أثناءها — انظر §8) |
| ملفات غير متتبعة | **5** |

## 2. الملفات غير المتتبعة (5)

| المسار | الطبيعة |
|---|---|
| `architecture_audit/` | مخرجات التدقيق والتشخيص نفسها (توثيق فقط) |
| `lib/features/sync/domain/entities/dispatch_auth.dart` | كود إنتاج جديد (ملكية الإرسال — Stage 2B-1) |
| `test/backend/http/interceptors/dispatch_send_time_test.dart` | اختبار جديد |
| `test/features/inspection/data/` | اختبارات EC-0.2a الجديدة (عزل + مراجعة + توافق) |
| `test/features/sync/dispatch_ownership_test.dart` | اختبار جديد |

## 3. الملفات المعدّلة (64): التوزيع

| النطاق | العدد | الأبرز |
|---|---|---|
| `lib/backend/` | 13 | 8 sub-adapters + 4 contracts + `auth_interceptor` (سياج `expectedOwnerDriverId` و`SessionEpoch`) |
| `lib/core/` | 4 | `app_error`، `failure`، `api_client`، `app_theme` |
| `lib/features/` | 35 | `duty_status_tracker`، `codriver_provider`، `home_page`، `eld_connection_page`، `sync/*` (5)، `logs/*` (11)، `hos/*` (6)، `inspection/*` (3)، `vehicle_provider` |
| `lib/l10n/` | 7 | 3× `.arb` + 4 ملفات مولّدة |
| `test/` | 5 | `duty_status_tracker_test`، `app_error_test`، `change_status_page_test`، `send_logs_page_test`، `trailers_page_test` |

إجمالي الفرق: `2306 insertions(+), 676 deletions(-)`.

## 4. التغييرات ذات الصلة منذ التدقيق السابق

> فرضية الاستمرارية الموثقة: الشجرة الحالية ≡ شجرة التدقيق **عدا** ما يلي (مجموعة `M` تطابق توزيع خط الأساس المسجل في `phase_0_execution/01_baseline.md`: 13+4+37+7+5).

| التغيير | الملفات | الأثر على التشخيص |
|---|---|---|
| **عمل EC-0.2a** (الوحيد اللاحق للتدقيق) | `inspection_repository_impl.dart` + `test/features/inspection/data/` (3 ملفات اختبار جديدة) | DST-002 مُخفَّف؛ أُدخلت مفاهيم جديدة (ملكية مُتحقَّقة، بوابة CSV، رسائل `inspection*`) — موثقة في `implementation_0_2a_correction.md` بحالة `READY_FOR_TECHNICAL_REVIEW` (غير معتمد إنتاجياً) |
| عمل Stage 2B-1 / P0 (سابق للتدقيق، غير مُودَع) | backend subs/contracts، `auth_interceptor`، `sync/*`، `duty_status_tracker` | التدقيق رآها؛ التشخيص الحالي يقرأ الحالة الراهنة مباشرة |

## 5. الملفات المولّدة (مستثناة من التقييم المعماري)

| النمط | المواقع |
|---|---|
| `*.freezed.dart` + `*.g.dart` | `lib/domain/**` (7 أزواج بجانب المصدر اليدوي) |
| `app_localizations*.dart` (4 ملفات) | `lib/l10n/` (من `.arb` عبر `generate: true`) |

## 6. نطاق عمل EC-0.2a (للتمييز عن البنية المُودَعة)

- **ملف إنتاج واحد:** `lib/features/inspection/data/repositories/inspection_repository_impl.dart` (341 سطر diff: ملكية، epoch، بوابة FMCSA).
- **ملفات اختبار:** `test/features/inspection/data/` (عزل + مراجعة نهائية + توافق خلفية).
- **الحالة:** `READY_WITH_LIMITATIONS` — عيب تحقق CSV غير واعٍ بالاقتباس (C8) + 4 مفاتيح خطأ غير مترجمة. **ليست بنية مُودَعة.**

## 7. قواعد الحفظ المطبقة في هذه المهمة

قراءة وتحليل فقط. لم يُنفَّذ `reset`/`checkout`/`clean`/`stash`/`commit`. ملفات التقارير الجديدة كُتبت حصراً تحت `architecture_audit/architecture_decision_baseline/` (داخل مجلد غير متتبَّع أصلاً).

## 8. تغيير خارجي أثناء المهمة (موثّق — ليس من عملي)

> سجل أدوات هذه المهمة لا يحتوي أي كتابة/تحرير لملفات `lib/` (كل الكتابات: تقارير جديدة + سكربتات مؤقتة خارج التسليم). ومع ذلك رُصد أثناء الفحص النهائي ملفان إضافيان:

| الملف | التغيير المرصود (`git diff`) | التوقيت |
|---|---|---|
| `lib/core/widgets/app_text_field.dart` | إضافة معامل `errorText` (3 أسطر: حقل + مُنشئ + تمرير لـ `InputDecoration`) | ~01:13 |
| `lib/features/hos/presentation/pages/change_status_page.dart` | استبدال `TextField` خامين بـ `AppTextField` المشترك (−47/+13 سطراً) مع تغيير طفيف في شرط الخطأ | ~01:17 |

- **الاتجاه معمارياً:** إعادة استخدام الودجت المشترك بدل تكرار `InputDecoration` — يتوافق مع توصية التوحيد، ويُقلّل موضوع HL-41 جزئياً.
- **الأثر على هذا التشخيص:** لا شيء — لا تقرير يستشهد بأي من الملفين (فُحصت المراجع آلياً: صفر إشارة). الأرقام المعتمدة في التقارير هي حالة بدء المهمة (64) ما لم يُذكر خلاف ذلك.
- **الإجراء:** لا دمج ولا عكس ولا تعليق — يُترك لمالك الشجرة. يُسجَّل هنا لمنع أي التباس في النسب.
