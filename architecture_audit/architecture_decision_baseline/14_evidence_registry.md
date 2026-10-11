# 14 — سجل الأدلة (Evidence Registry)

> كل استنتاج مؤكد أدناه مربوط بدليله. `HAND` = فحصت الشيفرة/شغّلت بنفسي. `GRAPH` = مخطط مُعاد بناؤه (1,726 حافة). `COUNT` = عدّ آلي. `PRIOR` = تحقق سابق مسجّل (phase_0/EC-0.2a) أُعيد تأكيده.

## أدلة الوحدات والحدود

| # | الاستنتاج | الدليل | المنهج |
|---|---|---|---|
| E01 | 7 حواف `core→features` | القائمة الكاملة (06 ملفات مصدر) | GRAPH+HAND |
| E02 | 9 حواف `backend→features` | 4+2+3 مسرودة | GRAPH+HAND |
| E03 | 20 حافة pres→data كلها لمزودات تركيب | القائمة الكاملة | GRAPH+HAND |
| E04 | 14 حافة pres→backend (9+3+2) | القائمة الكاملة | GRAPH+HAND |
| E05 | دورة 25 + 3 ثنائية (+1 مولدة مستثناة) | Tarjan + دورة دنيا + تبادل مباشر | HAND |
| E06 | صفر حواف domain→data/presentation | بحث شامل (عدا شقوق النقاء الموثقة) | GRAPH+HAND |
| E07 | 19 علامة `ignore_architecture` + لا lint | العدّ + `analysis_options.yaml` | COUNT+HAND |
| E08 | `BackendRegistry` بلا مستهلك إنتاجي | grep (تعريف+مزود+اختبار فقط) | HAND |
| E09 | `trackingService` مزدوج + override أحادي | `:200`/:22/:41/:91 | HAND |
| E10 | `HttpClient()` خام `:136` | السطر + غياب `close()` | HAND |
| E11 | `/session` الميت + URL مطلق | `:64` + `eld_auth_backend:29-30` | HAND |
| E12 | `static` codriver `:17-18` + `switchDrivers` بلا سياج | القراءة الكاملة (238) | HAND |
| E13 | `RegExp(r'\d+')` في DVIR `:468` | السطر | HAND |
| E14 | `{'reports': []}` مقابل `rawJson['data']` | السطران | HAND |
| E15 | استيرادات tracker المخالفة `:4,5,11,13` | الأسطر | HAND |
| E16 | `Exception(l10nKey)` + هبوط + عرض خام | السلسلة + 17 موقعاً | HAND |
| E17 | `kDebugMode` يقيّد التجاوز `:29` | السطر | HAND |
| E18 | `.env` بلا أسرار + تعليق موثق | المحتوى + `.gitignore:49-52` | HAND |
| E19 | `RawJson` typedef + 33 مستورداً ولا domain | العدّ + بحث النطاق | COUNT+HAND |
| E20 | `duty_status_code` يستورد Flutter + ألوان | `:7-8,75-88` | HAND |
| E21 | سياج منسوخ + `switchDrivers` بلا سياج | المقارنة السطرية | HAND |
| E22 | `DvirNotifier(storageService)` مُهمَل | `:117-125` بلا حقل | HAND |
| E23 | `Ref?` يُسكت الكتابة `:94,162,192,214` | الأسطر | HAND |
| E24 | §396.13 في كائن حالة `:45-57` | الأسطر | HAND |
| E25 | `Duration(hours:11)` في `build` `:125-129` | الأسطر | HAND |
| E26 | `json['data']` في presentation `:26-32` | الأسطر | HAND |
| E27 | 5 كتابات dashboard عابرة | grep شجري | HAND |
| E28 | Notifier الاتصال في ملف صفحة + 24 استيراداً | `:27-248` | HAND |
| E29 | `HosNotifier` يقرأ audit repo `:140` | السطر | HAND |
| E30 | `OFFLINE_GENERATED:` بروتوكول طبقتين | `:361` + `:267-268` | HAND |
| E31 | `LogoutUseCase` تُسقط `Either` | التوقيعان | HAND |
| E32 | 7 ملفات use-case (3 تمريرية) | glob + قراءة | HAND |
| E33 | مزود use-case داخل ملفه `:52-61` | الأسطر | HAND |
| E34 | مزود auth وحيد في "الجذر" | 25 سطراً كاملة | HAND |
| E35 | `export` متبادل core↔backend | سطرا التصدير/الاستيراد | HAND |
| E36 | `SyncRepository` حي عبر `sync_provider` | grep المستهلكين | HAND |
| E37 | `connection/domain` موجود ومُستخدم | glob + grep | HAND |
| E38 | `vehicle_selection` بلا HTTP (153 سطراً) | القراءة الكاملة | HAND |
| E39 | `daily_form_rules:7` يستورد l10n | السطر | HAND |
| E40 | DTO المحوّل مستورد مباشرة | أسطر الاستيراد | HAND |
| E41 | `sync_providers:7-8` بـ `ignore_architecture` | السطران | HAND |
| E42 | `account_page:98-102` عرض خام | الأسطر | HAND |
| E43 | خريطة تسميات `status_radio_group:20-24` | الأسطر | HAND |
| E44 | 22 `UnimplementedError` مقابل ~60 عقداً | العدّ | COUNT+HAND |
| E45 | تعليق الموك القديم + shim معلّق بلا مستوردين | القراءة + grep صفري | HAND |
| E46 | `validateManualTransition` قبل `submitManualChange` | `:95-106` + engine | HAND |
| E47 | اختبار `server_rejected` يفشل (14✅/1❌) | **تشغيل فعلي** | HAND |
| E48 | `home_page` 21 استيراداً؛ `eld_connection` 24 | العدّ | COUNT |
| E49 | `EldRetryView` في 11 موقعاً | العدّ | COUNT |
| E50 | 95 مزوداً (68/12/7/5/3) + 23 Notifier | إحصاء آلي | COUNT |
| E51 | `vehicleBackendProviderAlias` تمرير أعمى | القراءة | HAND |
| E52 | تحقق المدخلات مكرر (form + use-case) | `:65-70,96-101` + use-case | HAND |

## فصل الحقائق

- **OBSERVED_FACT:** E01–E52 (كلها قابلة لإعادة الإنتاج بالأوامر المذكورة).
- **ARCHITECTURAL_INTERPRETATION:** تصنيفات VALID/VIOLATION/CONTEXT في 08، والأحكام في 02-07 (مفسّرة ومبررة، قابلة للنقاش).
- **UNVERIFIED_ASSUMPTION:** بنود 12 العشرة (مصرّح بها واحداً واحداً).
