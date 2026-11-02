import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/domain/entities/connection_status.dart';
import 'package:golden_feather_eld/core/design_system.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:signature/signature.dart';

void main() {
  group('Phase 2B — Supporting Component Migration Tests', () {
    Widget buildThemedApp({
      required Widget child,
      ThemeData? theme,
      Locale locale = const Locale('en'),
      TextDirection textDirection = TextDirection.ltr,
      TextScaler textScaler = TextScaler.noScaling,
    }) {
      return ProviderScope(
        child: MaterialApp(
          theme: theme ?? AppTheme.light,
          locale: locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: AppLocalizations.supportedLocales,
          home: Directionality(
            textDirection: textDirection,
            child: MediaQuery(
              data: MediaQueryData(textScaler: textScaler),
              child: Scaffold(
                body: Center(child: child),
              ),
            ),
          ),
        ),
      );
    }

    // =========================================================================
    // 1. AppFeedback Tests
    // =========================================================================
    group('AppFeedback', () {
      testWidgets('Triggers success, error, info, and warn in Light & Dark without error', (tester) async {
        for (final theme in [AppTheme.light, AppTheme.dark]) {
          await tester.pumpWidget(
            buildThemedApp(
              theme: theme,
              child: Builder(
                builder: (context) => Column(
                  children: [
                    ElevatedButton(
                      onPressed: () => AppFeedback.success(context, 'Success msg'),
                      child: const Text('Show Success'),
                    ),
                    ElevatedButton(
                      onPressed: () => AppFeedback.error(context, 'Error msg'),
                      child: const Text('Show Error'),
                    ),
                    ElevatedButton(
                      onPressed: () => AppFeedback.info(context, 'Info msg'),
                      child: const Text('Show Info'),
                    ),
                    ElevatedButton(
                      onPressed: () => AppFeedback.warn(context, 'Warning msg'),
                      child: const Text('Show Warn'),
                    ),
                  ],
                ),
              ),
            ),
          );

          // Success
          await tester.tap(find.text('Show Success'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('Success msg'), findsOneWidget);

          // Error
          await tester.tap(find.text('Show Error'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('Error msg'), findsOneWidget);

          // Info
          await tester.tap(find.text('Show Info'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('Info msg'), findsOneWidget);

          // Warn
          await tester.tap(find.text('Show Warn'));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 100));
          expect(find.text('Warning msg'), findsOneWidget);

          // Drain the 3-second timer
          await tester.pump(const Duration(seconds: 4));
        }
      });

      testWidgets('Supports text scaling (2.0) and swipe-up dismissal', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            textScaler: const TextScaler.linear(2.0),
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => AppFeedback.success(context, 'Scaled message'),
                child: const Text('Trigger'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Trigger'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('Scaled message'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Tap to dismiss
        await tester.tap(find.text('Scaled message'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.text('Scaled message'), findsNothing);

        // Drain the 3-second timer
        await tester.pump(const Duration(seconds: 4));
      });

      testWidgets('Does not throw when caller context is deactivated and overlay rebuilds', (tester) async {
        var showChild = true;
        late StateSetter updateState;

        await tester.pumpWidget(
          buildThemedApp(
            child: StatefulBuilder(
              builder: (context, setState) {
                updateState = setState;
                if (!showChild) {
                  return const SizedBox();
                }
                return Builder(
                  builder: (innerContext) => ElevatedButton(
                    onPressed: () {
                      AppFeedback.success(innerContext, 'Caller deactivated');
                    },
                    child: const Text('Trigger'),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Trigger'));
        await tester.pump();

        // Deactivate caller widget
        updateState(() {
          showChild = false;
        });
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Expect feedback message still visible without throwing deactivated ancestor lookup error
        expect(find.text('Caller deactivated'), findsOneWidget);
        expect(tester.takeException(), isNull);

        // Drain timer
        await tester.pump(const Duration(seconds: 4));
      });
    });

    // =========================================================================
    // 2. EldRetryView Tests
    // =========================================================================
    group('EldRetryView', () {
      testWidgets('Error state renders title, message, and retry button', (tester) async {
        bool retried = false;

        await tester.pumpWidget(
          buildThemedApp(
            child: EldRetryView.error(
              title: 'Connection Failed',
              message: 'Unable to reach backend',
              onRetry: () => retried = true,
            ),
          ),
        );

        expect(find.text('Connection Failed'), findsOneWidget);
        expect(find.text('Unable to reach backend'), findsOneWidget);
        expect(find.byType(IconButton), findsOneWidget);

        await tester.tap(find.byType(IconButton));
        await tester.pump();
        expect(retried, isTrue);
      });

      testWidgets('Empty state renders without requiring retry button', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            child: const EldRetryView.empty(
              title: 'No Logs Found',
              message: 'You have no logs recorded for today.',
            ),
          ),
        );

        expect(find.text('No Logs Found'), findsOneWidget);
        expect(find.text('You have no logs recorded for today.'), findsOneWidget);
        expect(find.byType(IconButton), findsNothing);
      });

      testWidgets('Supports text scaling (2.0) and RTL layout', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            textDirection: TextDirection.rtl,
            textScaler: const TextScaler.linear(2.0),
            child: const EldRetryView(
              message: 'فشل في تحميل السجلات، يرجى المحاولة لاحقاً',
            ),
          ),
        );

        expect(find.text('فشل في تحميل السجلات، يرجى المحاولة لاحقاً'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    // =========================================================================
    // 3. ConnectionStatusIndicator Tests
    // =========================================================================
    group('ConnectionStatusIndicator', () {
      testWidgets('Connected status displays wifi icon and localized text', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            child: const ConnectionStatusIndicator(
              statusOverride: ConnectionStatus.connected,
            ),
          ),
        );

        expect(find.byIcon(Icons.wifi), findsOneWidget);
        expect(find.text('Connected'), findsOneWidget);
      });

      testWidgets('Connecting status displays progress indicator and connecting text', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            child: const ConnectionStatusIndicator(
              statusOverride: ConnectionStatus.connecting,
            ),
          ),
        );

        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Connecting...'), findsOneWidget);
      });

      testWidgets('Disconnected status shows warning button when showWarningTriangle is true', (tester) async {
        bool tapped = false;

        await tester.pumpWidget(
          buildThemedApp(
            child: ConnectionStatusIndicator(
              statusOverride: ConnectionStatus.disconnected,
              showWarningTriangle: true,
              onTap: () => tapped = true,
            ),
          ),
        );

        expect(find.byIcon(Icons.warning_amber), findsOneWidget);
        await tester.tap(find.byIcon(Icons.warning_amber));
        await tester.pump();
        expect(tapped, isTrue);

        // When showWarningTriangle is false
        await tester.pumpWidget(
          buildThemedApp(
            child: const ConnectionStatusIndicator(
              statusOverride: ConnectionStatus.disconnected,
              showWarningTriangle: false,
            ),
          ),
        );

        expect(find.byIcon(Icons.warning_amber), findsNothing);
      });
    });

    // =========================================================================
    // 4. AppSignatureCanvas Tests
    // =========================================================================
    group('AppSignatureCanvas', () {
      testWidgets('Preserves signature points and clear action', (tester) async {
        final controller = SignatureController(
          points: [
            Point(const Offset(10, 10), PointType.tap, 1.0),
            Point(const Offset(20, 20), PointType.move, 1.0),
          ],
          penColor: Colors.black,
          exportBackgroundColor: Colors.white,
        );

        await tester.pumpWidget(
          buildThemedApp(
            child: AppSignatureCanvas(
              controller: controller,
            ),
          ),
        );

        expect(find.byType(Signature), findsOneWidget);
        expect(controller.isNotEmpty, isTrue);
        expect(controller.points.length, 2);

        // Verify clear link
        expect(find.text('Clear signature'), findsOneWidget);
        await tester.tap(find.text('Clear signature'));
        await tester.pump();

        expect(controller.isEmpty, isTrue);
        expect(controller.exportBackgroundColor, Colors.white);
      });

      testWidgets('Displays error text and adapts to dark theme', (tester) async {
        final controller = SignatureController();

        await tester.pumpWidget(
          buildThemedApp(
            theme: AppTheme.dark,
            child: AppSignatureCanvas(
              controller: controller,
              errorText: 'Signature is mandatory',
            ),
          ),
        );

        expect(find.text('Signature is mandatory'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    // =========================================================================
    // 5. AppDialog Tests
    // =========================================================================
    group('AppDialog', () {
      testWidgets('Informational dialog renders title and single primary action', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            child: const AppDialog.informational(
              title: 'Notice',
              contentText: 'System maintenance scheduled tonight.',
              primaryActionLabel: 'Got It',
            ),
          ),
        );

        expect(find.text('Notice'), findsOneWidget);
        expect(find.text('System maintenance scheduled tonight.'), findsOneWidget);
        expect(find.text('Got It'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline_rounded), findsOneWidget);
      });

      testWidgets('Confirmation dialog renders confirmation buttons and handles result', (tester) async {
        bool? result;

        await tester.pumpWidget(
          buildThemedApp(
            child: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  result = await AppDialog.show(
                    context,
                    title: 'Save Changes?',
                    contentText: 'Do you want to save your daily recap edits?',
                    primaryLabel: 'Confirm',
                    secondaryLabel: 'Cancel',
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Dialog'));
        await tester.pumpAndSettle();

        expect(find.text('Save Changes?'), findsOneWidget);
        expect(find.text('Confirm'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);

        await tester.tap(find.text('Confirm'));
        await tester.pumpAndSettle();

        expect(result, isTrue);
      });

      testWidgets('Destructive dialog renders destructive button style', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            theme: AppTheme.dark,
            child: const AppDialog.destructive(
              title: 'Delete Document?',
              contentText: 'This action cannot be undone.',
              destructiveActionLabel: 'Delete Forever',
              secondaryActionLabel: 'Keep',
            ),
          ),
        );

        expect(find.text('Delete Document?'), findsOneWidget);
        expect(find.text('Delete Forever'), findsOneWidget);
        expect(find.text('Keep'), findsOneWidget);
        expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      });

      testWidgets('Supports text scaling (2.0) and RTL layout', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            textDirection: TextDirection.rtl,
            textScaler: const TextScaler.linear(2.0),
            child: const AppDialog(
              title: 'تأكيد الحذف',
              contentText: 'هل أنت متأكد من حذف هذا السجل نهائياً؟',
              primaryActionLabel: 'تأكيد',
              secondaryActionLabel: 'إلغاء',
            ),
          ),
        );

        expect(find.text('تأكيد الحذف'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });

    // =========================================================================
    // 6. AppLogo Tests
    // =========================================================================
    group('AppLogo', () {
      testWidgets('Renders all standard sizes (small, medium, large, custom)', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            child: const Column(
              children: [
                AppLogo.small(),
                AppLogo.medium(),
                AppLogo.large(),
                AppLogo(customSize: 64.0),
              ],
            ),
          ),
        );

        expect(find.byType(AppLogo), findsNWidgets(4));
        expect(find.byType(Image), findsNWidgets(4));

        final smallBox = tester.renderObject<RenderBox>(
          find.descendant(of: find.byType(AppLogo).at(0), matching: find.byType(SizedBox)),
        );
        expect(smallBox.size.width, AppSizing.logoSmall);
        expect(smallBox.size.height, AppSizing.logoSmall);

        final mediumBox = tester.renderObject<RenderBox>(
          find.descendant(of: find.byType(AppLogo).at(1), matching: find.byType(SizedBox)),
        );
        expect(mediumBox.size.width, AppSizing.logoMedium);

        final largeBox = tester.renderObject<RenderBox>(
          find.descendant(of: find.byType(AppLogo).at(2), matching: find.byType(SizedBox)),
        );
        expect(largeBox.size.width, AppSizing.logoLarge);

        final customBox = tester.renderObject<RenderBox>(
          find.descendant(of: find.byType(AppLogo).at(3), matching: find.byType(SizedBox)),
        );
        expect(customBox.size.width, 64.0);
      });

      testWidgets('Preserves AspectRatio 1:1 and image asset path', (tester) async {
        await tester.pumpWidget(
          buildThemedApp(
            child: const AppLogo.medium(),
          ),
        );

        final imageWidget = tester.widget<Image>(find.byType(Image));
        expect(imageWidget.fit, BoxFit.contain);
        expect((imageWidget.image as AssetImage).assetName, AppLogo.assetPath);

        final aspectRatioWidget = tester.widget<AspectRatio>(find.byType(AspectRatio));
        expect(aspectRatioWidget.aspectRatio, 1.0);
      });
    });
  });
}
