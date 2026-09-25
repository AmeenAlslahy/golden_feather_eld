import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_styles.dart';
import 'app_typography.dart';
import 'eld_colors.dart';
import 'press_feedback.dart';

export 'app_styles.dart';
export 'eld_colors.dart';

/// ثيم تطبيق ELD
class AppTheme {
  AppTheme._();

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    extensions: [EldColors.light(), AppStyles.light()],
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryGold,
      onPrimary: AppColors.surface,
      secondary: AppColors.successGreen,
      onSecondary: AppColors.surface,
      error: AppColors.dangerRed,
      onError: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: PressFeedback.splashFactory,
    splashColor: PressFeedback.ink,
    highlightColor: Colors.black.withValues(alpha: 0.06),
    textTheme: AppTypography.lightTextTheme,

    // ========== شريط العنوان ==========
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.secondary,
      foregroundColor: AppColors.primaryGold,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: AppStyles.light().appBarTitle.copyWith(color: AppColors.primaryGold),
      iconTheme: const IconThemeData(color: AppColors.primaryGold),
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
        splashFactory: PressFeedback.splashFactory,
        animationDuration: const Duration(milliseconds: 90),
      ).copyWith(
        overlayColor: PressFeedback.overlay(),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        splashFactory: PressFeedback.splashFactory,
        animationDuration: const Duration(milliseconds: 90),
      ).copyWith(
        overlayColor: PressFeedback.overlay(onDark: true),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        splashFactory: PressFeedback.splashFactory,
      ).copyWith(
        overlayColor: PressFeedback.overlay(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        splashFactory: PressFeedback.splashFactory,
      ).copyWith(
        overlayColor: PressFeedback.overlay(),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        splashFactory: PressFeedback.splashFactory,
      ).copyWith(
        overlayColor: PressFeedback.overlay(),
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
        borderSide: const BorderSide(color: AppColors.primaryGold, width: 2),
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
          return AppColors.primaryGold;
        }
        return const Color(0xFFC7C7CC);
      }),
    ),
  );

  static final ThemeData dark = light.copyWith(
    brightness: Brightness.dark,
    extensions: [EldColors.dark(), AppStyles.dark()],
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryGold,
      onPrimary: AppColors.black,
      secondary: AppColors.successGreen, // Fix dark mode button background
      onSecondary: AppColors.black,
      error: AppColors.dangerOnDark,
      onError: AppColors.black,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.darkTextPrimary,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    textTheme: AppTypography.darkTextTheme,
    cardTheme: light.cardTheme.copyWith(
      color: AppColors.surfaceDark,
    ),
    inputDecorationTheme: light.inputDecorationTheme.copyWith(
      fillColor: AppColors.surfaceDark,
    ),
    dividerTheme: light.dividerTheme.copyWith(
      color: const Color(0xFF48484A),
    ),
  );
}
