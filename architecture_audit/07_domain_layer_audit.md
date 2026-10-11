# 07 — تدقيق طبقة النطاق (Domain Layer Audit)

## نطاق التدقيق

`lib/domain/**` (النطاق المشترك، 9 ملفات)، `lib/core/domain/entities/**`، وكل ما يقع تحت `lib/features/*/domain/**`، إضافة إلى `backend/contracts/**` بوصفها عقود النطاق المقابلة.

## الحكم العام

النطاق **ليس نقياً**، لكن نسبة الانViolation **منخفضة**. هذا يستحق التوثيق: المشروع لم يبنِ «Clean Architecture» نظرياً ثم خالفها جوهرياً — بل بنى نطاقاً حقيقياً ثم **تسرّب منه** في 6 نقاط محددة. هذا فرق مهم في تقدير الجهد: الإصلاح محدود وليس إعادة بناء.

## النطاق المشترك `lib/domain/**` — 8 من 9 ملفات نقية

**مؤكد بالاستيراد الكامل لكل ملف**: لا Riverpod، لا Dio، لا `features/`، لا Flutter في أي ملف من التسعة — **عدا ملف واحد**:

```dart
// lib/domain/duty_status/duty_status_code.dart:7-8
import 'package:flutter/widgets.dart';
import '../../../core/utils/logger.dart';
```
وحمل ألوان في `:75-88`. هذا **الملف الواحد** هو مصدر تسريب Beverage: `Color` من Flutter ينتشر إلى `backend/contracts/status_dashboard_backend.dart:2`، `eld_engine/mappers/status_dashboard_mapper.dart:1`، `hos_provider.dart:12` و**18 ملفاً آخراً** (DOM-001).

### تصحيح إضافي من التدقيق البصري (CUI-013)

الملف نفسه يوثّق أربع قيم لونية على أنها مكافئة لـ `AppColors` — **والأربع مختلفة فعلياً**:
```
0xFF10B981 ≠ AppColors.successGreen (0xFF34C759)
```
تعليقات مغلوطة في نطاق مشترك، تنتشر كسلوك مرئي خاطئ.

## جذور نطاق متوازية (DOM-002)

```
lib/domain/**                       ← 9 ملفات
lib/core/domain/entities/**         ← 3 ملفات (user, hos_models, location_point)
```
كيانات النطاق موزّعة على جذرين. `lib/domain/**` يستورد من `lib/core/domain/entities/**` — لكن العكس غير موجود. هذا تشظير لا انقلاب اتجاه، لكنه يربك «أين الكيان».

## DTO شبكة داخل النطاق (DOM-003)

```dart
// lib/domain/account/driver_account.dart:3-4
// يحمل .g.dart  → freezed/json_serializable
```
هذه **ليست كيان نطاقي** بل نموذج نقل وُضع في المكان الخطأ. الأثر: `lib/domain/` لا يمكن اختباره في سياق Dart نقي (يتطلب `build_runner`).

## تسرّب النطاق عبر الميزات

### `features/hos` — الأخطر (HL-01, HL-02) — CRITICAL

```dart
// lib/features/hos/domain/engine/tracking/duty_status_tracker.dart
 4: import '../../../../logs/domain/repositories/log_repository.dart';
 5: import '../../../../../core/services/local_storage_service.dart';
11: import 'package:uuid/uuid.dart';
13: import '../../../../../backend/contracts/status_dashboard_backend.dart';
```
والتعليق في `line 7` يقول «Domain Pure». أربع عمليات انقسام:
1. **عقد feature أخرى** في domain — `hos` لا يُختبر دون `logs`.
2. **`LocalStorageService`** — بنية تحتية داخل «نطاق نقي».
3. **`uuid`** — توليد معرّف داخل domain.
4. **عقد backend** — `RawJson` يدخل النطاق من الباب الخلفي.

**المشكلة التي لا تظهر في الاستيرادات**: الملف أيضاً يبني حمولة شبكة (HL-06، `:218-230` و `:370-374`) و**يخمّن «هل الخطأ شبكي؟» بنص الخطأ**. هذا ليس نطاقاً متسرباً — هذا **منسّق I/O يحمل اسم domain**.

### `features/logs` — ان|mixtures عبر l10n (HL-17)

```dart
// lib/features/logs/domain/daily_form_rules.dart:7
import '...app_localizations.dart';
```
وفي `:86-90` ثلاث لغات مكتوبة يدوياً داخل نطاق. استدلال: ملف قواعد نطاقي يستدعي كائن ترجمة — لأن القواعد نفسها **ليست نطاقية بل نصية**. هذا ليس خطأ ترجمة، بل خطأ تصنيف: القاعدة الحقيقية (الحد الأدنى/الأقصى لعدد الأيام) كتبت كنص.

### `features/codriver` + `features/connection` — تحليل JSON في domain (COD-006)

أربعة ملفات نطاقية تحلّل حمولات JSON: `current_codriver.dart:16-51`, `team_status.dart:25-56`, `connectivity_status.dart:74-151`, `hardware_readiness.dart:28-75`. النطاق هنا يعرف أسماء حقول الخادم.

### `features/vehicle` — domain ينفذ I/O (DST-044)

```dart
// lib/features/vehicle/domain/vehicle_selection.dart:52-96, 99-119
```
قراءة JSON وربط HTTP داخل نطاق. وفي المقابل `vehicle_provider.dart:228-245` يعيد تنفيذ نفس القاعدة يدوياً — **قاعدة معطّلة في domain ومكرّرة في presentation** (DST-045).

## Use Cases — التقييم الصادق

المشروع لا يحتوي «Too Many Use Cases» — بل يحتوي **استخدامين متطرفين** في آن واحد:

| الحالة | العدد | الحكم |
|---|---|---|
| Use-case **ذو قيمة** | 4 | `login_usecase`, `sync_engine`, `tracking_event_processor`, `duty_status_tracker` — منطق حقيقي، في مكانه |
| Use-case **.pass-through** | 12+ | 8–14 سطراً، لا يفعل سوى استدعاء `repository.method()` |
| Use-case ** ceremony** | 3 | `check_auth_status` (12)، `logout` (9 — **ويُسقط النتيجة**)، `get_weekly_recap` (12) |

`HL-10`-industrial الملاحظة مؤكدة: `get_status_dashboard_use_case.dart:12-14`, `get_weekly_recap_use_case.dart:12-14`, `update_duty_status_use_case.dart:12-17` فارغة. **التوصية ليست إضافة Use Cases — بل حذف الفارغة أو دمجها في المستودع.**

### حالات أسوأ من الفراغ

- `ACC-001`: `features/account/application/usecases/update_rules_use_case.dart` يستورد Riverpod، **يعرّف DI**، ويعتمد على presentation لميزة أخرى. طبقة use-case صارت container.
- `HL-09`: `HosRulesEngine` (نطاق) يُرجع `ServerFailure` — مصطلح نقل من domain.
- `DST-026`: أسماء أنواع الأحداث نصوص حرفية مكرّرة في domain وdata —Primitive Obsession مشترك.
- `DST-013`: حقول wire خام في `DvirDefect` رغم وجود enums مخصصة.

## قوانين النطاق التي من المفترض أن تكون في النطاق وهي ليست كذلك

| القاعدة | الموقع الحالي | الحكم |
|---|---|---|
| «لا تبديل أثناء القيادة» | `duty_status_tracker.dart:417-420` — **تُسجَّل بلا `return`** | قاعدة موجودة لكن **غير مُنفَّذة** (HL-15) — أخطر من غيابها |
| عتبة «المركبة متحركة» | `duty_status_tracker.dart:106` (miles) مقابل `hos_rules_engine.dart:80` (km) | **تعارض وحدات** (HL-04) |
| قاعدة اختيار المركبة | مكرّرة في domain وdata وpresentation (DST-047) | ثلاث نسخ |
| DVIR-09 | widget + data + data (DST-006) | ثلاث نسخ |
| §396.13 | `dvir_provider.dart:45-57` (presentation state) | قاعدة قانونية في presentation |

## جدول تفصيلي
tmp

**عدد الملاحظات في هذا القسم: 38**

--------------------------------------------------
### ISSUE AUTH-002: طبقة `usecase` في auth طقسية، و`LogoutUseCase` يُسقط نتيجة العملية
- **Severity:** Medium
- **Category:** Meaningless abstraction / Information loss
- **Location:** `lib/features/auth/domain/usecases/check_auth_status_usecase.dart:12-14`, `lib/features/auth/domain/usecases/logout_usecase.dart:9-11`, مقارنةً بـ `lib/features/auth/presentation/providers/auth_state_provider.dart:135-329`
- **Evidence:**
```dart
// lib/features/auth/domain/usecases/check_auth_status_usecase.dart:12
  Future<Either<Failure, User>> call() async {
    return await repository.checkAndRestoreSession();
  }

// lib/features/auth/domain/usecases/logout_usecase.dart:9
  Future<void> call() async {
    await repository.logout();
  }
```
- **Current behavior:** `CheckAuthStatusUseCase` لا يضيف أي قيمة (تحويل منطقي صفر). `LogoutUseCase` يحوّل `Future<Either<Failure, Unit>>` إلى `Future<void>` في **يُهمل الفشل نهائياً**، بينما `AuthNotifier.logout()` (`:301-324`) يبني حالته على افتراض النجاح دائماً.
- **Why problematic:** طبقة application وهمية تُنتج تكلفة تسمية بلا عائد، والأخطر: `Either<Failure, Unit>` كان القناة الوحيدة التي كان يمكن بها الإبلاغ عن فشل الخروج؛ إتلافها يجعل `logout()` غير قابل للإ(report) عن الفشل.
- **Violated principle:** "Use-case must carry domain policy" + "Don't hide information in pass-through wrappers".
- **Current owner:** `logout_usecase.dart`.
- **Correct owner:** إما حذف `CheckAuthStatusUseCase` (استدعاء `AuthRepository.checkAndRestoreSession()` مباشرة)، وإما أن يحمل `LogoutUseCase` `Either<Failure, Unit>` كما هو.
- **Consequences:** (1) صفر قيمة مضافة مقابل 12–15 سطراً لكل use-case؛ (2) فقدان إمكانية عرض "تعذّر تسجيل الخروج على الخادم" للسائق؛ (3) تضليل المراجعKenzie candle sefurther على وجود طبقة use-case غير موجودة فعلاً.
- **Recommended correction:** احذف `CheckAuthStatusUseCase`، وغيّر توقيع `LogoutUseCase.call()` إلى `Future<Either<Failure, Unit>>`.
- **Related files:** `lib/features/auth/presentation/providers/auth_state_provider.dart:294`, `:314`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE AUTH-003: `Password` و`LoginIdentifier` value-objects فارغة قانونياً وتُصدر مفاتيح ترجمة من `domain`
- **Severity:** Medium
- **Category:** Domain purity / Security hardening gap
- **Location:** `lib/features/auth/domain/entities/value_objects/password.dart:9-20`, `lib/features/auth/domain/entities/value_objects/login_identifier.dart:29-40`
- **Evidence:**
```dart
// lib/features/auth/domain/entities/value_objects/password.dart:9
  factory Password(String input) {
    final isValid = input.isNotEmpty;
    return Password._(input, isValid);
  }

// :15
  String? get errorMessage {
    if (value.isEmpty) {
      return 'passwordRequired';
    }
    return null;
  }
```
- **Current behavior:** لا قاعدة تعقيد، لا طول أدنى، لا `operator ==`/`hashCode` (فهي ليست value object بالمعنى التقني)، ولا `toString` حاجب — رغم أن `AuthSession` في نفس الـ feature *حجب* سرّه في `toString()` (`auth_session.dart:50-52`). كما أن الكائن يُعيد **مفاتيح l10n** (`'passwordRequired'`, `'emailRequired'`, `'invalidEmailFormat'`, `'invalidValue'`) كنصوص.
- **Why problematic:** (أ) `Password` يسكن في `domain` فيُفترض أنه يحمل قاعدة كلمة المرور، لكنه لا يحمل شيئاً؛ (ب) القواعد الحقيقية لتطبيقها في `login_usecase.dart` (مرتين: widget + usecase) ⇒ إذا أُضيفت قاعدة تعقيد مستقبلاً ستُطبَّق في طبقة واحدة فقط وتُنسى الأخرى؛ (ج) مفاتيح الترجمة داخل domain تربط النموذجLocalization.
- **Violated principle:** Value Object يجب أن يكون مغلقاً وآمناً وقابلاً للمقارنة؛ Domain لا يعتمد على l10n.
- **Current owner:** `features/auth/domain/entities/value_objects/`.
- **Correct owner:** القاعدة (policy) تبقى في domain؛ **الترجمة** تُنقل إلى presentation عبر `code` لا `message`.
- **Consequences:** (1) استنزاف trust البنية: كائن كلمة المرور لا يوفّر أي حماية؛ (2) تكرار التحقق في موضعين؛ (3) اقتران domain بنظام الترجمة.
- **Recommended correction:** اجعل `errorMessage` يُرجع `enum ValidationCode`، وأضف `operator ==`/`hashCode` و`toString()` حاجب لـ `Password`.
- **Related files:** `lib/features/auth/domain/usecases/login_usecase.dart:19-29`, `lib/features/auth/presentation/widgets/login_form.dart:96-105`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE AUTH-007: التحقق من المدخلات مكرَّر حرفياً بين الـ Widget والـ UseCase
- **Severity:** Low
- **Category:** Duplicated policy / DRY
- **Location:** `lib/features/auth/presentation/widgets/login_form.dart:65-74`, `:96-105` مقابل `lib/features/auth/domain/usecases/login_usecase.dart:19-29`
- **Evidence:**
```dart
// lib/features/auth/presentation/widgets/login_form.dart:69
              final identifierObj = LoginIdentifier(v);
              if (!identifierObj.isValid) {
                return context.translateErrorKey(identifierObj.errorMessage);
              }

// lib/features/auth/domain/usecases/login_usecase.dart:19
    if (!identifierObj.isValid) ...
```
- **Current behavior:** نفس القواعد مُطبَّقة مرتين بنفس الـ value objects، بنفس ترتيب الفحص.
- **Why problematic:** عند إضافة قاعدة (مثلاً `password.length >= 8`)، هناك احتمال أن يُعدَّل أحد الموقعين فقط — والـ widget يُعطي， المستخدم رسالة "قصيرة" بينما الـ usecase يرفض بصمت.
- **Violated principle:** مصدر واحد للحقيقة على مستوى القاعدة.
- **Current owner:** كلاهما.
- **Correct owner:** `LoginUseCase` (المصدر الوحيد)؛ الـ widget يستدعيه ويتلقى `ValidationFailure` ويفحصه لعرضه حقل-بـحقل.
- **Consequences:** ازدواج صيانة؛ احتمال انحراف سلوكي.
- **Recommended correction:** اجعل `LoginUseCase` يُرجع `ValidationFailure(fieldErrors: …)` واربطه بـ `FormField` validator عبر `Form.of(context)`.
- **Related files:** `lib/core/error/failure.dart:92-99` (يوجد `fieldErrors` — غير مستخدم في auth!)
- **Confidence:** CONFIRMED (ملاحظة: حقل `fieldErrors` في `ValidationFailure` غير مستخدم في أي مكان — راجع §C-3)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE COD-006: تحليل حمولات JSON داخل `domain/` في ثلاث ملفات (current_codriver, team_status, connectivity_status, hardware_readiness)
- **Severity:** Medium
- **Category:** Data mapping in domain
- **Location:** `lib/features/codriver/domain/current_codriver.dart:16-51`, `lib/features/codriver/domain/team_status.dart:25-56`, `lib/features/connection/domain/connectivity_status.dart:74-151`, `lib/features/connection/domain/hardware_readiness.dart:28-75`
- **Evidence:**
```dart
// lib/features/codriver/domain/current_codriver.dart:16
/// A non-object body is an error. `coDriverId` of 0 is an empty link, not a driver.
CurrentCoDriverRead? parseCurrentCoDriver(dynamic data) {
  final root = _asMap(data);
  if (root == null) return null;
  final body = _asMap(root['data']) ?? root;
```
```dart
// lib/features/connection/domain/connectivity_status.dart:112
Map<String, dynamic>? _asMap(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  return null;
}
```
- **Current behavior:** أربعة ملفات في `domain/` تحتوي دوال `parse*(dynamic)` مع فضاء أسماء خاص (`_asMap`, `_asInt`, `_text`, `_strings`, `_double`, `_bool`) — أي **mappers على Bhagwan JSON** داخل طبقة النطاق. الكود مكرر حرفياً بين الملفات الأربعة (نفس `_asMap`/`_text` مكرر 4 مرات).
- **Why problematic:** (أ) knowledge بشكل الـ wire داخل domain — تغيير اسم حقل في الخادم يفرض تعديل domain؛ (b) تكرار helpers quartet; (ج) **المشروع نفسه يملك العُرف الصحيح**: `lib/features/inspection/domain/inspection_transfer.dart:1-6` يصرّح: «قراءة أجسام الخادم (الـ parsing) في `data/mappers/inspection_mappers.dart`». ⇒ فالمشروع فيه **عُرفان**، وdomain هو الأقلية المخالفة.
- **Violated principle:** Layered separation of concerns: Domain models ≠ Data DTOs.
- **Current owner:** domain files.
- **Correct owner:** `features/codriver/data/mappers/`, `features/connection/data/mappers/`؛/domain يحتفظ بـ الكيان النقي فقط.
- **Consequences:** (1) تكرار 4× helpers؛ (2) domain غير قابل لإعادة الاستخدام لـ source آخر (mock/engine)؛ (3) خلط مسؤوليات.
- **Recommended correction:** انقل `parse*` + helpers إلى `data/mappers/` لكل feature، واجعل `domain` يحتفظ بـ `class` فقط (كما في `hardware_alert.dart`).
- **Related files:** `lib/features/inspection/domain/inspection_transfer.dart:1-6` (المرجع الصحيح), `lib/features/connection/domain/entities/hardware_alert.dart:1-2` (الكيان النقي المرجعي)
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE CON-006: تقسيم قاعدة MAC غير متسق بين domain و presentation (والـ formatter يضيق القاعدة)
- **Severity:** Low
- **Category:** Split validation policy / Inconsistent UX
- **Location:** `lib/features/connection/presentation/pages/eld_connection_page.dart:436-444` مقابل `lib/features/connection/domain/connectivity_status.dart:150`
- **Evidence:**
```dart
// lib/features/connection/presentation/pages/eld_connection_page.dart:436-443
                      maxLength: 17,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F:]')),
                      ],
                      onSubmitted: (_) => _attemptConnection(),
                      validator: (v) => macAddressError(
                        v,
                        loc: context.loc,
                      ),
```
```dart
// lib/features/connection/domain/connectivity_status.dart:148-151
/// `AA:BB:CC:DD:EE:FF` (or `-` separated). Shared by prefill and the
/// connection form so both agree on what a MAC looks like.
bool isMacAddress(String value) =>
    RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$').hasMatch(value.trim());
```
- **Current behavior:** (أ) `isMacAddress` (accepts `:` أو `-`) موجودة في domain وتُستخدم للـ prefill (`eld_connection_page.dart:316`)؛ (ب) الـ `validator` في presentation **لا يتحقق من الصيغة إطلاقاً** (illowing فقط) — وهذا **مقصود وموثّق** في `mac_address_validation.dart:4-5`؛ (c) لكن الـ `FilteringTextInputFormatter` في presentation **يحذف** أي حرف خارج `[0-9a-fA-F:]` أثناء الكتابة/اللصق.
- **Why problematic:** عدم اتساق: لو لصق السائق معرّفاً بصيغة `AA-BB-CC-...` (يقبله `isMacAddress` صراحةً كـ "valid MAC")، فإن الـ formatter **يحذف الشرطات** قبل التحقق. النتيجة: قيمة مُحوّلة تُرسل للخادم بشكل مختلف عن ما كُتب.
- **Violated principle:** Single source of validation truth.
- **Current owner:** presentation.
- **Correct owner:** مشتق واحد في domain (أو presentation) يُستخدم في الثلاثة (prefill + formatter + validator).
- **Consequences:**driver pastes a MAC, the field silently changes; server sees different value.
- **Recommended correction:** إمّا احذف الـ formatter (دع `isMacAddress` يتحقق)، أو اجعله يقبل `[0-9A-Fa-f:-]` ليطابق النطاق.
- **Related files:** `lib/features/connection/presentation/mac_address_validation.dart`
- **Confidence:** POTENTIAL (النية التصميمية — "لا ترفض الصيغة في العميل" — صحيحة؛ لكن الـ formatter يتعارض معها)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DOM-001: `lib/domain/duty_status/duty_status_code.dart` يستورد Flutter + logger ويحمل ألواناً — وينتشر إلى `backend/contracts`
- **Severity:** High
- **Category:** Domain purity breach (Flutter in shared domain)
- **Location:** `lib/domain/duty_status/duty_status_code.dart:7-8`, `:75-88`؛ الانتشار: `lib/backend/contracts/status_dashboard_backend.dart:2`, `lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart:1`, `lib/features/hos/presentation/providers/hos_provider.dart:12`, **و18 ملفاً آخر**
- **Evidence:**
```dart
// lib/domain/duty_status/duty_status_code.dart:7-8
import 'package:flutter/widgets.dart';
import '../../../core/utils/logger.dart';

// :74-88
  /// UI Color representation mapping
  Color get displayColor {
    switch (this) {
      case DutyStatusCode.onDutyNotDriving:
      case DutyStatusCode.yardMove:
      case DutyStatusCode.personalConveyance:
        return const Color(0xFFFBBF24); // AppColors.primaryGold
      case DutyStatusCode.offDuty:
        return const Color(0xFF6B7280); // AppColors.textSecondary
      case DutyStatusCode.driving:
        return const Color(0xFF10B981); // AppColors.successGreen
      case DutyStatusCode.sleeperBerth:
        return const Color(0xFFF59E0B); // AppColors.warningYellow
    }
  }
```
- **Current behavior:** **8 من 9 ملفات في `lib/domain/` نقي تماماً** (لا Flutter، لا Riverpod، لا Dio، لا features — تم التحقق من **كل** استيرادات الملفات التسعة). الملف التاسع `duty_status_code.dart` يخالف: (أ) يستورد `flutter/widgets.dart` (سطر 7)، (ب) يستورد `core/utils/logger.dart` (سطر 8)، (ج) يحمل `Color get displayColor` بـ hex **مكرَّرة حرفياً من `core/theme/app_colors.dart`** (تعليق السطر 80 يؤكد التكرار). أستورد `lib/backend/contracts/status_dashboard_backend.dart:2` و`lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart:1` ⇒ **نوع Flutter `Color` يُسحب إلى طبقة عقود البنية التحتية**.
- **Why problematic:** (أ) عقد الـ backend لم يعد نقيا؛ (ب) `displayColor` **ليس** قرار نطاق (business) — قرار عرض؛ (ج) القيم الستاسية مكرَّرة: تعديل لون في `AppColors.primaryGold` لن ينعكس على `DutyStatusCode.displayColor`.
- **Violated principle:** **"verify it imports nothing from Flutter/Riverpod/Dio/features"** — الملف الوحيد من التسعة الذي ينتهك.
- **Current owner:** `lib/domain/duty_status/duty_status_code.dart`.
- **Correct owner:** (أ) `displayColor` → `core/theme/status_color_mapper.dart` أو `core/utils/status_color_helper.dart` (الموجود!). (ب) `AppLogger.warning` → نبذه من domain (يمسح الاستيراد).
- **Consequences:** (1) `backend/contracts` و`backend/adapters` يعتمدان transitively على Flutter؛ (2) قيم لونية غير قابلة للتحديث؛ (3) `lib/domain/` غير صالحة كـ "domain مستقل".
- **Recommended correction:** احذف `flutter/widgets.dart` و`core/utils/logger.dart` من الملف؛ انقل `displayColor` إلى `core/utils/status_color_helper.dart` (المستورد أصلاً في `lib/core/utils/status_color_helper.dart:2`).
- **Related files:** `lib/core/utils/status_color_helper.dart:2`, `lib/backend/contracts/status_dashboard_backend.dart:2`
- **Confidence:** CONFIRMED (كل استيرادات الملفات التسعة تم فحصها)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DOM-002: جذور دومين متوازية — `lib/domain/**` و`lib/core/domain/entities/**`
- **Severity:** Medium
- **Category:** Structural incoherence
- **Location:** `lib/domain/**` (9 ملفات) مقابل `lib/core/domain/entities/{user, hos_models, location_point}.dart`
- **Current behavior:** المشروع فيه **جذران للمجال**: `lib/domain/` (account, config, duty_status, hardware, inspection, shared, signature) و`lib/core/domain/entities/` (user.dart, hos_models.dart, location_point.dart). كلاهما "domain"، وأحدهما ليس تحت `core`.
- **Why problematic:** (أ) `lib/domain/` يُستورد من **~130 استيراد في 60+ ملفاً** موزّعة على `lib/backend/**` و`lib/core/**` و`lib/features/**` كلها ⇒ **coupling واسع جداً**؛ (ب) وجود جذرين يجعل "أين domain؟" سؤالاً بلا جواب ⇒ قرارPlacement لـ`lib/domain` غيرcoherent مع وجود `lib/core/domain` بالتوازي؛ (c) `lib/domain/account/driver_account.dart` (network DTO) و`lib/core/domain/entities/user.dart` (persisted entity) غير المتجانسة.
- **Violated principle:** Single responsibility for placement of shared kernel.
- **Current owner:** بنية المشروع.
- **Correct owner:** إمّا `lib/domain/**` فقط (وتُلغى `lib/core/domain`)، أو `lib/core/domain/**` فقط. الموقف الحالي — 둘 موجودان — غيرcoherent.
- **Recommended correction:** قرّر جذراً واحداً؛ المرجّح `lib/core/domain/**` لتطابق بقية `core/`.
- **Confidence:** CONFIRMED (البنية معروضة)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DOM-003: `driver_account.dart` DTO شبكة داخل `lib/domain/` (يحمل `.g.dart`)
- **Severity:** Medium
- **Category:** Data DTO in domain
- **Location:** `lib/domain/account/driver_account.dart:3-4`, `:24`
- **Evidence:**
```dart
// lib/domain/account/driver_account.dart:3-4
part 'driver_account.freezed.dart';
part 'driver_account.g.dart';

// :24
  factory DriverAccount.fromJson(Map<String, dynamic> json) => _$DriverAccountFromJson(json);
```
- **Current behavior:** من التسعة، **هذا الملف الوحيد** يحمل `part '*.g.dart'` (json_serializable) ⇒ هو **DTO طبقة بيانات** لا كيان نطاقي. ويستخدمه `lib/backend/adapters/eld_engine/sub/eld_account_backend.dart` كنموذج سلك.
- **Why problematic:** (أ) خلط: كل ملفات `lib/domain` الأخرى (value_objects, status_dashboard, telemetry_reading, signature, dot_inspection) هي freezed بدون `.g.dart` — **هذا الملف outlier**؛ (ب) `DriverAccount` هو في الواقع "Account read model من الخادم" وليس domain invariant.
- **Violated principle:** Domain ≠ DTO.
- **Current owner:** `lib/domain/account/driver_account.dart`.
- **Correct owner:** `lib/features/account/data/models/driver_account_dto.dart` (أو mapper ← domain entity).
- **Consequences:** (1) الحزمة shared domain تعتمد على أداة توليد JSON؛ (2) ترقّب على تغيير شكل الاستجابة.
- **Recommended correction:** انقل إلى `features/account/data/models/`، أو اجعله entity صافية + mapper منفصل.
- **Related files:** `lib/backend/adapters/eld_engine/sub/eld_account_backend.dart:3-4`, `lib/backend/contracts/account_backend.dart:2-3`
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DOM-004: `server_config.dart` يخلط سياسة تطبيع العنوان داخل DTO
- **Severity:** Low
- **Category:** Mixed responsibility in value/DTO
- **Location:** `lib/domain/config/server_config.dart:49-58`
- **Evidence:**
```dart
// lib/domain/config/server_config.dart:48-58
  /// Normalizes a URL: trims, ensures scheme, removes trailing slashes.
  static String normalizeUrl(String url) {
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
- **Current behavior:** DTO بلا `.g.dart` يحمل **سياسة تطبيع عنوان** + **افتراضي أمني `https://`** (سطر 52) + **مجموعة مصطلحات ثانية** (`BackendType`) تparallel لـ `lib/backend/core/backend_kind.dart` (`BackendKind`).
- **Why problematic:** (أ) `normalizeUrl` سياسة (تُستدعى من `ServerConfig.unverified/verified`) — مكانها 자연 هو  domain policy أو config service لا static داخل DTO؛ (b) `BackendType` vs `BackendKind` — معجمان مختلفان لنفس "نوع الـ backend" (eldEngine/mock vs eld/traccar) ⇒ التباس.
- **Violated principle:** Separate config DTO from config policy.
- **Current owner:** `lib/domain/config/server_config.dart`.
- **Correct owner:** `ServerConfigProvider` / `core/config/server_config_store.dart` (المستهلك الحالي).
- **Recommended correction:** انقل `normalizeUrl` إلى `core/config/`؛ ووحّد `BackendType`/`BackendKind`.
- **Related files:** `lib/backend/core/backend_kind.dart:11-19`, `lib/core/config/server_config_store.dart:7`
- **Confidence:** CONFIRMED (لاحظ: `BackendType.traccar` يبدو legacygiven the ELD engine)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE DOM-005: لا يوجد أي فحص معماري آلي؛ علامات `// ignore_architecture` أصبحت بلا أثر
- **Severity:** Low
- **Category:** Missing guardrail
- **Location:** `analysis_options.yaml` (فحصه كاملاً: `linter: rules:` فارغ عملياً)؛ `lib/core/di/app_providers.dart:3,7,10`
- **Evidence:**
```dart
// lib/core/di/app_providers.dart:3
import 'package:golden_feather_eld/backend/providers/backend_providers.dart'; // ignore_architecture
...
// :10
import 'package:golden_feather_eld/features/auth/data/repositories/auth_repository_impl.dart'; // ignore_architecture
```
- **Current behavior:** المشروع يستخدم وسم `// ignore_architecture` كوَسم مهني في `app_providers.dart`، لكن `analysis_options.yaml` لا يعرّف أي lint باسم architecture (تم التحقق: `linter: rules:` لا يحتوي شيء). ⇒ الوسم **لا يفعل شيئاً** — حماية زائفة.
- **Why problematic:** بدون أداة، كل المخالفات أعلاه (SUI/aip provider = repository، domain→Flutter، application→presentation) تمر بلا إنذار. `custom_lint` أو `dependency_rules` أو `dart_code_metrics` من `analysis_options.yaml` كان كفيلاً بكشف 6 من 9 ملاحظات High.
- **Violated principle:** Executable architecture.
- **Current owner:** — (missing)
- **Correct owner:** `analysis_options.yaml` + `dependency_rules`-style config.
- **Recommended correction:** فعّل `dependency_rules` بالحدود: `lib/domain/**` ⊅ `flutter/`, `features/*/presentation/**` ⊅ `features/*/data/**` و `backend/adapters/**`.
- **Confidence:** CONFIRMED

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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
- **Why problematic:** (أ) **إجابة فحص المطلوب:** الموضع **ليس خطأً طبقياً صارماً** (لا استيراد Flutter/Dio/Riverpod — تحقّقت)، لكنه **مسؤولية مختلطة**: قراءة JSON ووصل HTTP من مسؤوليات  data داخل `domain/`. (ب) `readVehicle` يقرأ `'uniqueId'` و`'vehicleId'` و`'myVehicle'` و`'inUseByOtherDriver'` — أسماء حقول خادم wire داخل domain. (ج) `vehicleOperateFailure` خريطة HTTP، ويستهلكها `vehicle_repository_impl.dart:72-80`.
- **Violated principle:** SRP، Layer Cohesion.
- **Current owner:** `vehicle/domain/vehicle_selection.dart`
- **Correct owner:** `vehicle/data/mappers/vehicle_mappers.dart` لـ JSON + HTTP mapping؛ وتبقى القواعد الصرفة في domain.
- **Consequences:** تغيير اسم حقل في API يمسّ domain؛ لا يمكن تبديل strategy قراءة بلا تعديل domain.
- **Recommended correction:** فصل الملف إلى (1) `vehicle_selection_rules.dart` (domain: `listedVehicleIsOperable`, `refuseVehicleOperate`, `readOperableUniqueId`)، (2) `vehicle/data/mappers/vehicle_mappers.dart` (JSON)، (3) خريطة HTTP في `vehicle_repository_impl`.
- **Related files:** `vehicle/data/repositories/vehicle_repository_impl.dart:35-56, 72-80`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

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

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-01: `DutyStatusTracker` في مجلد domain يتصل بمستودع ميزة أخرى
- **Severity:** Critical
- **Category:** Domain Purity / Cross-Feature Coupling
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:4` و `:284`
- **Evidence:**
```dart
 4: import '../../../../logs/domain/repositories/log_repository.dart';
...
284:      _logRepository.savePeriod(period).then((result) {
285:        result.match(
286:          (failure) =>
287:              AppLogger.error('Failed to save period', failure.message),
288:          (success) => AppLogger.info('Period saved successfully'),
289:        );
290:      });
```
- **Current behavior:** صنف داخل `features/hos/domain/` يحتفظ بمرجع إلى `LogRepository` (عقد feature `logs`) وينفّذ عملية كتابة غير متزامنة عليه.
- **Why problematic:** (1) `features/hos` لا يستطيع أن يُختبر أو يُستبدل دون `features/logs`. (2) كيان `DutyPeriod` المستخدم هنا معرَّف في `core/domain/entities/hos_models.dart` أي أنه **مشترك**؛ فالمستودع الصحيح هو مستودع HOS نفسه لا مستودع السجلات. (3) الملف يسمي نفسه «domain pure» في `line 7` والتعليق كاذب معمارياً.
- **Violated principle:** Dependency Inversion + Feature Isolation + توثيق صادق.
- **Current owner:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart`
- **Correct owner:** عقد `DutyPeriodRepository` في `lib/features/hos/domain/repositories/`.
- **Consequences:** أي حذف/تغيير في feature `logs` يكسر HOS؛ دوائر HOS تتطلب تهيئة Hive لسجلات logs؛ أي تغيّر في تخطيط تخزين logs يتسلل إلى HOS.
- **Recommended correction:** استخراج واجهة `abstract class DutyPeriodRepository { Future<void> savePeriod(DutyPeriod p); }` في `hos/domain/repositories/`، حقنها في `DutyStatusTracker`، وتنفيذها في `hos/data/repositories/` على نفس Hive box دون ربط.
- **Related files:** `lib/features/logs/domain/repositories/log_repository.dart:85`, `lib/features/hos/presentation/providers/hos_engine_provider.dart:43`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-02: `DutyStatusTracker` (domain) يستورد طبقة البنية التحتية وطبقة backend وأداة uuid
- **Severity:** Critical
- **Category:** Domain Purity
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:5` و `:11` و `:13`
- **Evidence:**
```dart
 5: import '../../../../../core/services/local_storage_service.dart';
...
11: import 'package:uuid/uuid.dart';
...
13: import '../../../../../backend/contracts/status_dashboard_backend.dart';
```
(`core/services/local_storage_service.dart:1-5` يستورد `dart:io` و `package:shared_preferences/shared_preferences.dart`.)
- **Current behavior:** صنف domain يعتمد على: خدمة تخزين محلية قائمة على SharedPreferences، مولّد UUID عشوائي، وعقد backend.
- **Why problematic:** `domain` لا يجب أن يعتمد قابلاً للاستبدال على Flutter/plugins؛ `SharedPreferences` يتطلب plugin channel؛ `uuid` مولّد عشوائي (غير حتمي) في طبقة قانونية؛ و`StatusDashboardBackend` عقد شبكة داخل domain.
- **Violated principle:** Dependency Rule (domain innermost) + Domain determinism.
- **Current owner:** الملف نفسه.
- **Correct owner:** الواجهات (clock/ids) تُحقن كواجهات (`TimeAuthority`, `IdGenerator` — يوجد فعلاً في `core/`، مستخدَم في `log_repository_impl.dart:336`). التخزين عبر مستودع domain. الاتصال عبر use-case في `application/`.
- **Consequences:** استحالة اختبار نقي لمحرك HOS؛ تسرّب تبعيات native إلى طبقة المجال؛ عدم قابلية استبدال مصدر الأرقام العشوائية.
- **Recommended correction:** استبدال `LocalStorageService` بواجهة `DutyStatusStore`؛ استبدال `const Uuid().v4()` (`line 216`) بـ `IdGenerator`؛ نقل نداء `_dashboardBackend` إلى use-case في `hos/application/`.
- **Related files:** `lib/features/logs/data/providers/log_repository_providers.dart:8` (نفس النمط الصحيح)، `lib/features/hos/presentation/providers/hos_engine_provider.dart:44-46`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-04: عتبة «المركبة متحركة» متباعدة بين miles و km
- **Severity:** High
- **Category:** Business Logic Location / Unit Mismatch
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:106` مقابل `lib/features/hos/domain/engine/hos_rules_engine.dart:80`
- **Evidence:**
```dart
// duty_status_tracker.dart:106
    if (eldEvent.speedMph > 5.0) {
```
```dart
// hos_rules_engine.dart:79-84
    required double currentSpeedKmh,
    required double speedThresholdKmh,
  }) {
    if (currentStatus == DutyStatus.driving &&
        newStatus != DutyStatus.driving) {
      if (currentSpeedKmh >= speedThresholdKmh) {
```
- **Current behavior:** المتتبع يقارن **ميل/ساعة** بالعتبة `5.0` المثبتة، بينما المحرّك يقارن **كم/ساعة** بـ `HosConfiguration.movingSpeedThresholdKmh = 8.0`.
- **Why problematic:** رقمان يمثّلان العتبة الفيزيائية نفسها (5 mph ≈ 8.05 km/h) لكن كلٌّ في وحدته وحيّده. تعديل `movingSpeedThresholdKmh` (مثلاً لولاية أخرى) **لن يؤثر على الانتقال التلقائي**، بينما يؤثر على الرفض اليدوي — سلوكان متناقضان من نفس المفهوم. كما أن `FmcsaConstants.drivingSpeedThresholdMph = 5.0` (`lib/core/constants/fmcsa_constants.dart:10`) موجودة ولم تُستخدم هنا.
- **Violated principle:** DRY + Consistent Rule Source.
- **Current owner:** `duty_status_tracker.dart:106`
- **Correct owner:** `HosConfiguration` مع حقل مفرد معرَّف على الوحدات (`movingSpeedThresholdMph`) يُحوَّل في `HosCalculator` لا في المتتبع.
- **Consequences:** عتبة 5.0 mph بينما الرفض اليدوي عند 8.0 km/h — هامش 0.05 km/h فقط بين عمليتين من نفس القاعدة.
- **Recommended correction:** احذف `5.0`؛ حقن `HosConfiguration` في `DutyStatusTracker` واستخدم `movingSpeedThresholdKmh` بعد التحويل، أو أضف `movingSpeedThresholdMph` إلى `HosConfiguration` واستخدمه.
- **Related files:** `lib/core/config/hos_configuration.dart:31`, `lib/core/constants/fmcsa_constants.dart:7-10`, `lib/features/hos/presentation/providers/hos_engine_provider.dart:72-75`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-05: تحويل الوحدات (ميل→كم) داخل domain
- **Severity:** Medium
- **Category:** Layer Responsibility
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:227`
- **Evidence:**
```dart
227:        if (odometer != null) 'odometerKm': odometer * 1.609344,
```
- **Current behavior:** domain يحوّل من الميل إلى الكيلومتر أثناء بناء حمولة `PendingEvent`.
- **Why problematic:** (1) هذا اشتقاق **سلكي** (wire) داخل domain. (2) التحويل **معكوس** في data: `log_model.dart:59: odometer = km * _kmToMiles;` — إذن الطبقتان تعملان بوحدتين مختلفتين وتحوّلان في اتجاهين متعاكسين. ثلاث تحويلات في ثلاث طبقات لنفس الحقل.
- **Violated principle:** Single Unit of Measure + Separation.
- **Current owner:** `duty_status_tracker.dart:227`
- **Correct owner:** الـ mapper في `data/` (تحويل `DutyPeriod`/`PendingEvent` إلى DTO سلكي).
- **Consequences:** احتمال خطأ عند التصحيح؛ صعب تتبع أي طبقة تملك القيمة الحقيقية.
- **Recommended correction:** اجعل `DutyPeriod` يحمل `odometerKm` بوحدته، وضع التحويل كله في mapper واحد في data.
- **Related files:** `lib/features/logs/data/models/log_model.dart:55-62`, `lib/core/domain/entities/hos_models.dart` (`odometerMiles`)
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-06: `DutyStatusTracker` يبني حمولة شبكة ويخمّن «هل الخطأ شبكي؟» بنص الخطأ
- **Severity:** High
- **Category:** Layer Responsibility / Fragile Error Handling
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:218-230` و `:370-374`
- **Evidence:**
```dart
218:      payload: {
219:        'status': wireStatus,
220:        'startTime': stamp.toIso8601String(),
221:        if (_readDriverId?.call() != null) 'driverId': _readDriverId!.call(),
...
370:      final isNetwork = error.code.contains('network') ||
371:          error.code.contains('connection') ||
372:          error.code.contains('timeout') ||
373:          error.code.contains('offline') ||
374:          error.context?['statusCode'] == null;
```
- **Current behavior:** domain (أ) يبني خريطة JSON كاملة لـ `PendingEvent`، (ب) يقرأ `error.code` و`error.context` كـ `Map` غير مُنمّط لتقرير نوع الخطأ.
- **Why problematic:** (1) أسماء الحقول السلكية (`locationText`, `notes`, `driverId`, `odometerKm`) متشعبة بين domain و`log_repository_impl.dart:171-176` — نفس العقد مكتوب يدوياً في مكانين. (2) `error.context?['statusCode'] == null` مقارنة على `Map` غير مُنمّط — **مقارنة `== null` تُعامَل كـ «خطأ شبكي»**، أي أن **أي خطأ خادمي بلا statusCode يُختبر محلياً رغم أنه قد يكون رفض تحقق**. (3) منطق I/O داخل domain.
- **Violated principle:** Layered Architecture + Typed Errors.
- **Current owner:** الملف نفسه.
- **Correct owner:** mapper في data + `Failure` مُنمّط في `core/error/`.
- **Consequences:** خطأ تحقق 400 بلا `statusCode` قد يُقبل محلياً — مخالفة FMCSR محتملة.
- **Recommended correction:** استخدم `NetworkFailure`/`ServerFailure` المُنمّطة بدل فحص النص؛ انقل بناء الـ payload إلى `data/datasources/`.
- **Related files:** `lib/features/logs/data/repositories/log_repository_impl.dart:170-177`, `lib/features/sync/domain/entities/pending_event.dart`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-07: `TrustedTimeProvider` (مستهلك محرك HOS) يُعرِّف Riverpod Provider داخل نفس الملف
- **Severity:** Medium
- **Category:** Domain Purity (transitive)
- **Location:** `lib/features/hos/domain/engine/hos_calculator.dart:2` → `lib/core/time/trusted_time_provider.dart:3-4` و `:200`
- **Evidence:**
```dart
// hos_calculator.dart:2
import '../../../../core/time/trusted_time_provider.dart';
```
```dart
// trusted_time_provider.dart:3-4
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
...
200: final trustedTimeProvider = Provider<TrustedTimeProvider>((ref) {
```
- **Current behavior:** ملف واحد يجمع الواجهة + التنفيذ + DI + `FakeTrustedTimeProvider` للاختبار.
- **Why problematic:** محرك HOS (`hos_calculator`, `hos_rules_engine`, `hos_state_machine`, `duty_status_tracker`) لا يستطيع أن يُستورد دون أن يجرّ Riverpod و SharedPreferences. أي أن «نقاء domain» موروث ومخترق.
- **Violated principle:** Dependency Rule.
- **Current owner:** `core/time/trusted_time_provider.dart` (ملف واحد بأربعة أدوار).
- **Correct owner:** الواجهة في `trusted_time_provider.dart` فقط، التنفيذ في `trusted_time_provider_impl.dart`، DI في `core/time/providers/`.
- **Consequences:** لا يمكن اختبار محرك HOS مع `FakeTrustedTimeProvider` دون تحميل Riverpod؛ اقتران غير مقصود.
- **Recommended correction:** قسّم الملف إلى ثلاثة.
- **Related files:** `lib/features/hos/domain/engine/hos_state_machine.dart:5`, `lib/features/hos/domain/engine/hos_rules_engine.dart:6`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-09: `HosRulesEngine` يُرجع `ServerFailure` من طبقة domain
- **Severity:** Medium
- **Category:** Layer Responsibility / Domain Vocabulary
- **Location:** `lib/features/hos/domain/engine/hos_rules_engine.dart:85-87`
- **Evidence:**
```dart
85:      return Left(ServerFailure(
86:          message:
87:              'Cannot manually change from DRIVING while vehicle is moving ($currentSpeedKmh km/h)'));
```
- **Current behavior:** محرك يرفض انتقالاً قانونياً بمخالفة **نقل** (`ServerFailure`) ويضع نصاً إنجليزياً فيه.
- **Why problematic:** `ServerFailure` تعني «رفض الخادم» — لا علاقة لها بقاعدة «لا تبدّل أثناء الحركة». المستهلك (`hos_provider.dart:104`) يسجّل `validationResult.fold((f) => f.message, …)` فينتج سجلاً يحوي سرعة حيّة متغيرة — قيمة غير ثابتة في سجل أخطاء.
- **Violated principle:** Ubiquitous Language + Layered error model.
- **Current owner:** engine.
- **Correct owner:** نوع خطأ مجال (`TransitionRefusal`) يُترجم في presentation.
- **Consequences:** سجلات تحوي أرقاماً متغيرة؛ التمييز بين رفض المجال ورفض الخادم مستحيل.
- **Recommended correction:** أعد `Either<Failure, void>` مع `DutyTransitionViolation` وعرفها في domain، واعرضها عبر `dutyChangeMessage()` الموجودة أصلاً في `presentation/duty_change_message.dart`.
- **Related files:** `lib/features/hos/presentation/providers/hos_provider.dart:103-106`, `lib/core/error/failure.dart`
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
### ISSUE HL-15: قاعدة «لا تبديل أثناء القيادة» مسجّلة بلا `return`
- **Severity:** High
- **Category:** Correctness / Legal Rule Not Enforced
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:417-420`
- **Evidence:**
```dart
417:    if (_currentStatus == 'driving' && newStatus != 'driving') {
418:      AppLogger.warning(
419:          'Cannot manually transition from driving while moving.');
420:    }
```
- **Current behavior:** القاعدة **تُسجَّل ثم يتدفق التنفيذ**. الانتقال يكمل إلى `line 428: _transitionTo(...)`.
- **Why problematic:** استدعاءا `DutyStatusTracker.manualTransition` / `submitManualChange` عبر هذا المسار يسجل تغيير حالة قانونياً رغم أن القاعدة المعلنة تمنعه. (المسار الفعلي من الواجهة يمر أولاً بـ `hos_provider.dart:103` الذي يفحص عبر engine، لكن المتتبع نفسه — وهو مصدر الحقيقة للتتبع — لا يحميه؛ و`manualTransition` في `line 324` مستدعى من أي مكان آخر.)
- **Violated principle:** Business Rule Enforcement / Fail-safe.
- **Current owner:** الملف نفسه.
- **Correct owner:** نفس الملف — يحتاج `return`/رفض.
- **Consequences:** سجل ELD قد يحتوي انتقالاً يدوياً غير قانوني. مخالفة FMCSA §395.8.
- **Recommended correction:** `return const ManualDutyChangeResult(refusal: DutyStampRefusal.moving);` أو ارفع الفحص إلى use-case ووحّد المصدر بين `manualTransition` و`submitManualChange`.
- **Related files:** `lib/features/hos/presentation/providers/hos_provider.dart:95-106`, `lib/features/hos/presentation/providers/change_status_provider.dart:278-280`
- **Confidence:** **CONFIRMED** (السلك)، **POTENTIAL** (مدى بلوغه؛ `manualTransition` غير مستدعَى خارج الملف حسب البحث)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-17: `logs/domain/daily_form_rules.dart` يستورد Flutter عبر l10n
- **Severity:** High
- **Category:** Domain Purity
- **Location:** `lib/features/logs/domain/daily_form_rules.dart:7`
- **Evidence:**
```dart
 7: import '../../../../l10n/app_localizations.dart';
```
و `lib/l10n/app_localizations.dart:3-4`:
```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
```
- **Current behavior:** ملف domain يعتمد على كائن يعتمد على `BuildContext` و`Localizations`.
- **Why problematic:** الملف يحتوي قواعد تحقق ممتازة بمحتوى غير قابل للنقاش (RegExp عربية `\p{L}`)، لكنه **لا يمكن اختباره في unit test Dart نقي** بدون Flutter test harness. والأنوأ: الملف لا يُرجع رمز خطأ بل **نصاً**، و`line 86-90` يختار نصوصاً عربية/إسبانية/إنجليزية **من داخل domain**:
```dart
86:    return loc.localeName == 'ar'
87:        ? 'يجب أن يحتوي رقم الوثيقة على حروف وأرقام وعلامات بسيطة فقط'
88:        : (loc.localeName == 'es'
89:            ? 'El número de documento solo debe contener letras, números y signos básicos'
90:            : 'Document number must contain letters, numbers, and basic signs only');
```
هذه **أكبر مخالفة** في الملف: ثلاث لغات مكتوبة يدوياً داخل طبقة المجال، بينما بقية المشروع كله فوق `.arb`.
- **Violated principle:** Domain Purity + i18n discipline.
- **Current owner:** الملف.
- **Correct owner:** القواعد تبقى هنا؛ **النصوص** تنتقل إلى `l10n` كمفتاح `trailerNumberFormatErrorInvalidChars` لكل لغة.
- **Consequences:** كل لغة جديدة تُعدّل ملف Dart داخل domain؛ لا اختبار نقي للقواعد.
- **Recommended correction:** غيّر التوقيع إلى `String? trailerNumberError(String value, {required String enterMsg, required String formatMsg, required String invalidCharsMsg})` أو أعِد رمز خطأ (`enum TrailerError { empty, invalidChars, … }`) وتُترجم في presentation.
- **Related files:** `lib/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart:142,166,353,360`, `lib/features/logs/presentation/pages/trailers_page.dart:41`, `lib/features/logs/presentation/pages/shipping_documents_page.dart:40`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-18: تحليل استجابات JSON داخل domain
- **Severity:** Medium
- **Category:** Layer Responsibility
- **Location:** `lib/features/logs/domain/saved_form_status.dart:10-26`؛ `lib/features/logs/domain/entities/audit_entry.dart:44-84`
- **Evidence:**
```dart
// saved_form_status.dart:10-14
SavedFormRead readSavedForm(Map<String, dynamic> json) {
  final body = json['data'] is Map
      ? Map<String, dynamic>.from(json['data'] as Map)
      : json;
  final raw = body['formStatus']?.toString().trim();
  final message = body['message']?.toString().trim();
```
```dart
// audit_entry.dart:44-48
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      // ISO string: _saveToBox يستخرج مفتاح اليوم من نص ISO.
      'timestamp': timestamp.toIso8601String(),
```
- **Current behavior:** domain يقرأ `json['data']`, `json['formStatus']`, `json['message']`، ويفحص `'COMPLETED'/'COMPLETE'/'INCOMPLETE'/'IN_PROGRESS'`؛ الكيان ينتج خريطة تخزين.
- **Why problematic:** (1) `'data'` غلاف HTTP — مكانه `log_repository_impl.dart` الذي ينفّذ `readSavedForm(json)` في `line 359`. (2) `AuditEntry.toMap()` يخص **Hive**؛ التعليق في `line 47` «_saveToBox يستخرج مفتاح اليوم من نص ISO» يربط الكيان بمصدر بيانات محدد.
- **Violated principle:** Domain knows nothing about persistence/transport.
- **Current owner:** domain.
- **Correct owner:** `logs/data/models/` (mapper).
- **Consequences:** تغيير أي حقل في domain يمسّ طبقة النقل.
- **Recommended correction:** انقل `readSavedForm` إلى `data/models/saved_form_mapper.dart`، واحذف `toMap`/`fromMap` من `AuditEntry` إلى `data/models/audit_entry_mapper.dart`.
- **Related files:** `lib/features/logs/data/repositories/log_repository_impl.dart:359`, `lib/features/logs/data/datasources/log_local_data_source.dart:288`
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
### ISSUE HL-30: `LogEvent.props` يُسقط `location` وأربع حقول من مفتاح family
- **Severity:** Medium
- **Category:** Correctness (Riverpod identity)
- **Location:** `lib/features/logs/domain/entities/daily_log.dart:248-250` مستهلَك في `lib/features/logs/presentation/providers/edit_log_form_provider.dart:55-56`
- **Evidence:**
```dart
// daily_log.dart:248-250
  @override
  List<Object?> get props =>
      [id, status, startTime, duration, location, isExpanded];
```
```dart
// edit_log_form_provider.dart:55-56
final editLogFormProvider = StateNotifierProvider.autoDispose
    .family<EditLogFormNotifier, EditLogFormState, LogEvent?>((ref, event) {
```
- **Current behavior:** `LogEvent` هو **مفتاح family**. عندما يصل التحديث من الخادم وتختلف `location` فقط — والقيمة مستثناة من `props` — deems Riverpod الكيانين متساويين ولا يعيد بناء الـ provider. لكن `location` **نعم** مُدرجة في props في السطر أعلاه.
- **ملاحظة مقدَّرة:** بعد مراجعة دقيقة — `location` **موجود** في `props`. الحقول المستثناة فعلاً: `odometer`, `engineHours`, `automatedDriving`, `editable`. الاستثناء الحاسم هو **`editable`**، وهو الحقل الذي يحدد **`خط القلم في `events_tab.dart:78-79`**:
```dart
                      onEdit: (event.automatedDriving == true ||
                              event.editable == false)
                          ? null
```
فإذا تغيّر `editable` من الخادم، deems الكيانان متساويين ⇒ لا إعادة بناء ⇒ **قلم التعديل على حدث مقفل قانونياً يبقى ظاهراً** (أو العكس).
- **Why problematic:** سعة `props` غير مكتملة بينما الكيان يُستخدم كمفتاح هوية.
- **Violated principle:** Value-object identity completeness.
- **Current owner:** `daily_log.dart:248`
- **Correct owner:** نفس الملف — إما إكمال `props`، أو تحويل family key إلى `String? eventId`.
- **Consequences:** زر تعديل على حدث لا يجوز تعديله.
- **Recommended correction:** أكمل `props`، أو اجعل family key معرّفاً صريحاً.
- **Related files:** `lib/features/logs/presentation/widgets/log_detail_tabs/events_tab.dart:78-85`
- **Confidence:** **POTENTIAL** (الأثر الخاطئ محتمل؛ لم يُشغَّل الكود)

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-35: عقد نصي مشترك بين widget و domain مربوط بتعليق فقط
- **Severity:** Low
- **Category:** Implicit Contract
- **Location:** `lib/features/logs/presentation/widgets/time_picker_sheet.dart:69-72` ↔ `lib/features/logs/domain/log_edit.dart:41-43`
- **Evidence:**
```dart
// time_picker_sheet.dart:69-72
                onPressed: () {
                  // Always use English AM/PM so parseEditFormTime can parse it properly.
                  final time = '${_selectedHour.toString().padLeft(2, '0')}:${_selectedMinute.toString().padLeft(2, '0')}:${_selectedSecond.toString().padLeft(2, '0')} $_selectedPeriod';
                  widget.onDone(time);
                },
```
```dart
// log_edit.dart:41-43
  final m12 = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM)$',
          caseSensitive: false)
      .firstMatch(trimmed);
```
- **Current behavior:** الـ widget ينتج نصاً، والـ domain يحلّله بـ regex. العقد **نصّي غير مُنمّط**، رابطه تعليق فقط.
- **Why problematic:** أي تعديل على تنسيق الإخراج يكسر التحليل صامتاً (`parseEditFormTime` يعيد `null` ⇒ `invalidTime`).
- **Violated principle:** Type Safety across layers.
- **Current owner:** — / **Correct owner:** value object أو `TimeOfDay` من Flutter يُمرَّر كـ `DateTime`.
- **Consequences:** كسر صامت عند أي تغيير في الطرف.
- **Recommended correction:** مرّر `TimeOfDay` من الـ widget، ودع `domain` يستقبل `DateTime`.
- **Related files:** `lib/core/time/time_formatter.dart:37`
- **Confidence:** **CONFIRMED**

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-38: توالد الأرقام الإحصائية والإحصاءات داخل domain tracker بنوع غير مُنمّط
- **Severity:** Low
- **Category:** Primitive Obsession / Dead Code
- **Location:** `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:444-535`
- **Evidence:**
```dart
444:  Map<String, double> getTodayStats() {
445:    final now = _getCurrentTime();
446:    if (now == null) {
447:      return {
448:        'driving': 0,
449:        'on_duty': 0,
450:        'off_duty': 0,
451:        'sleeper': 0,
452:        'distance': 0,
453:      };
...
455:    final todayStart = DateTime(now.year, now.month, now.day);
```
- **Current behavior:** دالتان تُعيدان `Map<String, double>` بمفاتيح نصية، ومفتاح `'sleeper'` يختلف عن `'sleeper_berth'` المستخدم في الـ switch (`line 473`) — **عدم تطابق تسمية**.
- **Why problematic:** (1) **كود ميت**: البحث في `lib/` لم يجد أي مستهلك لـ `getTodayStats`/`getWeekStats`. (2) `Map<String,double>` بنصوص حرة في domain ⇒ نقطة فشل صامتة. (3) `DateTime(now.year, now.month, now.day)` يبني **وقتاً محلياً من UTC** (`_getCurrentTime()` يُرجع UTC) ⇒ حدّ اليوم محسوب في TZ الجهاز لا في TZ التنظيمي.
- **Violated principle:** Primitive Obsession + Dead code.
- **Current owner:** الملف.
- **Correct owner:** احذفه، أو `DutySummary` entity في domain.
- **Consequences:** لا أثر مباشر؛ كود ميّت في ملف مخالف.
- **Recommended correction:** احذف الدالتين (لا مستهلك لهما).
- **Related files:** — (بحث `lib/` عن `getTodayStats|getWeekStats` أعاد ملفّها فقط)
- **Confidence:** **CONFIRMED** (الموجود)، **POTENTIAL** (أهمية حدّ اليوم الزمني)

--------------------------------------------------

--------------------------------------------------



