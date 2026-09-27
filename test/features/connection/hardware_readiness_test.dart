import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/connection/domain/connectivity_status.dart';
import 'package:golden_feather_eld/features/connection/domain/hardware_readiness.dart';

/// `GET /eld/hardware/readiness` (PreOperationReadinessResponse) and the
/// manual-mode fields of `GET /eld/hardware/status` — shapes as seen on the
/// live server for driver 106 / ELD-PRO-1006 (2026-09-25).
void main() {
  test('live readiness body: checklist order kept, reasons and action read', () {
    final read = parseHardwareReadiness(const {
      'uniqueId': 'ELD-PRO-1006',
      'vehicleName': 'Truck #1006',
      'checklist': {
        'device_paired': true,
        'connection_active': false,
        'motion_data': false,
        'location_data': false,
        'engine_telemetry': false,
      },
      'rejectionReasons': ['no signal', 'manual mode active'],
      'recommendedAction': 'end manual mode after the device reconnects',
      'ready': false,
    })!;

    expect(read.ready, isFalse);
    expect(read.checklist.keys.toList(), [
      'device_paired',
      'connection_active',
      'motion_data',
      'location_data',
      'engine_telemetry',
    ]);
    expect(read.checklist['device_paired'], isTrue);
    expect(read.checklist['engine_telemetry'], isFalse);
    expect(read.rejectionReasons, hasLength(2));
    expect(read.recommendedAction, 'end manual mode after the device reconnects');
  });

  test('missing ready is not ready; envelope {data:{}} unwrapped', () {
    final read = parseHardwareReadiness(const {
      'data': {'checklist': {'device_paired': true}},
    })!;
    expect(read.ready, isFalse);
    expect(read.checklist, {'device_paired': true});
    expect(read.rejectionReasons, isEmpty);
    expect(read.recommendedAction, isNull);
  });

  test('non-object body or malformed lists are unreadable', () {
    expect(parseHardwareReadiness('oops'), isNull);
    expect(parseHardwareReadiness(const {'checklist': 'x'}), isNull);
    expect(parseHardwareReadiness(const {'rejectionReasons': 'x'}), isNull);
  });

  test('status carries the manual-mode fields; absent means unknown, not active', () {
    final active = parseConnectivityStatus(const {
      'connectionStatus': 'UNAVAILABLE',
      'manualRecordingAllowed': true,
      'manualModeActive': true,
      'manualModeReason': 'no connection',
    })!;
    expect(active.manualModeActive, isTrue);
    expect(active.manualModeReason, 'no connection');
    expect(active.manualRecordingAllowed, isTrue);

    final unknown = parseConnectivityStatus(const {'connectionStatus': 'CONNECTED'})!;
    expect(unknown.manualModeActive, isNull);
    expect(unknown.manualRecordingAllowed, isNull);
  });
}
