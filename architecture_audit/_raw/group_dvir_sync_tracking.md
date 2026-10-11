# Group: dvir + inspection + sync + tracking + vehicle — Layer/Responsibility Audit

**نطاق التدقيق:** 91 ملف Dart (مستبعد `*.g.dart` و `*.freezed.dart`)، إجمالي 11,080 سطر — تم قراءة كل ملف بالكامل.
**قاعدة الحكم:** كل بيان مبني على قراءة الملف بالكامل + `path:line` دقيق + مقتطف كود منسوخ حرفياً.
**مستويات الخطورة:** Critical / High / Medium / Low.
**نوع الدليل:** CONFIRMED (مُتحقَّق منه) / POTENTIAL (يستدعي مراجعة بشري).
**قيود مُطبَّقة:** Riverpod داخل Widget ليس مخالفة. حجم الملف ليس مخالفة بذاته. أسماء الملفات لا تُستخدم كدليل — كل ملف فُتح وقُرئ.

---

## A. Per-file findings

### `lib/features/dvir/domain/repositories/dvir_repository.dart` (43 lines, non-empty 43)
- **المسؤوليات:** عقد مجرّد لـ 7 عمليات DVIR.
- **الطبقة معلنة/فعلية:** domain / domain
- **الحالة:** سليم. `fpdart` + `core/error/failure.dart` مقبولان كـ shared kernel. صفر Flutter/Dio/Riverpod.
- **Issue IDs:** —

### `lib/features/dvir/domain/defect_enums.dart` (37, 37)
- **المسؤوليات:** `DefectSeverity` و `DefectLifecycleStage` + `fromWire`.
- **الطبقة:** domain / domain — سليم.
- **Issue IDs:** —

### `lib/features/dvir/domain/dvir_catalog.dart` (64, 64)
- **المسؤوليات:** `DvirCatalogItem`، `DvirDefectSelection`، وثابت `kStandardTrailerDefectItems` (15 عنصر §396.11 للمقطورات).
- **الطبقة:** domain / domain — سليم. ملاحظة Low: `props` (سطر 43) يتجاهل `severity` و`stage`.
- **Issue IDs:** —

### `lib/features/dvir/domain/dvir_list_summary.dart` (33, 33)
- **المسؤوليات:** `DvirListSummary` + `summarizeDvirReports` (عدّاد اشتقاقي).
- **الطبقة:** domain / domain — سليم (تجميع في الـ domain لا في Widget).
- **Issue IDs:** —

### `lib/features/dvir/domain/dvir_signature.dart` (9, 9)
- **المسؤوليات:** `dvirSignatureData(bytes)` → base64.
- **الطبقة:** domain / domain (`dart:convert` فقط) — سليم.
- **Issue IDs:** —

### `lib/features/dvir/domain/dvir_vehicle.dart` (8, 8)
- **المسؤوليات:** `noVehicleSentinel = 'No Vehicle'` + `isUnassignedVehicleId`.
- **الطبقة:** domain — سليم منطقياً، لكن الحرفي يُستهلك في ثلاث طبقات.
- **Issue IDs:** DST-012

### `lib/features/dvir/domain/entities/dvir_defect.dart` (73, 73)
- **المسؤوليات:** `DvirDefect` + `DvirRepairAction` + `DvirDefectCertification`.
- **الطبقة:** domain — سليم، لكن `severity`/`stage` نصّان خامان رغم وجود enums.
- **Issue IDs:** DST-013

### `lib/features/dvir/domain/entities/dvir_report.dart` (266, 266)
- **المسؤوليات:** كيان + 3 enums + `DvirTrailer` + مشتقّان (`vehicleOperationalStatus`, `retentionUntil` 3 أشهر) + `copyWith` (30 حقلاً).
- **الطبقة:** domain — سليم: قواعد العمل في مكانها الصحيح.
- **Issue IDs:** —

### `lib/features/dvir/data/mappers/dvir_mappers.dart` (208, 208)
- **المسؤوليات:** `parseDvirCatalog`، `_findList`، `defectSelectionToWire`، `_defects`، `buildDvirCreateBody` (+ `extractDetects` داخلي).
- **الطبقة:** data / data — لكن `buildDvirCreateBody` يطبّع قاعدة عمل DVIR-09.
- **Issue IDs:** DST-005, DST-006

### `lib/features/dvir/data/mappers/dvir_defect_mappers.dart` (91, 91)
- **المسؤوليات:** `parseDvirDefect`، `parseDvirDefectList`، helpers.
- **الطبقة:** data / data — **نظيف تماماً**.
- **Issue IDs:** —

### `lib/features/dvir/data/repositories/dvir_repository_impl.dart` (388, 388)
- **المسؤوليات:** 7 عمليات + `guardedNetwork` + بناء جسم الإنشاء + **DTO→entity mapping داخلي** (`_mapDtoToEntity`, 61 سطراً) + `_parseDate`/`_parseInspectionType`/`_parseVehicleCondition`.
- **الطبقة:** data / data + business rule (انحراف جزئي).
- **Issue IDs:** DST-004, DST-005, DST-006, DST-007

### `lib/features/dvir/data/providers/dvir_repository_providers.dart` (17, 17)
- **المسؤوليات:** تركيب `DvirRepositoryImpl`.
- **الطبقة:** data/DI — سليم؛ يستورد `sync/data/providers` (data-to-data).
- **Issue IDs:** DST-018

### `lib/features/dvir/presentation/extensions/dvir_catalog_extensions.dart` (9, 9)
- **المسؤوليات:** `label(loc)` لعنصر الكتالوج.
- **الطبقة:** presentation / presentation — سليم (تعليق الملف يبرر الموقع).
- **Issue IDs:** —

### `lib/features/dvir/presentation/extensions/dvir_status_extensions.dart` (37, 37)
- **المسؤوليات:** `label` + `color` لـ `VehicleOperationalStatus` و `DvirConditionStatus`.
- **الطبقة:** presentation — سليم بنيوياً؛ يحوي نصوصاً خارج l10n.
- **Issue IDs:** DST-011

### `lib/features/dvir/presentation/pages/dvir_list_page.dart` (340, 340)
- **المسؤوليات:** Scaffold + `_DvirSummaryRow` + `ActiveDefectsSection` + `_DvirCard`.
- **الطبقة:** presentation — تصنيف حالة العيب بمقارنة نص wire داخل Widget.
- **Issue IDs:** DST-014

### `lib/features/dvir/presentation/pages/dvir_form_page.dart` (690, 690) — **الأخطر في المجموعة**
- **المسؤوليات المقاسة (11):** 6 `TextEditingController`؛ `SignatureController` + listener؛ 3 دوال فتح كتالوج العيوب؛ نافذة الحالة؛ منتقي الوقت؛ منتقي المركبة؛ صفحة المقطورات؛ تدفق مراجعة §396.13؛ **حلّ `deviceId`**؛ بناء `DvirReport`؛ تنسيق الإرسال.
- **الطبقة:** presentation / presentation + business validation + **اختراع معرّف**.
- **Issue IDs:** DST-001, DST-006, DST-012

### `lib/features/dvir/presentation/pages/dvir_detail_page.dart` (486, 486)
- **المسؤوليات:** عرض قراءة فقط + `_DetailBody` + 5 widgets فرعية.
- **الطبقة:** presentation — سليم؛ `_DefectCard` يستخدم `DefectLifecycleStage.values` بشكل صحيح؛ `catch (_)` مع بديل عرض = guard مقبول.
- **Issue IDs:** —

### `lib/features/dvir/presentation/providers/dvir_provider.dart` (325, 325)
- **المسؤوليات:** `DvirState` + `DvirNotifier` (5 عمليات) + `dvirCatalogProvider` + `activeVehicleDefectsProvider`.
- **الطبقة:** presentation — قاعدة §396.13 داخل State؛ تحقق توقيع؛ اعتماد ميت.
- **Issue IDs:** DST-003, DST-017

### `lib/features/dvir/presentation/widgets/active_defects_section.dart` (257, 257)
- **المسؤوليات:** قائمة العيوب النشطة + حوار تفاصيل يتحدّث من الخادم.
- **الطبقة:** presentation + **وصول مباشر لمستودع data**؛ تصنيف شدة بـ substring؛ ابتلاع الفشل.
- **Issue IDs:** DST-008, DST-014

### `lib/features/dvir/presentation/widgets/defects_modal.dart` (153, 153)
- **المسؤوليات:** حوار checkbox للكتالوج الحي + ملاحظة لكل بند.
- **الطبقة:** presentation — **سليم** (يقرأ `dvirCatalogProvider` لا المستودع).
- **Issue IDs:** —

### `lib/features/dvir/presentation/widgets/defect_card.dart` (58, 58)
- **المسؤوليات:** عرض عيب + زر إزالة.
- **الطبقة:** presentation — **نظيف**.
- **Issue IDs:** —

### `lib/features/dvir/presentation/widgets/dvir_form_components.dart` (199, 199)
- **المسؤوليات:** 5 widgets تخطيطية.
- **الطبقة:** presentation — **نظيف** (ألوان مثبتة = مرئية لا معمارية).
- **Issue IDs:** —

### `lib/features/dvir/presentation/widgets/dvir_form_sections.dart` (498, 498)
- **المسؤوليات:** 10 أقسام نموذج + `_ReadOnlySignature`.
- **الطبقة:** presentation + **تحقق عمل بنصوص ثلاثية اللغة مكتوبة يدوياً**.
- **Issue IDs:** DST-011

### `lib/features/dvir/presentation/widgets/previous_dvir_review_modal.dart` (74, 74)
- **المسؤوليات:** حوار عرض المراجعة السابقة (يستقبل `previousDefects` جاهزةً).
- **الطبقة:** presentation — **نظيف**.
- **Issue IDs:** —

### `lib/features/dvir/presentation/widgets/status_modal.dart` (81, 81)
- **المسؤوليات:** اختيار `DvirConditionStatus` (يعيد enum لا نص wire).
- **الطبقة:** presentation — **سليم**.
- **Issue IDs:** —

### `lib/features/inspection/data/mappers/inspection_mappers.dart` (120, 120)
- **المسؤوليات:** `readTransferOutcome`، `parseInformationPacket`، `parseTransferAudit`.
- **الطبقة:** data / data — **نظيف**.
- **Issue IDs:** —

### `lib/features/inspection/data/providers/inspection_repository_providers.dart` (15, 15)
- **المسؤوليات:** تركيب `InspectionRepositoryImpl(backend, networkInfo, syncEngine)`.
- **الطبقة:** data/DI — تمرير `SyncEngine` كوسيط ثالث اختياري إلى مستودع.
- **Issue IDs:** DST-018

### `lib/features/inspection/data/repositories/inspection_repository_impl.dart` (266, 266)
- **المسؤوليات:** 7 عمليات + **كاش `static` عام (4 حقول)** + **توليد ملف FMCSA CSV داخل مسار offline** + تسييل حدث للمزامنة.
- **الطبقة:** data / data + global mutable state + بروتوكول نصي للواجهة.
- **Issue IDs:** DST-002, DST-016

### `lib/features/inspection/data/services/fmcsa_eld_output_generator.dart` (208, 208)
- **المسؤوليات:** توليد CSV متوافق 49 CFR Part 395 Appendix A وكتابته على القرص.
- **الطبقة:** data/service.
- **الحالة — نتيجة الفحص المطلوب:** **الفرضية مرفوضة**: لا `import 'package:pdf'` ولا `'package:printing'` ولا `'package:share_plus'` في هذا الملف. بحث شامل على `lib/` أثبت أن `share_plus` يظهر **حصرياً** في `send_logs_page.dart:2`. الاستيرادات الفعلية: `dart:io` + `path_provider` + `intl` + `logger` + domain entities. **لا طبقة عرض داخل طبقة البيانات هنا.**
- **Issue IDs:** DST-009

### `lib/features/inspection/domain/inspection_transfer.dart` (58, 58)
- **المسؤوليات:** `TransferMethod` + `isValidInspectionComment` (4–60) + `TransferOutcome` + `PacketLine` + `InformationPacketView`.
- **الطبقة:** domain / domain — نظيف؛ لكن التحقق مُكرَّر في presentation.
- **Issue IDs:** DST-015

### `lib/features/inspection/domain/transfer_audit.dart` (31, 31)
- **المسؤوليات:** `TransferAuditRow` + `isEmpty`.
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/inspection/domain/repositories/inspection_repository.dart` (43, 43)
- **المسؤوليات:** عقد مجرّد لـ 7 عمليات.
- **الطبقة:** domain — سليم.
- **Issue IDs:** —

### `lib/features/inspection/presentation/pages/dot_inspection_page.dart` (73, 73)
- **المسؤوليات:** Scaffold + `PopScope` + تبديل start/active.
- **الطبقة:** presentation — يستدعي `accountProvider.notifier.fetchMyAccount()` كأثر جانبي.
- **Issue IDs:** DST-019

### `lib/features/inspection/presentation/pages/inspection_active_view.dart` (145, 145)
- **المسؤوليات:** عرض السجل النشط + تنقّل الأيام + جدول + رسم بياني.
- **الطبقة:** presentation — `coDriverId` يُبنى بinterpolation حرفية معطّلة (`'\${...}'`) = عيب سلوكي محتمل لا مخالفة معمارية.
- **Issue IDs:** —

### `lib/features/inspection/presentation/pages/inspection_start_view.dart` (210, 210)
- **المسؤوليات:** 4 أقسام صلاحيات fail-closed + `inspectionDisplayText` (دالة pure) + `_push`.
- **الطبقة:** presentation — **في الغالب نظيف**.
- **Issue IDs:** —

### `lib/features/inspection/presentation/pages/send_logs_page.dart` (332, 332)
- **المسؤوليات:** نموذج بريد/تعليق + قناة + **كتابة سجل تدقيق عبر مستودع logs** + **مشاركة عبر `share_plus`** + تفكيك `OFFLINE_GENERATED:`.
- **الطبقة:** presentation + **اعتماد على data layer لميزة أخرى**.
- **Issue IDs:** DST-016, DST-021

### `lib/features/inspection/presentation/providers/inspection_provider.dart` (367, 367)
- **المسؤوليات:** `InspectionState` + `InspectionNotifier` (start/selectDay/end/sendLogs) + `informationPacketProvider` + `isValidInspectionPin`.
- **الطبقة:** presentation — قاعدة عمل **ميتة**؛ ثابت `days: 8`.
- **Issue IDs:** DST-015

### `lib/features/inspection/presentation/providers/dot_inspection_providers.dart` (60, 60)
- **المسؤوليات:** 3 providers عبر `InspectionRepository`.
- **الطبقة:** presentation — سليم؛ `days: 8` مكرر.
- **Issue IDs:** DST-015

### `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart` (176, 176)
- **المسؤوليات:** رسم 24h + `_hourOf` (5 صيغ وقت) + `_rowOf` (تصنيف duty code بنص حر و5 regex).
- **الطبقة:** presentation + **parsing وتصنيف أعمال**.
- **Issue IDs:** DST-020

### `lib/features/inspection/presentation/widgets/inspection_log_header_table.dart` (259, 259)
- **المسؤوليات:** جدول RODS + **~25 getter اشتقاقية** (سلسلة أفضلية log→day→screen، دمج القوائم، تركيبcarrier).
- **الطبقة:** presentation + قواعد اشتقاق وقواعد 49 CFR §395.8(k).
- **Issue IDs:** DST-010

### `lib/features/sync/data/datasources/sync_local_data_source.dart` (60, 60)
- **المسؤوليات:** عقد + Impl على `SharedPreferences` بمفتاحَي `'sync_queue'` و `'last_sync_time'`.
- **الطبقة:** data / data — `catch (e) { return []; }` (سطر 28) ابتلاع صامت لتلف JSON.
- **Issue IDs:** DST-008, DST-025

### `lib/features/sync/data/models/sync_item_model.dart` (56, 56)
- **المسؤوليات:** `SyncItemModel extends SyncItem` + `fromJson`/`toJson`/`fromEntity`.
- **الطبقة:** data / data — النموذج **يرث** كيان الـ domain.
- **Issue IDs:** DST-022

### `lib/features/sync/data/providers/sync_providers.dart` (148, 148)
- **المسؤوليات:** تركيب 5 providers + **تعريف `MockRemoteEventDispatcher` و `FailClosedRemoteEventDispatcher`** داخل ملف DI + اشتراكات شبكة.
- **الطبقة:** data/DI + أصناف سلوكية.
- **Issue IDs:** DST-018, DST-023

### `lib/features/sync/data/repositories/memory_offline_queue.dart` (145, 145)
- **المسؤوليات:** تنفيذ ثانٍ لـ `OfflineQueue` في الذاكرة.
- **الطبقة:** data / data — **مطلوب فعلاً**: يُستخدم في بيئة `mock` (`sync_providers.dart:64-67`) وفي 4 ملفات اختبار. **ليس تكراراً زائداً.** تباين سلوكي واحد مع SQLite.
- **Issue IDs:** DST-005b

### `lib/features/sync/data/repositories/sqlite_offline_queue.dart` (382, 382)
- **المسؤوليات:** 3 جداول + ترقية v1→v3 + معاملتان ذريتان (`_park`, `releaseToPending`).
- **الطبقة:** data / data — **خلاصة الفحص المطلوب: نظيف معمارياً**. منطق retry/idempotency **ليس** هنا بل في `SyncEngine` + `RetryPolicy` = قرار صحيح. الاستثناء الوحيد: `assert()` كقاعدة عمل.
- **Issue IDs:** DST-005b, DST-024

### `lib/features/sync/data/repositories/sync_repository_impl.dart` (156, 156)
- **المسؤوليات:** **طابور مزامنة ثانٍ بالكامل** على `SharedPreferences` + retry بـ `_maxRetries = 3`.
- **الطبقة:** data / data — ازدواجية منظومة كاملة + سياسة retry متعارضة.
- **Issue IDs:** DST-025

### `lib/features/sync/data/repositories/traccar_remote_event_dispatcher.dart` (322, 322)
- **المسؤوليات:** توجيه 6 أنواع أحداث + سياج الملكية `_authorize` + حل الملكية `_resolveOwnership` + `_mapResult` موحّد.
- **الطبقة:** data / data + security fence — السياج قرار تصميمي مقصود؛ التوجيه بـ `switch` على `String`.
- **Issue IDs:** DST-026

### `lib/features/sync/domain/entities/dispatch_auth.dart` (19, 19)
- **المسؤوليات:** `DispatchAuthContext` value object.
- **الطبقة:** domain — **نظيف تماماً**.
- **Issue IDs:** —

### `lib/features/sync/domain/entities/event_ownership.dart` (109, 109)
- **المسؤوليات:** `OwnerEvidence` + `EventOwnership` + `EventOwnershipResolver.resolve`.
- **الطبقة:** domain — قرار ممتاز (استخراج pure)، لكن `_directDriverId` يفحص أنواعاً بنصوص خام.
- **Issue IDs:** DST-026

### `lib/features/sync/domain/entities/pending_event.dart` (72, 72)
- **المسؤوليات:** `SyncPriority` + `PendingEvent` + `RetryPolicy.calculateNextRetry`.
- **الطبقة:** domain — **`calculateNextRetry` لا يملك أي مسار يُعيد `null`** رغم نوعه `DateTime?`.
- **Issue IDs:** DST-027

### `lib/features/sync/domain/entities/quarantine_record.dart` (41, 41)
- **المسؤوليات:** `StoredEventState` + `OwnershipProof` + `QuarantineRecord`.
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/sync/domain/entities/sync_item.dart` (100, 100)
- **المسؤوليات:** `SyncEventType` + `SyncStatus` + `SyncItem` + `SyncState`.
- **الطبقة:** domain — نظيف (لكن ضمن منظومة مكرَّرة).
- **Issue IDs:** DST-025

### `lib/features/sync/domain/repositories/offline_queue.dart` (49, 49) — **المطلوب مقتبساً**
- **المسؤوليات:** عقد الطابور: `enqueue`، `getReadyEvents`، `updateEvent`، `removeEvent`، `count`، `moveToDeadLetter`، `moveToDeferred`، `moveToQuarantine`، `getDeferred`، `getQuarantined`، `releaseToPending`.
- **الطبقة:** domain / domain.
- **خلاصة الفحص المطلوب:** ❌ **لا تتسرب أنواع sqflite إطلاقاً**. الاقتباس الحرفي:
```dart
// lib/features/sync/domain/repositories/offline_queue.dart:1-6
import '../entities/pending_event.dart';
import '../entities/quarantine_record.dart';

abstract class OfflineQueue {
  /// إضافة حدث للطابور
  Future<void> enqueue(PendingEvent event);
```
  العقد بالكامل مكتوب بنطاقات `PendingEvent`، `StoredEventState`، `OwnershipProof`، `QuarantineRecord`، `String`، `int`، `bool` — **صفر `Database`، صفر `sqflite`**. **الحكم: نظيف.**
- **Issue IDs:** —

### `lib/features/sync/domain/repositories/sync_repository.dart` (25, 25)
- **المسؤوليات:** عقد الطابور الثاني (`SyncItem`).
- **الحالة:** سليم لكنه مكرّر معرفياً مع `OfflineQueue`.
- **Issue IDs:** DST-025

### `lib/features/sync/domain/usecases/sync_engine.dart` (226, 226)
- **المسؤوليات:** `RemoteEventDispatcher` port + `SyncEngine` (submitEvent، submitEventAndReport، releaseEligible، triggerSync، _settle، _completeReport) + **تزامن داخلي بـ Completer**.
- **الطبقة:** domain/usecase.
- **Issue IDs:** DST-027, DST-028

### `lib/features/sync/presentation/providers/sync_engine_provider.dart` (4, 4)
- **المسؤوليات:** جسر توافق (`export '../../data/providers/sync_providers.dart';`).
- **الحالة:** بلا محتوى؛ يعكس أن providers انزلقت إلى data أصلاً.
- **Issue IDs:** DST-018

### `lib/features/sync/presentation/providers/sync_provider.dart` (76, 76)
- **المسؤوليات:** `syncStateProvider` + `SyncNotifier` + `Timer.periodic(1 minute)`.
- **الطبقة:** presentation — Riverpod داخل providers = **صحيح**؛ لا مخالفة.
- **Issue IDs:** DST-025

### `lib/features/sync/presentation/widgets/sync_status_indicator.dart` (46, 46)
- **المسؤوليات:** شارة حالة المزامنة.
- **الطبقة:** presentation — نظيف، لكنه يعرض طابوراً **غير مستخدم في الإنتاج**.
- **Issue IDs:** DST-025

### `lib/features/tracking/data/datasources/live_tracking_data_source.dart` (168, 168)
- **المسؤوليات:** منفذ `LiveTrackingDataSource` + `MockLiveTrackingDataSource` + `ProcessorLiveTrackingDataSource` + **مزوّد Riverpod**.
- **الطبقة:** data/datasource → data + DI.
- **الحالة:** مزوّد داخل `datasources/`؛ Mock في كود الإنتاج؛ منفذ يكشف `EldEvent`/`LocationPoint`؛ `start()` غير awaited.
- **Issue IDs:** DST-023, DST-029, DST-030

### `lib/features/tracking/data/datasources/native_event_channel_client.dart` (164, 164)
- **المسؤوليات:** `NativeLocationQualityValidator` (5 قواعد جودة) + `NativeEventChannelClient` (اشتراك EventChannel + `_parseEvent`).
- **الطبقة:** data — `_parseEvent` صحيح؛ **لكن قواعد الجودة (5 د، 60 د، ترتيب) أعمال**.
- **Issue IDs:** DST-031

### `lib/features/tracking/data/datasources/traccar_data_source.dart` (135, 135)
- **المسؤوليات:** adapter يدمج 4 عملاء Traccar + اشتقاق `ConnectionStatus` + بناء `TrackingEvent`.
- **الطبقة:** data — **نظيف**؛ `_apiClient` معلّم `// ignore: unused_field` و`getLastEvent` يُرجع `null` دائماً (كود ميت Low).
- **Issue IDs:** —

### `lib/features/tracking/data/datasources/tracking_data_source.dart` (26, 26)
- **المسؤوليات:** `TrackingDataSource implements TrackingDataSourcePort` + `start`/`stop`/`getLastEvent`.
- **الطبقة:** data — **نتيجة فحص الـ port**: الـ port حقيقي لكنه ناقص التغطية ⇒ الإضافات خارج العقد.
- **Issue IDs:** DST-032

### `lib/features/tracking/data/datasources/tracking_local_data_source.dart` (69, 69)
- **المسؤوليات:** عقد + Impl على `SharedPreferences` (`'last_location'`, `'tracking_logs'`).
- **الطبقة:** data — `_storage` محقون ومعلّم `// ignore: unused_field` ولا يُستخدم إطلاقاً.
- **Issue IDs:** DST-033

### `lib/features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart` (30, 30)
- **المسؤوليات:** بديل اختبار لـ `TraccarNativeClient`.
- **الحالة:** كود وهمي داخل `lib/data`.
- **Issue IDs:** DST-023

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_api_client.dart` (19, 19)
- **المسؤوليات:** عقد REST لـ Traccar (5 عمليات).
- **الطبقة:** data — `Map<String, dynamic>` نقي داخل data = **مقبول**.
- **Issue IDs:** —

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_api_client_impl.dart` (131, 131)
- **المسؤوليات:** 5 عمليات REST على `ApiClient` + `EldEndpoints`.
- **الحالة:** التفاف الاستثناءات مرتين في الدوال الخمس.
- **Issue IDs:** DST-034

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart` (24, 24)
- **المسؤوليات:** عقد MethodChannel (7 عمليات).
- **الطبقة:** data — نظيف.
- **Issue IDs:** —

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart` (79, 79)
- **المسؤوليات:** 7 نداءات `MethodChannel('com.goldenfeather.eld/traccar')`.
- **الحالة:** ابتلاع `PlatformException` في 3 دوال وإرجاع قيم نجاح زائفة.
- **Issue IDs:** DST-035

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_websocket_client.dart` (21, 21)
- **المسؤوليات:** عقد WebSocket (connect/disconnect/reconnect/3 streams).
- **الطبقة:** data — نظيف.
- **Issue IDs:** —

### `lib/features/tracking/data/datasources/traccar_sdk/traccar_websocket_client_impl.dart` (156, 156)
- **المسؤوليات:** اتصال + backoff أسّي (`1 << attempts` بسقف 60s) + بث.
- **الحالة:** ابتلاع صامت لأخطاء فك التشفير (سطر 87-89).
- **Issue IDs:** DST-035

### `lib/features/tracking/data/models/location_model.dart` (59, 59)
- **المسؤوليات:** `LocationModel extends LocationEntity` + JSON.
- **الطبقة:** data — **وراثة** الكيان + اختراع قيم افتراضية.
- **Issue IDs:** DST-022, DST-036

### `lib/features/tracking/data/providers/tracking_providers.dart` (51, 51)
- **المسؤوليات:** 4 providers.
- **الحالة:** **مزوّدان منفصلان لنفس النوع**؛ `app_initializer` يتجاوز الأول بينما المستودع يستهلك الثاني.
- **Issue IDs:** DST-037

### `lib/features/tracking/data/repositories/tracking_repository_impl.dart` (243, 243)
- **المسؤوليات:** 9 عمليات + **تدفّق صلاحيات كامل** + fallback Geolocator + قراءة config من storage.
- **الطبقة:** data/repository.
- **Issue IDs:** DST-038, DST-039, DST-040

### `lib/features/tracking/data/services/tracking_service.dart` (204, 204)
- **المسؤوليات:** تهيئة config + تطبيع منفذ OsmAnd + 8 عمليات تغليف لـ `TraccarNativeClient` + **تعريف `trackingServiceProvider`**.
- **الطبقة:** data/service + DI.
- **Issue IDs:** DST-029, DST-037, DST-041

### `lib/features/tracking/domain/entities/connection_status.dart` (8, 8)
- **المسؤوليات:** enum خماسي.
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/tracking/domain/entities/location_entity.dart` (141, 141)
- **المسؤوليات:** `LocationEntity` + `TrackingConfigEntity` + `TrackingLogEntity`.
- **الطبقة:** domain — نظيف؛ `LocationEntity.empty()` مصنع пустой (Low).
- **Issue IDs:** —

### `lib/features/tracking/domain/entities/native_location_event.dart` (75, 75)
- **المسؤوليات:** `LocationQualityStatus` + `LocationSource` + `NativeLocationEvent`.
- **الطبقة:** domain — الـ enums هنا لكن منطق استخدامها في data.
- **Issue IDs:** DST-031

### `lib/features/tracking/domain/entities/tracking_event.dart` (98, 98)
- **المسؤوليات:** `TrackingEventSource` + `TrackingEvent` (16 حقلاً).
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/tracking/domain/repositories/tracking_data_source_port.dart` (8, 8)
- **المسؤوليات:** تدفّقان فقط.
- **الطبقة:** domain — **port حقيقي وموضعه صحيح** (domain-owned، نقي، له منفّذ ومستهلك) **لكنه ناقص التغطية**.
- **Issue IDs:** DST-032

### `lib/features/tracking/domain/repositories/tracking_repository.dart` (36, 36)
- **المسؤوليات:** عقد 9 عمليات.
- **الحالة:** سليم؛ لا يغطي دورة التتبع عبر الـ port.
- **Issue IDs:** DST-032

### `lib/features/tracking/domain/usecases/tracking_event_processor.dart` (124, 124)
- **المسؤوليات:** اشتراك في الـ port + توزيع على 3 تدفقات + `_mapToEldEvent` + **`_startMockProcessing`**.
- **الطبقة:** domain/usecase — **يحتوي `Timer.periodic` وبيانات وهمية بإحداثيات مثبتة `24.7136 / 46.6753` و`fromEcm: true`**.
- **Issue IDs:** DST-023, DST-042

### `lib/features/tracking/presentation/providers/tracking_provider.dart` (252, 252)
- **المسؤوليات:** `TrackingState` + `TrackingNotifier` (6 عمليات) + `currentVehicleSpeedProvider`.
- **الطبقة:** presentation — Riverpod في provider = **صحيح**. لكن `Ref` محفوظ داخل الـ notifier + `isDrivingChecker` قابل للكتابة من خارج ⇒ service-locator خفيف؛ ونصوص إنجليزية غير مترجمة تصل الواجهة.
- **Issue IDs:** DST-011, DST-043

### `lib/features/tracking/presentation/providers/tracking_providers.dart` (15, 15)
- **المسؤوليات:** جسر توافق (`export`) + `gpsStatusProvider`.
- **الحالة:** **مزوّد Riverpod في providers presentation** بينما بقية مزوّدات التتبع في data ⇒ ازدواج طبقتين.
- **Issue IDs:** DST-029

### `lib/features/vehicle/data/providers/vehicle_repository_providers.dart` (23, 23)
- **المسؤوليات:** `vehicleBackendProviderAlias` (تمرير صوري بلا قيمة) + `vehicleRepositoryProvider`.
- **الطبقة:** data/DI — سليم (Low في Alias).
- **Issue IDs:** —

### `lib/features/vehicle/data/repositories/vehicle_repository_impl.dart` (81, 81)
- **المسؤوليات:** 3 عمليات + `_readList` + `_message`.
- **الطبقة:** data — **نظيف**؛ `catch (_)` محوَّل إلى `Failure` مقبول.
- **Issue IDs:** DST-047

### `lib/features/vehicle/domain/entities/vehicle.dart` (68, 68)
- **المسؤوليات:** كيان `Vehicle` (14 حقلاً) + `displayName` + `shortDisplayName`.
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/vehicle/domain/repositories/vehicle_repository.dart` (15, 15)
- **المسؤوليات:** عقد 3 عمليات.
- **الطبقة:** domain — نظيف.
- **Issue IDs:** —

### `lib/features/vehicle/domain/vehicle_selection.dart` (153, 153) — **المطلوب فحصه**
- **المسؤوليات الفعلية (3 مختلطة):** (1) قواعد أعمال صرفة: `listedVehicleIsOperable`، `refuseVehicleOperate`، `readOperableUniqueId`. (2) **قراءة جسم الخادم**: `parseVehicleList`، `readVehicle`، `_vehicleRows`، `_asMap`، `_text`، `_bool`. (3) **خريطة أخطاء HTTP**: `vehicleOperateFailure` (400→rejected، 403→unauthorized، 409→in_use…).
- **الطبقة:** domain / **مختلط**.
- **الحالة:** لا استيراد Flutter/Dio/Riverpod (✅)، لكن **قراءة JSON وربط HTTP في الـ domain**. والأسوأ: القواعد (1) **شابة** — `refuseVehicleOperate` و `VehicleOperateRefusal` لا يُستدعيان من أي مكان في `lib/`؛ `vehicle_provider.dart` يعيد تنفيذها يدوياً بدلالات مختلفة.
- **Issue IDs:** DST-044, DST-045

### `lib/features/vehicle/presentation/pages/select_vehicle_page.dart` (299, 299)
- **المسؤوليات:** Scaffold + بحث + حوار غير مُسند + تنسيق النجاح إلى dashboard و localStorage و go_router.
- **الطبقة:** presentation + side-effects عبر features.
- **Issue IDs:** DST-019, DST-046

### `lib/features/vehicle/presentation/providers/vehicle_provider.dart` (254, 254)
- **المسؤوليات:** `VehicleState` + `VehicleNotifier` + سياج session (bindOwner/reset) + تسلسل `_loadSeq` + `selectVehicle`.
- **الطبقة:** presentation + قاعدة عمل مكرَّرة.
- **Issue IDs:** DST-045, DST-047

### `lib/features/vehicle/presentation/widget/vehicle_card.dart` (124, 124)
- **المسؤوليات:** صف مركبة + شارة + دالة عامة `vehicleErrorText`.
- **الطبقة:** presentation — نظيف (تنظيم الملف فقط).
- **Issue IDs:** —

---

## B. Detailed issues

--------------------------------------------------
### ISSUE DST-001: اختراع `deviceId` المركبة من regex داخل Widget
- **Severity:** Critical
- **Category:** Business Logic in Presentation / Data Integrity
- **Location:** `lib/features/dvir/presentation/pages/dvir_form_page.dart:463-476`
- **Evidence:**
```dart
    if (resolvedDeviceId == null) {
      final directInt = int.tryParse(reportVehicleId);
      if (directInt != null && directInt > 0) {
        resolvedDeviceId = directInt;
      } else {
        final match = RegExp(r'\d+').firstMatch(reportVehicleId);
        if (match != null) {
          final digits = int.tryParse(match.group(0)!);
          if (digits != null && digits > 0) {
            resolvedDeviceId = digits;
          }
        }
      }
    }
```
- **Current behavior:** إذا لم يُعثر على `deviceId` من `dashboard` أو `selectedVehicle` أو قائمة المركبات، تستخرج الـ Widget **أول سلسلة أرقام من نص اسم/معرّف المركبة** وتستخدمها كـ Traccar `deviceId` في جسم DVIR الرسمي.
- **Why problematic:** (أ) مخالفة مباشرة للمبدأ المعلن في **نفس الـ feature**: `dvir_mappers.dart:119-121` يقول «الخادم يرفض إنشاء الفحص بلا معرف جهاز المركبة (deviceId) — لا جسم ناقص ولا اختراع قيمة». (ب) أي رقم في الاسم (سنة الصنع، رقم اللوحة) يصبح **معرّف جهاز قانوني مزيّف** في سجل CMV. (ج) قاعدة سلامة بيانات في وثيقة رسمية، غير قابلة للاختبار ولا للوحدة.
- **Violated principle:** SRP (Widget = عرض)، Domain Model Integrity، «لا قيم مخترعة».
- **Current owner:** `_DvirFormPageState._handleSubmit`
- **Correct owner:** `DvirRepositoryImpl` أو use-case في `dvir/domain/usecases/`
- **Consequences:** DVIR official record قد يشير إلى جهاز غير موجود؛ احتمال رفض أو قبول خاطئ لـ `POST /eld/dvir`؛ قاعدة غير قابلة للاختبار.
- **Recommended correction:** حذف فرع الـ regex كاملاً؛ الاكتفاء بـ `dashboard.deviceId` / `selectedVehicle.deviceId` / `vehicles.firstWhere((v) => v.deviceId != null && v.deviceId! > 0)`؛ عند الغياب → `Left(ServerFailure('deviceId required'))`. نقل القاعدة إلى domain.
- **Related files:** `dvir_mappers.dart:119-125`, `dvir_repository_impl.dart:245-263`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-002: كاش `static` عام في مستودع التفتيش — تسريب بين جلسات السائق
- **Severity:** Critical
- **Category:** Global Mutable State / Session Isolation
- **Location:** `lib/features/inspection/data/repositories/inspection_repository_impl.dart:28-32`
- **Evidence:**
```dart
  /// ذاكرة مؤقتة تضمن استمرار عمل التفتيش وعرض السجلات حتى عند انقطاع الاتصال
  static DotInspectionScreen? _cachedScreen;
  static List<DotInspectionCycleDay> _cachedCycle = [];
  static final Map<String, DotInspectionLog> _cachedLogs = {};
  static InformationPacketView? _cachedPacket;
```
- **Current behavior:** أربعة كاشات على مستوى **العملية كلها** (process-wide)، تُخدم منها القراءات offline:
```dart
// inspection_repository_impl.dart:91-92
      if (_cachedLogs.containsKey(key)) return Right(_cachedLogs[key]!);
      if (_cachedLogs.isNotEmpty) return Right(_cachedLogs.values.first);
```
- **Why problematic:** (أ) `static` = حالة مشتركة بين كل نسخ المستودع، ومع `StateNotifierProvider` غير الـ autoDispose تبقى حيّة طوال عمر التطبيق. (ب) **لا يوجد أي مسار إبطال** — بحث شامل عن `_cached` / `clearCache` / `resetForTests` في `lib/features/inspection` أثبت أنه لا يوجد أي تعيين لـ `null` ولا `clear()`. (ج) عند تسجيل خروج سائق A ودخول سائق B على **نفس جهاز ELD**، سيقرأ B سجلات تفتيش A offline بما فيها `driverId` و`carrierName` و`vin`.
- **Violated principle:** SRP، Encapsulation، Session Isolation (مبدأ صريح في `vehicle_provider.dart:105-107` «ملكية الجلسة»).
- **Current owner:** `InspectionRepositoryImpl` static fields
- **Correct owner:** cache طبقي **مفهرس بـ driverId ومُبطل عند تغيّر الجلسة**، أو `LocalCache` في data بواجهة `invalidateFor(driverId)`.
- **Consequences:** Privacy / ELD violation؛ `getLogs` قد يرجع سجل سائق آخر كـ «سجل اليوم الحالي»؛ لا يمكن اختبار العزل.
- **Recommended correction:** تحويل `static` → instance fields داخل provider بـ `autoDispose`، أو إضافة `int? _cacheOwnerDriverId` يمنع القراءة إذا `cachedOwner != currentOwner`؛ واستدعاء `invalidate()` من `ref.listen(authStateProvider)`.
- **Related files:** `inspection_provider.dart:260-271`, `vehicle_provider.dart:73-99` (نموذج السياج الصحيح المطلوب تكراره)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-003: قاعدة عمل §396.13 داخل `State` في طبقة presentation
- **Severity:** High
- **Category:** Business Logic in Presentation
- **Location:** `lib/features/dvir/presentation/providers/dvir_provider.dart:45-57`
- **Evidence:**
```dart
  DvirReport? previousToReview(String vehicleId) {
    if (previousLookupDone && !previousLookupFailed && previousVehicleId == vehicleId) {
      final p = previousDvir;
      return (p != null && p.nextDriverReviewed != true) ? p : null;
    }
    return reports
        .where((r) => r.vehicleId == vehicleId)
        .cast<DvirReport?>()
        .firstWhere(
          (r) => r!.nextDriverReviewed != true,
          orElse: () => null,
        );
  }
```
- **Current behavior:** **قاعدة قانونية** (من هو التقرير المعلَّق على مراجعة §396.13، وأولوية مصدر `pre-trip` على القائمة) مُنفَّذة كطريقة على class الحالة داخل مجلد providers.
- **Why problematic:** (أ) لا يمكن اختبارها إلا عبر Riverpod container. (ب) حالتها (`previousLookupDone` / `previousLookupFailed` / `previousVehicleId`) جزء من `DvirState` فتُعاد تقييمها في كل `copyWith`. (ج) القاعدة بلا use-case خاص بها.
- **Violated principle:** Domain Model، SRP.
- **Current owner:** `DvirState` (presentation)
- **Correct owner:** use-case نقي في `dvir/domain/usecases/` يعيد `DvirReport?` من `(DvirReport? fromEndpoint, List<DvirReport> list, LookupOutcome)`.
- **Consequences:** لا ضمان اتساق بين الواجهة والتطبيقات الأخرى (مثل reporting) لنفس القاعدة.
- **Recommended correction:** استخراج `previousToReview` إلى دالة pure top-level في domain، وتبقى `DvirState` حاوية بيانات فقط.
- **Related files:** `dvir_form_page.dart:485-487` (المستهلك الوحيد)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-004: المستودع يؤدّي DTO→entity mapping يدوياً رغم وجود مجلد `mappers/`
- **Severity:** Medium
- **Category:** Layer Responsibility (SRP)
- **Location:** `lib/features/dvir/data/repositories/dvir_repository_impl.dart:327-387`
- **Evidence:**
```dart
  DvirReport _mapDtoToEntity(DvirDto dto) {
    return DvirReport(
      id: dto.id.toString(),
      ...
      selectedDefects: [
        for (final defect in dto.defects)
          if ((defect.itemCode ?? '').trim().isNotEmpty || (defect.itemName ?? '').trim().isNotEmpty)
            DvirDefectSelection(
              item: DvirCatalogItem(
                code: defect.itemCode?.trim() ?? 'GENERIC',
```
- **Current behavior:** 61 سطراً من mapping + 3 دوال تحليل مساندة (`_parseDate:313`، `_parseInspectionType:375`، `_parseVehicleCondition:380`) **داخل المستودع**، بينما `data/mappers/dvir_mappers.dart` (208 سطر) و `dvir_defect_mappers.dart` (91 سطر)exists لهذا الغرض.
- **Why problematic:** انقسام **غير متسق**: قراءة الكتالوج والعيوب في mappers، وقراءة **التقرير الرئيسي** في المستودع؛ فالمستودع يجمع تنسيق الشبكة + mapping معاً.
- **Violated principle:** SRP، تماسك حدود الطبقة.
- **Current owner:** `DvirRepositoryImpl`
- **Correct owner:** `data/mappers/dvir_mappers.dart` كـ `DvirReport mapDtoToEntity(DvirDto)`
- **Consequences:** صعوبة اختبار mapping بمعزل؛ تكرار نمط السلسلة الهرمية الحرفية في كل mapping جديد.
- **Recommended correction:** نقل `_mapDtoToEntity` والـ 3 دوال إلى `data/mappers/dvir_mappers.dart`؛ يبقى المستودع تنسيقاً فقط.
- **Related files:** `data/mappers/dvir_mappers.dart`, `data/mappers/dvir_defect_mappers.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-005: هندسة مكرّرة للـ create body داخل نفس مسار النداء
- **Severity:** High
- **Category:** Duplicated Orchestration / Layer Leak
- **Location:** `lib/features/dvir/data/repositories/dvir_repository_impl.dart:229-264`
- **Evidence:**
```dart
  Map<String, dynamic>? _buildCreateBody(
    DvirReport report, {
    required int driverId,
    required DvirConditionStatus status,
  }) {
    // Reconcile status: if the report has defects, status cannot be satisfactory.
    final effectiveStatus =
        (report.hasDefects || report.selectedDefects.isNotEmpty) &&
                status == DvirConditionStatus.satisfactory
            ? DvirConditionStatus.hasDefects
            : status;
    ...
    return buildDvirCreateBody(
      ...
      status: effectiveStatus.wire,
```
- **Current behavior:** المستودع يحسب `effectiveStatus` ثم يمرره إلى `buildDvirCreateBody` الذي **يعيد تطبيق نفس القاعدة**:
```dart
// dvir_mappers.dart:137-141
  var wireStatus = status.trim();
  if (defects.isNotEmpty &&
      wireStatus == DvirConditionStatus.satisfactory.wire) {
    wireStatus = DvirConditionStatus.hasDefects.wire;
  }
```
- **Why problematic:** نفس القاعدة (DVIR-09) مطبَّقة **مرتين في نفس مسار التنفيذ**، وقبلهما مرة ثالثة في الـ Widget (انظر DST-006) ⇒ ثلاث نقاط فشل لسلامة قانونية واحدة.
- **Violated principle:** DRY، Single Source of Truth.
- **Current owner:** المستودع **و** الـ mapper **و** الـ Widget.
- **Correct owner:** `dvir/domain/usecases/reconcile_condition_status.dart` أو method على `DvirReport` في `dvir_report.dart`.
- **Consequences:** تعديل القاعدة في مكان واحد يجعل النسخة المرسلة/anتحقق المحلي يتباعدان.
- **Recommended correction:** إضافة method على `DvirReport` في domain؛ حذف التكرارين.
- **Related files:** `dvir_mappers.dart:135-141`, `dvir_form_page.dart:202-206`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-005b: تباين سلوكي بين `SQLiteOfflineQueue` و `MemoryOfflineQueue` في `releaseToPending`
- **Severity:** Medium
- **Category:** Contract Divergence / Test Fidelity
- **Location:** `lib/features/sync/data/repositories/sqlite_offline_queue.dart:370` مقابل `lib/features/sync/data/repositories/memory_offline_queue.dart:135-139`
- **Evidence:**
```dart
// sqlite_offline_queue.dart:362-372
      await txn.insert(
        _tableName,
        {
          'id': record.event.id,
          'type': record.event.type,
          'payload': jsonEncode(record.event.payload),
          'createdAt': record.event.createdAt.millisecondsSinceEpoch,
          'priority': record.event.priority.index,
          'retryCount': record.event.retryCount,
          'nextRetryAt': null,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
```
```dart
// memory_offline_queue.dart:135-139
  Future<void> releaseToPending(String eventId) async {
    final record = _parked.remove(eventId);
    if (record == null) return;
    await enqueue(record.event);
  }
```
- **Current behavior:** SQLite **يبطِل** `nextRetryAt` (إعادة محاولة فورية بعد الإفراج)؛ Memory **يحتفظ** بالقيمة الأصلية (تأخير حتى موعد backoff القديم).
- **Why problematic:** عقد واحد (`offline_queue.dart:46-48`)، تنفيذان بسلوكين مختلفين. الاختبارات المبنية على `MemoryOfflineQueue` **لا تختبر سلوك الإنتاج** في بند حسّاس (سياج الإفراج).
- **Violated principle:** Liskov Substitution، Test Fidelity.
- **Current owner:** تنفيذان مستقلان بلا عقد سلوكي موثّق.
- **Correct owner:** قاعدة صرفة مشتركة تُستدعى من الاثنين، مثل `PendingEvent rescheduledForImmediateRetry()`.
- **Consequences:** حدث مؤجَّل يُفرَج في الإنتاج يُرسل فوراً، وفي الاختبار ينتظر.
- **Recommended correction:** استخراج `PendingEvent immediateRetry()` في `sync/domain/entities/pending_event.dart` واستدعاؤها في الاثنين.
- **Related files:** `sync/domain/entities/pending_event.dart`, `sync/domain/repositories/offline_queue.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-006: قاعدة DVIR-09 مثبتة ثلاث مرات (widget + data + data)
- **Severity:** High
- **Category:** Duplicated Business Rule
- **Location:** `lib/features/dvir/presentation/pages/dvir_form_page.dart:202-206` (ومكرّر في `:231-235` و `:259-263`)
- **Evidence:**
```dart
    setState(() {
      _selectedDefects = [...picked, ...trailerDefects];
      _vehicleDefectsController.text =
          picked.map((d) => d.item.label(context.loc)).join(', ');
      if (_selectedDefects.isNotEmpty) {
        _selectedStatus = DvirConditionStatus.hasDefects;
      } else if (_trailerDefectsController.text.trim().isEmpty) {
        _selectedStatus = DvirConditionStatus.satisfactory;
      }
    });
```
- **Current behavior:** Widget يعيد اشتقاق الحالة القانونية من الاختيارات — ثلاث مرات في نفس الملف.
- **Why problematic:** قاعدة **قانونية** (DVIR-09، SRS 7.1/7.6) لها **خمس نسخ** في نفس الـ feature (Widget×3 + Repository + Mapper). تغيير معيار «العيوب غير المعالجة» في مكان واحد يجعل الأربع الأخرى غير متسقة.
- **Violated principle:** DRY، Single Source of Truth، Business Logic in Presentation.
- **Current owner:** Widget ×3 + Repository + Mapper.
- **Correct owner:** دالة في `dvir/domain/` مثل `resolveConditionStatus({required DvirConditionStatus chosen, required bool hasAnyDefect})`.
- **Consequences:** DVIR قد يُرسل بحالة `Satisfactory` مع عيوب مسجلة لو أُزيل فرع من Widget فقط.
- **Recommended correction:** استخراج الدالة إلى domain واستدعاؤها من المواضع الخمسة.
- **Related files:** `dvir_repository_impl.dart:235-239`, `dvir_mappers.dart:137-141`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-007: اختراع قيم fallback داخل mapper
- **Severity:** Medium
- **Category:** Data Integrity / Hardcoded Business Value
- **Location:** `lib/features/dvir/data/repositories/dvir_repository_impl.dart:355-361`
- **Evidence:**
```dart
            DvirDefectSelection(
              item: DvirCatalogItem(
                code: defect.itemCode?.trim() ?? 'GENERIC',
                name: defect.itemName ?? defect.itemCode ?? 'Unknown defect',
                category: defect.category ?? '',
                critical: defect.safetyAffecting || defect.outOfService,
              ),
```
- **Current behavior:** غياب `itemCode` يُملأ بـ `'GENERIC'` وغياب الاسم بـ `'Unknown defect'`.
- **Why problematic:** يخالف صراحةً سياسة الـ feature المعلنة في `dvir/domain/entities/dvir_defect.dart:1-2` («ما لا يرسله الخادم يبقى null — لا قيم مخترعة ولا افتراضات») وفي `data/mappers/dvir_defect_mappers.dart:3-4`. النتيجة: **كتالوج يحتوي item وهمي** يُرسل كـ defect حقيقي.
- **Violated principle:** «لا قيم مخترعة» (مبدأ المشروع المعلَن).
- **Current owner:** `DvirRepositoryImpl`
- **Correct owner:** `data/mappers/` مع قرار صريح: **تجاهل** الصف بدل اختراع code.
- **Consequences:** DVIR official record يحتوي معرّف عيب غير موجود في كتالوج §396.11.
- **Recommended correction:** تصفية الصفوف بـ `itemCode != null` في mapper، أو تمثيل `code` كـ nullable على الكيان.
- **Related files:** `dvir/domain/entities/dvir_defect.dart:1-2`, `data/mappers/dvir_defect_mappers.dart:3-4`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-008: ابتلاع الاستثناءات بلا أثر
- **Severity:** Medium
- **Category:** Swallowed Exception
- **Location:** `lib/features/dvir/presentation/widgets/active_defects_section.dart:123-126`
- **Evidence:**
```dart
    setState(() {
      _refreshing = false;
      result.fold((_) {}, (fresh) => _defect = fresh);
    });
```
- **Current behavior:** فشل `getDefectDetails` **يُسقط بصمت** — لا سجل ولا واجهة.
- **Why problematic:** الملف نفسه يَعِد بـ «فشل التحديث يُبقي المعروض» (سطر 98)، وهو صحيح وظيفياً، لكن **الفشل غير مرئي إطلاقاً** ⇒ لا تشخيص ميداني لأعطال «التفاصيل لا تتحدّث».
- **Violated principle:** Error Handling / Observability.
- **Current owner:** Widget
- **Correct owner:** Widget مع تسجيل، أو `dvirProvider` مع حالة خطأ صريحة.
- **Consequences:** لا يمكن تشخيص العطل ميدانياً.
- **Recommended correction:** إضافة `AppLogger.warning` على فرع `Left`، واعتماد `if (result case Right(:final fresh))` لزيادة الوضوح.
- **Related files:** `dvir/data/providers/dvir_repository_providers.dart:1-17`, `sync/data/datasources/sync_local_data_source.dart:25-30`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-009: رقمان مختلفان لنفس التحويل الفيزيائي داخل نفس الـ feature
- **Severity:** Low
- **Category:** Hardcoded Value (Business/Environment)
- **Location:** `lib/features/inspection/data/services/fmcsa_eld_output_generator.dart:118` و `:144` مقابل `lib/features/inspection/presentation/widgets/inspection_log_header_table.dart:96-97`
- **Evidence:**
```dart
// fmcsa_eld_output_generator.dart:118
      '3,$seq,1,1,1,$fileDate,000000,${(startOdo * 0.621371).toStringAsFixed(1)},...
// fmcsa_eld_output_generator.dart:144
        final miles = (event.odometer * 0.621371).toStringAsFixed(1);
// inspection_log_header_table.dart:96-97
  static const double _kmPerMile = 1.609344;
  static String _mi(double km) => (km / _kmPerMile).toStringAsFixed(0);
```
- **Current behavior:** تحويل km→mile بـ **0.621371** في مولّد الملف (data) وبـ **1.609344** في جدول العرض (presentation) — داخل نفس الميزة.
- **Why problematic:** (أ) **قيمة أعمال** (وحدات ملف 49 CFR A.3.1.1) في data بلا مرجع. (ب) **رقمان مختلفان** لنفس التحويل ⇒ انحراف بين الملف الرسمي وما يعرضه الضابط على الشاشة.
- **Violated principle:** DRY، Business Constants Placement.
- **Current owner:** ملفان في طبقتين.
- **Correct owner:** `core/constants/fmcsa_constants.dart` (موجود ويستخدمه `tracking_orchestrator.dart:40-47`).
- **Consequences:** ملف CSV وورقة RODS يعرضان مسافات مختلفة لنفس البيانات.
- **Recommended correction:** ثابت واحد `kmToMiles` في `FmcsaConstants`.
- **Related files:** `lib/core/constants/fmcsa_constants.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-010: ~25 getter اشتقاقية داخل Widget جدول
- **Severity:** Medium
- **Category:** Business Logic in Presentation
- **Location:** `lib/features/inspection/presentation/widgets/inspection_log_header_table.dart:33-127`
- **Evidence:**
```dart
  List<String> get _diagList => {
        ...?day?.activeDataDiagnostics,
        ...?log?.activeDataDiagnostics,
      }.toList();
  List<String> get _malfList => {
        ...?day?.activeDeviceMalfunctions,
        ...?log?.activeDeviceMalfunctions,
      }.toList();
  ...
  // 395.8(k)/8.3 — an indicator that is ON must say which code(s) are active.
  String get _diagCodes => _diagList.join(', ');
  String get _malfCodes => _malfList.join(', ');
```
- **Current behavior:** Widget يحوي `_pick` (سلسلة أفضلية log→day→screen)، `_num` (اختيار القيمة غير الصفرية)، `_odometer` (تركيب نطاق)، `_diagList`/`_malfList` (اتحاد)، `_carrier` (تركيب name + DOT#)، `_unidentified` (دمج منطقين).
- **Why problematic:** (أ) قواعد 49 CFR §395.8(k) و SRS 8.3 **مطبَّقة في Widget**. (ب) غير قابلة للاختبار إلا بـ widget test. (ج) أي مسار آخر يحتاج ورقة RODS (طباعة/تصدير) سيكرّر القاعدة يدوياً.
- **Violated principle:** Domain Model، SRP.
- **Current owner:** Widget.
- **Correct owner:** view-model نقي في `inspection/domain/` مثل `RodsRow.from(log, day, screen)`.
- **Consequences:** تكرار القاعدة عند أي مخرج آخر.
- **Recommended correction:** استخراج view-model إلى domain؛ يبقى Widget عارضاً فقط.
- **Related files:** `inspection_active_view.dart:83-90`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-011: نصوص مستخدم مثبتة في data/presentation خارج نظام l10n
- **Severity:** Medium
- **Category:** Hardcoded Presentation Values in Wrong Layer
- **Location:** `lib/features/tracking/data/repositories/tracking_repository_impl.dart:66-79`، `lib/features/dvir/presentation/widgets/dvir_form_sections.dart:165-171`، `lib/features/tracking/presentation/providers/tracking_provider.dart:136`
- **Evidence:**
```dart
// tracking_repository_impl.dart:65-69  (data layer)
      if (!locationStatus.isGranted) {
        return const Left(PermissionFailure(
          message: 'صلاحية الموقع في الخلفية مطلوبة',
        ));
      }
```
```dart
// dvir_form_sections.dart:164-171
          if (parsed == null || parsed.isNaN || parsed < 0) {
            return loc.localeName == 'ar'
                ? 'قيمة العداد غير صالحة'
                : (loc.localeName == 'es'
                    ? 'Lectura de odómetro no válida'
                    : 'Invalid odometer reading');
          }
```
```dart
// tracking_provider.dart:135-138
        state = state.copyWith(
          errorMessage: 'No GPS signal received from device',
          errorType: TrackingErrorType.technical,
        );
```
- **Current behavior:** ثلاث فئات: (1) **عربية داخل data layer** تصل للواجهة كما هي؛ (2) **ثلاثية اللغة مكتوبة يدوياً** في Widget بدل `.arb`؛ (3) **إنجليزية صريحة** في presentation providers.
- **Why problematic:** (أ) `failure.message` من data **يُعرض مباشرة** في `tracking_provider.dart:118` (`errorMessage: failure.message`) ⇒ **طبقة data تقرر نصاً مرئياً**. (ب) التفرع اللغوي اليدوي **ينمو** مع كل لغة جديدة (المشروع يدعم ar/en/es).
- **Violated principle:** i18n Centralization، Layer Separation.
- **Current owner:** data layer و Widget.
- **Correct owner:** `core/error/user_facing_message.dart` + `l10n/*.arb` بمفتاح بدل نص.
- **Consequences:** مستخدم غير عربي يرى نصاً عربياً على شاشة رفض الأذونات.
- **Recommended correction:** `PermissionFailure(l10nKey: 'tracking_permission_background_required')`؛ ويمرّر `tracking_provider` عبر `anyErrorUserMessage(failure, loc:)` كالموجود في `inspection_provider.dart:159-161`.
- **Related files:** `inspection_provider.dart:159-161`, `lib/core/error/user_facing_message.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-012: قيمة حرفية مشتركة ('No Vehicle' / 'None') تُستهلك في ثلاث طبقات
- **Severity:** Medium
- **Category:** Magic Value Across Layers
- **Location:** التعريف `lib/features/dvir/domain/dvir_vehicle.dart:3` → الاستهلاك `dvir_repository_impl.dart:47`، `dvir_mappers.dart:123`، `dvir_form_page.dart:531-535`
- **Evidence:**
```dart
// dvir_form_page.dart:531-535  (presentation layer)
      trailerId:
          (dashboard.trailerId == 'None' ||
              dashboard.trailerId?.trim().isEmpty == true)
          ? null
          : dashboard.trailerId,
```
- **Current behavior:** الـ **domain** يوفّر `noVehicleSentinel` و`isUnassignedVehicleId()` صراحةً لتفادي هذا النمط، لكن الـ Widget **لا يستخدم الدالة** ويطابق `'None'` حرفياً، بينما data يستخدم `'No Vehicle'`.
- **Why problematic:** (أ) الـ domain يوفّر واجهة صرفة بالضبط لتفادي هذا، والـ Widget يتجاهلها. (ب) حارس المُقطورة `'None'` معرَّف في **ثلاث أماكن** بلا مصدر واحد.
- **Violated principle:** DRY، Domain Model Adoption.
- **Current owner:** Widget + Repository + Mapper.
- **Correct owner:** `dvir/domain/dvir_vehicle.dart` — دالة `normalizeTrailerId(String?)` بجانب `isUnassignedVehicleId`.
- **Consequences:** تغيير نص Sentinel من لوحة القيادة يكسر DVIR بهدوء.
- **Recommended correction:** إضافة `String? normalizeTrailerId(String? raw)` في domain واستدعاؤها من الثلاثة.
- **Related files:** `dvir_repository_impl.dart:47`, `dvir_mappers.dart:122-123`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-013: حقول wire خام في كيان domain رغم وجود enums مخصصة
- **Severity:** Medium
- **Category:** Primitive Obsession / Model Inconsistency
- **Location:** `lib/features/dvir/domain/entities/dvir_defect.dart:13-14`
- **Evidence:**
```dart
  final String? severity;
  final String? stage;
```
- **Current behavior:** `DvirDefect` يحمل `severity` و`stage` كنصوص، بينما `DvirReport.selectedDefects` يحمل نفس المفاهيم كـ `DefectSeverity`/`DefectLifecycleStage` (انظر `dvir_catalog.dart:29-44`). التحويل يحدث في `dvir_defect_mappers.dart:21-22` بـ `_asString(json['severity'])` **بلا تحويل إلى enum**.
- **Why problematic:** نموذج واحد في نفس الـ feature يمثّل نفس المفهوم بطريقتين؛ ينتج بالتالي تصنيفاً بأسلوب string في الـ presentation.
- **Violated principle:** Primitive Obsession، تماسك Domain Model.
- **Current owner:** `DvirDefect`
- **Correct owner:** `DvirDefect` باستخدام `DefectSeverity?` و `DefectLifecycleStage`.
- **Consequences:** التصنيف بـ string في `dvir_list_page.dart:146` و `active_defects_section.dart:67-70`.
- **Recommended correction:** تحويل الحقلين إلى enums مع `?? null` في mapper.
- **Related files:** `dvir/data/mappers/dvir_defect_mappers.dart:21-22`, `dvir/domain/defect_enums.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-014: تصنيف حالة/شدة العيب بمقارنة نصوص داخل Widget
- **Severity:** Medium
- **Category:** Business Logic in Presentation / Duplicated Rule
- **Location:** `lib/features/dvir/presentation/pages/dvir_list_page.dart:145-147` و `lib/features/dvir/presentation/widgets/active_defects_section.dart:66-71`
- **Evidence:**
```dart
// dvir_list_page.dart:145-147
    final openCount = activeDefects != null
        ? activeDefects.where((d) => d.stage?.toUpperCase() == 'OPEN').length
        : summary.openDefects;
```
```dart
// active_defects_section.dart:66-71
    final text = (severity ?? '').toUpperCase();
    final color = text.contains('HIGH')
        ? AppColors.dangerRed
        : text.contains('MED')
            ? AppColors.warningYellow
            : AppColors.successGreen;
```
- **Current behavior:** (أ) Widget يقارن `'OPEN'` نصياً بينما `DefectLifecycleStage.open.wire == 'OPEN'` موجود في domain. (ب) Widget يصنّف الشدة بـ **substring match** (`contains('MED')`) بينما `DefectSeverity.fromWire` موجود ويستخدم `==`.
- **Why problematic:** قيمة جديدة مثل `'MEDIUM_CRITICAL'` أو `'off_duty'` تُصنَّف خطأً؛ والمطابقة بالسلسلة الفرعية هشّة بطبيعتها.
- **Violated principle:** DRY، Type Safety، Business Logic in Presentation.
- **Current owner:** Widget ×2
- **Correct owner:** `DefectSeverity.fromWire` / `DefectLifecycleStage.fromWire` (موجودان في `defect_enums.dart:11-16` و `30-36`).
- **Consequences:** تلوين خاطئ لشدة العيب — مؤشر سلامة ظاهر للسائق.
- **Recommended correction:** في mapper: `severity: DefectSeverity.fromWire(json['severity'])`؛ ثم `switch` على الـ enum في الـ Widget.
- **Related files:** `dvir/domain/defect_enums.dart:11-36`, `dvir/data/mappers/dvir_defect_mappers.dart:21-22`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-015: قاعدة PIN ميتة + ثابت عمل `days: 8` في presentation
- **Severity:** Low
- **Category:** Dead Code / Business Constants in Presentation
- **Location:** `lib/features/inspection/presentation/providers/inspection_provider.dart:19-24` و `:226`
- **Evidence:**
```dart
/// قاعدة رمز التفتيش (SRS 7.5): أربعة أرقام بالضبط — واحدة للحوارين
/// (الإنشاء والخروج)، نقية وقابلة للاختبار بلا widget.
bool isValidInspectionPin(String pin) {
  final value = pin.trim();
  return value.length == 4 && int.tryParse(value) != null;
}
```
```dart
// inspection_provider.dart:226
    final cycleResult = await _repository.getCycle(driverId: driver, days: 8);
```
- **Current behavior:** (أ) دالة قاعدة أعمال **غير مستخدمة** — بحث شامل على `lib/` لم يجد أي استدعاء لـ `isValidInspectionPin`. (ب) ثابت `days: 8` (نافذة 8 أيام، 49 CFR §395.8(d)) مكرَّر في `inspection_provider.dart:226` و `dot_inspection_providers.dart:57`.
- **Why problematic:** قاعدة ميتة توحي بأنها مُطبَّقة؛ وتعديل نافذة الـ days يستلزم تعديل موضعين في presentation.
- **Violated principle:** Dead Code، Business Constants Placement.
- **Current owner:** ملف providers.
- **Correct owner:** `inspection/domain/dot_inspection_rules.dart` مع `kDotCycleDays = 8`.
- **Consequences:** مطوّر قد يضيف تحقق PIN في presentation معتقداً أنه مُفعّل.
- **Recommended correction:** نقل القاعدة والثابت إلى domain؛ إما تفعيل القاعدة أو حذفها.
- **Related files:** `dot_inspection_providers.dart:57`, `inspection_start_view.dart:53-61`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-016: بروتوكول نصي `OFFLINE_GENERATED:` بين data و presentation
- **Severity:** High
- **Category:** Layer Coupling via String Protocol
- **Location:** `lib/features/inspection/data/repositories/inspection_repository_impl.dart:169-172` → `lib/features/inspection/presentation/pages/send_logs_page.dart:267-268`
- **Evidence:**
```dart
// inspection_repository_impl.dart:169-172
        return Right(TransferOutcome(
          accepted: true,
          text: 'OFFLINE_GENERATED:$filePath',
        ));
```
```dart
// send_logs_page.dart:267-268
    final isOffline = message != null && message.startsWith('OFFLINE_GENERATED:');
    final localPath = isOffline ? message.substring('OFFLINE_GENERATED:'.length) : null;
```
- **Current behavior:** المستودع **يخزّن مسار ملف وسماً داخل حقل نص عرض**، والـ Widget **يفكّ الترميز** بـ `startsWith`/`substring` ثم يقرر UX (إظهار زر المشاركة).
- **Why problematic:** (أ) **Broken type smell مؤكَّد**: `TransferOutcome.text` مقصود للعرض وحُمِل عليه مسار آلة. (ب) الـ Widget يستنتج حالة النظام من نص. (ج) لا يمكن إضافة outcome ثالث دون تعديل المتصل. (د) مسار الملف ينتقل من data إلى Widget عبر نص.
- **Violated principle:** Information Hiding، Layer Separation، Primitive Obsession.
- **Current owner:** اتفاق ضمني صامت بين مستودع و Widget.
- **Correct owner:** كيان domain صريح، مثل `sealed class TransferOutcome { OnlineAccepted(text) | OfflineGenerated(filePath) | Rejected(reason) }`.
- **Consequences:** تغيير صيغة الوسم يكسر الشاشة بصمت؛ صفر تغطية اختبار على النوع.
- **Recommended correction:** تحويل `TransferOutcome` إلى sealed class في `inspection_transfer.dart`؛ يحذف تحليل النص من الـ Widget.
- **Related files:** `inspection/domain/inspection_transfer.dart:23-28`, `inspection/data/services/fmcsa_eld_output_generator.dart:14-24`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-017: اعتماد محقون غير مستخدم في Provider التتبع
- **Severity:** Low
- **Category:** Dead Dependency
- **Location:** `lib/features/dvir/presentation/providers/dvir_provider.dart:96` و `:117-125`
- **Evidence:**
```dart
  final storageService = ref.watch(trackingConfigStorageProvider);
  final selectedVehicle = ref.watch(vehicleProvider).selectedVehicle;
```
```dart
  DvirNotifier({
    required DvirRepository repository,
    required TrackingConfigStorageService storageService,
    String? vehicleId,
  })  : _repository = repository,
        _vehicleId = vehicleId,
```
- **Current behavior:** `TrackingConfigStorageService` يُقرأ ويُمرَّر إلى الـ Notifier ثم **لا يُخزَّن ولا يُستخدم إطلاقاً** — لا حقل له ولا مرجع في جسم الـ class.
- **Why problematic:** اعتماد زائد يوحي بارتباط غير موجود بين DVIR وتخزين إعدادات التتبع، ويصعّب الاختبار بتزويد خدمة غير مستعملة.
- **Violated principle:** Dead Code / Undeclared Effective Dependency.
- **Current owner:** `dvirProvider` + `DvirNotifier`
- **Correct owner:** — (يُحذف)
- **Consequences:** `DvirNotifier` غير قابل للاختبار دون تزويده بخدمة لا يستخدمها.
- **Recommended correction:** حذف السطرين.
- **Related files:** `lib/core/services/tracking_config_storage_service.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-018: `// ignore_architecture` على استيرادات تكسر عزل الميزات
- **Severity:** High
- **Category:** Cross-Feature Coupling (data → presentation)
- **Location:** `lib/features/sync/data/providers/sync_providers.dart:7-8`
- **Evidence:**
```dart
import '../../../auth/presentation/providers/auth_state_provider.dart'; // ignore_architecture
import '../../../logs/data/datasources/log_local_data_source.dart'; // ignore_architecture
```
- **Current behavior:** **طبقة data** في ميزة `sync` تستورد من **presentation** ميزة أخرى (`auth`) ومن **data** ميزة أخرى (`logs`).
- **Why problematic:** (أ) `data → presentation` انقلاب اتجاه صارم في Clean Architecture. (ب) `authStateProvider` مصدر حالة واجهة؛ ربط المزامنة به يربط دورة حياةها بعمر واجهة المصادقة. (ج) التعليق `// ignore_architecture` **يُخفي** الانحراف ولا يظهر في أي تقرير architecture.
- **Violated principle:** Dependency Rule (inward-only)، Feature Isolation.
- **Current owner:** `sync/data/providers`
- **Correct owner:** عقد في domain — `DispatchAuthContext` **موجود أصلاً** في `sync/domain/entities/dispatch_auth.dart:5`؛ يكفي تمرير closures من composition root، أو استخراج مزوّد الجلسة إلى `core/`.
- **Consequences:** لا يمكن اختبار `sync` بمفرده؛ تغيير auth presentation يكسر المزامنة بصمت.
- **Recommended correction:** نقل مزوّد الجلسة إلى `core/session/`، أو تمرير `observeAuth` من `app/orchestrators`.
- **Related files:** `sync/domain/entities/dispatch_auth.dart`, `sync/data/providers/sync_providers.dart:90-102`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-019: صفحات تُطلق side-effects على مزوّدات features أخرى
- **Severity:** Low
- **Category:** Cross-Feature Side Effects from UI
- **Location:** `lib/features/inspection/presentation/pages/dot_inspection_page.dart:63-65`، `lib/features/vehicle/presentation/pages/select_vehicle_page.dart:84-92`
- **Evidence:**
```dart
// dot_inspection_page.dart:63-65
    if (ref.read(inspectionProvider).isInspectionMode) {
      ref.read(accountProvider.notifier).fetchMyAccount();
    }
```
```dart
// select_vehicle_page.dart:84-92
    final state = ref.read(vehicleProvider);
    if (state.isSuccess && state.selectedVehicle != null) {
      final v = state.selectedVehicle!;
      ref.read(dashboardDataProvider.notifier).updateVehicle(v);
      final uid = v.uniqueId;
      if (v.deviceId != null) {
        ref.read(localStorageProvider).setDeviceId(v.deviceId.toString());
      } else if (uid != null && uid.isNotEmpty) {
        ref.read(localStorageProvider).setDeviceId(uid);
      }
    }
```
- **Current behavior:** صفحات presentation تستدعي notifiers لميزات أخرى كأثر جانبي، وصفحة **`select_vehicle_page` تكتب تخزين الجهاز مباشرة**.
- **Why problematic:** (أ) `setDeviceId` من Widget = side effect على device storage خارج دورة حياة أي feature. (ب) لا orchestrator ينسّق هذه手续 رغم وجود `app/orchestrators/tracking_orchestrator.dart` كنموذج صالح.
- **Violated principle:** UI Purity، Orchestration Placement.
- **Current owner:** Widgets.
- **Correct owner:** `app/orchestrators/*.dart` يستمع للحالة.
- **Consequences:** إعادة تحميل حساب عند كل تفتيش؛ تغيّر `deviceId` من صفحة بلا event.
- **Recommended correction:** نقل الـ trigger إلى orchestrator يستمع `vehicleProvider` / `inspectionProvider`.
- **Related files:** `app/orchestrators/tracking_orchestrator.dart:87-95` (النمط الصحيح موجود)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-020: parsing الوقت وتصنيف رموز duty داخل Widget
- **Severity:** Medium
- **Category:** Business Logic / Parsing in Presentation
- **Location:** `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart:75-162`
- **Evidence:**
```dart
  static String _rowOf(DotInspectionEvent event) {
    // The standard duty code is authoritative; free-text matching below is
    // only a fallback for servers that send descriptive codes.
    switch (event.eventCode.trim().toUpperCase()) {
      case '1':
      case 'OFF':
        return 'OFF';
```
  و `_hourOf` (سطر 75) يحلل **5 صيغ وقت**: ISO، epoch (10/13 رقماً)، AM/PM بـ regex، `HH:mm`، و`HHMM`.
- **Current behavior:** Widget (أ) يحلل نص الوقت القادم من الخادم إلى ساعة عشرية، (ب) يصنّف كود الحالة بنص حر مع 5 regex احتياطية، ويعيد `'OFF'` كقيمة fallback افتراضية (سطر 161).
- **Why problematic:** (أ) `DutyStatusCode.fromAny(...)` **موجود في domain** ويستخدمه `fmcsa_eld_output_generator.dart:206`. (ب) تحليل الوقت **مكرر المنطق** مع `FmcsaEldOutputGenerator._parseTimeToHHmmss:191-203`. (ج) fallback `'OFF'` يخفي فشل التصنيف بصمت.
- **Violated principle:** DRY، Parsing Layer Placement.
- **Current owner:** Widget.
- **Correct owner:** `lib/domain/duty_status/` للرمز؛ `core/time/` لتحليل الوقت.
- **Consequences:** رسم بياني خاطئ عند أي صيغة جديدة من الخادم، بصمت.
- **Recommended correction:** `_rowOf` → `DutyStatusCode.fromAny(event.eventCode).wire`؛ `_hourOf` → دالة في `core/time/parse_eld_time.dart`.
- **Related files:** `lib/domain/duty_status/duty_status_code.dart`, `inspection/data/services/fmcsa_eld_output_generator.dart:191-206`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-021: صفحة التفتيش تكتب سجل تدقيق عبر data layer لميزة أخرى
- **Severity:** Medium
- **Category:** Cross-Feature Implementation Dependency
- **Location:** `lib/features/inspection/presentation/pages/send_logs_page.dart:11` و `:126-141`
- **Evidence:**
```dart
import '../../../../features/logs/data/providers/log_repository_providers.dart';
```
```dart
      await ref
          .read(logRepositoryProvider)
          .logAudit(
            AuditEntry(
              id: 'transfer-${DateTime.now().millisecondsSinceEpoch}',
              timestamp: DateTime.now(),
              driverId: driverId?.toString() ?? '',
              newStatus: outcome.accepted ? 'SENT' : 'FAILED',
              reason: errorText ?? _commentController.text,
              action: widget.isEmailMode ? 'email_logs' : 'send_logs',
              entityType: 'transfer',
```
- **Current behavior:** صفحة presentation في `inspection` تستدعي **مزوّد data** من `logs` مباشرة وتبني كيان `AuditEntry` من `logs/domain`.
- **Why problematic:** (أ) استيراد `data/providers` من presentation = **تجاوز طبقي**؛ الواجهة يجب أن talk إلى use-case أو عقد لا إلى data layer. (ب) `id` مولّد بـ `millisecondsSinceEpoch` ⇒ **احتمال تصادم** عند إرسالين في نفس المللي ثانية. (ج) ثلاث جهات محتملة لكتابة التدقيق بلا عقد موحد.
- **Violated principle:** Dependency Rule، Feature Isolation.
- **Current owner:** Widget.
- **Correct owner:** use-case في `logs/domain/usecases/record_transfer_audit.dart` خلف عقد `TransferAuditPort`.
- **Consequences:** سجل التدقيق SRS 8.10 يعتمد على نية الواجهة؛ فقدان سجل عند إغلاق الشاشة.
- **Recommended correction:** رفع الاستدعاء إلى `InspectionNotifier.sendLogs`؛ استخدام معرّف فريد بدل الطابع الزمني.
- **Related files:** `logs/data/providers/log_repository_providers.dart`, `logs/domain/entities/audit_entry.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-022: Data models ترث كيانات الـ domain
- **Severity:** Medium
- **Category:** Layer Design (Inheritance vs Composition)
- **Location:** `lib/features/tracking/data/models/location_model.dart:4` و `lib/features/sync/data/models/sync_item_model.dart:4`
- **Evidence:**
```dart
// location_model.dart:4
class LocationModel extends LocationEntity {
```
```dart
// sync_item_model.dart:4
class SyncItemModel extends SyncItem {
```
- **Current behavior:** النموذجان في طبقة data **يمتدان** من كيان الـ domain مباشرة، مع إضافة `fromJson`/`toJson` عليهما.
- **Why problematic:** (أ) **الوراثة** تجعل النموذج is-a الكيان؛ أي حقل جديد في الـ domain يفرض تغيّراً في data. (ب) دوال الحفظ (`fromJson`) تصبح جزءاً من الكيان. (ج) استحالة تغيير تمثيل الكيان دون كسر طبقة data.
- **Violated principle:** Composition over Inheritance، Model Independence.
- **Current owner:** `data/models/*`
- **Correct owner:** نموذج مستقل + `toEntity()`.
- **Consequences:** تسرّب منطق التخزين إلى كيان العمل.
- **Recommended correction:** `class LocationModel { ... LocationEntity toEntity() => ...; }`.
- **Related files:** `tracking/domain/entities/location_entity.dart`, `sync/domain/entities/sync_item.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-023: أصناف Mock داخل كود الإنتاج
- **Severity:** Medium
- **Category:** Test Code in Production / Environment Switching
- **Location:** `lib/features/tracking/domain/usecases/tracking_event_processor.dart:48-78`، `lib/features/tracking/data/datasources/live_tracking_data_source.dart:24-98`، `lib/features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart:3`، `lib/features/sync/data/providers/sync_providers.dart:42-49`
- **Evidence:**
```dart
// tracking_event_processor.dart:47-56  ← داخل domain/usecases
  // --- Mock Support للمحافظة على التوافق مع وضع التطوير القديم ---
  void _startMockProcessing() {
    // محاكاة الاتصال الناجح في وضع Mock
    _connectionStatusController.add(ConnectionStatus.connected);

    double mockSpeed = 0.0;
    double mockLat = 24.7136;
    double mockLon = 46.6753;

    _mockTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      mockSpeed = (mockSpeed < 60.0) ? mockSpeed + 5.0 : 60.0;
```
  ومعه في نفس الدالة (سطر 63-70):
```dart
      _eldEventsController.add(EldEvent(
        timestamp: now,
        speedMph: mockSpeed,
        speedDurationSeconds: 5,
        odometerMiles: null,
        engineHours: null,
        fromEcm: true, // مهم جداً: جعل محرك HOS يعتقد أن هذه الأحداث حقيقية لاختبار التحويل للقيادة
      ));
```
- **Current behavior:** **أربع** شُعَب بيانات وهمية داخل `lib/`: مولّد في الـ **domain usecase**، مولّد ثانٍ في data datasource، mock client في traccar_sdk، وmock dispatcher في providers. المولّدان **يتكرران** نفس المنطق (مؤقّت 5 ثوانٍ + إحداثيات مثبتة).
- **Why problematic:** (أ) **domain layer تحتوي `Timer.periodic`** — use-case كان يجب أن يكون نقياً. (ب) **خطر سلامة حقيقي**: المولّد يُصدر `fromEcm: true` أي أن محرك HOS يعتبرها **قيادة حقيقية** (كما يصرّح تعليق السطر 69). (ج) mockان متطابقان يمكن أن يُشغَّلا معاً.
- **Violated principle:** Layer Purity (domain)، Environment Configuration.
- **Current owner:** 4 ملفات إنتاجية.
- **Correct owner:** `test/` مع `ProviderScope` overrides في اختبارات التكامل فقط.
- **Consequences:** في أي مسار يفشل، **بيانات GPS وهمية** تدخل سجلات HOS كـ driving فعلي — مخالفة FMCSA مباشرة.
- **Recommended correction:** نقل جميع الأصناف إلى `test/helpers/`؛ الإنتاج يعتمد على `TraccarNativeClientImpl` وحده.
- **Related files:** `core/events/eld_events_provider.dart:12` (المستهلك الفعلي)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-024: قاعدة عمل مُطبَّقة بـ `assert()` داخل طبقة data
- **Severity:** Low
- **Category:** Business Rule Placement / Debug-Only Enforcement
- **Location:** `lib/features/sync/data/repositories/sqlite_offline_queue.dart:265-268` (والمكرر في `memory_offline_queue.dart:86-89`)
- **Evidence:**
```dart
    assert(
      state != StoredEventState.quarantinedUnknownOwner,
      'use moveToQuarantine for unknown-owner parking',
    );
```
- **Current behavior:** شرط **صحيح معمارياً** (منع اختيار الدالة الخطأ) لكن **مطبَّق بـ `assert`** الذي **يُزال كلياً في بناء الإصدار (release)**.
- **Why problematic:** قاعدة صنف لا تُطبَّق في الإنتاج؛ فيمكن لـ`moveToDeferred(state: quarantinedUnknownOwner)` المرور بصمت على الجهاز، فـ **صف مجهول المالك يُعامَل كـ «مؤجَّل قابل للإفراج»** ويُفرَج عند عودة المالك — وهو تحديداً ما يقضبه `sync_engine.dart:86-88` («المحجور-مجهول لا يُمس أبداً هنا»).
- **Violated principle:** Defense in Depth.
- **Current owner:** طبقتا التنفيذ.
- **Correct owner:** الـ domain — `SyncEngine` أو عقد `OfflineQueue` يعيد `Result` بدل `Future<void>`.
- **Consequences:** في release، سوء الاستخدام يقوّض ضمان الـ quarantine.
- **Recommended correction:** استبدال `assert` بـ `if (...) return Future.error(...)`، أو تقسيم الـ enum design بحيث يستحيل الاستدعاء.
- **Related files:** `sync/domain/usecases/sync_engine.dart:86-116`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-025: ازدواجية كاملة لمنظومة الطابور داخل ميزة sync
- **Severity:** High
- **Category:** Duplicated Subsystem / Dead Code
- **Location:** `lib/features/sync/data/repositories/sync_repository_impl.dart` (156 سطراً) مقابل `lib/features/sync/domain/usecases/sync_engine.dart` (226 سطراً)
- **Evidence:**
```dart
// sync_repository_impl.dart:18
  static const int _maxRetries = 3;
```
```dart
// sync_repository_impl.dart:106-110
  /// إرسال حدث للخادم
  ///
  /// P0 2B-1 — حكم الحجر يُحترم هنا أيضاً: يُبقى العنصر كما هو بلا
  /// زيادة محاولات (هذا الطابور عملياً بلا producers؛ لا storm ولا حذف).
  Future<bool> _sendToServer(SyncItem item) async {
```
- **Current behavior:** ميزتان متنافستان: (أ) `OfflineQueue`/`SyncEngine`/`PendingEvent`/`sqflite` — **المستخدَمة فعلياً** بـ DVIR وlogs وinspection وduty. (ب) `SyncRepository`/`SyncItem`/`SyncLocalDataSource`/`SharedPreferences` — تعمل عبر `SyncNotifier` مع `Timer.periodic(1 minute)`.
- **Why problematic:** (أ) **سياسة retry متعارضة**: `_maxRetries = 3` هنا مقابل `RetryPolicy.maxRetries = 5` في domain. (ب) الملف **يعترف** بـ«هذا الطابور عملياً بلا producers». (ج) الاستهلاك الفعلي الوحيد هو `syncStateProvider` (شارة) و `app_initializer.dart:114` (`container.read(syncStateProvider.notifier)`). (د) كل دورة دقيقة تعيد كتابة الطابور كاملاً في SharedPreferences.
- **Violated principle:** DRY، YAGNI، Single Source of Truth.
- **Current owner:** كليهما بالتساوي.
- **Correct owner:** `OfflineQueue` + `SyncEngine` وحدهما.
- **Consequences:** شارة «بانتظار المزامنة» في `sync_status_indicator.dart` **لا تعكس** طابور الإنتاج ⇒ مؤشر مضلّل للسائق.
- **Recommended correction:** حذف `SyncRepository` / `SyncRepositoryImpl` / `SyncItem` / `SyncLocalDataSource` / `SyncNotifier`؛ تعديل `SyncStatusIndicator` ليقرأ `offlineQueueProvider.count`.
- **Related files:** `sync/presentation/providers/sync_provider.dart`, `app/app_initializer.dart:114`, `sync/data/datasources/sync_local_data_source.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-026: أسماء أنواع الأحداث نصوص حرفية مكرَّرة في domain و data
- **Severity:** Medium
- **Category:** Primitive Obsession / Duplicated Dispatch Table
- **Location:** `lib/features/sync/domain/entities/event_ownership.dart:84-97` مقابل `lib/features/sync/data/repositories/traccar_remote_event_dispatcher.dart:135-147`
- **Evidence:**
```dart
// event_ownership.dart:84-97  (domain)
    switch (event.type) {
      case 'duty_status':
      case 'dvir_create':
      case 'inspection_transfer':
        return _asPositiveInt(payload['driverId']);
      case 'dvir_review':
        final review = payload['review'];
        if (review is Map) {
          return _asPositiveInt(review['reviewingDriverId']);
        }
        return null;
      default:
        return null;
    }
```
```dart
// traccar_remote_event_dispatcher.dart:135-147  (data)
      switch (event.type) {
        case 'duty_status':
          return await _dispatchDutyStatus(event, owner);
        case 'daily_log_form':
          return await _dispatchDailyLogForm(event, owner);
        case 'certification':
          return await _dispatchCertification(event, owner);
        case 'dvir_create':
          return await _dispatchDvirCreate(event, owner);
```
- **Current behavior:** أسماء الأنواع **نصوص حرفية** مكرَّرة في **موقعين** بقواعد مختلفة: الأنواع ذات `driverId` مباشر (4) ≠ الأنواع ذات معالج (6).
- **Why problematic:** إضافة نوع جديد تتطلب **تعديلاً صامتاً في مكانين**؛ إذا نُسي أحدهما يُحجر الحدث `unknown` بلا تشخيص. (ملاحظة: نقص `daily_log_form`/`certification` من جدول domain **مقصود وموثّق** في سطر 81، لكنه غير مفروض آلياً).
- **Violated principle:** Open/Closed، Type Safety.
- **Current owner:** سلاسل حرفية في domain + data.
- **Correct owner:** `enum PendingEventType` في domain مع `wire` و`hasDirectOwnerSlot` كخصائص على الـ enum.
- **Consequences:** جدولة نوع جديد دون تحديث ⇒ فقدان أحداث بصمت.
- **Recommended correction:** `enum` معياري؛ و`switch` مبنيان على `PendingEventType.fromWire(event.type)` مع compiler exhaustiveness.
- **Related files:** `sync/domain/entities/pending_event.dart`, `sync/data/providers/sync_providers.dart:70-103`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-027: فرع dead-lettering غير قابل للوصول + إعادة محاولة بلا سقف
- **Severity:** High
- **Category:** Dead Code / Reliability / Unbounded Resource
- **Location:** `lib/features/sync/domain/entities/pending_event.dart:60-71` → `lib/features/sync/domain/usecases/sync_engine.dart:203-212`
- **Evidence:**
```dart
// pending_event.dart:60-71
  DateTime? calculateNextRetry(
    int currentRetries, {
    required DateTime nowUtc,
  }) {
    // FMCSA: Never drop HOS data, cap at max retries delay and keep retrying.
    final effectiveRetries = currentRetries >= maxRetries ? maxRetries : (currentRetries + 1);

    // Linear backoff: base × factor × (effectiveRetries) — locked by pending_event_test.
    final delaySeconds =
        baseDelay.inSeconds * (backoffFactor * effectiveRetries);
    return nowUtc.add(Duration(seconds: delaySeconds.toInt()));
  }
```
```dart
// sync_engine.dart:203-212
        if (nextRetry != null) {
          await _queue.updateEvent(event.copyWith(
            retryCount: event.retryCount + 1,
            nextRetryAt: nextRetry,
          ));
        } 
        else {
          AppLogger.warning('SyncEngine: Event ${event.id} exhausted retries. Moving to dead-letter.');
          await _queue.moveToDeadLetter(event);
        }
```
- **Current behavior:** `calculateNextRetry` **لا يملك أي مسار `return null`** رغم أن نوعه `DateTime?`؛ فـ `nextRetry != null` **دائماً صحيحاً**، وفرع `moveToDeadLetter` (سطر 210-211) **ميت تماماً**.
- **Why problematic:** (أ) جدول `dead_letters` (وكل بنية `moveToDeadLetter` في `sqlite_offline_queue.dart:173-194`) **لا تُكتب عملياً أبداً** ⇒ بنية تحتية معطّلة بصمت. (ب) إعادة المحاولة **بلا سقف زمني حقيقي**: كل حدث يُعاد كل `5 × 2 × 5 = 50` ثانية **إلى الأبد** عند فشل دائم (مثلاً deviceId خاطئ)، مع إعادة كتابة الصف في SQLite كل مرة.
- **Violated principle:** Dead Code، Resource Bounding.
- **Current owner:** `RetryPolicy.calculateNextRetry`
- **Correct owner:** نفس الدالة — إضافة `return null;` عند تجاوز السقف، أو تغيير العقد ليعيد `Duration` غير nullable ويبقى قرار السقف في `SyncEngine`.
- **Consequences:** نمو غير محدود للطابور + استنزاف بطارية + كتابة SQLite مستمرة في وضع offline؛ و`dead_letters` غير مُختبَرة عملياً.
- **Recommended correction:** `if (currentRetries >= maxRetries) return null;` **قبل** حساب الـ delay؛ وتحديث `pending_event_test` المقفل.
- **Related files:** `sync/data/repositories/sqlite_offline_queue.dart:173-194`, `sync/data/repositories/sync_repository_impl.dart:18` (سياسة 3 المتعارضة)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-028: تزامن داخلي بـ Completer داخل Use-case
- **Severity:** Medium
- **Category:** Complexity / SRP
- **Location:** `lib/features/sync/domain/usecases/sync_engine.dart:30-33` و `:56-84`
- **Evidence:**
```dart
  bool _isSyncing = false;
  bool _syncAgain = false;
  final Map<String, Completer<Either<Failure, bool>>> _reports = {};
  final List<Completer<void>> _idle = [];
```
```dart
// sync_engine.dart:60-71
    if (_isSyncing) {
      _syncAgain = true;
      final idle = Completer<void>();
      _idle.add(idle);
      if (!_isSyncing && !idle.isCompleted) {
        idle.complete();
      }
      await idle.future;
    }
    if (!report.isCompleted) {
      await triggerSync();
    }
```
- **Current behavior:** `SyncEngine` (use-case) يحوي **آلية انتظار/تنبيه معقدة** أسفل واجهة `Future`، مع 4 حقول حالة متزامنة.
- **Why problematic:** (أ) الشرط `!_isSyncing && !idle.isCompleted` بعد `_idle.add(idle)` **منطقياً شبه مستحيل** (فرع ميت). (ب) `_isSyncing` يُقرأ بعد `await` دون قفل ⇒ **تسابق بين `_syncAgain` و `_idle`**. (ج) تعقيد `submitEventAndReport` هشّ ويصعب صيانة.
- **Violated principle:** SRP، Complexity Management.
- **Current owner:** `SyncEngine`
- **Correct owner:** `Completer<void>? _idleGate` واحد، أو `StreamController`، أو جعل الطلب مباشراً بلا انتظار دورة.
- **Consequences:** احتمال أن لا يُكتمل الـ Completer ⇒ `await idle.future` يعلّق ⇒ السائق لا يعرف إن كان حدث duty قُبل.
- **Recommended correction:** استبدال `List<Completer<void>>` بـ gate واحد؛ أو جعل `submitEventAndReport` لا ينتظر دورة المزامنة.
- **Related files:** `sync/data/providers/sync_providers.dart:105-148`
- **Confidence:** **CONFIRMED** (وجود التعقيد وفرع ميت) / **POTENTIAL** (حدوث التعليق الفعلي — يعتمد على جدولة التنفيذ)

--------------------------------------------------
### ISSUE DST-029: مزوّدات Riverpod موزّعة على أربع طبقات في الميزة نفسها
- **Severity:** Medium
- **Category:** Composition Root Placement
- **Location:** `lib/features/tracking/data/datasources/live_tracking_data_source.dart:129`، `lib/features/tracking/data/services/tracking_service.dart:200`، `lib/features/tracking/presentation/providers/tracking_providers.dart:10`
- **Evidence:**
```dart
// live_tracking_data_source.dart:129-136  ← داخل data/datasources
final liveTrackingDataSourceProvider = Provider<LiveTrackingDataSource>((ref) {
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    final dataSource = MockLiveTrackingDataSource();
    dataSource.start();
    ref.onDispose(() {
      dataSource.dispose();
    });
    return dataSource;
```
```dart
// tracking_providers.dart:151-157  (data/datasources)
    // Start processing (starts native tracking)
    dataSource.start();
```
- **Current behavior:** أربعة مواقع لـ Riverpod providers في نفس الميزة: `data/datasources/`, `data/services/`, `data/providers/`, `presentation/providers/`.
- **Why problematic:** (أ) **DI خارج composition root**: `liveTrackingDataSourceProvider` يُستهلك من `core/events/eld_events_provider.dart:12` ⇒ `core` يعتمد على data feature (DST-030). (ب) `Provider` **بدون `autoDispose`** ⇒ حي طوال عمر التطبيق ويبدأ التتبع تلقائياً عند أول watch. (ج) `dataSource.start()` غير-awaited في جسم المزوّد ⇒ استثناء غير ملتقَط.
- **Violated principle:** Composition Root, Layer Direction.
- **Current owner:** 4 ملفات.
- **Correct owner:** `data/providers/tracking_providers.dart` **وحده**، أو `app/` للـ cross-feature.
- **Consequences:** فشل بدء التتبع في provider غير مُبلَّغ عنه.
- **Recommended correction:** نقل المزوّدات إلى `data/providers/tracking_providers.dart`؛ إضافة `.autoDispose` حيث يلزم؛ معالجة خطأ `start()`.
- **Related files:** `core/events/eld_events_provider.dart:12,17`, `tracking/presentation/providers/tracking_providers.dart:10`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-030: `core` يستورد من `features/*/data` (انقلاب اتجاه)
- **Severity:** High
- **Category:** Layer Direction Inversion
- **Location:** `lib/core/events/eld_events_provider.dart:3`
- **Evidence:**
```dart
import '../../features/tracking/data/datasources/live_tracking_data_source.dart';
import '../domain/entities/hos_models.dart';
import '../../features/tracking/domain/entities/connection_status.dart';

/// Domain-level provider exposing the live ELD events stream.
///
/// This decouples the HOS/Sync/Logs domains from directly importing
/// the tracking data source.
final eldEventsStreamProvider = StreamProvider<EldEvent>((ref) {
  return ref.watch(liveTrackingDataSourceProvider).events;
});
```
- **Current behavior:** حزمة `core` (النواة المشتركة) تستورد **طبقة data** لميزة `tracking` ثم تعيد تصدير `StreamProvider` منها.
- **Why problematic:** (أ) **انقلاب اتجاه صارم**: `core` أدنى الهرم ويُفترض أن يقدّم على الميزات لا أن يعتمد عليها. (ب) كل مستهلك لـ `eldEventsStreamProvider` (HOS، sync) **يحبس** كاملَ حزمة `tracking/data` في رسمه البياني. (ج) الملف يصف نفسه بـ«Domain-level provider» (سطر 7) وهو **ليس كذلك**.
- **Violated principle:** Dependency Rule، Layer Direction.
- **Current owner:** `core/events/eld_events_provider.dart`
- **Correct owner:** `tracking/presentation/providers/` أو `app/orchestrators/`؛ أو domain port مع implementation في data.
- **Consequences:** لا يمكن حذف feature tracking دون كسر `core`؛ خطر تصادم أسماء providers.
- **Recommended correction:** نقل الملف إلى `tracking/presentation/providers/`؛ composition في `app/orchestrators/tracking_orchestrator.dart`.
- **Related files:** `sync/data/providers/sync_providers.dart:12,127`, `app/app_initializer.dart:116`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-031: قواعد جودة موقع في طبقة datasource
- **Severity:** Medium
- **Category:** Business Rule in Data Layer
- **Location:** `lib/features/tracking/data/datasources/native_event_channel_client.dart:15-55`
- **Evidence:**
```dart
  NativeLocationEvent validate(
      NativeLocationEvent event, DateTime? lastRecordedAt) {
    // Basic coordinate bounds
    if (event.latitude < -90 ||
        event.latitude > 90 ||
        event.longitude < -180 ||
        event.longitude > 180) {
      return event.copyWith(qualityStatus: LocationQualityStatus.invalid);
    }
    ...
    // Time validation
    final now = _nowUtc();
    final timeDiff = event.recordedAt.difference(now).inMinutes;
    if (timeDiff > 5) {
      // Future timestamp (suspicious)
      return event.copyWith(qualityStatus: LocationQualityStatus.suspicious);
    }

    if (now.difference(event.recordedAt).inMinutes > 60) {
      // Very old (stale)
      return event.copyWith(qualityStatus: LocationQualityStatus.stale);
    }

    // Ordering validation
    if (lastRecordedAt != null && event.recordedAt.isBefore(lastRecordedAt)) {
      return event.copyWith(qualityStatus: LocationQualityStatus.outOfOrder);
    }
```
- **Current behavior:** **ست قواعد جودة** (حدود، NaN/Infinity، سالب، future > 5 د، stale > 60 د، ترتيب) مُنفَّذة داخل `datasources/`.
- **Why problematic:** (أ) العتبات **5 و 60 دقيقة قيم أعمال** (سلامة سجل ELD) لا دوال لغة. (ب) **غير قابلة للاختبار** دون EventChannel (لولا حقن `nowUtc` لكانت مرتبطة بساعة الجهاز). (ج) `LocationQualityStatus` و`LocationSource` **enums في domain** لكن منطق استخدامها في data.
- **Violated principle:** Domain Model، Layer Placement، Testability.
- **Current owner:** `NativeLocationQualityValidator` (data)
- **Correct owner:** `tracking/domain/services/location_quality_policy.dart` مع `const` للعتبات؛ data تحقّق منها فقط.
- **Consequences:** تغيير عتبة الـ stale لا يمكن التحقق منه؛ قاعدة غير مسجّلة في SRS.
- **Recommended correction:** نقل `validate()` إلى domain كدالة pure؛ إبقاء الـ data parser ناقلاً فقط.
- **Related files:** `tracking/domain/entities/native_location_event.dart:3-5`, `tracking/data/providers/tracking_providers.dart:32-34`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-032: الـ port ناقص التغطية ⇒ يُتجاوز عبر `TrackingService` (ازدواج مسارَي التتبع)
- **Severity:** High
- **Category:** Ports & Adapters (Dependency Inversion)
- **Location:** `lib/features/tracking/domain/repositories/tracking_data_source_port.dart:1-8`
- **Evidence:**
```dart
// tracking_data_source_port.dart — كامل الملف
import 'dart:async';
import '../entities/tracking_event.dart';
import '../entities/connection_status.dart';

abstract class TrackingDataSourcePort {
  Stream<TrackingEvent> get events;
  Stream<ConnectionStatus> get connectionStatusStream;
}
```
```dart
// tracking_data_source.dart:9-25  (data)
abstract class TrackingDataSource implements TrackingDataSourcePort {
  @override
  Stream<TrackingEvent> get events;

  @override
  Stream<ConnectionStatus> get connectionStatusStream;

  Future<void> start();

  Future<void> stop();

  Future<TrackingEvent?> getLastEvent();
}
```
- **Current behavior — إجابة فحص الـ port:** الـ port **حقيقي فعلاً** وموضعه صحيح: مُعرَّف في domain، نقي (لا Flutter/Dio/Riverpod)، وله **منفّذ** (`TraccarDataSource`) و**مستهلك** (`TrackingEventProcessor`). **لكنه ناقص**: يعرض التدفقين فقط، فلا يشمل `start/stop` ولا الإذن. لذلك `TrackingRepository` (domain) الذي يملك `startTracking/stopTracking` **لا يستطيع** الاعتماد عليه، فيلجأ `TrackingRepositoryImpl` إلى `TrackingService` (data/services) مباشرة (`tracking_repository_impl.dart:16`).
- **Why problematic — ازدواج المسارات:**
  - **المسار (أ):** `liveTrackingDataSourceProvider` → `TraccarDataSource` + `NativeEventChannelClient` → `TrackingEventProcessor` → `eldEventsStreamProvider` (يستهلكه HOS و sync).
  - **المسار (ب):** `trackingRepositoryProvider` → `TrackingRepositoryImpl` → `TrackingService` → `TraccarNativeClientImpl` + `NativeEventChannelClient` → `trackingStateProvider` (يستهلكه UI و orchestrator).
  كلاهما ينشئ **`TraccarNativeClientImpl` مستقلاً**: `live_tracking_data_source.dart:143` و `app_initializer.dart:67` ⇒ `configure()` و`startBackgroundTracking()` تُنفَّذان على method-channel clients مختلفة ⇒ **حالة native غير متسقة**.
- **Violated principle:** Dependency Inversion، Interface Segregation، Single Source of Truth.
- **Current owner:** port ناقص + `TrackingService` متجاوزَه.
- **Correct owner:** توسيع `TrackingDataSourcePort` بـ `start/stop/getLastEvent`؛ وحذف `TrackingService` كوسيط — `TrackingRepositoryImpl` يعتمد على Port لا على صنف تحكم.
- **Consequences:** مصدران للحقيقة للبيانات؛ خطر تهيئة مزدوجة لـ native.
- **Recommended correction:** (1) توسيع الـ port؛ (2) `TrackingRepositoryImpl` → `TrackingDataSourcePort`؛ (3) `TrackingService` يصبح adapter للـ port أو يختفي؛ (4) توحيد `liveTrackingDataSourceProvider` مع `trackingRepositoryProvider`.
- **Related files:** `tracking/data/repositories/tracking_repository_impl.dart:12,16`, `tracking/data/services/tracking_service.dart:10-20`, `tracking/presentation/providers/tracking_provider.dart:61`, `live_tracking_data_source.dart:143`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-033: اعتماد محقون غير مستخدم في datasource
- **Severity:** Low
- **Category:** Dead Dependency
- **Location:** `lib/features/tracking/data/datasources/tracking_local_data_source.dart:25-29`
- **Evidence:**
```dart
class TrackingLocalDataSourceImpl implements TrackingLocalDataSource {
  // ignore: unused_field
  final LocalStorageService _storage;

  TrackingLocalDataSourceImpl(this._storage);
```
- **Current behavior:** `LocalStorageService` محقون من `tracking_providers.dart:17` ثم **لا يُستخدم**؛ كل التخزين يذهب إلى `SharedPreferences.getInstance()` مباشرة.
- **Why problematic:** اعتماد زائد و`// ignore: unused_field` كاتم؛ يوحي بوجود strategy تخزين غير قائم.
- **Violated principle:** Dead Code، YAGNI.
- **Current owner:** Impl.
- **Correct owner:** — (يُحذف أو يُستخدم فعلياً).
- **Consequences:** لا شيء وظيفياً؛ ضجيج معماري وتكلفة اختبار زائدة.
- **Recommended correction:** حذف الحقل والمُعامل، وتحديث `trackingLocalDataSourceProvider`.
- **Related files:** `tracking/data/providers/tracking_providers.dart:15-19`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-034: التفاف الاستثناءات مرتين في `traccar_api_client_impl`
- **Severity:** Low
- **Category:** Error Handling / Observability
- **Location:** `lib/features/tracking/data/datasources/traccar_sdk/traccar_api_client_impl.dart:39-41`
- **Evidence:**
```dart
    } catch (e) {
      throw Exception('Failed to authenticate: $e');
    }
```
  ويتكرر في `:58-60` و `:80-82` و `:107-109` و `:127-129`.
- **Current behavior:** كل دالة من الخمس تلتقط استثناءً — **حتى استثناءها هي الذي تلتقطه** (سطر 30: `throw Exception('Authentication failed with status: ...')`) — وتغلفه في `Exception` جديد بنص مركّب.
- **Why problematic:** (أ) `DioException` الأصلي (status، request) يضيع خلف `Exception`. (ب) الناتج في `authenticate` يصبح `Exception('Failed to authenticate: Exception: Authentication failed with status: 401')`. (ج) **إطلاق استثناء من داخل `fold`**.
- **Violated principle:** Error Handling، Observability.
- **Current owner:** `TraccarApiClientImpl`
- **Correct owner:** طبقة أعلى — `TrackingRepositoryImpl` يترجم إلى `Failure`.
- **Consequences:** تشخيص أعطال REST صعب ميدانياً؛ والمستودع يبتلعها كلها في `TrackingFailure` عام (`tracking_repository_impl.dart:90-95`).
- **Recommended correction:** إزالة `try/catch` أو استخدام `rethrow` مع `AppLogger.error`.
- **Related files:** `tracking/data/repositories/tracking_repository_impl.dart:90-95`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-035: ابتلاع متتالي عبر ثلاث طبقات يُنتج «فشل غير مرئي»
- **Severity:** High
- **Category:** Swallowed Exception (multi-hop)
- **Location:** `traccar_native_client_impl.dart:66-68` → `tracking_service.dart:170-177` → `tracking_repository_impl.dart:184-193`
- **Evidence:**
```dart
// traccar_native_client_impl.dart:60-69
  Future<List<Map<String, dynamic>>> getNativeLogs() async {
    try {
      final List<dynamic>? result =
          await _channel.invokeMethod<List<dynamic>>('getLogs');
      if (result == null) return [];
      return result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } on PlatformException {
      return [];
    }
  }
```
```dart
// tracking_service.dart:170-178
  Future<List<Map<String, dynamic>>> getLogs() async {
    try {
      return await _tracker.getNativeLogs();
    } catch (e) {
      // In production, we don't mock logs anymore
      AppLogger.error('Failed to get logs from native tracker', e);
      return [];
    }
  }
```
```dart
// tracking_repository_impl.dart:185-193
      final logsData = await _service.getLogs();
      final logs = logsData.map((log) {
        return TrackingLogEntity(
          time: log['time'] as int,
          message: log['message'] as String,
        );
      }).toList();
      return Right(logs);
```
- **Current behavior:** ثلاث طبقات متتابعة تحوّل أي خطأ إلى **قائمة فارغة ناجحة**. المستودع يُرجع `Right([])` دائماً ⇒ فرع `Left` في `tracking_repository_impl.dart:194-198` **غير قابل للوصول عملياً** ⇒ `TrackingNotifier.loadLogs()` يستقبل نجاحاً فارغاً والواجهة تعرض «لا سجلات».
- **Why problematic:** (أ) **أخطر نمط ابتلاع**: خطأ منصّة حقيقي يُعرض كـ «فارغ». (ب) `isTrackingActive` (سطر 40-47 في native client) يبتلع ويُرجع `false` ⇒ الواجهة تعرض «التتبع متوقف» بينما native لا يعرف شيئاً. (ج) `log['time'] as int` cast غير محمي يضيف موضع ثالث لفشل صامت.
- **Violated principle:** Fail-Fast، Error Transparency، Observable Failure.
- **Current owner:** الطبقات الثلاث؛ المسؤولة الأساسية الأدنى.
- **Correct owner:** `TraccarNativeClientImpl` يجب أن **يُعيد الرمي**؛ الترجمة إلى `Failure` في `TrackingRepositoryImpl` وحده.
- **Consequences:** استحالة تشخيص ميداني («السجلات فاضية» بينما native يعطي `MissingPluginException`).
- **Recommended correction:** حذف `on PlatformException { return []; }`؛ و`TrackingService.getLogs` يعيد `rethrow`؛ و`TrackingRepositoryImpl` يترجم إلى `Left(TrackingFailure(...))`؛ واستبدال `as int` بتحقق `is int`.
- **Related files:** `tracking/presentation/providers/tracking_provider.dart:227-239`, `traccar_websocket_client_impl.dart:87-89`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-036: اختراع قيم افتراضية في `LocationModel.fromJson`
- **Severity:** Medium
- **Category:** Data Integrity
- **Location:** `lib/features/tracking/data/models/location_model.dart:17-30`
- **Evidence:**
```dart
  factory LocationModel.fromJson(Map<String, dynamic> json) {
    return LocationModel(
      latitude: (json['latitude'] ?? 0).toDouble(),
      longitude: (json['longitude'] ?? 0).toDouble(),
      altitude: json['altitude']?.toDouble(),
      speed: json['speed']?.toDouble(),
      bearing: json['bearing']?.toDouble(),
      accuracy: json['accuracy']?.toDouble(),
      timestamp: json['timestamp'] != null
          ? DateTime.tryParse(json['timestamp']) ?? DateTime.now()
          : DateTime.now(),
      provider: json['provider'],
    );
  }
```
- **Current behavior:** غياب الإحداثيات ⇒ `(0.0, 0.0)` = **مركز الأرض/محيط الأطلسي**؛ غياب الطابع ⇒ `DateTime.now()`.
- **Why problematic:** (أ) `tracking_local_data_source.dart:41-50` يخزّن هذه القيمة تحت مفتاح `'last_location'`؛ ثم `TrackingRepositoryImpl.getCurrentLocation:126-128` يُرجعها بـ `Right(lastLocation)` ⇒ **موقع مزيّف يُقدَّم كـ GPS حقيقي**. (ب) الطابع الافتراضي يناقض صراحةً الرقابة الصارمة في `native_event_channel_client.dart`.
- **Violated principle:** «لا قيم مخترعة»، Null Safety Semantics.
- **Current owner:** `LocationModel.fromJson`
- **Correct owner:** mapper في data يعيد `LocationModel?` (null عند غياب).
- **Consequences:** نقطة مضلّلة في سجل ELD عند تلف SharedPreferences.
- **Recommended correction:** `static LocationModel? tryParse(Map<String, dynamic> json)` يُرجع null إذا كانت `latitude/longitude` غير موجودتين.
- **Related files:** `tracking/data/repositories/tracking_repository_impl.dart:125-128`, `tracking/data/datasources/tracking_local_data_source.dart:41-50`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-037: مزوّدان لنفس الخدمة — تجاوز `app_initializer` لا يسري
- **Severity:** High
- **Category:** DI Duplication / Dead Override
- **Location:** `lib/features/tracking/data/services/tracking_service.dart:200` مقابل `lib/features/tracking/data/providers/tracking_providers.dart:22`
- **Evidence:**
```dart
// tracking_service.dart:199-204
/// مزود خدمة التتبع
final trackingServiceProvider = Provider<TrackingService>((ref) {
  final storage = ref.watch(localStorageProvider);
  final tracker = ref.watch(traccarNativeClientProvider);
  return TrackingService(storage: storage, tracker: tracker);
});
```
```dart
// tracking_providers.dart:21-26
/// مزود خدمة التتبع
final trackingServiceFullProvider = Provider<TrackingService>((ref) {
  final storage = ref.watch(localStorageProvider);
  final tracker = ref.watch(traccarNativeClientProvider);
  return TrackingService(storage: storage, tracker: tracker);
});
```
```dart
// tracking_providers.dart:40-42
final trackingRepositoryProvider = Provider<TrackingRepository>((ref) {
  final service = ref.watch(trackingServiceFullProvider);
```
```dart
// app/app_initializer.dart:64-69
  Future<void> _initDependentServices() async {
    trackingService = TrackingService(
      storage: localStorageService,
      tracker: TraccarNativeClientImpl(),
    );
    await trackingService.init();
```
```dart
// app/app_initializer.dart:86-95
  ProviderContainer createProviderContainer() {
    return ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(localStorageService),
        localDatabaseServiceProvider.overrideWithValue(localDatabaseService),
        trackingServiceProvider.overrideWithValue(trackingService),
```
- **Current behavior — تحقُّق الفرضية المطلوبة:** (1) `app_initializer.dart:65-69` ينشئ `TrackingService` بـ `TraccarNativeClientImpl()` **يدوياً** ويستدعي `init()`. (2) `app_initializer.dart:91` يتجاوز **`trackingServiceProvider`**. (3) لكن `trackingRepositoryProvider` (سطر 41) يستهلك **`trackingServiceFullProvider`** — **مزوّد مختلف**. ⇒ **التجاوز لا يسري على المستودع**؛ بينما `app/services/quick_actions_initializer.dart:29` يقرأ `trackingServiceProvider` (المتجاوز) فيحصل على النسخة المُهيّأة.
- **Why problematic:** نسختان من نفس البنية، أحدهما مُتجاوز في bootstrap والآخر لا. النتيجة: **الخدمة التي يهيئها التطبيق ويحقنها ليست نفس التي يستخدمها `TrackingRepositoryImpl`** ⇒ حالة `_isInitialized` و`TraccarNativeClient` مختلفان ⇒ `configure()` و`start()` على method-channel clients مختلفة.
- **Violated principle:** DRY، Composition Root Single Source، Least Surprise.
- **Current owner:** ملفان في `data/` + `app/app_initializer.dart`.
- **Correct owner:** مزوّد واحد في `data/providers/tracking_providers.dart`.
- **Consequences:** صعوبة تشخيص التتبع؛ تهيئة مزدوجة؛ سلوك غير متوقع عند أي إضافة.
- **Recommended correction:** حذف `trackingServiceProvider` من `tracking_service.dart` وتوجيه كل الاستهلاك إلى `trackingServiceFullProvider` (أو العكس: حذف `Full` وجعل `app_initializer` يتجاوز `trackingServiceProvider`).
- **Related files:** `lib/app/app_initializer.dart:65-69, 91`, `lib/app/services/quick_actions_initializer.dart:29`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-038: تدفّق الصلاحيات (مع حوارات النظام) داخل مستودع data
- **Severity:** High
- **Category:** UI/Platform Policy in Data Layer
- **Location:** `lib/features/tracking/data/repositories/tracking_repository_impl.dart:50-80`
- **Evidence:**
```dart
      // ١. فحص صلاحية الموقع دائماً (الخلفية) - مطلوبة لعمل Traccar
      var locationStatus = await Permission.locationAlways.status;

      if (!locationStatus.isGranted) {
        // في أندرويد 10+ يجب طلب الصلاحية العادية أولاً ثم الخلفية
        var inUseStatus = await Permission.locationWhenInUse.status;
        if (!inUseStatus.isGranted) {
          inUseStatus = await Permission.locationWhenInUse.request();
        }

        if (inUseStatus.isGranted) {
          locationStatus = await Permission.locationAlways.request();
        }
      }

      if (!locationStatus.isGranted) {
        return const Left(PermissionFailure(
          message: 'صلاحية الموقع في الخلفية مطلوبة',
        ));
      }
```
- **Current behavior:** المستودع ينفّذ **حوارَي أذونات متدرّجين** عبر `permission_handler`، بما في ذلك استدعاء `.request()` الذي **يفتح واجهة نظام**.
- **Why problematic:** (أ) **طبقة data تُطلق UI** ⇒ `TrackingRepository` غير قابل للاختبار ويخالف الـ layering. (ب) **تناقض صريح مع تعليق المشروع**: `tracking_provider.dart:89-92` يقول «Battery-optimisation exemption is requested on the Permissions page (permission_handler); **no second dialog path lives here**» — لكن **المسار الثاني موجود هنا بالتحديد**. (ج) بحث شامل أثبت أن `permission_handler` يظهر في **ثلاثة** مواقع: `tracking_repository_impl.dart:3`، `lib/features/permissions/presentation/pages/permissions_page.dart:4`، `lib/features/auth/presentation/pages/splash_page.dart:9` ⇒ **ثلاثة مسارات أذونات**.
- **Violated principle:** Layer Separation، UI Concerns in Data.
- **Current owner:** `TrackingRepositoryImpl.startTracking()`
- **Correct owner:** `permissions/presentation` للحوار؛ ثم `startTracking()` يفحص الحالة فقط.
- **Consequences:** حوار مزدوج؛ و`Geolocator.isLocationServiceEnabled().catchError(...)` (سطر 73-75) يغلّف نتيجة خدمة الموقع في `Exception('Error updating position: $error')` — **رسالة خاطئة** تماماً.
- **Recommended correction:** استخراج `PermissionCoordinator` في presentation؛ تمرير `bool permissionAlreadyGranted` إلى `startTracking()`.
- **Related files:** `lib/features/permissions/presentation/pages/permissions_page.dart:4`, `lib/features/auth/presentation/pages/splash_page.dart:9`, `tracking/presentation/providers/tracking_provider.dart:89-92`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-039: مصدران للموقع + مسار غير مُتحقَّق منه الجودة
- **Severity:** Medium
- **Category:** Layer Responsibility / Redundant Fallback
- **Location:** `lib/features/tracking/data/repositories/tracking_repository_impl.dart:2` و `:130-142`
- **Evidence:**
```dart
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
```
```dart
      // Fallback to Geolocator
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final fallbackLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        altitude: position.altitude,
        bearing: position.heading,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
      await _localDataSource.saveLastLocation(fallbackLocation);
      return Right(fallbackLocation);
```
- **Current behavior:** `getCurrentLocation` و`requestPosition` (كلاهما) إذا لم يوجد `lastLocation` محفوظ، **يستدعيان `Geolocator.getCurrentPosition`** — أي **مصدر GPS ثانٍ** بجانب native Traccar.
- **Why problematic:** (أ) **مصدران للموقع** لا يُنسَّق بينهما: بيانات native (عبر `locationStream`) وGeolocator (مستقل) ⇒ **تعارض في سجل ELD**. (ب) **رقابة جودة غير متسقة**: المسار الأصلي يمر بـ `NativeLocationQualityValidator` (رقابة صارمة)، بينما مسار Geolocator **لا يمر بأي رقابة** ⇒ **موقع غير مُتحقَّق منه يدخل سجل ELD**. (ج) استهلاك إضافي للبattery خارج ما طلبه UI.
- **Violated principle:** SRP، Single Data Source، Consistency.
- **Current owner:** `TrackingRepositoryImpl`
- **Correct owner:** مصدر واحد (`NativeEventChannelClient`) خلف port.
- **Consequences:** موقع سيّئ الجودة يُسجَّل بلا تحقّق؛ بطارية تُستهلك دون داعٍ.
- **Recommended correction:** حذف الـ fallback، أو تغليفه بـ port منفصل في data يمر بنفس `LocationQualityValidator`.
- **Related files:** `tracking/data/datasources/native_event_channel_client.dart:15-55`, `tracking/presentation/providers/tracking_providers.dart:2` (geolocator في presentation أيضاً)
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-040: ازدواجية حرفية بين `getCurrentLocation` و `requestPosition`
- **Severity:** Medium
- **Category:** Duplicated Orchestration (SRP)
- **Location:** `lib/features/tracking/data/repositories/tracking_repository_impl.dart:119-181`
- **Evidence:**
```dart
// getCurrentLocation:125-149
      final lastLocation = await _localDataSource.getLastLocation();
      if (lastLocation != null) {
        return Right(lastLocation);
      }

      // Fallback to Geolocator
      final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      final fallbackLocation = LocationModel(
        latitude: position.latitude,
        longitude: position.longitude,
        speed: position.speed,
        altitude: position.altitude,
        bearing: position.heading,
        accuracy: position.accuracy,
        timestamp: position.timestamp,
      );
      await _localDataSource.saveLastLocation(fallbackLocation);
      return Right(fallbackLocation);
```
  والمكرر حرفياً في `requestPosition:157-175` (الفرق الوحيد: `await _service.requestPosition(alarm: alarm)`).
- **Current behavior:** جسمان متطابقان عدا سطر واحد.
- **Why problematic:** ازدواجية تشتّت التعديل؛ كلتاهما تشارك نفس القيمة الافتراضية المبتكرة (DST-036) ⇒ **الازدواجية تضاعف مخاطر السلامة**.
- **Violated principle:** DRY، SRP.
- **Current owner:** `TrackingRepositoryImpl`
- **Correct owner:** دالة خاصة `_readOrFetchPosition({String? alarm})`.
- **Recommended correction:** استخراج الجسم المشترك إلى method واحدة.
- **Related files:** `tracking/domain/repositories/tracking_repository.dart:17-20`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-041: `TrackingService` تقرأ `AppEnvironmentConfig` وتنتج خريطة نصية
- **Severity:** Low
- **Category:** Environment Access / Stringly-typed Config
- **Location:** `lib/features/tracking/data/services/tracking_service.dart:32-40` و `:80-95`
- **Evidence:**
```dart
      // لا تسمح ببدء التتبع بعنوان وهمي أو فارغ في بيئة temporaryTraccar
      if (AppEnvironmentConfig.current == AppEnvironment.temporaryTraccar) {
        if (config['serverUrl'].isEmpty ||
            config['serverUrl'].contains('mock-traccar-server')) {
          AppLogger.error(
              '❌ Tracking blocked: Invalid or Mock URL used in temporaryTraccar');
          throw Exception(
              'Configuration Error: Valid Server URL required for temporaryTraccar');
```
```dart
// tracking_service.dart:80-95
    return {
      'serverUrl': serverUrl,
      'deviceId': _storage.deviceId,
      'location': {
        'accuracy': _mapAccuracy(_storage.accuracy),
        'distanceMeters': _storage.distance,
        'intervalSeconds': _storage.interval,
        'angleDegrees': _storage.angle,
        'heartbeatIntervalSeconds': _storage.heartbeat,
        'stopDetection': _storage.stopDetection,
      },
      'wakeLock': _storage.wakelock,
      'buffer': _storage.buffer,
      'preferPlatformProviders': _storage.preferPlatformProviders,
    };
```
- **Current behavior:** طبقة data تقرأ **متغير بيئة عام**، تقارنه بقيمة، وتبني **خريطة `Map<String, dynamic>` غير مُنمَّطة** تُمرَّر إلى `MethodChannel`.
- **Why problematic:** (أ) خطأ إملائي في `'preferPlatformProviders'` أو `'heartbeatIntervalSeconds'` **يُخترع صامتاً** في native بلا أي تحقق. (ب) منطق **حارس بيئة** داخل service ⇒ لا يمكن اختباره إلا بضبط global.
- **Violated principle:** Explicit Configuration، Environment Abstraction.
- **Current owner:** `TrackingService`
- **Correct owner:** `core/config` + factory في `data/providers` يمرّر `TrackingRuntimeConfig` مُنمَّطاً.
- **Consequences:** صمت أمام أخطاء المفاتيح؛ تطبيع منفذ OsmAnd (`osmAndPort`) مثبّت هنا أيضاً.
- **Recommended correction:** كيان `TrackingRuntimeConfig` في domain؛ الـ map تُبنى في adapter واحد.
- **Related files:** `lib/core/config/app_environment.dart`, `lib/core/network/core_providers.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-042: تحويل وحدة مثبت داخل domain usecase
- **Severity:** Low
- **Category:** Hardcoded Value (Business) / Layer Placement
- **Location:** `lib/features/tracking/domain/usecases/tracking_event_processor.dart:100`
- **Evidence:**
```dart
    return EldEvent(
      timestamp: event.timestampUtc,
      speedMph: event.speed * 2.23694,
```
- **Current behavior:** تحويل m/s → mph بمعامل مثبت داخل domain usecase.
- **Why problematic:** (أ) **قيمة فيزيائية أعمال** بلا مرجع ولا اختبار. (ب) استخدمها `FmcsaEldOutputGenerator` أيضاً بمعامل **مختلف** (`0.621371` km→mi). (ج) لو تغيّرت وحدة `LocationEntity` (مثلاً إلى km/h) لن تتغير.
- **Violated principle:** Business Constants Placement، DRY.
- **Current owner:** `TrackingEventProcessor._mapToEldEvent`
- **Correct owner:** `core/constants/` أو دالةUnits في domain مع اختبار.
- **Consequences:** انحراف صامت بين المسارات.
- **Recommended correction:** `Units.metersPerSecondToMilesPerHour(value)` في `core/constants/fmcsa_constants.dart`.
- **Related files:** `lib/features/inspection/data/services/fmcsa_eld_output_generator.dart:118,144`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-043: `Ref` محفوظ داخل Notifier وحقل عام قابل للكتابة من الخارج
- **Severity:** Low
- **Category:** Service Locator Smell / Encapsulation
- **Location:** `lib/features/tracking/presentation/providers/tracking_provider.dart:67-74`
- **Evidence:**
```dart
class TrackingNotifier extends StateNotifier<TrackingState> {
  final TrackingRepository _repository;
  final Ref ref;
  bool Function()? isDrivingChecker;
  StreamSubscription<LocationEntity>? _locationSubscription;
  Timer? _gpsTimeoutTimer;

  TrackingNotifier(this._repository, this.ref) : super(const TrackingState());
```
  ويُملأ من الخارج في `app/orchestrators/tracking_orchestrator.dart:16-22`:
```dart
  final notifier = ref.read(trackingStateProvider.notifier);

  notifier.isDrivingChecker = () {
    final hosState = ref.read(hosStatusProvider);
    return hosState is HosEngineReady &&
        hosState.update.currentStatus == DutyStatus.driving;
  };
```
- **Current behavior:** الـ notifier يحتفظ بـ `Ref` كاملاً (لالتقاط `currentVehicleSpeedProvider` في `tracking_provider.dart:155`)، و`isDrivingChecker` حقل عام قابل للكتابة يُملأ من orchestrator.
- **Why problematic:** (أ) **service locator**: الـ notifier يعرف المزوّدات بدل الاعتماد على ما يُمرَّر. (ب) **قاعدة أعمال في orchestrator**: «السائق لا يستطيع إيقاف التتبع أثناء القيادة (§395)» مُنفَّذة كـ callback مخزَّن، فتُختبر فقط عبر integration.
- **Violated principle:** Encapsulation، Dependency Inversion.
- **Current owner:** `TrackingNotifier` + `tracking_orchestrator.dart`.
- **Correct owner:** use-case في domain يقبل `isDriving` كمدخل، أو `ref.keepAlive()` مع مزوّد `isDrivingProvider` محقون.
- **Consequences:** `TrackingNotifier` غير قابل للاختبار دون container؛ سلوك مرتبط بترتيب التهيئة.
- **Recommended correction:** تمرير `isDrivingProvider` كمُعامل للـ Notifier بدل الحقل القابل للكتابة؛-roll استبدال `Ref` المحفوظ بمزوّد السرعة كمُعامل أو `Ref` للقراءة فقط.
- **Related files:** `app/orchestrators/tracking_orchestrator.dart:16-22, 97-109`, `tracking/presentation/providers/tracking_provider.dart:155, 173-180`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-044: قراءة JSON وربط HTTP داخل domain في `vehicle_selection.dart`
- **Severity:** Medium
- **Category:** Layer Responsibility (Domain doing Data work)
- **Location:** `lib/features/vehicle/domain/vehicle_selection.dart:52-96` و `:99-119`
- **Evidence:**
```dart
/// A missing list is an error. An empty list is an empty success.
/// A row without `uniqueId` or `vehicleId` is not given an invented id.
List<Vehicle>? parseVehicleList(dynamic data) {
  final raw = _vehicleRows(data);
  if (raw == null) return null;
  final vehicles = <Vehicle>[];
  for (final item in raw) {
    final row = _asMap(item);
    if (row == null) return null;
    final vehicle = readVehicle(row);
    if (vehicle == null) return null;
    vehicles.add(vehicle);
  }
  return vehicles;
}

Vehicle? readVehicle(Map<String, dynamic> json) {
  final uniqueId = _text(json['uniqueId']);
  final vehicleId = _text(json['vehicleId'] ?? json['id']);
  final id = uniqueId ?? vehicleId;
  if (id == null) return null;
```
```dart
// vehicle_selection.dart:98-119
/// Prefer the server sentence. Otherwise name the HTTP result, do not invent a policy.
String vehicleOperateFailure({
  required String code,
  String? serverMessage,
  int? statusCode,
}) {
  final message = serverMessage?.trim();
  if (message != null && message.isNotEmpty) return message;
  switch (statusCode) {
    case 400:
      return 'rejected';
    case 403:
      return 'unauthorized';
```
- **Current behavior:** الملف يحتوي **ثلاثة أنواع مختلفة** من المسؤوليات: قواعد اختيار أعمال صرفة + **قراءة جسم خادم (JSON parsing)** + **خريطة رموز حالة HTTP**.
- **Why problematic:** (أ) **إجابة فحص المطلوب:** الموضع **ليس خطأً طبقياً صارماً** (لا استيراد Flutter/Dio/Riverpod — تحقّقت)، لكنه **مسؤولية مختلطة**: قراءة JSON ووصل HTTP من职责 data داخل `domain/`. (ب) `readVehicle` يقرأ `'uniqueId'` و`'vehicleId'` و`'myVehicle'` و`'inUseByOtherDriver'` — أسماء حقول خادم wire داخل domain. (ج) `vehicleOperateFailure` خريطة HTTP، ويستهلكها `vehicle_repository_impl.dart:72-80`.
- **Violated principle:** SRP، Layer Cohesion.
- **Current owner:** `vehicle/domain/vehicle_selection.dart`
- **Correct owner:** `vehicle/data/mappers/vehicle_mappers.dart` لـ JSON + HTTP mapping؛ وتبقى القواعد الصرفة في domain.
- **Consequences:** تغيير اسم حقل في API يمسّ domain؛ لا يمكن تبديل strategy قراءة بلا تعديل domain.
- **Recommended correction:** فصل الملف إلى (1) `vehicle_selection_rules.dart` (domain: `listedVehicleIsOperable`, `refuseVehicleOperate`, `readOperableUniqueId`)، (2) `vehicle/data/mappers/vehicle_mappers.dart` (JSON)، (3) خريطة HTTP في `vehicle_repository_impl`.
- **Related files:** `vehicle/data/repositories/vehicle_repository_impl.dart:35-56, 72-80`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-045: قاعدة اختيار مركبة مكرَّرة يدوياً في presentation مع دالة domain ميتة
- **Severity:** Medium
- **Category:** Duplicated Business Rule / Dead Domain Code
- **Location:** `lib/features/vehicle/presentation/providers/vehicle_provider.dart:228-245` مقابل `lib/features/vehicle/domain/vehicle_selection.dart:29-48`
- **Evidence:**
```dart
// vehicle_selection.dart:29-48  (domain — لا يُستدعى من أي مكان في lib/)
VehicleOperateRefusal? refuseVehicleOperate({
  required double? speedMps,
  required double thresholdKmh,
  required String? uniqueId,
}) {
  if (!thresholdKmh.isFinite || thresholdKmh <= 0) {
    return VehicleOperateRefusal.thresholdMissing;
  }
  if (speedMps == null || !speedMps.isFinite) {
    return VehicleOperateRefusal.motionUnknown;
  }
  if (speedMps * 3.6 >= thresholdKmh) {
    return VehicleOperateRefusal.vehicleMoving;
  }
  final id = uniqueId?.trim() ?? '';
  if (id.isEmpty || id == 'unknown' || id == 'No Vehicle') {
    return VehicleOperateRefusal.identifierMissing;
  }
  return null;
}
```
```dart
// vehicle_provider.dart:228-245  (presentation — إعادة تنفيذ يدوية)
    // SRS 9.4: المركبة قيد الحركة فعلياً (تيار موقع حي) — رفض فوري.
    if (trackingLive && speedMps != null && speedMps * 3.6 >= thresholdKmh) {
      state = state.copyWith(isLoading: false, error: 'vehicleMoving');
      return;
    }

    // SRS 9.3: حارس التبديل يعمل فقط حين يكون تيار الموقع حياً —
    // تتبع مغلق يعني لا دليل قيادة أصلاً؛ الاختيار هو بدء الجلسة الجديدة
    // والتحقق القانوني يتكفل به الخادم عند connectSession.
    final hasActiveSession =
        state.vehicles.any((v) => v.activeForCurrentDriver == true) ||
        (state.selectedVehicle != null &&
            state.selectedVehicle?.id != 'No Vehicle');

    if (hasActiveSession && trackingLive && speedMps == null) {
      state = state.copyWith(isLoading: false, error: 'motionUnknown');
      return;
    }
```
- **Current behavior:** `VehicleOperateRefusal` و `refuseVehicleOperate` **معزوفان في domain وم-touching by any code في `lib/`** (بحث شامل على المشروع). `VehicleNotifier.selectVehicle` يعيد تنفيذ القاعدتين **بنصوص خطأ حرفية** `'vehicleMoving'` و `'motionUnknown'` و `'No Vehicle'`.
- **Why problematic:** (أ) **دالة domain ميتة** بينما presentation يكرّر منطقها — بالضبط الحالة التي يفحصها التدقيق. (ب) **البدلالات تختلف**: domain يفحص `thresholdKmh.isFinite` و`uniqueId`؛ presentation **لا يفحصهما إطلاقاً** ⇒ `thresholdKmh` غير منتهٍ يتجاوز الحارس. (ج) sentinel `'No Vehicle'` مطابق حرفياً في presentation (DST-012 sibling).
- **Violated principle:** DRY， Dead Code، Single Source of Truth.
- **Current owner:** presentation يدوياً؛ domain معزوف.
- **Correct owner:** `refuseVehicleOperate` في domain كما هي — على presentation استدعاؤها.
- **Consequences:** قاعدة أمان حارس المركبة (SRS 9.3/9.4) غير مطبَّقة بالكامل؛ تعديل domain لا يؤثر على السلوك الفعلي.
- **Recommended correction:** في `selectVehicle`: `final refusal = refuseVehicleOperate(speedMps: speedMps, thresholdKmh: thresholdKmh, uniqueId: vehicle.uniqueId ?? vehicle.id); if (refusal != null) { state = ...(refusal.name); return; }` مع إبقاء شرط `trackingLive` كشرط منفصل في presentation.
- **Related files:** `vehicle/domain/vehicle_selection.dart:3-8, 29-48`, `vehicle/presentation/pages/select_vehicle_page.dart:55-94`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-046: صفحة تكتب device storage مباشرة
- **Severity:** Low
- **Category:** Side Effect in Presentation
- **Location:** `lib/features/vehicle/presentation/pages/select_vehicle_page.dart:86-92`
- **Evidence:** (انظر DST-019 لأداء الكود الكامل) — تحديداً:
```dart
      final uid = v.uniqueId;
      if (v.deviceId != null) {
        ref.read(localStorageProvider).setDeviceId(v.deviceId.toString());
      } else if (uid != null && uid.isNotEmpty) {
        ref.read(localStorageProvider).setDeviceId(uid);
      }
```
- **Current behavior:** صفحة presentation تكتب `deviceId` في التخزين المحلي، وتحدّث `dashboardDataProvider`، ثم `context.go(...)`.
- **Why problematic:** (أ) الكتابة على تخزين الجهاز **أثر جانبي دائم** يُنفَّذ من Widget. (ب) المنطق ي duplicate بـ `dvir_form_page.dart:444-476` الذي يحاول قراءة `deviceId` من **fallbacks متعددة** — لأن التخزين قد لا يكون متسقاً.
- **Violated principle:** UI Purity.
- **Current owner:** Widget.
- **Correct owner:** orchestrator يستمع `vehicleProvider`.
- **Recommended correction:** نقل الكتابة إلى `app/orchestrators/tracking_orchestrator.dart` (نفس النمط المستخدم في `vehicle_provider.dart`).
- **Related files:** `vehicle/presentation/providers/vehicle_provider.dart:203-211`, `app/orchestrators/tracking_orchestrator.dart:87-95`
- **Confidence:** **CONFIRMED**

--------------------------------------------------
### ISSUE DST-047: منطق «المركبة المحددة من الخادم» مكرَّر في domain و data و presentation
- **Severity:** Medium
- **Category:** Duplicated Business Rule
- **Location:** `lib/features/vehicle/data/repositories/vehicle_repository_impl.dart:61-68` مقابل `lib/features/vehicle/presentation/providers/vehicle_provider.dart:203-211`
- **Evidence:**
```dart
// vehicle_repository_impl.dart:60-69  (data)
  Future<Either<Failure, Vehicle?>> getSelectedVehicle() async {
    final listed = await getVehicles();
    return listed.fold((failure) => Left(failure), (vehicles) {
      for (final vehicle in vehicles) {
        if (vehicle.activeForCurrentDriver == true ||
            vehicle.selectedByServer == true) {
          return Right(vehicle);
        }
      }
      return const Right(null);
    });
  }
```
```dart
// vehicle_provider.dart:203-211  (presentation)
  Vehicle? _serverSelected(List<Vehicle> vehicles) {
    for (final vehicle in vehicles) {
      if (vehicle.activeForCurrentDriver == true ||
          vehicle.selectedByServer == true) {
        return vehicle;
      }
    }
    return null;
  }
```
- **Current behavior:** **نفس الحلقة تماماً** في data و presentation. مع ملاحظة أن `getSelectedVehicle()` في العقد **لا يُستدعى من أي مكان في `lib/`** (بحث شامل) ⇒ هو نفسه **كود ميت يكرّر** منطقاً حيّاً في presentation.
- **Why problematic:** (أ) نفس القاعدة (معيار «المركبة النشطة») في طبقتين. (ب) العقد الميت `getSelectedVehicle` يوحي بوجود مسار قراءة رسمي غير مستخدم. (ج) `VehicleState.copyWith` (سطر 50-52) بتحويل `clearSelected` له منطق غامض.
- **Violated principle:** DRY، Dead Code.
- **Current owner:** presentation (حي) + data (ميت).
- **Correct owner:** domain — `Vehicle? findServerSelected(List<Vehicle>)` في `vehicle_selection.dart`.
- **Consequences:** تعديل معيار التحديد في مكان واحد يجعل presentation ينحرف عن العقد.
- **Recommended correction:** استخراج الدالة في domain؛ `getSelectedVehicle()` في المستودع يستدعيها؛ presentation يستدعيها أيضاً.
- **Related files:** `vehicle/domain/vehicle_selection.dart`, `vehicle/domain/repositories/vehicle_repository.dart:13-14`, `vehicle/presentation/providers/vehicle_provider.dart:169-177`
- **Confidence:** **CONFIRMED**

---

## C. Cross-feature import table

| # | From → To | Path:line | ما هو المستورد | الحكم |
|---|---|---|---|---|
| 1 | DVIR → HOME | `dvir/presentation/providers/dvir_provider.dart:10` | `home/presentation/providers/dashboard_provider.dart` | **سليمة** — presentation→presentation (قراءة `vehicleId` فقط). ملاحظة: نفس الملف يستورد `trackingConfigStorageProvider` غير المستخدم (DST-017). الحكم: **مقبولة** (قراءة فقط) |
| 2 | DVIR → HOME (2) | `dvir/presentation/pages/dvir_form_page.dart:7` | نفس المزوّد | **مقبولة** |
| 3 | DVIR → HOME (3) | `dvir/presentation/widgets/dvir_form_sections.dart:9` | `DashboardData` | **مقبولة** |
| 4 | DVIR → SYNC | `dvir/data/repositories/dvir_repository_impl.dart:3` | `sync/domain/entities/pending_event.dart` | **سليمة** — data→**domain** الميزة الأخرى (عقد مشترك) |
| 5 | DVIR → SYNC (2) | `dvir/data/repositories/dvir_repository_impl.dart:4` | `sync/domain/repositories/offline_queue.dart` | **سليمة** — عقد Port |
| 6 | DVIR → SYNC (3) | `dvir/data/providers/dvir_repository_providers.dart:5` | `sync/data/providers/sync_providers.dart` | **مقبولة** — data→data لتركيب `offlineQueueProvider` (DI). لكن `sync_providers.dart` نفسه يحمل انحرافاته (DST-018) |
| 7 | DVIR → ACCOUNT | `dvir/presentation/pages/dvir_form_page.dart:8` | `account/presentation/providers/account_provider.dart` | **مقبولة** — presentation→presentation لقراءة `carrier` |
| 8 | DVIR → VEHICLE | `dvir/presentation/providers/dvir_provider.dart:11` | `vehicle/presentation/providers/vehicle_provider.dart` | **مقبولة** |
| 9 | DVIR → VEHICLE (2) | `dvir/presentation/pages/dvir_form_page.dart:10` | نفس المزوّد | **مقبولة** |
| 10 | DVIR → VEHICLE (3) | `dvir/presentation/pages/dvir_form_page.dart:32` | `vehicle/domain/entities/vehicle.dart` | **سليمة** — presentation→**domain** |
| 11 | DVIR → AUTH | `dvir/presentation/pages/dvir_form_page.dart:12` | `auth/presentation/providers/auth_state_provider.dart` | **مقبولة** — قراءة `currentDriverIdProvider` |
| 12 | DVIR → TRACKING | `dvir/presentation/pages/dvir_form_page.dart:9` | `tracking/presentation/providers/tracking_provider.dart` | **مقبولة** — قراءة `trackingStateProvider.currentLocation`؛ لكن **تركيب نص إحداثيات في Widget** (`dvir_form_page.dart:344-352`, `596-605`) = business formatting in presentation |
| 13 | DVIR → LOGS | `dvir/presentation/pages/dvir_form_page.dart:30-31` | `logs/presentation/widgets/vehicle_picker_dialog.dart`, `logs/presentation/pages/trailers_page.dart` | **مقبولة** — Widgets مشتركة بين الشاشات |
| 14 | INSPECTION → LOGS | `inspection/presentation/pages/send_logs_page.dart:10-11` | `logs/domain/entities/audit_entry.dart` + `logs/data/providers/log_repository_providers.dart` | **انحراف مؤكَّد** — presentation يستورد **data layer** لميزة أخرى (DST-021) |
| 15 | INSPECTION → SYNC | `inspection/data/repositories/inspection_repository_impl.dart:12` | `sync/domain/entities/pending_event.dart` | **مقبولة** — data→domain؛ لكن **تسييل حدث داخل مستودع** (use-case في data) |
| 16 | INSPECTION → SYNC (2) | `inspection/data/repositories/inspection_repository_impl.dart:13` | `sync/domain/usecases/sync_engine.dart` | **مقبولة** — استخدام use-case؛ لكن **بوسيط اختياري nullable** |
| 17 | INSPECTION → SYNC (3) | `inspection/data/providers/inspection_repository_providers.dart:4` | `sync/data/providers/sync_providers.dart` | **مقبولة** (DI) |
| 18 | INSPECTION → AUTH | `inspection/presentation/providers/inspection_provider.dart:7` | `auth/presentation/providers/auth_state_provider.dart` | **مقبولة** |
| 19 | INSPECTION → AUTH (2) | `inspection/presentation/providers/dot_inspection_providers.dart:5` | نفس المزوّد | **مقبولة** |
| 20 | INSPECTION → AUTH (3) | `inspection/presentation/pages/send_logs_page.dart:9` | نفس المزوّد | **مقبولة** |
| 21 | INSPECTION → LOGS (2) | `inspection/presentation/pages/send_logs_page.dart:10` | `audit_entry.dart` (domain) | **مقبولة** — كيان مشترك؛ لكن الإنشاء في Widget |
| 22 | SYNC → TRACKING | `sync/data/providers/sync_providers.dart:13` | `tracking/domain/entities/connection_status.dart` | **سليمة** — data→**domain** الميزة الأخرى (عقد مشترك) |
| 23 | SYNC → TRACKING (2) | `sync/data/providers/sync_providers.dart:12` | `core/events/eld_events_provider.dart` → يستورد بدوره `tracking/data/datasources/live_tracking_data_source.dart` | **انحراف مؤكَّد** — data→core→**data feature** (انقلاب اتجاه، DST-030) |
| 24 | SYNC → LOGS | `sync/data/providers/sync_providers.dart:8` | `logs/data/datasources/log_local_data_source.dart` مع `// ignore_architecture` | **انحراف مؤكَّد** — data→data لـ feature أخرى مع suppression (DST-018) |
| 25 | SYNC → AUTH | `sync/data/providers/sync_providers.dart:7` | `auth/presentation/providers/auth_state_provider.dart` مع `// ignore_architecture` | **انحراف مؤكَّد** — data→**presentation** (DST-018) |
| 26 | SYNC → DVIR (عكسي) | `sync/data/repositories/traccar_remote_event_dispatcher.dart:12` | `backend/contracts/dvir_backend.dart` | **سليمة** — data→عقد backend مشترك (shared kernel)، لا تنفيذ feature |
| 27 | SYNC → INSPECTION (عكسي) | `sync/data/repositories/traccar_remote_event_dispatcher.dart:13` | `backend/contracts/inspection_backend.dart` | **سليمة** — عقد backend مشترك |
| 28 | SYNC → AUTH (2) | `sync/data/repositories/traccar_remote_event_dispatcher.dart:16` | `auth/data/datasources/auth_local_data_source.dart` | **مقبولة** — data→data (عقد مخزن)، لكن `getSession()` قراءة مباشرة بدل بوابة |
| 29 | TRACKING → (core) | `sync/data/providers/sync_providers.dart:13` | — | (مغطى في #23) |
| 30 | VEHICLE → AUTH | `vehicle/presentation/providers/vehicle_provider.dart:6` | `auth/presentation/providers/auth_state_provider.dart` | **مقبولة** — `ref.listen(authStateProvider)`Implementing سياج الجلسة؛ **نمط ممتاز** |
| 31 | VEHICLE → HOME | `vehicle/presentation/pages/select_vehicle_page.dart:10` | `home/presentation/providers/dashboard_provider.dart` | **مقبولة** مع DST-019 |
| 32 | VEHICLE → HOME (2) | `vehicle/presentation/pages/select_vehicle_page.dart:9` | `home/presentation/widgets/eld_drawer.dart` | **سليمة** — widget مشترك |
| 33 | VEHICLE → TRACKING | `vehicle/presentation/pages/select_vehicle_page.dart:15` | `tracking/presentation/providers/tracking_provider.dart` | **مقبولة** — قراءة `currentVehicleSpeedProvider` و`trackingStateProvider.isTracking` |
| 34 | VEHICLE → HOS | `vehicle/presentation/pages/select_vehicle_page.dart:14` | `hos/presentation/providers/hos_engine_provider.dart` | **مقبولة** — قراءة `movingSpeedThresholdKmh`؛ لكن **العتبة يجب أن تأتي من domain لا presentation** |
| 35 | TRACKING → CORE | `tracking/presentation/providers/tracking_providers.dart:2` | `package:geolocator/geolocator.dart` | **مقبولة** — StreamProvider لحالة GPS؛ لكن **الاستعلام عن المنصة في presentation** (يُفترض أن يكون في data) |

**ملاحظة على الأحكام:** أربعة استثناءات **مؤكدة** (الصفوف 14، 23، 24، 25)، والباقي **مقبولة** لأن اتجاهها presentation→presentation أو data→domain مع عقد مشترك. الحافة **الأخطر** في المجموعة هي `SYNC → AUTH` (data→presentation مع suppression).

---

## D. Exhaustive list of files read (proof of coverage)

**dvir — 25 files (100%):**
1. `lib/features/dvir/data/mappers/dvir_defect_mappers.dart` (91)
2. `lib/features/dvir/data/mappers/dvir_mappers.dart` (208)
3. `lib/features/dvir/data/providers/dvir_repository_providers.dart` (17)
4. `lib/features/dvir/data/repositories/dvir_repository_impl.dart` (388)
5. `lib/features/dvir/domain/defect_enums.dart` (37)
6. `lib/features/dvir/domain/dvir_catalog.dart` (64)
7. `lib/features/dvir/domain/dvir_list_summary.dart` (33)
8. `lib/features/dvir/domain/dvir_signature.dart` (9)
9. `lib/features/dvir/domain/dvir_vehicle.dart` (8)
10. `lib/features/dvir/domain/entities/dvir_defect.dart` (73)
11. `lib/features/dvir/domain/entities/dvir_report.dart` (266)
12. `lib/features/dvir/domain/repositories/dvir_repository.dart` (43)
13. `lib/features/dvir/presentation/extensions/dvir_catalog_extensions.dart` (9)
14. `lib/features/dvir/presentation/extensions/dvir_status_extensions.dart` (37)
15. `lib/features/dvir/presentation/pages/dvir_detail_page.dart` (486)
16. `lib/features/dvir/presentation/pages/dvir_form_page.dart` (690)
17. `lib/features/dvir/presentation/pages/dvir_list_page.dart` (340)
18. `lib/features/dvir/presentation/providers/dvir_provider.dart` (325)
19. `lib/features/dvir/presentation/widgets/active_defects_section.dart` (257)
20. `lib/features/dvir/presentation/widgets/defect_card.dart` (58)
21. `lib/features/dvir/presentation/widgets/defects_modal.dart` (153)
22. `lib/features/dvir/presentation/widgets/dvir_form_components.dart` (199)
23. `lib/features/dvir/presentation/widgets/dvir_form_sections.dart` (498)
24. `lib/features/dvir/presentation/widgets/previous_dvir_review_modal.dart` (74)
25. `lib/features/dvir/presentation/widgets/status_modal.dart` (81)

**inspection — 15 files (100%):**
1. `lib/features/inspection/data/mappers/inspection_mappers.dart` (120)
2. `lib/features/inspection/data/providers/inspection_repository_providers.dart` (15)
3. `lib/features/inspection/data/repositories/inspection_repository_impl.dart` (266)
4. `lib/features/inspection/data/services/fmcsa_eld_output_generator.dart` (208)
5. `lib/features/inspection/domain/inspection_transfer.dart` (58)
6. `lib/features/inspection/domain/transfer_audit.dart` (31)
7. `lib/features/inspection/domain/repositories/inspection_repository.dart` (43)
8. `lib/features/inspection/presentation/pages/dot_inspection_page.dart` (73)
9. `lib/features/inspection/presentation/pages/inspection_active_view.dart` (145)
10. `lib/features/inspection/presentation/pages/inspection_start_view.dart` (210)
11. `lib/features/inspection/presentation/pages/send_logs_page.dart` (332)
12. `lib/features/inspection/presentation/providers/dot_inspection_providers.dart` (60)
13. `lib/features/inspection/presentation/providers/inspection_provider.dart` (367)
14. `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart` (176)
15. `lib/features/inspection/presentation/widgets/inspection_log_header_table.dart` (259)

**sync — 18 files (100%):**
1. `lib/features/sync/data/datasources/sync_local_data_source.dart` (60)
2. `lib/features/sync/data/models/sync_item_model.dart` (56)
3. `lib/features/sync/data/providers/sync_providers.dart` (148)
4. `lib/features/sync/data/repositories/memory_offline_queue.dart` (145)
5. `lib/features/sync/data/repositories/sqlite_offline_queue.dart` (382)
6. `lib/features/sync/data/repositories/sync_repository_impl.dart` (156)
7. `lib/features/sync/data/repositories/traccar_remote_event_dispatcher.dart` (322)
8. `lib/features/sync/domain/entities/dispatch_auth.dart` (19)
9. `lib/features/sync/domain/entities/event_ownership.dart` (109)
10. `lib/features/sync/domain/entities/pending_event.dart` (72)
11. `lib/features/sync/domain/entities/quarantine_record.dart` (41)
12. `lib/features/sync/domain/entities/sync_item.dart` (100)
13. `lib/features/sync/domain/repositories/offline_queue.dart` (49)
14. `lib/features/sync/domain/repositories/sync_repository.dart` (25)
15. `lib/features/sync/domain/usecases/sync_engine.dart` (226)
16. `lib/features/sync/presentation/providers/sync_engine_provider.dart` (4)
17. `lib/features/sync/presentation/providers/sync_provider.dart` (76)
18. `lib/features/sync/presentation/widgets/sync_status_indicator.dart` (46)

**tracking — 25 files (100%):**
1. `lib/features/tracking/data/datasources/live_tracking_data_source.dart` (168)
2. `lib/features/tracking/data/datasources/native_event_channel_client.dart` (164)
3. `lib/features/tracking/data/datasources/traccar_data_source.dart` (135)
4. `lib/features/tracking/data/datasources/tracking_data_source.dart` (26)
5. `lib/features/tracking/data/datasources/tracking_local_data_source.dart` (69)
6. `lib/features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart` (30)
7. `lib/features/tracking/data/datasources/traccar_sdk/traccar_api_client.dart` (19)
8. `lib/features/tracking/data/datasources/traccar_sdk/traccar_api_client_impl.dart` (131)
9. `lib/features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart` (24)
10. `lib/features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart` (79)
11. `lib/features/tracking/data/datasources/traccar_sdk/traccar_websocket_client.dart` (21)
12. `lib/features/tracking/data/datasources/traccar_sdk/traccar_websocket_client_impl.dart` (156)
13. `lib/features/tracking/data/models/location_model.dart` (59)
14. `lib/features/tracking/data/providers/tracking_providers.dart` (51)
15. `lib/features/tracking/data/repositories/tracking_repository_impl.dart` (243)
16. `lib/features/tracking/data/services/tracking_service.dart` (204)
17. `lib/features/tracking/domain/entities/connection_status.dart` (8)
18. `lib/features/tracking/domain/entities/location_entity.dart` (141)
19. `lib/features/tracking/domain/entities/native_location_event.dart` (75)
20. `lib/features/tracking/domain/entities/tracking_event.dart` (98)
21. `lib/features/tracking/domain/repositories/tracking_data_source_port.dart` (8)
22. `lib/features/tracking/domain/repositories/tracking_repository.dart` (36)
23. `lib/features/tracking/domain/usecases/tracking_event_processor.dart` (124)
24. `lib/features/tracking/presentation/providers/tracking_provider.dart` (252)
25. `lib/features/tracking/presentation/providers/tracking_providers.dart` (15)

**vehicle — 8 files (100%):**
1. `lib/features/vehicle/data/providers/vehicle_repository_providers.dart` (23)
2. `lib/features/vehicle/data/repositories/vehicle_repository_impl.dart` (81)
3. `lib/features/vehicle/domain/vehicle_selection.dart` (153)
4. `lib/features/vehicle/domain/entities/vehicle.dart` (68)
5. `lib/features/vehicle/domain/repositories/vehicle_repository.dart` (15)
6. `lib/features/vehicle/presentation/pages/select_vehicle_page.dart` (299)
7. `lib/features/vehicle/presentation/providers/vehicle_provider.dart` (254)
8. `lib/features/vehicle/presentation/widget/vehicle_card.dart` (124)

**الإجمالي: 91 ملف — تم استيعاب كل واحد.**

---

## ملخص تنفيذي

| Level | Issue IDs | Count |
|---|---|---|
| **Critical** | DST-001, DST-002 | 2 |
| **High** | DST-003, DST-005, DST-006, DST-018, DST-021, DST-025, DST-027, DST-030, DST-032, DST-035, DST-037, DST-038 | 12 |
| **Medium** | DST-004, DST-005b, DST-007, DST-008, DST-010, DST-011, DST-012, DST-013, DST-014, DST-016, DST-020, DST-021, DST-022, DST-023, DST-026, DST-028, DST-029, DST-031, DST-034, DST-035, DST-039, DST-040, DST-044, DST-045, DST-047 | 25 |
| **Low** | DST-009, DST-015, DST-017, DST-019, DST-024, DST-033, DST-041, DST-042, DST-043, DST-046 | 10 |

**أسوأ ثلاث نقاط في المجموعة:**
1. **DST-001** — اختراع `deviceId` قانوني من regex داخل Widget DVIR.
2. **DST-002** — كاش `static` في مستودع التفتيش بلا إبطال ⇒ تسريب سجلات بين جلسات السائقين.
3. **DST-035 + DST-025** — ابتلاع الأخطاء عبر ثلاث طبقات يعرض «فارغ» بينما المنصة فشلت، **مع منظومة طابور ثانية مكرَّرة لا تمثّل الإنتاج**.

**الملاحظات الإيجابية (نماذج صالحة داخل المشروع):**
- `sync/domain/repositories/offline_queue.dart` — عقد نقي بلا تسريب sqflite (نموذج مرجعي).
- `sync/domain/entities/event_ownership.dart` — استخراج ملكية pure في domain.
- `dvir/domain/entities/dvir_report.dart` — قواعد §396.11 retention و out-of-service في مكانها الصحيح.
- `vehicle/presentation/providers/vehicle_provider.dart` — سياج session + تسلسل ردود متأخر (نموذج لتعميمه على `InspectionRepositoryImpl`).
- `dvir/data/mappers/dvir_defect_mappers.dart` — mapper نقي بلا اختراع قيم.