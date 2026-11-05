import 'dart:typed_data';
import '../models/parsed_ecm_packet.dart';

/// Abstract contract for parsing raw byte frames received from an ELD BLE adapter.
abstract interface class EldPacketParser {
  /// Parses raw byte stream/frame into a strongly typed [ParsedEcmPacket].
  ///
  /// Implementations MUST return [ParsedEcmPacket.invalid()] rather than throwing
  /// exceptions when encountering unrecognized or malformed bytes.
  ParsedEcmPacket parse(Uint8List bytes);
}

