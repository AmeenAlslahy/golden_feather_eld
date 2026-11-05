import 'dart:typed_data';
import '../models/parsed_ecm_packet.dart';
import 'eld_packet_parser.dart';

/// SAE J1939 CAN packet parser for heavy-duty commercial vehicles.
///
/// Blocked pending hardware vendor wire format documentation and live Logcat sample.
///
/// Target J1939 PGN specifications (for future implementation once dongle framing is known):
/// - PGN 61444 (0xF004) - Electronic Engine Controller 1 (EEC1) / Engine Speed
/// - PGN 65265 (0xFEF1) - Cruise Control/Vehicle Speed (CCVS) / Wheel-Based Vehicle Speed (Bytes 2-3, 1/256 km/h per bit)
/// - PGN 65248 (0xFEE0) - Vehicle Distance / Total Vehicle Distance (Bytes 1-4, 0.125 km/bit = 5 m/bit)
/// - PGN 65217 (0xFEA1) - High Resolution Vehicle Distance (Bytes 1-4, 5 m/bit = 0.005 km/bit)
/// - PGN 65252 (0xFEE4) - Total Engine Hours (Bytes 1-4, 0.05 hr/bit)
class J1939PacketParser implements EldPacketParser {
  const J1939PacketParser();

  @override
  ParsedEcmPacket parse(Uint8List bytes) {
    // TODO: Implement J1939 CAN frame decoding once physical dongle wire framing
    // (e.g. 29-bit CAN identifier encapsulation, payload delimitation, or ASCII framing)
    // is documented by vendor or captured in live Logcat testing.
    return ParsedEcmPacket.invalid(
      rawData: bytes.isEmpty ? null : bytes.join(','),
      source: EcmSource.j1939,
    );
  }
}

