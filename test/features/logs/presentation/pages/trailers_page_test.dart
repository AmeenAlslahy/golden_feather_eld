import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/contracts/daily_logs_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/logs/domain/daily_form_rules.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/shipping_documents_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/trailers_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Logs extends Mock implements DailyLogsBackend {}

class _Repo extends Mock implements LogRepository {}

/// SRS 5.5–5.13 — trailers / shipping documents are edited on their pages,
/// stored once on the dashboard form state, and sent by the Form SAVE.
void main() {
  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
    registerFallbackValue(DateTime(2026));
  });

  group('daily_form_rules', () {
    test('split/join ignore placeholders and round-trip', () {
      expect(splitFormList(null), isEmpty);
      expect(splitFormList('None'), isEmpty);
      expect(splitFormList('-'), isEmpty);
      expect(splitFormList('TR-1, AB2 ,'), ['TR-1', 'AB2']);
      expect(joinFormList(const []), 'None');
      expect(joinFormList(const ['TR-1', 'AB2']), 'TR-1, AB2');
    });

    test('trailer and document rules', () {
      expect(trailerNumberError('TR-1402', isArabic: false), isNull);
      expect(trailerNumberError('TR 1402', isArabic: false), isNotNull);
      expect(trailerNumberError('', isArabic: false), isNotNull);
      expect(trailerNumberError('a' * 51, isArabic: false), isNotNull);
      expect(shippingDocumentError('BOL 2026/01', isArabic: false), isNull);
      expect(shippingDocumentError('a,b', isArabic: false), isNotNull);
      expect(shippingDocumentError('a' * 101, isArabic: false), isNotNull);
    });
  });

  Future<ProviderContainer> pump(
    WidgetTester tester,
    Widget home, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(overrides: [
      dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
      ...overrides,
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: home,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  Future<void> settleSnackBar(WidgetTester tester) async {
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  }

  testWidgets('Trailers page starts empty and writes to the form state',
      (tester) async {
    final container = await pump(tester, const TrailersPage());

    expect(find.text('Trailers'), findsOneWidget);
    expect(find.text('No trailers added'), findsOneWidget);
    expect(find.text('1402'), findsNothing); // no fake default

    await tester.enterText(find.byType(TextField), '  TR-1402 ');
    await tester.tap(find.text('ADD'));
    await tester.pumpAndSettle();

    expect(find.text('TR-1402'), findsOneWidget);
    expect(container.read(dashboardDataProvider).trailerId, 'TR-1402');

    // Invalid trailer number is refused with a message and not stored.
    await tester.enterText(find.byType(TextField), 'TR 9');
    await tester.tap(find.text('ADD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('letters, numbers, or hyphens'), findsOneWidget);
    expect(container.read(dashboardDataProvider).trailerId, 'TR-1402');
    await settleSnackBar(tester);

    await tester.enterText(find.byType(TextField), 'AB12');
    await tester.tap(find.text('ADD'));
    await tester.pumpAndSettle();
    expect(container.read(dashboardDataProvider).trailerId, 'TR-1402, AB12');

    await tester.tap(find.text('DELETE').first);
    await tester.pumpAndSettle();
    expect(find.text('TR-1402'), findsNothing);
    expect(container.read(dashboardDataProvider).trailerId, 'AB12');

    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();
    expect(container.read(dashboardDataProvider).trailerId, 'None');
    expect(find.text('No trailers added'), findsOneWidget);
  });

  testWidgets('Shipping Documents page writes to the form state',
      (tester) async {
    final container = await pump(tester, const ShippingDocumentsPage());

    expect(find.text('Shipping Documents'), findsOneWidget);
    expect(find.text('No documents added'), findsOneWidget);
    expect(find.text('BOL-2024-001'), findsNothing); // no fake default

    await tester.enterText(find.byType(TextField), 'BOL 2026/09-1');
    await tester.tap(find.text('ADD'));
    await tester.pumpAndSettle();
    expect(find.text('BOL 2026/09-1'), findsOneWidget);
    expect(
      container.read(dashboardDataProvider).shippingDocuments,
      'BOL 2026/09-1',
    );

    await tester.tap(find.text('DELETE'));
    await tester.pumpAndSettle();
    expect(container.read(dashboardDataProvider).shippingDocuments, 'None');
  });

  group('Form tab SAVE', () {
    late _Logs logs;
    late _Repo repo;
    final log = DailyLog(
      id: const DailyLogId(42),
      uniqueId: 'TRK-1',
      date: DateTime(2026, 9, 24),
      totalDrivingHours: 0,
      isFormComplete: false,
      isCertified: false,
    );

    setUp(() {
      logs = _Logs();
      repo = _Repo();
      // selectLog now loads the day's events (SRS 5.2); the Form tab does
      // not need them, so answer with an empty list.
      when(() => repo.getEvents(any(), any()))
          .thenAnswer((_) async => const Right([]));
    });

    List<Override> overrides() => [
          dailyLogsBackendProvider.overrideWithValue(logs),
          logsProvider.overrideWith((ref) => LogsNotifier(repo, null)),
        ];

    testWidgets('sends every trailer and shipping document from the pages',
        (tester) async {
      when(() => logs.saveForm(logId: any(named: 'logId'), form: any(named: 'form')))
          .thenAnswer((_) async => const Right({'formStatus': 'COMPLETED'}));

      final container = await pump(
        tester,
        const Scaffold(body: FormTab()),
        overrides: overrides(),
      );
      container.read(logsProvider.notifier).selectLog(log);
      container
          .read(dashboardDataProvider.notifier)
          .updateTrailers(['TR-1402', 'AB12']);
      container
          .read(dashboardDataProvider.notifier)
          .updateShippingDocuments(['BOL 2026/09-1']);
      await tester.pumpAndSettle();

      // The Form tab shows the same values the SAVE will send.
      expect(find.text('TR-1402, AB12'), findsOneWidget);
      expect(find.text('BOL 2026/09-1'), findsOneWidget);

      await tester.ensureVisible(find.text('SAVE'));
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      final captured = verify(() => logs.saveForm(
            logId: const DailyLogId(42),
            form: captureAny(named: 'form'),
          )).captured.single as Map<String, dynamic>;
      expect(captured['trailers'], [
        {'trailerNumber': 'TR-1402'},
        {'trailerNumber': 'AB12'},
      ]);
      expect(captured['shippingDocuments'], [
        {'documentNumber': 'BOL 2026/09-1'},
      ]);
      expect(find.text('server.500'), findsNothing);
    });

    testWidgets('server failure is shown sanitized, never the raw code',
        (tester) async {
      when(() => logs.saveForm(logId: any(named: 'logId'), form: any(named: 'form')))
          .thenAnswer((_) async => const Left(
                ServerError(code: 'server.500', statusCode: 500),
              ));

      final container = await pump(
        tester,
        const Scaffold(body: FormTab()),
        overrides: overrides(),
      );
      container.read(logsProvider.notifier).selectLog(log);
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('SAVE'));
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      expect(find.text('server.500'), findsNothing);
      expect(find.byType(SnackBar), findsOneWidget);
      final shown = tester.widget<SnackBar>(find.byType(SnackBar));
      expect((shown.content as Text).data, isNot(contains('server.')));
      await settleSnackBar(tester);
    });
  });
}
