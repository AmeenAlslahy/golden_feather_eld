import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/duration_format.dart';
import '../../../../../domain/duty_status/duty_status_code.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';

/// الدائرة المركزية الكبيرة لعرض الوقت القانوني المتبقي وحركة المؤشر
/// مطابقة بنسبة 100% للتطبيق الأصلي مع العد التنازلي المباشر وتحول اللون للأحمر عند الاقتراب من النهاية
class MainCircularTimer extends StatefulWidget {
  final RemainingCircle circle;
  final String statusLabel;
  final DutyStatusCode? dutyStatus;
  final HosIndicators? hosIndicators;
  final VoidCallback? onTap;

  const MainCircularTimer({
    super.key,
    required this.circle,
    required this.statusLabel,
    this.dutyStatus,
    this.hosIndicators,
    this.onTap,
  });

  @override
  State<MainCircularTimer> createState() => _MainCircularTimerState();
}

class _MainCircularTimerState extends State<MainCircularTimer> {
  Timer? _ticker;
  late DateTime _snapshotTime;

  @override
  void initState() {
    super.initState();
    _snapshotTime = DateTime.now();
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(MainCircularTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circle.remaining != widget.circle.remaining ||
        oldWidget.dutyStatus != widget.dutyStatus ||
        oldWidget.hosIndicators != widget.hosIndicators) {
      _snapshotTime = DateTime.now();
      _startTickerIfNeeded();
      setState(() {});
    }
  }

  bool get _isRestDuty {
    final status = widget.dutyStatus;
    if (status == DutyStatusCode.offDuty ||
        status == DutyStatusCode.sleeperBerth ||
        status == DutyStatusCode.personalConveyance) {
      return true;
    }
    final lower = widget.statusLabel.toLowerCase();
    return lower.contains('off') ||
        lower.contains('sleeper') ||
        lower.contains('personal');
  }

  bool get _isActiveDuty {
    if (_isRestDuty) return false;
    final status = widget.dutyStatus;
    if (status != null) {
      return status == DutyStatusCode.driving ||
          status == DutyStatusCode.onDutyNotDriving ||
          status == DutyStatusCode.yardMove;
    }
    return true;
  }

  void _startTickerIfNeeded() {
    _ticker?.cancel();
    _ticker = null;
    if (_isActiveDuty) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRest = _isRestDuty;
    final isDriving = widget.dutyStatus == DutyStatusCode.driving;

    // تحديد الحد الإجمالي والقيمة المتبقية الأساسية
    final Duration totalLimit;
    final Duration baseRemaining;

    if (isRest) {
      totalLimit = const Duration(hours: 11);
      baseRemaining = Duration.zero;
    } else if (isDriving) {
      totalLimit = const Duration(hours: 11);
      final driveVal = widget.hosIndicators?.drive.value;
      baseRemaining = (driveVal != null && driveVal > Duration.zero)
          ? driveVal
          : (widget.circle.remaining > Duration.zero
              ? widget.circle.remaining
              : const Duration(hours: 11));
    } else {
      // On Duty / Yard Move: الحد الحاكم هو الوردية 14 ساعة أو الاستراحة 8 ساعات
      final shiftVal = widget.hosIndicators?.shift.value;
      final breakVal = widget.hosIndicators?.breakTime.value;
      if (breakVal != null &&
          breakVal > Duration.zero &&
          (shiftVal == null || breakVal < shiftVal)) {
        totalLimit = const Duration(hours: 8);
        baseRemaining = breakVal;
      } else {
        totalLimit = const Duration(hours: 14);
        baseRemaining = (shiftVal != null && shiftVal > Duration.zero)
            ? shiftVal
            : (widget.circle.remaining > Duration.zero
                ? widget.circle.remaining
                : const Duration(hours: 14));
      }
    }

    // حساب الوقت المتبقي الحي ثانية بثانية
    final Duration liveRemaining;
    if (isRest) {
      liveRemaining = Duration.zero;
    } else {
      final elapsedSinceSnapshot = DateTime.now().difference(_snapshotTime);
      liveRemaining = baseRemaining - elapsedSinceSnapshot;
    }

    // حساب نسبة الاستهلاك (تقدم الدائرة باتجاه عقارب الساعة كما في التطبيق الأصلي)
    final double progress;
    if (isRest) {
      progress = 0.0;
    } else {
      final consumedSeconds = totalLimit.inSeconds - liveRemaining.inSeconds;
      progress =
          (consumedSeconds / math.max(1, totalLimit.inSeconds)).clamp(0.0, 1.0);
    }

    // تحديد اللون: رمادي عند الراحة، أحمر عند اقتراب النهاية (≤ 15 دقيقة / انتهاء الوقت)، أخضر في الأمان
    final Color arcColor;
    final Color timeTextColor;
    if (isRest || liveRemaining <= Duration.zero) {
      arcColor = theme.disabledColor;
      timeTextColor = theme.hintColor;
    } else if (liveRemaining <= const Duration(minutes: 15)) {
      arcColor = theme.colorScheme.error;
      timeTextColor = theme.colorScheme.error;
    } else {
      // أخضر ناصع (Safe color)
      arcColor = const Color(0xFF34A853);
      timeTextColor = const Color(0xFF34A853);
    }

    final timeString = isRest
        ? '00:00'
        : DurationFormat.hhMm(
            liveRemaining.isNegative ? Duration.zero : liveRemaining,
          );

    return Semantics(
      button: widget.onTap != null,
      label: 'Remaining time: $timeString. Status: ${widget.statusLabel}',
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: double.infinity,
          height: 310,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // زر الوضع الليلي في الزاوية العلوية اليسرى
              Positioned(
                top: 4,
                left: 16,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.nightlight_round,
                    color: theme.colorScheme.onPrimary,
                    size: 22,
                  ),
                ),
              ),

              // الدائرة المتحركة
              SizedBox(
                width: 280,
                height: 280,
                child: CustomPaint(
                  painter: _OriginalEldCirclePainter(
                    progress: progress,
                    isRest: isRest,
                    trackColor: isRest
                        ? theme.disabledColor.withValues(alpha: 0.3)
                        : theme.dividerColor,
                    progressColor: arcColor,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Remaining',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.hintColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        timeString,
                        style: theme.textTheme.displayLarge?.copyWith(
                          fontSize: 56,
                          fontWeight: FontWeight.w400,
                          color: timeTextColor,
                          letterSpacing: -1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.statusLabel.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Icon(
                        Icons.keyboard_arrow_down,
                        size: 26,
                        color: theme.colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// رسام الدائرة مطابق 100% للتطبيق الأصلي
class _OriginalEldCirclePainter extends CustomPainter {
  final double progress;
  final bool isRest;
  final Color trackColor;
  final Color progressColor;

  _OriginalEldCirclePainter({
    required this.progress,
    required this.isRest,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 8;
    const strokeWidth = 8.0;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // رسم مسار الدائرة الأساسي
    canvas.drawCircle(center, radius, trackPaint);

    // إذا كانت الحالة راحة (Off Duty / Sleeper)، المسار الرمادي الكامل كافٍ
    if (isRest || progress <= 0.0) {
      return;
    }

    // رسم القوس الأخضر/الأحمر المتقدم مع الوقت
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2, // يبدأ من الأعلى (الساعة 12)
      sweepAngle, // يتقدم باتجاه عقارب الساعة
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_OriginalEldCirclePainter old) =>
      old.progress != progress ||
      old.isRest != isRest ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}
