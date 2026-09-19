import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/config/feature_flags.dart';
import 'package:golden_feather_eld/features/home/presentation/pages/home_page.dart';
import 'package:golden_feather_eld/features/hos/presentation/pages/status_dashboard_page.dart';

import '../../../hos/presentation/helpers/pump_page.dart';

void main() {
  group('HomePage — feature flag OFF', () {
    testWidgets('shows legacy StatusDashboard (HosPage)', (tester) async {
      await pumpPage(
        tester,
        const HomePage(),
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          featureFlagsProvider.overrideWithValue(
            const FeatureFlags(useNewStatusDashboard: false),
          ),
        ],
      );
      await tester.pump();

      // Legacy StatusDashboard is present (NOT StatusDashboardPage).
      expect(find.byType(StatusDashboardPage), findsNothing);
    });
  });

  group('HomePage — feature flag ON', () {
    testWidgets('shows new StatusDashboardPage', (tester) async {
      await pumpPage(
        tester,
        const HomePage(),
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          featureFlagsProvider.overrideWithValue(
            const FeatureFlags(useNewStatusDashboard: true),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatusDashboardPage), findsOneWidget);
    });
  });
}
