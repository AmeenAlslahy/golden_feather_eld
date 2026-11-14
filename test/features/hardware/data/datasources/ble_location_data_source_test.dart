import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/services/bluetooth_service.dart';
import 'package:golden_feather_eld/features/hardware/application/ble_frame_monitor.dart';
import 'package:golden_feather_eld/features/hardware/data/datasources/ble_location_data_source.dart';

/// The production service talks to a MethodChannel; the datasource only needs
/// the `events` stream, so overriding that getter keeps the test plugin-free.
class _FakeBluetoothService extends BluetoothService {
  final StreamController<Map<String, dynamic>> _controller =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get events => _controller.stream;

  void emit(Map<String, dynamic> event) => _controller.add(event);

  Future<void> close() => _controller.close();
}

Map<String, dynamic> _dataFrame(String ascii) {
  final bytes = ascii.codeUnits;
  return {
    'type': 'data',
    'hex': bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase(),
    'ascii': ascii,
    'values': bytes,
    'characteristic': 'ffe1',
  };
}

void main() {
  late _FakeBluetoothService bluetooth;
  late List<Map<String, dynamic>> pushes;
  late BleLocationDataSource source;

  setUp(() {
    bluetooth = _FakeBluetoothService();
    pushes = [];
    BleFrameMonitor.instance.clear();
    source = BleLocationDataSource(
      bluetoothService: bluetooth,
      pushLocation: (location) async => pushes.add(location),
      monitor: BleFrameMonitor.instance,
    );
  });

  tearDown(() async {
    source.stop();
    await bluetooth.close();
  });

  test('forwards a decoded NMEA fix to the native queue', () async {
    source.start();
    bluetooth.emit(
      _dataFrame(
        r'$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W'
        '\r\n',
      ),
    );
    await pumpEventQueue();

    expect(pushes, hasLength(1));
    expect(pushes.single['source'], 'ble');
    expect(pushes.single['latitude'], closeTo(48.1173, 0.0001));
    expect(pushes.single['longitude'], closeTo(11.5167, 0.0001));
    // 22.4 knots normalised to metres per second for the native uploader.
    expect(pushes.single['speed'], closeTo(11.52, 0.01));
  });

  test('drops repeated identical frames within the rate limit', () async {
    source.start();
    final frame = _dataFrame(
      r'$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W'
      '\r\n',
    );
    bluetooth.emit(frame);
    bluetooth.emit(frame);
    await pumpEventQueue();

    expect(pushes, hasLength(1));
  });

  test('ignores payloads without a location sentence', () async {
    source.start();
    bluetooth.emit(_dataFrame('AT+OK\r\n'));
    await pumpEventQueue();

    expect(pushes, isEmpty);
  });

  test('rejects fixes at null island', () async {
    source.start();
    bluetooth.emit(
      _dataFrame(
        r'$GPRMC,123519,A,0000.000,N,00000.000,E,000.0,000.0,230394,003.1,W'
        '\r\n',
      ),
    );
    await pumpEventQueue();

    expect(pushes, isEmpty);
  });

  test('records raw frames for field diagnostics', () async {
    source.start();
    bluetooth.emit(_dataFrame('AT+OK\r\n'));
    await pumpEventQueue();

    final kinds = BleFrameMonitor.instance.frames.map((f) => f.kind).toList();
    expect(kinds, contains('data'));
    expect(kinds, contains('info'));
  });

  test('stops forwarding after stop()', () async {
    source.start();
    source.stop();

    bluetooth.emit(
      _dataFrame(
        r'$GPRMC,123519,A,4807.038,N,01131.000,E,022.4,084.4,230394,003.1,W'
        '\r\n',
      ),
    );
    await pumpEventQueue();

    expect(pushes, isEmpty);
  });
}
