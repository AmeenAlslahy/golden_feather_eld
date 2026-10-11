# 01 — خط الأساس (Baseline)

> **النطاق:** توثيق حالة المستودع قبل أي تنفيذ. **لم يُعدَّل أي ملف مصدري.**

## 1.1 هوية المستودع

| البند | القيمة |
|---|---|
| Branch | `temp-fixes` |
| Commit HEAD | `e11312986abdffe82d401b564a3c2580c1d3cdde` |
| آخر 3 رسائل | `e113129` Stage 2B-1 Part 1: event ownership foundation and durable quarantine storage · `4e87aef` P0 session isolation (Stage 1) + logout request-leak fix · `7bde9db` تعديلات معتمدة من مالك المشروع |
| Remote | لم يُفحص (غير مطلوب) |

> **ملاحظة حاسمة:** آخر commitين عنوانهما صراحةً **`P0 session isolation (Stage 1)`** و **`Stage 2B-1 Part 1`**. أي أن **جزءاً من عمل Phase 0 مُنجَز ومُدمج بالفعل**، والتدقيقArchitecture يجب أن يُقرأ على هذا الأساس لا كأنه لم يبدأ.

## 1.2 حالة شجرة العمل

| الفئة | العدد |
|---|---|
| ملفات معدَّلة (modified / not staged) | **63** |
| ملفات غير متتبَّعة (untracked) من كود المشروع | **3** |
| **الإجمالي (بلا مخرجات التدقيق)** | **66** |

> الأرقام أعلاه **مصحَّحة**. القياس الأول أعطى «4 untracked» وكان يتضمّن `architecture_audit/` (مخرجات التدقيق) وليس ملفاً من المشروع. القياس الدقيق أدناه.

### الملفات غير المتتبَّعة من كود المشروع (3) — تُحفظ كما هي

```
lib/features/sync/domain/entities/dispatch_auth.dart
test/backend/http/interceptors/dispatch_send_time_test.dart
test/features/sync/dispatch_ownership_test.dart
```

> `test/features/sync/queue_ownership_storage_test.dart` **ليس** untracked — هو متتبَّع ومُدمج في `e113129`. مُتحقَّق بـ `git log -- <path>`.

الملف الأول **جزء من كود الإنتاج** غير المتتبَّع (`lib/.../dispatch_auth.dart`). هذا يعني أن `git stash` أو أي عملية تعتمد على tracked files **ستُخرج التطبيق من حالة البناء**. تحذير تشغيلي.

### توزيع الـ 63 ملفاً المعدَّلاً

| المجموعة | العدد | ملاحظة |
|---|---|---|
| `lib/backend/**` | 13 | يشمل `contracts/daily_logs_backend.dart`, `contracts/dvir_backend.dart`, `auth_interceptor.dart` — **داخل نطاق Phase 0** |
| `lib/core/**` | 4 | `app_error.dart`, `failure.dart`, `api_client.dart`, `theme/app_theme.dart` |
| `lib/features/**` | 37 | يشمل **`duty_status_tracker.dart`**, `codriver_provider.dart`, `home_page.dart`, `dvir/*` عبر `logs/presentation` |
| `lib/l10n/**` | 7 | `*.arb` + 4 ملفات مولّدة |
| `test/**` | 5 | `duty_status_tracker_test.dart`among others |

> **تعارض مباشر مع Phase 0:** الملفان `duty_status_tracker.dart` (البند 0.1) و`codriver_provider.dart` (البند 0.2) **معدَّلان بالفعل وغير مُودَعين**. أي تنفيذ_BUFدهما يجب أن يُطبَّق فوق التعديلات الحالية لا فوق نسخة HEAD.

## 1.3 الأدوات والإصدارات

| الأداة | الإصدار |
|---|---|
| Flutter | **3.47.2** (stable, revision `d3b14c8769`, 2026-08-26) |
| Dart | **3.13.2** (stable, 2026-08-25) |
| DevTools | 2.60.0 |
| Platform | `windows_x64` |

> **ملاحظة توافق:** `pubspec.yaml` يطلب `sdk: '>=3.8.0 <4.0.0'` و `flutter: '>=3.32.0'`. SDK الفعلي 3.13.2 / Flutter 3.47.2 — متوافقان.

## 1.4 البنية التحتية للاختبار

| البند | القيمة |
|---|---|
| إجمالي ملفات الاختبار | **148** |
| إطار الاختبار | `flutter_test` + `mocktail` + `http_mock_adapter` + `sqflite_common_ffi` |
| مجلد بيانات الاختبار | `test_hive_dir/` (موجود في جذر المشروع) |
| تحليل الساكن | `analysis_options.yaml`: `flutter_lints` فقط — **لا توجد قاعدة `architecture`** |

### ملفات الاختبار المتعلقة ببنود Phase 0

| البند | ملف الاختبار الموجود | الحالة |
|---|---|---|
| 0.1 | `test/core/engine/tracking/duty_status_tracker_test.dart` (756 سطر) | موجود — **و فيه اختبار فاشل** |
| 0.2 (inspection) | **لا يوجد** لـ `InspectionRepositoryImpl` | **مفقود** |
| 0.2 (codriver) | `test/features/codriver/data/repositories/codriver_repository_impl_test.dart` | موجود — لا يغطي العزل |
| 0.3 | `test/backend/adapters/mock/sub/mock_dvir_backend_test.dart`, `test/features/dvir/**` (7 ملفات) | موجود |
| 0.4 | `test/features/account/presentation/rules_page_test.dart` | موجود |
| 0.5 | `test/features/home/presentation/pages/home_page_test.dart` | موجود |
| 0.6 | `test/app/orchestrators/tracking_orchestrator_test.dart` | موجود — لا يغطي التوحيد |
| 0.7 | — | لا ينطبق |
| 0.8 | `test/backend/http/interceptors/auth_interceptor_test.dart`, `auth_interceptor_epoch_test.dart` | موجود |
| 0.9 | **لا يوجد** | **مفقود** |

### اختبارات عزل الجلسة الموجودة (من工作在 Stage 1)

```
test/features/session/session_isolation_test.dart        (6 سيناريوهات)
test/features/session/session_epoch_401_test.dart
test/features/session/session_navigation_test.dart
test/features/sync/dispatch_ownership_test.dart          (untracked)
test/features/sync/queue_ownership_storage_test.dart     (tracked — merged in e113129)
test/backend/http/interceptors/auth_interceptor_epoch_test.dart
```

هذه **أصل معead** لبناء اختبارات البند 0.2 عليها — لا حاجة لاختبار عزل جديد من الصفر.

## 1.5 خط أساس الاختبارات — **13 فشلاً سابقاً للتدقيق**

تم التشغيل فعلياً:

```
flutter test test/features/session/ test/core/engine/tracking/duty_status_tracker_test.dart \
            test/features/codriver/ test/features/dvir/ \
            test/backend/http/interceptors/ test/features/account/
→ 00:35 +68 -9   (المجموعة الأولى)
→ +68 -13        (المجموعة الموسّعة)
```

### قائمة الفشل (-allpreexisting، لم يُعدَّل شيء)

| # | الملف | السيناريو |
|---|---|---|
| 1 | `test/core/engine/tracking/duty_status_tracker_test.dart` | **`server rejection does not change local duty status`** |
| 2 | `codriver_page_test.dart` | `shows server link state and SWITCH is disabled with nobody selected` |
| 3 | `codriver_page_test.dart` | `SRS 5.8: HOS isolation line comes from /team and is verbatim` |
| 4 | `codriver_page_test.dart` | `linked co-driver shows the server team state; refresh re-reads it` |
| 5 | `codriver_page_test.dart` | `picking a co-driver selects it locally — no management endpoint call` |
| 6 | `codriver_page_test.dart` | `SWITCH refuses when vehicle motion is unknown — no server call` |
| 7 | `codriver_page_test.dart` | `SWITCH while stopped: confirm → switchPrimary → home` |
| 8 | `codriver_page_test.dart` | `server refusal on switch is shown to the driver, no navigation` |
| 9 | `codriver_page_test.dart` | `no daily log today → no isolation line, no invented state` |
| 10 | `dvir_form_defects_test.dart` | `re-opening defects catalog preserves previous selections` |
| 11 | `dvir_list_page_test.dart` | `summary row counts Total / Open / Signed / OOS from the loaded list` |
| 12 | `info_packet_page_test.dart` | `complete packet per server → no status line, two blocks only` |
| 13 | `info_packet_page_test.dart` | `server says complete but a mandatory item is missing → incomplete` |

### دلالات هذا الخط الأساس

1. **الفشل رقم 1 يقع مباشرة في نطاق البند 0.1** — وهو **الدليل التجريبي على وجود خلل حقيقي** لا مجرد ادعاء. التفاصيل في `02_findings_verification.md` §0.1.
2. **8 من 13emu遗产 في `codriver_page_test.dart`** — أي أن ميزة codriver (البند 0.2) **غير مستقرة أصلاً**. أي إصلاح لـ 0.2 يجب أن يُقاس على هذه القاعدة المتكسورة، لا على قاعدة نظيفة.
3. هذه الإخفاقات **ليست ناتجة عن هذا التدقيق**. لم يُجرَّ أي تعديل قبل تشغيلها.

> **قاعدة إلزامية للم��نف:** يُقاس نجاح أي إصلاح Phase 0 على **`13 failing → 13 failing` لا أكثر**. أي فشل جديد هو انحدار مُحدث.

## 1.6 قيود خط الأساس

- لم يُشغَّل `flutter test` على كامل الـ 148 ملفاً (لمدة). ما سبق مجموعة **مركَّزة** على نطاق Phase 0.
- لم يُشغَّل `flutter analyze`. النتيجة المتوقعة معروفة مسبقاً من التدقيق: **لا توجد قاعدة معمارية مفروضة**، فالمحلل لا يضيف دليلاً هنا.
- لم يُفحص `pubspec.lock` لأمان التبعيات (خارج النطاق).
- لم يُنفَّذ أي `git`命令 يغيّر الحالة (no reset / checkout / clean / stash / commit).

## 1.7 قواعد الحفظ الإلزامية

```
ممنوع منعاً باتاً:
  git reset --hard          git checkout -- .        git clean -fd
  git stash                 git add -A               git commit

الإجراء المسموح الوحيد عند التنفيذ:
  • تعديل ملفات محددة بالـ Edit/Write
  • git diff -- <file>  للقراءة فقط
  • git stash push -- <file>^ كنسخة احتياطية فردية إن لزم (يُحفظ ولا يُدمج)
```