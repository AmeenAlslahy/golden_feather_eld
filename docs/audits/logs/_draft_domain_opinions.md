# مسودة آراء طبقة `domain` — غير معتمدة

نُقلت هذه الآراء من `01_domain.md` في 2026-10-27. هذا الملف ليس جردًا، ولا يُعتمد كأساس قرار. لا تُنفَّذ أي توصية منه قبل قرار صريح.

## الملاحظات الأولية (آراء)

| المشكلة | الدليل (ملف:سطر) | التصنيف | الخطورة | نطاق التأثير |
|---|---|---|---|---|
| عقد مستودع واحد بـ20 دالة يخلط عشرة اختصاصات | `log_repository.dart:17-116` | معمارية | عالية | كل مستخدمي `LogRepository` و`LogRepositoryImpl` وكل الـMocks والاختبارات |
| `DailyLog` يحمل حالة واجهة (`isExpanded`) داخل كيان domain ويضمّها في المساواة | `daily_log.dart:177`، `daily_log.dart:154` | معمارية | متوسطة | `logs_provider`، `log_event_tile`، أي كاش أو مقارنة للسجلات |
| `DailyLog` ينسّق التاريخ والوقت بإنجليزي ثابت داخل domain | `daily_log.dart:118-139`، `daily_log.dart:198-208` | عمارة/توطين | عالية | كل شاشة تعرض `formattedDate` أو `formattedDuration`، ومنها التعريب والإسبانية |
| `formStatus` مكتوب ولا يُقرأ، ومكرر مع `isFormComplete` | `daily_log.dart:20` و`daily_log.dart:22`، الكتابة `form_tab_provider.dart:344` و`form_tab_provider.dart:363` | إدارة حالة/جودة | متوسطة | `form_tab_provider`، `log_list_item`، `log_detail_page`، أي منطق اكتمال |
| `isCertified` مكرر مع `certificationStatus` مع تعليق Legacy | `daily_log.dart:21` و`daily_log.dart:23` | جودة/معمارية | متوسطة | `log_list_item`، `certify_log_provider`، `log_repository_impl` |
| حقول ميتة موسومة Legacy أو غير مقروءة: `licensePlate`، `vin`، `formStatus` | `daily_log.dart:20`، `daily_log.dart:33-34` | جودة | متوسطة | `DailyLogDto`، اختبارات DTO، أي شاشة تفاصيل مستقبلية |
| `DailyLogPage.empty` غير مستخدم | `daily_log_page.dart:20` | جودة | منخفضة | لا شيء حاليًا |
| `totalElements` و`totalPages` لا يُقرآن | `daily_log_page.dart:9-10` | جودة | منخفضة | `DailyLogPage` و`logs_provider` فقط |
| `DailyFormData.vehicleId` موثّق بأنه يُستخدم عند الحفظ، بينما `DailyFormUpdate` يمنع إرساله | `daily_form_data.dart:7-9` مقابل `daily_form_update.dart:8-10` | معمارية/عقد | متوسطة | `logs_provider`، `log_repository_impl`، أي حفظ مستقبلي |
| `DailyFormUpdate.notes` لا يُقرأ ولا يُكتب | `daily_form_update.dart:17` | جودة | منخفضة | `form_tab_provider`، `log_repository_impl` |
| `AuditEntry` يحوّل نفسه إلى `Map` ويعرف تفصيل تخزين `_saveToBox` | `audit_entry.dart:44-75`، والتعليق `audit_entry.dart:47` | معمارية | متوسطة | `log_local_data_source`، `audit_trail_provider`، اختبارات التدقيق |
| `AuditEntry.fromMap` يفسد البيانات بصمت: epoch 0 وحقول مطلوبة فارغة | `audit_entry.dart:62-83` | جودة/بيانات قانونية | عالية | سجل التدقيق، التقارير، أي تحقيق FMCSA |
| `action` له قيمة افتراضية `''` رغم أن SRS يوجب وجوده | `audit_entry.dart:5` و`audit_entry.dart:37` | جودة/امتثال | متوسطة | كل إدخالات التدقيق القديمة والجديدة |
| `LogReadiness` ينسّق نصوص العرض داخل domain | `log_readiness.dart:21-32`، `log_readiness.dart:76-90` | معمارية/توطين | متوسطة | `certify_tab`، `carrier_edit_card`، التعريب |
| حقول جاهزية لا تُقرأ: `legalStatement`، `availableActions`، `previousValuesSummary` | `log_readiness.dart:8`، `log_readiness.dart:52-53` | جودة | متوسطة | `certify_tab`، `carrier_edit_card` |
| `LogCertifyState` يحمل ثمانية حقول غير مقروءة من أصل عشرة | `log_certify_state.dart:9-21` مقابل القراءة `certify_log_provider.dart:52-77` | جودة/عقد | عالية | شاشة الاعتماد، أي عرض للنص القانوني أو التوقيع |
| `LogCertifyState.certificationStatus` نص وليس enum | `log_certify_state.dart:20` و`log_certify_state.dart:34` | جودة/اتساق | متوسطة | `certify_log_provider`، أي مقارنة حالة |
| `parseEditFormTime` يقبل `13:00 PM` وثواني 99 | `log_edit.dart:48-57` | جودة/تحقق | عالية | `edit_log_provider`، أي تعديل وقت؛ الدالة نفسها في domain وليست في الصفحة |
| `refuseAutomaticDrivingEdit` يقارن `DateTime` كاملة مع وقت يُقرأ بدقة الدقيقة | `log_edit.dart:16`، `daily_log.dart:198-202`، `log_edit.dart:40` | منطق أعمال | عالية | تعديل الأحداث الآلية، اختبارات `log_edit`؛ القاعدة في `edit_log_provider.dart:105` وليست في الواجهة |
| `isAutomaticDrivingEvent` عام لكنه داخلي فقط | `log_edit.dart:4` و`log_edit.dart:15` | جودة | منخفضة | `log_edit` فقط |
| `FormSaveResult.online` يقبل null والمستهلك يستخدم `!` | `saved_form_status.dart:17`، `form_tab_provider.dart:353` | عقد/أمان | متوسطة | `form_tab_provider`، أي تنفيذ بديل للمستودع |
| `SavedFormRead.formStatus` و`message` غير مقروءين | `saved_form_status.dart:3-5` | جودة | منخفضة | `saved_form_dto`، `trailers_page_test` |
| `copyWith` لا يستطيع تصفير الحقول الاختيارية في `DailyLog` و`LogEvent` | `daily_log.dart:105-113`، `daily_log.dart:229-233` | جودة/مرونة | متوسطة | أي مسح لـ`odometer` أو`engineHours` أو`automatedDriving` أو عنوان |
| نص `'None'` الإنجليزي داخل domain يُقارن به في الواجهة | `daily_form_rules.dart:26`، `form_tab_provider.dart:134` | توطين | متوسطة | `form_tab_provider`، `dashboard_provider`، صفحات المقطورات والوثائق |
| الاعتماد الخارجي على `logs` موثق بالكامل في القسم التالي | القسم «الاعتماد الخارجي الكامل على `logs`» | حدود/توسع | عالية | `home`، `hos`، `inspection`، `dvir`، `app`، `sync`، `routes` |
| لا اختبارات لـ`formatRequirement`، `displaySummary`، `formattedDate`، `dayName`، `DailyLogPage` | البحث في `test/features/logs` أعاد صفرًا لهذه الرموز | اختبار | متوسطة | طبقة domain بالكامل |

## ما يمكن إصلاحه بأمان الآن: اختبارات فقط

1. إضافة اختبارات لـ`parseEditFormTime` تغطي `13:00 PM` و`08:15:99 PM`: اختبارات فقط، لا تمس المصدر.
2. إضافة اختبارات لـ`formatRequirement` و`displaySummary`: لا توجد اختبارات حاليًا، والإضافة لا تكسر شيئًا.
3. إضافة اختبار لـ`refuseAutomaticDrivingEdit` يثبت سلوك إعادة حفظ حدث آلي بلا تغيير، قبل أي تعديل على المقارنة الزمنية.

لا تُدرج في هذه القائمة أي عملية تحذف حقلًا أو تغيّر توقيعًا أو تمس عقد خادم أو تغيّر سلوكًا. تلك تحتاج قرارًا مستقلًا.

## ما يحتاج قرارًا قبل التنفيذ

1. **تقسيم `LogRepository`:** هل نقسمه إلى `LogReadQueryRepository` و`LogFormRepository` و`LogCertifyRepository` و`LogAuditRepository` و`LogDraftRepository`؟ كل قسم سيغيّر كل الـMocks والاختبارات.
2. **مصير الحقول Legacy:** هل نحذف `totalDrivingHours` و`isCertified` و`formStatus` بعد ترحيل الشاشات إلى `formattedTotalWorkTime` و`certificationStatus` و`isFormComplete`؟ الحذف يمس DTO والاختبارات والشاشات.
3. **مصير `vin` و`licensePlate`:** هل هما مخصصان لشاشة تفاصيل مستقبلية أم بقايا عقد؟ `daily_log_dto_test.dart:52-53` يثبت أنهما يُحوّلان إلى الكيان، لكن لا شاشة تقرأهما.
4. **صرامة `AuditEntry.fromMap`:** هل نُبقي الافتراضات الصامتة (epoch 0 و`''`) أم نرمي استثناءً أو نعيد `Result`؟ هذا قرار قانوني قبل تقني.
5. **دقة مقارنة وقت القيادة الآلية:** هل قاعدة الرفض تُقارن بالدقيقة أم بالثانية؟ إذا كانت بالثانية، فيجب إصلاح مسار النموذج ليحفظ الثواني.
6. **ملكية التنسيق:** هل تنسيق التاريخ والوقت ينتقل إلى `presentation` مع `AppLocalizations`، أم يبقى إنجليزيًا ثابتًا وفق متطلب FMCSA؟
7. **حدود الميزة:** هل `logs/domain` مقصود أن يكون shared kernel لـ`home` و`hos` و`inspection` و`dvir`؟ إذا لا، فيجب نقل `DailyFormData` و`AuditEntry` و`DutyPeriod` إلى عقود مشتركة أو إزالة الاعتماد المباشر.

## ترتيب مقترح للتنفيذ (مسودة غير معتمدة)

1. **تثبيت السلوك الحالي باختبارات:** إضافة اختبارات للحالات غير المغطاة قبل أي تعديل، وخاصة `parseEditFormTime` و`refuseAutomaticDrivingEdit` و`formatRequirement`.
2. **إزالة الميت الآمن:** `DailyLogPage.empty`، وتخصيص `isAutomaticDrivingEvent` و`dayName`. لا يعتمد عليها أحد.
3. **إصلاح تحقق الوقت:** تعديل `parseEditFormTime` ليرفض `13:00 PM` والثواني خارج 0-59، ثم تشغيل الاختبارات.
4. **تثبيت قرار دقة الوقت:** اختبار يثبت هل إعادة حفظ حدث آلي بلا تغيير يجب أن تُقبل. إذا نعم، تُقارن الدقائق لا الثواني.
5. **توحيد مصادر الحقيقة:** حسم `formStatus` مقابل `isFormComplete` و`isCertified` مقابل `certificationStatus` قبل أي شاشة جديدة.
6. **فصل التنسيق عن domain:** نقل `formattedDate` و`formattedDuration` و`displaySummary` و`formatRequirement` إلى مكوّنات عرض، بعد إضافة بدائل مترجمة.
7. **تقسيم العقد:** تقسيم `LogRepository` وفق الاستخدام الفعلي، وتحديث الـProviders والاختبارات تدريجيًا.
8. **تصحيح الحدود:** نقل الاعتمادات الخارجية إلى عقود صريحة أو shared kernel، بدل الاستيراد المباشر من `logs/domain`.

## أسئلة مفتوحة

1. هل `vin` و`licensePlate` مطلوبان لعرض قادم، أم يمكن حذفهما من `DailyLog`؟
2. هل `formStatus` له أي مستهلك غير مباشر خارج ما فُحص، أم يمكن حذفه؟
3. هل `AuditEntry` يجب أن يرفض الصفوف التالفة بدل إنتاج قيم افتراضية؟
4. هل `totalDrivingHours` ما زال مطلوبًا بعد وجود `formattedTotalWorkTime`؟
5. هل تُعرض التواريخ بالإنجليزية دائمًا، أم يجب أن تتبع لغة الواجهة؟
6. هل يرسل الخادم ثواني غير صفرية في `startTime` للأحداث الآلية؟
7. هل `logs/domain` هو المكان الرسمي لعقد `AuditEntry` و`DailyFormData` المشترك مع `inspection` و`home`؟

## الاعتماد الخارجي الكامل على `logs`

بحث فعلي بـ`Select-String` في `lib` و`test` عن أي استيراد إلى `features/logs` من خارج `lib/features/logs` و`test/features/logs`.

### ملفات إنتاجية

| الملف الخارجي | السطر | ما يستورده من `logs` |
|---|---:|---|
| `lib/app.dart` | 20 | `features/logs/data/datasources/log_local_data_source.dart` |
| `lib/features/dvir/presentation/pages/dvir_form_page.dart` | 30 | `logs/presentation/widgets/vehicle_picker_dialog.dart` |
| `lib/features/home/presentation/providers/dashboard_provider.dart` | 2 | `logs/domain/daily_form_rules.dart` |
| `lib/features/home/presentation/providers/dashboard_provider.dart` | 3 | `logs/domain/entities/daily_form_data.dart` |
| `lib/features/hos/data/providers/duty_period_store_providers.dart` | 3 | `logs/data/providers/log_repository_providers.dart` |
| `lib/features/hos/data/repositories/log_duty_period_store.dart` | 2 | `logs/domain/repositories/log_repository.dart` |
| `lib/features/inspection/presentation/pages/send_logs_page.dart` | 10 | `logs/domain/entities/audit_entry.dart` |
| `lib/features/inspection/presentation/pages/send_logs_page.dart` | 11 | `logs/data/providers/log_repository_providers.dart` |
| `lib/features/sync/data/providers/sync_providers.dart` | 9 | `logs/data/datasources/log_local_data_source.dart` |
| `lib/routes/logs_routes.dart` | 3 | `logs/presentation/pages/logs_list_page.dart` |
| `lib/routes/logs_routes.dart` | 4 | `logs/presentation/pages/log_detail_page.dart` |
| `lib/routes/logs_routes.dart` | 5 | `logs/presentation/pages/edit_log_page.dart` |
| `lib/routes/logs_routes.dart` | 6 | `logs/presentation/pages/suggested_events_page.dart` |
| `lib/routes/logs_routes.dart` | 7 | `logs/presentation/pages/unidentified_events_page.dart` |
| `lib/routes/logs_routes.dart` | 8 | `logs/domain/entities/daily_log.dart` |

### اختبارات خارج `test/features/logs`

| الملف الخارجي | السطر | ما يستورده من `logs` |
|---|---:|---|
| `test/audit_task05/dvir_vehicle_scope_test.dart` | 29 | `logs/presentation/widgets/vehicle_picker_dialog.dart` |
| `test/audit_task06/driver_isolation_test.dart` | 6 | `logs/data/datasources/log_local_data_source.dart` |
| `test/features/hos/data/repositories/log_duty_period_store_test.dart` | 6 | `logs/domain/repositories/log_repository.dart` |

### ملفات ذُكرت سابقًا ولا تعتمد على `logs`

- `lib/backend/adapters/eld_engine/sub/eld_daily_logs_backend.dart`: لا يستورد أي ملف من `features/logs`. السطران 240 و255 يستدعيان `EldEndpoints.dailyLogEvent` ولا يبنيان `LogEvent`. الاستشهادان حُذفا من `01_domain.md`.
- `lib/features/dvir/presentation/pages/dvir_form_page.dart` كان غائبًا من القائمة السابقة، وأُضيف أعلاه.
