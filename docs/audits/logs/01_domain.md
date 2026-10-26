# جرد طبقة `domain` — ميزة `logs`

## نطاق الملف

- **11 ملفًا**، **890 سطرًا**، **0 Providers**.
- كل ملف قُرئ كاملًا.
- كل استشهاد بالسطر تم التحقق منه بفتح الملف حول السطر.
- الملفات المولّدة غير موجودة في هذه الطبقة.
- لا توجد تعديلات على ملفات المصدر. مخرجات الجرد هي ملفات `docs/audits/logs/` فقط.

## ملخص الطبقة

| الملف | الأسطر | الكلاسات | الـEnums | الدوال والـMethods | الحقول | الثوابت |
|---|---:|---:|---:|---:|---:|---:|
| `domain/entities/daily_log.dart` | 252 | 2 | 2 | 11 | 33 | 0 |
| `domain/entities/daily_log_page.dart` | 21 | 1 | 0 | 1 | 5 | 1 |
| `domain/entities/daily_form_data.dart` | 37 | 1 | 0 | 2 | 7 | 0 |
| `domain/entities/daily_form_update.dart` | 35 | 1 | 0 | 2 | 5 | 0 |
| `domain/entities/audit_entry.dart` | 100 | 1 | 0 | 5 | 11 | 0 |
| `domain/entities/log_readiness.dart` | 105 | 2 | 0 | 7 | 16 | 0 |
| `domain/entities/log_certify_state.dart` | 53 | 1 | 0 | 2 | 10 | 0 |
| `domain/repositories/log_repository.dart` | 117 | 1 | 0 | 20 | 0 | 0 |
| `domain/log_edit.dart` | 61 | 0 | 0 | 3 | 0 | 0 |
| `domain/daily_form_rules.dart` | 91 | 0 | 2 | 6 | 0 | 7 |
| `domain/saved_form_status.dart` | 18 | 2 | 0 | 3 | 5 | 0 |
| **الإجمالي** | **890** | **12** | **4** | **62** | **92** | **8** |

ملاحظة العدّ: مجموع الحقول 92 حقلًا داخل الكلاسات. الثوابت الثمانية: سبعة top-level في `daily_form_rules.dart` (`_placeholders` في السطر 8، و`maxTrailerNumberLength` في السطر 11، و`maxShippingDocumentLength` في السطر 12، و`_labelBase` في السطر 32، و`_labelWithSlash` في السطر 33، و`_labelSubstance` في السطر 36، و`_freeTextChars` في السطر 41)، وثابت class-static واحد هو `DailyLogPage.empty` في `daily_log_page.dart:20`. أُعيد عدّ الدوال من الصفوف المعروضة: `daily_log.dart` يعرض 11 دالة (6 لـ`DailyLog` و5 لـ`LogEvent`)، و`daily_log_page.dart` يعرض constructor واحدًا بعد نقل `empty` إلى الثوابت. مجموع الصفوف 62، وهو رقم وصفي لا يُستخدم كأساس قرار.

---

## 1. `lib/features/logs/domain/entities/daily_log.dart`

- **الطبقة:** domain
- **المسؤولية في جملة واحدة:** تعريف كياني `DailyLog` و`LogEvent` اللذين يمثلان سجل اليوم وحدث تغيير حالة السائق، مع حالة النموذج والاعتماد.
- **عدد الأسطر:** 252
- **الاعتمادات:**
  - داخل الميزة: لا يوجد.
  - من `core/` وشجرة `lib` العامة: `lib/domain/shared/value_objects.dart` (من أجل `DailyLogId`).
  - حزم خارجية: `equatable`.
- **من يستورد هذا الملف؟**
  - داخل `lib/features/logs`: `data/datasources/log_local_data_source.dart:9`، `data/models/daily_log_dto.dart:1`، `data/models/log_model.dart:1`، `data/repositories/log_repository_impl.dart:20`، `domain/log_edit.dart:1`، `domain/entities/daily_log_page.dart:1`، `domain/repositories/log_repository.dart:3`، `presentation/mappers/inspection_preview_event_mapper.dart:6`، `presentation/pages/edit_log_page.dart:12`، `presentation/pages/inspection_preview_page.dart:18`، `presentation/pages/log_detail_page.dart:9`، `presentation/pages/suggested_events_page.dart:7`، `presentation/providers/certify_log_provider.dart:18`، `presentation/providers/edit_log_form_provider.dart:5`، `presentation/providers/edit_log_provider.dart:10`، `presentation/providers/form_tab_provider.dart:8`، `presentation/providers/logs_provider.dart:4`، `presentation/providers/suggested_events_provider.dart:3`، `presentation/widgets/log_graph.dart:6`، `presentation/widgets/log_list_item.dart:4`، `presentation/widgets/suggested_log_card.dart:4`، `presentation/widgets/log_detail_tabs/certify_tab.dart:11`، `presentation/widgets/log_detail_tabs/events_tab.dart:6`، `presentation/widgets/log_detail_tabs/expanded_content.dart:5`، `presentation/widgets/log_detail_tabs/form_tab.dart:8`، `presentation/widgets/log_detail_tabs/log_event_tile.dart:5`.
  - خارج الميزة: `lib/routes/logs_routes.dart:8`.
  - الاختبارات: 21 ملفًا، منها `test/features/logs/log_edit_test.dart:2`، `test/features/logs/data/log_repository_offline_test.dart:11`، `test/features/logs/data/models/daily_log_dto_test.dart:3`، `test/features/logs/domain/log_event_equality_test.dart:2`، `test/features/logs/presentation/mappers/inspection_preview_event_mapper_test.dart:3`، `test/features/logs/presentation/pages/edit_log_page_logic_test.dart:10`، `test/features/logs/presentation/pages/edit_log_page_test.dart:9`، `test/features/logs/presentation/pages/logs_list_page_test.dart:11`، `test/features/logs/presentation/pages/log_detail_page_indexed_stack_test.dart:11`، `test/features/logs/presentation/pages/log_detail_page_route_test.dart:14`، `test/features/logs/presentation/pages/suggested_events_page_test.dart:7`، `test/features/logs/presentation/pages/trailers_page_test.dart:10`، `test/features/logs/presentation/providers/form_list_provider_test.dart:6`، `test/features/logs/presentation/providers/form_tab_provider_test.dart:10`، `test/features/logs/presentation/providers/logs_provider_events_test.dart:8`، `test/features/logs/presentation/providers/logs_provider_form_race_test.dart:12`، `test/features/logs/presentation/providers/suggested_events_provider_test.dart:4`، `test/features/logs/presentation/widgets/log_detail_tabs/certify_tab_errors_test.dart:10`، `test/features/logs/presentation/widgets/log_detail_tabs/certify_tab_signature_draft_test.dart:10`، `test/features/logs/presentation/widgets/log_detail_tabs/certify_tab_test.dart:14`، `test/features/logs/presentation/widgets/log_detail_tabs/events_tab_test.dart:6`.

### الكلاسات والـEnums

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `FormStatus` | enum | حالة النموذج: `completed`، `incomplete`، `unknown` | 4 |
| `CertificationStatus` | enum | حالة الاعتماد: `certified`، `uncertified`، `reCertificationRequired`، `unknown` | 6 |
| `DailyLog` | Equatable class | كيان سجل اليوم | 14 |
| `LogEvent` | Equatable class | كيان حدث تغيير الحالة | 169 |

### حقول `DailyLog`

| الاسم | النوع | public/private | final / late / mutable | الغرض | السطر | قراءة مؤكدة (ملف:سطر) | كتابة مؤكدة (ملف:سطر) |
|---|---|---|---|---|---|---|---|
| `id` | `DailyLogId` | public | final | هوية السجل | 15 | `log.id` في `logs_provider.dart:161`، `logs_provider.dart:229`؛ `state.selectedLog?.id` و`log.id` في `logs_provider.dart:198`؛ `state.selectedLog?.id` و`log.id` في `logs_provider.dart:335` | `daily_log_dto.dart:189`، `daily_log.dart:92` |
| `uniqueId` | `String` | public | final | معرف اليوم الفريد من الخادم | 16 | `log.uniqueId` في `logs_provider.dart:214`؛ `current.uniqueId` في `logs_provider.dart:250`؛ `selectedLog.uniqueId` في `form_tab_provider.dart:167`؛ `_log.uniqueId` في `form_tab_provider.dart:284` | `daily_log_dto.dart:190`، `form_tab_provider.dart:340` |
| `date` | `DateTime` | public | final | تاريخ اليوم | 17 | `log.date` في `logs_provider.dart:353` | `daily_log_dto.dart:191` |
| `formattedTotalWorkTime` | `String` | public | final | إجمالي وقت العمل جاهز العرض من الخادم | 18 | `log.formattedTotalWorkTime` في `log_list_item.dart:67`، `log_list_item.dart:68` | `daily_log_dto.dart:194` |
| `totalDrivingHours` | `double` | public | final | إجمالي ساعات القيادة، موسوم Legacy | 19 | `log.totalDrivingHours` في `log_list_item.dart:69`، `log_list_item.dart:71` | `daily_log_dto.dart:195` |
| `formStatus` | `FormStatus` | public | final | حالة النموذج | 20 | لا توجد قراءة خارجية مؤكدة بعد البحث عن `.formStatus` في `lib/features/logs` | `daily_log_dto.dart:196`، `form_tab_provider.dart:344`، `form_tab_provider.dart:363` |
| `certificationStatus` | `CertificationStatus` | public | final | حالة الاعتماد | 21 | `selectedLog.certificationStatus` في `log_detail_page.dart:266`؛ `log.certificationStatus` في `suggested_events_provider.dart:14`، `suggested_log_card.dart:14` | `daily_log_dto.dart:197` |
| `isFormComplete` | `bool` | public | final | اكتمال النموذج، موسوم Legacy | 22 | `log.isFormComplete` في `log_list_item.dart:89`، `certify_log_provider.dart:249`؛ `selectedLog.isFormComplete` في `log_detail_page.dart:313`، `inspection_preview_page.dart:292` | `daily_log_dto.dart:198`، `form_tab_provider.dart:343`، `form_tab_provider.dart:362` |
| `isCertified` | `bool` | public | final | الاعتماد، موسوم Legacy | 23 | `log.isCertified` في `log_list_item.dart:98` | `daily_log_dto.dart:199` |
| `requiresAction` | `bool` | public | final | هل يحتاج السجل إجراءً | 24 | `log.requiresAction` في `suggested_events_provider.dart:13` | `daily_log_dto.dart:200` |
| `today` | `bool` | public | final | هل السجل هو يوم اليوم | 25 | `log.today` في `logs_provider.dart:204`؛ `selectedLog.today` في `form_tab_provider.dart:148`؛ `selected.today` في `form_list_provider.dart:99`؛ `log?.today` في `edit_log_form_provider.dart:106` | `daily_log_dto.dart:201` |
| `events` | `List<LogEvent>` | public | final | أحداث السجل | 26 | `state.selectedLog!.events` في `logs_provider.dart:370`، `logs_provider.dart:398`، `logs_provider.dart:473` | `daily_log_dto.dart:202`، `logs_provider.dart:378`، `logs_provider.dart:405` |
| `driverName` | `String?` | public | final | اسم السائق من التفاصيل | 31 | `selectedLog?.driverName` في `form_tab_provider.dart:151`، `inspection_preview_page.dart:123` | `daily_log_dto.dart:203` |
| `vehicleName` | `String?` | public | final | اسم المركبة من التفاصيل | 32 | `log.vehicleName` في `logs_provider.dart:207`، `logs_provider.dart:215` | `daily_log_dto.dart:204` |
| `vin` | `String?` | public | final | رقم VIN من التفاصيل | 33 | لا توجد قراءة عبر `DailyLog.vin`؛ كل نتائج `.vin` تعود إلى كيانات `inspection` و`vehicle` | `daily_log_dto.dart:205` |
| `licensePlate` | `String?` | public | final | رقم اللوحة من التفاصيل | 34 | لا توجد قراءة خارجية مؤكدة؛ النمط `.licensePlate` لا يظهر إلا في التعريف و`copyWith` | `daily_log_dto.dart:206` |
| `carrierName` | `String?` | public | final | اسم الناقل | 35 | `selectedLog?.carrierName` في `inspection_preview_page.dart:118` | `daily_log_dto.dart:207` |
| `usdotNumber` | `String?` | public | final | رقم USDOT | 36 | `selectedLog?.usdotNumber` في `inspection_preview_page.dart:119` | `daily_log_dto.dart:208` |
| `mainOfficeAddress` | `String?` | public | final | عنوان المكتب الرئيسي | 37 | لا توجد قراءة عبر `DailyLog.mainOfficeAddress`؛ نتائج `.mainOfficeAddress` تعود إلى كيانات `inspection` و`account` | `daily_log_dto.dart:209` |
| `homeTerminalAddress` | `String?` | public | final | عنوان المحطة الرئيسية | 38 | لا توجد قراءة عبر `DailyLog.homeTerminalAddress`؛ نتائج `.homeTerminalAddress` تعود إلى كيانات `inspection` و`account` | `daily_log_dto.dart:210` |
| `trailers` | `List<String>` | public | final | أرقام المقطورات | 39 | `log.trailers` في `logs_provider.dart:205`، `logs_provider.dart:216`؛ `selectedLog?.trailers` في `form_tab_provider.dart:186` | `daily_log_dto.dart:211`، `form_tab_provider.dart:341` |
| `shippingDocuments` | `List<String>` | public | final | وثائق الشحن | 40 | `log.shippingDocuments` في `logs_provider.dart:206`، `logs_provider.dart:217` | `daily_log_dto.dart:212`، `form_tab_provider.dart:342` |

### حقول `LogEvent`

| الاسم | النوع | public/private | final / late / mutable | الغرض | السطر | قراءة مؤكدة (ملف:سطر) | كتابة مؤكدة (ملف:سطر) |
|---|---|---|---|---|---|---|---|
| `id` | `String` | public | final | معرف الحدث | 170 | `e.id` في `logs_provider.dart:371`، `logs_provider.dart:474`؛ `event.id` في `logs_provider.dart:474` | `edit_log_provider.dart:124`، ويُستخدم مفتاحًا في `logs_provider.dart:375` |
| `status` | `String` | public | final | رمز الحالة `OFF` و`SB` و`D` و`ON` | 171 | `event.status` في `log_edit.dart:6`، `inspection_preview_event_mapper.dart:70`؛ `original.status` في `log_edit.dart:16` | `edit_log_provider.dart:119`، `log_model.dart:98` (عبر `LogEventModel.fromJson`) |
| `startTime` | `DateTime` | public | final | وقت البداية | 172 | `original.startTime` في `log_edit.dart:16`؛ `event.formattedStartTime` في `expanded_content.dart:18` (getter يقرأ `startTime`) | `edit_log_provider.dart:120`، `log_model.dart:99` (عبر `LogEventModel.fromJson`) |
| `duration` | `Duration` | public | final | مدة الحدث | 173 | `event.duration` في `log_graph.dart:41`؛ `e.duration` في `events_tab.dart:125`؛ `this.duration` ضمنيًا في `daily_log.dart:205` | `edit_log_provider.dart:127`، `log_model.dart:100` (عبر `LogEventModel.fromJson`) |
| `location` | `String` | public | final | الموقع النصي | 174 | `event.location` في `inspection_preview_event_mapper.dart:71` | `edit_log_provider.dart:121`، `log_local_data_source.dart:341`، `log_model.dart:101` (عبر `LogEventModel.fromJson`) |
| `odometer` | `double?` | public | final | قراءة العداد | 175 | `event.odometer` في `expanded_content.dart:21`، `expanded_content.dart:25`، `inspection_preview_event_mapper.dart:72` | `log_local_data_source.dart:342`، `log_model.dart:102` (عبر `LogEventModel.fromJson`) |
| `engineHours` | `double?` | public | final | ساعات المحرك | 176 | `event.engineHours` في `expanded_content.dart:27`، `expanded_content.dart:31`، `inspection_preview_event_mapper.dart:73` | `log_local_data_source.dart:343`، `log_model.dart:103` (عبر `LogEventModel.fromJson`) |
| `isExpanded` | `bool` | public | final | حالة توسيع الواجهة | 177 | `e.isExpanded` في `logs_provider.dart:371`، `logs_provider.dart:400`؛ `event.isExpanded` في `log_event_tile.dart:46` | `logs_provider.dart:375`، `logs_provider.dart:400` |
| `automatedDriving` | `bool?` | public | final | هل القيادة آلية | 178 | `event.automatedDriving` في `log_edit.dart:5`، `events_tab.dart:84`، `inspection_preview_event_mapper.dart:62` | `log_model.dart:106` (عبر `fromJson`)، `log_model.dart:153` (عبر `fromEntity` غير المستخدمة) |
| `editable` | `bool?` | public | final | هل الحدث قابل للتعديل | 179 | `event.editable` في `log_edit.dart:6`، `events_tab.dart:85` | `log_model.dart:107` (عبر `fromJson`) |
| `startedOnPreviousDay` | `bool` | public | final | بدأ الحدث في اليوم السابق | 182 | لا توجد قراءة في الواجهة؛ يمر عبر `LogEventModel` فقط | `log_model.dart:108` (عبر `fromJson`)، `log_model.dart:155` (عبر `fromEntity` غير المستخدمة) |

### دوال `DailyLog`

| الاسم | التوقيع الكامل | الكلاس المالك | الغرض | المدخلات | المخرجات | الآثار الجانبية | Providers | من يستدعيها |
|---|---|---|---|---|---|---|---|---|
| `DailyLog` | `const DailyLog({required DailyLogId id, String uniqueId = '', required DateTime date, String formattedTotalWorkTime = '', required double totalDrivingHours, FormStatus formStatus = FormStatus.unknown, CertificationStatus certificationStatus = CertificationStatus.unknown, required bool isFormComplete, required bool isCertified, bool requiresAction = false, bool today = false, List<LogEvent> events = const [], String? driverName, String? vehicleName, String? vin, String? licensePlate, String? carrierName, String? usdotNumber, String? mainOfficeAddress, String? homeTerminalAddress, List<String> trailers = const [], List<String> shippingDocuments = const []})` | `DailyLog` | إنشاء كيان السجل | الحقول أعلاه | `DailyLog` | لا يوجد | لا يوجد | `daily_log_dto.dart:188` فقط |
| `copyWith` | `DailyLog copyWith({DailyLogId? id, String? uniqueId, DateTime? date, String? formattedTotalWorkTime, double? totalDrivingHours, FormStatus? formStatus, CertificationStatus? certificationStatus, bool? isFormComplete, bool? isCertified, bool? requiresAction, bool? today, List<LogEvent>? events, String? driverName, String? vehicleName, String? vin, String? licensePlate, String? carrierName, String? usdotNumber, String? mainOfficeAddress, String? homeTerminalAddress, List<String>? trailers, List<String>? shippingDocuments})` | `DailyLog` | نسخ السجل مع تعديل حقول | الحقول الاختيارية | `DailyLog` | لا يوجد | لا يوجد | `logs_provider.dart:341`، `logs_provider.dart:378`، `logs_provider.dart:405`، `logs_provider.dart:436`، `logs_provider.dart:472`، `logs_provider.dart:480`، `form_tab_provider.dart:339`، `form_tab_provider.dart:358` |
| `dayName` | `String get dayName` | `DailyLog` | اسم اليوم المختصر | لا يوجد | `String` | لا يوجد | لا يوجد | داخليًا من `formattedDate` في `daily_log.dart:124` فقط |
| `formattedDate` | `String get formattedDate` | `DailyLog` | تاريخ منسّق للعرض | لا يوجد | `String` | لا يوجد | لا يوجد | `log.formattedDate` في `log_list_item.dart:39`، `log_list_item.dart:40`، `suggested_log_card.dart:38`؛ `selectedLog.formattedDate` في `log_detail_page.dart:213`، `inspection_preview_page.dart:187`؛ `selectedLog?.formattedDate` في `edit_log_page.dart:68` |
| `_ordinal` | `String _ordinal(int day)` | `DailyLog` | لاحقة اليوم `st` و`nd` و`rd` و`th` | `int day` | `String` | لا يوجد | لا يوجد | `daily_log.dart:124` فقط |
| `props` | `List<Object?> get props` | `DailyLog` | خصائص المساواة | لا يوجد | `List<Object?>` | لا يوجد | لا يوجد | `Equatable` |

### دوال `LogEvent`

| الاسم | التوقيع الكامل | الكلاس المالك | الغرض | المدخلات | المخرجات | الآثار الجانبية | Providers | من يستدعيها |
|---|---|---|---|---|---|---|---|---|
| `LogEvent` | `const LogEvent({required String id, required String status, required DateTime startTime, required Duration duration, required String location, double? odometer, double? engineHours, bool isExpanded = false, bool? automatedDriving, bool? editable, bool startedOnPreviousDay = false})` | `LogEvent` | إنشاء حدث | الحقول أعلاه | `LogEvent` | لا يوجد | لا يوجد | `edit_log_provider.dart:123`، `log_local_data_source.dart:308`، `daily_log.dart:223` (داخل `copyWith`). حُذف استشهادان سابقان بـ`eld_daily_logs_backend.dart:240` و`eld_daily_logs_backend.dart:255` لأنهما `EldEndpoints.dailyLogEvent` وليسا بناء `LogEvent`. |
| `formattedStartTime` | `String get formattedStartTime` | `LogEvent` | تنسيق وقت البداية `HH:mm` | لا يوجد | `String` | لا يوجد | لا يوجد | `event?.formattedStartTime` في `edit_log_form_provider.dart:153`؛ `event.formattedStartTime` في `expanded_content.dart:18` |
| `formattedDuration` | `String get formattedDuration` | `LogEvent` | تنسيق المدة `Xh Ym` | لا يوجد | `String` | لا يوجد | لا يوجد | `event?.formattedDuration` في `edit_log_form_provider.dart:154`؛ `event.formattedDuration` في `expanded_content.dart:19`، `log_event_tile.dart:107` |
| `copyWith` | `LogEvent copyWith({String? id, String? status, DateTime? startTime, Duration? duration, String? location, double? odometer, double? engineHours, bool? isExpanded, bool? automatedDriving, bool? editable, bool? startedOnPreviousDay})` | `LogEvent` | نسخ الحدث مع تعديل حقول | الحقول الاختيارية | `LogEvent` | لا يوجد | لا يوجد | `logs_provider.dart:375`، `logs_provider.dart:400`، `edit_log_provider.dart:118` |
| `props` | `List<Object?> get props` | `LogEvent` | خصائص المساواة | لا يوجد | `List<Object?>` | لا يوجد | لا يوجد | `Equatable` |

### حقائق مرصودة في `daily_log.dart`

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- مرشّحات dead code مبنية على بحث فعلي:
  - `dayName` عام لكنه يُقرأ فقط داخل `formattedDate` في السطر 124.
  - `DailyLog.licensePlate` لا تُقرأ خارجيًا، ولا يظهر النمط `.licensePlate` إلا في الأسطر 58 و108 وفي `daily_log_dto.dart:44`.
  - `DailyLog.vin` لا تُقرأ عبر هذا الكيان؛ نتائج `.vin` في المشروع كلها لكيانات `inspection` و`vehicle`.
  - `DailyLog.formStatus` يُكتب في `form_tab_provider.dart:344` و`form_tab_provider.dart:363` ولا يُقرأ بعدها.
  - `totalDrivingHours` و`isFormComplete` و`isCertified` تحمل تعليقات Legacy صريحة في الأسطر 19 و22 و23.
- منطق أعمال داخل كيان domain:
  - تنسيق التاريخ بإنجليزي ثابت: `'Today'` في السطر 119، مصفوفة أيام الأسبوع في السطر 120، مصفوفة الأشهر في السطر 124، لواحق الترتيب في الأسطر 127-139.
  - تنسيق الوقت والمدة بإنجليزي ثابت: `'${hours}h ${minutes}m'` في السطر 207.
- حالة واجهة داخل domain:
  - `isExpanded` في السطر 177 ويدخل في `props` في السطر 154.
  - `today` يدخل في `props` في السطر 153.
- `ref.read` أو `ref.watch`: لا يوجد.
- `Navigator` أو `showDialog` أو `showModalBottomSheet`: لا يوجد.
- أرقام أو نصوص مكتوبة يدويًا بدل الثوابت أو الترجمة: الأسطر 119، 120، 124، 128-138، 207.
- تكرار شبه حرفي:
  - `formStatus` و`isFormComplete` يمثلان المعلومة نفسها (`daily_log.dart:20` و`daily_log.dart:22`).
  - `certificationStatus` و`isCertified` يمثلان المعلومة نفسها (`daily_log.dart:21` و`daily_log.dart:23`).
- دوال أطول من 40 سطرًا: `DailyLog.copyWith` من 67 إلى 116 بطول 50 سطرًا. `DailyLog.props` من 142 إلى 165 بطول 24 سطرًا. `LogEvent.copyWith` من 210 إلى 236 بطول 27 سطرًا.
- `build` أطول من 80 سطرًا: لا ينطبق.

---

## 2. `lib/features/logs/domain/entities/daily_log_page.dart`

- **الطبقة:** domain
- **المسؤولية في جملة واحدة:** تغليف صفحة واحدة من نتائج `GET /eld/daily-logs` مع بيانات الترقيم.
- **عدد الأسطر:** 21
- **الاعتمادات:**
  - داخل الميزة: `daily_log.dart`.
  - من `core/`: لا يوجد.
  - حزم خارجية: لا يوجد.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/repositories/log_repository_impl.dart:21`، `domain/repositories/log_repository.dart:4`.
  - خارج الميزة: لا يوجد.
  - الاختبارات: `test/features/logs/data/log_repository_offline_test.dart:12`، `test/features/logs/presentation/pages/edit_log_page_test.dart:10`، `test/features/logs/presentation/pages/logs_list_page_test.dart:12`، `test/features/logs/presentation/pages/log_detail_page_route_test.dart:15`، `test/features/logs/presentation/pages/unidentified_events_page_test.dart:16`، `test/features/logs/presentation/providers/logs_provider_events_test.dart:9`، `test/features/logs/presentation/providers/logs_provider_form_race_test.dart:13`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `DailyLogPage` | class عادي غير Equatable | صفحة سجلات مع ترقيم | 5 |

### الحقول

| الاسم | النوع | public/private | final | الغرض | السطر | قراءة مؤكدة | كتابة مؤكدة |
|---|---|---|---|---|---|---|---|
| `logs` | `List<DailyLog>` | public | final | سجلات الصفحة | 6 | `logs_provider.dart:156` | `log_repository_impl.dart:77`، `log_repository_impl.dart:103` |
| `page` | `int` | public | final | رقم الصفحة | 7 | لا توجد قراءة خارجية مؤكدة؛ `logs_provider` يستخدم `state.page` الخاص به | `log_repository_impl.dart:77`، `log_repository_impl.dart:103` |
| `hasNext` | `bool` | public | final | وجود صفحة تالية | 8 | `logs_provider.dart:169` | `log_repository_impl.dart:77`، `log_repository_impl.dart:103` |
| `totalElements` | `int?` | public | final | إجمالي العناصر | 9 | لا توجد قراءة خارجية؛ النمط `.totalElements` لا يظهر خارج `core/network/api_response.dart` و`backend` وهذا الملف | `log_repository_impl.dart` |
| `totalPages` | `int?` | public | final | إجمالي الصفحات | 10 | لا توجد قراءة خارجية؛ النمط `.totalPages` لا يظهر خارج `core/network/api_response.dart` و`backend` وهذا الملف | `log_repository_impl.dart` |

### الدوال

| الاسم | التوقيع الكامل | الغرض | من يستدعيها |
|---|---|---|---|
| `DailyLogPage` | `const DailyLogPage({required List<DailyLog> logs, int page = 0, bool hasNext = false, int? totalElements, int? totalPages})` | إنشاء صفحة | `log_repository_impl.dart:77`، `log_repository_impl.dart:103`، `daily_log_page.dart:20` (داخل `empty`) |

### الثوابت

| الاسم | النوع | القيمة | الغرض | السطر | من يستدعيها |
|---|---|---|---|---|---|
| `empty` | `static const DailyLogPage` | `DailyLogPage(logs: [])` | قيمة فارغة جاهزة | 20 | لا توجد قراءة خارجية؛ البحث الدقيق `DailyLogPage.empty` لم يجد أي استخدام في `lib` أو `test` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- مرشّح dead code: `DailyLogPage.empty` في السطر 20 لا يُستخدم. الحقلان `totalElements` و`totalPages` لا يُقرآن.
- الكلاس لا يورث `Equatable` ولا يوفّر `copyWith`، فلا مساواة قيمة بين صفحتين متطابقتين.
- منطق أعمال داخل Widget: لا ينطبق.
- نصوص أو أرقام مكتوبة يدويًا: لا يوجد.
- دوال أطول من 40 سطرًا: لا يوجد.

---

## 3. `lib/features/logs/domain/entities/daily_form_data.dart`

- **الطبقة:** domain
- **المسؤولية في جملة واحدة:** Snapshot للبيانات المحفوظة لنموذج اليوم على الخادم دون بيانات الجلسة الحية.
- **عدد الأسطر:** 37
- **الاعتمادات:**
  - داخل الميزة: لا يوجد.
  - من `core/`: لا يوجد.
  - حزم خارجية: `equatable`.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/repositories/log_repository_impl.dart:31`، `domain/repositories/log_repository.dart:11`، `presentation/providers/logs_provider.dart:5`.
  - خارج الميزة: `lib/features/home/presentation/providers/dashboard_provider.dart:3`.
  - الاختبارات: `test/features/logs/presentation/pages/trailers_page_test.dart:12`، `test/features/logs/presentation/providers/form_list_provider_test.dart:4`، `test/features/logs/presentation/providers/form_tab_provider_test.dart:9`، `test/features/logs/presentation/providers/logs_provider_form_race_test.dart:11`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `DailyFormData` | Equatable class | لقطة نموذج اليوم | 6 |

### الحقول

| الاسم | النوع | public/private | final | الغرض | السطر | قراءة مؤكدة | كتابة مؤكدة |
|---|---|---|---|---|---|---|---|
| `vehicleId` | `int?` | public | final | معرّف المركبة الرقمي، والتعليق يقول إنه يُستخدم عند الحفظ | 9 | `logs_provider.dart:271` فقط (نسخه إلى كائن جديد) | `log_repository_impl.dart:448` |
| `vehicleUniqueId` | `String?` | public | final | معرف المركبة النصي | 10 | `logs_provider.dart:214`، `logs_provider.dart:250`، `form_tab_provider.dart:173` | `log_repository_impl.dart:449` |
| `vehicleName` | `String?` | public | final | اسم المركبة | 11 | `serverForm?.vehicleName` في `form_tab_provider.dart:161`، `form_tab_provider.dart:165` | `log_repository_impl.dart:450` |
| `coDriverId` | `int?` | public | final | معرف السائق المساعد | 12 | `form_tab_provider.dart:217`، `dashboard_provider.dart:187` | `log_repository_impl.dart:451` |
| `coDriverName` | `String?` | public | final | اسم السائق المساعد | 13 | `form_tab_provider.dart:209`، `form_tab_provider.dart:211`، `dashboard_provider.dart:190` | `log_repository_impl.dart:452` |
| `trailers` | `List<String>` | public | final | المقطورات | 14 | `form_tab_provider.dart:184`، `dashboard_provider.dart:183` | `log_repository_impl.dart:453` |
| `shippingDocuments` | `List<String>` | public | final | وثائق الشحن | 15 | `form_tab_provider.dart:199`، `dashboard_provider.dart:185` | `log_repository_impl.dart:454` |

### الدوال

| الاسم | التوقيع الكامل | الغرض | من يستدعيها |
|---|---|---|---|
| `DailyFormData` | `const DailyFormData({int? vehicleId, String? vehicleUniqueId, String? vehicleName, int? coDriverId, String? coDriverName, List<String> trailers = const [], List<String> shippingDocuments = const []})` | إنشاء اللقطة | `logs_provider.dart:213`، `logs_provider.dart:249`، `logs_provider.dart:270`، `logs_provider.dart:293`، `logs_provider.dart:314`، `log_repository_impl.dart:447` |
| `props` | `List<Object?> get props` | المساواة | `Equatable` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- تعارض موثّق بين هذا الملف و`daily_form_update.dart`:
  - `daily_form_data.dart:7-9` يقول إن `vehicleId` «يُستخدم كـ `vehicleId` عند الحفظ».
  - `daily_form_update.dart:8-10` يقول إن المعرّف الرقمي `vehicleId` «مرفوض دائماً (400) حتى عندما يكون صحيحاً، فلا يُرسل ولا يُشتق».
  - `DailyFormUpdate` لا يحتوي حقل `vehicleId` أصلًا (`daily_form_update.dart:11-17`). أي أن الحقل في `DailyFormData` لا يمكن أن يصل إلى الحفظ عبر هذا المسار.
- لا يوجد `copyWith`، ولذلك يعيد `logs_provider.dart` بناء الكائن كاملًا ثلاث مرات في الأسطر 270-278 و293-301 و314-322.
- منطق أعمال داخل Widget: لا ينطبق.
- نصوص أو أرقام مكتوبة يدويًا: لا يوجد.
- دوال أطول من 40 سطرًا: لا يوجد.

---

## 4. `lib/features/logs/domain/entities/daily_form_update.dart`

- **الطبقة:** domain
- **المسؤولية في جملة واحدة:** Command لتحديث نموذج اليوم على الخادم.
- **عدد الأسطر:** 35
- **الاعتمادات:**
  - داخل الميزة: لا يوجد.
  - من `core/`: لا يوجد.
  - حزم خارجية: `equatable`.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/repositories/log_repository_impl.dart:32`، `domain/repositories/log_repository.dart:12`، `presentation/providers/form_tab_provider.dart:9`.
  - خارج الميزة: لا يوجد.
  - الاختبارات: `test/features/logs/data/repositories/log_repository_impl_form_test.dart:13`، `test/features/logs/presentation/pages/trailers_page_test.dart:11`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `DailyFormUpdate` | Equatable class | أمر حفظ النموذج | 7 |

### الحقول

| الاسم | النوع | public/private | final | الغرض | السطر | قراءة مؤكدة | كتابة مؤكدة |
|---|---|---|---|---|---|---|---|
| `vehicleUniqueId` | `String` | public | final | معرف المركبة النصي المرسل | 11 | `log_repository_impl.dart:466`، `log_repository_impl.dart:474`، `form_tab_provider.dart:331` | `form_tab_provider.dart:104` |
| `coDriverId` | `int?` | public | final | معرف السائق المساعد | 12 | لا توجد قراءة مباشرة مؤكدة خارج `_mapFormUpdateToJson` في `log_repository_impl.dart` | `form_tab_provider.dart:105` |
| `trailers` | `List<String>` | public | final | المقطورات | 13 | `log_repository_impl.dart:357` | `form_tab_provider.dart:106` |
| `shippingDocuments` | `List<String>` | public | final | وثائق الشحن | 14 | `log_repository_impl.dart:358`، `log_repository_impl.dart:475` | `form_tab_provider.dart:107` |
| `notes` | `String?` | public | final | ملاحظات السائق | 17 | لا توجد قراءة خارجية مؤكدة؛ النمط `.notes` لا يظهر في أي ملف داخل `logs` | لا توجد كتابة خارج constructor |

### الدوال

| الاسم | التوقيع الكامل | الغرض | من يستدعيها |
|---|---|---|---|
| `DailyFormUpdate` | `const DailyFormUpdate({required String vehicleUniqueId, int? coDriverId, required List<String> trailers, required List<String> shippingDocuments, String? notes})` | إنشاء أمر الحفظ | `form_tab_provider.dart:103` |
| `props` | `List<Object?> get props` | المساواة | `Equatable` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- مرشّح dead code: `notes` في السطر 17 لا يُقرأ ولا يُكتب خارج constructor.
- لا يوجد `copyWith`.
- منطق أعمال داخل Widget: لا ينطبق.
- نصوص أو أرقام مكتوبة يدويًا: لا يوجد.
- دوال أطول من 40 سطرًا: لا يوجد.

---

## 5. `lib/features/logs/domain/entities/audit_entry.dart`

- **الطبقة:** domain
- **المسؤولية في جملة واحدة:** تمثيل إدخال سجل تدقيق للتعديلات اليدوية، مع تحويله من وإلى `Map`.
- **عدد الأسطر:** 100
- **الاعتمادات:**
  - داخل الميزة: لا يوجد.
  - من `core/`: لا يوجد.
  - حزم خارجية: `equatable`.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/datasources/log_local_data_source.dart:10`، `data/repositories/log_repository_impl.dart:22`، `domain/repositories/log_repository.dart:6`، `presentation/providers/audit_trail_provider.dart:3`، `presentation/providers/edit_log_provider.dart:9`.
  - خارج الميزة: `lib/features/inspection/presentation/pages/send_logs_page.dart:10`.
  - الاختبارات: `test/features/logs/audit_entry_test.dart:2`، `test/features/logs/presentation/audit_trail_page_test.dart:5`، `test/features/logs/presentation/pages/edit_log_page_logic_test.dart:6`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `AuditEntry` | Equatable class | إدخال تدقيق | 7 |

### الحقول

| الاسم | النوع | public/private | final | الغرض | السطر | قراءة مؤكدة | كتابة مؤكدة |
|---|---|---|---|---|---|---|---|
| `id` | `String` | public | final | معرف الإدخال | 8 | `audit_entry.dart:63` | `send_logs_page.dart:128`، `edit_log_provider.dart:148` |
| `timestamp` | `DateTime` | public | final | وقت الإدخال | 9 | `audit_entry.dart:64`، `audit_entry.dart:79` | `send_logs_page.dart:129`، `edit_log_provider.dart:149` |
| `driverId` | `String` | public | final | معرف السائق | 10 | `log_repository_impl.dart:752` | `send_logs_page.dart:130` |
| `oldStatus` | `String?` | public | final | الحالة السابقة | 11 | `audit_entry.dart:66` | `edit_log_provider.dart:151` |
| `newStatus` | `String` | public | final | الحالة الجديدة | 12 | `audit_entry.dart:67` | `send_logs_page.dart:131`، `edit_log_provider.dart:152` |
| `reason` | `String` | public | final | سبب التعديل | 13 | `audit_entry.dart:68` | `send_logs_page.dart:132` |
| `action` | `String` | public | final | اسم الإجراء | 16 | `audit_entry.dart:69` | `send_logs_page.dart:133` |
| `entityType` | `String?` | public | final | نوع الكيان | 19 | `audit_entry.dart:70` | `send_logs_page.dart:134` |
| `entityId` | `String?` | public | final | معرف الكيان | 22 | `audit_entry.dart:71` | `send_logs_page.dart:135` |
| `userName` | `String?` | public | final | اسم المنفذ | 25 | `audit_entry.dart:72` | `send_logs_page.dart:136` |
| `userRole` | `String?` | public | final | دور المنفذ | 28 | `audit_entry.dart:73` | `send_logs_page.dart:137` |

### الدوال

| الاسم | التوقيع الكامل | الغرض | من يستدعيها |
|---|---|---|---|
| `AuditEntry` | `const AuditEntry({required String id, required DateTime timestamp, required String driverId, String? oldStatus, required String newStatus, required String reason, String action = '', String? entityType, String? entityId, String? userName, String? userRole})` | إنشاء إدخال | `send_logs_page.dart:127`، `edit_log_provider.dart:147` |
| `toMap` | `Map<String, dynamic> toMap()` | تحويل إلى خريطة تخزين | `audit_entry_test.dart:15`، `log_local_data_source.dart:445` |
| `fromMap` | `factory AuditEntry.fromMap(Map<String, dynamic> map)` | قراءة من خريطة تخزين | `audit_entry_test.dart:21`، `log_local_data_source.dart:447` |
| `_readTimestamp` | `static DateTime _readTimestamp(Object? raw)` | قبول ISO أو milliseconds | داخليًا من `fromMap` في السطر 64 |
| `props` | `List<Object?> get props` | المساواة | `Equatable` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- منطق تخزين داخل domain: `toMap` و`fromMap` في الأسطر 44-75، والتعليق في السطر 47 يذكر `_saveToBox` وهو تفصيل تخزين خارج الطبقة.
- فساد بيانات صامت في `fromMap`:
  - الطابع الزمني غير الصالح يصبح `DateTime.fromMillisecondsSinceEpoch(0)` في الأسطر 81-83.
  - `newStatus` المطلوب يصبح `''` في السطر 67.
  - `driverId` المطلوب يصبح `''` في السطر 65.
  - الاختبار `audit_entry_test.dart:36-44` يثبّت هذا السلوك صراحةً.
- تعارض بين التعليق والتنفيذ: السطر 5 يقول إن كل حدث يحمل الإجراء، لكن `action` له قيمة افتراضية `''` في السطر 37 و`fromMap` يعيد `''` في السطر 69.
- منطق أعمال داخل Widget: لا ينطبق.
- نصوص أو أرقام مكتوبة يدويًا: `0` كطابع زمني بديل في السطر 81، و`0` في السطر 83.
- دوال أطول من 40 سطرًا: لا يوجد.

---

## 6. `lib/features/logs/domain/entities/log_readiness.dart`

- **الطبقة:** domain
- **المسؤولية في جملة واحدة:** تمثيل جاهزية السجل للاعتماد والتعديلات المقترحة من الناقل، مع تنسيق نصوص المتطلبات للعرض.
- **عدد الأسطر:** 105
- **الاعتمادات:**
  - داخل الميزة: لا يوجد.
  - من `core/`: لا يوجد.
  - حزم خارجية: `equatable`.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/repositories/log_repository_impl.dart:28`، `domain/repositories/log_repository.dart:9`، `presentation/providers/certify_log_provider.dart:19`، `presentation/widgets/log_detail_tabs/carrier_edit_card.dart:6`، `presentation/widgets/log_detail_tabs/certify_tab.dart:12`، `presentation/widgets/log_detail_tabs/pending_carrier_edits_section.dart:5`.
  - خارج الميزة: لا يوجد.
  - الاختبارات: `test/features/logs/presentation/pages/log_detail_page_indexed_stack_test.dart:12`، `test/features/logs/presentation/widgets/log_detail_tabs/certify_tab_signature_draft_test.dart:11`، `test/features/logs/presentation/widgets/log_detail_tabs/certify_tab_test.dart:12`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `CarrierProposedEditEntity` | Equatable class | تعديل مقترح من الناقل | 3 |
| `LogReadiness` | Equatable class | جاهزية السجل | 45 |

### حقول `CarrierProposedEditEntity`

| الاسم | النوع | public/private | final | الغرض | السطر | قراءة مؤكدة | كتابة مؤكدة |
|---|---|---|---|---|---|---|---|
| `id` | `String` | public | final | معرف التعديل | 4 | `log_repository_impl.dart:584` | constructor |
| `carrierName` | `String?` | public | final | اسم الناقل | 5 | `log_readiness.dart:23` | `log_repository_impl.dart:585` |
| `carrierReason` | `String?` | public | final | سبب الناقل | 6 | `log_readiness.dart:29` | `log_repository_impl.dart:586` |
| `proposedStatus` | `String?` | public | final | الحالة المقترحة | 7 | `log_readiness.dart:25` | `log_repository_impl.dart:587` |
| `previousValuesSummary` | `String?` | public | final | ملخص القيم السابقة | 8 | لا توجد قراءة خارجية؛ `displaySummary` لا يضمّه | `log_repository_impl.dart:588` |
| `newValuesSummary` | `String?` | public | final | ملخص القيم الجديدة | 9 | `log_readiness.dart:27` | `log_repository_impl.dart:589` |

### حقول `LogReadiness`

| الاسم | النوع | public/private | final | الغرض | السطر | قراءة مؤكدة | كتابة مؤكدة |
|---|---|---|---|---|---|---|---|
| `dailyLogId` | `int` | public | final | معرف السجل | 46 | لا توجد قراءة خارجية مؤكدة | `log_repository_impl.dart:572` |
| `driverId` | `int` | public | final | معرف السائق | 47 | لا توجد قراءة خارجية مؤكدة داخل `logs` | `log_repository_impl.dart:573` |
| `driverName` | `String` | public | final | اسم السائق | 48 | لا توجد قراءة خارجية مؤكدة داخل `certify` | `log_repository_impl.dart:574` |
| `logDate` | `String` | public | final | تاريخ السجل | 49 | لا توجد قراءة خارجية مؤكدة؛ نتائج `.logDate` تعود إلى أنواع أخرى | `log_repository_impl.dart:575` |
| `readinessStatus` | `String` | public | final | حالة الجاهزية | 50 | `certify_log_provider.dart:61` | `log_repository_impl.dart:576` |
| `missingRequirements` | `List<String>` | public | final | المتطلبات الناقصة | 51 | `certify_log_provider.dart:67`، `certify_log_provider.dart:79` | `log_repository_impl.dart:577` |
| `legalStatement` | `String` | public | final | النص القانوني | 52 | لا توجد قراءة خارجية مؤكدة | `log_repository_impl.dart:578` |
| `availableActions` | `List<String>` | public | final | الإجراءات المتاحة | 53 | لا توجد قراءة خارجية مؤكدة | `log_repository_impl.dart:579` |
| `carrierProposedEditsPending` | `bool` | public | final | وجود تعديلات ناقل معلقة | 54 | `certify_log_provider.dart:57`، `certify_log_provider.dart:68` | `log_repository_impl.dart:580` |
| `pendingCarrierEdits` | `List<CarrierProposedEditEntity>` | public | final | التعديلات المعلقة | 55 | `certify_tab.dart:243`، `certify_tab.dart:298` | `log_repository_impl.dart:581` |

### الدوال

| الاسم | التوقيع الكامل | الكلاس المالك | الغرض | من يستدعيها |
|---|---|---|---|---|
| `CarrierProposedEditEntity` | `const CarrierProposedEditEntity({required String id, String? carrierName, String? carrierReason, String? proposedStatus, String? previousValuesSummary, String? newValuesSummary})` | `CarrierProposedEditEntity` | إنشاء تعديل مقترح | `log_repository_impl.dart:583` |
| `displaySummary` | `String get displaySummary` | `CarrierProposedEditEntity` | دمج الناقل والحالة والقيم والسبب بفاصل ` · ` | `carrier_edit_card.dart:23` |
| `props` | `List<Object?> get props` | `CarrierProposedEditEntity` | المساواة | `Equatable` |
| `LogReadiness` | `const LogReadiness({required int dailyLogId, required int driverId, required String driverName, required String logDate, required String readinessStatus, required List<String> missingRequirements, required String legalStatement, required List<String> availableActions, bool carrierProposedEditsPending = false, List<CarrierProposedEditEntity> pendingCarrierEdits = const []})` | `LogReadiness` | إنشاء حالة الجاهزية | `log_repository_impl.dart:551`، `log_repository_impl.dart:571`، `certify_tab.dart:149` |
| `formattedMissingRequirements` | `List<String> get formattedMissingRequirements` | `LogReadiness` | تنسيق المتطلبات الناقصة | `certify_tab.dart:208` |
| `formatRequirement` | `static String formatRequirement(String req)` | `LogReadiness` | تحويل الطوابع الزمنية داخل النص إلى `HH:mm` محلي | داخليًا من `formattedMissingRequirements`؛ لا توجد قراءة مباشرة أخرى |
| `props` | `List<Object?> get props` | `LogReadiness` | المساواة | `Equatable` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- منطق عرض داخل domain:
  - `displaySummary` يبني نص عرض بفاصل ثابت ` · ` في الأسطر 21-32.
  - `formatRequirement` يستخدم `RegExp` و`toLocal` لتنسيق وقت للعرض في الأسطر 76-90.
- مرشّحات dead code مبنية على بحث فعلي:
  - `previousValuesSummary` في السطر 8 لا يُقرأ خارجيًا.
  - `legalStatement` في السطر 52 لا يُقرأ خارجيًا.
  - `availableActions` في السطر 53 لا يُقرأ خارجيًا.
  - `dailyLogId` و`driverId` و`driverName` و`logDate` لا تظهر لها قراءة خارجية مؤكدة داخل `features/logs`.
- لا توجد اختبارات لـ`formatRequirement` أو`displaySummary`؛ البحث عنهما في `test/features/logs` أعاد صفرًا.
- نصوص مكتوبة يدويًا: الفاصل ` · ` في السطر 31.
- دوال أطول من 40 سطرًا: لا يوجد.

---

## 7. `lib/features/logs/domain/entities/log_certify_state.dart`

- **الطبقة:** domain
- **المسؤولية في جملة واحدة:** تمثيل حالة شاشة الاعتماد القادمة من الخادم، بما فيها إمكانية الاعتماد وأسباب المنع.
- **عدد الأسطر:** 53
- **الاعتمادات:**
  - داخل الميزة: لا يوجد.
  - من `core/`: لا يوجد.
  - حزم خارجية: `equatable`.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/repositories/log_repository_impl.dart:29`، `domain/repositories/log_repository.dart:10`، `presentation/providers/certify_log_provider.dart:20`.
  - خارج الميزة: لا يوجد.
  - الاختبارات: لا يوجد استيراد مباشر.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `LogCertifyState` | Equatable class | حالة الاعتماد | 8 |

### الحقول

| الاسم | النوع | public/private | final | الغرض | السطر | قراءة مؤكدة | كتابة مؤكدة |
|---|---|---|---|---|---|---|---|
| `dailyLogId` | `int` | public | final | معرف السجل | 9 | لا توجد قراءة خارجية مؤكدة | `log_repository_impl.dart:619` |
| `logDate` | `String` | public | final | تاريخ السجل | 10 | لا توجد قراءة خارجية مؤكدة | `log_repository_impl.dart:620` |
| `statementText` | `String` | public | final | النص القانوني | 13 | لا توجد قراءة خارجية مؤكدة | `log_repository_impl.dart:621` |
| `ruleReference` | `String` | public | final | مرجع القاعدة | 14 | لا توجد قراءة خارجية مؤكدة | `log_repository_impl.dart:622` |
| `hasSignature` | `bool` | public | final | وجود توقيع مسجل | 17 | لا توجد قراءة خارجية مؤكدة | `log_repository_impl.dart:623` |
| `signatureImageData` | `String?` | public | final | صورة التوقيع | 18 | لا توجد قراءة خارجية مؤكدة | `log_repository_impl.dart:624` |
| `certificationStatus` | `String` | public | final | حالة الاعتماد النصية | 20 | لا توجد قراءة عبر `LogCertifyState.certificationStatus`؛ النمط `.certificationStatus` يعود إلى `DailyLog` وDTO | `log_repository_impl.dart:625` |
| `certified` | `bool` | public | final | هل السجل معتمد | 21 | لا توجد قراءة داخل `logs`؛ النمط `.certified` يعود إلى `dvir` و`inspection` و`backend` | `log_repository_impl.dart:626` |
| `canCertify` | `bool` | public | final | هل يمكن الاعتماد الآن | 22 | `certify_log_provider.dart:56` | `log_repository_impl.dart:627` |
| `validationCodes` | `List<String>` | public | final | رموز المنع | 25 | `certify_log_provider.dart:52`، `certify_log_provider.dart:76`، `certify_log_provider.dart:77` | `log_repository_impl.dart:628` |

### الدوال

| الاسم | التوقيع الكامل | الغرض | من يستدعيها |
|---|---|---|---|
| `LogCertifyState` | `const LogCertifyState({required int dailyLogId, String logDate = '', String statementText = '', String ruleReference = '', bool hasSignature = false, String? signatureImageData, String certificationStatus = 'UNCERTIFIED', bool certified = false, bool canCertify = false, List<String> validationCodes = const []})` | إنشاء حالة الاعتماد | `log_repository_impl.dart:618` |
| `props` | `List<Object?> get props` | المساواة | `Equatable` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- ستة حقول لا تُقرأ بعد البناء: `dailyLogId`، `logDate`، `statementText`، `ruleReference`، `hasSignature`، `signatureImageData`، إضافة إلى `certificationStatus` و`certified`. الحقول التي تُقرأ فعليًا هي `canCertify` و`validationCodes` فقط عبر `certify_log_provider.dart:52-77`.
- حالة نصية بدل enum: `certificationStatus` من نوع `String` بقيمة افتراضية `'UNCERTIFIED'` في السطر 34، بينما `DailyLog` يستخدم `CertificationStatus` enum في `daily_log.dart:6`.
- نصوص مكتوبة يدويًا: `'UNCERTIFIED'` في السطر 34.
- دوال أطول من 40 سطرًا: لا يوجد.

---

## 8. `lib/features/logs/domain/repositories/log_repository.dart`

- **الطبقة:** domain
- **المسؤولية في جملة واحدة:** العقد المجرّد لكل عمليات قراءة وكتابة السجلات اليومية والأحداث والنموذج والاعتماد والتدقيق ومسودات التوقيع.
- **عدد الأسطر:** 117
- **الاعتمادات:**
  - داخل الميزة: `entities/daily_log.dart`، `entities/daily_log_page.dart`، `entities/audit_entry.dart`، `saved_form_status.dart`، `entities/log_readiness.dart`، `entities/log_certify_state.dart`، `entities/daily_form_data.dart`، `entities/daily_form_update.dart`.
  - من `core/`: `core/error/failure.dart`، `core/domain/entities/hos_models.dart`، `lib/domain/shared/value_objects.dart`.
  - حزم خارجية: `fpdart`.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/providers/log_repository_providers.dart:8`، `data/repositories/log_repository_impl.dart:17`، `presentation/providers/certify_log_provider.dart:21`، `presentation/providers/logs_provider.dart:6`، `presentation/providers/log_draft_signature_provider.dart:9`.
  - خارج الميزة: `lib/features/hos/data/repositories/log_duty_period_store.dart:2`.
  - الاختبارات: `test/features/hos/data/repositories/log_duty_period_store_test.dart:6`، `test/features/logs/presentation/pages/edit_log_page_logic_test.dart:20`، `test/features/logs/presentation/pages/edit_log_page_test.dart:13`، `test/features/logs/presentation/pages/logs_list_page_test.dart:13`، `test/features/logs/presentation/pages/log_detail_page_indexed_stack_test.dart:13`، `test/features/logs/presentation/pages/log_detail_page_route_test.dart:16`، `test/features/logs/presentation/pages/trailers_page_test.dart:14`، `test/features/logs/presentation/pages/unidentified_events_page_test.dart:17`، `test/features/logs/presentation/providers/form_tab_provider_test.dart:11`، `test/features/logs/presentation/providers/logs_provider_events_test.dart:10`، `test/features/logs/presentation/providers/logs_provider_form_race_test.dart:14`، `test/features/logs/presentation/widgets/log_detail_tabs/certify_tab_errors_test.dart:11`، `test/features/logs/presentation/widgets/log_detail_tabs/certify_tab_signature_draft_test.dart:12`، `test/features/logs/presentation/widgets/log_detail_tabs/certify_tab_test.dart:15`، `test/features/logs/presentation/widgets/log_detail_tabs/events_tab_test.dart:7`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `LogRepository` | abstract class | عقد مستودع السجلات | 14 |

### الدوال

| الاسم | التوقيع الكامل | الغرض | المخرجات | من يستدعيها |
|---|---|---|---|---|
| `getDailyLogs` | `Future<Either<Failure, DailyLogPage>> getDailyLogs({required int driverId, int page = 0, int size = 20})` | قائمة السجلات المرقّمة | صفحة سجلات أو فشل | `logs_provider.dart:132` |
| `getLogById` | `Future<Either<Failure, DailyLog>> getLogById(DailyLogId logId)` | تفاصيل سجل واحد | سجل أو فشل | `logs_provider.dart:333` |
| `getForm` | `Future<Either<Failure, DailyFormData?>> getForm(DailyLogId logId)` | قراءة نموذج اليوم المحفوظ | نموذج أو null أو فشل | `logs_provider.dart:229` |
| `saveForm` | `Future<Either<Failure, FormSaveResult>> saveForm({required DailyLogId logId, required DailyFormUpdate form, int? ownerDriverId})` | حفظ النموذج مع دعم offline | نتيجة حفظ أو فشل | `form_tab_provider.dart:319` |
| `getEvents` | `Future<Either<Failure, List<LogEvent>>> getEvents(DailyLogId logId, DateTime date)` | أحداث السجل | أحداث أو فشل | `logs_provider.dart:353` |
| `addEvent` | `Future<Either<Failure, bool>> addEvent(LogEvent event, {String? reason, int? ownerDriverId})` | إضافة حدث | نجاح أو فشل | `logs_provider.dart:423`، `logs_provider.dart:428` |
| `updateEvent` | `Future<Either<Failure, LogEvent?>> updateEvent(LogEvent event, {required String reason, DailyLogId? logId, int? ownerDriverId})` | تعديل حدث | الحدث المؤكد أو null أو فشل | `logs_provider.dart:456`، `logs_provider.dart:462` |
| `getReadiness` | `Future<Either<Failure, LogReadiness>> getReadiness(DailyLogId logId)` | جاهزية السجل | جاهزية أو فشل | `certify_log_provider.dart:168` |
| `getCertifyState` | `Future<Either<Failure, LogCertifyState>> getCertifyState(DailyLogId logId)` | حالة الاعتماد | حالة أو فشل | `certify_log_provider.dart:174` |
| `respondToCarrierEdit` | `Future<Either<Failure, bool>> respondToCarrierEdit({required DailyLogId logId, required String editId, required String action, String? driverNotes})` | الرد على تعديل الناقل | نجاح أو فشل | `certify_log_provider.dart:208` |
| `reassignDriving` | `Future<Either<Failure, bool>> reassignDriving({required DailyLogId logId, required int statusId, required int targetCoDriverId, required String annotation})` | إعادة تعيين وقت القيادة لسائق مساعد | نجاح أو فشل | لا استدعاء لـ`LogRepository.reassignDriving` في `lib` أو `test`؛ النداء الوحيد داخل التنفيذ هو `_dailyLogsBackend.reassignDriving` في `log_repository_impl.dart:713` |
| `certifyLog` | `Future<Either<Failure, bool>> certifyLog({required DailyLogId logId, required int driverId, bool certified = true, String? signatureImageBase64})` | اعتماد السجل | نجاح أو فشل | `certify_log_provider.dart:279` |
| `getPeriods` | `Future<Either<Failure, List<DutyPeriod>>> getPeriods(DateTime date)` | فترات العمل من `core` | فترات أو فشل | `log_duty_period_store.dart:12` خارج الميزة |
| `savePeriod` | `Future<Either<Failure, bool>> savePeriod(DutyPeriod period)` | حفظ فترة | نجاح أو فشل | `log_duty_period_store.dart:21` خارج الميزة |
| `logAudit` | `Future<Either<Failure, bool>> logAudit(AuditEntry entry)` | كتابة إدخال تدقيق | نجاح أو فشل | `send_logs_page.dart:126`، `edit_log_provider.dart:157` |
| `getAuditEntries` | `Future<Either<Failure, List<AuditEntry>>> getAuditEntries(DateTime date)` | إدخالات يوم | إدخالات أو فشل | لا استدعاء لـ`LogRepository.getAuditEntries` في `lib` أو `test`؛ النداء الوحيد `log_repository_impl.dart:754` يخصّ `_localDataSource.getAuditEntries` |
| `getRecentAuditEntries` | `Future<Either<Failure, List<AuditEntry>>> getRecentAuditEntries({int limit = 100})` | أحدث الإدخالات | إدخالات أو فشل | `audit_trail_provider.dart:10` |
| `saveDraftSignature` | `Future<void> saveDraftSignature(DailyLogId logId, String pointsJson)` | حفظ مسودة توقيع كنص JSON | لا يوجد | `log_draft_signature_provider.dart:41` |
| `getDraftSignature` | `Future<String?> getDraftSignature(DailyLogId logId)` | قراءة مسودة كنص JSON | نص أو null | `log_draft_signature_provider.dart:22` |
| `deleteDraftSignature` | `Future<void> deleteDraftSignature(DailyLogId logId)` | حذف المسودة | لا يوجد | `log_draft_signature_provider.dart:39`، `log_draft_signature_provider.dart:50` |

منهج التحقق: بحث `Select-String` بنمط الاستدعاء `\.<methodName>\(` في `lib` و`test`، لا بنمط الاسم. الصفوف بلا استدعاء صريح مكتوب عليها «لا استدعاء»، ولا يُستدل على الاستدعاء من ذكر الاسم.

### تصحيحات المصالحة (2026-10-27)

هذه التصحيحات لا تغيّر ملفات المصدر؛ إنها تصحّح نسبة الاستشهادات في هذا التقرير.

| الموضع | الاستشهاد السابق | ما يقرأه السطر فعلًا | المالك الصحيح | الإجراء |
|---|---|---|---|---|
| `DailyLog.date` | `log_detail_page.dart:213` | `selectedLog.formattedDate` | `DailyLog.formattedDate` | نُقل إلى صف `formattedDate` |
| `DailyLog.vehicleName` | `logs_provider.dart:216` | `log.trailers` | `DailyLog.trailers` | حُذف من `vehicleName` |
| `DailyLog.vehicleName` | `form_tab_provider.dart:161` | `serverForm?.vehicleName` | `DailyFormData.vehicleName` | حُذف من `DailyLog` |
| `DailyLog.shippingDocuments` | `form_tab_provider.dart:199` | `serverForm?.shippingDocuments` | `DailyFormData.shippingDocuments` | حُذف من `DailyLog` |
| `DailyLog.isCertified` | `log_repository_impl.dart:679` | `data.isCertified` | `CertifyResponseDto.isCertified` في `certify_dto.dart:43` | حُذف من `DailyLog` |
| `LogEvent.location` | `edit_log_page.dart:224` | `formState.location` | `EditLogFormState.location` في `edit_log_form_provider.dart:12` | حُذف من `LogEvent` |
| `LogEvent.id` | `logs_provider.dart:400` | `e.isExpanded` | `LogEvent.isExpanded` | حُذف من `id` وبقي في `isExpanded` |
| `LogEvent` constructor | `eld_daily_logs_backend.dart:240`، `eld_daily_logs_backend.dart:255` | `EldEndpoints.dailyLogEvent(...)` | ليس بناء `LogEvent` | حُذف الاستشهادان |
| `logAudit` | `send_logs_page.dart:124` | `.logAudit(` في `send_logs_page.dart:126` | `LogRepository.logAudit` | صُحح السطر |
| `getReadiness` | `certify_log_provider.dart:86` | معامل `copyWith` | ليس استدعاءً | صُحح إلى `certify_log_provider.dart:168` |
| `getCertifyState` | `certify_log_provider.dart:87` | معامل `copyWith` | ليس استدعاءً | صُحح إلى `certify_log_provider.dart:174` |
| `getAuditEntries` | `audit_trail_provider.dart` | `getRecentAuditEntries(limit: 100)` في `audit_trail_provider.dart:10` | `LogRepository.getRecentAuditEntries` | كُتب «لا استدعاء» |
| `DailyFormData.vehicleName` | `logs_provider.dart:216` | `log.trailers` | `DailyLog.trailers` | حُذف؛ والسطر `logs_provider.dart:215` يقرأ `log.vehicleName` ويُسند إلى `DailyFormData.vehicleName` عند البناء، فهو قراءة لـ`DailyLog` لا لحقل `DailyFormData` |
| `DailyLog.uniqueId` | `logs_provider.dart:250` | `current.uniqueId` | `DailyLog.uniqueId` | صُحح اسم المستقبِل من `log` إلى `current` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- انتهاك حدود الطبقات:
  - domain يستورد `core/error/failure.dart` في السطر 2، فيعتمد على نوع خطأ خارج الميزة.
  - domain يستورد `core/domain/entities/hos_models.dart` في السطر 8، فيعتمد على كيان `DutyPeriod` من `core`.
- واجهة عريضة جدًا: 20 دالة في عقد واحد تغطي القائمة والتفاصيل والنموذج والأحداث والجاهزية والاعتماد وتعديلات الناقل والفترات والتدقيق والمسودات. هذا مخالف لمبدأ فصل الواجهات (ISP) ومبدأ المسؤولية الواحدة (SRP).
- تسريب تفصيل تخزين: `pointsJson` نص خام في السطر 114، و`getDraftSignature` يعيد `String?` خامًا في السطر 115. عقد domain يعرف صيغة تخزين المسودة.
- قيم افتراضية سحرية: `size = 20` في السطر 20، و`limit = 100` في السطر 110.
- دلالات غير موثقة: قيم `action` المقبولة في `respondToCarrierEdit` غير مذكورة في السطر 84. معنى `reassignDriving` الدقيق غير مذكور في الأسطر 87-92. `⚠️ غير واضح — يحتاج توضيح`.
- لا توجد أي دالة `dispose` أو إدارة موارد؛ العقد كله عمليات.

---

## 9. `lib/features/logs/domain/log_edit.dart`

- **الطبقة:** domain
- **المسؤولية في جملة واحدة:** قواعد منع تعديل القيادة الآلية، وتحويل نص وقت النموذج إلى `DateTime` على يوم السجل.
- **عدد الأسطر:** 61
- **الاعتمادات:**
  - داخل الميزة: `entities/daily_log.dart`.
  - من `core/`: لا يوجد.
  - حزم خارجية: لا يوجد.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `presentation/providers/edit_log_form_provider.dart:6`، `presentation/providers/edit_log_provider.dart:11`.
  - خارج الميزة: لا يوجد.
  - الاختبارات: `test/features/logs/log_edit_test.dart:3`.

### الدوال

| الاسم | التوقيع الكامل | الغرض | المدخلات | المخرجات | من يستدعيها |
|---|---|---|---|---|---|
| `isAutomaticDrivingEvent` | `bool isAutomaticDrivingEvent(LogEvent event)` | هل الحدث قيادة آلية | `LogEvent` | `bool` | داخليًا من `refuseAutomaticDrivingEdit` في السطر 15 فقط؛ لا توجد قراءة خارجية |
| `refuseAutomaticDrivingEdit` | `String? refuseAutomaticDrivingEdit({required LogEvent original, required String newStatusCode, required DateTime newStart})` | رفض تغيير حالة أو وقت حدث آلي | حدث أصلي، حالة جديدة، وقت جديد | `'automatic_driving'` أو null | `edit_log_provider.dart:105`، `log_edit_test.dart:39`، `log_edit_test.dart:47` |
| `parseEditFormTime` | `DateTime? parseEditFormTime(String raw, DateTime? logDate, [DateTime? fallbackDate])` | تحليل `HH:mm` أو `h:mm[:ss] AM/PM` | نص الوقت، تاريخ السجل، تاريخ بديل | `DateTime?` | `edit_log_form_provider.dart:77`، `edit_log_form_provider.dart:84`، `edit_log_provider.dart:85`، `time_picker_sheet.dart:104`، `log_edit_test.dart:10`، `log_edit_test.dart:15`، `log_edit_test.dart:18`، `log_edit_test.dart:19`، `log_edit_test.dart:23`، `log_edit_test.dart:24`، `log_edit_test.dart:25` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- عيب تحقق في `parseEditFormTime`:
  - نمط 12 ساعة في الأسطر 44-47 يسمح بأي ساعة من 0 إلى 23 ثم يضيف 12 عند PM فقط إن كانت أقل من 12. لذلك `13:00 PM` يبقى 13:00 ويُقبل لأن الشرط في السطر 55 هو `h < 24` فقط.
  - الثواني تُقرأ في السطر 51 ولا تُتحقق؛ `08:15:99 PM` يعيد `DateTime` بالثانية 99 بدل الرفض.
  - لا توجد اختبارات لهاتين الحالتين في `log_edit_test.dart`.
- مقارنة زمنية دقيقة أكثر من اللازم:
  - `refuseAutomaticDrivingEdit` يقارن `newStart != original.startTime` في السطر 16 بمقارنة `DateTime` كاملة.
  - نموذج التعديل يقرأ الوقت بصيغة `HH:mm` من `formattedStartTime` في `daily_log.dart:198-202`، فيضيع عدد الثواني.
  - `parseEditFormTime` يبني الوقت بالثواني صفرًا في السطر 40 عندما لا تُذكر الثواني.
  - إعادة حفظ حدث آلي دون تغيير الوقت قد تُرفض لأن الثواني الأصلية تختلف عن الصفر. هذا استنتاج من مسار الكود ويحتاج اختبارًا تأكيديًا قبل تصنيفه كخطأ مؤكد.
- نص مكتوب يدويًا: `'automatic_driving'` في السطر 17.
- دوال أطول من 40 سطرًا: لا يوجد.

---

## 10. `lib/features/logs/domain/daily_form_rules.dart`

- **الطبقة:** domain
- **المسؤولية في جملة واحدة:** المصدر الوحيد لقواعد قوائم النموذج اليومي: تقسيم ودمج المقطورات ووثائق الشحن، والتحقق من التسميات والنصوص الحرة.
- **عدد الأسطر:** 91
- **الاعتمادات:**
  - داخل الميزة: لا يوجد.
  - من `core/`: لا يوجد.
  - حزم خارجية: لا يوجد.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `presentation/mappers/form_validation_mapper.dart:2`، `presentation/pages/edit_log_page.dart:13`، `presentation/providers/form_list_provider.dart:3`، `presentation/providers/form_tab_provider.dart:6`.
  - خارج الميزة: `lib/features/home/presentation/providers/dashboard_provider.dart:2`.
  - الاختبارات: `test/features/logs/presentation/pages/trailers_page_test.dart:9`.

### الثوابت والأEnums

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `_placeholders` | `Set<String>` خاص | القيم التي تُحذف عند التقسيم | 8 |
| `maxTrailerNumberLength` | `int` عام | حد طول رقم المقطورة | 11 |
| `maxShippingDocumentLength` | `int` عام | حد طول وثيقة الشحن | 12 |
| `TrailerValidationError` | enum | أخطاء المقطورة: `empty`، `tooLong`، `formatError` | 62 |
| `ShippingDocValidationError` | enum | أخطاء الوثيقة: `empty`، `tooLong`، `containsComma`، `formatError` | 64 |
| `_labelBase` | `RegExp` خاص | التسمية الأساسية | 32 |
| `_labelWithSlash` | `RegExp` خاص | التسمية مع `/` | 33 |
| `_labelSubstance` | `RegExp` خاص | وجود حرف أو رقم | 36 |
| `_freeTextChars` | `RegExp` خاص | أحرف النص الحر | 41 |

### الدوال

| الاسم | التوقيع الكامل | الغرض | المخرجات | من يستدعيها |
|---|---|---|---|---|
| `splitFormList` | `List<String> splitFormList(String? raw)` | تقسيم النص إلى عناصر وحذف placeholders | `List<String>` | `form_list_provider.dart:103`، `form_tab_provider.dart:57`، `form_tab_provider.dart:67`، `form_tab_provider.dart:92`، `dashboard_provider` |
| `joinFormList` | `String joinFormList(List<String> items)` | دمج العناصر أو إرجاع `None` | `String` | `form_tab_provider.dart:185`، `form_tab_provider.dart:187`، `form_tab_provider.dart:200`، `form_tab_provider.dart:202`، `dashboard_provider.dart:161`، `dashboard_provider.dart:166`، `dashboard_provider.dart:183`، `dashboard_provider.dart:185` |
| `isFormLabelValid` | `bool isFormLabelValid(String value, int maxLength, {bool allowSlash = false})` | تحقق تسمية | `bool` | `form_list_provider.dart:138`، داخليًا من `validateTrailerNumber` و`validateShippingDocument` |
| `isFreeTextValid` | `bool isFreeTextValid(String value, {int maxLength = 200})` | تحقق نص حر | `bool` | `edit_log_page.dart:248`، `edit_log_page.dart:277` |
| `validateTrailerNumber` | `TrailerValidationError? validateTrailerNumber(String value)` | تحقق رقم مقطورة | enum أو null | `form_validation_mapper.dart:9` |
| `validateShippingDocument` | `ShippingDocValidationError? validateShippingDocument(String value)` | تحقق وثيقة شحن | enum أو null | `form_validation_mapper.dart:20` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- حساسية حالة الأحرف: `_placeholders` في السطر 8 يحتوي `None` و`none` و`-` و`''` فقط. القيم `NONE` أو `Null` لا تُحذف.
- سلسلة سحرية إنجليزية داخل domain: `joinFormList` يعيد `'None'` في السطر 26، وهي قيمة تُقارن بها الواجهة في `form_tab_provider.dart:134` و`form_tab_provider.dart:180`.
- حد افتراضي سحري: `maxLength = 200` في السطر 56.
- الثابتان `maxTrailerNumberLength` و`maxShippingDocumentLength` عامّان لكن لا يُستوردان خارج هذا الملف؛ يُستخدمان داخليًا فقط في الأسطر 70 و73 و83 و87.
- لا توجد اختبارات مباشرة لـ`isFreeTextValid` أو لثوابت الطول داخل `test/features/logs`.
- دوال أطول من 40 سطرًا: لا يوجد.

---

## 11. `lib/features/logs/domain/saved_form_status.dart`

- **الطبقة:** domain
- **المسؤولية في جملة واحدة:** تمثيل نتيجة قراءة حالة النموذج المحفوظ ونتيجة الحفظ أونلاين أو أوفلاين.
- **عدد الأسطر:** 18
- **الاعتمادات:**
  - داخل الميزة: لا يوجد.
  - من `core/`: لا يوجد.
  - حزم خارجية: لا يوجد.
- **من يستورد هذا الملف؟**
  - داخل الميزة: `data/models/saved_form_dto.dart:1`، `data/repositories/log_repository_impl.dart:30`، `domain/repositories/log_repository.dart:7`.
  - خارج الميزة: لا يوجد.
  - الاختبارات: `test/features/logs/presentation/pages/trailers_page_test.dart:13`.

### الكلاسات

| الاسم | النوع | الوصف | السطر |
|---|---|---|---|
| `SavedFormRead` | class عادي | حالة النموذج المقروءة من الخادم | 2 |
| `FormSaveResult` | class عادي | نتيجة الحفظ | 11 |

### الحقول

| الاسم | النوع | public/private | final | الغرض | السطر | قراءة مؤكدة | كتابة مؤكدة |
|---|---|---|---|---|---|---|---|
| `SavedFormRead.formStatus` | `String?` | public | final | حالة النموذج النصية | 3 | لا توجد قراءة خارجية مؤكدة | `saved_form_dto.dart:40` |
| `SavedFormRead.complete` | `bool?` | public | final | هل النموذج مكتمل | 4 | `form_tab_provider.dart:354` | `saved_form_dto.dart:40` |
| `SavedFormRead.message` | `String?` | public | final | رسالة الخادم | 5 | لا توجد قراءة خارجية مؤكدة | `saved_form_dto.dart:40` |
| `FormSaveResult.isOffline` | `bool` | public | final | هل الحفظ محلي | 12 | `form_tab_provider.dart:335` | `saved_form_status.dart:15`، `saved_form_status.dart:17` |
| `FormSaveResult.syncedData` | `SavedFormRead?` | public | final | بيانات الخادم بعد الحفظ | 13 | `form_tab_provider.dart:353` بقوة `!` | `saved_form_status.dart:17` |

### الدوال

| الاسم | التوقيع الكامل | الغرض | من يستدعيها |
|---|---|---|---|
| `SavedFormRead` | `const SavedFormRead({String? formStatus, bool? complete, String? message})` | إنشاء حالة قراءة | `saved_form_dto.dart:40` |
| `FormSaveResult.offline` | `const FormSaveResult.offline() : isOffline = true, syncedData = null` | نتيجة حفظ محلي | `log_repository_impl.dart:500` |
| `FormSaveResult.online` | `const FormSaveResult.online(SavedFormRead? syncedData) : isOffline = false` | نتيجة حفظ من الخادم | `log_repository_impl.dart:524` |

### حقائق مرصودة

- كود معلّق: لا يوجد.
- TODO / FIXME / HACK: لا يوجد.
- Imports غير مستخدمة: لا يوجد.
- عقد نوعي ضعيف:
  - `FormSaveResult.online` يقبل `SavedFormRead?` في السطر 17، أي يسمح نظريًا بإنشاء نتيجة online بلا بيانات.
  - المستهلك في `form_tab_provider.dart:353` يستخدم `saveResult.syncedData!` قسرًا.
  - التنفيذ الحالي في `log_repository_impl.dart:516-524` يمرر كائنًا غير null، لذلك لا يوجد انهيار حالي، لكن النوع لا يمنع الحالة.
- حقلا `formStatus` و`message` في `SavedFormRead` لا يُقرآن خارجيًا.
- لا يوجد `Equatable`، ولا اختبار مباشر لـ`FormSaveResult`؛ اختبار `saved_form_status_test.dart` يختبر `SavedFormDto` فقط.
- نصوص مكتوبة يدويًا: لا يوجد.
- دوال أطول من 40 سطرًا: لا يوجد.

---


## الآراء

نُقلت آراء هذه الطبقة وقراراتها وأسئلتها إلى `docs/audits/logs/_draft_domain_opinions.md` في 2026-10-27. هذا الملف جرد حقول وعقد فقط، ولا يحتوي توصيات تنفيذ.
