/// إعدادات وحدود ساعات الخدمة (HOS Configuration).
/// يتيح هذا الكلاس تعريف قواعد HOS بشكل ديناميكي (مثل USA أو Canada) بدلاً من الأرقام الثابتة.
class HosConfiguration {
  final int drivingLimitMinutes;
  final int shiftLimitMinutes;
  final int cycleLimitHours;
  final int breakDurationMinutes;
  final double movingSpeedThresholdKmh;
  final int driveBeforeBreakMinutes;
  final int maxConsecutiveDays;
  final int weeklyRestartHours;

  const HosConfiguration({
    required this.drivingLimitMinutes,
    required this.shiftLimitMinutes,
    required this.cycleLimitHours,
    required this.breakDurationMinutes,
    required this.movingSpeedThresholdKmh,
    required this.driveBeforeBreakMinutes,
    required this.maxConsecutiveDays,
    required this.weeklyRestartHours,
  });

  /// الإعدادات الافتراضية لقواعد الولايات المتحدة (USA 70/8)
  factory HosConfiguration.usa70_8() {
    return const HosConfiguration(
      drivingLimitMinutes: 11 * 60,
      shiftLimitMinutes: 14 * 60,
      cycleLimitHours: 70,
      breakDurationMinutes: 30,
      movingSpeedThresholdKmh: 8.0,
      driveBeforeBreakMinutes: 8 * 60,
      maxConsecutiveDays: 8, // 70 hours in 8 days
      weeklyRestartHours: 34,
    );
  }

  /// الإعدادات الافتراضية لقواعد الولايات المتحدة (USA 60/7)
  factory HosConfiguration.usa60_7() {
    return const HosConfiguration(
      drivingLimitMinutes: 11 * 60,
      shiftLimitMinutes: 14 * 60,
      cycleLimitHours: 60,
      breakDurationMinutes: 30,
      movingSpeedThresholdKmh: 8.0,
      driveBeforeBreakMinutes: 8 * 60,
      maxConsecutiveDays: 7, // 60 hours in 7 days
      weeklyRestartHours: 34,
    );
  }

  HosConfiguration copyWith({
    int? drivingLimitMinutes,
    int? shiftLimitMinutes,
    int? cycleLimitHours,
    int? breakDurationMinutes,
    double? movingSpeedThresholdKmh,
    int? driveBeforeBreakMinutes,
    int? maxConsecutiveDays,
    int? weeklyRestartHours,
  }) {
    return HosConfiguration(
      drivingLimitMinutes: drivingLimitMinutes ?? this.drivingLimitMinutes,
      shiftLimitMinutes: shiftLimitMinutes ?? this.shiftLimitMinutes,
      cycleLimitHours: cycleLimitHours ?? this.cycleLimitHours,
      breakDurationMinutes: breakDurationMinutes ?? this.breakDurationMinutes,
      movingSpeedThresholdKmh: movingSpeedThresholdKmh ?? this.movingSpeedThresholdKmh,
      driveBeforeBreakMinutes: driveBeforeBreakMinutes ?? this.driveBeforeBreakMinutes,
      maxConsecutiveDays: maxConsecutiveDays ?? this.maxConsecutiveDays,
      weeklyRestartHours: weeklyRestartHours ?? this.weeklyRestartHours,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'drivingLimitMinutes': drivingLimitMinutes,
      'shiftLimitMinutes': shiftLimitMinutes,
      'cycleLimitHours': cycleLimitHours,
      'breakDurationMinutes': breakDurationMinutes,
      'movingSpeedThresholdKmh': movingSpeedThresholdKmh,
      'driveBeforeBreakMinutes': driveBeforeBreakMinutes,
      'maxConsecutiveDays': maxConsecutiveDays,
      'weeklyRestartHours': weeklyRestartHours,
    };
  }

  factory HosConfiguration.fromJson(Map<String, dynamic> json) {
    return HosConfiguration(
      drivingLimitMinutes: json['drivingLimitMinutes'] as int? ?? 11 * 60,
      shiftLimitMinutes: json['shiftLimitMinutes'] as int? ?? 14 * 60,
      cycleLimitHours: json['cycleLimitHours'] as int? ?? 70,
      breakDurationMinutes: json['breakDurationMinutes'] as int? ?? 30,
      movingSpeedThresholdKmh: (json['movingSpeedThresholdKmh'] as num?)?.toDouble() ?? 8.0,
      driveBeforeBreakMinutes: json['driveBeforeBreakMinutes'] as int? ?? 8 * 60,
      maxConsecutiveDays: json['maxConsecutiveDays'] as int? ?? 8,
      weeklyRestartHours: json['weeklyRestartHours'] as int? ?? 34,
    );
  }
}
