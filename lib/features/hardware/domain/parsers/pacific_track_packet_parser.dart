import 'dart:typed_data';
import '../models/parsed_ecm_packet.dart';
import 'eld_packet_parser.dart';

/// Pacific Track (PT30) packet parser stub.
///
/// Blocked pending hardware vendor wire format documentation and live Logcat sample.
class PacificTrackPacketParser implements EldPacketParser {
  const PacificTrackPacketParser();

  @override
  ParsedEcmPacket parse(Uint8List bytes) {
    // TODO: Implement PT30 proprietary frame decoding once official wire protocol
    // specification is provided or verified via live hardware capture.
    return ParsedEcmPacket.invalid(
      rawData: bytes.isEmpty ? null : bytes.join(','),
      source: EcmSource.pt30,
    );
  }
}

