import 'package:freezed_annotation/freezed_annotation.dart';

import '../shared/value_objects.dart';
import 'duty_status_code.dart';

part 'status_dashboard.freezed.dart';

// =============================================================================
// Top-level aggregate
// =============================================================================

/// Complete status dashboard returned by `GET /eld/status`.
///
/// This is the **main screen** of the driver app.
@freezed
abstract class StatusDashboard with _$StatusDashboard {
  const factory StatusDashboard({
    required DriverRef driver,
    required OperationalAlerts operationalAlerts,
    required DutyStatusCode currentDutyStatus,
    required RemainingCircle remainingCircle,
    required HosIndicators hosIndicators,
    required RegulatoryConstraints regulatoryConstraints,
  }) = _StatusDashboard;
}

// =============================================================================
// Driver
// =============================================================================

/// Minimal driver info shown at the top of the dashboard.
@freezed
abstract class DriverRef with _$DriverRef {
  const factory DriverRef({
    required DriverId id,
    required String name,
    required String displayText,
  }) = _DriverRef;
}

// =============================================================================
// Operational alerts
// =============================================================================

/// Connection and device status indicators.
@freezed
abstract class OperationalAlerts with _$OperationalAlerts {
  const factory OperationalAlerts({
    required bool toolIcon,
    required bool warningTriangleIcon,
    required ConnectionStatus connectionStatus,
  }) = _OperationalAlerts;
}

enum ConnectionStatus {
  ok('OK'),
  warning('WARNING'),
  disconnected('DISCONNECTED'),
  unknown('UNKNOWN');

  const ConnectionStatus(this.wire);
  final String wire;

  static ConnectionStatus fromWire(String? value) {
    final upper = value?.toUpperCase() ?? '';
    return ConnectionStatus.values.firstWhere(
      (s) => s.wire == upper,
      orElse: () => ConnectionStatus.unknown,
    );
  }
}

// =============================================================================
// Remaining circle
// =============================================================================

/// The large central circle showing remaining legal time.
@freezed
abstract class RemainingCircle with _$RemainingCircle {
  const RemainingCircle._();

  const factory RemainingCircle({
    /// Remaining legal time.
    required Duration remaining,

    /// Label shown above the time.
    required String label,

    /// Progress in `[0.0, 1.0]`.
    required double progress,
  }) = _RemainingCircle;

  /// Whether the remaining time has expired.
  bool get isExpired => remaining <= Duration.zero;

  /// Whether the value is close to expiring (≤ 1 hour).
  bool get isCritical => remaining <= const Duration(hours: 1);
}

// =============================================================================
// HOS indicators
// =============================================================================

/// The four HOS indicators (drive, shift, break, cycle).
@freezed
abstract class HosIndicators with _$HosIndicators {
  const factory HosIndicators({
    required HosIndicator drive,
    required HosIndicator shift,
    required HosIndicator breakTime,
    required HosIndicator cycle,
  }) = _HosIndicators;
}

/// A single HOS indicator.
@freezed
abstract class HosIndicator with _$HosIndicator {
  const factory HosIndicator({
    /// Backend-supplied label (e.g. "DRIVE").
    required String label,

    /// Duration value.
    required Duration value,

    /// Whether this value is "used" or "remaining".
    required IndicatorType type,
  }) = _HosIndicator;
}

enum IndicatorType {
  used('USED'),
  remaining('REMAINING');

  const IndicatorType(this.wire);
  final String wire;

  static IndicatorType fromWire(String? value) {
    final upper = value?.toUpperCase() ?? '';
    return IndicatorType.values.firstWhere(
      (t) => t.wire == upper,
      orElse: () => IndicatorType.used,
    );
  }
}

// =============================================================================
// Regulatory constraints
// =============================================================================

/// Regulatory rule set and limits applied to this driver.
@freezed
abstract class RegulatoryConstraints with _$RegulatoryConstraints {
  const factory RegulatoryConstraints({
    required CycleRule ruleSet,
    required List<String> limits,
  }) = _RegulatoryConstraints;
}

extension RegulatoryConstraintsX on RegulatoryConstraints {
  /// يبحث عن الساعات الرقمية لقيد معين (مثل driving أو shift) في قائمة القيود التنظيمية
  String? limitHoursFor(List<String> keys) {
    for (final limit in limits) {
      final lower = limit.toLowerCase();
      if (keys.any(lower.contains)) {
        final match = RegExp(r'(\d+(\.\d+)?)').firstMatch(limit);
        if (match != null) return match.group(1);
      }
    }
    return null;
  }
}

/// Cycle rule sets supported by the backend.
enum CycleRule {
  usa70_8('USA 70/8', 70, 8),
  usa60_7('USA 60/7', 60, 7),
  california80_8('CALIFORNIA_80_8', 80, 8),
  texas70_7('TEXAS_70_7', 70, 7),
  mexicoOnly('MEXICO_ONLY', 60, 7),
  canadaSouth70_7('CANADA_SOUTH_70_7', 70, 7),
  canadaSouth120_14('CANADA_SOUTH_120_14', 120, 14),
  unknown('UNKNOWN', 0, 0);

  const CycleRule(this.wire, this.cycleHours, this.cycleDays);

  /// Backend wire value.
  final String wire;

  /// Maximum cycle hours.
  final int cycleHours;

  /// Maximum cycle days.
  final int cycleDays;

  static CycleRule fromWire(String? value) {
    if (value == null) return CycleRule.unknown;
    return CycleRule.values.firstWhere(
      (r) => r.wire == value,
      orElse: () => CycleRule.unknown,
    );
  }
}
