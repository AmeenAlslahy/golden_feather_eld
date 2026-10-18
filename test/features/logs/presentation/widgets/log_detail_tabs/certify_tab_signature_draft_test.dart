import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/logs/data/repositories/log_repository_impl.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/log_readiness.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/log_detail_tab_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/log_draft_signature_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/log_detail_tabs/certify_tab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:signature/signature.dart';

class _MockRepo extends Mock implements LogRepository {}

class _MockAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _MockAuthNotifier(super.state);
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

  group('CertifyTab Signature Draft Persistence', () {
    late _MockRepo repo;
    late MockAdapter adapter;
    String? storedDraft;

    final log = DailyLog(
      id: const DailyLogId(555),
      date: DateTime(2026, 10, 14),
      totalDrivingHours: 4.5,
      isCertified: false,
      isFormComplete: true,
      events: const [],
    );

    setUp(() {
      repo = _MockRepo();
      adapter = MockAdapter();
      storedDraft = null;

      when(() => repo.getReadiness(any())).thenAnswer(
        (_) async => const Right(LogReadiness(
          dailyLogId: 555,
          driverId: 1,
          driverName: 'Driver 1',
          logDate: '2026-10-14',
          readinessStatus: 'READY',
          missingRequirements: [],
          legalStatement: 'I certify that this record is true and correct.',
          availableActions: ['certify'],
          carrierProposedEditsPending: false,
          pendingCarrierEdits: [],
        )),
      );

      when(() => repo.getDraftSignature(any())).thenAnswer((_) async => storedDraft);
      when(() => repo.saveDraftSignature(any(), any())).thenAnswer((invocation) async {
        storedDraft = invocation.positionalArguments[1] as String;
      });
      when(() => repo.deleteDraftSignature(any())).thenAnswer((_) async {
        storedDraft = null;
      });
    });

    Widget createTestApp(ProviderContainer container, {required Widget child}) {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Scaffold(body: child),
        ),
      );
    }

    testWidgets('restores draft signature when page is reopened (survives screen exit)', (tester) async {
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
        ],
      );
      addTearDown(container.dispose);

      // Pre-populate draft points in notifier
      final pts = [
        Point(const Offset(20, 30), PointType.tap, 1.0),
        Point(const Offset(25, 35), PointType.move, 1.0),
      ];
      container.read(logDraftSignatureProvider(log.id).notifier).updateDraft(pts);

      // Pump CertifyTab for the first time
      await tester.pumpWidget(createTestApp(container, child: CertifyTab(selectedLog: log)));
      await tester.pumpAndSettle();

      // Controller must have the restored points!
      final signatureWidgets = tester.widgetList<Signature>(find.byType(Signature));
      expect(signatureWidgets, isNotEmpty);
      final sigController = signatureWidgets.first.controller;
      expect(sigController.points.length, 2);
      expect(sigController.isNotEmpty, isTrue);

      // Exit page (unmount CertifyTab)
      await tester.pumpWidget(createTestApp(container, child: const SizedBox(key: ValueKey('other_page'))));
      await tester.pumpAndSettle();
      expect(find.byType(CertifyTab), findsNothing);

      // Re-open page (mount CertifyTab again)
      await tester.pumpWidget(createTestApp(container, child: CertifyTab(selectedLog: log)));
      await tester.pumpAndSettle();

      // Controller MUST still have the restored signature!
      final reloadedWidgets = tester.widgetList<Signature>(find.byType(Signature));
      expect(reloadedWidgets, isNotEmpty);
      final reloadedController = reloadedWidgets.first.controller;
      expect(reloadedController.points.length, 2);
      expect(reloadedController.isNotEmpty, isTrue);
    });

    testWidgets('drawing remains possible after a restored draft (regression: unmodifiable list crash)', (tester) async {
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
        ],
      );
      addTearDown(container.dispose);

      // المسودة تعيش في حالة `List.unmodifiable`؛ يجب أن يستلم المتحكم نسخة
      // قابلة للتعديل، وإلا انهار الرسم بأول لمسة:
      // "Unsupported operation: Cannot add to an unmodifiable list".
      container
          .read(logDraftSignatureProvider(log.id).notifier)
          .updateDraft([Point(const Offset(20, 30), PointType.tap, 1.0)]);

      await tester.pumpWidget(createTestApp(container, child: CertifyTab(selectedLog: log)));
      await tester.pumpAndSettle();

      final controller =
          tester.widgetList<Signature>(find.byType(Signature)).first.controller;
      final before = controller.points.length;

      final gesture =
          await tester.startGesture(tester.getCenter(find.byType(Signature)));
      await gesture.moveBy(const Offset(24, 16));
      await gesture.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(controller.points.length, greaterThan(before));
    });

    testWidgets('NOT READY button navigates to Events without wiping signature', (tester) async {
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
        ],
      );
      addTearDown(container.dispose);

      // Set current tab to 2 (Certify)
      container.read(logDetailTabProvider.notifier).state = 2;

      // Add a draft signature
      final pts = [Point(const Offset(10, 10), PointType.tap, 1.0)];
      container.read(logDraftSignatureProvider(log.id).notifier).updateDraft(pts);

      await tester.pumpWidget(createTestApp(container, child: CertifyTab(selectedLog: log)));
      await tester.pumpAndSettle();

      // Tap NOT READY button
      final notReadyBtn = find.text('NOT READY');
      expect(notReadyBtn, findsOneWidget);
      await tester.tap(notReadyBtn);
      await tester.pumpAndSettle();

      // Must have switched tab index to 0
      expect(container.read(logDetailTabProvider), 0);

      // Draft signature MUST still be preserved!
      expect(container.read(logDraftSignatureProvider(log.id)).length, 1);
    });
  });
}
