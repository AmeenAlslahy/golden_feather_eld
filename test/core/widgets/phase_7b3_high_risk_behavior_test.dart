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

  group('Phase 7B.3 — High-Risk Component Behaviors', () {
    // 1. AppButton: repeated taps while loading do not invoke the action more than once
    testWidgets('AppButton: repeated taps while loading do not invoke action', (tester) async {
      int tapCount = 0;
      bool isLoading = false;

      await tester.pumpWidget(
        buildAppWrapper(
          child: StatefulBuilder(
            builder: (context, setState) {
              return AppButton.primary(
                label: 'Submit Action',
                isLoading: isLoading,
                onPressed: () {
                  tapCount++;
                  setState(() => isLoading = true);
                },
              );
            },
          ),
        ),
      );

      // Initial tap triggers callback and toggles isLoading to true
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(tapCount, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Subsequent 5 taps while loading must NOT invoke callback again
      for (int i = 0; i < 5; i++) {
        await tester.tap(find.byType(AppButton));
        await tester.pump(const Duration(milliseconds: 50));
      }

      expect(tapCount, 1);
    });

    testWidgets('AppButton: button initialized as isLoading does not trigger callback on tap', (tester) async {
      int tapCount = 0;

      await tester.pumpWidget(
        buildAppWrapper(
          child: AppButton.primary(
            label: 'Initial Loading',
            isLoading: true,
            onPressed: () => tapCount++,
          ),
        ),
      );

      for (int i = 0; i < 3; i++) {
        await tester.tap(find.byType(AppButton));
        await tester.pump();
      }

      expect(tapCount, 0);
    });

    // 2. GoldenAppBar: normal routes expose back navigation; fullscreen-dialog routes expose close/dismiss behavior
    testWidgets('GoldenAppBar: normal route exposes BackButton', (tester) async {
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('Home Page')),
        ),
      );

      navKey.currentState!.push(
        MaterialPageRoute(
          builder: (context) => const Scaffold(
            appBar: GoldenAppBar(titleText: 'Normal Route'),
            body: Text('Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BackButton), findsOneWidget);
      expect(find.byType(CloseButton), findsNothing);
    });

    testWidgets('GoldenAppBar: fullscreenDialog route exposes CloseButton', (tester) async {
      final navKey = GlobalKey<NavigatorState>();

      await tester.pumpWidget(
        MaterialApp(
          navigatorKey: navKey,
          home: const Scaffold(body: Text('Home Page')),
        ),
      );

      navKey.currentState!.push(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (context) => const Scaffold(
            appBar: GoldenAppBar(titleText: 'Fullscreen Dialog Route'),
            body: Text('Dialog Content'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CloseButton), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
    });

    // 3. AppDialog: actions remain visible and usable at text scales 1.5x and 2.0x
    for (final scale in [1.5, 2.0]) {
      testWidgets('AppDialog: actions remain visible and clickable at ${scale}x scale', (tester) async {
        bool primaryClicked = false;
        bool secondaryClicked = false;

        await tester.pumpWidget(
          buildAppWrapper(
            textScale: scale,
            child: Builder(
              builder: (context) {
                return ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AppDialog.confirmation(
                        title: 'Confirm Action',
                        contentText: 'Are you sure you want to proceed with this operation at large scale?',
                        primaryActionLabel: 'Confirm Now',
                        secondaryActionLabel: 'Cancel Action',
                        onPrimaryAction: () {
                          primaryClicked = true;
                          Navigator.pop(ctx);
                        },
                        onSecondaryAction: () {
                          secondaryClicked = true;
                          Navigator.pop(ctx);
                        },
                      ),
                    );
                  },
                  child: const Text('Open Dialog'),
                );
              },
            ),
          ),
        );

        // Open Dialog
        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        // Check dialog is displayed without overflow exceptions
        expect(tester.takeException(), isNull);
        expect(find.text('Confirm Action'), findsOneWidget);
        expect(find.text('Confirm Now'), findsOneWidget);
        expect(find.text('Cancel Action'), findsOneWidget);

        // Tap secondary action
        await tester.tap(find.text('Cancel Action'));
        await tester.pumpAndSettle();
        expect(secondaryClicked, isTrue);
        expect(primaryClicked, isFalse);
      });
    }

    // 4. Disabled buttons and disabled selection tiles remain legible in Light and Dark
    testWidgets('Disabled buttons and disabled selection tiles render legible text in Light mode', (tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          theme: AppTheme.light,
          child: Column(
            children: [
              const AppButton.primary(
                label: 'Disabled Primary',
                onPressed: null,
              ),
              const SizedBox(height: 16),
              AppSelectionTile(
                title: 'Disabled Option',
                subtitle: 'This option cannot be selected',
                enabled: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      final buttonText = tester.widget<Text>(find.text('Disabled Primary'));
      expect(buttonText.style?.color, GoldenColors.light.disabledForeground);

      final tileTitle = tester.widget<Text>(find.text('Disabled Option'));
      expect(tileTitle.style?.color, GoldenColors.light.disabledForeground);

      final tileSubtitle = tester.widget<Text>(find.text('This option cannot be selected'));
      expect(tileSubtitle.style?.color, GoldenColors.light.disabledForeground);
    });

    testWidgets('Disabled buttons and disabled selection tiles render legible text in Dark mode', (tester) async {
      await tester.pumpWidget(
        buildAppWrapper(
          theme: AppTheme.dark,
          child: Column(
            children: [
              const AppButton.primary(
                label: 'Disabled Dark Button',
                onPressed: null,
              ),
              const SizedBox(height: 16),
              AppSelectionTile(
                title: 'Disabled Dark Option',
                subtitle: 'Dark option subtitle',
                enabled: false,
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      final buttonText = tester.widget<Text>(find.text('Disabled Dark Button'));
      expect(buttonText.style?.color, GoldenColors.dark.disabledForeground);

      final tileTitle = tester.widget<Text>(find.text('Disabled Dark Option'));
      expect(tileTitle.style?.color, GoldenColors.dark.disabledForeground);

      final tileSubtitle = tester.widget<Text>(find.text('Dark option subtitle'));
      expect(tileSubtitle.style?.color, GoldenColors.dark.disabledForeground);
    });

    // 5. AppTextField: multiline input expands without clipping at 1.5x and 2.0x
    for (final scale in [1.5, 2.0]) {
      testWidgets('AppTextField: multiline input expands without clipping at ${scale}x scale', (tester) async {
        final controller = TextEditingController(
          text: 'Line 1: Pre-trip inspection noted\n'
              'Line 2: Brake fluid level checked\n'
              'Line 3: Tire tread depth within acceptable bounds\n'
              'Line 4: Headlights and taillights functional\n'
              'Line 5: Defect report filed with dispatch.',
        );

        await tester.pumpWidget(
          buildAppWrapper(
            textScale: scale,
            child: SingleChildScrollView(
              child: AppTextField(
                label: 'Inspection Remarks',
                controller: controller,
                maxLines: 5,
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final renderBox = tester.renderObject<RenderBox>(find.byType(TextField));
        // Verify height expanded considerably beyond single-line input height (52.0)
        expect(renderBox.size.height, greaterThan(AppSizing.inputHeight));
      });
    }

    // 6. AppStatusBadge and AppStatusPill resolve identical semantic colors for the same status while retaining different shapes
    testWidgets('AppStatusBadge and AppStatusPill resolve identical semantic colors across roles', (tester) async {
      const goldenColors = GoldenColors.light;

      final testCases = [
        (AppStatusBadgeType.success, AppStatusPillType.success, StatusSemanticRole.success),
        (AppStatusBadgeType.error, AppStatusPillType.error, StatusSemanticRole.error),
        (AppStatusBadgeType.warning, AppStatusPillType.warning, StatusSemanticRole.warning),
        (AppStatusBadgeType.info, AppStatusPillType.info, StatusSemanticRole.info),
        (AppStatusBadgeType.neutral, AppStatusPillType.neutral, StatusSemanticRole.neutral),
      ];

      for (final (badgeType, pillType, semanticRole) in testCases) {
        final (expectedText, expectedBg) = semanticRole.resolve(goldenColors);

        Widget buildPill(AppStatusPillType type, String label) {
          return switch (type) {
            AppStatusPillType.success => AppStatusPill.success(label: label),
            AppStatusPillType.error => AppStatusPill.error(label: label),
            AppStatusPillType.warning => AppStatusPill.warning(label: label),
            AppStatusPillType.info => AppStatusPill.info(label: label),
            AppStatusPillType.neutral => AppStatusPill.neutral(label: label),
          };
        }

        await tester.pumpWidget(
          buildAppWrapper(
            theme: AppTheme.light,
            child: Column(
              children: [
                AppStatusBadge(
                  label: 'Badge ${badgeType.name}',
                  type: badgeType,
                ),
                buildPill(pillType, 'Pill ${pillType.name}'),
              ],
            ),
          ),
        );

        // Verify Badge text & container color
        final badgeText = tester.widget<Text>(find.text('Badge ${badgeType.name}'));
        expect(badgeText.style?.color, expectedText);

        final badgeContainer = tester.widget<Container>(
          find.descendant(of: find.byType(AppStatusBadge), matching: find.byType(Container)).first,
        );
        final badgeDec = badgeContainer.decoration as BoxDecoration;
        expect(badgeDec.color, expectedBg);
        expect(badgeDec.borderRadius, BorderRadius.circular(AppRadius.badge));

        // Verify Pill text & container color
        final pillText = tester.widget<Text>(find.text('Pill ${pillType.name}'));
        expect(pillText.style?.color, expectedText);

        final pillContainer = tester.widget<Container>(
          find.descendant(of: find.byType(AppStatusPill), matching: find.byType(Container)).first,
        );
        final pillDec = pillContainer.decoration as BoxDecoration;
        expect(pillDec.color, expectedBg);
        expect(pillDec.borderRadius, BorderRadius.circular(AppRadius.pill));
      }
    });
  });
}
