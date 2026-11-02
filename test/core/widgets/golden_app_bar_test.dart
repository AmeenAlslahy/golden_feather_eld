import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/design_system.dart';

void main() {
  group('GoldenAppBar Tests', () {
    Widget buildApp({
      required Widget child,
      ThemeData? theme,
      TextDirection textDirection = TextDirection.ltr,
      Locale locale = const Locale('en'),
    }) {
      return MaterialApp(
        theme: theme ?? AppTheme.light,
        locale: locale,
        home: Directionality(
          textDirection: textDirection,
          child: child,
        ),
      );
    }

    testWidgets('Brand variant applies brand golden gradient and dark text', (tester) async {
      await tester.pumpWidget(
        buildApp(
          theme: AppTheme.light,
          child: const Scaffold(
            appBar: GoldenAppBar(
              titleText: 'Inspection Reports',
              variant: GoldenAppBarVariant.brand,
            ),
          ),
        ),
      );

      expect(find.text('Inspection Reports'), findsOneWidget);

      // Verify Tooltip wrapping for accessibility
      expect(find.byType(Tooltip), findsOneWidget);

      // Verify Text color is brand black for contrast over gold
      final textWidget = tester.widget<Text>(find.text('Inspection Reports'));
      expect(textWidget.style?.color, AppColors.brandBlack);

      // Verify AnnotatedRegion sets dark status bar icons over gold gradient
      final annotated = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.descendant(
          of: find.byType(GoldenAppBar),
          matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        ).first,
      );
      expect(annotated.value.statusBarIconBrightness, Brightness.dark);
    });

    testWidgets('Brand variant maintains dark text & dark status bar icons in Dark Mode', (tester) async {
      await tester.pumpWidget(
        buildApp(
          theme: AppTheme.dark,
          child: const Scaffold(
            appBar: GoldenAppBar(
              titleText: 'Dark Brand Header',
              variant: GoldenAppBarVariant.brand,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text('Dark Brand Header'));
      expect(textWidget.style?.color, AppColors.brandBlack);

      final annotated = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.descendant(
          of: find.byType(GoldenAppBar),
          matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        ).first,
      );
      expect(annotated.value.statusBarIconBrightness, Brightness.dark);
    });

    testWidgets('Standard variant uses theme surface and adaptive system overlay', (tester) async {
      await tester.pumpWidget(
        buildApp(
          theme: AppTheme.dark,
          child: const Scaffold(
            appBar: GoldenAppBar(
              titleText: 'Standard Neutral Header',
              variant: GoldenAppBarVariant.standard,
            ),
          ),
        ),
      );

      expect(find.text('Standard Neutral Header'), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text('Standard Neutral Header'));
      expect(textWidget.style?.color, AppTheme.dark.colorScheme.onSurface);

      final annotated = tester.widget<AnnotatedRegion<SystemUiOverlayStyle>>(
        find.descendant(
          of: find.byType(GoldenAppBar),
          matching: find.byType(AnnotatedRegion<SystemUiOverlayStyle>),
        ).first,
      );
      expect(annotated.value.statusBarIconBrightness, Brightness.light);
    });

    testWidgets('Long title is accessible via Tooltip and does not silently truncate', (tester) async {
      const longTitle = 'Driver Vehicle Inspection Report For Heavy Commercial Fleet Multi-Stop Route 2026';

      await tester.pumpWidget(
        buildApp(
          child: const Scaffold(
            appBar: GoldenAppBar(
              titleText: longTitle,
              variant: GoldenAppBarVariant.brand,
            ),
          ),
        ),
      );

      final textWidget = tester.widget<Text>(find.text(longTitle));
      expect(textWidget.maxLines, 2);
      expect(textWidget.overflow, TextOverflow.ellipsis);

      final tooltip = tester.widget<Tooltip>(find.byType(Tooltip));
      expect(tooltip.message, longTitle);
    });

    testWidgets('RTL directional navigation renders correctly in Arabic', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('ar'),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (context) => Scaffold(
                  body: Center(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const Scaffold(
                              appBar: GoldenAppBar(
                                titleText: 'تفاصيل الفحص',
                                variant: GoldenAppBarVariant.brand,
                              ),
                            ),
                          ),
                        );
                      },
                      child: const Text('Open Detail'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Detail'));
      await tester.pumpAndSettle();

      expect(find.text('تفاصيل الفحص'), findsOneWidget);
      // Back button should be present
      expect(find.byType(BackButton), findsOneWidget);

      final backButton = tester.widget<BackButton>(find.byType(BackButton));
      expect(backButton.color, AppColors.brandBlack);

      // Tapping back button navigates back
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('Open Detail'), findsOneWidget);
    });

    testWidgets('Actions inherit centralized foreground color and spacing', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: Scaffold(
            appBar: GoldenAppBar(
              titleText: 'Actions Test',
              variant: GoldenAppBarVariant.brand,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.refresh), findsOneWidget);
      final iconTheme = tester.widget<IconTheme>(
        find.ancestor(
          of: find.byIcon(Icons.refresh),
          matching: find.byType(IconTheme),
        ).first,
      );
      expect(iconTheme.data.color, AppColors.brandBlack);
    });
  });
}
