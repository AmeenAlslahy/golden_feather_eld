import 'dart:math' as math;

import '../../../../../domain/duty_status/duty_status_code.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';

/// تمثل حالة الواجهة للدائرة المحسوبة من البيانات الأساسية
class TimerUiState {
  final Duration liveRemaining;
  final double progress;
  final bool isRest;

  const TimerUiState({
    required this.liveRemaining,
    required this.progress,
    required this.isRest,
  });
}

/// يفصل المنطق التجاري وقوانين الحساب (Business Rules) عن الواجهة (Widget)
class CircularTimerLogic {
  static bool isRestDuty(DutyStatusCode? status, String statusLabel) {
    if (status != null) {
      return status == DutyStatusCode.offDuty ||
          status == DutyStatusCode.sleeperBerth ||
          status == DutyStatusCode.personalConveyance;
    }
    final parsed = DutyStatusCode.tryFromAny(statusLabel);
    if (parsed != null) {
      return parsed == DutyStatusCode.offDuty ||
          parsed == DutyStatusCode.sleeperBerth ||
          parsed == DutyStatusCode.personalConveyance;
    }
    final lower = statusLabel.toLowerCase();
    return lower.contains('off') ||
        lower.contains('sleeper') ||
        lower.contains('personal') ||
        lower.contains('خارج') ||
        lower.contains('سرير') ||
        lower.contains('شخصي') ||
        lower.contains('fuera') ||
        lower.contains('litera');
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

  /// يحسب ما يُعرض على الدائرة: **قيمة الخادم** مرساةً + استيفاء زمني.
  ///
  /// ### الرقم (قرار المالك — الخادم هو المرجع)
  ///
  /// عبر الإنترنت لا يوجد اشتقاق محلي: الدائرة تعرض `متبقي الخادم` من
  /// اللقطة، وينقص بالمنقضي منذ لحظة القياس، ثم **يُستبدل كاملاً**
  /// ببيانات الخادم عند كل نبضة جلب (كل 5 دقائق).
  ///
  /// ### القوس الدائري (مطابق للتطبيق المرجعي)
  ///
  /// 1. **في حالة الراحة (OFF_DUTY, SLEEPER, PERSONAL_CONVEYANCE)**:
  ///    - الدائرة فارغة تماماً (`progress = 0.0`) بدون أي قوس ملون.
  ///    - لون النص رمادي محايد.
  ///
  /// 2. **في حالة العمل النشطة (ON_DUTY, DRIVING, YARD_MOVE)**:
  ///    - عند انتهاء الوقت أو تجاوزه (`liveRemaining <= 0`):
  ///      تكتمل الدائرة 100% (`progress = 1.0`) وتظهر كحلقة حمراء مغلقة بالكامل
  ///      والنص بالأحمر.
  ///    - عند وجود وقت متبقي (`liveRemaining > 0`):
  ///      القوس يمثل نسبة الوقت **المستهلك** من الحد القانوني الحاكم:
  ///      `progress = 1.0 - (liveRemaining / governingLimit)`
  ///      ويبدأ من الأعلى (الساعة 12) متقدماً باتجاه عقارب الساعة بلون أخضر ناصع.
  static TimerUiState calculateUiState({
    required RemainingCircle circle,
    required DutyStatusCode? dutyStatus,
    required HosIndicators? hosIndicators,
    required String statusLabel,
    required Duration elapsedSinceSnapshot,
    Duration cycleLimit = const Duration(hours: 70),
  }) {
    final isRest = isRestDuty(dutyStatus, statusLabel);

    final Duration liveRemaining;
    if (isRest) {
      // 🔴 الخادم هو المرجع: قيمة الخادم المرساة لا تُصفَّر عند الراحة.
      // بما أن السائق في راحة (لا قيادة ولا عمل)، لا يُستهلك رصيد العمل بالمنقضي،
      // فتُعرض قيمة الخادم المتبقية مباشرة كما أرسلها السيرفر.
      liveRemaining = circle.remaining;
    } else {
      // 🔴 العدّاد التنازلي **لا ينزل تحت الصفر بسبب مرور الوقت**.
      // أما السالب القادم من الخادم فحالة أخرى: السائق تجاوز الحدّ
      // أصلاً — وضع ثابت يُعرض كما ورد (مثبَّت في
      // main_circular_timer_test) ولا يصحّحه مصفّر الطرح.
      final raw = circle.remaining - elapsedSinceSnapshot;
      final drivenBelowZeroByElapsed =
          !circle.remaining.isNegative && raw.isNegative;
      liveRemaining = drivenBelowZeroByElapsed ? Duration.zero : raw;
    }

    final double progress;
    if (isRest) {
      // في حالة الراحة، الدائرة فارغة تماماً
      progress = 0.0;
    } else if (liveRemaining <= Duration.zero) {
      // عند انتهاء الوقت في العمل، تكتمل الدائرة 360 درجة
      progress = 1.0;
    } else {
      final governing = _matchingLimit(
        dutyStatus: dutyStatus,
        circleRemaining: circle.remaining,
        indicators: hosIndicators,
        cycleLimit: cycleLimit,
      );
      if (governing != null) {
        final liveSeconds = math.max(0, liveRemaining.inSeconds);
        progress = (1.0 - liveSeconds / governing.inSeconds).clamp(0.0, 1.0);
      } else {
        progress = circle.progress.clamp(0.0, 1.0);
      }
    }

    return TimerUiState(
      liveRemaining: liveRemaining,
      progress: progress,
      isRest: isRest,
    );
  }

  /// المؤشرات الأربعة بصيغتها **الحية** — تنزلق بنفس `elapsedSinceSnapshot`
  /// الذي تنزلق به الدائرة بالضبط.
  static HosIndicators liveIndicators({
    required HosIndicators indicators,
    required DutyStatusCode? dutyStatus,
    required String statusLabel,
    required Duration elapsedSinceSnapshot,
  }) {
    final isRest = isRestDuty(dutyStatus, statusLabel);
    if (isRest || elapsedSinceSnapshot <= Duration.zero) return indicators;

    final isDriving = dutyStatus == DutyStatusCode.driving;
    HosIndicator live(HosIndicator i) {
      if (i.type == IndicatorType.used) {
        return i.copyWith(value: i.value + elapsedSinceSnapshot);
      }
      final next = i.value - elapsedSinceSnapshot;
      return i.copyWith(value: next.isNegative ? Duration.zero : next);
    }

    return indicators.copyWith(
      drive: isDriving ? live(indicators.drive) : indicators.drive,
      shift: live(indicators.shift),
      breakTime: isDriving ? live(indicators.breakTime) : indicators.breakTime,
      cycle: live(indicators.cycle),
    );
  }

  /// الحدّ القانوني الحاكم لدائرة الخادم.
  ///
  /// يُختار أولاً المؤشر الذي «متبقيه» يطابق `circleRemaining` بدقة (± ساعة).
  /// فإن لم يوجد تطابق (فارق كبير أو استجابة غير متزامنة)، نختار المؤشر
  /// الأكثر تقييداً (الأقل متبقياً) للحالة الراهنة حتى لا نقع في fallback لقيم اعتباطية.
  static Duration? _matchingLimit({
    required DutyStatusCode? dutyStatus,
    required Duration circleRemaining,
    required HosIndicators? indicators,
    required Duration cycleLimit,
  }) {
    if (indicators == null) return null;

    Duration? best;
    var bestGap = const Duration(hours: 1);

    void consider(HosIndicator indicator, Duration limit) {
      if (limit.inSeconds <= 0) return;
      final remaining = indicator.type == IndicatorType.used
          ? limit - indicator.value
          : indicator.value;
      final gap = (remaining - circleRemaining).abs();
      if (gap < bestGap) {
        bestGap = gap;
        best = limit;
      }
    }

    final isDriving = dutyStatus == DutyStatusCode.driving;
    if (isDriving) {
      consider(indicators.drive, const Duration(hours: 11));
      consider(indicators.shift, const Duration(hours: 14));
      consider(indicators.breakTime, const Duration(hours: 8));
      consider(indicators.cycle, cycleLimit);
    } else {
      consider(indicators.shift, const Duration(hours: 14));
      consider(indicators.cycle, cycleLimit);
    }

    if (best != null) return best;

    // استنتاج الحد الحاكم من المؤشر الأقل متبقياً لحالة السائق
    Duration remainingOf(HosIndicator ind, Duration limit) =>
        ind.type == IndicatorType.used ? limit - ind.value : ind.value;

    if (isDriving) {
      var minRemaining = remainingOf(indicators.drive, const Duration(hours: 11));
      var governing = const Duration(hours: 11);

      final shiftRem = remainingOf(indicators.shift, const Duration(hours: 14));
      if (shiftRem < minRemaining) {
        minRemaining = shiftRem;
        governing = const Duration(hours: 14);
      }

      final breakRem = remainingOf(indicators.breakTime, const Duration(hours: 8));
      if (breakRem < minRemaining) {
        minRemaining = breakRem;
        governing = const Duration(hours: 8);
      }

      final cycleRem = remainingOf(indicators.cycle, cycleLimit);
      if (cycleRem < minRemaining) {
        governing = cycleLimit;
      }

      return governing;
    } else {
      final shiftRem = remainingOf(indicators.shift, const Duration(hours: 14));
      final cycleRem = remainingOf(indicators.cycle, cycleLimit);
      return cycleRem < shiftRem ? cycleLimit : const Duration(hours: 14);
    }
  }
}
