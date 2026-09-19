import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/hos/presentation/pages/status_dashboard_page.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart';

import '../../helpers/pump_page.dart';

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
  });
}
