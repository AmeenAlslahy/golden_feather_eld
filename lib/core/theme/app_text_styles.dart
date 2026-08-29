import 'package:flutter/material.dart';
import 'app_typography.dart';
import 'app_colors.dart';

/// الأنماط الدلالية للنصوص حسب دليل التصميم
class AppTextStyles {
  final BuildContext context;

  AppTextStyles(this.context);

  Brightness get _brightness => Theme.of(context).brightness;
  bool get _isLight => _brightness == Brightness.light;
  TextTheme get _textTheme => _isLight ? AppTypography.lightTextTheme : AppTypography.darkTextTheme;

  // ========== العناوين ==========

  /// عنوان الصفحة (pageTitle = 20 / w700)
  TextStyle get pageTitle => _textTheme.headlineMedium ?? const TextStyle(fontSize: 20, fontWeight: AppTypography.bold);

  /// عنوان القسم (sectionTitle = 16 / w600)
  TextStyle get sectionTitle => (_textTheme.headlineSmall ?? const TextStyle(fontSize: 16)).copyWith(
    fontWeight: AppTypography.semiBold,
  );

  // ========== النصوص الأساسية ==========

  /// النص الأساسي (body = 16 / w400)
  TextStyle get body => _textTheme.bodyLarge ?? const TextStyle(fontSize: 16, fontWeight: AppTypography.regular);

  /// النص الأساسي العريض (bodyBold = 16 / w700)
  TextStyle get bodyBold => (_textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(
    fontWeight: AppTypography.bold,
  );

  /// النص العربي (arabicBody = 16 / w400 + height 1.7)
  TextStyle get arabicBody => (_textTheme.bodyLarge ?? const TextStyle(fontSize: 16, fontWeight: AppTypography.regular)).copyWith(
    height: 1.7,
  );

  /// الشرح (caption = 12 / w400)
  TextStyle get caption => _textTheme.labelSmall ?? const TextStyle(fontSize: 12, fontWeight: AppTypography.regular);

  // ========== الأزرار ==========

  /// نص الزر (buttonText = 16 / w700)
  TextStyle get buttonText => (_textTheme.bodyLarge ?? const TextStyle(fontSize: 16)).copyWith(
    fontWeight: AppTypography.bold,
  );

  // ========== الحالات ==========

  /// نص الخطأ (errorText = 14 / w500 + danger)
  TextStyle get errorText => (_textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
    fontWeight: FontWeight.w500,
    color: AppColors.dangerRed,
  );

  /// نص النجاح (successText = 14 / w500 + success)
  TextStyle get successText => (_textTheme.bodyMedium ?? const TextStyle(fontSize: 14)).copyWith(
    fontWeight: FontWeight.w500,
    color: AppColors.successGreen,
  );

  // ========== الأرقام ==========

  /// الأرقام الثابتة (number = 18 / w700 + monospace font features)
  TextStyle get number => const TextStyle(
    fontSize: 18,
    fontWeight: AppTypography.bold,
    fontFeatures: [FontFeature.tabularFigures()],
  ).copyWith(
    color: AppColors.textPrimaryForBrightness(_brightness),
  );
}

/// امتداد للوصول السريع لأنماط النصوص من Theme
extension AppThemeTextStylesExt on ThemeData {
  /// الأنماط الدلالية (Semantic Styles)
  AppTextStyles textStyles(BuildContext context) => AppTextStyles(context);
}
