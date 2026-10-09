/// Duty status codes per FMCSA §395.3.
///
/// Wire values (e.g. `"DRIVING"`) come from the backend.
/// Short codes (e.g. `"D"`) are used in compact UI displays.
library;

import 'package:flutter/widgets.dart';
import '../../../core/utils/logger.dart';

enum DutyStatusCode {
  offDuty('OFF_DUTY', 'OFF', 'off_duty'),
  sleeperBerth('SLEEPER', 'SB', 'sleeper_berth'),
  driving('DRIVING', 'D', 'driving'),
  onDutyNotDriving('ON_DUTY', 'ON', 'on_duty'),
  yardMove('YARD_MOVE', 'YM', 'yard_move'),
  personalConveyance('PERSONAL_CONVEYANCE', 'PC', 'personal_use');

  const DutyStatusCode(this.wire, this.shortCode, this.engineCode);

  /// The value sent by the backend (uppercase snake_case).
  final String wire;

  /// Short code for compact UI (e.g. log graphs).
  final String shortCode;

  /// Internal engine status string used by DutyStatusTracker.
  final String engineCode;

  /// Parses from any string format (wire, short, or engine code).
  static DutyStatusCode fromAny(String? value) {
    if (value == null || value.isEmpty) return DutyStatusCode.offDuty;
    final upper = value.toUpperCase();
    final lower = value.toLowerCase();

    for (final c in values) {
      if (c.wire == upper || c.shortCode == upper || c.engineCode == lower) {
        return c;
      }
    }

    // Aliases for loosely typed systems
    if (upper == 'SLEEPER') return DutyStatusCode.sleeperBerth;
    if (lower == 'personal_conveyance') return DutyStatusCode.personalConveyance;

    AppLogger.warning('DutyStatusCode.fromAny: unknown value "$value" — falling back to offDuty');
    return DutyStatusCode.offDuty;
  }

  /// Parses from the backend wire value.
  static DutyStatusCode fromWire(String? value) => fromAny(value);

  /// Parses from a short code.
  static DutyStatusCode? fromShortCode(String? code) {
    final c = fromAny(code);
    return c == DutyStatusCode.offDuty && code?.toUpperCase() != 'OFF' ? null : c;
  }

  /// FMCSA Duty Status Code (1=OFF, 2=SB, 3=D, 4=ON)
  String toFmcsaCode() {
    switch (this) {
      case DutyStatusCode.offDuty:
      case DutyStatusCode.personalConveyance:
        return '1';
      case DutyStatusCode.sleeperBerth:
        return '2';
      case DutyStatusCode.driving:
        return '3';
      case DutyStatusCode.onDutyNotDriving:
      case DutyStatusCode.yardMove:
        return '4';
    }
  }

  /// UI Color representation mapping
  Color get displayColor {
    switch (this) {
      case DutyStatusCode.onDutyNotDriving:
      case DutyStatusCode.yardMove:
      case DutyStatusCode.personalConveyance:
        return const Color(0xFFFBBF24); // AppColors.primaryGold
      case DutyStatusCode.offDuty:
        return const Color(0xFF6B7280); // AppColors.textSecondary
      case DutyStatusCode.driving:
        return const Color(0xFF10B981); // AppColors.successGreen
      case DutyStatusCode.sleeperBerth:
        return const Color(0xFFF59E0B); // AppColors.warningYellow
    }
  }

  /// Whether this status counts as "on-duty" for HOS purposes.
  bool get countsAsOnDuty => switch (this) {
        DutyStatusCode.offDuty => false,
        DutyStatusCode.sleeperBerth => false,
        DutyStatusCode.driving => true,
        DutyStatusCode.onDutyNotDriving => true,
        DutyStatusCode.yardMove => true,
        DutyStatusCode.personalConveyance => false,
      };
}
