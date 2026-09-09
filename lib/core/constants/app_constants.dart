/// ثوابت التطبيق الأساسية
class AppConstants {
  AppConstants._();

  // معلومات التطبيق
  static const String appName = 'Golden Feather ELD';
  static const String appVersion = '1.0.0';
  static const String appPackageName = 'com.goldenfeather.eld';
  static const bool isDevelopmentMode =
      true; // Added to fix tracking_service.dart error

  // إعدادات التتبع الافتراضية
  static const double defaultDistanceMeters = 75.0;
  static const int defaultIntervalSeconds = 300;
  static const int defaultHeartbeatSeconds = 300;
  static const int defaultAngleDegrees = 0;

  // إعدادات المزامنة
  static const int maxRetryAttempts = 3;
  static const Duration retryDelay = Duration(seconds: 30);
  static const Duration syncInterval = Duration(minutes: 15);

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
  pending('قيد الانتظار'),
  inProgress('قيد التنفيذ'),
  completed('مكتمل'),
  failed('فشل'),
  requiresReview('يحتاج مراجعة');

  final String arabicName;
  const InspectionStatus(this.arabicName);
}
