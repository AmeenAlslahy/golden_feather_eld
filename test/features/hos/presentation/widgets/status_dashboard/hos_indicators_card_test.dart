import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_dashboard/hos_indicators_card.dart';

import '../../../../helpers/pump_page.dart';

void main() {
  const indicators = HosIndicators(
    drive: HosIndicator(
      label: 'DRIVE',
      value: Duration(hours: 2, minutes: 23),
      type: IndicatorType.used,
    ),
    shift: HosIndicator(
      label: 'SHIFT',
      value: Duration(hours: 5, minutes: 23),
      type: IndicatorType.used,
    ),
    breakTime: HosIndicator(
      label: 'BREAK',
      value: Duration(minutes: 30),
      type: IndicatorType.remaining,
    ),
    cycle: HosIndicator(
      label: 'CYCLE',
      value: Duration(hours: 61, minutes: 23),
      type: IndicatorType.used,
    ),
  );

  group('HosIndicatorsCard', () {
    testWidgets('renders all 4 labels', (tester) async {
      await pumpPage(tester, const HosIndicatorsCard(indicators: indicators));

      expect(find.text('DRIVE'), findsOneWidget);
      expect(find.text('SHIFT'), findsOneWidget);
      expect(find.text('BREAK'), findsOneWidget);
      expect(find.text('CYCLE'), findsOneWidget);
    });

    testWidgets('renders durations in HH:MM', (tester) async {
      await pumpPage(tester, const HosIndicatorsCard(indicators: indicators));

      expect(find.text('02:23'), findsOneWidget);
      expect(find.text('05:23'), findsOneWidget);
      expect(find.text('00:30'), findsOneWidget);
      expect(find.text('61:23'), findsOneWidget);
    });

    testWidgets('renders "Used" for used type', (tester) async {
      await pumpPage(tester, const HosIndicatorsCard(indicators: indicators));

      expect(find.text('Used'), findsNWidgets(3));
    });

    testWidgets('renders "Remaining" for remaining type', (tester) async {
      await pumpPage(tester, const HosIndicatorsCard(indicators: indicators));

      expect(find.text('Remaining'), findsOneWidget);
    });
  });
}
