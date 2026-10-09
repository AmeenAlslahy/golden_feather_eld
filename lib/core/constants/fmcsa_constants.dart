/// FMCSA Regulatory & Technical Constants (49 CFR Part 395).
class FmcsaConstants {
  FmcsaConstants._();

  /// Speed threshold for automatic driving detection: 5 mph (~2.235 m/s)
  /// per 49 CFR § 395.2.
  static const double drivingSpeedThresholdMps = 2.235;

  /// Speed in mph corresponding to the 5 mph threshold.
  static const double drivingSpeedThresholdMph = 5.0;

  /// Inactivity interval before sending telemetry heartbeats (30 seconds).
  static const int telemetryIntervalSeconds = 30;

  /// Stationary time before prompting driver or transitioning to On-Duty (5 minutes / 300s).
  static const int stationaryPromptSeconds = 300;

  /// Maximum consecutive driving hours before 10-hour rest requirement: 11 hours.
  static const int maxDrivingHours = 11;

  /// Maximum duty window duration after coming on duty: 14 hours.
  static const int maxDutyWindowHours = 14;

  /// Required uninterrupted rest period: 10 consecutive hours.
  static const int requiredConsecutiveRestHours = 10;

  /// Mandatory 30-minute rest break after 8 hours of cumulative driving.
  static const int breakRequiredAfterDrivingHours = 8;
  static const int mandatoryBreakDurationMinutes = 30;

  /// Standard cycle limits (60 hours / 7 days or 70 hours / 8 days).
  static const int cycle7DaysLimitHours = 60;
  static const int cycle8DaysLimitHours = 70;
  static const int cycleRestartHours = 34;

  /// Standard number of past days required for roadside inspection data transfer.
  static const int inspectionCycleDays = 8;

  /// Default FMCSA submission email endpoint per 49 CFR § 395 Appendix A.
  static const String fmcsaSubEmail = 'fmcsaeldsub@dot.gov';
}
