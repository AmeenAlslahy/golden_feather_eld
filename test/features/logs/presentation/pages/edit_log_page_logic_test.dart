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
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';

class MockLogsNotifier extends StateNotifier<LogsState> with Mock implements LogsNotifier {
  MockLogsNotifier(super.state);
}

class MockTimeAuthority extends Mock implements TimeAuthority {}

void main() {
  group('EditLogPage Bug Fixes', () {
    late MockLogsNotifier logsNotifier;
    late MockTimeAuthority mockTimeAuth;

    final testEvent = LogEvent(
      id: 'e1',
      status: 'ON',
      startTime: DateTime(2026, 1, 1, 8, 0, 0),
      duration: const Duration(hours: 1),
      location: 'Old Location',
    );

    setUp(() {
      logsNotifier = MockLogsNotifier(LogsState(
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
        ),
      ));
      
      mockTimeAuth = MockTimeAuthority();
      when(() => mockTimeAuth.nowUtc()).thenReturn(DateTime.utc(2026, 1, 1, 10, 0, 0));

      registerFallbackValue(testEvent);
      registerFallbackValue(AuditEntry(
        id: '1',
        timestamp: DateTime.now(),
        driverId: 'd',
        newStatus: 'ON',
        reason: '',
      ));
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
          timeAuthorityProvider.overrideWithValue(mockTimeAuth),
          authStateProvider.overrideWith((ref) => StateController(mockAuth) as AuthNotifier),
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

    testWidgets('BUG B: invalid time -> mutation is not called -> localized error', (tester) async {
      when(() => logsNotifier.updateEvent(any(), reason: any(named: 'reason')))
          .thenAnswer((_) async => true);
          
      await tester.pumpWidget(createTestApp(
        EditLogPage(event: testEvent, isNewEvent: false),
      ));
      await tester.pumpAndSettle();

      final BuildContext context = tester.element(find.byType(EditLogPage));
      final container = ProviderScope.containerOf(context);
      container.read(editLogFormProvider(testEvent).notifier).setStartTime('invalid-time');

      debugDumpApp();
      await tester.ensureVisible(find.byType(AppButton).first);
      await tester.tap(find.byType(AppButton).first);
      await tester.pump(const Duration(milliseconds: 100)); // wait for snackbar animation

      verifyNever(() => logsNotifier.updateEvent(any(), reason: any(named: 'reason')));
      // AppFeedback shows an Overlay, not a SnackBar.
      expect(find.byWidgetPredicate((w) => w is Text && (w.data?.toLowerCase().contains('invalid') ?? false)), findsWidgets);
    });

    testWidgets('BUG C: user enters manual location -> saved LogEvent receives exactly that location', (tester) async {
      when(() => logsNotifier.updateEvent(any(), reason: any(named: 'reason')))
          .thenAnswer((_) async => true);
      when(() => logsNotifier.saveAuditEntry(any()))
          .thenAnswer((_) async => const Right(true));

      await tester.pumpWidget(createTestApp(
        EditLogPage(event: testEvent, isNewEvent: false),
      ));
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

      verify(() => logsNotifier.updateEvent(
        any(that: predicate<LogEvent>((e) => e.location == 'New Manual Location')),
        reason: any(named: 'reason'),
      )).called(1);
    });
  });
}
