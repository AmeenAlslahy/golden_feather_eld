import '../../../../domain/hardware/telemetry_reading.dart';

/// Maps [TelemetryReading] to the ELD backend wire format.
///
/// **Unit note:**
/// The backend accepts `speed` in MPH (US ELD context). We convert
/// from the domain's canonical m/s.
class HardwareMapper {
  const HardwareMapper._();

  /// Converts **meters per second** to **miles per hour**.
  static const double _mpsToMph = 2.23694;

  static Map<String, dynamic> telemetryToJson(TelemetryReading reading) {
    return {
      'driverId': reading.driverId.value,
      'speed': reading.speedMps * _mpsToMph,
      if (reading.rpm != null) 'rpm': reading.rpm,
      if (reading.odometerMiles != null) 'odometer': reading.odometerMiles,
      if (reading.engineHours != null) 'engineHours': reading.engineHours,
      if (reading.engineOn != null) 'engineOn': reading.engineOn,
    };
  }
}
