# 06 — تدقيق طبقة البيانات والشبكة (Data & Network Audit)

## نطاق التدقيق

`lib/backend/**` (contracts, adapters/eld_engine, adapters/mock, core, http/interceptors, providers)، `lib/features/*/data/**` (datasources, models, mappers, repositories, services)، `lib/core/network/**`، `lib/core/services/**`، `lib/core/storage/**`.

## البصمات المعمارية الفعلية (تم التحقق منها)

هذه نقاط القوة — موثّقة عمداً لمنع «الإصلاح الزائد»:

- **موقع بناء `Dio` واحد فقط في المشروع كله.** لا تكرار، لا نسخ صامتة.
- **لا اعتراضات مكرّرة.** Despite وجود `lib/backend/http/api_config.dart` و`lib/core/network/api_config.dart`، التحقق أثبت أن الأول **ملف تعليقات ميت (7 أسطر) لا يُستورد من أي مكان** (BACK-028). التكرار الحقيقي ليس في الاعتراضات بل في **تطبيع URL ثلاثي النسخ عبر طبقتين** (BACK-026).
- **العقود (`contracts/`) خالية من Dio** — لا `DioException` ولا status code في العقد.
- **طبقة المحوّلات (mappers) جودة عالية** — المشكلة في التغطية لا في الجودة.
- **التوكن في `FlutterSecureStorage`**، ولا يوجد أي `print` أو تسجيل لبيانات الاعتماد (SEC-001، تأكيد موجب بعد فحص الـ 24 نداء `AppLogger` في ملفات auth).
- **`request_logger` محصور بـ `kDebugMode`** — لا تسريب في الإنتاج (لكن BACK-032: جسم الخطأ يُطبع بلا إخفاء حتى في debug).
- **`offline_queue.dart` منفذ نظيف** — لا تسريب لـ sqflite (فرضية مرفوضة بالتحقق).

## انقلاب الاتجاه في العقد (BACK-004) — CRITICAL

الملف الذي يفترض أنه «منفذ» يستورد من مجلد المحوّل:
```dart
// lib/backend/contracts/daily_logs_backend.dart:3-4
import '../adapters/eld_engine/models/certify_dto.dart';
import '../adapters/eld_engine/models/readiness_dto.dart';
```
**النتيجة المباشرة المُقاسة**: `MockDailyLogsBackend` (`mock_daily_logs_backend.dart:5-6`) *مُجبر* على استيراد DTOات محرك ELD للوصول إلى توقيع العقد. الموك لم يعد بديلاً مستقلاً — هذا يُبطل_ports & adapters_ كلياً، ويفسّر لماذا 22 من 58 دالة عقد (38%) `throw UnimplementedError`.

## تسرّب `RawJson` (BACK-001)

`contracts/raw_json.dart:10` يصدّر `RawJson` كـ typedef. التتبّع أثبت وصوله إلى:
- **domain**: `duty_status_tracker.dart:13,46`
- **presentation**: 7 مواقع

نوع JSON الخام في عقد النطاق يعني أن «نقاء domain» اصطلاحي: الـ domain يفهم شكل الخادم.

## انحراف صامت في شكل الاستجابة (BACK-008)

```dart
// mock_dvir_backend.dart:20  يعيد
{'reports': []}
// بينما dvir_repository_impl.dart:54  يقرأ
rawJson['data']
```
**لا خطأ، لا exception، لا log** — قائمة DVIR فارغة دائماً تحت الموك. هذا هو أخطر  نوع من التباين: فشل صامت في بيئة الاختبار يعني أن الاختبارات تعطي ثقة زائفة.

## تتبّع عملية API نموذجية

مسار `login` عبر الطبقات الفعلية:

```
auth_page.dart (presentation)
  → authStateProvider (presentation, 293 سطراً)  ← absorb سياسات الهوية (AUTH-001)
     → loginUseCase (domain, 32 سطراً)             ← pass-through (AUTH-002)
        → AuthRepository (domain contract)
           → AuthRepositoryImpl (data, 177 سطراً)
              → AuthBackend (backend contract)
                 → EldAuthBackend (eld_engine)     ← يتجاوز ApiClient (BACK-011)
                    → dio.post(...)
```

**حيث ينحرف عن المخطط:**
1. `EldAuthBackend` يتجاوز `ApiClient` ويعيد بناء العنوان والتطبيع (BACK-011) — طبقة ثانية من منطق الشبكة.
2. `LoginUseCase` طقسي — 32 سطراً مقابل 293 سطراً في الـ provider؛ `LogoutUseCase` **يُسقط نتيجة العملية** (AUTH-002).
3. `Password` و`LoginIdentifier` value-objects **فارغة قانونياً** — لا تختبر أي قاعدة؛وتصدر مفاتيح الترجمة مُصدَرة من `domain` (AUTH-003).
4. لا يوجد تدفّق refresh — وهذا **صحيح** لجللسات `JSESSIONID`؛ لكن `refreshTokenKey` (app_constants.dart:28) ميت (CORE-021).

## جدول تفصيلي

جميع الملاحظات المرتبطة بالبيانات والشبكة أدناه مع أدلتها الكاملة، يليها جدول تماثل العقود بين `eld_engine` و`mock`.
tmp

**عدد الملاحظات في هذا القسم: 76**

--------------------------------------------------
### ISSUE COD-001: ذاكرة مؤقتة `static` مشتركة على مستوى العملية في مستودع codriver ⇒ تسريب بيانات بين السائقين
- **Severity:** High
- **Category:** Global mutable state / Session-isolation breach
- **Location:** `lib/features/codriver/data/repositories/codriver_repository_impl.dart:17-18`, `:32`, `:51`, `:55-57`, `:84`, `:119-122`, `:135-138`
- **Evidence:**
```dart
// lib/features/codriver/data/repositories/codriver_repository_impl.dart:17
  static List<CoDriver> _cachedDrivers = [];
  static CurrentCoDriverRead? _cachedCurrentCoDriver;

// :54-58
    } else {
      if (_cachedDrivers.isNotEmpty) {
        return Right(_cachedDrivers);
      }
      return const Left(NetworkFailure());
    }
```
- **Current behavior:** حقلا `static` على مستوى class (أي على مستوى العملية كلها) يُستخدمان كـ cache للأImplicit، **لا يُبطلان عند logout**، ولا يُبقيان أي مرجع بالـ `driverId` المالك. عند فشل الشبكة، `getAvailableDrivers()` يُعيد **قائمة سائقين مساعدينDriveالمaling�� إلى السائق الجديد**.
- **Why problematic:** المشروع كرّر 4 مرات نمط «P0 Stage 1 session ownership» في `AccountNotifier` (`account_provider.dart:36-63`) و`CoDriverNotifier` (`codriver_provider.dart:98-132`) و`VehicleNotifier` و`DashboardNotifier`. كلهم يفرضون `owner + epoch + seq`. **لكن الـ cache يقع تحت السياج** — `_cachedDrivers` في طبقة data، ولا يعرف الـ epoch. ⇒ **تسريب cross-driver مقصود التهرب منه في الطبقات الأعلى**.
- **Violated principle:** Session-scoped data must be fenced by owner; repository must not hold process-global mutable caches.
- **Current owner:** `CoDriverRepositoryImpl` (static).
- **Correct owner:** (أ) اجعل الـ cache **instance** وليس static، (ب) اجعل `clearCache()` يُستدعى من `logout()`، (ج) الأفضل: use-case يمرّر `DriverId` ويخزّن cache keyed by owner.
- **Consequences:** **سائق B يرى أسماء سائقي A كمشترين في مساعدين عند انقطاع الشبكة** — تسريب بيانات شخصية + سلوك HOS خاطئ (تبديل الدور لسائق من جلسة أخرى).
- **Recommended correction:** `Map<int, List<CoDriver>>` keyed by `driverId`، أو instance cache + `invalidate()` في `LogoutUseCase`.
- **Related files:** `lib/features/codriver/presentation/providers/codriver_provider.dart:98-132` (نمط السياج الصحيح، مرجع للمقارنة)
- **Confidence:** CONFIRMED

--------------------------------------------------

--------------------------------------------------

--------------------------------------------------
### ISSUE COD-003: رسائل إنجليزية hardcoded تُستعمل كـ `Failure.message` / `state.error` وتُعرض خاماً
- **Severity:** Medium
- **Category:** Localization bypass + wrong error channel
- **Location:** `lib/features/codriver/data/repositories/codriver_repository_impl.dart:52`, `:81`, `:92`, `:110`, `:130`، `:40`؛ `lib/features/codriver/presentation/providers/codriver_provider.dart:213`, `:215`, `:224`؛ العرض: `lib/features/codriver/presentation/pages/codriver_page.dart:167`
- **Evidence:**
```dart
// lib/features/codriver/data/repositories/codriver_repository_impl.dart:108-112
      if (coDriverId <= 0) {
        return const Left(
          ServerFailure(message: 'Select a co-driver before switching.'),
        );
      }

// lib/features/codriver/presentation/providers/codriver_provider.dart:213-217
    final id = int.tryParse(state.selectedCoDriver?.id ?? '');
    if (id == null || id <= 0) {
      const message = 'Select a co-driver before switching.';
      state = state.copyWith(isSwitching: false, error: message);
      return message;
    }

// lib/features/codriver/presentation/pages/codriver_page.dart:166-168
                           Text(
                             codriverState.error!,
```
- **Current behavior:** خطأ تحقق **محلي** (السائق لم يختر سائقاً) يُعاد كـ`ServerFailure` — أي كخطأ خادم — برسالة إنجليزية. نفس الجملة مكرَّرة في المستودع وفي الـ provider، وتُعرض خاماً في الواجهة.
- **Why problematic:** (أ) misuse قناة `ServerFailure` لتحقق local؛ (ب) **ازدواج** نفس الجملة في موضعين؛ (ج) لا ترجمة — السائق العربي يرى إنجليزية؛ (د) `anyErrorUserMessage` ستعتبره نصاً آمناً لو مرّ عبره (لأنه ServerFailure + `_isSafeUserFacingText`) فيُعرض كما هو.
- **Violated principle:** Domain error codes ≠ user strings; single source of message.
- **Current owner:** مستودع + provider.
- **Correct owner:** رمز خطأ (`'coDriverNotSelected'`) في `Failure.message`، والترجمة في `codriver_page.dart` عبر `context.translateErrorKey(...)` أو getter في extension.
- **Consequences:** رسائل غير مترجمة + التصنيف الخاطئ (client error labelled server error).
- **Recommended correction:** استبدل الجملة برمز، وأضف الحالات إلى `localization_helper.dart`.
- **Related files:** `lib/core/utils/localization_helper.dart:11-33`, `lib/features/codriver/data/repositories/codriver_repository_impl.dart:130` (`'Co-driver shift change'` — payload فعلي للنظام، مقبول)
- **Confidence:** CONFIRMED

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
### ISSUE SEC-002: كاش الجلسة في الذاكرة + مفتاح تخزين موروث من Traccar
- **Severity:** Low / POTENTIAL
- **Category:** Credential handling nuance
- **Location:** `lib/features/auth/data/datasources/auth_local_data_source.dart:37`, `:43`, `:73-74`
- **Evidence:**
```dart
// :37
  static const _sessionKey = 'traccar_auth_session';

// :43
  AuthSession? _sessionCache;

// :73-74
  final cached = _sessionCache;
    if (cached != null) return cached;
```
- **Current behavior:** (أ) `_sessionCache` يحمل كائن `AuthSession` (بما فيه `sessionCredential`) في **حقل Dart عادي** طوال عمر العملية — بلا zeroing عند logout (يُسقَط المرجع فقط عبر `_sessionCache = null` في السطر 94)؛ (ب) مفتاح التخزين `'traccar_auth_session'` موروث من naming legacy بينما الـ backend الحالي ELD Engine.
- **Why problematic:** (أ) المخاطرة: نسخة ثانية من credential في الذاكرة خارج Keystore (مقصودة للأداء — موثّقة بالتعليق 40–42)؛ (ب) الـ naming leak يجعل migration أصعب.
- **Violated principle:** (a) cache not a violation per se — **POTENTIAL** فقط.
- **Current owner:** `AuthLocalDataSourceImpl`.
- **Correct owner:** — (القرار مقصود وموثّق).
- **Recommended correction:** إعادة تسمية المفتاح عند أول تشغيل لـ `eld_auth_session` (مع backward-compat read).
- **Confidence:** POTENTIAL (قرار تصميمي واعٍ، لا مخالفة)

--------------------------------------------------

# C. جدول النصوص الثابتة / تجاوز الترجمة (Hardcoded content & localization bypass)

## C-1. جدول شامل (كل الأسطر في نطاق هذه المجموعة)

| # | File:Line | العيّنة الحرفية | النوع | الحكم |
|---|---|---|---|---|
| 1 | `auth/presentation/widgets/forgot_password_form.dart:42` | `? 'أدخل بريداً صالحاً.'` | عربي/إنجليزي hand-if | **مخالفة ترجمة** (AUTH-004) |
| 2 | `auth/presentation/widgets/forgot_password_form.dart:43` | `: 'Enter a valid email.'` | نفس الحالة | **مخالفة ترجمة** |
| 3 | `auth/presentation/widgets/forgot_password_form.dart:63-64` | `'الاستعادة غير متاحة على هذا الخادم. تواصل مع مدير الأسطول.'` / `'Reset is not available on this server. Contact your fleet manager.'` | نفس الحالة | **مخالفة ترجمة** |
| 4 | `auth/presentation/widgets/forgot_password_form.dart:72-74` | `'إن كان البريد مسجّلاً فستصلك تعليمات إعادة التعيين.'` / `'If the email is registered, reset instructions will be sent.'` | نفس الحالة | **مخالفة ترجمة** |
| 5 | `auth/presentation/widgets/forgot_password_form.dart:94-96` | `'أدخل بريد الحساب. إن لم يصلك شيء فتواصل مع مدير الأسطول.'` / `'Enter the account email...'` | نفس الحالة | **مخالفة ترجمة** |
| 6 | `auth/presentation/widgets/forgot_password_form.dart:111` | `label: _arabic ? 'إرسال' : 'Send',` | نفس الحالة | **مخالفة ترجمة** |
| 7 | `auth/presentation/widgets/forgot_password_form.dart:28` | `bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';` | التفاف l10n يدوي | **نمط معاد** |
| 8 | `auth/presentation/widgets/forgot_password_form.dart:38` | `if (email.isEmpty \|\| !email.contains('@'))` | قاعدة تحقق محلية | تكرار لـ `LoginIdentifier` |
| 9 | `auth/presentation/pages/auth_page.dart:46` / `splash_page.dart:81` | `'assets/images/ic_launcher.png'` | مسار أصل | مقبول |
| 10 | `account/presentation/pages/user_manual_page.dart:129` | `'Golden Feather ELD'` | نص إنجليزي | ي يجب `loc.appName` (CTN-001) |
| 11 | `account/presentation/pages/instructions_page.dart:374` | `'www.topceld.com'` | نص إنجليزي | inconsequential (مقصود) |
| 12 | `account/presentation/pages/account_page.dart:180` | `newValue.toLowerCase() == 'arabic' \|\| newValue == 'العربية'` | mapping لغة | **منطق أعمال في Widget** (ACC-007) |
| 13 | `account/presentation/pages/account_page.dart:181` | `newValue.toLowerCase() == 'spanish' \|\| newValue == 'español'` | نفس الحالة | نفس الحالة |
| 14 | `account/presentation/pages/account_page.dart:41,43,45,46` | `['English','Spanish','Arabic']`، `['mi','km']`، `'English'`, `'mi'` | sentinels | مقبول كـ fallback UI |
| 15 | `account/presentation/pages/account_page.dart:101-103` | `Text(accountState.error!, ...)` | **مفتاح l10n يُعرض خاماً** | **مخالفة confirmed** (ACC-004) |
| 16 | `account/application/models/rules_screen_model.dart:65-66` | `if (t == 'allowed' \|\| t == 'true') return true;` | تفسير wire | تكرار مع rules_page (ACC-005) |
| 17 | `account/presentation/pages/rules_page.dart:58-59` | `'sixteenHourException'` | مفتاح حقل | **magic string** |
| 18 | `account/presentation/pages/rules_page.dart:123-136`, `:172-185` | `case 'cycleRule': case 'cargoType': case 'restart': case 'restBreak':` ×2 | **تكرار switch مطابق** | smell |
| 19 | `account/presentation/pages/rules_page.dart:378-391` | `'personalConveyance', 'personalConveyanceEnabled', 'yardMoves', 'yardMoveEnabled'` | magic strings | مكرر في النموذج |
| 20 | `account/presentation/providers/rules_screen_provider.dart:13` | `throw Exception('User not authenticated')` | استثناء غير typed | **سلوك خاطئ مؤكد** (ACC-003) |
| 21 | `codriver/domain/entities/codriver.dart:9` | `static const CoDriver none = CoDriver(id: 'none', name: 'No One');` | نص domain يُعرض | §C |
| 22 | `codriver/data/repositories/codriver_repository_impl.dart:40` | `name: json['name'] ?? 'Unknown'` | fallback | §C |
| 23 | `codriver/data/repositories/codriver_repository_impl.dart:52,92` | `'Unexpected error occurred'` | `ServerFailure.message` | **يُعرض خاماً** (COD-003) |
| 24 | `codriver/data/repositories/codriver_repository_impl.dart:110` | `ServerFailure(message: 'Select a co-driver before switching.')` | misuse قناة + إنجليزي | **مخالفة** (COD-003) |
| 25 | `codriver/data/repositories/codriver_repository_impl.dart:130` | `reason: reason ?? 'Co-driver shift change'` | payload للنظام | **مقبول** |
| 26 | `codriver/data/repositories/codriver_repository_impl.dart:81` | `'co_driver_response_unreadable'` | error code | **صحيح** (نمط) |
| 27 | `codriver/presentation/providers/codriver_provider.dart:215` | `const message = 'Select a co-driver before switching.'` | تكرار مع #24 | **مخالفة** (COD-003) |
| 28 | `codriver/presentation/providers/codriver_provider.dart:224` | `if (!mounted) return 'Switch was interrupted.';` | نص إنجليزي | §C |
| 29 | `codriver/presentation/pages/codriver_page.dart:167` | `codriverState.error!` | عرض خام | **مخالفة** (COD-003) |
| 30 | `codriver/presentation/pages/codriver_page.dart:304` | `context.go('/home');` | **route literal** | **مخالفة** (COD-004) |
| 31 | `codriver/presentation/pages/codriver_page.dart:213` | `name: next.currentCoDriver!.name ?? 'Unknown'` | fallback | §C |
| 32 | `connection/presentation/pages/eld_connection_page.dart:433` | `hint: 'AA:BB:CC:DD:EE:FF'` | placeholder MAC | مقصود |
| 33 | `connection/presentation/pages/eld_connection_page.dart:436-439` | `maxLength: 17` + `FilteringTextInputFormatter.allow(RegExp(r'[0-9a-fA-F:]'))` | تضييق قاعدة | **غير متسق** (CON-006) |
| 34 | `connection/presentation/pages/eld_connection_page.dart:366` | `dashboard.vehicleDisplayName != 'No Vehicle'` | magic sentinel | (HOM-004) |
| 35 | `connection/presentation/widgets/diagnostics/event_card.dart:25` | `'MALFUNCTION'` / `'DATA_DIAGNOSTIC'` | تصنيف | يقابل المنطق في الصفحة (CON-007) |
| 36 | `connection/presentation/widgets/diagnostics/event_card.dart:55` | `Text('DETECTED', ...)` | **نص UI غير مترجم** | §C |
| 37 | `connection/presentation/widgets/diagnostics/stat_row.dart:24-27` | `'ACTIVE DIAG'`, `'ACTIVE MALF'`, `'TOTAL DIAG'`, `'TOTAL MALF'` | **نصوص UI غير مترجمة** | §C (بينها `'active'` مترجم في 23) |
| 38 | `home/presentation/providers/dashboard_provider.dart:65-68` | `driverName: 'Unknown'`, `vehicleId: 'No Vehicle'`, `vehicleDisplayName: 'Select a vehicle'` | sentinels | يُقارَن بها في 3 ملفات (HOM-004) |
| 39 | `home/presentation/providers/dashboard_provider.dart:112,114,119,213` | `'No Vehicle'`, `'Select a vehicle'`, `'Unknown'` | sentinels مكرَّرة | تكرار |
| 40 | `home/presentation/pages/home_page.dart:59,366` | `!= 'Unknown'`, `!= 'No Vehicle'` | مقارنة sentinel | هشّة (HOM-004) |
| 41 | `home/presentation/widgets/eld_drawer.dart:104` | `snapshot.data?.version ?? '1.0.0'` | fallback version | inconsequential |
| 42 | `settings/presentation/pages/settings_page.dart:119` | `code == 'ar' ? 'Arabic' : (code == 'es' ? 'Spanish' : 'English')` | mapping لغة | **منطق في Widget** (SET-001) |
| 43 | `settings/presentation/pages/settings_page.dart:181` | `hint: 'https://snsoft.cloud'` | نص إنجليزي | inconsequential |
| 44 | `permissions/presentation/pages/permissions_page.dart:61-64` | `'صلاحية الموقع مطلوبة'` + نص قانوني FMCSA | **عربي hardcoded** | **مخالفة ترجمة** (PERM-001) |
| 45 | `permissions/.../permissions_page.dart:77-80` | `'صلاحية البلوتوث'` + `'ساعات القيادة يدوياً'` | نفس الحالة | نفس الحالة |
| 46 | `permissions/.../permissions_page.dart:141` | `Text(isRequired ? 'منح الصلاحية' : 'موافق')` | نفس الحالة | نفس الحالة |
| 47 | `permissions/.../permissions_page.dart:179,185` | `'صلاحيات التطبيق'`, `'يحتاج تطبيق ELD للصلاحيات التالية\nللعمل بشكل قانوني'` | نفس الحالة | نفس الحالة |
| 48 | `permissions/.../permissions_page.dart:194-235` | `'الموقع الجغرافي'`,`'البلوتوث'`,`'الإشعارات'`,`'توفير البطارية'`,`'الكاميرا'` + 5 subtitles | نفس الحالة | نفس الحالة |
| 49 | `permissions/.../permissions_page.dart:249-250` | `'متابعة'` / `'منح الصلاحيات'` | نفس الحالة | نفس الحالة |
| 50 | `permissions/.../permissions_page.dart:286` | `label: 'مطلوب'` | نفس الحالة | نفس الحالة |
| 51 | `about/presentation/pages/about_page.dart:156` | `'• ${a.message}'` | عرض خام لخادم | نص الخادم (مقبول عمداً) |
| 52 | `connection/presentation/pages/eld_connection_page.dart:82,131` | `errorMessage: 'bluetooth_failed'` / `'connect_failed'` | **marker** موثّق | ✓ نمط صحيح (مشروعي) |
| 53 | `connection/presentation/pages/eld_connection_page.dart:182` | `infoMessage: 'disconnected_accepted'` | marker | ✓ |
| 54 | `auth/domain/entities/value_objects/password.dart:17` | `return 'passwordRequired';` | **مفتاح l10n من domain** | **مخالفة** (AUTH-003) |
| 55 | `auth/domain/entities/value_objects/login_identifier.dart:31,34,37` | `'emailRequired'`, `'invalidEmailFormat'`, `'invalidValue'` | **مفاتيح l10n من domain** | **مخالفة** (AUTH-003) |

**إجمالي أسطر النصوص الثابتة داخل النطاق: 55 موضعاً**، منها:
- **تجاوز ترجمة مؤكد (نصوص معروضة للمستخدم غير مترجمة):** 17 موضعاً (`forgot_password_form` ×6، `permissions_page` ×13، `stat_row` ×4، `event_card` ×1، `codriver_provider` ×2).
- **تسريب مفاتيح l10n من domain:** 4 أسطر في ملفين (`AUTH-003`).
- **عرض خام لمفتاح l10n للمستخدم:** 1 موضع مؤكد (`account_page.dart:102` — **ACC-004**).
- **magic strings / sentinels للمقارنة:** 12 موضعاً.
- **مقبول أو مقصود:** الباقي.

## C-2. الصفحات التي يفترض أنها «غير مترجمة» — فحص دقيق

| الملف | عدد الأسطر | `context.loc` / `loc.` | الحروف الخشنة | الحكم النهائي |
|---|---|---|---|---|
| `instructions_page.dart` | 502 | **~45 استدعاء** | 1 (`'www.topceld.com'`) | **مترجم ✓** |
| `user_manual_page.dart` | 559 | **~40 استدعاء** | 1 (`'Golden Feather ELD'`) | **مترجم ✓** |
| `rules_page.dart` | 502 | **~28 استدعاء** | 0 | **مترجم ✓** |
| `forgot_password_form.dart` | 133 | 4 فقط | **6** | **غير مترجم ✗** |
| `permissions_page.dart` | 301 | 2 فقط | **~15** | **غير مترجم ✗** |
| `stat_row.dart` / `event_card.dart` | 58 / 72 | 1 / 2 | 4 / 2 | **جزئي ✗** |

> **خلاصة:** الفرضية التي طُرحت على صفحات `account` **مرفوضة**. المخالفة الحقيقية في الترجمة تقع في **`forgot_password_form.dart`** و**`permissions_page.dart`** وwidgets التشخيص، لا في صفحات الدليل.

---

# D. جدول الاستيرادات العابرة للميزات (Cross-feature import table)

> الاستخراج آلي: كل `import '...'` نسبي في ملفات النطاق، مُحلَّل إلى مسار مطلق، ومُصنَّف حسب الميزة. **47 حافة** مُستخرجة.

## D.1. `ACCOUNT` (6 حواف)

| From:Line | To | المسار المطلق | نوع الاعتماد | الحكم |
|---|---|---|---|---|
| `account/presentation/pages/account_page.dart:7` | HOME | `lib/features/home/presentation/providers/dashboard_provider.dart` | **presentation implementation** | **مخالفة confirmed** (ACC-007, HOM-001) |
| `account/presentation/pages/account_page.dart:8` | HOME | `lib/features/home/presentation/widgets/eld_drawer.dart` | **presentation widget** | **مخالفة confirmed** (ACC-008) |
| `account/presentation/pages/info_packet_page.dart:6` | HOME | `lib/features/home/presentation/widgets/eld_drawer.dart` | presentation widget | **مخالفة** (ACC-008) |
| `account/presentation/pages/info_packet_page.dart:7` | INSPECTION | `lib/features/inspection/domain/inspection_transfer.dart` | **domain** (عقد/كيان) | مقبول ✓ |
| `account/presentation/pages/info_packet_page.dart:8` | INSPECTION | `lib/features/inspection/presentation/providers/inspection_provider.dart` | **presentation implementation** | **مخالفة confirmed** (ACC-006) |
| `account/presentation/pages/rules_page.dart:10` | HOME | `lib/features/home/presentation/widgets/eld_drawer.dart` | presentation widget | **مخالفة** (ACC-008) |
| `account/application/usecases/update_rules_use_case.dart:9` | AUTH | `lib/features/auth/presentation/providers/auth_state_provider.dart` | **presentation** | **مخالفة عالية confirmed** (ACC-001) |
| `account/presentation/providers/account_provider.dart:5` | AUTH | `lib/features/auth/presentation/providers/auth_state_provider.dart` | presentation | **مقبول عملياً** — قارئ هوية (common) |
| `account/presentation/providers/rules_screen_provider.dart:5` | AUTH | same | presentation | **مقبول** (قراءة هوية فقط) |
| `account/presentation/pages/rules_page.dart:13` | BACKEND | `lib/backend/adapters/eld_engine/models/rules_screen_dto.dart` | **data adapter** | **مخالفة عالية confirmed** (ACC-002) |

## D.2. `CODRIVER` (8 حواف)

| From:Line | To | المسار | نوع | الحكم |
|---|---|---|---|---|
| `codriver/presentation/pages/codriver_page.dart:9` | HOME | `.../home/presentation/widgets/eld_drawer.dart` | presentation widget | **مخالفة** (ACC-008) |
| `codriver/presentation/pages/codriver_page.dart:14` | AUTH | `.../auth_state_provider.dart` | presentation | **مقبول** (قراءة `currentDriverIdProvider`) |
| `codriver/presentation/pages/codriver_page.dart:15` | HOS | `lib/features/hos/domain/engine/hos_rules_engine.dart` | **domain implementation** (`HosEngineReady`) | **مخالفة confirmed** (COD-002) |
| `codriver/presentation/pages/codriver_page.dart:16` | HOS | `.../hos/presentation/providers/hos_engine_provider.dart` | **presentation** | **مخالفة confirmed** (COD-002) |
| `codriver/presentation/pages/codriver_page.dart:17` | HOS | `.../hos/presentation/providers/hos_provider.dart` | **presentation** | **مخالفة confirmed** (COD-002) |
| `codriver/presentation/pages/codriver_page.dart:18` | TRACKING | `.../tracking/presentation/providers/tracking_provider.dart` | **presentation** | **مخالفة confirmed** (COD-002) |
| `codriver/presentation/pages/codriver_page.dart:23` | HOS | `.../hos/presentation/providers/status_dashboard_providers.dart` | **presentation** | **مخالفة** (إبطال cache فقط) |
| `codriver/presentation/providers/codriver_provider.dart:3` | AUTH | `auth_state_provider.dart` | presentation | **مقبول** (نمط session ownership) |
| `codriver/presentation/providers/team_status_provider.dart:5` | AUTH | `auth_state_provider.dart` | presentation | **مقبول** |
| `codriver/data/repositories/codriver_repository_impl.dart:10` | SHARED | `lib/domain/shared/value_objects.dart` | **domain kernel** | ✓ سليم |

## D.3. `CONNECTION` (5 حواف)

| From:Line | To | المسار | نوع | الحكم |
|---|---|---|---|---|
| `connection/presentation/pages/eld_connection_page.dart:11` | HOME | `.../home/presentation/providers/dashboard_provider.dart` | **presentation implementation** | **مخالفة** (CON-001, HOM-001) |
| `connection/presentation/pages/eld_connection_page.dart:12` | VEHICLE | `lib/features/vehicle/domain/entities/vehicle.dart` | **domain entity** | ✓ سليم |
| `connection/presentation/pages/eld_connection_page.dart:13` | VEHICLE | `.../vehicle/presentation/providers/vehicle_provider.dart` | **presentation implementation** | **مخالفة** — feature يستهلك provider feature أخرى (نفس النمط في `hardware_status_provider.dart:3`) |
| `connection/presentation/pages/eld_connection_page.dart:23` | TRACKING | `lib/features/tracking/data/providers/tracking_providers.dart` | **data providers** | **مخالفة** (CON-001) |
| `connection/presentation/pages/eld_connection_page.dart:24` | TRACKING | `.../tracking/presentation/providers/tracking_provider.dart` | **presentation** | **مخالفة** (CON-001) |

## D.4. `HOME` (11 حواف)

| From:Line | To | المسار | نوع | الحكم |
|---|---|---|---|---|
| `home/presentation/pages/home_page.dart:8` | HOS | `.../hos/presentation/pages/recap_page.dart` | **presentation page** | **مخالفة** (HOM-002) |
| `home/presentation/pages/home_page.dart:9` | HOS | `.../hos/presentation/widgets/driving_lock_screen.dart` | **presentation widget (قفل قيادة)** | **مخالفة عالية — امتثال** (HOM-002) |
| `home/presentation/pages/home_page.dart:10` | SYNC | `.../sync/presentation/widgets/sync_status_indicator.dart` | presentation widget | **مخالفة** (ACC-008 — shell owned by feature) |
| `home/presentation/pages/home_page.dart:16` | TRACKING | `.../tracking/presentation/providers/tracking_providers.dart` | presentation | **مخالفة** |
| `home/presentation/pages/home_page.dart:18` | HOS | `.../hos/presentation/pages/status_dashboard_page.dart` | **presentation page** | **مخالفة** (HOM-002) |
| `home/presentation/pages/home_page.dart:19` | HOS | `.../hos/presentation/providers/status_dashboard_providers.dart` | presentation | **مخالفة** |
| `home/presentation/pages/home_page.dart:20` | HOS | `.../hos/presentation/providers/hos_engine_provider.dart` | presentation | **مخالفة** |
| `home/presentation/pages/home_page.dart:21` | AUTH | `auth_state_provider.dart` | presentation | **مقبول** (session gate) |
| `home/presentation/providers/dashboard_provider.dart:2` | LOGS | `lib/features/logs/domain/daily_form_rules.dart` | **domain** | **مخالفة confirmed** (HOM-001) |
| `home/presentation/providers/dashboard_provider.dart:3` | LOGS | `lib/features/logs/domain/entities/daily_form_data.dart` | **domain** | **مخالفة** (HOM-001) |
| `home/presentation/providers/dashboard_provider.dart:4,5,6,7,8` | AUTH/VEHICLE/CODRIVER | providers + entities | **presentation + domain** | **مخالعة confirmed** (HOM-001) |
| `home/presentation/providers/home_provider.dart:3` | APP | `lib/routes.dart` | **app layer** | **مخالفة — دورة** (HOM-003) |
| `home/presentation/widgets/eld_drawer.dart:8` | APP | `lib/routes.dart` | app layer | **مخالفة — دورة** (HOM-003) |
| `home/presentation/widgets/eld_drawer.dart:10` | AUTH | `auth_state_provider.dart` + `notifier.logout()` | **presentation + mutation** | **مخالفة** (HOM-005) |

## D.5. `SETTINGS` / `ABOUT`

| From:Line | To | المسار | نوع | الحكم |
|---|---|---|---|---|
| `settings/presentation/pages/settings_page.dart:12` | HOME | `.../home/presentation/widgets/eld_drawer.dart` | presentation widget | **مخالفة** (ACC-008) |
| `settings/presentation/pages/settings_page.dart:14` | ACCOUNT | `.../account/presentation/providers/account_provider.dart` | **presentation write** | **مخالفة confirmed** (SET-001) |
| `about/presentation/pages/about_page.dart:15` | TRACKING | `.../tracking/presentation/providers/tracking_providers.dart` | presentation | مقبول نسبياً |
| `about/presentation/pages/about_page.dart:16` | CONNECTION | `.../connection/presentation/pages/diagnostics_page.dart` | **presentation page** | **مخالفة** (ACC-008) |
| `about/presentation/pages/about_page.dart:17` | CONNECTION | `.../connection/presentation/providers/hardware_alerts_provider.dart` | **presentation** | **مخالفة** |
| `about/presentation/pages/about_page.dart:18` | CONNECTION | `.../connection/presentation/providers/hardware_status_provider.dart` | **presentation** | **مخالفة** |
| `about/presentation/pages/about_page.dart:19` | CONNECTION | `.../connection/presentation/widgets/eld_diagnostics_section.dart` | **presentation barrel (4 widgets)** | **مخالفة** (ACC-008) |

## D.6. الحواف المطلوبة في التفويض — قرار صريح لكل واحدة

| الحافة المطلوبة | **الموقع** | **تنفيذ آخر feature؟** | **الحكم الصريح** |
|---|---|---|---|
| `ACCOUNT -> HOME` | `account_page.dart:7,8`، `info_packet_page.dart:6`، `rules_page.dart:10` | **نعم** — provider + widget | **مخالفة confirmed.** `EldDrawer` app-shell في feature، و`dashboardDataProvider` تجميع shared في feature |
| `ACCOUNT -> INSPECTION` | `info_packet_page.dart:7` (domain) + `:8` (presentation) | **جزئياً** — السطر 7 عقد domain ✓، السطر 8 تنفيذ presentation ✗ | **مخالفة confirmed** (السطر 8 فقط) |
| `ACCOUNT -> AUTH` | `account_provider.dart:5`, `rules_screen_provider.dart:5` (قراءة هوية) | تنفيذ presentation، لكن **قراءة فقط** | **مقبول عملياً** — نمط session-ownership شائع ومقصود. **لكن** `update_rules_use_case.dart:9` (**كتابة/بناء**) ⇒ **مخالفة confirmed** (ACC-001) |
| `ACCOUNT -> BACK` | — | — | **لا توجد feature اسمها `back`.** أقرب تفسير: `instructions_page.dart:34,454` و`user_manual_page.dart:23` تستدعي `Navigator.pop(context)` مباشرة بدل `context.pop()` — تجاوز بسيط (§E)، **لا مخالفة معمارية**. |
| `HOME -> HOS` | `home_page.dart:8,9,18,19,20` | **نعم** — صفحات + widgets + providers | **مخالفة confirmed** (HOM-002) — HOME هو الـ shell لكن بالاختراق لا بالتصميم |
| `HOME -> AUTH` | `home_page.dart:21`, `dashboard_provider.dart:4`, `eld_drawer.dart:10` | presentation | **مقبول** — session gate + logout natural |
| `HOME -> LOGS` | `dashboard_provider.dart:2,3` | **نعم** — domain لـ feature أخرى | **مخالفة confirmed** (HOM-001) — shared state live في feature |
| `HOME -> SYNC` | `home_page.dart:10` | widget | **مخالفة** (نمط shell، ACC-008) |
| `CODRIVER -> HOS` | `codriver_page.dart:15,16,17,23` | **نعم** — domain impl + 3 providers | **مخالفة confirmed** (COD-002) |
| `CODRIVER -> TRACKING` | `codriver_page.dart:18` | **نعم** — presentation | **مخالفة confirmed** (COD-002) |
| `CONNECTION -> VEHICLE` | `eld_connection_page.dart:12` (domain ✓) + `:13` (presentation ✗)، `hardware_status_provider.dart:3` (presentation ✗) | مختلط | **مخالحة confirmed** لجزء presentation؛ جزء domain سليم |
| `CONNECTION -> HOME` | `eld_connection_page.dart:11` | **نعم** — presentation provider | **مخالفة confirmed** (HOM-001) |
| `SETTINGS -> ACCOUNT` | `settings_page.dart:14` | **نعم** — presentation + كتابة | **مخالفة confirmed** (SET-001) |
| `SETTINGS -> HOME` | `settings_page.dart:12` | widget | **مخالفة** (ACC-008) |

**حصيلة:** من أصل 15 حافة مطلوبة: **7 مخالفات مؤكدة**، **2 مقبولة** (قراءة AUTH)، **1 غير موجودة** (BACK)، والباقي مخالفات **بنية/تسمية** لا تسمك بالتطبيق.

---

# E. جدول تجاوز التوجيه (Navigator-bypass table)

> الاستخراج: `Navigator.push` / `Navigator.of(...).push` / `Navigator.pushNamed` / `context.go|push|goNamed|pushNamed` داخل **نطاق هذه المجموعة فقط**.

## E.1. `Navigator.push` (إنشاء شاشات جديدة — تجاوز حقيقي لـ GoRouter)

| File:Line | الكود | veins إلى | هل يوجد مسار GoRouter؟ | الحكم |
|---|---|---|---|---|
| `account/presentation/pages/info_packet_page.dart:45-48` | `Navigator.push(context, MaterialPageRoute(builder: (_) => const UserManualPage()));` | `UserManualPage` | **نعم** — `AppRoutes.userManual='/user-manual'` (`routes/account_routes.dart:30-34`) | **تجاوز مؤكد** (ROU-001) |
| `account/presentation/pages/info_packet_page.dart:57-60` | `Navigator.push(context, MaterialPageRoute(builder: (_) => const InstructionsPage()));` | `InstructionsPage` | **لا** | تجاوز بلا بديل — **مقبول** (ينقص مسار) |
| `account/presentation/pages/instructions_page.dart:77-82` | `Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => ZoomableSectionPage(...)))` | `ZoomableSectionPage` | **لا** (widget فرعي) | **مقبول ✓** |
| `about/presentation/pages/about_page.dart:267-273` | `Navigator.push(context, MaterialPageRoute(builder: (_) => const DiagnosticsPage()))` | `DiagnosticsPage` | **لا** | تجاوز بلا بديل — **مقبول**، لكن `DiagnosticsPage` صفحة feature كاملة تستحق مساراً |

**المجموع: 4 استدعاءات `Navigator.push`**، منها **1 تجاوز مؤكد** (ROU-001)، **1 نقص مسار**، **2 مقبولة**.

## E-2. `context.go / push` — استخدام صحيح لـ GoRouter

| File:Line | الكود | الحكم |
|---|---|---|
| `connection/presentation/pages/eld_connection_page.dart:344` | `context.go(AppRoutes.home);` | ✓ صحيح (ثابت) |
| `connection/presentation/pages/eld_connection_page.dart:361` | `context.push(AppRoutes.selectVehicle);` | ✓ صحيح |
| `home/presentation/pages/home_page.dart:160` | `onPressed: () => context.push(AppRoutes.connection),` | ✓ صحيح |
| `home/presentation/widgets/eld_drawer.dart:66` | `context.go(item.route);` | ✓ صحيح |
| `home/presentation/widgets/eld_drawer.dart:68` | `context.push(item.route);` | ✓ صحيح |
| `home/presentation/widgets/eld_drawer.dart:87` | `context.push(AppRoutes.settings);` | ✓ صحيح |
| **`codriver/presentation/pages/codriver_page.dart:304`** | **`context.go('/home');`** | **✗ route literal خام — مخالفة** (COD-004) |
| `auth/presentation/pages/splash_page.dart:36` | `context.goNamed('onboarding');` | ✓ صحيح |
| `auth/presentation/pages/splash_page.dart:53` | `context.goNamed('permissions');` | ✓ صحيح |
| `auth/presentation/pages/splash_page.dart:67` | `context.goNamed(isLoggedIn ? 'connection' : 'login');` | ✓ صحيح (dynamically named) |
| `onboarding/presentation/pages/onboarding_page.dart:49` | `context.goNamed('splash');` | ✓ صحيح |
| `permissions/presentation/pages/permissions_page.dart:150` | `context.goNamed('login');` | ✓ صحيح |

**المجموع: 12 استدعاء `context.*`** — **11 صحيح، 1 مخالفة**.

## E-3. `Navigator.pop` (لا счита تجاوزاً — لكن موثّق للاكتمال)

| الملف | الأسطر | العدد |
|---|---|---|
| `account/presentation/pages/user_manual_page.dart` | 23 | 1 |
| `account/presentation/pages/instructions_page.dart` | 34, 454 | 2 |
| `codriver/presentation/pages/codriver_page.dart` | 62, 234, 243, 291, 382, 402 | 6 |
| `connection/presentation/widgets/dialogs/manual_mode_reason_dialog.dart` | 47, 51 | 2 |
| `home/presentation/pages/home_page.dart` | 143 | 1 |
| `home/presentation/widgets/eld_drawer.dart` | 61, 84, 129, 135, 136 | 5 |
| `permissions/presentation/pages/permissions_page.dart` | 126, 133 | 2 |

**المجموع: 19 `Navigator.pop`** — كلها مقبولة (pop لا ينشئ مساراً).

## E-4. ملاحظة على `RouterNotifier` (نمط سليم — CONFIRMED CLEAN)

```dart
// lib/routes.dart:55-61
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
```
هذا **هو النمط الصحيح** لفصل Riverpod عن GoRouter: `ChangeNotifier` بلا أي اعتماد على Flutter widgets، يُمرَّر كـ `refreshListenable`، و`redirect` يقرأ بـ `ref.read` (وهو الصحيح داخل redirect لتجنب إعادة البناء). **لا مخافة معمارية هنا.** الملاحظة الوحيدة في ROU-003 (نقص الاستماع لـ `transitioning`).

## E-5. ملاحظة: `AuthPage` لا يتنقّل إطلاقاً ✓

```dart
// lib/features/auth/presentation/widgets/login_form.dart:43
    // Navigation is handled automatically by the router listening to auth state
```
✔ **قرار تصميمي ممتاز**: نموذج الدخول لا يعرف شيئاً عن التنقل؛ `routes.dart:88` (`if (isLoggedIn && isLoginRoute) return AppRoutes.connection;`) يتولى. **نموذج يُحتذى.**

---

# F. قائمة شاملة بالملفات المقروءة (إثبات التغطية)

> **72 ملفاً في النطاق + 6 ملفات توجيه داعمة = 78 ملفاً، كلها مقروءة بالكامل.**
> الملفات المولّدة (`*.g.dart`, `*.freezed.dart`) مستثناة من القراءة كأولوية، لكن **تم توثيق** `part` directives و`@freezed` في كل موضع.

## F.1. `lib/features/auth/**` — 19/19 ✓

| # | Path | أسطر | غير فارغ | Issue IDs |
|---|---|---|---|---|
| 1 | `lib/features/auth/data/datasources/auth_local_data_source.dart` | 137 | 117 | SEC-002 |
| 2 | `lib/features/auth/data/models/auth_session_dto.dart` | 65 | 58 | — |
| 3 | `lib/features/auth/data/repositories/auth_repository_impl.dart` | 195 | 175 | — |
| 4 | `lib/features/auth/domain/entities/auth_session.dart` | 53 | 44 | — |
| 5 | `lib/features/auth/domain/entities/value_objects/email_regex.dart` | 8 | 8 | — |
| 6 | `lib/features/auth/domain/entities/value_objects/login_identifier.dart` | 41 | 36 | AUTH-003 |
| 7 | `lib/features/auth/domain/entities/value_objects/password.dart` | 21 | 18 | AUTH-003 |
| 8 | `lib/features/auth/domain/repositories/auth_repository.dart` | 20 | 16 | — |
| 9 | `lib/features/auth/domain/usecases/check_auth_status_usecase.dart` | 15 | 12 | AUTH-002 |
| 10 | `lib/features/auth/domain/usecases/login_usecase.dart` | 37 | 32 | AUTH-002, AUTH-007 |
| 11 | `lib/features/auth/domain/usecases/logout_usecase.dart` | 12 | 9 | AUTH-002 |
| 12 | `lib/features/auth/presentation/pages/auth_page.dart` | 160 | 150 | — |
| 13 | `lib/features/auth/presentation/pages/splash_page.dart` | 97 | 86 | **AUTH-005** |
| 14 | `lib/features/auth/presentation/providers/auth_mode_provider.dart` | 14 | 12 | — |
| 15 | `lib/features/auth/presentation/providers/auth_providers.dart` | 3 | 2 | AUTH-006 |
| 16 | `lib/features/auth/presentation/providers/auth_state_provider.dart` | 330 | 292 | **AUTH-001** |
| 17 | `lib/features/auth/presentation/providers/login_form_provider.dart` | 33 | 26 | — |
| 18 | `lib/features/auth/presentation/widgets/forgot_password_form.dart` | 133 | 125 | **AUTH-004** |
| 19 | `lib/features/auth/presentation/widgets/login_form.dart` | 134 | 121 | AUTH-007 |

## F.2. `lib/features/account/**` — 9/9 ✓

| # | Path | أسطر | غير فارغ | Issue IDs |
|---|---|---|---|---|
| 1 | `lib/features/account/application/models/rules_screen_model.dart` | 70 | 59 | ACC-005 |
| 2 | `lib/features/account/application/usecases/update_rules_use_case.dart` | 62 | 51 | **ACC-001** |
| 3 | `lib/features/account/presentation/pages/account_page.dart` | 352 | 336 | **ACC-004**, ACC-007, ACC-008 |
| 4 | `lib/features/account/presentation/pages/info_packet_page.dart` | 150 | 139 | **ACC-006**, **ROU-001** |
| 5 | `lib/features/account/presentation/pages/instructions_page.dart` | 502 | 475 | ROU-002 |
| 6 | `lib/features/account/presentation/pages/rules_page.dart` | 502 | 476 | **ACC-002**, ACC-005, ACC-008 |
| 7 | `lib/features/account/presentation/pages/user_manual_page.dart` | 559 | 538 | CTN-001 |
| 8 | `lib/features/account/presentation/providers/account_provider.dart` | 157 | 136 | **ACC-004** |
| 9 | `lib/features/account/presentation/providers/rules_screen_provider.dart` | 25 | 21 | **ACC-003** |

> **ملاحظة تحقق:** `about_page.dart` يقع تحت `lib/features/about/` وليس `account/` ✓ (تم التحقق).

## F.3. `lib/features/codriver/**` — 10/10 ✓

| # | Path | أسطر | غير فارغ | Issue IDs |
|---|---|---|---|---|
| 1 | `lib/features/codriver/data/providers/codriver_repository_providers.dart` | 20 | 16 | — |
| 2 | `lib/features/codriver/data/repositories/codriver_repository_impl.dart` | 144 | 136 | **COD-001**, **COD-003** |
| 3 | `lib/features/codriver/domain/current_codriver.dart` | 51 | 46 | COD-006 |
| 4 | `lib/features/codriver/domain/role_switch_guard.dart` | 40 | 38 | COD-002 |
| 5 | `lib/features/codriver/domain/team_status.dart` | 56 | 51 | COD-006 |
| 6 | `lib/features/codriver/domain/entities/codriver.dart` | 10 | 8 | — |
| 7 | `lib/features/codriver/domain/repositories/codriver_repository.dart` | 15 | 12 | — |
| 8 | `lib/features/codriver/presentation/pages/codriver_page.dart` | 541 | 521 | **COD-002**, COD-003, **COD-004**, ACC-008 |
| 9 | `lib/features/codriver/presentation/providers/codriver_provider.dart` | 238 | 219 | COD-001, **COD-003** |
| 10 | `lib/features/codriver/presentation/providers/team_status_provider.dart` | 41 | 37 | COD-005, COD-006 |

## F.4. `lib/features/connection/**` — 16/16 ✓

| # | Path | أسطر | غير فارغ | Issue IDs |
|---|---|---|---|---|
| 1 | `lib/features/connection/domain/connectivity_status.dart` | 151 | 136 | **CON-005**, CON-006 |
| 2 | `lib/features/connection/domain/hardware_readiness.dart` | 75 | 67 | **CON-005** |
| 3 | `lib/features/connection/domain/entities/hardware_alert.dart` | 15 | 14 | (نموذج نقي مرجعي) |
| 4 | `lib/features/connection/presentation/mac_address_validation.dart` | 13 | 12 | **CON-006** (منخفض) |
| 5 | `lib/features/connection/presentation/pages/diagnostics_page.dart` | 101 | 92 | CON-007 |
| 6 | `lib/features/connection/presentation/pages/eld_connection_page.dart` | 529 | 492 | **CON-001**, **CON-002**, CON-008 |
| 7 | `lib/features/connection/presentation/providers/hardware_alerts_provider.dart` | 83 | 74 | **CON-003** |
| 8 | `lib/features/connection/presentation/providers/hardware_status_provider.dart` | 42 | 39 | CON-003 (نمط) |
| 9 | `lib/features/connection/presentation/widgets/eld_connectivity_panel.dart` | 78 | 74 | — |
| 10 | `lib/features/connection/presentation/widgets/eld_diagnostics_section.dart` | 13 | 12 | — |
| 11 | `lib/features/connection/presentation/widgets/eld_readiness_panel.dart` | 117 | 113 | — |
| 12 | `lib/features/connection/presentation/widgets/manual_recording_section.dart` | 131 | 124 | **CON-004** |
| 13 | `lib/features/connection/presentation/widgets/diagnostics/active_malfunction_actions.dart` | 41 | 37 | — |
| 14 | `lib/features/connection/presentation/widgets/diagnostics/event_card.dart` | 72 | 65 | §C |
| 15 | `lib/features/connection/presentation/widgets/diagnostics/stat_row.dart` | 58 | 51 | §C |
| 16 | `lib/features/connection/presentation/widgets/dialogs/manual_mode_reason_dialog.dart` | 57 | 51 | — |

## F.5. `lib/features/home/**` — 5/5 ✓

| # | Path | أسطر | غير فارغ | Issue IDs |
|---|---|---|---|---|
| 1 | `lib/features/home/presentation/pages/home_page.dart` | 219 | 206 | **HOM-002**, HOM-003, HOM-004 |
| 2 | `lib/features/home/presentation/providers/dashboard_provider.dart` | 224 | 202 | **HOM-001**, HOM-004 |
| 3 | `lib/features/home/presentation/providers/home_provider.dart` | 66 | 63 | HOM-003 |
| 4 | `lib/features/home/presentation/widgets/eld_bottom_nav.dart` | 100 | 92 | — |
| 5 | `lib/features/home/presentation/widgets/eld_drawer.dart` | 149 | 146 | **HOM-003**, **HOM-005**, ACC-008 |

## F.6. ميزات متنوعة — 4/4 ✓

| # | Path | أسطر | غير فارغ | Issue IDs |
|---|---|---|---|---|
| 1 | `lib/features/onboarding/presentation/pages/onboarding_page.dart` | 183 | 170 | — |
| 2 | `lib/features/permissions/presentation/pages/permissions_page.dart` | 301 | 276 | **PERM-001** |
| 3 | `lib/features/settings/presentation/pages/settings_page.dart` | 214 | 202 | **SET-001**, ACC-008 |
| 4 | `lib/features/about/presentation/pages/about_page.dart` | 330 | 314 | ACC-008, §E-1 |

## F.7. `lib/domain/**` — 9/9 ✓ (بلا `*.freezed.dart` / `*.g.dart`)

| # | Path | أسطر | غير فارغ | `part` directives | Issue IDs |
|---|---|---|---|---|---|
| 1 | `lib/domain/account/driver_account.dart` | 36 | 31 | `.freezed.dart` + **`.g.dart`** | **DOM-003** |
| 2 | `lib/domain/config/server_config.dart` | 85 | 71 | `.freezed.dart` فقط | DOM-004 |
| 3 | `lib/domain/duty_status/duty_status_code.dart` | 99 | 84 | **لا شيء (enum خام)** | **DOM-001** |
| 4 | `lib/domain/duty_status/status_dashboard.dart` | 202 | 167 | `.freezed.dart` | يرث DOM-001 |
| 5 | `lib/domain/duty_status/weekly_recap.dart` | 45 | 40 | `.freezed.dart` | — |
| 6 | `lib/domain/hardware/telemetry_reading.dart` | 47 | 39 | `.freezed.dart` | — |
| 7 | `lib/domain/inspection/dot_inspection.dart` | 142 | 131 | `.freezed.dart` | (read projection) |
| 8 | `lib/domain/shared/value_objects.dart` | 70 | 56 | `.freezed.dart` | **نموذج ممتاز** |
| 9 | `lib/domain/signature/signature.dart` | 43 | 35 | `.freezed.dart` | — |

**استيراد `lib/domain` الكامل — مُتحقَّق منه سطراً بسطر:**
```
driver_account.dart      : freezed_annotation فقط                       ✓ نقي
server_config.dart       : freezed_annotation فقط                       ✓ نقي
duty_status_code.dart    : flutter/widgets + core/utils/logger         ✗ متسرب
status_dashboard.dart    : freezed_annotation + ../shared + duty_status_code  ✓ (متسرب عبر 3)
weekly_recap.dart        : freezed_annotation + status_dashboard         ✓ نقي
telemetry_reading.dart   : freezed_annotation + ../shared                ✓ نقي
dot_inspection.dart      : freezed_annotation + ../shared                ✓ نقي
value_objects.dart       : freezed_annotation فقط                        ✓ نقي
signature.dart           : freezed_annotation + ../shared                ✓ نقي
```
**النتيجة: 8/9 نقي (88.9%)** — لا استيراد لـ Riverpod، ولا Dio، ولا `features/`، ولا `backend/` في أيٍّ منها ✓.

## F.8. ملفات التوجيه (داعمة، خارج النطاق المعلن لكنها ضرورية لإثبات §E) — 6/6 ✓

| # | Path | أسطر | غير فارغ | Issue IDs |
|---|---|---|---|---|
| 1 | `lib/routes.dart` | 100 | 89 | ROU-003 |
| 2 | `lib/routes/auth_routes.dart` | 39 | 33 | AUTH-005 |
| 3 | `lib/routes/home_routes.dart` | 38 | 32 | ROU-003, HOM-003 |
| 4 | `lib/routes/account_routes.dart` | 46 | 40 | ROU-001, ACC-008 |
| 5 | `lib/routes/logs_routes.dart` | 43 | 38 | — (انظر الملاحظة) |
| 6 | `lib/routes/dvir_routes.dart` | 33 | 30 | — (انظر الملاحظة) |

**ملاحظتان داعمتان من ملفات التوجيه:**

```dart
// lib/routes/logs_routes.dart:8
import '../features/logs/domain/entities/daily_log.dart';

// lib/routes/logs_routes.dart:38
            final event = state.extra as LogEvent?; // تمرير الـ event كـ extra
```
```dart
// lib/routes/dvir_routes.dart:5-6
import '../features/inspection/presentation/pages/dot_inspection_page.dart';
import '../features/inspection/presentation/pages/send_logs_page.dart';
```
- **الأولى:** طبقة التوجيه على مستوى التطبيق (`lib/routes/`) تستورد **domain entity** من feature (`logs/domain`) لاستخدامه في `state.extra`. ⇒ جذر التطبيق «يعرف» تفاصيل نطاقات الميزات. نمط closely related بـ DOM-002.
- **الثانية (تؤكّد ROU-002):** `DvirRoutes` يسجّل `/inspection` و`/send-logs`، بينما **لا يوجد أي `GoRoute` لـ `/instructions`** في أيٍّ من ملفات `routes/*.dart` الستة ⇒ تأكيد قاطع أن `InstructionsSection.inspection/sendLogs/malfunction` **غير قابلة للوصول**. كما أن `DotInspectionPage` و`SendLogsPage` من feature **INSPECTION** مُسجَّلان داخل `DvirRoutes` — ازدواج ملكية المسارات يعكس ازدواج ملكية الميزات (`inspection` و`dvir` يتبادلان الصفحات).

## F.9. ملفات داعمة مقروءة أيضاً (خارج النطاق — لأجل دليل الـ cross-feature)

| Path | سبب القراءة |
|---|---|
| `lib/core/di/app_providers.dart` | إثبات أن `core/di` هو composition root الوحيد (AUTH-006, DOM-005) |
| `lib/core/session/session_epoch.dart` | إثبات أن `SessionEpoch` كائن static عابر للطبقات (AUTH-001) |
| `lib/core/error/failure.dart` | إثبات `ValidationFailure.fieldErrors` غير المستخدم (AUTH-007) |
| `lib/core/error/user_facing_message.dart` | **إثبات ACC-003** — تتبع `Exception → errRequestFailedNetwork` |
| `lib/core/utils/localization_helper.dart` | إثبات أن مفاتيح l10n مصمَّمة ليتم ترجمتها (AUTH-003) |
| `lib/core/utils/logger.dart` | إثبات أن `AppLogger` لا يطبع أسراراً (SEC-001) |
| `lib/core/design_system.dart` | إثبات barrel nature (يُستخدم في `active_malfunction_actions.dart:4`) |
| `lib/backend/core/backend_kind.dart` | مقارنة مع `BackendType` (DOM-004) |
| `lib/core/domain/entities/user.dart` | إثبات وجود جذر دومين ثانٍ (DOM-002) |
| `lib/features/inspection/domain/inspection_transfer.dart` | **المرجع الصحيح** لـ COD-006 / COD-005 |
| `lib/features/inspection/presentation/providers/inspection_provider.dart:100-149` | إثبات موقع `informationPacketProvider` (ACC-006) |
| `lib/features/vehicle/presentation/providers/vehicle_provider.dart` | مقارنة بـ `codriver_provider` في COD-001/COD-002 |
| `lib/features/logs/domain/daily_form_rules.dart` | إثبات أن LOGS domain يستورد l10n (HOM-001) |
| `analysis_options.yaml` | إثبات غياب أي lint معماري (DOM-005) |

## F.10. ملخص التغطية

| المجموعة | المطلوب | المقروء | النسبة |
|---|---|---|---|
| auth | 19 | 19 | 100% |
| account | 9 | 9 | 100% |
| codriver | 10 | 10 | 100% |
| connection | 16 | 16 | 100% |
| home | 5 | 5 | 100% |
| onboarding / permissions / settings / about | 4 | 4 | 100% |
| lib/domain | 9 | 9 | 100% |
| **المجموع في النطاق** | **72** | **72** | **100%** |
| routing (داعم) | 6 | 6 | 100% |
| داعم خارج النطاق | 14 | 14 | — |

**لم يُقرأ أي ملف `*.g.dart` أو `*.freezed.dart`** (مستثنى بحكم التفويض)، ولم يُقدَّر أي ملف من اسمه — كل حكم مبني على قراءة كاملة للكود.

---

## G. ترتيب المعالجة المقترح (Remediation Order)

| الأولوية | Issue IDs | السبب |
|---|---|---|
| **P0** | **COD-001**, **ACC-003**, **ACC-004**, **DOM-001** | تسريب بيانات بين السائقين / رسائل خاطئة ومفصح عنها / تلويث نواة الدومين بـ Flutter |
| **P1** | **AUTH-005**, **CON-001**, **HOM-002**, **AUTH-004**, **ACC-001**, **ACC-002**, **COD-002** | انهيار طبقات: use-case داخل Widget / feature بلا domain / تجاوز قفل القيادة |
| **P2** | **HOM-001**, **ACC-006**, **ACC-008**, **COD-005**, **COD-006**, **CON-003**, **CON-004**, **CON-005** | تطبيع  حدود  feature boundaries + استخراج mappers |
| **P3** | **AUTH-001**, **AUTH-002**, **AUTH-003**, **AUTH-007**, **ACC-005**, **ACC-007**, **COD-003**, **COD-004**, **CON-002**, **CON-006**, **CON-007**, **HOM-003**, **HOM-004**, **DOM-002**, **DOM-003**, **DOM-004**, **DOM-005**, **ROU-001**, **ROU-002**, **ROU-003**, **SET-001**, **PERM-001**, **AUTH-006**, **SEC-002** | تحسين البنية والتجربة |
| — | **CTN-001**, **SEC-001**, **CON-006** (جزء الحكم), **§E-4** | **مناطق نظيفة موثّقة — لا عمل مطلوب** |

---

*نهاية التقرير. جميع الأكواد في §B مقتبسة حرفياً من الملفات المقروءة. لم يُعدَّل أي ملف تحت `lib/`.*

--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-001: طبقة العقد تصدّر `RawJson` وتتسرب بها إلى domain وpresentation
- **Severity:** HIGH
- **Category:** Architecture
- **Location:** `lib/backend/contracts/raw_json.dart:10`
- **Evidence:**
```dart
typedef RawJson = Map<String, dynamic>;
```
والتسريب المؤكَّد في الاستهلاك من طبقتين أعلى:
```dart
// lib/features/hos/domain/engine/tracking/duty_status_tracker.dart:13
import '../../../../../backend/contracts/status_dashboard_backend.dart';
// :46
  final StatusDashboardBackend _dashboardBackend;
```
```dart
// lib/features/connection/presentation/providers/hardware_status_provider.dart:15-23
  final backend = ref.read(hardwareBackendProvider);
  final uniqueId = ref.watch(vehicleProvider).selectedVehicle?.uniqueId;
  final result = await backend.getStatus(uniqueId: uniqueId);
  return result.fold((failure) => throw failure, (json) {
    final read = parseConnectivityStatus(json);
    if (read == null) {
      throw const FormatException('connectivity body is not an object');
    }
    return read;
  });
```
- **السلوك الحالي:** `RawJson` (= `Map<String, dynamic>`) هو النوع المُرجَع في 11 من 13 عقدة. الملفات التي تنتج هذه الخرائط هي بالضبط نفس الملفات التي يفترض في Clean Architecture أن تُنشئ نماذج مُحاطة.
- **لماذا هو مشكل:** النوع غير المُحاط يمرّر لأسفل حتى الطبقتين اللتين يفترض أنهما الأبعد عن السلك. النتيجة أن **اسم حقل من `openapi.yaml` صار واجهة برمجية** داخل `presentation`. مثال: `hardware_status_provider.dart:19` يستدعي `parseConnectivityStatus(json)` — محلل يفهم مفاتيح الخادم — من داخل `presentation`.
- **المبدأ المنتهك:** Dependency Inversion + Encapsulation. الـ port يجب أن يكون مكتوبًا بلغة النطاق (domain)، لا بلغة النقل (wire).
- **المالك الحالي:** `lib/backend/contracts/*` (النوع) و`lib/features/*` (الاستهلاك).
- **المالك الصحيح:** `lib/domain/**` — نماذج مُحاطة، مثل `DotInspectionScreen` في `inspection_backend.dart:9`، وهو يثبت أن الحل معمول به بالفعل داخل نفس المجلد.
- **العواقب:** تغيير اسم حقل في الخادم = كسر في `presentation`. لا يمكن كتابة اختبار نطاقي (domain test) بلا تشغيل خادم. `flutter analyze` لا يستطيع التقاط خطأ مفتاح.
- **التصحيح المقترح:** استبدال تدريجي لـ `RawJson` بنماذج domain مُحاطة، بالترتيب التصاعدي للاستخدام: `getAvailableDrivers` → `hardware.getStatus/getReadiness` → `unidentifiedEvents.list` → `dailyLogs.list`. وحظر أي `import` لـ `raw_json.dart` من `domain/` أو `presentation/` كقاعدة تحليل جذرية (انظر BACK-003).
- **الملفات المرتبطة:** `raw_json.dart`، `daily_logs_backend.dart`، `duty_status_backend.dart`، `dvir_backend.dart`، `hardware_backend.dart`، `inspection_backend.dart`، `vehicle_backend.dart`، `auth_backend.dart`، `driver_session_backend.dart`، `unidentified_events_backend.dart`، `duty_status_tracker.dart`، `hardware_status_provider.dart`، `unidentified_events_provider.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-002: الحافة المعروفة `lib/backend → lib/features` ليست حادثة بل نمط من 6 استيرادات
- **Severity:** HIGH
- **Category:** Coupling
- **Location:** `lib/backend/contracts/rules_screen_backend.dart:3`
- **Evidence:**
```dart
// lib/backend/contracts/rules_screen_backend.dart:3
import '../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
```
والتكرارات الخمس الأخرى (تحققت منها كلها بالبحث النصي):
```dart
// lib/backend/adapters/eld_engine/sub/eld_rules_screen_backend.dart:3
import '../../../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
// lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart:1
import '../../../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
// lib/backend/adapters/mock/sub/mock_rules_screen_backend.dart:4
import '../../../../features/account/application/models/rules_screen_model.dart'; // ignore_architecture
// lib/backend/http/interceptors/auth_interceptor.dart:2-3
import '../../../features/auth/data/datasources/auth_local_data_source.dart'; // ignore_architecture
import '../../../features/auth/domain/entities/auth_session.dart'; // ignore_architecture
// lib/backend/providers/backend_network_providers.dart:11-13
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/traccar_native_client.dart'; // ignore_architecture
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/traccar_native_client_impl.dart'; // ignore_architecture
import 'package:golden_feather_eld/features/tracking/data/datasources/traccar_sdk/mock_traccar_native_client.dart'; // ignore_architecture
```
- **السلوك الحالي:** `RulesScreenModel` — كائن من `features/account/application` — يتدفق عبر دورة كاملة: العقدة → المحوّل → الـ mapper → presentation، موزّعًا على 4 ملفات.
- **لماذا هو مشكل (الحكم المطلوب):** **ليست استيرادًا عارضًا.** الدليل أن `RulesScreenModel` لا يمكن نقله ببساطة: هو ليس `domain` ولا `application` مجرد حاوية، بل **كائن عابر للطبقات** يحمل `HosConfiguration limits` (`rules_screen_mapper.dart:19-30`) القادمة من `core/config`. الجذر ليس موقع الملف، بل أن **`RulesScreenModel` لا ينتمي لأي طبقة** — كان يجب أن يُوضع في `domain/account` أو `domain/hos`. كذلك `auth_interceptor.dart:2` يستورد من `features/auth/**data**` — أي أن طبقة البنية التحتية تعرف عن تنفيذ مصادقة ميزة ما. و`backend_network_providers.dart:11-13` يجعل `backend/providers` بوابة لعميل تتبّع native خاص بميزة.
- **المبدأ المنتهك:** Dependency Rule (طبقة البنية التحتية لا تعرف الميزات).
- **المالك الحالي:** `features/account/application/models/rules_screen_model.dart`. **المالك الصحيح:** `lib/domain/account/rules_screen_model.dart` أو `lib/domain/hos/`.
- **العواقب:** لا يمكن حذف feature `account` دون كسر `contracts`. لا يمكن اختبار `RulesScreenBackend` في عزلة عن الميزة. `AuthInterceptor` غير قابل لإعادة الاستخدام خارج هذا المشروع.
- **التصحيح المقترح:** (1) **نقل** `RulesScreenModel` إلى `lib/domain/`. (2) **نقل** `AuthLocalDataSource` و`AuthSession` خلف واجهة في `lib/core/session/` — وهي موجودة أصلًا (`core/session/session_epoch.dart`). (3) **نقل** `traccarNativeClientProvider` إلى `features/tracking/data/providers/`. (4) **حذف `// ignore_architecture`** لأنها ليست آلية (انظر BACK-003).
- **الملفات المرتبطة:** `rules_screen_backend.dart`، `eld_rules_screen_backend.dart`، `rules_screen_mapper.dart`، `mock_rules_screen_backend.dart`، `auth_interceptor.dart`، `backend_network_providers.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

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
### ISSUE BACK-004: العقد `daily_logs_backend.dart` يستورد نماذج من مجلد محوّل (انقلاب اتجاه)
- **Severity:** CRITICAL
- **Category:** Architecture
- **Location:** `lib/backend/contracts/daily_logs_backend.dart:3-4`
- **Evidence:**
```dart
// lib/backend/contracts/daily_logs_backend.dart:1-6
import '../../core/result/result.dart';
import '../../domain/shared/value_objects.dart';
import '../adapters/eld_engine/models/certify_dto.dart';
import '../adapters/eld_engine/models/readiness_dto.dart';
import 'raw_json.dart';
```
```dart
// lib/backend/contracts/daily_logs_backend.dart:38-41
  Future<Result<CertifyResponseDto>> certify(
    CertifyRequestDto request, {
    int? expectedOwnerDriverId,
  });
```
والنتيجة المباشرة — الموك مُلزَم بتوقيع يحتوي على DTOات المحرك الحقيقي:
```dart
// lib/backend/adapters/mock/sub/mock_daily_logs_backend.dart:5-6
import '../../eld_engine/models/certify_dto.dart';
import '../../eld_engine/models/readiness_dto.dart';
```
- **السلوك الحالي:** طبقة الـ port (المحايدة المفترضة) تستورد من **محوّل محدّد بعينه** (`eld_engine`).
- **لماذا هو مشكل:** هذا هو **المعيار الحقيقي** لما إذا كان there port حقيقي: هل يستطيع mock أن يُنفَّذ دون أن يعرف المحرك الحقيقي؟ هنا الإجابة لا. كما أن `DailyLogsBackend` — وهي واجهة use-case — صارت **مرتبطة بتمثيل ELD المحدد**، ما يعني أن أي backend ثالث محكوم عليه بإعادة تعريف نفس الـ DTOs.
- **المبدأ المنتهك:** Dependency Inversion — تعتمد المصادر الداخلية (Abstract) على التفاصيل الخارجية.
- **المالك الحالي:** `adapters/eld_engine/models/*`. **المالك الصحيح:** `lib/domain/logs/` (أو `lib/backend/contracts/dto/` مشترك).
- **العواقب:** استبدال/حذف `eld_engine` يكسر العقدة. الرسم البياني للطبقات غير قابل للتحقق آليًا. أي backend ثالث مجبور على تبنّي DTOات غريبة عنه.
- **التصحيح المقترح:** نقل `certify_dto.dart` و`readiness_dto.dart` إلى `lib/domain/logs/` كنماذج domain مع `fromJson` في mapper المحوّل. بعد نقلها يصبح السطران 3-4 في العقدة استيرادًا محايدًا، ويُحلBACK-035 في نفس الوقت.
- **الملفات المرتبطة:** `daily_logs_backend.dart`، `certify_dto.dart`، `readiness_dto.dart`，`mock_daily_logs_backend.dart`، `eld_daily_logs_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-005: نصوص عرض إنجليزية داخل طبقة backend (mapper + محوّل)
- **Severity:** LOW
- **Category:** Architecture
- **Location:** `lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart:76`
- **Evidence:**
```dart
// status_dashboard_mapper.dart:73-84
    if (raw is! Map<String, dynamic>) {
      return const RemainingCircle(
        remaining: Duration.zero,
        label: 'Remaining',
        progress: 0.0,
      );
    }
    return RemainingCircle(
      remaining: _parseDuration(raw['time']),
      label: JsonPrimitives.asString(raw['label'], fallback: 'Remaining'),
      progress: JsonPrimitives.asDouble(raw['progress']).clamp(0.0, 1.0),
    );
```
```dart
// status_dashboard_mapper.dart:90-93
      drive: _parseIndicator(raw['drive'], fallbackLabel: 'DRIVE'),
      shift: _parseIndicator(raw['shift'], fallbackLabel: 'SHIFT'),
      breakTime: _parseIndicator(raw['breakTime'], fallbackLabel: 'BREAK'),
      cycle: _parseIndicator(raw['cycle'], fallbackLabel: 'CYCLE'),
```
```dart
// eld_status_dashboard_backend.dart:110-125
  static String _defaultNoteFor(DutyStatusCode status) {
    switch (status) {
      case DutyStatusCode.onDutyNotDriving:
        return 'Available';
      case DutyStatusCode.sleeperBerth:
        return 'Sleeper Berth';
```
- **السلوك الحالي:** سلاسل عرض مُحاط بها داخل domain (`RemainingCircle.label`، `HosIndicator.label`) ومُولَّدة في طبقة البنية التحتية.
- **لماذا هو مشكل:** التطبيق يدّع دعم العربية (الـ fixtures والموكات تحمل نصوصًا عربية)، لكن هذه القيم ستُعرض دائمًا بالإنجليزية لأن مَن يملك l10n هو presentation. هذا **خلط مسؤوليات** لا مجرد ترجمة ناقصة.
- **المبدأ المنتهك:** SRP على مستوى الطبقة.
- **العواقب:** لا يمكن ترجمة شاشات HOS. الفحص المتسق عند نقص البيانات يُنتج نصًا إنجليزيًا في بيئة عربية.
- **التصحيح المقترح:** جعل `label` nullable في النماذج وترجمتها في presentation عبر `AppLocalizations`، أو إطلاق الـ fallback كمفتاح ترجمة (`'hosIndicator.drive'`) لا كنص نهائي.
- **الملفات المرتبطة:** `status_dashboard_mapper.dart`، `eld_status_dashboard_backend.dart`، `mock_status_dashboard_backend.dart`، `mock_inspection_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-006: منطق أعمال داخل `DvirDto.fromJson` و`toJson` يعيد كتابة حقول الخادم
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/eld_engine/models/dvir_dto.dart:107`
- **Evidence:**
```dart
// dvir_dto.dart:107-114
      hasDefects: json['hasDefects'] == true || vehicleDefects.isNotEmpty || trailerDefects.isNotEmpty || flatDefects.isNotEmpty,
      defectsCount: flatDefects.length + vehicleDefects.length + trailerDefects.length,
      defectsSummary: json['defectsSummary']?.toString(),
      outOfService: json['outOfService'] == true,
      photos: photos,
      vehicleDefects: vehicleDefects,
      trailers: trailers,
      defects: [...flatDefects, ...vehicleDefects, ...trailerDefects],
```
```dart
// dvir_dto.dart:129-130
      'id': id,
      'driver': driver?.toJson(),
```
```dart
// dvir_dto.dart:154-155
      'certified': certified,
      'signatureData': signatureData,
```
- **السلوك الحالي:** `hasDefects` و`defectsCount` ودمج القوائم الثلاث **مشتقات** لا قيم مخزّنة. و`toJson()` يُعيد كتابة حقول الخادم (`id`, `certified`, `createdAt`, `formattedTime`, `defectsCount`, `retentionDaysRemaining`).
- **لماذا هو مشكل:** DTO السلكي يجب أن يكون faithful transcode فقط. الاشتقاق هنا **قاعدة DVIR** (هل يوجد عيب فعلي؟) داخل طبقة البنية التحتية؛ أي تعديل في الخادم على تعريف «العيب» يتطلب تعديلًا في هذا الملف. وإذا استُخدم `CreateDvirRequestDto.fromJson` (322) لتحويل حمولة واردة ثم `toJson()` (350) للإرسال، فسيتكرر `id` وحقول الخادم في جسم الطلب.
- **المبدأ المنتهك:** SRP / فصل DTO عن Mapper.
- **المالك الحالي:** `adapters/eld_engine/models/dvir_dto.dart`. **المالك الصحيح:** mapper في `adapters/eld_engine/mappers/dvir_mapper.dart` (المجلد موجود ويعمل).
- **العواقب:** عدم تناسق بين «ما يراه الخادم» و«ما يراه التطبيق». اختبار `hasDefects` يحتاج معرفة مصادر العيوب الثلاثة.
- **التصحيح المقترح:** نقل الاشتقاق إلى `DvirMapper.toEntity(DvirDto)`. وحذف `toJson()` من DTOات القراءة (`DvirDto`) لأنها غير مستخدمة — تحققت: `CreateDvirRequestDto` و`ReviewDvirRequestDto` هما المستخدمان فعليًا (المستهلك الوحيد `dvir_repository_impl.dart:279`).
- **الملفات ذات الصلة:** `dvir_dto.dart`، `lib/features/dvir/data/repositories/dvir_repository_impl.dart:327`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-007: `DvirDto` (نموذج `eld_engine`) يُستهلك من خارج مجلد المحوّل
- **Severity:** MEDIUM
- **Category:** Coupling
- **Location:** `lib/features/dvir/data/repositories/dvir_repository_impl.dart:56`
- **Evidence:**
```dart
// features/dvir/data/repositories/dvir_repository_impl.dart:54-58
        final rawReports = (rawJson['data'] as List<dynamic>?) ?? [];
        final reports = rawReports.map((json) {
          final dto = DvirDto.fromJson(json as Map<String, dynamic>);
          return _mapDtoToEntity(dto);
        }).toList();
```
- **السلوك الحالي:** `DvirDto` (و`ReviewDvirRequestDto` عند 279) معرّفان في `lib/backend/adapters/eld_engine/models/` ويُستهلكان في `lib/features/dvir/data/repositories/`. تحققت بالبحث النصي: **لا استيراد لـ `dvir_dto.dart` من أي مكان داخل `lib/backend/`**.
- **لماذا هو مشكل:** هذا يعني أن `DvirDto` ليس نوعًا داخليًا للمحوّل بل **حقيقة مشتركة** بين البنية التحتية والمستهلك. الموقع في `adapters/eld_engine/` مضلّل: أي كود في طبقة `data` يستطيع الوصول إلى تفاصيل ELD Engine بينما العقدة (`dvir_backend.dart`) تُرجع `RawJson`. عمليًا: طبقة `data` مربوطة بمحوّل واحد بالتزامًا مع `MockAdapter`.
- **المبدأ المنتهك:** Encapsulation (نوع مشترك وُضع في المكان الخطأ).
- **العواقب:** استبدال المحرك = كسر طبقة `data`. لا يمكن إعادة استخدام `DvirDto` مع backend ثالث.
- **التصحيح المقترح:** إما (أ) رفع `dvir_dto.dart` إلى `lib/backend/contracts/dto/` كـ port DTO مشترك (الأنسب، لأنه يُستخدم فعلاً من الطرفين)، أو (ب) الأفضل: نقل التحليل إلى mapper داخل المحوّل وإرجاع `DvirReport` (domain) من العقدة نفسها — وهذا يلغي `RawJson` أيضًا.
- **الملفات ذات الصلة:** `dvir_dto.dart`، `dvir_repository_impl.dart`، `dvir_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-008: تباين صامت في شكل استجابة `DvirBackend.list` بين المحرك والموك
- **Severity:** HIGH
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_dvir_backend.dart:20`
- **Evidence:**
```dart
// mock_dvir_backend.dart:19-21
  }) async {
    return ok({'reports': []});
  }
```
مقابل:
```dart
// eld_dvir_backend.dart:34
      parser: (data) => data is List ? {'data': data} : (data is Map<String, dynamic> ? data : {}),
```
والconsumer:
```dart
// features/dvir/data/repositories/dvir_repository_impl.dart:54
        final rawReports = (rawJson['data'] as List<dynamic>?) ?? [];
```
- **السلوك الحالي:** العقد نفسه يُرجع `RawJson`، لكن **شكله غير مُلزم**. المحرك الحقيقي يغلّف في `'data'`، والموك يغلّف في `'reports'`. المستهلك يقرأ `'data'` فقط.
- **لماذا هو مشكل:** هذا **ليس** مجرد نقص تناظر في التنفيذ، بل **عقد ضمني غير معلن** يعيش خارج الواجهة. النتيجة المؤكَّدة: `getDvirReports()` تحت الموك يُرجع **قائمة فارغة دائمًا** (`rawJson['data']` = null) — لا رسالة خطأ، لا تحذير. أي أن **اختبار العرض بكامل وظيفته يمرّ تحت الموك يكذب بهدوء**.
- **المبدأ المنتهك:** Contract completeness / Liskov Substitution.
- **العواقب:** شاشة DVIR فارغة في وضع الموك بلا أي مؤشر؛ اختبارات الواجهة تمرّ (قائمة فارغة) دون كشف الانحراف؛ أي إصلاح لاحق على الشاشة لا يُختبر على الموك.
- **التصحيح المقترح:** إما (أ) **الحظر الصريح**: `MockDvirBackend.list` يرجع `{'data': <dynamic>[]}` لمطابقة المحرك، أو (ب) الأفضل: استبدال `RawJson` بـ `List<DvirReport>` في العقدة — عندها يصبح الشكل جزءًا من النوع (مُجمَّع بالـ compiler) ولا يمكن أن يتباين.
- **الملفات ذات الصلة:** `mock_dvir_backend.dart`، `eld_dvir_backend.dart`، `dvir_repository_impl.dart`، `dvir_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-009: `auth_interceptor.dart` يستورد من طبقتي `features/auth` (data + domain)
- **Severity:** HIGH
- **Category:** Coupling
- **Location:** `lib/backend/http/interceptors/auth_interceptor.dart:2-3`
- **Evidence:**
```dart
// lib/backend/http/interceptors/auth_interceptor.dart:1-7
import 'package:dio/dio.dart';
import '../../../features/auth/data/datasources/auth_local_data_source.dart'; // ignore_architecture
import '../../../features/auth/domain/entities/auth_session.dart'; // ignore_architecture
import '../../../core/error/failure.dart';
import '../../../core/session/session_epoch.dart';
import '../../../core/utils/logger.dart';
import '../eld_endpoints.dart';
```
- **السلوك الحالي:** اعتراض HTTP — وهو البنية التحتية — يعتمد على `features/auth/data/datasources/auth_local_data_source.dart` (طبقة data كاملة، تشمل تخزين Keystore) وعلى كيان `features/auth/domain/entities/auth_session.dart`.
- **لماذا هو مشكل:** `AuthLocalDataSource` ليس عقدة (interface) بل **تنفيذ كامل** لطبقة data. بالتالي `AuthInterceptor` لا يعمل إلا مع `AuthLocalDataSource` حقيقي. والأسوأ: `AuthLocalDataSource` هو المكان الذي تعيش فيه سياسة تخزين الجلسة — وهي سياسة عالية المستوى التي يفترض أن `lib/backend` لا يعرفها.
- **المبدأ المنتهك:** Dependency Rule + Dependency Inversion (اعتماد concretes لا abstractions).
- **المالك الحالي:** `features/auth/data`. **المالك الصحيح:** عقدة في `lib/core/session/` — ولحسن الحظ `lib/core/session/session_epoch.dart` **موجود بالفعل**، فالجذر قائم والحدّ غائب.
- **العواقب:** لا يمكن اختبار `AuthInterceptor` بجلسة وهمية إلا بتبعية حقيقية على Keystore. استبدال سياسة تخزين الجلسة = تعديل `lib/backend`.
- **التصحيح المقترح:** تعريف `abstract interface class SessionStore { Future<AuthSession?> getSession(); int get credentialGeneration; }` داخل `lib/core/session/`، وتنفيذه في `features/auth/data`. يحوّل الاعتماد من concrete إلى abstraction دون تغيير سلوك.
- **الملفات ذات الصلة:** `auth_interceptor.dart`، `auth_local_data_source.dart`، `core/session/session_epoch.dart`، `backend_network_providers.dart:57`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-010: `AuthBackend` يمرّر `backendType` ومفاتيح JSON الخام كواجهة، ولا يوجد تدفّق refresh
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/contracts/auth_backend.dart:5-10`
- **Evidence:**
```dart
// lib/backend/contracts/auth_backend.dart:4-16
abstract interface class AuthBackend {
  Future<Result<RawJson>> login({
    required String identifier,
    required String password,
    required String serverUrl,
    required String backendType,
  });

  Future<Result<RawJson>> validateSession({
    required String serverOrigin,
    required String sessionCredential,
    required String backendType,
  });
```
والاستهلاك الذي يثبّت المفاتيح كعقد ضمني:
```dart
// lib/features/auth/data/repositories/auth_repository_impl.dart:60-64
        final sessionDto = AuthSessionDto.create(
          serverOrigin: rawJson['serverOrigin'],
          sessionCredential: rawJson['credential'],
          userModel: UserModel.fromMetadata(rawJson['user'], defaultEmail: identifier),
        );
```
- **السلوك الحالي:** ثلاث ملاحظات في عقدة واحدة.
- **(أ) `backendType`**: اسم تسمية داخلية (`eldEngine` / `mock`) يُمرَّر كـ required parameter في 3 تواقيع، رغم أن تعليق `eld_auth_backend.dart:27-28` يقرّ صراحةً بأنه **لا يختار أي تسجيل دخول ثانٍ**. فهو معامل ميت في العقد.
- **(ب) `RawJson`**: بنية `{'credential', 'user', 'serverOrigin'}` تصبح عقدًا ضمنيًا يفهمه `auth_repository_impl` (60-64). لو غيّر `EldAuthBackend` اسم مفتاح، ينكسر `features/auth` — مع أن العقد لم يتغير.
- **(ج) لا يوجد `refreshSession`**: بحثت في `lib/` بالكامل — لا يوجد أي use لـ `refreshToken`/`refresh_token` عدا الثابت `app_constants.dart:28` (`refreshTokenKey`) وهو غير مستخدم، و`request_logger.dart:26` (قائمة حجب). **التقييم: هذه ليست مخالفة** — نموذج ELD يعتمد على `JSESSIONID` (cookie)، فالتجديد التلقائي غير مطلوب؛ بل الفقدان الصحيح للجلسة عند 401 هو السلوك الصحيح. وتأكيدًا لذلك: `auth_interceptor.dart:120-141` يعالج 401 بثلاثة أجيال (sessionAttached / credentialGeneration / epoch) وهو تصميم متين.
- **المبدأ المنتهك:** (أ) و(ب): Interface Segregation + Explicit contracts.
- **المالك الحالي / الصحيح:** `contracts/auth_backend.dart` — لكن بأنواع مُحاطة (`SessionGrant`) وبدون `backendType`.
- **العواقب:** تسمية داخلية تسرّبت للواجهة؛ عقد ضمني غير مرئي في التوقيع؛ `app_constants.refreshTokenKey` عتاد ميت يوحي بمعمارية لا وجود لها.
- **التصحيح المقترح:** حذف `backendType` من التواقيع الثلاثة؛ إرجاع `Result<SessionGrant>` (domain) بدل `RawJson`؛ حذف `refreshTokenKey` من `app_constants.dart`.
- **الملفات ذات الصلة:** `auth_backend.dart`، `eld_auth_backend.dart`، `mock_auth_backend.dart`، `auth_repository_impl.dart`، `app_constants.dart:28`
- **Confidence:** CONFIRMED (أ، ب، عدم وجود ج) / تقييم معماري صريح: قرار (ج) تصميمي مقصود وليس مخالفة


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-011: `EldAuthBackend` يتجاوز `ApiClient` ويكرّر بناء العنوان وتطبيع URL
- **Severity:** MEDIUM
- **Category:** Dio
- **Location:** `lib/backend/adapters/eld_engine/sub/eld_auth_backend.dart:29-38`
- **Evidence:**
```dart
// eld_auth_backend.dart:24-26
      final baseUrl = serverUrl.endsWith('/')
          ? serverUrl.substring(0, serverUrl.length - 1)
          : serverUrl;
```
```dart
// eld_auth_backend.dart:29-38
      final response = await _apiClient.dio.post(
        '$baseUrl/api${EldEndpoints.session}',
        data: {'email': identifier, 'password': password},
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
```
- **السلوك الحالي:** (1) يستخدم `_apiClient.dio` مباشرة بدل `_apiClient.post(...)`، متجاوزًا `ApiResponse.fromBody` و`error_mapper` الموحّدين. (2) يبني عنوانًا مطلقًا بـ `'${baseUrl}/api${EldEndpoints.session}'` — أي **نص `/api` مكتوب يدويًا في 4 مواضع** (30، 107، 156، 174) رغم أن `ApiConfig.baseUrl` أصلًا ينتهي بـ `/api` (مضمون في `backend_network_providers.dart:33-39`). (3) تطبيع URL هنا (24-26) **لا يضيف scheme**، بخلاف `BackendIdentity._normalizeUrl` (86-88) و`ApiConfig.normalized()` (68-70) اللذين يضيفان `https://`. (4) **لا يفرض TLS**.
- **لماذا هو مشكل:** في مسار المصادقة تحديدًا، تجاوز العميل الموحّد يعني فقدان `error_mapper` الموحد، واستخراج `ApiResponse`، وأي معالجة `expectedOwnerDriverId` منhigher. والأهم: **ثلاث نسخ مختلفة من تطبيع URL**، اثنتان منها تضيفان scheme وواحدة لا.
- **المبدأ المنتهك:** DRY + Centralized transport configuration.
- **العواقب:** خطر إرسال اعتماديات عبر HTTP صريح إذا أخطأ المستخدم؛ عدم اتساق في سلوك الأخطاء بين مسارات المصادقة؛ `/api` قد يتكرر.
- **التصحيح المقترح:** (1) نقل بناء العنوان إلى `ApiClient` كـ `postAbsolute(path, origin: serverUrl)`؛ (2) استخدام `ApiConfig.normalized()` بدل التطبيع المحلي؛ (3) رفض `http://` صراحةً في `EldAuthBackend.login` مع رسالة واضحة.
- **الملفات ذات الصلة:** `eld_auth_backend.dart`، `core/network/api_client.dart`، `core/network/api_config.dart:64-84`، `backend_network_providers.dart:33-39`
- **Confidence:** CONFIRMED (البنية) / POTENTIAL (خطورة TLS تعتمد على قيود input في شاشة الإعدادات — لم أقرأ `lib/features/settings` لأنها خارج النطاق)


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-012: `expectedOwnerDriverId` و`List<dynamic>` يتسرّبان من طبقة النقل إلى العقد
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/contracts/dvir_backend.dart:21-24`
- **Evidence:**
```dart
// lib/backend/contracts/dvir_backend.dart:21-24
  Future<Result<void>> create(
    RawJson report, {
    int? expectedOwnerDriverId,
  });
```
```dart
// lib/backend/contracts/driver_session_backend.dart:11-12
  /// GET /api/drivers
  Future<Result<List<dynamic>>> getAvailableDrivers();
```
الأصل المفهومي:
```dart
// lib/backend/http/interceptors/auth_interceptor.dart:41-45
  /// P0 2B-1 — المالك المتوقع لعملية الطابور (يضعه الـ dispatcher عبر
  /// ApiClient حصراً لطلبات المزامنة). عند الإرسال الفعلي يُقارن بجلسة
  /// اللحظة: أي اختلاف (تبديل جلسة أثناء الـ awaits السابقة) يرفض
  /// الطلب قبل مغادرة أي بايت — فلا ترث عملية قديمة جلسة جديدة أبداً.
  static const expectedOwnerKey = 'gf_expected_owner';
```
- **السلوك الحالي:** (أ) `expectedOwnerDriverId` وارد في **4 عقد** (`dvir_backend`, `daily_logs_backend`, `duty_status_backend`, `inspection_backend`) ويمرّ إلى `ApiClient` الذي يحوله إلى `extra['gf_expected_owner']`. (ب) `List<dynamic>` في توقيع عقد.
- **لماذا هو مشكل:** (أ) **سياسة تنفيذية** (منع عملية قديمة من وراثة جلسة جديدة) صارت **جزءًا من توقيع واجهة النطاق**. كل من يستدعي `dvir.create` عليه أن يعرف مفهوم الـ queue-dispatch. (ب) `List<dynamic>` يلغي أي ضمان نوع: المستهلك لا يستطيع الوصول إلى `id`/`name` بدون cast يدوي في كل مكان.
- **المبدأ المنتهك:** Interface Segregation + Information Hiding.
- **المالك الحالي:** `contracts/*`. **المالك الصحيح:** `ApiClient`/الاعتراض (المالك الفعلي الآن).
- **العواقب:** كل use-case جديد يختار `expectedOwnerDriverId` اعتباطًا؛Philosophyالمعرفة موزّعة على طبقتين.
- **التصحيح المقترح:** (أ) نقل `expectedOwnerDriverId` من توقيع العقدة إلى `ApiClient` وحده، مع API مختلف للمسارات التي تحتاج ربطًا (`dispatcherClient` مخصص). (ب) تعريف `DriverRef` (موجود أصلًا في `domain/duty_status`) كعنصر `List<DriverRef>`.
- **الملفات ذات الصلة:** `dvir_backend.dart`، `daily_logs_backend.dart`، `duty_status_backend.dart`، `inspection_backend.dart`، `driver_session_backend.dart`، `auth_interceptor.dart`، `core/network/api_client.dart:102,263-272`
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
### ISSUE BACK-014: المحوّل يحقن قيمة ناقصة في الاستجابة لإخفاء تعطّل العقد
- **Severity:** MEDIUM
- **Category:** ErrorHandling
- **Location:** `lib/backend/adapters/eld_engine/sub/eld_status_dashboard_backend.dart:84-89`
- **Evidence:**
```dart
// eld_status_dashboard_backend.dart:82-91
        .then((result) => result.mapValue(
          (response) {
            final json = response.data ?? const <String, dynamic>{};
            final map = Map<String, dynamic>.from(json);
            if (!map.containsKey('currentDutyStatus') || map['currentDutyStatus'] == null) {
              map['currentDutyStatus'] = status.wire;
            }
            return StatusDashboardMapper.fromDashboardJson(map);
          },
        ));
```
- **السلوك الحالي:** إذا رجعت استجابة الخادم بلا `currentDutyStatus` (انحراف عقد، أو 200 بجسم فارغ — وهو مسار مُعالَج في 53-80)، يقوم المحوّل **بملء القيمة من طلب العميل** ويُعيد نتيجة تبدو ناجحة.
- **لماذا هو مشكل:** التطبيق يعرض «حالة العمل الحالية» كأنها حقيقة مؤكدة، لكن الخادم لم يؤكّدها. السائق يرى حالة واثقة وهي **مُختلَقة محليًا**. في نظام ELD متعلق بالامتثال، عرض حالة غير مؤكدة كموثوقة خطأ جسيم.
- **المبدأ المنتهك:** Fail loudly / Truthfulness.
- **المالك الحالي:** المحوّل. **المالك الصحيح:** نفس المحوّل، لكن مع **إشارة**: تسجيل + `ServerError` أو علم `unconfirmed` في `StatusDashboard`.
- **العواقب:** انحراف خادم غير مرئي؛ قد يُعرض سجل HOS اعتمادًا على قيمة لم يؤكدها الخادم.
- **التصحيح المقترح:** إضافة `bool confirmed` إلى `StatusDashboard` وضبطه `false` عند الحقن، وعرض مؤشر في الواجهة؛ أو إعادة `ServerError(code: 'eld.status_contract_violation')`.
- **الملفات ذات الصلة:** `eld_status_dashboard_backend.dart`، `status_dashboard_mapper.dart`، `lib/domain/duty_status/status_dashboard.dart`
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
### ISSUE BACK-019: الموك لا يمرّ بنفس تطبيع الحساب الذي يمرّ به المحرك الحقيقي
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_account_backend.dart:16`
- **Evidence:**
```dart
// mock_account_backend.dart:14-17
  @override
  Future<Result<DriverAccount>> getMyAccount({DriverId? driverId}) async {
    return ok(DriverAccount.fromJson(accountMyAccountFixture));
  }
```
مقابل المحرك الحقيقي:
```dart
// eld_account_backend.dart:15-16
  Map<String, dynamic> _mapAccountJson(Map<String, dynamic> json, {DriverId? fallbackDriverId}) {
    // 1. معالجة المعرف driverId
```
```dart
// eld_account_backend.dart:23-40
    if (json['license'] is String) {
      final licenseStr = json['license'] as String;
      final parts = licenseStr.split(',');
      final state = parts.isNotEmpty ? parts[0].trim() : '';
      final number = parts.length > 1 ? parts[1].trim() : licenseStr;
      
      json['license'] = {
        'state': state,
        'number': number,
        'formatted': licenseStr,
      };
    } else if (json['license'] == null) {
```
- **السلوك الحالي:** المحرك الحقيقي يطبّق 3 تحويلات قبل `fromJson` (driverId fallback، تحويل نص الرخصة `"MI, A350622298913"` إلى Map، توحيد `timezone`→`timeZone`). الموك يمرّر الـ fixture مباشرة.
- **لماذا هو مشكل:** الـ fixture الحالية مُصنوعة أصلًا بالشكل **بعد التطبيع** (`license` Map في `accountMyAccountFixture:39-43`، و`timeZone` في 64). أي أن الموك **يتجاوز تمامًا السلوك الذي صُمم لاختباره** — وهو في الواقع اختصار مسار التطبيع. عند فشل التطبيع في الإنتاج، لن يكتشفه أي اختبار يعمل على الموك.
- **المبدأ المنتهك:** Faithful test double.
- **العواقب:** مسار `_mapAccountJson` (26 سطرًا من منطق العمل) غير مغطى؛ بيانات الـ fixture الصحيحة تُخفي أخطاء التطبيع.
- **التصحيح المقترح:** (أ) نقل `_mapAccountJson` إلى مشترك في `mappers/account_mapper.dart` يناديه كلا المحوّلين، و(ب) إضافة fixture ثانٍ بصيغة **الخام** (`license` كنص + `timezone`) لاختبار التطبيع تحت الموك.
- **الملفات ذات الصلة:** `mock_account_backend.dart`، `eld_account_backend.dart`، `account_fixtures.dart`، `account_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-020: 22 من 58 دالة عقد (≈38%) غير منفَّذة في الموك
- **Severity:** HIGH
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_unidentified_events_backend.dart:18`
- **Evidence:** العقد الوحيد بنسبة تنفيذ 0%:
```dart
// mock_unidentified_events_backend.dart:12-20
  @override
  Future<Result<RawJson>> list({
    UnidentifiedTab tab = UnidentifiedTab.unclaimed,
    String? uniqueId,
    DriverId? driverId,
  }) =>
      throw UnimplementedError(
        'MockUnidentifiedEventsBackend.list — Phase 2',
      );
```
```dart
// mock_daily_logs_backend.dart:51-52
  @override
  Future<Result<RawJson>> getById(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.getById — Phase 2');
```
```dart
// mock_hardware_backend.dart:62-64
  @override
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    throw UnimplementedError('MockHardwareBackend.getStatus — not implemented');
  }
```
```dart
// mock_inspection_backend.dart:163-165
  @override
  Future<Result<RawJson>> getInformationPacket({DriverId? driverId}) =>
      throw UnimplementedError('MockInspectionBackend.getInformationPacket — Phase 2');
```
```dart
// mock_driver_session_backend.dart:13-16
  Future<Result<RawJson>> getActiveSession(DriverId driverId) =>
      throw UnimplementedError(
        'MockDriverSessionBackend.getActiveSession — Phase 2',
      );
```
- **السلوك الحالي:** العدد الدقيق (بتفصيله الكامل في القسم C): `dailyLogs` 4/11، `driverSession` 4/5، `dutyStatus` 1/5، `dvir` 2/8، `hardware` 3/6، `inspection` 5/8، `unidentifiedEvents` 3/3 = **22 دالة**.
- **لماذا هو مشكل:** ليس مجرد نقص تغطية، بل **أن الموك ليس بديلاً**؛ البديل يفشل بصمت أو بانفجار حيث ينجح الأصل. والأثر مباشر في الإنتاج: `hardware_status_provider.dart:17` يستدعي `getStatus` من `presentation`؛ تحت الموك هذا `UnimplementedError` غير معالَج (لا `try/catch`، فقط `fold` على `Result`). النتيجة: **شاشة حالة الجهاز تنهار في وضع الموك**.
- **المبدأ المنتهك:** Liskov Substitution.
- **العواقب:** (أ) لا يمكن عرض شاشات DVIR/التفتيش/الأحداث غير المعرّفة تحت الموك. (ب) انهيار في `presentation` لا في `data`. (ج) الوعد في التوثيق («filled in Phase 2») تجاوزه الزمن.
- **التصحيح المقترح:** استراتيجيتان: (أ) **قابل للتبديل**: كل دالة غير منفَّذة ترجع `err(ServerError(code: 'mock.not_implemented', context: {'method': '...'})` بدل `throw` — يحوّل الانهيار إلى حالة خطأ معروضة. (ب) **اختبار تناظر آلي**: ملف اختبار يمرّ على كل عضو في `BackendAdapter` ويفحص `MockAdapter.<x>` عبر `try/catch` ويفشل إن رمى — فيصبح الرقم في القسم C مُراقَبًا في CI.
- **الملفات ذات الصلة:** كل ملفات `mock/sub/*`، `hardware_status_provider.dart`، `unidentified_events_provider.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-021: الموك يستخدم `DateTime.now()` رغم قاعدة «لا مؤقتات / حتمية» المعلنة
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_duty_status_backend.dart:13`
- **Evidence:**
```dart
// mock_duty_status_backend.dart:11-13
  @override
  Future<Result<RawJson>> record(RawJson event) async =>
      ok(<String, dynamic>{'id': DateTime.now().millisecondsSinceEpoch, ...event});
```
والقاعدة العامة المعلنة:
```dart
// mock_adapter.dart:36
/// **Rule:** No network access. No timers. No platform channels.
```
- **السلوك الحالي:** `id` المُعاد يعتمد على ساعة الجهاز الحقيقية.
- **لماذا هو مشكل:** (أ) يخالف القاعدة الصريحة. (ب) **يكسر الحتمية**: نفس `event` يعطي `id` مختلفًا في كل تشغيل، فأي اختبار يعتمد على `id` يصبح متذبذبًا. (ج) في نظام HOS، توليد معرّف اعتماد حالة من ساعة جهاز **غير موثوقة** (انظر BACK-033) قرار خاطئ في حد ذاته. (د) **`DateTime.now()` في طبقة backend يتجاوز `TrustedTimeProvider`** الموجود والمتاح.
- **المبدأ المنتهك:** Determinism + Single source of truth للوقت.
- **العواقب:** اختبارات متذبذبة؛ معرّفات غير قابلة للتنبؤ في العرض التوضيحي.
- **التصحيح المقترح:** تمرير `TrustedTimeProvider` (أو `FakeTrustedTimeProvider` في الاختبارات) إلى `MockDutyStatusBackend`، أو عداد تصاعدي `int _nextId = 1000;`.
- **الملفات ذات الصلة:** `mock_duty_status_backend.dart`، `mock_adapter.dart:36`، `core/time/trusted_time_provider.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-022: `MockHardwareBackend` يرمي داخل `async` فتتغير دلالة الخطأ
- **Severity:** MEDIUM
- **Category:** ErrorHandling
- **Location:** `lib/backend/adapters/mock/sub/mock_hardware_backend.dart:59-64`
- **Evidence:**
```dart
// mock_hardware_backend.dart:58-64
  @override
  Future<Result<RawJson>> getStatus({
    String? uniqueId,
    DriverId? driverId,
  }) async {
    throw UnimplementedError('MockHardwareBackend.getStatus — not implemented');
  }
```
مقابل النسخة المتزامنة (سلوك مختلف عمدًا):
```dart
// mock_daily_logs_backend.dart:51-52
  @override
  Future<Result<RawJson>> getById(DailyLogId logId) =>
      throw UnimplementedError('MockDailyLogsBackend.getById — Phase 2');
```
- **السلوك الحالي:** `getAlerts` (13)، `connectSession` (55)، `getStatus` (63) معلَّمة `async` وترمي **داخل** الجسم ⇒ `Future.error`. أما `mock_daily_logs` و`mock_dvir` و`mock_unidentified` و`mock_driver_session` فتستخدم `=> throw` المتزامنة.
- **لماذا هو مشكل:** في كلتا الحالتين يرمي الاستدعاء قبل الوصول إلى `fold` في المستهلك، لكن **التناقض أسلوبي يربك**: كأن أحدهم كتب `async` قصدًا أن يصير `Future`، أو نسي. dune dissatisfaction: `getStatus` يرمي بينما `getStatusProvider` في presentation لا يملك `try/catch` — في كلتا الحالتين هذا **انهيار**.
- **المبدأ المنتهك:** اتساق عقد معالجة الأخطاء.
- **العواقب:** سلوك مختلف ومربك لنفس الفكرة؛ دالة `async` بلا `await`.
- **التصحيح المقترح:** توحيد الأسلوب (الأفضل: `=> throw UnimplementedError(...)` متزامنًا كما في بقية الموكات) + تصحيح جذر: إرجاع `err(...)` بدل الرمي (BACK-020).
- **الملفات ذات الصلة:** `mock_hardware_backend.dart`، `mock_daily_logs_backend.dart`، `hardware_status_provider.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-023: طبقة presentation تستدعي عقود backend مباشرة (تجاوز حدّ الـ port)
- **Severity:** HIGH
- **Category:** Architecture
- **Location:** `lib/features/logs/presentation/providers/unidentified_events_provider.dart:97`
- **Evidence:** مواقع presentation التي تستهلك عقود الـ backend مباشرة (7 مواقع، تحققت من كلٍّ منها بالبحث النصي):
```dart
// unidentified_events_provider.dart:97
    final backend = ref.read(unidentifiedEventsBackendProvider);
```
```dart
// features/connection/presentation/pages/eld_connection_page.dart:87
    final hardwareBackend = _ref.read(hardwareBackendProvider);
```
```dart
// features/connection/presentation/providers/hardware_alerts_provider.dart:42
    final backend = ref.read(hardwareBackendProvider);
```
```dart
// features/connection/presentation/providers/hardware_status_provider.dart:15
    final backend = ref.read(hardwareBackendProvider);
```
```dart
// features/account/presentation/providers/rules_screen_provider.dart:17
    final backend = ref.read(rulesScreenBackendProvider);
```
```dart
// features/account/presentation/providers/account_provider.dart:138
    ref.watch(accountBackendProvider),
```
```dart
// features/hos/presentation/providers/hos_engine_provider.dart:46
  final dashboardBackend = ref.watch(statusDashboardBackendProvider);
```
```dart
// features/logs/presentation/providers/team_status_provider.dart:16
    final backend = ref.read(dailyLogsBackendProvider);
```
- **السلوك الحالي:** في كل هذه المواقع، `presentation` يتجاوز `domain` تمامًا: لا use-case، لا repository. يقرأ `RawJson` بنفسه — `unidentified_events_provider.dart:107`:
```dart
    final otherCount =
        results[1].fold<int?>((_) => null, (json) => _parse(json).length);
```
- **لماذا هو مشكل:** هذا **يكشف أن الـ port ليس حدًا معماريًا**: الواجهة موجودة في `backend/contracts`، لكن **حدود الطبقات سُيّرت من presentation أعدت اختراقها**. عمليًا: أسماء حقول الخادم (`json['data']`, `json['message']`, `json['hasPreviousDvir']`) تصل إلى الـ widgets. بين BACK-001 و BACK-023، **طبقة الـ port صارت شفافة**.
- **المبدأ المنتهك:** Dependency Rule — presentation يعتمد على domain فقط.
- **العواقب:** تغيير مفتاح في الخادم يكسر UI؛ منطق العمل (عدّ التبويبات، تفسير `hasPreviousDvir`) في presentation؛ اختبارات الواجهة تتطلب مزوّدات backend.
- **التصحيح المقترح:** لكل موقع من السبعة، إنشاء repository في `data/` + use-case في `domain/`، وربط presentation بالـ use-case فقط. **الأولوية:** `unidentified_events_provider` (3 دوال خام في presentation)، `hardware_status_provider` + `hardware_alerts_provider`.
- **الملفات ذات الصلة:** الملفات المذكورة أعلاه، `lib/backend/providers/backend_providers.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-024: قيم wire الخاصة بـ backend مسرّبة إلى طبقة العقد وإلى presentation
- **Severity:** MEDIUM
- **Category:** Coupling
- **Location:** `lib/backend/contracts/contract_enums.dart:45-51`
- **Evidence:**
```dart
// contract_enums.dart:45-51
enum DutyStatusAction {
  switchPrimary('switch-primary'),
  legacySwitch('legacy-switch');

  const DutyStatusAction(this.wire);
  final String wire;
}
```
```dart
// contract_enums.dart:37-43
enum UnidentifiedTab {
  unclaimed('UNCLAIMED'),
  rejected('REJECTED');
```
والاستهلاك في presentation:
```dart
// lib/features/logs/presentation/pages/unidentified_events_page.dart:6
import '../../../../backend/contracts/contract_enums.dart';
```
- **السلوك الحالي:** (أ) أسماء `DutyStatusAction` هي حرفيًا قيم Swagger: `'switch-primary'`، `'legacy-switch'` — ليست أسماء مفاهيمية بل أسماء مُعاملات. (ب) `UnidentifiedTab` قيمه `SCREAMING_SNAKE_CASE` مطابقة لتسمية الخادم. (ج) `presentation` يستورد `contract_enums.dart` مباشرة.
- **لماذا هو مشكل:** التسمية الجيدة لعقدة تجعل `DutyStatusAction.makePrimaryDriver` بدل `switchPrimary('switch-primary')`. الاسم الحالي **يقيد التصميم**: تغيير قيمة الخادم من `switch-primary` إلى `switch_to_primary` يجب أن يمسّ قيمة الـ enum — أو يدفع المطوّر لتغيير اسم الـ enum نفسه (وكل مستهلكيه)، وهو تغيير غير ضروري.
- **المبدأ المنتهك:** Naming as a design tool / Information hiding.
- **المالك الحالي:** العقدة. **المالك الصحيح:** التحويل (`wire`) يحدث حاليًا في المحوّل (`eld_unidentified_events_backend.dart:51`: `'tab': tab.wire`) — وهذا صحيح؛ المشكلة في اسم الـ enum نفسه وفي وصوله إلى presentation.
- **العواقب:** تعديل قيمة خادم = تعديل اسم كود في `presentation`. تهريب `backend/contracts` إلى UI.
- **التصحيح المقترح:** إعادة التسمية إلى أسماء سلوكية (`primaryDriverChange`, `legacySwitch`)، وإبقاء `wire` في المحوّل. ومنع استيراد `contracts/` من `presentation`.
- **الملفات ذات الصلة:** `contract_enums.dart`، `unidentified_events_page.dart`، `unidentified_events_provider.dart`، `codriver_repository_impl.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-025: `BackendAdapter` nullable + تحويل `null` إلى `StateError` في 13 مزوّدًا
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/core/backend_adapter.dart:28-31`
- **Evidence:**
```dart
// backend_adapter.dart:27-33
  // ==========================================================================
  // Contracts — all nullable (a backend may not support all features)
  // ==========================================================================

  AuthBackend? get auth;

  AccountBackend? get account;
```
والتحويل في كل مستهلك:
```dart
// backend_providers.dart:59-62
final authBackendProvider = Provider<AuthBackend>((ref) {
  final adapter = ref.watch(activeBackendProvider);
  return adapter.auth ?? (throw StateError('AuthBackend not supported by active adapter'));
});
```
(يتكرر في 13 مزوّدًا: 61، 66، 71، 76، 81، 86، 91، 96، 101، 106، 111، 116).
- **السلوك الحالي:** الـ nullability **ليست** مرونة بل **غياب أنواع**. كلا المحوّلين ينفّذ **كل** الـ 14 getter كغير-null (`eld_engine_adapter.dart:52-93`، `mock_adapter.dart:56-99`)، فالـ `?` **لا يتحقق أبدًا**.
- **لماذا هو مشكل:** (أ) كل واحد من الـ 14 عقدة محاط بـ `?` — الـ compiler يسمح لـ `adapter.dvir!` في أي مكان. (ب) الاستبدال بـ `StateError` في 13 مكانًا يعني أن الكود **لا يستطيع معرفة** ما هي العقود غير المدعومة إلا بالتشغيل. (ج) **الغموض مستخدم فعليًا**: لا يوجد أي عقدة تُرجع null، فالثنائية «قد لا يدعم» وهمية.
- **المبدأ المنتهك:** Sound nullability / Honest type signatures.
- **العواقب:** 13× `StateError` غير معالَج أثناء بناء شجرة Riverpod. `throw` داخل Provider body يُنتج خطأ تحميل، لا حالة خطأ قابلة للتعامل.
- **التصحيح المقترح:** إمّا (أ) **اجعلها غير nullable**: `required DvirBackend get dvir;`، وافصل `supports(...)` إن لزم. أو (ب) إن كانت النية فعلًا أن يدعم backend ناقصًا، فالمسؤول عن الاستدعاء يجب أن يفحص قبل الاعتماد. **الاقتراح (أ)** هو الأنظف ويحذف 13 `throw`.
- **الملفات ذات الصلة:** `backend_adapter.dart`، `backend_providers.dart`، `eld_engine_adapter.dart`، `mock_adapter.dart`
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
### ISSUE BACK-027: `BackendRegistry` (129 سطرًا) بلا أي مستهلك إنتاجي
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/core/backend_registry.dart:17`
- **Evidence:**
```dart
// backend_registry.dart:78-100
  /// The currently active adapter.
  ///
  /// This is what features access.
  BackendAdapter get active => _adapters[activeIdentity.id]!;

  /// Returns the adapter with the given [id], or `null` if missing.
  BackendAdapter? getById(String id) => _adapters[id];

  /// Returns the adapter matching the given [identity], or `null`.
  BackendAdapter? getByIdentity(BackendIdentity identity) =>
      _adapters[identity.id];

  /// All registered adapters.
  Iterable<BackendAdapter> get all => _adapters.values;

  /// Whether an adapter with the given [id] is registered.
  bool has(String id) => _adapters.containsKey(id);

  /// The number of registered adapters.
  int get length => _adapters.length;

  /// Whether this registry contains only a mock adapter.
  bool get isMockOnly => _adapters.values.every((a) => a.isMock);
```
الاستهلاك الوحيد في `lib/`:
```dart
// backend_providers.dart:27-29
final backendRegistryProvider = Provider<BackendRegistry>((ref) {
  return BackendRegistry.single(ref.watch(activeBackendProvider));
});
```
- **السلوك الحالي:** بحثت في `lib/` بالكامل: `BackendRegistry` يظهر **فقط** في `backend_registry.dart` و`backend_providers.dart:27-28`. **لا يوجد أي مستهلك لـ `backendRegistryProvider`**. أي: `getById`، `getByIdentity`، `all`، `has`، `length`، `isMockOnly`، `disposeAll` — **سبعة أعضاء، صفر استدعاء إنتاجي**. و`single()` (71) يُلغي تمامًا تعدد الـ adapters الذي تبرره الترويسة (10-13).
- **لماذا هو مشكل:** هذا هو السؤال المطلوب («هل `BackendAdapter`/`backend_registry` تجريد حقيقي أم زخرفي؟»): **الإجابة: `BackendAdapter` حقيقي و`BackendRegistry` زخرفة**. الأول مُستخدم فعليًا (13 getter تُستهلك في 13 provider)، والثاني مصنع لا يحتاجه أحد.
- **المبدأ المنتهك:** YAGNI / Dead abstraction.
- **العواقب:** 129 سطرًا + ملف اختبار معزول (`test/backend/core/backend_registry_test.dart`) تُصان بلا فائدة؛ توثيق يَعِد ("قد تحتاج عدة backends") لا يتحقق.
- **ملاحظة أمانة:** يوجد `test/backend/core/backend_registry_test.dart` (10 إشارات) — أي أنه **مُختبر في عزلة** لا مستهلَك. لذلك بدقة: ليس بلا أي استخدام، بل **بلا أي استخدام إنتاجي**.
- **التصحيح المقترح:** حذف `BackendRegistry` و`backendRegistryProvider` بالكامل، والاكتفاء بـ `activeBackendProvider` من النوع `BackendAdapter`. إن كان التوسع المستقبلي مرغوبًا، يُعاد إحياؤه عند الحاجة الفعلية.
- **الملفات ذات الصلة:** `backend_registry.dart`، `backend_providers.dart:27-29`، `backend_adapter.dart`
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
### ISSUE BACK-029: `EldEndpoints` مبني على `int`/`String` الخام بينما العقدة تستخدم Value Objects
- **Severity:** LOW
- **Category:** Architecture
- **Location:** `lib/backend/http/eld_endpoints.dart:53`
- **Evidence:**
```dart
// eld_endpoints.dart:53-55
  static String dailyLogDetails(int logId) => '/eld/daily-logs/$logId';
  /// الرد على تعديلات الناقل
  static String respondCarrierEdit(int logId, String editId) => '/eld/daily-logs/$logId/carrier-edits/$editId/respond';
```
و18 موقعًا آخر بنفس النمط (57، 59، 61، 63، 65، 67، 69، 73، 75، 88، 90، 98، 101، 105، 107، 109، 133، 135). بينما العقدة تستخدم:
```dart
// daily_logs_backend.dart:24
  Future<Result<RawJson>> getById(DailyLogId logId);
```
والاستدعاء يتطلب `.value` يدويًا في كل موقع:
```dart
// eld_daily_logs_backend.dart:49
      EldEndpoints.dailyLogDetails(logId.value),
```
- **السلوك الحالي:** طبقة الـ endpoints تتوقف عند النوع البدائي، والنقاط تتوقف عند value object. `domain/shared/value_objects.dart` (المستوردة في كل عقدة) **لا تُستخدم في بناء المسار**.
- **لماذا هو مشكل:** الفصل بين الطبقتين لا يبرّر تجاهل أنواع النطاق: `EldEndpoints` في طبقة `http/` (الأدنى) يستطيع استيراد `domain/shared` كما تفعل المحوّلات. النتيجة: **≈20 استدعاء `.value` يدوي**، ولكل منها فرصة نسيان. في DVIR مثلًا: `DvirId.value` في 3 مواضع (73، 88، 100) — احتمال خلط `dvirId.value` مع `statusId.value` في نفس الاستدعاء لا يلتقطه الـ compiler.
- **المبدأ المنتهك:** Type safety at boundaries.
- **العواقب:** أخطاء نوعية في وقت التشغيل لا وقت الترجمة.
- **التصحيح المقترح:** جعل `EldEndpoints` يقبل الأنواع المحاطة مباشرة بعد إضافة `toString()` تُعيد القيمة في `DailyLogId`/`DvirId`/`EditId`/`DutyStatusId` — عندها تُحذف كل استدعاءات `.value`.
- **الملفات ذات الصلة:** `eld_endpoints.dart`، `lib/domain/shared/value_objects.dart`، كل `eld_*_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-030: توثيق `AuthInterceptor` يبالغ في ضمان الذرّية عبر `await`
- **Severity:** LOW
- **Category:** Security
- **Location:** `lib/backend/http/interceptors/auth_interceptor.dart:68-73`
- **Evidence:**
```dart
// auth_interceptor.dart:68-76
    // P0 2B-1 — قراءة جلسة واحدة لكل طلب: كل ما بعدها متزامن بحت
    // داخل نفس الـ microtask (أحادي الخيط: لا تداخل ممكن)، فيكون قرار
    // الإرفاق والتحقق من المالك ذرياً بالنسبة لتغيرات الجلسة.
    AuthSession? session;
    try {
      session = await localDataSource.getSession();
    } catch (e) {
      AppLogger.error('AuthInterceptor failed to read session for $backendType: $e');
    }
```
- **السلوك الحالي:** التعليق يدّعي أن القراءة + «كل ما بعدها متزامن» تُنتج قرارًا ذريًا. لكن `await localDataSource.getSession()` **يُنهي الـ microtask**، فبين خروجه وعودته (قراءة Keystore = I/O غير متزامن) يمكن أن يتغيّر مراقب الجلسة.
- **لماذا هو مشكل:** **هذا ليس خطأً مؤكدًا** — بعد `await` يعود التنفيذ، وكل الأسطر التالية (80-115) متزامنة فعلًا، فالكود يفعل ما يقول. لكن الاعتماد على «أحادي الخيط» غير كافٍ حين تكون القراءة نفسها غير متزامنة: الضمان الصحيح هو **snapshot** لا **تنفيذ متزامن**. عمليًا الخطر محدود لأن `credentialGeneration` (59، 122-129) يلتقط جيل الاعتماد **قبل** الـ await — وهذا **يحل** الحالة الفعلية.
- **المبدأ المنتهك:** دقة التوثيق للضمانات (SOLID على مستوى التوثيق).
- **التقييم:** finding بصيغة **POTENTIAL** لا CONFIRMED كخلل أمني: الحماية الفعلية (`credGenKey`) سليمة ومُتحقَّق منها في `onError`. المشكلة **توصيفية**.
- **التصحيح المقترح:** إعادة صياغة التعليق 68-70 لتذكر أن الحماية الحقيقية هي `credGenKey` (المأخوذ قبل الـ await) و`epochKey`، وأن الذرّية بعد الـ await تسبقها خطوة snapshot فقط.
- **الملفات ذات الصلة:** `auth_interceptor.dart`، `lib/core/session/session_epoch.dart`
- **Confidence:** POTENTIAL


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-031: استثناء مسار إنشاء الجلسة بمقارنة `options.path == '/session'` لا يتحقق مع المسارات المطلقة
- **Severity:** MEDIUM
- **Category:** Security
- **Location:** `lib/backend/http/interceptors/auth_interceptor.dart:64`
- **Evidence:**
```dart
// auth_interceptor.dart:60-66
    // لا نستثني إلا نقطة إنشاء الجلسة نفسها؛ contains('/session') كانت
    // تخطّي أي مسار يحتوي الكلمة (مثل /eld/sessions/123/members).
    // (حُذف استثناء POST /users — لم يعد له مستدعٍ وكان يسمح بمرور
    // طلبات إنشاء مستخدمين بلا جلسة، توسيعاً غير مبرر لسطح الهجوم.)
    if (options.path == EldEndpoints.session) {
      return super.onRequest(options, handler);
    }
```
بينما الاستدعاءات تمرّ بمسارات مطلقة:
```dart
// eld_auth_backend.dart:29-31
      final response = await _apiClient.dio.post(
        '$baseUrl/api${EldEndpoints.session}',
        data: {'email': identifier, 'password': password},
```
```dart
// eld_auth_backend.dart:106-107
      final response = await _apiClient.dio.get(
        '$serverOrigin/api${EldEndpoints.session}',
```
```dart
// eld_auth_backend.dart:156
      await _apiClient.dio.delete('$serverOrigin/api${EldEndpoints.session}', options: options);
```
- **السلوك الحالي:** الشرط يقارن `options.path` بـ `'/session'` (نسبة). لكن في المسارات الثلاثة أعلاه، `path` المُمرَّر إلى `dio` هو `'$baseUrl/api/session'` — **مطلق** — فلا يساوي `'/session'` أبدًا.
- **الأثر الفعلي:** الاستثناء لا يتحقق في `login` ولا `validateSession` ولا `logout`. في `login` (30) لا نريد كوكيًا أصلًا — لكن `getSession()` ستُقرأ، وعندها تحاول الشيفرة إرفاق `JSESSIONID` القديم بـ cookie على **نفس المضيف** (لأن `requestHost == baseHost`)، فيُرسل مع طلب إنشاء جلسة جديد. نفس الشيء في `logout`: يُرفَق كوكي مع طلب الإبطال.
- **لماذا هو مشكل:** حارس أمني مكتوب بافتراض `path` نسبي بينما الاستدعاء الفعلي مختلط. هذا نمط هشّ: أول من يغيّر بناء العنوان إلى نسبي (أو يضيف مسارًا) ينكسر صامتًا.
- **المبدأ المنتهك:** Correctness of a security guard.
- **خطورة الأثر:** منخفضة عمليًا (نفس المضيف، والتشويش فقط)، لكن المبدأ معطوب.
- **التصحيح المقترح:** استخدام `options.uri.path.endsWith('/api/session')`، أو — الأنظف — `options.extra['skip_session'] = true` يضعه `EldAuthBackend` صراحةً بدل الاستدلال من المسار.
- **الملفات ذات الصلة:** `auth_interceptor.dart`، `eld_auth_backend.dart`، `eld_endpoints.dart:15`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-032: `request_logger` يطبع جسم الخطأ الخام بلا إخفاء (مقيّد بـ kDebugMode)
- **Severity:** LOW
- **Category:** Security
- **Location:** `lib/backend/http/interceptors/request_logger.dart:128-130`
- **Evidence:**
```dart
// request_logger.dart:96-130
    if (err.response?.data != null) {
      final data = err.response?.data;
      if (data is String) {
        ...
        } else {
          AppLogger.error('Data: ${data.length > 500 ? '${data.substring(0, 500)}...' : data}');
        }
      } else {
        AppLogger.error('Data: $data');
      }
    }
```
والإخفاء المطبَّق على الطلب والاستجابة:
```dart
// request_logger.dart:61-66
    if (response.data != null &&
        (response.requestOptions.uri.path.contains('/sessions') ||
            response.requestOptions.uri.path.contains('/drivers'))) {
      AppLogger.debug(
        '📦 Response data: ${_redactSensitiveData(response.data)}',
      );
    }
```
والتقييد بوضع التصحيح:
```dart
// backend_network_providers.dart:67
  if (kDebugMode) dio.interceptors.add(RequestLogger());
```
- **السلوك الحالي:** `RequestLogger` كله **مقيَّد بـ `kDebugMode`** (سطر 67) — وهذا **إنجاز أمني حقيقي**، لأن `AppLogger.error` يُكتب في الإنتاج (`logger.dart:30-32` يمرّر إلى `package:logger` الذي يُخرج `Level.info` فأعلى في release). **فلا يوجد تسرب PII في الإنتاج.**
- **لكن:** (أ) مسار `onError` (128-130) يطبع `$data` **بلا `_redactSensitiveData`** عندما يكون الجسم `Map` (وهو الافتراضي في Dio لـ JSON) — أي أن أجسام خطأ JSON تُطبع كما هي. (ب) `sensitiveKeys` (21-37) حجب **مفاتيح** فقط؛ قائمة `List<String>` أو نص خام يمرّ بلا حجب. (ج) شرط الاستجابة (61-63) يستهدف `/sessions` و`/drivers` — **أعلى مسارات PII** — بينما أجسام أخطاء DVIR/التفتيش/القيادة تُطبع بلا حجب.
- **لماذا هو مشكل:** في debug، على جهاز سائق في يد موظف، `flutter logs` يكشف أسماء وبيانات تشغيلية. ليس production leak لكنه **تسريب في بيئة التطوير/QA**.
- **المبدأ المنتهك:** Defense in depth.
- **العواقب:** كشف PII في سجلات التطوير؛ ضخامة السجلات (500 حرف لكل خطأ).
- **التصحيح المقترح:** (1) تمرير `_redactSensitiveData(err.response?.data)` في السطر 129. (2) توسيع `sensitiveKeys` بـ `'name','email','phone','license','vin','latitude','longitude','signature'`. (3) تخفيض سقف 500 إلى 200.
- **الملفات ذات الصلة:** `request_logger.dart`، `backend_network_providers.dart:67`، `core/utils/logger.dart:30`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-033: سلسلة ثقة الوقت بلا تحقق من القيمة ولا opt-out لكل طلب
- **Severity:** MEDIUM
- **Category:** Security
- **Location:** `lib/backend/http/interceptors/time_drift_interceptor.dart:38-66`
- **Evidence:**
```dart
// time_drift_interceptor.dart:50-65
    final lastServer = _lastServerUtc;
    final lastAnchor = _lastAnchorLocal;
    if (lastServer != null && lastAnchor != null) {
      final now = DateTime.now().toUtc();
      final expected = lastServer.add(now.difference(lastAnchor));
      final drift = serverUtc.difference(expected).abs();
      if (drift < _driftTolerance &&
          now.difference(lastAnchor) < _minResyncInterval) {
        return;
      }
    }

    timeProvider.anchor(serverUtc);
    _lastServerUtc = serverUtc;
    _lastAnchorLocal = DateTime.now().toUtc();
```
و`anchor()` نفسها بلا تحقق:
```dart
// core/time/trusted_time_provider.dart:107-113
  @override
  void anchor(DateTime serverUtc) {
    _trustedServerUtcAtSync = serverUtc.toUtc();
    _restoredFromDisk = false;
    _restoredAnchorUtc = null;
    _restoredDeviceWallMs = null;
```
والاعتراض مربوط بالـ Dio **المشترك** بلا استثناء:
```dart
// backend_network_providers.dart:69-71
  dio.interceptors.add(
    TimeDriftInterceptor(timeProvider: ref.read(trustedTimeProvider)),
  );
```
- **السلوك الحالي — أربع ثغرات في سلسلة الثقة:**
  1. **لا تحقق من القيمة إطلاقًا**: `anchor()` يقبل أي `DateTime`. خادم يُرجع `Date: Mon, 01 Jan 1990...` أو `Sat, 01 Jan 2050...` يُثبّت ساعة الامتثال. الفحص الوحيد هو **تكرار** (throttling)، لا **صحة**.
  2. **الاستجابة الأولى غير محمية**: عند `lastServer == null` (50-51) يُثبَّت أي وقت بلا مقارنة؛ منطق الـ drift (52-60) لا يعمل إلا بعد أول مرساة.
  3. **أي مضيف**: `EldAuthBackend.login` يرسل إلى **عنوان يختاره المستخدم** (`'$baseUrl/api${EldEndpoints.session}'`) على نفس الـ Dio، فـ `Date` من مضيف غير موثوق يثبّت ساعة HOS. لا يوجد `Options.extra` يمنع ذلك.
  4. **الاستجابات الخطأ تُعالَج عمدًا** (31-36) — وهذا منطقي (الفرصة الوحيدة للمعايرة)، لكنه يوسّع سطح الهجوم: خادم يرد `401` بترويسة `Date` خبيثة يثبّت الساعة.
- **لماذا هو مشكل:** `TrustedTimeProvider` **مرجع الامتثال** (تواريخ HOS تُوقَّع به). في نظام ELD، تلاعب بالوقت = تفتيش فاشل. وبنية `MonotonicTrustedTimeProvider` تُخزّن المرساة على القرص (`trusted_time_provider.dart:115-120`) وتستعيدها عند الإقلاع لأيام — أي أن **مرساة واحدة سيئة تفسد 7 أيام** (وهو ما يعلنه `state` في 93-95).
- **المبدأ المنتهك:** Trust chain / Least privilege / Input validation عند حدود الثقة.
- **المالك الحالي:** `TimeDriftInterceptor` + `MonotonicTrustedTimeProvider`. **المالك الصحيح:** `TrustedTimeProvider` يجب أن يكون **المُتحقِّق** (validate + clamp)، والاعتراض مجرّد ناقل.
- **العواقب:** استضافة خبيثة → إزاحة ساعة الامتثال لأيام → تواريخ سجلات HOS خاطئة → مخالفة تنظيمية.
- **التصحيح المقترح:** (1) في `MonotonicTrustedTimeProvider.anchor()`: رفض `serverUtc` إذا كان أبعد من ±24 ساعة عن `DateTime.now()` (باستثناء أول مزامنة صريحة)؛ (2) في `TimeDriftInterceptor`: تخطّي الاستجاعات التي `err.requestOptions.uri.host != baseUrl.host` (أو مسارات `login`)، إلا إذا كانت مزامنة صريحة؛ (3) إضافة حد أقصى للقفز الأمامي؛ (4) تسجيل `TrustedTimeState` بعد كل مرساة لتشخيصها.
- **الملفات ذات الصلة:** `time_drift_interceptor.dart`، `core/time/trusted_time_provider.dart`، `backend_network_providers.dart:69-71`، `eld_auth_backend.dart:30`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-034: `backend_network_providers.dart` يحتوي ميزةَين غير متعلقتين بالباك-إند ويكرّر منطق اختيار الموك
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/providers/backend_network_providers.dart:77-82`
- **Evidence:**
```dart
// backend_network_providers.dart:76-82
// Provider لعميل التتبع الخلفي (بديلاً عن trackingClientProvider)
final traccarNativeClientProvider = Provider<TraccarNativeClient>((ref) {
  if (AppEnvironmentConfig.current == AppEnvironment.mock) {
    return MockTraccarNativeClient();
  }
  return TraccarNativeClientImpl();
});
```
مقابل المنطق المركزي الحاضر في الملف المجاور:
```dart
// backend_providers.dart:38-43
  final choice = resolveRuntimeBackend(
    environment: AppEnvironmentConfig.current,
    buildBaseUrl: AppEnvironmentConfig.apiBaseUrl,
    savedServerUrl: ref.watch(serverUrlProvider),
    savedBackendType: prefs.backendType,
  );
```
- **السلوك الحالي:** `backend/providers` يحوي **اختيارًا ثلاثيًا** (`eldEngine` vs `mock`) في `activeBackendProvider` (36-53)، **واختيارًا ثنائيًا** (`mock` vs `TraccarNativeClientImpl`) هنا. عمليتان مختلفتان تمامًا خلف ملف واحد. والأهم: فحص `AppEnvironmentConfig.current == AppEnvironment.mock` **مكرَّر** هنا بينما `activeBackendProvider` يستخدم الدالة المركزية `resolveRuntimeBackend(...)`.
- **لماذا هو مشكل:** (أ) الملف اسمه `backend_network_providers` لكن الأسطر 11-13 تستورد `features/tracking/data/datasources/traccar_sdk/*` — فمزوّد تتبّع في مجلد الباك-إند. (ب) **منطقان مختلفان لاتخاذ نفس القرار** في نفس المجلد — وهذا مصدر خلاف مستقبلي (مثل `serverUrl` محفوظ: `resolveRuntimeBackend` يحترمه، والفحص المباشر هنا لا).
- **المبدأ المنتهك:** SRP على مستوى الملف + DRY في القرار.
- **العواقب:** `traccarNativeClientProvider` يجب أن يُنقل إلى `features/tracking/data/providers/`؛ خطر أن يختلف شرط الموك بين المسارين.
- **التصحيح المقترح:** نقل المزوّد إلى `features/tracking/data/providers/traccar_native_client_provider.dart` واستخدام `resolveRuntimeBackend(...)` بدل فحص `AppEnvironment` مباشرة.
- **الملفات ذات الصلة:** `backend_network_providers.dart`، `backend_providers.dart:38-43`، `core/config/runtime_selection.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-035: `mock` يعتمد على تحويلات `eld_engine` — الموك ليس بديلاً مستقلاً
- **Severity:** MEDIUM
- **Category:** Architecture
- **Location:** `lib/backend/adapters/mock/sub/mock_rules_screen_backend.dart:7-8`
- **Evidence:**
```dart
// mock_rules_screen_backend.dart:7-8
import '../../eld_engine/models/rules_screen_dto.dart';
import '../../eld_engine/mappers/rules_screen_mapper.dart';
```
```dart
// mock_daily_logs_backend.dart:5-6
import '../../eld_engine/models/certify_dto.dart';
import '../../eld_engine/models/readiness_dto.dart';
```
- **السلوك الحالي:** **4 ملفات** من مجلد `mock/` تستورد من مجلد `eld_engine/`. المحوّلان داخل نفس `BackendAdapter` لكن في فرعين مختلفين من الشجرة، وأحدهما يعتمد على الآخر.
- **لماذا هو مشكل:** الموك موجود ليختبر سلوكًا معزولًا عن المحرك الحقيقي. بجعل الموك يستخدم DTOات ومحوّل المحرك الحقيقي، صار: (1) الاختبار على الموك **لا يختبر العزل** بل يختبر المحرك عبر مسار بديل؛ (2) **تعديل DTO في `eld_engine` يكسر `mock`** — فالفصل البنيوي بين المحوّلين غير قائم؛ (3) الرسم البياني لطبقات الاعتمادية لم يعد شجريًا.
- **المبدأ المنتهك:** Parallel implementations / ISP.
- **العواقب:** إعادة استخدام DTOات (وهي الحل الصحيح لـ BACK-004) **ستُصلح** هذه المشكلة تلقائيًا، لأن DTO ستصبح في `contracts/dto/` ولا يبقى داعٍ للاستيراد العابر.
- **التصحيح المقترح:** نقل `certify_dto.dart`، `readiness_dto.dart`، `rules_screen_dto.dart`، `rules_screen_options.dart`، و`rules_screen_mapper.dart` إلى `lib/backend/contracts/dto/` + `lib/backend/contracts/mappers/` مشتركين. **تغيير واحد يحل BACK-004 و BACK-035 و BACK-002 جزئيًا.**
- **الملفات ذات الصلة:** `mock_rules_screen_backend.dart`، `mock_daily_logs_backend.dart`، `eld_engine/models/*`، `contracts/daily_logs_backend.dart`
- **Confidence:** CONFIRMED


--------------------------------------------------

--------------------------------------------------
### ISSUE BACK-036: `update_rules_use_case.dart` يرمي استثناءً داخل جسم Provider ويقرن العقد بالتخزين والمصادقة
- **Severity:** MEDIUM
- **Category:** Riverpod
- **Location:** `lib/features/account/application/usecases/update_rules_use_case.dart:52-61`
- **Evidence:**
```dart
// update_rules_use_case.dart:52-61
final updateRulesUseCaseProvider = Provider<UpdateRulesUseCase>((ref) {
  final backend = ref.watch(rulesScreenBackendProvider);
  final storage = ref.watch(localStorageProvider);
  final user = ref.watch(authStateProvider).user;
   
  if (user == null) {
    throw Exception('User not authenticated');
  }

  return UpdateRulesUseCase(backend, storage, user.id);
});
```
- **السلوك الحالي:** الـ use-case (طبقة `application`) يحتجز **ثلاثة** اعتمادات: العقد + التخزين + المصادقة، ويُرمى استثناء عند غياب المستخدم.
- **لماذا هو مشكل:** (أ) `throw Exception(...)` داخل `Provider` body = خطأ **بناء شجرة Riverpod**، لا حالة خطأ قابلة للاستخدام في الواجهة؛ كل `ref.watch(updateRulesUseCaseProvider)` في وقت غير مصادَق يرمي. (ب) اقتران `localStorageProvider` و`authStateProvider` داخل use-case يخلط «منطق حالة القاعدة» بـ«منطق الجلسة والتخزين» — SRP.
- **المبدأ المنتهك:** Riverpod best practices (لا ترمي من Provider body)، SRP.
- **العواقب:** شاشة إعدادات القاعدة تنهار بدل أن تعرض «سجّل الدخول».
- **التصحيح المقترح:** جعل `UpdateRulesUseCase` يعتمد على `AuthState` (nullable) أو على `DriverId` اختياري، وتحويل غياب المستخدم إلى `Either<Failure, ...>` بدل `throw`.
- **الملفات ذات الصلة:** `update_rules_use_case.dart`، `rules_screen_backend.dart`، `core/di/core_providers.dart`
- **Confidence:** CONFIRMED

---

## C. جدول تناظر العقود (`eld_engine` مقابل `mock`)

**إجمالي دوال العقد: 58.** كل صف = دالة عقد واحدة.
«✅» = يُرجع قيمة `Result` صحيحة | «❌» = `throw UnimplementedError` | «⚠️» = منفَّذ لكن بتناظر دلالي/شكلي مختلف.

| العقد | الدالة | `eld_engine` | `mock` | حالة التناظر |
|---|---|---|---|---|
| **AuthBackend**<br>4/4 ✅ | `login` | `eld_auth_backend.dart:17` | `mock_auth_backend.dart:9` ✅ | تناظر تام — نفس المفاتيح `credential/user/serverOrigin` |
| | `validateSession` | `eld_auth_backend.dart:100` | `mock_auth_backend.dart:23` ✅ | تناظر تام |
| | `logout` | `eld_auth_backend.dart:142` | `mock_auth_backend.dart:36` ✅ | تناظر تام |
| | `requestPasswordReset` | `eld_auth_backend.dart:165` | `mock_auth_backend.dart:45` ✅ | تناظر تام |
| **AccountBackend**<br>2/2 ✅ | `getMyAccount` | `eld_account_backend.dart:51` | `mock_account_backend.dart:15` ⚠️ | الموك لا يطبّق `_mapAccountJson` (BACK-019) |
| | `updatePreferences` | `eld_account_backend.dart:64` | `mock_account_backend.dart:20` ⚠️ | نفس الملاحظة |
| **DailyLogsBackend**<br>7/11 ✅ | `list` | `eld_daily_logs_backend.dart:17` | `mock_daily_logs_backend.dart:14` ✅ | تناظر شكلي |
| | `getById` | `eld_daily_logs_backend.dart:47` | `mock_daily_logs_backend.dart:51` ❌ | `UnimplementedError` |
| | `getTeamStatus` | `eld_daily_logs_backend.dart:56` | `mock_daily_logs_backend.dart:55` ✅ | تناظر |
| | `respondToCarrierEdit` | `eld_daily_logs_backend.dart:65` | `mock_daily_logs_backend.dart:67` ✅ | تناظر |
| | `certify` | `eld_daily_logs_backend.dart:83` | `mock_daily_logs_backend.dart:77` ✅ | تناظر (يستورد DTO المحرك — BACK-035) |
| | `reassignDriving` | `eld_daily_logs_backend.dart:97` | `mock_daily_logs_backend.dart:89` ✅ | تناظر |
| | `getForm` | `eld_daily_logs_backend.dart:114` | `mock_daily_logs_backend.dart:99` ❌ | `UnimplementedError` |
| | `saveForm` | `eld_daily_logs_backend.dart:123` | `mock_daily_logs_backend.dart:103` ❌ | `UnimplementedError` |
| | `getGraphGrid` | `eld_daily_logs_backend.dart:138` | `mock_daily_logs_backend.dart:111` ✅ | تناظر |
| | `lock` | `eld_daily_logs_backend.dart:147` | `mock_daily_logs_backend.dart:115` ❌ | `UnimplementedError` |
| | `getReadiness` | `eld_daily_logs_backend.dart:155` | `mock_daily_logs_backend.dart:119` ✅ | تناظر |
| **DriverSessionBackend**<br>1/5 ✅ | `getActiveSession` | `eld_driver_session_backend.dart:17` | `mock_driver_session_backend.dart:13` ❌ | `UnimplementedError` |
| | `getAvailableDrivers` | `eld_driver_session_backend.dart:39` | `mock_driver_session_backend.dart:24` ✅ | الموك `[]` دائمًا |
| | `getCurrentCoDriver` | `eld_driver_session_backend.dart:26` | `mock_driver_session_backend.dart:19` ❌ | `UnimplementedError` («no invented co-driver») |
| | `connect` | `eld_driver_session_backend.dart:50` | `mock_driver_session_backend.dart:29` ❌ | `UnimplementedError` |
| | `switchPrimaryDriver` | `eld_driver_session_backend.dart:66` | `mock_driver_session_backend.dart:36` ❌ | `UnimplementedError` |
| **DutyStatusBackend**<br>4/5 ✅ | `record` | `eld_duty_status_backend.dart:15` | `mock_duty_status_backend.dart:12` ⚠️ | **`DateTime.now()` ⇒ غير حتمي** (BACK-021) |
| | `update` | `eld_duty_status_backend.dart:25` | `mock_duty_status_backend.dart:16` ⚠️ | نفس الملاحظة |
| | `getGraphGrid` | `eld_duty_status_backend.dart:38` | `mock_duty_status_backend.dart:23` ❌ | `UnimplementedError` |
| | `submitLegacyDutyStatusEvent` | `eld_duty_status_backend.dart:54` | `mock_duty_status_backend.dart:30` ✅ | تناظر |
| | `submitLegacyGenericEvent` | `eld_duty_status_backend.dart:73` | `mock_duty_status_backend.dart:39` ✅ | تناظر |
| **DvirBackend**<br>6/8 ✅ | `list` | `eld_dvir_backend.dart:16` | `mock_dvir_backend.dart:12` ⚠️ **❗** | **شكل مختلف: `'data'` vs `'reports'`** (BACK-008) |
| | `create` | `eld_dvir_backend.dart:52` | `mock_dvir_backend.dart:24` ✅ | تناظر (`ok(null)`) |
| | `getById` | `eld_dvir_backend.dart:71` | `mock_dvir_backend.dart:32` ❌ | `UnimplementedError` |
| | `review` | `eld_dvir_backend.dart:82` | `mock_dvir_backend.dart:38` ❌ | `UnimplementedError` |
| | `getDefectsCatalog` | `eld_dvir_backend.dart:104` | `mock_dvir_backend.dart:46` ✅ | تناظر (11 عنصرًا) |
| | `getPreviousDvir` | `eld_dvir_backend.dart:113` | `mock_dvir_backend.dart:63` ✅ | تناظر |
| | `getDefectDetails` | `eld_dvir_backend.dart:122` | `mock_dvir_backend.dart:68` ✅ | تناظر (`{}` فارغ) |
| | `getVehicleDefects` | `eld_dvir_backend.dart:131` | `mock_dvir_backend.dart:72` ✅ | تناظر |
| **HardwareBackend**<br>3/6 ✅ | `getAlerts` | `eld_hardware_backend.dart:20` | `mock_hardware_backend.dart:12` ❌ | `async`-throw (BACK-022) |
| | `setManualMode` | `eld_hardware_backend.dart:30` | `mock_hardware_backend.dart:17` ✅ | تناظر |
| | `getReadiness` | `eld_hardware_backend.dart:51` | `mock_hardware_backend.dart:30` ✅ | تناظر |
| | `connectSession` | `eld_hardware_backend.dart:68` | `mock_hardware_backend.dart:51` ❌ | `async`-throw |
| | `getStatus` | `eld_hardware_backend.dart:85` | `mock_hardware_backend.dart:59` ❌ **❗** | `async`-throw ⇒ **انهيار `hardwareStatusProvider`** |
| | `sendTelemetry` | `eld_hardware_backend.dart:106` | `mock_hardware_backend.dart:67` ✅ | تناظر |
| **InspectionBackend**<br>3/8 ✅ | `getScreen` | `eld_inspection_backend.dart:17` | `mock_inspection_backend.dart:14` ✅ | الموك يعلن `canStart/canSend/canEmail/canView = false` بوعي |
| | `getCycle` | `eld_inspection_backend.dart:34` | `mock_inspection_backend.dart:43` ✅ | تناظر |
| | `getLogs` | `eld_inspection_backend.dart:59` | `mock_inspection_backend.dart:87` ✅ | تناظر (مع تخزين في الذاكرة) |
| | `emailLogs` | `eld_inspection_backend.dart:103` | `mock_inspection_backend.dart:152` ❌ | `UnimplementedError` |
| | `getInformationPacket` | `eld_inspection_backend.dart:128` | `mock_inspection_backend.dart:164` ❌ | `UnimplementedError` |
| | `sendLogs` | `eld_inspection_backend.dart:139` | `mock_inspection_backend.dart:168` ❌ | `UnimplementedError` |
| | `startInspection` | `eld_inspection_backend.dart:166` | `mock_inspection_backend.dart:181` ❌ | `UnimplementedError` |
| | `getTransfers` | `eld_inspection_backend.dart:185` | `mock_inspection_backend.dart:192` ❌ | `UnimplementedError` |
| **RulesScreenBackend**<br>2/2 ✅ | `getRulesScreen` | `eld_rules_screen_backend.dart:18` | `mock_rules_screen_backend.dart:55` ✅ | تناظر — لكن كلاهما يمرّ بـ `eld_engine` DTO+mapper (BACK-035) |
| | `saveRulesScreen` | `eld_rules_screen_backend.dart:28` | `mock_rules_screen_backend.dart:61` ✅ | تناظر |
| **SignatureBackend**<br>1/1 ⚠️ | `save` | `eld_signature_backend.dart:18` | `mock_signature_backend.dart:19` ⚠️ **❗** | **تباين تام**: المحرك يُرجع `err` دائمًا، الموك يُصدر شهادة. **ولا يوجد provider ولا مستهلك للاثنتين** (BACK-013) |
| **StatusDashboardBackend**<br>3/3 ✅ | `getDashboard` | `eld_status_dashboard_backend.dart:21` | `mock_status_dashboard_backend.dart:29` ✅ | تناظر كامل — نماذج domain مُحاطة |
| | `updateDutyStatus` | `eld_status_dashboard_backend.dart:37` | `mock_status_dashboard_backend.dart:34` ✅ | تناظر كامل |
| | `getWeeklyRecap` | `eld_status_dashboard_backend.dart:95` | `mock_status_dashboard_backend.dart:43` ✅ | تناظر كامل |
| **UnidentifiedEventsBackend**<br>**0/3** ❗ | `list` | `eld_unidentified_events_backend.dart:43` | `mock_unidentified_events_backend.dart:13` ❌ | `UnimplementedError` |
| | `claim` | `eld_unidentified_events_backend.dart:61` | `mock_unidentified_events_backend.dart:23` ❌ | `UnimplementedError` |
| | `reject` | `eld_unidentified_events_backend.dart:73` | `mock_unidentified_events_backend.dart:31` ❌ | `UnimplementedError` |
| **VehicleBackend**<br>2/2 ✅ | `getCompanyFleet` | `eld_vehicle_backend.dart:19` | `mock_vehicle_backend.dart:14` ✅ | تناظر — كلاهما `{'data': []}` |
| | `getMyVehicles` | `eld_vehicle_backend.dart:34` | `mock_vehicle_backend.dart:18` ✅ | تناظر |

### ملخص التناظر

| المقياس | القيمة |
|---|---|
| إجمالي دوال العقد | **58** |
| منفَّذة بالكامل في الموك | **36** (62%) |
| `throw UnimplementedError` في الموك | **22** (38%) — BACK-020 |
| عقود بنسبة تنفيذ 0% | **1** من 13 (`UnidentifiedEventsBackend`) |
| عقود بنسبة تنفيذ 100% | **5** من 13 (`AuthBackend`, `VehicleBackend`, `RulesScreenBackend`, `StatusDashboardBackend`, `AccountBackend` تنازليًا) |
| دوال بتباين **دلالي صامت** (تنجح لكن بشكل مختلف) | **3**: `DvirBackend.list` (❗ BACK-008)، `DutyStatusBackend.record/update` (BACK-021)، `AccountBackend.*` (BACK-019) |
| دوال بتباين **كامل** | **1**: `SignatureBackend.save` (❗ BACK-013، وهي ميتة أصلًا) |
| getterات في `BackendAdapter` بلا `Provider` | **1 من 14**: `signature` (BACK-013) |
| صنف في `MockAdapter` بلا تنفيذ جوهري | **1**: `MockSignatureBackend` (49 سطرًا منطق لا يُستدعى) |

**الحكم على التماثل:** المحوّلان **متماثلان على مستوى التوقيع** (كل الـ 13 عقدة تُنفَّذ في `MockAdapter`، ولا يوجد getter ناقص — عدا `signature` الميت في الاثنين). لكن **التناظر على مستوى السلوك ضعيف**: 38% من الدوال ترمي استثناءً، و3 دوال «تنجح» بشكل مختلف دون أن يعلم أحد.

---

## D. ملاحظات عبر الملفات

### D.1 — طبقات تستهلك `lib/backend/contracts/` (نتيجة بحث نصي على `lib/` بالكامل)
| الملف | السطر | نوع الطبقة | العقد المستورد | الحكم |
|---|---|---|---|---|
| `features/codriver/data/repositories/codriver_repository_impl.dart` | 8, 9 | data | `contract_enums`, `driver_session_backend` | ✅ صحيح |
| `features/codriver/data/providers/codriver_repository_providers.dart` | 3 | data | `driver_session_backend` | ✅ صحيح |
| `features/inspection/data/repositories/inspection_repository_impl.dart` | 9, 10 | data | `inspection_backend`, `contract_enums` | ✅ صحيح |
| `features/vehicle/data/repositories/vehicle_repository_impl.dart` | 8, 9 | data | `raw_json`, `vehicle_backend` | ⚠️ يستورد `raw_json` مباشرة (BACK-001) |
| `features/vehicle/data/providers/vehicle_repository_providers.dart` | 3 | data | `vehicle_backend` | ✅ صحيح |
| `features/dvir/data/repositories/dvir_repository_impl.dart` | 14, 15 | data | `dvir_backend`, `raw_json` | ⚠️ + يستورد `eld_engine` DTO (BACK-007) |
| **`features/hos/domain/engine/tracking/duty_status_tracker.dart`** | **13** | **domain** | `status_dashboard_backend` | ❌ **انقلاب طبقة** (BACK-001) |
| `features/hos/data/repositories/status_dashboard_repository_impl.dart` | 2 | data | `status_dashboard_backend` | ✅ صحيح |
| `features/sync/data/repositories/traccar_remote_event_dispatcher.dart` | 9, 11, 12, 13, 14 | data | 4 عقود | ✅ صحيح |
| `features/auth/data/repositories/auth_repository_impl.dart` | 11 | data | `auth_backend` | ✅ صحيح |
| **`features/logs/presentation/pages/unidentified_events_page.dart`** | **6** | **presentation** | `contract_enums` | ❌ **خرق** (BACK-024) |
| **`features/logs/presentation/providers/unidentified_events_provider.dart`** | **3** | **presentation** | `contract_enums` | ❌ **خرق** (BACK-024) + يستدعي العقد مباشرة (BACK-023) |
| `features/logs/data/repositories/log_repository_impl.dart` | 12, 13 | data | `daily_logs_backend`, `duty_status_backend` | ✅ صحيح |
| **`features/account/presentation/providers/account_provider.dart`** | **3** | **presentation** | `account_backend` | ❌ **خرق** (BACK-023) |
| `features/account/application/usecases/update_rules_use_case.dart` | 3 | application | `rules_screen_backend` | ⚠️ مقبول (use-case يعتمد على port)، لكن `throw` في Provider body (BACK-036) |

**الخلاصة:** 15 ملفًا. **10 منها في `data`** (الصحيح). **1 في `domain`** (انقلاب مؤكد). **1 في `application`** (مقبول). **3 في `presentation`** (خرق مؤكد).

### D.2 — الحواف المعكوسة من `lib/backend` إلى `lib/features` (سجل كامل)
| الملف | السطر | العمود المستورد | نوع الخرق |
|---|---|---|---|
| `contracts/rules_screen_backend.dart` | 3 | `features/account/application/models` | layer inversion |
| `adapters/eld_engine/sub/eld_rules_screen_backend.dart` | 3 | `features/account/application/models` | layer inversion |
| `adapters/eld_engine/mappers/rules_screen_mapper.dart` | 1 | `features/account/application/models` | layer inversion |
| `adapters/mock/sub/mock_rules_screen_backend.dart` | 4 | `features/account/application/models` | layer inversion |
| `http/interceptors/auth_interceptor.dart` | 2 | `features/auth/**data**` | concrete dependency (الأخطر) |
| `http/interceptors/auth_interceptor.dart` | 3 | `features/auth/domain/entities` | عديم الخطر نسبيًا |
| `providers/backend_network_providers.dart` | 11-13 | `features/tracking/data/datasources/traccar_sdk` | misplaced feature |

**لا يوجد import دائري حقيقي داخل `lib/backend`** — تحققت من الرسم البياني: `contracts → adapters/eld_engine/models` ثم `models → (لا شيء)`، و`adapters/mock → adapters/eld_engine` ثم `eld_engine → contracts`؟ لا: `eld_engine/sub/*` يستورد `contracts/*`، و`contracts/*` لا يستورد أي `sub/*`. لذلك لا دورة import فعلية؛ المشكلة **اتجاه** وليس **دورة**.

### D.3 — إجابات مباشرة على أسئلة التدقيق المطلوبة

**س: هل تتسرّب أنواع Dio أو رموز HTTP أو أشكال JSON أو أسماء حقول خاصة بالـ backend إلى كود النطاق؟**
- **أنواع Dio: لا.** صفر استيراد لـ `package:dio` في أي ملف تحت `lib/backend/contracts/` (تحققت بقراءة الـ 15 ملفًا كاملة). ✅
- **رموز HTTP: نعم، بشكل مقبول.** `eld_endpoints.dart` مصدر واحد منظَّم للمسارات، والاستخدام محصور في مجلد `adapters/`. لكن `expectedOwnerDriverId` (سياسة جدولة) تسرّب إلى 4 عقد (BACK-012).
- **أسماء حقول الخادم: نعم، وبشكل واسع.** `contract_enums.dart` (5 enums بـ`wire`)، `AuthBackend` (`credential/user/serverOrigin`)، `RawJson` (37 موضع استيراد). **CONFIRMED**.
- **كم الترجمة الفعلية في المappers؟** من الـ 58 دالة عقد: **12 ترجع نوعًا مُحاطًا** (3 account/status_dashboard/signature + 3 inspection + 2 daily_logs + 1 rules_screen + …) أي **≈21% ترجمة حقيقية**، والباقي تمرير خام. المappers المجردة (`status_dashboard_mapper.dart` 215 سطرًا، `dot_inspection_mapper.dart` 151، `rules_screen_mapper.dart` 33) ممتازة في عملها؛ المشكلة في **تغطيتها** لا في **جودتها**.

**س: هل التجريد (`BackendAdapter` / `backend_registry`) حقيقي أم زخرفي؟**
- `BackendAdapter`: **حقيقي**. مُستهلك في 13 provider (`backend_providers.dart:60-116`)، وله استبدال فعلي في `activeBackendProvider` (45-52). لكن **بنيته متكسرة**: 14 getter كلها `?` مع تحويل `null → StateError` في 13 مكانًا (BACK-025)، و`signature` بلا provider (BACK-013).
- `BackendRegistry`: **زخرفة**. 129 سطرًا، **7 أعضاء بلا أي استدعاء إنتاجي**، والمصنع المستخدم هو `single()` الذي يلغي التعدّد (BACK-027).

**س: هل يوجد ازدواج في base-URL / endpoint / timeout بين `lib/backend/http/api_config.dart` و`lib/core/network/api_config.dart`؟**
- **لا.** الملف في `backend/http/` **كله تعليقات** (7 أسطر) ولا يستورده أي كود. تم اقتباس الملفين بالكامل في BACK-028.
- **الازدواج الحقيقي في مكان آخر**: تطبيع URL **3 نسخ** عبر طبقتين (`BACK-026`). أما الـ endpoints (مصدر واحد) والـ timeouts (مصدر واحد) فسليمان.

**س: هل `contracts/*` تكشف raw JSON / Map / dynamic للمستهلكين، وهل يتسرّب إلى domain/UI؟**
- **نعم في 11 من 13 عقدة**، ويوجد `List<dynamic>` إضافي في `driver_session_backend.dart:12`.
- **التسرّب مؤكَّد إلى طبقتين**: `domain` (ملف واحد، BACK-001) و`presentation` (7 مواقع، BACK-001 + BACK-023).

**س: هلتفوّق بين `eld_engine` و`mock`؟**
- على مستوى التوقيع: **لا** (13/13 عقدة، 14 getter مع `signature`).
- على مستوى التنفيذ: **نعم، حادًا** — 22/58 دالة ترمي (BACK-020).
- على مستوى شكل البيانات: **نعم، بصمت** — `DvirBackend.list` (BACK-008).

### D.4 — أنماط ثابتة تستحق إشادة (للتوازن)
1. **`mappers/json_primitives.dart`**: توحيد يدوي لمساعدة كانت مكرّرة في ملفين. قرار عالٍ الجودة.
2. **`mappers/hardware_mapper.dart`**: 27 سطرًا، مسؤولية واحدة، تحويل وحدات موثّق. مثال للمعيار.
3. **`sub/eld_account_backend.dart`**: `_mapAccountJson` ترجمة حقيقية تحل انحرافات الـ wire داخل المحوّل — بالضبط ما يجب أن يفعله mapper.
4. **`contracts/status_dashboard_backend.dart`**: أنقى عقدة في المشروع (0 `RawJson`، 0 Dio، 0 نص).
5. **`sub/eld_auth_backend.dart` + `auth_interceptor.dart`**: تعامل ناضج مع `JSESSIONID` ككوكي (لا Bearer)، حماية من التسريب عبر الأصول (106)، ومعالجة 401 بثلاثة أجيال. موثّق بالعربية وبتعليقات تُشرح «لماذا».
6. **`sub/mock_inspection_backend.dart:30-35`**: تعليق يشرح قرارًا تصميميًا صعبًا (إعلان `false` بدل `true` للأزرار غير المنفَّذة). هذا بالضبط ما يجب أن يُكتب.
7. **`RequestLogger` مقيَّد بـ `kDebugMode`** (`backend_network_providers.dart:67`) — يمنع تسرب PII في الإنتاج رغم أن `AppLogger.error` يُكتب في release.
8. **`AuthInterceptor` يرفض الإرسال تحت جلسة مختلفة قبل مغادرة أي بايت** (87-98) — سلوك تنفيذي نادر ودقيق.

### D.5 — نمط متكرر: `parser: (data) => data is Map<String, dynamic> ? data : {}`
هذا اللمboa يتكرر **20+ مرة** عبر `eld_daily_logs_backend.dart`، `eld_dvr_backend.dart`، `eld_duty_status_backend.dart`، `eld_hardware_backend.dart`، `eld_vehicle_backend.dart`. تأثيره:
- **يمحو كل انحرافات الـ wire بصمت**: جسم من نوع `List` أو `String` يُستبدل بـ `{}`، فيُبلَّغ， المستهلك كـ «نجاح» بجسم فارغ. مثال ملموس: `eld_daily_logs_backend.dart:41` يحوّل `List` إلى `{'data': data}` — لكن `eld_dvir_backend.dart:34` يفعل الشيء نفسه. هذا يعني أن **`RawJson` لا يحمل أي ضمان شكل**، وهو ما جعل BACK-008 ممكنًا.
- التوصية: مصدر مشترك `coerceToMap` (BACK-015) +، الأهم، **استبدال `RawJson` بنوع مُحاط** (BACK-001).

### D.6 — ترتيب الإصلاح المقترح (حسب الأثر ÷ الجهد)
1. **نقل DTOات إلى `contracts/dto/`** → يحل BACK-004 + BACK-035 + يزيح جزءًا من BACK-002. (جهد صغير، أثر معماري كبير.)
2. **إضافة `signatureBackendProvider` أو حذف العقدة** → يحسم BACK-013 (لا ambiguitiy).
3. **حذف `BackendRegistry`** + إضافة `signature` للنطاق الصحيح + توحيد `SessionStore` → يحل BACK-027 + BACK-009.
4. **توحيد `url` في `ApiConfig`** → يحل BACK-026 + يبسّط BACK-011.
5. **حظر `RawJson` في `presentation` عبر lint** → يمنع توسّع BACK-001 قبل إصلاحه جذريًا.
6. **اختبار تناظر آلي + تغيير `throw` إلى `err`** → يحل BACK-020 ويحوّل الرقم في القسم C إلى مؤشر أداء مُراقَب.
7. **نقل `RulesScreenModel` إلى `domain`** + `SessionStore` → BACK-002.
8. **التحقق من `anchor()` + opt-out للمسارات الخارجية** → BACK-033 (الأمان، لكنه أقل انتشارًا).

---

## E. قائمة شاملة بالملفات التي قُرئت (إثبات التغطية)

**عدد الملفات: 66/66 — تغطية 100%.**
الأرقام: `N` = إجمالي الأسطر، `M` = الأسطر غير الفارغة.

### `lib/backend/adapters/eld_engine/` (24 ملفًا)
| # | المسار | N | M |
|---|---|---|---|
| 1 | `lib/backend/adapters/eld_engine/eld_engine_adapter.dart` | 118 | 97 |
| 2 | `lib/backend/adapters/eld_engine/mappers/dot_inspection_mapper.dart` | 151 | 135 |
| 3 | `lib/backend/adapters/eld_engine/mappers/hardware_mapper.dart` | 27 | 23 |
| 4 | `lib/backend/adapters/eld_engine/mappers/json_primitives.dart` | 72 | 64 |
| 5 | `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart` | 33 | 32 |
| 6 | `lib/backend/adapters/eld_engine/mappers/status_dashboard_mapper.dart` | 215 | 188 |
| 7 | `lib/backend/adapters/eld_engine/models/certify_dto.dart` | 50 | 45 |
| 8 | `lib/backend/adapters/eld_engine/models/dvir_dto.dart` | 432 | 401 |
| 9 | `lib/backend/adapters/eld_engine/models/readiness_dto.dart` | 86 | 81 |
| 10 | `lib/backend/adapters/eld_engine/models/rules_screen_dto.dart` | 103 | 94 |
| 11 | `lib/backend/adapters/eld_engine/models/rules_screen_options.dart` | 29 | 29 |
| 12 | `lib/backend/adapters/eld_engine/sub/eld_account_backend.dart` | 81 | 72 |
| 13 | `lib/backend/adapters/eld_engine/sub/eld_auth_backend.dart` | 200 | 183 |
| 14 | `lib/backend/adapters/eld_engine/sub/eld_daily_logs_backend.dart` | 162 | 149 |
| 15 | `lib/backend/adapters/eld_engine/sub/eld_driver_session_backend.dart` | 92 | 85 |
| 16 | `lib/backend/adapters/eld_engine/sub/eld_duty_status_backend.dart` | 89 | 82 |
| 17 | `lib/backend/adapters/eld_engine/sub/eld_dvir_backend.dart` | 138 | 124 |
| 18 | `lib/backend/adapters/eld_engine/sub/eld_hardware_backend.dart` | 114 | 101 |
| 19 | `lib/backend/adapters/eld_engine/sub/eld_inspection_backend.dart` | 195 | 182 |
| 20 | `lib/backend/adapters/eld_engine/sub/eld_rules_screen_backend.dart` | 51 | 46 |
| 21 | `lib/backend/adapters/eld_engine/sub/eld_signature_backend.dart` | 34 | 31 |
| 22 | `lib/backend/adapters/eld_engine/sub/eld_status_dashboard_backend.dart` | 126 | 119 |
| 23 | `lib/backend/adapters/eld_engine/sub/eld_unidentified_events_backend.dart` | 83 | 75 |
| 24 | `lib/backend/adapters/eld_engine/sub/eld_vehicle_backend.dart` | 47 | 42 |

### `lib/backend/adapters/mock/` (15 ملفًا)
| # | المسار | N | M |
|---|---|---|---|
| 25 | `lib/backend/adapters/mock/mock_adapter.dart` | 109 | 87 |
| 26 | `lib/backend/adapters/mock/fixtures/account_fixtures.dart` | 65 | 63 |
| 27 | `lib/backend/adapters/mock/sub/mock_account_backend.dart` | 30 | 27 |
| 28 | `lib/backend/adapters/mock/sub/mock_auth_backend.dart` | 51 | 46 |
| 29 | `lib/backend/adapters/mock/sub/mock_daily_logs_backend.dart` | 131 | 119 |
| 30 | `lib/backend/adapters/mock/sub/mock_driver_session_backend.dart` | 44 | 38 |
| 31 | `lib/backend/adapters/mock/sub/mock_duty_status_backend.dart` | 45 | 39 |
| 32 | `lib/backend/adapters/mock/sub/mock_dvir_backend.dart` | 74 | 63 |
| 33 | `lib/backend/adapters/mock/sub/mock_hardware_backend.dart` | 70 | 63 |
| 34 | `lib/backend/adapters/mock/sub/mock_inspection_backend.dart` | 195 | 182 |
| 35 | `lib/backend/adapters/mock/sub/mock_rules_screen_backend.dart` | 72 | 68 |
| 36 | `lib/backend/adapters/mock/sub/mock_signature_backend.dart` | 49 | 41 |
| 37 | `lib/backend/adapters/mock/sub/mock_status_dashboard_backend.dart` | 191 | 178 |
| 38 | `lib/backend/adapters/mock/sub/mock_unidentified_events_backend.dart` | 39 | 35 |
| 39 | `lib/backend/adapters/mock/sub/mock_vehicle_backend.dart` | 21 | 17 |

### `lib/backend/contracts/` (15 ملفًا)
| # | المسار | N | M |
|---|---|---|---|
| 40 | `lib/backend/contracts/account_backend.dart` | 17 | 15 |
| 41 | `lib/backend/contracts/auth_backend.dart` | 29 | 25 |
| 42 | `lib/backend/contracts/contract_enums.dart` | 51 | 41 |
| 43 | `lib/backend/contracts/daily_logs_backend.dart` | 72 | 61 |
| 44 | `lib/backend/contracts/driver_session_backend.dart` | 31 | 25 |
| 45 | `lib/backend/contracts/duty_status_backend.dart` | 35 | 30 |
| 46 | `lib/backend/contracts/dvir_backend.dart` | 50 | 39 |
| 47 | `lib/backend/contracts/hardware_backend.dart` | 37 | 31 |
| 48 | `lib/backend/contracts/inspection_backend.dart` | 65 | 56 |
| 49 | `lib/backend/contracts/raw_json.dart` | 10 | 9 |
| 50 | `lib/backend/contracts/rules_screen_backend.dart` | 15 | 13 |
| 51 | `lib/backend/contracts/signature_backend.dart` | 13 | 12 |
| 52 | `lib/backend/contracts/status_dashboard_backend.dart` | 20 | 17 |
| 53 | `lib/backend/contracts/unidentified_events_backend.dart` | 27 | 24 |
| 54 | `lib/backend/contracts/vehicle_backend.dart` | 12 | 9 |

### `lib/backend/core/` (4 ملفات)
| # | المسار | N | M |
|---|---|---|---|
| 55 | `lib/backend/core/backend_adapter.dart` | 61 | 42 |
| 56 | `lib/backend/core/backend_identity.dart` | 94 | 81 |
| 57 | `lib/backend/core/backend_kind.dart` | 19 | 17 |
| 58 | `lib/backend/core/backend_registry.dart` | 129 | 111 |

### `lib/backend/http/` (6 ملفات)
| # | المسار | N | M |
|---|---|---|---|
| 59 | `lib/backend/http/api_config.dart` | 7 | 6 |
| 60 | `lib/backend/http/api_response.dart` | 7 | 6 |
| 61 | `lib/backend/http/eld_endpoints.dart` | 150 | 137 |
| 62 | `lib/backend/http/interceptors/auth_interceptor.dart` | 144 | 130 |
| 63 | `lib/backend/http/interceptors/request_logger.dart` | 134 | 124 |
| 64 | `lib/backend/http/interceptors/time_drift_interceptor.dart` | 67 | 57 |

### `lib/backend/providers/` (2 ملفان)
| # | المسار | N | M |
|---|---|---|---|
| 65 | `lib/backend/providers/backend_network_providers.dart` | 82 | 70 |
| 66 | `lib/backend/providers/backend_providers.dart` | 117 | 99 |

**المجموع: 66 ملفًا.**

### ملفات خارج النطاق قُرئت للتحقق من السياق (قراءة فقط)
| المسار | سبب القراءة |
|---|---|
| `lib/core/network/api_config.dart` | مقارنة ازدواج الإعداد مع `lib/backend/http/api_config.dart` (BACK-026، BACK-028) |
| `lib/core/network/api_client.dart` (جزئي) | فهم `expectedOwnerDriverId` و`ApiResponse` و`rawBody` المشار إليها في العقود |
| `lib/core/time/trusted_time_provider.dart` | التحقق من سلسلة الثقة التي يخدمها `TimeDriftInterceptor` (BACK-033) |
| `lib/core/utils/logger.dart` | التحقق من أن `AppLogger.error` يُكتب في الإنتاج (BACK-032) |
| `lib/core/di/app_providers.dart` | تتبّع `authBackendProvider` في جذر التكوين (BACK-013) |
| `analysis_options.yaml` | التحقق من عدم وجود lint معماري يفرض `ignore_architecture` (BACK-003) |
| `lib/features/dvir/data/repositories/dvir_repository_impl.dart` (جزئي) | التحقق من استهلاك `DvirDto` وشكل `rawJson['data']` (BACK-007، BACK-008) |
| `lib/features/hos/domain/engine/tracking/duty_status_tracker.dart` (استخراج) | إثبات انقلاب طبقة domain → backend (BACK-001) |
| `lib/features/auth/data/repositories/auth_repository_impl.dart` (جزئي) | إثبات استهلاك مفاتيح `RawJson` الخام (BACK-010) |
| `lib/features/account/application/usecases/update_rules_use_case.dart` (جزئي) | إثبات `throw` داخل Provider body (BACK-036) |
| `lib/features/connection/presentation/providers/hardware_status_provider.dart` | إثبات تسريب `RawJson` إلى presentation (BACK-001، BACK-023) |
| `lib/features/logs/presentation/providers/unidentified_events_provider.dart` (جزئي) | إثبات استدعاء presentation للعقد مباشرة (BACK-023) |

### ملاحظات منهجية
- **لم يُعدَّل أي ملف تحت `lib/`.** الإجراء الوحيد المُنفَّذ هو `flutter analyze lib/backend` (قراءة فقط).
- **لم يُستدعَ `custom_lint` ولا أي أداة تحليل معماري** — لا يوجد في المشروع (`analysis_options.yaml` لا يشير إلى أي حزمة إضافية).
- **البحث النصي** تم عبر أداة `grep` المدمجة على `lib/` بالكامل، وليس على مجلد `lib/backend` فقط، لمنع تفويت الحواف.
- **كل رقم سطر في هذا التقرير** مأخوذ من قراءة الملف نفسه، وكل مقتطف كود منسوخ حرفيًا من الملف المشار إليه.

--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-010: نظامان متنافسان للخطأ — `AppError`/`Result` مقابل `Failure`/`Either`
- Severity: MEDIUM
- Category: Architecture
- Location: `lib/core/result/result.dart:16` مقابل `lib/core/error/failure.dart:4`; `lib/core/network/error_mapper.dart:15` مقابل `lib/core/utils/repository_helper.dart:10`
- Evidence:
```dart
typedef Result<T> = fp.Either<AppError, T>;
```
```dart
final _defaultNetworkInfo = NetworkInfoImpl();

/// Helper function to standardize error handling across all repositories.
Future<Either<Failure, T>> executeWithHandling<T>(
```
```dart
/// This is the **single point** where HTTP errors are translated.
AppError mapDioException(DioException e) {
```
- Current behavior: `Result<T>` (نوع `AppError`) يُستخدم في 13 مورداً من `lib/backend/adapters/**`، بينما كل المستودعات في `lib/features/**` تُرجع `Either<Failure, T>` وتُغلَّف بـ`guardedNetwork` أو `executeWithHandling`. `mapDioException`claimed كـ«نقطة ترجمة وحيدة» لكنها تعمل على مستوى Dio فقط؛ ثم يُطبَّق تحويل ثانٍ (`executeWithHandling`) فوق نتيجتها.
- Why problematic: تسريب استثناء من العقد الثاني إلى الأول مثبت في الكود:
```dart
return response.fold((error) => throw ServerException(message: error.code), (json) {
```
  (`lib/features/logs/data/repositories/log_repository_impl.dart:270`). أي أن طبقة `AppError` تغني راية `Failure` عبر استثناء، ثم يمسكه `executeWithHandling` الذي يعيد بناء `Failure`. ثلاث طبقات لنفس المشكلة. كما أن `error_mapper.dart` و`user_facing_message.dart` لا يعرفان `Failure`، و`repository_helper.dart` لا يعرف `AppError` — فالنظامان لا يتقاطعان أبداً ولا يغطيان بعضهما.
- Violated principle: Single error contract عبر الطبقات؛ قاعدة «لا ترمِ عبر حدود طبقة».
- Current owner: `lib/core/result/result.dart`, `lib/core/error/failure.dart`
- Correct owner: عقد واحد على مستوى `core` — غالباً `Result<T>` — مع تحويل `Failure` إلى adapter في المودال.
- Consequences: كل مستودع جديد يختار عشوائياً؛ إمكانية وصول `DioException`/`ServerException` لواجهة المستخدم؛ ورسائل خطأ غير متسقة.
- Recommended correction: اختر `Result<T>` كعقد وحيد، احذف `exception.dart`، وحوّل `executeWithHandling`/`guardedNetwork` لتُعيد `Result`. إن أبقبيت `Failure`، فاجعل `AppError` subclass لـ`Failure` (ورثة) بدل تصنيفين متماهيين.
- Related files: `lib/core/error/exception.dart`, `lib/core/network/network_guard.dart:20`, `lib/core/error/user_facing_message.dart:7-25`, `lib/features/logs/data/repositories/log_repository_impl.dart:270`
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
### ISSUE CORE-029: إسقاط.payload صامت في `ApiResponse` يُنتج `data == null` بلا خطأ
- Severity: MEDIUM
- Category: ErrorHandling
- Location: `lib/core/network/api_response.dart:136-151,100-101`
- Evidence:
```dart
  static T? _parsePayload<T>(
    dynamic payload,
    T Function(dynamic)? parser,
  ) {
    if (payload == null) return null;

    if (parser != null) {
      return parser(payload);
    }

    if (payload is T) {
      return payload;
    }

    return null;
  }
```
- Current behavior: عند عدم تمرير `parser`، إن لم يكن `payload` من النوع `T` المتوقّع، يُعاد `null` **دون خطأ**. و`ApiClient._execute` يعيد `fp.Right(apiResponse)` دائماً في مسار 2xx:
```dart
        final apiResponse = ApiResponse.fromBody<T>(
          statusCode: response.statusCode ?? 0,
          rawBody: response.data,
          parser: parser,
        );

        return fp.Right(apiResponse);
```
  إذاً استجابة 200 بجسم من نوع خاطئ تُقرأكنجاح، ثم يفشل `parser`/الاستخدام لاحقاً خارج حدود الشبكة.
- Why problematic: كتم الفشل ينقله إلى طبقة أبعد (repositories/widgets)، حيث يُ.handler كـ`null` ويُقرأ كـ«لا توجد بيانات» — صامت تماماً. القاعدة المعلنة في نفس الملف (`:9-11` من `app_error.dart`) «No raw exceptions should escape» صامدة، لكن العكس لم يُفرض: **الأخطاء UASILE لا تُنتج `AppError`**.
- Violated principle: Fail fast at boundaries؛ لا `null` كقناة خطأ صامتة.
- Current owner: `lib/core/network/api_response.dart:136-151`
- Correct owner: نفس الملف — يجب أن يُنتج `ValidationError`/ServerError عبر `Result` بدل `null`.
- Consequences: تشخيصBug على الواجهة بدل الشبكة.
- Recommended correction: اجعل `_parsePayload` يرمي `FormatException` (ول��د في `mapDioException` كـ`server.malformedResponse`)، أو اجعل `fromBody` يُعيد `Either<AppError, ApiResponse<T>>`.
- Related files: `lib/core/network/api_client.dart:276-329`, `lib/core/network/error_mapper.dart:59-69`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-032: `ApiClient` لا يثبّت اعتراضاته فيُنشأ غير صالح بذاته
- Severity: LOW
- Category: Architecture
- Location: `lib/core/network/api_client.dart:41-60`
- Evidence:
```dart
  ApiClient({
    required ApiConfig config,
    Dio? dio,
    this.maxRetries = 2,
    this.retryBackoff = const Duration(milliseconds: 400),
  })  : _config = config.normalized(),
        _dio = dio ?? Dio() {
    _dio.transformer = LenientJsonTransformer();
    ...
    // Logging lives in one interceptor (`RequestLogger`, debug only, redacted).
    // The former `LogInterceptor(requestBody: true, responseBody: true)` was a
    // second logger that printed the login body and every response twice.
  }
```
- Current behavior: `ApiClient` يهيّئ الترويسة والتحويل فقط. إضافة `AuthInterceptor` و`RequestLogger` و`TimeDriftInterceptor` تتم خارجاً في `lib/backend/providers/backend_network_providers.dart:56-71` عبر `client.dio`. لا يوجد مسار `ApiClient` مكتمل بذاته؛ والوصول exposes عبر `Dio get dio => _dio;`.
- Why problematic: من يبني `ApiClient` مباشرة (اختبار، أداة، feature جديد) يحصل على عميل **بلا مصادقة وبلا تثبيت وقت** — وهو في تطبيق ELD مikoالأسوأ: يُرسل طلبات بلا جلسة، ولا تثبيت الوقت. `// Not responsible for: Auth token injection (see interceptors)` في الترويسة يجعلها تبدو قراراً مقصوداً، لكن ليس فيها عقد يفرضه.
- Violated principle: Self-contained abstraction؛ Principle of Least Surprise in a compliance-critical path.
- Current owner: `lib/core/network/api_client.dart` + `lib/backend/providers/backend_network_providers.dart`
- Correct owner: `ApiClient` يقبل `List<Interceptor>` في المُنشئ (أو في `factory`) — فيظل التركيب فيComposition root دون أن يصبح سهل النسيان.
- Consequences: احتمال عميل شبكة غير مُهيأ في مسار جديد.
- Recommended correction: `ApiClient({required ApiConfig config, List<Interceptor> interceptors = const [], Dio? dio, ...})` ثم `dio.interceptors.addAll(interceptors)` في المُنشئ؛ واحتفظ بالتركيب في `backend_network_providers.dart`.
- Related files: `lib/backend/providers/backend_network_providers.dart:48-73`, `lib/core/network/core_providers.dart:13-14`
- Confidence: POTENTIAL
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-033: معرّفات تخزين ثابتة على مستوى الفئة قبل التهيئة + معرفة `Traccar` داخل `core`
- Severity: MEDIUM
- Category: Architecture
- Location: `lib/core/services/local_storage_service.dart:17-18,24`; `lib/core/data/models/user_model.dart:32-69,71-83`
- Evidence:
```dart
class LocalStorageService implements ServerConfigProvider {
  static Future<void>? _initFuture;
  static late SharedPreferencesWithCache _prefs;
  bool _initialized = false;
...
  SharedPreferencesWithCache get prefs => _prefs;
```
```dart
  factory UserModel.fromJson(Map<String, dynamic> json,
      {String? defaultEmail}) {
    // Traccar API returns id as int, name, email, administrator boolean
    final idValue = json['id']?.toString() ?? '';
...
    UserRole userRole = UserRole.fieldWorker;
    if (json['administrator'] == true) {
      userRole = UserRole.admin;
```
- Current behavior: (1) `LocalStorageService` يحفظ `SharedPreferencesWithCache` في **`static late`** مشترك بين كل النسخ في الـisolate، بينما التهيئة (`_initialized`, `_trackingStorage`, `_preferencesStorage`) **على مستوى النسخة** — فحال واحد مختلط. أي قراءة لـ`prefs` قبل `init()` ترمي `LateInitializationError`؛ وهذا بالضبط ما يصطاده `trusted_time_provider.dart:203-212` بـ`catch (_) { return null; }`. (2) `UserModel` — وهو `core/data/models` — يعرف صيغة `Traccar` السلكية (`administrator`, `disabled`, `name`)؛ كما أن معاملي `defaultEmail` غير مستخدمين تماماً.
- Why problematic: (1) الحالة الساكنة تجعل الخدمة غير آمنة في `build()` العابر أو عند بناء مُزوّد قبل التهيئة — وتُخفى بـcatch مطوّل في `trusted_time_provider`. (2) `core/data/models/user_model.dart` يعرف صيغة `features/tracking` عبر `fromJson` — عدم احترام حدود الطبقة (مرتبط بـCORE-004). (3) معاملان ميتان (`defaultEmail` في `fromJson` و`fromMetadata`).
- Violated principle: لا حالة ساكنة لحالات مُعتمَدة على التهيئة؛ Encapsulation of transport-format knowledge.
- Current owner: `lib/core/services/local_storage_service.dart:17-18`; `lib/core/data/models/user_model.dart`
- Correct owner: `lib/core/storage/` لـSharedPreferences؛ و`features/tracking/data/models` أو `backend/adapters/.../mappers` لـ`UserModel.fromJson` (صيغة Traccar).
- Consequences: `LateInitializationError` مُخفي؛ و`core` يحمل معرفة بـvendor.
- Recommended correction: (أ) اجعل `prefs` nullable مع `get isReady`، أو انقل `trustedTimeProvider` إلى ما بعد التهيئة؛ (ب) انقل `UserModel.fromJson` إلى mapper في `backend/adapters/eld_engine/mappers/` أو `features/tracking/data/models/`، واحذف `defaultEmail` إن لم يُستخدم.
- Related files: `lib/core/time/trusted_time_provider.dart:200-229`, `lib/app/app_initializer.dart:53-54`, `lib/core/services/tracking_config_storage_service.dart:101-107`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

--------------------------------------------------
### ISSUE CORE-036: `isConnected` يبتلع الاستثناء ويعيد `false`
- Severity: LOW
- Category: ErrorHandling
- Location: `lib/core/services/bluetooth_service.dart:83-91`
- Evidence:
```dart
  /// Check if the device is currently connected via BLE.
  Future<bool> isConnected() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      AppLogger.error('Error checking isConnected', e);
      return false;
    }
  }
```
- Current behavior: فشل القناة الأصلية يُترجم إلى `false` (غير متصل) بعد تسجيل فقط، بينما بقية الدوال (`startScan`, `connect`, ...) **ترمي** `BluetoothException`.
- Why problematic: التوحيد على مستوى الصنف منكسر: هذا العضو وحده يبتلع. المستدعي لا يستطيع التمييز بين «غير متصل فعلاً» و«القناة الأصلية معطوبة» — وهذا تمييز مهم لتطبيق ELD (قد يمنع التتبع تلقائياً بصمت).
- Violated principle: اتساق العقد على مستوى الصنف؛ Fail-loud.
- Current owner: `lib/core/services/bluetooth_service.dart:83-91`
- Correct owner: نفس الملف — إمّا يرمي `BluetoothException` كبقية الأعضاء، أو يُرجع نتيجة مُصنَّفة (`BluetoothStatus`).
- Consequences: فشل صامت في فحص الاتصال.
- Recommended correction: اجعلها ترمي `BluetoothException(e.code, ...)` كبقية دوال الصنف، أو وثّق الاستثناء صراحة.
- Related files: `lib/core/services/bluetooth_service.dart:47-80`, `lib/core/network/core_providers.dart:16-20`
- Confidence: CONFIRMED
--------------------------------------------------


--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

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

--------------------------------------------------

--------------------------------------------------
### ISSUE HL-11: مستودع بيانات يُعيد استخدام `static _cachedDashboard` على مستوى الفئة
- **Severity:** Medium
- **Category:** Encapsulation / Testability
- **Location:** `lib/features/hos/data/repositories/status_dashboard_repository_impl.dart:18`
- **Evidence:**
```dart
18:  static StatusDashboard? _cachedDashboard;
```
- **Current behavior:** cache مشترك على مستوى **الفئة**، لا على مستوى النسخة.
- **Why problematic:** كل نسخة `StatusDashboardRepositoryImpl` تتشارك نفس الخلية. مع Riverpod هذا غير مرئي، لكن في اختبارات متوازية (أو إذا أُنشئت نسختان لسبب ما) تتسرب بيانات **السائق A إلى عرض B**. كما أن `_cachedDashboard` لا يُمسح عند logout —/providers/status_dashboard_providers.dart:122-123` يمنع GET فقط ولا يمسح الـ cache.
- **Violated principle:** Encapsulation + Instance-level state.
- **Current owner:** المستودع.
- **Correct owner:** خلية على مستوى النسخة (repository لكل جلسة) أو cache service مُدار بالجلسة.
- **Consequences:** تسرب بيانات بين السائقين في سيناريو تعدد الجلسات.
- **Recommended correction:** اجعلها خلية نسخة، وأضف `clearCache()` تُستدعى عند logout.
- **Related files:** `lib/features/hos/presentation/providers/status_dashboard_providers.dart:122-123`
- **Confidence:** **POTENTIAL** (يتطلب سيناريو تعدد جلسات غير مُثبت في الكود المقروء)

--------------------------------------------------

--------------------------------------------------



## C. جدول تناظر العقود (`eld_engine` مقابل `mock`)

**إجمالي دوال العقد: 58.** كل صف = دالة عقد واحدة.
«✅» = يُرجع قيمة `Result` صحيحة | «❌» = `throw UnimplementedError` | «⚠️» = منفَّذ لكن بتناظر دلالي/شكلي مختلف.

| العقد | الدالة | `eld_engine` | `mock` | حالة التناظر |
|---|---|---|---|---|
| **AuthBackend**<br>4/4 ✅ | `login` | `eld_auth_backend.dart:17` | `mock_auth_backend.dart:9` ✅ | تناظر تام — نفس المفاتيح `credential/user/serverOrigin` |
| | `validateSession` | `eld_auth_backend.dart:100` | `mock_auth_backend.dart:23` ✅ | تناظر تام |
| | `logout` | `eld_auth_backend.dart:142` | `mock_auth_backend.dart:36` ✅ | تناظر تام |
| | `requestPasswordReset` | `eld_auth_backend.dart:165` | `mock_auth_backend.dart:45` ✅ | تناظر تام |
| **AccountBackend**<br>2/2 ✅ | `getMyAccount` | `eld_account_backend.dart:51` | `mock_account_backend.dart:15` ⚠️ | الموك لا يطبّق `_mapAccountJson` (BACK-019) |
| | `updatePreferences` | `eld_account_backend.dart:64` | `mock_account_backend.dart:20` ⚠️ | نفس الملاحظة |
| **DailyLogsBackend**<br>7/11 ✅ | `list` | `eld_daily_logs_backend.dart:17` | `mock_daily_logs_backend.dart:14` ✅ | تناظر شكلي |
| | `getById` | `eld_daily_logs_backend.dart:47` | `mock_daily_logs_backend.dart:51` ❌ | `UnimplementedError` |
| | `getTeamStatus` | `eld_daily_logs_backend.dart:56` | `mock_daily_logs_backend.dart:55` ✅ | تناظر |
| | `respondToCarrierEdit` | `eld_daily_logs_backend.dart:65` | `mock_daily_logs_backend.dart:67` ✅ | تناظر |
| | `certify` | `eld_daily_logs_backend.dart:83` | `mock_daily_logs_backend.dart:77` ✅ | تناظر (يستورد DTO المحرك — BACK-035) |
| | `reassignDriving` | `eld_daily_logs_backend.dart:97` | `mock_daily_logs_backend.dart:89` ✅ | تناظر |
| | `getForm` | `eld_daily_logs_backend.dart:114` | `mock_daily_logs_backend.dart:99` ❌ | `UnimplementedError` |
| | `saveForm` | `eld_daily_logs_backend.dart:123` | `mock_daily_logs_backend.dart:103` ❌ | `UnimplementedError` |
| | `getGraphGrid` | `eld_daily_logs_backend.dart:138` | `mock_daily_logs_backend.dart:111` ✅ | تناظر |
| | `lock` | `eld_daily_logs_backend.dart:147` | `mock_daily_logs_backend.dart:115` ❌ | `UnimplementedError` |
| | `getReadiness` | `eld_daily_logs_backend.dart:155` | `mock_daily_logs_backend.dart:119` ✅ | تناظر |
| **DriverSessionBackend**<br>1/5 ✅ | `getActiveSession` | `eld_driver_session_backend.dart:17` | `mock_driver_session_backend.dart:13` ❌ | `UnimplementedError` |
| | `getAvailableDrivers` | `eld_driver_session_backend.dart:39` | `mock_driver_session_backend.dart:24` ✅ | الموك `[]` دائمًا |
| | `getCurrentCoDriver` | `eld_driver_session_backend.dart:26` | `mock_driver_session_backend.dart:19` ❌ | `UnimplementedError` («no invented co-driver») |
| | `connect` | `eld_driver_session_backend.dart:50` | `mock_driver_session_backend.dart:29` ❌ | `UnimplementedError` |
| | `switchPrimaryDriver` | `eld_driver_session_backend.dart:66` | `mock_driver_session_backend.dart:36` ❌ | `UnimplementedError` |
| **DutyStatusBackend**<br>4/5 ✅ | `record` | `eld_duty_status_backend.dart:15` | `mock_duty_status_backend.dart:12` ⚠️ | **`DateTime.now()` ⇒ غير حتمي** (BACK-021) |
| | `update` | `eld_duty_status_backend.dart:25` | `mock_duty_status_backend.dart:16` ⚠️ | نفس الملاحظة |
| | `getGraphGrid` | `eld_duty_status_backend.dart:38` | `mock_duty_status_backend.dart:23` ❌ | `UnimplementedError` |
| | `submitLegacyDutyStatusEvent` | `eld_duty_status_backend.dart:54` | `mock_duty_status_backend.dart:30` ✅ | تناظر |
| | `submitLegacyGenericEvent` | `eld_duty_status_backend.dart:73` | `mock_duty_status_backend.dart:39` ✅ | تناظر |
| **DvirBackend**<br>6/8 ✅ | `list` | `eld_dvir_backend.dart:16` | `mock_dvir_backend.dart:12` ⚠️ **❗** | **شكل مختلف: `'data'` vs `'reports'`** (BACK-008) |
| | `create` | `eld_dvir_backend.dart:52` | `mock_dvir_backend.dart:24` ✅ | تناظر (`ok(null)`) |
| | `getById` | `eld_dvir_backend.dart:71` | `mock_dvir_backend.dart:32` ❌ | `UnimplementedError` |
| | `review` | `eld_dvir_backend.dart:82` | `mock_dvir_backend.dart:38` ❌ | `UnimplementedError` |
| | `getDefectsCatalog` | `eld_dvir_backend.dart:104` | `mock_dvir_backend.dart:46` ✅ | تناظر (11 عنصرًا) |
| | `getPreviousDvir` | `eld_dvir_backend.dart:113` | `mock_dvir_backend.dart:63` ✅ | تناظر |
| | `getDefectDetails` | `eld_dvir_backend.dart:122` | `mock_dvir_backend.dart:68` ✅ | تناظر (`{}` فارغ) |
| | `getVehicleDefects` | `eld_dvir_backend.dart:131` | `mock_dvir_backend.dart:72` ✅ | تناظر |
| **HardwareBackend**<br>3/6 ✅ | `getAlerts` | `eld_hardware_backend.dart:20` | `mock_hardware_backend.dart:12` ❌ | `async`-throw (BACK-022) |
| | `setManualMode` | `eld_hardware_backend.dart:30` | `mock_hardware_backend.dart:17` ✅ | تناظر |
| | `getReadiness` | `eld_hardware_backend.dart:51` | `mock_hardware_backend.dart:30` ✅ | تناظر |
| | `connectSession` | `eld_hardware_backend.dart:68` | `mock_hardware_backend.dart:51` ❌ | `async`-throw |
| | `getStatus` | `eld_hardware_backend.dart:85` | `mock_hardware_backend.dart:59` ❌ **❗** | `async`-throw ⇒ **انهيار `hardwareStatusProvider`** |
| | `sendTelemetry` | `eld_hardware_backend.dart:106` | `mock_hardware_backend.dart:67` ✅ | تناظر |
| **InspectionBackend**<br>3/8 ✅ | `getScreen` | `eld_inspection_backend.dart:17` | `mock_inspection_backend.dart:14` ✅ | الموك يعلن `canStart/canSend/canEmail/canView = false` بوعي |
| | `getCycle` | `eld_inspection_backend.dart:34` | `mock_inspection_backend.dart:43` ✅ | تناظر |
| | `getLogs` | `eld_inspection_backend.dart:59` | `mock_inspection_backend.dart:87` ✅ | تناظر (مع تخزين في الذاكرة) |
| | `emailLogs` | `eld_inspection_backend.dart:103` | `mock_inspection_backend.dart:152` ❌ | `UnimplementedError` |
| | `getInformationPacket` | `eld_inspection_backend.dart:128` | `mock_inspection_backend.dart:164` ❌ | `UnimplementedError` |
| | `sendLogs` | `eld_inspection_backend.dart:139` | `mock_inspection_backend.dart:168` ❌ | `UnimplementedError` |
| | `startInspection` | `eld_inspection_backend.dart:166` | `mock_inspection_backend.dart:181` ❌ | `UnimplementedError` |
| | `getTransfers` | `eld_inspection_backend.dart:185` | `mock_inspection_backend.dart:192` ❌ | `UnimplementedError` |
| **RulesScreenBackend**<br>2/2 ✅ | `getRulesScreen` | `eld_rules_screen_backend.dart:18` | `mock_rules_screen_backend.dart:55` ✅ | تناظر — لكن كلاهما يمرّ بـ `eld_engine` DTO+mapper (BACK-035) |
| | `saveRulesScreen` | `eld_rules_screen_backend.dart:28` | `mock_rules_screen_backend.dart:61` ✅ | تناظر |
| **SignatureBackend**<br>1/1 ⚠️ | `save` | `eld_signature_backend.dart:18` | `mock_signature_backend.dart:19` ⚠️ **❗** | **تباين تام**: المحرك يُرجع `err` دائمًا، الموك يُصدر شهادة. **ولا يوجد provider ولا مستهلك للاثنتين** (BACK-013) |
| **StatusDashboardBackend**<br>3/3 ✅ | `getDashboard` | `eld_status_dashboard_backend.dart:21` | `mock_status_dashboard_backend.dart:29` ✅ | تناظر كامل — نماذج domain مُحاطة |
| | `updateDutyStatus` | `eld_status_dashboard_backend.dart:37` | `mock_status_dashboard_backend.dart:34` ✅ | تناظر كامل |
| | `getWeeklyRecap` | `eld_status_dashboard_backend.dart:95` | `mock_status_dashboard_backend.dart:43` ✅ | تناظر كامل |
| **UnidentifiedEventsBackend**<br>**0/3** ❗ | `list` | `eld_unidentified_events_backend.dart:43` | `mock_unidentified_events_backend.dart:13` ❌ | `UnimplementedError` |
| | `claim` | `eld_unidentified_events_backend.dart:61` | `mock_unidentified_events_backend.dart:23` ❌ | `UnimplementedError` |
| | `reject` | `eld_unidentified_events_backend.dart:73` | `mock_unidentified_events_backend.dart:31` ❌ | `UnimplementedError` |
| **VehicleBackend**<br>2/2 ✅ | `getCompanyFleet` | `eld_vehicle_backend.dart:19` | `mock_vehicle_backend.dart:14` ✅ | تناظر — كلاهما `{'data': []}` |
| | `getMyVehicles` | `eld_vehicle_backend.dart:34` | `mock_vehicle_backend.dart:18` ✅ | تناظر |

### ملخص التناظر

| المقياس | القيمة |
|---|---|
| إجمالي دوال العقد | **58** |
| منفَّذة بالكامل في الموك | **36** (62%) |
| `throw UnimplementedError` في الموك | **22** (38%) — BACK-020 |
| عقود بنسبة تنفيذ 0% | **1** من 13 (`UnidentifiedEventsBackend`) |
| عقود بنسبة تنفيذ 100% | **5** من 13 (`AuthBackend`, `VehicleBackend`, `RulesScreenBackend`, `StatusDashboardBackend`, `AccountBackend` تنازليًا) |
| دوال بتباين **دلالي صامت** (تنجح لكن بشكل مختلف) | **3**: `DvirBackend.list` (❗ BACK-008)، `DutyStatusBackend.record/update` (BACK-021)، `AccountBackend.*` (BACK-019) |
| دوال بتباين **كامل** | **1**: `SignatureBackend.save` (❗ BACK-013، وهي ميتة أصلًا) |
| getterات في `BackendAdapter` بلا `Provider` | **1 من 14**: `signature` (BACK-013) |
| صنف في `MockAdapter` بلا تنفيذ جوهري | **1**: `MockSignatureBackend` (49 سطرًا منطق لا يُستدعى) |

**الحكم على التماثل:** المحوّلان **متماثلان على مستوى التوقيع** (كل الـ 13 عقدة تُنفَّذ في `MockAdapter`، ولا يوجد getter ناقص — عدا `signature` الميت في الاثنين). لكن **التناظر على مستوى السلوك ضعيف**: 38% من الدوال ترمي استثناءً، و3 دوال «تنجح» بشكل مختلف دون أن يعلم أحد.

---

