import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/features/connection/presentation/widgets/connecting_overlay.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

/// The overlay reports progress and the cancel action it exposes must look as
/// available as it actually is. Its cancel callback is always non-null, so a
/// dim "tertiary" look was misleading.
void main() {
  Future<void> pumpOverlay(
    WidgetTester tester, {
    bool isConnecting = true,
    bool isContinuingDisconnected = false,
    bool serverRequestPending = false,
    VoidCallback? onCancel,
    VoidCallback? onContinueDisconnected,
    Locale locale = const Locale('en'),
    Size surfaceSize = const Size(400, 800),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: ConnectingOverlay(
            isContinuingDisconnected: isContinuingDisconnected,
            isConnecting: isConnecting,
            serverRequestPending: serverRequestPending,
            onCancel: onCancel ?? () {},
            onContinueDisconnected: onContinueDisconnected,
          ),
        ),
      ),
    );
    // A CircularProgressIndicator animates forever, so pumpAndSettle would
    // time out; a single frame is enough for layout assertions.
    await tester.pump();
  }

  testWidgets('cancel is enabled and visually secondary, not a dim tertiary', (
    tester,
  ) async {
    var cancelled = 0;
    await pumpOverlay(tester, onCancel: () => cancelled++);

    final cancel = tester.widget<AppButton>(
      find.byKey(const Key('cancel_connection_button')),
    );
    expect(cancel.type, EldButtonType.secondary);
    expect(cancel.onPressed, isNotNull);
    expect(cancel.isLoading, isFalse);
    expect(cancel.icon, Icons.close);

    expect(find.text('You can cancel at any time.'), findsOneWidget);

    await tester.tap(find.byKey(const Key('cancel_connection_button')));
    expect(cancelled, 1);
  });

  testWidgets('progress text is announced and named per operation', (
    tester,
  ) async {
    await pumpOverlay(tester);
    expect(find.text('Connecting...'), findsOneWidget);

    await pumpOverlay(
      tester,
      isConnecting: false,
      isContinuingDisconnected: true,
    );
    expect(find.text('Submitting disconnected mode...'), findsOneWidget);
  });

  testWidgets(
    'continue action is unavailable while a server write is pending',
    (tester) async {
      await pumpOverlay(
        tester,
        serverRequestPending: true,
        onContinueDisconnected: () {},
      );

      final continueButton = tester.widget<AppButton>(
        find.byKey(const Key('continue_disconnected_overlay_button')),
      );
      expect(continueButton.onPressed, isNull);

      final cancel = tester.widget<AppButton>(
        find.byKey(const Key('cancel_connection_button')),
      );
      expect(cancel.onPressed, isNotNull, reason: 'cancel stays available');
    },
  );

  testWidgets('Arabic RTL at 320dp and 2.0x text does not overflow', (
    tester,
  ) async {
    await pumpOverlay(
      tester,
      locale: const Locale('ar'),
      surfaceSize: const Size(320, 640),
      textScale: 2.0,
    );

    expect(tester.takeException(), isNull);
    expect(find.byKey(const Key('cancel_connection_button')), findsOneWidget);
  });
}
