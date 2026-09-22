import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_gap.dart';

/// Unified circular timer widget used by both HOS page and Status Dashboard.
///
/// **CLEAN-HIGH-03 fix:** Consolidates the two duplicate implementations
/// into a single, reusable component.
class CircularTimerWidget extends StatelessWidget {
  /// Progress from 0.0 to 1.0.
  final double progress;

  /// Time string to display (e.g. "04:06").
  final String timeString;

  /// Label above the time (e.g. "DRIVING").
  final String label;

  /// Status text below the time (e.g. "DRIVING").
  final String statusText;

  /// Whether time is critically low.
  final bool isCritical;

  /// Whether time has expired.
  final bool isExpired;

  /// Optional tap callback.
  final VoidCallback? onTap;

  const CircularTimerWidget({
    super.key,
    required this.progress,
    required this.timeString,
    required this.label,
    required this.statusText,
    this.isCritical = false,
    this.isExpired = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = _color();

    return Semantics(
      button: onTap != null,
      label: 'Remaining time: $timeString. Status: $statusText',
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: SizedBox(
          width: 280,
          height: 280,
          child: CustomPaint(
            painter: _CirclePainter(
              progress: progress,
              trackColor: color.withValues(alpha: 0.15),
              progressColor: color,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    color: color.withValues(alpha: 0.7),
                  ),
                ),
                AppGap.xs,
                Text(
                  timeString,
                  style: TextStyle(
                    fontSize: 56,
                    fontWeight: AppTypography.bold,
                    color: color,
                    letterSpacing: -1,
                  ),
                ),
                AppGap.xs,
                Text(
                  statusText.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: AppTypography.semiBold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _color() {
    if (isExpired) return AppColors.dangerRed;
    if (isCritical) return AppColors.warningYellow;
    return AppColors.successGreen;
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
    final radius = math.min(size.width, size.height) / 2 - 12;
    const strokeWidth = 12.0;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress.clamp(0.0, 1.0),
      false,
      Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_CirclePainter old) =>
      old.progress != progress ||
      old.progressColor != progressColor ||
      old.trackColor != trackColor;
}
