import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/widgets/eld_graph_grid.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';

void main() {
  group('RND-001: EldGraphGrid Optimization & Repaint Tests', () {
    test('1. EldGraphPoint value equality and hashCode work correctly', () {
      const p1 = EldGraphPoint(
        startHour: 0.0,
        endHour: 8.5,
        status: 'OFF',
        tag: null,
        isDashed: false,
      );
      const p2 = EldGraphPoint(
        startHour: 0.0,
        endHour: 8.5,
        status: 'OFF',
        tag: null,
        isDashed: false,
      );
      const pDifferentStatus = EldGraphPoint(
        startHour: 0.0,
        endHour: 8.5,
        status: 'SB',
        tag: null,
        isDashed: false,
      );
      const pDifferentTag = EldGraphPoint(
        startHour: 0.0,
        endHour: 8.5,
        status: 'OFF',
        tag: 'PC',
        isDashed: false,
      );
      const pDifferentDashed = EldGraphPoint(
        startHour: 0.0,
        endHour: 8.5,
        status: 'OFF',
        tag: null,
        isDashed: true,
      );

      expect(p1, equals(p2));
      expect(p1.hashCode, equals(p2.hashCode));
      expect(p1, isNot(equals(pDifferentStatus)));
      expect(p1, isNot(equals(pDifferentTag)));
      expect(p1, isNot(equals(pDifferentDashed)));
    });

    testWidgets('2. EldGraphGrid wraps CustomPaint in a RepaintBoundary', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: EldGraphGrid(
              points: [
                EldGraphPoint(startHour: 0.0, endHour: 10.0, status: 'OFF'),
                EldGraphPoint(startHour: 10.0, endHour: 18.0, status: 'D'),
              ],
              rightSideStats: {'OFF': 10.0, 'SB': 0.0, 'D': 8.0, 'ON': 0.0},
              liveMarkerHour: 18.0,
            ),
          ),
        ),
      );

      // Verify that EldGraphGrid root or direct child is RepaintBoundary
      final repaintBoundaryFinder = find.descendant(
        of: find.byType(EldGraphGrid),
        matching: find.byType(RepaintBoundary),
      );
      expect(repaintBoundaryFinder, findsOneWidget);

      final customPaintFinder = find.descendant(
        of: repaintBoundaryFinder,
        matching: find.byType(CustomPaint),
      );
      expect(customPaintFinder, findsOneWidget);
    });

    testWidgets('3. CustomPaint painter suppresses repaint on identical data', (tester) async {
      final initialPoints = [
        const EldGraphPoint(startHour: 0.0, endHour: 8.0, status: 'OFF'),
        const EldGraphPoint(startHour: 8.0, endHour: 16.0, status: 'D'),
        const EldGraphPoint(startHour: 16.0, endHour: 24.0, status: 'ON'),
      ];
      final initialStats = {'OFF': 8.0, 'SB': 0.0, 'D': 8.0, 'ON': 8.0};

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: EldGraphGrid(
              points: initialPoints,
              rightSideStats: initialStats,
              liveMarkerHour: 16.5,
            ),
          ),
        ),
      );

      final customPaintWidget = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(EldGraphGrid),
          matching: find.byType(CustomPaint),
        ),
      );
      final initialPainter = customPaintWidget.painter as CustomPainter;

      // Pump with NEW list instance and NEW map instance containing identical values
      final clonedPoints = [
        const EldGraphPoint(startHour: 0.0, endHour: 8.0, status: 'OFF'),
        const EldGraphPoint(startHour: 8.0, endHour: 16.0, status: 'D'),
        const EldGraphPoint(startHour: 16.0, endHour: 24.0, status: 'ON'),
      ];
      final clonedStats = {'OFF': 8.0, 'SB': 0.0, 'D': 8.0, 'ON': 8.0};

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: EldGraphGrid(
              points: clonedPoints,
              rightSideStats: clonedStats,
              liveMarkerHour: 16.5,
            ),
          ),
        ),
      );

      final updatedPaintWidget = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(EldGraphGrid),
          matching: find.byType(CustomPaint),
        ),
      );
      final updatedPainter = updatedPaintWidget.painter as CustomPainter;

      // shouldRepaint must return FALSE because content is identical!
      expect(updatedPainter.shouldRepaint(initialPainter), isFalse);
    });

    testWidgets('4. CustomPaint painter repaints when points change', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: EldGraphGrid(
              points: [
                EldGraphPoint(startHour: 0.0, endHour: 8.0, status: 'OFF'),
              ],
            ),
          ),
        ),
      );

      final p1 = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(EldGraphGrid), matching: find.byType(CustomPaint)),
      ).painter!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: EldGraphGrid(
              points: [
                EldGraphPoint(startHour: 0.0, endHour: 8.0, status: 'OFF'),
                EldGraphPoint(startHour: 8.0, endHour: 14.0, status: 'D'),
              ],
            ),
          ),
        ),
      );

      final p2 = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(EldGraphGrid), matching: find.byType(CustomPaint)),
      ).painter!;

      expect(p2.shouldRepaint(p1), isTrue);
    });

    testWidgets('5. CustomPaint painter repaints when stats change', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: EldGraphGrid(
              points: [],
              rightSideStats: {'OFF': 8.0, 'D': 2.0},
            ),
          ),
        ),
      );

      final p1 = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(EldGraphGrid), matching: find.byType(CustomPaint)),
      ).painter!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: EldGraphGrid(
              points: [],
              rightSideStats: {'OFF': 8.0, 'D': 3.0},
            ),
          ),
        ),
      );

      final p2 = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(EldGraphGrid), matching: find.byType(CustomPaint)),
      ).painter!;

      expect(p2.shouldRepaint(p1), isTrue);
    });

    testWidgets('6. CustomPaint painter repaints when live marker changes', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: EldGraphGrid(
              points: [],
              liveMarkerHour: 10.0,
            ),
          ),
        ),
      );

      final p1 = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(EldGraphGrid), matching: find.byType(CustomPaint)),
      ).painter!;

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: EldGraphGrid(
              points: [],
              liveMarkerHour: 10.5,
            ),
          ),
        ),
      );

      final p2 = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(EldGraphGrid), matching: find.byType(CustomPaint)),
      ).painter!;

      expect(p2.shouldRepaint(p1), isTrue);
    });

    testWidgets('7. CustomPaint painter repaints when theme changes (light to dark)', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Theme(
              data: AppTheme.light,
              child: const EldGraphGrid(
                points: [],
              ),
            ),
          ),
        ),
      );

      final p1 = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(EldGraphGrid), matching: find.byType(CustomPaint)),
      ).painter!;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Theme(
              data: AppTheme.dark,
              child: const EldGraphGrid(
                points: [],
              ),
            ),
          ),
        ),
      );

      final p2 = tester.widget<CustomPaint>(
        find.descendant(of: find.byType(EldGraphGrid), matching: find.byType(CustomPaint)),
      ).painter!;

      expect(p2.shouldRepaint(p1), isTrue);
    });

    testWidgets('8. Graph renders cleanly in RTL and LTR directionality', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: EldGraphGrid(
                points: [
                  EldGraphPoint(startHour: 0.0, endHour: 5.0, status: 'OFF'),
                  EldGraphPoint(startHour: 5.0, endHour: 12.0, status: 'D', tag: 'PC', isDashed: true),
                ],
                rightSideStats: {'OFF': 5.0, 'SB': 0.0, 'D': 7.0, 'ON': 0.0},
                liveMarkerHour: 12.0,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(EldGraphGrid), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
