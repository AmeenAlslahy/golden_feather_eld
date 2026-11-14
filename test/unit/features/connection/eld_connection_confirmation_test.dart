import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/contracts/driver_session_backend.dart';
import 'package:golden_feather_eld/backend/contracts/hardware_backend.dart';
import 'package:golden_feather_eld/backend/contracts/raw_json.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/error/app_error.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/bluetooth_service.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/domain/shared/value_objects.dart';
import 'package:golden_feather_eld/features/auth/presentation/providers/auth_state_provider.dart';
import 'package:golden_feather_eld/features/connection/data/datasources/eld_session_snapshot_store.dart';
import 'package:golden_feather_eld/features/connection/domain/eld_session_snapshot.dart';
import 'package:golden_feather_eld/features/connection/presentation/pages/eld_connection_page.dart';
import 'package:golden_feather_eld/features/tracking/data/providers/tracking_providers.dart';
import 'package:golden_feather_eld/features/tracking/domain/entities/location_entity.dart';
import 'package:golden_feather_eld/features/tracking/domain/repositories/tracking_repository.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockBluetoothService extends Mock implements BluetoothService {}

class _MockHardwareBackend extends Mock implements HardwareBackend {}

class _MockDriverSessionBackend extends Mock implements DriverSessionBackend {}

class _MockTrackingRepository extends Mock implements TrackingRepository {}

/// حالة مركبة ثابتة لاختبارات طبقة الحالة (بلا مستودع/شبكة).
class _FakeVehicleNotifier extends StateNotifier<VehicleState>
    implements VehicleNotifier {
  _FakeVehicleNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _vehicle = Vehicle(
  id: 'V-1001',
  uniqueId: '1001',
  name: 'Truck 1001',
  year: '2024',
);

const _connectRejected = ServerError(
  code: 'eld.session.connectRejected',
  l10nKey: 'sessionConnectRejected',
  statusCode: 409,
);

const _connectUnconfirmed = ServerError(
  code: 'eld.session.connectUnconfirmed',
  l10nKey: 'sessionStatusUnconfirmed',
  context: {'reason': 'missing_or_malformed_data'},
);

const _trackingConfig = TrackingConfigEntity(
  serverUrl: 'https://example.com',
  deviceId: 'device-1',
);

/// Waits for an async notifier step without relying on real time.
Future<void> _waitUntil(bool Function() condition) async {
  for (var i = 0; i < 200; i++) {
    if (condition()) return;
    await Future<void>.delayed(Duration.zero);
  }
  fail('Condition was not reached');
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockBluetoothService bt;
  late _MockHardwareBackend hardware;
  late _MockTrackingRepository tracking;
  late LocalStorageService storage;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({'language': 'en'});
    storage = LocalStorageService();
    await storage.init();
    // `LocalStorageService` keeps one process-wide prefs cache; snapshots
    // written by earlier tests in this file must not leak into the next one.
    await EldSessionSnapshotStore(storage.prefs).clear(7);

    bt = _MockBluetoothService();
    hardware = _MockHardwareBackend();
    tracking = _MockTrackingRepository();
    registerFallbackValue(const DriverId(0));

    when(() => bt.disconnect()).thenAnswer((_) async {});
    when(() => bt.connect(any())).thenAnswer((_) async {});
    when(
      () => tracking.locationStream,
    ).thenAnswer((_) => const Stream<LocationEntity>.empty());
    when(
      () => tracking.getCurrentConfig(),
    ).thenAnswer((_) async => _trackingConfig);
    when(
      () => tracking.updateConfig(_trackingConfig),
    ).thenAnswer((_) async => right(true));
    when(() => tracking.startTracking()).thenAnswer((_) async => right(true));
  });

  ProviderContainer createContainer({
    Stream<bool>? connectivity,
    Vehicle? vehicle = _vehicle,
    int? driverId,
    DriverSessionBackend? driverSession,
  }) {
    final container = ProviderContainer(
      overrides: [
        activeBackendProvider.overrideWithValue(MockAdapter()),
        bluetoothServiceProvider.overrideWithValue(bt),
        hardwareBackendProvider.overrideWithValue(hardware),
        localStorageProvider.overrideWithValue(storage),
        trackingRepositoryProvider.overrideWithValue(tracking),
        vehicleProvider.overrideWith(
          (ref) => _FakeVehicleNotifier(
            VehicleState(
              selectedVehicle: vehicle,
              vehicles: vehicle == null ? const [] : [vehicle],
            ),
          ),
        ),
        if (driverId != null)
          currentDriverIdProvider.overrideWithValue(driverId),
        if (driverSession != null)
          driverSessionBackendProvider.overrideWithValue(driverSession),
        if (connectivity != null)
          isConnectedProvider.overrideWith((ref) => connectivity),
      ],
    );
    final sub = container.listen(eldConnectionProvider, (_, __) {});
    addTearDown(() {
      sub.close();
      container.dispose();
    });
    return container;
  }

  EldSessionSnapshot? snapshotFor(int driverId) =>
      EldSessionSnapshotStore(storage.prefs).load(driverId);

  void stubConnect(Future<Result<RawJson>> Function() answer) {
    when(
      () => hardware.connectSession(
        uniqueId: any(named: 'uniqueId'),
        disconnected: false,
        driverId: any(named: 'driverId'),
      ),
    ).thenAnswer((_) => answer());
  }

  void stubContinue(Future<Result<RawJson>> Function() answer) {
    when(
      () => hardware.connectSession(
        uniqueId: any(named: 'uniqueId'),
        disconnected: true,
        driverId: any(named: 'driverId'),
      ),
    ).thenAnswer((_) => answer());
  }

  group('single-flight guard', () {
    test(
      'repeated connect taps produce one BLE link and one server write',
      () async {
        final bluetoothGate = Completer<void>();
        final serverGate = Completer<Result<RawJson>>();
        when(() => bt.connect(any())).thenAnswer((_) => bluetoothGate.future);
        stubConnect(() => serverGate.future);

        final container = createContainer();
        final notifier = container.read(eldConnectionProvider.notifier);

        final first = notifier.attemptConnection('AA:BB:CC:DD:EE:FF');
        await notifier.attemptConnection('AA:BB:CC:DD:EE:FF');

        verify(() => bt.connect(any())).called(1);
        expect(container.read(eldConnectionProvider).isConnecting, isTrue);

        bluetoothGate.complete();
        await _waitUntil(
          () => container.read(eldConnectionProvider).serverRequestPending,
        );

        // Still busy: both a second connect and a continue are no-ops.
        await notifier.attemptConnection('AA:BB:CC:DD:EE:FF');
        await notifier.continueDisconnected();

        verify(
          () => hardware.connectSession(
            uniqueId: any(named: 'uniqueId'),
            disconnected: false,
            driverId: any(named: 'driverId'),
          ),
        ).called(1);
        verifyNever(
          () => hardware.connectSession(
            uniqueId: any(named: 'uniqueId'),
            disconnected: true,
          ),
        );

        serverGate.complete(ok(const {'id': 1, 'status': 'ACTIVE'}));
        await first;

        final state = container.read(eldConnectionProvider);
        expect(state.connectionConfirmed, isTrue);
        expect(state.serverRequestPending, isFalse);
      },
    );

    test('continue is ignored while its own server write is pending', () async {
      final serverGate = Completer<Result<RawJson>>();
      stubContinue(() => serverGate.future);

      final container = createContainer(connectivity: Stream.value(true));
      final notifier = container.read(eldConnectionProvider.notifier);

      final first = notifier.continueDisconnected();
      await _waitUntil(
        () => container.read(eldConnectionProvider).serverRequestPending,
      );

      await notifier.continueDisconnected();
      await notifier.continueDisconnected();

      verify(
        () => hardware.connectSession(
          uniqueId: any(named: 'uniqueId'),
          disconnected: true,
          driverId: any(named: 'driverId'),
        ),
      ).called(1);

      serverGate.complete(ok(const {'id': 1}));
      await first;
      expect(container.read(eldConnectionProvider).connectionConfirmed, isTrue);
    });
  });

  group('continue disconnected — only confirmed results pass', () {
    test(
      'confirmed non-empty result starts local tracking and reports success',
      () async {
        stubContinue(
          () async => ok(const {
            'id': 1,
            'status': 'ACTIVE',
            'driver': {'id': 7},
          }),
        );

        final container = createContainer(connectivity: Stream.value(true));
        await container.read(isConnectedProvider.future);
        final notifier = container.read(eldConnectionProvider.notifier);

        await notifier.continueDisconnected();

        final state = container.read(eldConnectionProvider);
        expect(state.connectionConfirmed, isTrue);
        expect(state.sessionUnconfirmed, isFalse);
        expect(state.hasFailed, isFalse);
        expect(state.infoMessage, 'disconnected_accepted');
        verify(() => tracking.startTracking()).called(1);
      },
    );

    test(
      'offline continue records a pending snapshot and starts tracking',
      () async {
        final container = createContainer(
          connectivity: Stream.value(false),
          driverId: 7,
        );
        await container.read(isConnectedProvider.future);
        final notifier = container.read(eldConnectionProvider.notifier);

        await notifier.continueDisconnected();

        final state = container.read(eldConnectionProvider);
        expect(state.hasFailed, isFalse);
        expect(state.connectionConfirmed, isFalse);
        expect(state.localSessionPendingSync, isTrue);
        expect(state.sessionStarted, isTrue);
        expect(state.sessionUnconfirmed, isFalse);
        expect(state.infoMessage, 'session_local_pending');
        verifyNever(
          () => hardware.connectSession(
            uniqueId: any(named: 'uniqueId'),
            disconnected: true,
          ),
        );
        verify(() => tracking.startTracking()).called(1);

        final snapshot = snapshotFor(7);
        expect(snapshot, isNotNull);
        expect(snapshot!.syncState, EldSessionSyncState.pending);
        expect(snapshot.origin, EldSessionOrigin.localManual);
        expect(snapshot.manualMode, isTrue);
        expect(snapshot.vehicleUniqueId, '1001');
      },
    );

    test(
      'explicit server rejection stays a failure without local activation',
      () async {
        stubContinue(() async => err<RawJson>(_connectRejected));

        final container = createContainer(connectivity: Stream.value(true));
        final notifier = container.read(eldConnectionProvider.notifier);

        await notifier.continueDisconnected();

        final state = container.read(eldConnectionProvider);
        expect(state.hasFailed, isTrue);
        expect(state.errorMessage, 'disconnected_rejected');
        expect(state.sessionUnconfirmed, isFalse);
        expect(state.connectionConfirmed, isFalse);
        expect(state.infoMessage, isNull);
        verifyNever(() => tracking.startTracking());
      },
    );

    test(
      'unconfirmed error keeps the warning and does not claim acceptance',
      () async {
        stubContinue(() async => err<RawJson>(_connectUnconfirmed));

        final container = createContainer(connectivity: Stream.value(true));
        final notifier = container.read(eldConnectionProvider.notifier);

        await notifier.continueDisconnected();

        final state = container.read(eldConnectionProvider);
        expect(state.hasFailed, isFalse);
        expect(state.sessionUnconfirmed, isTrue);
        expect(state.connectionConfirmed, isFalse);
        expect(state.errorMessage, isNull);
        expect(state.error?.code, 'eld.session.connectUnconfirmed');
        expect(state.infoMessage, isNull);
        verifyNever(() => tracking.startTracking());
      },
    );

    test('an empty success payload cannot confirm a session', () async {
      stubContinue(() async => ok(const <String, dynamic>{}));

      final container = createContainer(connectivity: Stream.value(true));
      final notifier = container.read(eldConnectionProvider.notifier);

      await notifier.continueDisconnected();

      final state = container.read(eldConnectionProvider);
      expect(state.sessionUnconfirmed, isTrue);
      expect(state.connectionConfirmed, isFalse);
      expect(state.infoMessage, isNull);
      expect(state.error?.code, 'eld.session.connectUnconfirmed');
      verifyNever(() => tracking.startTracking());
    });

    test(
      'unknown connectivity still sends the request and decides by result',
      () async {
        stubContinue(() async => ok(const {'id': 1}));

        final container = createContainer(
          connectivity: const Stream<bool>.empty(),
        );
        final notifier = container.read(eldConnectionProvider.notifier);

        await notifier.continueDisconnected();

        final state = container.read(eldConnectionProvider);
        expect(state.connectionConfirmed, isTrue);
        verify(
          () => hardware.connectSession(
            uniqueId: any(named: 'uniqueId'),
            disconnected: true,
          ),
        ).called(1);
      },
    );
  });

  group('device identity and GET-first', () {
    test(
      'POST /connect sends vehicle.uniqueId as deviceId, never the MAC',
      () async {
        String? capturedUniqueId;
        final driverSession = _MockDriverSessionBackend();
        when(() => driverSession.getActiveSession(any())).thenAnswer(
          (_) async =>
              err<RawJson>(const NotFoundError(code: 'eld.session.noneActive')),
        );
        when(
          () => hardware.connectSession(
            uniqueId: any(named: 'uniqueId'),
            disconnected: false,
            driverId: any(named: 'driverId'),
          ),
        ).thenAnswer((invocation) async {
          capturedUniqueId =
              invocation.namedArguments[#uniqueId] as String?;
          return ok(const {'id': 1, 'status': 'ACTIVE'});
        });

        final container = createContainer(
          driverId: 7,
          driverSession: driverSession,
        );
        final notifier = container.read(eldConnectionProvider.notifier);

        await notifier.attemptConnection('AA:BB:CC:DD:EE:FF');

        expect(capturedUniqueId, '1001');
        expect(snapshotFor(7)?.vehicleUniqueId, '1001');
        verify(() => driverSession.getActiveSession(any())).called(1);
      },
    );

    test('no selected vehicle is refused before Bluetooth or HTTP', () async {
      final container = createContainer(vehicle: null, driverId: 7);
      final notifier = container.read(eldConnectionProvider.notifier);

      await notifier.attemptConnection('AA:BB:CC:DD:EE:FF');
      expect(
        container.read(eldConnectionProvider).errorMessage,
        'vehicle_missing',
      );

      await notifier.continueDisconnected();

      final state = container.read(eldConnectionProvider);
      expect(state.hasFailed, isTrue);
      expect(state.errorMessage, 'vehicle_missing');
      expect(state.connectionConfirmed, isFalse);
      expect(state.localSessionPendingSync, isFalse);
      verifyNever(() => bt.connect(any()));
      verifyNever(
        () => hardware.connectSession(
          uniqueId: any(named: 'uniqueId'),
          disconnected: false,
          driverId: any(named: 'driverId'),
        ),
      );
      verifyNever(
        () => hardware.connectSession(
          uniqueId: any(named: 'uniqueId'),
          disconnected: true,
          driverId: any(named: 'driverId'),
        ),
      );
    });

    test(
      'GET-first adopts an active server session without a second POST',
      () async {
        final driverSession = _MockDriverSessionBackend();
        when(() => driverSession.getActiveSession(any())).thenAnswer(
          (_) async => ok(const {
            'id': 55,
            'status': 'ACTIVE',
            'connectionStatus': 'CONNECTED',
            'vehicle': {'uniqueId': '1001', 'name': 'Truck 1001'},
          }),
        );

        final container = createContainer(
          driverId: 7,
          driverSession: driverSession,
        );
        final notifier = container.read(eldConnectionProvider.notifier);

        // لا توجد لقطة محلية سابقة — ومع ذلك يجب أن يُقرأ السيرفر أولاً.
        await notifier.attemptConnection('AA:BB:CC:DD:EE:FF');

        final state = container.read(eldConnectionProvider);
        expect(state.connectionConfirmed, isTrue);
        expect(state.sessionUnconfirmed, isFalse);
        expect(state.infoMessage, 'connected');
        verifyNever(
          () => hardware.connectSession(
            uniqueId: any(named: 'uniqueId'),
            disconnected: false,
            driverId: any(named: 'driverId'),
          ),
        );
        final snapshot = snapshotFor(7);
        expect(snapshot?.sessionId, 55);
        expect(snapshot?.syncState, EldSessionSyncState.synced);
        expect(snapshot?.origin, EldSessionOrigin.server);
      },
    );

    test(
      'an active server session on another vehicle is a conflict',
      () async {
        final driverSession = _MockDriverSessionBackend();
        when(() => driverSession.getActiveSession(any())).thenAnswer(
          (_) async => ok(const {
            'id': 70,
            'status': 'ACTIVE',
            'vehicle': {'uniqueId': '2002'},
          }),
        );

        final container = createContainer(
          driverId: 7,
          driverSession: driverSession,
        );
        final notifier = container.read(eldConnectionProvider.notifier);

        await notifier.attemptConnection('AA:BB:CC:DD:EE:FF');

        final state = container.read(eldConnectionProvider);
        expect(state.hasFailed, isTrue);
        expect(state.errorMessage, 'session_conflict');
        expect(state.connectionConfirmed, isFalse);
        expect(snapshotFor(7), isNull);
        verifyNever(
          () => hardware.connectSession(
            uniqueId: any(named: 'uniqueId'),
            disconnected: false,
            driverId: any(named: 'driverId'),
          ),
        );
        verifyNever(() => tracking.startTracking());
      },
    );
  });

  group('cancellation', () {
    test(
      'before HTTP dispatch: no server write and no unconfirmed warning',
      () async {
        final bluetoothGate = Completer<void>();
        when(() => bt.connect(any())).thenAnswer((_) => bluetoothGate.future);

        final container = createContainer();
        final notifier = container.read(eldConnectionProvider.notifier);

        unawaited(notifier.attemptConnection('AA:BB:CC:DD:EE:FF'));
        await Future<void>.delayed(Duration.zero);
        await notifier.cancelConnection();

        var state = container.read(eldConnectionProvider);
        expect(state.wasCancelled, isTrue);
        expect(state.serverRequestPending, isFalse);
        expect(state.sessionUnconfirmed, isFalse);
        expect(state.connectionConfirmed, isFalse);

        bluetoothGate.complete();
        await Future<void>.delayed(Duration.zero);

        state = container.read(eldConnectionProvider);
        expect(state.sessionUnconfirmed, isFalse);
        verifyNever(
          () => hardware.connectSession(
            uniqueId: any(named: 'uniqueId'),
            disconnected: false,
            driverId: any(named: 'driverId'),
          ),
        );
        verifyNever(() => tracking.startTracking());
      },
    );

    test(
      'after HTTP dispatch: unconfirmed, and a late success is ignored',
      () async {
        when(() => bt.connect(any())).thenAnswer((_) async {});
        final serverGate = Completer<Result<RawJson>>();
        stubConnect(() => serverGate.future);

        final container = createContainer();
        final notifier = container.read(eldConnectionProvider.notifier);

        final attempt = notifier.attemptConnection('AA:BB:CC:DD:EE:FF');
        await _waitUntil(
          () => container.read(eldConnectionProvider).serverRequestPending,
        );

        await notifier.cancelConnection();

        var state = container.read(eldConnectionProvider);
        expect(state.wasCancelled, isTrue);
        expect(state.isConnecting, isFalse);
        expect(state.serverRequestPending, isTrue);
        expect(state.sessionUnconfirmed, isTrue);
        expect(state.connectionConfirmed, isFalse);
        expect(state.infoMessage, isNull);

        // The server may still complete the write; this must not be claimed as a
        // confirmed session, and it must not start local tracking.
        serverGate.complete(ok(const {'id': 1, 'status': 'ACTIVE'}));
        await attempt;
        await _waitUntil(
          () => !container.read(eldConnectionProvider).serverRequestPending,
        );

        state = container.read(eldConnectionProvider);
        expect(state.wasCancelled, isTrue);
        expect(state.connectionConfirmed, isFalse);
        expect(state.sessionUnconfirmed, isTrue);
        expect(state.infoMessage, isNull);
        verifyNever(() => tracking.startTracking());
      },
    );

    test(
      'cancelling an already-dispatched write twice stays single-flight',
      () async {
        when(() => bt.connect(any())).thenAnswer((_) async {});
        final serverGate = Completer<Result<RawJson>>();
        stubConnect(() => serverGate.future);

        final container = createContainer();
        final notifier = container.read(eldConnectionProvider.notifier);

        final attempt = notifier.attemptConnection('AA:BB:CC:DD:EE:FF');
        await _waitUntil(
          () => container.read(eldConnectionProvider).serverRequestPending,
        );

        await notifier.cancelConnection();
        await notifier.cancelConnection();

        verify(
          () => hardware.connectSession(
            uniqueId: any(named: 'uniqueId'),
            disconnected: false,
            driverId: any(named: 'driverId'),
          ),
        ).called(1);

        serverGate.complete(err<RawJson>(_connectUnconfirmed));
        await attempt;
        await _waitUntil(
          () => !container.read(eldConnectionProvider).serverRequestPending,
        );

        final state = container.read(eldConnectionProvider);
        expect(state.sessionUnconfirmed, isTrue);
        expect(state.connectionConfirmed, isFalse);
      },
    );
  });
}
