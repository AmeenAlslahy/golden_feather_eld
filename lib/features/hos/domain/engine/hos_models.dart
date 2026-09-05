import 'package:golden_feather_eld/features/hos/domain/engine/hos_calculator.dart';

// ==========================================
// 1. Duty Status & Tracking Models
// ==========================================

/// ط­ط§ظ„ط§طھ ط§ظ„ط®ط¯ظ…ط© ط§ظ„ظ…ط¹طھظ…ط¯ط© ظ…ظ† FMCSA
enum DutyStatus {
  offDuty('Off Duty', 'ط®ط§ط±ط¬ ط§ظ„ط®ط¯ظ…ط©'),
  sleeperBerth('Sleeper Berth', 'ط§ظ„ظ†ظˆظ…'),
  onDutyNotDriving('On Duty', 'ط¹ظ„ظ‰ ط£ظ‡ط¨ط© ط§ظ„ط¹ظ…ظ„'),
  driving('Driving', 'ظ‚ظٹط§ط¯ط©'),
  personalUse('Personal Use', 'ط§ط³طھط®ط¯ط§ظ… ط´ط®طµظٹ');

  final String englishName;
  final String arabicName;
  const DutyStatus(this.englishName, this.arabicName);
}

/// ط­ط¯ط« ظ…ظ† ط¬ظ‡ط§ط² ELD
class EldEvent {
  final double speedMph;
  final int speedDurationSeconds;
  final double odometerMiles;
  final double engineHours;
  final DateTime timestamp;
  final int engineRpm;

  const EldEvent({
    required this.speedMph,
    this.speedDurationSeconds = 0,
    required this.odometerMiles,
    required this.engineHours,
    required this.timestamp,
    this.engineRpm = 0,
  });

  factory EldEvent.fromMap(Map<dynamic, dynamic> map) {
    return EldEvent(
      speedMph: (map['speedMph'] as num?)?.toDouble() ?? 0.0,
      engineRpm: map['engineRpm'] as int? ?? 0,
      odometerMiles: (map['odometerMiles'] as num?)?.toDouble() ?? 0.0,
      engineHours: (map['engineHours'] as num?)?.toDouble() ?? 0.0,
      timestamp: map['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int)
          : DateTime.now(),
    );
  }
}

/// ط­ط¯ط« طھط؛ظٹظٹط± ط­ط§ظ„ط© (طھظڈط³طھط®ط¯ظ… ظ„ظ„ط­ظپط¸ ط£ظˆ ظ„ظ„طھط§ط±ظٹط®)
class DutyStatusEvent {
  final String status;
  final DateTime timestamp;
  final double? latitude;
  final double? longitude;
  final double? odometer;
  final double? engineHours;

  const DutyStatusEvent({
    required this.status,
    required this.timestamp,
    this.latitude,
    this.longitude,
    this.odometer,
    this.engineHours,
  });
}

/// ظپطھط±ط© ط²ظ…ظ†ظٹط©
class DutyPeriod {
  final String status;
  final DateTime startTime;
  final DateTime endTime;
  final double? startOdometer;
  final double? endOdometer;
  final double? startLat;
  final double? startLon;
  final double? endLat;
  final double? endLon;

  const DutyPeriod({
    required this.status,
    required this.startTime,
    required this.endTime,
    this.startOdometer,
    this.endOdometer,
    this.startLat,
    this.startLon,
    this.endLat,
    this.endLon,
  });

  Duration get duration => endTime.difference(startTime);
  double? get distanceKm {
    if (startLat != null && startLon != null && endLat != null && endLon != null) {
      return null; // ط³ظٹطھظ… ط§ط³طھط®ط¯ط§ظ…ظ‡ ظ„ط§ط­ظ‚ط§ ظ…ط¹ Haversine
    }
    return null;
  }
}

/// ط§ظ†طھظ‚ط§ظ„ ظپظٹ ط§ظ„ط­ط§ظ„ط© ظٹطھظ… ط¥ط±ط³ط§ظ„ظ‡ ط¹ط¨ط± ط§ظ„ط¨ط«
class DutyTransition {
  final String newStatus;
  final String annotation;

  const DutyTransition({required this.newStatus, required this.annotation});
}

// ==========================================
// 2. Alert & Limits Models
// ==========================================

/// ط£ظ†ظˆط§ط¹ ط§ظ„طھظ†ط¨ظٹظ‡ط§طھ
enum HosAlertType {
  drivingExpiring,
  shiftExpiring,
  cycleExpiring,
  breakRequired,
}

/// ظ…ط³طھظˆظٹط§طھ ط§ظ„ط®ط·ظˆط±ط©
enum AlertSeverity {
  info,
  warning,
  critical,
}

/// طھظ†ط¨ظٹظ‡
class HosAlert {
  final HosAlertType type;
  final String message;
  final AlertSeverity severity;
  final int remainingMinutes;

  const HosAlert({
    required this.type,
    required this.message,
    required this.severity,
    required this.remainingMinutes,
  });
}

/// طھط­ط¯ظٹط« ط­ط§ظ„ط© HOS
class HosStatusUpdate {
  final DutyStatus currentStatus;
  final HosLimits limits;
  final List<HosAlert> alerts;
  final List<HosViolation> violations;
  final int remainingDriveMinutes;
  final int remainingShiftMinutes;
  final double remainingCycleHours;
  final bool breakRequired;
  final int breakRemainingMinutes;

  const HosStatusUpdate({
    required this.currentStatus,
    required this.limits,
    required this.alerts,
    required this.violations,
    required this.remainingDriveMinutes,
    required this.remainingShiftMinutes,
    required this.remainingCycleHours,
    required this.breakRequired,
    required this.breakRemainingMinutes,
  });

  bool get hasViolations => violations.isNotEmpty;
  bool get hasCriticalAlerts => alerts.any((a) => a.severity == AlertSeverity.critical);
}

// ==========================================
// 3. Violation Models
// ==========================================

/// ط£ظ†ظˆط§ط¹ ط§ظ†طھظ‡ط§ظƒط§طھ HOS
enum HosViolationType {
  dailyDrivingExceeded,
  dailyWorkExceeded,
  dailyRestInsufficient,
  weeklyDrivingExceeded,
  no30MinBreakAfter8h,
  consecutiveDaysExceeded,
  weeklyRestInsufficient,
}

/// ظ…ط³طھظˆظ‰ ط§ظ„ط§ظ†طھظ‡ط§ظƒ
enum ViolationLevel {
  minor('ط¨ط³ظٹط·', 'Minor'),
  medium('ظ…طھظˆط³ط·', 'Medium'),
  high('ط¹ط§ظ„ظٹ', 'High'),
  critical('ط­ط±ط¬', 'Critical');

  final String arabicName;
  final String englishName;
  const ViolationLevel(this.arabicName, this.englishName);
}

/// ظ†ظ…ظˆط°ط¬ ط§ظ†طھظ‡ط§ظƒ
class HosViolation {
  final HosViolationType type;
  final ViolationLevel level;
  final String message;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  const HosViolation({
    required this.type,
    required this.level,
    required this.message,
    required this.timestamp,
    this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'level': level.name,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
}
