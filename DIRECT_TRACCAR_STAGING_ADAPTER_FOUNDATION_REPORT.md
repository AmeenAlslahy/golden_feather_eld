# DIRECT_TRACCAR_STAGING_ADAPTER_FOUNDATION_REPORT.md

## 1. الهدف (Objective)
تأسيس البنية التحتية لرفع بيانات المواقع الجغرافية (GPS) إلى بيئة Traccar التجريبية (Demo/Staging) بشكل مباشر، دون تفعيل الرفع الفعلي حتى يتم توثيق وإثبات عقد بروتوكول الاتصال (مثل OsmAnd HTTP أو غيره). 

## 2. المعمارية المؤقتة (Temporary Architecture)
تم فصل مهام تتبع ELD عن مسار Traccar المباشر بناءً على المعطيات التالية:
- **المواقع الحية والتدريب:** تُرسل فقط إلى `Direct Traccar` (مؤقتاً) كبيئة `Staging`.
- **بيانات ELD (HOS/DVIR...):** ستبقى مخزنة محلياً ولن ترفع إلى Traccar المباشر لمنع التلوث والتداخل.
- **تأكيد Nano Backend:** الاحتفاظ بالـ `Nano Authentication Foundation` كمسار رسمي مستقبلي للإنتاج (Production).

## 3. طبقة التكيف (Adapter Layer)
تم إنشاء `LocationUploadAdapter` و `TrackingBackend` لتجريد مسار الرفع:
```dart
enum TrackingBackend {
  directTraccarDemo,
  nanoBackend,
}

abstract class LocationUploadAdapter {
  Future<Either<Failure, void>> uploadLocation(NativeLocationEvent event);
}
```

## 4. المحاكي (Fake Adapter)
نظراً لعدم وجود توثيق دقيق عن البورت (Port) واسم البروتوكول في `api.md` (الذي يحتوي فقط على نقاط REST API)، تم تنفيذ `FakeDirectTraccarAdapter` لمنع الإرسال العشوائي إلى الخادم.
- يتحقق من أن مصدر الموقع هو `localNative` حصراً (يرفض `remoteTraccar` لمنع الـ Loop).
- يحاكي الـ Network Delay.
- يقدم طريقة آمنة لاختبار طبقة التطبيق (UI/Queue) قبل برمجة `http` حقيقية عبر بروتوكول OsmAnd.

## 5. الاختبارات (Tests)
تم بناء اختبارات آلية (`fake_direct_traccar_adapter_test.dart`) تثبت:
1. نجاح محاكاة رفع المواقع المحلية.
2. الرفض الصارم لأي مواقع ليست من نوع `localNative` (حماية من التكرار).
3. معالجة الفشل الافتراضي (`ServerFailure`).
**النتيجة:** `All tests passed!`

## 6. الخطوات التالية (Next Steps)
لا يُنصح بكتابة `TraccarHttpAdapter` حقيقي يرسل بيانات الـ GPS إلا بعد التأكد من فريق الـ Backend / الخادم حول النقاط التالية:
- **المنفذ (Port):** هل يستخدم Traccar حالياً المنفذ 5055 (OsmAnd) للرفع المباشر للأجهزة المحمولة؟
- **هوية الجهاز (Device ID):** ما هي الآلية التي سيتم بها تمرير المعرف لـ Traccar؟ هل سيتم استخدام رقم هاتف السائق أو معرّف الجهاز المولد تلقائياً؟
- بمجرد توفر هذه المعلومات، يمكن بسهولة تحويل `FakeDirectTraccarAdapter` إلى عميل حقيقي.

تم تطبيق هذه التغييرات لضمان سير المشروع بأمان نحو نظام HOS دون العبث بقواعد البيانات.
