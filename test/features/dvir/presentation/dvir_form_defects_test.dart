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
import 'package:golden_feather_eld/features/dvir/presentation/widgets/dvir_form_sections.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _OnlineNetwork implements NetworkInfo {
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

class _FakeTrackingStorage extends Mock
    implements TrackingConfigStorageService {
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

  Future<void> pump(WidgetTester tester, {bool seedVehicle = false}) async {
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
          trackingConfigStorageProvider.overrideWithValue(
            _FakeTrackingStorage(),
          ),
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
    // البذر بعد أول إطار (خارج مرحلة البناء — تعديل مزوّد أثناء البناء
    // ممنوع): مستمع لوحة القيادة في مزوّد النموذج يعيد حل هوية المركبة
    // تفاعلياً. ProviderScope يبقى في الشجرة ليُدمَّر معها فيُلغى مؤقّت
    // keepAlive الخاص بالكتالوج قبل فحص timersPending.
    if (seedVehicle) {
      ProviderScope.containerOf(tester.element(find.byType(DvirFormPage)))
          .read(dashboardDataProvider.notifier)
          .updateVehicle(
            const Vehicle(
              id: 'V-ID',
              uniqueId: 'V-U',
              deviceId: 503,
              name: 'Truck V',
              year: '2021',
            ),
          );
    }
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> openAddDefects(WidgetTester tester) async {
    final defectsCell = find.descendant(
      of: find.byType(DvirVehicleSection),
      matching: find.byType(InkWell),
    );
    await tester.tap(defectsCell);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> scrollToStatus(WidgetTester tester, String label) async {
    await tester.scrollUntilVisible(
      find.text(label),
      200,
      scrollable: find.byType(Scrollable).first,
    );
  }

  testWidgets('tapping defects opens the live catalog list', (tester) async {
    await pump(tester, seedVehicle: true);
    await openAddDefects(tester);

    expect(find.text('Vehicle - Defects'), findsOneWidget);
    expect(find.text('Service brakes'), findsOneWidget);
    expect(find.text('Safety affecting'), findsWidgets);
    // The list is lazy; the last regulatory item is reachable by scrolling.
    final last = find.text('Emergency equipment');
    await tester.scrollUntilVisible(
      last,
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(last, findsOneWidget);
  });

  testWidgets(
    'picking an item updates field and switches status to Has Defects',
    (tester) async {
      await pump(tester, seedVehicle: true);
      await openAddDefects(tester);

      await tester.tap(find.widgetWithText(CheckboxListTile, 'Tires'));
      await tester.pump();
      // A note field appears for the checked item.
      expect(
        find.widgetWithText(TextField, 'Description (optional)'),
        findsOneWidget,
      );

      await tester.tap(find.text('OK'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Tires'), findsOneWidget);
      // Status label follows the pick (wire value 'Has Defects').
      await scrollToStatus(tester, 'Has Defects');
      expect(find.text('Has Defects'), findsOneWidget);
    },
  );

  testWidgets('CANCEL keeps the report free of catalog defects', (
    tester,
  ) async {
    await pump(tester, seedVehicle: true);
    await openAddDefects(tester);

    await tester.tap(find.widgetWithText(CheckboxListTile, 'Service brakes'));
    await tester.pump();
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await scrollToStatus(tester, 'Vehicle Condition Satisfactory');
    expect(find.text('Vehicle Condition Satisfactory'), findsOneWidget);
  });

  testWidgets('re-opening defects catalog preserves previous selections', (
    tester,
  ) async {
    await pump(tester, seedVehicle: true);
    await openAddDefects(tester);
    await tester.tap(find.widgetWithText(CheckboxListTile, 'Tires'));
    await tester.pump();
    await tester.tap(find.text('OK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tires'), findsOneWidget);

    await openAddDefects(tester);
    expect(
      find.widgetWithText(CheckboxListTile, 'Service brakes'),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    await tester.pump();
  });

  testWidgets(
    'tapping on Vehicle defects field opens the vehicle defect catalog',
    (tester) async {
      await pump(tester, seedVehicle: true);
      final vehicleDefectsCell = find.widgetWithText(InkWell, 'Defects').first;
      await tester.tap(vehicleDefectsCell);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Vehicle - Defects'), findsOneWidget);
      expect(find.text('Service brakes'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
    },
  );

  testWidgets(
    'tapping on Trailer defects field opens the trailer defect catalog',
    (tester) async {
      await pump(tester, seedVehicle: true);
      final trailerField = find.descendant(
        of: find.byType(DvirTrailerSection),
        matching: find.byType(TextField),
      );
      await tester.enterText(trailerField, '5555');
      await tester.pump();
      final trailerDefectsCell = find.widgetWithText(InkWell, 'Defects').last;
      await tester.tap(trailerDefectsCell);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Trailer - Defects'), findsOneWidget);
      expect(find.text('Brake Connections'), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pump();
    },
  );
}
