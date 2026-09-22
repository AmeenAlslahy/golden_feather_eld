/// مدد الحركة حسب دليل التصميم — موحدة، لا قيم يدوية
library;

class AppDurations {
  AppDurations._();

  /// سريع — للانتقالات الخفيفة
  static const Duration fast = Duration(milliseconds: 200);

  /// عادي — للرسوم المتحركة القياسية
  static const Duration normal = Duration(milliseconds: 300);

  /// بطيء — للانتقالات الكبيرة
  static const Duration slow = Duration(milliseconds: 400);

  /// تأخير الشبكة / المحاكاة
  static const Duration networkSimulation = Duration(milliseconds: 500);

  /// مهلة GPS
  static const Duration gpsTimeout = Duration(seconds: 10);

  /// تأخير قصير للتحميل
  static const Duration shortDelay = Duration(milliseconds: 400);

  /// مدة عرض الإشعار
  static const Duration snackBar = Duration(seconds: 3);
}
