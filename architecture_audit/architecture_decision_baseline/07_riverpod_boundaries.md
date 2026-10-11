# 07 — حدود Riverpod (Riverpod Responsibility Boundaries)

> 95 مزوداً مُحصاة آلياً (68 `Provider`، 12 `StateNotifierProvider`، 7 `FutureProvider`، 5 `StateProvider`، 3 `StreamProvider`) + 23 صنف Notifier. التصنيف أدناه بالأدوار الفعلية المقروءة — والتنسيق في Notifier **ليس** خطأ تلقائياً.

## 1. التصنيف الفعلي

| الفئة | الأعضاء (أمثلة موثقة) |
|---|---|
| **DEPENDENCY_COMPOSITION** | مزودات `*/data/providers` (8 ملفات تركيب)، `backend_providers` (15 عقداً)، `updateRulesUseCaseProvider`، `trackingService(Full)Provider`، `*_aliases` |
| **PRESENTATION_STATE** | `login_form_provider`، `ChangeStatusState`، `DvirState`، `LogsState`، `EldConnectionState`، `dashboardDataProvider`، `homeNavIndex` |
| **APPLICATION_COORDINATION** | `HosNotifier` (محرك+متتبع+مستمعان)، `LogsNotifier` (مستودع+كتابة عابرة)، `DvirNotifier` (إرسال+مراجعة)، `CoDriverNotifier` (تحميل+تبديل)، `ChangeStatusNotifier.submit`، `trackingOrchestratorProvider`، `InspectionNotifier.sendLogs` |
| **DOMAIN_SERVICE_ACCESS** | `hosEngineProvider`، `dutyStatusTrackerProvider`، `syncEngineProvider` — خدمات نطاق مُدارة دورياً |
| **INFRASTRUCTURE_RESOURCE** | `apiClientProvider`، `networkInfoProvider` (+`dispose`)، `localStorageProvider` (+override)، `bluetoothServiceProvider`، `secureStorageProvider`، `timeAuthorityProvider` |
| **OTHER (مختلط)** | `driverRulesProvider` (اشتقاق عابر للطبقات)، `eld_events_provider` (بث من مصدر ملموس)، `sessionEpochProvider` (لقطة عدّاد)، `currentDriverIdProvider` (تحويل هوية) |

## 2. التقييم لكل سؤال مطلوب

| السؤال | الحكم |
|---|---|
| حالة مناسبة؟ | نعم غالباً — الحالات (`*State`) عرضية خالصة |
| تبعيات مناسبة؟ | **لا دائماً**: `trackingServiceFullProvider` مكرر؛ `vehicleBackendProviderAlias` تمرير أعمى؛ `DvirNotifier(storageService)` مُهمَل |
| تنسيق مناسب؟ | **مقبول مع تحفظ**: التنسيق في Notifier مشروع Riverpod؛ المشكلة **تكرار** التنسيق عبر 3 طبقات (W2) لا وجوده |
| تسرب تنفيذ الخلفي؟ | نعم: `unidentified_events_provider` و`team_status_provider` يقرآن مزودات العقود ويحللان الخام |
| أمثلة مكررة؟ | `TrackingService` ×2 (مؤكد)؛ سياج owner/epoch ×2 ملفات |
| اقتران دورة حياة؟ | `autoDispose` مقابل دائم مقابل `keepAlive(30د)` مقابل مؤقتات دقيقة — بلا قاعدة؛ مزودات tracking الأربعة عادية (غير autoDispose) على نطاق التطبيق، و`onDispose` فيها لا يُستدعى إلا بموت الحاوية (سلوك طبيعي، لا تسرب مثبت) |
| تسرب حالة بين الميزات؟ | قراءة واسعة (مشروعة) + كتابة (5 مواقع dashboard) + إبطال (3 مزودات من app) |

## 3. ملاحظات دقيقة (لا تعميمات)

- `ChangeNotifier` يُستخدم مرة واحدة (`RouterNotifier`) — جسر التوجيه القياسي، لا بديل `ref.listen` المباشر المكرر في `app.dart` (نمطان متجاوران لسبب واحد: إبطال + سناك).
- `StateProvider` (5) لثوابت واجهة (`homeNavIndex`، `developerBypass`) — مناسب.
- `StreamProvider` (3) للشبكة/البث — مناسب.
- `FutureProvider` للجلب لمرة واحدة مع `cacheFor` — مناسب؛ الاستثناء `team_status/hardware_*` (منطق متعدد الخطوات بدل جلب).
- `ref.watch` داخل مصنع المزود للاشتقاق (`driverRulesProvider`) — مشروع تقنياً، مخالف طبقياً (المشكلة الموضع لا الآلية).
