import 'package:flutter/material.dart';

import 'app_colors.dart';

/// امتداد ثيم مخصص لألوان Golden Feather (Design System 2.0).
///
/// يغطي الأدوار الدلالية الخاصة بالتطبيق التي لا يغطيها [ColorScheme]
/// القياسي بصورة كافية، ويُمكّن المكونات من الوصول للألوان المناسبة
/// للثيم النشط عبر `context.goldenColors` دون فحص يدوي لـ Brightness.
@immutable
class GoldenColors extends ThemeExtension<GoldenColors> {
  const GoldenColors({
    required this.surfaceSecondary,
    required this.surfaceElevated,
    required this.textMuted,
    required this.border,
    required this.borderStrong,
    required this.inputBorder,
    required this.primaryText,
    required this.successText,
    required this.successBackground,
    required this.errorText,
    required this.errorBackground,
    required this.warningText,
    required this.warningBackground,
    required this.infoText,
    required this.infoBackground,
    this.screenSurface = AppColors.lightSurface,
    this.background = AppColors.lightBackground,
    this.textPrimary = AppColors.lightTextPrimary,
    this.textSecondary = AppColors.lightTextSecondary,
    this.gold = AppColors.goldDeep,
    this.goldContainer = AppColors.goldBg,
    this.disabledForeground = AppColors.lightTextMuted,
    this.disabledSurface = AppColors.lightSurfaceSecondary,
    this.selectedContainer = AppColors.lightPrimaryContainer,
    this.focusRing = AppColors.brandGoldDark,
    this.pressedOverlay = const Color(0x1F000000),
    this.hoverOverlay = const Color(0x0A000000),
    this.brandGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: AppColors.goldenGradientColors,
    ),
  });

  /// تدرج الهوية الذهبي الرسمي لشريط التطبيق والعناصر المميزة
  final LinearGradient brandGradient;

  /// سطح الشاشة العام (Scaffold / Canvas)
  final Color screenSurface;

  /// خلفية التطبيق العامة
  final Color background;

  /// لون النص الأساسي المتباين مع السطح
  final Color textPrimary;

  /// لون النص الثانوي للتسميات والأوصاف
  final Color textSecondary;

  /// سطح ثانوي مميز عن السطح الأساسي
  final Color surfaceSecondary;

  /// سطح مرتفع للبطاقات والحوارات
  final Color surfaceElevated;

  /// نص خافت أو غير نشط
  final Color textMuted;

  /// حدود قياسية خفيفة
  final Color border;

  /// حدود واضحة قوية
  final Color borderStrong;

  /// حد الحقول التفاعلية (نص/قائمة/توقيع) — منفصل عن [border] الذي يخدم
  /// الفواصل والحدود الزخرفية (بطاقات/حوارات/صفوف معلومات).
  final Color inputBorder;

  /// النص الذهبي الدلالي المتناسق مع السطح
  final Color primaryText;

  /// لون الهوية الذهبي المتناسق مع السطوع
  final Color gold;

  /// حاوية خلفية ذهبية خفيفة
  final Color goldContainer;

  /// نص النجاح
  final Color successText;

  /// خلفية حاوية النجاح
  final Color successBackground;

  /// نص الخطأ / الخطر
  final Color errorText;

  /// خلفية حاوية الخطأ
  final Color errorBackground;

  /// نص التحذير
  final Color warningText;

  /// خلفية حاوية التحذير
  final Color warningBackground;

  /// نص المعلومات
  final Color infoText;

  /// خلفية حاوية المعلومات
  final Color infoBackground;

  /// لون المقدمة للعناصر المعطلة
  final Color disabledForeground;

  /// لون السطح للعناصر المعطلة
  final Color disabledSurface;

  /// خلفية العنصر المحدد
  final Color selectedContainer;

  /// لون حلقة التركيز للوحة المفاتيح — ذهبي داكن في الفاتح لتحقيق 3:1
  /// على خلفيات الحقول، وذهبي فاتح في الداكن.
  final Color focusRing;

  /// طبقة التعتيم عند الضغط
  final Color pressedOverlay;

  /// طبقة التعتيم عند التحويم
  final Color hoverOverlay;

  /// النسخة الدلالية للوضع الفاتح (Light Mode)
  static const GoldenColors light = GoldenColors(
    screenSurface: AppColors.lightSurface,
    background: AppColors.lightBackground,
    textPrimary: AppColors.lightTextPrimary,
    textSecondary: AppColors.lightTextSecondary,
    surfaceSecondary: AppColors.lightSurfaceSecondary,
    surfaceElevated: AppColors.lightSurfaceElevated,
    textMuted: AppColors.lightTextMuted,
    border: AppColors.lightBorder,
    borderStrong: AppColors.lightBorderStrong,
    inputBorder: AppColors.lightInputBorder,
    primaryText: AppColors.lightPrimaryText,
    gold: AppColors.goldDeep,
    goldContainer: AppColors.goldBg,
    successText: AppColors.successText,
    successBackground: AppColors.successBg,
    errorText: AppColors.dangerText,
    errorBackground: AppColors.dangerBg,
    warningText: AppColors.warningText,
    warningBackground: AppColors.warningBg,
    infoText: AppColors.infoText,
    infoBackground: AppColors.infoBg,
    disabledForeground: AppColors.lightTextMuted,
    disabledSurface: AppColors.lightSurfaceSecondary,
    selectedContainer: AppColors.lightPrimaryContainer,
    focusRing: AppColors.brandGoldDark,
    pressedOverlay: Color(0x1F000000),
    hoverOverlay: Color(0x0A000000),
  );

  /// النسخة الدلالية للوضع الداكن (Dark Mode)
  static const GoldenColors dark = GoldenColors(
    screenSurface: AppColors.darkSurface,
    background: AppColors.darkBackground,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    surfaceSecondary: AppColors.darkSurfaceSecondary,
    surfaceElevated: AppColors.darkSurfaceElevated,
    textMuted: AppColors.darkTextMuted,
    border: AppColors.darkBorder,
    borderStrong: AppColors.darkBorderStrong,
    inputBorder: AppColors.darkInputBorder,
    primaryText: AppColors.darkPrimaryText,
    gold: AppColors.primaryGold,
    goldContainer: AppColors.darkGoldBg,
    successText: AppColors.successOnDark,
    successBackground: AppColors.darkSuccessBg,
    errorText: AppColors.dangerOnDark,
    errorBackground: AppColors.darkDangerBg,
    warningText: AppColors.warningOnDark,
    warningBackground: AppColors.darkWarningBg,
    infoText: AppColors.infoOnDark,
    infoBackground: AppColors.darkInfoBg,
    disabledForeground: AppColors.darkTextMuted,
    disabledSurface: AppColors.darkSurfaceSecondary,
    selectedContainer: AppColors.darkPrimaryContainer,
    focusRing: AppColors.brandGoldLight,
    pressedOverlay: Color(0x1FFFFFFF),
    hoverOverlay: Color(0x0AFFFFFF),
  );

  /// الحصول على الامتداد المناسب بحسب السطوع
  factory GoldenColors.fromBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }

  @override
  GoldenColors copyWith({
    Color? screenSurface,
    Color? background,
    Color? textPrimary,
    Color? textSecondary,
    Color? surfaceSecondary,
    Color? surfaceElevated,
    Color? textMuted,
    Color? border,
    Color? borderStrong,
    Color? inputBorder,
    Color? primaryText,
    Color? gold,
    Color? goldContainer,
    Color? successText,
    Color? successBackground,
    Color? errorText,
    Color? errorBackground,
    Color? warningText,
    Color? warningBackground,
    Color? infoText,
    Color? infoBackground,
    Color? disabledForeground,
    Color? disabledSurface,
    Color? selectedContainer,
    Color? focusRing,
    Color? pressedOverlay,
    Color? hoverOverlay,
    LinearGradient? brandGradient,
  }) {
    return GoldenColors(
      screenSurface: screenSurface ?? this.screenSurface,
      background: background ?? this.background,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      surfaceSecondary: surfaceSecondary ?? this.surfaceSecondary,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textMuted: textMuted ?? this.textMuted,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      inputBorder: inputBorder ?? this.inputBorder,
      primaryText: primaryText ?? this.primaryText,
      gold: gold ?? this.gold,
      goldContainer: goldContainer ?? this.goldContainer,
      successText: successText ?? this.successText,
      successBackground: successBackground ?? this.successBackground,
      errorText: errorText ?? this.errorText,
      errorBackground: errorBackground ?? this.errorBackground,
      warningText: warningText ?? this.warningText,
      warningBackground: warningBackground ?? this.warningBackground,
      infoText: infoText ?? this.infoText,
      infoBackground: infoBackground ?? this.infoBackground,
      disabledForeground: disabledForeground ?? this.disabledForeground,
      disabledSurface: disabledSurface ?? this.disabledSurface,
      selectedContainer: selectedContainer ?? this.selectedContainer,
      focusRing: focusRing ?? this.focusRing,
      pressedOverlay: pressedOverlay ?? this.pressedOverlay,
      hoverOverlay: hoverOverlay ?? this.hoverOverlay,
      brandGradient: brandGradient ?? this.brandGradient,
    );
  }

  @override
  GoldenColors lerp(ThemeExtension<GoldenColors>? other, double t) {
    if (other is! GoldenColors) return this;
    return GoldenColors(
      screenSurface: Color.lerp(screenSurface, other.screenSurface, t)!,
      background: Color.lerp(background, other.background, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      surfaceSecondary: Color.lerp(surfaceSecondary, other.surfaceSecondary, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      inputBorder: Color.lerp(inputBorder, other.inputBorder, t)!,
      primaryText: Color.lerp(primaryText, other.primaryText, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      goldContainer: Color.lerp(goldContainer, other.goldContainer, t)!,
      successText: Color.lerp(successText, other.successText, t)!,
      successBackground:
          Color.lerp(successBackground, other.successBackground, t)!,
      errorText: Color.lerp(errorText, other.errorText, t)!,
      errorBackground: Color.lerp(errorBackground, other.errorBackground, t)!,
      warningText: Color.lerp(warningText, other.warningText, t)!,
      warningBackground:
          Color.lerp(warningBackground, other.warningBackground, t)!,
      infoText: Color.lerp(infoText, other.infoText, t)!,
      infoBackground: Color.lerp(infoBackground, other.infoBackground, t)!,
      disabledForeground:
          Color.lerp(disabledForeground, other.disabledForeground, t)!,
      disabledSurface: Color.lerp(disabledSurface, other.disabledSurface, t)!,
      selectedContainer:
          Color.lerp(selectedContainer, other.selectedContainer, t)!,
      focusRing: Color.lerp(focusRing, other.focusRing, t)!,
      pressedOverlay: Color.lerp(pressedOverlay, other.pressedOverlay, t)!,
      hoverOverlay: Color.lerp(hoverOverlay, other.hoverOverlay, t)!,
      brandGradient:
          LinearGradient.lerp(brandGradient, other.brandGradient, t) ??
              brandGradient,
    );
  }
}
