import '../../../../core/config/hos_configuration.dart';
import '../../../../core/time/trusted_time_provider.dart';
import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';

sealed class CalculationResult {}

class CalculationSuccess extends CalculationResult {
  final HosLimits limits;
  CalculationSuccess(this.limits);
}

class CalculationTimeUnavailable extends CalculationResult {
  final TrustedTimeState state;
  CalculationTimeUnavailable(this.state);
}

sealed class ShiftLimitResult {}

class ShiftLimitSuccess extends ShiftLimitResult {
  final int remainingMinutes;
  ShiftLimitSuccess(this.remainingMinutes);
}

class ShiftLimitUnavailable extends ShiftLimitResult {
  final TrustedTimeState state;
  ShiftLimitUnavailable(this.state);
}

/// حاسب ساعات الخدمة (HOS Calculator)
class HosCalculator {
  final HosConfiguration config;
  final TrustedTimeProvider timeProvider;

  const HosCalculator(this.config, this.timeProvider);

  /// حساب جميع الحدود
  /// Needs: trusted UTC (to compare against shiftStartTime)
  ///
  /// [drivingHoursSinceBreak] منفصل عن [drivingHours]: الحد الثامن
  /// يُقاس من آخر استراحة مؤهلة (49 CFR 395.3(a)(3)(ii))، بينما Driving
  /// الحد الإجمالي يُقاس من إعادة التصفير الأسبوعية.
  CalculationResult calculateAllLimits({
    required double drivingHours,
    required DateTime shiftStartTime,
    required double cycleHours,
    double? drivingHoursSinceBreak,
  }) {
    final timeResult = timeProvider.currentTime;
    if (timeResult is TrustedTimeUnavailable) {
      return CalculationTimeUnavailable(timeResult.state);
    }

    final now = (timeResult as TrustedTimeAvailable).utc;

    // 1. حد القيادة (11 ساعة) - Needs nothing (monotonic pure input)
    final drivenMinutes = (drivingHours * 60).toInt();
    final remainingDriveMinutes = (config.drivingLimitMinutes - drivenMinutes)
        .clamp(0, config.drivingLimitMinutes);

    // 2. نافذة العمل (14 ساعة) - Needs trusted UTC
    final shiftElapsed = now.difference(shiftStartTime.toUtc()).inMinutes;
    final remainingShiftMinutes = (config.shiftLimitMinutes - shiftElapsed)
        .clamp(0, config.shiftLimitMinutes);

    // 3. الدورة الأسبوعية (60 أو 70 ساعة) - Needs nothing
    final remainingCycleHours = (config.cycleLimitHours - cycleHours)
        .clamp(0.0, config.cycleLimitHours.toDouble());

    // 4. الاستراحة الإلزامية (30 دقيقة بعد 8 ساعات)
    //
    // تُقاس من آخر استراحة مؤهلة، لا من بداية الوردية.
    final breakDrivingHours = drivingHoursSinceBreak ?? drivingHours;
    final breakDrivenMinutes = (breakDrivingHours * 60).toInt();
    final breakRequired =
        breakDrivenMinutes >= config.driveBeforeBreakMinutes;
    final breakRemainingMinutes =
        breakRequired ? config.breakDurationMinutes : 0;
    final timeUntilBreakMinutes =
        (config.driveBeforeBreakMinutes - breakDrivenMinutes)
            .clamp(0, config.driveBeforeBreakMinutes);

    return CalculationSuccess(HosLimits(
      remainingDriveMinutes: remainingDriveMinutes,
      remainingShiftMinutes: remainingShiftMinutes,
      remainingCycleHours: remainingCycleHours,
      breakRequired: breakRequired,
      breakRemainingMinutes: breakRemainingMinutes,
      timeUntilBreakMinutes: timeUntilBreakMinutes,
    ));
  }

  /// حساب حد القيادة فقط
  /// Needs: nothing (monotonic pure input)
  int calculateDriveLimit(double drivingHours) {
    final drivenMinutes = (drivingHours * 60).toInt();
    return (config.drivingLimitMinutes - drivenMinutes)
        .clamp(0, config.drivingLimitMinutes);
  }

  /// حساب نافذة العمل فقط
  /// Needs: trusted UTC
  ShiftLimitResult calculateShiftLimit(DateTime shiftStartTime) {
    final timeResult = timeProvider.currentTime;
    if (timeResult is TrustedTimeUnavailable) {
      return ShiftLimitUnavailable(timeResult.state);
    }
    final now = (timeResult as TrustedTimeAvailable).utc;
    final elapsed = now.difference(shiftStartTime.toUtc()).inMinutes;
    return ShiftLimitSuccess((config.shiftLimitMinutes - elapsed)
        .clamp(0, config.shiftLimitMinutes));
  }

  /// فحص الراحة الأسبوعية (34 ساعة)
  /// Needs: Regulatory Timezone (Currently assumes inputs are already formatted)
  bool hasWeeklyRestart(List<({DateTime start, DateTime end})> offDutyPeriods) {
    // 34 consecutive hours of off-duty/sleeper berth
    const requiredHours = 34;
    for (final period in offDutyPeriods) {
      final duration = period.end.difference(period.start);
      if (duration.inMinutes >= requiredHours * 60) {
        return true;
      }
    }
    return false;
  }
}

