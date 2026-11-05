import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/services/bluetooth_service.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/codriver/data/datasources/codriver_local_cache.dart';
import 'package:golden_feather_eld/features/codriver/data/providers/codriver_repository_providers.dart';
import 'package:golden_feather_eld/features/codriver/domain/current_codriver.dart';
import 'package:golden_feather_eld/features/codriver/domain/entities/codriver.dart';
import 'package:golden_feather_eld/features/codriver/domain/repositories/codriver_repository.dart';
import 'package:golden_feather_eld/features/codriver/presentation/pages/codriver_page.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/pages/status_dashboard_page.dart';
import 'package:golden_feather_eld/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:golden_feather_eld/features/tracking/presentation/providers/tracking_provider.dart';
import 'package:golden_feather_eld/features/vehicle/data/datasources/vehicle_local_cache.dart';
import 'package:golden_feather_eld/features/vehicle/data/providers/vehicle_repository_providers.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/pages/select_vehicle_page.dart';
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
  _FakeDashboardNotifier()
      : super(const DashboardData(
          driverName: 'John Doe',
          vehicleId: 'TRK-101',
          vehicleDisplayName: 'Freightliner Cascadia #101',
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
  String get theme => 'dark';
  @override
  Future<void> setTheme(String value) async {}
  @override
  String? get selectedVehicleId => 'TRK-101';
  @override
  HosConfiguration get hosConfiguration => HosConfiguration.usa70_8();
  @override
  Future<void> setDeviceId(String value) async {}
  @override
  Future<void> saveSelectedVehicleId(String value) async {}
}

class _MockTrackingRepo extends Mock implements TrackingRepository {}

class _MockVehicleRepo extends Mock implements VehicleRepository {}

class _MockCoDriverRepo extends Mock implements CoDriverRepository {}

class _FakeAuthNotifier extends StateNotifier<AuthState> implements AuthNotifier {
  _FakeAuthNotifier()
      : super(
          AuthState(
            status: AuthStatus.authenticated,
            user: User(
              id: '106',
              username: 'driver106',
              email: 'driver106@goldenfeather.com',
              fullName: 'John Doe',
              role: UserRole.fieldWorker,
              createdAt: DateTime(2026),
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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

  late _MockVehicleRepo vehicleRepo;
  late _MockCoDriverRepo codriverRepo;

  const v1 = Vehicle(
    id: 'TRK-101',
    name: 'Freightliner Cascadia',
    year: '2023',
    uniqueId: '00:1B:44:11:3A:B7',
    isAssigned: true,
    activeForCurrentDriver: true,
  );
  const v2 = Vehicle(
    id: 'TRK-102',
    name: 'Volvo VNL 760',
    year: '2022',
    uniqueId: '00:1B:44:11:3A:C8',
    isAssigned: true,
  );
  const v3 = Vehicle(
    id: 'TRK-103',
    name: 'Kenworth T680',
    year: '2021',
    uniqueId: '00:1B:44:11:3A:D9',
    isAssigned: false,
  );

  const cd1 = CoDriver(id: '101', name: 'Alex Rivera');
  const cd2 = CoDriver(id: '102', name: 'Sam Lee');

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

  setUp(() {
    vehicleRepo = _MockVehicleRepo();
    codriverRepo = _MockCoDriverRepo();

    when(() => vehicleRepo.getVehicles()).thenAnswer((_) async => const Right([v1, v2, v3]));
    when(() => vehicleRepo.getSelectedVehicle()).thenAnswer((_) async => const Right(v1));
    when(() => vehicleRepo.getCompanyVehicles()).thenAnswer((_) async => const Right([v1, v2, v3]));

    when(() => codriverRepo.getAvailableDrivers()).thenAnswer((_) async => const Right([cd1, cd2]));
    when(() => codriverRepo.getCurrentCoDriver()).thenAnswer(
      (_) async => const Right(CurrentCoDriverRead(coDriverId: 101, teamDrivingActive: true)),
    );
  });

  Future<void> captureScreen({
    required WidgetTester tester,
    required GlobalKey key,
    required String filename,
  }) async {
    await tester.binding.runAsync(() async {
      final boundary = key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final outDir = Directory('build/screenshots');
      if (!outDir.existsSync()) {
        outDir.createSync(recursive: true);
      }
      await File('build/screenshots/$filename').writeAsBytes(bytes);

      const artifactDir = r'C:\Users\Owner\.gemini\antigravity-ide\brain\5a94c5e4-5889-4e0e-a640-28bea96b9f8a';
      final artDir = Directory(artifactDir);
      if (artDir.existsSync()) {
        await File('$artifactDir/$filename').writeAsBytes(bytes);
      }
    });
  }

  Widget buildHarness({
    required GlobalKey repaintKey,
    required Widget child,
    required ThemeData theme,
    Locale locale = const Locale('en'),
    double textScale = 1.0,
    double screenWidth = 375,
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
          dashboardDataProvider.overrideWith((ref) => _FakeDashboardNotifier()),
          authStateProvider.overrideWith((ref) => _FakeAuthNotifier()),
          vehicleRepositoryProvider.overrideWithValue(vehicleRepo),
          coDriverRepositoryProvider.overrideWithValue(codriverRepo),
          currentDriverIdProvider.overrideWithValue(106),
          trackingStateProvider.overrideWith((ref) => TrackingNotifier(_MockTrackingRepo(), ref)),
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
            child: child,
          ),
        ),
      ),
    );
  }

  group('Phase 7C Batch 1 — Gallery Screenshots Suite', () {
    // ═════════════════════════════════════════════════════════════════════════
    // VEHICLE SELECTION SCREEN
    // ═════════════════════════════════════════════════════════════════════════
    testWidgets('Vehicle Selection — English Light', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHarness(
        repaintKey: key,
        child: const SelectVehiclePage(),
        theme: AppTheme.light,
        locale: const Locale('en'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(tester: tester, key: key, filename: 'vehicle_selection_english_light.png');
    });

    testWidgets('Vehicle Selection — Arabic Dark', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHarness(
        repaintKey: key,
        child: const SelectVehiclePage(),
        theme: AppTheme.dark,
        locale: const Locale('ar'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(tester: tester, key: key, filename: 'vehicle_selection_arabic_dark.png');
    });

    testWidgets('Vehicle Selection — Spanish Light 320dp', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(640, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHarness(
        repaintKey: key,
        child: const SelectVehiclePage(),
        theme: AppTheme.light,
        locale: const Locale('es'),
        screenWidth: 320,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(tester: tester, key: key, filename: 'vehicle_selection_spanish_320dp.png');
    });

    // ═════════════════════════════════════════════════════════════════════════
    // CO-DRIVER SCREEN
    // ═════════════════════════════════════════════════════════════════════════
    testWidgets('Co-Driver — English Light', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHarness(
        repaintKey: key,
        child: const CoDriverPage(),
        theme: AppTheme.light,
        locale: const Locale('en'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(tester: tester, key: key, filename: 'codriver_english_light.png');
    });

    testWidgets('Co-Driver — Arabic Dark', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHarness(
        repaintKey: key,
        child: const CoDriverPage(),
        theme: AppTheme.dark,
        locale: const Locale('ar'),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(tester: tester, key: key, filename: 'codriver_arabic_dark.png');
    });

    testWidgets('Co-Driver — Spanish 2.0x Text Scaling', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHarness(
        repaintKey: key,
        child: const CoDriverPage(),
        theme: AppTheme.light,
        locale: const Locale('es'),
        textScale: 2.0,
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      await captureScreen(tester: tester, key: key, filename: 'codriver_spanish_2_0x.png');
    });

    // ═════════════════════════════════════════════════════════════════════════
    // HOS DASHBOARD SCREEN
    // ═════════════════════════════════════════════════════════════════════════
    testWidgets('HOS Dashboard — English Light', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHarness(
        repaintKey: key,
        child: const Scaffold(body: StatusDashboardPage()),
        theme: AppTheme.light,
        locale: const Locale('en'),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      await captureScreen(tester: tester, key: key, filename: 'hos_dashboard_english_light.png');
    });

    testWidgets('HOS Dashboard — Arabic Dark', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHarness(
        repaintKey: key,
        child: const Scaffold(body: StatusDashboardPage()),
        theme: AppTheme.dark,
        locale: const Locale('ar'),
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      await captureScreen(tester: tester, key: key, filename: 'hos_dashboard_arabic_dark.png');
    });

    testWidgets('HOS Dashboard — Spanish 320dp', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(640, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHarness(
        repaintKey: key,
        child: const Scaffold(body: StatusDashboardPage()),
        theme: AppTheme.light,
        locale: const Locale('es'),
        screenWidth: 320,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      await captureScreen(tester: tester, key: key, filename: 'hos_dashboard_spanish_320dp.png');
    });

    testWidgets('HOS Dashboard — 2.0x Text Scaling', (tester) async {
      final key = GlobalKey();
      tester.view.physicalSize = const Size(750, 1624);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(buildHarness(
        repaintKey: key,
        child: const Scaffold(body: StatusDashboardPage()),
        theme: AppTheme.light,
        locale: const Locale('en'),
        textScale: 2.0,
      ));
      await tester.pump();
      await tester.pumpAndSettle();

      await captureScreen(tester: tester, key: key, filename: 'hos_dashboard_2_0x.png');
    });
  });
}
