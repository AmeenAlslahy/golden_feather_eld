import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/edit_log_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/edit_log_form_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/core/time/time_authority_provider.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../helpers/fake_time_authority.dart';

class MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  MockAuthNotifier(super.state);
  
  @override
  Future<bool> login({required String username, required String password, String? serverUrl}) async => true;
  
  @override
  void forceLogout() {}
  
  @override
  Future<void> logout() async {}
  
  @override
  Future<void> checkAuthStatus() async {}
  
  @override
  void clearError() {}
}

class TestWidget extends ConsumerWidget {
  final void Function(WidgetRef) onRef;
  const TestWidget({required this.onRef, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    onRef(ref);
    return const SizedBox.shrink();
  }
}

class MockLogRepository extends Mock implements LogRepository {}

Widget createTestApp(Widget child) {
  final mockRepo = MockLogRepository();
  // We only mock what LogsNotifier might call during initialization or simple rendering
  when(() => mockRepo.getDailyLogs(
    driverId: any(named: 'driverId'),
    limit: any(named: 'limit'),
    offset: any(named: 'offset'),
  )).thenAnswer((_) async => const Right([]));

  final mockAuthState = AuthState(
    status: AuthStatus.authenticated,
    user: User(id: 'd1', fullName: 'Test', email: 'test@demo.com', username: 'test', role: UserRole.fieldWorker, createdAt: DateTime.now()),
  );

  return ProviderScope(
    overrides: [
      timeAuthorityProvider.overrideWithValue(FakeTimeAuthority()),
      logsProvider.overrideWith((ref) => LogsNotifier(mockRepo, 1)),
      dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
      authStateProvider.overrideWith((ref) => MockAuthNotifier(mockAuthState)),
    ],
    child: MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );
}

void main() {
  group('EditLogPage & editLogFormProvider', () {
    testWidgets('EditLogPage(event: null) -> Insert Duty Status', (tester) async {
      await tester.pumpWidget(createTestApp(const EditLogPage(event: null, isNewEvent: true)));
      await tester.pumpAndSettle();

      expect(find.byType(EditLogPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('EditLogPage(event: LogEvent(...)) -> Edit Duty Status', (tester) async {
      final fakeEvent = LogEvent(
        id: '123',
        status: 'D',
        startTime: DateTime(2026, 1, 1, 8, 0).toUtc(),
        duration: const Duration(hours: 2),
        location: 'Miami, FL',
      );

      await tester.pumpWidget(createTestApp(EditLogPage(event: fakeEvent)));
      await tester.pumpAndSettle();

      expect(find.byType(EditLogPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    test('editLogFormProvider(null) initializes with default values', () {
      final container = ProviderContainer(
        overrides: [
          timeAuthorityProvider.overrideWithValue(FakeTimeAuthority()),
        ],
      );
      addTearDown(container.dispose);

      final state = container.read(editLogFormProvider(null));

      expect(state.selectedStatus, 'OFF');
      expect(state.duration, '00:00');
      expect(state.location, '');
    });

    test('editLogFormProvider(logEvent) initializes with event values', () {
      final container = ProviderContainer(
        overrides: [
          timeAuthorityProvider.overrideWithValue(FakeTimeAuthority()),
        ],
      );
      addTearDown(container.dispose);

      final fakeEvent = LogEvent(
        id: '123',
        status: 'ON',
        startTime: DateTime(2026, 1, 1, 8, 0).toUtc(),
        duration: const Duration(hours: 1),
        location: 'Dallas, TX',
      );

      final state = container.read(editLogFormProvider(fakeEvent));

      expect(state.selectedStatus, 'ON');
      expect(state.location, 'Dallas, TX');
    });
  });
}
