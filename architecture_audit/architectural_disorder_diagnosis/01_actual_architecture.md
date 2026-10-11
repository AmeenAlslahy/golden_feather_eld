# 01 — الخريطة المعمارية الفعلية (Actual Architecture)

> القياس أُعيد من الصفر على الشجرة الحالية (408 ملفات). كل الأرقام أدناه من قياسي الخاص، لا نقلاً عن التدقيق السابق.
> المنهج: تحليل كل سطور `import`/`export` (1,726 حافة داخلية فريدة)، تصنيف طبقي، وخوارزمية Tarjan للدورات.

## 1. الطبقات كما هي فعلياً (لا كما توحي المجلدات)

| الطبقة المعلنة (المجلد) | الدور الفعلي المقاس |
|---|---|
| `lib/features/*/presentation/` | واجهة + تنسيق + **تركيب DI** (تُنشئ/تراقب مزودات `data/providers`) + منطق أعمال انتقائي |
| `lib/features/*/domain/` | كيانات + عقود + محركات حقيقية (HOS) + **تحليل wire** في 4 ملفات + تبعية بنية تحتية في ملف واحد |
| `lib/features/*/data/` | مستودعات + مصادر بيانات + خرائط + **تركيب DI الخاص بالميزة** + مزودات Riverpod |
| `lib/features/*/application/` | موجود في `account` فقط: نموذج + use-case يحمل مزوده الخاص |
| `lib/backend/contracts/` | عقود مجردة **لكن** تستورد نماذج `eld_engine` (4 حواف) وتُصدّر `RawJson` |
| `lib/backend/adapters/` | `eld_engine` (HTTP فعلي) + `mock` (غير مكتمل: 22 موقع `UnimplementedError`) |
| `lib/backend/providers/` | اختيار المحوّل + حقن Dio/interceptors + مزودات شبكة Traccar |
| `lib/core/` | شبكة + خطأ + تخزين + وقت + إعدادات + **تركيب auth** + **نظام تصميم** + أحداث + مزودات تعبر للميزات |
| `lib/domain/` | كيانات مشتركة (نقية تقريباً) + **ملف واحد يستورد Flutter** |
| `lib/app/` + `lib/routes*` | تنسيق عابر للميزات (تتبع، توجيه، إشعارات) |

## 2. جذور حقن الاعتماديات (DI) — أربعة لا واحد

| # | الجذر | الموقع | ما يُركّب |
|---|---|---|---|
| 1 | `core/di/app_providers.dart` (25 سطراً) | `core` | **مستودع auth فقط** رغم ادعاء "Composition Root for all Domain Repositories" |
| 2 | `backend/providers/` | `backend` | اختيار `MockAdapter`/`EldEngineAdapter` + كل مزودات العقود + مزودات شبكة Traccar |
| 3 | `features/*/data/providers/` | كل ميزة | مستودع الميزة من (backend + networkInfo + مصادر محلية) |
| 4 | مزودات محلية مبعثرة | `application/`, `tracking_service.dart`, `inspection_repository_impl.dart` (ضمني) | `updateRulesUseCaseProvider`، `trackingServiceProvider`، ... |

**التشخيص:** لا يوجد جذر تركيب واحد. التركيب موزّع على 4 مستويات، وبعض المزودات تُعرَّف بجانب أصنافها (`trackingServiceProvider` في `tracking_service.dart:200`).

## 3. مسارات العمل الفعلية (Workflows)

### W1 — تسجيل الدخول (الأنظف معمارياً)

```
auth_page → authStateProvider.login()
  → LoginUseCase (تحقق شكلي 32 سطراً)
    → AuthRepositoryImpl.login() (يقرأ serverUrl، guardedNetwork)
      → AuthBackend.login() (عقد)
        → EldAuthBackend (يبني URL مطلقاً، POST /api/session)
      → AuthSessionDto → saveSession + saveUser (تخزين محلي)
  → SessionEpoch.bump() + AuthState(sessionEpoch, transitioning=false)
  → app.dart:40-46 يُبطل hosStatus/dashboard/recap
```

- الاتجاه سليم. الملاحظة: `LoginUseCase` تحقق شكلي مكرر مع الواجهة؛ `Password`/`LoginIdentifier` كائنات قيمة شكلية.

### W2 — تغيير حالة HOS (الأكثر تشعباً)

```
change_status_page → ChangeStatusNotifier.submit()
  ├─ فحص محلي: isVehicleMoving (provider) + PC/YM permission + annotation
  → hosStatusProvider.changeStatus()
      ├─ فحص ثانٍ: HosRulesEngine.validateManualTransition (سرعة/عتبة)
      → DutyStatusTracker.submitManualChange()
          ├─ _legalRefusal (وقت/جلسة)
          → StatusDashboardBackend.updateDutyStatus (HTTP)
          ├─ خطأ شبكي؟ → _applyManualLocal + enqueue (SyncEngine)
          └─ نجاح → _applyManualLocal + dashboard snapshot
      → statusDashboardProvider.applyServerDashboard (تغذية فورية)
```

- **قاعدة "المركبة تتحرك" تُفحص مرتين** (سطر 278 في change_status + سطر 95 في hos_provider عبر المحرك).
- ثلاث طبقات قرار (notifier → provider → tracker) لنفس الانتقال.

### W3 — إرسال السجلات للتفتيش (الأخطر سابقاً)

```
send_logs_page --(inspectionProvider.sendLogs)--> InspectionRepositoryImpl.sendLogs()
  ├─ online → backend.sendLogs / emailLogs
  └─ offline → FmcsaEldOutputGenerator.generateAndSave(screen, cycle, logs)
       → 'OFFLINE_GENERATED:<path>' (بروتوكول نصي يُفكك في الصفحة 267-268)
```

- بعد EC-0.2a: ملكية مُتحقَّقة + بوابة حقول + حذف الملف الفاسد. التحقق اللاحق كشف عيب اقتباس CSV في البوابة (موثّق، خارج النطاق).

### W4 — تقديم DVIR

```
dvir_form_page (_handleSubmit)
  ├─ حل deviceId: dashboard → selectedVehicle → قائمة المركبات → int.tryParse → RegExp (DST-001)
  → dvirProvider.createReport(report)
    → DvirRepositoryImpl.submitDvirReport → DvirBackend.create
```

- **حل الهوية في الواجهة** بدل المستودع/النطاق، وآخر fallback يستخرج أرقاماً من نص حر.

### W5 — تبديل السائق المساعد

```
codriver_page → CoDriverNotifier.switchDrivers()
  → CoDriverRepositoryImpl.switchPrimary() → DriverSessionBackend
  → _refreshCurrent()
```

- ملاحظة: `switchDrivers` و`_refreshCurrent` **بلا سياج owner/epoch** (السياج مطبق على `_loadDrivers` فقط) — اتساق داخلي ناقص.

### W6 — بدء التتبع (الأكثر تشتتاً)

```
app_initializer (override trackingServiceProvider)
  ├─ trackingOrchestratorProvider (Provider<void>): 4 مستمعين (tracking/auth/vehicle/hos)
  │    ├─ isDrivingChecker حقن عكسي في trackingStateProvider
  │    ├─ telemetry POST عبر hardwareBackendProvider
  │    └─ auto-start عند vehicle/status
  ├─ trackingRepositoryProvider ← trackingServiceFullProvider (مثال B)
  └─ quick_actions_initializer ← trackingServiceProvider (مثال A)
```

- **مثالان حيان** من نفس الصنف (DST-037/CORE-005 مؤكد). التنسيق موزّع على orchestrator + app.dart + مزودات.

### W7 — شاشة القواعد (account)

```
rules_page → rulesScreenProvider (FutureProvider)
  → rulesScreenBackendProvider → RulesScreenBackend → DTO → RulesScreenModel
  → driverRulesProvider (core يراقب presentation!)
```

- أقصر سلسلة تُظهر الانقلاب: `core/providers` يستهلك `features/account/presentation`.

## 4. إدارة الجلسة — ثلاث آليات لشاغل واحد

| الآلية | الموقع | النطاق |
|---|---|---|
| `SessionEpoch` (عدّاد أحادي + `bump()` عند الهوية) | `core/session` | عام — interceptor يوسم الطلبات، `sessionEpochProvider` يعيد البناء |
| سياج owner/epoch/seq لكل notifier | `account_provider`, `codriver_provider` (نسختان متطابقتان تقريباً) | 3 مزودات فقط |
| `expectedOwnerDriverId` في العقود | 4 عقود + interceptor (`gf_expected_owner`) | طلبات المزامنة فقط |

**التشخيص:** نفس الشاغل (عزل الهوية عبر الزمن) بثلاث آليات متوازية: واحدة عامة، وواحدة منسوخة يدوياً في كل notifier، وواحدة مُمرَّرة كمعامل. الاتساق جزئي (codriver يسيّج التحميل لا التبديل).

## 5. معالجة الأخطاء — قناتان + تسرب خام

- `AppError`/`Result` (شبكة/خلفية) مقابل `Failure`/`Either` (مستودعات/نطاق) — نظامان متوازيان.
- `anyErrorUserMessage` يُصنّف للعرض؛ لكن **17 موقعاً** تخزّن `failure.message` / `e.toString()` / `l10nKey` في الحالة وتُعرض خاماً.
- `rules_screen_provider:22` يرمي `Exception(l10nKey)` فيهبط لرسالة شبكة عامة (ACC-003 مؤكد).

## 6. التخزين المؤقت — سياسات متعددة

| الآلية | الموقع | السياسة |
|---|---|---|
| `guardedNetwork(action, offline:)` | كل مستودع | fallback يدوي لكل طريقة |
| `cacheFor(ref, duration)` | مزودات presentation | 30ث–30د حسب الملف |
| `SessionEpoch` + owner tags | inspection (بعد الإصلاح) | تحقق ملكية |
| owner/seq fencing | account/codriver notifiers | إسقاط متزامن |
| `static` caches | codriver repo (متبقٍّ) | بلا إبطال |

**لا سياسة تخزين موحدة.** كل مستودع يبتكر fallback خاصاً.
