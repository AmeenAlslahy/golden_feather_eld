import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
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
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
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
  _FakeDashboardNotifier(String vehicleDisplayName)
      : super(DashboardData(
          driverName: 'John Doe',
          vehicleId: 'VH-101',
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

RulesScreenModel _rules(Map<String, dynamic> fixed) => RulesScreenModel(
      ruleSource: 'Federal',
      cycleRule: 'USA 70/8',
      cargoType: 'Property',
      restart: '34 Hour Restart',
      restBreak: '30 Minute Rest Break Required',
      sixteenHourException: false,
      options: const {},
      editableFields: const {},
      readOnlyFields: const {},
      fixedSettings: fixed,
      notice: '',
      limits: HosConfiguration.usa70_8(),
    );

class _RealImageBinding extends AutomatedTestWidgetsFlutterBinding {
  @override
  Future<ui.Codec> instantiateImageCodecWithSize(
    ui.ImmutableBuffer buffer, {
    ui.TargetImageSizeCallback? getTargetSize,
  }) async {
    if (getTargetSize != null) {
      final descriptor = await ui.ImageDescriptor.encoded(buffer);
      final targetSize = getTargetSize(descriptor.width, descriptor.height);
      return descriptor.instantiateCodec(
        targetWidth: targetSize.width,
        targetHeight: targetSize.height,
      );
    }
    return ui.instantiateImageCodecFromBuffer(buffer);
  }
}

void main() {
  _RealImageBinding();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    try {
      final robotoLoader = FontLoader('Roboto');
      final regularFile = File('assets/fonts/google_fonts/Roboto-Regular.ttf');
      if (regularFile.existsSync()) {
        robotoLoader.addFont(
          Future.value(ByteData.view(regularFile.readAsBytesSync().buffer)),
        );
      }
      final mediumFile = File('assets/fonts/google_fonts/Roboto-Medium.ttf');
      if (mediumFile.existsSync()) {
        robotoLoader.addFont(
          Future.value(ByteData.view(mediumFile.readAsBytesSync().buffer)),
        );
      }
      final boldFile = File('assets/fonts/google_fonts/Roboto-Bold.ttf');
      if (boldFile.existsSync()) {
        robotoLoader.addFont(
          Future.value(ByteData.view(boldFile.readAsBytesSync().buffer)),
        );
      }
      await robotoLoader.load();
    } catch (_) {}

    try {
      final iconLoader = FontLoader('MaterialIcons');
      final iconFile = File('assets/fonts/MaterialIcons-Regular.otf');
      if (iconFile.existsSync()) {
        iconLoader.addFont(
          Future.value(ByteData.view(iconFile.readAsBytesSync().buffer)),
        );
        await iconLoader.load();
      }
    } catch (_) {}
  });

  Future<void> captureScreen({
    required WidgetTester tester,
    required GlobalKey key,
    required String filename,
  }) async {
    await tester.binding.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final outDir = Directory('build/screenshots');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      await File('build/screenshots/$filename').writeAsBytes(bytes);

      const artifactDir =
          r'C:\Users\Owner\.gemini\antigravity-ide\brain\5a94c5e4-5889-4e0e-a640-28bea96b9f8a';
      final artDir = Directory(artifactDir);
      if (artDir.existsSync()) {
        await File('$artifactDir/$filename').writeAsBytes(bytes);
      }
    });
  }

  Widget buildConnectionHarness({
    required GlobalKey repaintKey,
    required ThemeData theme,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    double screenWidth = 375,
    ConnectivityStatus? status,
    EldConnectionState? connectionState,
    Vehicle? selectedVehicle,
  }) {
    return RepaintBoundary(
      key: repaintKey,
      child: ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          localStorageProvider.overrideWithValue(_FakeLocalStorage()),
          networkInfoProvider.overrideWithValue(_OnlineNetwork()),
          coDriverLocalCacheProvider.overrideWithValue(_FakeCoDriverCache()),
          vehicleLocalCacheProvider.overrideWithValue(_FakeVehicleCache()),
          bluetoothServiceProvider.overrideWithValue(_Bluetooth()),
          dashboardDataProvider.overrideWith((ref) => _FakeDashboardNotifier(
                selectedVehicle?.name ?? 'Select a vehicle',
              )),
          if (status != null)
            hardwareStatusProvider.overrideWith((ref) async => status),
          if (connectionState != null)
            eldConnectionProvider.overrideWith((ref) {
              final notifier = EldConnectionNotifier(ref);
              notifier.state = connectionState;
              return notifier;
            }),
          if (selectedVehicle != null)
            vehicleProvider.overrideWith((ref) {
              return _FakeVehicleNotifier(VehicleState(
                selectedVehicle: selectedVehicle,
                vehicles: [selectedVehicle],
              ));
            }),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(screenWidth, 812),
              textScaler: TextScaler.linear(textScale),
            ),
            child: const EldConnectionPage(),
          ),
        ),
      ),
    );
  }

  Widget buildChangeStatusHarness({
    required GlobalKey repaintKey,
    required ThemeData theme,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    double screenWidth = 375,
    DutyStatus currentStatus = DutyStatus.offDuty,
    DutyStatusOption? selectedOption,
    bool isMoving = false,
    String? customLocation,
    String? notes,
    bool pcAllowed = true,
    bool ymAllowed = true,
  }) {
    return RepaintBoundary(
      key: repaintKey,
      child: ProviderScope(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          localStorageProvider.overrideWithValue(_FakeLocalStorage()),
          networkInfoProvider.overrideWithValue(_OnlineNetwork()),
          coDriverLocalCacheProvider.overrideWithValue(_FakeCoDriverCache()),
          vehicleLocalCacheProvider.overrideWithValue(_FakeVehicleCache()),
          bluetoothServiceProvider.overrideWithValue(_Bluetooth()),
          dashboardDataProvider.overrideWith((ref) => _FakeDashboardNotifier(
                'Freightliner Cascadia #101',
              )),
          hosStatusProvider.overrideWith((ref) => _HosNotifier(currentStatus)),
          rulesScreenProvider.overrideWith((ref) async => _rules({
                'personalConveyanceEnabled': pcAllowed,
                'yardMoveEnabled': ymAllowed,
              })),
          currentVehicleSpeedProvider.overrideWith((ref) => isMoving ? 15.0 : 0.0),
          localStorageProvider.overrideWithValue(_FakeLocalStorage()),
          changeStatusProvider.overrideWith((ref) {
            final notifier = ChangeStatusNotifier(
              ref,
              initialStatus: currentStatus,
              isYardMoves: false,
              initialLocation: 'Denver, CO (39.7392° N, 104.9903° W)',
              isPersonalConveyanceAllowed: pcAllowed,
              isYardMoveAllowed: ymAllowed,
              isVehicleMoving: isMoving,
            );
            if (selectedOption != null) {
              notifier.selectOption(selectedOption);
            }
            if (customLocation != null) {
              notifier.updateCustomLocation(customLocation);
            }
            if (notes != null) {
              notifier.updateNotes(notes);
            }
            return notifier;
          }),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: theme,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(screenWidth, 812),
              textScaler: TextScaler.linear(textScale),
            ),
            child: const ChangeStatusPage(),
          ),
        ),
      ),
    );
  }

  group('Phase 6B — Screenshots Generation Suite', () {
    // ═════════════════════════════════════════════════════════════════════════
    // VEHICLE CONNECTION SCREEN
    // ═════════════════════════════════════════════════════════════════════════
    testWidgets('1. Vehicle Connection — Arabic Light', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildConnectionHarness(
        repaintKey: key,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        status: const ConnectivityStatus(
          connectionStatus: 'DISCONNECTED',
          eldIdentifier: '00:1B:44:11:3A:B7',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'vehicle_connection_arabic_light.png',
      );
    });

    testWidgets('2. Vehicle Connection — Arabic Dark', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildConnectionHarness(
        repaintKey: key,
        theme: AppTheme.dark,
        locale: const Locale('ar'),
        status: const ConnectivityStatus(
          connectionStatus: 'DISCONNECTED',
          eldIdentifier: '00:1B:44:11:3A:B7',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'vehicle_connection_arabic_dark.png',
      );
    });

    testWidgets('3. Vehicle Connection — English Light', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildConnectionHarness(
        repaintKey: key,
        theme: AppTheme.light,
        locale: const Locale('en'),
        selectedVehicle: const Vehicle(
          id: 'VH-101',
          name: 'Freightliner Cascadia #101',
          year: '2023',
          uniqueId: '00:1B:44:11:3A:B7',
        ),
        status: const ConnectivityStatus(
          connectionStatus: 'DISCONNECTED',
          eldIdentifier: '00:1B:44:11:3A:B7',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'vehicle_connection_english.png',
      );
    });

    testWidgets('4. Vehicle Connection — Spanish Light', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildConnectionHarness(
        repaintKey: key,
        theme: AppTheme.light,
        locale: const Locale('es'),
        status: const ConnectivityStatus(
          connectionStatus: 'DISCONNECTED',
          eldIdentifier: '00:1B:44:11:3A:B7',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'vehicle_connection_spanish.png',
      );
    });

    testWidgets('5. Vehicle Connection — Invalid MAC', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildConnectionHarness(
        repaintKey: key,
        theme: AppTheme.light,
        locale: const Locale('en'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await tester.enterText(find.byType(TextField).first, 'INVALID-MAC-ZZZ');
      await tester.tap(find.widgetWithText(AppButton, 'CONNECT'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'vehicle_connection_invalid_mac.png',
      );
    });

    testWidgets('6. Vehicle Connection — Connecting', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildConnectionHarness(
        repaintKey: key,
        theme: AppTheme.light,
        locale: const Locale('en'),
        connectionState: EldConnectionState(isConnecting: true),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'vehicle_connection_connecting.png',
      );
    });

    testWidgets('7. Vehicle Connection — Connection Error', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildConnectionHarness(
        repaintKey: key,
        theme: AppTheme.light,
        locale: const Locale('en'),
        connectionState: EldConnectionState(
          hasFailed: true,
          errorMessage: 'bluetooth_failed',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'vehicle_connection_error.png',
      );
    });

    testWidgets('8. Vehicle Connection — 320dp', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(640, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildConnectionHarness(
        repaintKey: key,
        theme: AppTheme.light,
        locale: const Locale('en'),
        screenWidth: 320,
        status: const ConnectivityStatus(
          connectionStatus: 'DISCONNECTED',
          eldIdentifier: '00:1B:44:11:3A:B7',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'vehicle_connection_320dp.png',
      );
    });

    testWidgets('9. Vehicle Connection — 2.0x Text Scaling', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildConnectionHarness(
        repaintKey: key,
        theme: AppTheme.light,
        locale: const Locale('en'),
        textScale: 2.0,
        status: const ConnectivityStatus(
          connectionStatus: 'DISCONNECTED',
          eldIdentifier: '00:1B:44:11:3A:B7',
        ),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'vehicle_connection_2_0x_text_scaling.png',
      );
    });

    // ═════════════════════════════════════════════════════════════════════════
    // CHANGE DUTY STATUS SCREEN
    // ═════════════════════════════════════════════════════════════════════════
    testWidgets('10. Change Duty Status — Arabic Light', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildChangeStatusHarness(
        repaintKey: key,
        theme: AppTheme.light,
        locale: const Locale('ar'),
        currentStatus: DutyStatus.offDuty,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'change_duty_status_arabic_light.png',
      );
    });

    testWidgets('11. Change Duty Status — Arabic Dark', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildChangeStatusHarness(
        repaintKey: key,
        theme: AppTheme.dark,
        locale: const Locale('ar'),
        currentStatus: DutyStatus.offDuty,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'change_duty_status_arabic_dark.png',
      );
    });

    testWidgets('12. Change Duty Status — English Light', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildChangeStatusHarness(
        repaintKey: key,
        theme: AppTheme.light,
        locale: const Locale('en'),
        currentStatus: DutyStatus.offDuty,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'change_duty_status_english.png',
      );
    });

    testWidgets('13. Change Duty Status — Spanish Light', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildChangeStatusHarness(
        repaintKey: key,
        theme: AppTheme.light,
        locale: const Locale('es'),
        currentStatus: DutyStatus.offDuty,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'change_duty_status_spanish.png',
      );
    });

    testWidgets('14. Change Duty Status — Selected Status', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildChangeStatusHarness(
        repaintKey: key,
        theme: AppTheme.light,
        currentStatus: DutyStatus.offDuty,
        selectedOption: DutyStatusOption.onDuty,
        notes: 'Pre-trip inspection completed',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'change_duty_status_selected_status.png',
      );
    });

    testWidgets('15. Change Duty Status — Disabled Status (Moving)',
        (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildChangeStatusHarness(
        repaintKey: key,
        theme: AppTheme.light,
        currentStatus: DutyStatus.driving,
        isMoving: true,
        pcAllowed: false,
        ymAllowed: false,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'change_duty_status_disabled_status.png',
      );
    });

    testWidgets('16. Change Duty Status — Location / Remarks', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildChangeStatusHarness(
        repaintKey: key,
        theme: AppTheme.light,
        currentStatus: DutyStatus.offDuty,
        selectedOption: DutyStatusOption.onDuty,
        customLocation: 'Exit 104, I-70 West, Golden, CO',
        notes: 'Driver load check and vehicle safety walkthrough',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'change_duty_status_location_remarks.png',
      );
    });

    testWidgets('17. Change Duty Status — Update Enabled', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildChangeStatusHarness(
        repaintKey: key,
        theme: AppTheme.light,
        currentStatus: DutyStatus.offDuty,
        selectedOption: DutyStatusOption.onDuty,
        notes: 'Shift start inspection',
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'change_duty_status_update_enabled.png',
      );
    });

    testWidgets('18. Change Duty Status — Update Disabled', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // No new status selected -> update button is disabled
      await tester.pumpWidget(buildChangeStatusHarness(
        repaintKey: key,
        theme: AppTheme.light,
        currentStatus: DutyStatus.offDuty,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'change_duty_status_update_disabled.png',
      );
    });

    testWidgets('19. Change Duty Status — 320dp', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(640, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildChangeStatusHarness(
        repaintKey: key,
        theme: AppTheme.light,
        screenWidth: 320,
        currentStatus: DutyStatus.offDuty,
        selectedOption: DutyStatusOption.sleeperBerth,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'change_duty_status_320dp.png',
      );
    });

    testWidgets('20. Change Duty Status — 2.0x Text Scaling', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildChangeStatusHarness(
        repaintKey: key,
        theme: AppTheme.light,
        textScale: 2.0,
        currentStatus: DutyStatus.offDuty,
        selectedOption: DutyStatusOption.onDuty,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(
        tester: tester,
        key: key,
        filename: 'change_duty_status_2_0x_text_scaling.png',
      );
    });
  });
}
