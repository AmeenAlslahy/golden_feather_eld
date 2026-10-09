import '../../../../domain/hardware/telemetry_reading.dart';

/// Maps [TelemetryReading] to the ELD backend wire format.
///
/// **Unit note:**
/// The backend accepts `speed` in KMH and odometer in KM (International ELD context).
/// We convert from the domain's canonical m/s and miles.
class HardwareMapper {
  const HardwareMapper._();

  /// Converts **meters per second** to **kilometers per hour**.
  static const double _mpsToKmh = 3.6;

  /// Converts **miles** to **kilometers**.
  static const double _milesToKm = 1.60934;

  static Map<String, dynamic> telemetryToJson(TelemetryReading reading) {
    return {
      'driverId': reading.driverId.value,
      'speed': reading.speedMps * _mpsToKmh,
      if (reading.rpm != null) 'rpm': reading.rpm,
      if (reading.odometerMiles != null) 'odometer': reading.odometerMiles! * _milesToKm,
      if (reading.engineHours != null) 'engineHours': reading.engineHours,
      if (reading.engineOn != null) 'engineOn': reading.engineOn,
    };
  }
}
