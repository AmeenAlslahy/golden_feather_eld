import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/services/tracking_config_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/dvir/presentation/pages/dvir_form_page.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OnlineNetwork implements NetworkInfo {
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

class _FakeTrackingStorage extends Mock implements TrackingConfigStorageService {
  @override
  String get deviceId => '1001';
}

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

/// The §396.11 catalog picker on the DVIR insert screen, backed by the mock
/// `GET /eld/dvir/catalog` (11 regulatory items).
void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          localStorageProvider.overrideWithValue(_FakeLocalStorage()),
          networkInfoProvider.overrideWithValue(_OnlineNetwork()),
          trackingConfigStorageProvider.overrideWithValue(_FakeTrackingStorage()),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: const DvirFormPage(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> openAddDefects(WidgetTester tester) async {
    final defectsCell = find.widgetWithText(InkWell, 'Defects').first;
    await tester.tap(defectsCell);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('tapping defects opens the live catalog list', (tester) async {
    await pump(tester);
    await openAddDefects(tester);

    expect(find.text('Vehicle - Defects'), findsOneWidget);
    expect(find.text('Service brakes'), findsOneWidget);
    expect(find.text('Safety affecting'), findsWidgets);
    // The list is lazy; the last regulatory item is reachable by scrolling.
    final last = find.text('Emergency equipment');
    await tester.scrollUntilVisible(last, 100,
        scrollable: find.byType(Scrollable).last);
    expect(last, findsOneWidget);
  });

  testWidgets('picking an item updates field and switches status to Has Defects',
      (tester) async {
    await pump(tester);
    await openAddDefects(tester);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Tires'));
    await tester.pump();
    // A note field appears for the checked item.
    expect(find.widgetWithText(TextField, 'Description (optional)'), findsOneWidget);

    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Tires'), findsOneWidget);
    // Status label follows the pick (wire value 'Has Defects').
    expect(find.text('Has Defects'), findsOneWidget);
  });

  testWidgets('CANCEL keeps the report free of catalog defects', (tester) async {
    await pump(tester);
    await openAddDefects(tester);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Horn'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Vehicle Condition Satisfactory'), findsOneWidget);
  });

  testWidgets('re-opening defects catalog preserves previous selections',
      (tester) async {
    await pump(tester);
    await openAddDefects(tester);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Tires'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tires'), findsOneWidget);

    await openAddDefects(tester);
    await tester.scrollUntilVisible(find.text('Tires'), 100, scrollable: find.byType(Scrollable).last);
    expect(find.text('Tires'), findsWidgets);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
  });

  testWidgets('tapping on Vehicle defects field opens the vehicle defect catalog',
      (tester) async {
    await pump(tester);
    final vehicleDefectsCell = find.widgetWithText(InkWell, 'Defects').first;
    await tester.tap(vehicleDefectsCell);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Vehicle - Defects'), findsOneWidget);
    expect(find.text('Service brakes'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
  });

  testWidgets('tapping on Trailer defects field opens the trailer defect catalog',
      (tester) async {
    await pump(tester);
    final trailerDefectsCell = find.widgetWithText(InkWell, 'Defects').last;
    await tester.tap(trailerDefectsCell);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Trailer - Defects'), findsOneWidget);
    expect(find.text('Brake Connections'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
  });
}

