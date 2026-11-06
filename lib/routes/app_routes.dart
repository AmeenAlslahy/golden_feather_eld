/// مسارات التطبيق (مطابقة لقائمة التنقل في SRS §4)
class AppRoutes {
  AppRoutes._();

  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String permissions = '/permissions';
  static const String connection = '/connection';
  static const String login = '/login';
  static const String home = '/home';
  static const String status = '/status';
  static const String logs = '/logs';
  static const String logDetail = '/logs/:id';
  static String logDetailPath(Object id) => '/logs/$id';
  static const String editLog = '/logs/:id/edit';
  static const String dvir = '/dvir';
  static const String dvirForm = '/dvir/create';
  static const String inspection = '/inspection';
  static const String sendLogs = '/inspection/send';
  static const String codriver = '/codriver';
  static const String account = '/account';
  static const String rules = '/rules';
  static const String infoPacket = '/info-packet';
  static const String hos = '/hos';
  static const String selectVehicle = '/select-vehicle';
  static const String userManual = '/user-manual';
  static const String instructions = '/instructions';
  static const String about = '/about';
  static const String settings = '/settings';
  static const String suggestedEvents = '/logs/suggested-events';
  static const String unidentifiedEvents = '/logs/unidentified-events';
  static const String auditTrail = '/logs/audit-trail';

  /// مسارات متاحة بدون تسجيل دخول
  static const Set<String> publicRoutes = {
    splash,
    onboarding,
    permissions,
    login,
    about, // SRS §17: حول التطبيق والتشخيص متاحة بدون مصادقة
  };
}
