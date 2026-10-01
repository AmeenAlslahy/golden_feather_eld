import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/log_detail_tabs/events_tab.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements LogRepository {}

/// SRS 5.2 / 49 CFR §395.30(b) — the pencil is offered only on events the
/// driver may edit (manual ON/OFF/SB); automatically recorded driving and
/// server-locked events show no edit affordance at all.
void main() {
  LogEvent ev(String id, String status,
          {bool? automated, bool? editable}) =>
      LogEvent(
        id: id,
        status: status,
        startTime: DateTime(2026, 9, 24, 8),
        duration: const Duration(minutes: 30),
        location: 'Reno, NV',
        automatedDriving: automated,
        editable: editable,
      );

  Future<void> pump(WidgetTester tester, DailyLog log) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logsProvider.overrideWith((ref) => LogsNotifier(_Repo(), null)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: EventsTab(selectedLog: log)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('automatic driving has no pencil; manual events do',
      (tester) async {
    final log = DailyLog(
      id: const DailyLogId(1),
      date: DateTime(2026, 9, 24),
      totalDrivingHours: 1,
      isFormComplete: false,
      isCertified: false,
      events: [
        ev('1', 'OFF'),
        ev('2', 'D', automated: true, editable: false),
        ev('3', 'ON', editable: true),
      ],
    );
    await pump(tester, log);

    // Two editable events → two pencils; the automatic DRIVING row has none.
    expect(find.byIcon(Icons.edit), findsNWidgets(2));
  });

  testWidgets('hour totals per status are shown under the graph (SRS 5.2)',
      (tester) async {
    final log = DailyLog(
      id: const DailyLogId(1),
      date: DateTime(2026, 9, 24),
      totalDrivingHours: 1,
      isFormComplete: false,
      isCertified: false,
      events: [
        LogEvent(
          id: '1',
          status: 'OFF',
          // Started the evening before → the start date is shown.
          startTime: DateTime(2026, 9, 23, 22),
          duration: const Duration(hours: 8),
          location: '',
        ),
        ev('2', 'D', automated: true, editable: false),
        LogEvent(
          id: '3',
          status: 'PC',
          startTime: DateTime(2026, 9, 24, 12),
          duration: const Duration(minutes: 45),
          location: '',
        ),
      ],
    );
    await pump(tester, log);

    final totals = find.byKey(const Key('events_status_totals'));
    Finder inTotals(String t) => find.descendant(of: totals, matching: find.text(t));
    expect(inTotals('8h 45m'), findsOneWidget); // OFF + PC
    expect(inTotals('0h 30m'), findsOneWidget); // D
    expect(inTotals('0h 00m'), findsNWidgets(2)); // SB, ON
    // The OFF event starts the evening before the log date — the tile
    // marks the other-day start next to the duration.
    expect(find.text('Started: 9/23/2026'), findsOneWidget);
  });

  testWidgets('server-locked manual event has no pencil either',
      (tester) async {
    final log = DailyLog(
      id: const DailyLogId(1),
      date: DateTime(2026, 9, 24),
      totalDrivingHours: 0,
      isFormComplete: false,
      isCertified: true,
      events: [ev('1', 'SB', editable: false)],
    );
    await pump(tester, log);
    expect(find.byIcon(Icons.edit), findsNothing);
  });
}
