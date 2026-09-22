import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/app/providers/app_repository_providers.dart';
import 'package:golden_feather_eld/backend/adapters/eld_engine/models/readiness_dto.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
// ignore: directives_ordering
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
// ignore: directives_ordering
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
// ignore: directives_ordering
import 'package:golden_feather_eld/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
// ignore: directives_ordering
import 'package:mocktail/mocktail.dart';

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

class MockLogRepository extends Mock implements LogRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
  });

  group('CertifyTab', () {
    late MockAdapter mockAdapter;
    late MockLogRepository mockRepo;

    setUp(() {
      mockAdapter = MockAdapter();
      mockRepo = MockLogRepository();
    });

    Future<void> pumpTab(
      WidgetTester tester, {
      required DailyLog log,
      String? driverId,
    }) async {
      final authState = AuthState(
        status: driverId != null ? AuthStatus.authenticated : AuthStatus.unauthenticated,
        user: driverId != null ? User(
          id: driverId,
          fullName: 'Test Driver',
          email: 'test@demo.com',
          username: 'test',
          role: UserRole.fieldWorker,
          createdAt: DateTime.now(),
        ) : null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBackendProvider.overrideWithValue(mockAdapter),
            authStateProvider.overrideWith((ref) => MockAuthNotifier(authState)),
            logRepositoryProvider.overrideWithValue(mockRepo),
          ],
          child: MaterialApp(
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: CertifyTab(selectedLog: log),
            ),
          ),
        ),
      );
    }

    testWidgets('AGREE button is disabled when signature is empty', (tester) async {
      final log = DailyLog(
        id: const DailyLogId(123),
        date: DateTime.now(),
        totalDrivingHours: 10.0,
        isCertified: false,
        events: const [],
        isFormComplete: true,
      );

      // ignore: prefer_const_constructors
      when(() => mockRepo.getReadiness(any())).thenAnswer((_) async => const Right(ReadinessDto(
        dailyLogId: 123,
        driverId: 1,
        driverName: 'Test Driver',
        logDate: '2023-01-01',
        readinessStatus: 'READY',
        missingRequirements: [],
        availableActions: ['CERTIFY'],
        legalStatement: 'I certify...',
      )));

      await pumpTab(tester, log: log, driverId: null);
      await tester.pumpAndSettle();
      
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });
  });
}
