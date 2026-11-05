import 'dart:typed_data';
import '../models/parsed_ecm_packet.dart';
import 'eld_packet_parser.dart';

/// SAE J1708/J1587 legacy vehicle bus packet parser stub.
///
/// Blocked pending hardware vendor wire format documentation and live Logcat sample.
class J1708PacketParser implements EldPacketParser {
  const J1708PacketParser();

  @override
  ParsedEcmPacket parse(Uint8List bytes) {
    // TODO: Implement SAE J1708/J1587 MID/PID decoding once legacy hardware
    // framing and adapter encapsulation are documented.
    return ParsedEcmPacket.invalid(
      rawData: bytes.isEmpty ? null : bytes.join(','),
      source: EcmSource.j1708,
    );
  }
}

