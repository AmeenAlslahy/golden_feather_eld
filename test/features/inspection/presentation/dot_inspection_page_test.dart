import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/core/widgets/eld_date_paginator.dart';
import 'package:golden_feather_eld/domain/inspection/dot_inspection.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/inspection/domain/inspection_transfer.dart';
import 'package:golden_feather_eld/features/inspection/domain/repositories/inspection_repository.dart';
import 'package:golden_feather_eld/features/inspection/presentation/pages/dot_inspection_page.dart';
import 'package:golden_feather_eld/features/inspection/presentation/pages/inspection_start_view.dart';
import 'package:golden_feather_eld/features/inspection/data/providers/inspection_repository_providers.dart';
import 'package:golden_feather_eld/features/inspection/presentation/providers/dot_inspection_providers.dart';
import 'package:golden_feather_eld/features/inspection/presentation/providers/inspection_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeLocalStorage extends Mock implements LocalStorageService {
  @override
  String get backendType => 'mock';
  @override
  String get serverUrl => 'https://example.com';
  @override
  String get language => 'en';
  @override
  String? get selectedVehicleId => null;
}

/// Server screen that allows starting an inspection (the mock says false).
class _StartAllowed extends DotInspectionScreenNotifier {
  @override
  Future<DotInspectionScreen> build() async => DotInspectionScreen(
    screenTitle: 'DOT Inspection',
    guidanceText: 'Review the driver records',
    handOverDeviceNotice: 'Hand the device to the inspector',
    carrierComplianceStatement: 'Compliant',
    carrierName: 'Golden Feather Transport',
    usdotNumber: '1234567',
    eldIdentifier: 'GF-ELD-001',
    eldRegistrationId: 'GF10000001',
    driverId: const DriverId(101),
    driverName: 'Ahmed',
    inspectionDate: DateTime.utc(2026, 1, 15),
    cycleDaysCovered: 8,
    canStartInspection: true,
    canSendLogs: false,
    canEmailLogs: false,
    canViewInformationPacket: false,
    inspectionActive: false,
    readOnlyMode: false,
  );
}

class _MockInspectionRepository extends Mock implements InspectionRepository {}

/// Inspection already running on a two-day cycle, showing day 0.
class _SeededInspection extends InspectionNotifier {
  _SeededInspection(
    InspectionRepository repository,
    List<DotInspectionCycleDay> cycle,
    DotInspectionLog log,
  ) : super(
        repository: repository,
        driverId: 101,
        loc: lookupAppLocalizations(const Locale('en')),
      ) {
    state = InspectionState(
      isInspectionMode: true,
      isPinLocked: true,
      cycle: cycle,
      log: log,
      selectedDayIndex: 0,
    );
  }
}

DotInspectionCycleDay _cycleDay(DateTime date) => DotInspectionCycleDay(
  driverId: const DriverId(101),
  driverName: 'Ahmed',
  logDate: date,
  displayDate: 'Day ${date.day}',
  displayLocation: 'Riyadh',
  certified: false,
  certifiedAt: null,
  eldRegistrationId: 'GF10000001',
  eldIdentifier: 'GF-ELD-001',
  eldProvider: 'Golden Feather',
  vehicleNumber: '646',
  uniqueId: '1001',
  vin: '1FUJGLDR5CSBJ0527',
  startOdometerKm: 1,
  endOdometerKm: 2,
  totalDistanceKm: 1,
  engineHours: 1,
  trailers: '',
  shippingDocuments: '',
  carrierName: 'Golden Feather Transport',
  usdotNumber: '1234567',
  mainOfficeAddress: 'M',
  homeTerminalAddress: 'H',
  activeDataDiagnostics: const [],
  activeDeviceMalfunctions: const [],
  exemptDriver: false,
  hasUnidentifiedDriving: false,
  unidentifiedDrivingCount: 0,
);

DotInspectionLog _logFor(DateTime date) => DotInspectionLog(
  driverId: const DriverId(101),
  driverName: 'Ahmed',
  logDate: date,
  displayDate: 'Day ${date.day}',
  displayLocation: 'Riyadh',
  certified: false,
  certifiedAt: null,
  eldRegistrationId: 'GF10000001',
  eldIdentifier: 'GF-ELD-001',
  eldProvider: 'Golden Feather',
  vehicleNumber: '646',
  uniqueId: '1001',
  vin: '1FUJGLDR5CSBJ0527',
  startOdometerKm: 1,
  endOdometerKm: 2,
  totalDistanceKm: 1,
  engineHours: 1,
  trailers: '',
  shippingDocuments: '',
  carrierName: 'Golden Feather Transport',
  usdotNumber: '1234567',
  mainOfficeAddress: 'M',
  homeTerminalAddress: 'H',
  activeDataDiagnostics: const [],
  activeDeviceMalfunctions: const [],
  events: const [],
  readOnly: false,
);

/// An inspection already running and locked with PIN 1234 (no log loaded, so
/// the page shows the empty body plus the lock icon in the app bar).
/// Locks the notifier through the public API only (owner decision D:
/// no PIN backdoor) — the repository stub supplies one displayable day
/// and the test drives `startInspection` before pumping.
class _LockedInspection extends InspectionNotifier {
  _LockedInspection(InspectionRepository repository)
    : super(
        repository: repository,
        driverId: 101,
        loc: lookupAppLocalizations(const Locale('en')),
      );
}

/// The mock `GET /eld/dot-inspection` declares every capability false and
/// returns its own guidance copy. The start view must reflect both.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('isValidInspectionPin: exactly four digits', () {
    expect(isValidInspectionPin('1234'), isTrue);
    expect(isValidInspectionPin(' 1234 '), isTrue); // trim
    expect(isValidInspectionPin('123'), isFalse);
    expect(isValidInspectionPin('12345'), isFalse);
    expect(isValidInspectionPin('12a4'), isFalse);
    expect(isValidInspectionPin(''), isFalse);
  });

  test('inspectionDisplayText policy (SRS 8.1): Arabic shows the local '
      'translation, English shows the server text when present', () {
    expect(
      inspectionDisplayText(
        isArabic: true,
        serverText: 'Server guidance',
        localFallback: 'Local',
      ),
      'Local',
    );
    expect(
      inspectionDisplayText(
        isArabic: false,
        serverText: 'Server guidance',
        localFallback: 'Local',
      ),
      'Server guidance',
    );
    expect(
      inspectionDisplayText(
        isArabic: false,
        serverText: '   ',
        localFallback: 'Local',
      ),
      'Local',
    );
  });

  Future<void> pump(WidgetTester tester, {bool allowStart = false}) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          localStorageProvider.overrideWithValue(_FakeLocalStorage()),
          if (allowStart)
            dotInspectionScreenProvider.overrideWith(_StartAllowed.new),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const DotInspectionPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('server guidance text replaces the local copy', (tester) async {
    await pump(tester);
    expect(find.text('Review the driver records'), findsOneWidget);
    expect(find.text('Hand the device to the inspector'), findsOneWidget);
    final compliance = find.text(
      'This device is compliant with FMCSA 49 CFR Part 395',
    );
    await tester.scrollUntilVisible(
      compliance,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(compliance, findsOneWidget);
  });

  testWidgets('explicit false capabilities disable the four actions', (
    tester,
  ) async {
    await pump(tester);

    for (final label in const [
      'START INSPECTION',
      'SEND LOGS',
      'EMAIL LOGS',
      'INFORMATION PACKET',
    ]) {
      final finder = find.widgetWithText(AppButton, label);
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(finder, findsOneWidget, reason: label);
      expect(tester.widget<AppButton>(finder).onPressed, isNull, reason: label);
    }
    // Each disabled generic action shows the server-refusal note. The list
    // is lazily built, so assert per section while it is on screen instead
    // of a global count (scrolled-past sections get discarded).
    for (final label in const [
      'SEND LOGS',
      'EMAIL LOGS',
      'INFORMATION PACKET',
    ]) {
      final finder = find.widgetWithText(AppButton, label);
      await tester.scrollUntilVisible(
        finder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(
        find.text(
          'Not available for this account per the server.',
          skipOffstage: false,
        ),
        findsAtLeastNWidgets(1),
        reason: label,
      );
    }
    final startNote = find.text(
      'The server does not allow starting an inspection right now.',
    );
    await tester.scrollUntilVisible(
      startNote,
      -200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(startNote, findsOneWidget);
  });

  testWidgets(
    'PIN dialog validates, and closing it does not touch a disposed controller',
    (tester) async {
      await pump(tester, allowStart: true);
      final start = find.widgetWithText(AppButton, 'START INSPECTION');
      expect(tester.widget<AppButton>(start).onPressed, isNotNull);

      await tester.tap(start);
      await tester.pumpAndSettle();
      expect(find.text('Inspection PIN'), findsOneWidget);

      // Non-digit paste attempt → stripped by the digits-only formatter.
      await tester.enterText(find.byType(TextField).first, 'abcd');
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('PIN must be 4 digits.'), findsOneWidget);

      // Too short → refused inside the dialog.
      await tester.enterText(find.byType(TextField).first, '12');
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('PIN must be 4 digits.'), findsOneWidget);

      // Mismatch → refused.
      await tester.enterText(find.byType(TextField).first, '1234');
      await tester.enterText(find.byType(TextField).last, '4321');
      await tester.tap(find.text('Start'));
      await tester.pumpAndSettle();
      expect(find.text('The PINs do not match.'), findsOneWidget);

      // Cancel: the exit animation used to throw
      // "A TextEditingController was used after being disposed".
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(find.text('Inspection PIN'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('driver exit checks the inspection PIN locally, no server call', (
    tester,
  ) async {
    final repository = _MockInspectionRepository();
    registerFallbackValue(const DriverId(101));
    registerFallbackValue(TransferMethod.webService);
    registerFallbackValue(DateTime.utc(2026));
    final d0 = DateTime.utc(2026, 1, 13);
    // عرض البداية (بعد نجاح الخروج) يجلب شاشته عبر المستودع — نجيب جواباً
    // لا يهم، والاختبار نفسه يتأكد أن الخروج لم يستدعِ دورة/سجلات/إرسال.
    when(
      () => repository.getScreen(),
    ).thenAnswer((_) async => const Left(ServerFailure(message: 'ignored')));
    when(
      () => repository.getCycle(
        driverId: any(named: 'driverId'),
        days: any(named: 'days'),
      ),
    ).thenAnswer((_) async => Right([_cycleDay(d0)]));
    when(
      () => repository.getLogs(
        driverId: any(named: 'driverId'),
        date: any(named: 'date'),
      ),
    ).thenAnswer((_) async => Right(_logFor(d0)));
    // بدء التفتيش يسجّل القفل على الخادم الآن (غير معيق) — نجيب نجاحاً.
    when(
      () => repository.registerInspectionStart(
        driverId: any(named: 'driverId'),
      ),
    ).thenAnswer((_) async => const Right(unit));

    // Decision D: the PIN is seeded through startInspection — the public
    // lifecycle — never by writing state directly.
    final notifier = _LockedInspection(repository);
    await notifier.startInspection(pin: '1234');
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          localStorageProvider.overrideWithValue(_FakeLocalStorage()),
          inspectionRepositoryProvider.overrideWithValue(repository),
          inspectionProvider.overrideWith((ref) => notifier),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const DotInspectionPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Locked: the app bar shows the lock, not the drawer menu.
    await tester.tap(find.byIcon(Icons.lock));
    await tester.pumpAndSettle();
    // Scoped to the dialog: the active view behind it shows its own
    // 'Driver exit' button now that the seed renders a full log.
    final dialogTitle = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.text('Driver exit'),
    );
    expect(dialogTitle, findsOneWidget);

    // Empty → required.
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the inspection PIN.'), findsOneWidget);

    // Wrong PIN → refused, still locked.
    await tester.enterText(find.byType(TextField), '9999');
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect PIN.'), findsOneWidget);
    expect(dialogTitle, findsOneWidget);

    // Correct PIN → inspection ends. The exit itself never touched the
    // server: no cycle/log reload, no transfer — the only repository call
    // after unlock is the start view's own screen fetch (stubbed above).
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    expect(find.text('Driver exit'), findsNothing);
    expect(find.byIcon(Icons.lock), findsNothing);
    // Seed made exactly one cycle+log call; the exit added none.
    verify(
      () => repository.getCycle(
        driverId: any(named: 'driverId'),
        days: any(named: 'days'),
      ),
    ).called(1);
    verify(
      () => repository.getLogs(
        driverId: any(named: 'driverId'),
        date: any(named: 'date'),
      ),
    ).called(1);
    verifyNever(
      () => repository.sendLogs(
        driverId: any(named: 'driverId'),
        method: any(named: 'method'),
        email: any(named: 'email'),
        routingCode: any(named: 'routingCode'),
        comment: any(named: 'comment'),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'day navigation: arrows disabled while loading; date advances only on success',
    (tester) async {
      final repository = _MockInspectionRepository();
      registerFallbackValue(const DriverId(101));
      registerFallbackValue(DateTime.utc(2026));

      final d0 = DateTime.utc(2026, 1, 13);
      final d1 = DateTime.utc(2026, 1, 12);
      final gate = Completer<Either<Failure, DotInspectionLog>>();
      when(
        () => repository.getLogs(
          driverId: any(named: 'driverId'),
          date: any(named: 'date'),
        ),
      ).thenAnswer((_) => gate.future);

      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBackendProvider.overrideWithValue(MockAdapter()),
            localStorageProvider.overrideWithValue(_FakeLocalStorage()),
            inspectionRepositoryProvider.overrideWithValue(repository),
            inspectionProvider.overrideWith(
              (ref) => _SeededInspection(repository, [
                _cycleDay(d0),
                _cycleDay(d1),
              ], _logFor(d0)),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const DotInspectionPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      String dayLabel() => tester
          .widget<Text>(find.descendant(
              of: find.byType(EldDatePaginator),
              matching: find.byType(Text)).first)
          .data!;

      expect(dayLabel(), '2026-01-13');
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();
      // In flight: the arrow is disabled and the displayed date did not
      // advance — the old (day, log) pair stays on screen.
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left),
            )
            .onPressed,
        isNull,
      );
      expect(dayLabel(), '2026-01-13');

      gate.complete(Right(_logFor(d1)));
      await tester.pumpAndSettle();
      // Success: the index and the log advanced together (newest-day edge
      // disables chevron_left again, chevron_right is available). The label
      // is the record's own logDate, not the constant displayDate.
      expect(dayLabel(), '2026-01-12');
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_left),
            )
            .onPressed,
        isNull,
      );
      expect(
        tester
            .widget<IconButton>(
              find.widgetWithIcon(IconButton, Icons.chevron_right),
            )
            .onPressed,
        isNotNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
