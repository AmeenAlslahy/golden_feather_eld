import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/eld_retry_view.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/logs_list_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _MockLogRepository extends Mock implements LogRepository {}

/// SRS 5.1 — the daily log list: the server `today` marker, Form / Certify
/// chips (original single-row layout), and the retry path when the request
/// fails. `requiresAction` is not an SRS 5.1 list element and is not rendered.
void main() {
  late _MockLogRepository repo;

  setUp(() => repo = _MockLogRepository());

  DailyLog log({
    required int id,
    required DateTime date,
    bool today = false,
    bool requiresAction = false,
    bool form = false,
    bool certified = false,
    String work = '',
  }) =>
      DailyLog(
        id: DailyLogId(id),
        date: date,
        formattedTotalWorkTime: work,
        totalDrivingHours: 0,
        isFormComplete: form,
        isCertified: certified,
        today: today,
        requiresAction: requiresAction,
      );

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          logRepositoryProvider.overrideWithValue(repo),
          currentDriverIdProvider.overrideWithValue(106),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const LogsListPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders server rows with the Today marker and chips',
      (tester) async {
    when(() => repo.getDailyLogs(
          driverId: any(named: 'driverId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => Right([
          log(
            id: 2,
            date: DateTime(2026, 9, 24),
            today: true,
            work: '3h 15m',
          ),
          log(
            id: 1,
            date: DateTime(2026, 9, 23),
            requiresAction: true,
            form: true,
            certified: true,
          ),
        ]));

    await pump(tester);

    expect(find.text('Logs'), findsOneWidget);
    // The row renders the marker as 'Today - <date>'.
    expect(find.textContaining('Today'), findsOneWidget);
    // Not part of the SRS 5.1 row design — must not be rendered.
    expect(find.text('Action'), findsNothing);
    expect(find.text('3h 15m'), findsOneWidget);
    expect(find.text('Form'), findsNWidgets(2));
    expect(find.text('Certify'), findsNWidgets(2));
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(2));
    // Only the first page is requested, with the signed-in driver.
    verify(() => repo.getDailyLogs(driverId: 106, limit: 20, offset: 0))
        .called(1);
  });

  testWidgets('empty list shows No Records with a retry affordance',
      (tester) async {
    when(() => repo.getDailyLogs(
          driverId: any(named: 'driverId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async => const Right([]));

    await pump(tester);

    expect(find.text('No Records'), findsOneWidget);
    expect(find.byType(EldRetryView), findsOneWidget);
  });

  testWidgets('failure shows a sanitized message and retry reloads',
      (tester) async {
    var calls = 0;
    when(() => repo.getDailyLogs(
          driverId: any(named: 'driverId'),
          limit: any(named: 'limit'),
          offset: any(named: 'offset'),
        )).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        return const Left(ServerFailure(
          message:
              'DioException [bad response]: Hibernate could not extract ResultSet extension',
          statusCode: 500,
        ));
      }
      return Right([log(id: 1, date: DateTime(2026, 9, 23))]);
    });

    await pump(tester);

    // Raw Dio / Hibernate text must never reach the driver.
    expect(find.textContaining('Dio'), findsNothing);
    expect(find.textContaining('Hibernate'), findsNothing);
    expect(
      find.text(
          'The request could not be completed. Check the network and try again.'),
      findsOneWidget,
    );

    await tester.tap(find.descendant(
      of: find.byType(EldRetryView),
      matching: find.byType(IconButton),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(calls, 2);
    expect(find.byType(EldRetryView), findsNothing);
    expect(find.text('Form'), findsOneWidget);
  });
}
