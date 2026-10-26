import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/widgets/eld_card.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/theme/app_radius.dart';

void main() {
  group('RND-002: EldCard Clipping Investigation & Optimization', () {
    testWidgets('1. EldCard defaults to Clip.none to avoid unnecessary canvas clipping', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: EldCard(
              child: Text('Card Content'),
            ),
          ),
        ),
      );

      final cardFinder = find.byType(Card);
      expect(cardFinder, findsOneWidget);

      final cardWidget = tester.widget<Card>(cardFinder);
      expect(cardWidget.clipBehavior, Clip.none);
    });

    testWidgets('2. EldCard accepts explicit clipBehavior when caller requires clipping', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: EldCard(
              clipBehavior: Clip.antiAlias,
              child: Text('Clipped Content'),
            ),
          ),
        ),
      );

      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.clipBehavior, Clip.antiAlias);
    });

    testWidgets('3. EldCard preserves RoundedRectangleBorder with AppRadius.card', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: EldCard(
              child: Text('Border Radius Check'),
            ),
          ),
        ),
      );

      final cardWidget = tester.widget<Card>(find.byType(Card));
      expect(cardWidget.shape, isA<RoundedRectangleBorder>());
      final shape = cardWidget.shape as RoundedRectangleBorder;
      expect(shape.borderRadius, BorderRadius.circular(AppRadius.card));
    });

    testWidgets('4. EldCard InkWell handles tap and preserves borderRadius', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: EldCard(
              onTap: () => tapped = true,
              child: const Text('Tappable Card'),
            ),
          ),
        ),
      );

      final inkWellFinder = find.byType(InkWell);
      expect(inkWellFinder, findsOneWidget);

      final inkWell = tester.widget<InkWell>(inkWellFinder);
      expect(inkWell.borderRadius, BorderRadius.circular(AppRadius.card));

      await tester.tap(inkWellFinder);
      await tester.pump();

      expect(tapped, isTrue);
    });

    testWidgets('5. EldCard applies default and custom padding properly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: EldCard(
              padding: EdgeInsets.all(32),
              child: Text('Custom Padding'),
            ),
          ),
        ),
      );

      final paddingWidget = tester.widget<Padding>(
        find.descendant(of: find.byType(InkWell), matching: find.byType(Padding)),
      );
      expect(paddingWidget.padding, const EdgeInsets.all(32));
    });

    testWidgets('6. EldCard renders properly in RTL directionality', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: EldCard(
                child: Text('بطاقة تجريبية'),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(EldCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
