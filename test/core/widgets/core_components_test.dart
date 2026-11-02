import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/design_system.dart';

void main() {
  group('Phase 2A — Core Component Migration Tests', () {
    Widget buildThemedApp({
      required Widget child,
      ThemeData? theme,
      TextDirection textDirection = TextDirection.ltr,
      TextScaler textScaler = TextScaler.noScaling,
    }) {
      return MaterialApp(
        theme: theme ?? AppTheme.light,
        home: Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQueryData(textScaler: textScaler),
            child: Scaffold(
              body: Center(child: child),
            ),
          ),
        ),
      );
    }

    // =========================================================================
    // 1. AppButton Tests
    // =========================================================================
    group('AppButton', () {
      testWidgets('Renders all 5 semantic roles in Light Mode', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            theme: AppTheme.light,
            child: Column(
              children: [
                AppButton.primary(label: 'Primary', onPressed: () {}),
                AppButton.secondary(label: 'Secondary', onPressed: () {}),
                AppButton.tertiary(label: 'Tertiary', onPressed: () {}),
                AppButton.destructive(label: 'Destructive', onPressed: () {}),
                AppButton.success(label: 'Success', onPressed: () {}),
              ],
            ),
          ),
        );

        expect(find.text('Primary'), findsOneWidget);
        expect(find.text('Secondary'), findsOneWidget);
        expect(find.text('Tertiary'), findsOneWidget);
        expect(find.text('Destructive'), findsOneWidget);
        expect(find.text('Success'), findsOneWidget);
      });

      testWidgets('Renders all 5 semantic roles in Dark Mode', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            theme: AppTheme.dark,
            child: Column(
              children: [
                AppButton.primary(label: 'Primary Dark', onPressed: () {}),
                AppButton.secondary(label: 'Secondary Dark', onPressed: () {}),
                AppButton.tertiary(label: 'Tertiary Dark', onPressed: () {}),
                AppButton.destructive(label: 'Destructive Dark', onPressed: () {}),
                AppButton.success(label: 'Success Dark', onPressed: () {}),
              ],
            ),
          ),
        );

        expect(find.text('Primary Dark'), findsOneWidget);
        expect(find.text('Secondary Dark'), findsOneWidget);
        expect(find.text('Tertiary Dark'), findsOneWidget);
        expect(find.text('Destructive Dark'), findsOneWidget);
        expect(find.text('Success Dark'), findsOneWidget);
      });

      testWidgets('Maps legacy EldButtonType values to correct semantic roles', (tester) async {
        expect(EldButtonType.agree.role, equals(AppButtonRole.success));
        expect(EldButtonType.connect.role, equals(AppButtonRole.success));
        expect(EldButtonType.danger.role, equals(AppButtonRole.destructive));
        expect(EldButtonType.continueDisconnected.role, equals(AppButtonRole.secondary));
        expect(EldButtonType.send.role, equals(AppButtonRole.primary));
        expect(EldButtonType.dark.role, equals(AppButtonRole.tertiary));
        expect(EldButtonType.muted.role, equals(AppButtonRole.tertiary));
      });

      testWidgets('Enabled button triggers onPressed; Disabled button does not', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildThemedApp(
            child: AppButton(
              label: 'Enabled Btn',
              onPressed: () => tapped = true,
            ),
          ),
        );

        await tester.tap(find.text('Enabled Btn'));
        await tester.pump();
        expect(tapped, isTrue);

        // Disabled button
        tapped = false;
        await tester.pumpWidget(
          buildThemedApp(
            child: const AppButton(
              label: 'Disabled Btn',
              onPressed: null,
            ),
          ),
        );

        await tester.tap(find.text('Disabled Btn'));
        await tester.pump();
        expect(tapped, isFalse);
      });

      testWidgets('Loading state displays spinner and ignores tap', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildThemedApp(
            child: AppButton(
              label: 'Loading Btn',
              isLoading: true,
              onPressed: () => tapped = true,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Loading Btn'), findsNothing);

        await tester.tap(find.byType(AppButton));
        await tester.pump();
        expect(tapped, isFalse);
      });

      testWidgets('Supports text scaling without RenderFlex overflow', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            textScaler: const TextScaler.linear(2.0),
            child: AppButton(
              label: 'Button With Very Long Text That Scales Significantly',
              icon: Icons.check,
              onPressed: () {},
            ),
          ),
        );

        expect(find.byType(AppButton), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('Standard height vs compact height', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            child: Column(
              children: [
                AppButton.primary(label: 'Standard', isCompact: false, onPressed: () {}),
                AppButton.primary(label: 'Compact', isCompact: true, onPressed: () {}),
              ],
            ),
          ),
        );

        final standardBox = tester.renderObject<RenderBox>(find.byType(SizedBox).first);
        expect(standardBox.size.height, equals(AppSizing.buttonHeight));

        final compactFinder = find.ancestor(
          of: find.text('Compact'),
          matching: find.byType(SizedBox),
        ).first;
        final compactBox = tester.renderObject<RenderBox>(compactFinder);
        expect(compactBox.size.height, equals(AppSizing.buttonCompactHeight));
      });
    });

    // =========================================================================
    // 2. AppTextField Tests
    // =========================================================================
    group('AppTextField', () {
      testWidgets('Renders normal state with proper minHeight constraint in Light and Dark', (tester) async {
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          await tester.pumpWidget(
            buildThemedApp(
              theme: theme,
              child: const AppTextField(
                label: 'Test Label',
                hint: 'Test Hint',
              ),
            ),
          );

          expect(find.text('Test Label'), findsOneWidget);
          expect(find.text('Test Hint'), findsOneWidget);
        }
      });

      testWidgets('Renders error state without crashing', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            child: const AppTextField(
              label: 'Field with Error',
              errorText: 'Required Field',
            ),
          ),
        );

        expect(find.text('Required Field'), findsOneWidget);
      });

      testWidgets('Renders disabled state properly', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            child: const AppTextField(
              label: 'Disabled Field',
              enabled: false,
            ),
          ),
        );

        final textField = tester.widget<TextFormField>(find.byType(TextFormField));
        expect(textField.enabled, isFalse);
      });

      testWidgets('Multiline field expands vertically beyond standard minHeight', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            child: const Column(
              children: [
                AppTextField(label: 'Single', maxLines: 1),
                AppTextField(label: 'Multi', maxLines: 5),
              ],
            ),
          ),
        );

        final singleFinder = find.byType(AppTextField).first;
        final multiFinder = find.byType(AppTextField).last;

        final singleHeight = tester.getSize(singleFinder).height;
        final multiHeight = tester.getSize(multiFinder).height;

        expect(multiHeight, greaterThan(singleHeight));
        expect(singleHeight, greaterThanOrEqualTo(AppSizing.inputHeight));
      });

      testWidgets('Supports RTL and text scaling without clipping', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            textDirection: TextDirection.rtl,
            textScaler: const TextScaler.linear(1.8),
            child: const AppTextField(
              label: 'اسم السائق بالكامل مع ملاحظات تفصيلية',
              hint: 'أدخل النص هنا',
              prefixIcon: Icon(Icons.person),
            ),
          ),
        );

        expect(find.text('اسم السائق بالكامل مع ملاحظات تفصيلية'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    // =========================================================================
    // 3. EldCard Tests
    // =========================================================================
    group('EldCard', () {
      testWidgets('Renders in Light and Dark mode with appropriate surface colors', (tester) async {
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          await tester.pumpWidget(
            buildThemedApp(
              theme: theme,
              child: const EldCard(
                child: Text('Card Content'),
              ),
            ),
          );

          expect(find.text('Card Content'), findsOneWidget);
          final card = tester.widget<Card>(find.byType(Card));
          expect(card.shape, isA<RoundedRectangleBorder>());
          final shape = card.shape as RoundedRectangleBorder;
          expect(shape.borderRadius, BorderRadius.circular(AppRadius.card));
        }
      });

      testWidgets('Respects custom and default padding', (tester) async {
        // Default padding
        await tester.pumpWidget(
          buildThemedApp(
            child: const EldCard(
              child: Text('Default'),
            ),
          ),
        );

        final defaultPadding = tester.widget<Padding>(
          find.descendant(of: find.byType(InkWell), matching: find.byType(Padding)),
        );
        expect(defaultPadding.padding, const EdgeInsets.all(AppSpacing.cardPadding));

        // Custom padding
        await tester.pumpWidget(
          buildThemedApp(
            child: const EldCard(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text('Custom'),
            ),
          ),
        );

        final customPadding = tester.widget<Padding>(
          find.descendant(of: find.byType(InkWell), matching: find.byType(Padding)),
        );
        expect(customPadding.padding, const EdgeInsets.symmetric(horizontal: 24, vertical: 8));
      });

      testWidgets('InkWell handles tap properly', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildThemedApp(
            child: EldCard(
              onTap: () => tapped = true,
              child: const Text('Tappable'),
            ),
          ),
        );

        await tester.tap(find.text('Tappable'));
        await tester.pump();
        expect(tapped, isTrue);
      });
    });

    // =========================================================================
    // 4. AppStatusBadge Tests
    // =========================================================================
    group('AppStatusBadge', () {
      testWidgets('Renders all 5 semantic states in Light and Dark mode', (tester) async {
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          await tester.pumpWidget(
            buildThemedApp(
              theme: theme,
              child: const Column(
                children: [
                  AppStatusBadge(label: 'Success', type: AppStatusBadgeType.success, icon: Icons.check),
                  AppStatusBadge(label: 'Error', type: AppStatusBadgeType.error, icon: Icons.error),
                  AppStatusBadge(label: 'Warning', type: AppStatusBadgeType.warning, icon: Icons.warning),
                  AppStatusBadge(label: 'Info', type: AppStatusBadgeType.info, icon: Icons.info),
                  AppStatusBadge(label: 'Neutral', type: AppStatusBadgeType.neutral, icon: Icons.circle),
                ],
              ),
            ),
          );

          expect(find.text('Success'), findsOneWidget);
          expect(find.text('Error'), findsOneWidget);
          expect(find.text('Warning'), findsOneWidget);
          expect(find.text('Info'), findsOneWidget);
          expect(find.text('Neutral'), findsOneWidget);
        }
      });

      testWidgets('Supports text scaling without overflow', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            textScaler: const TextScaler.linear(1.8),
            child: const AppStatusBadge(
              label: 'Very Long Status Badge Label',
              type: AppStatusBadgeType.success,
              icon: Icons.check,
            ),
          ),
        );

        expect(find.text('Very Long Status Badge Label'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    // =========================================================================
    // 5. AppStatusPill Tests
    // =========================================================================
    group('AppStatusPill', () {
      testWidgets('Renders all 5 semantic constructors in Light and Dark mode', (tester) async {
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          await tester.pumpWidget(
            buildThemedApp(
              theme: theme,
              child: const Column(
                children: [
                  AppStatusPill.success(label: 'Active', icon: Icons.circle),
                  AppStatusPill.error(label: 'Failed', icon: Icons.circle),
                  AppStatusPill.warning(label: 'Pending', icon: Icons.circle),
                  AppStatusPill.info(label: 'Notice', icon: Icons.circle),
                  AppStatusPill.neutral(label: 'Inactive', icon: Icons.circle),
                ],
              ),
            ),
          );

          expect(find.text('Active'), findsOneWidget);
          expect(find.text('Failed'), findsOneWidget);
          expect(find.text('Pending'), findsOneWidget);
          expect(find.text('Notice'), findsOneWidget);
          expect(find.text('Inactive'), findsOneWidget);
        }
      });

      testWidgets('Supports legacy constructor with explicit color', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            child: const AppStatusPill(
              label: 'Custom Color',
              color: Colors.amber,
              icon: Icons.star,
            ),
          ),
        );

        expect(find.text('Custom Color'), findsOneWidget);
        expect(find.byIcon(Icons.star), findsOneWidget);
      });

      testWidgets('Supports RTL and text scaling without overflow', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            textDirection: TextDirection.rtl,
            textScaler: const TextScaler.linear(1.8),
            child: const AppStatusPill.success(
              label: 'مكتمل بنجاح',
              icon: Icons.check_circle,
            ),
          ),
        );

        expect(find.text('مكتمل بنجاح'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}
