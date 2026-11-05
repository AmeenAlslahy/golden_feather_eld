import 'dart:async';
import '../../../../../../core/theme/app_typography.dart';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/time/trusted_time_provider.dart';
import '../../../../../core/utils/duration_format.dart';
import '../../../../../core/widgets/app_theme_toggle_button.dart';
import '../../../../../domain/duty_status/duty_status_code.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';
import '../../../../../l10n/app_localizations.dart';
import 'circular_timer_logic.dart';

/// الزمن المنقضي منذ اللقطة — على الساعة الموثوقة واحدة.
///
/// طرفي الطرح (الآن واللقطة) يأتيان من `TrustedTimeProvider`، وهو مثبَّت
/// على ساعة الخادم عبر ترويسة `Date:`. لذلك النتيجة غير قابلة للتأثير
/// بتعديل ساعة الجهاز. لو استُخدم `DateTime.now()` لأحد الطرفين لأصبح
/// الطرح بين ساعتين غير مرتبطتين.
///
/// **مشتركة عمداً** مع بطاقات المؤشرات: أي نسختين من هذه الدالة هي
/// وعود بأن رقمين مختلفين سيظهران لنفس الحدّ القانوني.
Duration computeElapsedSinceSnapshot({
  required TrustedTimeResult trustedTime,
  required DateTime? snapshotTimestamp,
  Duration stopwatchElapsed = Duration.zero,
}) {
  final stamp = snapshotTimestamp;
  if (stamp != null) {
    if (trustedTime is TrustedTimeAvailable) {
      final diff = trustedTime.utc.difference(stamp.toUtc());
      return diff.isNegative
          ? Duration.zero
          : Duration(seconds: diff.inSeconds);
    }
    // ⚠️ لا مرساة موثوقة بعد (أول تشغيل بلا أي رد خادم). نستعمل ساعة
    // الجهاز كأدنى بديل — أأمن من تجميد العدّاد على صفر.
    final wall = DateTime.now().toUtc().difference(stamp.toUtc());
    return wall.isNegative ? Duration.zero : Duration(seconds: wall.inSeconds);
  }
  return Duration(seconds: stopwatchElapsed.inSeconds);
}

/// الدائرة المركزية الكبيرة لعرض الوقت القانوني المتبقي وحركة المؤشر
/// مطابقة بنسبة 100% للتطبيق الأصلي مع العد التنازلي المباشر والقوس الدائري
class MainCircularTimer extends ConsumerStatefulWidget {
  final RemainingCircle circle;
  final String statusLabel;
  final DutyStatusCode? dutyStatus;
  final HosIndicators? hosIndicators;
  final VoidCallback? onTap;

  /// حدّ الدورة لمجموعة القواعد — يُستخدم لمطابقة مؤشر `CYCLE` عند رسم
  /// القوس المتقدم. الافتراضي 70h (USA 70/8)؛ الصفحة تمرّر القيمة من
  /// `regulatoryConstraints.ruleSet`.
  final Duration cycleLimit;

  /// لحظة اللقطة على **ساعة موثوقة** (خادم مُثبَّت عبر ترويسة `Date:`).
  final DateTime? snapshotTimestamp;

  /// اختياري: مصدر موحّد للزمن المنقضي لمزامنة الدائرة مع بقية عناصر الشاشة
  final ValueListenable<Duration>? elapsedNotifier;

  const MainCircularTimer({
    super.key,
    required this.circle,
    required this.statusLabel,
    this.dutyStatus,
    this.hosIndicators,
    this.onTap,
    this.snapshotTimestamp,
    this.elapsedNotifier,
    this.cycleLimit = const Duration(hours: 70),
  });

  @override
  ConsumerState<MainCircularTimer> createState() => _MainCircularTimerState();
}

class _MainCircularTimerState extends ConsumerState<MainCircularTimer>
    with AutomaticKeepAliveClientMixin {
  Timer? _ticker;
  late final Stopwatch _stopwatch;
  late final ValueNotifier<Duration> _elapsedNotifier;

  ValueListenable<Duration> get _effectiveElapsedNotifier =>
      widget.elapsedNotifier ?? _elapsedNotifier;

  @override
  bool get wantKeepAlive => true;

  /// الزمن المنقضي منذ اللقطة — على الساعة الموثوقة واحدة.
  Duration _computeElapsed() => computeElapsedSinceSnapshot(
    trustedTime: ref.read(trustedTimeProvider).currentTime,
    snapshotTimestamp: widget.snapshotTimestamp,
    stopwatchElapsed: _stopwatch.elapsed,
  );

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _elapsedNotifier = ValueNotifier(
      widget.snapshotTimestamp != null ? _computeElapsed() : Duration.zero,
    );
    _startTickerIfNeeded();
  }

  @override
  void didUpdateWidget(MainCircularTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.elapsedNotifier == null &&
        (oldWidget.snapshotTimestamp != widget.snapshotTimestamp ||
            oldWidget.dutyStatus != widget.dutyStatus)) {
      _stopwatch.reset();
      _stopwatch.start();
      _elapsedNotifier.value = _computeElapsed();
      _startTickerIfNeeded();
    }
  }

  bool get _isRestDuty =>
      CircularTimerLogic.isRestDuty(widget.dutyStatus, widget.statusLabel);

  bool get _isActiveDuty =>
      CircularTimerLogic.isActiveDuty(widget.dutyStatus, _isRestDuty);

  void _startTickerIfNeeded() {
    _ticker?.cancel();
    _ticker = null;
    if (widget.elapsedNotifier != null) return;
    if (_isActiveDuty) {
      _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) _elapsedNotifier.value = _computeElapsed();
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
    super.build(context);
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
                valueListenable: _effectiveElapsedNotifier,
                builder: (context, elapsedSinceSnapshot, child) {
                  final uiState = CircularTimerLogic.calculateUiState(
                    circle: widget.circle,
                    dutyStatus: widget.dutyStatus,
                    hosIndicators: widget.hosIndicators,
                    statusLabel: widget.statusLabel,
                    elapsedSinceSnapshot: elapsedSinceSnapshot,
                    cycleLimit: widget.cycleLimit,
                  );

                  final liveRemaining = uiState.liveRemaining;
                  final progress = uiState.progress;
                  final isRest = uiState.isRest;

                  // تحديد اللون:
                  // 1. في حالة الراحة: رمادي محايد (كما في الصورة المرجعية 5).
                  // 2. عند انتهاء الوقت في العمل (00:00 أو سالب): أحمر كامل (كما في الصورة المرجعية 2).
                  // 3. في حالة العمل مع وجود وقت متبقي: أخضر ناصع (كما في الصور المرجعية 1، 3، 4، 6).
                  final Color arcColor;
                  final Color timeTextColor;
                  if (isRest) {
                    arcColor = theme.disabledColor;
                    timeTextColor = theme.colorScheme.onSurface.withValues(
                      alpha: 0.5,
                    );
                  } else if (liveRemaining <= Duration.zero) {
                    arcColor = theme.colorScheme.error;
                    timeTextColor = theme.colorScheme.error;
                  } else {
                    arcColor = context.success;
                    timeTextColor = context.success;
                  }

                  final timeString =
                      DurationFormat.hhMm(liveRemaining, signed: true);
                  final remainingText =
                      AppLocalizations.of(context)?.remainingLabel ??
                      'Remaining';

                  return Semantics(
                    button: widget.onTap != null,
                    label: '$remainingText: $timeString. ${widget.statusLabel}',
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
                            trackColor: context.border,
                            progressColor: arcColor,
                          ),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(circleSize * 0.12),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      remainingText,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(
                                          alpha: 0.8,
                                        ),
                                        fontSize: circleSize * 0.05,
                                      ),
                                    ),
                                    SizedBox(height: circleSize * 0.02),
                                    Text(
                                      timeString,
                                      style: theme.textTheme.displayLarge?.copyWith(
                                        fontSize: circleSize * 0.23,
                                        fontWeight: AppTypography.light,
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
                                        fontWeight: AppTypography.regular,
                                        fontSize: circleSize * 0.075,
                                        color: theme.colorScheme.onSurface.withValues(
                                          alpha: 0.8,
                                        ),
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

    // رسم مسار الدائرة الأساسي (الحلقة الخلفية الرمادية)
    canvas.drawCircle(center, radius, trackPaint);

    // إذا كانت النسبة صفرية أو في حالة راحة، المسار الرمادي الأساسي كافٍ
    if (progress <= 0.0 || isRest) {
      return;
    }

    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    // إذا اكتمل الوقت بالكامل (100% أو أكثر كما في الصورة 2 عند 00:00):
    // رسم دائرة حمراء كاملة متصلة 360 درجة
    if (progress >= 1.0) {
      canvas.drawCircle(center, radius, progressPaint);
      return;
    }

    // رسم القوس الأخضر المتقدم باتجاه عقارب الساعة من الساعة 12
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
