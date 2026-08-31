import '../config/hos_configuration.dart';

/// حاسب ساعات الخدمة (HOS Calculator)
class HosCalculator {
  final HosConfiguration config;

  const HosCalculator(this.config);

  /// حساب جميع الحدود
  HosLimits calculateAllLimits({
    required double drivingHours,
    required DateTime shiftStartTime,
    required double cycleHours,
  }) {
    final now = DateTime.now();

    // 1. حد القيادة (11 ساعة)
    final drivenMinutes = (drivingHours * 60).toInt();
    final remainingDriveMinutes = (config.drivingLimitMinutes - drivenMinutes)
        .clamp(0, config.drivingLimitMinutes);

    // 2. نافذة العمل (14 ساعة)
    final shiftElapsed = now.difference(shiftStartTime).inMinutes;
    final remainingShiftMinutes = (config.shiftLimitMinutes - shiftElapsed)
        .clamp(0, config.shiftLimitMinutes);

    // 3. الدورة الأسبوعية (60 أو 70 ساعة)
    final remainingCycleHours = (config.cycleLimitHours - cycleHours)
        .clamp(0.0, config.cycleLimitHours.toDouble());

    // 4. الاستراحة الإلزامية (30 دقيقة بعد 8 ساعات)
    final breakRequired = drivenMinutes >= config.driveBeforeBreakMinutes;
    final breakRemainingMinutes =
        breakRequired ? config.breakDurationMinutes : 0;

    return HosLimits(
      remainingDriveMinutes: remainingDriveMinutes,
      remainingShiftMinutes: remainingShiftMinutes,
      remainingCycleHours: remainingCycleHours,
      breakRequired: breakRequired,
      breakRemainingMinutes: breakRemainingMinutes,
    );
  }

  /// حساب حد القيادة فقط
  int calculateDriveLimit(double drivingHours) {
    final drivenMinutes = (drivingHours * 60).toInt();
    return (config.drivingLimitMinutes - drivenMinutes).clamp(0, config.drivingLimitMinutes);
  }

  /// حساب نافذة العمل فقط
  int calculateShiftLimit(DateTime shiftStartTime) {
    final elapsed = DateTime.now().difference(shiftStartTime).inMinutes;
    return (config.shiftLimitMinutes - elapsed).clamp(0, config.shiftLimitMinutes);
  }

  /// حساب الأيام المتتالية
  int calculateConsecutiveDays(List<DateTime> workDays) {
    if (workDays.isEmpty) return 0;

    workDays.sort();
    int consecutive = 1;
    for (int i = 1; i < workDays.length; i++) {
      final diff = workDays[i].difference(workDays[i - 1]).inDays;
      if (diff == 1) {
        consecutive++;
      } else {
        consecutive = 1;
      }
    }
    return consecutive;
  }

  /// فحص الراحة الأسبوعية (34 ساعة)
  bool hasWeeklyRestart(List<DateTime> offDutyPeriods) {
    for (final period in offDutyPeriods) {
      // يجب أن تتضمن فترتين من 1-5 صباحاً
      if (period.hour >= 1 && period.hour <= 5) {
        return true;
      }
    }
    return false;
  }

  /// تحويل التوقيت المحلي إلى UTC
  static DateTime toUtc(DateTime localTime) {
    return localTime.toUtc();
  }

  /// تحويل UTC إلى التوقيت المحلي
  static DateTime fromUtc(DateTime utcTime) {
    return utcTime.toLocal();
  }

  /// الحصول على التوقيت الحالي بصيغة UTC
  static DateTime get currentUtc => DateTime.now().toUtc();

  /// الحصول على اسم المنطقة الزمنية
  static String get timezoneName => DateTime.now().timeZoneName;

  /// الحصول على فرق التوقيت عن UTC
  static Duration get timezoneOffset => DateTime.now().timeZoneOffset;

  /// تنسيق الوقت بصيغة UTC للمزامنة
  static String formatUtc(DateTime time) {
    return '${time.toUtc().toIso8601String()}Z';
  }

  /// مزامنة الوقت مع UTC (للاستخدام في التقارير)
  static Map<String, dynamic> getTimeSyncInfo() {
    final now = DateTime.now();
    return {
      'utc_time': now.toUtc().toIso8601String(),
      'local_time': now.toIso8601String(),
      'timezone': now.timeZoneName,
      'offset_hours': now.timeZoneOffset.inHours,
      'is_dst': now.timeZoneOffset !=
          const Duration(hours: 3), // مثال للمنطقة العربية
    };
  }
}

/// حدود ساعات الخدمة (أضفتها هنا لتعمل بشكل منفصل أو يمكنك استيرادها)
class HosLimits {
  final int remainingDriveMinutes;
  final int remainingShiftMinutes;
  final double remainingCycleHours;
  final bool breakRequired;
  final int breakRemainingMinutes;

  const HosLimits({
    required this.remainingDriveMinutes,
    required this.remainingShiftMinutes,
    required this.remainingCycleHours,
    required this.breakRequired,
    required this.breakRemainingMinutes,
  });
}
