import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

  /// نخزّن الأساس مرة واحدة — أداء أفضل بكثير من getter.
  static final TextTheme _base = GoogleFonts.robotoTextTheme();

  static final TextTheme lightTextTheme = _base.copyWith(
    headlineLarge: const TextStyle(
      fontSize: headerSize,
      fontWeight: bold,
      color: AppColors.textPrimary,
      letterSpacing: -0.5,
      height: 1.2,
    ),
    headlineMedium: const TextStyle(
      fontSize: 20,
      fontWeight: bold,
      color: AppColors.textPrimary,
      letterSpacing: -0.3,
      height: 1.25,
    ),
    headlineSmall: const TextStyle(
      fontSize: bodySize,
      fontWeight: bold,
      color: AppColors.textPrimary,
      height: 1.3,
    ),
    titleLarge: const TextStyle(
      fontSize: largeButtonSize,
      fontWeight: bold,
      color: AppColors.textPrimary,
      height: 1.3,
    ),
    bodyLarge: const TextStyle(
      fontSize: bodySize,
      fontWeight: regular,
      color: AppColors.textPrimary,
      height: 1.5,
    ),
    bodyMedium: const TextStyle(
      fontSize: subtitleSize,
      fontWeight: regular,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    bodySmall: const TextStyle(
      fontSize: captionSize,
      fontWeight: light,
      color: AppColors.textSecondary,
      height: 1.4,
    ),
    labelSmall: const TextStyle(
      fontSize: smallSize,
      fontWeight: regular,
      color: AppColors.textSecondary,
      letterSpacing: 0.2,
      height: 1.3,
    ),
    // عداد الوقت — ذهبي عميق لضمان التباين على خلفية فاتحة (6.94:1)
    displayMedium: const TextStyle(
      fontSize: timerSize,
      fontWeight: bold,
      color: AppColors.goldDeep,
      letterSpacing: 1.0,
      fontFeatures: [FontFeature.tabularFigures()],
      height: 1.1,
    ),
  );

  /// الوضع الداكن — يغطي كل الأنماط.
  static final TextTheme darkTextTheme = lightTextTheme.copyWith(
    headlineLarge: lightTextTheme.headlineLarge!
        .copyWith(color: AppColors.darkTextPrimary),
    headlineMedium: lightTextTheme.headlineMedium!
        .copyWith(color: AppColors.darkTextPrimary),
    headlineSmall: lightTextTheme.headlineSmall!
        .copyWith(color: AppColors.darkTextPrimary),
    titleLarge:
        lightTextTheme.titleLarge!.copyWith(color: AppColors.darkTextPrimary),
    bodyLarge:
        lightTextTheme.bodyLarge!.copyWith(color: AppColors.darkTextPrimary),
    bodyMedium:
        lightTextTheme.bodyMedium!.copyWith(color: AppColors.darkTextSecondary),
    bodySmall:
        lightTextTheme.bodySmall!.copyWith(color: AppColors.darkTextSecondary),
    labelSmall:
        lightTextTheme.labelSmall!.copyWith(color: AppColors.darkTextSecondary),
    // عداد الوقت — ذهبي لامع على أسود (9.24:1)
    displayMedium:
        lightTextTheme.displayMedium!.copyWith(color: AppColors.primaryBlue),
  );
}
