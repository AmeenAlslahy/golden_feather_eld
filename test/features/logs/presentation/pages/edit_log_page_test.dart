import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
// ignore: depend_on_referenced_packages
import 'package:geolocator_platform_interface/geolocator_platform_interface.dart';
// ignore: depend_on_referenced_packages
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/edit_log_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/edit_log_form_provider.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/edit_log_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log.dart';
import 'package:golden_feather_eld/features/logs/domain/entities/daily_log_page.dart';
import 'package:golden_feather_eld/core/time/time_authority_provider.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/logs/presentation/widgets/time_picker_sheet.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../helpers/fake_time_authority.dart';

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

class MockGeolocatorPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements GeolocatorPlatform {}

Widget createTestApp(Widget child) {
  final mockRepo = MockLogRepository();
  // We only mock what LogsNotifier might call during initialization or simple rendering
  when(
    () => mockRepo.getDailyLogs(
      driverId: any(named: 'driverId'),
      page: any(named: 'page'),
      size: any(named: 'size'),
    ),
  ).thenAnswer((_) async => const Right(DailyLogPage.empty));
  when(
    () => mockRepo.getEventDetails(any(), any()),
  ).thenAnswer((_) async => const Right(null));

  final mockAuthState = AuthState(
    status: AuthStatus.authenticated,
    user: User(
      id: 'd1',
      fullName: 'Test',
      email: 'test@demo.com',
      username: 'test',
      role: UserRole.fieldWorker,
      createdAt: DateTime.now(),
    ),
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
  setUpAll(() {
    registerFallbackValue(const DailyLogId(0));
    registerFallbackValue(const DutyStatusId(0));
  });

  group('EditLogPage & editLogFormProvider', () {
    testWidgets('EditLogPage(event: null) -> Insert Duty Status', (
      tester,
    ) async {
      await tester.pumpWidget(
        createTestApp(const EditLogPage(event: null, isNewEvent: true)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(EditLogPage), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('EditLogPage(event: LogEvent(...)) -> Edit Duty Status and prefills manual location', (
      tester,
    ) async {
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
      expect(find.widgetWithText(TextField, 'Miami, FL'), findsOneWidget);
      expect(find.widgetWithIcon(IconButton, Icons.my_location), findsOneWidget);
    });

    testWidgets('EditLogPage prefills manualLocation if explicitly present on event', (
      tester,
    ) async {
      final fakeEventWithManual = LogEvent(
        id: '124',
        status: 'ON',
        startTime: DateTime(2026, 1, 1, 8, 0).toUtc(),
        duration: const Duration(hours: 1),
        location: '1mi SW from Clarksville, AR',
        manualLocation: 'Dallas, TX',
      );

      await tester.pumpWidget(createTestApp(EditLogPage(event: fakeEventWithManual)));
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, 'Dallas, TX'), findsOneWidget);
    });

    testWidgets('tapping location icon fetches GPS coordinates and populates manual location field', (
      tester,
    ) async {
      final mockGeolocator = MockGeolocatorPlatform();
      GeolocatorPlatform.instance = mockGeolocator;

      when(() => mockGeolocator.isLocationServiceEnabled())
          .thenAnswer((_) async => true);
      when(() => mockGeolocator.checkPermission())
          .thenAnswer((_) async => LocationPermission.always);
      when(() => mockGeolocator.getCurrentPosition(
            locationSettings: any(named: 'locationSettings'),
          )).thenAnswer(
        (_) async => Position(
          longitude: -93.4668,
          latitude: 35.4714,
          timestamp: DateTime.now(),
          accuracy: 5.0,
          altitude: 100.0,
          altitudeAccuracy: 1.0,
          heading: 0.0,
          headingAccuracy: 1.0,
          speed: 0.0,
          speedAccuracy: 0.0,
        ),
      );

      final fakeEvent = LogEvent(
        id: '125',
        status: 'ON',
        startTime: DateTime(2026, 1, 1, 8, 0).toUtc(),
        duration: const Duration(hours: 1),
        location: '',
      );

      await tester.pumpWidget(createTestApp(EditLogPage(event: fakeEvent)));
      await tester.pumpAndSettle();

      final locationIconBtn = find.widgetWithIcon(IconButton, Icons.my_location);
      expect(locationIconBtn, findsOneWidget);

      await tester.ensureVisible(locationIconBtn);
      await tester.tap(locationIconBtn);
      await tester.pumpAndSettle();

      expect(find.widgetWithText(TextField, '35.4714, -93.4668'), findsOneWidget);
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

    test('editLogFormProvider recalculates duration based on next event and now', () {
      final fakeTime = DateTime(2026, 1, 1, 14, 0, 0).toUtc();
      final container = ProviderContainer(
        overrides: [
          timeAuthorityProvider.overrideWithValue(FakeTimeAuthority(initialTime: fakeTime)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(editLogFormProvider(null).notifier);

      final dailyLog = DailyLog(
        id: const DailyLogId(1),
        uniqueId: 'L1',
        date: DateTime(2026, 1, 1),
        formattedTotalWorkTime: '8h',
        totalDrivingHours: 4.0,
        today: true,
        isFormComplete: true,
        isCertified: false,
        events: [
          LogEvent(
            id: 'e1',
            status: 'OFF',
            startTime: DateTime(2026, 1, 1, 6, 0),
            duration: const Duration(hours: 2),
            location: 'Station A',
          ),
          LogEvent(
            id: 'e2',
            status: 'D',
            startTime: DateTime(2026, 1, 1, 10, 0),
            duration: const Duration(hours: 3),
            location: 'Station B',
          ),
        ],
      );

      // Start time at 07:00 AM - next event is e2 at 10:00 AM -> difference is 3 hours
      notifier.setStartTime('07:00:00 AM', dailyLog);
      expect(container.read(editLogFormProvider(null)).duration, '03:00');

      // Start time at 08:30 AM - next event is e2 at 10:00 AM -> difference is 1 hour 30 min
      notifier.setStartTime('08:30:00 AM', dailyLog);
      expect(container.read(editLogFormProvider(null)).duration, '01:30');

      // Start time at 11:00 AM - no next event, today log, now is 14:00 (2:00 PM) -> difference is 3 hours
      notifier.setStartTime('11:00:00 AM', dailyLog);
      expect(container.read(editLogFormProvider(null)).duration, '03:00');
    });

    testWidgets('TimePickerSheet renders PM correctly and includes column headers', (tester) async {
      final initialPmTime = DateTime(2026, 1, 1, 20, 15, 30); // 08:15:30 PM
      String? pickedTime;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en'),
          theme: AppTheme.light,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: TimePickerSheet(
              initialTime: initialPmTime,
              dateLabel: 'Today - Jan 1st',
              onDone: (time) => pickedTime = time,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TimePickerSheet), findsOneWidget);
      expect(find.text('Today - Jan 1st'), findsOneWidget);
      expect(find.text('Hour'), findsOneWidget);
      expect(find.text('Minute'), findsOneWidget);
      expect(find.text('Second'), findsOneWidget);
      expect(find.text('Period'), findsOneWidget);

      // Tap Save button without scrolling: should preserve PM and initial time
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(pickedTime, '08:15:30 PM');
    });

    test('editLogErrorUserMessage maps overlapConflict to eventTimeOverlap', () {
      final loc = lookupAppLocalizations(const Locale('ar'));
      final msg = editLogErrorUserMessage(
        EditLogError(EditLogErrorCode.overlapConflict),
        loc,
      );
      expect(msg, 'تتعارض أوقات هذه الحالة مع حدث آخر مسجل في نفس اليوم.');
    });

    test('editLogErrorUserMessage maps overlapConflict to English translation', () {
      final loc = lookupAppLocalizations(const Locale('en'));
      final msg = editLogErrorUserMessage(
        EditLogError(EditLogErrorCode.overlapConflict),
        loc,
      );
      expect(
        msg,
        'The selected time range conflicts with another event on this day.',
      );
    });
  });
}
