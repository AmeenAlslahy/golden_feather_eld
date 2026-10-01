import 'package:flutter/material.dart';
import 'app_colors.dart';

/// أنماط الخطوط حسب دليل التصميم.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Roboto';
  static const String fontFamilyIOS = 'SF Pro Text';

  static const double headerSize = 28.0;
  static const double titleSize = 20.0;
  static const double largeButtonSize = 17.0;
  static const double bodySize = 16.0;
  static const double subtitleSize = 14.0;
  static const double captionSize = 13.0;
  static const double smallSize = 12.0;
  static const double timerSize = 40.0;

  static const FontWeight bold = FontWeight.w700;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight light = FontWeight.w300;

  /// الأساس من خط Roboto **المضمّن محلياً** (pubspec fonts) — كان سابقاً
  /// GoogleFonts.robotoTextTheme() الذي يجلب الخط عبر الشبكة عند أول
  /// استخدام (قفزة إقلاع + سلوك مختلف أوفلاين). أنماطنا تتجاوز الأحجام
  /// والأوزان والألوان على أي حال، فالأساس يحتاج عائلة الخط فقط.
  static const TextTheme _base = TextTheme(
    displayLarge: TextStyle(fontFamily: fontFamily),
    displayMedium: TextStyle(fontFamily: fontFamily),
    displaySmall: TextStyle(fontFamily: fontFamily),
    headlineLarge: TextStyle(fontFamily: fontFamily),
    headlineMedium: TextStyle(fontFamily: fontFamily),
    headlineSmall: TextStyle(fontFamily: fontFamily),
    titleLarge: TextStyle(fontFamily: fontFamily),
    titleMedium: TextStyle(fontFamily: fontFamily),
    titleSmall: TextStyle(fontFamily: fontFamily),
    bodyLarge: TextStyle(fontFamily: fontFamily),
    bodyMedium: TextStyle(fontFamily: fontFamily),
    bodySmall: TextStyle(fontFamily: fontFamily),
    labelLarge: TextStyle(fontFamily: fontFamily),
    labelMedium: TextStyle(fontFamily: fontFamily),
    labelSmall: TextStyle(fontFamily: fontFamily),
  );

  /// يبني نسخة ملونة من الأساس — **مصدر واحد** يستخدمه الوضعان،
  /// بدل كتلتَي copyWith متكررتين.
  static TextTheme _colored(Color primary, Color secondary, Color gold) {
    return _base.copyWith(
      headlineLarge:
          _base.headlineLarge!.copyWith(color: primary, letterSpacing: -0.5),
      headlineMedium:
          _base.headlineMedium!.copyWith(color: primary, letterSpacing: -0.3),
      titleLarge: _base.titleLarge!.copyWith(color: primary),
      bodyLarge: _base.bodyLarge!.copyWith(color: primary),
      bodyMedium: _base.bodyMedium!.copyWith(color: secondary),
      bodySmall: _base.bodySmall!.copyWith(color: secondary),
      labelSmall: _base.labelSmall!.copyWith(color: secondary),
      displayMedium: _base.displayMedium!.copyWith(color: gold),
    );
  }

  static final TextTheme lightTextTheme = _colored(
    AppColors.textPrimary,
    AppColors.textSecondary,
    AppColors.goldDeep,
  );

  static final TextTheme darkTextTheme = _colored(
    AppColors.darkTextPrimary,
    AppColors.darkTextSecondary,
    AppColors.primaryGold,
  );
}
