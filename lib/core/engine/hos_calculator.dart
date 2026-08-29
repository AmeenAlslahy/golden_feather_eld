/// حاسب ساعات الخدمة (HOS Calculator)
class HosCalculator {
  /// حدود FMCSA القانونية
  static const int maxDriveMinutes = 11 * 60; // 11 ساعة
  static const int maxShiftMinutes = 14 * 60; // 14 ساعة
  static const int maxCycleHours = 70; // 70 ساعة في 8 أيام
  static const int requiredBreakMinutes = 30; // استراحة 30 دقيقة
  
  static int _activeMaxCycleHours = 70; // الافتراضي 70 ساعة
  
  /// الحصول على حد الدورة النشط
  static int get activeMaxCycleHours => _activeMaxCycleHours;

  /// تعيين حد الدورة
  static void setCycleRule(String rule) {
    switch (rule) {
      case 'USA 60/7':
        _activeMaxCycleHours = 60;
        break;
      case 'Canada 70/7':
        _activeMaxCycleHours = 70;
        break;
      case 'Canada 120/14':
        _activeMaxCycleHours = 120;
        break;
      default: // USA 70/8
        _activeMaxCycleHours = 70;
    }
  }
  static const int driveBeforeBreakMinutes = 8 * 60; // 8 ساعات قيادة متواصلة
  static const int maxConsecutiveDays = 7;
  static const int weeklyRestartHours = 34;

  /// حساب جميع الحدود
  HosLimits calculateAllLimits({
    required double drivingHours,
    required DateTime shiftStartTime,
    required double cycleHours,
  }) {
    final now = DateTime.now();

    // 1. حد القيادة (11 ساعة)
    final drivenMinutes = (drivingHours * 60).toInt();
    final remainingDriveMinutes = (maxDriveMinutes - drivenMinutes).clamp(0, maxDriveMinutes);

    // 2. نافذة العمل (14 ساعة)
    final shiftElapsed = now.difference(shiftStartTime).inMinutes;
    final remainingShiftMinutes = (maxShiftMinutes - shiftElapsed).clamp(0, maxShiftMinutes);

    // 3. الدورة الأسبوعية (60 أو 70 ساعة)
    final remainingCycleHours = (_activeMaxCycleHours - cycleHours).clamp(0.0, _activeMaxCycleHours.toDouble());

    // 4. الاستراحة الإلزامية (30 دقيقة بعد 8 ساعات)
    final breakRequired = drivenMinutes >= driveBeforeBreakMinutes;
    final breakRemainingMinutes = breakRequired ? requiredBreakMinutes : 0;

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
    return (maxDriveMinutes - drivenMinutes).clamp(0, maxDriveMinutes);
  }

  /// حساب نافذة العمل فقط
  int calculateShiftLimit(DateTime shiftStartTime) {
    final elapsed = DateTime.now().difference(shiftStartTime).inMinutes;
    return (maxShiftMinutes - elapsed).clamp(0, maxShiftMinutes);
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
      'is_dst': now.timeZoneOffset != const Duration(hours: 3), // مثال للمنطقة العربية
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


