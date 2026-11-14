import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
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
  final MethodChannel _methodChannel = const MethodChannel(
    ChannelConstants.bluetooth,
  );
  final EventChannel _eventChannel = const EventChannel(
    '${ChannelConstants.bluetooth}/events',
  );

  final StreamController<Map<String, dynamic>> _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();
  StreamSubscription? _eventSubscription;

  BluetoothService();

  /// The native Bluetooth plugin only exists on Android/iOS.
  ///
  /// Widget/screenshot tests run on the host where no plugin is registered;
  /// subscribing eagerly produced `MissingPluginException` noise that failed
  /// unrelated tests. The subscription is also lazy so creating the service
  /// (e.g. through a Riverpod provider) has no side effects.
  static bool get _platformSupportsBluetooth =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  void _ensureEventSubscription() {
    if (_eventSubscription != null) return;
    if (!_platformSupportsBluetooth) return;
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
  Stream<Map<String, dynamic>> get events {
    _ensureEventSubscription();
    return _eventStreamController.stream;
  }

  /// Discovery events only (`deviceFound`).
  Stream<Map<String, dynamic>> get discoveredDevices =>
      events.where((event) => event['type'] == 'deviceFound');

  /// Payload notifications from the connected device.
  Stream<Map<String, dynamic>> get incomingData =>
      events.where((event) => event['type'] == 'data');

  /// Start scanning for ELD Bluetooth devices.
  Future<void> startScan() async {
    try {
      await _methodChannel.invokeMethod('startScan');
    } on PlatformException catch (e) {
      throw BluetoothException(
        e.code,
        e.message ?? 'Unknown error starting scan',
      );
    }
  }

  /// Stop scanning.
  Future<void> stopScan() async {
    try {
      await _methodChannel.invokeMethod('stopScan');
    } on PlatformException catch (e) {
      throw BluetoothException(
        e.code,
        e.message ?? 'Unknown error stopping scan',
      );
    }
  }

  /// Formats a 12-char hex string (e.g. E0B488C7CAE9) into colon format (E0:B4:88:C7:CA:E9).
  static String? formatMacAddress(String input) {
    final trimmed = input.trim();
    final stripped = trimmed.replaceAll(RegExp(r'[:\-\s]'), '').toUpperCase();
    if (stripped.length == 12 && RegExp(r'^[0-9A-F]{12}$').hasMatch(stripped)) {
      return List.generate(
        6,
        (i) => stripped.substring(i * 2, i * 2 + 2),
      ).join(':');
    }
    if (RegExp(r'^([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$').hasMatch(trimmed)) {
      return trimmed.toUpperCase().replaceAll('-', ':');
    }
    return null;
  }

  /// Searches nearby BLE devices if the input is a device name or serial.
  Future<String> _searchAndResolveDeviceMac(
    String query, {
    Duration scanDuration = const Duration(seconds: 6),
  }) async {
    final cleanQuery = query.trim().toLowerCase();
    if (cleanQuery.isEmpty) {
      throw BluetoothException('INVALID_MAC', 'Device identifier is empty');
    }

    final completer = Completer<String>();
    StreamSubscription? sub;

    try {
      sub = discoveredDevices.listen((event) {
        final name = (event['name'] as String? ?? '').toLowerCase();
        final addr = (event['macAddress'] as String? ?? '').toLowerCase();
        final raw = event['manufacturerData']?.toString().toLowerCase() ?? '';

        if (name.contains(cleanQuery) ||
            addr.replaceAll(':', '').contains(cleanQuery.replaceAll(':', '')) ||
            raw.contains(cleanQuery)) {
          final target = event['macAddress'] as String?;
          if (target != null && !completer.isCompleted) {
            completer.complete(target.toUpperCase());
          }
        }
      });

      await startScan();

      return await completer.future.timeout(
        scanDuration,
        onTimeout: () => throw BluetoothException(
          'TIMEOUT',
          'Could not find any nearby device matching "$query"',
        ),
      );
    } finally {
      await sub?.cancel();
      try {
        await stopScan();
      } catch (_) {}
    }
  }

  /// Connect to an ELD device using its MAC address (or UUID on iOS).
  ///
  /// On mobile devices, this waits for the native GATT connection event
  /// or times out after [timeout].
  Future<void> connect(
    String macAddress, {
    Duration timeout = const Duration(seconds: 10),
  }) async {
    if (!_platformSupportsBluetooth) return;

    final directMac = formatMacAddress(macAddress);
    var targetAddress = directMac ?? macAddress;

    if (directMac == null) {
      // User entered a name/serial (e.g. PT30, PT30-U, 3B5000440418)
      try {
        targetAddress = await _searchAndResolveDeviceMac(macAddress);
      } catch (e) {
        if (e is BluetoothException) rethrow;
        throw BluetoothException(
          'TIMEOUT',
          'Could not find nearby device matching "$macAddress"',
        );
      }
    }

    final normalized = targetAddress.trim().toUpperCase();

    // Check if already connected to this device
    try {
      final isAlreadyConnected = await isConnected();
      final last = await getLastDevice();
      if (isAlreadyConnected &&
          last['macAddress']?.toString().toUpperCase() == normalized) {
        return;
      }
    } catch (_) {}

    final completer = Completer<void>();
    StreamSubscription? sub;
    try {
      sub = events.listen((event) {
        final type = event['type'];
        final addr = event['macAddress']?.toString().toUpperCase();
        if (type == 'connected') {
          if (addr == null || addr.isEmpty || addr == normalized) {
            if (!completer.isCompleted) completer.complete();
          }
        } else if (type == 'disconnected') {
          if (!completer.isCompleted) {
            completer.completeError(
              BluetoothException(
                'DISCONNECTED',
                'Device disconnected during connection handshake',
              ),
            );
          }
        }
      });

      await _methodChannel.invokeMethod('connect', {'macAddress': targetAddress});
      await completer.future.timeout(timeout);
    } on TimeoutException {
      try {
        await disconnect();
      } catch (_) {}
      throw BluetoothException('TIMEOUT', 'Connection to $macAddress timed out');
    } on PlatformException catch (e) {
      throw BluetoothException(
        e.code,
        e.message ?? 'Unknown error connecting to device',
      );
    } finally {
      await sub?.cancel();
    }
  }

  // Decision 2 (P1): Reconnect Loop.
  /// Synchronize driver session active state and manual mode toggle with native service.
  Future<void> setSessionState({
    required bool isActive,
    required bool isManualMode,
    bool clearMac = false,
  }) async {
    try {
      await _methodChannel.invokeMethod('setSessionState', {
        'isActive': isActive,
        'isManualMode': isManualMode,
        'clearMac': clearMac,
      });
    } on PlatformException catch (e) {
      AppLogger.error('Error synchronizing BLE session state', e);
    }
  }

  // Decision 2 (P1): Reconnect Loop.
  /// Pure executor for BLE connection without timers or retry loops.
  Future<bool> executeConnect(String macAddress) async {
    try {
      final result = await _methodChannel.invokeMethod<bool>('executeConnect', {
        'macAddress': macAddress,
      });
      return result ?? false;
    } on PlatformException catch (e) {
      throw BluetoothException(
        e.code,
        e.message ?? 'Unknown error in executeConnect',
      );
    }
  }

  /// Disconnect from the currently connected ELD device.
  Future<void> disconnect() async {
    try {
      await _methodChannel.invokeMethod('disconnect');
    } on PlatformException catch (e) {
      throw BluetoothException(
        e.code,
        e.message ?? 'Unknown error disconnecting from device',
      );
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

  /// Connected device details (MTU, services, characteristics, battery).
  Future<Map<String, dynamic>> readDeviceInfo() async {
    try {
      final result = await _methodChannel.invokeMethod<dynamic>(
        'readDeviceInfo',
      );
      if (result is! Map) return const {};
      return Map<String, dynamic>.from(result);
    } on PlatformException catch (e) {
      AppLogger.error('Error reading BLE device info', e);
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }

  /// Sends a command to the connected ELD (hex string or plain text).
  Future<void> sendCommand({
    String? hex,
    String? text,
    String? characteristic,
    String? writeType,
  }) async {
    try {
      await _methodChannel.invokeMethod('sendCommand', {
        if (hex != null) 'hex': hex,
        if (text != null) 'text': text,
        if (characteristic != null) 'characteristic': characteristic,
        if (writeType != null) 'writeType': writeType,
      });
    } on PlatformException catch (e) {
      throw BluetoothException(
        e.code,
        e.message ?? 'Unknown error sending BLE command',
      );
    }
  }

  /// Last device remembered by the native layer.
  Future<Map<String, dynamic>> getLastDevice() async {
    try {
      final result = await _methodChannel.invokeMethod<dynamic>(
        'getLastDevice',
      );
      if (result is! Map) return const {};
      return Map<String, dynamic>.from(result);
    } on PlatformException {
      return const {};
    } on MissingPluginException {
      return const {};
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
    _eventStreamController.close();
  }
}
