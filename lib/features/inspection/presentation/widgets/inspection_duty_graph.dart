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

  /// SRS 8.3 / FMCSA graph-grid: exactly four duty rows. Personal
  /// Conveyance is drawn on the OFF row and Yard Move on the ON row, each
  /// with a distinct colour plus a "PC"/"YM" tag so special categories stay
  /// visually distinct from the base statuses.
  static const _rows = ['OFF', 'SB', 'D', 'ON'];

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

    final points = <({double hour, String row, String? special})>[];
    for (final event in events) {
      final hour = _hourOf(event.timeEt);
      if (hour == null) continue;
      final code = _rowOf(event);
      points.add((
        hour: hour,
        row: switch (code) { 'PC' => 'OFF', 'YM' => 'ON', _ => code },
        special: code == 'PC' || code == 'YM' ? code : null,
      ));
    }
    if (points.isEmpty) return;
    points.sort((a, b) => a.hour.compareTo(b.hour));

    final line = Paint()
      ..color = AppColors.primaryGold
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final specialLine = Paint()
      ..color = AppColors.infoBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    double yFor(String row) {
      final index = _rows.indexOf(row);
      final i = index < 0 ? 0 : index;
      return i * rowHeight + rowHeight / 2;
    }

    void tag(String text, double x1, double x2, double y) {
      final tp = TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 8,
            color: AppColors.infoBlue,
            fontWeight: FontWeight.w700,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      if (x2 - x1 < tp.width) return;
      tp.paint(canvas, Offset((x1 + x2) / 2 - tp.width / 2, y - tp.height - 2));
    }

    // Horizontal segment per status interval; vertical joins between rows.
    final firstX = labelWidth + (points.first.hour / 24) * chartWidth;
    var y = yFor(points.first.row);
    canvas.drawLine(Offset(labelWidth, y), Offset(firstX, y), line);
    for (var i = 0; i < points.length; i++) {
      final startX = labelWidth + (points[i].hour / 24) * chartWidth;
      final endX = i + 1 < points.length
          ? labelWidth + (points[i + 1].hour / 24) * chartWidth
          : labelWidth + chartWidth;
      final rowY = yFor(points[i].row);
      if (i > 0 && rowY != y) {
        canvas.drawLine(Offset(startX, y), Offset(startX, rowY), line);
      }
      final special = points[i].special;
      canvas.drawLine(
        Offset(startX, rowY),
        Offset(endX, rowY),
        special == null ? line : specialLine,
      );
      if (special != null) tag(special, startX, endX, rowY);
      y = rowY;
    }
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
    // The standard duty code is authoritative; free-text matching below is
    // only a fallback for servers that send descriptive codes.
    switch (event.eventCode.trim().toUpperCase()) {
      case '1':
      case 'OFF':
        return 'OFF';
      case '2':
      case 'SB':
        return 'SB';
      case '3':
      case 'D':
        return 'D';
      case '4':
      case 'ON':
        return 'ON';
      case 'PC':
        return 'PC';
      case 'YM':
        return 'YM';
    }
    final raw = '${event.eventCode} ${event.eventType} ${event.description}'
        .toUpperCase();
    // Word boundaries (\b): 'OFFICE' must not match OFF, 'PERSONAL
    // CONVEYANCE' must not land on ON via "cONveyance".
    if (RegExp(r'\bPC\b|\bPERSONAL\b').hasMatch(raw)) return 'PC';
    if (RegExp(r'\bYM\b|\bYARD\b').hasMatch(raw)) return 'YM';
    if (RegExp(r'\bSB\b|\bSLEEPER\b').hasMatch(raw)) return 'SB';
    if (RegExp(r'\bDRIV').hasMatch(raw)) return 'D';
    if (RegExp(r'\bON\b').hasMatch(raw)) return 'ON';
    if (RegExp(r'\bOFF\b').hasMatch(raw)) return 'OFF';
    return 'OFF';
  }

  @override
  bool shouldRepaint(covariant _InspectionGraphPainter oldDelegate) {
    return oldDelegate.events != events ||
        oldDelegate.textColor != textColor ||
        oldDelegate.gridColor != gridColor;
  }
}
