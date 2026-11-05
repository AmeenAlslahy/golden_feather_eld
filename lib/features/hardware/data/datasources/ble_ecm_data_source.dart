import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/bluetooth_service.dart';
import '../../../../core/utils/logger.dart';
import '../../../sync/domain/entities/duty_event_record.dart'; // ignore_architecture
import '../../../sync/domain/repositories/duty_event_journal.dart'; // ignore_architecture
import '../../../tracking/domain/usecases/tracking_event_processor.dart'; // ignore_architecture
import '../../domain/models/parsed_ecm_packet.dart';
import '../../domain/parsers/composite_eld_parser.dart';
import '../../domain/parsers/eld_packet_parser.dart';

/// Data source listening to native BLE events and parsing incoming ECM bytes.
class BleEcmDataSource {
  final BluetoothService _bluetoothService;
  final EldPacketParser _parser;
  final TrackingEventProcessor? _trackingEventProcessor;
  final DutyEventJournal? _journal;
  final bool Function() _isFeatureEnabled;

  StreamSubscription<Map<String, dynamic>>? _bleSubscription;
  final StreamController<ParsedEcmPacket> _parsedPacketsController =
      StreamController<ParsedEcmPacket>.broadcast();

  BleEcmDataSource({
    required BluetoothService bluetoothService,
    EldPacketParser? parser,
    TrackingEventProcessor? trackingEventProcessor,
    DutyEventJournal? journal,
    bool Function()? isFeatureEnabled,
  })  : _bluetoothService = bluetoothService,
        _parser = parser ?? CompositeEldParser(),
        _trackingEventProcessor = trackingEventProcessor,
        _journal = journal,
        _isFeatureEnabled =
            isFeatureEnabled ?? (() => AppConstants.enableBleEcmIngestion);

  /// Stream of all parsed ECM packets (both valid and invalid).
  Stream<ParsedEcmPacket> get parsedPackets => _parsedPacketsController.stream;

  /// Starts listening to native Bluetooth events.
  void start() {
    _bleSubscription?.cancel();
    _bleSubscription = _bluetoothService.events.listen(
      _handleBleEvent,
      onError: (error, stackTrace) {
        AppLogger.error('BLE event stream error in BleEcmDataSource', error, stackTrace);
      },
    );
  }

  /// Converts a comma-separated byte string (e.g. "5,65,13") into [Uint8List].
  static Uint8List parseDataStringToBytes(String rawString) {
    if (rawString.trim().isEmpty) {
      return Uint8List(0);
    }

    final tokens = rawString.split(',');
    final bytes = <int>[];

    for (final token in tokens) {
      final trimmed = token.trim();
      if (trimmed.isEmpty) continue;
      final parsed = int.tryParse(trimmed);
      if (parsed != null) {
        bytes.add(parsed & 0xFF);
      }
    }

    return Uint8List.fromList(bytes);
  }

  void _handleBleEvent(Map<String, dynamic> event) async {
    // 1. Strict Feature Flag Check MUST precede any event handling or parsing.
    if (!_isFeatureEnabled()) {
      return;
    }

    // 2. Only process events with type == 'data'
    if (event['type'] != 'data') {
      return;
    }

    final rawData = event['data'];
    if (rawData is! String || rawData.trim().isEmpty) {
      return;
    }

    // 3. Parse and protect against exceptions with try/catch
    try {
      final bytes = parseDataStringToBytes(rawData);
      if (bytes.isEmpty) {
        return;
      }

      final packet = _parser.parse(bytes);
      _parsedPacketsController.add(packet);

      // 4. Feed TrackingEventProcessor ONLY when confirmed from ECM
      if (packet.isValid && packet.fromEcm) {
        _trackingEventProcessor?.processEcmPacket(
          speedMps: packet.speedMps,
          odometerMiles: packet.odometerMiles,
          engineHours: packet.engineHours,
          fromEcm: packet.fromEcm,
          timestamp: packet.timestamp,
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error('BLE ECM packet parsing failed', e, stackTrace);
      await _recordParseError(rawData, e.toString());
    }
  }

  /// Records a parse error diagnostic event into the append-only journal.
  Future<void> _recordParseError(String rawString, String errorMessage) async {
    if (_journal == null) return;

    try {
      final payloadMap = {
        'error': errorMessage,
        'rawBase64': base64Encode(utf8.encode(rawString)),
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      };

      final record = DutyEventRecord(
        eventId: 'err_ble_${DateTime.now().microsecondsSinceEpoch}',
        ownerDriverId: null,
        source: DutyEventSource.ecm,
        status: 'PARSE_ERROR',
        eventTimeUtc: DateTime.now().toUtc(),
        receivedAtUtc: DateTime.now().toUtc(),
        timeSource: DutyTimeSource.device,
        timeConfidence: DutyTimeConfidence.untrusted,
        monotonicMs: 0,
        payload: payloadMap,
        syncState: DutyEventSyncState.localOnly,
        createdAt: DateTime.now().toUtc(),
      );

      await _journal.append(record);
    } catch (e, stackTrace) {
      AppLogger.error('Failed to log parse_error to journal', e, stackTrace);
    }
  }

  /// Disposes active subscriptions and controllers.
  void dispose() {
    _bleSubscription?.cancel();
    _bleSubscription = null;
    _parsedPacketsController.close();
  }
}
