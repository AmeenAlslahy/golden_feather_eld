import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/suggested_events_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/log_detail_tab_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/suggested_log_card.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

class _FakeLogsNotifier extends StateNotifier<LogsState>
    implements LogsNotifier {
  DailyLog? lastSelected;

  _FakeLogsNotifier(super.state);

  @override
  void selectLog(DailyLog log) {
    lastSelected = log;
    state = state.copyWith(selectedLog: log);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

DailyLog _makeLog({
  required int id,
  DateTime? date,
  bool requiresAction = false,
  CertificationStatus certificationStatus = CertificationStatus.certified,
}) {
  return DailyLog(
    id: DailyLogId(id),
    date: date ?? DateTime(2026, 10, 24),
    totalDrivingHours: 4.5,
    isFormComplete: true,
    isCertified: certificationStatus == CertificationStatus.certified,
    requiresAction: requiresAction,
    certificationStatus: certificationStatus,
  );
}

void main() {
  testWidgets('SuggestedEventsPage renders empty state when no pending logs', (
    tester,
  ) async {
    final normalLog = _makeLog(id: 1);
    final notifier = _FakeLogsNotifier(LogsState(logs: [normalLog]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [logsProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(
          themeMode: ThemeMode.light,
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SuggestedEventsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Suggested Events'), findsOneWidget);
    expect(find.byType(SuggestedLogCard), findsNothing);
    expect(
      find.textContaining('Unidentified driving is reviewed in Unidentified'),
      findsOneWidget,
    );
  });

  testWidgets('SuggestedEventsPage renders SuggestedLogCards and handles tap', (
    tester,
  ) async {
    final recertLog = _makeLog(
      id: 10,
      certificationStatus: CertificationStatus.reCertificationRequired,
    );
    final carrierEditLog = _makeLog(
      id: 20,
      requiresAction: true,
      certificationStatus: CertificationStatus.certified,
    );

    final notifier = _FakeLogsNotifier(
      LogsState(logs: [recertLog, carrierEditLog]),
    );

    final router = GoRouter(
      initialLocation: '/suggested',
      routes: [
        GoRoute(
          path: '/suggested',
          builder: (_, __) => const SuggestedEventsPage(),
        ),
        GoRoute(
          path: '/logs/:id',
          builder: (_, state) =>
              Text('Log Detail ${state.pathParameters['id']}'),
        ),
      ],
    );

    late ProviderContainer container;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [logsProvider.overrideWith((ref) => notifier)],
        child: Consumer(
          builder: (context, ref, _) {
            container = ProviderScope.containerOf(context);
            return MaterialApp.router(
              theme: AppTheme.light,
              locale: const Locale('en'),
              supportedLocales: AppLocalizations.supportedLocales,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              routerConfig: router,
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SuggestedLogCard), findsNWidgets(2));
    expect(find.textContaining('Re-certification Required'), findsWidgets);
    expect(find.text('Carrier proposed edit'), findsOneWidget);

    // Tap on the first card
    await tester.tap(find.byType(SuggestedLogCard).first);
    await tester.pumpAndSettle();

    // Check that selectLog was called
    expect(notifier.lastSelected?.id.value, 10);
    // Check that tab was set to certify
    expect(container.read(logDetailTabProvider), LogDetailTab.certify.index);
    // Check navigation succeeded
    expect(find.text('Log Detail 10'), findsOneWidget);
  });

  testWidgets('SuggestedEventsPage renders loading state when isLoading is true', (
    tester,
  ) async {
    final notifier = _FakeLogsNotifier(
      const LogsState(isLoading: true, logs: []),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [logsProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SuggestedEventsPage(),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('SuggestedEventsPage renders error state and triggers retry', (
    tester,
  ) async {
    final notifier = _FakeLogsNotifier(
      const LogsState(error: 'Failed to load logs from server', logs: []),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [logsProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(
          locale: Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SuggestedEventsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Failed to load logs from server'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });

  testWidgets('SuggestedEventsPage renders Arabic localized dates in Arabic UI', (
    tester,
  ) async {
    final recertLog = _makeLog(
      id: 10,
      date: DateTime(2026, 10, 24),
      certificationStatus: CertificationStatus.reCertificationRequired,
    );
    final notifier = _FakeLogsNotifier(LogsState(logs: [recertLog]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [logsProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(
          locale: Locale('ar'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SuggestedEventsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('الأحداث المقترحة'), findsOneWidget);
    expect(find.textContaining('يلزم إعادة الاعتماد'), findsWidgets);
    expect(find.byType(SuggestedLogCard), findsOneWidget);
  });

  testWidgets('SuggestedEventsPage renders Spanish localized dates in Spanish UI', (
    tester,
  ) async {
    final carrierLog = _makeLog(
      id: 20,
      date: DateTime(2026, 10, 24),
      requiresAction: true,
      certificationStatus: CertificationStatus.certified,
    );
    final notifier = _FakeLogsNotifier(LogsState(logs: [carrierLog]));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [logsProvider.overrideWith((ref) => notifier)],
        child: const MaterialApp(
          locale: Locale('es'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: SuggestedEventsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Eventos sugeridos'), findsOneWidget);
    expect(find.text('Carrier propuso la edición'), findsOneWidget);
    expect(find.byType(SuggestedLogCard), findsOneWidget);
  });

  testWidgets('SuggestedEventsPage responsive layouts 320dp and 2.0x scale', (
    tester,
  ) async {
    final recertLog = _makeLog(
      id: 10,
      date: DateTime(2026, 10, 24),
      certificationStatus: CertificationStatus.reCertificationRequired,
    );
    final notifier = _FakeLogsNotifier(LogsState(logs: [recertLog]));

    tester.view.physicalSize = const Size(640, 1400); // 320 x 700 at 2.0 DPR
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [logsProvider.overrideWith((ref) => notifier)],
        child: const MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2.0)),
          child: MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: SuggestedEventsPage(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SuggestedLogCard), findsOneWidget);
  });
}

