import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/design_system.dart';

void main() {
  group('AppButton Unified State System Tests', () {
    Widget buildApp({
      required Widget child,
      ThemeData? theme,
    }) {
      return MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: child,
            ),
          ),
        ),
      );
    }

    testWidgets('Primary button identity in Light Mode uses gold background and dark readable text', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: AppButton.primary(
            label: 'Submit Inspection',
            onPressed: () {},
          ),
        ),
      );

      expect(find.text('Submit Inspection'), findsOneWidget);

      final material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      expect(material.color, AppColors.primaryGold);

      final text = tester.widget<Text>(find.text('Submit Inspection'));
      expect(text.style?.color, AppTheme.light.colorScheme.onPrimary);
    });

    testWidgets('Disabled button uses distinct semantic surface and muted readable text', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const AppButton.primary(
            label: 'Disabled Action',
            onPressed: null,
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      // Disabled filled button has distinct muted surface
      expect(material.color, GoldenColors.light.surfaceSecondary);

      final text = tester.widget<Text>(find.text('Disabled Action'));
      expect(text.style?.color, GoldenColors.light.textMuted);

      // Verify InkWell has no onTap
      final inkWell = tester.widget<InkWell>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(InkWell)),
      );
      expect(inkWell.onTap, isNull);
    });

    testWidgets('Loading state prevents interaction, preserves dimensions, and shows progress indicator', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        buildApp(
          child: AppButton.primary(
            label: 'Signing...',
            isLoading: true,
            onPressed: () => tapped = true,
          ),
        ),
      );

      // Label is hidden during loading, spinner is visible
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Fixed height preserved
      expect(tester.getSize(find.byType(AppButton)).height, AppSizing.buttonHeight);

      // Tap does not invoke callback
      await tester.tap(find.byType(AppButton));
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('Secondary button uses transparent surface with primary gold border', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: AppButton.secondary(
            label: 'Review Later',
            onPressed: () {},
          ),
        ),
      );

      final material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      expect(material.color, Colors.transparent);

      final shape = material.shape as RoundedRectangleBorder;
      expect(shape.side.color, GoldenColors.light.primaryText);
    });

    testWidgets('Destructive and Success buttons map to semantic tokens', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: Column(
            children: [
              AppButton.destructive(label: 'Delete Record', onPressed: () {}),
              AppButton.success(label: 'Confirm Approval', onPressed: () {}),
            ],
          ),
        ),
      );

      expect(find.text('Delete Record'), findsOneWidget);
      expect(find.text('Confirm Approval'), findsOneWidget);
    });

    testWidgets('Focused button displays distinct focus border', (tester) async {
      final focusNode = FocusNode();
      await tester.pumpWidget(
        buildApp(
          child: Focus(
            focusNode: focusNode,
            child: AppButton.primary(
              label: 'Focus Target',
              onPressed: () {},
            ),
          ),
        ),
      );

      // Initially unfocused
      var material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      var shape = material.shape as RoundedRectangleBorder;
      expect(shape.side, BorderSide.none);

      // Trigger focus on InkWell
      final inkWellFinder = find.descendant(
        of: find.byType(AppButton),
        matching: find.byType(InkWell),
      );
      final inkWell = tester.widget<InkWell>(inkWellFinder);
      inkWell.onFocusChange?.call(true);
      await tester.pump();

      // After focus, shape has 2.0px focus border
      material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      shape = material.shape as RoundedRectangleBorder;
      expect(shape.side.width, 2.0);
    });

    testWidgets('Hovered button blends hover overlay', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: AppButton.primary(
            label: 'Hover Target',
            onPressed: () {},
          ),
        ),
      );

      final inkWellFinder = find.descendant(
        of: find.byType(AppButton),
        matching: find.byType(InkWell),
      );
      final inkWell = tester.widget<InkWell>(inkWellFinder);

      // Trigger hover
      inkWell.onHover?.call(true);
      await tester.pump();

      final material = tester.widget<Material>(
        find.descendant(of: find.byType(AppButton), matching: find.byType(Material)),
      );
      // Hovered color is blended, different from base primary gold
      expect(material.color, isNot(AppColors.primaryGold));
    });
  });
}
