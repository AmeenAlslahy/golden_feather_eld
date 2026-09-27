# فحص الجاهزية للتشغيل — Golden Feather ELD

> كل تعديلات الدورات الأخيرة **لم تُترجم بعد** (لا Flutter SDK في بيئة العمل).
> هذا الفحص هو البوابة قبل اعتبار التطبيق جاهزًا. أنفَّذ بالتسلسل، وأي
> خطأ → انسخه كاملًا وأرجعه للمعالجة.

## البوابة 1 — التحليل (يجب أن يكون 0 errors)

```bash
cd golden_feather_eld
flutter pub get
flutter analyze
```

- **0 errors** شرط لا يقبل الاستثناء.
- warnings: راجعها لكن لا توقف الجاهزية بسببها.

### ملفات الدورة الأخيرة (الأكثر احتمالًا لإخفاء خطأ ترجمة)
| الملف | السبب |
|---|---|
| `lib/features/logs/...` (edit_log_page, logs_provider, log_local_data_source, log_edit, audit_entry) | أعقد سلسلة رُممت: حفظ الحدث + التدقيق |
| `lib/backend/http/interceptors/auth_interceptor.dart` | استيراد `EldEndpoints` جديد + منطق path |
| `lib/backend/http/interceptors/time_drift_interceptor.dart` | `onError` + حقول جديدة |
| `lib/backend/http/api_client.dart` | إخراج `sendTimeout` + LogInterceptor |
| `lib/features/auth/data/datasources/auth_local_data_source.dart` | حاش `_sessionCache` |
| `lib/core/services/event_log_service.dart` | استيراد `uuid` جديد |
| `lib/features/hos/domain/engine/diagnostics/diagnostics_engine.dart` | توقيعات دوال تغيرت + حذف `_checkUnidentifiedDrive` |
| `lib/core/domain/entities/hos_models.dart` | فك ترميز (لا أخطاء متوقعة) |
| `lib/main.dart` | حذف `_isExpectedError` |
| إعادة التسمية `primaryGold` (68 مرجعًا) | ميكانيكي، خطرها منخفض لكن واسع |

## البوابة 2 — الاختبارات

```bash
flutter test
```

يجب أن تمر كل الاختبارات الموجودة + الجديدة:
- `test/features/logs/audit_entry_test.dart`
- `test/features/logs/log_edit_test.dart`
- `test/features/auth/email_test.dart`
- `test/domain/duty_status_code_test.dart`
- اختبارات التحليلات الموجودة (parsers, submission...)

فشل أي اختبار جديد → انسخ الفشل كاملًا.

## البوابة 3 — البناء والتشغيل الدخاني

```bash
flutter build apk --debug     # أو: flutter run على جهاز
```

### مسار الدخان (10 خطوات، لا تتخطَّ أيًّا)
1. **Splash → Permissions**: منحة الموقع (والبطارية إن طُلبت).
2. **Server Configuration**: تأكد أن `https://snsoft.cloud` معروض افتراضيًا → Save.
3. **Login**: بالحساب الفعلي (JSESSIONID via Cookie — لا JSON body).
4. **Connection**: زر الاتصال → يجب أن تصل الحالة من `GET /eld/hardware/status`
   (وليس "Error fetching" — هذا البند رُمم مؤخرًا، افحصه بعين).
5. **Home / Status Dashboard**: الحالة والدورة الدائرية تُعرض من الخادم.
6. **Change Status**: ارجع ON ثم OFF مع annotation — يذهب
   `POST /eld/duty-status` ويعود dashboard محدثًا.
7. **Logs → Open log → Edit an event**: غيّر الحالة/الوقت → Save
   → أعد فتح السجل: **التعديل يجب أن يبقى** (هذا الإصلاح المركزي لدورة السجلات).
8. **DVIR**: افتح القائمة (بيانات الخادم تظهر بالحالة الصحيحة —
   "Has Defects" لم يعد يظهر "آمن")، وافتح نموذج التقرير.
9. **Inspection**: شاشة التفتيش + Transfer Audit (القراءة من
   `GET /eld/dot-inspection/transfers` — لا صفوف مخترعة).
10. **About / Rules / Account**: لا نصوص مشوهة (فكّ ترميز hos_models)،
    ولا رموز `§` في أسماء الحالات.

## خارج الكود (لا يمر حتى مع كود سليم)

- **الخادم**: `snsoft.cloud` يجب أن يكون مستضيفًا لعقد ELD Engine
  (جلسات JSESSIONID، `/eld/*`).
- **الجهاز**: إذن الموقع فعّال (المحرك يحكم على الحركة منه).
- **عتاد ELD**: `POST /eld/hardware/connect` يتطلب جهازًا مسجلًا
  (أو وضع Continue Disconnected لاختبار المسار بدون عتاد).

## القرارات المعلقة (لا توقف الترجمة، لكن تغيّر السلوك)

1. DVIR `items: const []` — بنود مهيكل لا تُرسل (تطلب إعادة فتح الـ slice).
2. `trackingOrchestratorProvider` لا يراقبه أحد → لا تتبع تلقائي.
3. افتراضي الـ backend = `traccar` (قرار slice الشبكة).
4. fallback `snsoft.cloud` في `runtime_selection` و`local_storage_service`.

## الحكم

- **جاهز**: البوابات 1-3 خالية من الأخطاء + مسار الدخان كامل + القرارات الأربعة حُسمت (أو قُبِل تأجيلها).
- **غير جاهز**: أي error في analyze، أو فشل اختبار، أو كسر في خطوات الدخان 3-8.
