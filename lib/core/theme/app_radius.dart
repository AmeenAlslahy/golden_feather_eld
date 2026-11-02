/// زوايا العناصر حسب دليل التصميم
class AppRadius {
  AppRadius._();

  // =========================================================================
  // مقياس الزوايا الجديد — Design System 2.0
  // =========================================================================

  static const double scaleSmall = 6.0;
  static const double scaleMedium = 10.0;
  static const double scaleLarge = 14.0;
  static const double scaleXLarge = 20.0;
  static const double scalePill = 999.0;

  static const double large = 14.0;
  static const double xLarge = 20.0;

  // =========================================================================
  // الأنماط الدلالية للمكونات (Semantic Components)
  // =========================================================================

  /// حقول الإدخال
  static const double input = 10.0;

  /// الأزرار
  static const double button = 12.0;

  /// البطاقات
  static const double card = 12.0;

  /// الحوارات
  static const double dialog = 16.0;

  /// الشارات (Badges)
  static const double badge = 8.0;

  /// تنبيهات الملاحظات الفورية (Feedback)
  static const double feedback = 16.0;

  /// أوراق السحب السفلية (Bottom Sheets)
  static const double bottomSheet = 16.0;

  // =========================================================================
  // ثوابت التوافق السابقة (Legacy Tokens)
  // =========================================================================

  static const double small = 4.0;
  static const double medium = 8.0;
  static const double round = 24.0;

  /// مربع الصورة في DVIR - 8px
  static const double imagePlaceholder = 8.0;

  /// المؤشرات الصغيرة المربعة (مربع الصح) - 2px
  static const double indicator = 2.0;

  /// البطاقات الكبيرة
  static const double largeCard = 12.0;

  /// الأوراق والبطاقات العريضة (رأس الدليل، صور الحوارات)
  static const double sheet = 16.0;

  /// الشارة الدائرية الكاملة (Pill) — شارات الحالة
  static const double pill = 999.0;
}
