import 'package:flutter/material.dart';
import 'app_colors.dart';

/// أنماط الخطوط حسب دليل التصميم.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Roboto';
  static const String fontFamilyIOS = 'SF Pro Text';

  static const double headerSize = 28.0;
  static const double pageTitleSize = 24.0;
  static const double appBarTitleSize = 18.0;
  static const double titleSize = pageTitleSize;
  static const double sectionTitleSize = 16.0;
  static const double largeButtonSize = 16.0;
  static const double bodySize = 16.0;
  static const double subtitleSize = 14.0;
  static const double captionSize = 12.0;
  static const double smallSize = 12.0;
  static const double timerSize = 40.0;
  static const double heroTimerSize = 52.0;
  static const double numberSize = 18.0;

  /// �矫�� ����� �����꟢ (SRS 8.2).
  static const double sheetTitleSize = 18.0;
  static const double sheetItemTitleSize = 14.0;
  static const double sheetCaptionSize = 12.0;
  static const double sheetItemSize = 14.0;

  static const FontWeight bold = FontWeight.w700;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight light = FontWeight.w300;

  /// الأساس من خط Roboto **المضمّن محلياً** (pubspec fonts) — كان سابقاً
  /// GoogleFonts.robotoTextTheme() الذي يجلب الخط عبر الشبكة عند أول
  /// استخدام (قفزة إقلاع + سلوك مختلف أوفلاين). أنماطنا تتجاوز الأحجام
  /// والأوزان والألوان على أي حال، فالأساس يحتاج عائلة الخط فقط.
  static const TextTheme _base = TextTheme(
    displayLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 57,
      fontWeight: regular,
      height: 1.12,
    ),
    displayMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: 45,
      fontWeight: regular,
      height: 1.16,
    ),
    displaySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: 36,
      fontWeight: regular,
      height: 1.22,
    ),
    headlineLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 32,
      fontWeight: bold,
      height: 1.25,
    ),
    headlineMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: headerSize,
      fontWeight: semiBold,
      height: 1.29,
    ),
    headlineSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: pageTitleSize,
      fontWeight: semiBold,
      height: 1.33,
    ),
    titleLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: 22,
      fontWeight: semiBold,
      height: 1.27,
    ),
    titleMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: sectionTitleSize,
      fontWeight: semiBold,
      height: 1.5,
    ),
    titleSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: subtitleSize,
      fontWeight: semiBold,
      height: 1.43,
    ),
    bodyLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: bodySize,
      fontWeight: regular,
      height: 1.5,
    ),
    bodyMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: subtitleSize,
      fontWeight: regular,
      height: 1.43,
    ),
    bodySmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: smallSize,
      fontWeight: regular,
      height: 1.33,
    ),
    labelLarge: TextStyle(
      fontFamily: fontFamily,
      fontSize: bodySize,
      fontWeight: semiBold,
      height: 1.25,
    ),
    labelMedium: TextStyle(
      fontFamily: fontFamily,
      fontSize: subtitleSize,
      fontWeight: semiBold,
      height: 1.43,
    ),
    labelSmall: TextStyle(
      fontFamily: fontFamily,
      fontSize: smallSize,
      fontWeight: semiBold,
      height: 1.33,
    ),
  );

  /// يبني نسخة ملونة من الأساس — **مصدر واحد** يستخدمه الوضعان،
  /// بدل كتلتَي copyWith متكررتين.
  static TextTheme _colored(Color primary, Color secondary, Color gold) {
    return _base.copyWith(
      headlineLarge: _base.headlineLarge!.copyWith(
        color: primary,
        letterSpacing: -0.5,
      ),
      headlineMedium: _base.headlineMedium!.copyWith(
        color: primary,
        letterSpacing: -0.3,
      ),
      headlineSmall: _base.headlineSmall!.copyWith(color: primary),
      titleLarge: _base.titleLarge!.copyWith(color: primary),
      titleMedium: _base.titleMedium!.copyWith(color: primary),
      titleSmall: _base.titleSmall!.copyWith(color: primary),
      bodyLarge: _base.bodyLarge!.copyWith(color: primary),
      bodyMedium: _base.bodyMedium!.copyWith(color: secondary),
      bodySmall: _base.bodySmall!.copyWith(color: secondary),
      labelLarge: _base.labelLarge!.copyWith(color: primary),
      labelMedium: _base.labelMedium!.copyWith(color: primary),
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
