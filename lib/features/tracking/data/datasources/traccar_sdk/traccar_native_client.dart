/// واجهة للتعامل مع Traccar Native Background Client (Android/iOS).
/// مسؤولة فقط عن التواصل عبر MethodChannel مع خدمة الخلفية (Foreground Service).
abstract class TraccarNativeClient {
  /// تهيئة إعدادات التتبع في الخلفية
  Future<void> configure(Map<String, dynamic> config);

  /// بدء التتبع في الخلفية
  Future<void> startBackgroundTracking();

  /// إيقاف التتبع في الخلفية
  Future<void> stopBackgroundTracking();

  /// التحقق من حالة التتبع في الخلفية
  Future<bool> isTrackingActive();

  /// طلب موقع فوري من خدمة الخلفية
  Future<void> requestImmediatePosition({String? alarm});

  /// يمرّر قفلاً من مصدر خارجي (جهاز BLE/ELD) إلى طابور الرفع الأصلي.
  ///
  /// `speed` يجب أن يكون بالمتر/الثانية؛ التحويل إلى عقد (knots) يتم في
  /// طبقة الرفع الأصلية.
  Future<void> pushLocation(Map<String, dynamic> location);

  /// آخر موقع معروف من نظام التشغيل — قراءة فقط.
  ///
  /// لا يُدخل الموقع في قاعدة البيانات الأصلية ولا يرفعه إلى Traccar؛
  /// يعيد `null` إذا لم يوجد قفل حديث ضمن نافذة العمر المسموح.
  Future<Map<String, dynamic>?> getLastKnownPosition();

  /// جلب سجلات التتبع المحلية (Logs) من الخدمة
  Future<List<Map<String, dynamic>>> getNativeLogs();

  /// مسح سجلات التتبع المحلية
  Future<void> clearNativeLogs();
}
