import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/config/feature_flags.dart';
import 'package:golden_feather_eld/features/home/presentation/pages/home_page.dart';
import 'package:golden_feather_eld/features/hos/presentation/pages/status_dashboard_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

void main() {
  // HomePage is a full Scaffold — do NOT wrap it in another Scaffold
  // (that causes unbounded-height RenderFlex errors).
  Future<void> pumpHomePage(
    WidgetTester tester, {
    required FeatureFlags flags,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          featureFlagsProvider.overrideWithValue(flags),
        ],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: HomePage(),
        ),
      ),
    );
  }

  group('HomePage — feature flag OFF', () {
    testWidgets('does NOT show new StatusDashboardPage', (tester) async {
      await pumpHomePage(
        tester,
        flags: const FeatureFlags(useNewStatusDashboard: false),
      );
      await tester.pump();

      expect(find.byType(StatusDashboardPage), findsNothing);
    });
  });

  group('HomePage — feature flag ON', () {
    testWidgets('shows new StatusDashboardPage', (tester) async {
      await pumpHomePage(
        tester,
        flags: const FeatureFlags(useNewStatusDashboard: true),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatusDashboardPage), findsOneWidget);
    });
  });
}
