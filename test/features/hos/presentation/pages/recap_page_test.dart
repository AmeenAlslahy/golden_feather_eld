import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/hos/data/providers/status_dashboard_repository_providers.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/eld_retry_view.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart';
import 'package:golden_feather_eld/domain/duty_status/weekly_recap.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/repositories/status_dashboard_repository.dart';
import 'package:golden_feather_eld/features/hos/presentation/pages/recap_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements StatusDashboardRepository {}

class _AuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _AuthNotifier()
      : super(
          AuthState(
            status: AuthStatus.authenticated,
            user: User(
              id: '106',
              username: 'driver106',
              email: 'driver106@test.com',
              fullName: 'Driver 106',
              role: UserRole.fieldWorker,
              createdAt: DateTime(2026),
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// SRS 2.3 Recap — 7-day table + totals from the server recap, decimal
/// hours, retry on failure, fully localized rows.
void main() {
  late _Repo repo;

  setUp(() => repo = _Repo());

  WeeklyRecap recap() {
    final today = DateTime.now();
    RecapDay day(int back, int minutes) => RecapDay(
          date: today.subtract(Duration(days: back)),
          dayOfWeek: back == 0 ? 'Today' : 'Day-$back',
          driving: Duration(minutes: minutes ~/ 2),
          onDuty: Duration(minutes: minutes ~/ 2),
          totalWork: Duration(minutes: minutes),
        );
    return WeeklyRecap(
      cycleRule: CycleRule.usa70_8,
      cycleUsed: const Duration(hours: 41, minutes: 30),
      cycleRemaining: const Duration(hours: 28, minutes: 30),
      availableTomorrow: const Duration(hours: 36, minutes: 15),
      days: [for (var i = 6; i >= 0; i--) day(i, i == 0 ? 195 : 480)],
    );
  }

  Future<void> pump(WidgetTester tester, {Locale locale = const Locale('en')}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          statusDashboardRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith((ref) => _AuthNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const Scaffold(body: RecapPage()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('renders 7 days, cycle totals and today/tomorrow availability',
      (tester) async {
    when(() => repo.getWeeklyRecap(driverId: any(named: 'driverId')))
        .thenAnswer((_) async => Right(recap()));
    await pump(tester);

    for (var i = 1; i <= 6; i++) {
      expect(find.text('Day-$i'), findsOneWidget);
    }
    expect(find.text('08.00'), findsNWidgets(6));
    // Today's total appears twice: in the table and as "Hours Worked Today".
    expect(find.text('03.25'), findsNWidgets(2));
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Last 7 Days'), findsOneWidget);
    expect(find.text('41.50'), findsOneWidget);
    expect(find.text('Hours Worked Today'), findsOneWidget);
    expect(find.text('Hours Available Today'), findsOneWidget);
    expect(find.text('28.50'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Hours Available Tomorrow'), 200,
        scrollable: find.byType(Scrollable));
    expect(find.text('Hours Available Tomorrow'), findsOneWidget);
    expect(find.text('36.25'), findsOneWidget);
  });

  testWidgets('Arabic locale has no leftover English row titles', (tester) async {
    when(() => repo.getWeeklyRecap(driverId: any(named: 'driverId')))
        .thenAnswer((_) async => Right(recap()));
    await pump(tester, locale: const Locale('ar'));

    expect(find.text('Total'), findsNothing);
    expect(find.text('Last 7 Days'), findsNothing);
    expect(find.text('Hours Worked Today'), findsNothing);
    expect(find.text('Hours Available Today'), findsNothing);
    expect(find.text('الإجمالي'), findsOneWidget);
    expect(find.text('آخر 7 أيام'), findsOneWidget);
    expect(find.text('ساعات العمل اليوم'), findsOneWidget);
    expect(find.text('الساعات المتاحة اليوم'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('الساعات المتاحة غداً'), 200,
        scrollable: find.byType(Scrollable));
    expect(find.text('الساعات المتاحة غداً'), findsOneWidget);
  });

  testWidgets('no cache + no server → explicit unavailable, no fake numbers',
      (tester) async {
    when(() => repo.getWeeklyRecap(driverId: any(named: 'driverId')))
        .thenAnswer((_) async => const Left(NoRecapSnapshotFailure()));
    await pump(tester);

    expect(find.text('No data'), findsOneWidget);
    expect(find.byType(EldRetryView), findsNothing);
    // The old synthesized recap always showed 8.00 available tomorrow.
    expect(find.text('Hours Available Tomorrow'), findsNothing);
    expect(find.text('8.00'), findsNothing);
  });

  testWidgets('failure → sanitized retry view, retry re-queries the server',
      (tester) async {
    var calls = 0;
    when(() => repo.getWeeklyRecap(driverId: any(named: 'driverId')))
        .thenAnswer((_) async {
      calls++;
      return calls == 1
          ? const Left(ServerFailure(message: 'DioException Hibernate', statusCode: 500))
          : Right(recap());
    });
    await pump(tester);

    expect(find.byType(EldRetryView), findsOneWidget);
    expect(find.textContaining('Dio'), findsNothing);

    await tester.tap(find.byIcon(Icons.refresh));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(calls, 2);
    expect(find.byType(EldRetryView), findsNothing);
    expect(find.text('Total'), findsOneWidget);
  });

  testWidgets('empty days renders localized noData text', (tester) async {
    when(() => repo.getWeeklyRecap(driverId: any(named: 'driverId')))
        .thenAnswer((_) async => const Right(
              WeeklyRecap(
                cycleRule: CycleRule.usa70_8,
                cycleUsed: Duration.zero,
                cycleRemaining: Duration(hours: 70),
                availableTomorrow: Duration(hours: 70),
                days: [],
              ),
            ));
    await pump(tester);
    expect(find.text('No data'), findsOneWidget);
  });

  testWidgets('renders onDuty hours when totalWork is zero (server only sends onDuty)', (tester) async {
    final today = DateTime.now();
    final r = WeeklyRecap(
      cycleRule: CycleRule.usa70_8,
      cycleUsed: const Duration(hours: 10),
      cycleRemaining: const Duration(hours: 60),
      availableTomorrow: const Duration(hours: 10),
      days: [
        RecapDay(
          date: today,
          dayOfWeek: 'Today',
          onDuty: const Duration(hours: 6),
          totalWork: Duration.zero,
        ),
      ],
    );

    when(() => repo.getWeeklyRecap(driverId: any(named: 'driverId')))
        .thenAnswer((_) async => Right(r));
    await pump(tester);

    expect(find.text('06.00'), findsNWidgets(2)); // in table row and in "Hours Worked Today"
  });
}
