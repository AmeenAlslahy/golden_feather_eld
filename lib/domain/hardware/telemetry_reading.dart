import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/value_objects.dart';

part 'telemetry_reading.freezed.dart';

/// A single ECM telemetry reading from the vehicle's engine computer.
///
/// **Why this exists:**
/// - FMCSA §4.4.1.2 requires odometer + engine hours to come from the
///   vehicle, not be estimated by the app.
/// - These fields feed the ELD submission endpoint
///   `POST /eld/hardware/telemetry`.
///
/// **Optional fields:**
/// - [odometerMiles], [engineHours], [rpm], [engineOn] are nullable.
///   When the vehicle does not provide them, they are omitted from the
///   backend request — never fabricated.
@freezed
abstract class TelemetryReading with _$TelemetryReading {
  const factory TelemetryReading({
    required DriverId driverId,

    /// Vehicle speed in **meters per second** (canonical).
    ///
    /// Mappers convert to the backend's wire unit.
    required double speedMps,

    /// Engine RPM (raw value from ECM).
    double? rpm,

    /// Cumulative odometer reading in **miles**.
    ///
    /// `null` when the vehicle does not report it.
    double? odometerMiles,

    /// Cumulative engine hours since vehicle manufacture.
    ///
    /// `null` when the vehicle does not report it.
    double? engineHours,

    /// Whether the engine is currently running.
    ///
    /// `null` when unknown.
    bool? engineOn,
  }) = _TelemetryReading;
}
