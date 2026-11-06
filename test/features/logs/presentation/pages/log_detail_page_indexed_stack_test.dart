import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/logs/data/providers/log_repository_providers.dart';

import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/log_readiness.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/log_detail_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/log_detail_tab_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/log_draft_signature_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signature/signature.dart';

class _MockRepo extends Mock implements LogRepository {}

class _MockAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _MockAuthNotifier(super.state);
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

class _MockLogsNotifier extends StateNotifier<LogsState>
    implements LogsNotifier {
  _MockLogsNotifier(super.state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
  });

  group('LogDetailPage IndexedStack Tab Preservation', () {
    late _MockRepo repo;
    late MockAdapter adapter;

    final log = DailyLog(
      id: const DailyLogId(101),
      date: DateTime(2026, 10, 14),
      totalDrivingHours: 3.0,
      isCertified: false,
      isFormComplete: true,
      events: const [],
    );

    setUp(() {
      repo = _MockRepo();
      adapter = MockAdapter();

      when(() => repo.getReadiness(any())).thenAnswer(
        (_) async => const Right(
          LogReadiness(
            dailyLogId: 101,
            driverId: 1,
            driverName: 'Driver 1',
            logDate: '2026-10-14',
            readinessStatus: 'READY',
            missingRequirements: [],
            legalStatement: 'I certify that this record is true and correct.',
            availableActions: ['certify'],
            carrierProposedEditsPending: false,
            pendingCarrierEdits: [],
          ),
        ),
      );
      when(() => repo.getDraftSignature(any())).thenAnswer((_) async => null);
      when(
        () => repo.saveDraftSignature(any(), any()),
      ).thenAnswer((_) async {});
      when(() => repo.deleteDraftSignature(any())).thenAnswer((_) async {});
    });

    testWidgets(
      'switching tabs preserves CertifyTab state and drawn signature in memory',
      (tester) async {
        tester.view.physicalSize = const Size(1080, 2340);
        tester.view.devicePixelRatio = 3.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer(
          overrides: [
            activeBackendProvider.overrideWithValue(adapter),
            logRepositoryProvider.overrideWithValue(repo),
            authStateProvider.overrideWith(
              (ref) => _MockAuthNotifier(
                AuthState(
                  status: AuthStatus.authenticated,
                  user: User(
                    id: '1',
                    fullName: 'Driver 1',
                    email: 'd1@test.com',
                    username: 'd1',
                    role: UserRole.fieldWorker,
                    createdAt: DateTime.now(),
                  ),
                ),
              ),
            ),
            logsProvider.overrideWith(
              (ref) => _MockLogsNotifier(
                LogsState(logs: [log], selectedLog: log, isLoading: false),
              ),
            ),
            dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppTheme.light,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              home: const LogDetailPage(),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Initially on Events tab (index 0)
        expect(find.byType(IndexedStack), findsOneWidget);

        // Switch to Certify tab (index 2)
        container.read(logDetailTabProvider.notifier).state = 2;
        await tester.pumpAndSettle();

        // Add a stroke to the draft provider
        final pts = [Point(const Offset(40, 50), PointType.tap, 1.0)];
        container
            .read(logDraftSignatureProvider(log.id).notifier)
            .updateDraft(pts);
        await tester.pumpAndSettle();

        // Signature controller has 1 point
        final sigFinder = find.byType(Signature);
        expect(sigFinder, findsOneWidget);
        final sigController = tester.widget<Signature>(sigFinder).controller;
        expect(sigController.points.length, 1);

        // Switch to Form tab (index 1)
        container.read(logDetailTabProvider.notifier).state = 1;
        await tester.pumpAndSettle();

        // Switch to Events tab (index 0)
        container.read(logDetailTabProvider.notifier).state = 0;
        await tester.pumpAndSettle();

        // CertifyTab should STILL exist in the IndexedStack tree (offstage)!
        expect(find.byType(CertifyTab, skipOffstage: false), findsOneWidget);

        // Switch back to Certify tab (index 2)
        container.read(logDetailTabProvider.notifier).state = 2;
        await tester.pumpAndSettle();

        // Signature controller MUST still be the same controller with 1 point!
        final recheckedController = tester
            .widget<Signature>(sigFinder)
            .controller;
        expect(identical(sigController, recheckedController), isTrue);
        expect(recheckedController.points.length, 1);
      },
    );
  });
}
