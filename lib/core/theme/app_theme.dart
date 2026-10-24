import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_styles.dart';
import 'press_feedback.dart';
export 'app_styles.dart';

/// ثيم تطبيق ELD
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

  static final ThemeData light = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    extensions: [AppStyles.fromBrightness(Brightness.light)],
    colorScheme: const ColorScheme.light(
      primary: AppColors.primaryGold,
      onPrimary: AppColors.onGold,
      // الهوية: ذهبي رئيسي / أسود ثانوي. الأخضر/الأحمر ألوان حالة فقط.
      secondary: AppColors.secondary,
      onSecondary: AppColors.primaryGold,
      error: AppColors.dangerRed,
      onError: AppColors.surface,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
    ),
    // خلفية واحدة لكل الصفحات؛ البطاقات والحاويات بيضاء فوقها بحدّ `border`.
    // لا تضع `backgroundColor` على Scaffold في الشاشات.
    scaffoldBackgroundColor: AppColors.background,
    splashFactory: PressFeedback.splashFactory,
    splashColor: PressFeedback.ink,
    highlightColor: Colors.black.withValues(alpha: 0.06),
    textTheme: AppTypography.lightTextTheme,
    iconTheme: const IconThemeData(color: AppColors.textPrimary),

    // ========== شريط العنوان ==========
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.primaryGold,
      foregroundColor: AppColors.onGold,
      elevation: 0,
      centerTitle: true,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      ),
      titleTextStyle: AppStyles.fromBrightness(Brightness.light).appBarTitle,
      iconTheme: const IconThemeData(color: AppColors.onGold),
      actionsIconTheme: const IconThemeData(color: AppColors.onGold),
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

    // ========== الحوارات ==========
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.dialog),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      titleTextStyle: AppTypography.lightTextTheme.titleLarge?.copyWith(
        fontSize: 20,
      ),
      contentTextStyle: AppTypography.lightTextTheme.bodyLarge,
    ),

    // ========== الأزرار ==========
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
      ).copyWith(overlayColor: PressFeedback.overlay()),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primaryGold,
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
      ).copyWith(overlayColor: PressFeedback.overlay(onDark: true)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.goldDeep,
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.secondaryButtonHeight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        side: const BorderSide(color: AppColors.goldDeep, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: _buttonTextStyle,
        splashFactory: PressFeedback.splashFactory,
      ).copyWith(overlayColor: PressFeedback.overlay()),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.goldDeep,
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.secondaryButtonHeight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.compact),
        textStyle: _buttonTextStyle,
        splashFactory: PressFeedback.splashFactory,
      ).copyWith(overlayColor: PressFeedback.overlay()),
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
        foregroundColor: AppColors.textPrimary,
        splashFactory: PressFeedback.splashFactory,
      ).copyWith(overlayColor: PressFeedback.overlay()),
    ),

    // ========== حقول الإدخال ==========
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      constraints: const BoxConstraints(minHeight: AppSpacing.inputHeight),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
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

    // ========== الرسائل السفلية ==========
    snackBarTheme: SnackBarThemeData(
      backgroundColor: AppColors.secondary,
      contentTextStyle: AppTypography.lightTextTheme.bodyMedium?.copyWith(
        color: AppColors.surface,
      ),
      actionTextColor: AppColors.goldAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
    ),

    // ========== القوائم ==========
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: AppSpacing.dividerHeight,
      space: 0,
    ),
    listTileTheme: const ListTileThemeData(
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.rowHorizontal,
        vertical: AppSpacing.xs,
      ),
      minVerticalPadding: AppSpacing.sm,
      minLeadingWidth: AppSpacing.iconSize,
      horizontalTitleGap: AppSpacing.compact,
      iconColor: AppColors.textSecondary,
    ),

    // ========== شريط التنقل السفلي ==========
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: AppColors.navBarBackground,
      selectedItemColor: AppColors.navBarActive,
      unselectedItemColor: AppColors.navBarInactive,
      type: BottomNavigationBarType.fixed,
      elevation: 1,
    ),

    // ========== شريط التبويبات ==========
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

    // ========== مفاتيح التبديل ==========
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryGold;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.goldLight;
        }
        return null;
      }),
    ),

    // ========== مربعات الاختيار ==========
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
    extensions: [AppStyles.fromBrightness(Brightness.dark)],
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primaryGold,
      onPrimary: AppColors.black,
      secondary: AppColors.darkTextPrimary,
      onSecondary: AppColors.primaryGold,
      error: AppColors.dangerOnDark,
      onError: AppColors.surfaceDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.darkTextPrimary,
      onSurfaceVariant: AppColors.darkTextSecondary,
    ),
    scaffoldBackgroundColor: AppColors.darkBackground,
    textTheme: AppTypography.darkTextTheme,
    iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
    appBarTheme: light.appBarTheme.copyWith(
      titleTextStyle: AppStyles.fromBrightness(Brightness.dark).appBarTitle,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: AppColors.darkTextPrimary,
        splashFactory: PressFeedback.splashFactory,
      ).copyWith(overlayColor: PressFeedback.overlay(onDark: true)),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primaryGold,
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.secondaryButtonHeight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        side: const BorderSide(color: AppColors.primaryGold, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.button),
        ),
        textStyle: _buttonTextStyle,
        splashFactory: PressFeedback.splashFactory,
      ).copyWith(overlayColor: PressFeedback.overlay(onDark: true)),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primaryGold,
        minimumSize: const Size(
          AppSpacing.minTouchTarget,
          AppSpacing.secondaryButtonHeight,
        ),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.compact),
        textStyle: _buttonTextStyle,
        splashFactory: PressFeedback.splashFactory,
      ).copyWith(overlayColor: PressFeedback.overlay(onDark: true)),
    ),
    cardTheme: light.cardTheme.copyWith(color: AppColors.surfaceDark),
    dialogTheme: light.dialogTheme.copyWith(
      backgroundColor: AppColors.surfaceDark,
      titleTextStyle: AppTypography.darkTextTheme.titleLarge?.copyWith(
        fontSize: 20,
      ),
      contentTextStyle: AppTypography.darkTextTheme.bodyLarge,
    ),
    listTileTheme: light.listTileTheme.copyWith(
      iconColor: AppColors.darkTextSecondary,
    ),
    inputDecorationTheme: light.inputDecorationTheme.copyWith(
      fillColor: AppColors.surfaceDark,
      hintStyle: light.inputDecorationTheme.hintStyle?.copyWith(
        color: AppColors.darkTextSecondary,
      ),
    ),
    bottomNavigationBarTheme: light.bottomNavigationBarTheme.copyWith(
      backgroundColor: AppColors.surfaceDark,
      selectedItemColor: AppColors.primaryGold,
      unselectedItemColor: AppColors.darkTextSecondary,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.primaryGold;
        }
        return null;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return AppColors.darkGoldBg;
        }
        return null;
      }),
    ),
    dividerTheme: light.dividerTheme.copyWith(color: const Color(0xFF48484A)),
    // بدونهما يرث الداكن قيم الفاتح (رمادي داكن على أسود) فتبدو
    // النصوص والأدوات المعتمدة عليهما باهتة — بلاغ الوضع الغامق.
    hintColor: AppColors.darkTextSecondary,
    disabledColor: const Color(0xFF8E8E93),
  );
}
