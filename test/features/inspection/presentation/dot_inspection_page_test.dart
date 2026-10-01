import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/domain/inspection/dot_inspection.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/inspection/presentation/pages/dot_inspection_page.dart';
import 'package:golden_feather_eld/backend/contracts/inspection_backend.dart';
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

class _InspectionBackend extends Mock implements InspectionBackend {}

/// An inspection already running and locked with PIN 1234 (no log loaded, so
/// the page shows the empty body plus the lock icon in the app bar).
class _LockedInspection extends InspectionNotifier {
  _LockedInspection(InspectionBackend backend)
      : super(backend: backend, driverId: 101, loc: lookupAppLocalizations(const Locale('en'))) {
    state = const InspectionState(
      isInspectionMode: true,
      isPinLocked: true,
      pinCode: '1234',
    );
  }
}

/// The mock `GET /eld/dot-inspection` declares every capability false and
/// returns its own guidance copy. The start view must reflect both.
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

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
    final compliance =
        find.text('This device is compliant with FMCSA 49 CFR Part 395');
    await tester.scrollUntilVisible(compliance, 200,
        scrollable: find.byType(Scrollable).first);
    expect(compliance, findsOneWidget);
  });

  testWidgets('explicit false capabilities disable the four actions', (tester) async {
    await pump(tester);

    for (final label in const [
      'START INSPECTION',
      'SEND LOGS',
      'EMAIL LOGS',
      'INFORMATION PACKET',
    ]) {
      final finder = find.widgetWithText(AppButton, label);
      await tester.scrollUntilVisible(finder, 200,
          scrollable: find.byType(Scrollable).first);
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
      await tester.scrollUntilVisible(finder, 200,
          scrollable: find.byType(Scrollable).first);
      expect(
        find.text('Not available for this account per the server.',
            skipOffstage: false),
        findsAtLeastNWidgets(1),
        reason: label,
      );
    }
    final startNote =
        find.text('The server does not allow starting an inspection right now.');
    await tester.scrollUntilVisible(startNote, -200,
        scrollable: find.byType(Scrollable).first);
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
  });

  testWidgets('driver exit checks the inspection PIN locally, no server call',
      (tester) async {
    final backend = _InspectionBackend();
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          localStorageProvider.overrideWithValue(_FakeLocalStorage()),
          inspectionBackendProvider.overrideWithValue(backend),
          inspectionProvider
              .overrideWith((ref) => _LockedInspection(backend)),
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
    expect(find.text('Driver exit'), findsOneWidget);

    // Empty → required.
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    expect(find.text('Enter the inspection PIN.'), findsOneWidget);

    // Wrong PIN → refused, still locked.
    await tester.enterText(find.byType(TextField), '9999');
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    expect(find.text('Incorrect PIN.'), findsOneWidget);
    expect(find.text('Driver exit'), findsOneWidget);

    // Correct PIN → inspection ends. Nothing was sent to the server:
    // not the inspection backend, and no login re-auth.
    await tester.enterText(find.byType(TextField), '1234');
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    expect(find.text('Driver exit'), findsNothing);
    expect(find.byIcon(Icons.lock), findsNothing);
    verifyZeroInteractions(backend);
    expect(tester.takeException(), isNull);
  });
}
