import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/widgets/eld_retry_view.dart';
import 'package:golden_feather_eld/features/hos/presentation/pages/status_dashboard_page.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/status_dashboard_providers.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart';

import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';

import '../helpers/pump_page.dart';

void main() {
  group('StatusDashboardPage', () {
    testWidgets('shows loading indicator initially', (tester) async {
      await pumpPage(tester, const StatusDashboardPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders dashboard after load', (tester) async {
      await pumpPage(tester, const StatusDashboardPage());
      await tester.pumpAndSettle();

      expect(find.byType(MainCircularTimer), findsOneWidget);
      expect(find.byType(HosIndicatorsCard), findsOneWidget);
    });

    testWidgets('renders status label', (tester) async {
      await pumpPage(tester, const StatusDashboardPage());
      await tester.pumpAndSettle();

      // MockAdapter default is onDutyNotDriving → "ON DUTY"
      expect(find.text('ON DUTY'), findsOneWidget);
    });

    testWidgets('renders driver-independent data', (tester) async {
      await pumpPage(tester, const StatusDashboardPage());
      await tester.pumpAndSettle();

      expect(find.text('DRIVE'), findsOneWidget);
      expect(find.text('SHIFT'), findsOneWidget);
      expect(find.text('BREAK'), findsOneWidget);
      expect(find.text('CYCLE'), findsOneWidget);
    });

    testWidgets('shows the applied rule set and its legal limits (SRS 4.x)',
        (tester) async {
      await pumpPage(tester, const StatusDashboardPage());
      await tester.pumpAndSettle();

      // Rule set and limits render as the table's description lines
      // (reference layout: no separate chip / caption).
      expect(find.textContaining('USA 70/8'), findsOneWidget);
      expect(find.textContaining('11-Hour Driving Limit'), findsOneWidget);
      expect(find.textContaining('14-Hour On Duty Limit'), findsOneWidget);
      expect(find.text('HOURS OF SERVICE'), findsOneWidget);
    });

    testWidgets('shows loading view when session is missing during transition',
        (tester) async {
      await pumpPage(
        tester,
        const StatusDashboardPage(),
        overrides: [
          statusDashboardProvider.overrideWith(
            () => _ThrowingDashboardNotifier(const SessionMissingFailure()),
          ),
        ],
      );
      await tester.pump();

      // Must NOT show EldRetryView on SessionMissingFailure (prevents error flash)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(EldRetryView), findsNothing);
    });

    testWidgets('shows EldRetryView on real terminal failure without previous data',
        (tester) async {
      await pumpPage(
        tester,
        const StatusDashboardPage(),
        overrides: [
          statusDashboardProvider.overrideWith(
            () => _ThrowingDashboardNotifier(
              const ServerFailure(message: 'server_down'),
            ),
          ),
        ],
      );
      await tester.pumpAndSettle();

      expect(find.byType(EldRetryView), findsOneWidget);
    });
  });
}

class _ThrowingDashboardNotifier extends StatusDashboardNotifier {
  final Object failureToThrow;

  _ThrowingDashboardNotifier(this.failureToThrow);

  @override
  Future<StatusDashboard> build() async {
    throw failureToThrow;
  }
}
