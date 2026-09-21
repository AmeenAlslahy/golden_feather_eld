/// Duty status codes per FMCSA §395.3.
///
/// Wire values (e.g. `"DRIVING"`) come from the backend.
/// Short codes (e.g. `"D"`) are used in compact UI displays.
library;

enum DutyStatusCode {
  offDuty('OFF_DUTY', 'OFF'),
  sleeperBerth('SLEEPER', 'SB'),
  driving('DRIVING', 'D'),
  onDutyNotDriving('ON_DUTY', 'ON'),
  yardMove('YARD_MOVE', 'YM'),
  personalConveyance('PERSONAL_CONVEYANCE', 'PC');

  const DutyStatusCode(this.wire, this.shortCode);

  /// The value sent by the backend (uppercase snake_case).
  final String wire;

  /// Short code for compact UI (e.g. log graphs).
  final String shortCode;

  /// Parses from the backend wire value.
  ///
  /// Unknown values fall back to [offDuty] — the safest default.
  static DutyStatusCode fromWire(String? value) {
    final upper = value?.toUpperCase() ?? '';
    return DutyStatusCode.values.firstWhere(
      (c) => c.wire == upper,
      orElse: () => DutyStatusCode.offDuty,
    );
  }

  /// Parses from a short code.
  ///
  /// Returns `null` if no match — caller decides the fallback.
  static DutyStatusCode? fromShortCode(String? code) {
    final upper = code?.toUpperCase() ?? '';
    for (final c in DutyStatusCode.values) {
      if (c.shortCode == upper) return c;
    }
    return null;
  }

  /// Whether this status counts as "on-duty" for HOS purposes.
  ///
  /// Per FMCSA: driving, on-duty, yard move, and personal conveyance
  /// all count toward shift limits.
  bool get countsAsOnDuty => switch (this) {
        DutyStatusCode.offDuty => false,
        DutyStatusCode.sleeperBerth => false,
        DutyStatusCode.driving => true,
        DutyStatusCode.onDutyNotDriving => true,
        DutyStatusCode.yardMove => true,
        DutyStatusCode.personalConveyance => true,
      };
}
