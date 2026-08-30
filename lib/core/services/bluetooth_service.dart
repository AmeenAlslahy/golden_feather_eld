import 'package:golden_feather_eld/core/engine/hos_models.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/logger.dart';
// import EldEvent
import '../constants/channel_constants.dart';
import 'mock_bluetooth_data_source.dart';

/// جهاز ELD
class EldDevice {
  final String name;
  final String macAddress;
  final String? vin;
  final int rssi;
  final bool isConnected;

  const EldDevice({
    required this.name,
    required this.macAddress,
    this.vin,
    required this.rssi,
    this.isConnected = false,
  });

  factory EldDevice.fromMap(Map<dynamic, dynamic> map) {
    return EldDevice(
      name: map['name'] as String? ?? 'Unknown',
      macAddress: map['macAddress'] as String? ?? '',
      vin: map['vin'] as String?,
      rssi: map['rssi'] as int? ?? 0,
      isConnected: map['isConnected'] as bool? ?? false,
    );
  }
}

/// حالة اتصال Bluetooth
enum BluetoothConnectionStatus {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

/// واجهة تجريد اتصال البلوتوث
abstract class BluetoothDataSource {
  Stream<List<EldDevice>> startScanning();
  Future<void> stopScanning();
  Future<EldDevice?> connect(String macAddress);
  Future<void> disconnect();

  Stream<EldEvent> get dataStream;
  Stream<BluetoothConnectionStatus> get statusStream;

  void dispose();
}

/// التنفيذ الحقيقي لـ Bluetooth عبر MethodChannel
class RealBluetoothDataSource implements BluetoothDataSource {
  static const MethodChannel _channel =
      MethodChannel(ChannelConstants.bluetooth);

  final _dataController = StreamController<EldEvent>.broadcast();
  final _statusController =
      StreamController<BluetoothConnectionStatus>.broadcast();
  final _scanController = StreamController<List<EldDevice>>.broadcast();

  RealBluetoothDataSource() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    try {
      switch (call.method) {
        case 'onDevicesFound':
          final list = call.arguments as List;
          final devices = list.map((e) => EldDevice.fromMap(e as Map)).toList();
          _scanController.add(devices);
          break;
        case 'onStatusChanged':
          final statusStr = call.arguments as String;
          final status = BluetoothConnectionStatus.values.firstWhere(
            (e) => e.name == statusStr,
            orElse: () => BluetoothConnectionStatus.error,
          );
          _statusController.add(status);
          break;
        case 'onDataReceived':
          final data = EldEvent.fromMap(call.arguments as Map);
          _dataController.add(data);
          break;
      }
    } catch (e) {
      AppLogger.error('Error handling Bluetooth MethodCall: ${call.method}', e);
    }
  }

  @override
  Stream<List<EldDevice>> startScanning() {
    _channel.invokeMethod('startScanning');
    return _scanController.stream;
  }

  @override
  Future<void> stopScanning() async {
    await _channel.invokeMethod('stopScanning');
  }

  @override
  Future<EldDevice?> connect(String macAddress) async {
    final result =
        await _channel.invokeMethod('connect', {'macAddress': macAddress});
    if (result != null) {
      return EldDevice.fromMap(result as Map);
    }
    return null;
  }

  @override
  Future<void> disconnect() async {
    await _channel.invokeMethod('disconnect');
  }

  @override
  Stream<EldEvent> get dataStream => _dataController.stream;

  @override
  Stream<BluetoothConnectionStatus> get statusStream =>
      _statusController.stream;

  @override
  void dispose() {
    _dataController.close();
    _statusController.close();
    _scanController.close();
  }
}

/// خدمة Bluetooth محسنة لإدارة الذاكرة
class BluetoothService {
  final BluetoothDataSource _dataSource;

  BluetoothConnectionStatus _status = BluetoothConnectionStatus.disconnected;
  EldDevice? _connectedDevice;

  StreamSubscription? _dataSubscription;
  StreamSubscription? _statusSubscription;

  void Function(EldEvent)? _onDataReceived;
  void Function(BluetoothConnectionStatus)? _onStatusChanged;

  BluetoothService({required BluetoothDataSource dataSource})
      : _dataSource = dataSource {
    _statusSubscription = _dataSource.statusStream.listen((status) {
      _status = status;
      _onStatusChanged?.call(status);
      if (status == BluetoothConnectionStatus.disconnected) {
        _connectedDevice = null;
      }
    });

    _dataSubscription = _dataSource.dataStream.listen((data) {
      _onDataReceived?.call(data);
    });
  }

  BluetoothConnectionStatus get status => _status;
  EldDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _status == BluetoothConnectionStatus.connected;

  Stream<List<EldDevice>> startScanning() {
    AppLogger.info('🔍 BLE Scanning started');
    return _dataSource.startScanning();
  }

  void stopScanning() {
    AppLogger.info('🔍 BLE Scanning stopped');
    _dataSource.stopScanning();
  }

  Future<bool> connect(String macAddress) async {
    AppLogger.info('🔗 Connecting to $macAddress');
    final device = await _dataSource.connect(macAddress);
    if (device != null) {
      _connectedDevice = device;
      AppLogger.info('✅ Connected to $macAddress');
      return true;
    }
    return false;
  }

  Future<void> disconnect() async {
    await _dataSource.disconnect();
    AppLogger.info('🔌 Disconnected');
  }

  void onDataReceived(void Function(EldEvent) callback) {
    _onDataReceived = callback;
  }

  void onStatusChanged(void Function(BluetoothConnectionStatus) callback) {
    _onStatusChanged = callback;
  }

  void dispose() {
    _dataSubscription?.cancel();
    _statusSubscription?.cancel();
    _dataSource.dispose();
    AppLogger.info('BluetoothService disposed');
  }
}

/// مزود مصدر بيانات البلوتوث
final bluetoothDataSourceProvider = Provider<BluetoothDataSource>((ref) {
  const bool useRealBluetooth =
      bool.fromEnvironment('USE_REAL_BLUETOOTH', defaultValue: false);
  final dataSource =
      useRealBluetooth ? RealBluetoothDataSource() : MockBluetoothDataSource();
  ref.onDispose(() => dataSource.dispose());
  return dataSource;
});

/// مزود خدمة Bluetooth
final bluetoothServiceProvider = Provider<BluetoothService>((ref) {
  final dataSource = ref.watch(bluetoothDataSourceProvider);
  return BluetoothService(dataSource: dataSource);
});
