import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/inspection/dot_inspection.dart';

/// 24-hour duty graph for inspection mode, drawn from DOT log events.
class InspectionDutyGraph extends StatelessWidget {
  const InspectionDutyGraph({super.key, required this.events});

  final List<DotInspectionEvent> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 180,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.sm,
        top: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: _InspectionGraphPainter(
              events: events,
              textColor: Theme.of(context).colorScheme.onSurface,
              gridColor: Theme.of(context).colorScheme.outlineVariant,
            ),
          );
        },
      ),
    );
  }
}

class _InspectionGraphPainter extends CustomPainter {
  _InspectionGraphPainter({
    required this.events,
    required this.textColor,
    required this.gridColor,
  });

  final List<DotInspectionEvent> events;
  final Color textColor;
  final Color gridColor;

  static const _rows = ['OFF', 'SB', 'D', 'ON', 'PC', 'YM'];

  @override
  void paint(Canvas canvas, Size size) {
    const labelWidth = 32.0;
    final rowHeight = size.height / _rows.length;
    final chartWidth = size.width - labelWidth;

    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: 0.35)
      ..strokeWidth = 0.5;
    for (var i = 0; i <= _rows.length; i++) {
      final y = i * rowHeight;
      canvas.drawLine(Offset(labelWidth, y), Offset(size.width, y), gridPaint);
    }
    final colWidth = chartWidth / 24;
    for (var i = 0; i <= 24; i++) {
      canvas.drawLine(
        Offset(labelWidth + i * colWidth, 0),
        Offset(labelWidth + i * colWidth, size.height),
        gridPaint,
      );
    }

    for (var i = 0; i < _rows.length; i++) {
      final span = TextSpan(
        text: _rows[i],
        style: TextStyle(
          fontSize: 9,
          color: textColor.withValues(alpha: 0.65),
          fontWeight: FontWeight.w500,
        ),
      );
      final tp = TextPainter(text: span, textDirection: TextDirection.ltr)
        ..layout();
      tp.paint(
        canvas,
        Offset(2, i * rowHeight + rowHeight / 2 - tp.height / 2),
      );
    }

    if (events.isEmpty) return;

    final points = <({double hour, String row})>[];
    for (final event in events) {
      final hour = _hourOf(event.timeEt);
      if (hour == null) continue;
      points.add((hour: hour, row: _rowOf(event)));
    }
    if (points.isEmpty) return;
    points.sort((a, b) => a.hour.compareTo(b.hour));

    final line = Paint()
      ..color = AppColors.primaryGold
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeJoin = StrokeJoin.round;

    double yFor(String row) {
      final index = _rows.indexOf(row);
      final i = index < 0 ? 0 : index;
      return i * rowHeight + rowHeight / 2;
    }

    final path = Path();
    var x = labelWidth + (points.first.hour / 24) * chartWidth;
    var y = yFor(points.first.row);
    path.moveTo(labelWidth, y);
    path.lineTo(x, y);
    for (var i = 1; i < points.length; i++) {
      final nextX = labelWidth + (points[i].hour / 24) * chartWidth;
      final nextY = yFor(points[i].row);
      path.lineTo(nextX, y);
      path.lineTo(nextX, nextY);
      x = nextX;
      y = nextY;
    }
    path.lineTo(labelWidth + chartWidth, y);
    canvas.drawPath(path, line);
  }

  static double? _hourOf(String timeEt) {
    final parsed = DateTime.tryParse(timeEt);
    if (parsed != null) return parsed.hour + parsed.minute / 60.0;
    final parts = timeEt.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return h + m / 60.0;
  }

  static String _rowOf(DotInspectionEvent event) {
    final raw = '${event.eventCode} ${event.eventType} ${event.description}'
        .toUpperCase();
    if (raw.contains('PC') || raw.contains('PERSONAL')) return 'PC';
    if (raw.contains('YM') || raw.contains('YARD')) return 'YM';
    if (raw.contains('SB') || raw.contains('SLEEPER') || raw.contains(' 2')) {
      return 'SB';
    }
    if (raw.contains('DRIV') ||
        raw == 'D' ||
        raw.startsWith('D ') ||
        raw.contains(' 3') ||
        event.eventCode == '3') {
      return 'D';
    }
    if (raw.contains('ON') || event.eventCode == '4') return 'ON';
    if (raw.contains('OFF') || event.eventCode == '1') return 'OFF';
    return 'OFF';
  }

  @override
  bool shouldRepaint(covariant _InspectionGraphPainter oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor;
  }
}
