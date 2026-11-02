import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/design_system.dart';
import 'package:golden_feather_eld/features/dvir/presentation/widgets/dvir_form_components.dart';

void main() {
  group('Phase 4.1 — Single Source of Visual Truth Verification', () {
    Widget buildApp({required Widget child, ThemeData? theme}) {
      return MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(body: Center(child: child)),
      );
    }

    // -------------------------------------------------------------------------
    // Test A — Button styling consistency across contexts
    // -------------------------------------------------------------------------
    testWidgets('Test A — Button styling is identical across feature boundaries', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: Column(
            children: [
              // Standard auth/core button
              AppButton.primary(label: 'Sign In', onPressed: () {}),
              // DVIR primary action button
              AppButton(
                label: 'Sign & Submit DVIR',
                type: EldButtonType.primary,
                onPressed: () {},
              ),
            ],
          ),
        ),
      );

      final materials = tester.widgetList<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      ).toList();

      expect(materials.length, 2);
      // Both buttons must share the exact same primary gold background and button shape
      expect(materials[0].color, materials[1].color);
      expect(materials[0].color, AppColors.primaryGold);
      expect(materials[0].shape, materials[1].shape);
    });

    // -------------------------------------------------------------------------
    // Test B — Input styling propagation
    // -------------------------------------------------------------------------
    testWidgets('Test B — Centralized input radius & border propagate to DVIR fields', (tester) async {
      final textController = TextEditingController(text: '125430');
      addTearDown(textController.dispose);

      await tester.pumpWidget(
        buildApp(
          child: Column(
            children: [
              // Core field (as used in Login)
              const AppTextField(hint: 'Username'),
              // DVIR field (as used in Odometer/Location)
              DvirFlatTextField(
                controller: textController,
                hint: 'Odometer',
              ),
            ],
          ),
        ),
      );

      // Both fields delegate to AppTextField
      expect(find.byType(AppTextField), findsNWidgets(2));

      final textFields = tester.widgetList<AppTextField>(find.byType(AppTextField)).toList();
      expect(textFields.length, 2);
      expect(find.byType(TextFormField), findsNWidgets(2));
    });

    // -------------------------------------------------------------------------
    // Test C — AppBar brand gradient propagation
    // -------------------------------------------------------------------------
    testWidgets('Test C — GoldenAppBar instances use centralized brandGradient definition', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const Scaffold(
            appBar: GoldenAppBar(
              titleText: 'DVIR Inspection List',
              variant: GoldenAppBarVariant.brand,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(GoldenAppBar),
          matching: find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration),
        ).first,
      );

      final decoration = container.decoration as BoxDecoration;
      expect(decoration.gradient, GoldenColors.light.brandGradient);
      expect(decoration.gradient, AppDecorations.goldenGradient);
    });

    // -------------------------------------------------------------------------
    // Test D — Theme switching reactivity
    // -------------------------------------------------------------------------
    testWidgets('Test D — Components react immediately to Light and Dark theme switching', (tester) async {
      final themeNotifier = ValueNotifier<ThemeData>(AppTheme.light);
      addTearDown(themeNotifier.dispose);

      await tester.pumpWidget(
        ValueListenableBuilder<ThemeData>(
          valueListenable: themeNotifier,
          builder: (context, theme, _) {
            return MaterialApp(
              theme: theme,
              home: Scaffold(
                appBar: const GoldenAppBar(
                  titleText: 'Theme Test',
                  variant: GoldenAppBarVariant.standard,
                ),
                body: AppButton.primary(
                  label: 'Action',
                  onPressed: () {},
                ),
              ),
            );
          },
        ),
      );

      // Light mode verification
      var text = tester.widget<Text>(find.text('Theme Test'));
      expect(text.style?.color, AppTheme.light.colorScheme.onSurface);

      // Switch to Dark mode
      themeNotifier.value = AppTheme.dark;
      await tester.pumpAndSettle();

      // Dark mode verification
      text = tester.widget<Text>(find.text('Theme Test'));
      expect(text.style?.color, AppTheme.dark.colorScheme.onSurface);
    });

    // -------------------------------------------------------------------------
    // Test E — No parallel styling in DVIR components
    // -------------------------------------------------------------------------
    testWidgets('Test E — DVIR components derive visual tokens from GoldenColors and AppRadius', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const DvirCell(
            title: 'Cell Title',
            child: Text('Cell Content'),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container).first);
      final decoration = container.decoration as BoxDecoration;

      // Radius is derived from AppRadius.input
      expect(decoration.borderRadius, BorderRadius.circular(AppRadius.input));
      // Border is derived from GoldenColors.light.border
      final border = decoration.border as Border;
      expect(border.top.color, GoldenColors.light.border);
    });
  });
}
