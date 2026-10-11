# 08 — SOLID وجودة الكود

## القراءة الصحيحة لحجم الملفات

المشروع يحتوي **53 ملفاً** يتجاوز 200 سطراً، و**11 ملفاً** يتجاوز 400 سطراً، من أصل 399 ملف. لكن الطول وحده ليس مخالفة. القاعدة المتبنّاة:

| الملف | الحكم |
|---|---|
| `core/error/app_error.dart` (504) | **ليس** حزمة مهملات — 14 نوع خطأ متماسكة. عيوبه: 3 أنواع لا تُنشأ أبداً (CORE-009) وتعارض مع `Failure` (CORE-010). |
| `backend/adapters/eld_engine/models/dvir_dto.dart` (402) | **ليس مشتتاً** — DTOات متماسكة لميزة واحدة. تقسيمها سيزيد التشظير. |
| `features/hos/domain/engine/tracking/duty_status_tracker.dart` (494) | **حجمه مشروع** — لكنه يحمل 7 أسباب للتغيير (انظر S أدناه). |
| `features/vehicle/domain/vehicle_selection.dart` (142) | **مخالف رغم قصره** — فيه HTTP و JSON في domain. |
| `features/connection/presentation/mac_address_validation.dart` (12) | **سليم** — يأخذ `AppLocalizations` فلا يمكن أن يكون في domain. |

> القاعدة المستخرجة: أضيق ملف في المشروع (`mac_address_validation.dart`، 12 سطراً) كان موضعاً لتساؤل طبقي؛ وأكبر ملف (`app_error.dart`) كان سليم معمارياً. **الحجم لا يقيس النضج المعماري.**

## S — Single Responsibility

| الصنف | أسباب التغيير القابلة للعد | الحكم |
|---|---|---|
| `DutyStatusTracker` (hos/domain) | تتبّع الحالة، بناء حمولة شبكة، تمييز الخطأ الشبكي بنصه، قراءة Hive، توليد `uuid`، حال�� «مركبة متحركة»، إحصاءات | **7** — SRP مخالفة |
| `AuthStateNotifier` (auth/presentation) | سياسات حدود الهوية، ترتيب التخزين، تحويل الخطأ، تسجيل الخروج، إبطال المزوّدات | **5** — SRP مخالفة |
| `auth_state_provider.dart` (293) | أكبر ملف presentation في المشروع ويقابل 3 use-casesهشّة (AUTH-002) | SRP مخالفة |
| `tracking_repository_impl.dart` (222) | مصدران للموقع، إذن، تتبّع صنف، تحويل | 4 — مخالفة (DST-039) |
| `LogRepositoryImpl` (501) | reading + writing + mapping + Hive | مسموح لمستودع |
| `TrackingOrchestrator` | تنسيق + سياسات HTTP + حدود تنظيمية (CORE-025) | SRP مخالفة في `Provider<void>` |

## O — Open/Closed

كل مثال مؤكد هو **تكرار قاعدة** لا تكرار صنف:

- حدّ HOS التنظيمي: **مكانان بقيم متطابقة يدوياً** (CORE-022: `hos_configuration.dart:25-50` و `fmcsa_constants.dart:18-34`).
- قيد HOS رقمي: **9 مواقع** خارج الإعداد المركزي، منها قيم **مُختلقة** (`35` دقيقة، `2:08`) داخل مستودع بيانات تُعرض كوقت قانوني (HL-03).
- DVIR-09: **ثلاث نسخ** (widget + data + data) — DST-006.
- قاعدة اختيار المركبة: **ثلاث نسخ** (domain معطّلة + data + presentation) — DST-047.
- تطبيع رموز الحالات الخمسة: **5 خرائط** داخل presentation — HL-34، وHL-24 (**5 مواقع أخرى**).
- تنسيق الوقت والمدة: **7 نقاط** — HL-26.
- قواعد HOS التنظيمية: خريطة في domain (HL-14 ×3).

كل إضافة لقاعدة FMCSA جديدة تتطلب اليوم تعديل **7–9 ملفات**. هذا هو الثمن الحقيقي، لا عدد الملفات.

## L — Liskov Substitution

| العقد | Yank | الحكم |
|---|---|---|
| `MockDailyLogsBackend` | **مُجبر** على استيراد DTOات `eld_engine` عبر توقيع العقد (BACK-004) | **مخالفة LSP مؤكدة** — الموك ليس بديلاً، بل عميل لنوع belongs للمحوّل |
| `RawJson` في العقد | يصل إلى domain وpresentation | التسريب كسر الاستبدال: أي تغيير في شكل الخادم يمسّ كل الطبقات |
| `DvirBackend` | mock يعيد `{'reports': []}` والمحرك يعيد `{'data': ...}` (BACK-008) | **مخالفة صامتة** — التوقيع واحد، الدلالة مختلفة |
| `UnidentifiedEventsBackend` | 0 من 3 منفّذة في الموك | فشل صامت لا استثناء |
| 22 من 58 دالة عقد (38%) | `throw UnimplementedError` | العقد لا يمكن استبداله في الاختبار |

## I — Interface Segregation

- `BackendAdapter` (BACK-025): nullable + تحويل `null` إلى `StateError` في **13 مزوّداً**. كل مزوّد يتعامل مع عقد اختياري — العقد قيل too broad.
- `SignatureBackend`: عقدة **ميتة بالكامل** — لا مزوّد ولا مستهلك (BACK-013).
- `BackendRegistry` (129 سطراً): **7 أعضاء بلا أي مستهلك إنتاجي** (BACK-027). تجريد زائد.
- `AppError` (14 نوعاً): 3 أنواع **لا تُنشأ أبداً** (CORE-009) — ثقل ميت على كل مُعالِج.

## D — Dependency Inversion

| الموقع | التفصيل |
|---|---|
| `duty_status_tracker.dart:5` | domain يستورد `LocalStorageService` (بنية تحتية) |
| `duty_status_tracker.dart:4` | domain يستورد عقد feature أخرى |
| `duty_status_tracker.dart:13` | domain يستورد عقد backend |
| `vehicle_selection.dart:52-119` | domain ينفّذ HTTP |
| `core/providers/driver_rules_provider.dart:2` | `core` يراقب presentation |
| `core/events/eld_events_provider.dart:3` | `core` يستورد data source من feature |
| `core/di/app_providers.dart:10` | `core` يستورد تنفيذ feature |
| `tracking_repository_impl.dart:50-80` | data يدير تدفّق صلاحيات النظام |
| `rules_page.dart:13` | presentation يستورد DTO من `backend/adapters` |
| `hos_rules_engine.dart:85-87` | domain يُرجع `ServerFailure` |

## التكرار الهيكلي (لا يوصى باستخراجه دائماً)

**مكرر يستحق الاستخراج**: `EldRetryView` مستخدم في **7 مواضع** بـ **6 ملفات**؛ `CircularProgressIndicator` في **12 ملفاً**؛ `BottomNavigationBar` بنسختين متطابقتين — كلها **نفس المسؤولية** وتتر一成 معاً (HL-41).

**لا يُوصى بالاستخراج**: `TrailersPage` و`ShippingDocumentsPage` نسختان متطابقتان (HL-27) لكنهما يبدو نفس المسؤولية — قرار واحد يصلح لهما معاً، فالاستخراج هنا **مبرر**.

**مكرر لا يوصى باستخراجه**: `dvir_dto.dart` (432 سطراً) — DTOات cohesive. والتعليق الذي اقترح تقسيمه **رُفض**، وهذا صحيح.

## الشيفرة الميتة المرصودة

| العنصر | الدليل |
|---|---|
| `refreshTokenKey` | `app_constants.dart:28` — ميت، ولا يوجد تدفّق refresh أصلاً |
| `UtcSyncService` | CORE-023: بنية ميتة، لا مرجع خادمي ولا مستهلك |
| `BackendRegistry` (7 أعضاء) | BACK-027 |
| `SignatureBackend` | BACK-013 |
| `accountProfileFixture` (21 سطراً) | BACK-016 |
| `api_config.dart` / `api_response.dart` في backend | BACK-028 — ملفّان ميتان |
| `refuseVehicleOperate` | domain، لا يُستدعى؛ presentation يعيد تنفيذه بفحوص أضعف |
| `isValidInspectionPin` + ثابت `days: 8` | DST-015 |
| `@override` يتيم | BACK-017 |
| 4 أقسام في `InstructionsPage` | 3 منها غير قابلة للوصول (ROU-002) |

## ثابت يُطبَّق بـ `assert()` (DST-024)

```dart
// sqlite_offline_queue.dart:265-268  (والمكرر في memory_offline_queue.dart:86-89)
```
قاعدة عمل داخل طبقة data، مُطبَّقة بـ `assert()` — أي **تختفي في الإنتاج** لأن Dart يُلغي `assert` في release. قاعدة يجب أن تُنفَّذ، لا أن تُتحقق في التطوير.

## فجوات قابلية الاختبار

| الفجوة | الأثر |
|---|---|
| `core/network/core_providers.dart` ↔ `backend_network_providers.dart` | اختبار `core/network` يتطلب fake backend |
| `MockDailyLogsBackend` مقيّد بـ DTOات | لا يمكن بناء mock مستقل |
| 22 دالة عقد غير منفّذة | لا يمكن اختبار 38% من العقد |
| `_ref` اختياري في `logs_provider` | الكتابة العابرة تتوقف بصمت |
| لا قاعدة lint معمارية | 19 علامة `// ignore_architecture` **زخرفية** — بلا أي آلية إنفاذ |

## جدول تفصيلي
tmp

**عدد الملاحظات في هذا القسم: 52**

--------------------------------------------------
### ISSUE BACK-003: `// ignore_architecture` تعليق تزييني بلا أي آلية إنفاذ
- **Severity:** MEDIUM
- **Category:** Maintainability
- **Location:** `lib/backend/contracts/rules_screen_backend.dart:3` (و6 مواضع أخرى)
- **Evidence:**
```yaml
# analysis_options.yaml:18-20
include: package:flutter_lints/flutter.yaml

linter:
  # The lint rules applied to this project can be customized in the
```
و:
```dart
// lib/backend/contracts/rules_screen_backend.dart:3
import '../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
```
- **السلوك الحالي:** تحققت عمليًا: `flutter analyze lib/backend` ⇒ `No issues found!`. لا يوجد lint باسم `ignore_architecture` في `flutter_lints` ولا مضاف في `linter.rules` (المكان مذكور فقط كتعليق توضيحي، ولم يُفعَّل أي قاعدة).
- **لماذا هو مشكل:** تعليق يُقرأ كـ«هذا الاستيراد مسموح استثناءً موثّقًا» بينما هو **تعليق لا يفعل شيئًا** إطلاقًا. 9 occurrences في `lib/backend/` وحده. النتيجة: انطباع زائف بأن الحد المعماري مُراقَب، بينما كسره مجاني.
- **المبدأ المنتهك:** Defense in Depth / Governance.
- **المالك الحالي / الصحيح:** سجل استثناءات حقيقي (`docs/architecture_exceptions.md` مُراجَع من المالك) + custom lint عبر `custom_lint` و`arch_lints`.
- **العواقب:** كل «استثناء معتمد» في المشروع غير قابل للتدقيق ولا للتصحيح.
- **الملفات المرتبطة:** `analysis_options.yaml`، كل ملفات `lib/backend/**` الحاملة للتعليق
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-013: عقدة `SignatureBackend` ميتة بالكامل — لا مزوّد ولا مستهلك
- **Severity:** MEDIUM
- **Category:** Maintainability
- **Location:** `lib/backend/providers/backend_providers.dart:59-117`
- **Evidence:** التعداد الفعلي للمزوّدات في الملف = 13، بينما `BackendAdapter` يعرّف 14 عقدة:
```dart
// lib/backend/core/backend_adapter.dart:56
  SignatureBackend? get signature;
```
```dart
// lib/backend/adapters/eld_engine/sub/eld_signature_backend.dart:24-32
    return err(
      const ServerError(
        code: 'eld.signature_endpoint_absent',
        context: {
          'message':
              'The server contract has no signature upload path. Certify the daily log instead.',
        },
      ),
    );
```
- **السلوك الحالي:** تحققت بالبحث النصي في `lib/` بالكامل: `SignatureBackend` يظهر **فقط** في `contracts/signature_backend.dart`، `core/backend_adapter.dart:56`، `eld_signature_backend.dart`، `mock_signature_backend.dart`، `eld_engine_adapter.dart:58`، `mock_adapter.dart:62`. **لا يوجد أي `signatureBackendProvider`**، ولا أي مستهلك. رغم أن `mock_signature_backend.dart` بني منطقًا حقيقيًا كاملًا (49 سطرًا: تخزين، hash، شهادة).
- **لماذا هو مشكل:** طبقة كاملة (عقدة + محوّلان + getter في الـ adapter + منطق mock) موجودة لتعمل في الفراغ. هذا يوهم Maintenance بأن «التوقيعات مدعومة عبر المنفذ»، بينما هي غير مربوطة إطلاقًا.
- **المبدأ المنتهك:** Dead code removal / YAGNI على مستوى العقد.
- **العواقب:** 4 ملفات + منطق mock تُصان بلا مستفيد؛ قرّاء الكود يفترضون وجود مسار توقيع.
- **التصحيح المقترح:** إما (أ) **حذف العقدة والمحوّلين** بالكامل (بما في ذلك `mock_signature_backend.dart`) لأن الاعتماد يتم عبر `daily-logs/{id}/certify`؛ أو (ب) إن كانت هناك نية لإحيائها: أضف `signatureBackendProvider` وموضع استهلاك. التوصية: (أ)، لأن `EldSignatureBackend` نفسه يقرّ بأن المسار غير موجود في العقد الحي.
- **الملفات ذات الصلة:** `signature_backend.dart`، `backend_adapter.dart:56`، `eld_signature_backend.dart`، `mock_signature_backend.dart`، `eld_engine_adapter.dart:58`، `mock_adapter.dart:62`، `backend_providers.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-015: تكرار `_asMap` في خمس مواضع بسلوكين مختلفين
- **Severity:** LOW
- **Category:** Duplication
- **Location:** `lib/backend/adapters/eld_engine/sub/eld_vehicle_backend.dart:23-28`
- **Evidence:**
```dart
// eld_vehicle_backend.dart:23-28
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        if (data is List) return {'items': data};
        throw const FormatException('vehicle list is not an object');
      },
```
```dart
// eld_vehicle_backend.dart:38-43
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        if (data is List) return {'items': data};
        return <String, dynamic>{};
      },
```
```dart
// eld_dvir_backend.dart:96-101
  RawJson _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }
```
```dart
// eld_unidentified_events_backend.dart:18-23
  RawJson _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }
```
```dart
// eld_inspection_backend.dart:81-86
  RawJson _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is List) return {'items': data};
    return <String, dynamic>{};
  }
```
```dart
// eld_driver_session_backend.dart:29-33
      parser: (data) {
        if (data is Map<String, dynamic>) return data;
        if (data is Map) return Map<String, dynamic>.from(data);
        throw const FormatException('co-driver body is not an object');
      },
```
- **السلوك الحالي:** نفس الدالة الحرفية في 3 ملفات، ونسختان lambda داخل `eld_vehicle_backend` — مع **اختلاف سلوكي مقصود**: نسخة `eld_vehicle_backend:27` **ترمي** `FormatException`، وبقية النسخ **تُعيد** `{}`. و`eld_driver_session_backend:32` نسخة سادسة ترمي بنص مختلف.
- **لماذا هو مشكل:** مساعدات تطبيع JSON **يجب** أن تكون متطابقة عبر كل المحوّلات وإلا صارت المقارنة بينها مستحيلة. وجود نسختين مختلفتين سلوكيًا في نفس الملف (`eld_vehicle_backend`) هو الدليل الأوضح.
- **المبدأ المنتهك:** DRY عبر حدود الملف.
- **العواقب:** تصحيح واحد يحتاج 6 تعديلات؛ انحراف سلوكي صامت عند تطبيق التصحيح.
- **التصحيح المقترح:** وضع `RawJson coerceToMap(Object? data, {bool throwOnNonObject})` في `mappers/json_primitives.dart` (المجلد موجود ومخصص للمساعدات المشتركة).
- **الملفات ذات الصلة:** `eld_vehicle_backend.dart`، `eld_dvir_backend.dart`، `eld_unidentified_events_backend.dart`، `eld_inspection_backend.dart`، `eld_driver_session_backend.dart`، `mappers/json_primitives.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-016: `accountProfileFixture` ثابت ميت (21 سطر بيانات)
- **Severity:** LOW
- **Category:** Maintainability
- **Location:** `lib/backend/adapters/mock/fixtures/account_fixtures.dart:12`
- **Evidence:**
```dart
// account_fixtures.dart:12-32
const accountProfileFixture = <String, dynamic>{
  'id': 101,
  'name': 'سعد بن محمد العتيبي',
  'email': 'driver101@eld.com',
  'phone': '+966501234567',
  'licenseNumber': 'TX-DL-123456',
  'licenseState': 'TX',
  'carrierName': 'Top Compliance Logistics LLC',
  'carrierUsdot': '1234567',
  'status': 'ACTIVE',
  'mainOfficeAddress': '100 Logistics Blvd, Dallas, TX 75001',
  'homeTerminalAddress': 'طريق الملك فهد، الرياض',
  'timezone': 'Asia/Riyadh',
  'language': 'ar',
  'availableLanguages': ['ar', 'en', 'es'],
  'odometer': 'mi',
  'availableOdometerUnits': ['mi', 'km'],
  'canEdit': false,
  'editRestrictionNotice':
      'لا يمكن تغيير معلومات الحساب إلا بواسطة مدير الأسطول',
};
```
- **السلوك الحالي:** تحققت بالبحث النصي: المستهلك الوحيد هو `accountMyAccountFixture` في `mock_account_backend.dart:16` و`:25`. `accountProfileFixture` لا يُقرأ من أي مكان في `lib/` ولا `test/`.
- **لماذا هو مشكل:** لا يُخالِف قاعدة معمارية، لكنه عقبة صيانة: ثابت بصيغة مختلفة (`timezone` لا `timeZone`، `licenseNumber`/`licenseState` لا `license` Map) يوحي بمسار بيانات كان موجودًا. ولاحظ التوثيق في 5-9: «المحاكي يعيد الحقول القانونية فقط» — وهو وصف لا يصف أي شيء مستخدم.
- **المبدأ المنتهك:** Dead code.
- **العواقب:** إغراء صيانة باستخدامه لاحقًا ← يكسر `MockAccountBackend` لأن `DriverAccount.fromJson` لا يتوقع تلك الصيغة (وهو بالضبط ما ينقصه! انظر BACK-019).
- **التصحيح المقترح:** حذفه وتحديث توثيق الملف؛ أو — وهو الأفضل — **استخدامه فعليًا** كـ fixture ثانٍ يغطي صيغة الـ API الخام (قبل `_mapAccountJson`)، فيصبح `mock_account_backend` يعكس تطبيع المحرك الحقيقي.
- **الملفات ذات الصلة:** `account_fixtures.dart`، `mock_account_backend.dart`، `eld_account_backend.dart:15-48`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-017: `mock_adapter.dart` يحوي `@override` يتيمًا (أثر حذف)
- **Severity:** LOW
- **Category:** Maintainability
- **Location:** `lib/backend/adapters/mock/mock_adapter.dart:101-102`
- **Evidence:**
```dart
// mock_adapter.dart:98-107
  @override
  late final HardwareBackend hardware = MockHardwareBackend();

  @override

  // ==========================================================================

  @override
  Future<void> dispose() async {
    // Mocks hold only in-memory state; nothing to release.
  }
```
- **السلوك الحالي:** السطر 101 يحمل `@override` يتيمًا (لم يبقَ عضو يتبعه) بعد حذف عضو سابق. تحققت عمليًا: `flutter analyze lib/backend` ⇒ `No issues found!` — أي أن المحلل يتحمّله، لكنه **أثر حذف**.
- **لماذا هو مشكل:** ليس مخالفة معمارية (لا أبلّغه كـ HIGH)، لكنه دليل على أن الملف ليس مُراجَعًا بعد الحذف، ويُربك القارئ: يبدو كأن هناك getter ناقصًا.
- **المبدأ المنتهك:** وضوح المصدر.
- **العواقب:** تضليل قارئ؛ خطر أن يظن القارئ أن هناك getter ناقصًا.
- **التصحيح المقترح:** حذف السطر 101 (والأسطر الفارغة 102-104).
- **الملفات ذات الصلة:** `mock_adapter.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-018: توثيق `mock_adapter.dart` يناقض الواقع (17 عقدة مقابل 22 دالة)
- **Severity:** LOW
- **Category:** Maintainability
- **Location:** `lib/backend/adapters/mock/mock_adapter.dart:32-34`
- **Evidence:**
```dart
// mock_adapter.dart:30-36
/// In-memory backend for development, demos, and tests.
///
/// **Status in T1.8:**
/// - 2 contracts are fully mocked (account, statusDashboard).
/// - 17 contracts throw [UnimplementedError] (filled in Phase 2).
///
/// **Rule:** No network access. No timers. No platform channels.
```
- **السلوك الحالي:** الواقع (بعد قراءة الـ 13 mock sub-backend كاملة): عدد العقود **13**، منها عدد من الدوال منفَّذ، و**7 عقود** تحتوي `UnimplementedError`؛ بإجمالي **22 دالة غير منفَّذة من 58**. الوثيقة تقول «17 contracts».
- **لماذا هو مشكل:** التوثيق المعماري المنقوص أخطر من انعدامه، لأنه يُستخدم كمرجع لقرار «هل الموك جاهز؟».
- **المبدأ المنتهك:** Accurate documentation.
- **العواقب:** المطور يظن أن 17 عقدة معطّلة بينما 22 دالة كذلك؛ قرار «الموك كافٍ للتجربة» مبني على رقم خاطئ.
- **التصحيح المقترح:** تحديث التوثيق بالأرقام الفعلية، ويفضّل استبداله بتقرير يُولَّد آليًا من اختبار تناظر (انظر القسم C).
- **الملفات ذات الصلة:** `mock_adapter.dart`، كل ملفات `mock/sub/*`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-026: تطبيع URL ثلاثي النسخ عبر طبقتين
- **Severity:** MEDIUM
- **Category:** Duplication
- **Location:** `lib/backend/core/backend_identity.dart:84-93`
- **Evidence:**
```dart
// lib/backend/core/backend_identity.dart:84-93
  static String _normalizeUrl(String url) {
    var normalized = url.trim();
    if (!normalized.contains('://')) {
      normalized = 'https://$normalized';
    }
    while (normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
```
```dart
// lib/core/network/api_config.dart:64-76
  ApiConfig normalized() {
    var normalizedUrl = baseUrl.trim();

    // Ensure scheme
    if (!normalizedUrl.contains('://')) {
      normalizedUrl = 'https://$normalizedUrl';
    }

    // Remove trailing slash(es)
    while (normalizedUrl.endsWith('/')) {
      normalizedUrl = normalizedUrl.substring(0, normalizedUrl.length - 1);
    }
```
```dart
// lib/backend/providers/backend_network_providers.dart:30-39
  var effectiveUrl = serverUrl.isNotEmpty ? serverUrl : coreConfig.baseUrl;

  // ضمان أن الرابط يحتوي على /api
  if (effectiveUrl.isNotEmpty && !effectiveUrl.endsWith('/api')) {
    // إزالة أي / زائدة من النهاية
    while (effectiveUrl.endsWith('/')) {
      effectiveUrl = effectiveUrl.substring(0, effectiveUrl.length - 1);
    }
    effectiveUrl = '$effectiveUrl/api';
  }
```
- **السلوك الحالي:** ثلاث نسخ من «تطبيع الرابط»، أول اثنتان متطابقتان حرفيًا، والثالثة **تُطبِّق بعد** ولا تتصل بالأولتين إطلاقًا.
- **لماذا هو مشكل — الإجابة المباشرة على سؤال ازدواج `api_config`:** لا يوجد ازدواج **في** `lib/backend/http/api_config.dart` — الملف **كله تعليقات** (7 أسطر، DEPRECATED، لا يستورده أحد). **الازدواج الحقيقي موجود في مكان آخر**: تطبيع الرابط مكرر ثلاث مرات وموزَّع على **طبقتين** (`core/network` و`backend/core`). أما **الـ endpoints** فمصدرها **واحد** (`eld_endpoints.dart`) — لا ازدواج. والـ **timeouts** في **مكان واحد** (`ApiConfig` 38-40) — لا ازدواج هناك أيضًا. إذن: **لا ازدواج في base-URL/timeout بين الملفين؛ الازدواج في تطبيع URL فقط.**
- **المبدأ المنتهك:** DRY / Single source of truth للإعداد.
- **العواقب:** التصحيح في `BackendIdentity` لا يصل إلى `ApiClient`. النسخة الثالثة تفترض `/api` ثابتة وتُضيفها حتى لو لم تُطلب. سلوك غير متوقع إذا أدخل المستخدم `https://host/api/v2`.
- **التصحيح المقترح:** `ApiConfig.normalized()` هو المكان الطبيعي؛ `BackendIdentity` يجب أن يستقبل `baseUrl` **مُطبَّعًا** (لا يعيد التطبيع)، و`backend_network_providers` يجب أن يستدعي `normalized()` بدل الحلقة اليدوية.
- **الملفات ذات الصلة:** `backend_identity.dart:84-93`، `core/network/api_config.dart:64-84`، `backend_network_providers.dart:30-46`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-028: ملفّا `lib/backend/http/api_config.dart` و`api_response.dart` ميتان بالكامل
- **Severity:** LOW
- **Category:** Maintainability
- **Location:** `lib/backend/http/api_config.dart:1-7`
- **Evidence:** الملف بأكمله:
```dart
// lib/backend/http/api_config.dart:1-7
// /// HTTP configuration for the ELD backend.
// ///
// /// **DEPRECATED**: This file is kept for backward compatibility.
// /// Please import `lib/core/network/api_config.dart` directly instead.
// library;

// export '../../core/network/api_config.dart';
```
```dart
// lib/backend/http/api_response.dart:1-7
// /// Unified HTTP response wrapper.
// ///
// /// **DEPRECATED**: This file is kept for backward compatibility.
// /// Please import `lib/core/network/api_response.dart` directly instead.
// library;

// export '../../core/network/api_response.dart';
```
- **السلوك الحالي:** لا يستوردهما أي كود (تحققت). الملفان **لا يولّدان أي رمز** (حتى `library;` معطّل) — أي أنهما ملفان نصّيان.
- **لماذا هو مشكل:** «kept for backward compatibility» بلا مستهلك = لا شيء maintained له توافق. وجودهما يربك البحث عن إعداد HTTP ويوحي بأن هناك مصدرين. **ملاحظة مهمة:** هذا **ليس** ازدواجًا فعليًا (انظر BACK-026)؛ هو **بقايا ميتة**.
- **العواقب:** ارتباك؛ احتمال أن يضيف مطوّر كودًا جديدًا ملفًا بلا فائدة.
- **التصحيح المقترح:** حذف الملفين.
- **الملفات ذات الصلة:** `lib/backend/http/api_config.dart`، `lib/backend/http/api_response.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-008: نظامان موازيان بالكامل للزمن الموثوق داخل `core/time`
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/time/time_authority.dart` + `time_authority_provider.dart` + `monotonic_time_authority.dart` مقابل `lib/core/time/trusted_time_provider.dart`
- Evidence:
```dart
abstract interface class TimeAuthority {
  Future<void> initialize();
  DateTime nowUtc();
  Duration get monotonicElapsed;
  TrustLevel get trustLevel;
  Future<bool> resync();
}
```
```dart
abstract interface class TrustedTimeProvider {
  TrustedTimeState get state;
  TrustedTimeResult get currentTime;
  Duration get monotonicElapsed;
  void anchor(DateTime serverUtc);
}
```
- Current behavior: واجهتان بمجموعة أعضاء متقاربة في نفس المجلد، لهما تنفيذان (`MonotonicTimeAuthority` و`MonotonicTrustedTimeProvider`)، ولهما مزوّدان (`timeAuthorityProvider` و`trustedTimeProvider`)، ونموذجا ثقة (`TrustLevel` enum مقابل `TrustedTimeState` enum + `TrustedTimeResult` sealed). الأولى مستهلكة من `features/logs` و`features/sync` و`features/tracking`؛ والثانية مستهلكة من `backend/http/interceptors/time_drift_interceptor.dart:70` فقط.
- Why problematic: مجموعتان من البنى بنفس الاسم-ish (`monotonicElapsed` في둘) بنفس الدلالة ولكن بعقود مختلفة (`resync()` مقابل `anchor()`). من ينظر للمجلد لا يستطيع أيهما «سلاح الزمن الموثوق». كما أن أحدهما يحمل الفجوة الأمنية (CORE-006) والآخر يحمل الاستعادة (CORE-007)، فلا يوجد مسار واحد يمكن تشديده.
- Violated principle: DRY على مستوى التجريد؛ وتقدّم الكائنات (Low coupling / High cohesion على مستوى النموذج).
- Current owner: `lib/core/time/` (كلاهما)
- Correct owner: abstractions واحدة — `core/time/trusted_time.dart` (Contract + sealed result + state)، مع `FakeTrustedTimeProvider` كبديل اختبار موحّد.
- Consequences: صيانة مكرّرة، احتمال اختلاف سلوك بين مستهلكَين للزمن، وصعوبة certifying واحدة للإتقان القانوني.
- Recommended correction: احذف عائلة `TimeAuthority` (أو اجعلها `typedef`/adapter رقيق فوق `TrustedTimeProvider`)، وحمّل الاستهلاك على `trustedTimeProvider` + `TrustedTimeResult`.
- Related files: `lib/core/time/time_authority_provider.dart`, `lib/core/time/monotonic_time_authority.dart`, `lib/backend/http/interceptors/time_drift_interceptor.dart`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-009: ثلاث فئات خطأ مُصنَّفة `AppError` لا تُنشأ أبداً — إحداها تحمل ثقلاً قانونياً
- Severity: MEDIUM
- Category: Maintainability
- Location: `lib/core/error/app_error.dart:414-437` (`TimeUnavailableError`), `:444-467` (`StorageError`), `:344-372` (`UnsupportedCapabilityError`)
- Evidence:
```dart
/// Trusted time is unavailable. HOS calculations must be suspended.
final class TimeUnavailableError extends AppError {
```
- Current behavior: بحث في كامل `lib/` (خارج تعريفات الملف نفسه) وجد **0** بناء لـ`TimeUnavailableError`، `StorageError`، `UnsupportedCapabilityError`. أي: التعاقد «HOS calculations must be suspended» لا يوجد له أي تنفيذ. بينما `ConflictError` و`ValidationError` يُستخدمان فعلاً في `core/network/error_mapper.dart:132,134,102,104,141,150,159,161`.
- Why problematic: وجود نوع خطأ بلا منتج يجعل القارئ (والمدقق) يفترض وجود آلية إيقاف فعّلي. ويعني أن HOS يُحسب فعلاً حتى عند انعدام الثقة — وهو خلفيّة CORE-006/007. كما أن التوثيق يوحي بأن `StorageError` و`UnsupportedCapabilityError` كلمتان مناسبتان لكنهما غير مربوطتين.
- Violated principle: YAGNI مقابل السلامة — التغطية الوهمية ليست تغطية.
- Current owner: `lib/core/error/app_error.dart`
- Correct owner: نفس الملف (للتصنيف) + مواقع الاستهلاك التي يجب أن تُنشئها (`core/time`، `core/storage`، `backend`).
- Consequences: ثلاثة آثار: (أ) ضياع صلة التنفيذ التي كان يفترضها التعاقد مع HOS؛ (ب) تسطيح التعاقد؛ (ج) فخ صيانة.
- Recommended correction: إمّا ابدأ في بناء `TimeUnavailableError` من `MonotonicTrustedTimeProvider` عند `state != trusted` (مع ربطه بـCORE-006)، أو احذف الأنواع الثلاثة مع تعليق صريح.
- Related files: `lib/core/error/user_facing_message.dart:39-47` (لا case لـ`TimeUnavailableError` ⇒ يسقط إلى `_ => loc.errGeneric`), `lib/core/time/trusted_time_provider.dart`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-011: `core/error/exception.dart` شبه ميت — موقع `throw` واحد مقابل 7 فئات
- Severity: MEDIUM
- Category: Maintainability
- Location: `lib/core/error/exception.dart:2-77`; `lib/core/utils/repository_helper.dart:28-52`
- Evidence:
```dart
/// استثناء المتابعة
class SyncException implements Exception {
  final String? message;

  const SyncException([this.message]);

  @override
  String toString() => 'SyncException: $message';
}
```
```dart
  } on ServerException catch (e) {
    ...
  } on OfflineException catch (e) {
    ...
  } on UnauthorizedException catch (e) {
    ...
  } on CacheException catch (e) {
```
- Current behavior: بحث في كامل `lib/` وجد موقع `throw` واحد فقط يستعمل أيًّا من هذه السبعة: `lib/features/logs/data/repositories/log_repository_impl.dart:270` (`throw ServerException`). وبقية الفئات (Sync, Tracking, Permission) لا تُرمى إطلاقاً. ومع ذلك `executeWithHandling` يبني 4 معالجات `on <X> catch`.
- Why problematic: الملف يبدو واجهة خطأ حيّة (بلا `sealed`، وبلا تحويل إلى `AppError`، وبلا استيراد `dio`)، فيوحي بأنه الطبقة المعمتمدة — بينما هو مسار ميت يترك `executeWithHandling` يبدو كأنه يلتقط أخطاء حقيقية. كما أن وجود معالج `on X catch` لاستثناء لا يُرمى هو كود لا يمكن اختباره.
- Violated principle: إزالة الكود الميت؛ وقاعدة DIP — استثناءات المستوى الأعلى بلا متطلب مطابق في `core`.
- Current owner: `lib/core/error/exception.dart`
- Correct owner: احذفه (بعد توحيد العقد — CORE-010)، أو اجعله `final class ... extends AppError` حتى يدخل في نفس النظام.
- Consequences: صيانة مهدورة، وقارئ يظن أن هناك طبقتَي خطأ نشطتين بينما هناك نصف طبقة.
- Recommended correction: احذف `exception.dart` وكل معالجات `on <X> catch` المرتبطة به بعد توحيد العقد على `Result`.
- Related files: `lib/core/utils/repository_helper.dart:28-52`, `lib/core/error/failure.dart`, `lib/features/logs/data/repositories/log_repository_impl.dart:270`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-012: كاشف «تراكمات الخادم» مكرر في ملفين بقائمتين مختلفتين
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/network/error_mapper.dart:212-221` مقابل `lib/core/error/user_facing_message.dart:64-78`
- Evidence (`error_mapper.dart`):
```dart
bool _looksLikeServerDump(String text) {
  final lower = text.toLowerCase();
  return lower.contains('org.hibernate') ||
      lower.contains('org.postgresql') ||
      lower.contains('eldpersistenceexception') ||
      lower.contains('psqlexception') ||
      lower.contains('could not execute statement') ||
      lower.contains('\tat ') ||
      text.length > 280;
}
```
- Evidence (`user_facing_message.dart`):
```dart
bool _looksLikeServerDump(String text) {
  final lower = text.toLowerCase();
  return lower.contains('hibernate') ||
      lower.contains('dioexception') ||
      lower.contains('org.postgresql') ||
      lower.contains('org.springframework') ||
      lower.contains('java.lang.') ||
      lower.contains('kotlin.') ||
      lower.contains('eldpersistenceexception') ||
      lower.contains('exception:') ||
      lower.contains('stacktrace') ||
      lower.contains('\tat ') ||
      lower.contains('instance of') ||
      lower.contains('package:');
}
```
- Current behavior: دالة بنفس الاسم والنية في طبقتين مختلفتين، بنفس الحجم، وقائمتا أسطر مختلفة مع اختلاف في الحد (`text.length > 280` مقابل `trimmed.length > 140`).
- Why problematic: كشف الإTEXTIII عن تسريب الخادم هو ضابط أمني للمحتوى الذي يصل للسائق؛ ازدواجه يعني أن إصلاحاً في أحدهما لا يصل للآخر. فمثلاً `dioexception` مرشَّح في `user_facing_message` لكنه ليس في `error_mapper` — فـ`error_mapper` قد يضع نصاً فيه `DioException` في `context['serverMessage']`، ثم `user_facing_message` يرفضه عند العرض — سلوك متفق عليه لكنه عرضي لا مقصود.
- Violated principle: DRY؛ مصدر واحد لسياسة التنقية الأمنية.
- Current owner: ملفان في `core` بنفس `_looksLikeServerDump`.
- Correct owner: `core/error/user_facing_message.dart` (سياسة العرض) — يستورد منه `error_mapper` دالة واحدة.
- Consequences: انحراف سلوكي مستقبلي، وصعوبة مراجعة سياسة الخصوصية في مكان واحد.
- Recommended correction: اجعل `error_mapper` يستورد `_looksLikeServerDump` كـ`@visibleForTesting` عام من `user_facing_message`، واحذف النسخة المكرّرة؛ وحّد عتبة الطول في ثابت واحد.
- Related files: `lib/core/network/error_mapper.dart:195-227`, `lib/core/error/user_facing_message.dart:50-99`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-013: `localization_helper` تمرر رسائل الخطأ عبر قناة ثانية موازية لـ`user_facing_message`
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/utils/localization_helper.dart:11-50`
- Evidence:
```dart
    switch (key) {
      case 'emailRequired':
        return loc.emailRequired;
      ...
      case 'permissionDenied':
        return loc.permissionDenied;
      default:
        // Not an l10n key: a backend error code such as
        // `network.connectionFailed`, `server.unavailable`, `server_error`.
        // The driver never sees the code itself.
        final loc = AppLocalizations.of(this)!;
        final lower = key.toLowerCase();
        if (lower.startsWith('network.') || lower.contains('connection')) {
          return anyErrorUserMessage('noInternet', loc: loc);
        }
        if (lower.startsWith('server') ||
            lower.endsWith('_error') ||
            lower.contains('.') ||
            lower.contains('_')) {
          return anyErrorUserMessage(Object(), loc: loc);
        }
        return anyErrorUserMessage(key, loc: loc);
    }
```
- Current behavior: دالة تمديد على `BuildContext` تختار نصاً للمستخدم عبر (أ) `switch` على 12 مفتاح l10n، ثم (ب) تخمين مبني على شكل النص (`startsWith('network.')`، `contains('_')`) يُمرِّر النص إلى `anyErrorUserMessage` للتحقق. هذا يعني وجود **منطق** في طبقة UIwm ودالة التحقق في طبقة `core/error`.
- Why problematic: منطق الترجمة في ثلاث أماكن: `user_facing_message.appErrorUserMessage` (`switch` على نوع `AppError`)، و`localization_helper` (`switch` على نص + تخمين)، و`context_extensions.translateStatus` (`switch` آخر). كما أن التخمين في الفرع `default` هشّ: أي مفتاح يحوي `.` أو `_` يُعامَل كخطأ عام. وهو يجلب `AppLocalizations` مرتين (`loc` في السطر 9 ثم `final loc` في السطر 38 — متغيّر مظِلّ).
- Violated principle: SRP في عرض الأخطاء؛ قاعدة «طبقة العرض لا تقرر ما هو آمن للعرض».
- Current owner: `lib/core/utils/localization_helper.dart`
- Correct owner: `lib/core/error/user_facing_message.dart` يجب أن تملك التحويل الوحيد من (نوع/رمز) → نص، ويكون `localization_helper` نداءً واحداً بلا `switch`.
- Consequences: نفس رمز الخطأ قد يُترجم إلى نصين مختلفين حسب المسار؛ وصعوبة إضافة رمز جديد.
- Recommended correction: احذف الـ`switch` من `localization_helper` واجعله `return anyErrorUserMessage(key, loc: loc)`، ووسّع `appErrorUserMessage` ليقبل `String code` أيضاً عبر سجل مركزي.
- Related files: `lib/core/error/user_facing_message.dart:27-48`, `lib/core/extensions/context_extensions.dart:22-32`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-014: عنوان السيرفر الثابت مُعرَّف في مكانين
- Severity: MEDIUM
- Category: Hardcoding
- Location: `lib/core/config/runtime_selection.dart:23`; `lib/core/services/local_storage_service.dart:94`
- Evidence:
```dart
const String fallbackServerOrigin = 'https://snsoft.cloud';
```
```dart
    // وضع الإعدادات الافتراضية إذا لم تكن موجودة
    const String defaultServer = 'https://snsoft.cloud';
    final currentUrl = _prefs.getString('url');
        
    if (currentUrl == null || currentUrl.isEmpty) {
      await _prefs.setString('url', defaultServer);
      await _prefs.setString('backend_type', 'eld');
      AppLogger.info('Server URL and Backend Type set to default settings');
    }
```
- Current behavior: نفس العنوان الحرفي في مكانين مستقلين تماماً. `local_storage_service` يكتبه في `SharedPreferences` عند أول تشغيل، فيصبح المدخل المحفوظ يتغلّب على `fallbackServerOrigin` في `resolveRuntimeBackend` (لأن `saved.isNotEmpty` يُقدَّم على `build`). أي أن أول تشغيل يثبّت العنوان محلياً، ولا-central Changes.
- Why problematic: مصدران للحقيقة؛ وتغيير `fallbackServerOrigin` لن يؤثر على أي جهاز ثُبّت بالفعل لأن `url` محفوظ. والأخطر: `local_storage_service` يكتب `'backend_type', 'eld'` بينما `tracking_config_storage_service.dart:40` يستخدم `'traccar'` كقيمة افتراضية للقراءة:
```dart
  String get backendType => _prefs.getString(_backendTypeKey) ?? 'traccar';
```
- Violated principle: Single Source of Truth on configuration؛ قاعدة «الإعدادات من مصدر واحد».
- Current owner: `lib/core/services/local_storage_service.dart` (كاتب) + `lib/core/config/runtime_selection.dart` (قارئ)
- Correct owner: `lib/core/config/runtime_selection.dart` — يتولّى كتابة الـdefaults أيضاً.
- Consequences: اختلاف السلوك بين جهاز جديد وجهاز مُرقّع؛ عدم القدرة على تدوير الخادم الافتراضي.
- Recommended correction: اجعل `local_storage_service` يستدعي `resolveRuntimeBackend` (أ) constante واحدة من `runtime_selection.dart`، واحذف `'traccar'` كقيمة افتراضية للقراءة في `tracking_config_storage_service.dart:40` — دع `resolveBackendType` في `core_providers.dart:58-66` هيsole صاحبة القرار.
- Related files: `lib/core/network/core_providers.dart:44-66`, `lib/core/services/tracking_config_storage_service.dart:40`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-017: نسخة `NetworkInfoImpl` عامة على مستوى الوحدة تُنشأ بالاستيراد ولا تُتلف
- Severity: MEDIUM
- Category: Maintainability
- Location: `lib/core/utils/repository_helper.dart:7,17`
- Evidence:
```dart
final _defaultNetworkInfo = NetworkInfoImpl();
```
```dart
  if (checkNetworkFirst) {
    final checker = networkInfo ?? _defaultNetworkInfo;
    if (!(checker.isConnected)) {
```
- Current behavior: متغير top-level في `repository_helper.dart` يُنشئ `NetworkInfoImpl()` **عند أول استيراد للملف**، فيفتح اشتراكاً على قناة منصّة `connectivity_plus` — حتى لو لم يُستدعَ `executeWithHandling` ولا مرة مع `checkNetworkFirst: true`. الكائن لا يملك مسار disposal (لا `ref`، لا `onDispose`).
- Why problematic: (1) تسريب اشتراك عالمي مدى الحياة العملية، مكرر عن `networkInfoProvider` في `core_providers.dart:29-34` الذي يتعامل مع `dispose` بشكل صحيح (`ref.onDispose(networkInfo.dispose)`). (2) وجود مصدرين لقراءة حالة الشبكة — واحد حيّ في `Provider` وآخر حيّ دائم — وقد ينحرفان. (3) تهيئة المنصة في وقت الاستيراد (import time) سلوك غير متوقع في بيئة الاختبار.
- Violated principle: DI / Dependency Injection — اعتناد على المورد عبر الحاوية لا على global variable؛ إدارة دورة حياة المورد.
- Current owner: `lib/core/utils/repository_helper.dart`
- Correct owner: `core/network/core_providers.dart` (المزوود الموجود فعلاً).
- Consequences: استيراد `repository_helper.dart` من أي ملف يفتح قناة منصّة لا تُغلق؛ تسريب في الاختبارات (FakesAsync).
- Recommended correction: احذف `_defaultNetworkInfo` واجعل `networkInfo` **مطلوباً** في `executeWithHandling` (اجعلها معاملاً إجبارياً)، أو انقل الدالة لتصبح امتداداً على `Ref` تمرير `ref.watch(networkInfoProvider)`.
- Related files: `lib/core/network/network_info.dart:29-45`, `lib/core/network/core_providers.dart:29-34`, `lib/core/network/network_guard.dart:20-28`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-018: استيراد دائري بين `local_storage_service` و`tracking_config_storage_service`
- Severity: MEDIUM
- Category: Maintainability
- Location: `lib/core/services/local_storage_service.dart:11`; `lib/core/services/tracking_config_storage_service.dart:4`
- Evidence:
```dart
import 'tracking_config_storage_service.dart';
```
```dart
import '../constants/app_constants.dart';
import 'local_storage_service.dart';
```
- Current behavior: `local_storage_service.dart` يستورد `tracking_config_storage_service.dart` (لينشئه في `init()`)، و`tracking_config_storage_service.dart` يستورد `local_storage_service.dart` (لينشئ مزوّده في السطر 101-107). دورتان في نفس حزمة `core/services`.
- Why problematic: الاعتماد المتبادل بين facade وتطبيقه يمنع استخراج التطبيق إلى وحدة مستقلة، ويجعل أي refactor في أحدهما يتمسّ الآخر. الدليل على أن هذا ضروري فعلاً موجود في `tracking_config_storage_service.dart` نفسه:
```dart
final trackingConfigStorageProvider =
    Provider<TrackingConfigStorageService>((ref) {
  // We temporarily read from the existing local storage provider to get the shared prefs instance.
  // In the future, this should depend on a dedicated SharedPreferences provider.
  final localStorage = ref.watch(localStorageProvider);
  return TrackingConfigStorageService(localStorage.prefs);
});
```
  الاعتراف المؤقت في تعليق ما زال مستبدلاً.
- Violated principle: Acyclic Dependencies (DAG) — قاعدة العقوديات البنيوية.
- Current owner: `lib/core/services/tracking_config_storage_service.dart`
- Correct owner: مزوّد `SharedPreferencesWithCache` مستقل في `core/services/` أو `core/storage/`، تعتمد عليه كل الخدمات.
- Consequences: صعوبة استبدال طبقة التخزين؛ حالات تهيئة هشّة (انظر CORE-033 على `static late _prefs`).
- Recommended correction: عرّف `sharedPreferencesProvider` يعيد `SharedPreferencesWithCache`، واحذف `trackingConfigStorageProvider` بالكامل (لا مستهلك له خارج الملف)، واحذف الاستيراد من `local_storage_service` إن لم يعد لازماً.
- Related files: `lib/core/services/local_storage_service.dart:16-38,223-225`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-019: مزوّدان بالاسم نفسه `secureStorageProvider` في `core`، واحد ميت
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/network/core_providers.dart:40-42`; `lib/core/storage/storage_providers.dart:10-12`
- Evidence:
```dart
final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});
```
```dart
final secureStorageProvider = Provider<SecureStoragePort>((ref) {
  return const FlutterSecureStorageAdapter();
});
```
- Current behavior: اسمان متطابقان، نوعان مختلفان، في مجلدين مختلفان من `core`. المستهلَك الوحيد (`server_config_store.dart:13`) يستورد `../storage/storage_providers.dart` ويأخذ نسخة `SecureStoragePort`. نسخة `FlutterSecureStorage` في `core_providers.dart` **لا تُستهلك من أي مكان** (بحث: `secureStorageProvider` يظهر في 4 مواضع فقط: تعريفه، تعريف الآخر، الاستخدام في `server_config_store.dart`، واسم الملف في تعليقات الاستيراد).
- Why problematic: اسم واحد ل.Dependency مختلفة النوعية في نفس الطبقة = فخ استيراد صامت. لو استورد ملف `core_providers.dart` و`storage_providers.dart` معاً، يفوز أحدهما بصمت (أو يظهر تعارض). والأهم: وجود `FlutterSecureStorage` في `core/network/` يكسرHexagonal — يُخالف نفس الـport الذي صُمّم لـ.
- Violated principle: Dependency Inversion —_port واحد، تنفيذ واحد؛ تسمية فريدة للمزوّدات.
- Current owner: `lib/core/network/core_providers.dart:40-42`
- Correct owner: `lib/core/storage/storage_providers.dart` (المُبقى).
- Consequences: احتمال أن يمرر كودٌ ما `FlutterSecureStorage` مكشوفاً بدل المنفذ، فتتحقق القاعدة «لا أسرار إلا عبر `SecureStoragePort`» بالإهمال لا بالبنية.
- Recommended correction: احذف `secureStorageProvider` من `core_providers.dart`، وسمِّ الأ Ableton. أي مستهلك يحتاج `FlutterSecureStorage` مباشرة يجب أن يمر عبر المنفذ.
- Related files: `lib/core/storage/ports/secure_storage_port.dart`, `lib/core/config/server_config_store.dart:11-15`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-020: مفاتيح التخزين مُعرَّفة في أربعة أماكن
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/constants/app_constants.dart:27-32`; `lib/core/constants/storage_constants.dart:3-5`; `lib/core/services/tracking_config_storage_service.dart:12-23`; `lib/core/services/user_preferences_storage_service.dart:9-16`; `lib/core/localization/locale_provider.dart:19,23`
- Evidence:
```dart
  // مفاتيح التخزين
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String languageKey = 'language_code';
  static const String themeKey = 'theme_mode';
```
```dart
class StorageConstants {
  // SharedPreferences Keys
  static const String serverUrl = 'url';
  static const String deviceId = 'id';
  static const String eventLogs = 'event_logs';
```
```dart
  static const String _languageKey = 'language';
  static const String _themeKey = 'theme';
```
```dart
  static const String _oldLanguageKey = 'language_code';
```
- Current behavior: `'url'` و`'id'` في `StorageConstants` **و** في `tracking_config_storage_service`؛ `'language'` في `user_preferences_storage_service` و`'language_code'` في `AppConstants` و`'language_code'` في `locale_provider` كمفتاح قديم؛ `'theme'` مقابل `'theme_mode'`. و7 ثوابت من `AppConstants` (المفاتيح كلها) لا تُستخدم إلا `appVersion` في `features/about/presentation/pages/about_page.dart:92`.
- Why problematic: مفتاح preferences تالف يصمتاً (يكتب في مكان ويقرأ من آخر) لأن الاسم الحرفي مكرر؛ والأسوأ أن `AppConstants.tokenKey`/`refreshTokenKey` تُوحي بمكان تخزين التوكن — وهو في الواقع `FlutterSecureStorage` (تحققت: `auth_local_data_source.dart:36,61` يستعمل `FlutterSecureStorage`).
- Violated principle: DRY؛ Single Source of Truth لأسماء المدخلات.
- Current owner: `lib/core/constants/app_constants.dart` + `lib/core/constants/storage_constants.dart`
- Correct owner: `lib/core/constants/storage_constants.dart` كمصدر وحيد لأسماء `SharedPreferences`، مع حذف ثوابت التوكن الميتة.
- Consequences: فقد تفضيلات عند أي إعادة تسمية؛ وحالة زائدة تُوحي بتخزين غير آمن.
- Recommended correction: (أ) احذف مفاتيح التخزين كلها من `AppConstants` (`tokenKey`..`themeKey`) — تحقّقت أنها غير مستخدمة؛ (ب) اجعل `StorageConstants` التعريف الوحيد لكل مفتاح، واستورده في `tracking_config_storage_service` و`user_preferences_storage_service`؛ (ج) احذف `StorageConstants.eventLogs` (ميت).
- Related files: `lib/core/constants/storage_constants.dart`, `lib/features/auth/data/datasources/auth_local_data_source.dart:36-132`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-022: حدود HOS التنظيمية مُعرَّفة في مكانين بقيم متطابقة يدوياً
- Severity: MEDIUM
- Category: Duplication
- Location: `lib/core/config/hos_configuration.dart:25-50`; `lib/core/constants/fmcsa_constants.dart:18-34`
- Evidence:
```dart
  factory HosConfiguration.usa70_8() {
    return const HosConfiguration(
      drivingLimitMinutes: 11 * 60,
      shiftLimitMinutes: 14 * 60,
      cycleLimitHours: 70,
      breakDurationMinutes: 30,
      movingSpeedThresholdKmh: 8.0,
      driveBeforeBreakMinutes: 8 * 60,
      maxConsecutiveDays: 8, // 70 hours in 8 days
      weeklyRestartHours: 34,
    );
  }
```
```dart
  /// Maximum consecutive driving hours before 10-hour rest requirement: 11 hours.
  static const int maxDrivingHours = 11;
  /// Maximum duty window duration after coming on duty: 14 hours.
  static const int maxDutyWindowHours = 14;
  static const int cycle8DaysLimitHours = 70;
  static const int cycleRestartHours = 34;
```
- Current behavior: نفس الأرقام التنظيمية (11، 14، 70، 30، 8، 34) مكتوبة مرة في `FmcsaConstants` ومرة في `HosConfiguration.usa70_8()/usa60_7()`، بصيغ مختلفة (`maxDrivingHours` ساعة مقابل `drivingLimitMinutes: 11 * 60` دقيقة). كذلك `FmcsaConstants.drivingSpeedThresholdMps = 2.235` مقابل `HosConfiguration.movingSpeedThresholdKmh = 8.0` (نفس العتبة بوحدتين مختلفتين، تحويل غير موثّق).
- Why problematic: في تطبيق ELD خاضع لتنظيم 49 CFR، تكرار رقم تنظيمي في مكانين هو خطر امتثال مباشر: تصحيح `FmcsaConstants` لا يسري على `HosConfiguration` التي تحرّك `LocalStorageService.hosConfiguration` (والمخزّنة في `'hos_configuration'` — أي أن القيم القديمة تبقى في أجهزة المستخدمين).
- Violated principle: DRY؛ مصدر واحد للحقيقة التنظيمية.
- Current owner: `lib/core/config/hos_configuration.dart`
- Correct owner: `lib/core/constants/fmcsa_constants.dart` —|source واحد يُبنى منه `HosConfiguration.usa70_8()`.
- Consequences: خطر انحراف حدود القيادة على أجهزة مُرقّعة؛ وصعوبة المراجعة التنظيمية.
- Recommended correction: اجعل مصانع `HosConfiguration` تقرأ من `FmcsaConstants` (تحويلات صريحة `maxDrivingHours * 60`)، أو اجعل `FmcsaConstants` مشتقاً من `HosConfiguration`. وثّق وحدة `movingSpeedThresholdKmh` مقابل Mps.
- Related files: `lib/core/constants/fmcsa_constants.dart`, `lib/core/services/local_storage_service.dart:183-198`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-023: `UtcSyncService` بنية ميتة — لا مرجع خادمي ولا مستهلك
- Severity: MEDIUM
- Category: Maintainability
- Location: `lib/core/services/utc_sync_service.dart:5,15-32,35-49`; `lib/app/app_initializer.dart:22,82-83,92`
- Evidence:
```dart
  Future<void> syncWithUtc({DateTime? serverTime}) async {
    final now = DateTime.now();
    if (serverTime == null) {
      AppLogger.warning(
          'UTC sync skipped: no server reference time (device clock must not anchor trusted time)');
      return;
    }
```
- Current behavior: `AppInitializer` ينشئ `UtcSyncService` ويحقنه في `ProviderContainer` عبر `utcSyncServiceProvider.overrideWithValue(utcSync)` ثم يستدعي `await utcSync.syncWithUtc();` **بلا `serverTime`**. النتيجة: return فوري مع تحذير في كل إقلاع. و`_drift` يبقى `null` دائماً، فيصبح `syncedTime` و`utcNow` مجرد `DateTime.now()` + `.toUtc()`. **بحث في `lib/` وجد 0 استهلاك خارجي لـ`utcNow` أو `syncedTime`.**
- Why problematic: بنية كاملة (صنف + مزوّد + حقن في الـcontainer + استدعاء إقلاع) لا تفعل شيئاً. وهي توأم مع نظام `TimeAuthority` (CORE-008)، ما يضاعف الالتباس: القارئ يرى ثلاث خدمات زمنية في `core` اثنتان منها ميتتان.
- Violated principle: Dead code removal؛ SRP.
- Current owner: `lib/core/services/utc_sync_service.dart`
- Correct owner: لا مكان له — يُحذف، أو يُدمج في `TrustedTimeProvider` (المالك الوحيد للمراسي).
- Consequences: عبء إقلاع مضاعف، وضوضاء في السجلات (`AppLogger.warning` في كل إقلاع)، وطبقة زمنية ثالثة يدعها المطوّرون.
- Recommended correction: احذف `UtcSyncService` و`utcSyncServiceProvider` وسطر `overrideWithValue` من `app_initializer.dart:92`، واحذف `utcSync` من الحقول (22، 82-83). المرساة الخادمية يوفّرها `TimeDriftInterceptor` وحده.
- Related files: `lib/app/app_initializer.dart:22,82-83,92`, `lib/core/time/trusted_time_provider.dart`, `lib/backend/http/interceptors/time_drift_interceptor.dart:62`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-025: المنسّق يحمل سياسات HTTP وحدوداً تنظيمية داخل `Provider<void>`
- Severity: MEDIUM
- Category: SOLID
- Location: `lib/app/orchestrators/tracking_orchestrator.dart:15,28-67`
- Evidence:
```dart
final trackingOrchestratorProvider = Provider<void>((ref) {
  final notifier = ref.read(trackingStateProvider.notifier);
```
```dart
    if (isSpeedTrigger || isTimeTrigger) {
      lastTelemetrySent = now;
      lastSpeedSent = speed;

      final reading = TelemetryReading(
        driverId: DriverId(int.tryParse(auth.user!.id) ?? 0),
        speedMps: speed,
        engineOn: speed > 0,
      );

      ref.read(hardwareBackendProvider).sendTelemetry(reading).then((result) {
```
- Current behavior: `Provider<void>` يقوم بأربع مسؤوليات غير مترابطة: (1) ربط `isDrivingChecker`، (2) سياسة **إرسال** HTTP للـtelemetry (عتبة السرعة، فترة 30 ثانية، `FmcsaConstants`) وهي **حالة محلية قابلة للضياع** (`lastTelemetrySent`, `lastSpeedSent` داخل الإغلاق)، (3) تحويل `TelemetryReading` ووسم المالك بـ`int.tryParse(...) ?? 0`، (4) بدء/إيقاف التتبع آلياً عند تغيّر الحالة.
- Why problematic: (1) حالة الـthrottle عالقة داخل الإغلاق، فلا يمكن اختبارها ولا تعليلها ولا الاعتماد عليها. (2) `?? 0` في `DriverId` — إذا فشل `int.tryParse` فإن معرّف السائق يُرسَل الطلب بمعرّف `0` أي **لسائق آخر**؛ ولا يوجد رفض. (3) مزوّد بنوع `void` لا يمكن لأحد التحقق منه أو نسخه. (4) `Provider` يُعدم مرة واحدة عند الإقلاع ولا يُعاد إنشاؤه.
- Violated principle: SRP؛ Dependency Inversion (سياسة الاتصال بشبكة خارجة داخل منسّق فيزيائي)؛ Fail-fast بدل `?? 0`.
- Current owner: `lib/app/orchestrators/tracking_orchestrator.dart`
- Correct owner: (1) البصمة/العتبة ← `features/telemetry` أو `core/services` كخدمة `TelemetryThrottle` قابلة للاختبار؛ (2) تحويل `TelemetryReading` ← mapper في `backend/adapters`؛ (3) الإرسال ← `features/hardware` use-case؛ يبقى في المنسّق ربط الإشارات فقط.
- Consequences: استعابال محتمل فيTelemetry (معرّف `0`)، وصعوبة إثبات سلوك الإرسال في اختبار.
- Recommended correction: استخرج `class TelemetryBurstGate { bool shouldSend({required double speed, required DateTime now}); }` واختبرها وحدها، وارفض الطلب إن كان `driverId` غير قابل للتحليل. غيّر نوع المزوّد إلى `Provider<TelemetryOrchestratorHandle>` يحمل `dispose`.
- Related files: `lib/core/constants/fmcsa_constants.dart:7,13`, `lib/domain/hardware/telemetry_reading.dart`, `lib/domain/shared/value_objects.dart`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-026: جذر التطبيق يحمل آثار جانبيةpresentation ونصوصاً صلبة
- Severity: LOW
- Category: Maintainability
- Location: `lib/app.dart:49-64,55-61`
- Evidence:
```dart
    ref.listen<HosEngineResult>(hosStatusProvider, (previous, next) {
      if (next is HosEngineReady) {
        final prevStatus =
            (previous is HosEngineReady) ? previous.update.currentStatus : null;
        if (next.update.currentStatus == DutyStatus.driving &&
            prevStatus != DutyStatus.driving) {
          final feedbackContext = rootNavigatorKey.currentContext;
          if (feedbackContext != null) {
            AppFeedback.success(
              feedbackContext,
              'بدأت خدمة التتبع تلقائياً لتسجيل حالة القيادة',
            );
          }
        }
      }
    });
```
- Current behavior: `GoldenFeatherApp` (ConsumerWidget) يستمع لحالة HOS ليُظهر تنبيهاً، وفي نفس الملف نص عربي **غير مترجم** مضمّن (بينما `AppLocalizations` مستخدم في نفس الملف في السطر 82-83).
- Why problematic: (1) نص عربي صلب في جذر التطبيق — بينما التطبيق كامل الترجمة ويستخدم `l10n/app_localizations.dart`؛ سيظهر للمستخدم على الجهاز الإنجليزي. (2) منطق «متى أُعلم السائق» في الجذر لا في use-case أو `hos_provider` — يصعب اختباره ويعاد بناؤه في `tracking_orchestrator.dart:97-109` بنفس الشرط (`currentStatus == DutyStatus.driving && prevStatus != driving`) — **نفس القاعدة مكرّرة في مكانين**.
- Violated principle: SRP في الجذر؛ i18n completeness.
- Current owner: `lib/app.dart:49-64` (والتكرار في `tracking_orchestrator.dart:97-109`)
- Correct owner: مستخدمcase داخل `features/hos` يستمع ويصدر حدثاً؛ الجذر يربطه بـ`AppFeedback` فقط بنص مترجم.
- Consequences: نص غير مترجم؛ وقاعدة منطقية واحدة في مكانين قد تنحرف.
- Recommended correction: انقل النص إلى `l10n`، واستخرج شرط «الانتقال إلى قيادة» إلى دالة نقية مشتركة (مثل `enteredDriving(prev, next)`) يستعملها الطرفان.
- Related files: `lib/app/orchestrators/tracking_orchestrator.dart:97-109`, `lib/routes.dart:63` (`rootNavigatorKey` مستورد من `routes.dart` في `app.dart`)
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-030: مسارانBuild نفس الصفحة
- Severity: LOW
- Category: Duplication
- Location: `lib/routes/home_routes.dart:21-26`
- Evidence:
```dart
        GoRoute(
          path: AppRoutes.status,
          name: 'status',
          builder: (context, state) => const StatusDashboardPage(),
        ),
        GoRoute(
          path: AppRoutes.hos,
          name: 'hos',
          builder: (context, state) => const StatusDashboardPage(),
        ),
```
- Current behavior: `AppRoutes.status = '/status'` و`AppRoutes.hos = '/hos'` يبنمان نفس الـWidget. ومع منطق `redirect` القائم على `matchedLocation` الدقيق، فإن كليهما خاص (ليس ضمن `publicRoutes`) فيمرّان بقاعدة التوجيه نفسها بلا فرق.
- Why problematic: ازدواج في مسمّى URL بلا فرق سلوكي؛ ويخلق لبساً في التحليلات (أيّهما «الصحيح»؟) وفي سجلّ الروابط المستخدَمة.
- Violated principle: DRY in navigation surface.
- Current owner: `lib/routes/home_routes.dart`
- Correct owner: مسار واحد، والآخر `redirect` إليه.
- Consequences:رابط ميت محتمل، وت-reporting موزّع.
- Recommended correction: اجعل `/hos` redirect إلى `/status`، أو احذف أحدهما من `AppRoutes`.
- Related files: `lib/routes.dart:23,35`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-034: كيان نطاقي يحمل عضواً دائماً `null`
- Severity: LOW
- Category: Maintainability
- Location: `lib/core/domain/entities/hos_models.dart:141-149`
- Evidence:
```dart
  Duration get duration => endTime.difference(startTime);
  double? get distanceKm {
    if (startLat != null &&
        startLon != null &&
        endLat != null &&
        endLon != null) {
      return null; // سيتم استخدامه لاحقا مع Haversine
    }
    return null;
  }
```
- Current behavior: `distanceKm` يفحص أربعة حقول ثم يعيد `null` في الحالتين — الفرعان متطابقان.
- Why problematic: كيان نطاقي يحمل عضواً ميتاً يوحي بأن المسافة متاحة. في سياق ELD (مسافة مقطوعة رهن 49 CFR) وجود عضو يُقرأ `distanceKm` ويُتوقع منه رقم — قد يدفع مطوّراً لاستخدامه لاحقاً.
- Violated principle: Dead code؛ لا false affordances في طبقة النطاق.
- Current owner: `lib/core/domain/entities/hos_models.dart:141-149`
- Correct owner: يُحذف، أو يُطبَّع فعلياً (Haversine) في `features/logs/domain`.
- Consequences:لا أثر تنفيذي؛ خطر فهم.
- Recommended correction: احذف `distanceKm`، أو نفّذ `Haversine` في خدمة حساب المسافة في `features/logs/domain` واعرضها.
- Related files: `lib/core/domain/entities/hos_models.dart:117-150`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-037: تكرار داخل منسّق الوقت
- Severity: LOW
- Category: Duplication
- Location: `lib/core/time/time_formatter.dart:7-14,37-44`
- Evidence:
```dart
  static String formatTime12Hour(DateTime time) {
    final h24 = time.hour;
    final h12 = h24 > 12 ? h24 - 12 : (h24 == 0 ? 12 : h24);
    final h = h12.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final period = h24 < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
```
```dart
  static String formatTimeOfDay12Hour(TimeOfDay time) {
    final h24 = time.hour;
    final h12 = h24 > 12 ? h24 - 12 : (h24 == 0 ? 12 : h24);
    final h = h12.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    final period = h24 < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
```
- Current behavior: الدالتان متطابقتان سطرياً عدا نوع المُدخل. (`formatCurrentTime12Hour` ثالثة بنفس النواة + ثوانٍ.)
- Why problematic: ثلاث نسخ من نفس الخوارزمية؛ تقسيم `int` بلا حد أعلى (لا تحقّق من أن `hour` ضمن 0..23).
- Violated principle: DRY.
- Current owner: `lib/core/time/time_formatter.dart`
- Correct owner: دالة داخلية `_format12(int hour, int minute, int? second)`.
- Consequences: لا أثر تنفيذي؛ تكلفة صيانة صغيرة.
- Recommended correction: ادمج الثلاث في دالة واحدة تدعم أرقام الثواني الاختيارية.
- Related files: `lib/core/utils/duration_format.dart` (نفس النمط: موحّد لكن بمحتوى مختلف — لا تعارض)
- Confidence: CONFIRMED
--------------------------------------------------

## C. Cross-file observations within this group

**(1) ما بدا خطراً وانكشف سليماً — يُوثَّق صراحةً:**

- **لا يوجد تكرار في الاعتراضات.** رغم أن العنوان يوحي باحتمال، فقد تحققت: `ApiClient` لا يضيف أي `Interceptor` (`lib/core/network/api_client.dart:41-60`)، والإضافات الثلاثة (`AuthInterceptor`, `RequestLogger`, `TimeDriftInterceptor`) تُضاف مرة واحدة في `lib/backend/providers/backend_network_providers.dart:56-71`. لا ازدواج. (**مهاكلة** هي أن `ApiClient` غير صالح بذاته — CORE-032 — لا التكرار.)
- **لا يوجد `Dio` مُنشأ في أكثر من مكان.** بحث في كامل `lib/` وجد `Dio()` واحداً فقط: `lib/core/network/api_client.dart:47` (`_dio = dio ?? Dio()`). أفضل من المتوقع.
- **`baseUrl` غير مكتوب في `core/network` بشكل صريح.** `ApiConfig` يقرأ من `String.fromEnvironment` ثم `AppEnvironmentConfig` (`lib/core/network/api_config.dart:46-53`)؛ و`backend_network_providers.dart:30-39` يضيف `/api`. لا تكرار بين الملفين.
- **لا يوجد `print()` في `lib/`.** البحث عن `^\s*print(` أعاد صفر نتيجة. `AppLogger` هو القناة الوحيدة.
- **إعادة التصدير من `core/network/core_providers.dart:13-14`** (`apiClientProvider`, `traccarNativeClientProvider`) هي محاولة **مقصودة**prevent_features من استيراد `backend/` مباشرة. النية معمارية صحيحة؛ الخلل أن التنفيذ نصّفه تحت `core/` (CORE-004).
- **`app_error.dart` ليس dumping ground.** 14 فئة، كلها متجانسة التصنيف (شبكة/مصادقة/تحقق/صلاحية/العثور/تعارض/قدرة/خادم/زمن/تخزين/مزامنة/ملكية/غير معروف). التكرار الميكانيكي في `_copyWith` هو **أثر ثانوي لكون الصنف مغلقاً ولكل فئة حقولها**، لا ازدواج تصميمي. المشكلة ليست الحجم بل **ثلاثة أنواع منها لا تُستخدم** (CORE-009) و**ازدواج النظام مع `Failure`** (CORE-010).
- **`network_guard.dart` و`user_facing_message.dart` و`api_response.dart` و`ports/secure_storage_port.dart` و`runtime_selection.dart`** كلّها مصمَّمة جيداً وتستحق الثناء — موثّقة بالعقد، نقية، وقابلة للاختبار.

**(2) الأنماط العرضية عبر المجموعة:**

- **`// ignore_architecture` على الاستيرادات التي تعبر حدود الطبقات** في `core/di/app_providers.dart`، و`core/di/auth_local_data_source_provider.dart`، و`core/config/server_config_store.dart`، و`core/network/api_client.dart`، و`core/network/error_mapper.dart`، و`core/network/lenient_json_transformer.dart` — بينما `core/providers/driver_rules_provider.dart` و`core/events/eld_events_provider.dart` (الأسوأ) **بلا علامة أصلاً**. هذا نمط بحد ذاته: الانتهاكات «المعلَنة» أخفّ خطورةً ظاهرياً من غير المعلَنة لأنها توحي بأنها روجعت.
- **حالة ثابتة عامة** في موضعين فقط: `SessionEpoch._value` (`lib/core/session/session_epoch.dart:19`) — مقصود وموثّق، وقابل للاختبار؛ و`_defaultNetworkInfo` (`lib/core/utils/repository_helper.dart:7`) — غير مقصود ولا مُدار (CORE-017).
- **`catch (_)` / `catch (e)` يبتلع بصمت** في: `network_info.dart:42` (مع تعليق)، `server_config_store.dart:36`، `trusted_time_provider.dart:82,121,209,221`، `user_preferences_storage_service` لا، `app_date_utils.dart:12` (fallback)، `quick_actions_initializer.dart:39-41` (فارغ تماماً — **الوحيد الفارغ**)، `bluetooth_service.dart:88`. أربعة منها في مسار زمني/قانوني.
- **خمس مفاتيح preferences معرَّفة حرفياً في أكثر من مكان**: `'url'`, `'id'`, `'language'`, `'theme'`, `'hos_configuration'`, `'trusted_time_anchor'` (CORE-020، CORE-035).
- **ثلاث خدمات في `core/services` متشابهة الغرض**: `tracking_config_storage_service`، و`user_preferences_storage_service` (كلاهما فوق `SharedPreferencesWithCache`)، و`local_storage_service` (واجهة facade لهما). التقسيم مقصود لكنه ينتج استيراداً دائرياً (CORE-018).
- **`app/` يستورد `core/` و`features/` و`backend/` بحرية** — وهذا **مقبول**: `app/` هي طبقة التطبيق (composition + orchestration)، والاعتماد من أعلى إلى أسفل مسموح على `features`. المشكلة الوحيدة: `app/` يبني كائنات يدوياً (CORE-005) ويستخدم `HttpClient` خاماً (CORE-016).

**(3) خريطة الاعتماد الفعلية المستخرجة (بدقة):**

```
lib/core/  ──▶  features/**        (5 استيرادات: driver_rules_provider, eld_events_provider,
                                    di/app_providers, di/auth_local_data_source_provider,
                                    + widgets/connection_status_indicator خارج النطاق)
lib/core/  ──▶  backend/           (server_config_store عبر domain/config؛ app_providers؛ core_providers re-export)
lib/app/   ──▶  features/**, core/**            (مسموح)
lib/routes/ ──▶ features/**/presentation/pages  (مسموح)
lib/core/  ──▶  l10n/              (user_facing_message, localization_helper, context_extensions)
lib/core/  ──▶  core/theme/        (context_extensions, design_system) — جسر معلن في design_system.dart:1-6
```

**(4) المسارات الميتة المؤكدة بالبحث النصي:**
- `core/error/exception.dart`: 7 فئات، موقع `throw` واحد في `lib/` كله.
- `AppConstants`: 7 ثوابت تخزين + 3 ثوابت إعدادات + `maxRetryAttempts`, `retryDelay`, `syncInterval`, `maxOfflineInspections`, `maxLocalImages` — الاستعمال الوحيد المؤكد `appVersion`.
- `StorageConstants.serverUrl`, `deviceId`, `eventLogs`: غير مستخدمة.
- `core/network/core_providers.dart:40-42` (`secureStorageProvider` من نوع `FlutterSecureStorage`): غير مستخدم.
- `core/services/utc_sync_service.dart`: لا مستهلك لـ`utcNow`/`syncedTime`.
- `TimeUnavailableError`, `StorageError`, `UnsupportedCapabilityError`: لا بنّاء واحد.
- `TrustLevel`/`trustLevel`: لا قارئ خارج ملف التعريف.
- `UserModel.fromJson({String? defaultEmail})`, `fromMetadata({String? defaultEmail})`: المعاملان غير مستخدمين.
- `location_point.dart` (12 سطراً): لم أتحقق من وجود منافس لها في features (خارج نطاق القراءة) — **يقتصر الانتباه عليه**.
- `lib/backend/http/api_config.dart` و`lib/backend/http/api_response.dart`: **ملفان ميتان كلياً — كل محتواهما معلَّق بـ`//`**، رغم أن ترويسة الملفين تقول «DEPRECATED». (خارج نطاق القراءة — لُوحظا كدليل مساند.)

---

## D. List of every file you read (proof of coverage)

**70 ملفاً — 4,812 سطراً غير فارغ — كلها مقروءة بالكامل.**

### Entry points & app shell (3)
1. `lib/main.dart` (64 / 54)
2. `lib/app.dart` (114 / 103)
3. `lib/routes.dart` (100 / 86)

### `lib/app/` (4)
4. `lib/app/app_initializer.dart` (119 / 101)
5. `lib/app/orchestrators/tracking_orchestrator.dart` (110 / 96)
6. `lib/app/services/push_notification_service.dart` (156 / 137)
7. `lib/app/services/quick_actions_initializer.dart` (77 / 68)

### `lib/routes/` (5)
8. `lib/routes/account_routes.dart` (46 / 44)
9. `lib/routes/auth_routes.dart` (39 / 37)
10. `lib/routes/dvir_routes.dart` (33 / 31)
11. `lib/routes/home_routes.dart` (38 / 36)
12. `lib/routes/logs_routes.dart` (43 / 41)

### `lib/core/network/` (9)
13. `lib/core/network/api_client.dart` (345 / 318)
14. `lib/core/network/api_config.dart` (109 / 93)
15. `lib/core/network/api_response.dart` (157 / 138)
16. `lib/core/network/error_mapper.dart` (228 / 204)
17. `lib/core/network/lenient_json_transformer.dart` (34 / 30)
18. `lib/core/network/network_guard.dart` (29 / 27)
19. `lib/core/network/network_info.dart` (57 / 49)
20. `lib/core/network/core_providers.dart` (66 / 56)

### `lib/core/error/` (4)
21. `lib/core/error/app_error.dart` (565 / 504)
22. `lib/core/error/exception.dart` (77 / 57)
23. `lib/core/error/failure.dart` (136 / 113)
24. `lib/core/error/user_facing_message.dart` (99 / 92)

### `lib/core/result/` (1)
25. `lib/core/result/result.dart` (104 / 86)

### `lib/core/config/` (5)
26. `lib/core/config/app_environment.dart` (106 / 90)
27. `lib/core/config/hos_configuration.dart` (99 / 93)
28. `lib/core/config/runtime_selection.dart` (61 / 53)
29. `lib/core/config/server_config_provider.dart` (8 / 7)
30. `lib/core/config/server_config_store.dart` (79 / 67)

### `lib/core/di/` (3)
31. `lib/core/di/app_providers.dart` (33 / 25)
32. `lib/core/di/auth_local_data_source_provider.dart` (11 / 9)
33. `lib/core/di/id_generator_provider.dart` (6 / 5)

### `lib/core/providers/` + `lib/core/session/` (2)
34. `lib/core/providers/driver_rules_provider.dart` (24 / 21)
35. `lib/core/session/session_epoch.dart` (31 / 28)

### `lib/core/storage/` (3)
36. `lib/core/storage/storage_providers.dart` (12 / 10)
37. `lib/core/storage/adapters/flutter_secure_storage_adapter.dart` (29 / 21)
38. `lib/core/storage/ports/secure_storage_port.dart` (17 / 13)

### `lib/core/services/` (6)
39. `lib/core/services/bluetooth_service.dart` (97 / 83)
40. `lib/core/services/local_database_service.dart` (31 / 26)
41. `lib/core/services/local_storage_service.dart` (225 / 190)
42. `lib/core/services/tracking_config_storage_service.dart` (107 / 98)
43. `lib/core/services/user_preferences_storage_service.dart` (40 / 32)
44. `lib/core/services/utc_sync_service.dart` (50 / 44)

### `lib/core/time/` (5)
45. `lib/core/time/monotonic_time_authority.dart` (56 / 50)
46. `lib/core/time/time_authority.dart` (70 / 61)
47. `lib/core/time/time_authority_provider.dart` (31 / 29)
48. `lib/core/time/time_formatter.dart` (45 / 41)
49. `lib/core/time/trusted_time_provider.dart` (230 / 197)

### `lib/core/utils/` (8)
50. `lib/core/utils/app_date_utils.dart` (16 / 15)
51. `lib/core/utils/duration_format.dart` (21 / 20)
52. `lib/core/utils/id_generator.dart` (12 / 9)
53. `lib/core/utils/localization_helper.dart` (52 / 50)
54. `lib/core/utils/logger.dart` (37 / 31)
55. `lib/core/utils/provider_cache.dart` (18 / 16)
56. `lib/core/utils/repository_helper.dart` (61 / 58)
57. `lib/core/utils/status_color_helper.dart` (8 / 7)

### `lib/core/events/` + `extensions` + `localization` + design system (5)
58. `lib/core/events/app_events.dart` (18 / 15)
59. `lib/core/events/eld_events_provider.dart` (18 / 15)
60. `lib/core/extensions/context_extensions.dart` (112 / 94)
61. `lib/core/localization/locale_provider.dart` (41 / 34)
62. `lib/core/design_system.dart` (19 / 17)

### `lib/core/constants/` (4)
63. `lib/core/constants/app_constants.dart` (53 / 45)
64. `lib/core/constants/channel_constants.dart` (5 / 5)
65. `lib/core/constants/fmcsa_constants.dart` (41 / 30)
66. `lib/core/constants/storage_constants.dart` (15 / 13)

### `lib/core/data/` + `lib/core/domain/` (4)
67. `lib/core/data/models/user_model.dart` (99 / 91)
68. `lib/core/domain/entities/hos_models.dart` (316 / 278)
69. `lib/core/domain/entities/location_point.dart` (12 / 11)
70. `lib/core/domain/entities/user.dart` (77 / 64)

---

### مُلحق — ملفات خارج النطاق قُرئت كدليل مساند (لا تدخل في التغطية)

قرأتُ هذه للتحقق من ادعاءات عبر-الملفات فقط، ولم أُدرجها في قائمة التغطية ولا في مخرجات Per-file:

- `lib/backend/providers/backend_network_providers.dart` (82 سطراً) — ضروري لإثبات CORE-005 (نسختا `TrackingService`) وCORE-032 (تثبيت الاعتراضات خارج `ApiClient`) وCORE-016.
- `lib/backend/http/interceptors/auth_interceptor.dart` (144) — للتحقق من عدم تكرار الاعتراضات وسلوك 401/epoch.
- `lib/backend/http/interceptors/request_logger.dart` (134) — للتحقق من وجود إخفاء (`_redactSensitiveData`) بدل `print()`.
- `lib/backend/http/interceptors/time_drift_interceptor.dart` (67) — للتحقق من أن المرساة الخادمية تمر عبر `Date` header فقط.
- `lib/features/tracking/data/services/tracking_service.dart:190-204` — للتحقق من تعريف `trackingServiceProvider` الثاني.
- `lib/features/tracking/data/providers/tracking_providers.dart` (51) — للتحقق من `trackingServiceFullProvider`.
- `lib/features/auth/data/datasources/auth_local_data_source.dart` (مقتطفات بالبحث) — للتحقق من أن التوكن في `FlutterSecureStorage` لا في preferences.
- `lib/backend/http/api_config.dart`, `lib/backend/http/api_response.dart` (7 لكلٍّ) — ملفان ميتان (محتواهما تعليقات فقط).
- `analysis_options.yaml`, `.gitignore`, `.env`, `.env.example`, `.env.test` — للتحقق من CORE-004 وCORE-015.

### التحقق المتقاطع المنفَّذ

| ما دُعي في النطاق | نتيجة البحث الفعلي |
|---|---|
| `Dio()` في أكثر من مكان | 1 فقط: `core/network/api_client.dart:47` |
| اعتراضات مكرّرة بين `api_client` و`backend/http/interceptors` | 0 — التقسيم صحيح (لكن `ApiClient` غير مكتمل بذاته، CORE-032) |
| `core/` يستورد `features/` | 5 ملفات (CORE-001، CORE-002، CORE-003 ×2) |
| `print(` في `lib/` | 0 |
| `throw <X>Exception` من `core/error/exception.dart` | 1 فقط في كامل `lib/` |
| `TrustLevel` / `trustLevel` مستهلَك | 0 خارج ملف التعريف |
| بنّاءو `TimeUnavailableError` / `StorageError` / `UnsupportedCapabilityError` | 0 |
| بنّاءو `ConflictError` / `ValidationError` | مستخدَمان في `core/network/error_mapper.dart` |
| مستهلكو `utcNow` / `syncedTime` | 0 خارج `utc_sync_service.dart` |
| الاستيراد من `core/result/result.dart` | 35 ملفاً — العقد مُستخدم فعلاً، لكن مع تسرّب إلى `Failure` (CORE-010) |
| مستهلكو `guardedNetwork` / `executeWithHandling` | 39 استدعاءً في 6 مستودعات — كلاهما حيّ |
| `.env` متتبَّعة في git؟ | نعم: `git ls-files` يُرجع `.env`, `.env.example`, `.env.test` |

---

## ملخص تنفيذي

**الأخطر (4):**
1. **CORE-006** — ساعة الجهاز (`MonotonicTimeAuthority`) هي المزوّد الافتراضي الذي يوقّع أحداث `SyncEngine` القانونية، و`TrustLevel` لا يقرأه أحد. الحظر المكتوب في `app_initializer.dart:98-100` طُبِّق على `UtcSyncService` فقط، لا على المزوّد المستهلَك فعلياً.
2. **CORE-016** — رفع توكن الإشعارات يتجاوز `ApiClient`/`Dio` كلياً عبر `HttpClient` خام، بلا مصادقة، بلا مسار endpoint، مع تسريب connection pool.
3. **CORE-005** — كائنان حيّان من `TrackingService`، أحدهما يتجاهل منطق `mock` فيذهب إلى Traccar حقيقي في بيئة الاختبار.
4. **CORE-003 / CORE-001 / CORE-002** — `core/di` يستورد تنفيذ `features/auth/data`، و`core/providers` يستورد `features/account/presentation`، و`core/events` يستورد `features/tracking/data`.

**الأهم بنيوياً:** **CORE-004** — لا يوجد أي lint للطبقات؛ 19 تعليق `// ignore_architecture` لا تفعل شيئاً لأن `analysis_options.yaml` لا يعرّف قاعدة اسمها `architecture`. هذا ما يسمح ببقاء العشرة أعلاه.

**ما هو سليم فعلاً (يُوثَّق لمنع الإصلاح الزائد):** `Dio` واحد في المشروع، لا اعتراضات مكرّرة، لا `print()`، التوكن في `FlutterSecureStorage`، `network_guard.dart`/`user_facing_message.dart`/`runtime_selection.dart`/`secure_storage_port.dart` مصمَّمة بإتقان، و`app_error.dart` ليس dumping ground رغم حجمه.

**العدد الإجمالي:** 37 ملاحظة مُصنَّفة — **8 HIGH**، **19 MEDIUM**، **10 LOW**؛ منها **32 CONFIRMED** و**5 POTENTIAL**. التغطية: **70 ملفاً / 4,812 سطراً غير فارغ** في المجموعة.

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-002: `connection_status_indicator.dart` يُعيد بناء `AppStatusBadge` يدوياً بدل استهلاكه
- Severity: **MODERATE**
- Category: Duplication inside core / Missed design-system adoption
- Location `lib/core/widgets/connection_status_indicator.dart:60-99`
- Evidence code block:
```dart
60:    return Center(
61:      child: Container(
62:        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
63:        margin: const EdgeInsets.symmetric(horizontal: 4),
64:        decoration: BoxDecoration(
65:          color: color.withValues(alpha: 0.1),
66:          borderRadius: BorderRadius.circular(16),
67:          border: Border.all(color: color.withValues(alpha: 0.3)),
68:        ),
69:        child: Row(
70:          mainAxisSize: MainAxisSize.min,
...
82:              Icon(icon, size: 14, color: color),
83:            const SizedBox(width: 6),
84:            Flexible(
85:              child: Text(
86:                text,
87:                overflow: TextOverflow.ellipsis,
88:                style:
89:                    (Theme.of(context).textTheme.labelSmall ?? const TextStyle())
90:                        .copyWith(
91:                  color: color,
92:                  fontWeight: FontWeight.bold,
93:                ),
```
- Current behavior: حاوية `BoxDecoration` بخلفية شفافة وحدّ و`Row` ونص ملوّن — وهو بالضبط ما يقدّمه `AppStatusBadge` في `app_status_badge.dart:65-94`. الملف لا يستورد `app_status_badge.dart` إطلاقاً، بينما الملفات الشقيقة في `features` تفعل ذلك بشكل صحيح (`features/sync/presentation/widgets/sync_status_indicator.dart:27`).
- Why problematic: وجود بديلين للشارة داخل نفس الحزمة (CUI-010) مع ثالث داخل `core`؛ وقيم `alpha 0.1 / 0.3` و`radius 16` و`fontWeight: bold` مثبّتة خارج نظام التصميم، فأي تعديل على `AppStatusBadge` لن ينعكس.
- Violated principle: DRY / Single source of truth for visual tokens.
- Current owner: `lib/core/widgets/connection_status_indicator.dart:60-99`
- Correct owner: `lib/core/widgets/app_status_badge.dart` (المصدّر القياسي للشارة)
- Consequences: ثلاث تنفيذات متنافسة للشارة؛ تفاوت بصري بين شارة المزامنة وشارة الاتصال.
- Recommended correction: استبدل الحاوية بـ`AppStatusBadge(label: text, type: ..., icon: icon)`، أو — إن لزم عنصر جانبي — مرّر `AppStatusBadge` مع أيقونة `CircularProgressIndicator` في `icon`.
- Related files: `lib/core/widgets/app_status_badge.dart:65-94`, `lib/features/sync/presentation/widgets/sync_status_indicator.dart:27-42`, `lib/core/theme/app_radius.dart:21-30`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-004: `eld_graph_grid.dart` يُضمّن رموز الحالة التنظيمية FMCSA وترتيب صفوف المخطط داخل `core`
- Severity: **MODERATE**
- Category: Domain leakage  presented as presentation primitive / Hardcoded regulatory vocabulary
- Location `lib/core/widgets/eld_graph_grid.dart:8-9`, `:23`, `:79`, `:104-106`, `:160`, `:177`, `:330-338`
- Evidence code block:
```dart
 8:   final String status; // 'OFF', 'SB', 'D', 'ON'
 9:   final String? tag; // e.g. 'PC', 'YM'
```
```dart
23:   final Map<String, double>? rightSideStats; // Map of 'OFF', 'SB', 'D', 'ON' to hours
```
```dart
79:    final rowHeight = chartHeight / 4.0; // 4 rows: OFF, SB, D, ON
```
```dart
102:  void _drawTimeAxis(Canvas canvas, double offsetX, double chartWidth, double height) {
103:    final hours = [
104:      'M', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11',
105:      'N', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', 'M'
106:    ];
```
```dart
330:  double _getYPosition(String status, double rowHeight) {
331:    switch (status) {
332:      case 'OFF': return rowHeight * 0.5;
333:      case 'SB':  return rowHeight * 1.5;
334:      case 'D':   return rowHeight * 2.5;
335:      case 'ON':  return rowHeight * 3.5;
336:      default:    return rowHeight * 0.5;
337:    }
338:  }
```
- Current behavior: `core` يحمل (أ) مفردات الحالة التنظيمية كـ`String` حرة، و(ب) **ترتيب صفوف مخطط ساعات العمل**. ملاحظة تقنية: `_getYPosition` يستعمل `rowHeight * N.5` وليس `rowHeight * N`، فالمقادير الفعلية `0.5r / 1.5r / 2.5r / 3.5r`؛ وبما أن الرسم يبدأ بـ`canvas.translate(0, timeAxisHeight)` تُقصّ الصفوف العليا والسفلى جزئياً خارج `chartHeight`. وبغض النظر عن ذلك، **الترتيب مقصود ومثبّت**.
- Why problematic:
  1. **`_getYPosition` تكرار منطقي**: توجد خريطتان مستقلتان لنفس المعرفة — `inspection_duty_graph.dart:130-162` (`_rowOf`) و`log_graph.dart:46-53` (`normalized`) — وكلتاهما تفرض **نفس** الترتيب. ثلاث نسخ من قاعدة واحدة.
  2. **الترتيب قرار تنظيمي**: مخطط Graph of Duty Status في 49 CFR 395.8 يحدّد الترتيب `OFF / SB / D / ON`. وضعه في `core` يعني أن `core` يحمل معرفة تنظيمية.
  3. **`default:` يبتلع أي رمز جديد بصمت** (السطر 336): رمز غير معروف يُرسم كـ`OFF` — وهو خطأ صامت في سياق تنظيمي.
  4. **نصوص إنجليزية مُشفّرة** (`:104-106`, `:160`, `:177`) لا تمرّ بـ`AppLocalizations`، وهي عناوين المخطط المعروضة للضابط على الطريق. وبالمقابل `eld_events_table.dart` يمرّر عناوينه عبر `context.loc` (`:62-99`)، فهناك تباين غير مبرَّر.
- Violated principle: Domain model must not be re-encoded in the UI layer; Policy (regulatory row order) belongs to domain.
- Current owner: `lib/core/widgets/eld_graph_grid.dart`
- Correct owner: `DutyStatusCode` (`lib/domain/duty_status/duty_status_code.dart:10-16`، وهو يملك `shortCode`) يوفّر الترتيب؛ و`core` يستقبل ترتيب الصفوف جاهزاً كمعامل.
- Consequences: إضافة حالة جديدة كصف مستقل تتطلب تعديل `core`؛ انحراف بصري صامت عند رموز غير معروفة؛ خطر اختلاف ترتيب الصفوف بين المخططات الثلاثة دون ضابط.
- Recommended correction: مرّر `required List<String> rowOrder` و`required Map<String, int> rowIndex` إلى `EldGraphGrid`؛ واجعل `switch` يُبرز الحالات غير المعروفة بدل ابتلاعها؛ وانقل نصوص المحاور إلى `AppLocalizations`.
- Related files: `lib/features/inspection/presentation/widgets/inspection_duty_graph.dart:22-29,130-162`, `lib/features/logs/presentation/widgets/log_graph.dart:25-30,46-53`, `lib/domain/duty_status/duty_status_code.dart:10-16,53-56`
- Confidence: **CONFIRMED** (للرموز والترتيب) / **POTENTIAL** (هل يجب أن يكون الرسم قابلاً لإعادة الاستخدام خارج ELD — قد يكون مقصوداً)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-007: `app_theme.dart` يحمل قيم `Color(0x...)` خارج `AppColors` — أحدها تكرار حرفي
- Severity: **MINOR**
- Category: Design-token rule violation / Duplication
- Location `lib/core/theme/app_theme.dart:175`, `:215`, `:220`
- Evidence code block:
```dart
170:    radioTheme: RadioThemeData(
171:      fillColor: WidgetStateProperty.resolveWith((states) {
172:        if (states.contains(WidgetState.selected)) {
173:          return AppColors.primaryGold;
174:        }
175:        return const Color(0xFFC7C7CC);
176:      }),
```
```dart
214:    dividerTheme: light.dividerTheme.copyWith(
215:      color: const Color(0xFF48484A),
216:    ),
...
220:    disabledColor: const Color(0xFF8E8E93),
```
- Current behavior: `app_colors.dart:3` يعلن صراحةً أنه **الملف الوحيد الذي يحمل قيمة `Color(0x...)`** ويكررها في السطر 13. ثلاثة انتهاكات في نفس الملف:
  - `:175` قيمة `0xFFC7C7CC` بلا اسم ولا معنى دلالي.
  - `:215` قيمة `0xFF48484A` — فاصل داكن بلا رمز (يقابله `AppColors.darkBorder` في `:147` و`AppColors.border` في `:67`).
  - `:220` قيمة `0xFF8E8E93` — **تكرار حرفي كامل** لـ`app_colors.dart:124`.
- Evidence for the duplication:
```dart
// lib/core/theme/app_colors.dart
124:   static const Color navBarInactive = Color(0xFF8E8E93);
```
- Why problematic: وجود قيمة واحدة بلا اسم دلالي (`disabledColor`) وأخرى باسمها (`navBarInactive`) في الملفين يجعل «المصدر الوحيد» غير صحيح؛ وتغيير لون معطّل واحد يجب أن يمرّ بمكانين.
- Violated principle: Single source of truth — القاعدة التي أعلنها المشروع نفسه.
- Current owner: `lib/core/theme/app_theme.dart`
- Correct owner: `lib/core/theme/app_colors.dart` بأسماء دلالية (`radioUnselected`, `darkDivider`, `disabledGrey`).
- Consequences: انجراف لوني صامت؛ استثناءات متكررة بنفس القيمة.
- Recommended correction: أضف `radioUnselected = Color(0xFFC7C7CC)` و`darkDivider = Color(0xFF48484A)` و`disabledGrey = Color(0xFF8E8E93)` في `AppColors`، واستبدل `:220` بـ`AppColors.navBarInactive`.
- Related files: `lib/core/theme/app_colors.dart:3,13,67,124,147`, `lib/core/theme/app_typography.dart:2`, `lib/core/theme/press_feedback.dart:32-33`, `lib/core/theme/app_shadows.dart:14,23`, `lib/core/widgets/app_feedback.dart:70`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-009: `eld_card.dart` يُعيد تعريف قيم `cardTheme` بدل استهلاك `AppDecorations.card`
- Severity: **MINOR**
- Category: Duplication inside core / Design-system bypass
- Location `lib/core/widgets/eld_card.dart:20-30`
- Evidence code block:
```dart
20:    return Card(
21:      clipBehavior: Clip.antiAlias,
22:      color: Theme.of(context).cardTheme.color ??
23:          Theme.of(context).colorScheme.surface,
24:      elevation: 0.5,
25:      shadowColor:
26:          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
27:      margin: EdgeInsets.zero,
28:      shape: RoundedRectangleBorder(
29:        borderRadius: BorderRadius.circular(AppRadius.card),
30:      ),
```
- Current behavior: **`eld_card.dart` يكرّر القيم الخمس نفسها حرفاً بحرف** كما في `app_theme.dart:50-58`:
```dart
50:    cardTheme: CardThemeData(
51:      color: AppColors.surface,
52:      elevation: 0.5,
53:      shadowColor: Colors.black.withValues(alpha: 0.05),
54:      shape: RoundedRectangleBorder(
55:        borderRadius: BorderRadius.circular(AppRadius.card),
56:      ),
57:      margin: EdgeInsets.zero,
58:    ),
```
  أي أن `eld_card.dart` **يلغي** ما عرّفه الثيم، ويجعل `shadowColor` مشتقاً من `onSurface` بدل `black` كما في الثيم.
- Why problematic: صنف في `core` يعيد تعريف نفس القيم الخمس؛ أي تعديل على `cardTheme` لن ينعكس على البطاقات الأكثر استخداماً.
- Violated principle: DRY / single source of truth for visual tokens.
- Current owner: `lib/core/widgets/eld_card.dart:20-30`
- Correct owner: `lib/core/theme/app_theme.dart:50-58` للقيم، و`lib/core/theme/app_decorations.dart:18-28` للزخرفة.
- Consequences: ازدواج بصري محتمل بين بطاقات `Card` وبطاقات `Container`.
- Recommended correction: احذف الصفات الخمس من `EldCard` واعتمد على `cardTheme`؛ أو استخدم `AppDecorations.card(context)` مع `Material`.
- Related files: `lib/core/theme/app_theme.dart:50-58`, `lib/core/theme/app_decorations.dart:18-28`, `lib/features/about/presentation/pages/about_page.dart:13`, `lib/features/settings/presentation/pages/settings_page.dart:11`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-010: نظام التصميم فيه بديلان متداخلان للشارة (`AppStatusBadge` و`AppStatusPill`)
- Severity: **MINOR**
- Category: Duplication inside core / Overlapping primitives
- Location `lib/core/widgets/app_status_pill.dart:28-51` و `lib/core/widgets/app_status_badge.dart:65-94`
- Evidence code block:
```dart
// lib/core/widgets/app_status_pill.dart
28:    return Container(
29:      padding: const EdgeInsets.symmetric(
30:        horizontal: AppSpacing.sm,
31:        vertical: 4,
32:      ),
33:      decoration: AppDecorations.tinted(color),
34:      child: Row(
35:        mainAxisSize: MainAxisSize.min,
36:        children: [
37:          if (icon != null) ...[
38:            Icon(icon, size: iconSize, color: color),
39:            const SizedBox(width: 6),
40:          ],
41:          Text(
42:            label,
43:            style: TextStyle(
44:              color: color,
45:              fontSize: 12,
46:              fontWeight: AppTypography.semiBold,
47:            ),
48:          ),
```
```dart
// lib/core/widgets/app_status_badge.dart
65:    return Container(
66:      padding: const EdgeInsets.symmetric(
67:        horizontal: AppSpacing.sm,
68:        vertical: AppSpacing.xs,
69:      ),
70:      decoration: BoxDecoration(
71:        color: _getBackgroundColor(brightness),
72:        borderRadius: BorderRadius.circular(AppRadius.badge),
73:      ),
74:      child: Row(
75:        mainAxisSize: MainAxisSize.min,
76:        children: [
77:          if (icon != null) ...[
78:            Icon(icon, size: 14, color: textColor),
```
- Current behavior: كلاهما: `Container` + `EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4)` + `Row(mainAxisSize: .min)` + أيقونة اختيارية + نص ملوّن. الفرق الوحيد: مصدر اللون (نوع محسوم داخلياً مقابل لون مُمرَّر) و`borderRadius` (`AppRadius.badge = 8` مقابل `AppRadius.pill = 999`).
- Why problematic: لا يوجد دليل في الملفات على أيّهما هو المعيار: `AppStatusPill` مُصدَّر من `core/design_system.dart:19` بينما `AppStatusBadge` لا. والاستهلاك في `features` منقسم: `app_status_badge` في أربعة ملفات، `app_status_pill` في ملف واحد (`features/dvir/presentation/pages/dvir_list_page.dart:11`).
- Violated principle: DRY / clear design-system API.
- Current owner: `lib/core/widgets/` (الاثنين)
- Correct owner: `lib/core/widgets/app_status_badge.dart` كوحيد، مع `variant: {pill, badge}`.
- Consequences: تباين بصري بين شارات في شاشات مختلفة؛ عبء معرفي للمطوّر.
- Recommended correction: ادمجهما في صنف واحد بأسلوب (`radius`) كمعامل؛ واحذف التصدير المفرد من `design_system.dart`.
- Related files: `lib/core/design_system.dart:19`, `lib/features/dvir/presentation/pages/dvir_list_page.dart:11,204`, `lib/features/vehicle/presentation/widget/vehicle_card.dart:4`, `lib/features/permissions/presentation/pages/permissions_page.dart:8`, `lib/features/codriver/presentation/pages/codriver_page.dart:7`, `lib/features/sync/presentation/widgets/sync_status_indicator.dart:5`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-011: `app_button.dart` يُعيد تنفيذ منطق الضغط بدل استهلاك `PressFeedback.pressed`
- Severity: **MINOR**
- Category: Duplication inside core / Design-system bypass
- Location `lib/core/widgets/app_button.dart:124-132` مقابل `lib/core/theme/press_feedback.dart:25-30`
- Evidence code block:
```dart
124:    final overlay = _isOutlined
125:        ? AppColors.primaryGold.withValues(alpha: 0.12)
126:        : (widget.type == EldButtonType.danger
127:            ? Colors.white.withValues(alpha: 0.28)
128:            : Colors.black.withValues(alpha: 0.24));
...
130:    final color = _pressed && _enabled
131:        ? (_isOutlined ? overlay : Color.alphaBlend(overlay, base))
132:        : base;
```
```dart
// lib/core/theme/press_feedback.dart
25:  static Color pressed(Color base, {bool onDark = false}) {
26:    return Color.alphaBlend(
27:      (onDark ? Colors.white : Colors.black).withValues(alpha: 0.20),
28:      base,
29:    );
30:  }
```
- Current behavior: `AppButton` يحمل حالته `_pressed` (`:51`) ويدمج `overlay` بنفسه بقيمة `alpha 0.24`، بينما `PressFeedback.pressed` تستخدم `0.20`. **قيمتان مختلفتان في ملفين لنفس التأثير**، و`app_button.dart` لا يستورد `press_feedback.dart` إطلاقاً رغم أنه في نفس `core`.
- Why problematic: صنفان في نفس المجلد يُعطيان استجابة ضغط مختلفة قليلاً، بينما الثيم كله يستورد `PressFeedback` (`app_theme.dart:32,70,81,89,99,108`).
- Violated principle: DRY / consistent color token.
- Current owner: `lib/core/widgets/app_button.dart:124-132`
- Correct owner: `lib/core/theme/press_feedback.dart:25-30`
- Consequences: تفاوت بصري بين أزرار `AppButton` وأزرار الثيم.
- Recommended correction: استدعِ `PressFeedback.pressed(base, onDark: ...)` واحذف الدمج اليدوي، أو وحّد قيمة `alpha` في مكان واحد.
- Related files: `lib/core/theme/press_feedback.dart:8-30`, `lib/core/theme/app_theme.dart:32-33,70-73`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-013: `duty_status_code.dart` يضع `Color` في `domain` بتعليقات مُضلِّلة لا تطابق `AppColors` فعلياً
- Severity: **MODERATE**
- Category: Domain pollution / False cross-reference / Duplication risk
- Location `lib/domain/duty_status/duty_status_code.dart:7`, `:74-88`
- Evidence code block:
```dart
7: import 'package:flutter/widgets.dart';
```
```dart
74:   /// UI Color representation mapping
75:   Color get displayColor {
76:     switch (this) {
77:       case DutyStatusCode.onDutyNotDriving:
78:       case DutyStatusCode.yardMove:
79:       case DutyStatusCode.personalConveyance:
80:         return const Color(0xFFFBBF24); // AppColors.primaryGold
81:       case DutyStatusCode.offDuty:
82:         return const Color(0xFF6B7280); // AppColors.textSecondary
83:       case DutyStatusCode.driving:
84:         return const Color(0xFF10B981); // AppColors.successGreen
85:       case DutyStatusCode.sleeperBerth:
86:         return const Color(0xFFF59E0B); // AppColors.warningYellow
87:     }
88:   }
```
- Current behavior: **إجابة دقيقة على السؤال 6 — لا يوجد تكرار حرفي، بل العكس: التعليقات الأربعة كلها تدّعي مساواة قيم `AppColors` وهي كاذبة.** جدول التحقق الكامل:

| السطر | القيمة في `duty_status_code.dart` | الرمز المذكور | القيمة الفعلية في `app_colors.dart` | مطابقة؟ |
|---|---|---|---|---|
| `:80` | `0xFFFBBF24` | `AppColors.primaryGold` | `0xFFD4AF37` (`app_colors.dart:21`) | لا |
| `:82` | `0xFF6B7280` | `AppColors.textSecondary` | `0xFF5C5C5C` (`app_colors.dart:73`) | لا |
| `:84` | `0xFF10B981` | `AppColors.successGreen` | `0xFF34C759` (`app_colors.dart:37`) | لا |
| `:86` | `0xFFF59E0B` | `AppColors.warningYellow` | `0xFFFF9500` (`app_colors.dart:39`) | لا |

  أضف إلى ذلك أن `domain` يستورد `package:flutter/widgets.dart` في السطر 7، وأن `duty_status_code.dart:8` يستورد `core/utils/logger.dart`.
- Why problematic:
  1. **`domain` يحمل `Color`** — ربط بالمكتبة البيانية داخل الطبقة الأعمق، ويجعل `domain` غير قابل لإعادة الاستخدام خارج Flutter.
  2. **ألوان مكرّرة بأسمائها**: المبرر يقول `AppColors.primaryGold` بينما القيمة مختلفة؛ أي مطوّر سيصلح السطر الناقص ظناً أنه تكرار.
  3. **تثليث خرائط الحالة إلى اللون** (انظر CUI-022).
- Violated principle: Dependency Rule — الـdomain لا يعتمد على إطار العمل ولا على الطبقة الخارجية.
- Current owner: `lib/domain/duty_status/duty_status_code.dart:75-88`
- Correct owner: `lib/core/theme/app_colors.dart` أو ملف `core/presentation/status_palette.dart`؛ ويبقى `domain` على `DutyStatusCode` فقط.
- Consequences: تلوين غير متسق بين الشاشات (لون من `displayColor` وآخر من `AppColors` لنفس الحالة)، ومبرِّر مضلِّل يُضلِّل الصيانة.
- Recommended correction: احذف `displayColor` و`import 'package:flutter/widgets.dart'`؛ وأنشئ `AppStatusPalette.forDutyStatus(DutyStatusCode)` في `core/` يُشير إلى `AppColors`، واستبدل كل `StatusColorHelper.getStatusColor(...)` به.
- Related files: `lib/core/theme/app_colors.dart:21,37,39,73`, `lib/core/utils/status_color_helper.dart:1-8`, `lib/features/logs/presentation/pages/inspection_preview_page.dart:273-286`, `lib/domain/duty_status/duty_status_code.dart:8`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-014: `eld_info_row.dart` يُعيد تنفيذ ألوان الضغط بدل `PressFeedback`
- Severity: **MINOR**
- Category: Design-system bypass / Hardcoded interaction colors
- Location `lib/core/widgets/eld_info_row.dart:23-26`
- Evidence code block:
```dart
23:    return InkWell(
24:      onTap: onTap,
25:      splashColor: Colors.black.withValues(alpha: 0.12),
26:      highlightColor: Colors.black.withValues(alpha: 0.06),
```
- Current behavior: قيم تفاعل مُشفّرة (0.12 و0.06)، بينما `PressFeedback.overlay()` في `press_feedback.dart:8-23` يقدّم 0.18 و0.06 — والدالة موجودة ومستخدمة في كل الثيم (`app_theme.dart:73,84,94,102,111,202`). والملف لا يستورد `press_feedback.dart`.
- Why problematic: صنف مشترك في `core` يخالف القاعدة التي يعلنها `app_shadows.dart:6-7` (عدم كتابة قيم التصميم مباشرة في الشاشات)، بمثلها في اللون.
- Violated principle: DRY / design-token adoption.
- Current owner: `lib/core/widgets/eld_info_row.dart:25-26`
- Correct owner: `lib/core/theme/press_feedback.dart:8-23`
- Consequences: تفاوت طفيف في الاستجابة بين الصفوف وبقية التطبيق.
- Recommended correction: احذف السطرين أو استخدم `PressFeedback.overlay()`.
- Related files: `lib/core/theme/press_feedback.dart:8-23`, `lib/core/theme/app_theme.dart:73`
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CUI-016: مواضع في `features/**` تُعيد تنفيذ ما تقدمه `core/widgets` (تكميم)
- Severity: **MODERATE**
- Category: Duplication / Shared-widget bypass
- Location المرجع: `lib/core/widgets/eld_retry_view.dart:22-50` مقابل خمسة مواضع في `features`
- Evidence code block:
```dart
// المرجع — lib/core/widgets/eld_retry_view.dart:36-45
36:            IconButton(
37:              tooltip: context.loc.retryButton,
38:              iconSize: 40,
39:              color: context.styles.gold.color,
40:              onPressed: onRetry,
41:              icon: Icon(
42:                Icons.refresh,
43:                color: context.styles.gold.color,
44:              ),
45:            ),
```
```dart
// إعادة تنفيذ 1 — lib/features/logs/presentation/pages/edit_log_page.dart:379-395
379:            : vehicleState.error != null && vehicles.isEmpty
380:                ? Column(
381:                    mainAxisSize: MainAxisSize.min,
382:                    children: [
383:                      Text(
384:                        vehicleState.error!,
385:                        style: context.styles.error,
386:                      ),
387:                      const SizedBox(height: 8),
388:                      TextButton(
389:                        onPressed: () => ref
390:                            .read(vehicleProvider.notifier)
391:                            .loadVehicles(forceRefresh: true),
392:                        child: Text(context.loc.retryButton),
393:                      ),
394:                    ],
395:                  )
```
```dart
// إعادة تنفيذ 2 — lib/features/logs/presentation/pages/unidentified_events_page.dart:247-258
247:                if (state.error != null)
248:                  MaterialBanner(
249:                    content: Text(state.error!, style: context.styles.error),
250:                    actions: [
251:                      TextButton(
252:                        onPressed: _load,
253:                        child: Text(
254:                          context.loc.retryButton,
255:                        ),
256:                      ),
257:                    ],
258:                  ),
```
- Current behavior: التكميم الكامل في القسم C. الخلاصة: **`EldRetryView` مُستخدم في ثمانية ملفات**، ومع ذلك **خمسة مواضع** في `features` تُصمّم واجهة «رسالة + إعادة محاولة» يدوياً.
- Why problematic: عدم اتساق في الشكل والحجم والموضع بين الشاشات؛ وصعوبة تطبيق أي تحسين مركزي.
- Violated principle: DRY / shared-component adoption.
- Current owner: الصفحات في `features`
- Correct owner: `lib/core/widgets/eld_retry_view.dart`
- Consequences: خمسة أنماط مختلفة للخطأ نفسه.
- Recommended correction: وحّد الاستخدام؛ واعتمد `AppStatusPill` أو `AppStatusBadge` بدلاً من البطاقات اليدوية في `active_defects_section.dart`.
- Related files: انظر جدول القسم C.
- Confidence: **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-03: قيود HOS الرقمية مثبتة في طبقة العرض والعرض — 6 مواقع خارج `core/config`
- **Severity:** Critical
- **Category:** Business-Rule Duplication / Hardcoded Values
- **Location (متعدد):** انظر الجدول (C).
- **Evidence:**
```dart
// lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:85-95
    if (status == DutyStatusCode.driving) {
      const remaining = Duration(minutes: 35);
      const total = Duration(hours: 11);
      return RemainingCircle(
        remaining: remaining,
        label: 'Remaining',
        progress: (total.inMinutes - remaining.inMinutes) / total.inMinutes,
      );
    }
    const remaining = Duration(hours: 2, minutes: 8);
    const total = Duration(hours: 14);
```
```dart
// lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:125-145
      totalLimit = const Duration(hours: 11);
...
        totalLimit = const Duration(hours: 8);
...
        totalLimit = const Duration(hours: 14);
```
- **Current behavior:** المستودع يولّد **أرقام توازن مُختلقة** (`35` دقيقة متبقية، `2:08` للوردية) كمسار offline؛ والودجت يختار الحد الحاكم بنفسها.
- **Why problematic:** (1) `Duration(minutes: 35)` و `Duration(hours: 2, minutes: 8)` **ليستا قاعدة**، بل بيانات توازن عشوائية من نموذج تصميمي — تُعرض للسائق كوقت قانوني متبقٍ. مخالفة قانونية محتملة (FMCSA §395.24). (2) حدود `8/11/14` في الودجت تتجاهل أن `HosConfiguration` القابل للتهيئة **لا يُستخدم في الشاشة الرئيسية**. (3) تسعة أرقام متفرقة لنفس المفهوم.
- **Violated principle:** Single Source of Truth + Separation of Concerns.
- **Current owner:** متنتشر.
- **Correct owner:** `lib/core/config/hos_configuration.dart` (المصدر الصحيح فعلياً: `drivingLimitMinutes`, `shiftLimitMinutes`, `driveBeforeBreakMinutes`) + `lib/core/constants/fmcsa_constants.dart`.
- **Consequences:** تغيير قاعدة الدولة (مثلاً كندا 120/14 mentioned في `status_dashboard.dart:181`) لن ينعكس على الشاشة الرئيسية؛ أرقام مختلقة في وضع عدم الاتصال.
- **Recommended correction:** حذف `_circleForStatus` من المستودع؛ عند offline استخدم آخر `StatusDashboard` مخزّن كما يفعل `line 38-41`، أو أعِد `Left(NetworkFailure())` بلا تلفيق. نقل `remainingOf` وحدود 8/11/14 إلى `hos_calculator.dart` كـ `RemainingCircleCalculator`.
- **Related files:** `lib/core/config/hos_configuration.dart:27-34`, `lib/core/constants/fmcsa_constants.dart:19-34`, `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:73-100`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-10: Use-cases فارغة (Pass-Through) في مجلد domain
- **Severity:** Low
- **Category:** SRP / Speculative Generality
- **Location:** `lib/features/hos/domain/usecases/get_status_dashboard_use_case.dart:12-14` (وكذلك `get_weekly_recap_use_case.dart:12-14`، `update_duty_status_use_case.dart:12-17`)
- **Evidence:**
```dart
12:  Future<Either<Failure, StatusDashboard>> execute({DriverId? driverId}) {
13:    return _repository.getDashboard(driverId: driverId);
14:  }
```
- **Current behavior:** ثلاث فئات بلا أي منطق.
- **Why problematic:** **ليست مخالفة معمارية صريحة** — لكنها تعطي انطباعاً بوجود طبقة use-case mientras المسار الحقيقي في `logs` يتجاوزها تماماً (HL-21). الظهور والتعدد معاً يخلقان بنية زائفة.
- **Violated principle:** SRP (Softer).
- **Current owner:** — / **Correct owner:** إما تُغنى بقواعد (مثلاً رفض `updateDutyStatus` بلا `notes` لـ YM)، أو تُحذف وتُستخدم العقد مباشرة.
- **Consequences:** تضليل قارئ البنية.
- **Recommended correction:** إما أغنِها بقاعدة، أو احذفها.
- **Related files:** `lib/features/hos/presentation/providers/status_dashboard_providers.dart:35-37`
- **Confidence:** **CONFIRMED** (الوصف) — **POTENTIAL** (أنها مخالفة)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-14: مطابقة `DutyStatus ⇄ DutyStatusCode` مكرّرة ثلاث مرات
- **Severity:** Medium
- **Category:** Duplication
- **Location:** 3 مواقع
- **Evidence:**
```dart
// lib/features/hos/presentation/providers/change_status_provider.dart:37-52
  DutyStatusCode toDutyStatusCode() {
    switch (this) {
      case DutyStatusOption.offDuty:
        return DutyStatusCode.offDuty;
...
```
```dart
// lib/features/hos/presentation/providers/status_dashboard_providers.dart:18-31
DutyStatusCode _engineStatusCode(DutyStatus status) {
  switch (status) {
    case DutyStatus.driving:
      return DutyStatusCode.driving;
...
```
```dart
// lib/features/hos/presentation/providers/hos_provider.dart:59-74
  DutyStatus _mapStatus(String s) {
    final code = DutyStatusCode.fromAny(s);
    switch (code) {
```
- **Current behavior:** ثلاث دوال مطابقة في نفس المجلد، اثنتان في نفس الاتجاه.
- **Why problematic:** إضافة حالة جديدة (مثلاً `yardMove` كحالة مستقلة) تحتاج تعديل 3 مواقع؛ نسيان أحدها ينتج حالة خاطئة قانونياً.
- **Violated principle:** DRY.
- **Current owner:** presentation ×3.
- **Correct owner:** `DutyStatus` في `core/domain/entities/hos_models.dart` (المصدر الوحيد لـ `DutyStatus`).
- **Consequences:** عدم اتساق محتمل.
- **Recommended correction:** أضف `DutyStatus.toDutyStatusCode()` واحدة على الـ enum، واحذف الباقي.
- **Related files:** `lib/features/hos/domain/engine/hos_rules_engine.dart:51-64` (رابع: يقارن `DutyStatus` بـ `offDuty/sleeperBerth` مباشرة)
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-19: كيان `DailyLog` يحتوي تنسيقات عرض و`DateTime.now()` داخل getter
- **Severity:** Medium
- **Category:** SRP / Presentation in Domain
- **Location:** `lib/features/logs/domain/entities/daily_log.dart:110-155` و `:210-220`
- **Evidence:**
```dart
110:  String get dayName {
111:    final now = DateTime.now();
112:    if (date.year == now.year &&
...
115:      return 'Today';
...
123:    return ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
124:  }
126:  String get formattedDate {
127:    return '$dayName - ${[
128:      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
...
133:      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
140:    ][date.month - 1]} ${date.day}${_ordinal(date.day)}';
141:  }
```
- **Current behavior:** getter في domain يُنتج نصوصاً إنجليزية، ويقرأ ساعة الحائط عند كل استدعاء.
- **Why problematic:** (1) النصوص **غير مترجمة** بينما الواجهة تمرّرها عبر `context.loc.todayLogDate(...)` في `logs_list_page.dart:138` — طبقتان تتنافسان. (2) `DateTime.now()` في getter غير قابل للتخزين، ويجعل `props` في `Equatable` غير مستقرة إن استُخدم.
- **Violated principle:** Domain ≠ Presentation.
- **Current owner:** كيان domain.
- **Correct owner:** `core/presentation/formatters/` (المشروع يملك precedent في `core/utils/duration_format.dart`).
- **Consequences:** تواريخ إنجليزية في تطبيق عربي/إسباني.
- **Recommended correction:** انقل `dayName`/`formattedDate`/`formattedStartTime`/`formattedDuration` إلى `DateFormatters` في presentation، واحذف استدعاء `DateTime.now()` (مرّره كوسائط).
- **Related files:** `lib/features/logs/presentation/pages/logs_list_page.dart:139`, `lib/features/logs/presentation/widgets/log_detail_tabs/log_event_tile.dart:104`, `lib/features/logs/presentation/providers/edit_log_form_provider.dart:61-62`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-24: تطبيع رموز الحالات الخمسة مكرّر في 5 مواقع داخل presentation
- **Severity:** High
- **Category:** Duplication / Business Rule
- **Location:** 5 مواقع (كلها داخل `logs/presentation`)
- **Evidence:**
```dart
// log_graph.dart:47-53
      if (status == 'PC') {
        normalized = 'OFF';
      } else if (status == 'YM' || status == 'OTH' || !stats.containsKey(status)) {
        normalized = 'ON';
      } else {
        normalized = status;
      }
```
```dart
// events_tab.dart:117-121
      final key = switch (e.status) {
        'PC' => 'OFF',
        'YM' => 'ON',
        _ => e.status,
      };
```
```dart
// inspection_preview_page.dart:194-199
                              return [
                                'ON',
                                'D',
                                'SB',
                                'OFF',
                              ].contains(e.status);
```
- **Current behavior:** ثلاث نسخ من قاعدة «PC يُحسب OFF و YM يُحسب ON»، والتعليق في `inspection_preview_page.dart:192-193` يعترف بعدم اكتمالها:
```dart
  // Custom filter logic for "Active Events"
  // Currently keeps duty statuses. Implement exact logic if needed.
```
- **Why problematic:** (1) القاعدة **قانونية** (§395.28) ومعروضة للسائق في الجدول الرسمي. (2) نسخة `log_graph` تضيف `'OTH'` والثانية لا. (3) النسخة الثالثة تكسر كل الرموز (لا تطبيع).
- **Violated principle:** DRY على قاعدة قانونية.
- **Current owner:** presentation ×3 (وأخريتان للترتيب).
- **Correct owner:** `DutyStatusCode` في `lib/domain/duty_status/duty_status_code.dart` كـ `graphBucket`، أو `StatusTotalsCalculator` في `logs/domain/`.
- **Consequences:** جدول Graph-Grid قد لا يطابق جدول Total في تبويب الأحداث.
- **Recommended correction:** `String graphBucket(String shortCode)` واحدة، تستهلكها المواضع الثلاثة.
- **Related files:** `lib/features/logs/presentation/widgets/status_radio_group.dart:19-26`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-26: تنسيق الوقت والمدة مكرّر في 7 نقاط
- **Severity:** Medium
- **Category:** Duplication
- **Location:** جدول أدناه
| # | الملف:السطر | الصيغة |
|---|---|---|
| 1 | `logs/domain/entities/daily_log.dart:210-214` | `'$h:$m'` |
| 2 | `logs/domain/entities/daily_log.dart:216-220` | `'${hours}h ${minutes}m'` (بلا padding) |
| 3 | `logs/presentation/widgets/log_detail_tabs/events_tab.dart:106-110` | `'${h}h ${m.padLeft(2,'0')}m'` (**بعكس #2**) |
| 4 | `logs/presentation/pages/logs_list_page.dart:168-170` | `'< 1m'` أو حساب يدوي لـ `% 1 * 60` |
| 5 | `logs/presentation/pages/audit_trail_page.dart:77-79` | `DateFormat('yyyy-MM-dd\nHH:mm')` |
| 6 | `logs/presentation/providers/certify_log_provider.dart:177` | `DateFormat('yyyy-MM-dd')` |
| 7 | `logs/presentation/widgets/log_detail_tabs/certify_tab.dart:82-95` | regex ISO داخل widget |
- **Evidence:**
```dart
// events_tab.dart:106-110
  static String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    return '${h}h ${m.toString().padLeft(2, '0')}m';
  }
```
```dart
// daily_log.dart:216-220
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }
```
- **Current behavior:** نفس المدة تُعرض `1h 5m` في موضع و `1h 05m` في آخر.
- **Why problematic:** المشروع يملك `core/utils/duration_format.dart` (`hhMm`, `decimalHours`) و`core/time/time_formatter.dart` (4 دوال) ولم يُستخدما في Consistency.
- **Violated principle:** DRY + Presentation consistency.
- **Current owner:** متنتشر.
- **Correct owner:** `core/utils/duration_format.dart` و`core/time/time_formatter.dart`.
- **Consequences:** تباين بصري؛ خطأ حسابي في #4 (`% 1 * 60` عرضة للتقريب العشري العائم).
- **Recommended correction:** احذف #1–#4 واستخدم `DurationFormat`؛ انقل #7 إلى `TimeFormatter` باختبارات.
- **Related files:** `lib/core/utils/duration_format.dart:6,17`, `lib/core/time/time_formatter.dart:7,17,26`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-27: `TrailersPage` و `ShippingDocumentsPage` نسختان متطابقتان
- **Severity:** Medium
- **Category:** Duplication (Structural)
- **Location:** `lib/features/logs/presentation/pages/trailers_page.dart` (170) و `lib/features/logs/presentation/pages/shipping_documents_page.dart` (170)
- **Current behavior:** الملفان بنفس البنية: نفس `_controller`، نفس `_addX()`، نفس `_removeX()`، نفس الشجرة، نفس RegExp (بفرق `/` واحد).
- **Evidence (مقارنة حرفية):**
```dart
// trailers_page.dart:36-37
  List<String> get _trailers =>
      splitFormList(ref.read(dashboardDataProvider).trailerId);
```
```dart
// shipping_documents_page.dart:35-36
  List<String> get _documents =>
      splitFormList(ref.read(dashboardDataProvider).shippingDocuments);
```
```dart
// trailers_page.dart:96-102
                    inputFormatters: [
                      // نفس مجموعة المدقق (حروف كل اللغات + أرقام + -_#)
                      // — النقاط والفواصل وعلامات الرياضيات تُمنع أثناء الكتابة.
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\p{L}\p{N}\s\-_#]', unicode: true),
                      ),
                    ],
```
```dart
// shipping_documents_page.dart:97-102
                    inputFormatters: [
                      // نفس مجموعة المدقق (+ `/` لأرقام BOL).
                      FilteringTextInputFormatter.allow(
                        RegExp(r'[\p{L}\p{N}\s\-_#/]', unicode: true),
                      ),
                    ],
```
- **Why problematic:** الـ RegExp ثالث نسخة من النمط المعرَّف في المصدر الصحيح `daily_form_rules.dart:29-31`، والنسختان **ستنحرفان** عند أي تعديل.
- **Violated principle:** DRY.
- **Current owner:** presentation ×2.
- **Correct owner:** widget عام `FormListEditorPage` في `logs/presentation/widgets/` يقبل `title`, `hint`, `validator`, `allowSlash`.
- **Consequences:** صيانة مزدوجة؛ خطر انحراف قواعد الإدخال.
- **Recommended correction:** استخرج `FormListEditorPage` واحد، وحيّد الـ RegExp من `daily_form_rules.dart` مُباشرة (`isFormLabelValid` بدل RegExp مكرر).
- **Related files:** `lib/features/logs/domain/daily_form_rules.dart:29-31,46-52`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-34: خرائط رموز الحالات الخمسة: 5 نسخ داخل presentation
- **Severity:** Medium
- **Category:** Duplication
- **Location:** 5 مواقع (كلها presentation)
| # | الملف:السطر | المحتوى |
|---|---|---|
| 1 | `logs/presentation/widgets/status_radio_group.dart:19-26` | 6 رموز + تسميات |
| 2 | `logs/presentation/pages/inspection_preview_page.dart:194-199` | 4 رموز |
| 3 | `logs/presentation/pages/inspection_preview_page.dart:273-286` | 4 رموز → ألوان |
| 4 | `logs/presentation/widgets/log_graph.dart:26-30` + `:47-53` | 4 رموز + تطبيع |
| 5 | `logs/presentation/widgets/log_detail_tabs/events_tab.dart:104` | 4 رموز |
- **Current behavior:** المصدر الرسمي موجود: `lib/domain/duty_status/duty_status_code.dart` و`core/domain/entities/hos_models.dart:toShortCode()`؛ ومع ذلك كل موضع يُعيد كتابة المجموعة.
- **Why problematic:** خريطة الألوان في #3 **مكرّرة** مع `core/utils/status_color_helper.dart:5-7` الموجودة فعلاً والمُستخدمة في `log_event_tile.dart:45`. أي حالة جديدة تظهر بلون مختلف في كل شاشة.
- **Violated principle:** DRY.
- **Current owner:** presentation ×5.
- **Correct owner:** `DutyStatusCode` + `StatusColorHelper`.
- **Consequences:** شاشات متعارضة اللون.
- **Recommended correction:** في #3 استبدل `_getStatusColor` بـ `StatusColorHelper.getStatusColor(status)`؛ وفي الباقي ولّد من `DutyStatusCode.values`.
- **Related files:** `lib/core/utils/status_color_helper.dart`, `lib/domain/duty_status/duty_status_code.dart`, `lib/core/domain/entities/hos_models.dart:12-27`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-39: عتبات العرض (1 ساعة حرج، 15 دقيقة أحمر) مكتوبة داخل widgets
- **Severity:** Medium
- **Category:** Hardcoded Business Thresholds in Presentation
- **Location:** `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart:105`؛ `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:179`
- **Evidence:**
```dart
// hos_indicators_card.dart:103-105
    final isCritical =
        indicator.type == IndicatorType.remaining &&
        indicator.value <= const Duration(hours: 1);
```
```dart
// main_circular_timer.dart:178-181
    } else if (liveRemaining <= Duration.zero ||
        liveRemaining <= const Duration(minutes: 15)) {
      arcColor = theme.colorScheme.error;
```
- **Current behavior:** عتبتان لونيّتان محدّدتان رقمياً داخل widgets، بينما محرّك التنبيهات في `hos_rules_engine.dart:104-127` يستخدم 15/30/60 دقيقة.
- **Why problematic:** **نفس المفهوم (اقتراب الحد) بعتبتين مختلفتين في مكانين مختلفين**: المحرّك يصنّف 30/60 دقيقة كتنبيهات، والواجهة تحوّل الأحمر عند 15 دقيقة فقط. كما أن `Duration(minutes: 15)` في الودجت لا يستمد من `HosConfiguration` ولا `FmcsaConstants`.
- **Violated principle:** Single Source of Truth.
- **Current owner:** widgets ×2.
- **Correct owner:** `FmcsaConstants` أو `HosConfiguration`، مع استهلاكها عبر `AlertSeverity` القادم من المحرك.
- **Consequences:** تناقض بصري: السائق يرى «حرج» في لوح واحد و«معلومات» في آخر لنفس الوقت المتبقي.
- **Recommended correction:** اجعل `HosStatusUpdate` يحمل `AlertSeverity` لكل مؤشر، واستهلكه الودجت بدل حساب عتبة خاصة.
- **Related files:** `lib/features/hos/domain/engine/hos_rules_engine.dart:104-127`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-41: ازدواج شريط التنقل السفلي وطبقات Loading/Error في المجموعة
- **Severity:** Low
- **Category:** Duplication (Structural)
- **Location:** `BottomNavigationBar`: 2 موضعان متطابقان — `logs/presentation/pages/log_detail_page.dart:176` و `logs/presentation/pages/inspection_preview_page.dart:236`. `CircularProgressIndicator`: **12 موضعاً في 12 ملفاً** (`hos/presentation/pages/status_dashboard_page.dart:93`، `hos/presentation/pages/recap_page.dart:65`، `logs/presentation/pages/audit_trail_page.dart:40`، `logs/presentation/pages/edit_log_page.dart:377`، `logs/presentation/pages/logs_list_page.dart:64`، `logs/presentation/pages/inspection_preview_page.dart:118,362`، `logs/presentation/pages/unidentified_events_page.dart:244`، `logs/presentation/widgets/vehicle_picker_dialog.dart:64`، `logs/presentation/widgets/codriver_picker_dialog.dart:51`، `logs/presentation/widgets/log_detail_tabs/events_tab.dart:30`، `logs/presentation/widgets/log_detail_tabs/certify_tab.dart:116`). `EldRetryView`: **7 مواضع في 6 ملفات** (`hos/.../status_dashboard_page.dart:113`، `hos/.../recap_page.dart:67`، `logs/.../logs_list_page.dart:66,75`، `logs/.../events_tab.dart:33,42`، `logs/.../inspection_preview_page.dart:126`).
- **Current behavior:** نفس شريط التنقل السفلي (3 عناصر + Badge على «Form») مكرور مرتين؛ حالة التحميل تُبنى يدوياً 12 مرة.
- **Why problematic:** مجموعتان متطابقتان من Handling States بلا abstraction. (ملاحظة: `EldRetryView` و`CircularProgressIndicator` تكرارات **مقبولة** كـ shared widgets في `core/widgets/` — التسجيل هنا لقياس الكمية، لا للحكم على المخالفة.)
- **Violated principle:** DRY (بحدّ).
- **Current owner:** presentation.
- **Correct owner:** `core/widgets/` (يوجد precedent في `core/widgets/eld_date_paginator.dart` و`eld_events_table.dart`).
- **Consequences:** تعديل مظهر حالة الخطأ يتطلب 7 مواضع.
- **Recommended correction:** استخرج `AsyncStateView<T>` و`LogSectionTabBar` في `core/widgets/`.
- **Related files:** `lib/core/widgets/eld_retry_view.dart`, `lib/core/widgets/eld_date_paginator.dart`
- **Confidence:** **CONFIRMED**

---
# C. جدول تكرار قواعد HOS (الثابت -> كل موقع file:line)

> البحث تم عبر كامل `lib/` (باستثناء `*.g.dart` و `*.freezed.dart`).

## C.1 — حد القيادة 11 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:19` | `static const int maxDrivingHours = 11;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:27` | `drivingLimitMinutes: 11 * 60,` (usa70_8) | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:41` | `drivingLimitMinutes: 11 * 60,` (usa60_7) | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:89` | `?? 11 * 60` (fromJson fallback) | core/config | ✅ مصدر |
| 5 | `lib/features/hos/domain/engine/hos_rules_engine.dart:172` | نص: `'❌ تجاوز حد القيادة 11 ساعة'` | domain | ⚠️ نص |
| 6 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:87` | `const total = Duration(hours: 11);` | **data** | ❌ |
| 7 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:125` | `totalLimit = const Duration(hours: 11);` (rest) | **presentation** | ❌ |
| 8 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:128` | `totalLimit = const Duration(hours: 11);` (driving) | **presentation** | ❌ |
| 9 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:73` | `value: Duration(hours: 11),` | mock | ✅ مقبول |
| 10 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:139` | `const total = Duration(hours: 11);` | mock | ✅ مقبول |

## C.2 — نافذة الوردية 14 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:22` | `static const int maxDutyWindowHours = 14;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:28` | `shiftLimitMinutes: 14 * 60,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:42` | `shiftLimitMinutes: 14 * 60,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:90` | `?? 14 * 60` | core/config | ✅ مصدر |
| 5 | `lib/features/hos/domain/engine/hos_rules_engine.dart:181` | نص: `'❌ تجاوز نافذة العمل 14 ساعة'` | domain | ⚠️ نص |
| 6 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:95` | `const total = Duration(hours: 14);` | **data** | ❌ |
| 7 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:145` | `totalLimit = const Duration(hours: 14);` | **presentation** | ❌ |
| 8 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:78` | `value: Duration(hours: 14),` | mock | ✅ |
| 9 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:148` | `const total = Duration(hours: 14);` | mock | ✅ |

## C.3 — الاستراحة/حد 8 ساعات
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:28` | `static const int breakRequiredAfterDrivingHours = 8;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:32` | `driveBeforeBreakMinutes: 8 * 60,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:46` | `driveBeforeBreakMinutes: 8 * 60,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:94` | `?? 8 * 60` | core/config | ✅ مصدر |
| 5 | `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart:28` | `driveBeforeBreakMinutes: 8 * 60,` | backend mapper | ⚠️ mapper، تجاوز المصدر |
| 6 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:142` | `totalLimit = const Duration(hours: 8);` | **presentation** | ❌ |
| 7 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:83` | `value: Duration(hours: 8),` | mock | ✅ |

## C.4 — الاستراحة الإلزامية 30 دقيقة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:29` | `static const int mandatoryBreakDurationMinutes = 30;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:30` | `breakDurationMinutes: 30,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:44` | `breakDurationMinutes: 30,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:92` | `?? 30` | core/config | ✅ مصدر |
| 5 | `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart:26` | `breakDurationMinutes: 30,` | backend mapper | ⚠️ تجاوز المصدر |

## C.5 — حد الدورة الأسبوعية 60/70 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:32` | `static const int cycle7DaysLimitHours = 60;` | core/constants | ✅ مصدر |
| 2 | `lib/core/constants/fmcsa_constants.dart:33` | `static const int cycle8DaysLimitHours = 70;` | core/constants | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:29` | `cycleLimitHours: 70,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:43` | `cycleLimitHours: 60,` | core/config | ✅ مصدر |
| 5 | `lib/core/config/hos_configuration.dart:91` | `?? 70` | core/config | ✅ مصدر |
| 6 | `lib/domain/duty_status/status_dashboard.dart:175-181` | `usa70_8('USA 70/8', 70, 8)` … `canadaSouth120_14(…, 120, 14)` | domain مشترك | ✅ (مصدر ثانٍ مشروع) |
| 7 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:88` | `value: Duration(hours: 70),` | mock | ✅ |

## C.6 — إعادة التشغيل الأسبوعي 34 ساعة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:34` | `static const int cycleRestartHours = 34;` | core/constants | ✅ مصدر |
| 2 | `lib/core/config/hos_configuration.dart:34` | `weeklyRestartHours: 34,` | core/config | ✅ مصدر |
| 3 | `lib/core/config/hos_configuration.dart:48` | `weeklyRestartHours: 34,` | core/config | ✅ مصدر |
| 4 | `lib/core/config/hos_configuration.dart:96` | `?? 34` | core/config | ✅ مصدر |
| 5 | `lib/features/hos/domain/engine/hos_calculator.dart:103` | **`const requiredHours = 34;`** | **domain** | ❌ **يتجاهل `config.weeklyRestartHours`** |

> **ملاحظة حرجة (C.6):** `HosConfiguration` يوفّر `weeklyRestartHours` كحقل مهيّأ، لكن `HosCalculator.hasWeeklyRestart` **يتجاهله تماماً** ويثبّت `34` محلياً. أي أن تغيير قاعدة إعادة التشغيل (مثلاً ولاية أخرى) لا يسري.

## C.7 — عتبة السرعة 5 mph / 8 km/h
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:7` | `static const double drivingSpeedThresholdMps = 2.235;` | core/constants | ✅ مصدر |
| 2 | `lib/core/constants/fmcsa_constants.dart:10` | `static const double drivingSpeedThresholdMph = 5.0;` | core/constants | ✅ **المصدرUnused** |
| 3 | `lib/core/config/hos_configuration.dart:31` | `movingSpeedThresholdKmh: 8.0,` | core/config | ✅ |
| 4 | `lib/core/config/hos_configuration.dart:45` | `movingSpeedThresholdKmh: 8.0,` | core/config | ✅ |
| 5 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:106` | **`if (eldEvent.speedMph > 5.0) {`** | **domain** | ❌ **وحدات مختلفة** |
| 6 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:129` | نص: `'Auto Transition to Driving (> 5 mph sustained)'` | domain | ⚠️ نص |

## C.8 — الثبات 5 دقائق قبل الانتقال لـ ON_DUTY
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:16` | `static const int stationaryPromptSeconds = 300;` | core/constants | ✅ **المصدرUnused** |
| 2 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:168` | `if (elapsed.inMinutes >= 5) {` | domain | ❌ وليس في `HosConfiguration` |
| 3 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:185` | `const Duration(minutes: 5) - elapsed` | domain | ❌ |

## C.9 — عتبة التنبيه 15 دقيقة
| # | الموقع | الصيغة | الطبقة | المصدر الصحيح؟ |
|---|---|---|---|---|
| 1 | `lib/features/hos/domain/engine/hos_rules_engine.dart:104` | `if (limits.remainingDriveMinutes <= 15 &&` | domain | ⚠️ محرّك، لكن خارج `HosConfiguration` |
| 2 | `lib/features/hos/domain/engine/hos_rules_engine.dart:108` | نص: `'15 minutes driving time remaining'` | domain | ⚠️ نص |
| 3 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart:179` | `liveRemaining <= const Duration(minutes: 15)` | **presentation** | ❌ عتبة مستقلة |

## C.10 — الراحة المتتالية 10 ساعات
| # | الموقع | الصيغة | المصدر الصحيح؟ |
|---|---|---|---|
| 1 | `lib/core/constants/fmcsa_constants.dart:25` | `static const int requiredConsecutiveRestHours = 10;` | ✅ المصدر الوحيد |
| — | *(لا توجد أي نسخة أخرى في `lib/`)* | — | ⚠️ ثابت **غير مستخدم** — لا يوجد أي تنفيذ لقاعدة الراحة المتتالية 10 ساعات في المجموعة |

## C.11 — أرقام مُختلقة (ليست قواعد)
| # | الموقع | القيمة | الحكم |
|---|---|---|---|
| 1 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:86` | `const remaining = Duration(minutes: 35);` | ❌ بيانات توازن مُختلقة في data |
| 2 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:94` | `const remaining = Duration(hours: 2, minutes: 8);` | ❌ بيانات توازن مُختلقة في data |
| 3 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:95` | `Duration(minutes: 35)` | ✅ mock |
| 4 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart:100` | `Duration(hours: 2, minutes: 8)` | ✅ mock |
| 5 | `lib/features/logs/presentation/providers/logs_provider.dart:119` | `const limit = 20;` | ⚠️ حجم صفحة (قابل للضبط، ليس قاعدة قانونية) |
| 6 | `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart:105` | `const Duration(hours: 1)` | ❌ عتبة نقدية في widget |
| 7 | `lib/features/logs/presentation/pages/unidentified_events_page.dart:334` | `const Duration(hours: 24)` | ⚠️ نافذة إحصائية (SRS 11.6)، ليست FMCSA |
| 8 | `lib/features/logs/presentation/controllers/edit_log_controller.dart:52` | `const Duration(minutes: 1)` | ⚠️ هامش تسامح زمني |

**خلاصة القسم C:** عدد المواقع التي **تتجاوز** المصدر الصحيح داخل هذه المجموعة = **7** (`main_circular_timer.dart` ×5، `status_dashboard_repository_impl.dart` ×2، `duty_status_tracker.dart` ×1، `hos_calculator.dart` ×1). عدد الثوابت المعرَّفة في مصدرين رسميين (`FmcsaConstants` و`HosConfiguration`) = **12**، منها **3 غير مستخدمة** (`drivingSpeedThresholdMph`, `stationaryPromptSeconds`, `requiredConsecutiveRestHours`).

---

# D. جداول الاستيراد بين الميزات للمجموعة

## D.1 — `features/logs` -> ميزات أخرى (13 حافة)

| # | المستورد | السطر | المستوردَ منه | نوع الحافة | الحكم |
|---|---|---|---|---|---|
| 1 | `logs/data/repositories/log_repository_impl.dart` | 3 | `features/sync/domain/entities/pending_event.dart` | data → domain (عقد) | ✅ جائز |
| 2 | `logs/data/repositories/log_repository_impl.dart` | 4 | `features/sync/domain/repositories/offline_queue.dart` | data → domain (عقد) | ⚠️ جائز لكنه يجعل `sync` مجتمعة مع `logs` |
| 3 | `logs/data/providers/log_repository_providers.dart` | 6 | `features/sync/data/providers/sync_providers.dart` | data → data (DI) | ✅ جائز في بنية المشروع |
| 4 | `logs/presentation/providers/logs_provider.dart` | 11 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ معقول (هوية) |
| 5 | `logs/presentation/providers/logs_provider.dart` | **12** | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة حالة**) | ❌ **HL-25** |
| 6 | `logs/presentation/controllers/edit_log_controller.dart` | 5 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 7 | `logs/presentation/controllers/form_tab_controller.dart` | 2 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 8 | `logs/presentation/providers/certify_log_provider.dart` | 12 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 9 | `logs/presentation/providers/unidentified_events_provider.dart` | 8 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 10 | `logs/presentation/pages/edit_log_page.dart` | 4 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |
| 11 | `logs/presentation/pages/edit_log_page.dart` | 13 | `features/vehicle/domain/entities/vehicle.dart` | presentation → domain (عقد) | ✅ جائز |
| 12 | `logs/presentation/pages/edit_log_page.dart` | 14 | `features/vehicle/presentation/providers/vehicle_provider.dart` | presentation → presentation | ⚠️ معقول (اختيار) |
| 13 | `logs/presentation/widgets/vehicle_picker_dialog.dart` | 9 | `features/vehicle/presentation/providers/vehicle_provider.dart` | presentation → presentation | ⚠️ معقول |
| 14 | `logs/presentation/pages/unidentified_events_page.dart` | 11 | `features/vehicle/presentation/providers/vehicle_provider.dart` | presentation → presentation | ⚠️ معقول (فلترة) |
| 15 | `logs/presentation/widgets/codriver_picker_dialog.dart` | 5 | `features/codriver/domain/entities/codriver.dart` | presentation → domain (عقد) | ✅ |
| 16 | `logs/presentation/widgets/codriver_picker_dialog.dart` | 6 | `features/codriver/presentation/providers/codriver_provider.dart` | presentation → presentation | ⚠️ معقول |
| 17 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 7 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |
| 18 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 8 | `features/vehicle/domain/entities/vehicle.dart` | presentation → domain (عقد) | ✅ |
| 19 | `logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 9 | `features/vehicle/domain/vehicle_selection.dart` | presentation → domain (منطق) | ✅ منطق مجال مستورد كعقد |
| 20 | `logs/presentation/pages/inspection_preview_page.dart` | 14 | `features/inspection/domain/transfer_audit.dart` | presentation → domain (عقد) | ✅ |
| 21 | `logs/presentation/pages/inspection_preview_page.dart` | 15 | `features/inspection/presentation/providers/dot_inspection_providers.dart` | presentation → presentation | ⚠️ معقول |
| 22 | `logs/presentation/pages/inspection_preview_page.dart` | **16** | `features/inspection/presentation/widgets/inspection_log_header_table.dart` | presentation → **presentation widget** | ❌ **HL-13** |
| 23 | `logs/presentation/pages/logs_list_page.dart` | **11** | `features/home/presentation/widgets/eld_drawer.dart` | presentation → **presentation widget** | ❌ **HL-13** |
| 24 | `logs/presentation/pages/shipping_documents_page.dart` | 11 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |
| 25 | `logs/presentation/pages/trailers_page.dart` | 11 | `features/home/presentation/providers/dashboard_provider.dart` | presentation → presentation (**كتابة**) | ❌ **HL-25** |

**حساب:** 25 حافة إجمالاً. منها **5 مخالفة مؤكدة** (كتابة عبر features أو استيراد widget).
`LOGS → VEHICLE` = **4 حواف، كلها تستورد عقوداً أو providers قراءة** ⇒ **ليست مخالفة**.
`LOGS → HOME` = **7 حواف، 5 منها كتابة حالة** ⇒ **مخالفة مؤكدة**.
`LOGS → AUTH` = **5 حواف، قراءة فقط** ⇒ **ليست مخالفة**.
`LOGS → SYNC` = **3 حواف، كلها في طبقة data** ⇒ **ليست مخالفة**.
`LOGS → CODRIVER` = **3 حواف، عقدة + قراءة** ⇒ **ليست مخالفة**.
`LOGS → INSPECTION` = **3 حواف، منها استيراد widget** ⇒ **مخالفة جزئية**.

## D.2 — `features/hos` -> ميزات أخرى و `lib/domain` (11 حافة)

| # | المستورد | السطر | المستوردَ منه | نوع الحافة | الحكم |
|---|---|---|---|---|---|
| 1 | `hos/domain/engine/tracking/duty_status_tracker.dart` | **4** | `features/logs/domain/repositories/log_repository.dart` | **domain → domain (feature أخرى)** | ❌ **HL-01 مخالفة حرجة** |
| 2 | `hos/domain/engine/tracking/duty_status_tracker.dart` | **9** | `features/sync/domain/usecases/sync_engine.dart` | **domain → domain (use-case)** | ⚠️ تطبيق مجتمعة — غير مثالي لكنه عقد |
| 3 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 10 | `features/sync/domain/entities/pending_event.dart` | domain → domain (كيان) | ✅ كيان مشترك |
| 4 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 5 | `core/services/local_storage_service.dart` | **domain → infrastructure** | ❌ **HL-02** |
| 5 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 13 | `backend/contracts/status_dashboard_backend.dart` | **domain → backend contract** | ❌ **HL-02** |
| 6 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 14 | `lib/domain/duty_status/duty_status_code.dart` | domain → **shared domain** | ✅ **عقدة مشتركة** |
| 7 | `hos/domain/engine/tracking/duty_status_tracker.dart` | 15 | `lib/domain/duty_status/status_dashboard.dart` | domain → shared domain | ✅ عقدة مشتركة |
| 8 | `hos/presentation/providers/hos_engine_provider.dart` | 8 | `features/logs/data/providers/log_repository_providers.dart` | presentation → **data** | ⚠️ انعكاس لـ HL-01 |
| 9 | `hos/presentation/providers/hos_engine_provider.dart` | 9 | `features/sync/data/providers/sync_providers.dart` | presentation → data | ✅ DI |
| 10 | `hos/presentation/providers/hos_engine_provider.dart` | 7 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 11 | `hos/presentation/providers/hos_engine_provider.dart` | 11 | `features/tracking/presentation/providers/tracking_provider.dart` | presentation → presentation | ✅ (قراءة سرعة) |
| 12 | `hos/presentation/providers/hos_provider.dart` | 11 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 13 | `hos/presentation/providers/recap_provider.dart` | 7 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 14 | `hos/presentation/providers/status_dashboard_providers.dart` | 13 | `features/auth/presentation/providers/auth_state_provider.dart` | presentation → presentation | ✅ |
| 15 | `hos/presentation/widgets/driving_lock_screen.dart` | **7** | `features/home/presentation/pages/home_page.dart` | presentation → **presentation page** | ❌ **HL-13** |
| 16 | `hos/presentation/widgets/location_display_widget.dart` | 5 | `features/tracking/presentation/providers/tracking_provider.dart` | presentation → presentation | ✅ |
| 17 | `hos/presentation/widgets/status_dashboard/operational_alerts_banner.dart` | 8 | `features/connection/presentation/providers/hardware_alerts_provider.dart` | presentation → presentation | ✅ |

## D.3 — الحكم على التبعيات المُعلنة

| التبعية المُعلنة | الحكم | المبرر |
|---|---|---|
| **`LOGS -> VEHICLE`** | **ليست مخالفة** ✅ | الحواف الأربع (11, 13, 14 من `edit_log_page` + `vehicle_picker_dialog:9` + `unidentified_events_page:11` + `form_tab:8,9`) تستورد: (أ) كيان `Vehicle` (عقدة نطاق مشتركة)، (ب) `vehicle_selection.dart` (منطق مجال)، (ج) provider قراءة. **لا يوجد استيراد لتنفيذ vehicle (repository/datasource)**. هذا نمط سليم. |
| **`LOGS -> HOME`** | **مخالفة مؤكدة** ❌ | ليس استيراد عقدة، بل **كتابة حالة** عبر `dashboardDataProvider.notifier` في 5 مواضع (`logs_provider:162,192,214`، `form_tab:130,215`، `edit_log_page:182`، `trailers_page:52`، `shipping_documents_page:51`) + استيراد widget `EldDrawer`. `dashboardDataProvider` هو **source of truth** لبيانات النموذج، و`logs` يحدّثه. |
| **`HOS -> SDOM (lib/domain/**)`** | **ليست مخالفة** ✅ | `lib/domain/duty_status/duty_status_code.dart` و`status_dashboard.dart` و`shared/value_objects.dart` هي **عقد مشتركة** (Shared Domain Model) يستخدمها `logs` و`hos` معاً (`log_repository.dart:4`، `status_dashboard_repository.dart:3-6`، `log_repository_providers.dart:9`). هي **نماذج مجال مشتركة لا تنفيذ**. هذا نمط معماري صحيح. |
| **`HOS -> LOGS`** | **مخالفة حرجة مؤكدة** ❌ | ليس عقدة مشتركة: `duty_status_tracker.dart:4` يستورد **عقد مستودع feature أخرى** و`line 284` يستدعيه. كما أن `hos_engine_provider.dart:8` يستورد **طبقة data** (`log_repository_providers.dart`) لتحقن المستودع. |

---

# E. قائمة شاملة للملفات المقروءة (إثبات التغطية)

## E.1 — `lib/features/hos/**` (29 ملف)

| # | المسار | أسطر | غير فارغ |
|---|---|---|---|
| 1 | `lib/features/hos/data/providers/hos_audit_providers.dart` | 14 | 12 |
| 2 | `lib/features/hos/data/providers/status_dashboard_repository_providers.dart` | 15 | 12 |
| 3 | `lib/features/hos/data/repositories/hos_audit_repository_impl.dart` | 58 | 52 |
| 4 | `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart` | 115 | 108 |
| 5 | `lib/features/hos/domain/engine/hos_calculator.dart` | 113 | 94 |
| 6 | `lib/features/hos/domain/engine/hos_rules_engine.dart` | 240 | 207 |
| 7 | `lib/features/hos/domain/engine/hos_state_machine.dart` | 128 | 106 |
| 8 | `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` | 555 | 494 |
| 9 | `lib/features/hos/domain/repositories/hos_audit_repository.dart` | 6 | 5 |
| 10 | `lib/features/hos/domain/repositories/status_dashboard_repository.dart` | 20 | 17 |
| 11 | `lib/features/hos/domain/usecases/get_status_dashboard_use_case.dart` | 15 | 12 |
| 12 | `lib/features/hos/domain/usecases/get_weekly_recap_use_case.dart` | 15 | 12 |
| 13 | `lib/features/hos/domain/usecases/update_duty_status_use_case.dart` | 18 | 15 |
| 14 | `lib/features/hos/presentation/duty_change_message.dart` | 32 | 27 |
| 15 | `lib/features/hos/presentation/extensions/duty_status_l10n.dart` | 52 | 48 |
| 16 | `lib/features/hos/presentation/pages/change_status_page.dart` | 232 | 212 |
| 17 | `lib/features/hos/presentation/pages/recap_page.dart` | 117 | 113 |
| 18 | `lib/features/hos/presentation/pages/status_dashboard_page.dart` | 118 | 103 |
| 19 | `lib/features/hos/presentation/providers/change_status_provider.dart` | 397 | 353 |
| 20 | `lib/features/hos/presentation/providers/hos_engine_provider.dart` | 83 | 71 |
| 21 | `lib/features/hos/presentation/providers/hos_provider.dart` | 159 | 140 |
| 22 | `lib/features/hos/presentation/providers/recap_provider.dart` | 38 | 31 |
| 23 | `lib/features/hos/presentation/providers/status_dashboard_providers.dart` | 145 | 127 |
| 24 | `lib/features/hos/presentation/widgets/driving_lock_screen.dart` | 57 | 54 |
| 25 | `lib/features/hos/presentation/widgets/location_display_widget.dart` | 39 | 35 |
| 26 | `lib/features/hos/presentation/widgets/status_option_tiles.dart` | 70 | 62 |
| 27 | `lib/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart` | 150 | 139 |
| 28 | `lib/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart` | 365 | 331 |
| 29 | `lib/features/hos/presentation/widgets/status_dashboard/operational_alerts_banner.dart` | 93 | 84 |

**المجموع: 3,046 سطر — 29/29 ملف مقروء.**

## E.2 — `lib/features/logs/**` (42 ملف)

| # | المسار | أسطر | غير فارغ |
|---|---|---|---|
| 1 | `lib/features/logs/data/datasources/log_local_data_source.dart` | 322 | 291 |
| 2 | `lib/features/logs/data/models/daily_log_dto.dart` | 143 | 134 |
| 3 | `lib/features/logs/data/models/log_model.dart` | 133 | 121 |
| 4 | `lib/features/logs/data/providers/log_repository_providers.dart` | 25 | 21 |
| 5 | `lib/features/logs/data/repositories/log_repository_impl.dart` | 539 | 498 |
| 6 | `lib/features/logs/domain/daily_form_rules.dart` | 93 | 83 |
| 7 | `lib/features/logs/domain/log_edit.dart` | 57 | 49 |
| 8 | `lib/features/logs/domain/saved_form_status.dart` | 36 | 31 |
| 9 | `lib/features/logs/domain/entities/audit_entry.dart` | 100 | 89 |
| 10 | `lib/features/logs/domain/entities/daily_form_data.dart` | 32 | 29 |
| 11 | `lib/features/logs/domain/entities/daily_form_update.dart` | 27 | 24 |
| 12 | `lib/features/logs/domain/entities/daily_log.dart` | 251 | 236 |
| 13 | `lib/features/logs/domain/entities/log_readiness.dart` | 69 | 63 |
| 14 | `lib/features/logs/domain/repositories/log_repository.dart` | 93 | 85 |
| 15 | `lib/features/logs/presentation/controllers/edit_log_controller.dart` | 122 | 105 |
| 16 | `lib/features/logs/presentation/controllers/form_tab_controller.dart` | 68 | 58 |
| 17 | `lib/features/logs/presentation/pages/audit_trail_page.dart` | 93 | 88 |
| 18 | `lib/features/logs/presentation/pages/edit_log_page.dart` | 433 | 407 |
| 19 | `lib/features/logs/presentation/pages/inspection_preview_page.dart` | 401 | 382 |
| 20 | `lib/features/logs/presentation/pages/logs_list_page.dart` | 239 | 225 |
| 21 | `lib/features/logs/presentation/pages/log_detail_page.dart` | 220 | 211 |
| 22 | `lib/features/logs/presentation/pages/shipping_documents_page.dart` | 170 | 160 |
| 23 | `lib/features/logs/presentation/pages/suggested_events_page.dart` | 121 | 117 |
| 24 | `lib/features/logs/presentation/pages/trailers_page.dart` | 170 | 160 |
| 25 | `lib/features/logs/presentation/pages/unidentified_events_page.dart` | 505 | 479 |
| 26 | `lib/features/logs/presentation/providers/audit_trail_provider.dart` | 10 | 9 |
| 27 | `lib/features/logs/presentation/providers/certify_log_provider.dart` | 193 | 163 |
| 28 | `lib/features/logs/presentation/providers/edit_log_form_provider.dart` | 66 | 59 |
| 29 | `lib/features/logs/presentation/providers/logs_provider.dart` | 352 | 310 |
| 30 | `lib/features/logs/presentation/providers/log_detail_tab_provider.dart` | 5 | 4 |
| 31 | `lib/features/logs/presentation/providers/unidentified_events_provider.dart` | 170 | 154 |
| 32 | `lib/features/logs/presentation/widgets/codriver_picker_dialog.dart` | 113 | 105 |
| 33 | `lib/features/logs/presentation/widgets/log_graph.dart` | 101 | 86 |
| 34 | `lib/features/logs/presentation/widgets/status_radio_group.dart` | 61 | 57 |
| 35 | `lib/features/logs/presentation/widgets/time_field_widget.dart` | 53 | 50 |
| 36 | `lib/features/logs/presentation/widgets/time_picker_sheet.dart` | 175 | 165 |
| 37 | `lib/features/logs/presentation/widgets/vehicle_picker_dialog.dart` | 168 | 157 |
| 38 | `lib/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart` | 346 | 324 |
| 39 | `lib/features/logs/presentation/widgets/log_detail_tabs/events_tab.dart` | 144 | 134 |
| 40 | `lib/features/logs/presentation/widgets/log_detail_tabs/expanded_content.dart` | 59 | 55 |
| 41 | `lib/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart` | 383 | 358 |
| 42 | `lib/features/logs/presentation/widgets/log_detail_tabs/log_event_tile.dart` | 166 | 156 |

**المجموع: 6,634 سطر — 42/42 ملف مقروء.**

## E.3 — ملفات خارج النطاق قُرئت للتحقق (Cross-check)

| المسار | سبب القراءة |
|---|---|
| `lib/core/constants/fmcsa_constants.dart` | مطلوب صريحاً في نطاق المهمة (مقابل تكرار الثوابت) |
| `lib/core/config/hos_configuration.dart` | المصدر الحقيقي لحدود HOS |
| `lib/core/time/trusted_time_provider.dart` | للتحقق من HL-07 (Riverpod داخل الملف) |
| `lib/core/services/local_storage_service.dart` (ترويسة فقط) | للتحقق من HL-02 |
| `lib/core/utils/status_color_helper.dart` | للتحقق من HL-34 |
| `lib/core/utils/duration_format.dart` (ترويسة فقط) | للتحقق من HL-26 |
| `lib/core/time/time_formatter.dart` (ترويسة فقط) | للتحقق من HL-26 |
| `lib/backend/contracts/status_dashboard_backend.dart` | للتحقق من HL-02 |
| `lib/features/sync/domain/usecases/sync_engine.dart` (ترويسة فقط) | للتحقق من HL-01 |
| `lib/routes.dart` (قائمة المسارات فقط) | للتحقق من مسار التنقل |
| `lib/l10n/app_localizations.dart` (ترويسة فقط) | للتحقق من HL-17 |
| بحث نصي عبر `lib/` كله | لثوابت HOS والتكرارات والاستيرادات |

---

## ملحق: عدّاد التكرارات (كمية)

| البند | العدد | المواضع |
|---|---|---|
| تنفيذ loading | 12 | `CircularProgressIndicator` في 12 ملفاً (6 في `hos`+`logs` موزّعة) |
| تنفيذ error surface | 7 | `EldRetryView` في 6 ملفات |
| تنفيذ success toast | 6 | `AppFeedback.success` في `hos/.../change_status_page.dart:45`، `logs/.../log_detail_page.dart:137`، `logs/.../edit_log_page.dart:92`، `logs/.../unidentified_events_page.dart:167`، `logs/.../form_tab.dart:249,252`، `logs/.../certify_tab.dart:67` |
| تنسيق المدة | 4 | `daily_log.dart:216`, `events_tab.dart:106`, `logs_list_page.dart:168`, `DurationFormat` (غير مستخدم في الثلاثة الأولى) |
| تنسيق الوقت | 4 | `daily_log.dart:210`, `audit_trail_page.dart:77`, `certify_log_provider.dart:177`, `certify_tab.dart:82` |
| تسميات الحالات | 5 | `status_radio_group.dart:19`, `inspection_preview_page.dart:194`, `inspection_preview_page.dart:273`, `log_graph.dart:26`, `events_tab.dart:104` |
| خريطة رمز→لون | 2 | `StatusColorHelper` (مستخدمة) + `inspection_preview_page.dart:273` (مكرّرة) |
| تطبيع PC/YM | 3 | `log_graph.dart:47`, `events_tab.dart:117`, `inspection_preview_page.dart:194` |
| مطابقة `DutyStatus ⇄ DutyStatusCode` | 4 | `change_status_provider.dart:37`, `status_dashboard_providers.dart:18`, `hos_provider.dart:59`, `hos_rules_engine.dart:51` |
| بناء حمولة سلكية | 2 | `duty_status_tracker.dart:218`, `log_repository_impl.dart:206` |
| تطبيع الوحدات (ميل↔كم) | 3 | `duty_status_tracker.dart:227` (→كم)، `log_model.dart:59` (كم→ميل)، `dto`/presentation بال miles |
| استدعاءات دوال domain من widgets | 5 | `edit_log_page.dart:42,250,279`, `form_tab.dart:142,166` |
| RegExp أحرف الإدخال المكرر | 3 | `daily_form_rules.dart:30`, `trailers_page.dart:100`, `shipping_documents_page.dart:100` |
| writes عبر features | 7 | ( HL-25 ) |
| استيراد widgets عبر features | 3 | `logs_list_page.dart:11`, `inspection_preview_page.dart:16`, `driving_lock_screen.dart:7` |
| رموز حالة مكتوبة يدوياً في presentation | 5 | ( HL-34 ) |



--------------------------------------------------



