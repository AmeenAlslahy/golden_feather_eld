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

  /// جلب سجلات التتبع المحلية (Logs) من الخدمة
  Future<List<Map<String, dynamic>>> getNativeLogs();

  /// مسح سجلات التتبع المحلية
  Future<void> clearNativeLogs();
}
