# 13 — سجل الأدلة (Evidence Registry)

> كل تشخيص مؤكد أدناه مربوط بدليل من الشجرة الحالية. `HAND` = فحصت/شغّلت بنفسي. `AUTO` = مطابقة آلية + ملف غير متغيّر منذ التدقيق. `TREE` = بحث شجري. `PHASE0` = تحقق سابق مسجّل.

## حقائق مرصودة (OBSERVED FACTS)

| # | الواقعة | الدليل | المنهج |
|---|---|---|---|
| F1 | 1,726 حافة استيراد داخلية (408 ملفات) | سكربت القياس + `edges.tsv` | HAND |
| F2 | 7 حواف `core→features` | 6 في `core/` + 1 في `core/widgets` (مسرودة في 03) | HAND |
| F3 | دورة 25 ملفاً + 3 دورات ثنائية | Tarjan على الشجرة الحالية | HAND |
| F4 | `home_page ↔ driving_lock_screen` متبادل مباشر | الاستيرادان المتبادلان | HAND |
| F5 | 20 حافة pres→data كلها لملفات `providers/` | القائمة الكاملة في 03 | HAND |
| F6 | 14 حافة pres→backend (9 عقود + 3 مباشرة + 2 تنفيذ) | القائمة في 03 | HAND |
| F7 | 9 حواف backend→features (4+2+3) | القائمة في 03 | HAND |
| F8 | 19 علامة `ignore_architecture` في 13 ملفاً + لا lint بنيوي | العدّ + `analysis_options.yaml` | HAND |
| F9 | `BackendRegistry` بلا مستهلك إنتاجي | grep: تعريف + مزود + اختبار فقط | HAND |
| F10 | `trackingServiceProvider` مزدوج + override على أحدهما | `:200` مقابل `:22` + `:41` مقابل `:91` | HAND |
| F11 | `timeAuthorityProvider` افتراضيه ساعة الجهاز | `:24-25` | HAND |
| F12 | `HttpClient()` خام بلا إغلاق | `:136` | HAND |
| F13 | `options.path == '/session'` ميت | `:64` + مسار مطلق في `eld_auth_backend:29-30` | HAND |
| F14 | `static` متبقٍّ في codriver | `:17-18` | HAND |
| F15 | `RegExp(r'\d+')` في DVIR | `:468` | HAND |
| F16 | `{'reports': []}` في الموك | `:20` | HAND |
| F17 | استيرادات tracker المخالفة | `:4,5,11,13` | HAND |
| F18 | `Exception(l10nKey)` + هبوط شبكي | `:22` + `user_facing_message:24` + عرض خام | HAND |
| F19 | `kDebugMode` يقيّد التجاوز | `driving_lock_screen:29` | HAND |
| F20 | `.env` بلا أسرار | المحتوى كاملاً + تعليق `.gitignore:49-52` | HAND |
| F21 | `RawJson` typedef + 34 مستورداً ولا domain | العدّ + grep النطاق | HAND |
| F22 | `duty_status_code` يستورد Flutter | `:7-8` + ألوان `:75-88` | HAND |
| F23 | `offline` سياج owner/epoch منسوخ في ملفين | المقارنة السطرية | HAND |
| F24 | `switchDrivers` بلا سياج (نفس الملف المسيّج) | `:212-237` مقابل `:137-151` | HAND |
| F25 | `DvirNotifier(storageService)` مُهمَل | `:117-125` بلا حقل | HAND |
| F26 | `Ref?` + `?.` في logs_provider | `:94,162,192,214` | HAND |
| F27 | `previousToReview` (§396.13) في كائن حالة | `:45-57` | HAND |
| F28 | `Duration(hours:11)` في `build` | `:125-129` | HAND |
| F29 | `team_status` يحلل `json['data']` | `:26-32` | HAND |
| F30 | كتابة عابرة في dashboard (5 مواقع) | grep شجري | HAND |
| F31 | `EldConnectionNotifier` في ملف صفحة + 24 استيراداً | `:27-248` | HAND |
| F32 | `HosNotifier` يقرأ audit repo مباشرة | `:140` | HAND |
| F33 | `validateManualTransition` قبل `submitManualChange` | `:95-106` + engine `:82-89` | HAND |
| F34 | اختبار `server_rejected` يفشل (`null`) | تشغيل `flutter test` (14✅/1❌) | HAND |
| F35 | `OFFLINE_GENERATED:` بروتوكول نصي طبقتين | repo `:361` + page `:267-268` | HAND |
| F36 | `LogoutUseCase` تُسقط `Either` | repo `:16` مقابل use-case `:9-11` | HAND |
| F37 | 7 ملفات use-case فقط (3 تمريرية) | glob + قراءة | HAND |
| F38 | `updateRulesUseCaseProvider` داخل ملف الـ use-case | `:52-61` | HAND |
| F39 | `app_providers` يركّب مستودعاً واحداً | 25 سطراً كاملة | HAND |
| F40 | `core_providers` يُصدّر `backend_network_providers` | سطر `export` | HAND |
| F41 | `SyncRepository` حي (يستهلكه `sync_provider`) | grep المستهلكين | HAND |
| F42 | `Connection/domain` موجود ومُستخدم | glob + grep المستهلكين | HAND |
| F43 | `vehicle_selection` بلا HTTP (تحليل فقط) | قراءة 153 سطراً | HAND |
| F44 | `daily_form_rules:7` يستورد l10n | grep | HAND |
| F45 | `dvir/vehicle_repo` يستوردان DTO المحوّل | grep الاستيرادات | HAND |
| F46 | `sync_providers.dart:7-8` بـ `ignore_architecture` | القراءة المباشرة | HAND |
| F47 | `account_page:98-102` يعرض `error!` خاماً | القراءة | HAND |
| F48 | `status_radio_group:20-24` خريطة تسميات | القراءة | HAND |
| F49 | 22 `UnimplementedError` في الموك مقابل ~60 دالة عقد | العدّ | HAND |
| F50 | `mock_adapter:32-34` تعليق قديم ("17") | القراءة | HAND |
| F51 | `api_config.dart` الخلفي معلّق بالكامل + 0 مستوردين | القراءة + grep | HAND |
| F52 | `git status` مستمر: 63 + ملفي (لا تعديل خارج النطاق) | `git status` + بصمات | HAND |

## تفسيرات معمارية (INTERPRETATIONS — قابلة للنقاش)

| # | التفسير | البديل الممكن |
|---|---|---|
| I1 | حواف pres→data/providers "تجاوز" | قراءة بديلة: استهلاك Riverpod طبيعي لمزودات موضوعة في `data/` — المشكلة موضع التعريف لا الاستهلاك |
| I2 | `BackendRegistry` "ميت" | بديل: احتياطي تصميمي لم يُفعَّل — لكن 129 سطراً بلا مستهلك = ميت عملياً |
| I3 | use-cases شكلية "غير ضرورية" | بديل: `LoginUseCase` يحمل تحققاً حقيقياً — التعميم على الكل مبالغ فيه |
| I4 | `expectedOwnerDriverId` "تلويث عقد" | بديل: آلية أمان عملية بأقل احتكاك — مقبولة تكتيكياً، مرفوضة بنيوياً |
| I5 | خرائط الحالات "مكررة" | بديل: خيارات العرض أوسع من حالات النطاق (`yardMoves`) — جزء مبرر |
| I6 | `RawJson` "عملة مسربة" | بديل: براغماتية مقبولة للعقود الخام — لكن غياب المخطط هو المشكلة |
