import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_colors.dart';

class EldGraphPoint {
  final double startHour; // 0.0 to 24.0
  final double endHour; // 0.0 to 24.0
  final String status; // 'OFF', 'SB', 'D', 'ON'
  final String? tag; // e.g. 'PC', 'YM'
  final bool isDashed; // Draw this segment as a dashed line (for inspection)

  const EldGraphPoint({
    required this.startHour,
    required this.endHour,
    required this.status,
    this.tag,
    this.isDashed = false,
  });
}

class EldGraphGrid extends StatelessWidget {
  final List<EldGraphPoint> points;
  final Map<String, double>? rightSideStats; // Map of 'OFF', 'SB', 'D', 'ON' to hours
  final double? liveMarkerHour; // The current live time if applicable (0.0 to 24.0)

  const EldGraphGrid({
    super.key,
    required this.points,
    this.rightSideStats,
    this.liveMarkerHour,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final textColor = isDark ? Colors.white70 : Colors.black87;
    final gridColor = isDark ? Colors.white30 : Colors.black26;

    return CustomPaint(
      size: const Size(double.infinity, 220),
      painter: _EldGraphGridPainter(
        points: points,
        stats: rightSideStats,
        liveMarkerHour: liveMarkerHour,
        textColor: textColor,
        gridColor: gridColor,
      ),
    );
  }
}

class _EldGraphGridPainter extends CustomPainter {
  final List<EldGraphPoint> points;
  final Map<String, double>? stats;
  final double? liveMarkerHour;
  final Color textColor;
  final Color gridColor;

  _EldGraphGridPainter({
    required this.points,
    this.stats,
    this.liveMarkerHour,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const offsetX = 35.0; // Left padding for status labels
    // Only reserve right margin if stats are provided
    final rightMargin = stats != null ? 40.0 : 10.0;
    final chartWidth = size.width - offsetX - rightMargin;

    // Reserve top 20 pixels for Time Axis
    const timeAxisHeight = 20.0;
    final chartHeight = size.height - timeAxisHeight;
    final rowHeight = chartHeight / 4.0; // 4 rows: OFF, SB, D, ON

    _drawTimeAxis(canvas, offsetX, chartWidth, timeAxisHeight);

    canvas.save();
    canvas.translate(0, timeAxisHeight);

    _drawGridLines(canvas, size, offsetX, chartWidth, chartHeight, rowHeight);
    _drawYAxisLabels(canvas, offsetX, rowHeight);
    
    if (stats != null) {
      _drawRightSideStats(canvas, size, offsetX, chartWidth, rowHeight);
    }
    
    _drawStepLine(canvas, offsetX, chartWidth, rowHeight);

    if (liveMarkerHour != null) {
      _drawLiveMarker(canvas, offsetX, chartWidth, rowHeight);
    }

    canvas.restore();
  }

  void _drawTimeAxis(Canvas canvas, double offsetX, double chartWidth, double height) {
    final hours = [
      'M', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11',
      'N', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', 'M'
    ];
    final colWidth = chartWidth / 24;

    for (int i = 0; i <= 24; i++) {
      final textSpan = TextSpan(
        text: hours[i],
        style: TextStyle(
          fontSize: 9,
          color: textColor.withValues(alpha: 0.8),
        ),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();

      final x = offsetX + i * colWidth - (textPainter.width / 2);
      final y = height - textPainter.height - 4; // 4px padding above grid
      textPainter.paint(canvas, Offset(x, y));
    }
  }

  void _drawGridLines(Canvas canvas, Size size, double offsetX, double chartWidth, double chartHeight, double rowHeight) {
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    final minorTickPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    for (int i = 0; i <= 4; i++) {
      canvas.drawLine(Offset(offsetX, i * rowHeight), Offset(offsetX + chartWidth, i * rowHeight), gridPaint);
    }

    final colWidth = chartWidth / 24;

    for (int i = 0; i <= 24; i++) {
      final x = offsetX + i * colWidth;
      canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), gridPaint);

      if (i < 24) {
        for (int j = 1; j <= 3; j++) {
          final tickX = x + (colWidth / 4) * j;
          final tickHeight = (j == 2) ? 6.0 : 3.0;

          for (int r = 0; r <= 4; r++) {
            final y = r * rowHeight;
            canvas.drawLine(Offset(tickX, y - tickHeight), Offset(tickX, y + tickHeight), minorTickPaint);
          }
        }
      }
    }
  }

  void _drawYAxisLabels(Canvas canvas, double offsetX, double rowHeight) {
    const labels = ['OFF', 'SB', 'D', 'ON'];
    for (int i = 0; i < labels.length; i++) {
      final textSpan = TextSpan(
        text: labels[i],
        style: TextStyle(
          fontSize: 10,
          color: textColor.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(offsetX - textPainter.width - 6, i * rowHeight + rowHeight / 2 - textPainter.height / 2));
    }
  }

  void _drawRightSideStats(Canvas canvas, Size size, double offsetX, double chartWidth, double rowHeight) {
    const labels = ['OFF', 'SB', 'D', 'ON'];

    for (int i = 0; i < labels.length; i++) {
      final String formattedStat = (stats![labels[i]] ?? 0.0).toStringAsFixed(2).padLeft(5, '0');
      final textSpan = TextSpan(
        text: formattedStat,
        style: TextStyle(
          fontSize: 10,
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
      textPainter.layout();
      textPainter.paint(canvas, Offset(offsetX + chartWidth + 6, i * rowHeight + rowHeight / 2 - textPainter.height / 2));
    }
  }

  void _drawStepLine(Canvas canvas, double offsetX, double chartWidth, double rowHeight) {
    if (points.isEmpty) return;

    final solidPaint = Paint()
      ..color = AppColors.infoBlue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;

    final dashedPaint = Paint()
      ..color = AppColors.infoBlue
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter;

    double? lastY;
    double? lastX;

    for (final point in points) {
      if (point.endHour <= 0.0 || point.startHour >= 24.0) continue;
      
      final startHour = point.startHour.clamp(0.0, 24.0);
      final endHour = point.endHour.clamp(0.0, 24.0);

      final xStart = offsetX + (startHour / 24.0) * chartWidth;
      final xEnd = offsetX + (endHour / 24.0) * chartWidth;

      final double newY = _getYPosition(point.status, rowHeight);

      // Draw vertical drop/rise if needed
      if (lastY != null && lastX != null && lastY != newY) {
        canvas.drawLine(Offset(lastX, lastY), Offset(xStart, newY), solidPaint);
      } else if (lastY == null && xStart > offsetX) {
        // Line from midnight to first event
        final initialY = _getYPosition('OFF', rowHeight);
        canvas.drawLine(Offset(offsetX, initialY), Offset(xStart, initialY), solidPaint);
        if (initialY != newY) {
          canvas.drawLine(Offset(xStart, initialY), Offset(xStart, newY), solidPaint);
        }
      }

      // Draw horizontal line
      if (point.isDashed) {
        _drawDashedLine(canvas, Offset(xStart, newY), Offset(xEnd, newY), dashedPaint);
      } else {
        canvas.drawLine(Offset(xStart, newY), Offset(xEnd, newY), solidPaint);
      }

      // Draw Tag (e.g. PC, YM)
      if (point.tag != null && point.tag!.isNotEmpty) {
        _drawTag(canvas, point.tag!, xStart, xEnd, newY);
      }

      lastX = xEnd;
      lastY = newY;
    }
  }

  void _drawLiveMarker(Canvas canvas, double offsetX, double chartWidth, double rowHeight) {
    if (liveMarkerHour! < 0 || liveMarkerHour! > 24) return;
    
    final x = offsetX + (liveMarkerHour! / 24.0) * chartWidth;

    final markerPaint = Paint()
      ..color = AppColors.infoBlue.withValues(alpha: 0.5)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(x, 0);
    path.lineTo(x, rowHeight * 4);

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double distance = 0.0;
    
    for (PathMetric measurePath in path.computeMetrics()) {
      while (distance < measurePath.length) {
        canvas.drawPath(
          measurePath.extractPath(distance, distance + dashWidth),
          markerPaint,
        );
        distance += dashWidth + dashSpace;
      }
      distance = 0.0;
    }
    
    final circlePaint = Paint()
      ..color = AppColors.infoBlue
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(Offset(x, 0), 4, circlePaint);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 4.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dist = dx.abs();
    final stepX = (dx / dist) * (dashWidth + dashSpace);
    
    double currentDistance = 0;
    double currentX = p1.dx;
    
    while (currentDistance < dist) {
      final endX = currentX + (dx / dist) * dashWidth;
      final actualEndX = (currentDistance + dashWidth > dist) ? p2.dx : endX;
      canvas.drawLine(Offset(currentX, p1.dy), Offset(actualEndX, p1.dy), paint);
      
      currentX += stepX;
      currentDistance += dashWidth + dashSpace;
    }
  }

  void _drawTag(Canvas canvas, String text, double xStart, double xEnd, double y) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        fontSize: 10,
        color: AppColors.infoBlue,
        fontWeight: FontWeight.bold,
        backgroundColor: Colors.white70,
      ),
    );
    final textPainter = TextPainter(text: textSpan, textDirection: TextDirection.ltr);
    textPainter.layout();
    
    // Draw in the middle of the segment
    final midX = xStart + (xEnd - xStart) / 2;
    textPainter.paint(
      canvas,
      Offset(midX - (textPainter.width / 2), y - textPainter.height - 2),
    );
  }

  double _getYPosition(String status, double rowHeight) {
    switch (status) {
      case 'OFF': return rowHeight * 0.5;
      case 'SB':  return rowHeight * 1.5;
      case 'D':   return rowHeight * 2.5;
      case 'ON':  return rowHeight * 3.5;
      default:    return rowHeight * 0.5;
    }
  }

  @override
  bool shouldRepaint(covariant _EldGraphGridPainter oldDelegate) {
    return oldDelegate.points != points ||
           oldDelegate.stats != stats ||
           oldDelegate.liveMarkerHour != liveMarkerHour ||
           oldDelegate.textColor != textColor ||
           oldDelegate.gridColor != gridColor;
  }
}
