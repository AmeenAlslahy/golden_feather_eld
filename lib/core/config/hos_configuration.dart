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

  /// إعدادات قواعد الولايات المتحدة (USA 60/7)
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
}
