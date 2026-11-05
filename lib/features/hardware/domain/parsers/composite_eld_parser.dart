import 'dart:typed_data';
import '../models/parsed_ecm_packet.dart';
import 'eld_packet_parser.dart';
import 'geometris_packet_parser.dart';
import 'j1708_packet_parser.dart';
import 'j1939_packet_parser.dart';
import 'pacific_track_packet_parser.dart';

/// Composite parser using Strategy Pattern.
/// Iterates through candidate parsers and returns the first valid [ParsedEcmPacket].
class CompositeEldParser implements EldPacketParser {
  final List<EldPacketParser> _parsers;

  CompositeEldParser({List<EldPacketParser>? parsers})
      : _parsers = parsers ??
            const [
              J1939PacketParser(),
              PacificTrackPacketParser(),
              J1708PacketParser(),
              GeometrisPacketParser(),
            ];

  List<EldPacketParser> get parsers => List.unmodifiable(_parsers);

  @override
  ParsedEcmPacket parse(Uint8List bytes) {
    if (bytes.isEmpty) {
      return ParsedEcmPacket.invalid();
    }

    for (final parser in _parsers) {
      try {
        final result = parser.parse(bytes);
        if (result.isValid) {
          return result;
        }
      } catch (_) {
        // Individual parser errors are contained and do not break the chain.
      }
    }

    return ParsedEcmPacket.invalid(
      rawData: bytes.join(','),
      source: EcmSource.unknown,
    );
  }
}

