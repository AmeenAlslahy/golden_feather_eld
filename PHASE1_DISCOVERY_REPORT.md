# تقرير المرحلة الأولى: الاكتشاف والتحليل (Discovery Phase Report)

تم فحص المشروع بشكل شامل دون إجراء أي تعديل على الملفات. هذا التقرير يوثق الهيكلية الحالية، تدفق البيانات، ونتائج التحقق من المشاكل المذكورة سابقاً.

## ١. خريطة المجلدات والطبقات (Folder & Layer Map)
يعتمد المشروع على بنية قريبة من Clean Architecture مقسمة إلى:
- **`lib/core/` (الأساسيات والمحرك)**:
  - `engine/`: يحتوي على النواة الصلبة لمنطق HOS (`hos_rules_engine.dart`, `hos_violations_engine.dart`).
  - `network/`: يحتوي على عملاء الشبكة المتعددين.
  - يحتوي أيضاً على: `base`, `config`, `constants`, `errors`, `extensions`, `localization`, `services`, `theme`, `utils`, `widgets`.
- **`lib/features/` (الميزات)**:
  - مقسمة حسب الميزة: `account`, `auth`, `checklist`, `codriver`, `connection`, `dvir`, `home`, `hos`, `inspection`, `logs`, `permissions`, `reports`, `settings`, `sync`, `tracking`, `vehicle`.
  - كل ميزة مقسمة داخلياً (غالباً) إلى `data`, `domain`, `presentation`.

## ٢. خريطة الاعتماديات بين الملفات (Dependency Map)
- ميزات التطبيق (Features) تعتمد بشكل كبير على `lib/core/engine` لحسابات HOS.
- ميزة `sync` تعتمد بشكل وثيق على `TraccarRemoteEventDispatcher` الذي يستخدم `ApiClient`.
- يوجد تداخل كبير (Tight Coupling) بين طبقات البيانات (Data Layer) و Traccar في ميزات الـ Auth و Tracking.

## ٣. مصادر ومنفذي منطق HOS (HOS Logic Sources)
يتم تنفيذ منطق HOS محلياً داخل التطبيق في الملفات التالية:
- `DutyStatusTracker` (`lib/core/engine/tracking/duty_status_tracker.dart`): يحدد حالة السائق بناءً على السرعة والأحداث.
- `HosRulesEngine` (`lib/core/engine/hos_rules_engine.dart`): يطبق قواعد القيادة والراحة.
- `HosViolationsEngine` (`lib/core/engine/hos_violations_engine.dart`): يحسب ويتتبع الانتهاكات.

## ٤. مسار البيانات (Data Flow) من ELD إلى Backend
1. **الالتقاط**: الجهاز يرسل بيانات -> تتحول إلى `EldEvent`.
2. **التحليل المحلي**: `DutyStatusTracker` يحدث الحالة -> `HosRulesEngine` يحلل القواعد.
3. **التخزين المؤقت**: يتم تكوين `PendingEvent` وإضافته إلى قاعدة البيانات المحلية.
4. **المزامنة**: `SyncEngine` يقرأ الأحداث ويحاول إرسالها.
5. **الخادم (الخطأ المعماري)**: `TraccarRemoteEventDispatcher` يرسل هذه البيانات (بصيغة HOS) إلى `POST /api/events` في Traccar.

## ٥. عملاء الشبكة (Network Clients)
يوجد ٤ واجهات/كلاسات مختلفة للاتصال بالشبكة:
1. `ApiClient` (`lib/core/network/api_client.dart`): العميل الأساسي مع إعدادات Dio.
2. `TraccarApiClient` و `TraccarApiClientImpl` (`lib/core/network/traccar/`): عميل منفصل يستخدم Dio مباشرة دون الاستفادة الكاملة من معترضات (Interceptors) العميل الأساسي.
3. `DioClient` (`lib/core/network/dio_client.dart`): عميل وهمي/مؤقت (Mock).
4. `TrackingClientInterface` (`lib/core/network/tracking_client_sdk.dart`): واجهة للتعامل مع SDK التتبع.

## ٦. كيانات الموقع والأحداث (Entities)
يوجد ٥ كيانات مختلفة تمثل نفس البيانات الجغرافية/الأحداث:
1. `EldEvent` (`lib/core/engine/hos_models.dart`)
2. `TrackingEvent` (`lib/features/tracking/domain/entities/tracking_event.dart`)
3. `NativeLocationEvent` (`lib/features/tracking/domain/entities/native_location_event.dart`)
4. `LocationEntity` (`lib/features/tracking/domain/entities/location_entity.dart`)
5. `LocationModel` (`lib/features/tracking/data/models/location_model.dart`)

## ٧. نقاط الاتصال مع Traccar (Integration Points)
- **المصادقة**: `AuthRemoteDataSource` يتعامل مع الـ Cookies و JSESSIONID الخاصة بـ Traccar.
- **إرسال الأحداث**: `TraccarRemoteEventDispatcher` يرسل الأحداث إلى `/api/events`.
- **التتبع**: `TraccarSdkLocationProvider` و `TraccarDataSource`.
- **WebSocket**: (تم ذكره في التقرير، لم يتم فحصه بالكامل ولكن الاعتمادية موجودة).

## ٨. نتائج الفحص والاختبارات (Analyzer & Tests)
- **Flutter Analyze**: تم العثور على **88 مشكلة** (معظمها `unused_import`، وبعض الاستخدامات لدوال قديمة مثل `.withOpacity` التي يفضل استبدالها بـ `.withValues()`).
- **Flutter Test**: تم تشغيل الاختبارات. النتيجة: **55 نجاح، 7 فشل**.
  - **الفشل الملحوظ**:
    1. في `HosViolationsEngine` (فشل في اكتشاف تجاوز الأيام المتتالية Consecutive days exceeded).
    2. في `Sync Data Loss Prevention` (فشل في إرجاع `ServerFailure` من `FailClosedRemoteEventDispatcher`، ومشاكل في سياسة إعادة المحاولة `RetryPolicy`).

## ٩. التحقق من المشاكل المذكورة في التقرير
| المشكلة | الإثبات من الكود | تصنيف الخطورة | القرار المطلوب / نوع الإصلاح |
|---------|------------------|---------------|-----------------------------|
| **التناقض المعماري (HOS vs Traccar)** | **مثبتة**: `traccar_remote_event_dispatcher.dart` سطر 17 يرسل حدث HOS إلى `/api/events`. | 🔴 خطير جداً | **قرار معماري**: هل ننقل HOS للخادم أم نزيل مزامنة Traccar؟ |
| **ازدواجية عملاء الشبكة** | **مثبتة**: وجود 4 عملاء في `lib/core/network`. | 🟠 خطير | إصلاح مباشر (إعادة هيكلة عبر Adapters) |
| **ازدواجية كيانات البيانات** | **مثبتة**: وجود 5 كلاسات بأسماء مختلفة لنفس البيانات. | 🟡 متوسط | إصلاح مباشر (إنشاء كيان Domain واحد) |
| **تكرار UI** | **مثبتة**: `_buildSectionTitle` مكررة في `inspection_logs_page.dart` (سطر 126) و `user_manual_page.dart` (سطر 69) وغيرها. | 🟠 خطير | إصلاح مباشر (استخراج إلى `core/widgets`) |
| **Polling في Diagnostics** | **مثبتة**: حلقة `while (true)` في `diagnostics_stream_provider.dart` (سطر 14). | 🟡 متوسط | إصلاح مباشر (تحسين أداء باستبدالها بـ Stream) |
| **استعلامات متسلسلة** | **مثبتة**: حلقة `for` لـ 8 مرات في `logs_provider.dart` (سطر 49). | 🟢 بسيط | إصلاح مباشر (تحسين أداء بـ `Future.wait`) |
| **تحليل Cookies يدوياً** | **مثبتة**: `part.startsWith('JSESSIONID=')` في `auth_remote_data_source.dart` (سطر 71). | 🟡 متوسط | إصلاح مباشر (استخدام مكتبة `cookie_jar`) |
| **توجيه الـ Router** | **مثبتة**: `routes.dart` (سطر 70-85) لا يتحقق من اتصال المركبة `vehicleProvider`. | 🟠 خطير | إصلاح مباشر (إصلاح Bug) |

## ١٠. المخاطر والاعتماديات المخفية (Hidden Risks)
1. **فشل اختبارات HOS**: هناك اختبارات تفشل حالياً في `hos_violations_engine_test.dart` مما يعني أن الاعتماد على المنطق المحلي حالياً به ثغرات. **(تأثير عالي - يجب إصلاحه قبل أي تغيير).**
2. **الارتباط الوثيق بـ Traccar (Tight Coupling)**: إذا تم تغيير الخادم إلى "Nano Backend" في المستقبل، سيتطلب ذلك تغييرات جذرية في `Auth`, `Sync`, و `Tracking` بسبب غياب واجهة (Interface) موحدة للـ Backend.
3. **ضياع بيانات Sync**: اختبارات `Sync Data Loss Prevention` تفشل، مما يعني أن التطبيق قد يفقد بيانات الأحداث الهامة إذا فشل الإرسال للخادم.

---
**تم الانتهاء من المرحلة الأولى.**
أنا في انتظار موافقتك وقرارك بخصوص "التناقض المعماري (HOS)" للانتقال إلى "المرحلة 2: تثبيت السلوك بالاختبارات".
