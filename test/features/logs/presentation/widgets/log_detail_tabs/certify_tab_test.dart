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
import 'package:golden_feather_eld/backend/adapters/eld_engine/models/readiness_dto.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

class _ReadyLogRepository extends Mock implements LogRepository {}

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
        (_) async => const Right(ReadinessDto(
          dailyLogId: 123,
          driverId: 1,
          driverName: 'Test Driver',
          logDate: '2026-09-23',
          readinessStatus: 'READY',
          missingRequirements: [],
          legalStatement: 'I certify that this record is true and correct.',
          availableActions: ['certify'],
        )),
      );
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
            logRepositoryProvider.overrideWithValue(logRepository),
            authStateProvider.overrideWith((ref) => MockAuthNotifier(authState)),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
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

    testWidgets('NOT READY is tappable', (tester) async {
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
        find.widgetWithText(AppButton, 'NOT READY'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('AGREE with an empty signature refuses and explains', (tester) async {
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

      // The log is not certified without a signature; the driver is told why.
      expect(find.text('You need to fill and save form first.'), findsOneWidget);
      // Pump past the AppFeedback auto-dismiss timer (3s).
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });

    testWidgets('carrier-proposed edits are shown and ACCEPT hits the respond API',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var readinessCalls = 0;
      when(() => logRepository.getReadiness(any())).thenAnswer((_) async {
        readinessCalls++;
        return Right(ReadinessDto(
          dailyLogId: 123,
          driverId: 1,
          driverName: 'Test Driver',
          logDate: '2026-09-23',
          readinessStatus: 'READY',
          missingRequirements: const [],
          legalStatement: 'I certify that this record is true and correct.',
          availableActions: const ['certify'],
          carrierProposedEditsPending: readinessCalls == 1,
          pendingCarrierEdits: readinessCalls == 1
              ? const [
                  CarrierProposedEdit(
                    id: 'edit-77',
                    carrierName: 'Golden Feather Carrier',
                    carrierReason: 'Fuel stop was logged as driving',
                    proposedStatus: 'ON_DUTY',
                    previousValuesSummary: 'DRIVING 14:00–14:30',
                    newValuesSummary: 'ON_DUTY 14:00–14:30',
                  ),
                ]
              : const [],
        ));
      });
      when(() => logRepository.respondToCarrierEdit(
            logId: any(named: 'logId'),
            editId: any(named: 'editId'),
            action: any(named: 'action'),
            driverNotes: any(named: 'driverNotes'),
          )).thenAnswer((_) async => const Right(true));

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

      // SRS 6: the driver sees the carrier's proposal and must answer it first.
      expect(
        find.text('Carrier edits must be accepted or rejected before certification.'),
        findsOneWidget,
      );
      // Card summary = carrier · previous → new · reason (joined with ' · ').
      expect(find.textContaining('Golden Feather Carrier'), findsOneWidget);
      expect(find.textContaining('Fuel stop was logged as driving'), findsOneWidget);
      expect(find.widgetWithText(AppButton, 'REJECT'), findsOneWidget);

      final accept = find.widgetWithText(AppButton, 'ACCEPT');
      await tester.ensureVisible(accept);
      await tester.tap(accept);
      await tester.pumpAndSettle();

      // Existing respond pipeline — no parallel endpoint.
      verify(() => logRepository.respondToCarrierEdit(
            logId: const DailyLogId(123),
            editId: 'edit-77',
            action: 'ACCEPT',
            driverNotes: any(named: 'driverNotes'),
          )).called(1);
      // Readiness is re-fetched and the card disappears once the server clears it.
      expect(readinessCalls, 2);
      expect(find.textContaining('Fuel stop was logged as driving'), findsNothing);
      expect(find.widgetWithText(AppButton, 'ACCEPT'), findsNothing);
      expect(find.text('Carrier edit accepted. Re-certify the log.'), findsOneWidget);
      // Pump past the AppFeedback auto-dismiss timer (3s).
      await tester.pump(const Duration(seconds: 3));
      await tester.pumpAndSettle();
    });
  });
}
