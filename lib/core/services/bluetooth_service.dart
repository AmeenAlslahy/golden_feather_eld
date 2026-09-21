import 'dart:async';
import 'package:flutter/services.dart';
import '../constants/channel_constants.dart';
import '../utils/logger.dart';

/// Exceptions specific to Bluetooth operations.
class BluetoothException implements Exception {
  final String code;
  final String message;

  BluetoothException(this.code, this.message);

  @override
  String toString() => 'BluetoothException($code): $message';
}

/// Service to interact with the Native Bluetooth plugin.
class BluetoothService {
  final MethodChannel _methodChannel = const MethodChannel(ChannelConstants.bluetooth);
  final EventChannel _eventChannel = const EventChannel('${ChannelConstants.bluetooth}/events');

  final StreamController<Map<String, dynamic>> _eventStreamController = StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _eventSubscription;

  BluetoothService() {
    _initEventStream();
  }

  void _initEventStream() {
    _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
      (event) {
        if (event is Map) {
          final eventMap = Map<String, dynamic>.from(event);
          _eventStreamController.add(eventMap);
        }
      },
      onError: (error) {
        AppLogger.error('Bluetooth EventChannel Error', error);
      },
    );
  }

  /// Stream of raw events from the Bluetooth plugin.
  Stream<Map<String, dynamic>> get events => _eventStreamController.stream;

  /// Start scanning for ELD Bluetooth devices.
  Future<void> startScan() async {
    try {
      await _methodChannel.invokeMethod('startScan');
    } on PlatformException catch (e) {
      throw BluetoothException(e.code, e.message ?? 'Unknown error starting scan');
    }
  }

  /// Stop scanning.
  Future<void> stopScan() async {
    try {
      await _methodChannel.invokeMethod('stopScan');
    } on PlatformException catch (e) {
      throw BluetoothException(e.code, e.message ?? 'Unknown error stopping scan');
    }
  }

  /// Connect to an ELD device using its MAC address (or UUID on iOS).
  Future<void> connect(String macAddress) async {
    try {
      await _methodChannel.invokeMethod('connect', {'macAddress': macAddress});
    } on PlatformException catch (e) {
      throw BluetoothException(e.code, e.message ?? 'Unknown error connecting to device');
    }
  }

  /// Disconnect from the currently connected ELD device.
  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      throw BluetoothException(e.code, e.message ?? 'Unknown error disconnecting from device');
    }
  }

  /// Check if the device is currently connected via BLE.
  Future<bool> isConnected() async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('isConnected');
      return result ?? false;
    } on PlatformException catch (e) {
      AppLogger.error('Error checking isConnected', e);
      return false;
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _eventStreamController.close();
  }
}
