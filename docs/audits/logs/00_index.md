# فهرس تدقيق ميزة `logs`

## هوية التقرير

- **المهمة:** جرد تحليلي (Code Inventory & Audit) لميزة `logs` قبل أي إعادة هيكلة.
- **المسار الفعلي:** `lib/features/logs/` (مطابق للمسار المطلوب).
- **تاريخSnapshot:** 2026-10-26.
- **الفرع:** `fix/logs-phase-0`.
- **حالة شجرة العمل:** غير نظيفة. توجد تعديلات غير محفوظة داخل الميزة نفسها:
  - `lib/features/logs/presentation/pages/edit_log_page.dart`
  - `lib/features/logs/presentation/providers/edit_log_form_provider.dart`
  - `lib/features/logs/presentation/providers/edit_log_provider.dart`
  - `lib/features/logs/presentation/widgets/time_picker_sheet.dart`
  - وملفات خارج الميزة: `lib/backend/adapters/eld_engine/models/dvir_dto.dart`، `lib/features/dvir/data/mappers/dvir_mappers.dart`، `lib/features/dvir/domain/entities/dvir_report.dart`، ملفات `l10n` الثمانية.
  - ملفات غير متتبعة: `.zcode/`.
- **مهم:** كل ما في هذا التقرير يصف شجرة العمل الحالية، لا نسخة `HEAD`.

### تجميد استشهادات الملفات غير المحفوظة

الملفات الأربعة التالية كانت معدّلة وغير محفوظة وقت الجرد. استشهاداتها في `01_domain.md` و`02_data.md` مسجّلة مقابل البصمات التالية (عدد الأسطر وSHA-256). أي تغيير لاحق في أحدها يُبطل الاستشهادات ويوجب إعادة فتح الملف قبل المرحلة 3:

| الملف | الأسطر | SHA-256 |
|---|---:|---|
| `lib/features/logs/presentation/pages/edit_log_page.dart` | 317 | `6EB53EBD2C4F0B814ED909A70A2B9E95D6E456D63B11AA6F8E82AD28356B6015` |
| `lib/features/logs/presentation/providers/edit_log_form_provider.dart` | 160 | `531B6CECDE2DAB37A4C545FC3474DF0DFDABD4F0935D050B5CFB91E775432DF1` |
| `lib/features/logs/presentation/providers/edit_log_provider.dart` | 186 | `2FFE120B775CBBCDC46DFC5587549137850C3B8670A97B2E87A87546A3EB8FB3` |
| `lib/features/logs/presentation/widgets/time_picker_sheet.dart` | 264 | `80DC2C0253927B34C7709778529ABFB06051289E7B01C47F9871159CA910104A` |

## نطاق هذه المرحلة

الميزة تحتوي **64 ملف Dart** في `lib/features/logs` و**30 ملف اختبار** في `test/features/logs`، أي أكثر من حد الـ15 ملفًا الذي اشترط صاحب الطلب عنده التقسيم. لذلك يُنفَّذ الجرد على مراحل:

| المرحلة | المحتوى | الحالة |
|---|---|---|
| 1 | الشجرة + طبقة `domain` | مكتملة في `01_domain.md` |
| 2 | طبقة `data` | مكتملة في `02_data.md` |
| 3 | طبقة `presentation` (providers/pages/widgets/mappers) | لم تبدأ |
| 4 | خريطة الحالة + تدفقات البيانات + الحدود + الخلاصة النهائية | لم تبدأ |

هذا الفهرس **لا يدّعي** اكتمال الجرد. الأرقام الإجمالية للكلاسات والدوال والمتغيرات والـProviders على مستوى الميزة ستُحدَّث بعد اكتمال المراحل.

## منهجية الإثبات

1. قراءة كل ملف من طبقة `domain` كاملًا.
2. البحث عن كل رمز بـ `Select-String` على كل ملفات `lib/` و`test/` لأن `rg` غير مثبت على الجهاز.
3. تمييز القراءة الخارجية للحقول عبر نمط `.fieldName`، وتمييز الكتابة عبر أسماء الوسائط في `copyWith` والـconstructors.
4. كل سطر مُستشهد به تم فتح الملف حوله والتأكد من مضمونه، إلا حيث وُسم صراحة بأنه يحتاج توضيحًا.
5. الملفات المولّدة (`*.g.dart`، `*.freezed.dart`) غير موجودة داخل `logs`، لذلك لم يُستثنَ منها شيء.

## الشجرة الكاملة

الرقم بعد كل مسار هو عدد الأسطر.

```text
lib/features/logs/                                  64 ملفًا   9487 سطرًا
├── domain/                                          11 ملفًا    890 سطرًا
│   ├── entities/
│   │   ├── audit_entry.dart                                    100
│   │   ├── daily_form_data.dart                                 37
│   │   ├── daily_form_update.dart                               35
│   │   ├── daily_log.dart                                      252
│   │   ├── daily_log_page.dart                                  21
│   │   ├── log_certify_state.dart                               53
│   │   └── log_readiness.dart                                  105
│   ├── repositories/
│   │   └── log_repository.dart                                 117
│   ├── daily_form_rules.dart                                    91
│   ├── log_edit.dart                                            61
│   └── saved_form_status.dart                                   18
├── data/                                             7 ملفات   1742 سطرًا
│   ├── codecs/
│   │   └── signature_draft_codec.dart                            51
│   ├── datasources/
│   │   └── log_local_data_source.dart                           469
│   ├── models/
│   │   ├── daily_log_dto.dart                                   215
│   │   ├── log_model.dart                                       158
│   │   └── saved_form_dto.dart                                   42
│   ├── providers/
│   │   └── log_repository_providers.dart                         24
│   └── repositories/
│       └── log_repository_impl.dart                             783
└── presentation/                                    46 ملفًا   6855 سطرًا
    ├── mappers/
    │   ├── form_validation_mapper.dart                           28
    │   └── inspection_preview_event_mapper.dart                  91
    ├── pages/
    │   ├── audit_trail_page.dart                                 99
    │   ├── edit_log_page.dart                                   317
    │   ├── inspection_preview_page.dart                          367
    │   ├── log_detail_page.dart                                 349
    │   ├── logs_list_page.dart                                  146
    │   ├── shipping_documents_page.dart                           79
    │   ├── suggested_events_page.dart                            128
    │   ├── trailers_page.dart                                    75
    │   └── unidentified_events_page.dart                        219
    ├── providers/
    │   ├── audit_trail_provider.dart                              12
    │   ├── certify_log_provider.dart                             302
    │   ├── edit_log_form_provider.dart                           160
    │   ├── edit_log_provider.dart                                186
    │   ├── form_list_provider.dart                               144
    │   ├── form_tab_provider.dart                                384
    │   ├── log_detail_tab_provider.dart                           10
    │   ├── log_draft_signature_provider.dart                      64
    │   ├── logs_provider.dart                                    504
    │   ├── shipping_documents_provider.dart                       49
    │   ├── suggested_events_provider.dart                         18
    │   ├── trailers_provider.dart                                 40
    │   └── unidentified_events_provider.dart                     507
    └── widgets/
        ├── annotation_dialog.dart                                52
        ├── codriver_picker_dialog.dart                          123
        ├── form_list_editor_view.dart                           115
        ├── inspection_audit_trail_section.dart                   82
        ├── inspection_filter_dialog.dart                          66
        ├── log_graph.dart                                         99
        ├── log_list_item.dart                                    107
        ├── status_chip.dart                                       35
        ├── status_radio_group.dart                                62
        ├── suggested_log_card.dart                                49
        ├── time_field_widget.dart                                 53
        ├── time_picker_sheet.dart                                264
        ├── unidentified_events_list.dart                         162
        ├── unidentified_stats_row.dart                            54
        ├── vehicle_picker_dialog.dart                            170
        ├── log_detail_tabs/
        │   ├── carrier_edit_card.dart                             62
        │   ├── certify_tab.dart                                  340
        │   ├── events_tab.dart                                   150
        │   ├── expanded_content.dart                              56
        │   ├── form_tab.dart                                    251
        │   ├── log_event_tile.dart                               177
        │   └── pending_carrier_edits_section.dart                 48
```

ملاحظة تدقيق: المجلد لا يحتوي أي ملفات `*.g.dart` أو `*.freezed.dart`.

## الأرقام الإجمالية المرحلية

| المؤشر | الإجمالي في `lib/features/logs` | طبقة `domain` فقط | طبقة `data` فقط |
|---|---:|---:|---:|
| الملفات | 64 | 11 | 7 |
| الأسطر | 9487 | 890 | 1742 |
| الكلاسات | لم تُحسب بعد | 12 | 7 |
| الـEnums | لم تُحسب بعد | 4 | 0 |
| الدوال والـMethods (تشمل constructors/getters/factories) | لم تُحسب بعد | 62 | 92 |
| الحقول (fields) | لم تُحسب بعد | 92 | 27 |
| الثوابت (top-level وclass-static) | لم تُحسب بعد | 8 | 1 |
| الـProviders | لم تُحسب بعد | 0 | 2 |

ملاحظة: طبقة `presentation` (46 ملفًا، 6855 سطرًا) لم تُجرَد بعد؛ أرقامها ستُضاف بعد المرحلة 3، وعندها يكتمل مجموع الميزة: 11 + 7 + 46 = 64 ملفًا، و890 + 1742 + 6855 = 9487 سطرًا.

ملاحظة تدقيق (2026-10-27): تحقّق بأمر `Get-ChildItem` أن `lib/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart` موجود فعلًا وطوله **251 سطرًا**، وأن مجلد `presentation` يحتوي **46 ملفًا / 6855 سطرًا**، وأن `lib/features/logs` يحتوي **64 ملفًا / 9487 سطرًا**. كان `form_tab.dart` غائبًا من الشجرة في نسخة سابقة، وقد أُضيف إلى شجرة `presentation` أعلاه. الأرقام هنا مأخوذة من ناتج الأمر لا من تقدير.

## ملفات الاختبار

`test/features/logs` يحتوي **30 ملفًا** بمجموع **5026 سطرًا**. الملفات ذات الصلة المباشرة بطبقة `domain`:

| الملف | ما يغطيه فعلًا | الأسطر |
|---|---|---:|
| `test/features/logs/log_edit_test.dart` | `parseEditFormTime` (24h، 12h مع ثوانٍ، مدخلات غير صالحة)، و`refuseAutomaticDrivingEdit` (تغيير الحالة/الوقت) | 55 |
| `test/features/logs/audit_entry_test.dart` | `toMap`/`fromMap`، الطوابع الزمنية القديمة، الصفوف التالفة، حقول SRS 7.16 | 82 |
| `test/features/logs/domain/log_event_equality_test.dart` | تساوي `LogEvent` وعدم فقدان الحقول الاختيارية عند `copyWith` | 57 |
| `test/features/logs/saved_form_status_test.dart` | `SavedFormDto.fromJson` وقرار `complete` (لا يختبر `FormSaveResult` نفسه) | 27 |
| `test/features/logs/data/models/daily_log_dto_test.dart` | تحويل DTO إلى `DailyLog`، بما فيه الحقول النصية التفصيلية | 186 |
| `test/features/logs/data/log_repository_offline_test.dart` | قراءة القائمة والأحداث دون اتصال عبر `LogRepositoryImpl` | 310 |

لا توجد اختبارات مباشرة للعناصر التالية: `LogReadiness.formatRequirement`، `CarrierProposedEditEntity.displaySummary`، `DailyLog.formattedDate`، `DailyLog.dayName`، `DailyLogPage`، `DailyFormData`، `DailyFormUpdate`، `LogCertifyState`.

## ملفات التقرير

| الملف | المحتوى | الحالة |
|---|---|---|
| `00_index.md` | هذا الملف | مكتمل لهذه المرحلة |
| `01_domain.md` | الجرد التفصيلي لطبقة `domain` | مكتمل |
| `02_data.md` | الجرد التفصيلي لطبقة `data` | مكتمل |
| `_draft_domain_opinions.md` | الآراء والقرارات والأسئلة المنقولة من `01_domain.md`، وقائمة الاعتماد الخارجي الكاملة | مسودة غير معتمدة |
| `03_presentation.md` | الجرد التفصيلي لطبقة `presentation` | لم يُنشأ بعد |
| `04_state_map.md` | خريطة الحالة وتدفقات البيانات | لم يُنشأ بعد |
| `05_boundaries.md` | الحدود والاعتمادات المشتركة | لم يُنشأ بعد |
| `06_summary.md` | الخلاصة النهائية وترتيب التنفيذ | لم يُنشأ بعد |
