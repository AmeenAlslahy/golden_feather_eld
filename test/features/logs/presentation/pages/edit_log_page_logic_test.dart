import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/audit_entry.dart';
import 'package:mocktail/mocktail.dart';
import 'package:golden_feather_eld/core/time/time_authority_provider.dart';
import 'package:golden_feather_eld/core/time/time_authority.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/edit_log_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/edit_log_form_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/data/providers/log_repository_providers.dart';

class MockLogsNotifier extends StateNotifier<LogsState>
    with Mock
    implements LogsNotifier {
  MockLogsNotifier(super.state);
}

class MockAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  MockAuthNotifier(super.state);

  @override
  Future<bool> login({
    required String username,
    required String password,
    String? serverUrl,
  }) async => true;
  @override
  void forceLogout() {}
  @override
  Future<void> logout() async {}
  @override
  Future<void> checkAuthStatus() async {}
  @override
  void clearError() {}
}

class MockTimeAuthority extends Mock implements TimeAuthority {}

class MockLogRepository extends Mock implements LogRepository {}

void main() {
  group('EditLogPage Bug Fixes', () {
    late MockLogsNotifier logsNotifier;
    late MockTimeAuthority mockTimeAuth;
    late MockLogRepository mockRepo;

    final testEvent = LogEvent(
      id: 'e1',
      status: 'ON',
      startTime: DateTime(2026, 1, 1, 8, 0, 0),
      duration: const Duration(hours: 1),
      location: 'Old Location',
    );

    final nextEvent = LogEvent(
      id: 'e2',
      status: 'OFF',
      startTime: DateTime(2026, 1, 1, 12, 0, 0),
      duration: const Duration(hours: 1),
      location: '',
    );

    setUp(() {
      logsNotifier = MockLogsNotifier(
        LogsState(
          logs: [],
          isLoading: false,
          selectedLog: DailyLog(
            id: const DailyLogId(1),
            uniqueId: 'V1',
            date: DateTime(2026, 1, 1),
            formattedTotalWorkTime: '10h',
            totalDrivingHours: 5.0,
            isFormComplete: true,
            isCertified: false,
            events: [testEvent, nextEvent],
          ),
        ),
      );

      mockRepo = MockLogRepository();

      mockTimeAuth = MockTimeAuthority();
      when(
        () => mockTimeAuth.nowUtc(),
      ).thenReturn(DateTime.utc(2026, 1, 1, 10, 0, 0));

      registerFallbackValue(testEvent);
      registerFallbackValue(
        AuditEntry(
          id: '1',
          timestamp: DateTime.now(),
          driverId: 'd',
          newStatus: 'ON',
          reason: '',
        ),
      );
    });

    Widget createTestApp(Widget child) {
      final mockAuth = AuthState(
        status: AuthStatus.authenticated,
        user: User(
          id: 'driver-1',
          fullName: 'Test Driver',
          email: 'test@demo.com',
          username: 'test',
          role: UserRole.fieldWorker,
          createdAt: DateTime.now(),
        ),
      );

      return ProviderScope(
        overrides: [
          logsProvider.overrideWith((ref) => logsNotifier),
          logRepositoryProvider.overrideWithValue(mockRepo),
          timeAuthorityProvider.overrideWithValue(mockTimeAuth),
          authStateProvider.overrideWith((ref) => MockAuthNotifier(mockAuth)),
          dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: child,
        ),
      );
    }

    testWidgets(
      'BUG B: invalid time -> mutation is not called -> localized error',
      (tester) async {
        when(
          () => logsNotifier.updateEvent(any(), reason: any(named: 'reason')),
        ).thenAnswer((_) async => const Right(null));

        await tester.pumpWidget(
          createTestApp(EditLogPage(event: testEvent, isNewEvent: false)),
        );
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(find.byType(EditLogPage));
        final container = ProviderScope.containerOf(context);
        container
            .read(editLogFormProvider(testEvent).notifier)
            .setStartTime('invalid-time');

        await tester.ensureVisible(find.byType(AppButton).first);
        await tester.tap(find.byType(AppButton).first);
        await tester.pump(
          const Duration(milliseconds: 100),
        ); // wait for snackbar animation

        verifyNever(
          () => logsNotifier.updateEvent(any(), reason: any(named: 'reason')),
        );
        // AppFeedback shows an Overlay, not a SnackBar.
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data?.toLowerCase().contains('invalid') ?? false),
          ),
          findsWidgets,
        );

        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'BUG C: user enters manual location -> saved LogEvent receives exactly that location',
      (tester) async {
        when(
          () => logsNotifier.updateEvent(any(), reason: any(named: 'reason')),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockRepo.logAudit(any()),
        ).thenAnswer((_) async => const Right(true));

        await tester.pumpWidget(
          createTestApp(EditLogPage(event: testEvent, isNewEvent: false)),
        );
        await tester.pumpAndSettle();

        final locationField = find.ancestor(
          of: find.byIcon(Icons.my_location),
          matching: find.byType(TextField),
        );

        expect(locationField, findsOneWidget);

        await tester.enterText(locationField, 'New Manual Location');
        await tester.pump();

        final BuildContext context = tester.element(find.byType(EditLogPage));
        final container = ProviderScope.containerOf(context);
        final state = container.read(editLogFormProvider(testEvent));
        expect(state.location, 'New Manual Location');

        // Also enter a Reason so the form validates successfully
        final reasonField = find.byType(TextField).last;
        await tester.ensureVisible(reasonField);
        await tester.enterText(reasonField, 'Bug C reason');
        await tester.pump();

        await tester.ensureVisible(find.byType(AppButton).first);
        await tester.tap(find.byType(AppButton).first);
        await tester.pumpAndSettle();

        verify(
          () => logsNotifier.updateEvent(
            any(
              that: predicate<LogEvent>(
                (e) => e.location == 'New Manual Location',
              ),
            ),
            reason: any(named: 'reason'),
          ),
        ).called(1);

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'changing the start time sends the recomputed duration, not the old one',
      (tester) async {
        when(
          () => logsNotifier.updateEvent(any(), reason: any(named: 'reason')),
        ).thenAnswer((_) async => const Right(null));
        when(
          () => mockRepo.logAudit(any()),
        ).thenAnswer((_) async => const Right(true));

        await tester.pumpWidget(
          createTestApp(EditLogPage(event: testEvent, isNewEvent: false)),
        );
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(find.byType(EditLogPage));
        final container = ProviderScope.containerOf(context);
        final notifier = container.read(
          editLogFormProvider(testEvent).notifier,
        );

        // Moving the start to 09:00 with the next event at 12:00 makes the
        // form show three hours — that is what the driver approves.
        notifier.setStartTime('09:00:00 AM');
        expect(
          container.read(editLogFormProvider(testEvent)).duration,
          '03:00',
        );

        final reasonField = find.byType(TextField).last;
        await tester.ensureVisible(reasonField);
        await tester.enterText(reasonField, 'Corrected start');
        await tester.pump();

        await tester.ensureVisible(find.byType(AppButton).first);
        await tester.tap(find.byType(AppButton).first);
        await tester.pumpAndSettle();

        verify(
          () => logsNotifier.updateEvent(
            any(
              that: predicate<LogEvent>(
                (e) =>
                    e.startTime == DateTime(2026, 1, 1, 9) &&
                    e.duration == const Duration(hours: 3),
              ),
            ),
            reason: any(named: 'reason'),
          ),
        ).called(1);

        await tester.pump(const Duration(seconds: 4));
      },
    );

    testWidgets(
      'Future time -> mutation is not called -> eventCannotBeInFuture error displayed',
      (tester) async {
        when(
          () => logsNotifier.updateEvent(any(), reason: any(named: 'reason')),
        ).thenAnswer((_) async => const Right(null));

        await tester.pumpWidget(
          createTestApp(EditLogPage(event: testEvent, isNewEvent: false)),
        );
        await tester.pumpAndSettle();

        final BuildContext context = tester.element(find.byType(EditLogPage));
        final container = ProviderScope.containerOf(context);

        // mockTimeAuth.nowUtc().toLocal() is 13:00:00 (1:00 PM) on 2026-01-01
        // Pick 03:00:00 PM (15:00:00, in the future)
        container
            .read(editLogFormProvider(testEvent).notifier)
            .setStartTime('03:00:00 PM');

        // Enter a valid reason
        final reasonField = find.byType(TextField).last;
        await tester.ensureVisible(reasonField);
        await tester.enterText(reasonField, 'Future time test reason');
        await tester.pump();

        await tester.ensureVisible(find.byType(AppButton).first);
        await tester.tap(find.byType(AppButton).first);
        await tester.pump(const Duration(milliseconds: 100));

        verifyNever(
          () => logsNotifier.updateEvent(any(), reason: any(named: 'reason')),
        );
        // AppFeedback shows localized future time error
        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Text &&
                (w.data?.toLowerCase().contains('future') ?? false),
          ),
          findsWidgets,
        );

        await tester.pump(const Duration(seconds: 4));
        await tester.pumpAndSettle();
      },
    );
  });
}
