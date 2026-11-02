import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/design_system.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:signature/signature.dart';

void main() {
  group('Phase 7B.1 — Token Ownership & Centralized Theme Consolidation', () {
    // =========================================================================
    // 1. Light and Dark Semantic Colors in GoldenColors
    // =========================================================================
    test('1. GoldenColors.light owns all semantic roles correctly', () {
      const colors = GoldenColors.light;

      expect(colors.screenSurface, AppColors.lightSurface);
      expect(colors.background, AppColors.lightBackground);
      expect(colors.textPrimary, AppColors.lightTextPrimary);
      expect(colors.textSecondary, AppColors.lightTextSecondary);
      expect(colors.surfaceSecondary, AppColors.lightSurfaceSecondary);
      expect(colors.surfaceElevated, AppColors.lightSurfaceElevated);
      expect(colors.textMuted, AppColors.lightTextMuted);
      expect(colors.border, AppColors.lightBorder);
      expect(colors.borderStrong, AppColors.lightBorderStrong);
      expect(colors.primaryText, AppColors.lightPrimaryText);
      expect(colors.gold, AppColors.goldDeep);
      expect(colors.goldContainer, AppColors.goldBg);
      expect(colors.successText, AppColors.successText);
      expect(colors.successBackground, AppColors.successBg);
      expect(colors.errorText, AppColors.dangerText);
      expect(colors.errorBackground, AppColors.dangerBg);
      expect(colors.warningText, AppColors.warningText);
      expect(colors.warningBackground, AppColors.warningBg);
      expect(colors.infoText, AppColors.infoText);
      expect(colors.infoBackground, AppColors.infoBg);
      expect(colors.disabledForeground, AppColors.lightTextMuted);
      expect(colors.disabledSurface, AppColors.lightSurfaceSecondary);
      expect(colors.selectedContainer, AppColors.lightPrimaryContainer);
      expect(colors.focusRing, AppColors.brandGold);
      expect(colors.pressedOverlay, const Color(0x1F000000));
      expect(colors.hoverOverlay, const Color(0x0A000000));
    });

    test('2. GoldenColors.dark owns all semantic roles correctly and contrasts with light', () {
      const colors = GoldenColors.dark;

      expect(colors.screenSurface, AppColors.darkSurface);
      expect(colors.background, AppColors.darkBackground);
      expect(colors.textPrimary, AppColors.darkTextPrimary);
      expect(colors.textSecondary, AppColors.darkTextSecondary);
      expect(colors.surfaceSecondary, AppColors.darkSurfaceSecondary);
      expect(colors.surfaceElevated, AppColors.darkSurfaceElevated);
      expect(colors.textMuted, AppColors.darkTextMuted);
      expect(colors.border, AppColors.darkBorder);
      expect(colors.borderStrong, AppColors.darkBorderStrong);
      expect(colors.primaryText, AppColors.darkPrimaryText);
      expect(colors.gold, AppColors.primaryGold);
      expect(colors.goldContainer, AppColors.darkGoldBg);
      expect(colors.successText, AppColors.successOnDark);
      expect(colors.successBackground, AppColors.darkSuccessBg);
      expect(colors.errorText, AppColors.dangerOnDark);
      expect(colors.errorBackground, AppColors.darkDangerBg);
      expect(colors.warningText, AppColors.warningOnDark);
      expect(colors.warningBackground, AppColors.darkWarningBg);
      expect(colors.infoText, AppColors.infoOnDark);
      expect(colors.infoBackground, AppColors.darkInfoBg);
      expect(colors.disabledForeground, AppColors.darkTextMuted);
      expect(colors.disabledSurface, AppColors.darkSurfaceSecondary);
      expect(colors.selectedContainer, AppColors.darkPrimaryContainer);
      expect(colors.focusRing, AppColors.brandGoldLight);
      expect(colors.pressedOverlay, const Color(0x1FFFFFFF));
      expect(colors.hoverOverlay, const Color(0x0AFFFFFF));

      // Contrasting checks between light and dark
      const light = GoldenColors.light;
      expect(colors.screenSurface, isNot(light.screenSurface));
      expect(colors.background, isNot(light.background));
      expect(colors.textPrimary, isNot(light.textPrimary));
      expect(colors.textSecondary, isNot(light.textSecondary));
      expect(colors.disabledSurface, isNot(light.disabledSurface));
      expect(colors.selectedContainer, isNot(light.selectedContainer));
      expect(colors.focusRing, isNot(light.focusRing));
    });

    // =========================================================================
    // 2. GoldenColors.copyWith & lerp
    // =========================================================================
    test('3. GoldenColors.copyWith updates targeted fields without side-effects', () {
      const base = GoldenColors.light;
      final modified = base.copyWith(
        screenSurface: const Color(0xFF112233),
        focusRing: const Color(0xFF445566),
        disabledForeground: const Color(0xFF778899),
        selectedContainer: const Color(0xFFAABBCC),
      );

      expect(modified.screenSurface, const Color(0xFF112233));
      expect(modified.focusRing, const Color(0xFF445566));
      expect(modified.disabledForeground, const Color(0xFF778899));
      expect(modified.selectedContainer, const Color(0xFFAABBCC));

      // Unchanged fields remain equal to base
      expect(modified.background, base.background);
      expect(modified.textPrimary, base.textPrimary);
      expect(modified.border, base.border);
      expect(modified.gold, base.gold);
    });

    test('4. GoldenColors.lerp performs accurate linear interpolation', () {
      const light = GoldenColors.light;
      const dark = GoldenColors.dark;

      final lerp0 = light.lerp(dark, 0.0);
      expect(lerp0.screenSurface, light.screenSurface);
      expect(lerp0.textPrimary, light.textPrimary);
      expect(lerp0.focusRing, light.focusRing);

      final lerp1 = light.lerp(dark, 1.0);
      expect(lerp1.screenSurface, dark.screenSurface);
      expect(lerp1.textPrimary, dark.textPrimary);
      expect(lerp1.focusRing, dark.focusRing);

      final lerp50 = light.lerp(dark, 0.5);
      expect(lerp50.screenSurface, Color.lerp(light.screenSurface, dark.screenSurface, 0.5));
      expect(lerp50.disabledSurface, Color.lerp(light.disabledSurface, dark.disabledSurface, 0.5));
      expect(lerp50.selectedContainer, Color.lerp(light.selectedContainer, dark.selectedContainer, 0.5));

      // Non-GoldenColors fallback
      expect(light.lerp(null, 0.5), light);
    });

    // =========================================================================
    // 3. Central Input-Height Ownership & Spacing Alias
    // =========================================================================
    test('5. AppSizing.inputHeight is 52.0 and AppSpacing.inputHeight aliases to it', () {
      expect(AppSizing.inputHeight, 52.0);
      // Deprecated alias in AppSpacing must match authoritative AppSizing token
      // ignore: deprecated_member_use_from_same_package
      expect(AppSpacing.inputHeight, AppSizing.inputHeight);
      expect(AppSpacing.inputHeight, 52.0);
    });

    test('6. AppTheme inputDecorationTheme enforces AppSizing.inputHeight standard', () {
      final lightInputTheme = AppTheme.light.inputDecorationTheme;
      final darkInputTheme = AppTheme.dark.inputDecorationTheme;

      expect(lightInputTheme.constraints?.minHeight, AppSizing.inputHeight);
      expect(darkInputTheme.constraints?.minHeight, AppSizing.inputHeight);
    });

    // =========================================================================
    // 4. AppSemanticColors Context Extensions Delegation
    // =========================================================================
    testWidgets('7. AppSemanticColors delegates directly to GoldenColors in Light theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) {
              final golden = context.goldenColors;

              expect(context.textPrimary, golden.textPrimary);
              expect(context.textSecondary, golden.textSecondary);
              expect(context.textMuted, golden.textMuted);
              expect(context.border, golden.border);
              expect(context.borderStrong, golden.borderStrong);
              expect(context.screenSurface, golden.screenSurface);
              expect(context.background, golden.background);
              expect(context.surfaceSecondary, golden.surfaceSecondary);
              expect(context.surfaceElevated, golden.surfaceElevated);
              expect(context.primaryText, golden.primaryText);
              expect(context.gold, golden.gold);
              expect(context.success, golden.successText);
              expect(context.danger, golden.errorText);
              expect(context.warning, golden.warningText);
              expect(context.info, golden.infoText);
              expect(context.successContainer, golden.successBackground);
              expect(context.dangerContainer, golden.errorBackground);
              expect(context.warningContainer, golden.warningBackground);
              expect(context.infoContainer, golden.infoBackground);
              expect(context.goldContainer, golden.goldContainer);
              expect(context.disabledForeground, golden.disabledForeground);
              expect(context.disabledSurface, golden.disabledSurface);
              expect(context.selectedContainer, golden.selectedContainer);
              expect(context.focusRing, golden.focusRing);
              expect(context.pressedOverlay, golden.pressedOverlay);
              expect(context.hoverOverlay, golden.hoverOverlay);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('8. AppSemanticColors delegates directly to GoldenColors in Dark theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.dark,
          home: Builder(
            builder: (context) {
              final golden = context.goldenColors;

              expect(context.textPrimary, golden.textPrimary);
              expect(context.textSecondary, golden.textSecondary);
              expect(context.textMuted, golden.textMuted);
              expect(context.border, golden.border);
              expect(context.borderStrong, golden.borderStrong);
              expect(context.screenSurface, golden.screenSurface);
              expect(context.background, golden.background);
              expect(context.surfaceSecondary, golden.surfaceSecondary);
              expect(context.surfaceElevated, golden.surfaceElevated);
              expect(context.primaryText, golden.primaryText);
              expect(context.gold, golden.gold);
              expect(context.success, golden.successText);
              expect(context.danger, golden.errorText);
              expect(context.warning, golden.warningText);
              expect(context.info, golden.infoText);
              expect(context.successContainer, golden.successBackground);
              expect(context.dangerContainer, golden.errorBackground);
              expect(context.warningContainer, golden.warningBackground);
              expect(context.infoContainer, golden.infoBackground);
              expect(context.goldContainer, golden.goldContainer);
              expect(context.disabledForeground, golden.disabledForeground);
              expect(context.disabledSurface, golden.disabledSurface);
              expect(context.selectedContainer, golden.selectedContainer);
              expect(context.focusRing, golden.focusRing);
              expect(context.pressedOverlay, golden.pressedOverlay);
              expect(context.hoverOverlay, golden.hoverOverlay);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    // =========================================================================
    // 5. AppTextField Multiline Expansion & Text Scaling Integrity
    // =========================================================================
    testWidgets('9. AppTextField multiline expands properly without height clipping', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  AppTextField(label: 'Single-line Field', maxLines: 1),
                  AppTextField(label: 'Multi-line Field', maxLines: 4),
                ],
              ),
            ),
          ),
        ),
      );

      final singleFinder = find.byType(AppTextField).first;
      final multiFinder = find.byType(AppTextField).last;

      final singleSize = tester.getSize(singleFinder);
      final multiSize = tester.getSize(multiFinder);

      expect(singleSize.height, greaterThanOrEqualTo(AppSizing.inputHeight));
      expect(multiSize.height, greaterThan(singleSize.height));
      expect(tester.takeException(), isNull);
    });

    testWidgets('10. AppTextField scales gracefully at 1.5x and 2.0x text scaling without clipping or overflow', (tester) async {
      for (final scale in [1.5, 2.0]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.dark,
            home: MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(scale)),
              child: const Scaffold(
                body: SingleChildScrollView(
                  child: Column(
                    children: [
                      AppTextField(
                        label: 'Large Scaled Input',
                        hint: 'Type remarks here',
                        errorText: 'Verification notice message for driver',
                        prefixIcon: Icon(Icons.person),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Large Scaled Input *'), findsNothing);
        expect(find.text('Large Scaled Input'), findsOneWidget);
        expect(find.text('Verification notice message for driver'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });

    // =========================================================================
    // 6. Existing Shared Widgets Compatibility
    // =========================================================================
    testWidgets('11. Existing core shared widgets render cleanly in both Light and Dark', (tester) async {
      final sigController = SignatureController(
        penStrokeWidth: 2,
        penColor: Colors.black,
      );
      addTearDown(sigController.dispose);

      for (final theme in [AppTheme.light, AppTheme.dark]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: theme,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              appBar: const GoldenAppBar(titleText: 'Shared Component Verification'),
              body: SingleChildScrollView(
                child: Column(
                  children: [
                    AppButton(
                      label: 'Primary Action',
                      onPressed: () {},
                    ),
                    const AppTextField(
                      label: 'Test Input',
                      hint: 'Enter value',
                    ),
                    const EldCard(
                      child: Text('Card Content'),
                    ),
                    const AppStatusBadge(
                      label: 'Active',
                      type: AppStatusBadgeType.success,
                    ),
                    const AppStatusPill.success(
                      label: 'Connected',
                    ),
                    const AppDialog(
                      title: 'Dialog Test',
                      contentText: 'Testing shared dialog',
                    ),
                    AppSignatureCanvas(
                      controller: sigController,
                    ),
                    EldRetryView(
                      message: 'Connection issue occurred',
                      onRetry: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Shared Component Verification'), findsOneWidget);
        expect(find.text('Primary Action'), findsOneWidget);
        expect(find.text('Test Input'), findsOneWidget);
        expect(find.text('Card Content'), findsOneWidget);
        expect(find.text('Active'), findsOneWidget);
        expect(find.text('Connected'), findsOneWidget);
        expect(find.text('Dialog Test'), findsOneWidget);
        expect(find.text('Connection issue occurred'), findsOneWidget);
        expect(find.byType(AppSignatureCanvas), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    });
  });
}
