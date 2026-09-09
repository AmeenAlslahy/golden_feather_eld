import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// أنماط الخطوط حسب دليل التصميم
class AppTypography {
  AppTypography._();

  /// العائلة الخطية
  static const String fontFamily = 'Roboto'; // Android
  static const String fontFamilyIOS = 'SF Pro Text'; // iOS

  /// أحجام الخطوط
  static const double headerSize = 28.0; // عناوين رئيسية
  static const double largeButtonSize = 17.0; // أزرار كبيرة
  static const double bodySize = 16.0; // نصوص أساسية
  static const double subtitleSize = 14.0; // نصوص فرعية
  static const double captionSize = 13.0; // تعليمات صغيرة
  static const double smallSize = 12.0; // نصوص صغيرة جداً
  static const double timerSize = 40.0; // عداد الوقت في الحلقة

  /// سمك الخطوط
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight light = FontWeight.w300;

  static TextTheme get lightTextTheme {
    return GoogleFonts.robotoTextTheme().copyWith(
      // عنوان رئيسي - 28pt Bold
      headlineLarge: const TextStyle(
        fontSize: headerSize,
        fontWeight: bold,
        color: AppColors.textPrimary,
      ),
      // عنوان ثانوي - 20pt Bold
      headlineMedium: const TextStyle(
        fontSize: 20,
        fontWeight: bold,
        color: AppColors.textPrimary,
      ),
      // عنوان شريط / Dialog Title - 16pt Bold
      headlineSmall: const TextStyle(
        fontSize: bodySize,
        fontWeight: bold,
        color: AppColors.textPrimary,
      ),
      // أزرار كبيرة - 17pt Bold
      titleLarge: const TextStyle(
        fontSize: largeButtonSize,
        fontWeight: bold,
        color: AppColors.textPrimary,
      ),
      // نصوص أساسية - 16pt Regular
      bodyLarge: const TextStyle(
        fontSize: bodySize,
        fontWeight: regular,
        color: AppColors.textPrimary,
      ),
      // نصوص فرعية - 14pt Regular
      bodyMedium: const TextStyle(
        fontSize: subtitleSize,
        fontWeight: regular,
        color: AppColors.textSecondary,
      ),
      // تعليمات - 13pt Light
      bodySmall: const TextStyle(
        fontSize: captionSize,
        fontWeight: light,
        color: AppColors.textSecondary,
      ),
      // تسميات - 12pt
      labelSmall: const TextStyle(
        fontSize: smallSize,
        fontWeight: regular,
        color: AppColors.textSecondary,
      ),
      // عداد الوقت - 40pt Bold أخضر
      displayMedium: const TextStyle(
        fontSize: timerSize,
        fontWeight: bold,
        color: AppColors.successGreen,
      ),
    );
  }

  static TextTheme get darkTextTheme {
    return lightTextTheme.copyWith(
      headlineLarge: lightTextTheme.headlineLarge!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      headlineMedium: lightTextTheme.headlineMedium!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      headlineSmall: lightTextTheme.headlineSmall!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      bodyLarge: lightTextTheme.bodyLarge!.copyWith(
        color: AppColors.darkTextPrimary,
      ),
      bodyMedium: lightTextTheme.bodyMedium!.copyWith(
        color: AppColors.darkTextSecondary,
      ),
      bodySmall: lightTextTheme.bodySmall!.copyWith(
        color: AppColors.darkTextSecondary,
      ),
    );
  }
}
