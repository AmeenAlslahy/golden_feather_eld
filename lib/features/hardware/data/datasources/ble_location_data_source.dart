import 'dart:async';

import '../../../../core/services/bluetooth_service.dart';
import '../../../../core/utils/logger.dart';
import '../../application/ble_frame_monitor.dart';
import '../../domain/ble_location_parser.dart';

/// Listens to BLE notifications, decodes location payloads and forwards them to
/// the native tracking queue.
///
/// Keeping this in Dart (instead of the native service) has two advantages:
///  - the NMEA/JSON decoder is testable and hot-fixable without an app release,
///  - the same raw frames feed the diagnostics panel used to reverse-engineer
///    vendor-specific protocols (Pacific Track PT30-U today).
class BleLocationDataSource {
  BleLocationDataSource({
    required BluetoothService bluetoothService,
    required Future<void> Function(Map<String, dynamic> location) pushLocation,
    BleFrameMonitor? monitor,
  }) : _bluetoothService = bluetoothService,
       _pushLocation = pushLocation,
       _monitor = monitor ?? BleFrameMonitor.instance;

  final BluetoothService _bluetoothService;
  final Future<void> Function(Map<String, dynamic> location) _pushLocation;
  final BleFrameMonitor _monitor;
  final BleLocationFrameParser _parser = BleLocationFrameParser();

  StreamSubscription<Map<String, dynamic>>? _subscription;
  bool _running = false;

  String? _lastFixKey;
  DateTime? _lastPushAt;

  bool get isRunning => _running;

  void start() {
    if (_running) return;
    _running = true;
    _parser.reset();
    _subscription = _bluetoothService.events.listen(
      _handleEvent,
      onError: (Object error, StackTrace stackTrace) {
        AppLogger.error('BLE location stream error', error, stackTrace);
      },
    );
    _monitor.addFrame(kind: 'info', note: 'BLE location ingestion started');
  }

  void stop() {
    _running = false;
    _subscription?.cancel();
    _subscription = null;
    _parser.reset();
  }

  Future<void> _handleEvent(Map<String, dynamic> event) async {
    final type = event['type'];

    if (type == 'connected') {
      _monitor.addFrame(
        kind: 'connected',
        note: '${event['name'] ?? ''} ${event['macAddress'] ?? ''}'.trim(),
      );
      return;
    }
    if (type == 'disconnected') {
      _monitor.addFrame(
        kind: 'disconnected',
        note: 'status=${event['status'] ?? ''}',
      );
      return;
    }
    if (type == 'services') {
      final services = event['services'];
      _monitor.addFrame(
        kind: 'services',
        note:
            'mtu=${event['mtu']} services=${services is List ? services.length : 0}',
      );
      return;
    }
    if (type != 'data') return;

    final bytes = _extractBytes(event);
    if (bytes.isEmpty) return;

    final hex =
        event['hex'] as String? ??
        bytes
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join()
            .toUpperCase();
    final ascii = event['ascii'] as String? ?? _toAscii(bytes);

    _monitor.addFrame(
      kind: 'data',
      hex: hex,
      ascii: ascii,
      characteristic: event['characteristic'] as String?,
    );

    final fixes = _parser.addBytes(bytes);
    for (final fix in fixes) {
      await _forwardFix(fix);
    }
  }

  List<int> _extractBytes(Map<String, dynamic> event) {
    final values = event['values'];
    if (values is List) {
      return values
          .whereType<num>()
          .map((value) => value.toInt() & 0xFF)
          .toList(growable: false);
    }

    final hex = event['hex'];
    if (hex is String && hex.trim().isNotEmpty) {
      final clean = hex.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
      if (clean.length.isEven) {
        return [
          for (var i = 0; i < clean.length; i += 2)
            int.parse(clean.substring(i, i + 2), radix: 16),
        ];
      }
    }

    final raw = event['data'];
    if (raw is String && raw.trim().isNotEmpty) {
      return bytesFromCommaSeparated(raw);
    }
    return const [];
  }

  Future<void> _forwardFix(BleLocationFix fix) async {
    if (!fix.isValid) return;

    // Some gateways repeat the same NMEA sentence at high rate. Do not queue the
    // same fix twice (same second + same coordinates).
    final key =
        '${fix.timestamp.millisecondsSinceEpoch ~/ 1000}:${fix.latitude.toStringAsFixed(6)}:${fix.longitude.toStringAsFixed(6)}';
    if (key == _lastFixKey) return;

    // Defensive rate limit: at most one fix per second.
    final now = DateTime.now();
    if (_lastPushAt != null &&
        now.difference(_lastPushAt!).inMilliseconds < 900) {
      return;
    }

    _lastFixKey = key;
    _lastPushAt = now;

    try {
      await _pushLocation(fix.toNativeMap());
      _monitor.addFrame(
        kind: 'fix',
        note:
            '${fix.latitude.toStringAsFixed(5)},${fix.longitude.toStringAsFixed(5)} '
            '${fix.speedMps.toStringAsFixed(2)} m/s (${fix.protocol})',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Failed to push BLE location to native queue',
        e,
        stackTrace,
      );
      _monitor.addFrame(kind: 'error', note: 'push failed: $e');
    }
  }

  String _toAscii(List<int> bytes) {
    return bytes
        .map(
          (byte) => byte >= 32 && byte <= 126 ? String.fromCharCode(byte) : '.',
        )
        .join();
  }
}
