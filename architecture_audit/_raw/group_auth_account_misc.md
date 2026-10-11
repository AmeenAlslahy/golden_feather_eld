# Group: auth + account + codriver + connection + home + misc + shared domain
## تدقيق الطبقات والمسؤوليات (Layer / Responsibility Audit)

> **نطاق القراءة:** 72 ملفاً مطّلعاً بالكامل داخل النطاق المحدد (features/auth, account, codriver, connection, home, onboarding, permissions, settings, about + lib/domain) + 6 ملفات توجيه (`lib/routes.dart` و`lib/routes/*.dart`) قُرئت كدليل على حواف التنقّل. الملفات المولّدة `*.g.dart` و`*.freezed.dart` مستثناة من القراءة التفصيلية لكن **تم توثيق تعليقات التوليد (`part` directives) وملاحظات `@freezed`** في كل موضع.
>
> **قاعدة الحكم:**Riverpod داخل widget ليس مخالفة. حجم الملف ليس مخالفة بذاته. لا يُسجَّل finding إلا بـ `path:line` + مقتطف كود حقيقي.

---

## 0. خلاصة تنفيذية (Executive Summary)

| المحور | الحكم الصريح |
|---|---|
| تسجيل بيانات الاعتماد في السجلات (credentials logging) | **نظيف — لا مخالفة (CONFIRMED CLEAN)**. كل نداءات `AppLogger` في المصادقة مقتبسة في §C-1 ولا تطبع `password` ولا `sessionCredential`. بل `AuthSession.toString()` يحجبها صراحةً. |
| `auth_state_provider.dart` (330 سطر) | **يحمل سياسات نطاق الهوية (identity-boundary policy)**: `SessionEpoch.bump()` + سلسلة تسلسل عمليات التخزين `_storageChain`.olicies مفترض أن تكون في `domain`/`application`. → **AUTH-001** |
| هل طبقة `usecase` في auth ذات معنى؟ | **شبه طقسية (ceremonial)**. `CheckAuthStatusUseCase` = 15 سطر بلا أي سلوك، و`LogoutUseCase` **يُسقط** `Either<Failure, Unit>` بالكامل. → **AUTH-002** |
| تخزين/تحديث الـ token في presentation؟ | **لا.** التخزين في `AuthLocalDataSourceImpl` (data) ✓، والتحقق من صلاحية الجلسة في `AuthRepositoryImpl.checkAndRestoreSession` ✓. **لا يوجد refresh token أصلاً في الكود.** الفرضية المرفوضة. |
| `mac_address_validation.dart` في `presentation/` | **ليس مخالفة (CONFIRMED CLEAN)** — الدالة تُرجع رسالة `AppLocalizations`، فلا يمكن أن تعيش في `domain`. لكن **تقسيم التحقق** غير متسق → **CON-006** (منخفض). |
| صفحات `instructions` / `user_manual` / `rules` | **ليست صفحات نص خام غير مترجَم.** كل النصوص عبر `context.loc`. الفرضية المرفوضة عمداً؛ يوجد فقط 3 نصوص hardcoded → §C. |
| `lib/domain/**` | **8 من 9 ملفات نقية** (لا Flutter ولا Riverpod ولا Dio ولا features). الملف التاسع `duty_status_code.dart` **يخالف** ويُسحب إلى `backend/contracts` → **DOM-001** (عالٍ). |
| استقلالية التنقّل | نمط `RouterNotifier extends ChangeNotifier` **صحيح**. لكن يوجد تجاوز فعلي واحد لـ GoRouter → **ROU-001**. |

**إجمالي الملاحظات المرفوعة:** 45 finding موزّعة على 7 مجموعات:
- **13 High** — `AUTH-001, AUTH-004, AUTH-005, ACC-001, ACC-002, ACC-003, ACC-004, COD-001, COD-002, CON-001, HOM-001, HOM-002, DOM-001`
- **19 Medium** — `AUTH-002, AUTH-003, ACC-005..ACC-008, COD-003..COD-006, CON-002..CON-005, HOM-003, DOM-002, DOM-003, ROU-001, PERM-001`
- **11 Low** — `AUTH-006, AUTH-007, CON-006, CON-007, HOM-004, DOM-004, DOM-005, ROU-002, ROU-003, SET-001, SEC-002`
- **2 Informational (مناطق نظيفة موثّقة، لا عمل مطلوب)** — `CTN-001, SEC-001`

---

# A. Per-file findings — لكل ملف مقروء

## A.1 `lib/features/auth/**` (19 ملفاً)

### `lib/features/auth/data/datasources/auth_local_data_source.dart` (137 سطر، غير فارغ 117)
- **المسؤولية الفعلية:** ثنائي التوصيف (Abstract + Impl) لتخزين `AuthSession` و`User` في `FlutterSecureStorage`، مع كاش ذاكرة `_sessionCache` وعدّاد `credentialGeneration` لتوسيم الطلبات.
- **الطبقة المعلنة:** data ✓
- **الطبقة الفعلية:** data ✓
- **الحالة المعمارية:** سليم. الاستيراد elegiblity: `core/domain/entities/user.dart` و`core/data/models/user_model.dart` — عبور `data`→`core.data.models` مقبول.
- **ملاحظة أمنية إيجابية (CONFIRMED CLEAN):** لا يطبع أي سرّ. `AppLogger.info('Session securely stored for origin: ${session.serverOrigin}')` — يطبع الـ origin فقط.
- **Issue IDs:** —

### `lib/features/auth/data/models/auth_session_dto.dart` (65، 58)
- **المسؤولية:** DTO للتسلسل، مع `fromEntity/toEntity`.
- **المعلنة/الفعلية:** data ✓ / data ✓
- **الحالة:** سليم.
- **Issue IDs:** —

### `lib/features/auth/data/repositories/auth_repository_impl.dart` (195، 175)
- **المسؤولية:** تنفيذ `AuthRepository`: `login`، `checkAndRestoreSession` (+`guardedNetwork` مع مسار offline)، `logout`، `getCurrentSession`، وفحص صلاحية الـ origin.
- **المعلنة/الفعلية:** data ✓ / data ✓
- **الحالة:** سليم. تحقّق الـ origin مُطبَّق قبل استعادة الجلسة (`_isValidOrigin`) ✓، والمسار دون-شبكي لا يُعيد جلسة من خادم مختلف ✓.
- **Issue IDs:** —

### `lib/features/auth/domain/entities/auth_session.dart` (53، 44)
- **المسؤولية:** كيان جلسة equatable مع `belongsTo()` وحجب السر في `toString()`.
- **المعلنة/الفعلية:** domain ✓ / domain ✓
- **الحالة:** نقي تماماً (استيرادان فقط: `equatable` + `core/domain/entities/user.dart`).
- **Issue IDs:** —

### `lib/features/auth/domain/entities/value_objects/email_regex.dart` (8، 8)
- **المسؤولية:** ثابت نمط بريد مبسّط.
- **الحالة:** نقي ✓.
- **Issue IDs:** —

### `lib/features/auth/domain/entities/value_objects/login_identifier.dart` (41، 36)
- **المسؤولية:** value object للمُعرف + `errorMessage`.
- **المعلنة/الفعلية:** domain / domain + **تسريب مفاتيح l10n من domain** (يرجّع `'emailRequired'`، `'invalidEmailFormat'`, `'invalidValue'` كنصوص).
- **الحالة:** مخالفة طبقة (منخفضة) — domain لا يعرف مفاتيح الترجمة.
- **Issue IDs:** **AUTH-003**

### `lib/features/auth/domain/entities/value_objects/password.dart` (21، 18)
- **المسؤولية:** value object لكلمة المرور.
- **المسؤولية الفعلية:** **فارغة قانونياً**: `final isValid = input.isNotEmpty;` — لا قاعدة تعقيد، لا `==`/`hashCode`، لا `toString` حاجب.
- **المعلنة/الفعلية:** domain / domain + تسريب l10n key (`'passwordRequired'`).
- **Issue IDs:** **AUTH-003**

### `lib/features/auth/domain/repositories/auth_repository.dart` (20، 16)
- **المسؤولية:** عقد مستودع (4 عمليات، كلها `Either<Failure, …>`).
- **الحالة:** سليم ✓.
- **Issue IDs:** —

### `lib/features/auth/domain/usecases/check_auth_status_usecase.dart` (15، 12)
- **المسؤولية الفعلية:** `return await repository.checkAndRestoreSession();` — **تمرير بلا أي سلوك**.
- **الحالة:** طبقة use-case طقسية.
- **Issue IDs:** **AUTH-002**

### `lib/features/auth/domain/usecases/login_usecase.dart` (37، 32)
- **المسؤولية الفعلية:** فحص `identifier.isValid` و`password.isValid` ثم تمرير — 37 سطراً منها 12 استيراداً وتعليقاً.
- **الحالة:** السلوك الوحيد مكرَّر حرفياً داخل الـ widget ⇒ **AUTH-007**.
- **Issue IDs:** **AUTH-002**, **AUTH-007**

### `lib/features/auth/domain/usecases/logout_usecase.dart` (12، 9)
- **المسؤولية الفعلية:** `await repository.logout();` مع **إسقاط** `Either<Failure, Unit>` كاملة (الدالة تُرجع `Future<void>`).
- **الحالة:** طبقة use-case تُفقد معلومات — مخالفة.
- **Issue IDs:** **AUTH-002**

### `lib/features/auth/presentation/pages/auth_page.dart` (160، 150)
- **المسؤولية:** تخطيط شاشة المصادقة + تبديل الوضع بين `LoginForm`/`ForgotPasswordForm`.
- **الحالة:** presentation سليمة. استخدام Riverpod هنا سليم.
- **Issue IDs:** —

### `lib/features/auth/presentation/pages/splash_page.dart` (97، 86)
- **المسؤولية الفعلية:** **مُنسّق إقلاع على مستوى التطبيق**: يفحص `onboardingSeen`، ثم يستدعي `Permission.location/bluetooth` مباشرةً، ثم `checkAuthStatus()`، ثم يقرّر الوجهة بـ `context.goNamed(...)`.
- **المعلنة:** presentation (صفحة)
- **الفعلية:** **application bootstrap orchestrator** + وصول مباشر لـ `permission_handler`
- **الحالة:** مخالفة طبقة (عالية). يوجد بالفعل مجلد `lib/app/orchestrators/` تحوي `tracking_orchestrator.dart` — فالنمط متاح ومُهمَل هنا.
- **Issue IDs:** **AUTH-005**

### `lib/features/auth/presentation/providers/auth_mode_provider.dart` (14، 12)
- **المسؤولية:** `StateProvider<AuthMode>` لتبديل نموذج الواجهة.
- **الحالة:** presentation ✓ سليم.
- **Issue IDs:** —

### `lib/features/auth/presentation/providers/auth_providers.dart` (3، 2)
- **المسؤولية الفعلية:** سطر `export '../../../../core/di/app_providers.dart' show traccarAuthRepositoryProvider, authLocalDataSourceProvider;`
- **المعلنة/الفعلية:** presentation/providers / **إعادة تصدير جذر التركيب (composition root)**
- **الحالة:** smell طبقي منخفض: providersシーン الـ DI تُقدَّم وكأنها تخصّ auth presentation.
- **Issue IDs:** **AUTH-006**

### `lib/features/auth/presentation/providers/auth_state_provider.dart` (330، 292)
- **المسؤولية الفعلية (7 مهام):**
  1. `enum AuthStatus` (5 حالات).
  2. `class AuthState` + `copyWith` + `isAuthenticated`.
  3. `authStateProvider`: ربط `unauthenticatedEventProvider` (حدث 401 من `backend/providers`) بمنبّه `forceLogout`.
  4. إدارة تسلسل العمليات (`_operationId`, `_isOperationInProgress`).
  5. **سلسلة تسلسل عمليات التخزين** `_storageChain` / `_runOrdered()` (سياج ضد `clear(A)` المتأخر).
  6. **حدود الهوية** عبر `SessionEpoch.bump()` (كائن `static` قابل للتغيّر في `core/session`).
  7. اشتقاقات: `sessionEpochProvider`, `sessionTransitionProvider`, `currentDriverIdProvider`.
- **المعلنة:** presentation
- **الفعلية:** presentation + **سياسات identity-boundary + سياسات تسلسل التخزين**
- **الحالة:** مخالفة (متوسطة–عالية). يلاحظ أن **تخزين الـ token ليس هنا** ✓؛ ما هنا هو *سياسة* التوسيع.
- **Issue IDs:** **AUTH-001**

### `lib/features/auth/presentation/providers/login_form_provider.dart` (33، 26)
- **المسؤولية:** `obscurePassword` فقط.
- **الحالة:** presentation ✓.
- **Issue IDs:** —

### `lib/features/auth/presentation/widgets/login_form.dart` (134، 121)
- **المسؤولية:** نموذج الدخول + استدعاء `notifier.login(...)`.
- **الحالة:** presentation ✓، لكن **يكرّر التحقق** بنفس `LoginIdentifier`/`Password` (وهو نفس ما يفعله `LoginUseCase`).
- **Issue IDs:** **AUTH-007**

### `lib/features/auth/presentation/widgets/forgot_password_form.dart` (133، 125)
- **المسؤولية الفعلية:** استدعاء **`ref.read(authBackendProvider).requestPasswordReset(...)` مباشرة**، مع `AppError` + `anyErrorUserMessage` + كتالوج `AppLocalizations`، وبناء النصوص عبر `_arabic ? '…' : '…'`.
- **المعلنة:** presentation widget
- **الفعلية:** presentation + **وصول مباشر لعقد البنية التحتية (backend contract)** + تجاوز كامل لطبقتَي data/domain في feature auth
- **الحالة:** مخالفة عالية + تجاوز الترجمة.
- **Issue IDs:** **AUTH-004**

---

## A.2 `lib/features/account/**` (9 ملفات)

### `lib/features/account/application/models/rules_screen_model.dart` (70، 59)
- **المسؤولية:** نموذج read-projection لشاشة القواعد + `_isSettingAllowed()` الذي يفسّر حمولات الخادم المرنة.
- **المعلنة/الفعلية:** application/models / application + **اعتماد على `core/config/hos_configuration.dart`** (طبقة بنية تحتية)
- **الحالة:** مخالفة متوسطة؛ كما أن منطق تفسير الأسماء البديلة **مكرَّر** في `rules_page.dart:97 _serverSetting()`.
- **Issue IDs:** **ACC-005**

### `lib/features/account/application/usecases/update_rules_use_case.dart` (62، 51)
- **المسؤولية الفعلية:** `saveRulesScreen` على الخادم ثم **دمج** `HosConfiguration` في `LocalStorageService` وحفظه.
- **المعلنة:** application/usecases
- **الفعلية:** application + **`import 'package:flutter_riverpod/flutter_riverpod.dart';` (سطر 1) + تعريف `updateRulesUseCaseProvider` (سطر 52) = DI داخل طبقة application** + **اعتماد على presentation لميزة أخرى**: `../../../auth/presentation/providers/auth_state_provider.dart` (سطر 9)
- **الحالة:** مخالفة عالية (اتجاه تبعية معكوس + DI في application).
- **Issue IDs:** **ACC-001**

### `lib/features/account/presentation/pages/account_page.dart` (352، 336)
- **المسؤولية:** عرض بيانات الحساب + قائمة اللغة/العداد.
- **المسؤولية الفعلية الزائدة:** (أ) `ref.watch(dashboardDataProvider)` — مزوّد من feature **HOME** (سطر 7) لعرض اسم السائق؛ (ب) مطابقة أسماء اللغات بنصوص حرفية (سطور 180–181)؛ (ج) `Scaffold.of(context).openDrawer()` + استيراد `EldDrawer` من HOME.
- **الحالة:** مخالفات متوسطة.
- **Issue IDs:** **ACC-007**, **ACC-008**, **ACC-004** (عرض `error` الخام)

### `lib/features/account/presentation/pages/info_packet_page.dart` (150، 139)
- **المسؤولية:** صفحة "حزمة المعلومات".
- **المسؤولية الفعلية الزائدة:** `ref.watch(informationPacketProvider)` وهو مزوّد **presentation** من feature **INSPECTION** (سطور 7–8، 39).
- **الحالة:** مخالفة متوسطة (تبعية عابرة للميزات نحو تنفيذ的另一 feature).
- **Issue IDs:** **ACC-006**, **ROU-001**

### `lib/features/account/presentation/pages/instructions_page.dart` (502، 475)
- **المسؤولية:** ثلاث أقسام تعليمات + `ZoomableSectionPage`.
- **النصوص:** **مترجَمة بالكامل عبر `context.loc`** — الفرضية المرفوضة. النص الوحيد الخشن: `'www.topceld.com'` (سطر 374).
- **ملاحظة معمارية:** `enum InstructionsSection { all, inspection, sendLogs, malfunction }` — **3 من 4 أقسام غير قابلة للوصول** (لا يوجد GoRoute، ولا أي استدعاء بـ `section:`) ⇒ كود ميت وإعداد زائد.
- **Issue IDs:** **ROU-002**

### `lib/features/account/presentation/pages/rules_page.dart` (502، 476)
- **المسؤولية:** نموذج قواعد HOS قابل للتحرير + عرض الحدود.
- **المسؤولية الفعلية الزائدة:** `import '../../../../backend/adapters/eld_engine/models/rules_screen_dto.dart';` (سطر 13) — presentation يستهلك **DTO محوّل (adapter) من طبقة البيانات**.
- **Issue IDs:** **ACC-002**, **ACC-005**, **ACC-008**

### `lib/features/account/presentation/pages/user_manual_page.dart` (559، 538)
- **المسؤولية:** دليل مستخدم مرجعي كثيف النصوص.
- **النصوص:** **مترجَم بالكامل عبر `context.loc`** — الفرضية المرفوضة. النص الخشن الوحيد: `'Golden Feather ELD'` (سطر 129) — اسم العلامة التجارية، وقد يكون مقصوداً لكنه يخرق `context.loc.appName` الموجود.
- **Issue IDs:** — (فرضية "نصوص إنجليزية غير مترجمة" **مرفوضة**)

### `lib/features/account/presentation/providers/account_provider.dart` (157، 136)
- **المسؤولية:** جلب `DriverAccount` + `updatePreferences` + سياج `owner/epoch/seq`.
- **المسؤولية الفعلية الزائدة:** يكتب `failure.l10nKey` و`e.toString()` **في حقل `error`** المShowر خاماً في `account_page.dart:102`.
- **Issue IDs:** **ACC-004**

### `lib/features/account/presentation/providers/rules_screen_provider.dart` (25، 21)
- **المسؤولية الفعلية:** `FutureProvider` + **تحليل استجابة الخادم محلياً** + `throw Exception(failure.l10nKey)`.
- **المسؤولية_Zائدة:**استدعاء `rulesScreenBackendProvider` مباشرة + `throw Exception('User not authenticated')`.
- **الحالة:** مخالفة عالية — أيضاً **خطأ سلوكي مؤكد** (انظر ACC-003).
- **Issue IDs:** **ACC-003**, **CON-003** (نمط مكرر عبر المشروع)

---

## A.3 `lib/features/codriver/**` (10 ملفات)

### `lib/features/codriver/data/providers/codriver_repository_providers.dart` (20، 16)
- **المسؤولية:** تركيب `CoDriverRepositoryImpl` (نمط DI في data ✓).
- **ملاحظة:** `driverSessionBackendProviderAlias` (سطر 11) غلاف بلا قيمة لوغظية.
- **Issue IDs:** —

### `lib/features/codriver/data/repositories/codriver_repository_impl.dart` (144، 136)
- **المسؤولية:** 3 عمليات على `DriverSessionBackend` مع cache.
- **المسؤولية الفعلية الحرجة:** `static List<CoDriver> _cachedDrivers = [];` و`static CurrentCoDriverRead? _cachedCurrentCoDriver;` — **حالة mutables على مستوى العملية، لا تُبطل عند logout، ولا تتأثر بـ owner/epoch**.
- **Issue IDs:** **COD-001**, **COD-003**

### `lib/features/codriver/domain/current_codriver.dart` (51، 46)
- **المسؤولية الفعلية:** كيان + **`parseCurrentCoDriver(dynamic)` — تحليل حمولة JSON داخل `domain/`**.
- **Issue IDs:** **COD-006**

### `lib/features/codriver/domain/role_switch_guard.dart` (40، 38)
- **المسؤولية:** حارس تبديل الأدوار (نقي تماماً، صفر استيرادات).
- **الحالة:** domain نقي ✓. لكن **عقده يجبر المتصل على تزويده بحالة HOS + إعداد HOS + حالة التتبع** ⇒ التسرّب يقع في المتصل (الـ widget) ⇒ COD-002.
- **Issue IDs:** **COD-002** (كطرف مساهم)

### `lib/features/codriver/domain/team_status.dart` (56، 51)
- **المسؤولية:** كيان + **`parseTeamStatus(dynamic)` — تحليل JSON داخل domain**.
- **Issue IDs:** **COD-006**

### `lib/features/codriver/domain/entities/codriver.dart` (10، 8)
- **المسؤولية:** كيان `CoDriver` + ثابت `none = CoDriver(id: 'none', name: 'No One')`.
- **الحالة:** `'No One'` نص إنجليزي في domain يُعرض كخيار في الواجهة ⇒ §C.
- **Issue IDs:** — (ملاحظة محتوى)

### `lib/features/codriver/domain/repositories/codriver_repository.dart` (15، 12)
- **المسؤولية:** عقد مستودع ✓.
- **Issue IDs:** —

### `lib/features/codriver/presentation/pages/codriver_page.dart` (541، 521)
- **المسؤولية الفعلية الزائدة (5 استيرادات خارجية):** `hos/domain/engine/hos_rules_engine.dart` (15)، `hos/presentation/providers/hos_engine_provider.dart` (16)، `hos/presentation/providers/hos_provider.dart` (17)، `tracking/presentation/providers/tracking_provider.dart` (18)، `hos/presentation/providers/status_dashboard_providers.dart` (23) — كلها Feeding لـ `refuseRoleSwitch` داخل `onPressed`.
- **الحالة:** مخالفة عالية (الـ widgetActs كـ orchestrator لـ feature أخرى).
- **Issue IDs:** **COD-002**, **COD-003**, **COD-004**, **ACC-008**

### `lib/features/codriver/presentation/providers/codriver_provider.dart` (238، 219)
- **المسؤولية:** حالة + سياج `owner/epoch/seq` + `reload()` + `switchDrivers()`.
- **المسؤولية_Zائدة:** رسائل إنجليزية hardcoded تُخزَّن في `state.error` وتُعرض خاماً؛ استيراد `authStateProvider` presentation من feature أخرى (سطر 3).
- **Issue IDs:** **COD-003**, **COD-001** (كطرف متضرر)

### `lib/features/codriver/presentation/providers/team_status_provider.dart` (41، 37)
- **المسؤولية الفعلية:** **تنسيق عمليتين على الخادم**: `backend.list(...)` لاستخراج أول `id`، ثم `backend.getTeamStatus(...)`، مع **استخراج JSON يدوي** (`json['data']`, `first['id']`).
- **المعلنة/الفعلية:** presentation/providers / **data + domain orchestration**
- **Issue IDs:** **COD-005**, **COD-006**

---

## A.4 `lib/features/connection/**` (16 ملفاً)

### `lib/features/connection/domain/connectivity_status.dart` (151، 136)
- **المسؤولية الفعلية:** كيان + **`parseConnectivityStatus(dynamic)` (تحليل JSON في domain)** + `isMacAddress()` (نمط MAC).
- **Issue IDs:** **CON-005**, **CON-006** (التبعية العكسية للقرار)

### `lib/features/connection/domain/hardware_readiness.dart` (75، 67)
- **المسؤولية:** كيان + **`parseHardwareReadiness(dynamic)`** + 5 دوال `_asMap/_text` خاصة.
- **Issue IDs:** **CON-005**

### `lib/features/connection/domain/entities/hardware_alert.dart` (15، 14)
- **المسؤولية:** كيان نقي بلا JSON ✓ (التعليق في الملف يصرّح بذلك).
- **Issue IDs:** —

### `lib/features/connection/presentation/mac_address_validation.dart` (13، 12)
- **المسؤولية الفعلية:** فحص "غير فارغ" فقط + إرجاع `loc.macAddressRequired`.
- **الحكم الصريح:** **ليس مخالفة معمارية.** الدالة تعتمد على `AppLocalizations` بالتوقيع ⇒ لا يمكن أن تعيش في `domain` بصدق. الموضع في `presentation/` صحيح والتعليق في الملف (سطر 7) يشرح التاريخ.
- **لكن:** التقسيم غير متسق — قاعدة *صيغة* MAC في `domain/connectivity_status.dart:150`، بينما الواجهة تفرض صيغة *أضيق* في `eld_connection_page.dart:436–439`.
- **Issue IDs:** **CON-006** (منخفض/POTENTIAL)

### `lib/features/connection/presentation/pages/diagnostics_page.dart` (101، 92)
- **المسؤولية:** فرز التنبيهات إلى diagnostic/malfunction وعرضها.
- **المسؤولية_Zائدة:** `bool _isMalfunction(HardwareAlert a) => a.type.toUpperCase().contains('MALFUNCTION');` (سطر 23–24) — **قاعدة تصنيف نطاق (SRS 7.14) داخل صفحة**. وكتلة `kDebugMode` (سطور 81–91) بزر "محاكاة عطل" لا يفعل شيئاً سوى `AppFeedback.info`.
- **Issue IDs:** **CON-007**

### `lib/features/connection/presentation/pages/eld_connection_page.dart` (529، 492)
- **المسؤولية الفعلية (4 أشياء في ملف واحد):**
  1. `EldConnectionState` (27–59).
  2. `EldConnectionNotifier` (61–246): `attemptConnection` (Bluetooth + hardware backend + local storage + tracking repo + tracking state)، `setManualMode`، `continueDisconnected`.
  3. `eldConnectionProvider` (248–251).
  4. `EldConnectionPage` widget (253–529).
- **المعلنة:** presentation/pages
- **الفعلية:** presentation + **application use-case كامل** + وصول مباشر للبنية التحتية (`bluetoothServiceProvider`, `hardwareBackendProvider`, `localStorageProvider`, `trackingRepositoryProvider`)
- **الحالة:** feature `connection` **لا تملك طبقة `domain/` ولا `application/` إطلاقاً** ⇒ Use case "وصلة الـ ELD" مكتوب كاملاً داخل ملف صفحة.
- **Issue IDs:** **CON-001**, **CON-002**, **CON-008**

### `lib/features/connection/presentation/providers/hardware_alerts_provider.dart` (83، 74)
- **المسؤولية الفعلية:** `AsyncNotifier` + **`_hardwareAlertFromJson()` و`_alertList()` — تحليل JSON** + استدعاء `hardwareBackendProvider` مباشرة.
- **ملاحظة:** تعليق الملف نفسه (سطور 7–8) يعترف بالديون: «يبقى هنا حتى موجة نقل الـ parsing إلى data/mappers».
- **Issue IDs:** **CON-003**

### `lib/features/connection/presentation/providers/hardware_status_provider.dart` (42، 39)
- **المسؤولية:** `FutureProvider` لحالة الاتصال + `hardwareReadinessProvider` + استدعاء backend مباشرة + استيراد `vehicleProvider` من feature **VEHICLE** (سطر 3).
- **Issue IDs:** — (نمط "provider يستدعي backend" متكرر عبر المشروع — يُعالَج مركزياً في CON-003)

### `lib/features/connection/presentation/widgets/eld_connectivity_panel.dart` (78، 74)
- **المسؤولية:** عرض أسطر الحالة المترجمة ✓.
- **Issue IDs:** —

### `lib/features/connection/presentation/widgets/eld_diagnostics_section.dart` (13، 12)
- **المسؤولية:** Barrel export فقط ✓.
- **Issue IDs:** —

### `lib/features/connection/presentation/widgets/eld_readiness_panel.dart` (117، 113)
- **المسؤولية:** عرض قائمة الجاهزية + `readinessCheckLabel()` (تحويل مفتاح خادم إلى تسمية) — presentation ✓.
- **Issue IDs:** —

### `lib/features/connection/presentation/widgets/manual_recording_section.dart` (131، 124)
- **المسؤولية:** قسم §395.34 + نداء `setManualMode`.
- **المسؤولية_Zائدة:** `import '../pages/eld_connection_page.dart';` (سطر 9) — **widget يستورد صفحة** للحصول على `eldConnectionProvider` (الذي مكانه الصحيح `presentation/providers/`).
- **Issue IDs:** **CON-004**

### `lib/features/connection/presentation/widgets/diagnostics/active_malfunction_actions.dart` (41، 37)
- **المسؤولية:** 3 أزرار إرشادية.
- **Issue IDs:** —

### `lib/features/connection/presentation/widgets/diagnostics/event_card.dart` (72، 65)
- **المسؤولية:** بطاقة حدث.
- **النصوص الخشنة:** `'DETECTED'` (سطر 55)، `'MALFUNCTION'`/`'DATA_DIAGNOSTIC'` (سطر 25) ⇒ §C.
- **Issue IDs:** — (محتوى)

### `lib/features/connection/presentation/widgets/diagnostics/stat_row.dart` (58، 51)
- **المسؤولية:** 5 بطاقات إحصائية.
- **النصوص الخشنة:** `'ACTIVE DIAG'`, `'ACTIVE MALF'`, `'TOTAL DIAG'`, `'TOTAL MALF'` (سطور 24–27)، بينما `'active'` وحده مترجَم (سطر 23) ⇒ §C.
- **Issue IDs:** — (محتوى)

### `lib/features/connection/presentation/widgets/dialogs/manual_mode_reason_dialog.dart` (57، 51)
- **المسؤولية:** حوار سبب §395.34، مترجَم بالكامل ✓.
- **Issue IDs:** —

---

## A.5 `lib/features/home/**` (5 ملفات)

### `lib/features/home/presentation/providers/dashboard_provider.dart` (224، 202)
- **المسؤولية الفعلية:** تجميع **ثلاث features** في `DashboardData`: يستمع لـ `authStateProvider` (AUTH)، `vehicleProvider` (VEHICLE)، `codriverProvider` (CODRIVER)، ويستورد من LOGS: `logs/domain/daily_form_rules.dart` (`joinFormList`) و`logs/domain/entities/daily_form_data.dart`.
- **المعلنة:** home/presentation/providers
- **الفعلية:** **وحدة "ترويسة جلسة التطبيق" مشتركة بفعل الأمر** — يستهلكها `account_page.dart:7` و`eld_connection_page.dart:11` و`home_page.dart:40`.
- **الحالة:** مخالفة عالية (HOME تحوّل إلى طبقة समनاد غير معلنة).
- **Issue IDs:** **HOM-001**, **HOM-004**

### `lib/features/home/presentation/providers/home_provider.dart` (66، 63)
- **المسؤولية:** تعريف قائمة الكشّاف + `menuProvider`.
- **المسؤولية_Zائدة:** `import '../../../../../routes.dart';` (سطر 3) —/providers داخل feature يستورد جذر التطبيق ⇒ **دورة** مع `routes/home_routes.dart` الذي يستورد صفحات home.
- **Issue IDs:** **HOM-003**

### `lib/features/home/presentation/pages/home_page.dart` (219، 206)
- **المسؤولية الفعلية:** (أ) استضافة صفحتي HOS كتبويبات داخلية: `StatusDashboardPage()`, `RecapPage()` (سطور 30–35)؛ (ب) `DrivingLockScreen` من HOS؛ (ج) `developerBypassDrivingScreenProvider` (سطر 24) — **مفتاح تجاوز لشاشة منع القيادة** بلا حارس `kDebugMode`؛ (د) منطق تجميع نص الترووية (سطور 56–65).
- **ملاحظة:** `import 'package:geolocator/geolocator.dart';` (سطر 17) غير مستخدم في الملف.
- **Issue IDs:** **HOM-002**, **HOM-004**, **HOM-003**

### `lib/features/home/presentation/widgets/eld_drawer.dart` (149، 146)
- **المسؤولية:** الكشّاف + حوار تسجيل الخروج الذي ينفّذ `authStateProvider.notifier.logout()` ثم `router.go(AppRoutes.login)`.
- **المسؤولية_Zائدة:** widget داخل feature يستورد `routes.dart` + يستدعي mutation في feature AUTH ⇒ **الهيكلي (shell) مملوك لميزة**.
- **Issue IDs:** **HOM-003**, **HOM-005**

### `lib/features/home/presentation/widgets/eld_bottom_nav.dart` (100، 92)
- **المسؤولية:** شريط تبويب Available/Recap ✓ مترجَم بالكامل.
- **Issue IDs:** —

---

## A.6 ميزات متنوعة

### `lib/features/onboarding/presentation/pages/onboarding_page.dart` (183، 170)
- **المسؤولية:** 3 شرائح Onboarding + `setOnboardingSeen()` + `context.goNamed('splash')`.
- **المسؤولية_Zائدة:** كتابة في `LocalStorageService` من widget (مقبولة: أمر تهيئة的一次ي)، والتنقّل صحيح عبر GoRouter ✓.
- **Issue IDs:** —

### `lib/features/permissions/presentation/pages/permissions_page.dart` (301، 276)
- **المسؤولية الفعلية:** استدعاء **`permission_handler` مباشرةً** (5 صلاحيات) + كتابة `setState` + تجاوز التنقل إلى `login` بـ `goNamed`.
- **الحالة:** presentation-only feature بلا طبقة data ⇒ لا يمكنها العمل بشكل نظيف؛ لكن الحجم صغير. المشكلة الحقيقية: **الصفحة كلها عربية hardcoded** بينما التطبيق يدعم ar/en/es ⇒ §C.
- **Issue IDs:** — (محتوى؛ §C)

### `lib/features/settings/presentation/pages/settings_page.dart` (214، 202)
- **المسؤولية:** اللغة، السمة، عنوان الخادم (`setServerUrl` + `setBackendType('eld')`).
- **المسؤولية_Zائدة:** يستورد `home/presentation/widgets/eld_drawer.dart` (سطر 12) و`account/presentation/providers/account_provider.dart` (سطر 14)؛ ويشتقّ لغة الخادم بالنصوص الحرفية (سطر 119).
- **Issue IDs:** **ACC-008**, **ACC-007** (نمط)

### `lib/features/about/presentation/pages/about_page.dart` (330، 314)
- **المسؤولية:** معلومات التطبيق + بطاقات حالة الاتصال/التشخيص.
- **المسؤولية_Zائدة:** يستورد **feature CONNECTION كاملاً**: `diagnostics_page.dart`، `hardware_alerts_provider.dart`، `hardware_status_provider.dart`، `eld_diagnostics_section.dart` (سطور 16–19) — أي نبني واجهة feature أخرى داخل صفحة About.
- **Issue IDs:** **ACC-008** (نمط QUEST: shell widget owned by feature)، **ROU-001**

---

## A.7 `lib/domain/**` (9 ملفات — الدومين المشترك)

> **ملاحظة التوليد المُطلَبة:** كل الملفات تعتمد `freezed_annotation` مع `part '*.freezed.dart'`. **`driver_account.dart` وحده يحمل `part 'driver_account.g.dart'`** (أي `json_serializable`) — ⇒ **DOM-003**.

### `lib/domain/account/driver_account.dart` (36، 31)
- **الاستيرادات (كاملة):** `freezed_annotation` فقط.
- **المسؤولية الفعلية:** DTO شبكة صريح: `@freezed abstract class DriverAccount` + `factory DriverAccount.fromJson(...)` مع `part 'driver_account.g.dart'` (سطور 3–4).
- **الطبقة الفعلية:** **data (DTO) داخل مجلد domain**.
- **Issue IDs:** **DOM-003**

### `lib/domain/config/server_config.dart` (85، 71)
- **الاستيرادات (كاملة):** `freezed_annotation` فقط ✓.
- **المسؤولية:** `enum BackendType` + `ServerConfig` (بدون `.g.dart`).
- **المسؤولية_Zائدة:** `static String normalizeUrl(String url)` (سطور 49–58) **سياسة تطبيع عنوان** داخل DTO، وتضيف `https://` افتراضياً (سطر 52) — قرار أمني في domain.
- **Issue IDs:** **DOM-004** (منخفض)

### `lib/domain/duty_status/duty_status_code.dart` (99، 84)
- **الاستيرادات (كاملة — مخالفة):**
  ```dart
  7: import 'package:flutter/widgets.dart';
  8: import '../../../core/utils/logger.dart';
  ```
- **المسؤولية_Zائدة:** `Color get displayColor` (السطور 75–88) بـ **قيم hex مكرَّرة حرفياً من `core/theme/app_colors.dart`**، و`AppLogger.warning(...)` داخل `fromAny` (سطر 45).
- **الطبقة الفعلية:** presentation + logging داخل **نواة دومين مشتركة** يستوردها `backend/contracts` و`backend/adapters`.
- **Issue IDs:** **DOM-001** (عالٍ)

### `lib/domain/duty_status/status_dashboard.dart` (202، 167)
- **الاستيرادات (كاملة):** `freezed_annotation`، `../shared/value_objects.dart`، `duty_status_code.dart`.
- **الحالة:** نقي ✓ (والت970 dépendance على `duty_status_code.dart` تنقل Colour إلى العقد).
- **Issue IDs:** يرث أثر **DOM-001**

### `lib/domain/duty_status/weekly_recap.dart` (45، 40)
- **الاستيرادات (كاملة):** `freezed_annotation`، `status_dashboard.dart show CycleRule`.
- **الحالة:** نقي ✓.
- **Issue IDs:** —

### `lib/domain/hardware/telemetry_reading.dart` (47، 39)
- **الاستيرادات (كاملة):** `freezed_annotation`، `../shared/value_objects.dart`.
- **الحالة:** نقي ✓.
- **Issue IDs:** —

### `lib/domain/inspection/dot_inspection.dart` (142، 131)
- **الاستيرادات (كاملة):** `freezed_annotation`، `../shared/value_objects.dart`.
- **الحالة:** نقي ✓. **لكنه DTO شبكة صريح بحقول نصية جاهزة للعرض (`screenTitle`, `guidanceText`, `carrierComplianceStatement`)** — أي "read projection" لا كيان نطاقي ⇒ يتقاطع مع DOM-003.
- **Issue IDs:** —

### `lib/domain/shared/value_objects.dart` (70، 56)
- **الاستيرادات (كاملة):** `freezed_annotation` فقط ✓.
- **المسؤولية:** 12 معرّفاً مميَّزاً (`DriverId`, `DeviceId`, …).
- **الحالة:** نقي ✓ ومتماسك — **النواة الصلحة الوحيدة في `lib/domain/`**.
- **Issue IDs:** —

### `lib/domain/signature/signature.dart` (43، 35)
- **الاستيرادات (كاملة):** `freezed_annotation`، `../shared/value_objects.dart`.
- **الحالة:** نقي ✓.
- **Issue IDs:** —

---

# B. Detailed issues

--------------------------------------------------
### ISSUE AUTH-001: سياسات حدود الهوية وتسلسل التخزين موضوعة داخل `presentation/providers`
- **Severity:** High
- **Category:** Layer inversion / State-management responsibility
- **Location:** `lib/features/auth/presentation/providers/auth_state_provider.dart:145`, `:147-151`, `:260`, `:292`, `:306`
- **Evidence:**
```dart
// lib/features/auth/presentation/providers/auth_state_provider.dart:145
  Future<void> _storageChain = Future<void>.value();

// :147-151
  Future<void> _runOrdered(Future<void> Function() op) {
    final run = _storageChain.then((_) => op());
    _storageChain = run.catchError((_) {});
    return run;
  }

// :260
          final epoch = SessionEpoch.bump();

// :292
    final epoch = SessionEpoch.bump();
```
- **Current behavior:** الـ `StateNotifier` الموجود في طبقة presentation يملك: (أ) سلسلة تسلسل تسلسلية لكل عمليات حفظ/مسح الجلسة لمنع `clear(A)` المتأخر من محو `save(B)`؛ (ب) صلاحية استدعاء `SessionEpoch.bump()` عند حدود الهوية (نجاح دخول، بدء خروج، طرد إجباري).
- **Why problematic:** هذان قراران *سياسيان* لا علاقة لهما بـ "عرض الحالة". إضافةً، `SessionEpoch` كائن `static` قابل للتغيّر في `core/session/session_epoch.dart:19` يُقرأ من طبقات أخرى (مثل `AuthInterceptor`)، فالقرار المملوك لـ presentation أصبح عقداً عامّاً لا يمكن اختباره أو تبديله دون طبقة العرض.
- **Violated principle:** قاعدة الاعتماد (Dependency Rule): `presentation` يجب أن تنسّق بين `domain`/`application`، لا أن تُعرّف سياستهما. + مبدأ "Policy vs. Mechanism".
- **Current owner:** `AuthNotifier` (presentation).
- **Correct owner:** `domain/session/session_boundary_policy.dart` أو `application/session/session_coordinator.dart`؛ يبقى `AuthNotifier` مستهلكاً لها.
- **Consequences:** (1) استخراج `AuthNotifier` في اختبار وحدة يفرض تهيئة Flutter/Riverpod؛ (2) أي مالك بديل للهوية (أمر طرد إداري مثلاً) سيحتاج لنسخ منطق الـ bump؛ (3) `_storageChain` مربوط بحNotifier واحد، بينما `_localDataSource` قد يُشارك.
- **Recommended correction:** استخرج `SessionCoordinator` في `features/auth/application/session/session_coordinator.dart` يحوي `bump()`, `_storageChain`, `_runOrdered`، واجعل `AuthNotifier` ينفّذ عبره.
- **Related files:** `lib/core/session/session_epoch.dart`, `lib/features/auth/domain/usecases/logout_usecase.dart`, `lib/features/auth/presentation/providers/auth_state_provider.dart`
- **Confidence:** CONFIRMED (المواضع والأكواد مقتبسة حرفياً).

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
- **Why problematic:** (أ) `Password` يسكن في `domain` فيُفترض أنه يحمل قاعدة كلمة المرور، لكنه لا يحمل شيئاً؛ (ب) القواعد الحقيقية لتطبيقها في `login_usecase.dart` (مرتين: widget + usecase) ⇒若是 أُضيفت قاعدة تعقيد مستقبلاً ستُطبَّق في طبقة واحدة فقط وتُنسى الأخرى؛ (ج) مفاتيح الترجمة داخل domain تربط النموذجLocalization.
- **Violated principle:** Value Object يجب أن يكون مغلقاً وآمناً وقابلاً للمقارنة؛ Domain لا يعتمد على l10n.
- **Current owner:** `features/auth/domain/entities/value_objects/`.
- **Correct owner:** القاعدة (policy) تبقى في domain؛ **الترجمة** تُنقل إلى presentation عبر `code` لا `message`.
- **Consequences:** (1) استنزاف trust البنية: كائن كلمة المرور لا يوفّر أي حماية؛ (2) تكرار التحقق في موضعين؛ (3) اقتران domain بنظام الترجمة.
- **Recommended correction:** اجعل `errorMessage` يُرجع `enum ValidationCode`، وأضف `operator ==`/`hashCode` و`toString()` حاجب لـ `Password`.
- **Related files:** `lib/features/auth/domain/usecases/login_usecase.dart:19-29`, `lib/features/auth/presentation/widgets/login_form.dart:96-105`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE AUTH-004: `forgot_password_form.dart` يتجاوز طبقات feature auth ويستدعي عقد البنية التحتية مباشرة، ويتجاوز الترجمة
- **Severity:** High
- **Category:** Layer skip / Localization bypass
- **Location:** `lib/features/auth/presentation/widgets/forgot_password_form.dart:4`, `:51-54`, `:38`
- **Evidence:**
```dart
// lib/features/auth/presentation/widgets/forgot_password_form.dart:4
import '../../../../backend/providers/backend_providers.dart';

// :51-54
    final result = await ref.read(authBackendProvider).requestPasswordReset(
          email: email,
          serverUrl: ref.read(localStorageProvider).serverUrl,
        );

// :38
    if (email.isEmpty || !email.contains('@')) {
```
- **Current behavior:** Widget داخل feature `auth` يتجاوز `domain/repositories` و`data/` بالكامل ويصل إلى `AuthBackend` (عقد بنية تحتية في `lib/backend/`)، ويقرأ `LocalStorageService` مباشرة، ويطبّق قاعدة تحقق مخصّصة (`contains('@')`) بدل `LoginIdentifier` الموجود في نفس الـ feature.
- **Why problematic:** هذه العملية (استعادة كلمة المرور) هي **use case م_missing تماماً** في `auth`. كل طبقة أعلى منها (usecase / repository / datasource) لا تعرف بوجودها ⇒ لا يمكن اختبارها ولا تتبّعها ولا توحيد أسلوب الأخطاء. كما أن قاعدة التحقق موحّدة في مكانين.
- **Violated principle:** لم تُخترق طبقة فقط، بل قُفزت **طبقتان** (domain + data). + مبدأ DRY في التحقق.
- **Current owner:** widget.
- **Correct owner:** `ResetPasswordUseCase` في `features/auth/domain/usecases/reset_password_use_case.dart` يمرّر `LoginIdentifier` ويستدعي `AuthRepository.requestPasswordReset()`؛ التنفيذ يغلّف `AuthBackend` ويطبّق `NetworkInfo`/`guardedNetwork`.
- **Consequences:** (1) استعادة كلمة المرور خارج أي مسار مراقبة/تحليل/تسلسل؛ (2) سلوكها يختلف عن `login` في معالجة الشبكة؛ (3) النصوص العربية/الإنجليزية مدمجة في الـ widget (§C-2).
- **Recommended correction:** أنشئ use-case + repository method، واجعل الـ widget يستهلك `Either<Failure, Unit>`.
- **Related files:** `lib/features/auth/presentation/pages/auth_page.dart:157`, `lib/features/auth/domain/repositories/auth_repository.dart`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE AUTH-005: `splash_page.dart` منسّق إقلاع على مستوى التطبيق موضوع داخل feature المصادقة
- **Severity:** High
- **Category:** Wrong layer / Cross-feature orchestration
- **Location:** `lib/features/auth/presentation/pages/splash_page.dart:32`, `:47-48`, `:62`, `:67`, `:9`
- **Evidence:**
```dart
// lib/features/auth/presentation/pages/splash_page.dart:9
import 'package:permission_handler/permission_handler.dart';

// :47-48
      final locationGranted = await Permission.location.isGranted;
      final bluetoothGranted = await Permission.bluetooth.isGranted;

// :67
    context.goNamed(isLoggedIn ? 'connection' : 'login');
```
- **Current behavior:** صفحة داخل feature `auth` تقرأ `localStorageProvider.onboardingSeen` (قرار feature onboarding)، ثم تستدعي `permission_handler` مباشرة (feature permissions)، ثم `authStateProvider.checkAuthStatus()` (auth)، ثم تختار الوجهة بين `/connection` (feature connection) و`/login`.
- **Why problematic:** Four features orchestrated from one page in feature #5. `permission_handler` يُستدعى مباشرة دون port في `core/services`، فيصبح Widget قابلاً للاختبار فقط عبر instrumentation. كما أن `SplashPage` هي فعلياً **نقطة دخول التطبيق** (`AppRoutes.splash = '/'`).
- **Violated principle:** Feature slice must be self-contained; app-level bootstrap belongs to `lib/app/`.
- **Current owner:** `features/auth/presentation/pages/splash_page.dart`.
- **Correct owner:** `lib/app/bootstrap/app_bootstrap.dart` (منسّق) + `lib/features/permissions/data/permissions_service.dart` (port التغليف).
- **Consequences:** (1) أي تغيير في ترتيب الإقلاع يمسّ feature auth؛ (2) permission_handler موزّع في مكانين (splash + permissions_page)؛ (3) اختبار unit لمسار الإقلاع مستحيل.
- **Recommended correction:** `AppBootstrap` في `lib/app/` يستهلك `PermissionsService` (من feature permissions) + `authStateProvider` + `localStorageProvider`، ويصدر نتيجة (`BootstrapResult`)؛ الصفحة مجرد عارض.
- **Related files:** `lib/features/permissions/presentation/pages/permissions_page.dart:36-40`, `lib/app/orchestrators/tracking_orchestrator.dart`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE AUTH-006: `auth_providers.dart`presentation يعيد تصدير جذر التركيب
- **Severity:** Low
- **Category:** Dependency direction (barrel abuse)
- **Location:** `lib/features/auth/presentation/providers/auth_providers.dart:3`
- **Evidence:**
```dart
// lib/features/auth/presentation/providers/auth_providers.dart:3
export '../../../../core/di/app_providers.dart' show traccarAuthRepositoryProvider, authLocalDataSourceProvider;
```
- **Current behavior:** `core/di/app_providers.dart` هو الـ composition root الوحيد المسموح له باستيراد `*_impl.dart` (حسب تعليق الملف نفسه، السطر 17–19). هذا الـ barrel يجعل مستهلكي presentation_guid الم Orchid unaware أنهم يتكلمون مع root.
- **Why problematic:** نمط شائع لكنه يخفي حدود DI الحقيقية ويجعل `presentation` يبدو مسموحاً باستيراد `core/di`. كل مستورد لـ `auth_providers.dart` وراثياً مرتبط بكل ما يُضاف إلى `app_providers.dart` لاحقاً.
- **Violated principle:** Barrels يجب أن تعكس حدود Mughal المodule لا تُخفيها.
- **Current owner:** presentation barrel.
- **Correct owner:** import مباشر من `core/di/app_providers.dart` عند الحاجة، أو إعادة تسمية الملف إلى `auth_di.dart` في `core/di/`.
- **Consequences:** تلاصق مؤجل، لا عطل حالي.
- **Recommended correction:** احذف الملف واستورد مباشرة، أو انقله إلى `core/di/auth_di.dart`.
- **Related files:** `lib/core/di/app_providers.dart:10`, `lib/core/di/auth_local_data_source_provider.dart`
- **Confidence:** CONFIRMED (الأثر منخفض)

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
- **Why problematic:** عند إضافة قاعدة (مثلاً `password.length >= 8`)، هناك احتمال أن يُعدَّل أحد الموقعين فقط — والـ widget يُعطي，用户 رسالة "قصيرة" بينما الـ usecase يرفض بصمت.
- **Violated principle:** مصدر واحد للحقيقة على مستوى القاعدة.
- **Current owner:** كلاهما.
- **Correct owner:** `LoginUseCase` (المصدر الوحيد)؛ الـ widget يستدعيه ويتلقى `ValidationFailure` ويفحصه لعرضه حقل-بـحقل.
- **Consequences:** ازدواج صيانة؛ احتمال انحراف سلوكي.
- **Recommended correction:** اجعل `LoginUseCase` يُرجع `ValidationFailure(fieldErrors: …)` واربطه بـ `FormField` validator عبر `Form.of(context)`.
- **Related files:** `lib/core/error/failure.dart:92-99` (يوجد `fieldErrors` — غير مستخدم في auth!)
- **Confidence:** CONFIRMED (ملاحظة: حقل `fieldErrors` في `ValidationFailure` غير مستخدم في أي مكان — راجع §C-3)

--------------------------------------------------
### ISSUE ACC-001: `application/usecases/update_rules_use_case.dart` يستورد Riverpod ويعرّف DI ويعتمد على presentation لميزة أخرى
- **Severity:** High
- **Category:** Layer inversion (multi-directional)
- **Location:** `lib/features/account/application/usecases/update_rules_use_case.dart:1`, `:9`, `:52-61`
- **Evidence:**
```dart
// lib/features/account/application/usecases/update_rules_use_case.dart:1
import 'package:flutter_riverpod/flutter_riverpod.dart';

// :9
import '../../../auth/presentation/providers/auth_state_provider.dart';

// :52
final updateRulesUseCaseProvider = Provider<UpdateRulesUseCase>((ref) {
  ...
  final user = ref.watch(authStateProvider).user;
  if (user == null) {
    throw Exception('User not authenticated');
  }
  return UpdateRulesUseCase(backend, storage, user.id);
});
```
- **Current behavior:** Use-case في طبقة `application` (التي يجب أن تكون إطاراً-مستقلاً عن Flutter) يستورد `flutter_riverpod`، ويُعرّف `Provider` خاصاً به (حقن اعتماديات في نفس الطبقة)، ويسحب هوية السائق من **presentation** لميزة أخرى (AUTH).
- **Why problematic:** ثلاث انقلات في 62 سطراً: (أ) `application → framework DI`؛ (ب) `application → presentation(Auth)`؛ (ج) الـ provider يرمي `Exception` عند بناءه ⇒ **الخطأ يقع فيComposition لا في التشغيل**.
- **Violated principle:** Dependency Rule صارمة: `presentation → application → domain`. هنا `application → presentation`، وهو عكس المسار.
- **Current owner:** `UpdateRulesUseCase` file.
- **Correct owner:** (أ) المُركِّب في `core/di/` أو `features/account/data/providers/`؛ (ب) `driverId` يجب أن يُمرَّر كوسيط من presentation، أو يُؤخذ من `application`-level session abstraction لا من `authStateProvider`.
- **Consequences:** (1) `application` لا يمكن اختبارها خارج Flutter؛ (2) use-case مرتبطة ببنية Riverpod وحالة UI؛ (3) `throw Exception` في وقت البناء = فشل Composition لكل من يقرأ `rulesScreenProvider`.
- **Recommended correction:** احذف السطر 1 و52–61 من الملف؛ انقل `updateRulesUseCaseProvider` إلى `lib/features/account/data/providers/`، وغيّر `execute(request)` إلى `execute({required DriverId driverId, required RulesScreenUpdateRequest request})`.
- **Related files:** `lib/features/account/presentation/providers/rules_screen_provider.dart`, `lib/features/account/presentation/pages/rules_page.dart:57`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE ACC-002: `rules_page.dart` (presentation) يستورد DTO محوّل من `backend/adapters`
- **Severity:** High
- **Category:** Layer skip (presentation → data adapter)
- **Location:** `lib/features/account/presentation/pages/rules_page.dart:13`, `:65-73`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/rules_page.dart:13
import '../../../../backend/adapters/eld_engine/models/rules_screen_dto.dart';

// :65
      final request = RulesScreenUpdateRequest(
        cycleRule: _cycleRule!,
        cargoType: _cargoType!,
        restart: _restart!,
        restBreak: _restBreak!,
        sixteenHourException: sixteenEligible
            ? _sixteenHourException!
            : model.sixteenHourException,
      );
```
- **Current behavior:** Widget presentation ينشئ كائن طلب **من محوّل محوّل (adapter)某一个 من `backend/adapters/eld_engine/`** — وهو ليس عقداً (contract) بل تنفيذ露出一丝的 التنفيذ لـ backend محدد.
- **Why problematic:** (أ) presentation أصبح مرتبطاً بتنفيذ backend واحد (ELD Engine) — تبديله إلى `mock` أو غيره يكسر الواجهة؛ (ب) `RulesScreenUpdateRequest` كان يجب أن يكون في `application/` (وهو فعلاً في نفس الحزمة المستورَدة من `application/usecases`)؛ (ج) هذا هو **الاستوراد الوحيد** الذي يكسر القاعدة، لكنه يكسرها في places حرجة.
- **Violated principle:** presentation يعتمد على contracts لا على adapters.
- **Current owner:** `rules_page.dart`.
- **Correct owner:** انقل `RulesScreenUpdateRequest` إلى `lib/features/account/application/models/` واستورده من هناك.
- **Consequences:** (1) ارتباط presentation بتنفيذ backend محدد؛ (2) difficulty اختبار الواجهة بـ fake.
- **Recommended correction:** نقل الكيان إلى `application/models/rules_screen_update_request.dart` وتحديث الاستيراد.
- **Related files:** `lib/features/account/application/usecases/update_rules_use_case.dart:23`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE ACC-003: `rules_screen_provider.dart` يرمي `Exception(l10nKey)` ⇒ كل أخطاء القواعد تُعرض كـ«خطأ شبكة»
- **Severity:** High
- **Category:** Error-contract violation (نموذج) + bug سلوكي مؤكد
- **Location:** `lib/features/account/presentation/providers/rules_screen_provider.dart:13`, `:22`؛ 소비자: `lib/features/account/presentation/pages/rules_page.dart:229-232`؛ المُصيِّر: `lib/core/error/user_facing_message.dart:7-25`
- **Evidence:**
```dart
// lib/features/account/presentation/providers/rules_screen_provider.dart:13
  if (user == null) {
    throw Exception('User not authenticated');
  }

// :21-24
  return result.fold(
    (failure) => throw Exception(failure.l10nKey),
    (model) => model,
  );
```
```dart
// lib/core/error/user_facing_message.dart:7
String anyErrorUserMessage(Object error, {required AppLocalizations loc}) {
  if (error is AppError) return appErrorUserMessage(error, loc: loc);
  if (error is Failure) { ... }
  if (error is String) { ... }
  return loc.errRequestFailedNetwork;   // ← السقوط هنا
}
```
- **Current behavior:** `getRulesScreen` يرجع `AppError` (لديه `l10nKey`)، لكن الـ provider يحوّله إلى `Exception`. في `rules_page.dart` يُمرَّر إلى `anyErrorUserMessage(err, ...)`، وهو لا يتعامل مع `Exception` ⇒ **يسقط دائماً إلى `loc.errRequestFailedNetwork`**.
- **Why problematic:** ثلاث مشاكل: (أ) **السلوك**: كل فشل في شاشة القواعد — صلاحية، notFound، تعارض — يُعرض للسائق كـ«فشل طلب عبر الشبكة»؛ (ب) مفتاح الترجمة يُرمى في `Exception.toString()` ويتجاهَل تماماً؛ (ج) الفقدان محتمل أيضاً في `throw Exception('User not authenticated')`.
- **Violated principle:** خطأ typed يعبر channel typed — لا تحوّل `AppError` إلى `Exception` في provider.
- **Current owner:** `rules_screen_provider.dart`.
- **Correct owner:** `throw failure;` مباشرة (الـ `FutureProvider` يحمل `Object`، و`AppError` типه كافٍ لـ `appErrorUserMessage`).
- **Consequences:** (1) **خطأ مؤكد للمستخدم**: رسالة خاطئة تماماً؛ (2) `l10nKey` مكتوب ومهمَل — ازدواج؛ (3) النمط نفسه متكرر في `logs/data/repositories/log_repository_impl.dart` (6 مواضع) ⇒ عيب نظامي.
- **Recommended correction:** استبدل `throw Exception(failure.l10nKey)` بـ `throw failure;` في كل الملفات المتأثرة.
- **Related files:** `lib/features/logs/data/repositories/log_repository_impl.dart:85,115,372,450,471,492`
- **Confidence:** CONFIRMED (المسار من `Exception` إلى `errRequestFailedNetwork` تم التحقق منه سطراً سطراً في `user_facing_message.dart`)

--------------------------------------------------
### ISSUE ACC-004: `account_provider` يخزّن `l10nKey`/`e.toString()` في الحالة، والصفحة تعرضه خاماً
- **Severity:** High
- **Category:** Localization bypass + Raw exception exposure
- **Location:** `lib/features/account/presentation/providers/account_provider.dart:90`, `:95`, `:119`, `:130`؛ المستهلك: `lib/features/account/presentation/pages/account_page.dart:101-105`
- **Evidence:**
```dart
// lib/features/account/presentation/providers/account_provider.dart:90
        (failure) => state = state.copyWith(isLoading: false, error: failure.l10nKey),

// :95
      state = state.copyWith(isLoading: false, error: e.toString());

// :130
      state = state.copyWith(isLoading: false, error: e.toString());
```
```dart
// lib/features/account/presentation/pages/account_page.dart:101
                          child: Text(
                            accountState.error!,
                            style: context.styles.error,
                            textAlign: TextAlign.center,
                          ),
```
- **Current behavior:** عند فشل `getMyAccount`، يُخزَّن **مفتاح الترجمة** (`networkTimeout`, `sessionExpired`, `notFound`, …) في `AccountState.error` ثم يُعرض كـ`Text` خام. وفي حال الاستثناء العام يُخزَّن `e.toString()` ويُعرض كذلك.
- **Why problematic:** السائق يرى حرفياً `networkTimeout` أو `Exception: ...` على الشاشة. هذا يناقض بوضوح قرار المشروع المعلن في `user_facing_message.dart:6`: «Never the exception, stack, or `toString()`».
- **Violated principle:** Localization boundary + raw exception policy.
- **Current owner:** provider + page.
- **Correct owner:** (أ) `AccountState.error` يحمل `AppError` لا `String`؛ (ب) `account_page.dart` يمرّره إلى `anyErrorUserMessage(err, loc: context.loc)`.
- **Consequences:** (1) **خطأ مؤكد**: رسائل غير مترجمة وغير مقروءة؛ (2) تسريب استثناءات إلى UI؛ (3) تكرار: `AppError` → `l10nKey` في provider ثم `l10nKey` → نص في UI = نقرتان بلا فائدة.
- **Recommended correction:** `final AppError? error;` في `AccountState`، واعرض عبر `appErrorUserMessage`.
- **Related files:** `lib/core/error/app_error.dart:49`, `lib/core/error/user_facing_message.dart:6`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE ACC-005: `rules_screen_model` (application) يعتمد على `core/config`، والمنطق مكرَّر مع الصفحة
- **Severity:** Medium
- **Category:** Wrong dependency + duplicated interpretation
- **Location:** `lib/features/account/application/models/rules_screen_model.dart:1`, `:59-69`؛ المكرر: `lib/features/account/presentation/pages/rules_page.dart:97-112`
- **Evidence:**
```dart
// lib/features/account/application/models/rules_screen_model.dart:1
import '../../../../core/config/hos_configuration.dart';

// :59
  bool _isSettingAllowed(List<String> keys) {
    for (final key in keys) {
      final v = fixedSettings[key];
      if (v == null) continue;
      if (v is bool) return v;
      final t = v.toString().trim().toLowerCase();
      if (t == 'allowed' || t == 'true') return true;
      if (t == 'forbidden' || t == 'false' || t.isNotEmpty) return false;
    }
    return false;
  }
```
```dart
// lib/features/account/presentation/pages/rules_page.dart:97
  String _serverSetting(
    BuildContext context,
    Map<String, dynamic> settings,
    List<String> keys,
  ) {
```
- **Current behavior:** نموذج application يستورد `HosConfiguration` (إعداد بنية تحتية في `core/config`). وفي الوقت نفسه، **نفس منطق تفسير الأسماء البديلة** (`personalConveyance` / `personalConveyanceEnabled`، …) مُنفَّذ مرتين: مرة في النموذج (`_isSettingAllowed`) ومرة في الصفحة (`_serverSetting`).
- **Why problematic:** (أ) نموذج application يعتمد على طبقة إعداد؛ (ب) منطق تفسير حمولة الخادم المرنة (سِلّمWire: `bool` أو `"Allowed"` أو `"true"`) — **وهذا عمل mapper** — مكتوب في نموذج application وآخر في presentation؛ أي تعديل في الخادم يحتاج تعديلاً في موضعين ن divergently.
- **Violated principle:** Mapper-layered parsing belongs to data; application models depend on contracts.
- **Current owner:** `application/models` + `presentation/pages`.
- **Correct owner:** `lib/features/account/data/mappers/rules_settings_mapper.dart` ينتج `Map<String, SettingVerdict>` مطبَّعاً (enum: allowed/forbidden/unknown)؛ النموذج والصفحة يستهلكان نفس النوع.
- **Consequences:** ازدواج + مسارات تفسّر مختلفة لنفس الحمولة (`"Allowed"` → true في موضع، ونص في موضع آخر).
- **Recommended correction:** استخرج `SettingVerdict` mapper واحد.
- **Related files:** `lib/features/account/presentation/pages/rules_page.dart:373-417`, `lib/backend/adapters/eld_engine/mappers/rules_screen_mapper.dart`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE ACC-006: `info_packet_page.dart` يستهلك provider من presentation لميزة INSPECTION
- **Severity:** Medium
- **Category:** Cross-feature coupling to implementation
- **Location:** `lib/features/account/presentation/pages/info_packet_page.dart:7-8`, `:39`؛ المزوّد: `lib/features/inspection/presentation/providers/inspection_provider.dart:124-136`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/info_packet_page.dart:7-8
import '../../../inspection/domain/inspection_transfer.dart';
import '../../../inspection/presentation/providers/inspection_provider.dart';

// :39
          _PacketStatus(packet: ref.watch(informationPacketProvider)),
```
- **Current behavior:** صفحة ACCOUNT تستورد **مزوّداً من طبقة presentation لميزة أخرى**، وهو بدوره يستورد `InspectionRepository` وينفّذ الطلب.
- **Why problematic:** `informationPacketProvider` هو ليس عقداً — هو implementation داخل `presentation`. النتيجة: (أ) ACCOUNT مربوط بالتنفيذ لا بالعقد؛ (ب) الـ lifecycle (autoDispose + cacheFor 5د) مملوك لـ INSPECTION؛ (ج) `_PacketStatus` يستهلك `AsyncValue<InformationPacketView>` مباشرة، فيضطر presentation Knowing about provider semantics.
- **Violated principle:** Cross-feature communication عبر العقد/المستودع، لا عبر provider implementations.
- **Current owner:** `informationPacketProvider` (inspection).
- **Correct owner:** إما (أ) shared read-contract في `lib/domain/shared/` مع implementation فيapiданьinspection، أو (ب) `InformationPacketPage` في feature inspection نفسها (لأن الحزمةInspection حسب SRS هي مالكها).
- **Consequences:** (1) لا يمكن لـ ACCOUNT الاختبار بدون pullsentireinspection؛ (2) تعديل cacheدقيقة في inspection يغيّر سلوك ACCOUNT.
- **Recommended correction:** انقل "حزمة المعلومات" إلى feature inspection (المالك rightful) أو استخرج provider إلى `lib/domain`/`core` مشترك مع عقد.
- **Related files:** `lib/routes/account_routes.dart:26-29` (المسار في account_routes لكن المضيف في inspection)
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE ACC-007: `account_page.dart` يقرأ اسم السائق من مزوّد HOME، ويطابق أسماء اللغات بنصوص حرفية
- **Severity:** Medium
- **Category:** Cross-feature dependency + presentation-side mapping logic
- **Location:** `lib/features/account/presentation/pages/account_page.dart:7`, `:32`, `:115-119`, `:179-182`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/account_page.dart:7
import '../../../home/presentation/providers/dashboard_provider.dart';

// :32
    final dashboard = ref.watch(dashboardDataProvider);

// :116-118
                      _buildInfoRow(
                        context,
                        loc.sortByName,
                        dashboard.driverName,
                      ),

// :179-182
                                       String code = 'en';
                                       if (newValue.toLowerCase() == 'arabic' || newValue == 'العربية') code = 'ar';
                                       if (newValue.toLowerCase() == 'spanish' || newValue == 'español') code = 'es';
                                       ref.read(localeProvider.notifier).setLocale(code);
```
- **Current behavior:** (أ) الصفحة تعرض اسم السائق من `dashboardDataProvider` (HOME) — بينما نفس الصفحة تملك `authStateProvider.user!.fullName` عبر `accountProvider`، و`accountState.accountData.email`؛ (ب) منطق ترجمة **اسم اللغة النصي إلى رمز اللغة** مكتوب داخل معالج `onChanged` في الـ Widget.
- **Why problematic:** (أ) ACCOUNT صارت تعتمد على تجميع HOME — وهو ما يجعل HOME "طبقة علوية" غير معلنة (انظر HOM-001)؛ (ب) منطق mapping اللغة (سلوك تطبيق) في Widget؛ (ج) النصوص الحرفية `'arabic'`، `'العربية'`، `'español'` لا تغطي أي لغة أخرى — DAO يسقط بصمت إلى `'en'`.
- **Violated principle:** presentation يعرض، لا يقرّر. + duplicate source of truth.
- **Current owner:** page.
- **Correct owner:** (أ) `authStateProvider.user.fullName` مباشرة؛ (ب) `LanguageCodeMapper` في `core/localization/` يقبل `DriverAccount.availableLanguages` ويعيد رمز.
- **Consequences:** (1) ثلاث مصادر للاسم؛ (2) تعطُّل صامت عند إضافة لغة جديدة؛ (3) خيوط coupling متسلسلة.
- **Recommended correction:** احذف الاستيراد 7 واستخدم `ref.watch(authStateProvider).user?.fullName`.
- **Related files:** `lib/features/account/presentation/providers/account_provider.dart:5`, `lib/features/home/presentation/providers/dashboard_provider.dart:4`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE ACC-008: `EldDrawer` — هيكل التطبيق (app shell) مملوك داخل feature HOME ويُستورد من 5 صفحات
- **Severity:** Medium
- **Category:** Layering inversion (shared UI owned by a feature)
- **Location:** `lib/features/home/presentation/widgets/eld_drawer.dart` — مستورد من: `account_page.dart:8`, `info_packet_page.dart:6`, `rules_page.dart:10`, `codriver_page.dart:9`, `settings_page.dart:12`, `home_page.dart:12`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/account_page.dart:8
import '../../../home/presentation/widgets/eld_drawer.dart';

// lib/features/settings/presentation/pages/settings_page.dart:12
import '../../../home/presentation/widgets/eld_drawer.dart';
```
**و** `eld_drawer.dart:137` ينفّذ mutation في feature أخرى:
```dart
// lib/features/home/presentation/widgets/eld_drawer.dart:137
              await ref.read(authStateProvider.notifier).logout();
```
- **Current behavior:** Widget التنقّل الرئيسي (الدرج الجانبي + حوار الخروج) يعيش داخل `features/home/presentation/`، بينما **خمس صفحات من أربع ميزات** تستورده لتزويد نفسها للتنقّل.
- **Why problematic:** ينتج **نجمة耦合**: أي feature لا يستطيع امتلاك screen chrome خاصاً بها دون الاعتماد على HOME. كما أن `EldDrawer` ينفّذ `authStateProvider.notifier.logout()` — أي presentation widget في feature A يستدعي mutation في feature B.
- **Violated principle:** App shell / navigation chrome belongs to `lib/app/` or `core/widgets/`, not to a feature.
- **Current owner:** `features/home/presentation/widgets/eld_drawer.dart`.
- **Correct owner:** `lib/app/shell/app_drawer.dart` مع list menu تُمرَّر من `home_provider` أو `AppRoutes`.
- **Consequences:** (1) 6 استيرادات لـ HOME من Account/Settings/Codriver/InfoPacket؛ (2) تعديل تصميم الدرج يمسّ 4 ملفات؛ (3) الصفحات ترث سلوك logout دون أن تعرف.
- **Recommended correction:** انقل `EldDrawer` إلى `lib/app/shell/`.
- **Related files:** `lib/features/home/presentation/widgets/eld_drawer.dart:60-70, 137`, `lib/features/home/presentation/providers/home_provider.dart`
- **Confidence:** CONFIRMED

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
### ISSUE COD-002: `codriver_page.dart` يستورد خمس ملفات من HOS + TRACKING لتغذية حارس واحد
- **Severity:** High
- **Category:** Cross-feature coupling (widget as orchestrator)
- **Location:** `lib/features/codriver/presentation/pages/codriver_page.dart:15-18`, `:23`, `:193-214`
- **Evidence:**
```dart
// lib/features/codriver/presentation/pages/codriver_page.dart:15-18
import '../../../hos/domain/engine/hos_rules_engine.dart';
import '../../../hos/presentation/providers/hos_engine_provider.dart';
import '../../../hos/presentation/providers/hos_provider.dart';
import '../../../tracking/presentation/providers/tracking_provider.dart';

// :193-214
                                    final hos = ref.read(hosStatusProvider);
                                    final driving = hos is HosEngineReady
                                        ? hos.update.currentStatus ==
                                              DutyStatus.driving
                                        : null;
                                    final refusal = refuseRoleSwitch(
                                      currentDriverId: ref.read(currentDriverIdProvider),
                                      coDriverId: codriverState.selectedCoDriver?.id,
                                      speedMps: ref.read(currentVehicleSpeedProvider),
                                      thresholdKmh: ref
                                          .read(hosConfigurationProvider)
                                          .movingSpeedThresholdKmh,
                                      currentStatusIsDriving: driving,
                                      trackingLive: ref
                                          .read(trackingStateProvider)
                                          .isTracking,
                                    );
```
- **Current behavior:** الـ Widget يجمع 5 قطع من 3ميزات، منها نوع معقّد (`hos is HosEngineReady ? hos.update.currentStatus : null`) ويفكّ `Optional<bool?>` منطقياً. الحارس نفسه (`role_switch_guard.dart`) نقي تماماً — لكن **عقده** يفرض على المتصل معرفة HOS internals.
- **Why problematic:** حارس «الأمان» (FMCSA) في feature CODRIVER يعتمد على (أ) نموذج حالة HOS الداخلي (`HosEngineReady`), (ب) عتبة السرعة من إعدادات HOS المحفوظة, (ج) حالة التتبع من TRACKING. ⇒ (1) حذف/تغيير HOS يكسر COD؛ (2) `refuseRoleSwitch` غير قابل لإعادة الاستخدام خارج Widget؛ (3) منطق typedefarness غير قابل للاختبار إلا ببناء Widget.
- **Violated principle:** Cross-feature reads via shared contracts (e.g. `currentVehicleSpeedProvider` should live in a shared `session`/`telemetry` contract, not in tracking presentation).
- **Current owner:** `codriver_page.dart`.
- **Correct owner:** `features/codriver/application/role_switch/role_switch_guard_use_case.dart` يقرأ من عقود مشتركة (`SessionSpeedPort`, `DutyStatusQuery`, `TrackingLiveness`), ويبقى Widget مجرد مستدعٍ.
- **Consequences:** (1) 5 حواف صريحة CODRIVER→HOS/TRACKING؛ (2) منطق الامتثالnizصعب الاختبار؛ (3) ازدواج: `vehicle_provider.dart:220-253` ينسخ نفس قواعد الحراسة لتطبيق.
- **Recommended correction:** استخرج use-case يغلّف القراءة؛ اجعل الصفحة تنادي `ref.read(roleSwitchGuardProvider).guard(...)`.
- **Related files:** `lib/features/codriver/domain/role_switch_guard.dart`, `lib/features/vehicle/presentation/providers/vehicle_provider.dart:220-253`, `lib/features/hos/presentation/providers/hos_engine_provider.dart:18,80`
- **Confidence:** CONFIRMED

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
### ISSUE COD-004: `codriver_page.dart` ينتقل بمسار literal خام `'/'home'` بـ `context.go`
- **Severity:** Medium
- **Category:** Routing bypass / fragile navigation
- **Location:** `lib/features/codriver/presentation/pages/codriver_page.dart:304`
- **Evidence:**
```dart
// lib/features/codriver/presentation/pages/codriver_page.dart:302-304
                                       ref.invalidate(teamStatusProvider);
                                       ref.invalidate(statusDashboardProvider);
                                       context.go('/home');
```
- **Current behavior:** بعد نجاح التبديل، تستخدم الصفحة `context.go('/home')` — **نص حر** بدل `AppRoutes.home`، و`go` (استبدال الحزمة) بدل `pop()`.
- **Why problematic:** (أ) كسر التماسك: تعديل `AppRoutes.home` في `routes.dart:22` لا Affect هذا الاستدعاء ⇒ route point إلى لا شيء (silent 404 حسب redirect)؛ (ب) الصفحة وصلت إلى `codriver` عبر `context.push` من `EldDrawer` (`eld_drawer.dart:68`)، فالـ `go('/home')` يمسح الحزمة كلها — سلوك مختلف عن `pop()` المتوقع بعد "successful action".
- **Violated principle:** Route constants centralization; GoRouter stack semantics.
- **Current owner:** page.
- **Correct owner:** `context.go(AppRoutes.home)` على الأقل، والأفضل: إما `context.pop()` (إن كانت modal) أو `context.go(AppRoutes.home)` موحّد.
- **Consequences:** drift كامن + سلوك back غير متوقع.
- **Recommended correction:** استبدل بالحرف `'/'` → `AppRoutes.home` وفعّل قاعد Dart lint تمنع string literals في `context.go/push`.
- **Related files:** `lib/routes.dart:22`, `lib/features/home/presentation/widgets/eld_drawer.dart:68`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE COD-005: `team_status_provider.dart` ينسّق عمليتين على الخادم ويستخرج JSON يدوياً داخل presentation
- **Severity:** Medium
- **Category:** Data orchestration in presentation
- **Location:** `lib/features/codriver/presentation/providers/team_status_provider.dart:16`, `:20-32`, `:35`
- **Evidence:**
```dart
// lib/features/codriver/presentation/providers/team_status_provider.dart:20-32
  final listed = await backend.list(
    driverId: DriverId(driverId),
    startDate: today,
    endDate: today,
    limit: 1,
  );
  final logId = listed.fold<int?>((failure) => throw failure, (json) {
    final items = json['data'];
    if (items is! List || items.isEmpty) return null;
    final first = items.first;
    final id = first is Map ? first['id'] : null;
    return id is num ? id.toInt() : int.tryParse('$id');
  });

// :35
  final result = await backend.getTeamStatus(DailyLogId(logId));
```
- **Current behavior:** الـ provider يقرأ `dailyLogsBackendProvider`، يبني نطاق اليوم، يستخرج `id` من حمولة raw، ثم ينادي `getTeamStatus`. كل ذلك في presentation.
- **Why problematic:** (أ) knowledge بالشكل الخام لـ endpoint السجلات (`json['data'][0]['id']`) في presentation؛ (ب)协调 (orchestration) من presentation؛ (ج) `throw failure` هنا أفضل من siblings، لكنه ما زال presentation يتكلم مع backend مباشرة.
- **Violated principle:** Presentation must not orchestrate multi-call backend flows.
- **Current owner:** `team_status_provider.dart`.
- **Correct owner:** `GetTeamStatusUseCase` في `codriver/domain/usecases/` (يستهلك `DailyLogsQuery` + `DriverSessionBackend`)،/provider يصبح `FutureProvider` ساذج.
- **Consequences:** (1) منطق استخراج id غير قابل لإعادة الاستخدام؛ (2) presentation مربوط بـ contractين بدل واحد.
- **Recommended correction:** استخرج use-case.
- **Related files:** `lib/features/codriver/domain/team_status.dart` (المستهلك)
- **Confidence:** CONFIRMED

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
### ISSUE CON-001: `eld_connection_page.dart` يحتوي use-case "وصلة الـ ELD" كاملاً + استدعاءات بنية تحتية مباشرة
- **Severity:** High
- **Category:** Layer collapse / no domain layer in feature
- **Location:** `lib/features/connection/presentation/pages/eld_connection_page.dart:61-251` (النموذج والـ notifier والـ provider)، `:70`, `:87`, `:111`, `:114-116`, `:174-176`, `:224-226`
- **Evidence:**
```dart
// lib/features/connection/presentation/pages/eld_connection_page.dart:70
      final bluetoothService = _ref.read(bluetoothServiceProvider);
...
// :87
      final hardwareBackend = _ref.read(hardwareBackendProvider);
...
// :114-116
              final config = await _ref.read(trackingRepositoryProvider).getCurrentConfig();
              await _ref.read(trackingRepositoryProvider).updateConfig(config);
              await _ref.read(trackingStateProvider.notifier).startTracking();
```
- **Current behavior:** الملف الواحد يحتوي: (أ) `EldConnectionState` (27–59)، (ب) `EldConnectionNotifier` (61–246) ينسّق **5 مصادر بنية تحتية**: `bluetoothServiceProvider`, `hardwareBackendProvider`, `localStorageProvider`, `trackingRepositoryProvider`, `trackingStateProvider`، (ج) `eldConnectionProvider` (248–251)، (د) الـ Page (253–529).
- **Why problematic:** feature `connection` **لا تحتوي `domain/` ولا `application/` إطلاقاً** (الملفات الـ4 الأولى هي domain كيانات فقط، بلا usecase ولا repository). ⇒ **Use case "ConnectELD" مكتوب كاملاً داخل ملف Widget**، ويصل مباشرة إلى Bluetooth وbackend contracts ومستودع feature TRACKING. هذا نمط "fat notifier in page" أشد أشكال CLA(layer) violation.
- **Violated principle:** Presentation orchestrates, doesn't implement; Layer collapse.
- **Current owner:** `EldConnectionNotifier` في presentation.
- **Correct owner:** `features/connection/application/connect_eld/connect_eld_use_case.dart` + `features/connection/domain/repositories/connection_repository.dart`؛ يبقى presentation مجرد حالة عرض.
- **Consequences:** (1) منطق الاتصال (المهم قانونياً) غير قابل للاختبار بدون Flutter؛ (2) 5 حواف بنية تحتية من presentation؛ (3) `setManualMode` و`continueDisconnected` ينتميان لـ domain workflow لا presentation.
- **Recommended correction:** استخرج `ConnectEldUseCase` و`ManualModeUseCase` في `connection/application/`، واجعل `eldConnectionProvider` state-only.
- **Related files:** `lib/features/connection/presentation/providers/hardware_status_provider.dart` (نفس النمط), `lib/features/connection/presentation/widgets/manual_recording_section.dart:9`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE CON-002: `AppLocalizations` يُمرَّر كوسيط إلى `StateNotifier` (presentation logic يتلقى كائن ترجمة)
- **Severity:** Medium
- **Category:** Localization leakage into non-UI logic
- **Location:** `lib/features/connection/presentation/pages/eld_connection_page.dart:139-160`
- **Evidence:**
```dart
// lib/features/connection/presentation/pages/eld_connection_page.dart:139-147
  Future<String?> setManualMode({
    required bool enable,
    required String reason,
    required AppLocalizations loc,
  }) async {
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      return loc.enterAReasonForManualRecording;
    }
```
- **Current behavior:** منطق العمل (trim، تحقق، نداء backend) يستقبل كائن ترجمة كامل كوسيط، ويُرجع **نصاً جاهزاً للعرض** بدلاً من رمز خطأ.
- **Why problematic:** (أ) الحالة/المنطق صار غير قابل لإعادة الاستخدام (يحتاج `BuildContext` أو `AppLocalizations` كامل)؛ (ب) القرار «ماذا يُعرض» صار داخل notifier؛ (ج) هذا يقوّض نمط `anyErrorUserMessage` الموجود أصلاً.
- **Violated principle:** Non-UI code returns codes; presentation localizes.
- **Current owner:** `EldConnectionNotifier`.
- **Correct owner:** الكود يُرجع `Either<Failure, Unit>` أو enum؛ presentation يترجم.
- **Consequences:** تكرار منطق الترجمة في كل مستهلك.
- **Recommended correction:** أعد `Future<Either<Failure, Unit>> setManualMode(...)`.
- **Related files:** `lib/features/connection/presentation/widgets/manual_recording_section.dart:107-111` (المستهلك)، `lib/core/error/user_facing_message.dart`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE CON-003: `hardware_alerts_provider.dart` يقوم بـ JSON mapping + استدعاء backend داخل presentation
- **Severity:** Medium
- **Category:** Data mapping + backend access in presentation
- **Location:** `lib/features/connection/presentation/providers/hardware_alerts_provider.dart:9-19`, `:41-68`, `:71-78`
- **Evidence:**
```dart
// lib/features/connection/presentation/providers/hardware_alerts_provider.dart:7-9
/// تحليل رد التنبيهات — يبقى هنا حتى موجة نقل الـ parsing إلى
/// data/mappers؛ الكيان نفسه نقي في domain.
HardwareAlert _hardwareAlertFromJson(Map<String, dynamic> json) {
```
- **Current behavior:** الملف يحتوي mapper كامل (`_hardwareAlertFromJson` + `_alertList` مع تفرّع على `alerts`/`data.alerts`/سجل فارغ) ويستدعي `hardwareBackendProvider` مباشرة.
- **Why problematic:** (أ) knowledge بشكل wire في presentation؛ (ب) **الملف يعترف بالديون** في تعليقاته ⇒-technical debt معترف به لا مُصلَح؛ (ج) نفس النمط يتكرر في `rules_screen_provider.dart` و`team_status_provider.dart` ⇒ **نمط نظامي عبر المشروع** (provider كـ repository).
- **Violated principle:** Presentation must not contain data mapping.
- **Current owner:** provider.
- **Correct owner:** `features/connection/data/mappers/hardware_alert_mapper.dart` + `ConnectionRepository` + provider thin.
- **Consequences:** mapping غير قابل لإعادة الاستخدام/الاختبار؛ توحيد-shape ضائع.
- **Recommended correction:** استخرج mapper + repository (ينضم لـ CON-001).
- **Related files:** `lib/features/connection/presentation/providers/hardware_status_provider.dart:18-24`, `lib/features/account/presentation/providers/rules_screen_provider.dart:19-24`, `lib/features/codriver/presentation/providers/team_status_provider.dart:20-40`
- **Confidence:** CONFIRMED (مع الإقرار بأنه **مُعلَن** في التعليق — أي debt معروف)

--------------------------------------------------
### ISSUE CON-004: `manual_recording_section.dart` يستورد صفحة (وليس provider) للحصول على حالة الاتصال
- **Severity:** Medium
- **Category:** Wrong import (widget → page)
- **Location:** `lib/features/connection/presentation/widgets/manual_recording_section.dart:9`, `:107`
- **Evidence:**
```dart
// lib/features/connection/presentation/widgets/manual_recording_section.dart:9
import '../pages/eld_connection_page.dart';
...
// :107
    final error = await ref.read(eldConnectionProvider.notifier).setManualMode(
```
- **Current behavior:** Widget يستورد ملف صفحة ليستخدم `eldConnectionProvider` المعرَّف داخلها (سطر 248 من الصفحة).
- **Why problematic:** (أ) layering معكوس داخل presentation نفسها؛ (b)Makes `eldConnectionPage.dart` (529 سطر) **ملف hub** لا يمكن تقسيمه؛ (c) `AboutPage` يستورد هذا القسم، فيسحب ضمناً صفحة الاتصال كاملة إلى About.
- **Violated principle:** Provider should live in `providers/`, not in a page file.
- **Current owner:** `eld_connection_page.dart`.
- **Correct owner:** `lib/features/connection/presentation/providers/eld_connection_provider.dart`.
- **Consequences:** استيراد صفحة كاملة لمجرّد provider؛ circular-risk.
- **Recommended correction:** انقل `EldConnectionState/Notifier/Provider` إلى `presentation/providers/`.
- **Related files:** `lib/features/connection/presentation/pages/eld_connection_page.dart:248-251`, `lib/features/connection/presentation/pages/eld_connection_page.dart:9` (المتناقض: `mac_address_validation` من presentation, لكن provider من page)
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE CON-005: طبقة `connection/domain` تحتوي parsing للـ wire (انظر COD-006 — نفس العائلة)
*(موثّق بالتفصيل في COD-006؛ الملفات: `connectivity_status.dart:74-151`, `hardware_readiness.dart:28-75`)*
- **Severity:** Medium | **Confidence:** CONFIRMED
- **ملاحظة مضافة:** `connectivity_status.dart` يحتوي أيضاً `isMacAddress()` (سطر 150) — وهي قاعدة تنسيق (format) تستخدمهاpresentation للـ prefill؛ موقعها في domain **مقبول** بخلاف الـ parsing.

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
### ISSUE CON-007: قاعدة تصنيف MALFUNCTION في صفحة + زر debug بلا أثر في الإنتاج
- **Severity:** Low
- **Category:** Domain rule in presentation / dead debug affordance
- **Location:** `lib/features/connection/presentation/pages/diagnostics_page.dart:23-24`, `:81-91`
- **Evidence:**
```dart
// lib/features/connection/presentation/pages/diagnostics_page.dart:23
  bool _isMalfunction(HardwareAlert a) =>
      a.type.toUpperCase().contains('MALFUNCTION');
```
```dart
// :81-91
              if (kDebugMode) ...[
                ...
                OutlinedButton(
                  onPressed: () => AppFeedback.info(
                      context, loc.simulatedMalfunctionRecorded),
                  child: Text(loc.simulateMalfunction),
                ),
              ],
```
- **Current behavior:** (أ) تصنيف «هل هذا عطل أم data diagnostic؟» — قاعدة SRS 7.14 — عبر `contains('MALFUNCTION')` داخل الصفحة؛ (ب) كتلة `kDebugMode` بزر "محاكاة عطل" لا يفعل شيئاً سوى Toast.
- **Why problematic:** (أ) قاعدة نطاق (presentation-readable) في presentation؛ (ب) زر معلومات مضلّل في وضع debug (يقترح محاكاة ولا يحاكي) — risky أثناء اختبار江西roadside.
- **Violated principle:** Domain rules belong to domain.
- **Current owner:** page.
- **Correct owner:** `extension on HardwareAlert { bool get isMalfunction; }` في `connection/domain/entities/hardware_alert.dart`؛至于 الزر — يُحذف أو يُنفَّذ فعلياً.
- **Recommended correction:** انقل التصنيف إلى كيان `HardwareAlert`، واحذف/نفّذ كتلة kDebugMode.
- **Confidence:** CONFIRMED (الموضع والأكواد)

--------------------------------------------------
### ISSUE HOM-001: `dashboard_provider.dart` تحوّل HOME إلى "طبقة ترويسة جلسة مشتركة" تستهلكها 3ميزات
- **Severity:** High
- **Category:** Accidental shared module / cross-feature hub
- **Location:** `lib/features/home/presentation/providers/dashboard_provider.dart:2-8`, `:174-224`؛ المستهلكون: `account_page.dart:7`, `eld_connection_page.dart:11`, `home_page.dart:40`
- **Evidence:**
```dart
// lib/features/home/presentation/providers/dashboard_provider.dart:2-8
import '../../../logs/domain/daily_form_rules.dart';
import '../../../logs/domain/entities/daily_form_data.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../../codriver/domain/entities/codriver.dart';
import '../../../vehicle/domain/entities/vehicle.dart';
import '../../../vehicle/presentation/providers/vehicle_provider.dart';
import '../../../codriver/presentation/providers/codriver_provider.dart';
```
```dart
// :174-224 (مقتطف)
//Listen to Auth State
  ref.listen(authStateProvider, ...)
// Listen to Vehicle State
  ref.listen(vehicleProvider, ...)
// Listen to CoDriver State
  ref.listen(codriverProvider, ...)
```
- **Current behavior:** مزوّد داخل `features/home/presentation/providers/` يستمع لثلاثة features ويجمعها في `DashboardData`. ثم **ACCOUNT** (`account_page.dart:7`) و**CONNECTION** (`eld_connection_page.dart:11`) يستوردانه لعرض اسم السائق/اسم المركبة.
- **Why problematic:** (أ) `dashboardDataProvider` **ليس** مفهوم HOME — هو "ترويسة جلسة" مفهوم عابر للميزات؛ (ب) موضوعه في `home/` يعني أن أي feature تعتمد عليه ⇒ **home تتحول إلى provider common** (السبب الجذري لـ ACC-007 و CON-001 coupling)؛ (c) presence of `logs/domain` import — home presentation يعتمد على logs domain rules (`joinFormList`).
- **Violated principle:** A feature is a vertical slice; shared cross-cutting state belongs to `core`/`shared`, not to a feature that others depend on.
- **Current owner:** `features/home/presentation/providers/dashboard_provider.dart`.
- **Correct owner:** `lib/core/session/session_header_provider.dart` (أو `lib/app/` layer) — يجمع auth+vehicle+codriver ويخدم الجميع.
- **Consequences:** (1) circular-feel: home→codriver→auth؛ account→home؛ connection→home؛ (2) تغيير واحد في HOME يكسر 3 شاشات؛ (3) تسمية مضلّلة.
- **Recommended correction:** انقل إلى `core/session/` أو `app/` layer، ودع `home` يستهلكه كأي consumer.
- **Related files:** `lib/features/account/presentation/pages/account_page.dart:32`, `lib/features/connection/presentation/pages/eld_connection_page.dart:312`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE HOM-002: `home_page.dart` يستضيف صفحات HOS كتبويبات ويملك `developerBypassDrivingScreenProvider`
- **Severity:** High (compliance)
- **Category:** Feature composition + bypass affordance in presentation
- **Location:** `lib/features/home/presentation/pages/home_page.dart:24`, `:30-35`, `:212-215`
- **Evidence:**
```dart
// lib/features/home/presentation/providers/home_page.dart:24
final developerBypassDrivingScreenProvider = StateProvider<bool>((ref) => false);

// :30-35
  List<Widget> _pagesFor(WidgetRef ref) {
    return const [
      StatusDashboardPage(),
      RecapPage(),
    ];
  }

// :212-215
        if (isDriving && isMoving && !developerBypass)
          const Positioned.fill(
            child: DrivingLockScreen(),
          ),
```
- **Current behavior:** (أ) HOME يحتضن صفحتي feature HOS (`StatusDashboardPage`, `RecapPage`) كـ تبويبات داخلية، و`DrivingLockScreen` (HOS) كطبقة علوية؛ (ب) **`developerBypassDrivingScreenProvider`** — `StateProvider<bool>` داخل presentation، يمكن لأي كود في التطبيق (أو console debug عبر Riverpod) قلبه لتعطيل **قفل القيادة** أثناء القيادة.
- **Why problematic:** (أ) قفل القيادة (`DrivingLockScreen`) هو **ضمان امتثال HOS**؛ تجاوزه Sitting في presentation بلا `kDebugMode` ولا تسجيل — riesgo امتثال مباشر؛ (ب) HOME behaving as a `Shell`，却没有 نمط shell صريح — صفحات HOS تُدار بـ state محلي (`homeNavIndexProvider`) لا عبر GoRouter ⇒ لا deep-link ولا history.
- **Violated principle:** Compliance-critical invariants must not be presentation-toggleable; shell navigation belongs to router.
- **Current owner:** `home_page.dart`.
- **Correct owner:** (أ) `developerBypass` →移到 `kDebugMode`-guarded `Provider` في `app/` مع تسجيل؛ أو يُحذف؛ (ب) تبويبات HOME → `StatefulShellRoute.indexedStack` في `routes/home_routes.dart`.
- **Consequences:** (1) في تطبيق ELD منظَّم، إمكانية تعطيل قفل القيادة غير مقصودة = خطر تنظيمي؛ (2) التبويبات بلا deep-link.
- **Related files:** `lib/features/hos/presentation/widgets/driving_lock_screen.dart`, `lib/routes/home_routes.dart:11-37`
- **Confidence:** CONFIRMED (الرمز مقتبس حرفياً؛ التقييم عالي لكن **ليس style nit** — concerns合规 + بنية router)

--------------------------------------------------
### ISSUE HOM-003: دورة استيراد: `lib/routes.dart` ↔ `lib/features/home/`
- **Severity:** Medium
- **Category:** Circular dependency (app ↔ feature)
- **Location:** `lib/features/home/presentation/providers/home_provider.dart:3` و`lib/features/home/presentation/widgets/eld_drawer.dart:8` مقابل `lib/routes/home_routes.dart:3`
- **Evidence:**
```dart
// lib/features/home/presentation/providers/home_provider.dart:3
import '../../../../../routes.dart';

// lib/routes/home_routes.dart:3
import '../features/home/presentation/pages/home_page.dart';
```
- **Current behavior:** `routes.dart` → `routes/home_routes.dart` → `features/home/.../home_page.dart` → (عبر `home_provider.dart` و`eld_drawer.dart`) → `routes.dart`. ⇒ **دورة استيراد فعلية** بين جذر التطبيق و feature HOME.
- **Why problematic:** (أ) دورة打破黑盒 boundaries — كل feature يستورد `routes.dart` لكائن `AppRoutes`؛ (ب) `AppRoutes` يعتمد على features عبر `routes/*.dart`، و features تعتمد عليه ⇒ tight coupling in both directions؛ (c) يعقّب إعادة البناء والاختبار.
- **Violated principle:** App layer knows features; features must NOT know the app layer (they may know route *identifiers* via a leaf).
- **Current owner:** `home_provider.dart`, `eld_drawer.dart`.
- **Correct owner:** استخرج `lib/core/navigation/app_routes.dart` (leaf، بلا أي imports) يستهلكه الـ app والـ features معاً.
- **Consequences:** (1) inability to reason about the routing graph; (2) coupling كل feature تنوي الـ route constants.
- **Related files:** `lib/routes.dart:14-52`, `lib/features/account/presentation/providers/account_provider.dart` (يستورد auth presentation لا routes)
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE HOM-004: منطق تجميع نص الترويسة (أولوية 3 مصادر) داخل Widget
- **Severity:** Low
- **Category:** Presentation deciding data priority
- **Location:** `lib/features/home/presentation/pages/home_page.dart:56-65`
- **Evidence:**
```dart
// lib/features/home/presentation/pages/home_page.dart:56-65
    // الأولوية: بيانات الـ API → بيانات Auth المحلية → نص افتراضي
    final driverText = statusDashboardState.valueOrNull?.driver.displayText ??
        // SRS 4.2 — `Name - <driver id>`; the vehicle is not part of the header.
        (dashboard.driverName != 'Unknown'
            ? (ref.watch(currentDriverIdProvider) != null
                ? '${dashboard.driverName} - ${ref.watch(currentDriverIdProvider)}'
                : dashboard.driverName)
            : null) ??
        ref.watch(authStateProvider).user?.fullName ??
        '';
```
- **Current behavior:** الـ Widget يقرر أولوية عرض الاسم عبر 3 مصادر + مقارنات بالنصوص `'Unknown'`، ويبني نصاً مركّباً يدوياً (concatenation)، ويقارن بـ `'Unknown'` (magic string من `dashboard_provider.dart:65`).
- **Why problematic:** (أ) Formatting (`'Name - id'`) قرار عرض — مقبول هنا؛ لكن (ب) **مقارنة `!= 'Unknown'`** هشّة: الاسم الفعلي للسائق إن كان "Unknown" سيُسقط إلى auth fallback — سلوك خفي؛ (c) `dashboard.driverName` من feature-account-coupled-aggregation.
- **Violated principle:** No magic-string state comparison.
- **Current owner:** page.
- **Correct owner:** `DashboardData.isDriverNameKnown` (bool) أو `String?` بدل sentinel.
- **Recommended correction:** استبدل sentinel `'Unknown'` بـ `null`.
- **Related files:** `lib/features/home/presentation/providers/dashboard_provider.dart:65`, `lib/features/connection/presentation/pages/eld_connection_page.dart:365-367` (نفس نمط `'No Vehicle'`).
- **Related files note:** النمط نفسه يتكرر في `eld_connection_page.dart:365` و`dashboard_provider.dart:67-68`.
- **Confidence:** CONFIRMED

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
- **Confidence:** CONFIRMED (كل استيرادات الملفات التسعة تم核查)

--------------------------------------------------
### ISSUE DOM-002: جذور دومين متوازية — `lib/domain/**` و`lib/core/domain/entities/**`
- **Severity:** Medium
- **Category:** Structural incoherence
- **Location:** `lib/domain/**` (9 ملفات) مقابل `lib/core/domain/entities/{user, hos_models, location_point}.dart`
- **Current behavior:** المشروع فيه **جذران للمجال**: `lib/domain/` (account, config, duty_status, hardware, inspection, shared, signature) و`lib/core/domain/entities/` (user.dart, hos_models.dart, location_point.dart). كلاهما "domain"، وأحدهما ليس تحت `core`.
- **Why problematic:** (أ) `lib/domain/` يُستورد من **~130 استيراد في 60+ ملفاً** موزّعة على `lib/backend/**` و`lib/core/**` و`lib/features/**` كلها ⇒ **coupling واسع جداً**؛ (ب) وجود جذرين يجعل "أين domain؟" سؤالاً بلا جواب ⇒ قرارPlacement لـ`lib/domain` غيرcoherent مع وجود `lib/core/domain` بالتوازي؛ (c) `lib/domain/account/driver_account.dart` (network DTO) و`lib/core/domain/entities/user.dart` (persisted entity)的不齐.
- **Violated principle:** Single responsibility for placement of shared kernel.
- **Current owner:** بنية المشروع.
- **Correct owner:** إمّا `lib/domain/**` فقط (وتُلغى `lib/core/domain`)، أو `lib/core/domain/**` فقط. الموقف الحالي — 둘 موجودان — غيرcoherent.
- **Recommended correction:** قرّر جذراً واحداً؛ المرجّح `lib/core/domain/**` لتطابق بقية `core/`.
- **Confidence:** CONFIRMED (البنية معروضة)

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
- **Why problematic:** (أ) `normalizeUrl` سياسة (تُستدعى من `ServerConfig.unverified/verified`) — مكانها 자연类是 domain policy أو config service لا static داخل DTO؛ (b) `BackendType` vs `BackendKind` — معجمان مختلفان لنفس "نوع الـ backend" (eldEngine/mock vs eld/traccar) ⇒ التباس.
- **Violated principle:** Separate config DTO from config policy.
- **Current owner:** `lib/domain/config/server_config.dart`.
- **Correct owner:** `ServerConfigProvider` / `core/config/server_config_store.dart` (المستهلك الحالي).
- **Recommended correction:** انقل `normalizeUrl` إلى `core/config/`؛ ووحّد `BackendType`/`BackendKind`.
- **Related files:** `lib/backend/core/backend_kind.dart:11-19`, `lib/core/config/server_config_store.dart:7`
- **Confidence:** CONFIRMED (لاحظ: `BackendType.traccar` يبدو legacygiven the ELD engine)

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
### ISSUE ROU-001: تجاوز GoRouter فعلي واحد: `UserManualPage` تُفتح بـ `Navigator.push` رغم وجود مسار مسجّل
- **Severity:** Medium
- **Category:** Router bypass
- **Location:** `lib/features/account/presentation/pages/info_packet_page.dart:45-49` مقابل `lib/routes/account_routes.dart:30-34`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/info_packet_page.dart:45-49
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const UserManualPage()),
              );
```
```dart
// lib/routes/account_routes.dart:30-34
        GoRoute(
          path: AppRoutes.userManual,
          name: 'userManual',
          builder: (context, state) => const UserManualPage(),
        ),
```
- **Current behavior:** `UserManualPage` لها مسار GoRouter مسجّل (`/user-manual`)، لكنها **لا تُفتح عبره** من صفحة حزمة المعلومات، بل عبر `Navigator.push` بـ MaterialPageRoute. أما `DiagnosticsPage` (`about_page.dart:267`) و`ZoomableSectionPage` (`instructions_page.dart:77`) فلا مسار لهما — تجاوز مقبول تقنياً لكن غير مسجّل.
- **Why problematic:** (أ) نسختان مختلفتان mental model for navigation (router + navigator stack)؛ (b) `UserManualPage` عند فتحها عبر router-vs-push تنتج back-stack مختلفة؛ (c) `context.push` على `/user-manual` لم يُستخدم أبداً رغم تسجيله ⇒ **المسار Dead عملياً**.
- **Violated principle:** Single navigation authority.
- **Current owner:** `info_packet_page.dart`.
- **Correct owner:** `context.push(AppRoutes.userManual)` / `context.goNamed('userManual')`.
- **Consequences:** (1) المسار المسجّل غير مستخدم؛ (2) back-stack غير متوقع؛ (3) hard coupling للصفحات.
- **Recommended correction:** استبدل `Navigator.push` بـ `context.push(AppRoutes.userManual)`.
- **Related files:** `lib/routes/account_routes.dart:30-34`, `lib/features/about/presentation/pages/about_page.dart:267`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE ROU-002: `InstructionsPage` يمتلك 4 أقسام لكن 3 منها غير قابلة للوصول
- **Severity:** Low
- **Category:** Dead configuration / over-specification
- **Location:** `lib/features/account/presentation/pages/instructions_page.dart:12`, `:15`, `:19-24`
- **Evidence:**
```dart
// lib/features/account/presentation/pages/instructions_page.dart:12
enum InstructionsSection { all, inspection, sendLogs, malfunction }

// :19-24
  String _title(AppLocalizations loc) => switch (section) {
    InstructionsSection.all => loc.instructions,
    InstructionsSection.inspection => loc.inspectionMode,
    InstructionsSection.sendLogs => loc.dataTransferInstructionSheet,
    InstructionsSection.malfunction => loc.malfunctionManual39534,
  };
```
- **Current behavior:** `InstructionsPage` مع 4 أقسام، لكن **لا يوجد أي استدعاء بـ `section:`** (تم البحث الشامل: `InstructionsPage(` يظهر مرتين فقط — المرساة 15، والاستخدام في `info_packet_page.dart:59` بدون section). و**لا يوجد GoRoute لـ `/instructions`**. ⇒ 3 أقسام + عناوينها المترجمة dead code.
- **Why problematic:** configuration زائدة تُوهم أن الأقسام قابلة للوصول فرادى (SRS 8.2 يذكر 3 عناصر منفصلة)، بينما الواجهة فقط تعرضها مجتمعة.
- **Violated principle:** — (لا مبالغة)
- **Current owner:** page.
- **Correct owner:** إمّا أضف مسارات (`.inspection`, `.sendLogs`, `.malfunction`) أو احذف الـ enum.
- **Consequences:**_code ميت؛ localizations زائدة عن الحاجة.
- **Recommended correction:** استكمل المسارات أو احذف الـ enum.
- **Related files:** `lib/features/account/presentation/pages/info_packet_page.dart:52-62`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE ROU-003: مساران مكرران لنفس الصفحة، و`RouterNotifier` يستمع لمصدر حالة واحد فقط
- **Severity:** Low
- **Category:** Routing config drift / Incomplete redirect signal
- **Location:** `lib/routes/home_routes.dart:17-26`؛ `lib/routes.dart:55-61`, `:73-91`
- **Evidence:**
```dart
// lib/routes/home_routes.dart:17-26
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
```dart
// lib/routes.dart:55-61
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateProvider, (_, __) => notifyListeners());
  }
}
```
- **Current behavior:** (أ) `/status` و`/hos` مساران يبنيان **نفس** `StatusDashboardPage` — ازدواج في الـ URL space بلا فارق وظيفي؛ (ب) `RouterNotifier` يعيد حساب `redirect` **عند تغيّر `authStateProvider` فقط**، ولا يستمع إلى `sessionTransitionProvider` — أي أن الانتقال `unauthenticated → loading → authenticated` قد لا يُنتج إعادة توجيه متسقة إذا كانت الحالة النهائية متطابقة (مثلاً استعادة offline بعد authenticated)؛ (ج)Positive: نمط `RouterNotifier extends ChangeNotifier` كـ `refreshListenable` لـ GoRouter **هو النمط الصحيح** لفصل Riverpod عن Router — لا مخالفة في البنية نفسها.
- **Why problematic:** ازدواج المسارات يجعل `matchedLocation` في `EldDrawer.onTap` (`eld_drawer.dart:63`) غير مستقر: الضغط على `/hos` أو `/status` معاً يختلفان في السلوك. أما نقص الاستماع لـ `transitioning` فهو **POTENTIAL** (لم يُثبت سلوك خاطئ فعلياً).
- **Violated principle:** Single canonical route per screen; refresh signal completeness.
- **Current owner:** `routes/home_routes.dart`, `routes.dart`.
- **Correct owner:** اختيار مسار واحد (`/status`)؛ ووجعل `RouterNotifier` يستمع لـ `(authState, sessionTransition)` معاً.
- **Consequences:** ازدواج maintenance؛ عدم استقرار navigation state.
- **Recommended correction:** احذف أحد المسارين، أو اجعلهما aliases موثّقة عبر `redirect`.
- **Related files:** `lib/routes.dart:23, 35, 45-51`, `lib/features/home/presentation/widgets/eld_drawer.dart:62-69`
- **Confidence:** CONFIRMED (الازدواج) / POTENTIAL (نقص الاستماع)

--------------------------------------------------
### ISSUE SET-001: `settings_page.dart` يزامن تفضيل اللغة عبر feature ACCOUNT presentation
- **Severity:** Low
- **Category:** Cross-feature write through presentation
- **Location:** `lib/features/settings/presentation/pages/settings_page.dart:14`, `:116-125`
- **Evidence:**
```dart
// lib/features/settings/presentation/pages/settings_page.dart:14
import '../../../account/presentation/providers/account_provider.dart';

// :116-125
                      final accountState = ref.read(accountProvider);
                      // If user is logged in, sync to server
                      if (accountState.accountData != null) {
                        final langName = code == 'ar' ? 'Arabic' : (code == 'es' ? 'Spanish' : 'English');
                        final currentOdo = accountState.accountData?.odometer ?? 'mi';
                        await ref.read(accountProvider.notifier).updatePreferences(
                          language: langName,
                          odometerUnit: currentOdo,
                        );
                      }
```
- **Current behavior:** صفحة SETTINGS تكتب في `AccountNotifier` (presentation لميزة أخرى)، وتحوّل رمز اللغة إلى اسم نصي بمقارنة if/else داخل الـ Widget.
- **Why problematic:** (أ) SETTINGS → ACCOUNT presentation write path؛ (ب) نفس mapping مكرَّر في `account_page.dart:180-181` بترميز مختلف؛ (ج) `ref.read(accountProvider)` دون `watch` ⇒ لا إعادة بناء عند تغيّر الحساب.
- **Violated principle:** Cross-feature writes go through the owning feature's use-case.
- **Current owner:** page.
- **Correct owner:** use-case في `features/account/application/usecases/update_preferences_use_case.dart` + mapper لغة مشترك.
- **Consequences:** ازدواج mapping اللغة؛ تسرّب في الكتابة.
- **Recommended correction:** mapper لغة واحد + use-case مشترك.
- **Related files:** `lib/features/account/presentation/pages/account_page.dart:179-182`, `lib/features/account/presentation/providers/account_provider.dart:99`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE PERM-001: صفحة الصلاحيات rely على نصوص عربية hardcoded بالكامل في تطبيق يدعم 3 لغات
- **Severity:** Medium (compliance/UX) — ليس style nit
- **Category:** Localization bypass (feature-level)
- **Location:** `lib/features/permissions/presentation/pages/permissions_page.dart:61-64`, `:77-80`, `:141`, `:179`, `:185`, `:194-195`, `:204-205`, `:214-215`, `:224-225`, `:234-235`, `:249-250`, `:286`
- **Evidence:**
```dart
// lib/features/permissions/presentation/pages/permissions_page.dart:61-64
        title: 'صلاحية الموقع مطلوبة',
        message: 'يحتاج تطبيق ELD إلى الوصول للموقع الجغرافي بشكل دائم '
            'لتسجيل مسار المركبة وساعات القيادة تلقائياً.\n\n'
            'هذا متطلب قانوني من FMCSA ولا يمكن عمل التطبيق بدونه.',
```
```dart
// :141
            child: Text(isRequired ? 'منح الصلاحية' : 'موافق'),

// :286
                label: 'مطلوب',
```
- **Current behavior:** الصفحة **كلها** بالعربية hardcoded (بما فيها نصوص قانونية: «هذا متطلب قانوني من FMCSA ولا يمكن عمل التطبيق بدونه»)، بينما نفس الصفحة تستخدم `context.loc.continueWithout` (سطر 129) و`context.loc.grant` (سطر 296). ⇒ الترجمة **جزئية**.
- **Why problematic:** (أ) سائق English/Español يرى واجهة صلاحيات بالعربية بالكامل مع نصوص قانونية؛ (ب) التطبيق يعلن دعم ar/en/es في `settings_page.dart:95-110`؛ (ج) عدم اتساق داخل نفس الملف (بعضها `context.loc` وبعضها حرف).
- **Violated principle:** Localization completeness — `AppLocalizations` هو المصدر الوحيد.
- **Current owner:** page.
- **Correct owner:** `l10n/arb` + `AppLocalizations` (كل النصوص).
- **Consequences:** توهُم司机؛ المسار الإلزامي غير مفهوم لغير العربية.
- **Recommended correction:** ترجمة كل النصوص إلى `AppLocalizations` (نفس نهج `forgot_password_form.dart` لكن **بـ l10n** لا بـ if/else).
- **Related files:** `lib/l10n/app_localizations*.dart`, `lib/features/settings/presentation/pages/settings_page.dart:95-110`
- **Confidence:** CONFIRMED

--------------------------------------------------
### ISSUE CTN-001: صفحات الحaccount (instructions / user_manual / rules) مترجمة بشكل صحيح — فرضية «صفحات نص خام» مرفوضة
- **Severity:** Informational (لا مخالفة) — **CONFIRMED CLEAN**
- **Category:** Localization — تحقق إيجابي
- **Location:** `lib/features/account/presentation/pages/instructions_page.dart` (502 سطر)، `user_manual_page.dart` (559)، `rules_page.dart` (502)
- **Evidence (نماذج):**
```dart
// instructions_page.dart:125
                  loc.goldenFeatherEldInspectionMode,
// instructions_page.dart:135
                  text: loc.tapDotInspectionInTheMenuPress,
// user_manual_page.dart:129-131
                    Text(
                      'Golden Feather ELD',          // ← الاستثناء الوحيد
                      style: context.styles.body
                          .copyWith(fontSize: 24, fontWeight: FontWeight.w400),
                    ),
// user_manual_page.dart:169
        'title': loc.recordsOfDutyStatus,
```
- **Current behavior:** كل النصوص الطويلة في الصفحات الثلاث تمر عبر `context.loc` / `loc.*` (عشرات المطابقات). **النصوص الحرفية الوحيدة**: `'Golden Feather ELD'` (user_manual:129)، `'www.topceld.com'` (instructions:374)، `'AA:BB:CC:DD:EE:FF'` (eld_connection:433 — placeholder MAC مقصود).
- **Why problematic:** لا شيء جوهري. ملاحظة فقط: `'Golden Feather ELD'` يمكن استبداله بـ `loc.appName` الموجود.
- **Violated principle:** — (غير منتهك)
- **Current owner:** — | **Correct owner:** `loc.appName`.
- **Confidence:** CONFIRMED — **الفرضية المرفوضة بشكل صريح**.

--------------------------------------------------
### ISSUE SEC-001: لا يوجد أي تسريب لبيانات الاعتماد في السجلات — منطقة نظيفة (CONFIRMED CLEAN)
- **Severity:** Informational (لا مخالفة) — **CONFIRMED CLEAN**
- **Category:** Security — تحقق إيجابي
- **Location:** كل نداءات `AppLogger` داخل `features/auth/**` (7 ملفات، تم فحصها جميعاً)
- **Evidence (كامل نداءات المصادقة):**
```dart
// auth_local_data_source.dart:64
      AppLogger.info('Session securely stored for origin: ${session.serverOrigin}');
// auth_local_data_source.dart:107
      AppLogger.info('User securely stored: ${user.email}');   // بريد، لا سرّ
// auth_repository_impl.dart:162
      AppLogger.warning('Backend logout failed, proceeding with local clear', e, stackTrace);
// auth_state_provider.dart:168
    AppLogger.error('$logPrefix: ${failure.message}');        // Failure message ثابت أو error code
// auth_state_provider.dart:267
          AppLogger.info('Login successful: ${user.fullName}');
// auth_state_provider.dart:100-101
      AppLogger.warning(
          'Ignoring stale 401 from epoch $requestEpoch (current ${SessionEpoch.current})');
// auth_state_provider.dart:287
      AppLogger.info('forceLogout ignored: already unauthenticated');
// splash_page.dart:66
    AppLogger.info('SplashPage: Auth status check complete. IsLoggedIn: $isLoggedIn');
```
- **Current behavior:** **لا يوجد أي نداء يطبع `password` ولا `sessionCredential`.** إضافةً إلى إجراءات دفاعية مؤكدة: (أ) `AuthSession.toString()` يحجب `credential: [REDACTED]` (`auth_session.dart:50-52`)، (ب) `AuthLocalDataSource.credentialGeneration` يمنع مقارنة/طباعة الـ Cookie (التعليق `auth_local_data_source.dart:28-31`)، (ج) لا يوجد refresh token في المشروع إطلاقاً.
- **Why problematic:** — (لا شيء)
- **Violated principle:** — (ملتزم)
- **Current owner:** — | **Correct owner:** — (الوضع الحالي صحيح)
- **Confidence:** CONFIRMED — **الفرضية المرفوضة بشكل صريح**.

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
| 2 | `auth/presentation/widgets/forgot_password_form.dart:43` | `: 'Enter a valid email.'` |同上 | **مخالفة ترجمة** |
| 3 | `auth/presentation/widgets/forgot_password_form.dart:63-64` | `'الاستعادة غير متاحة على هذا الخادم. تواصل مع مدير الأسطول.'` / `'Reset is not available on this server. Contact your fleet manager.'` |同上 | **مخالفة ترجمة** |
| 4 | `auth/presentation/widgets/forgot_password_form.dart:72-74` | `'إن كان البريد مسجّلاً فستصلك تعليمات إعادة التعيين.'` / `'If the email is registered, reset instructions will be sent.'` |同上 | **مخالفة ترجمة** |
| 5 | `auth/presentation/widgets/forgot_password_form.dart:94-96` | `'أدخل بريد الحساب. إن لم يصلك شيء فتواصل مع مدير الأسطول.'` / `'Enter the account email...'` |同上 | **مخالفة ترجمة** |
| 6 | `auth/presentation/widgets/forgot_password_form.dart:111` | `label: _arabic ? 'إرسال' : 'Send',` |同上 | **مخالفة ترجمة** |
| 7 | `auth/presentation/widgets/forgot_password_form.dart:28` | `bool get _arabic => Localizations.localeOf(context).languageCode == 'ar';` | التفاف l10n يدوي | **نمط معاد** |
| 8 | `auth/presentation/widgets/forgot_password_form.dart:38` | `if (email.isEmpty \|\| !email.contains('@'))` | قاعدة تحقق محلية | تكرار لـ `LoginIdentifier` |
| 9 | `auth/presentation/pages/auth_page.dart:46` / `splash_page.dart:81` | `'assets/images/ic_launcher.png'` | مسار أصل | مقبول |
| 10 | `account/presentation/pages/user_manual_page.dart:129` | `'Golden Feather ELD'` | نص إنجليزي | ي应该 `loc.appName` (CTN-001) |
| 11 | `account/presentation/pages/instructions_page.dart:374` | `'www.topceld.com'` | نص إنجليزي | inconsequential (مقصود) |
| 12 | `account/presentation/pages/account_page.dart:180` | `newValue.toLowerCase() == 'arabic' \|\| newValue == 'العربية'` | mapping لغة | **منطق أعمال في Widget** (ACC-007) |
| 13 | `account/presentation/pages/account_page.dart:181` | `newValue.toLowerCase() == 'spanish' \|\| newValue == 'español'` |同上 |同上 |
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
| 45 | `permissions/.../permissions_page.dart:77-80` | `'صلاحية البلوتوث'` + `'ساعات القيادة يدوياً'` |同上 |同上 |
| 46 | `permissions/.../permissions_page.dart:141` | `Text(isRequired ? 'منح الصلاحية' : 'موافق')` |同上 |同上 |
| 47 | `permissions/.../permissions_page.dart:179,185` | `'صلاحيات التطبيق'`, `'يحتاج تطبيق ELD للصلاحيات التالية\nللعمل بشكل قانوني'` |同上 |同上 |
| 48 | `permissions/.../permissions_page.dart:194-235` | `'الموقع الجغرافي'`,`'البلوتوث'`,`'الإشعارات'`,`'توفير البطارية'`,`'الكاميرا'` + 5 subtitles |同上 |同上 |
| 49 | `permissions/.../permissions_page.dart:249-250` | `'متابعة'` / `'منح الصلاحيات'` |同上 |同上 |
| 50 | `permissions/.../permissions_page.dart:286` | `label: 'مطلوب'` |同上 |同上 |
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
| **P2** | **HOM-001**, **ACC-006**, **ACC-008**, **COD-005**, **COD-006**, **CON-003**, **CON-004**, **CON-005** | تطبيع 星 feature boundaries + استخراج mappers |
| **P3** | **AUTH-001**, **AUTH-002**, **AUTH-003**, **AUTH-007**, **ACC-005**, **ACC-007**, **COD-003**, **COD-004**, **CON-002**, **CON-006**, **CON-007**, **HOM-003**, **HOM-004**, **DOM-002**, **DOM-003**, **DOM-004**, **DOM-005**, **ROU-001**, **ROU-002**, **ROU-003**, **SET-001**, **PERM-001**, **AUTH-006**, **SEC-002** | تحسين البنية والتجربة |
| — | **CTN-001**, **SEC-001**, **CON-006** (جزء الحكم), **§E-4** | **مناطق نظيفة موثّقة — لا عمل مطلوب** |

---

*نهاية التقرير. جميع الأكواد في §B مقتبسة حرفياً من الملفات المقروءة. لم يُعدَّل أي ملف تحت `lib/`.*