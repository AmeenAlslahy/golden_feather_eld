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
      // On Duty / Yard Move: الحد الحاكم هو **الأضيق** بين نافذة الوردية
      // (14h) ونافذة الاستراحة (8h).
      //
      // 🔴 **المقارنة على المتبقّي لا على القيم الخام.**
      //
      // كان الكود يقارن `breakRemaining(7:56)` بـ `shiftUsed(10:12)` مباشرة.
      // وكميّتان مختلطتان: أحدهما **متبقٍّ** والآخر **مستهلَك** من
      // حدّين مختلفين (8h و14h) — فالمقارنة بلا معنى. والنتيجة أن الحد
      // الحاكم صار الاستراحة (7:56) بينما الخادم يعرض **3:48**
      // (= 14:00 − 10:12، أي الوردية). فرق قدره **4 ساعات و8 دقائق** يمنح السائق
      // رصيداً قانونياً غير موجود.
      //
      // القاعدة: حوّل كلا المؤشرين إلى "متبقٍّ" ثم خذ الأدنى.
      const shiftLimit = Duration(hours: 14);
      const breakLimit = Duration(hours: 8);

      final shiftRemaining = _remainingOf(
        hosIndicators?.shift,
        shiftLimit,
        circle.remaining,
      );
      final breakRemaining = _remainingOf(
        hosIndicators?.breakTime,
        breakLimit,
        circle.remaining,
      );

      if (breakRemaining < shiftRemaining) {
        totalLimit = breakLimit;
        baseRemaining = breakRemaining;
      } else {
        totalLimit = shiftLimit;
        baseRemaining = shiftRemaining;
      }
    }

    // حساب الوقت المتبقي الحي ثانية بثانية
    final Duration liveRemaining;
    if (isRest) {
      liveRemaining = Duration.zero;
    } else {
      final raw = baseRemaining - elapsedSinceSnapshot;

      // 🔴 العدّاد التنازلي **لا ينزل تحت الصفر بسبب مرور الوقت**.
      // `baseRemaining − elapsed` كان يمرّ سالباً بلا حدّ، فلا يتوقف
      // العدّاد عند بلوغ الصفر بل يكمل العدّ بالسالب.
      //
      // أما السالب القادم **من الخادم** فحالة أخرى: السائق تجاوز الحدّ
      // أصلاً — وضع ثابت يُعرض كما ورد (مثبَّت في
      // main_circular_timer_test) ولا يصحّحه مصفّر الطرح.
      
      final drivenBelowZeroByElapsed =
          elapsedSinceSnapshot > Duration.zero && raw.isNegative;
      liveRemaining = drivenBelowZeroByElapsed ? Duration.zero : raw;
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
      return i.copyWith(
        value: next.isNegative ? Duration.zero : next,
      );
    }

    return indicators.copyWith(
      drive: isDriving ? live(indicators.drive) : indicators.drive,
      shift: live(indicators.shift),
      breakTime: isDriving ? live(indicators.breakTime) : indicators.breakTime,
      cycle: live(indicators.cycle),
    );
  }

  /// دمج **أحادي الاتجاه**: التطبيق لا يُرجِع وقتاً مستهلكاً إلى الوراء.
  ///
  /// ### لماذا
  ///
  /// قيست الخادم الحيّ مباشرة ووجدت تبايناً بنيوياً:
  ///
  /// | المؤشر | هل يحتسب الفترة المفتوحة؟ |
  /// |---|---|
  /// | `CYCLE` | ✅ نعم (25:41 ← 36:43 خلال 11 ساعة) |
  /// | `SHIFT` | ❌ لا — يحسبه من الفترات **المغلقة** فقط |
  /// | `BREAK` / `circle` | ❌ لا — بقي `08:00` خلال 201 ثانية |
  ///
  /// فالسائق `ON_DUTY` منذ 12 ساعة، والخادم ما زال يقول
  /// `SHIFT 00:00`. ولو قبل التطبيق هذه القيمة عند كل نبضة 5 دقائق
  /// لقتل العدّاد وارتدّ إلى الصفر كل خمس دقائق — **وهو أسوأ من العطل
  /// الأصلي**: رقم يقفز بلا سبب ويخسر السائق الثقة بكل الأرقام.
  ///
  /// ### القاعدة
  ///
  /// - نفس حالة الخدمة ⇒ لا نقبل زيادة الوقت المتبقي عند الخادم.
  ///   المتبقي = `min(خادم، محلي)`.
  /// - تغيّرت حالة الخدمة ⇒ نافذة جديدة، والخادم مرجعها بلا تحفّظ.
  ///
  /// الأمان: **لا يمكن لهذه القاعدة أن تمنح السائق وقتاً أضيق**. أسوأ
  /// ما تفعله أنها تحذف سعة زائدة — وتُصحَّح عند إغلاق الفترة.
  static RemainingCircle reconcileRemaining({
    required RemainingCircle server,
    required RemainingCircle local,
    required bool sameDutyEpisode,
  }) {
    if (!sameDutyEpisode) return server;
    return server.remaining <= local.remaining ? server : local;
  }
}
