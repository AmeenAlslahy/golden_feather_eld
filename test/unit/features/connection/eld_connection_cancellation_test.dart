import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/adapters/mock/mock_adapter.dart';
import 'package:golden_feather_eld/backend/contracts/hardware_backend.dart';
import 'package:golden_feather_eld/backend/providers/backend_providers.dart';
import 'package:golden_feather_eld/core/network/core_providers.dart';
import 'package:golden_feather_eld/core/result/result.dart';
import 'package:golden_feather_eld/core/services/bluetooth_service.dart';
import 'package:golden_feather_eld/core/services/local_storage_service.dart';
import 'package:golden_feather_eld/core/theme/app_theme.dart';
import 'package:golden_feather_eld/core/widgets/app_button.dart';
import 'package:golden_feather_eld/features/connection/presentation/pages/eld_connection_page.dart';
import 'package:golden_feather_eld/features/connection/presentation/providers/hardware_status_provider.dart';
import 'package:golden_feather_eld/features/vehicle/domain/entities/vehicle.dart';
import 'package:golden_feather_eld/features/vehicle/presentation/providers/vehicle_provider.dart';
import 'package:golden_feather_eld/l10n/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockBluetoothService extends Mock implements BluetoothService {}

class _MockHardwareBackend extends Mock implements HardwareBackend {}

class _FakeVehicleNotifier extends StateNotifier<VehicleState>
    implements VehicleNotifier {
  _FakeVehicleNotifier(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _vehicle = Vehicle(
  id: 'VH-001',
  uniqueId: '1001',
  name: 'Truck 1001',
  year: '2024',
);

/// كل محاولة اتصال تشترط هوية مركبة (`vehicle.uniqueId` هو `deviceId`).
final List<Override> _vehicleOverrides = [
  vehicleProvider.overrideWith(
    (ref) => _FakeVehicleNotifier(
      const VehicleState(selectedVehicle: _vehicle, vehicles: [_vehicle]),
    ),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockBluetoothService mockBt;
  late _MockHardwareBackend mockHardware;
  late LocalStorageService realStorage;

  setUp(() async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.withData({
      'language': 'en',
      'selected_vehicle_id': 'VH-001',
    });
    realStorage = LocalStorageService();
    await realStorage.init();

    mockBt = _MockBluetoothService();
    mockHardware = _MockHardwareBackend();

    when(() => mockBt.disconnect()).thenAnswer((_) async {});
  });

  group('UX-001: BLE Connection Overlay Cancellation & Safety', () {
    test('1. Successful connection completes and transitions state', () async {
      when(() => mockBt.connect(any())).thenAnswer((_) async {});
      when(() => mockHardware.connectSession(uniqueId: any(named: 'uniqueId')))
          .thenAnswer((_) async => ok(const {'status': 'connected'}));

      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          bluetoothServiceProvider.overrideWithValue(mockBt),
          hardwareBackendProvider.overrideWithValue(mockHardware),
          localStorageProvider.overrideWithValue(realStorage),
          ..._vehicleOverrides,
        ],
      );
      final sub = container.listen(eldConnectionProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final notifier = container.read(eldConnectionProvider.notifier);

      final future = notifier.attemptConnection('AA:BB:CC:DD:EE:FF');
      expect(container.read(eldConnectionProvider).isConnecting, isTrue);

      await future;

      final state = container.read(eldConnectionProvider);
      expect(state.isConnecting, isFalse);
      expect(state.hasFailed, isFalse);
      expect(state.wasCancelled, isFalse);
    });

    test('2. Device unavailable / Bluetooth exception triggers failure state',
        () async {
      when(() => mockBt.connect(any())).thenThrow(
        BluetoothException('DEVICE_UNAVAILABLE', 'ELD device is not reachable'),
      );

      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          bluetoothServiceProvider.overrideWithValue(mockBt),
          hardwareBackendProvider.overrideWithValue(mockHardware),
          localStorageProvider.overrideWithValue(realStorage),
          ..._vehicleOverrides,
        ],
      );
      final sub = container.listen(eldConnectionProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final notifier = container.read(eldConnectionProvider.notifier);

      await notifier.attemptConnection('AA:BB:CC:DD:EE:FF');

      final state = container.read(eldConnectionProvider);
      expect(state.isConnecting, isFalse);
      expect(state.hasFailed, isTrue);
      expect(state.wasCancelled, isFalse);
      expect(state.errorMessage, equals('bluetooth_failed'));
    });

    test('3. User cancellation terminates overlay and disconnects BLE link',
        () async {
      final completer = Completer<void>();
      when(() => mockBt.connect(any())).thenAnswer((_) => completer.future);

      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          bluetoothServiceProvider.overrideWithValue(mockBt),
          hardwareBackendProvider.overrideWithValue(mockHardware),
          localStorageProvider.overrideWithValue(realStorage),
          ..._vehicleOverrides,
        ],
      );
      final sub = container.listen(eldConnectionProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final notifier = container.read(eldConnectionProvider.notifier);

      // Start in-flight attempt that hangs on BLE connect
      unawaited(notifier.attemptConnection('AA:BB:CC:DD:EE:FF'));
      expect(container.read(eldConnectionProvider).isConnecting, isTrue);

      // Cancel while in-flight
      await notifier.cancelConnection();

      final state = container.read(eldConnectionProvider);
      expect(state.isConnecting, isFalse);
      expect(state.hasFailed, isFalse);
      expect(state.wasCancelled, isTrue);

      verify(() => mockBt.disconnect()).called(1);

      // Even if connect later unblocks or throws, stale response is ignored
      completer.complete();
      await Future<void>.delayed(Duration.zero);

      final afterLateReturn = container.read(eldConnectionProvider);
      expect(afterLateReturn.isConnecting, isFalse);
      expect(afterLateReturn.wasCancelled, isTrue);
    });

    test('4. Repeated cancellation is safe and idempotent', () async {
      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          bluetoothServiceProvider.overrideWithValue(mockBt),
          hardwareBackendProvider.overrideWithValue(mockHardware),
          localStorageProvider.overrideWithValue(realStorage),
          ..._vehicleOverrides,
        ],
      );
      final sub = container.listen(eldConnectionProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final notifier = container.read(eldConnectionProvider.notifier);

      await notifier.cancelConnection();
      await notifier.cancelConnection();
      await notifier.cancelConnection();

      final state = container.read(eldConnectionProvider);
      expect(state.isConnecting, isFalse);
      expect(state.wasCancelled, isTrue);
    });

    test('5. Reconnection succeeds cleanly after a prior cancellation',
        () async {
      when(() => mockBt.connect(any())).thenAnswer((_) async {});
      when(() => mockHardware.connectSession(uniqueId: any(named: 'uniqueId')))
          .thenAnswer((_) async => ok(const {'status': 'connected'}));

      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          bluetoothServiceProvider.overrideWithValue(mockBt),
          hardwareBackendProvider.overrideWithValue(mockHardware),
          localStorageProvider.overrideWithValue(realStorage),
          ..._vehicleOverrides,
        ],
      );
      final sub = container.listen(eldConnectionProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final notifier = container.read(eldConnectionProvider.notifier);

      // 1) Cancel an attempt
      await notifier.cancelConnection();
      expect(container.read(eldConnectionProvider).wasCancelled, isTrue);

      // 2) Re-attempt
      await notifier.attemptConnection('AA:BB:CC:DD:EE:FF');

      final state = container.read(eldConnectionProvider);
      expect(state.isConnecting, isFalse);
      expect(state.hasFailed, isFalse);
      expect(state.wasCancelled, isFalse);
    });

    test('6. Stale connection callbacks do not falsely update state after sequence increment',
        () async {
      final slowConnect = Completer<void>();
      when(() => mockBt.connect('11:11:11:11:11:11'))
          .thenAnswer((_) => slowConnect.future);
      when(() => mockBt.connect('22:22:22:22:22:22')).thenThrow(
        BluetoothException('FAILED', 'Attempt 2 failed'),
      );

      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          bluetoothServiceProvider.overrideWithValue(mockBt),
          hardwareBackendProvider.overrideWithValue(mockHardware),
          localStorageProvider.overrideWithValue(realStorage),
          ..._vehicleOverrides,
        ],
      );
      final sub = container.listen(eldConnectionProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final notifier = container.read(eldConnectionProvider.notifier);

      // Attempt 1 started
      unawaited(notifier.attemptConnection('11:11:11:11:11:11'));

      // Cancel attempt 1
      await notifier.cancelConnection();

      // Attempt 2 started with different MAC and fails
      await notifier.attemptConnection('22:22:22:22:22:22');

      // Now Attempt 1's slow future finally completes
      slowConnect.complete();
      await Future<void>.delayed(Duration.zero);

      // State MUST reflect Attempt 2's failure, not Attempt 1's stale success
      final state = container.read(eldConnectionProvider);
      expect(state.errorMessage, equals('bluetooth_failed'));
      expect(state.hasFailed, isTrue);
      expect(state.wasCancelled, isFalse);
    });

    testWidgets(
        '7. UI overlay shows cancel and continue disconnected buttons and responds to cancellation',
        (tester) async {
      final hangCompleter = Completer<void>();
      when(() => mockBt.connect(any())).thenAnswer((_) => hangCompleter.future);

      tester.view.physicalSize = const Size(1080, 2340);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            activeBackendProvider.overrideWithValue(MockAdapter()),
            bluetoothServiceProvider.overrideWithValue(mockBt),
            hardwareBackendProvider.overrideWithValue(mockHardware),
            localStorageProvider.overrideWithValue(realStorage),
          ..._vehicleOverrides,
            hardwareStatusProvider.overrideWith(
              (ref) async => const ConnectivityStatus(
                connectionStatus: 'DISCONNECTED',
              ),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.light,
            locale: const Locale('en'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: const EldConnectionPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter MAC and tap CONNECT
      await tester.enterText(
          find.byType(TextField).first, 'AA:BB:CC:DD:EE:FF');
      final connectBtn = find.widgetWithText(AppButton, 'CONNECT');
      await tester.ensureVisible(connectBtn);
      await tester.tap(connectBtn);
      await tester.pump();

      // Overlay is visible
      expect(find.text('Connecting...'), findsOneWidget);
      expect(find.byKey(const Key('cancel_connection_button')), findsOneWidget);
      expect(find.byKey(const Key('continue_disconnected_overlay_button')),
          findsOneWidget);

      // Tap Cancel button on overlay
      await tester.tap(find.byKey(const Key('cancel_connection_button')));
      await tester.pumpAndSettle();

      // Overlay is dismissed!
      expect(find.text('Connecting...'), findsNothing);
      expect(find.byKey(const Key('cancel_connection_button')), findsNothing);

      // Disconnect was invoked on BLE service
      verify(() => mockBt.disconnect()).called(1);

      hangCompleter.complete();
    });

    test('8. continueDisconnected dismisses in-flight attempt and accepts disconnected mode',
        () async {
      final completer = Completer<void>();
      when(() => mockBt.connect(any())).thenAnswer((_) => completer.future);
      when(() => mockHardware.connectSession(
            uniqueId: any(named: 'uniqueId'),
            disconnected: true,
          )).thenAnswer((_) async => ok(const {'status': 'ok'}));

      final container = ProviderContainer(
        overrides: [
          activeBackendProvider.overrideWithValue(MockAdapter()),
          bluetoothServiceProvider.overrideWithValue(mockBt),
          hardwareBackendProvider.overrideWithValue(mockHardware),
          localStorageProvider.overrideWithValue(realStorage),
          ..._vehicleOverrides,
        ],
      );
      final sub = container.listen(eldConnectionProvider, (_, __) {});
      addTearDown(() {
        sub.close();
        container.dispose();
      });

      final notifier = container.read(eldConnectionProvider.notifier);

      unawaited(notifier.attemptConnection('AA:BB:CC:DD:EE:FF'));
      expect(container.read(eldConnectionProvider).isConnecting, isTrue);

      await notifier.continueDisconnected();

      final state = container.read(eldConnectionProvider);
      expect(state.isConnecting, isFalse);
      expect(state.infoMessage, equals('disconnected_accepted'));

      verify(() => mockBt.disconnect()).called(1);
      completer.complete();
    });
  });
}
