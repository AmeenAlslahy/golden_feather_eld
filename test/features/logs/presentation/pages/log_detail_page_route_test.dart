import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/eld_retry_view.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/log_events_snapshot.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log_page.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/log_detail_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/formatters/log_date_formatter.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements LogRepository {}

/// The detail route owns its day: `/logs/:id` must select that day even when
/// another (stale) day is still selected in shared state.
void main() {
  late _Repo repo;
  late ProviderContainer container;
  late MockAdapter adapter;

  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
    registerFallbackValue(DateTime(2026));
  });

  final newer = DailyLog(
    id: const DailyLogId(2),
    uniqueId: 'TRK-2',
    date: DateTime(2026, 9, 24),
    totalDrivingHours: 0,
    isFormComplete: true,
    isCertified: false,
  );
  final older = DailyLog(
    id: const DailyLogId(1),
    uniqueId: 'TRK-1',
    date: DateTime(2026, 9, 23),
    totalDrivingHours: 0,
    isFormComplete: true,
    isCertified: false,
  );

  setUp(() {
    repo = _Repo();
    adapter = MockAdapter();
    when(
      () => repo.getDailyLogs(
        driverId: any(named: 'driverId'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => Right(DailyLogPage(logs: [newer, older])));
    when(
      () => repo.getEvents(any(), any()),
    ).thenAnswer((_) async => const Right(LogEventsSnapshot.server([])));
    when(
      () => repo.getLogById(any()),
    ).thenAnswer((_) async => const Left(NetworkFailure()));
    when(() => repo.getForm(any())).thenAnswer((_) async => const Right(null));
    when(
      () => repo.getReadiness(any()),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'not used')));
    when(() => repo.getDraftSignature(any())).thenAnswer((_) async => null);
    when(() => repo.saveDraftSignature(any(), any())).thenAnswer((_) async {});
    when(() => repo.deleteDraftSignature(any())).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        activeBackendProvider.overrideWithValue(adapter),
        logRepositoryProvider.overrideWithValue(repo),
        currentDriverIdProvider.overrideWithValue(106),
        dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
      ],
    );
    addTearDown(container.dispose);
  });

  Future<void> pumpPage(WidgetTester tester, String logId) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: LogDetailPage(logId: logId),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('selects the route day even before the list has loaded', (
    tester,
  ) async {
    await pumpPage(tester, '2');

    expect(container.read(logsProvider).selectedLog?.id, newer.id);
    expect(find.text(newer.formattedDate), findsOneWidget);
    expect(find.text(older.formattedDate), findsNothing);
  });

  testWidgets('re-asserts the route day over a stale shared selection', (
    tester,
  ) async {
    await pumpPage(tester, '2');
    expect(container.read(logsProvider).selectedLog?.id, newer.id);

    container.read(logsProvider.notifier).selectLog(older);
    await tester.pumpAndSettle();

    expect(container.read(logsProvider).selectedLog?.id, newer.id);
    expect(find.text(newer.formattedDate), findsOneWidget);
  });

  testWidgets('pages forward until a deeper-linked day is found', (
    tester,
  ) async {
    when(
      () => repo.getDailyLogs(
        driverId: any(named: 'driverId'),
        page: 0,
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => Right(DailyLogPage(logs: [newer], hasNext: true)),
    );
    when(
      () => repo.getDailyLogs(
        driverId: any(named: 'driverId'),
        page: 1,
        size: any(named: 'size'),
      ),
    ).thenAnswer((_) async => Right(DailyLogPage(logs: [older])));

    await pumpPage(tester, '1');

    expect(container.read(logsProvider).selectedLog?.id, older.id);
    expect(find.text(older.formattedDate), findsOneWidget);
  });

  testWidgets('an unknown day stops loading and offers a retry', (
    tester,
  ) async {
    await pumpPage(tester, '999');

    expect(container.read(logsProvider).selectedLog, isNull);
    expect(find.byType(EldRetryView), findsOneWidget);
    verify(
      () => repo.getDailyLogs(
        driverId: any(named: 'driverId'),
        page: any(named: 'page'),
        size: any(named: 'size'),
      ),
    ).called(1);
  });
}
