# 01 — جرد الأدلة (Evidence Inventory)

> لكل سبب من RC-A إلى RC-H: النتائج الداعمة، الملفات الدقيقة، الأدلة الشيفرية، الحواف، المسؤوليات، العواقب المؤكدة، الافتراضات غير المتحقق منها، والأدلة المعارضة.
> كل non-trivial ادعاء أدناه تم التحقق منه مقابل الشجرة الحالية في هذه المهمة.

## RC-A — تشتت حقن الاعتماديات

| البند | المحتوى |
|---|---|
| النتائج الداعمة | CORE-005، DST-037، CORE-031، ACC-001 (جزئياً) |
| الملفات الدقيقة | `lib/core/di/app_providers.dart` (25 سطراً)؛ `lib/features/tracking/data/services/tracking_service.dart:200`؛ `lib/features/tracking/data/providers/tracking_providers.dart:22,41`؛ `lib/app/app_initializer.dart:91`؛ `lib/features/account/application/usecases/update_rules_use_case.dart:52-61`؛ `lib/backend/providers/backend_providers.dart` (99) + `backend_network_providers.dart` (70) |
| أدلة شيفرية | `trackingServiceProvider` و`trackingServiceFullProvider` جسدان متطابقان حرفياً؛ `app_initializer.dart:91` يتجاوز الأول بينما `tracking_providers.dart:41` يستهلك الثاني؛ `traccarAuthRepositoryProvider` المستودع الوحيد في "الجذر" المزعوم |
| الحواف | `app → trackingServiceProvider (override)`؛ `tracking_providers → trackingServiceFullProvider (watch)`؛ `quick_actions_initializer → trackingServiceProvider (read)` |
| المسؤوليات | التركيب، اختيار المثيل، دورة الحياة |
| العواقب المؤكدة | مثيلان حيان من `TrackingService` بحالتين منفصلتين؛ تجاوز الإقلاع لا يسري على المستودع |
| افتراضات غير متحقق منها | هل ظهرت أعراض ميدانية من الازدواج (مقابل خطر نظري) — UNKNOWN |
| أدلة معارضة | `backend_providers` اختيار المحوّل فيها مركزي ومتماسك فعلاً؛ مزودات `data/providers` لكل ميزة نمط Riverpod شائع وليس فوضى بالضرورة |

## RC-B — نماذج بلا مالك

| البند | المحتوى |
|---|---|
| النتائج الداعمة | CORE-001، CORE-002، BACK-002، ACC-008، HOM-001، CUI-001، DST-030 |
| الملفات الدقيقة | `lib/core/providers/driver_rules_provider.dart` (كاملاً: 22 سطراً)؛ `lib/core/events/eld_events_provider.dart:3,5`؛ `lib/core/widgets/connection_status_indicator.dart:7`؛ `lib/backend/contracts/rules_screen_backend.dart:3` (+ mapper/eld/mock)؛ `lib/features/home/presentation/widgets/eld_drawer.dart`؛ `lib/routes.dart` (`rootNavigatorKey:63`) |
| أدلة شيفرية | `driverRulesProvider` يراقب `rulesScreenProvider` ويشتق `DriverRules` (اشتقاق نقي من 3 حقول)؛ `connection_status_indicator:39` يستخدم `AppRoutes.connection` (ملاحة، لا المفتاح العام)؛ `rootNavigatorKey` لا يستخدمه إلا `app.dart:55` و`routes.dart:63,70` و`push_notification_service:115,123` |
| الحواف | 7 حواف `core→features` + 9 حواف `backend→features` (مقاسة fresh، تطابق التدقيق بعد تصحيح عدّه من 6) |
| المسؤوليات | تعريف الأنواع المشتركة، تصديرها، استهلاكها |
| العواقب المؤكدة | أي نقل لنموذج يكسر مستوردين في 3 طبقات؛ `core` غير قابل للاستخراج مستقلاً |
| افتراضات غير متحقق منها | أن توحيد المالك سيزيل الحواف (مقابل إعادة توزيعها) |
| أدلة معارضة | `DriverResponse.id` في العقد مثال على نموذج مشترك **موثّق جيداً**؛ `AppRoutes` في `routes.dart` مالك صحيح لثوابت الملاحة |

## RC-C — دورة التوجيه

| البند | المحتوى |
|---|---|
| النتائج الداعمة | HOM-003، ROU-001، CUI-001 (عضوية) |
| الملفات الدقيقة | `lib/routes.dart` (يستورد 5 ملفات توجيه + `auth_state_provider`)؛ `lib/routes/*_routes.dart` (تستورد الصفحات)؛ 7 صفحات/ودجات تستورد `routes.dart`؛ `home_page.dart ↔ driving_lock_screen.dart` (تبادل مباشر) |
| أدلة شيفرية | `routes.dart → home_routes.dart → home_page.dart → routes.dart` (دورة دنيا)؛ `home_provider.dart` يستورد `routes.dart` ويبني 10 وجهات `AppRoutes.*`؛ `RouterNotifier` يستمع `authStateProvider` |
| الحواف | SCC من 25 ملفاً (Tarjan على الشجرة الحالية) |
| المسؤوليات | تسجيل المسارات، حراسة التوجيه (`redirect`)، ثوابت الملاحة، المفتاح العام |
| العواقب المؤكدة | استحالة تحميل/اختبار أي صفحة من الـ17 بمعزل عن الشجرة الكاملة |
| افتراضات غير متحقق منها | كلفة الكسر الفعلية (تقديرية: نقل المفتاح + تحديث 7 مستوردين) |
| أدلة معارضة | الدورة **حميدة وقت التشغيل** (Dart يتحملها)؛ لا عطل إنتاجي موثّق منها |

## RC-D — سياج الجلسات المبعثر

| البند | المحتوى |
|---|---|
| النتائج الداعمة | COD-001، HL-31، BACK-031، DST-002 (قبل الإصلاح) |
| الملفات الدقيقة | `lib/core/session/session_epoch.dart` (31 سطراً)؛ `auth_state_provider.dart:140-151,175-324` (`_operationId`، `_storageChain`، `bump()`)؛ `account_provider:36-63` ≈ `codriver_provider:98-132` (نسخ)؛ `codriver_provider:186-237` (`switchDrivers`/`_refreshCurrent` **بلا سياج**)؛ 4 عقود تحمل `expectedOwnerDriverId?`؛ `auth_interceptor` (سياج `gf_expected_owner`) |
| أدلة شيفرية | `SessionEpoch.bump()` عند login/logout/forceLogout فقط (موثّق)؛ `if (!_isCurrent(seq, owner, epoch)) return;` بعد كل `await` في `_loadDrivers` مقابل غيابه في `switchDrivers` |
| الحواف | `auth_interceptor → auth_local_data_source + auth_session`؛ مزودات تراقب `authStateProvider`/`sessionEpochProvider` |
| المسؤوليات | عزل الهوية عبر الزمن، إبطال الاستجابات المتأخرة، ربط الطابور بالمالك |
| العواقب المؤكدة | COD-001 المتبقي (`static` بلا إبطال)؛ تغطية جزئية (dashboard/dvir/logs بلا سياج) |
| افتراضات غير متحقق منها | أن التوحيد سيقلل العيوب (مقابل أن التبعثر الحالي يعمل لمعظم المسارات) |
| أدلة معارضة | آلية `SessionEpoch` نفسها مصممة جيداً وموثقة؛ الإصلاح EC-0.2a أثبت قابلية التوسيع (20 اختباراً) |

## RC-E — العرض كطبقة تطبيق

| البند | المحتوى |
|---|---|
| النتائج الداعمة | عناقيد HL/DST/CON، AUTH-004/005، HL-24/HL-34، DST-003/006، CON-001/003 |
| الملفات الدقيقة | `team_status_provider.dart:16-35` (عمليتان + `json['data']`)؛ `hardware_status_provider.dart` (mapping + `FormatException`)؛ `dvir_form_page.dart:440-476`؛ `change_status_provider.dart:273-359` (`submit`)؛ `hos_provider.dart:85-134` (`changeStatus`)؛ `unidentified_events_provider.dart:97,136`؛ `eld_connection_page.dart:27-248` (Notifier في ملف صفحة) |
| أدلة شيفرية | `ref.read(unidentifiedEventsBackendProvider)` داخل provider عرض؛ `previousToReview` (قاعدة §396.13) داخل كائن حالة؛ `Duration(hours:11)` داخل `build` |
| الحواف | 14 حافة pres→backend (9 عقود + 3 مباشرة + 2 تنفيذ)؛ 5 كتابات عابرة في `dashboardDataProvider` |
| المسؤوليات | التنسيق، التحقق، الحل، التحويل، الكتابة العابرة |
| العواقب المؤكدة | منطق FMCSA مكرر بين provider ومحرك؛ اختبار الأعمال يتطلب Riverpod كاملاً |
| افتراضات غير متحقق منها | أن طبقة تطبيق منفصلة ستمتص هذا فعلاً (مقابل أن Riverpod يشجع هذا التموضع) |
| أدلة معارضة | `hosStatusProvider` تركيب (محرك+متتبع) نمط Riverpod مشروع؛ `dvirCatalogProvider` (keepAlive+dispose) إدارة دورة حياة سليمة |

## RC-F — شكل الـ wire الموزّع

| البند | المحتوى |
|---|---|
| النتائج الداعمة | BACK-008, BACK-006/007, COD-006, HL-18, DST-012, BACK-015/026, DST-004 |
| الملفات الدقيقة | `backend/contracts/raw_json.dart:10` (`typedef RawJson = Map<String, dynamic>`)؛ `mock_dvir_backend.dart:20` مقابل `dvir_repository_impl.dart:54`؛ `vehicle_selection.dart:52-153`؛ `team_status_provider:26-32`؛ `_asMap` ×5؛ تطبيع URL ×3؛ `log_repository_impl → certify_dto`؛ `dvir_repo → dvir_dto` |
| أدلة شيفرية | `{'reports': []}` مقابل `rawJson['data']` (فشل صامت)؛ `json['driver']?['id']` عبر `asInt(fallback: 0)` يمحو التمييز بين "مفقود" و"صفر" |
| الحواف | 33 مستورداً لـ `raw_json` (backend كله + مستودعان)؛ **صفر** في `domain` |
| المسؤوليات | التطبيع، التحليل، التعيين، التحقق الشكلي |
| العواقب المؤكدة | إخفاقات صامتة؛ تحليل مكرر؛ DTO المحوّل مستورد مباشرة |
| افتراضات غير متحقق منها | أن مخططات صارمة ستُعتمد من الخادم فعلاً (العقد يوثّق `driver` لكن `id` ليس `required`) |
| أدلة معارضة | مخططات `eld_engine` نفسها عالية الجودة وموثقة؛ `openapi.yaml` يوثّق `driver → DriverResponse` |

## RC-G — قناة الأخطاء النصية

| البند | المحتوى |
|---|---|
| النتائج الداعمة | ACC-003/004, HL-22/33, COD-003, RC-1 (الأخطر) |
| الملفات الدقيقة | `duty_status_tracker.dart:370-374` (تخمين `isNetwork`)؛ `rules_screen_provider.dart:22` (`throw Exception(l10nKey)`)؛ `user_facing_message.dart:7-25` (الهبوط)؛ `account_provider:90,95,119,130` + `account_page:98-102` (عرض خام)؛ 17 موقع `failure.message` في الحالة |
| أدلة شيفرية | `error.code.contains('network') || ... || error.context?['statusCode'] == null`؛ `Expected: 'server_rejected', Actual: <null>` (اختبار مُشغَّل: 14✅/1❌) |
| الحواف | لا حواف استيراد مميزة — القناة **نوعية** لا بنيوية (تمر عبر `Failure.message: String`) |
| المسؤوليات | التصنيف، التحويل للعرض، التخزين في الحالة |
| العواقب المؤكدة | رفض خادم يُطبَّق محلياً (انحراف سجل قانوني)؛ رسائل مضللة ("شبكة" لكل شيء) |
| افتراضات غير متحقق منها | مدى انتشار التخمين النصي خارج `duty_status_tracker` (عينة واحدة مؤكدة) |
| أدلة معارضة | `anyErrorUserMessage` كبوابة عرض تصميمها صحيح (المشكلة الالتفاف حولها)؛ `_isSafeUserFacingText` يمنع تسرب PII |

## RC-H — غياب الإنفاذ

| البند | المحتوى |
|---|---|
| النتائج الداعمة | CORE-004, DOM-005 (نفس العائلة) |
| الملفات الدقيقة | `analysis_options.yaml` (بلا قواعد بنيوية)؛ 19 علامة في 13 ملفاً (4 rules_screen + 2 interceptor + 3 network + 3+1 di + 1 api_client + 1 error_mapper + 1 transformer + 1 server_config_store + 2 sync)؛ `backend_registry.dart` (129 سطراً) + مزوده (اختبار فقط)؛ `api_config.dart` الخلفي معلّق بالكامل؛ 3 use-cases تمريرية (12-15 سطراً) |
| أدلة شيفرية | `flutter analyze lib/backend` ⇒ `No issues found!` رغم 6+ حواف عابرة؛ `BackendRegistry.single(...)` لا يستهلكه إنتاج |
| الحواف | لا شيء — الغياب نفسه هو الدليل |
| المسؤوليات | (مفقودة) حراسة الحدود، منع التراكم الميت |
| العواقب المؤكدة | تراكم تجريدات شكلية؛ انتهاكات مُعلَّنة بلا كلفة |
| افتراضات غير متحقق منها | أن الإنفاذ وحده كان سيمنع الانجراف (مقابل ضغط التسليم) |
| أدلة معارضة | الفريق **يعلن** الانتهاكات (`ignore_architecture` + تعليقات P0/SRS) — الوعي موجود والآلية غائبة |
