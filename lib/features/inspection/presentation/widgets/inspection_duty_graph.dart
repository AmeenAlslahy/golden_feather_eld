import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../domain/inspection/dot_inspection.dart';
import '../../../../core/widgets/eld_graph_grid.dart';

/// 24-hour duty graph for inspection mode, drawn from DOT log events.
class InspectionDutyGraph extends StatelessWidget {
  const InspectionDutyGraph({super.key, required this.events});

  final List<DotInspectionEvent> events;

  @override
  Widget build(BuildContext context) {
    final points = <EldGraphPoint>[];

    for (int i = 0; i < events.length; i++) {
      final event = events[i];
      final startHour = _hourOf(event.timeEt);
      if (startHour == null) continue;

      final row = _rowOf(event);
      final isPC = row == 'PC';
      final isYM = row == 'YM';
      final normalizedRow = isPC ? 'OFF' : (isYM ? 'ON' : row);
      final special = isPC ? 'PC' : (isYM ? 'YM' : null);

      double endHour = 24.0;
      if (i + 1 < events.length) {
        final nextHour = _hourOf(events[i + 1].timeEt);
        if (nextHour != null) {
          endHour = nextHour;
        }
      }

      points.add(
        EldGraphPoint(
          startHour: startHour,
          endHour: endHour,
          status: normalizedRow,
          tag: special,
          isDashed: special != null,
        ),
      );
    }

    return Container(
      height: 180,
      color: Theme.of(context).colorScheme.surface,
      padding: const EdgeInsets.only(
        top: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SizedBox(
            width: constraints.maxWidth,
            height: constraints.maxHeight,
            child: EldGraphGrid(
              points: points,
              // Inspection screen doesn't need right-side stats shown in the graph widget itself
            ),
          );
        },
      ),
    );
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
}
