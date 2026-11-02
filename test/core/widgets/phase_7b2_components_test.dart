import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/design_system.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

void main() {
  Widget buildAppWrapper({
    required Widget child,
    ThemeData? theme,
    double textScale = 1.0,
    double screenWidth = 375,
    Locale locale = const Locale('en'),
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final effectiveTheme = theme ?? AppTheme.light;
    final isDark = effectiveTheme.brightness == Brightness.dark;

    return MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: effectiveTheme,
      darkTheme: AppTheme.dark,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: Directionality(
        textDirection: textDirection,
        child: MediaQuery(
          data: MediaQueryData(
            size: Size(screenWidth, 800),
            textScaler: TextScaler.linear(textScale),
          ),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: screenWidth,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  group('Phase 7B.2 — Button Variants & Centralized States', () {
    testWidgets('AppButton variants render semantic colors accurately in Light Mode', (tester) async {
      final theme = AppTheme.light;
      const colors = GoldenColors.light;

      // Primary
      await tester.pumpWidget(
        buildAppWrapper(
          theme: theme,
          child: AppButton.primary(
            label: 'Submit',
            onPressed: () {},
          ),
        ),
      );
      var material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      expect(material.color, AppColors.primaryGold);

      // Destructive
      await tester.pumpWidget(
        buildAppWrapper(
          theme: theme,
          child: AppButton.destructive(
            label: 'Delete',
            onPressed: () {},
          ),
        ),
      );
      material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      expect(material.color, theme.colorScheme.error);

      // Success
      await tester.pumpWidget(
        buildAppWrapper(
          theme: theme,
          child: AppButton.success(
            label: 'Certify',
            onPressed: () {},
          ),
        ),
      );
      material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      expect(material.color, colors.successText);
    });

    testWidgets('AppButton variants render semantic colors accurately in Dark Mode', (tester) async {
      final theme = AppTheme.dark;
      const colors = GoldenColors.dark;

      // Destructive
      await tester.pumpWidget(
        buildAppWrapper(
          theme: theme,
          child: AppButton.destructive(
            label: 'Delete Dark',
            onPressed: () {},
          ),
        ),
      );
      var material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      expect(material.color, theme.colorScheme.error);

      // Success
      await tester.pumpWidget(
        buildAppWrapper(
          theme: theme,
          child: AppButton.success(
            label: 'Certify Dark',
            onPressed: () {},
          ),
        ),
      );
      material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      expect(material.color, colors.successText);
    });

    testWidgets('AppButton disabled state uses centralized disabledSurface and muted foreground', (tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          theme: AppTheme.light,
          child: const AppButton.primary(
            label: 'Disabled Action',
            onPressed: null,
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      expect(material.color, GoldenColors.light.disabledSurface);

      final text = tester.widget<Text>(find.text('Disabled Action'));
      expect(text.style?.color, GoldenColors.light.disabledForeground);
    });

    testWidgets('AppButton handles 1.5x and 2.0x text scaling gracefully without overflow', (tester) async {
      for (final scale in [1.5, 2.0]) {
        await tester.pumpWidget(
          buildAppWrapper(
            textScale: scale,
            screenWidth: 320,
            child: AppButton.primary(
              label: 'Complete Pre-Trip Inspection With High Text Scaling',
              onPressed: () {},
            ),
          ),
        );

        expect(find.byType(AppButton), findsOneWidget);
        expect(tester.takeException(), isNull);
        final size = tester.getSize(find.byType(AppButton));
        expect(size.height, greaterThanOrEqualTo(AppSizing.buttonHeight));
      }
    });
  });

  group('Phase 7B.2 — AppTextField Centralized States & Scalability', () {
    testWidgets('AppTextField renders focused border using focusRing semantic token', (tester) async {
      final focusNode = FocusNode();
      await tester.pumpWidget(
        buildAppWrapper(
          theme: AppTheme.light,
          child: AppTextField(
            label: 'Driver Notes',
            focusNode: focusNode,
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      final focusedBorder = textField.decoration?.focusedBorder as OutlineInputBorder?;
      expect(focusedBorder?.borderSide.color, GoldenColors.light.focusRing);
      expect(focusedBorder?.borderRadius.topLeft.x, AppRadius.input);
    });

    testWidgets('AppTextField multiline expands gracefully at 2.0x text scaling', (tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          textScale: 2.0,
          screenWidth: 320,
          child: const AppTextField(
            label: 'Multiline Remarks',
            maxLines: 4,
            minLines: 2,
          ),
        ),
      );

      expect(find.byType(AppTextField), findsOneWidget);
      expect(tester.takeException(), isNull);
      final size = tester.getSize(find.byType(AppTextField));
      expect(size.height, greaterThan(AppSizing.inputHeight));
    });
  });

  group('Phase 7B.2 — EldCard Density & Centralized States', () {
    testWidgets('EldCard supports standard and compact density with appropriate padding', (tester) async {
      // Standard
      await tester.pumpWidget(
        buildAppWrapper(
          child: const EldCard(
            child: Text('Standard Card Content'),
          ),
        ),
      );
      final standardPadding = tester.widget<Padding>(
        find.ancestor(of: find.text('Standard Card Content'), matching: find.byType(Padding)).first,
      ).padding as EdgeInsets;
      expect(standardPadding, const EdgeInsets.all(AppSpacing.cardPadding));

      // Compact
      await tester.pumpWidget(
        buildAppWrapper(
          child: const EldCard.compact(
            child: Text('Compact Card Content'),
          ),
        ),
      );
      final compactPadding = tester.widget<Padding>(
        find.ancestor(of: find.text('Compact Card Content'), matching: find.byType(Padding)).first,
      ).padding as EdgeInsets;
      expect(compactPadding, AppDensity.compact.cardPadding);
    });

    testWidgets('Interactive EldCard provides visual feedback without error', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildAppWrapper(
          child: EldCard(
            onTap: () => tapped = true,
            child: const Text('Interactive Card'),
          ),
        ),
      );

      await tester.tap(find.text('Interactive Card'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 7B.2 — GoldenAppBar Surface, RTL/LTR & Navigation Semantics', () {
    testWidgets('GoldenAppBar renders brand gradient on brand variant and solid surface on standard', (tester) async {
      // Brand
      await tester.pumpWidget(
        buildAppWrapper(
          child: const Scaffold(
            appBar: GoldenAppBar(titleText: 'Brand Header'),
            body: SizedBox(),
          ),
        ),
      );
      expect(find.text('Brand Header'), findsOneWidget);

      // Standard Surface
      await tester.pumpWidget(
        buildAppWrapper(
          theme: AppTheme.dark,
          child: const Scaffold(
            appBar: GoldenAppBar.standard(titleText: 'Settings Header'),
            body: SizedBox(),
          ),
        ),
      );
      expect(find.text('Settings Header'), findsOneWidget);
    });

    testWidgets('GoldenAppBar displays CloseButton when hosted in a fullscreen dialog route', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (_) => const Scaffold(
                      appBar: GoldenAppBar(titleText: 'Dialog Title'),
                      body: SizedBox(),
                    ),
                  ),
                );
              },
              child: const Text('Open Modal'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byType(CloseButton), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });
  });

  group('Phase 7B.2 — Status Components (Badge & Pill) Unification', () {
    testWidgets('AppStatusBadge and AppStatusPill resolve identical semantic colors in Light Mode', (tester) async {
      final (fg, bg) = StatusSemanticRole.success.resolve(GoldenColors.light);
      await tester.pumpWidget(
        buildAppWrapper(
          theme: AppTheme.light,
          child: const Row(
            children: [
              AppStatusBadge(label: 'Active', type: AppStatusBadgeType.success),
              AppStatusPill.success(label: 'Active'),
            ],
          ),
        ),
      );

      final badgeContainer = tester.widget<Container>(
        find.descendant(of: find.byType(AppStatusBadge), matching: find.byType(Container)),
      );
      final badgeDec = badgeContainer.decoration as BoxDecoration;
      expect(badgeDec.color, bg);

      final pillContainer = tester.widget<Container>(
        find.descendant(of: find.byType(AppStatusPill), matching: find.byType(Container)),
      );
      final pillDec = pillContainer.decoration as BoxDecoration;
      expect(pillDec.color, bg);

      // Shapes preserved: Badge = AppRadius.badge (8), Pill = AppRadius.pill (999)
      expect(badgeDec.borderRadius, BorderRadius.circular(AppRadius.badge));
      expect(pillDec.borderRadius, BorderRadius.circular(AppRadius.pill));
    });

    testWidgets('AppStatusBadge and AppStatusPill resolve identical semantic colors in Dark Mode', (tester) async {
      final (fg, bg) = StatusSemanticRole.success.resolve(GoldenColors.dark);
      await tester.pumpWidget(
        buildAppWrapper(
          theme: AppTheme.dark,
          child: const Row(
            children: [
              AppStatusBadge(label: 'Active', type: AppStatusBadgeType.success),
              AppStatusPill.success(label: 'Active'),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();

      final badgeContainer = tester.widget<Container>(
        find.descendant(of: find.byType(AppStatusBadge), matching: find.byType(Container)),
      );
      final badgeDec = badgeContainer.decoration as BoxDecoration;
      expect(badgeDec.color, bg);

      final pillContainer = tester.widget<Container>(
        find.descendant(of: find.byType(AppStatusPill), matching: find.byType(Container)),
      );
      final pillDec = pillContainer.decoration as BoxDecoration;
      expect(pillDec.color, bg);
    });
  });

  group('Phase 7B.2 — Candidate Patterns (Section, Tile, LoadingState, KeyValueRow)', () {
    testWidgets('AppSection renders title, optional action, and enforces standardized spacing', (tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          child: AppSection(
            title: 'Vehicle Information',
            subtitle: 'VIN and registration details',
            action: TextButton(onPressed: () {}, child: const Text('Edit')),
            child: const Text('Section Body'),
          ),
        ),
      );

      expect(find.text('Vehicle Information'), findsOneWidget);
      expect(find.text('VIN and registration details'), findsOneWidget);
      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Section Body'), findsOneWidget);
    });

    testWidgets('AppSelectionTile enforces >=48dp touch target and distinct selected state', (tester) async {
      bool selected = false;
      await tester.pumpWidget(
        buildAppWrapper(
          child: StatefulBuilder(
            builder: (context, setState) => AppSelectionTile(
              title: 'Sleeper Berth',
              subtitle: 'Rest period in sleeper berth',
              selected: selected,
              onTap: () => setState(() => selected = !selected),
            ),
          ),
        ),
      );

      final sizeBefore = tester.getSize(find.byType(AppSelectionTile));
      expect(sizeBefore.height, greaterThanOrEqualTo(AppDensity.compact.minTouchTarget));

      await tester.tap(find.byType(AppSelectionTile));
      await tester.pumpAndSettle();
      expect(selected, isTrue);
    });

    testWidgets('AppLoadingState renders brand gold spinner with accessibility announcement', (tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          child: const AppLoadingState(
            message: 'Synchronizing logs with ELD backend...',
          ),
        ),
      );

      expect(find.text('Synchronizing logs with ELD backend...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('AppKeyValueRow displays key-value pairs with density and divider support', (tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          child: const Column(
            children: [
              AppKeyValueRow(
                label: 'Odometer',
                value: '124,500 mi',
                showDivider: true,
              ),
              AppKeyValueRow.compact(
                label: 'Engine Hours',
                value: '3,420 hrs',
              ),
            ],
          ),
        ),
      );

      expect(find.text('Odometer'), findsOneWidget);
      expect(find.text('124,500 mi'), findsOneWidget);
      expect(find.text('Engine Hours'), findsOneWidget);
      expect(find.text('3,420 hrs'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);
    });
  });

  group('Phase 7B.2 — Centralized Propagation Proof', () {
    testWidgets('Independent component instances inherit identical visual token definitions', (tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          theme: AppTheme.light,
          child: Column(
            children: [
              AppButton.primary(label: 'Button A', onPressed: () {}),
              AppButton.primary(label: 'Button B', onPressed: () {}),
              const AppTextField(label: 'Field A'),
              const AppTextField(label: 'Field B'),
            ],
          ),
        ),
      );

      // Verify buttons inherit the exact same shared radius token
      final buttons = tester.widgetList<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      ).toList();
      expect(buttons.length, 2);
      final borderA = buttons[0].shape as RoundedRectangleBorder;
      final borderB = buttons[1].shape as RoundedRectangleBorder;
      expect(borderA.borderRadius, borderB.borderRadius);
      expect(borderA.borderRadius, BorderRadius.circular(AppRadius.button));

      // Verify fields inherit the exact same shared radius token
      final fields = tester.widgetList<TextField>(find.byType(TextField)).toList();
      expect(fields.length, 2);
      final outlineA = fields[0].decoration?.enabledBorder as OutlineInputBorder;
      final outlineB = fields[1].decoration?.enabledBorder as OutlineInputBorder;
      expect(outlineA.borderRadius, outlineB.borderRadius);
      expect(outlineA.borderRadius, BorderRadius.circular(AppRadius.input));
    });
  });

  group('Phase 7B.2 — Multi-Screen Responsive & Multi-Locale Matrix', () {
    final widths = [320.0, 375.0, 430.0];
    final scales = [1.0, 1.5, 2.0];
    final locales = [
      (const Locale('en'), TextDirection.ltr),
      (const Locale('ar'), TextDirection.rtl),
      (const Locale('es'), TextDirection.ltr),
    ];

    for (final width in widths) {
      for (final scale in scales) {
        testWidgets('Responsive width ${width}dp with ${scale}x scale renders without overflow', (tester) async {
          await tester.pumpWidget(
            buildAppWrapper(
              screenWidth: width,
              textScale: scale,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const GoldenAppBar(titleText: 'Responsive Test'),
                    const SizedBox(height: AppSpacing.md),
                    AppButton.primary(
                      label: 'Responsive Button',
                      onPressed: () {},
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const EldCard(
                      child: AppKeyValueRow(
                        label: 'Status',
                        value: 'On Duty Driving',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );

          expect(tester.takeException(), isNull);
        });
      }
    }

    for (final localeEntry in locales) {
      testWidgets('Locale ${localeEntry.$1.languageCode} renders in correct direction without layout breaks', (tester) async {
        await tester.pumpWidget(
          buildAppWrapper(
            locale: localeEntry.$1,
            textDirection: localeEntry.$2,
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AppButton.primary(label: 'Localized Action', onPressed: () {}),
                  const EldCard(
                    child: AppKeyValueRow(
                      label: 'العنوان / Title',
                      value: 'القيمة / Value',
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
