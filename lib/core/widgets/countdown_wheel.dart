import 'dart:math';
import 'package:flutter/material.dart';
import '../extensions/context_extensions.dart';
// import '../theme/app_colors.dart';

/// حلقة عد تنازلي دائرية لحساب ساعات الخدمة
class CountdownWheel extends StatelessWidget {
  final String label;
  final String remainingTime;
  final double progress; // 0.0 إلى 1.0
  final Color color;
  final double size;

  const CountdownWheel({
    super.key,
    required this.label,
    required this.remainingTime,
    required this.progress,
    required this.color,
    this.size = 140,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // الحلقة
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _CountdownPainter(
              progress: progress,
              color: color,
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    remainingTime,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    context.loc.remainingLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: color.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// رسام الحلقة
class _CountdownPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CountdownPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // خلفية
    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12;

    canvas.drawCircle(center, radius, bgPaint);

    // تقدم
    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    final sweepAngle = 2 * pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      -sweepAngle,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CountdownPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}


