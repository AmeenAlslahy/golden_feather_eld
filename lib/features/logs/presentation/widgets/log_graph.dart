import 'package:golden_feather_eld/core/domain/entities/hos_models.dart';
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:golden_feather_eld/features/tracking/data/datasources/live_tracking_data_source.dart';

final logGraphEventsProvider = StreamProvider.autoDispose<EldEvent>((ref) {
  return ref.watch(liveTrackingDataSourceProvider).events;
});

class LogGraph extends ConsumerWidget {
  final List<dynamic> events;
  final DateTime? logDate;

  const LogGraph({super.key, required this.events, this.logDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final latestEldEvent = ref.watch(logGraphEventsProvider).valueOrNull;

    return Container(
      height: 190,
      color: Colors.white,
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _LogGraphPainter(
              events: events,
              logDate: logDate,
              latestEldEvent: latestEldEvent,
              textColor: Colors.black87,
              gridColor: Colors.black54,
            ),
          );
        },
      ),
    );
  }
}

class _LogGraphPainter extends CustomPainter {
  final List<dynamic> events;
  final DateTime? logDate;
  final EldEvent? latestEldEvent;
  final Color textColor;
  final Color gridColor;

  _LogGraphPainter({
    required this.events,
    this.logDate,
    this.latestEldEvent,
    required this.textColor,
    required this.gridColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const offsetX = 35.0; // Left padding for status labels
    const rightMargin = 40.0; // Right padding for stats
    final chartWidth = size.width - offsetX - rightMargin;
    
    // Reserve top 20 pixels for Time Axis
    const timeAxisHeight = 20.0;
    final chartHeight = size.height - timeAxisHeight;
    final rowHeight = chartHeight / 4.0; // 4 rows: OFF, SB, D, ON

    _drawTimeAxis(canvas, offsetX, chartWidth, timeAxisHeight);
    
    // Shift canvas down by timeAxisHeight for the grid and lines
    canvas.save();
    canvas.translate(0, timeAxisHeight);

    _drawGridLines(canvas, size, offsetX, chartWidth, chartHeight, rowHeight);
    _drawYAxisLabels(canvas, offsetX, rowHeight);
    _drawRightSideStats(canvas, size, offsetX, chartWidth, rowHeight);
    _drawStepLine(canvas, offsetX, chartWidth, rowHeight);

    if (latestEldEvent != null) {
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

    // Horizontal lines (5 lines for 4 rows)
    for (int i = 0; i <= 4; i++) {
      canvas.drawLine(Offset(offsetX, i * rowHeight), Offset(offsetX + chartWidth, i * rowHeight), gridPaint);
    }

    final colWidth = chartWidth / 24;
    
    // Vertical hour lines and minor ticks
    for (int i = 0; i <= 24; i++) {
      final x = offsetX + i * colWidth;
      // Solid hour line
      canvas.drawLine(Offset(x, 0), Offset(x, chartHeight), gridPaint);
      
      if (i < 24) {
        // Minor ticks at 15, 30, 45 mins
        for (int j = 1; j <= 3; j++) {
          final tickX = x + (colWidth / 4) * j;
          final tickHeight = (j == 2) ? 6.0 : 3.0; // 30 min is taller
          
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
    final Map<String, double> stats = {'OFF': 0, 'SB': 0, 'D': 0, 'ON': 0};
    
    for (final event in events) {
      final status = event.status as String;
      final duration = event.duration as Duration;
      
      String normalized;
      if (status == 'PC') {
        normalized = 'OFF';
      } else if (status == 'YM' || status == 'OTH' || !stats.containsKey(status)) {
        normalized = 'ON';
      } else {
        normalized = status;
      }

      stats[normalized] = stats[normalized]! + (duration.inMinutes / 60.0);
    }

    for (int i = 0; i < labels.length; i++) {
      final String formattedStat = (stats[labels[i]] ?? 0.0).toStringAsFixed(2).padLeft(5, '0');
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
    if (events.isEmpty) return;

    final linePaint = Paint()
      ..color = const Color(0xFF1B5B8A) // Match blue color from screenshot
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.miter; // Miter makes sharp right angles

    final path = Path();
    final sortedEvents = List<dynamic>.from(events)..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    final referenceDate = (logDate ?? sortedEvents.first.startTime).toLocal();
    final midnight = DateTime(referenceDate.year, referenceDate.month, referenceDate.day);

    final firstEvent = sortedEvents.first;
    final firstStartHour = (firstEvent.startTime as DateTime).toLocal().difference(midnight).inMinutes / 60.0;
    
    // If the first event doesn't start exactly at midnight, assume OFF duty for the carry-over gap
    final String initialStatus = firstStartHour > 0.05 ? 'OFF' : firstEvent.status as String;
    
    final double startY = _getYPosition(initialStatus, rowHeight);
    path.moveTo(offsetX, startY);

    double currentX = offsetX;
    double currentY = startY;

    for (final event in sortedEvents) {
      final startTime = (event.startTime as DateTime).toLocal();
      final duration = event.duration as Duration;
      final status = event.status as String;

      // Calculate absolute hours since midnight of the logDate
      double startHour = startTime.difference(midnight).inMinutes / 60.0;
      double endHour = startHour + (duration.inMinutes / 60.0);

      // Clamp to 0..24 for drawing
      if (endHour <= 0.0) continue; // Event is entirely before today
      if (startHour >= 24.0) continue; // Event is entirely after today
      
      startHour = startHour.clamp(0.0, 24.0);
      endHour = endHour.clamp(0.0, 24.0);

      final xStart = offsetX + (startHour / 24.0) * chartWidth;
      final xEnd = offsetX + (endHour / 24.0) * chartWidth;

      final double newY = _getYPosition(status, rowHeight);

      if (xStart > currentX + 0.01) {
        path.lineTo(xStart, currentY);
      }
      path.lineTo(xStart, newY);
      path.lineTo(xEnd, newY);

      currentX = xEnd;
      currentY = newY;
    }

    if (currentX < offsetX + chartWidth) {
      path.lineTo(offsetX + chartWidth, currentY);
    }
    canvas.drawPath(path, linePaint);

    // Overlay for PC / YM (dashed/dotted or just thick line)
    final specialPaint = Paint()
      ..color = AppColors.infoBlue.withValues(alpha: 0.6)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
      
    for (final event in sortedEvents) {
      final status = event.status as String;
      if (status != 'PC' && status != 'YM') continue;
      
      final startTime = event.startTime as DateTime;
      final duration = event.duration as Duration;
      final startHour = startTime.hour + startTime.minute / 60.0;
      final endHour = startHour + (duration.inMinutes / 60.0);
      final xStart = offsetX + (startHour / 24.0) * chartWidth;
      final xEnd = offsetX + (endHour / 24.0) * chartWidth;
      final y = _getYPosition(status, rowHeight);
      
      canvas.drawLine(Offset(xStart, y), Offset(xEnd, y), specialPaint);
    }
  }

  void _drawLiveMarker(Canvas canvas, double offsetX, double chartWidth, double rowHeight) {
    final now = latestEldEvent!.timestamp;
    final startHour = now.hour + now.minute / 60.0;
    final xPos = offsetX + (startHour / 24.0) * chartWidth;
    final yPos = _getYPosition('ON', rowHeight);

    final markerPaint = Paint()..color = AppColors.warningYellow..style = PaintingStyle.fill;
    final glowPaint = Paint()..color = AppColors.warningYellow.withValues(alpha: 0.3)..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(xPos, yPos), 6.0, glowPaint);
    canvas.drawCircle(Offset(xPos, yPos), 3.0, markerPaint);
  }

  double _getYPosition(String status, double rowHeight) {
    int index = 0;
    switch (status) {
      case 'OFF':
      case 'PC':
        index = 0;
        break;
      case 'SB':
        index = 1;
        break;
      case 'D':
        index = 2;
        break;
      case 'ON':
      case 'YM':
      default:
        index = 3;
        break;
    }
    return index * rowHeight + (rowHeight / 2);
  }

  @override
  bool shouldRepaint(covariant _LogGraphPainter oldDelegate) {
    return events != oldDelegate.events || latestEldEvent != oldDelegate.latestEldEvent;
  }
}
