import 'dart:async';

import '../../../backend/contracts/hardware_backend.dart';
import '../../../core/services/bluetooth_service.dart';
import '../../../core/utils/logger.dart';
import '../../../domain/hardware/diagnostic_alert.dart';
import '../../sync/domain/entities/duty_event_record.dart';
import '../../sync/domain/repositories/duty_event_journal.dart';

/// Decision 2 (P1): Reconnect Loop & Hardware Diagnostics Coordinator.
/// Listens for `ble_reconnect_retry_event` from the native layer, records diagnostic
/// entries in `duty_event_journal`, and dispatches diagnostic alerts to the backend.
class BleReconnectCoordinator {
  final BluetoothService _bluetoothService;
  final DutyEventJournal _journal;
  final HardwareBackend _hardwareBackend;
  final int Function()? _readDriverId;
  final String Function()? _currentStatusProvider;

  StreamSubscription<Map<String, dynamic>>? _subscription;

  BleReconnectCoordinator({
    required BluetoothService bluetoothService,
    required DutyEventJournal journal,
    required HardwareBackend hardwareBackend,
    int Function()? readDriverId,
    String Function()? currentStatusProvider,
  })  : _bluetoothService = bluetoothService,
        _journal = journal,
        _hardwareBackend = hardwareBackend,
        _readDriverId = readDriverId,
        _currentStatusProvider = currentStatusProvider {
    _initSubscription();
  }

  void _initSubscription() {
    _subscription = _bluetoothService.events.listen((event) async {
      final type = event['type'];
      if (type == 'ble_reconnect_retry_event') {
        final attempt = event['attemptNumber'] as int? ?? 0;
        await handleReconnectAlert(attempt);
      }
    }, onError: (e) {
      AppLogger.error('BleReconnectCoordinator event stream error', e);
    });
  }

  Future<void> handleReconnectAlert(int attemptNumber) async {
    final now = DateTime.now().toUtc();
    final driverId = _readDriverId?.call() ?? 0;
    final status = _currentStatusProvider?.call() ?? 'off_duty';

    AppLogger.warning(
      'Decision 2 (P1): Handling BLE reconnect alert for attempt #$attemptNumber',
    );

    // 1. Record diagnostic event in journal
    final record = DutyEventRecord(
      eventId: 'diag_reconnect_${attemptNumber}_${now.microsecondsSinceEpoch}',
      ownerDriverId: driverId,
      source: DutyEventSource.ecm,
      status: status,
      eventTimeUtc: now,
      receivedAtUtc: now,
      timeSource: DutyTimeSource.trusted,
      timeConfidence: DutyTimeConfidence.trusted,
      monotonicMs: now.millisecondsSinceEpoch,
      payload: {
        'diagnostic_type': 'diagnostic_ble_reconnect_retry',
        'attempt_number': attemptNumber,
        'timestamp': now.toIso8601String(),
      },
      syncState: DutyEventSyncState.localOnly,
      createdAt: now,
    );

    try {
      await _journal.append(record);
    } catch (e) {
      AppLogger.error('Failed to append reconnect diagnostic to journal', e);
    }

    // 2. Dispatch alert to HardwareBackend (which falls back to offline queue on network failures)
    final request = DiagnosticAlertRequest(
      alertType: 'diagnostic_ble_reconnect_retry',
      attemptNumber: attemptNumber,
      timestamp: now,
      metadata: {
        'driver_id': driverId,
        'status': status,
      },
    );

    try {
      await _hardwareBackend.reportAlert(request);
    } catch (e) {
      AppLogger.error('Failed to report reconnect alert to backend', e);
    }
  }

  void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}

