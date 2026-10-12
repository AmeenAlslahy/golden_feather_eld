import 'dart:math' as math;

import '../../../../../domain/duty_status/duty_status_code.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';

/// تمثل حالة الواجهة للدائرة المحسوبة من البيانات الأساسية
class TimerUiState {
  final Duration liveRemaining;
  final double progress;
  final bool isRest;

  TimerUiState({
    required this.liveRemaining,
    required this.progress,
    required this.isRest,
  });
}

/// يفصل المنطق التجاري وقوانين الحساب (Business Rules) عن الواجهة (Widget)
class CircularTimerLogic {
  static bool isRestDuty(DutyStatusCode? status, String statusLabel) {
    if (status == DutyStatusCode.offDuty ||
        status == DutyStatusCode.sleeperBerth ||
        status == DutyStatusCode.personalConveyance) {
      return true;
    }
    final lower = statusLabel.toLowerCase();
    return lower.contains('off') ||
        lower.contains('sleeper') ||
        lower.contains('personal');
  }

  static bool isActiveDuty(DutyStatusCode? status, bool isRest) {
    if (isRest) return false;
    if (status != null) {
      return status == DutyStatusCode.driving ||
          status == DutyStatusCode.onDutyNotDriving ||
          status == DutyStatusCode.yardMove;
    }
    return true;
  }

  /// حساب القيمة المحكومة بناءً على نوع المؤشر (مستهلك أو متبقي)
  static Duration _remainingOf(
      HosIndicator? ind, Duration limit, Duration fallback) {
    if (ind == null) return fallback;
    if (ind.type == IndicatorType.used) {
      return limit - ind.value;
    }
    return ind.value;
  }

  /// يطبق القواعد لاختيار أضيق حد وحساب الوقت الحي
  static TimerUiState calculateUiState({
    required RemainingCircle circle,
    required DutyStatusCode? dutyStatus,
    required HosIndicators? hosIndicators,
    required String statusLabel,
    required Duration elapsedSinceSnapshot,
  }) {
    final isRest = isRestDuty(dutyStatus, statusLabel);
    final isDriving = dutyStatus == DutyStatusCode.driving;

    final Duration totalLimit;
    final Duration baseRemaining;

    if (isRest) {
      totalLimit = const Duration(hours: 11);
      baseRemaining = Duration.zero;
    } else if (isDriving) {
      totalLimit = const Duration(hours: 11);
      baseRemaining = _remainingOf(
        hosIndicators?.drive,
        totalLimit,
        circle.remaining,
      );
    } else {
      // On Duty / Yard Move: الحد الحاكم هو الوردية 14 ساعة أو الاستراحة 8 ساعات
      final shiftVal = hosIndicators?.shift;
      final breakVal = hosIndicators?.breakTime;
      final shiftRaw = shiftVal?.value;
      final breakRaw = breakVal?.value;

      if (breakVal != null &&
          breakRaw != null &&
          breakRaw > Duration.zero &&
          (shiftRaw == null || breakRaw < shiftRaw)) {
        totalLimit = const Duration(hours: 8);
        baseRemaining = _remainingOf(
          breakVal,
          totalLimit,
          circle.remaining,
        );
      } else {
        totalLimit = const Duration(hours: 14);
        baseRemaining = _remainingOf(
          shiftVal,
          totalLimit,
          circle.remaining,
        );
      }
    }

    // حساب الوقت المتبقي الحي ثانية بثانية
    final Duration liveRemaining;
    if (isRest) {
      liveRemaining = Duration.zero;
    } else {
      liveRemaining = baseRemaining - elapsedSinceSnapshot;
    }

    // حساب نسبة الاستهلاك (تقدم الدائرة باتجاه عقارب الساعة كما في التطبيق الأصلي)
    final double progress;
    if (isRest) {
      progress = 0.0;
    } else {
      final consumedSeconds = totalLimit.inSeconds - liveRemaining.inSeconds;
      progress = (consumedSeconds / math.max(1, totalLimit.inSeconds)).clamp(
        0.0,
        1.0,
      );
    }

    return TimerUiState(
      liveRemaining: liveRemaining,
      progress: progress,
      isRest: isRest,
    );
  }
}
