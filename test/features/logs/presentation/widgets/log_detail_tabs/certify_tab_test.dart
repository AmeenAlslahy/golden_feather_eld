import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/account/domain/entities/user.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

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

void main() {
  group('CertifyTab', () {
    late MockAdapter mockAdapter;

    setUp(() {
      mockAdapter = MockAdapter();
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
        id: '123',
        date: DateTime.now(),
        totalDrivingHours: 10.0,
        isCertified: false,
        events: const [],
        isFormComplete: true,
      );

      await pumpTab(tester, log: log, driverId: null);
      
      final buttonFinder = find.byType(ElevatedButton);
      expect(buttonFinder, findsOneWidget);
      final button = tester.widget<ElevatedButton>(buttonFinder);
      expect(button.onPressed, isNull);
    });
  });
}
