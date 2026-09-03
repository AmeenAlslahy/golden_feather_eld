/// واجهة للتعامل مع Traccar WebSocket.
/// مسؤولة فقط عن الاتصال المباشر (Live Stream) للأحداث والمواقع.
abstract class TraccarWebSocketClient {
  /// بدء الاتصال بخادم Traccar عبر WebSocket
  Future<void> connect(String serverUrl, String cookie);
  
  /// إنهاء الاتصال
  Future<void> disconnect();
  
  /// إعادة الاتصال
  Future<void> reconnect();
  
  /// بث (Stream) المواقع الحية (Positions)
  Stream<Map<String, dynamic>> get positionsStream;
  
  /// بث (Stream) الأحداث الحية (Events) مثل (Geofence, Status, إلخ)
  Stream<Map<String, dynamic>> get eventsStream;
  
  /// حالة الاتصال (متصل، جاري الاتصال، مفصول)
  Stream<bool> get connectionStateStream;
}
