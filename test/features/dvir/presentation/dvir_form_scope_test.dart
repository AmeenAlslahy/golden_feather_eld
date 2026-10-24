import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/services/tracking_config_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/dvir/domain/entities/dvir_report.dart';
import 'package:golden_feather_eld/features/dvir/presentation/pages/dvir_form_page.dart';
import 'package:golden_feather_eld/features/dvir/presentation/widgets/dvir_form_sections.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';
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

class _VehicleRepo extends Mock implements VehicleRepository {}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<ProviderContainer> pump(
    WidgetTester tester, {
    List<Override> overrides = const [],
    DvirReport? existingReport,
  }) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
        activeBackendProvider.overrideWithValue(MockAdapter()),
        localStorageProvider.overrideWithValue(_FakeLocalStorage()),
        networkInfoProvider.overrideWithValue(_OnlineNetwork()),
        trackingConfigStorageProvider.overrideWithValue(_FakeTrackingStorage()),
        ...overrides,
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: DvirFormPage(existingReport: existingReport),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    return container;
  }

  testWidgets('editing a DVIR trailer never rewrites the daily form', (
    tester,
  ) async {
    final container = await pump(tester);
    container.read(dashboardDataProvider.notifier).updateTrailers(['FORM-1']);
    await tester.pump();

    final trailerField = find.descendant(
      of: find.byType(DvirTrailerSection),
      matching: find.byType(TextFormField),
    );
    expect(trailerField, findsOneWidget);

    await tester.enterText(trailerField, 'DVIR-9');
    await tester.pump();

    expect(container.read(dashboardDataProvider).trailerId, 'FORM-1');
  });

  testWidgets('choosing a DVIR vehicle never rewrites the dashboard vehicle', (
    tester,
  ) async {
    const vehicleA = Vehicle(
      id: 'A-ID',
      uniqueId: 'A-U',
      deviceId: 101,
      name: 'Truck A',
      year: '2020',
    );
    const vehicleB = Vehicle(
      id: 'B-ID',
      uniqueId: 'B-U',
      deviceId: 102,
      name: 'Truck B',
      year: '2021',
    );
    final repo = _VehicleRepo();
    when(
      () => repo.getVehicles(),
    ).thenAnswer((_) async => const Right([vehicleA, vehicleB]));

    final container = await pump(
      tester,
      overrides: [vehicleProvider.overrideWith((ref) => VehicleNotifier(repo))],
    );
    container.read(dashboardDataProvider.notifier).updateVehicle(vehicleA);
    await tester.pump();

    await tester.tap(find.text(vehicleA.displayName));
    await tester.pumpAndSettle();
    await tester.tap(find.text(vehicleB.displayName));
    await tester.pumpAndSettle();

    expect(container.read(dashboardDataProvider).vehicleId, vehicleA.id);
    expect(
      find.descendant(
        of: find.byType(DvirVehicleSection),
        matching: find.text(vehicleB.displayName),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'read-only report shows the server condition status without inference',
    (tester) async {
      const report = DvirReport(
        id: '',
        type: InspectionType.preTrip,
        driverName: 'Driver',
        vehicleId: 'TRK-1',
        condition: VehicleCondition.needsRepair,
        conditionStatus: DvirConditionStatus.defectsCorrected,
        isSubmitted: true,
      );

      await pump(tester, existingReport: report);
      await tester.scrollUntilVisible(
        find.text('Defects Corrected'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Defects Corrected'), findsOneWidget);
      expect(find.text('Has Defects'), findsNothing);
    },
  );
}
