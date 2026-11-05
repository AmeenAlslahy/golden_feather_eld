import 'package:equatable/equatable.dart';

/// The hardware/protocol source from which the ECM packet originated.
enum EcmSource {
  j1939,
  pt30,
  j1708,
  geometris,
  unknown,
}

/// Immutable domain model representing a parsed vehicle ECM telemetry packet.
class ParsedEcmPacket extends Equatable {
  /// Vehicle speed in meters per second (m/s).
  final double speedMps;

  /// Vehicle odometer reading in miles, if available from ECM bus.
  final double? odometerMiles;

  /// Total engine operating hours, if available from ECM bus.
  final double? engineHours;

  /// True ONLY when the reading is confirmed to originate from the vehicle ECM.
  final bool fromEcm;

  /// True if the packet was successfully parsed and validated (checksum/PGN/structure).
  final bool isValid;

  /// Source hardware/protocol that decoded this packet.
  final EcmSource source;

  /// Timestamp when this packet was received / decoded.
  final DateTime timestamp;

  /// Optional raw representation or diagnostic payload for auditing/logging.
  final String? rawData;

  const ParsedEcmPacket({
    required this.speedMps,
    this.odometerMiles,
    this.engineHours,
    required this.fromEcm,
    required this.isValid,
    required this.source,
    required this.timestamp,
    this.rawData,
  });

  /// Factory constructor for invalid, unparseable, or stubbed packets.
  factory ParsedEcmPacket.invalid({
    String? rawData,
    EcmSource source = EcmSource.unknown,
    DateTime? timestamp,
  }) {
    return ParsedEcmPacket(
      speedMps: 0.0,
      odometerMiles: null,
      engineHours: null,
      fromEcm: false,
      isValid: false,
      source: source,
      timestamp: timestamp ?? DateTime.now().toUtc(),
      rawData: rawData,
    );
  }

  @override
  List<Object?> get props => [
        speedMps,
        odometerMiles,
        engineHours,
        fromEcm,
        isValid,
        source,
        timestamp,
        rawData,
      ];
}

