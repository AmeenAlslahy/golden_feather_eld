import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/utils/duration_format.dart';
import '../../../../../core/widgets/app_theme_toggle_button.dart';
import '../../../../../domain/duty_status/duty_status_code.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';
import 'circular_timer_logic.dart';

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
  late final Stopwatch _stopwatch;
  late final ValueNotifier<Duration> _elapsedNotifier;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _elapsedNotifier = ValueNotifier(Duration.zero);
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(MainCircularTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.circle.remaining != widget.circle.remaining ||
        oldWidget.dutyStatus != widget.dutyStatus ||
        oldWidget.hosIndicators != widget.hosIndicators) {
      _stopwatch.reset();
      _elapsedNotifier.value = Duration.zero;
      _startTickerIfNeeded();
    }
  }

  bool get _isRestDuty => CircularTimerLogic.isRestDuty(
        widget.dutyStatus,
        widget.statusLabel,
      );

  bool get _isActiveDuty => CircularTimerLogic.isActiveDuty(
        widget.dutyStatus,
        _isRestDuty,
      );

  void _startTickerIfNeeded() {
    _ticker?.cancel();
    _ticker = null;
    if (_isActiveDuty) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _elapsedNotifier.value = _stopwatch.elapsed;
      });
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    _elapsedNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        // اجعل الدائرة متجاوبة مع الشاشات مع حد أقصى 340 وبدون تجاوز الارتفاع
        final double maxAvailableHeight = constraints.maxHeight - 20;
        final double circleSize = math.min(
          math.min(constraints.maxWidth - 32, maxAvailableHeight),
          340,
        );
        
        return SizedBox(
          width: double.infinity,
          height: constraints.maxHeight,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // الدائرة المتحركة — وحدها القابلة للنقر لفتح تغيير الحالة
              ValueListenableBuilder<Duration>(
                valueListenable: _elapsedNotifier,
                builder: (context, elapsedSinceSnapshot, child) {
                  final uiState = CircularTimerLogic.calculateUiState(
                    circle: widget.circle,
                    dutyStatus: widget.dutyStatus,
                    hosIndicators: widget.hosIndicators,
                    statusLabel: widget.statusLabel,
                    elapsedSinceSnapshot: elapsedSinceSnapshot,
                  );

                  final liveRemaining = uiState.liveRemaining;
                  final progress = uiState.progress;
                  final isRest = uiState.isRest;

                  // تحديد اللون: رمادي عند الراحة فقط. المنتهي وهو يعمل يبقى أحمر
                  final Color arcColor;
                  final Color timeTextColor;
                  if (isRest) {
                    arcColor = theme.disabledColor;
                    timeTextColor = theme.hintColor;
                  } else if (liveRemaining <= Duration.zero ||
                      liveRemaining <= const Duration(minutes: 15)) {
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
                        width: circleSize,
                        height: circleSize,
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
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                  fontSize: circleSize * 0.05,
                                ),
                              ),
                              SizedBox(height: circleSize * 0.02),
                              Text(
                                timeString,
                                style: theme.textTheme.displayLarge?.copyWith(
                                  fontSize: circleSize * 0.23,
                                  fontWeight: FontWeight.w300,
                                  color: timeTextColor,
                                  letterSpacing: -1.0,
                                  height: 1.1,
                                ),
                              ),
                              SizedBox(height: circleSize * 0.02),
                              Text(
                                widget.statusLabel.toUpperCase(),
                                textAlign: TextAlign.center,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w400,
                                  fontSize: circleSize * 0.075,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                ),
                              ),
                              SizedBox(height: circleSize * 0.05),
                              Icon(
                                Icons.keyboard_arrow_down,
                                size: circleSize * 0.09,
                                color: theme.colorScheme.onSurface,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              // زر تبديل الثيم فوق الدائرة — يأتي أخيراً في الـ Stack
              // ليفوز باختبار النقر عند أي تداخل، ونقرته لا تفتح تغيير الحالة.
              const Positioned(top: 4, left: 16, child: AppThemeToggleButton()),
            ],
          ),
        );
      },
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
