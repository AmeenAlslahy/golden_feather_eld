import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'dart:async';
import 'bluetooth_service.dart';
// import EldEvent

/// التنفيذ الوهمي لـ Bluetooth للبيئة التطويرية
class MockBluetoothDataSource implements BluetoothDataSource {
  final _dataController = StreamController<EldEvent>.broadcast();
  final _statusController =
      StreamController<BluetoothConnectionStatus>.broadcast();
  StreamSubscription? _mockDataSub;

  @override
  Stream<List<EldDevice>> startScanning() {
    _statusController.add(BluetoothConnectionStatus.scanning);
    return Stream.periodic(
      const Duration(seconds: 2),
      (_) => [
        const EldDevice(
            name: 'ELD Adapter 9824',
            macAddress: '00:11:22:33:44:55',
            rssi: -45),
        const EldDevice(
            name: 'ELD Adapter 7731',
            macAddress: 'AA:BB:CC:DD:EE:FF',
            rssi: -78),
      ],
    );
  }

  @override
  Future<void> stopScanning() async {
    _statusController.add(BluetoothConnectionStatus.disconnected);
  }

  @override
  Future<EldDevice?> connect(String macAddress) async {
    _statusController.add(BluetoothConnectionStatus.connecting);
    await Future.delayed(const Duration(seconds: 1));
    _statusController.add(BluetoothConnectionStatus.connected);

    _mockDataSub?.cancel();
    _mockDataSub = Stream.periodic(const Duration(seconds: 1), (_) {
      return EldEvent(
        speedMph: 55.0 + (DateTime.now().millisecond % 10),
        engineRpm: 1500 + (DateTime.now().millisecond % 200),
        odometerMiles: 125000.0 + DateTime.now().millisecond / 1000,
        engineHours: 3500.0 + DateTime.now().millisecond / 3600000,
        timestamp: DateTime.now(),
      );
    }).listen((data) => _dataController.add(data));

    return EldDevice(
      name: 'ELD Adapter 9824',
      macAddress: macAddress,
      vin: '1FUJGLDR5CSBJ0527',
      rssi: -45,
      isConnected: true,
    );
  }

  @override
  Future<void> disconnect() async {
    _mockDataSub?.cancel();
    _statusController.add(BluetoothConnectionStatus.disconnected);
  }

  @override
  Stream<EldEvent> get dataStream => _dataController.stream;

  @override
  Stream<BluetoothConnectionStatus> get statusStream =>
      _statusController.stream;

  @override
  void dispose() {
    _mockDataSub?.cancel();
    _dataController.close();
    _statusController.close();
  }
}
