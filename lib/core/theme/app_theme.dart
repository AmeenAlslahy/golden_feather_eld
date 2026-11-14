import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_sizing.dart';
import 'app_styles.dart';
import 'golden_colors.dart';
import 'press_feedback.dart';

export 'app_animations.dart';
export 'app_styles.dart';
export 'golden_colors.dart';

/// ثيم تطبيق ELD — Golden Feather Design System 2.0
class AppTheme {
  AppTheme._();

  static const TextStyle _buttonTextStyle = TextStyle(
    fontSize: AppTypography.bodySize,
    fontWeight: AppTypography.semiBold,
    letterSpacing: 0.2,
    height: 1.25,
  );

  static const TextStyle _segmentedTextStyle = TextStyle(
    fontSize: AppTypography.subtitleSize,
    fontWeight: AppTypography.semiBold,
    height: 1.43,
  );

  /// إعدادات System UI المستجيبة للوضع الفعلي
  static SystemUiOverlayStyle systemUiOverlayStyleFor(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    return SystemUiOverlayStyle(
      statusBarColor: AppColors.transparent,
      statusBarIconBrightness: isLight ? Brightness.dark : Brightness.light,
      statusBarBrightness: isLight ? Brightness.light : Brightness.dark,
      systemNavigationBarColor:
          isLight ? AppColors.surface : AppColors.surfaceDark,
      systemNavigationBarIconBrightness:
          isLight ? Brightness.dark : Brightness.light,
    );
  }

  /// البناء المشترك لثيم التطبيق مع تحديد القيم الدلالية صراحة لكل وضع
  static ThemeData _buildTheme({required Brightness brightness}) {
    final isLight = brightness == Brightness.light;

    final colorScheme = isLight
        ? const ColorScheme.light(
            primary: AppColors.primaryGold,
            onPrimary: AppColors.onGold,
            primaryContainer: AppColors.lightPrimaryContainer,
            onPrimaryContainer: AppColors.lightOnPrimaryContainer,
            secondary: AppColors.secondary,
            onSecondary: AppColors.primaryGold,
            error: AppColors.dangerRed,
            onError: AppColors.surface,
            surface: AppColors.surface,
            onSurface: AppColors.textPrimary,
            surfaceContainerLow: AppColors.surface,
            surfaceContainer: AppColors.surface,
            surfaceContainerHigh: AppColors.surface,
            surfaceContainerHighest: AppColors.surface,
            outline: AppColors.textPrimary,
            outlineVariant: AppColors.textPrimary,
          )
        : const ColorScheme.dark(
            primary: AppColors.darkPrimary,
            onPrimary: AppColors.black,
            primaryContainer: AppColors.darkPrimaryContainer,
            onPrimaryContainer: AppColors.darkOnPrimaryContainer,
            secondary: AppColors.darkTextPrimary,
            onSecondary: AppColors.primaryGold,
            error: AppColors.dangerOnDark,
            onError: AppColors.surfaceDark,
            surface: AppColors.surfaceDark,
            onSurface: AppColors.darkTextPrimary,
            onSurfaceVariant: AppColors.darkTextSecondary,
            surfaceContainerLow: AppColors.surfaceDark,
            surfaceContainer: AppColors.surfaceDark,
            surfaceContainerHigh: AppColors.surfaceDark,
            surfaceContainerHighest: AppColors.surfaceDark,
            outline: AppColors.darkBorder,
            outlineVariant: AppColors.darkBorder,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      fontFamily: AppTypography.fontFamily,
      colorScheme: colorScheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.lightBackground : AppColors.darkBackground,
      splashFactory: PressFeedback.splashFactory,
      splashColor: PressFeedback.ink,
      highlightColor: AppColors.inkOverlay.withValues(alpha: 0.06),
      textTheme: isLight
          ? AppTypography.lightTextTheme
          : AppTypography.darkTextTheme,
      iconTheme: IconThemeData(
        color: isLight ? AppColors.textPrimary : AppColors.darkTextPrimary,
      ),
      hintColor: isLight
          ? AppColors.textSecondary
          : AppColors.darkTextSecondary,
      disabledColor: AppColors.navBarInactive,
      extensions: [
        AppStyles.fromBrightness(brightness),
        GoldenColors.fromBrightness(brightness),
      ],

      // ========== شريط العنوان (AppBar) ==========
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryGold,
        foregroundColor: AppColors.onGold,
        elevation: 0,
        centerTitle: true,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
        ),
        titleTextStyle: AppStyles.fromBrightness(brightness).appBarTitle,
        iconTheme: const IconThemeData(color: AppColors.onGold),
        actionsIconTheme: const IconThemeData(color: AppColors.onGold),
      ),

      // ========== البطاقات (Cards) ==========
      cardTheme: CardThemeData(
        color: isLight ? AppColors.surface : AppColors.surfaceDark,
        elevation: isLight ? 0.5 : 0.0,
        shadowColor: isLight
            ? AppColors.inkOverlay.withValues(alpha: 0.05)
            : AppColors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        margin: EdgeInsets.zero,
      ),

      // ========== الحوارات (Dialogs) ==========
      dialogTheme: DialogThemeData(
        backgroundColor: isLight ? AppColors.surface : AppColors.surfaceDark,
        surfaceTintColor: AppColors.transparent,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.dialog),
        ),
        insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        titleTextStyle: (isLight
                ? AppTypography.lightTextTheme.titleLarge
                : AppTypography.darkTextTheme.titleLarge)
            ?.copyWith(fontSize: 20),
        contentTextStyle: isLight
            ? AppTypography.lightTextTheme.bodyLarge
            : AppTypography.darkTextTheme.bodyLarge,
      ),

      // ========== الأزرار (Buttons) ==========
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryGold,
          foregroundColor: AppColors.onGold,
          minimumSize: const Size(double.infinity, AppSpacing.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: _buttonTextStyle,
          splashFactory: PressFeedback.splashFactory,
          animationDuration: const Duration(milliseconds: 90),
        ).copyWith(overlayColor: PressFeedback.overlay(onDark: !isLight)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor:
              isLight ? AppColors.primaryGold : AppColors.darkPrimary,
          foregroundColor: AppColors.onGold,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.secondaryButtonHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: _buttonTextStyle,
          splashFactory: PressFeedback.splashFactory,
          animationDuration: const Duration(milliseconds: 90),
        ).copyWith(overlayColor: PressFeedback.overlay(onDark: !isLight)),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: isLight ? AppColors.goldDeep : AppColors.primaryGold,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.secondaryButtonHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          side: BorderSide(
            color: isLight ? AppColors.goldDeep : AppColors.primaryGold,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          textStyle: _buttonTextStyle,
          splashFactory: PressFeedback.splashFactory,
        ).copyWith(overlayColor: PressFeedback.overlay(onDark: !isLight)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isLight ? AppColors.goldDeep : AppColors.primaryGold,
          minimumSize: const Size(
            AppSpacing.minTouchTarget,
            AppSpacing.secondaryButtonHeight,
          ),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.compact),
          textStyle: _buttonTextStyle,
          splashFactory: PressFeedback.splashFactory,
        ).copyWith(overlayColor: PressFeedback.overlay(onDark: !isLight)),
      ),
      segmentedButtonTheme: const SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: WidgetStatePropertyAll(
            Size(0, AppSpacing.secondaryButtonHeight),
          ),
          textStyle: WidgetStatePropertyAll(_segmentedTextStyle),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor:
              isLight ? AppColors.textPrimary : AppColors.darkTextPrimary,
          splashFactory: PressFeedback.splashFactory,
        ).copyWith(overlayColor: PressFeedback.overlay(onDark: !isLight)),
      ),

      // ========== حقول الإدخال (Inputs) ==========
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isLight ? AppColors.surface : AppColors.surfaceDark,
        constraints: const BoxConstraints(minHeight: AppSizing.inputHeight),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: isLight
                ? AppColors.lightInputBorder
                : AppColors.darkInputBorder,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: isLight
                ? AppColors.lightInputBorder
                : AppColors.darkInputBorder,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: isLight ? AppColors.brandGoldDark : AppColors.darkPrimary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: isLight ? AppColors.dangerRed : AppColors.dangerOnDark,
            width: 2,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: isLight ? AppColors.dangerRed : AppColors.dangerOnDark,
            width: 2.5,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.input),
          borderSide: BorderSide(
            color: isLight
                ? AppColors.lightInputBorder.withValues(alpha: 0.6)
                : AppColors.darkInputBorder.withValues(alpha: 0.6),
          ),
        ),
        hintStyle: (isLight
                ? AppTypography.lightTextTheme.bodyLarge
                : AppTypography.darkTextTheme.bodyLarge)
            ?.copyWith(
          color: isLight
              ? AppColors.textSecondary
              : AppColors.darkTextSecondary,
        ),
      ),

      // ========== الرسائل المنبثقة (SnackBars) ==========
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isLight ? AppColors.secondary : AppColors.surfaceDark,
        contentTextStyle: (isLight
                ? AppTypography.lightTextTheme.bodyMedium
                : AppTypography.darkTextTheme.bodyMedium)
            ?.copyWith(
          color: isLight ? AppColors.surface : AppColors.darkTextPrimary,
        ),
        actionTextColor: AppColors.goldAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
      ),

      // ========== الفواصل والقوائم ==========
      dividerTheme: DividerThemeData(
        color: isLight ? AppColors.border : AppColors.darkDivider,
        thickness: AppSpacing.dividerHeight,
        space: 0,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.rowHorizontal,
          vertical: AppSpacing.xs,
        ),
        minVerticalPadding: AppSpacing.sm,
        minLeadingWidth: AppSpacing.iconSize,
        horizontalTitleGap: AppSpacing.compact,
        iconColor: isLight
            ? AppColors.textSecondary
            : AppColors.darkTextSecondary,
      ),

      // ========== أشرطة التنقل السفلية (Bottom Navigation) ==========
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            isLight ? AppColors.navBarBackground : AppColors.surfaceDark,
        selectedItemColor:
            isLight ? AppColors.navBarActive : AppColors.primaryGold,
        unselectedItemColor:
            isLight ? AppColors.navBarInactive : AppColors.darkTextSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 1,
      ),

      // ========== شريط التنقل الحديث (NavigationBar Material 3) ==========
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isLight ? AppColors.surface : AppColors.surfaceDark,
        indicatorColor: isLight
            ? AppColors.lightPrimaryContainer
            : AppColors.darkPrimaryContainer,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(
              color: isLight ? AppColors.goldDeep : AppColors.darkPrimary,
            );
          }
          return IconThemeData(
            color: isLight
                ? AppColors.navBarInactive
                : AppColors.darkTextSecondary,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              fontSize: AppTypography.captionSize,
              fontWeight: AppTypography.semiBold,
              color: isLight ? AppColors.goldDeep : AppColors.darkPrimary,
            );
          }
          return TextStyle(
            fontSize: AppTypography.captionSize,
            fontWeight: AppTypography.regular,
            color: isLight
                ? AppColors.navBarInactive
                : AppColors.darkTextSecondary,
          );
        }),
      ),

      // ========== شريط التبويبات (TabBar) ==========
      tabBarTheme: TabBarThemeData(
        indicatorColor: AppColors.onGold,
        labelColor: AppColors.onGold,
        unselectedLabelColor: AppColors.onGold.withValues(alpha: 0.7),
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.subtitleSize,
          fontWeight: AppTypography.semiBold,
        ),
        unselectedLabelStyle: const TextStyle(
          fontFamily: AppTypography.fontFamily,
          fontSize: AppTypography.subtitleSize,
          fontWeight: AppTypography.regular,
        ),
      ),

      // ========== مؤشرات التقدم (Progress Indicators) ==========
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: isLight ? AppColors.primaryGold : AppColors.darkPrimary,
        linearTrackColor: isLight
            ? AppColors.lightPrimaryContainer
            : AppColors.darkPrimaryContainer,
        circularTrackColor: isLight
            ? AppColors.lightPrimaryContainer
            : AppColors.darkPrimaryContainer,
      ),

      // ========== مفاتيح التبديل (Switches) ==========
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryGold;
          }
          return null;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isLight ? AppColors.goldLight : AppColors.darkGoldBg;
          }
          return null;
        }),
      ),

      // ========== مربعات الاختيار (Checkboxes) ==========
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryGold;
          }
          return null;
        }),
        checkColor: const WidgetStatePropertyAll(AppColors.onGold),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.small),
        ),
      ),

      // ========== أزرار الاختيار (Radio Buttons) ==========
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primaryGold;
          }
          return AppColors.radioInactive;
        }),
      ),
    );
  }

  /// ثيم الوضع الفاتح (Light Theme)
  static final ThemeData light = _buildTheme(brightness: Brightness.light);

  /// ثيم الوضع الداكن (Dark Theme)
  static final ThemeData dark = _buildTheme(brightness: Brightness.dark);
}
