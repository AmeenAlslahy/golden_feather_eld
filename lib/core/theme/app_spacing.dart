/// المسافات حسب دليل التصميم
class AppSpacing {
  AppSpacing._();

  /// المسافات الأساسية
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double smMd = 12.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;

  /// مسافات محددة
  static const double screenPadding = 16.0; // padding يمين ويسار
  static const double cardPadding = 16.0;
  static const double buttonHeight = 52.0;
  static const double dividerHeight = 1.0; // سمك الفاصل
  static const double iconSize = 24.0;
  static const double loaderSize = 20.0; // حجم مؤشر التحميل داخل الأزرار
  static const double indicatorSize = 20.0; // حجم المؤشرات الصغيرة

  /// مسافات دقيقة — للحالات الخاصة (pill, tight rows)
  static const double xxs = 2.0;
  static const double xsSm = 6.0;
  static const double xsLg = 10.0;
  static const double mdLg = 20.0;
  static const double xxl = 36.0;
  static const double xxxl = 48.0;
}
