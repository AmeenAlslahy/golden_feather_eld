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

  // =========================================================================
  // 1. ألوان الهوية الأساسية (Brand Palette) — Golden Feather 2.0
  // =========================================================================

  /// الذهبي — لون الهوية الأساسي
  static const Color brandGold = Color(0xFFD4AF37);

  /// ذهبي فاتح للهوية
  static const Color brandGoldLight = Color(0xFFE8CC73);

  /// ذهبي داكن للهوية
  static const Color brandGoldDark = Color(0xFFA68422);

  /// ذهبي عميق — آمن للنصوص على الخلفيات الفاتحة
  static const Color brandGoldDeep = Color(0xFF6E5612);

  /// أسود الهوية الفاخر
  static const Color brandBlack = Color(0xFF0D0D0D);

  /// أبيض الهوية النقي
  static const Color brandWhite = Color(0xFFFFFFFF);

  /// تدرج الهوية الذهبي الرسمي — وقفات الألوان الثلاث
  static const List<Color> goldenGradientColors = [
    brandGoldDark,
    brandGold,
    brandGoldLight,
  ];

  // =========================================================================
  // 2. الألوان الدلالية — الوضع الفاتح (Light Semantic Palette)
  // =========================================================================

  static const Color lightBackground = Color(0xFFF7F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF1F3F5);
  static const Color lightSurfaceElevated = Color(0xFFFFFFFF);

  static const Color lightTextPrimary = Color(0xFF171717);
  // ثانوي أغمق من السابق (#62666D): يضمن تبايناً ≥ 7.7:1 على كل أسطح
  // الاستخدام الفاتحة (أبيض/خلفية/سطح ثانوي/حاويات الحالات والذهبي)،
  // ويحافظ على تدرج واضح تحت النص الأساسي #171717.
  static const Color lightTextSecondary = Color(0xFF4A4A4A);
  // خافت أغمق من السابق (#777B82): يحقق ≥ 4.5:1 للنص العادي على كل
  // الأسطح الفاتحة الفعلية (بما فيها #F1F3F5 و#F8F1DC)، ويبقى أخف من
  // lightTextSecondary للحفاظ على التسلسل البصري.
  static const Color lightTextMuted = Color(0xFF676C74);

  static const Color lightBorder = Color(0xFFE4E6EA);
  static const Color lightBorderStrong = Color(0xFFC9CDD3);

  /// حد الحقول التفاعلية (نص/قائمة/توقيع) — رمز مستقل عن [lightBorder]
  /// الذي يخدم الفواصل والحدود الزخرفية (بطاقات/حوارات/صفوف معلومات).
  /// القيمة محسوبة لتحقيق ≥ 3:1 على كل خلفيات الحقول الفعلية في الوضع الفاتح
  /// (أبيض، #F7F8FA، #F1F3F5، #FDF8E7، وخلفيات الخلايا المركبة).
  static const Color lightInputBorder = Color(0xFF80868F);

  static const Color lightPrimary = Color(0xFFD4AF37);
  static const Color lightOnPrimary = Color(0xFF171717);

  static const Color lightPrimaryText = Color(0xFF6E5612);
  static const Color lightPrimaryContainer = Color(0xFFF8F1DC);
  static const Color lightOnPrimaryContainer = Color(0xFF59450E);

  // =========================================================================
  // 3. الألوان الدلالية — الوضع الداكن (Dark Semantic Palette)
  // =========================================================================

  static const Color darkBackground = Color(0xFF101114);
  static const Color darkSurface = Color(0xFF1B1D21);
  static const Color darkSurfaceSecondary = Color(0xFF25282D);
  static const Color darkSurfaceElevated = Color(0xFF2B2E33);

  static const Color darkTextPrimary = Color(0xFFF5F5F5);
  static const Color darkTextSecondary = Color(0xFFB4B7BE);
  static const Color darkTextMuted = Color(0xFF969AA3);

  static const Color darkBorder = Color(0xFF35383E);
  static const Color darkBorderStrong = Color(0xFF50545B);

  /// حد الحقول التفاعلية في الوضع الداكن — مستقل عن [darkBorder] الزخرفي.
  /// محسوب لتحقيق ≥ 3:1 على كل خلفيات الحقول الفعلية، بما فيها السطح
  /// المرتفع #2B2E33 (أفتح سطح داكن) مع هامش آمن.
  static const Color darkInputBorder = Color(0xFF767D87);

  static const Color darkPrimary = Color(0xFFE8CC73);
  static const Color darkOnPrimary = Color(0xFF171717);

  static const Color darkPrimaryText = Color(0xFFE8CC73);
  static const Color darkPrimaryContainer = Color(0xFF302916);
  static const Color darkOnPrimaryContainer = Color(0xFFF1D98B);

  // =========================================================================
  // 4. رموز التوافق مع النظام الحالي (Legacy Compatibility Tokens)
  // =========================================================================

  /// الذهبي الرئيسي — نفس [brandGold]
  static const Color primaryGold = brandGold;

  /// أسود الهوية — نفس [brandBlack]
  static const Color secondary = brandBlack;

  // عائلة الذهبي
  static const Color goldLight = Color(0xFFF4E5B1);
  static const Color goldDark = Color(0xFFA88A1F);
  static const Color goldAccent = Color(0xFFFFD700);
  static const Color goldDeep = brandGoldDeep;

  // الحالات — قيم خام
  static const Color successGreen = Color(0xFF34C759);
  // أحمر الخطأ القياسي (Material Red 800): آمن كنص أبيض عليه (5.62:1)
  // وكرَسم للأيقونات/الحدود. كان #FF3B30 ولا يحقق 4.5:1 للنص الأبيض.
  static const Color dangerRed = Color(0xFFC62828);
  static const Color warningYellow = Color(0xFFFF9500);
  static const Color infoBlue = Color(0xFF1565C0);

  // الحالات — نص على خلفية فاتحة (قيم Material القياسية المألوفة)
  static const Color successText = Color(0xFF2E7D32); // Green 800
  static const Color dangerText = Color(0xFFC62828); // Red 800
  // أغمق قليلاً من Amber 700 (#B45309) ليحقق 4.5:1 حتى على الحاوية
  // الذهبية المحددة #F8F1DC، ويبقى برتقالياً دلالياً واضحاً.
  static const Color warningText = Color(0xFFA94F08);
  static const Color infoText = Color(0xFF1565C0); // Blue 800

  // الحالات — نص على خلفية داكنة
  static const Color successOnDark = Color(0xFF4ADE80);
  static const Color dangerOnDark = Color(0xFFFF6B6B);
  static const Color warningOnDark = Color(0xFFFFB74D); // Amber 300
  static const Color infoOnDark = Color(0xFF64B5F6); // Blue 300

  // الحالات — خلفيات خفيفة
  static const Color successBg = Color(0xFFE8F5E9);
  static const Color dangerBg = Color(0xFFFFEBEE);
  static const Color warningBg = Color(0xFFFFF3E0);
  static const Color infoBg = Color(0xFFE3F2FD);

  // الحالات — تعبئة صلبة للرسائل المنبثقة (SnackBar/Toast).
  // الألوان الدلالية المألوفة في أغلب التطبيقات، وكل زوج مفحوص ≥ 4.5:1.
  static const Color successFill = Color(0xFF2E7D32);
  static const Color onSuccessFill = Color(0xFFFFFFFF);
  static const Color dangerFill = Color(0xFFC62828);
  static const Color onDangerFill = Color(0xFFFFFFFF);
  // البرتقالي المألوف للتحذير يحتاج نصاً داكناً ليحقق التباين.
  static const Color warningFill = Color(0xFFF57C00);
  static const Color onWarningFill = Color(0xFF171717);
  static const Color infoFill = Color(0xFF1565C0);
  static const Color onInfoFill = Color(0xFFFFFFFF);

  // المحايدات — الوضع الفاتح
  static const Color background = lightBackground;
  static const Color surface = lightSurface;
  static const Color border = lightBorder;
  static const Color textPrimary = lightTextPrimary;
  static const Color textSecondary = lightTextSecondary;

  // المحايدات — الوضع الداكن
  static const Color surfaceDark = darkSurface;

  // خلفيات الحالات — الوضع الداكن (المصدر الوحيد)
  // أُشبعت أكثر من السابق (#0F2417/#2A1F0A/#2A0F0F/#0A1F2A) لأن الخلفيات
  // الداكنة جداً كانت تبدو باهتة؛ النصوص الدلالية عليها تبقى ≥ 4.5:1.
  static const Color darkSuccessBg = Color(0xFF14301C);
  static const Color darkWarningBg = Color(0xFF3A2A0C);
  static const Color darkDangerBg = Color(0xFF3A1414);
  static const Color darkInfoBg = Color(0xFF10293B);

  // الذهبي كخلفية
  static const Color goldBg = Color(0xFFFDF8E7);
  static const Color darkGoldBg = Color(0xFF2A2410);

  // أقسام صفحة التعليمات (دلالة تصميمية: شريط داكن دائم)
  static const Color inspectionBand = Color(0xFF333A45);
  static const Color inspectionBandDark = Color(0xFF1E242C);
  static const Color manualBand = Color(0xFFF7F7F7);
  static const Color manualBandDark = Color(0xFF1C1C1E);

  // عناصر الصور البديلة (Placeholders)
  static const Color placeholderGrey = Color(0xFF808080);
  static const Color placeholderDark = Color(0xFF424242);
  static const Color placeholderSurfaceLight = Color(0xFFF2F2F7);
  static const Color placeholderSurfaceDark = Color(0xFF2C2C2E);
  static const Color placeholderBorderLight = Color(0xFFD1D1D6);
  static const Color placeholderBorderDark = Color(0xFF3A3A3C);
  static const Color checkSquare = Color(0x8A000000);

  // طبقات التعتيم
  static const Color scrim = Color(0xD9000000);

  // جدول رأس السجل اليومي RODS (شكل الورقة الرسمية)
  static const Color rodsHeaderBg = Color(0xFFF2F2F2);
  static const Color rodsHeaderText = Color(0xFF222222);
  static const Color rodsHeaderSubtext = Color(0xFF333333);

  // على الذهبي / على الأسود
  static const Color onGold = lightOnPrimary;
  static const Color onBlack = primaryGold;

  // شريط التنقل السفلي
  static const Color navBarBackground = surface;
  static const Color navBarActive = goldDeep;
  static const Color navBarInactive = Color(0xFF8E8E93);

  // قيم كانت خامة داخل app_theme
  static const Color radioInactive = Color(0xFFC7C7CC);
  static const Color darkDivider = Color(0xFF48484A);
  static const Color inkOverlay = Color(0xFF000000);

  // مساعدات متكررة
  static const Color transparent = Colors.transparent;
  static const Color white = brandWhite;
  static const Color black = brandBlack;

  // =========================================================================
  // 5. دوال مساعدة معتمدة على السطوع
  // =========================================================================

  static Color textPrimaryFor(Brightness b) =>
      b == Brightness.light ? lightTextPrimary : darkTextPrimary;

  static Color textSecondaryFor(Brightness b) =>
      b == Brightness.light ? lightTextSecondary : darkTextSecondary;

  static Color backgroundFor(Brightness b) =>
      b == Brightness.light ? lightBackground : darkBackground;

  static Color surfaceFor(Brightness b) =>
      b == Brightness.light ? lightSurface : darkSurface;

  static Color borderFor(Brightness b) =>
      b == Brightness.light ? lightBorder : darkBorder;

  /// حد الحقول التفاعلية حسب السطوع.
  static Color inputBorderFor(Brightness b) =>
      b == Brightness.light ? lightInputBorder : darkInputBorder;

  /// النص الذهبي الآمن حسب الخلفية
  static Color goldFor(Brightness b) =>
      b == Brightness.light ? goldDeep : primaryGold;

  static Color placeholderSurfaceFor(Brightness b) =>
      b == Brightness.light ? placeholderSurfaceLight : placeholderSurfaceDark;

  static Color placeholderBorderFor(Brightness b) =>
      b == Brightness.light ? placeholderBorderLight : placeholderBorderDark;
}
