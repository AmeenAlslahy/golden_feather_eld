import 'package:flutter/material.dart';

/// نظام الألوان الوحيد في التطبيق — الملف الوحيد الذي يحمل قيمة `Color(0x…)`.
///
/// **الهوية:** الذهبي (`primaryGold`) هو اللون الرئيسي، والأسود (`secondary`)
/// هو الثانوي — قرار المالك 2026-09-24.
///
/// **قاعدة الاستخدام:**
/// - للنصوص: `context.styles.error/success/warning/muted` (لون + خط معًا).
/// - لأزواج خلفية/نص متباينة (شارات، تنبيهات): استخدم مجموعة الوضع الفاتح
///   (`successText`+`successBg`) ومجموعة الداكن (`successOnDark`+`darkSuccessBg`).
/// - `AppColors` مباشرة مقبول للأسطح والحدود والأيقونات (`surface`, `border`,
///   `primaryGold`, `dangerRed`) — لا تُنشئ `Color(0x…)` جديدًا في الواجهات؛
///   أضِف الرمز هنا أولاً.
class AppColors {
  AppColors._();

  // ========== الهوية الأساسية ==========

  /// الذهبي — لون الهوية الرئيسي.
  static const Color primaryGold = Color(0xFFD4AF37);

  /// أسود الهوية — اللون الثانوي والخلفية الفاخرة.
  static const Color secondary = Color(0xFF0D0D0D);

  // ========== عائلة الذهبي ==========

  static const Color goldLight = Color(0xFFF4E5B1);
  static const Color goldDark = Color(0xFFA88A1F);
  static const Color goldAccent = Color(0xFFFFD700);

  /// ذهبي عميق — النص الذهبي الآمن على خلفيات فاتحة (6.94:1).
  static const Color goldDeep = Color(0xFF6E5612);

  // ========== الحالات — قيم خام ==========

  static const Color successGreen = Color(0xFF34C759);
  static const Color dangerRed = Color(0xFFFF3B30);
  static const Color warningYellow = Color(0xFFFF9500);
  static const Color infoBlue = Color(0xFF1565C0);

  // ========== الحالات — نص على خلفية فاتحة ==========

  static const Color successText = Color(0xFF157A33);  // 5.47:1
  static const Color dangerText = Color(0xFFC5221F);   // 5.91:1
  static const Color warningText = Color(0xFFB45309);  // 4.62:1
  static const Color infoText = Color(0xFF0D47A1);     // 8.59:1

  // ========== الحالات — نص على خلفية داكنة ==========

  static const Color successOnDark = Color(0xFF4ADE80); // 8.62:1
  static const Color dangerOnDark = Color(0xFFFF6B6B);  // 6.15:1
  static const Color warningOnDark = Color(0xFFFFB020); // 9.87:1
  static const Color infoOnDark = Color(0xFF64D2FF);    // 9.45:1

  // ========== الحالات — خلفيات خفيفة ==========

  static const Color successBg = Color(0xFFE8F5E9);
  static const Color dangerBg = Color(0xFFFFEBEE);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color infoBg = Color(0xFFE3F2FD);

  // ========== المحايدات ==========

  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color border = Color(0xFFE5E5EA);

  /// النص الأساسي — 19.8:1 مع الأبيض.
  static const Color textPrimary = Color(0xFF0D0D0D);

  /// النص الثانوي — 6.65:1 مع الأبيض.
  static const Color textSecondary = Color(0xFF5C5C5C);

  // ========== الوضع الداكن ==========

  static const Color darkBackground = Color(0xFF0D0D0D);
  static const Color surfaceDark = Color(0xFF1A1A1A);

  /// أبيض — 19.8:1 مع `darkBackground`.
  static const Color darkTextPrimary = Color(0xFFFFFFFF);

  /// رمادي فاتح — 8.98:1 مع `darkBackground`.
  static const Color darkTextSecondary = Color(0xFFB0B0B0);

  // ========== خلفيات الحالات — الوضع الداكن (المصدر الوحيد) ==========

  static const Color darkSuccessBg = Color(0xFF0F2417);
  static const Color darkWarningBg = Color(0xFF2A1F0A);
  static const Color darkDangerBg = Color(0xFF2A0F0F);
  static const Color darkInfoBg = Color(0xFF0A1F2A);

  // ========== الذهبي كخلفية ==========
  static const Color goldBg = Color(0xFFFDF8E7);
  static const Color darkGoldBg = Color(0xFF2A2410);

  // ========== على الذهبي / على الأسود ==========
  static const Color onGold = secondary;      // نص على خلفية ذهبية
  static const Color onBlack = primaryGold;   // نص على خلفية سوداء

  // ========== عناصر خاصة ==========

  /// لون خفيف مكمل.

  // ========== شريط التنقل السفلي ==========
  static const Color navBarBackground = surface;
  static const Color navBarActive = goldDeep;
  static const Color navBarInactive = Color(0xFF8E8E93);

  // ========== مساعدات متكررة ==========

  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF0D0D0D);

  // ========== دوال مساعدة ==========

  static Color textPrimaryFor(Brightness b) =>
      b == Brightness.light ? textPrimary : darkTextPrimary;

  static Color textSecondaryFor(Brightness b) =>
      b == Brightness.light ? textSecondary : darkTextSecondary;

  static Color backgroundFor(Brightness b) =>
      b == Brightness.light ? background : darkBackground;

  static Color surfaceFor(Brightness b) =>
      b == Brightness.light ? surface : surfaceDark;

  static Color borderFor(Brightness b) =>
      b == Brightness.light ? border : const Color(0xFF3A3A3C);

  /// النص الذهبي الآمن حسب الخلفية.
  static Color goldFor(Brightness b) =>
      b == Brightness.light ? goldDeep : primaryGold;
}
