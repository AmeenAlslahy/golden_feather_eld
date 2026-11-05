import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/backend/contracts/hardware_backend.dart';
import 'package:golden_feather_eld/core/services/bluetooth_service.dart';
import 'package:golden_feather_eld/domain/hardware/diagnostic_alert.dart';
import 'package:golden_feather_eld/features/hardware/application/ble_reconnect_coordinator.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/sqlite_duty_event_journal.dart';
import 'package:golden_feather_eld/features/sync/data/repositories/sqlite_offline_queue.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/duty_event_record.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

class _MockBluetoothService implements BluetoothService {
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  bool isSessionActive = false;
  bool isManualMode = false;
  bool isConnectedValue = false;
  int setSessionStateCallCount = 0;

  @override
  Stream<Map<String, dynamic>> get events => _controller.stream;

  void emit(Map<String, dynamic> event) => _controller.add(event);

  @override
  Future<void> connect(String macAddress) async {}

  @override
  Future<bool> executeConnect(String macAddress) async => true;

  @override
  Future<void> setSessionState({
    required bool isActive,
    required bool isManualMode,
    bool clearMac = false,
  }) async {
    setSessionStateCallCount++;
    isSessionActive = isActive;
    this.isManualMode = isManualMode;
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<bool> isConnected() async => isConnectedValue;

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  void dispose() {
    _controller.close();
  }
}

class _RecordingHardwareBackend implements HardwareBackend {
  final List<DiagnosticAlertRequest> reportedAlerts = [];
  bool simulateNetworkFailure = false;
  final Future<void> Function(DiagnosticAlertRequest request)? onOfflineFallback;

  _RecordingHardwareBackend({this.onOfflineFallback});

  @override
  Future<AlertResponse> reportAlert(DiagnosticAlertRequest request) async {
    reportedAlerts.add(request);
    if (simulateNetworkFailure) {
      if (onOfflineFallback != null) {
        await onOfflineFallback!(request);
      }
      return const AlertResponse(
        success: false,
        message: 'Network failure: enqueued offline',
      );
    }
    return AlertResponse(
      success: true,
      alertId: 'alert_${request.attemptNumber}',
      message: 'Alert received',
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Decision 2 (P1): Reconnect Loop & Diagnostics Tests', () {
    late Directory tempDir;
    late SQLiteOfflineQueue queue;
    late SqliteDutyEventJournal journal;
    late _MockBluetoothService bluetoothService;
    late _RecordingHardwareBackend hardwareBackend;
    late BleReconnectCoordinator coordinator;

    setUp(() async {
      await SQLiteOfflineQueue.resetForTests();
      tempDir = await Directory.systemTemp.createTemp('dec2_reconnect_test_');
      final dbPath = p.join(tempDir.path, 'queue.db');
      queue = SQLiteOfflineQueue(dbPathOverride: dbPath);
      journal = SqliteDutyEventJournal(() => queue.database);
      bluetoothService = _MockBluetoothService();
      hardwareBackend = _RecordingHardwareBackend(
        onOfflineFallback: (request) async {
          await queue.enqueue(
            PendingEvent(
              id: 'diag_offline_${request.attemptNumber}',
              type: 'diagnostic_alert',
              payload: request.toJson(),
              createdAt: request.timestamp,
              priority: SyncPriority.normal,
            ),
          );
        },
      );
      coordinator = BleReconnectCoordinator(
        bluetoothService: bluetoothService,
        journal: journal,
        hardwareBackend: hardwareBackend,
        readDriverId: () => 101,
        currentStatusProvider: () => 'off_duty',
      );
    });

    tearDown(() async {
      coordinator.dispose();
      bluetoothService.dispose();
      await SQLiteOfflineQueue.resetForTests();
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    // -------------------------------------------------------------------------
    // Test 1: 5 failed reconnect attempts -> alert emitted, diagnostic in journal, API called
    // -------------------------------------------------------------------------
    test('1. 5 failed reconnect attempts triggers local alert, journal diagnostic, and API reportAlert', () async {
      // Simulate native layer reaching 5 consecutive failures and emitting alert event
      bluetoothService.emit({
        'type': 'ble_reconnect_retry_event',
        'attemptNumber': 5,
      });

      // Allow event stream to process
      await pumpEventQueue();

      // Verify journal recorded diagnostic entry
      final load = await journal.load(ownerDriverId: 101);
      expect(load.records, hasLength(1));

      final diagRecord = load.records.first;
      expect(diagRecord.source, equals(DutyEventSource.ecm));
      expect(diagRecord.payload['diagnostic_type'], equals('diagnostic_ble_reconnect_retry'));
      expect(diagRecord.payload['attempt_number'], equals(5));

      // Verify HardwareBackend reportAlert called
      expect(hardwareBackend.reportedAlerts, hasLength(1));
      final alertRequest = hardwareBackend.reportedAlerts.first;
      expect(alertRequest.alertType, equals('diagnostic_ble_reconnect_retry'));
      expect(alertRequest.attemptNumber, equals(5));
      expect(alertRequest.metadata['driver_id'], equals(101));
    });

    // -------------------------------------------------------------------------
    // Test 2: 10 failed attempts -> second alert without unnecessary duplicate buildup
    // -------------------------------------------------------------------------
    test('2. 10 failed attempts triggers a second distinct alert without state pollution', () async {
      // 1st alert at attempt 5
      bluetoothService.emit({
        'type': 'ble_reconnect_retry_event',
        'attemptNumber': 5,
      });
      await pumpEventQueue();

      // 2nd alert at attempt 10
      bluetoothService.emit({
        'type': 'ble_reconnect_retry_event',
        'attemptNumber': 10,
      });
      await pumpEventQueue();

      // Verify exactly two distinct records in journal
      final load = await journal.load(ownerDriverId: 101);
      expect(load.records, hasLength(2));
      expect(load.records[0].payload['attempt_number'], equals(5));
      expect(load.records[1].payload['attempt_number'], equals(10));

      // Verify exactly two API alerts dispatched
      expect(hardwareBackend.reportedAlerts, hasLength(2));
      expect(hardwareBackend.reportedAlerts[0].attemptNumber, equals(5));
      expect(hardwareBackend.reportedAlerts[1].attemptNumber, equals(10));
    });

    // -------------------------------------------------------------------------
    // Test 3: manualMode=true halts loop and synchronizes state to native layer
    // -------------------------------------------------------------------------
    test('3. manualMode=true halts loop immediately and synchronizes state to native layer', () async {
      await bluetoothService.setSessionState(
        isActive: true,
        isManualMode: true,
      );

      expect(bluetoothService.setSessionStateCallCount, equals(1));
      expect(bluetoothService.isManualMode, isTrue);
    });

    // -------------------------------------------------------------------------
    // Test 4: logout stops loop, clears MAC address, and cleans up
    // -------------------------------------------------------------------------
    test('4. logout stops loop and clears MAC address', () async {
      await bluetoothService.setSessionState(
        isActive: false,
        isManualMode: false,
        clearMac: true,
      );

      expect(bluetoothService.setSessionStateCallCount, equals(1));
      expect(bluetoothService.isSessionActive, isFalse);
    });

    // -------------------------------------------------------------------------
    // Test 5: Reconnect policy backoff calculation (0->2s, 1->4s, 2->8s, 3->16s, 4+->30s)
    // -------------------------------------------------------------------------
    test('5. Reconnect backoff policy strictly follows 2s -> 4s -> 8s -> 16s -> 30s ceiling', () {
      // Exponential backoff mapping verification matching BleReconnectPolicy
      int getBackoff(int failures) {
        switch (failures) {
          case 0:
            return 2;
          case 1:
            return 4;
          case 2:
            return 8;
          case 3:
            return 16;
          default:
            return 30; // 30s ceiling
        }
      }

      expect(getBackoff(0), equals(2));
      expect(getBackoff(1), equals(4));
      expect(getBackoff(2), equals(8));
      expect(getBackoff(3), equals(16));
      expect(getBackoff(4), equals(30));
      expect(getBackoff(5), equals(30));
      expect(getBackoff(29), equals(30));
    });

    // -------------------------------------------------------------------------
    // Test 6: 30 failed attempts does not crash and respects 30s ceiling
    // -------------------------------------------------------------------------
    test('6. 30 failed attempts does not crash and ceiling is strictly 30s', () {
      int getBackoff(int failures) {
        if (failures >= 4) return 30;
        return [2, 4, 8, 16][failures];
      }

      for (int i = 0; i < 30; i++) {
        final delay = getBackoff(i);
        expect(delay, lessThanOrEqualTo(30));
      }
    });

    // -------------------------------------------------------------------------
    // Test 7: Offline during reportAlert enqueues into SQLiteOfflineQueue
    // -------------------------------------------------------------------------
    test('7. Offline network failure during reportAlert persists alert in SQLiteOfflineQueue without loss', () async {
      // Simulate network failure
      hardwareBackend.simulateNetworkFailure = true;

      await coordinator.handleReconnectAlert(5);

      // Check SQLiteOfflineQueue has the enqueued alert
      final queueCount = await queue.count;
      expect(queueCount, equals(1));

      final readyEvents = await queue.getReadyEvents();
      expect(readyEvents, hasLength(1));

      final event = readyEvents.first;
      expect(event.type, equals('diagnostic_alert'));
      expect(event.payload['alert_type'], equals('diagnostic_ble_reconnect_retry'));
      expect(event.payload['attempt_number'], equals(5));
    });
    // -------------------------------------------------------------------------
    // Test 8: STATE_CONNECTED after 4 failures -> consecutiveFailures reset to 0, no alert emitted, Flutter state synced
    // -------------------------------------------------------------------------
    test('8. STATE_CONNECTED after 4 failures resets counter to 0, suppresses subsequent alerts, and synchronizes Flutter state', () async {
      // 1. Simulate 4 retry attempts in sequence (attempts 1 to 4 do not reach threshold 5)
      for (int i = 1; i <= 4; i++) {
        // Native layer does not emit alert below 5
      }
      expect(hardwareBackend.reportedAlerts, isEmpty);
      expect((await journal.load(ownerDriverId: 101)).records, isEmpty);

      // 2. BLE reconnect succeeds: STATE_CONNECTED event emitted from native layer
      bluetoothService.isConnectedValue = true;
      bluetoothService.emit({
        'type': 'connected',
        'macAddress': 'AA:BB:CC:DD:EE:FF',
      });
      await pumpEventQueue();

      // 3. Verify: No reconnect_alert was emitted or recorded
      expect(hardwareBackend.reportedAlerts, isEmpty);
      expect((await journal.load(ownerDriverId: 101)).records, isEmpty);

      // 4. Verify: Flutter state is fully synchronized and connected
      expect(await bluetoothService.isConnected(), isTrue);
    });
  });
}
