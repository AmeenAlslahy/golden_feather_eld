import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:golden_feather_eld/features/hardware/domain/models/parsed_ecm_packet.dart';
import 'package:golden_feather_eld/features/hardware/domain/parsers/composite_eld_parser.dart';
import 'package:golden_feather_eld/features/hardware/domain/parsers/eld_packet_parser.dart';
import 'package:golden_feather_eld/features/hardware/domain/parsers/geometris_packet_parser.dart';
import 'package:golden_feather_eld/features/hardware/domain/parsers/j1708_packet_parser.dart';
import 'package:golden_feather_eld/features/hardware/domain/parsers/j1939_packet_parser.dart';
import 'package:golden_feather_eld/features/hardware/domain/parsers/pacific_track_packet_parser.dart';

class _FakeValidParser implements EldPacketParser {
  final ParsedEcmPacket validPacket;
  _FakeValidParser(this.validPacket);

  @override
  ParsedEcmPacket parse(Uint8List bytes) => validPacket;
}

class _ThrowingParser implements EldPacketParser {
  @override
  ParsedEcmPacket parse(Uint8List bytes) => throw const FormatException('Corrupted frame');
}

void main() {
  group('ELD Hardware Parsers (Stubs)', () {
    final sampleBytes = Uint8List.fromList([5, 65, 13, 255]);

    test('J1939PacketParser returns invalid packet with source j1939', () {
      const parser = J1939PacketParser();
      final packet = parser.parse(sampleBytes);

      expect(packet.isValid, isFalse);
      expect(packet.fromEcm, isFalse);
      expect(packet.source, EcmSource.j1939);
      expect(packet.speedMps, 0.0);
      expect(packet.rawData, '5,65,13,255');
    });

    test('PacificTrackPacketParser returns invalid packet with source pt30', () {
      const parser = PacificTrackPacketParser();
      final packet = parser.parse(sampleBytes);

      expect(packet.isValid, isFalse);
      expect(packet.fromEcm, isFalse);
      expect(packet.source, EcmSource.pt30);
      expect(packet.rawData, '5,65,13,255');
    });

    test('J1708PacketParser returns invalid packet with source j1708', () {
      const parser = J1708PacketParser();
      final packet = parser.parse(sampleBytes);

      expect(packet.isValid, isFalse);
      expect(packet.fromEcm, isFalse);
      expect(packet.source, EcmSource.j1708);
      expect(packet.rawData, '5,65,13,255');
    });

    test('GeometrisPacketParser returns invalid packet with source geometris', () {
      const parser = GeometrisPacketParser();
      final packet = parser.parse(sampleBytes);

      expect(packet.isValid, isFalse);
      expect(packet.fromEcm, isFalse);
      expect(packet.source, EcmSource.geometris);
      expect(packet.rawData, '5,65,13,255');
    });
  });

  group('CompositeEldParser', () {
    final sampleBytes = Uint8List.fromList([1, 2, 3]);

    test('returns invalid packet when all registered stubs return invalid', () {
      final composite = CompositeEldParser();
      final result = composite.parse(sampleBytes);

      expect(result.isValid, isFalse);
      expect(result.fromEcm, isFalse);
      expect(result.source, EcmSource.unknown);
    });

    test('returns invalid packet immediately on empty input bytes', () {
      final composite = CompositeEldParser();
      final result = composite.parse(Uint8List(0));

      expect(result.isValid, isFalse);
      expect(result.fromEcm, isFalse);
    });

    test('returns the first valid packet in the strategy chain', () {
      final expectedPacket = ParsedEcmPacket(
        speedMps: 15.5,
        odometerMiles: 125430.2,
        engineHours: 4210.5,
        fromEcm: true,
        isValid: true,
        source: EcmSource.j1939,
        timestamp: DateTime.utc(2026, 11, 5),
      );

      final composite = CompositeEldParser(parsers: [
        const PacificTrackPacketParser(), // invalid stub
        _FakeValidParser(expectedPacket), // valid candidate
        const GeometrisPacketParser(), // should not be reached
      ]);

      final result = composite.parse(sampleBytes);
      expect(result.isValid, isTrue);
      expect(result.fromEcm, isTrue);
      expect(result.speedMps, 15.5);
      expect(result.odometerMiles, 125430.2);
      expect(result.engineHours, 4210.5);
      expect(result.source, EcmSource.j1939);
    });

    test('contains throwing parser errors and continues to next parser', () {
      final expectedPacket = ParsedEcmPacket(
        speedMps: 10.0,
        fromEcm: true,
        isValid: true,
        source: EcmSource.pt30,
        timestamp: DateTime.utc(2026, 11, 5),
      );

      final composite = CompositeEldParser(parsers: [
        _ThrowingParser(),
        _FakeValidParser(expectedPacket),
      ]);

      final result = composite.parse(sampleBytes);
      expect(result.isValid, isTrue);
      expect(result.source, EcmSource.pt30);
    });
  });
}
