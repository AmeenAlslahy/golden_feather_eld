/// Duty status codes per FMCSA §395.3.
///
/// Wire values (e.g. `"DRIVING"`) come from the backend.
/// Short codes (e.g. `"D"`) are used in compact UI displays.
library;

import '../../../core/utils/logger.dart';

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
  /// Unknown values fall back to [offDuty] — but a silent fallback is a
  /// legal landmine (a misspelt `DRIVING` would be counted as rest), so the
  /// mismatch is always logged before the fallback is applied.
  static DutyStatusCode fromWire(String? value) {
    final upper = value?.toUpperCase() ?? '';
    for (final c in values) {
      if (c.wire == upper) return c;
    }
    AppLogger.warning(
        'DutyStatusCode.fromWire: unknown wire value "$value" — falling back to offDuty');
    return DutyStatusCode.offDuty;
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
  /// Per FMCSA: driving and on-duty (not driving) and yard move count as
  /// on-duty. Personal conveyance is off-duty time: it does not accumulate
  /// against the 14-hour on-duty window or the 11-hour driving limit (it does
  /// not stop those clocks — the shift window keeps running).
  bool get countsAsOnDuty => switch (this) {
        DutyStatusCode.offDuty => false,
        DutyStatusCode.sleeperBerth => false,
        DutyStatusCode.driving => true,
        DutyStatusCode.onDutyNotDriving => true,
        DutyStatusCode.yardMove => true,
        DutyStatusCode.personalConveyance => false,
      };
}
