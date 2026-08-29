import 'package:golden_feather_eld/core/engine/hos_calculator.dart';

// ==========================================
// 1. Duty Status & Tracking Models
// ==========================================

/// حالات الخدمة المعتمدة من FMCSA
enum DutyStatus {
  offDuty('Off Duty', 'خارج الخدمة'),
  sleeperBerth('Sleeper Berth', 'النوم'),
  onDutyNotDriving('On Duty', 'على أهبة العمل'),
  driving('Driving', 'قيادة'),
  personalUse('Personal Use', 'استخدام شخصي');

  final String englishName;
  final String arabicName;
  const DutyStatus(this.englishName, this.arabicName);
}

/// حدث من جهاز ELD
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

/// حدث تغيير حالة (تُستخدم للحفظ أو للتاريخ)
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

/// فترة زمنية
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
      return null; // سيتم استخدامه لاحقا مع Haversine
    }
    return null;
  }
}

/// انتقال في الحالة يتم إرساله عبر البث
class DutyTransition {
  final String newStatus;
  final String annotation;

  const DutyTransition({required this.newStatus, required this.annotation});
}

// ==========================================
// 2. Alert & Limits Models
// ==========================================

/// أنواع التنبيهات
enum HosAlertType {
  drivingExpiring,
  shiftExpiring,
  cycleExpiring,
  breakRequired,
}

/// مستويات الخطورة
enum AlertSeverity {
  info,
  warning,
  critical,
}

/// تنبيه
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

/// تحديث حالة HOS
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

/// أنواع انتهاكات HOS
enum HosViolationType {
  dailyDrivingExceeded,
  dailyWorkExceeded,
  dailyRestInsufficient,
  weeklyDrivingExceeded,
  no30MinBreakAfter8h,
  consecutiveDaysExceeded,
  weeklyRestInsufficient,
}

/// مستوى الانتهاك
enum ViolationLevel {
  minor('بسيط', 'Minor'),
  medium('متوسط', 'Medium'),
  high('عالي', 'High'),
  critical('حرج', 'Critical');

  final String arabicName;
  final String englishName;
  const ViolationLevel(this.arabicName, this.englishName);
}

/// نموذج انتهاك
class HosViolation {
  final HosViolationType type;
  final ViolationLevel level;
  final String message;
  final String arabicMessage;
  final DateTime timestamp;
  final Map<String, dynamic>? details;

  const HosViolation({
    required this.type,
    required this.level,
    required this.message,
    required this.arabicMessage,
    required this.timestamp,
    this.details,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.name,
      'level': level.name,
      'message': message,
      'arabicMessage': arabicMessage,
      'timestamp': timestamp.toIso8601String(),
      'details': details,
    };
  }
}
