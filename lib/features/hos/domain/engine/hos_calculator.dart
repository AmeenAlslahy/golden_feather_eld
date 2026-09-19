import '../../../../core/config/hos_configuration.dart';
import '../../../../core/time/trusted_time_provider.dart';
import '../../../../core/domain/entities/hos_models.dart';

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
  CalculationResult calculateAllLimits({
    required double drivingHours,
    required DateTime shiftStartTime,
    required double cycleHours,
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

    // 4. الاستراحة الإلزامية (30 دقيقة بعد 8 ساعات) - Needs nothing
    final breakRequired = drivenMinutes >= config.driveBeforeBreakMinutes;
    final breakRemainingMinutes =
        breakRequired ? config.breakDurationMinutes : 0;

    return CalculationSuccess(HosLimits(
      remainingDriveMinutes: remainingDriveMinutes,
      remainingShiftMinutes: remainingShiftMinutes,
      remainingCycleHours: remainingCycleHours,
      breakRequired: breakRequired,
      breakRemainingMinutes: breakRemainingMinutes,
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

  /// حساب الأيام المتتالية
  /// Needs: nothing (pure function on inputs)
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
  /// Needs: Regulatory Timezone (Currently assumes inputs are already formatted)
  bool hasWeeklyRestart(List<DateTime> offDutyPeriods) {
    for (final period in offDutyPeriods) {
      // يجب أن تتضمن فترتين من 1-5 صباحاً
      if (period.hour >= 1 && period.hour <= 5) {
        return true;
      }
    }
    return false;
  }
}

