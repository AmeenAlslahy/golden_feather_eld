import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
export 'app_text_styles.dart';
export 'app_color_tokens.dart';
/// ثيم تطبيق ELD
class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryBlue,
        onPrimary: AppColors.surface,
        secondary: AppColors.successGreen,
        onSecondary: AppColors.surface,
        error: AppColors.dangerRed,
        onError: AppColors.surface,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.background,
      textTheme: AppTypography.lightTextTheme,

      // ========== شريط العنوان ==========
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.lightTextTheme.headlineSmall?.copyWith(
          color: AppColors.surface,
        ),
        iconTheme: IconThemeData(color: AppColors.surface),
      ),

      // ========== البطاقات ==========
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0.5,
        shadowColor: Colors.black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),

      // ========== الأزرار ==========
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.successGreen,
          foregroundColor: AppColors.surface,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: AppTypography.lightTextTheme.titleLarge,
        ),
      ),

      // ========== حقول الإدخال ==========
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: const BorderSide(color: AppColors.dangerRed, width: 2),
        ),
        hintStyle: AppTypography.lightTextTheme.bodyLarge?.copyWith(
          color: AppColors.textSecondary,
        ),
      ),

      // ========== القوائم ==========
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: AppSpacing.dividerHeight,
        space: 0,
      ),

      // ========== شريط التنقل السفلي ==========
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBarBackground,
        selectedItemColor: AppColors.navBarActive,
        unselectedItemColor: AppColors.navBarInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 1,
      ),

      // ========== أزرار الاختيار ==========
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryBlue;
          }
          return const Color(0xFFC7C7CC);
        }),
      ),
    );

  static final ThemeData dark = light.copyWith(
    brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryBlue,
        onPrimary: AppColors.surface,
        secondary: AppColors.successGreen,
        onSecondary: AppColors.surface,
        error: AppColors.dangerRed,
        onError: AppColors.surface,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: AppTypography.darkTextTheme,
      cardTheme: light.cardTheme.copyWith(
        color: AppColors.darkSurface,
      ),
      inputDecorationTheme: light.inputDecorationTheme.copyWith(
        fillColor: AppColors.darkSurface,
      ),
      dividerTheme: light.dividerTheme.copyWith(
        color: const Color(0xFF48484A),
      ),
    );
}


