/// واجهة مزود إعدادات الخادم لتطبيق مبدأ Interface Segregation
abstract class ServerConfigProvider {
  /// عنوان الخادم
  String get serverUrl;

  /// نوع الخادم (eld أو traccar)
  String get backendType;
}
