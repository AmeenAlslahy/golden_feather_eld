/// واجهة للتعامل مع Traccar REST API.
/// مسؤولة فقط عن طلبات الـ HTTP ولا تعرف شيئاً عن Native Tracking أو WebSockets.
abstract class TraccarApiClient {
  /// مصادقة المستخدم عبر POST /api/session
  Future<Map<String, dynamic>> authenticate(String email, String password);

  /// تحديث موقع لجهاز معين عبر REST (إذا كان مدعوماً)
  Future<void> updatePosition(Map<String, dynamic> positionData);

  /// جلب قائمة الأجهزة المرتبطة بالحساب
  Future<List<Map<String, dynamic>>> getDevices();

  /// جلب آخر المواقع لجهاز معين
  Future<List<Map<String, dynamic>>> getPositions(String deviceId);

  /// جلب الأحداث (Events)
  Future<List<Map<String, dynamic>>> getEvents(String deviceId,
      {DateTime? from, DateTime? to});
}
