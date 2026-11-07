import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/config/app_environment.dart';
import 'package:golden_feather_eld/core/config/hos_configuration.dart';
import 'package:golden_feather_eld/core/domain/entities/connection_status.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/domain/entities/location_point.dart';
import 'package:golden_feather_eld/core/domain/entities/user.dart';
import 'package:golden_feather_eld/core/error/failure.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/network/network_info.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/services/tracking_config_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/domain/duty_status/duty_status_code.dart';
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart'
    hide ConnectionStatus;
import 'package:golden_feather_eld/domain/duty_status/status_dashboard.dart'
    as dash
    show ConnectionStatus;
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/domain/repositories/auth_repository.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_providers.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/connection/domain/entities/hardware_alert.dart';
import 'package:golden_feather_eld/features/connection/presentation/providers/hardware_alerts_provider.dart';
import 'package:golden_feather_eld/features/connection/presentation/widgets/connecting_overlay.dart';
import 'package:golden_feather_eld/features/home/presentation/pages/home_page.dart';
import 'package:golden_feather_eld/features/home/presentation/providers/dashboard_provider.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/hos_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/status_dashboard_providers.dart';
import 'package:golden_feather_eld/features/logs/domain/repositories/log_repository.dart';
import 'package:golden_feather_eld/features/logs/presentation/pages/shipping_documents_page.dart';
import 'package:golden_feather_eld/features/logs/presentation/providers/logs_provider.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/sync_item.dart';
import 'package:golden_feather_eld/features/sync/presentation/providers/sync_provider.dart';
import 'package:golden_feather_eld/features/tracking/data/datasources/live_tracking_data_source.dart';
import 'package:golden_feather_eld/features/vehicle/data/providers/vehicle_repository_providers.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Verification captures for the status-message task.
///
/// Output goes to `build/screenshots/ui_messages_task/` only, so existing
/// screenshots/artifacts are never overwritten.
void main() {
  const outputDir = 'build/screenshots/ui_messages_task';

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppEnvironmentConfig.init(
      testEnv: {
        'API_BASE_URL': 'http://localhost',
        'TRACCAR_ENVIRONMENT': 'mock',
      },
    );
    await _loadFonts();
  });

  Future<void> capture(
    WidgetTester tester,
    GlobalKey key,
    String filename,
  ) async {
    await tester.binding.runAsync(() async {
      final boundary =
          key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final dir = Directory(outputDir);
      if (!dir.existsSync()) dir.createSync(recursive: true);
      await File(
        '$outputDir/$filename',
      ).writeAsBytes(data!.buffer.asUint8List());
    });
  }

  testWidgets('capture: connecting overlay AR light 320dp 2x', (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(
        key: key,
        locale: const Locale('ar'),
        theme: AppTheme.light,
        textScale: 2.0,
        child: const ConnectingOverlay(
          isContinuingDisconnected: false,
          isConnecting: true,
          serverRequestPending: false,
          onCancel: _noop,
          onContinueDisconnected: _noop,
        ),
      ),
    );
    await tester.pump();
    await capture(tester, key, 'connecting_overlay_ar_light_320dp_2x.png');
  });

  testWidgets('capture: connecting overlay EN dark', (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(375, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(
        key: key,
        locale: const Locale('en'),
        theme: AppTheme.dark,
        child: const ConnectingOverlay(
          isContinuingDisconnected: false,
          isConnecting: true,
          serverRequestPending: true,
          onCancel: _noop,
          onContinueDisconnected: _noop,
        ),
      ),
    );
    await tester.pump();
    await capture(tester, key, 'connecting_overlay_en_dark.png');
  });

  testWidgets('capture: inline document error AR light', (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(390, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(
        key: key,
        locale: const Locale('ar'),
        theme: AppTheme.light,
        child: ProviderScope(
          overrides: [
            dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
            logsProvider.overrideWith(
              (ref) => LogsNotifier(_LogRepository(), null),
            ),
          ],
          child: const ShippingDocumentsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('إضافة'));
    await tester.pumpAndSettle();
    await capture(tester, key, 'document_inline_error_ar_light.png');
  });

  testWidgets('capture: ADD stacked 320dp 2x AR', (tester) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      _harness(
        key: key,
        locale: const Locale('ar'),
        theme: AppTheme.light,
        textScale: 2.0,
        child: ProviderScope(
          overrides: [
            dashboardDataProvider.overrideWith((ref) => DashboardNotifier()),
            logsProvider.overrideWith(
              (ref) => LogsNotifier(_LogRepository(), null),
            ),
          ],
          child: const ShippingDocumentsPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'BOL-2024-001');
    await tester.pump();
    await capture(tester, key, 'document_add_stacked_320dp_2x_ar.png');
  });

  Future<void> captureHome(
    WidgetTester tester,
    ThemeData theme,
    String filename,
  ) async {
    final key = GlobalKey();
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer(
      overrides: [
        activeBackendProvider.overrideWithValue(MockAdapter()),
        traccarAuthRepositoryProvider.overrideWithValue(
          _FakeSessionAuthRepository(),
        ),
        localStorageProvider.overrideWithValue(_MockLocalStorageService()),
        trackingConfigStorageProvider.overrideWithValue(
          _MockTrackingConfigStorageService(),
        ),
        liveTrackingDataSourceProvider.overrideWithValue(
          _EmptyLiveTrackingDataSource(),
        ),
        vehicleRepositoryProvider.overrideWithValue(_MockVehicleRepository()),
        statusDashboardProvider.overrideWith(() => _StaticDashboardNotifier()),
        syncStateProvider.overrideWith((ref) => _MockSyncNotifier()),
        hosStatusProvider.overrideWith((ref) => _MockHosNotifier()),
        hardwareAlertsProvider.overrideWith(
          () => _MockHardwareAlertsNotifier(),
        ),
        networkInfoProvider.overrideWithValue(_OfflineNetworkInfo()),
        isConnectedProvider.overrideWith((ref) => Stream<bool>.value(false)),
      ],
    );
    addTearDown(container.dispose);
    await container
        .read(authStateProvider.notifier)
        .login(username: 'admin@demo.com', password: 'admin123');

    await tester.pumpWidget(
      RepaintBoundary(
        key: key,
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            locale: const Locale('ar'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            theme: theme,
            home: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    await capture(tester, key, filename);
  }

  testWidgets('capture: home offline banner AR light', (tester) async {
    await captureHome(
      tester,
      AppTheme.light,
      'home_offline_banner_ar_light.png',
    );
  });

  testWidgets('capture: home offline banner AR dark', (tester) async {
    await captureHome(tester, AppTheme.dark, 'home_offline_banner_ar_dark.png');
  });
}

void _noop() {}

Widget _harness({
  required GlobalKey key,
  required Locale locale,
  required ThemeData theme,
  required Widget child,
  double textScale = 1.0,
}) {
  return RepaintBoundary(
    key: key,
    child: MaterialApp(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      theme: theme,
      builder: (context, appChild) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: appChild!,
      ),
      home: Scaffold(body: child),
    ),
  );
}

Future<void> _loadFonts() async {
  try {
    // The app requests the 'Roboto' family everywhere. Roboto has no Arabic
    // glyphs and the test engine does not fall back to extra same-family
    // files, so host Tahoma (Latin + Arabic) is registered under that name
    // for these verification captures only.
    final loader = FontLoader('Roboto');
    final host = [
      r'C:\Windows\Fonts\tahoma.ttf',
      r'C:\Windows\Fonts\tahomabd.ttf',
    ].where((path) => File(path).existsSync()).toList();
    final paths = host.isNotEmpty
        ? host
        : [
            'assets/fonts/google_fonts/Roboto-Regular.ttf',
            'assets/fonts/google_fonts/Roboto-Medium.ttf',
            'assets/fonts/google_fonts/Roboto-Bold.ttf',
          ];
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        loader.addFont(
          Future.value(ByteData.view(file.readAsBytesSync().buffer)),
        );
      }
    }
    await loader.load();
  } catch (_) {}

  try {
    final icons = FontLoader('MaterialIcons');
    final flutterRoot = Platform.environment['FLUTTER_ROOT'];
    final candidates = [
      if (flutterRoot != null)
        '$flutterRoot/bin/cache/artifacts/material_fonts/'
            'materialicons-regular.otf',
      'assets/fonts/MaterialIcons-Regular.otf',
    ];
    for (final path in candidates) {
      final file = File(path);
      if (file.existsSync()) {
        icons.addFont(
          Future.value(ByteData.view(file.readAsBytesSync().buffer)),
        );
        break;
      }
    }
    await icons.load();
  } catch (_) {}
}

class _LogRepository extends Mock implements LogRepository {}

class _MockLocalStorageService extends Mock implements LocalStorageService {
  @override
  String get currentDutyStatus => 'off_duty';
  @override
  String get serverUrl => 'http://mock.test';
  @override
  String get backendType => 'mock';
  @override
  String get deviceId => '12345';
  @override
  String get theme => 'light';
  @override
  String get language => 'ar';
  @override
  HosConfiguration get hosConfiguration => HosConfiguration.usa70_8();
}

class _MockTrackingConfigStorageService extends Mock
    implements TrackingConfigStorageService {
  @override
  String get deviceId => '12345';
}

class _MockVehicleRepository extends Mock implements VehicleRepository {
  @override
  Future<Either<Failure, List<Vehicle>>> getVehicles() async => const Right([]);
  @override
  Future<Either<Failure, Vehicle?>> getSelectedVehicle() async =>
      const Right(null);
}

class _StaticDashboardNotifier extends StatusDashboardNotifier {
  @override
  Future<StatusDashboard> build() async => _dashboard;
}

class _FakeSessionAuthRepository implements AuthRepository {
  @override
  Future<Either<Failure, User>> login({
    required dynamic identifier,
    required dynamic password,
  }) async => Right(
    User(
      id: '101',
      fullName: 'Test User',
      email: 'test@example.com',
      username: 'admin',
      role: UserRole.fieldWorker,
      createdAt: DateTime.now(),
    ),
  );

  @override
  Future<Either<Failure, Unit>> logout() async => const Right(unit);

  @override
  Future<Either<Failure, User>> checkAndRestoreSession() async =>
      const Left(ServerFailure(message: 'No session'));

  @override
  Future<Either<Failure, User>> getCurrentSession() async =>
      const Left(ServerFailure(message: 'No session'));
}

class _MockSyncNotifier extends StateNotifier<SyncState>
    implements SyncNotifier {
  _MockSyncNotifier() : super(const SyncState());
  @override
  Future<void> syncNow() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHosNotifier extends StateNotifier<HosEngineResult>
    implements HosNotifier {
  _MockHosNotifier()
    : super(HosEngineTimeUnavailable(TrustedTimeState.uninitialized));
  @override
  void refresh() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _MockHardwareAlertsNotifier extends HardwareAlertsNotifier {
  @override
  Future<List<HardwareAlert>> build() async => [];
  @override
  Future<void> fetchAlerts() async {}
}

class _OfflineNetworkInfo implements NetworkInfo {
  @override
  Stream<bool> get onConnectionChange => Stream<bool>.value(false);
  @override
  bool get isConnected => false;
}

class _EmptyLiveTrackingDataSource implements LiveTrackingDataSource {
  @override
  Stream<EldEvent> get events => const Stream.empty();
  @override
  Stream<LocationPoint> get locations => const Stream.empty();
  @override
  Stream<ConnectionStatus> get connectionStatus =>
      Stream.value(ConnectionStatus.connected);
  @override
  Future<bool> start() async => true;
  @override
  Future<void> stop() async {}
}

const _indicator = HosIndicator(
  label: 'DRIVE',
  value: Duration(hours: 8),
  type: IndicatorType.remaining,
);

const _dashboard = StatusDashboard(
  driver: DriverRef(id: DriverId(101), name: 'Test', displayText: 'Test - 101'),
  operationalAlerts: OperationalAlerts(
    toolIcon: false,
    warningTriangleIcon: false,
    connectionStatus: dash.ConnectionStatus.ok,
  ),
  currentDutyStatus: DutyStatusCode.offDuty,
  remainingCircle: RemainingCircle(
    remaining: Duration(hours: 8),
    label: 'DRIVE',
    progress: 0.5,
  ),
  hosIndicators: HosIndicators(
    drive: _indicator,
    shift: _indicator,
    breakTime: _indicator,
    cycle: _indicator,
  ),
  regulatoryConstraints: RegulatoryConstraints(
    ruleSet: CycleRule.usa70_8,
    limits: [],
  ),
);
