import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/core/services/bluetooth_service.dart';
import 'package:golden_feather_eld/features/hardware/data/datasources/ble_ecm_data_source.dart';
import 'package:golden_feather_eld/features/hardware/domain/models/parsed_ecm_packet.dart';
import 'package:golden_feather_eld/features/hardware/domain/parsers/eld_packet_parser.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/duty_event_record.dart';
import 'package:golden_feather_eld/features/sync/domain/entities/pending_event.dart';
import 'package:golden_feather_eld/features/sync/domain/repositories/duty_event_journal.dart';
import 'package:golden_feather_eld/features/tracking/domain/usecases/tracking_event_processor.dart';

class _FakeBluetoothService implements BluetoothService {
  final StreamController<Map<String, dynamic>> _eventsController =
      StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get events => _eventsController.stream;

  void emitEvent(Map<String, dynamic> event) {
    _eventsController.add(event);
  }

  @override
  Future<void> connect(
    String macAddress, {
    Duration timeout = const Duration(seconds: 10),
  }) async {}

  @override
  Future<bool> executeConnect(String macAddress) async => true;

  @override
  Future<void> setSessionState({
    required bool isActive,
    required bool isManualMode,
    bool clearMac = false,
  }) async {}

  @override
  Future<void> disconnect() async {}

  @override
  void dispose() {
    _eventsController.close();
  }

  @override
  Future<bool> isConnected() async => true;

  @override
  Future<void> startScan() async {}

  @override
  Future<void> stopScan() async {}

  @override
  Stream<Map<String, dynamic>> get discoveredDevices =>
      events.where((event) => event['type'] == 'deviceFound');

  @override
  Stream<Map<String, dynamic>> get incomingData =>
      events.where((event) => event['type'] == 'data');

  @override
  Future<Map<String, dynamic>> readDeviceInfo() async => const {};

  @override
  Future<void> sendCommand({
    String? hex,
    String? text,
    String? characteristic,
    String? writeType,
  }) async {}

  @override
  Future<Map<String, dynamic>> getLastDevice() async => const {};
}

class _SpyParser implements EldPacketParser {
  int parseCallCount = 0;
  Uint8List? lastParsedBytes;
  ParsedEcmPacket packetToReturn;

  _SpyParser({ParsedEcmPacket? returnPacket})
      : packetToReturn = returnPacket ?? ParsedEcmPacket.invalid();

  @override
  ParsedEcmPacket parse(Uint8List bytes) {
    parseCallCount++;
    lastParsedBytes = bytes;
    return packetToReturn;
  }
}

class _ThrowingParser implements EldPacketParser {
  @override
  ParsedEcmPacket parse(Uint8List bytes) {
    throw const FormatException('Simulated crash in parser');
  }
}

class _SpyJournal implements DutyEventJournal {
  final List<DutyEventRecord> appendedRecords = [];

  @override
  Future<void> append(DutyEventRecord record, {PendingEvent? syncEvent}) async {
    appendedRecords.add(record);
  }

  @override
  Future<DutyEventJournalLoad> load({
    required int ownerDriverId,
    int limit = 1000,
  }) async {
    return DutyEventJournalLoad(records: appendedRecords, corruptedRows: 0);
  }
}

void main() {
  group('BleEcmDataSource - Byte parsing helper', () {
    test('converts standard comma-separated string to Uint8List', () {
      final bytes = BleEcmDataSource.parseDataStringToBytes('5,65,13');
      expect(bytes, equals(Uint8List.fromList([5, 65, 13])));
    });

    test('handles empty or whitespace strings safely', () {
      expect(BleEcmDataSource.parseDataStringToBytes(''), isEmpty);
      expect(BleEcmDataSource.parseDataStringToBytes('   '), isEmpty);
      expect(BleEcmDataSource.parseDataStringToBytes(' , , '), isEmpty);
    });

    test('ignores non-numeric tokens and masks to 0-255', () {
      // 300 & 0xFF = 44, -1 & 0xFF = 255
      final bytes = BleEcmDataSource.parseDataStringToBytes('5,bad_token,13,-1,300');
      expect(bytes, equals(Uint8List.fromList([5, 13, 255, 44])));
    });
  });

  group('BleEcmDataSource - Ingestion flow & Feature flag', () {
    late _FakeBluetoothService fakeBluetooth;
    late _SpyParser spyParser;
    late _SpyJournal spyJournal;

    setUp(() {
      fakeBluetooth = _FakeBluetoothService();
      spyParser = _SpyParser();
      spyJournal = _SpyJournal();
    });

    tearDown(() {
      fakeBluetooth.dispose();
    });

    test('when feature flag is false, incoming BLE data events are ignored', () async {
      final dataSource = BleEcmDataSource(
        bluetoothService: fakeBluetooth,
        parser: spyParser,
        journal: spyJournal,
        isFeatureEnabled: () => false, // Feature flag DISABLED
      );
      dataSource.start();

      fakeBluetooth.emitEvent({
        'type': 'data',
        'data': '5,65,13',
      });

      await pumpEventQueue();

      expect(spyParser.parseCallCount, equals(0));
      dataSource.dispose();
    });

    test('when feature flag is true, valid data events invoke parser', () async {
      final dataSource = BleEcmDataSource(
        bluetoothService: fakeBluetooth,
        parser: spyParser,
        journal: spyJournal,
        isFeatureEnabled: () => true, // Feature flag ENABLED
      );
      dataSource.start();

      fakeBluetooth.emitEvent({
        'type': 'data',
        'data': '5,65,13',
      });

      await pumpEventQueue();

      expect(spyParser.parseCallCount, equals(1));
      expect(spyParser.lastParsedBytes, equals(Uint8List.fromList([5, 65, 13])));
      dataSource.dispose();
    });

    test('events with type != "data" are filtered out', () async {
      final dataSource = BleEcmDataSource(
        bluetoothService: fakeBluetooth,
        parser: spyParser,
        isFeatureEnabled: () => true,
      );
      dataSource.start();

      fakeBluetooth.emitEvent({
        'type': 'connection_status',
        'status': 'connected',
      });

      await pumpEventQueue();

      expect(spyParser.parseCallCount, equals(0));
      dataSource.dispose();
    });

    test('try/catch contains parser exceptions and writes parse_error to journal in Base64', () async {
      final dataSource = BleEcmDataSource(
        bluetoothService: fakeBluetooth,
        parser: _ThrowingParser(),
        journal: spyJournal,
        isFeatureEnabled: () => true,
      );
      dataSource.start();

      fakeBluetooth.emitEvent({
        'type': 'data',
        'data': '10,20,30',
      });

      await pumpEventQueue();

      // Ensure error was safely recorded to journal without application crash
      expect(spyJournal.appendedRecords.length, equals(1));
      final record = spyJournal.appendedRecords.first;
      expect(record.status, equals('PARSE_ERROR'));
      expect(record.source, equals(DutyEventSource.ecm));

      final payloadMap = record.payload;
      expect(payloadMap['rawBase64'], equals(base64Encode(utf8.encode('10,20,30'))));
      expect(payloadMap['error'], contains('Simulated crash in parser'));

      dataSource.dispose();
    });

    test('feeds TrackingEventProcessor when packet is valid and fromEcm == true', () async {
      final expectedPacket = ParsedEcmPacket(
        speedMps: 20.0,
        odometerMiles: 10050.0,
        engineHours: 1200.0,
        fromEcm: true,
        isValid: true,
        source: EcmSource.j1939,
        timestamp: DateTime.utc(2026, 11, 5, 12, 0, 0),
      );

      final validParser = _SpyParser(returnPacket: expectedPacket);
      final processor = TrackingEventProcessor();

      final dataSource = BleEcmDataSource(
        bluetoothService: fakeBluetooth,
        parser: validParser,
        trackingEventProcessor: processor,
        isFeatureEnabled: () => true,
      );
      dataSource.start();

      final eldEventsFuture = expectLater(
        processor.eldEventsStream,
        emits(
          predicate((dynamic e) {
            return e.fromEcm == true &&
                (e.speedMph - (20.0 * 2.23694)).abs() < 0.01 &&
                e.odometerMiles == 10050.0 &&
                e.engineHours == 1200.0;
          }),
        ),
      );

      fakeBluetooth.emitEvent({
        'type': 'data',
        'data': '5,65,13',
      });

      await eldEventsFuture;

      dataSource.dispose();
      processor.dispose();
    });

    test('does NOT feed TrackingEventProcessor when packet is invalid or fromEcm == false', () async {
      final invalidPacket = ParsedEcmPacket.invalid();
      final invalidParser = _SpyParser(returnPacket: invalidPacket);
      final processor = TrackingEventProcessor();

      bool receivedEvent = false;
      final sub = processor.eldEventsStream.listen((_) {
        receivedEvent = true;
      });

      final dataSource = BleEcmDataSource(
        bluetoothService: fakeBluetooth,
        parser: invalidParser,
        trackingEventProcessor: processor,
        isFeatureEnabled: () => true,
      );
      dataSource.start();

      fakeBluetooth.emitEvent({
        'type': 'data',
        'data': '5,65,13',
      });

      await pumpEventQueue();

      expect(receivedEvent, isFalse);

      await sub.cancel();
      dataSource.dispose();
      processor.dispose();
    });
  });
}
