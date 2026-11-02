import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/design_system.dart';

void main() {
  group('Golden Feather Design System 2.0 — Theme Architecture', () {
    test('1. بناء Light Theme واكتمال الخصائص الأساسية', () {
      final theme = AppTheme.light;

      expect(theme.brightness, Brightness.light);
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, AppColors.lightBackground);
      expect(theme.colorScheme.primary, AppColors.primaryGold);
      expect(theme.colorScheme.onPrimary, AppColors.lightOnPrimary);
      expect(theme.colorScheme.surface, AppColors.lightSurface);
      expect(theme.colorScheme.onSurface, AppColors.lightTextPrimary);
      expect(theme.colorScheme.outline, AppColors.lightTextPrimary);
      expect(theme.colorScheme.outlineVariant, AppColors.lightTextPrimary);

      // التأكد من شريط العنوان والأيقونات
      expect(theme.appBarTheme.backgroundColor, AppColors.primaryGold);
      expect(theme.appBarTheme.foregroundColor, AppColors.onGold);
      expect(theme.appBarTheme.systemOverlayStyle?.statusBarIconBrightness,
          Brightness.dark);
    });

    test('2. بناء Dark Theme واكتمال الخصائص الأساسية', () {
      final theme = AppTheme.dark;

      expect(theme.brightness, Brightness.dark);
      expect(theme.useMaterial3, isTrue);
      expect(theme.scaffoldBackgroundColor, AppColors.darkBackground);
      expect(theme.colorScheme.primary, AppColors.darkPrimary);
      expect(theme.colorScheme.onPrimary, AppColors.black);
      expect(theme.colorScheme.surface, AppColors.darkSurface);
      expect(theme.colorScheme.onSurface, AppColors.darkTextPrimary);
      expect(theme.colorScheme.outline, AppColors.darkBorder);
      expect(theme.colorScheme.outlineVariant, AppColors.darkBorder);

      // التأكد من فقاعة الرسائل المنفصلة
      expect(theme.snackBarTheme.backgroundColor, AppColors.surfaceDark);
      expect(
          theme.snackBarTheme.backgroundColor, isNot(theme.scaffoldBackgroundColor));
    });

    test('3. توفر GoldenColors في الوضعين واختلاف قيمهما الدلالية', () {
      final lightColors = AppTheme.light.extension<GoldenColors>();
      final darkColors = AppTheme.dark.extension<GoldenColors>();

      expect(lightColors, isNotNull);
      expect(darkColors, isNotNull);

      // قيم الفاتح
      expect(lightColors!.surfaceSecondary, AppColors.lightSurfaceSecondary);
      expect(lightColors.surfaceElevated, AppColors.lightSurfaceElevated);
      expect(lightColors.textMuted, AppColors.lightTextMuted);
      expect(lightColors.border, AppColors.lightBorder);
      expect(lightColors.borderStrong, AppColors.lightBorderStrong);
      expect(lightColors.primaryText, AppColors.lightPrimaryText);

      // قيم الداكن
      expect(darkColors!.surfaceSecondary, AppColors.darkSurfaceSecondary);
      expect(darkColors.surfaceElevated, AppColors.darkSurfaceElevated);
      expect(darkColors.textMuted, AppColors.darkTextMuted);
      expect(darkColors.border, AppColors.darkBorder);
      expect(darkColors.borderStrong, AppColors.darkBorderStrong);
      expect(darkColors.primaryText, AppColors.darkPrimaryText);

      // التمايز الدلالي الصريح بين الوضعين
      expect(lightColors.surfaceSecondary, isNot(darkColors.surfaceSecondary));
      expect(lightColors.border, isNot(darkColors.border));
      expect(lightColors.borderStrong, isNot(darkColors.borderStrong));
      expect(lightColors.textMuted, isNot(darkColors.textMuted));
      expect(lightColors.primaryText, isNot(darkColors.primaryText));
      expect(lightColors.successBackground, isNot(darkColors.successBackground));
      expect(lightColors.errorBackground, isNot(darkColors.errorBackground));
      expect(lightColors.warningBackground, isNot(darkColors.warningBackground));
      expect(lightColors.infoBackground, isNot(darkColors.infoBackground));
    });

    test('4. توفر AppStyles في الوضعين ودعم الأنماط الجديدة', () {
      final lightStyles = AppTheme.light.extension<AppStyles>();
      final darkStyles = AppTheme.dark.extension<AppStyles>();

      expect(lightStyles, isNotNull);
      expect(darkStyles, isNotNull);

      // الأنماط الجديدة في 2.0
      expect(lightStyles!.display.fontSize, AppTypography.display);
      expect(lightStyles.cardTitle.fontSize, AppTypography.cardTitle);
      expect(lightStyles.bodyMedium.fontSize, AppTypography.bodyMedium);
      expect(lightStyles.secondary.fontSize, AppTypography.secondary);
      expect(lightStyles.badge.fontSize, AppTypography.badge);
      expect(lightStyles.timerLarge.fontSize, AppTypography.timerLarge);
      expect(lightStyles.timerMedium.fontSize, AppTypography.timerMedium);

      // الأرقام والمؤقتات تحمل tabularFigures
      expect(lightStyles.number.fontFeatures,
          contains(const FontFeature.tabularFigures()));
      expect(lightStyles.timer.fontFeatures,
          contains(const FontFeature.tabularFigures()));
      expect(lightStyles.timerLarge.fontFeatures,
          contains(const FontFeature.tabularFigures()));
      expect(lightStyles.timerMedium.fontFeatures,
          contains(const FontFeature.tabularFigures()));

      // تباين الألوان بين الفاتح والداكن
      expect(lightStyles.body.color, isNot(darkStyles!.body.color));
      expect(lightStyles.error.color, isNot(darkStyles.error.color));
    });

    test('5. عمل GoldenColors copyWith و lerp', () {
      const base = GoldenColors.light;
      final copied = base.copyWith(border: AppColors.primaryGold);

      expect(copied.border, AppColors.primaryGold);
      expect(copied.surfaceSecondary, base.surfaceSecondary);

      final lerped = base.lerp(GoldenColors.dark, 0.5);
      expect(lerped.border, Color.lerp(base.border, GoldenColors.dark.border, 0.5));
    });

    test('6. AppDensity يدعم النمطين ويحمي مساحة اللمس الدنيا', () {
      expect(AppDensity.compact.isCompact, isTrue);
      expect(AppDensity.comfortable.isComfortable, isTrue);

      // إمكانية الوصول: 48 بكسل على الأقل في كلا النمطين
      expect(AppDensity.compact.minTouchTarget, greaterThanOrEqualTo(48.0));
      expect(AppDensity.comfortable.minTouchTarget, greaterThanOrEqualTo(48.0));

      // كثافة المسافات
      expect(AppDensity.compact.verticalGap, lessThan(AppDensity.comfortable.verticalGap));
      expect(AppDensity.compact.fieldGap, lessThan(AppDensity.comfortable.fieldGap));
    });

    test('7. AppSizing يتضمن القيم القياسية الصحيحة', () {
      expect(AppSizing.buttonHeight, 52.0);
      expect(AppSizing.buttonCompactHeight, 48.0);
      expect(AppSizing.inputHeight, 52.0);
      expect(AppSizing.iconSmall, 16.0);
      expect(AppSizing.iconMedium, 20.0);
      expect(AppSizing.iconStandard, 24.0);
      expect(AppSizing.iconLarge, 28.0);
      expect(AppSizing.drawerItemHeight, 52.0);
      expect(AppSizing.logoLarge, 104.0);
      expect(AppSizing.logoMedium, 88.0);
      expect(AppSizing.logoSmall, 40.0);
      expect(AppSizing.dashboardTimerMax, 240.0);
    });

    test('8. AppSpacing يتضمن الشبكة الأساسية والمسافات الدلالية والتوافقية', () {
      expect(AppSpacing.space0, 0.0);
      expect(AppSpacing.space1, 4.0);
      expect(AppSpacing.space2, 8.0);
      expect(AppSpacing.space3, 12.0);
      expect(AppSpacing.space4, 16.0);
      expect(AppSpacing.space5, 20.0);
      expect(AppSpacing.space6, 24.0);
      expect(AppSpacing.space8, 32.0);
      expect(AppSpacing.space10, 40.0);
      expect(AppSpacing.space12, 48.0);

      expect(AppSpacing.screenHorizontal, 16.0);
      expect(AppSpacing.screenVertical, 16.0);
      expect(AppSpacing.sectionGap, 24.0);
      expect(AppSpacing.cardGap, 12.0);
      expect(AppSpacing.cardPadding, 16.0);
      expect(AppSpacing.fieldGap, 16.0);
      expect(AppSpacing.labelToField, 8.0);
      expect(AppSpacing.titleToContent, 12.0);
      expect(AppSpacing.buttonGroupGap, 12.0);

      // التوافق القديم
      expect(AppSpacing.md, 16.0);
      expect(AppSpacing.buttonHeight, 52.0);
    });

    test('9. AppRadius يتضمن المقياس الجديد والأنماط الدلالية والتوافقية', () {
      expect(AppRadius.scaleSmall, 6.0);
      expect(AppRadius.scaleMedium, 10.0);
      expect(AppRadius.scaleLarge, 14.0);
      expect(AppRadius.scaleXLarge, 20.0);
      expect(AppRadius.scalePill, 999.0);

      expect(AppRadius.large, 14.0);
      expect(AppRadius.xLarge, 20.0);
      expect(AppRadius.bottomSheet, 16.0);

      // التوافق القديم
      expect(AppRadius.card, 12.0);
      expect(AppRadius.button, 12.0);
      expect(AppRadius.input, 10.0);
      expect(AppRadius.dialog, 16.0);
      expect(AppRadius.badge, 8.0);
    });

    test('10. AppShadows يتضمن الظلال المخصصة حسب السطوع', () {
      expect(AppShadows.none, isEmpty);
      expect(AppShadows.subtleLight, isNotEmpty);
      expect(AppShadows.subtleDark, isNotEmpty);
      expect(AppShadows.floatingLight, isNotEmpty);
      expect(AppShadows.dialogLight, isNotEmpty);

      expect(AppShadows.cardFor(Brightness.light), AppShadows.card);
      expect(AppShadows.cardFor(Brightness.dark), AppShadows.none);
    });

    testWidgets('11. امتدادات BuildContext تعمل وتستجيب لتبديل الثيم', (tester) async {
      late GoldenColors capturedColors;
      late ThemeData capturedTheme;
      late Color capturedTextPrimary;

      Widget buildTestApp(ThemeMode mode) {
        return MaterialApp(
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          home: Builder(
            builder: (context) {
              capturedColors = context.goldenColors;
              capturedTheme = context.goldenTheme;
              capturedTextPrimary = context.textPrimary;
              return const Scaffold(body: Text('Theme Test'));
            },
          ),
        );
      }

      // وضع الفاتح
      await tester.pumpWidget(buildTestApp(ThemeMode.light));
      await tester.pumpAndSettle();

      expect(capturedTheme.brightness, Brightness.light);
      expect(capturedColors.primaryText, AppColors.lightPrimaryText);
      expect(capturedTextPrimary, AppColors.lightTextPrimary);

      // تبديل إلى الداكن
      await tester.pumpWidget(buildTestApp(ThemeMode.dark));
      await tester.pumpAndSettle();

      expect(capturedTheme.brightness, Brightness.dark);
      expect(capturedColors.primaryText, AppColors.darkPrimaryText);
      expect(capturedTextPrimary, AppColors.darkTextPrimary);
    });
  });
}
