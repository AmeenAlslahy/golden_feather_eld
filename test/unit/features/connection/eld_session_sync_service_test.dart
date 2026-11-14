import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/driver_session_backend.dart';
import 'package:golden_feather_eld/backend/contracts/hardware_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/connection/application/eld_session_sync_service.dart';
import 'package:golden_feather_eld/features/connection/data/datasources/eld_session_snapshot_store.dart';
import 'package:golden_feather_eld/features/connection/domain/eld_session_snapshot.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockHardwareBackend extends Mock implements HardwareBackend {}

class _MockDriverSessionBackend extends Mock implements DriverSessionBackend {}

final _startedAt = DateTime.utc(2026, 1, 2, 3, 4);

final _pendingManual = EldSessionSnapshot(
  driverId: 7,
  localId: 'local-1',
  vehicleUniqueId: '1001',
  vehicleName: 'Truck 1001',
  manualMode: true,
  startedAt: _startedAt,
  origin: EldSessionOrigin.localManual,
  syncState: EldSessionSyncState.pending,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalStorageService storage;
  late _MockHardwareBackend hardware;
  late _MockDriverSessionBackend driverSession;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({});
    storage = LocalStorageService();
    await storage.init();
    hardware = _MockHardwareBackend();
    driverSession = _MockDriverSessionBackend();
    registerFallbackValue(const DriverId(0));

    await EldSessionSnapshotStore(storage.prefs).save(
      _pendingManual.copyWith(startedAt: DateTime.utc(2026, 1, 2, 3, 4)),
    );
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        localStorageProvider.overrideWithValue(storage),
        hardwareBackendProvider.overrideWithValue(hardware),
        driverSessionBackendProvider.overrideWithValue(driverSession),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  EldSessionSnapshotStore store() => EldSessionSnapshotStore(storage.prefs);

  void stubActiveServerSession(Map<String, dynamic> data) {
    when(
      () => driverSession.getActiveSession(any()),
    ).thenAnswer((_) async => ok<RawJson>(data));
  }

  test('adopts an active server session without writing again', () async {
    stubActiveServerSession(const {
      'id': 55,
      'status': 'ACTIVE',
      'connectionStatus': 'CONNECTED',
      'vehicle': {'uniqueId': '1001'},
    });

    final service = createContainer().read(eldSessionSyncServiceProvider);
    await service.syncPendingForDriver(7);

    final snapshot = store().load(7)!;
    expect(snapshot.syncState, EldSessionSyncState.synced);
    expect(snapshot.sessionId, 55);
    expect(snapshot.origin, EldSessionOrigin.server);
    expect(snapshot.localId, 'local-1');
    verifyNever(
      () => hardware.connectSession(
        uniqueId: any(named: 'uniqueId'),
        disconnected: any(named: 'disconnected'),
      ),
    );
  });

  test('writes the pending session only after GET proves none exists', () async {
    when(() => driverSession.getActiveSession(any())).thenAnswer(
      (_) async =>
          err<RawJson>(const NotFoundError(code: 'eld.session.noneActive')),
    );
    when(
      () => hardware.connectSession(
        uniqueId: any(named: 'uniqueId'),
        disconnected: true,
        driverId: any(named: 'driverId'),
      ),
    ).thenAnswer(
      (_) async => ok(const {
        'id': 66,
        'status': 'ACTIVE',
        'vehicle': {'uniqueId': '1001'},
      }),
    );

    final service = createContainer().read(eldSessionSyncServiceProvider);
    await service.syncPendingForDriver(7);

    verify(
      () => hardware.connectSession(
        uniqueId: '1001',
        disconnected: true,
        driverId: any(named: 'driverId'),
      ),
    ).called(1);
    final snapshot = store().load(7)!;
    expect(snapshot.syncState, EldSessionSyncState.synced);
    expect(snapshot.sessionId, 66);
    expect(snapshot.localId, 'local-1');
    expect(snapshot.startedAt, DateTime.utc(2026, 1, 2, 3, 4));
  });

  test('an unreadable server state never triggers a write', () async {
    when(() => driverSession.getActiveSession(any())).thenAnswer(
      (_) async => err<RawJson>(
        const NetworkError(code: 'network.offline', l10nKey: 'networkError'),
      ),
    );

    final service = createContainer().read(eldSessionSyncServiceProvider);
    await service.syncPendingForDriver(7);

    verifyNever(
      () => hardware.connectSession(
        uniqueId: any(named: 'uniqueId'),
        disconnected: any(named: 'disconnected'),
      ),
    );
    expect(store().load(7)!.syncState, EldSessionSyncState.pending);
  });

  test('a rejected write keeps the session pending', () async {
    when(() => driverSession.getActiveSession(any())).thenAnswer(
      (_) async =>
          err<RawJson>(const NotFoundError(code: 'eld.session.noneActive')),
    );
    when(
      () => hardware.connectSession(
        uniqueId: any(named: 'uniqueId'),
        disconnected: true,
        driverId: any(named: 'driverId'),
      ),
    ).thenAnswer(
      (_) async => err<RawJson>(
        const ServerError(
          code: 'eld.session.connectRejected',
          statusCode: 409,
        ),
      ),
    );

    final service = createContainer().read(eldSessionSyncServiceProvider);
    await service.syncPendingForDriver(7);

    expect(store().load(7)!.syncState, EldSessionSyncState.pending);
  });

  test('a session already synced is left alone', () async {
    await store().save(
      _pendingManual
          .copyWith(startedAt: DateTime.utc(2026, 1, 2), syncState: EldSessionSyncState.synced),
    );

    final service = createContainer().read(eldSessionSyncServiceProvider);
    await service.syncPendingForDriver(7);

    verifyNever(() => driverSession.getActiveSession(any()));
    verifyNever(
      () => hardware.connectSession(
        uniqueId: any(named: 'uniqueId'),
        disconnected: any(named: 'disconnected'),
      ),
    );
  });
}
