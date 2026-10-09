import 'package:flutter/material.dart';


import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/vehicle/data/providers/vehicle_repository_providers.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/features/home/presentation/pages/home_page.dart';
import 'package:golden_feather_eld/features/hos/presentation/pages/status_dashboard_page.dart';
import 'package:golden_feather_eld/features/connection/domain/entities/hardware_alert.dart';
import 'package:golden_feather_eld/features/connection/presentation/providers/hardware_alerts_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';

import 'package:golden_feather_eld/core/config/app_environment.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/services/tracking_config_storage_service.dart';
import 'package:golden_feather_eld/features/tracking/data/datasources/live_tracking_data_source.dart';
import 'package:golden_feather_eld/features/tracking/domain/entities/connection_status.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:golden_feather_eld/core/domain/entities/location_point.dart';
import 'package:golden_feather_eld/features/vehicle/domain/repositories/vehicle_repository.dart';
import 'package:golden_feather_eld/features/sync/presentation/providers/sync_provider.dart';
import 'package:golden_feather_eld/features/hos/presentation/providers/hos_provider.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/sync_item.dart';
import 'package:golden_feather_eld/features/hos/domain/engine/hos_rules_engine.dart';
import 'package:golden_feather_eld/core/time/trusted_time_provider.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockLocalStorageService extends Mock implements LocalStorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    try {
      return super.noSuchMethod(invocation);
    } catch (e) {
      final name = invocation.memberName.toString();
      throw UnimplementedError(
        'MockLocalStorageService: $name not stubbed. '
        'Add a stub in pumpHomePage.',
      );
    }
  }
}
class MockTrackingConfigStorageService extends Mock implements TrackingConfigStorageService {}
class MockVehicleRepository extends Mock implements VehicleRepository {}

class MockSyncNotifier extends StateNotifier<SyncState> implements SyncNotifier {
  MockSyncNotifier() : super(const SyncState());
  
  @override
  Future<void> syncNow() async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHosNotifier extends StateNotifier<HosEngineResult> implements HosNotifier {
  MockHosNotifier() : super(HosEngineTimeUnavailable(TrustedTimeState.uninitialized));
  
  @override
  void refresh() {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockHardwareAlertsNotifier extends HardwareAlertsNotifier {
  @override
  Future<List<HardwareAlert>> build() async => [];
  
  @override
  Future<void> fetchAlerts() async {}
}

class EmptyLiveTrackingDataSource implements LiveTrackingDataSource {
  @override
  Stream<EldEvent> get events => const Stream.empty();
  @override
  Stream<LocationPoint> get locations => const Stream.empty();
  @override
  Stream<ConnectionStatus> get connectionStatus => Stream.value(ConnectionStatus.connected);
  @override
  Future<bool> start() async => true;
  @override
  Future<void> stop() async {}
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AppEnvironmentConfig.init(testEnv: {
      'API_BASE_URL': 'http://localhost',
      'TRACCAR_ENVIRONMENT': 'mock',
    });
  });

  // HomePage is a full Scaffold — do NOT wrap it in another Scaffold
  // (that causes unbounded-height RenderFlex errors).
  Future<ProviderContainer> pumpHomePage(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final mockLocalStorage = MockLocalStorageService();
    when(() => mockLocalStorage.currentDutyStatus).thenReturn('off_duty');
    when(() => mockLocalStorage.serverUrl).thenReturn('http://mock.test');
    when(() => mockLocalStorage.backendType).thenReturn('mock');
    when(() => mockLocalStorage.deviceId).thenReturn('12345');

    final mockTrackingConfig = MockTrackingConfigStorageService();
    when(() => mockTrackingConfig.deviceId).thenReturn('12345');

    final mockVehicleRepo = MockVehicleRepository();
    when(() => mockVehicleRepo.getVehicles()).thenAnswer((_) async => const Right([]));
    when(() => mockVehicleRepo.getSelectedVehicle()).thenAnswer((_) async => const Right(null));

    final container = ProviderContainer(
      overrides: [
        activeBackendProvider.overrideWithValue(MockAdapter()),
        localStorageProvider.overrideWithValue(mockLocalStorage),
        trackingConfigStorageProvider.overrideWithValue(mockTrackingConfig),
        liveTrackingDataSourceProvider.overrideWithValue(EmptyLiveTrackingDataSource()),
        vehicleRepositoryProvider.overrideWithValue(mockVehicleRepo),
        syncStateProvider.overrideWith((ref) => MockSyncNotifier()),
        hosStatusProvider.overrideWith((ref) => MockHosNotifier()),
        hardwareAlertsProvider.overrideWith(() => MockHardwareAlertsNotifier()),
      ],
    );

    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          locale: const Locale('en'),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          theme: AppTheme.light,
          home: const HomePage(),
        ),
      ),
    );

    return container;
  }

  group('HomePage — status dashboard', () {
    testWidgets('shows StatusDashboardPage (single source of truth)',
        (tester) async {
      await pumpHomePage(tester);
      // Wait for timers/futures to settle. Use pump(Duration) instead of pumpAndSettle
      // to avoid timeout from periodic timers if they aren't fully disposed immediately.
      await tester.pump(const Duration(seconds: 1));

      expect(find.byType(StatusDashboardPage), findsOneWidget);
    });
  });
}
