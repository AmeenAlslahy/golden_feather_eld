import 'dart:typed_data';
import '../models/parsed_ecm_packet.dart';
import 'eld_packet_parser.dart';

/// Geometris (e.g. G7 / OBD Dongle) packet parser stub.
///
/// Blocked pending hardware vendor wire format documentation and live Logcat sample.
class GeometrisPacketParser implements EldPacketParser {
  const GeometrisPacketParser();

  @override
  ParsedEcmPacket parse(Uint8List bytes) {
    // TODO: Implement Geometris proprietary binary/ASCII protocol decoding
    // once official documentation is verified.
    return ParsedEcmPacket.invalid(
      rawData: bytes.isEmpty ? null : bytes.join(','),
      source: EcmSource.geometris,
    );
  }
}

