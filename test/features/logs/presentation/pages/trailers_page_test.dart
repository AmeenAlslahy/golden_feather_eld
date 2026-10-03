import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/logs/domain/daily_form_rules.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_form_update.dart';
import 'package:golden_feather_eld/features/logs/domain/saved_form_status.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/shipping_documents_page.dart';
import 'package:golden_feather_eld/features/logs/data/providers/log_repository_providers.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/trailers_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/log_detail_tabs/form_tab.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class _Repo extends Mock implements LogRepository {}

class _MockLoc extends Mock implements AppLocalizations {}

/// SRS 5.5–5.13 — trailers / shipping documents are edited on their pages,
/// stored once on the dashboard form state, and sent by the Form SAVE.
void main() {
  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
    registerFallbackValue(DateTime(2026));
    registerFallbackValue(const DailyFormUpdate(vehicleUniqueId: '', trailers: [], shippingDocuments: []));
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
      final loc = _MockLoc();
      when(
        () => loc.enterTrailerNumber,
      ).thenReturn('Enter the trailer number.');
      when(() => loc.trailerNumberFormatError).thenReturn(
        'Trailer number must be letters, numbers, or hyphens (max 50).',
      );
      when(
        () => loc.enterDocumentNumber,
      ).thenReturn('Enter the document number.');
      when(
        () => loc.documentNumberTooLong,
      ).thenReturn('Shipping document number is too long (max 100).');
      when(
        () => loc.oneDocumentAtATime,
      ).thenReturn('Enter one document at a time (no comma).');
      when(() => loc.trailers).thenReturn('Trailers');
      when(() => loc.typeHere).thenReturn('Type here');
      when(() => loc.addButton).thenReturn('ADD');
      when(() => loc.deleteButton).thenReturn('DELETE');
      when(() => loc.noTrailersAdded).thenReturn('No trailers added');
      when(() => loc.shippingDocuments).thenReturn('Shipping Documents');
      when(() => loc.noDocumentsAdded).thenReturn('No documents added');

      expect(trailerNumberError('TR-1402', loc), isNull);
      expect(trailerNumberError('TR 1402', loc), isNotNull);
      expect(trailerNumberError('', loc), isNotNull);
      expect(trailerNumberError('a' * 51, loc), isNotNull);
      expect(shippingDocumentError('BOL 2026/01', loc), isNull);
      expect(shippingDocumentError('a,b', loc), isNotNull);
      expect(shippingDocumentError('a' * 101, loc), isNotNull);
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

    final container = ProviderContainer(
      overrides: [
        dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
        ...overrides,
      ],
    );
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

  testWidgets('Trailers page starts empty and writes to the form state', (
    tester,
  ) async {
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

    await tester.tap(find.text('Delete').first);
    await tester.pumpAndSettle();
    expect(find.text('TR-1402'), findsNothing);
    expect(container.read(dashboardDataProvider).trailerId, 'AB12');

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(container.read(dashboardDataProvider).trailerId, 'None');
    expect(find.text('No trailers added'), findsOneWidget);
  });

  testWidgets('Shipping Documents page writes to the form state', (
    tester,
  ) async {
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

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(container.read(dashboardDataProvider).shippingDocuments, 'None');
  });

  group('Form tab SAVE', () {
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
      repo = _Repo();
      // selectLog now loads the day's events (SRS 5.2); the Form tab does
      // not need them, so answer with an empty list.
      when(
        () => repo.getEvents(any(), any()),
      ).thenAnswer((_) async => const Right([]));
    });

    List<Override> overrides() => [
      logRepositoryProvider.overrideWithValue(repo),
      logsProvider.overrideWith((ref) => LogsNotifier(repo, null)),
    ];

    testWidgets('sends every trailer and shipping document from the pages', (
      tester,
    ) async {
      when(
        () => repo.saveForm(
          logId: any(named: 'logId'),
          form: any(named: 'form'),
        ),
      ).thenAnswer(
        (_) async => const Right(
          FormSaveResult.online(
            SavedFormRead(formStatus: 'COMPLETED', complete: true),
          ),
        ),
      );

      final container = await pump(
        tester,
        const Scaffold(body: FormTab()),
        overrides: overrides(),
      );
      container.read(logsProvider.notifier).selectLog(log);
      container.read(dashboardDataProvider.notifier).updateTrailers([
        'TR-1402',
        'AB12',
      ]);
      container.read(dashboardDataProvider.notifier).updateShippingDocuments([
        'BOL 2026/09-1',
      ]);
      await tester.pumpAndSettle();

      // The Form tab shows the same values the SAVE will send.
      expect(find.text('TR-1402, AB12'), findsOneWidget);
      expect(find.text('BOL 2026/09-1'), findsOneWidget);

      await tester.ensureVisible(find.text('SAVE'));
      await tester.tap(find.text('SAVE'));
      await tester.pumpAndSettle();

      final captured =
          verify(
                () => repo.saveForm(
                  logId: const DailyLogId(42),
                  form: captureAny(named: 'form'),
                ),
              ).captured.single
              as DailyFormUpdate;
      expect(captured.trailers, ['TR-1402', 'AB12']);
      expect(captured.shippingDocuments, ['BOL 2026/09-1']);
      expect(find.text('server.500'), findsNothing);
      // Pump past the AppFeedback auto-dismiss timer (3s).
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('server failure is shown sanitized, never the raw code', (
      tester,
    ) async {
      when(
        () => repo.saveForm(
          logId: any(named: 'logId'),
          form: any(named: 'form'),
        ),
      ).thenAnswer(
        (_) async => const Left(ServerFailure(message: 'server.500')),
      );

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
      // Feedback now renders as the AppFeedback top overlay.
      expect(find.byType(SnackBar), findsNothing);
      expect(find.textContaining('server.'), findsNothing);
      await settleSnackBar(tester);
    });
  });
}
