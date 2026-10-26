import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/presentation/mappers/inspection_preview_event_mapper.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

void main() {
  group('InspectionPreviewEventMapper', () {
    test('formatEventTime formats correctly into Mmm dd, hh:mm:ss am/pm', () {
      final dt = DateTime(2026, 8, 8, 16, 20, 32);
      final formatted = InspectionPreviewEventMapper.formatEventTime(dt);
      expect(formatted, 'Aug 08, 04:20:32 pm');

      final morningDt = DateTime(2026, 1, 5, 4, 5, 9);
      final morningFormatted = InspectionPreviewEventMapper.formatEventTime(
        morningDt,
      );
      expect(morningFormatted, 'Jan 05, 04:05:09 am');
    });

    testWidgets('toTableRow correctly maps LogEvent to EldTableRow', (
      tester,
    ) async {
      late BuildContext ctx;

      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              ctx = context;
              return const Placeholder();
            },
          ),
        ),
      );

      final event = LogEvent(
        id: 'ev-1',
        startTime: DateTime(2026, 8, 8, 16, 20, 32),
        duration: const Duration(hours: 1),
        status: 'D',
        location: 'Rolla, MO',
        odometer: 1460769.0,
        engineHours: 454.4,
        automatedDriving: true,
      );

      final row = InspectionPreviewEventMapper.toTableRow(event, ctx);

      expect(row.time, 'Aug 08, 04:20:32 pm');
      expect(row.status, 'Driving');
      expect(row.location, 'Rolla, MO');
      expect(row.odom, '1460769');
      expect(row.eng, '454.4');
      expect(row.src, 'Auto');
    });

    test(
      'filterEvents returns only active duty statuses when showActiveOnly is true',
      () {
        final events = [
          LogEvent(
            id: 'ev-1',
            startTime: DateTime(2026, 8, 8, 10, 0),
            duration: const Duration(hours: 1),
            status: 'D',
            location: 'Loc 1',
          ),
          LogEvent(
            id: 'ev-2',
            startTime: DateTime(2026, 8, 8, 11, 0),
            duration: const Duration(hours: 1),
            status: 'CERT',
            location: 'Loc 2',
          ),
          LogEvent(
            id: 'ev-3',
            startTime: DateTime(2026, 8, 8, 12, 0),
            duration: const Duration(hours: 1),
            status: 'ON',
            location: 'Loc 3',
          ),
        ];

        final filtered = InspectionPreviewEventMapper.filterEvents(
          events,
          showActiveOnly: true,
        );
        expect(filtered.length, 2);
        expect(filtered.map((e) => e.status), containsAll(['D', 'ON']));

        final all = InspectionPreviewEventMapper.filterEvents(
          events,
          showActiveOnly: false,
        );
        expect(all.length, 3);
      },
    );
  });
}
