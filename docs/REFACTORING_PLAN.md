# الخطة العلاجية لإعادة الهيكلة (Refactoring Plan)

هذه هي الخطة المرحلية المتبعة لتنظيف وإعادة هيكلة كود تطبيق Golden Feather ELD.

## المرحلة 1: إصلاح الأعطال الحرجة (تم الإنجاز ✅)
- إصلاح `InspectionNotifier` و `InspectionState` واستخدام MockData.
- إصلاح `DvirNotifier` و `DvirState`.
- إصلاح `CoDriverNotifier` و `CoDriverState`.
- إصلاح `VehicleNotifier`.
- ربط `SyncRepositoryImpl` بـ `TraccarRemoteEventDispatcher` بدلاً من التأخير الوهمي.

## المرحلة 2: تحسين الأداء (تم الإنجاز ✅)
- استبدال Polling في Diagnostics بـ Stream.
- تحسين `LogsNotifier._loadLogs` بـ `Future.wait`.
- تحسين `ReportsProvider` باستخدام `compute`.

## المرحلة 3: إزالة التكرار في الـ UI
- إنشاء Widgets مشتركة (`SectionTitle`, `InfoRow`, `ChecklistItem`).
- إعادة بناء شاشات: account, info_packet, instructions, user_manual, inspection_logs, reports, inspection_preview.

## المرحلة 4: توحيد الكيانات وعملاء الشبكة
- دمج كيانات الموقع (`EldEvent`, `LocationEntity` وغيرها).
- توحيد عملاء الشبكة تحت `ApiClient` واحد. (تم إنجاز الأولوية 1: ترحيل `TraccarApiClientImpl` ليستخدم `ApiClient` بدلاً من `Dio` ✅).

## المرحلة 5: تحسين المصادقة
- استخدام `cookie_jar` لإدارة جلسة Traccar بدلاً من التحليل اليدوي لـ `JSESSIONID`.

## المرحلة 6: عزل Traccar وقرار HOS
- إنشاء `AppBackendAdapter`.
- تحديد مكان حفظ قواعد العمل لـ HOS وتطبيق القرار.

## سجل الترحيل (Migration Log)

### الأولوية 1: توحيد `TraccarApiClientImpl`
- **تم الإنجاز ✅**: تم ترحيل `TraccarApiClientImpl` ليستخدم `ApiClient` الموحد وتم تمرير الـ `Options` بنجاح للطلبات.

### الأولوية 2: توحيد مصادر المصادقة وفصل التخزين
- **تم الإنجاز ✅**: تم إنشاء `UserStore` لفصل تخزين بيانات المستخدم (Profile) عن `AuthSessionStore` المخصص للجلسات (Tokens/Cookies).
- **الملفات المعدلة:**
  - `lib/core/services/local_storage_service.dart`: تمت إزالة دوال المستخدم القديمة.
  - `lib/features/auth/data/datasources/user_store.dart`: تم إنشاؤه للحفظ الآمن لهوية المستخدم باستخدام `FlutterSecureStorage`.
  - `lib/features/auth/presentation/providers/auth_state_provider.dart`: تم حقن `UserStore` لحفظ واستعادة بيانات المستخدم بشكل مستقل عن الجلسة.
- **السلوك المتأثر:** يتم الآن تخزين بيانات الجلسة منفصلة عن بيانات هوية المستخدم بطريقة نظيفة وآمنة.
- **ملاحظة:** تبين أثناء التدقيق أن `TraccarAuthNotifier` محذوف مسبقاً، لذا لم تكن هناك حاجة لدمجه، وكان التطبيق يعتمد بالفعل على `AuthNotifier` فقط.
