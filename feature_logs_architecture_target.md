# البنية المعمارية لـ features/logs (قبل وبعد Sprint A)

## البنية السابقة (Polished Spaghetti) ❌
- **منطق الأعمال في الواجهة (UI):** مئات الأسطر داخل `onPressed` في `edit_log_page.dart`، `form_tab.dart`، و `certify_tab.dart`.
- **العقود غير المحكمة (dynamic):** استخدام `dynamic` بدل `LogEvent` في العديد من الـ Providers والشاشات.
- **تداخل الميزات (Feature Coupling):** استيراد مباشر لـ `dashboard_provider`، `auth_state_provider`، ومصادر بيانات الـ Tracking والتفتيش داخل الواجهات، مع اختراقات صريحة مثل `// ignore_architecture`.
- **مزودات مبعثرة:** Providers معرّفة أسفل ملفات الـ Pages (مثل `editLogFormProvider`).
- **أدوات متكررة:** تنسيق الوقت `DateTime` وألوان الحالات `StatusColor` مكررة في 4 أماكن مختلفة على الأقل.

## لماذا نعيد الهيكلة؟ (أمثلة عملية)

### قبل (منطق متداخل يصعب اختباره)
مثال حقيقي من `edit_log_page.dart`:
```dart
onPressed: () async {
  // UI يقرأ ويتحقق ويبني الكائن ويتعامل مع قواعد الأعمال
  if (existing != null) {
    final refusal = refuseAutomaticDrivingEdit(...);
    if (refusal != null) {
      AppFeedback.error(context, context.loc.error);
      return;
    }
  }
  final event = LogEvent(id: DateTime.now()..., ...);
  final saved = await notifier.updateEvent(event);
  if (!saved) AppFeedback.error(context, ...);
  else Navigator.pop(context);
}
```
**المشكلة:** لا يمكن اختبار `refuseAutomaticDrivingEdit` إلا عبر استدعاء `WidgetTester` ومحاكاة النقر والـ `Navigator`.

### بعد (انفصال تام - Clean Architecture)
نفس المنطق في `EditLogController`:
```dart
Future<void> submit() async {
  // منطق أعمال صرف يعيد Either<Failure, Success>
  final refusal = refuseAutomaticDrivingEdit(...);
  if (refusal != null) return Left(InvalidEditFailure());
  
  final event = LogEvent(id: ref.read(idGeneratorProvider).v4(), ...);
  return await ref.read(logRepositoryProvider).update(event);
}
```
وفي الواجهة:
```dart
onPressed: () async {
  final result = await ref.read(editLogControllerProvider.notifier).submit();
  result.fold(
    (failure) => AppFeedback.error(context, failure.message),
    (success) => Navigator.pop(context),
  );
}
```
**النتيجة:** اختبار الـ Controller يتم في مللي ثانية بدون `WidgetTester`، وقواعد الأعمال معزولة وآمنة.

## البنية المستهدفة (Clean Architecture) ✅
ستصبح بنية `features/logs` كالتالي بعد انتهاء الـ 10 أيام:

```text
features/logs/
├── domain/
│   ├── entities/                    # موجود مسبقاً
│   ├── value_objects/               # ← جديد (LogEventDraft, EditReason, StatusChange)
│   ├── usecases/                    # ← جديد (SubmitLogEvent, CertifyLog...)
│   └── repositories/                # موجود مسبقاً
├── data/                            # موجود مسبقاً
└── presentation/
    ├── pages/                       # تنحيف الصفحات من منطق الأعمال (عقود صارمة)
    ├── widgets/                     # أدوات العرض (مترجمة بالكامل)
    ├── controllers/                 # ← جديد (EditLogController, FormTabController...)
    ├── facades/                     # ← جديد (فصل الاستيرادات المباشرة للميزات الأخرى)
    └── providers/                   # ← نقل كل الـ Providers المتناثرة إلى هنا
```

## التغييرات الجوهرية (Key Improvements)
1. **الـ Facade Pattern:** أي ميزة خارجية (مثل Tracking أو Home) سيتم استهلاكها عبر واجهة `Facade` لمنع الترابط الوثيق (Tight Coupling).
2. **الـ Controllers:** كل شاشة لها `Controller` مستقل (غالباً `AsyncNotifier`) يعالج الإدخال ويكلّم الـ UseCases، ويبقى العرض في الشاشة فقط (UI is just UI).
3. **Value Objects:** التخلص من `String` العشوائي لتمثيل سبب التعديل أو الحالة، واستبداله بـ Type-safe Objects.
4. **العقود الصارمة (Strict Types):** إزالة أي أثر لـ `dynamic` من المنظومة، وتوحيد التوليد للـ `ID` عبر Provider.
