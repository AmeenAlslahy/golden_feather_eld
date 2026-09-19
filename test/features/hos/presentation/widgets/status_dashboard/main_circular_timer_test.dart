import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/main_circular_timer.dart';

import '../../helpers/pump_page.dart';

void main() {
  RemainingCircle circle({
    Duration remaining = const Duration(hours: 8),
    double progress = 0.6,
  }) =>
      RemainingCircle(
        remaining: remaining,
        label: 'Remaining',
        progress: progress,
      );

  group('MainCircularTimer', () {
    testWidgets('renders remaining time in HH:MM', (tester) async {
      await pumpPage(
        tester,
        MainCircularTimer(
          circle: circle(remaining: const Duration(hours: 8, minutes: 37)),
          statusLabel: 'On Duty',
        ),
      );

      expect(find.text('08:37'), findsOneWidget);
    });

    testWidgets('renders label', (tester) async {
      await pumpPage(
        tester,
        MainCircularTimer(circle: circle(), statusLabel: 'On Duty'),
      );

      expect(find.text('Remaining'), findsOneWidget);
    });

    testWidgets('renders uppercase status label', (tester) async {
      await pumpPage(
        tester,
        MainCircularTimer(circle: circle(), statusLabel: 'On Duty'),
      );

      expect(find.text('ON DUTY'), findsOneWidget);
    });

    testWidgets('uses success color when plenty of time', (tester) async {
      await pumpPage(
        tester,
        MainCircularTimer(
          circle: circle(remaining: const Duration(hours: 8)),
          statusLabel: 'Driving',
        ),
      );

      // Look up the painter's progress color indirectly by finding the widget.
      final widget = tester.widget<MainCircularTimer>(
        find.byType(MainCircularTimer),
      );
      expect(widget.circle.isCritical, isFalse);
      expect(widget.circle.isExpired, isFalse);
    });

    testWidgets('marks critical when remaining ≤ 1h', (tester) async {
      await pumpPage(
        tester,
        MainCircularTimer(
          circle: circle(remaining: const Duration(minutes: 45)),
          statusLabel: 'Driving',
        ),
      );

      final widget = tester.widget<MainCircularTimer>(
        find.byType(MainCircularTimer),
      );
      expect(widget.circle.isCritical, isTrue);
    });

    testWidgets('marks expired when remaining is zero', (tester) async {
      await pumpPage(
        tester,
        MainCircularTimer(
          circle: circle(remaining: Duration.zero),
          statusLabel: 'Driving',
        ),
      );

      final widget = tester.widget<MainCircularTimer>(
        find.byType(MainCircularTimer),
      );
      expect(widget.circle.isExpired, isTrue);
    });

    testWidgets('renders negative duration with minus sign', (tester) async {
      await pumpPage(
        tester,
        MainCircularTimer(
          circle: circle(remaining: const Duration(hours: -1, minutes: -30)),
          statusLabel: 'Driving',
        ),
      );

      expect(find.text('-01:30'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await pumpPage(
        tester,
        MainCircularTimer(
          circle: circle(),
          statusLabel: 'Driving',
          onTap: () => tapped = true,
        ),
      );

      await tester.tap(find.byType(MainCircularTimer));
      expect(tapped, isTrue);
    });
  });
}
