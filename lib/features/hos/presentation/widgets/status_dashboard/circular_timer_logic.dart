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
  /// ببيانات الخادم عند كل نبضة جلب (كل 5 دقائق). الاشتقاق المحلي القديم
  /// (أضيق حد بين الوردية والاستراحة) كان يخالف الخادم — مقيس حياً:
  /// الخادم 00:58 (حاكم بالدورة) والتطبيق 07:57.
  ///
  /// ### القوس (كما في التطبيق المرجعي)
  ///
  /// يتقدم **ثانية بثانية** مع الوقت من الحدّ القانوني الحاكم، والحدّ
  /// يُستنتج من **مؤشرات الخادم نفسها** — المؤشر الذي «متبقيه» يطابق
  /// `circle.remaining` (المصدر الذي أنتج الدائرة). قيست المطابقة حياً:
  /// `00:58 = 70:00 − 69:02` (الدورة) و`03:48 = 14:00 − 10:12` (الوردية).
  ///
  /// - الراحة: صفر ودائرة فارغة.
  /// - السالب القادم **من الخادم** يُعرض كما ورد (تجاوز حدّ)، أما النزول
  ///   تحت الصفر **بسبب مرور الوقت** فيُقيَّد عند الصفر.
  ///
  /// [hosIndicators] تُستخدم لمطابقة الحدّ الحاكم (طول القوس) فقط — ولا
  /// تُغيّر الرقم المعروض إطلاقاً.
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

    // القوس يتقدم مع الوقت (كما في التطبيق المرجعي): نسبة المستهلك من
    // الحدّ القانوني **الحاكم**، ثانية بثانية مع العدّاد.
    //
    // ⚠️ لا يُشتق الإجمالي من نسبة الخادم: الصيغة القديمة
    // `total = متبقي ÷ (1−نسبة)` منفجرة — النسبة تصل بدقتين عشريتين،
    // وعند 0.99 يتراوح «الإجمالي» بين ~64 و193 ساعة والدورة 70، وكانت
    // تصفّر القوس عند تقريب الخادم إلى 1.00 (آخر ~21 دقيقة من الدورة)
    // عند كل نبضة (سنّ منشار). الحدّ يأتي من مطابقة مؤشرات الخادم.
    //
    // بلا مؤشرات (أو بلا مطابقة معقولة): قيمة الخادم حرفياً — لا نخترع
    // إجمالاً؛ وإذا بلغ العدّاد الصفر قبل النبضة التالية فالقوس يكتمل.
    final double progress;
    if (isRest) {
      // في حالة الراحة، تُعرض نسبة تقدم الخادم مباشرة.
      progress = circle.progress.clamp(0.0, 1.0);
    } else {
      final governing = _matchingLimit(
        circleRemaining: circle.remaining,
        indicators: hosIndicators,
        cycleLimit: cycleLimit,
      );
      if (governing != null) {
        final liveSeconds = math.max(0, liveRemaining.inSeconds);
        progress = (1 - liveSeconds / governing.inSeconds).clamp(0.0, 1.0);
      } else if (liveRemaining <= Duration.zero) {
        progress = 1.0;
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
  ///
  /// ### لماذا
  ///
  /// كانت البطاقة تعرض `indicator.value` الخام بلا طرح ولا إضافة:
  ///
  /// ```dart
  /// Text(DurationFormat.hhMm(indicator.value))   // لا يتغير أبداً
  /// ```
  ///
  /// فبينما الدائرة تنقص ثانية بثانية تبقى البطاقة على قيمة آخر جلب،
  /// فيعرض التطبيق **رقمين مختلفين لنفس الحدّ القانوني في وقت واحد**.
  /// Worse، مع الجلب الدوري كل 5 دقائق قفز الرقم كل خمس دقائق
  /// (قفزة خمس دقائق في لحظة واحدة) — يقرأها السائق كقفزة عشوائية.
  ///
  /// ### القاعدة
  ///
  /// - في حالة عمل نشطة: `USED` يزداد بـ elapsed، و`REMAINING` ينقص
  ///   بـ elapsed (مع الإبقاء عند الصفر).
  /// - في حالة الراحة: لا شيء يتحرّك — لا عمل ولا قيادة، فلا استهلاك.
  static HosIndicators liveIndicators({
    required HosIndicators indicators,
    required DutyStatusCode? dutyStatus,
    required String statusLabel,
    required Duration elapsedSinceSnapshot,
  }) {
    final isRest = isRestDuty(dutyStatus, statusLabel);
    if (isRest || elapsedSinceSnapshot <= Duration.zero) return indicators;

    // 🔴 مؤشرا القيادة والاستراحة يُحرَّكان فقط أثناء القيادة الفعلية (FMCSA § 395.3).
    // في حالة onDutyNotDriving أو yardMove يبقيان ثابتين — السائق لا يقود.
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

  /// الحدّ القانوني الحاكم لدائرة الخادم — من **بيانات الخادم وحدها**.
  ///
  /// يُختار المؤشر الذي «متبقيه» (المشتق من حدّه الثابت لقيم `USED`، أو
  /// قيمته لقيم `REMAINING`) هو الأقرب إلى `circleRemaining`. الخادم
  /// يحسب الدائرة من أحد مؤشراته الأربعة في اللقطة نفسها، فالمطابقة
  /// دقيقة (± دقيقة تقريب). إن بعدت كل المطابقات أكثر من ساعة (بيانات
  /// غير متسقة) يُعاد `null` — فيعرض القوس قيمة الخادم حرفياً.
  static Duration? _matchingLimit({
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

    consider(indicators.drive, const Duration(hours: 11));
    consider(indicators.shift, const Duration(hours: 14));
    consider(indicators.breakTime, const Duration(hours: 8));
    consider(indicators.cycle, cycleLimit);
    return best;
  }
}
