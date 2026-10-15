/// ثوابت التطبيق الأساسية
class AppConstants {
  AppConstants._();

  // معلومات التطبيق
  static const String appName = 'Golden Feather ELD';
  static const String appVersion = '1.0.0';
  static const String appPackageName = 'com.goldenfeather.eld';
  static const bool isDevelopmentMode = false;

  // إعدادات التتبع الافتراضية
  static const double defaultDistanceMeters = 75.0;
  static const int defaultIntervalSeconds = 300;
  static const int defaultHeartbeatSeconds = 300;
  static const int defaultAngleDegrees = 0;

  // إعدادات المزامنة
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 30);
  static const Duration syncInterval = Duration(minutes: 15);

  /// معدّل تصحيح لوحة الحالة من الخادم.
  ///
  /// **قاعدة التصميم:** الخادم هو المرجع القانوني، والتطبيق يحسب محلياً
  ///imarى أن يغرق الخادم بطلبات كل ثانية. فالتطبيق ينقص العدّاد بنفسه
  /// بين النقطتين، ويعود كل [dashboardRefreshInterval] ليتحقّق من الخادم
  /// ويصحّح الأرقام.
  ///
  /// ⚠️ كان `syncInterval` (15 دقيقة) ثابتاً **ميتاً بلا أي مستدعٍ**،
  /// فلا جلب دوري للوحة كان موجوداً إطلاقاً: الأرقام تبقى من آخر فتح.
  static const Duration dashboardRefreshInterval = Duration(minutes: 5);

  // إعدادات التخزين
  static const int maxOfflineInspections = 100;
  static const int maxLocalImages = 500;

  // مفاتيح التخزين
  static const String tokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userIdKey = 'user_id';
  static const String userRoleKey = 'user_role';
  static const String languageKey = 'language_code';
  static const String themeKey = 'theme_mode';
}

/// أدوار المستخدمين في النظام

/// حالة المزامنة
enum SyncStatus {
  synced,
  syncing,
  pending,
  failed,
  offline,
}

/// حالة التفتيش
enum InspectionStatus {
  pending,
  inProgress,
  completed,
  failed,
  requiresReview;
}
