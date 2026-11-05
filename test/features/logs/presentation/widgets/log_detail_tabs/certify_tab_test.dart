import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/log_readiness.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/core/localization/locale_provider.dart';

class _ReadyLogRepository extends Mock implements LogRepository {}

/// Production wires MaterialApp.locale from localeProvider; keep both on 'en'.
class _EnLocale extends StateNotifier<Locale> implements LocaleNotifier {
  _EnLocale() : super(const Locale('en'));
  @override
  Future<void> setLocale(String languageCode) async =>
      state = Locale(languageCode);
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

void main() {
  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
  });

  group('CertifyTab', () {
    late MockAdapter mockAdapter;

    late _ReadyLogRepository logRepository;

    setUp(() {
      mockAdapter = MockAdapter();
      logRepository = _ReadyLogRepository();
      when(() => logRepository.getReadiness(any())).thenAnswer(
        (_) async => const Right(
          LogReadiness(
            dailyLogId: 123,
            driverId: 1,
            driverName: 'Test Driver',
            logDate: '2026-09-23',
            readinessStatus: 'READY',
            missingRequirements: [],
            legalStatement: 'I certify that this record is true and correct.',
            availableActions: ['certify'],
            carrierProposedEditsPending: false,
            pendingCarrierEdits: [],
          ),
        ),
      );
      when(
        () => logRepository.getDraftSignature(any()),
      ).thenAnswer((_) async => null);
      when(
        () => logRepository.saveDraftSignature(any(), any()),
      ).thenAnswer((_) async {});
      when(
        () => logRepository.deleteDraftSignature(any()),
      ).thenAnswer((_) async {});
    });

    Future<void> pumpTab(
      WidgetTester tester, {
      required DailyLog log,
      String? driverId,
    }) async {
      final authState = AuthState(
        status: driverId != null
            ? AuthStatus.authenticated
            : AuthStatus.unauthenticated,
        user: driverId != null
            ? User(
                id: driverId,
                fullName: 'Test Driver',
                email: 'test@demo.com',
                username: 'test',
                role: UserRole.fieldWorker,
                createdAt: DateTime.now(),
              )
            : null,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBackendProvider.overrideWithValue(mockAdapter),
            logRepositoryProvider.overrideWithValue(logRepository),
            authStateProvider.overrideWith(
              (ref) => MockAuthNotifier(authState),
            ),
            localeProvider.overrideWith((ref) => _EnLocale()),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(body: CertifyTab(selectedLog: log)),
          ),
        ),
      );
    }

    testWidgets('clear-signature action is tappable', (tester) async {
      final log = DailyLog(
        id: const DailyLogId(123),
        date: DateTime.now(),
        totalDrivingHours: 10.0,
        isCertified: false,
        events: const [],
        isFormComplete: true,
      );

      await pumpTab(tester, log: log, driverId: '1');
      await tester.pumpAndSettle();

      final button = tester.widget<AppButton>(
        find.widgetWithText(AppButton, 'Clear signature'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('AGREE with an empty signature refuses and explains', (
      tester,
    ) async {
      final log = DailyLog(
        id: const DailyLogId(123),
        date: DateTime.now(),
        totalDrivingHours: 10.0,
        isCertified: false,
        events: const [],
        isFormComplete: true,
      );

      await pumpTab(tester, log: log, driverId: null);
      await tester.pumpAndSettle();

      final buttonFinder = find.widgetWithText(AppButton, 'AGREE');
      expect(buttonFinder, findsOneWidget);
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();

      // The log is not certified without a signature; the driver is told
      // why INLINE (FormField validator, SRS 8.1 dialog copy).
      expect(find.text('Please draw a signature first.'), findsOneWidget);
    });
  });
}
