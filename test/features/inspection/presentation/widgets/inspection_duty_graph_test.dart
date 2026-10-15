import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/widgets/eld_graph_grid.dart';
import 'package:golden_feather_eld/domain/inspection/dot_inspection.dart';
import 'package:golden_feather_eld/features/inspection/presentation/widgets/inspection_duty_graph.dart';

void main() {
  DotInspectionEvent makeEvent({
    required int seq,
    required String timeEt,
    required String code,
  }) {
    return DotInspectionEvent(
      sequenceNumber: seq,
      timeEt: timeEt,
      eventCode: code,
      eventType: 'DUTY_STATUS',
      description: code,
      location: 'Test Location',
      odometer: 1000.0,
      engineHours: 50.0,
      origin: 'MANUAL',
      notes: '',
      certificationEvent: false,
    );
  }

  group('InspectionDutyGraph', () {
    testWidgets('renders fallback 24-hour OFF line when events are empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: InspectionDutyGraph(events: []),
          ),
        ),
      );

      final grid = tester.widget<EldGraphGrid>(find.byType(EldGraphGrid));
      expect(grid.points.length, 1);
      expect(grid.points.first.startHour, 0.0);
      expect(grid.points.first.endHour, 24.0);
      expect(grid.points.first.status, 'OFF');
    });

    testWidgets('parses live server formats with ET and Arabic notes', (tester) async {
      final events = [
        makeEvent(seq: 1, timeEt: '12:00 AM ET (السابق)', code: 'ON'),
        makeEvent(seq: 2, timeEt: '01:01 AM ET', code: 'D'),
        makeEvent(seq: 3, timeEt: '06:30 AM ET', code: 'OFF'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InspectionDutyGraph(events: events),
          ),
        ),
      );

      final grid = tester.widget<EldGraphGrid>(find.byType(EldGraphGrid));
      expect(grid.points.length, 3);
      
      // Point 1: 12:00 AM -> 0.0 to 1.01667 (ON)
      expect(grid.points[0].startHour, 0.0);
      expect(grid.points[0].status, 'ON');

      // Point 2: 01:01 AM -> 1.01667 to 6.5 (D)
      expect(grid.points[1].startHour, closeTo(1.016, 0.01));
      expect(grid.points[1].status, 'D');

      // Point 3: 06:30 AM -> 6.5 to 24.0 (OFF)
      expect(grid.points[2].startHour, 6.5);
      expect(grid.points[2].endHour, 24.0);
      expect(grid.points[2].status, 'OFF');
    });

    testWidgets('parses 24h formats with milliseconds and 4-digit compacted', (tester) async {
      final events = [
        makeEvent(seq: 1, timeEt: '00:00:00.000', code: 'SB'),
        makeEvent(seq: 2, timeEt: '14:45', code: 'D'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InspectionDutyGraph(events: events),
          ),
        ),
      );

      final grid = tester.widget<EldGraphGrid>(find.byType(EldGraphGrid));
      expect(grid.points.length, 2);
      expect(grid.points[0].startHour, 0.0);
      expect(grid.points[0].status, 'SB');
      expect(grid.points[1].startHour, closeTo(14.75, 0.01));
      expect(grid.points[1].status, 'D');
    });
  });
}
