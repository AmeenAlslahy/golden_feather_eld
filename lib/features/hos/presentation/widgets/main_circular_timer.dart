import 'package:flutter/material.dart';

import '../../../../core/theme/app_typography.dart';
import '../../../../core/theme/app_color_tokens.dart';
import 'dart:math';

class MainCircularTimer extends StatelessWidget {
  final String timeString;
  final String statusText;
  final double progress;
  final VoidCallback? onTap;

  const MainCircularTimer({
    super.key,
    required this.timeString,
    required this.statusText,
    required this.progress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final successColor = theme.successColor;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        height: 280,
        padding: const EdgeInsets.all(16),
        child: CustomPaint(
          painter: _TimerPainter(
            progress: progress,
            trackColor: theme.colorScheme.onSurface.withValues(alpha: 0.1),
            progressColor: successColor,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Remaining',
                  style: TextStyle(
                    fontSize: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: AppTypography.bold,
                    color: successColor,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusText.toUpperCase(),
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: AppTypography.regular,
                    letterSpacing: 1,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                const Icon(
                  Icons.keyboard_arrow_down,
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TimerPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _TimerPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    const strokeWidth = 8.0;

    // رسم المسار الرمادي (الخلفية)
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius - strokeWidth / 2, trackPaint);

    // رسم مسار التقدم الأخضر
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -pi / 2; // يبدأ من الأعلى (الساعة 12)
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius - strokeWidth / 2),
      startAngle,
      sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.progressColor != progressColor;
  }
}
