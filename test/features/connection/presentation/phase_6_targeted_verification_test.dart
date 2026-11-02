import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/services/bluetooth_service.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/core/widgets/app_text_field.dart';
import 'package:golden_feather_eld/core/widgets/golden_app_bar.dart';
import 'package:golden_feather_eld/features/account/application/models/rules_screen_model.dart';
import 'package:golden_feather_eld/features/account/presentation/providers/rules_screen_provider.dart';
import 'package:golden_feather_eld/features/codriver/data/datasources/codriver_local_cache.dart';
import 'package:golden_feather_eld/features/codriver/data/providers/codriver_repository_providers.dart';
import 'package:golden_feather_eld/features/codriver/domain/current_codriver.dart';
import 'package:golden_feather_eld/features/codriver/domain/entities/codriver.dart';
import 'package:golden_feather_eld/features/connection/presentation/pages/eld_connection_page.dart';
import 'package:golden_feather_eld/features/connection/presentation/providers/hardware_status_provider.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/tracking/duty_status_tracker.dart';
import 'package:golden_feather_eld/features/hos/presentation/pages/change_status_page.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/change_status_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/hos_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/widgets/status_option_tiles.dart';
import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:golden_feather_eld/features/vehicle/data/datasources/vehicle_local_cache.dart';
import 'package:golden_feather_eld/features/vehicle/data/providers/vehicle_repository_providers.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _Bluetooth extends Mock implements BluetoothService {}

class _OnlineNetwork implements NetworkInfo {
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get onConnectionChange => const Stream.empty();
}

class _FakeVehicleCache implements VehicleLocalCache {
  @override
  Future<void> clear() async {}
  @override
  RawJson? load({bool companyFleet = false}) => null;
  @override
  Future<void> save(RawJson rawJson, {bool companyFleet = false}) async {}
}

class _FakeCoDriverCache implements CoDriverLocalCache {
  @override
  Future<void> clear() async {}
  @override
  List<CoDriver>? loadAvailableDrivers() => [];
  @override
  CurrentCoDriverRead? loadCurrentCoDriver() => null;
  @override
  Future<void> saveAvailableDrivers(List<CoDriver> drivers) async {}
  @override
  Future<void> saveCurrentCoDriver(CurrentCoDriverRead current) async {}
}

class _FakeDashboardNotifier extends StateNotifier<DashboardData>
    implements DashboardNotifier {
  _FakeDashboardNotifier([String vehicleDisplayName = '', String vehicleId = ''])
      : super(DashboardData(
          driverName: 'John Doe',
          vehicleId: vehicleId,
          vehicleDisplayName: vehicleDisplayName,
        ));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLocalStorage extends Mock implements LocalStorageService {
  @override
  String get backendType => 'mock';
  @override
  String get serverUrl => 'https://example.com';
  @override
  String get language => 'en';
  @override
  String? get selectedVehicleId => 'VH-101';
  @override
  HosConfiguration get hosConfiguration => HosConfiguration.usa70_8();
}

class _FakeVehicleNotifier extends StateNotifier<VehicleState>
    implements VehicleNotifier {
  _FakeVehicleNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _HosNotifier extends StateNotifier<HosEngineResult>
    implements HosNotifier {
  _HosNotifier(DutyStatus current)
      : super(HosEngineReady(HosStatusUpdate(
          currentStatus: current,
          limits: const HosLimits(
            remainingDriveMinutes: 600,
            remainingShiftMinutes: 800,
            remainingCycleHours: 60,
            breakRequired: false,
            breakRemainingMinutes: 0,
          ),
          alerts: const [],
          violations: const [],
          remainingDriveMinutes: 600,
          remainingShiftMinutes: 800,
          remainingCycleHours: 60,
          breakRequired: false,
          breakRemainingMinutes: 0,
        )));

  @override
  Future<ManualDutyChangeResult> changeStatus(DutyStatus newStatus,
      {String? annotation,
      bool isYardMoves = false,
      double? latitude,
      double? longitude}) async {
    return const ManualDutyChangeResult();
  }

  @override
  void refresh() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Phase 6B Targeted Tests — Vehicle Connection', () {
    testWidgets('Arabic fallback: displays اختيار المركبة when no vehicle selected',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBackendProvider.overrideWithValue(MockAdapter()),
            localStorageProvider.overrideWithValue(_FakeLocalStorage()),
            networkInfoProvider.overrideWithValue(_OnlineNetwork()),
            coDriverLocalCacheProvider.overrideWithValue(_FakeCoDriverCache()),
            vehicleLocalCacheProvider.overrideWithValue(_FakeVehicleCache()),
            bluetoothServiceProvider.overrideWithValue(_Bluetooth()),
            dashboardDataProvider.overrideWith((ref) =>
                _FakeDashboardNotifier('Select a vehicle', 'No Vehicle')),
            vehicleProvider.overrideWith((ref) =>
                _FakeVehicleNotifier(const VehicleState(selectedVehicle: null))),
            hardwareStatusProvider.overrideWith((ref) async =>
                const ConnectivityStatus(connectionStatus: 'DISCONNECTED')),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: EldConnectionPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // GoldenAppBar has titleText 'اختيار المركبة'
      final appBar = tester.widget<GoldenAppBar>(find.byType(GoldenAppBar));
      expect(appBar.titleText, 'اختيار المركبة');
      expect(find.text('Select a vehicle'), findsNothing);
    });

    testWidgets('English with vehicle: displays real vehicle name', (tester) async {
      const vehicle = Vehicle(
        id: 'VH-777',
        name: 'Kenworth W900 #77',
        year: '2024',
        uniqueId: '00:1B:44:11:3A:B7',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBackendProvider.overrideWithValue(MockAdapter()),
            localStorageProvider.overrideWithValue(_FakeLocalStorage()),
            networkInfoProvider.overrideWithValue(_OnlineNetwork()),
            coDriverLocalCacheProvider.overrideWithValue(_FakeCoDriverCache()),
            vehicleLocalCacheProvider.overrideWithValue(_FakeVehicleCache()),
            bluetoothServiceProvider.overrideWithValue(_Bluetooth()),
            dashboardDataProvider.overrideWith((ref) =>
                _FakeDashboardNotifier('Kenworth W900 #77', 'VH-777')),
            vehicleProvider.overrideWith((ref) =>
                _FakeVehicleNotifier(const VehicleState(selectedVehicle: vehicle))),
            hardwareStatusProvider.overrideWith((ref) async =>
                const ConnectivityStatus(connectionStatus: 'DISCONNECTED')),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: EldConnectionPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final appBar = tester.widget<GoldenAppBar>(find.byType(GoldenAppBar));
      expect(appBar.titleText, 'Kenworth W900 #77');
    });

    testWidgets('MAC Address field has Directionality LTR and AppButton roles',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBackendProvider.overrideWithValue(MockAdapter()),
            localStorageProvider.overrideWithValue(_FakeLocalStorage()),
            networkInfoProvider.overrideWithValue(_OnlineNetwork()),
            coDriverLocalCacheProvider.overrideWithValue(_FakeCoDriverCache()),
            vehicleLocalCacheProvider.overrideWithValue(_FakeVehicleCache()),
            bluetoothServiceProvider.overrideWithValue(_Bluetooth()),
            dashboardDataProvider.overrideWith((ref) =>
                _FakeDashboardNotifier('Select a vehicle', 'No Vehicle')),
            hardwareStatusProvider.overrideWith((ref) async =>
                const ConnectivityStatus(connectionStatus: 'DISCONNECTED')),
          ],
          child: const MaterialApp(
            locale: Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: EldConnectionPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Directionality around AppTextField is LTR
      final ltrFinder = find.ancestor(
        of: find.byType(AppTextField),
        matching: find.byWidgetPredicate(
            (w) => w is Directionality && w.textDirection == TextDirection.ltr),
      );
      expect(ltrFinder, findsWidgets);

      // Connect button is primary role
      final buttons = tester.widgetList<AppButton>(find.byType(AppButton)).toList();
      expect(buttons.length, 2);
      expect(buttons[0].type, EldButtonType.primary);
      expect(buttons[1].type, EldButtonType.secondary);
    });
  });

  group('Phase 6B Targeted Tests — Change Duty Status', () {
    testWidgets('Radio selection changes state and Update button toggles',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBackendProvider.overrideWithValue(MockAdapter()),
            localStorageProvider.overrideWithValue(_FakeLocalStorage()),
            networkInfoProvider.overrideWithValue(_OnlineNetwork()),
            coDriverLocalCacheProvider.overrideWithValue(_FakeCoDriverCache()),
            vehicleLocalCacheProvider.overrideWithValue(_FakeVehicleCache()),
            bluetoothServiceProvider.overrideWithValue(_Bluetooth()),
            dashboardDataProvider.overrideWith((ref) =>
                _FakeDashboardNotifier('Freightliner Cascadia #101', 'VH-101')),
            hosStatusProvider.overrideWith((ref) => _HosNotifier(DutyStatus.offDuty)),
            rulesScreenProvider.overrideWith((ref) async => RulesScreenModel(
                  ruleSource: 'Federal',
                  cycleRule: 'USA 70/8',
                  cargoType: 'Property',
                  restart: '34 Hour Restart',
                  restBreak: '30 Minute Rest Break Required',
                  sixteenHourException: false,
                  options: const {},
                  editableFields: const {},
                  readOnlyFields: const {},
                  fixedSettings: const {
                    'personalConveyanceEnabled': true,
                    'yardMoveEnabled': true,
                  },
                  notice: '',
                  limits: HosConfiguration.usa70_8(),
                )),
            currentVehicleSpeedProvider.overrideWith((ref) => 0.0),
            changeStatusProvider.overrideWith(
              (ref) => ChangeStatusNotifier(
                ref,
                initialStatus: DutyStatus.offDuty,
                isYardMoves: false,
                initialLocation: 'Dallas, TX',
                isPersonalConveyanceAllowed: true,
                isYardMoveAllowed: true,
                isVehicleMoving: false,
              ),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ChangeStatusPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Initially, Update button is disabled because current status is OFF and no new status is selected
      final updateBtnBefore =
          tester.widget<AppButton>(find.widgetWithText(AppButton, 'UPDATE'));
      expect(updateBtnBefore.onPressed, isNull);

      // Tap 'On Duty' option tile
      final onDutyTile = find.widgetWithText(StatusOptionTile, 'On Duty');
      expect(onDutyTile, findsOneWidget);
      await tester.tap(onDutyTile);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Update button is now enabled
      final updateBtnAfter =
          tester.widget<AppButton>(find.widgetWithText(AppButton, 'UPDATE'));
      expect(updateBtnAfter.onPressed, isNotNull);
    });

    testWidgets('Vehicle moving restriction: options are disabled and warning card shown',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBackendProvider.overrideWithValue(MockAdapter()),
            localStorageProvider.overrideWithValue(_FakeLocalStorage()),
            networkInfoProvider.overrideWithValue(_OnlineNetwork()),
            coDriverLocalCacheProvider.overrideWithValue(_FakeCoDriverCache()),
            vehicleLocalCacheProvider.overrideWithValue(_FakeVehicleCache()),
            bluetoothServiceProvider.overrideWithValue(_Bluetooth()),
            dashboardDataProvider.overrideWith((ref) =>
                _FakeDashboardNotifier('Freightliner Cascadia #101', 'VH-101')),
            hosStatusProvider.overrideWith((ref) => _HosNotifier(DutyStatus.offDuty)),
            rulesScreenProvider.overrideWith((ref) async => RulesScreenModel(
                  ruleSource: 'Federal',
                  cycleRule: 'USA 70/8',
                  cargoType: 'Property',
                  restart: '34 Hour Restart',
                  restBreak: '30 Minute Rest Break Required',
                  sixteenHourException: false,
                  options: const {},
                  editableFields: const {},
                  readOnlyFields: const {},
                  fixedSettings: const {
                    'personalConveyanceEnabled': false,
                    'yardMoveEnabled': false,
                  },
                  notice: '',
                  limits: HosConfiguration.usa70_8(),
                )),
            currentVehicleSpeedProvider.overrideWith((ref) => 15.0),
            changeStatusProvider.overrideWith(
              (ref) => ChangeStatusNotifier(
                ref,
                initialStatus: DutyStatus.offDuty,
                isYardMoves: false,
                initialLocation: 'Dallas, TX',
                isPersonalConveyanceAllowed: false,
                isYardMoveAllowed: false,
                isVehicleMoving: true,
              ),
            ),
          ],
          child: const MaterialApp(
            locale: Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: ChangeStatusPage(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Vehicle moving warning is displayed
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);

      // Non-driving options (Off Duty, Sleeper, On Duty) are disabled while moving
      final offDutyTile =
          tester.widget<StatusOptionTile>(find.widgetWithText(StatusOptionTile, 'Off Duty'));
      final sleeperTile =
          tester.widget<StatusOptionTile>(find.widgetWithText(StatusOptionTile, 'Sleeper'));
      final onDutyTile =
          tester.widget<StatusOptionTile>(find.widgetWithText(StatusOptionTile, 'On Duty'));
      final drivingTile =
          tester.widget<StatusOptionTile>(find.widgetWithText(StatusOptionTile, 'Driving'));

      expect(offDutyTile.enabled, isFalse);
      expect(sleeperTile.enabled, isFalse);
      expect(onDutyTile.enabled, isFalse);
      expect(drivingTile.enabled, isTrue); // Driving is the only valid destination while vehicle is moving
    });
  });
}
