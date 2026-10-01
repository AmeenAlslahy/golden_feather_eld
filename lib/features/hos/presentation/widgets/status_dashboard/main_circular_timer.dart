import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../domain/duty_status/status_dashboard.dart';

/// Large central circle showing remaining legal time.
///
/// Colors change based on [RemainingCircle.isCritical] and
/// [RemainingCircle.isExpired].
class MainCircularTimer extends StatelessWidget {
  final RemainingCircle circle;
  final String statusLabel;
  final VoidCallback? onTap;

  const MainCircularTimer({
    super.key,
    required this.circle,
    required this.statusLabel,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    final timeString = _formatDuration(circle.remaining);

    return Semantics(
      button: onTap != null,
      label: 'Remaining time: $timeString. Status: $statusLabel',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 280,
          height: 280,
          child: CustomPaint(
            painter: _CirclePainter(
              progress: circle.progress,
              trackColor: color.withValues(alpha: 0.15),
              progressColor: color,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  circle.label,
                  style: TextStyle(
                    fontSize: 16,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.normal,
                    color: color,
                    letterSpacing: -1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: context.styles.body.copyWith(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, size: 22),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _color(BuildContext context) {
    final status = statusLabel.toLowerCase();
    if (status.contains('off') || status.contains('sleeper')) return AppColors.textSecondaryFor(Theme.of(context).brightness);
    if (circle.isExpired) return AppColors.dangerRed;
    if (circle.isCritical) return AppColors.warningYellow;
    return AppColors.successGreen;
  }

  static String _formatDuration(Duration duration) {
    final negative = duration.isNegative;
    final abs = duration.abs();
    final hours = abs.inHours;
    final minutes = abs.inMinutes.remainder(60);
    final sign = negative ? '-' : '';
    return '$sign${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}';
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;

  _CirclePainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 16;
    const strokeWidth = 16.0;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    // Progress
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}
